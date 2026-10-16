"""Institutional Walk-Forward Out-of-Sample Validation Engine.

Eliminates lookahead and data-snooping biases by training parameters strictly
on rolling in-sample windows and evaluating performance on unseen out-of-sample periods.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
import numpy as np
import pandas as pd

from ..analysis.cadf_test import cadf_test
from ..state_space.kalman_filter import KalmanHedgeTracker
from ..strategy.zscore_signals import ZScoreSignalGenerator
from ..backtest.execution_sim import PairsExecutionSimulator
from ..backtest.performance import PerformanceAnalyzer, PerformanceMetrics


@dataclass
class WalkForwardFold:
    """Record of a single train/test walk-forward split."""
    fold_id: int
    train_start_idx: int
    train_end_idx: int
    test_start_idx: int
    test_end_idx: int
    best_z_entry: float
    best_z_exit: float
    in_sample_sharpe: float
    out_sample_sharpe: float
    out_sample_return_pct: float
    out_sample_trades: int
    is_cointegrated_train: bool


@dataclass
class WalkForwardResult:
    """Comprehensive container for walk-forward validation outputs."""
    folds: List[WalkForwardFold]
    spliced_oos_equity: np.ndarray
    spliced_oos_returns: np.ndarray
    spliced_oos_metrics: PerformanceMetrics
    average_is_sharpe: float
    average_oos_sharpe: float
    walk_forward_efficiency: float  # OOS Sharpe / IS Sharpe
    is_robust: bool                 # WFE >= 0.50


class WalkForwardValidator:
    """Rolling walk-forward parameter optimizer and out-of-sample evaluator."""

    def __init__(
        self,
        train_window: int = 252,        # 1 year in-sample training
        test_window: int = 63,          # 1 quarter out-of-sample testing
        z_entry_grid: Optional[List[float]] = None,
        z_exit_grid: Optional[List[float]] = None,
        initial_capital: float = 100_000.0,
        commission_per_share: float = 0.005,
        half_spread_bps: float = 3.0,
        slippage_bps: float = 2.0,
        short_borrow_fee_annual: float = 0.015
    ):
        """Initialize walk-forward validation parameters."""
        self.train_window = train_window
        self.test_window = test_window
        self.z_entry_grid = z_entry_grid or [1.5, 2.0, 2.5]
        self.z_exit_grid = z_exit_grid or [0.0, 0.5]
        self.initial_capital = initial_capital
        self.commission_per_share = commission_per_share
        self.half_spread_bps = half_spread_bps
        self.slippage_bps = slippage_bps
        self.short_borrow_fee_annual = short_borrow_fee_annual

    def _evaluate_params(
        self,
        y: np.ndarray,
        x: np.ndarray,
        z_entry: float,
        z_exit: float
    ) -> Tuple[float, float]:
        """Run single in-sample simulation and return (Sharpe, Total Return)."""
        kf = KalmanHedgeTracker(delta=1e-4, r_var=1e-3)
        kf_res = kf.filter_series(y, x)

        sig_gen = ZScoreSignalGenerator(z_entry=z_entry, z_exit=z_exit, z_stop=3.5)
        signals = sig_gen.generate(kf_res.zscore_history)

        sim = PairsExecutionSimulator(
            initial_capital=self.initial_capital,
            commission_per_share=self.commission_per_share,
            half_spread_bps=self.half_spread_bps,
            slippage_bps=self.slippage_bps,
            short_borrow_fee_annual=self.short_borrow_fee_annual
        )
        res = sim.simulate(y, x, signals.positions, kf_res.beta_history)

        analyzer = PerformanceAnalyzer(risk_free_rate_annual=0.04)
        metrics = analyzer.analyze(res)
        return metrics.sharpe_ratio, metrics.total_return_pct

    def run(
        self,
        series_y: np.ndarray,
        series_x: np.ndarray,
        dates: Optional[List[str]] = None
    ) -> WalkForwardResult:
        """Execute rolling walk-forward cross-validation.

        Args:
            series_y: Complete historical Y series.
            series_x: Complete historical X series.
            dates: Optional list of date strings.

        Returns:
            WalkForwardResult with fold-by-fold results and spliced OOS equity curve.
        """
        y = np.asarray(series_y, dtype=float)
        x = np.asarray(series_x, dtype=float)
        n = len(y)

        folds: List[WalkForwardFold] = []
        oos_returns_list = []
        oos_equity_curve = [self.initial_capital]

        current_cap = self.initial_capital
        fold_id = 0
        start_idx = 0

        while start_idx + self.train_window + self.test_window <= n:
            fold_id += 1
            train_start = start_idx
            train_end = start_idx + self.train_window
            test_start = train_end
            test_end = train_end + self.test_window

            y_train = y[train_start:train_end]
            x_train = x[train_start:train_end]
            y_test = y[test_start:test_end]
            x_test = x[test_start:test_end]

            # 1. Check cointegration in-sample
            coint_train = cadf_test(y_train, x_train)

            # 2. Grid search optimal parameters on in-sample slice
            best_sharpe = -999.0
            best_entry = 2.0
            best_exit = 0.0

            for entry in self.z_entry_grid:
                for exit_val in self.z_exit_grid:
                    if entry <= exit_val:
                        continue
                    try:
                        sh, _ = self._evaluate_params(y_train, x_train, entry, exit_val)
                        if sh > best_sharpe:
                            best_sharpe = sh
                            best_entry = entry
                            best_exit = exit_val
                    except Exception:
                        continue

            # 3. Evaluate selected parameters strictly on out-of-sample window
            kf_oos = KalmanHedgeTracker(delta=1e-4, r_var=1e-3)
            # Warm up Kalman filter on train, then filter test
            _ = kf_oos.filter_series(y_train, x_train)
            kf_test_res = kf_oos.filter_series(y_test, x_test)

            sig_oos = ZScoreSignalGenerator(z_entry=best_entry, z_exit=best_exit, z_stop=3.5)
            test_signals = sig_oos.generate(kf_test_res.zscore_history)

            sim_oos = PairsExecutionSimulator(
                initial_capital=current_cap,
                commission_per_share=self.commission_per_share,
                half_spread_bps=self.half_spread_bps,
                slippage_bps=self.slippage_bps,
                short_borrow_fee_annual=self.short_borrow_fee_annual
            )
            res_oos = sim_oos.simulate(y_test, x_test, test_signals.positions, kf_test_res.beta_history)

            analyzer_oos = PerformanceAnalyzer(risk_free_rate_annual=0.04)
            metrics_oos = analyzer_oos.analyze(res_oos)

            # Splicing OOS returns
            oos_ret_segment = res_oos.returns[1:]
            oos_returns_list.extend(oos_ret_segment)

            # Update running capital
            current_cap = res_oos.final_equity
            oos_equity_curve.append(current_cap)

            folds.append(WalkForwardFold(
                fold_id=fold_id,
                train_start_idx=train_start,
                train_end_idx=train_end,
                test_start_idx=test_start,
                test_end_idx=test_end,
                best_z_entry=best_entry,
                best_z_exit=best_exit,
                in_sample_sharpe=float(best_sharpe),
                out_sample_sharpe=float(metrics_oos.sharpe_ratio),
                out_sample_return_pct=float(metrics_oos.total_return_pct),
                out_sample_trades=len(res_oos.trades),
                is_cointegrated_train=coint_train.is_cointegrated
            ))

            start_idx += self.test_window

        # Build spliced out-of-sample equity trajectory
        spliced_ret = np.array(oos_returns_list, dtype=float)
        spliced_eq = self.initial_capital * np.cumprod(1.0 + spliced_ret)
        spliced_eq = np.insert(spliced_eq, 0, self.initial_capital)

        # Mock BacktestResult for spliced metrics calculation
        from ..backtest.execution_sim import BacktestResult
        spliced_res = BacktestResult(
            initial_capital=self.initial_capital,
            final_equity=float(spliced_eq[-1]),
            total_net_pnl=float(spliced_eq[-1] - self.initial_capital),
            total_return_pct=float((spliced_eq[-1] / self.initial_capital - 1.0) * 100.0),
            equity_curve=spliced_eq,
            returns=np.insert(spliced_ret, 0, 0.0),
            daily_pnl=np.diff(spliced_eq, prepend=self.initial_capital),
            positions=np.zeros_like(spliced_eq),
            trades=[],
            total_commissions=0.0,
            total_slippage=0.0,
            total_borrow_fees=0.0
        )
        spliced_metrics = PerformanceAnalyzer(risk_free_rate_annual=0.04).analyze(spliced_res)

        avg_is_sharpe = float(np.mean([f.in_sample_sharpe for f in folds])) if folds else 0.0
        avg_oos_sharpe = float(np.mean([f.out_sample_sharpe for f in folds])) if folds else 0.0
        wfe = (avg_oos_sharpe / avg_is_sharpe) if abs(avg_is_sharpe) > 1e-4 else 0.0

        return WalkForwardResult(
            folds=folds,
            spliced_oos_equity=spliced_eq,
            spliced_oos_returns=spliced_ret,
            spliced_oos_metrics=spliced_metrics,
            average_is_sharpe=avg_is_sharpe,
            average_oos_sharpe=avg_oos_sharpe,
            walk_forward_efficiency=float(wfe),
            is_robust=bool(wfe >= 0.50)
        )
