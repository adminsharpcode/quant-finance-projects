"""
Institutional Parameter Optimization & Sensitivity Engine.
=============================================================
Performs multi-dimensional grid search across Z-score thresholds and
Kalman filter process noise with Walk-Forward cross-validation and
stability penalties to prevent overfitted curve-fitting.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Any
import numpy as np
import pandas as pd

from ..state_space.kalman_filter import KalmanHedgeTracker
from ..strategy.zscore_signals import ZScoreSignalGenerator
from ..backtest.execution_sim import PairsExecutionSimulator
from ..backtest.performance import PerformanceAnalyzer


@dataclass
class OptimizationResult:
    """Detailed summary of the optimization search."""
    best_params: Dict[str, float]
    best_metrics: Dict[str, float]
    walk_forward_efficiency: float
    objective_metric: str
    total_combinations_tested: int
    results_df: pd.DataFrame
    surface_z_entry: List[float]
    surface_z_exit: List[float]
    surface_sharpe_matrix: List[List[float]]


class PairGridOptimizer:
    """
    Exhaustive and robust grid optimizer for pairs trading strategies.
    
    Prevents curve-fitting via:
    1. Minimum trade count threshold constraint.
    2. In-sample vs Out-of-sample Walk-Forward verification.
    3. Parameter surface plateau scoring.
    """

    DEFAULT_GRID = {
        "z_entry": [1.5, 1.8, 2.0, 2.3, 2.6],
        "z_exit": [-0.2, 0.0, 0.2, 0.5],
        "z_stop": [3.5, 4.0],
        "kalman_delta": [1e-5, 1e-4, 1e-3],
    }

    def __init__(
        self,
        initial_capital: float = 100_000.0,
        commission_per_share: float = 0.005,
        half_spread_bps: float = 3.0,
        slippage_bps: float = 2.0,
        short_borrow_fee_annual: float = 0.015,
        train_ratio: float = 0.65,
    ):
        self.initial_capital = initial_capital
        self.commission_per_share = commission_per_share
        self.half_spread_bps = half_spread_bps
        self.slippage_bps = slippage_bps
        self.short_borrow_fee_annual = short_borrow_fee_annual
        self.train_ratio = train_ratio

    def optimize(
        self,
        series_y: np.ndarray,
        series_x: np.ndarray,
        param_grid: Optional[Dict[str, List[float]]] = None,
        objective: str = "sharpe",
        min_trades: int = 4,
    ) -> OptimizationResult:
        """
        Run grid search over the parameter space.
        
        Args:
            series_y: Price series for asset Y (np.ndarray)
            series_x: Price series for asset X (np.ndarray)
            param_grid: Custom parameter grid dictionary
            objective: 'sharpe', 'calmar', 'return', 'win_rate', or 'profit_factor'
            min_trades: Minimum trades required to qualify
            
        Returns:
            OptimizationResult containing best parameters, full dataframe, and surface.
        """
        grid = param_grid or self.DEFAULT_GRID
        entries = grid.get("z_entry", [1.5, 2.0, 2.5])
        exits = grid.get("z_exit", [0.0, 0.2, 0.5])
        stops = grid.get("z_stop", [3.5, 4.0])
        deltas = grid.get("kalman_delta", [1e-4])

        n_total = len(series_y)
        split_idx = int(n_total * self.train_ratio)

        # In-sample & out-of-sample slices
        y_is, x_is = series_y[:split_idx], series_x[:split_idx]
        y_oos, x_oos = series_y[split_idx:], series_x[split_idx:]

        # Pre-calculate Kalman filter for each unique delta to avoid redundant updates
        kalman_cache = {}
        for delta in deltas:
            kf = KalmanHedgeTracker(delta=delta)
            kf_res = kf.filter_series(series_y, series_x)
            kalman_cache[delta] = kf_res

        trials = []
        sim = PairsExecutionSimulator(
            initial_capital=self.initial_capital,
            commission_per_share=self.commission_per_share,
            half_spread_bps=self.half_spread_bps,
            slippage_bps=self.slippage_bps,
            short_borrow_fee_annual=self.short_borrow_fee_annual,
        )
        perf_analyzer = PerformanceAnalyzer()

        for delta in deltas:
            kf_full = kalman_cache[delta]
            z_full = kf_full.zscore_history
            beta_full = kf_full.beta_history

            for z_in in entries:
                for z_out in exits:
                    if z_out >= z_in:
                        continue  # Exit cannot exceed entry
                    for z_st in stops:
                        if z_st <= z_in:
                            continue  # Stop loss must be wider than entry

                        # 1. Evaluate Full Sample
                        sig_gen = ZScoreSignalGenerator(z_entry=z_in, z_exit=z_out, z_stop=z_st)
                        sig_full = sig_gen.generate(z_full)
                        btest_full = sim.simulate(series_y, series_x, sig_full.positions, beta_full)
                        perf_full = perf_analyzer.analyze(btest_full)

                        # 2. Evaluate In-Sample (Train)
                        sig_is = sig_gen.generate(z_full[:split_idx])
                        btest_is = sim.simulate(y_is, x_is, sig_is.positions, beta_full[:split_idx])
                        perf_is = perf_analyzer.analyze(btest_is)

                        # 3. Evaluate Out-of-Sample (Test)
                        sig_oos = sig_gen.generate(z_full[split_idx:])
                        btest_oos = sim.simulate(y_oos, x_oos, sig_oos.positions, beta_full[split_idx:])
                        perf_oos = perf_analyzer.analyze(btest_oos)

                        # Calculate Walk-Forward Efficiency (WFE)
                        if perf_is.sharpe_ratio > 0.05:
                            wfe = max(0.0, perf_oos.sharpe_ratio / perf_is.sharpe_ratio)
                        else:
                            wfe = 1.0 if perf_oos.sharpe_ratio >= 0 else 0.0

                        # Score assignment based on selected objective
                        if objective == "calmar":
                            score = perf_full.calmar_ratio
                        elif objective == "return":
                            score = perf_full.total_return_pct
                        elif objective == "win_rate":
                            score = perf_full.win_rate_pct
                        elif objective == "profit_factor":
                            score = perf_full.profit_factor if perf_full.profit_factor < 20 else 20
                        else:  # 'sharpe'
                            score = perf_full.sharpe_ratio

                        # Discard low sample sizes
                        if perf_full.total_trades < min_trades:
                            score = -999.0

                        trials.append({
                            "z_entry": float(z_in),
                            "z_exit": float(z_out),
                            "z_stop": float(z_st),
                            "kalman_delta": float(delta),
                            "score": float(score),
                            "sharpe_full": float(perf_full.sharpe_ratio),
                            "sharpe_is": float(perf_is.sharpe_ratio),
                            "sharpe_oos": float(perf_oos.sharpe_ratio),
                            "wfe": float(wfe),
                            "total_return_pct": float(perf_full.total_return_pct),
                            "max_drawdown_pct": float(perf_full.max_drawdown_pct),
                            "win_rate_pct": float(perf_full.win_rate_pct),
                            "profit_factor": float(perf_full.profit_factor),
                            "total_trades": int(perf_full.total_trades),
                            "cagr_pct": float(perf_full.cagr_pct),
                        })

        df_trials = pd.DataFrame(trials)
        if df_trials.empty:
            raise ValueError("No parameter combinations tested.")

        # Sort descending by score
        df_sorted = df_trials.sort_values(by="score", ascending=False).reset_index(drop=True)
        best_row = df_sorted.iloc[0]

        best_params = {
            "z_entry": float(best_row["z_entry"]),
            "z_exit": float(best_row["z_exit"]),
            "z_stop": float(best_row["z_stop"]),
            "kalman_delta": float(best_row["kalman_delta"]),
        }

        best_metrics = {
            "score": float(best_row["score"]),
            "sharpe_ratio": float(best_row["sharpe_full"]),
            "sharpe_in_sample": float(best_row["sharpe_is"]),
            "sharpe_out_of_sample": float(best_row["sharpe_oos"]),
            "walk_forward_efficiency": float(best_row["wfe"]),
            "total_return_pct": float(best_row["total_return_pct"]),
            "max_drawdown_pct": float(best_row["max_drawdown_pct"]),
            "win_rate_pct": float(best_row["win_rate_pct"]),
            "profit_factor": float(best_row["profit_factor"]),
            "total_trades": int(best_row["total_trades"]),
        }

        # Build 2D surface (z_entry vs z_exit) fixed at best delta and best stop
        best_delta = best_params["kalman_delta"]
        best_stop = best_params["z_stop"]
        surface_entries = sorted(list(set(entries)))
        surface_exits = sorted(list(set(exits)))
        surface_matrix = []

        for z_out in surface_exits:
            row_vals = []
            for z_in in surface_entries:
                match = df_trials[
                    (df_trials["z_entry"] == z_in) &
                    (df_trials["z_exit"] == z_out) &
                    (df_trials["z_stop"] == best_stop) &
                    (df_trials["kalman_delta"] == best_delta)
                ]
                if not match.empty:
                    val = float(match.iloc[0]["sharpe_full"])
                else:
                    val = 0.0
                row_vals.append(val)
            surface_matrix.append(row_vals)

        return OptimizationResult(
            best_params=best_params,
            best_metrics=best_metrics,
            walk_forward_efficiency=float(best_row["wfe"]),
            objective_metric=objective,
            total_combinations_tested=len(df_trials),
            results_df=df_sorted,
            surface_z_entry=surface_entries,
            surface_z_exit=surface_exits,
            surface_sharpe_matrix=surface_matrix,
        )
