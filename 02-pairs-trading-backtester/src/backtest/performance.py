"""Quantitative Performance & Risk Analytics Suite.

Computes institutional risk-adjusted return metrics including Sharpe, Sortino,
Calmar, Maximum Drawdown duration, Win Rate, and Profit Factor.
"""

from dataclasses import dataclass
from typing import List, Optional
import numpy as np
import pandas as pd
from .execution_sim import BacktestResult, TradeRecord


@dataclass
class PerformanceMetrics:
    """Comprehensive performance and risk metrics summary."""
    total_return_pct: float
    cagr_pct: float
    annualized_vol_pct: float
    sharpe_ratio: float
    sortino_ratio: float
    max_drawdown_pct: float
    max_drawdown_duration_bars: int
    calmar_ratio: float
    total_trades: int
    winning_trades: int
    losing_trades: int
    win_rate_pct: float
    profit_factor: float
    avg_trade_pnl: float
    avg_trade_return_pct: float
    avg_holding_duration_bars: float
    gross_profits: float
    gross_losses: float
    total_commissions: float
    total_slippage: float
    total_borrow_fees: float
    drawdown_series: np.ndarray


class PerformanceAnalyzer:
    """Calculates risk and return performance statistics from backtest executions."""

    def __init__(self, risk_free_rate_annual: float = 0.04, periods_per_year: int = 252):
        """Initialize analyzer.

        Args:
            risk_free_rate_annual: Annualized benchmark risk-free rate (e.g. 0.04 for 4.0%).
            periods_per_year: Trading days per year (252 for equities, 365 for crypto).
        """
        self.rf = risk_free_rate_annual
        self.periods = periods_per_year

    def analyze(self, backtest_result: BacktestResult) -> PerformanceMetrics:
        """Compute full statistical summary from a BacktestResult object.

        Args:
            backtest_result: BacktestResult instance.

        Returns:
            PerformanceMetrics dataclass.
        """
        equity = backtest_result.equity_curve
        returns = backtest_result.returns
        trades = backtest_result.trades
        n = len(equity)

        if n < 2:
            raise ValueError(f"Insufficient equity history for performance analysis. Length={n}")

        # 1. Total Return & CAGR
        initial_cap = backtest_result.initial_capital
        final_cap = backtest_result.final_equity
        total_ret = (final_cap / initial_cap - 1.0)
        years = n / self.periods
        cagr = ((final_cap / initial_cap) ** (1.0 / max(years, 1e-4)) - 1.0) if final_cap > 0 else -1.0

        # 2. Annualized Volatility
        daily_ret = returns[1:]
        mean_daily = np.mean(daily_ret)
        std_daily = np.std(daily_ret, ddof=1)
        ann_vol = std_daily * np.sqrt(self.periods)

        # 3. Sharpe Ratio
        rf_daily = self.rf / self.periods
        excess_mean = mean_daily - rf_daily
        sharpe = (excess_mean * np.sqrt(self.periods) / std_daily) if std_daily > 1e-9 else 0.0

        # 4. Sortino Ratio (Downside volatility)
        downside_diff = np.minimum(daily_ret - rf_daily, 0.0)
        downside_std = np.sqrt(np.mean(downside_diff ** 2)) * np.sqrt(self.periods)
        sortino = (excess_mean * np.sqrt(self.periods) / downside_std) if downside_std > 1e-9 else 0.0

        # 5. Drawdown Series & Maximum Drawdown
        running_max = np.maximum.accumulate(equity)
        drawdowns = (equity - running_max) / running_max
        max_dd = float(np.min(drawdowns))  # negative float

        # Drawdown Duration
        max_dd_duration = 0
        curr_dd_duration = 0
        for dd in drawdowns:
            if dd < 0:
                curr_dd_duration += 1
                if curr_dd_duration > max_dd_duration:
                    max_dd_duration = curr_dd_duration
            else:
                curr_dd_duration = 0

        # 6. Calmar Ratio
        abs_max_dd = abs(max_dd)
        calmar = (cagr / abs_max_dd) if abs_max_dd > 1e-6 else 0.0

        # 7. Trade-Level Statistics
        total_trades = len(trades)
        winning_trades = sum(1 for t in trades if t.net_pnl > 0)
        losing_trades = sum(1 for t in trades if t.net_pnl < 0)
        win_rate = (winning_trades / total_trades * 100.0) if total_trades > 0 else 0.0

        gross_profits = sum(t.net_pnl for t in trades if t.net_pnl > 0)
        gross_losses = sum(abs(t.net_pnl) for t in trades if t.net_pnl < 0)
        profit_factor = (gross_profits / gross_losses) if gross_losses > 1e-6 else (np.inf if gross_profits > 0 else 0.0)

        avg_pnl = float(np.mean([t.net_pnl for t in trades])) if total_trades > 0 else 0.0
        avg_ret = float(np.mean([t.return_pct for t in trades])) if total_trades > 0 else 0.0
        avg_duration = float(np.mean([t.duration_bars for t in trades])) if total_trades > 0 else 0.0

        return PerformanceMetrics(
            total_return_pct=float(total_ret * 100.0),
            cagr_pct=float(cagr * 100.0),
            annualized_vol_pct=float(ann_vol * 100.0),
            sharpe_ratio=float(sharpe),
            sortino_ratio=float(sortino),
            max_drawdown_pct=float(abs_max_dd * 100.0),
            max_drawdown_duration_bars=int(max_dd_duration),
            calmar_ratio=float(calmar),
            total_trades=total_trades,
            winning_trades=winning_trades,
            losing_trades=losing_trades,
            win_rate_pct=float(win_rate),
            profit_factor=float(profit_factor),
            avg_trade_pnl=avg_pnl,
            avg_trade_return_pct=avg_ret,
            avg_holding_duration_bars=avg_duration,
            gross_profits=float(gross_profits),
            gross_losses=float(gross_losses),
            total_commissions=backtest_result.total_commissions,
            total_slippage=backtest_result.total_slippage,
            total_borrow_fees=backtest_result.total_borrow_fees,
            drawdown_series=drawdowns
        )
