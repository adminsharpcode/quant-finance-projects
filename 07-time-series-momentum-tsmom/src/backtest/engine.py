"""
Vectorized and Event-Driven Backtest Simulation Engine for Time Series Momentum.
Simulates daily mark-to-market accounting, monthly or daily rebalancing,
and realistic transaction costs.
"""

from dataclasses import dataclass
from typing import Dict, Optional, Union
import numpy as np
import pandas as pd

from .execution import ExecutionCostModel
from ..core.returns import compute_daily_returns


@dataclass
class BacktestResult:
    """Container for backtest output dataframes and performance summary."""
    daily_returns: pd.Series
    gross_returns: pd.Series
    net_returns: pd.Series
    cumulative_returns: pd.Series
    portfolio_equity: pd.Series
    weights: pd.DataFrame
    turnover: pd.Series
    transaction_costs: pd.Series
    asset_pnl: pd.DataFrame
    benchmark_returns: Optional[pd.Series] = None


class TSMOMBacktestEngine:
    """
    Simulates portfolio execution of Time Series Momentum with institutional precision.
    
    Parameters
    ----------
    initial_capital : float, default 10,000,000.0 ($10M institutional fund size)
    cost_model : ExecutionCostModel, optional
    rebalance_freq : str, default 'M' ('M' for monthly per Moskowitz et al., 'D' for daily)
    """

    def __init__(
        self,
        initial_capital: float = 10_000_000.0,
        cost_model: Optional[ExecutionCostModel] = None,
        rebalance_freq: str = "M",
    ):
        self.initial_capital = initial_capital
        self.cost_model = cost_model or ExecutionCostModel()
        self.rebalance_freq = rebalance_freq

    def run(
        self,
        prices: pd.DataFrame,
        target_weights: pd.DataFrame,
        benchmark_prices: Optional[pd.DataFrame] = None,
    ) -> BacktestResult:
        """
        Executes backtest over the price matrix.
        
        Parameters
        ----------
        prices : pd.DataFrame
            Daily continuous price matrix for contracts.
        target_weights : pd.DataFrame
            Target allocation weights w_{i, t}.
        benchmark_prices : pd.DataFrame, optional
            Benchmark prices for comparison (e.g. 60/40 or S&P 500).
            
        Returns
        -------
        BacktestResult
        """
        daily_returns = compute_daily_returns(prices)
        common_idx = daily_returns.index.intersection(target_weights.index)
        daily_returns = daily_returns.loc[common_idx]
        target_weights = target_weights.loc[common_idx]
        
        n_days = len(common_idx)
        n_assets = len(prices.columns)
        
        # Identify rebalance days
        if self.rebalance_freq == "M":
            # Rebalance on the last trading day of each month
            dates_series = pd.Series(common_idx, index=common_idx)
            month_group = dates_series.groupby([dates_series.dt.year, dates_series.dt.month]).last()
            rebalance_dates = set(month_group.values)
        else:
            rebalance_dates = set(common_idx)
            
        current_w = np.zeros(n_assets)
        actual_weights = np.zeros((n_days, n_assets))
        gross_ret = np.zeros(n_days)
        costs = np.zeros(n_days)
        net_ret = np.zeros(n_days)
        turnover_arr = np.zeros(n_days)
        asset_pnl_arr = np.zeros((n_days, n_assets))
        
        rate = self.cost_model.total_rate
        
        for t in range(n_days):
            dt = common_idx[t]
            r_t = daily_returns.iloc[t].values
            
            # Step 1: Holding return from t-1 to t
            pnl_assets = current_w * r_t
            r_gross_t = np.sum(pnl_assets)
            gross_ret[t] = r_gross_t
            asset_pnl_arr[t, :] = pnl_assets
            
            # Update post-return weights (drift before rebalance)
            drifted_w = current_w * (1.0 + r_t) / (1.0 + r_gross_t) if abs(1.0 + r_gross_t) > 1e-8 else current_w
            
            # Step 2: Check if rebalance day
            if dt in rebalance_dates or t == 0:
                target_w = target_weights.iloc[t].values
                # Turnover
                to_t = np.sum(np.abs(target_w - drifted_w))
                cost_t = to_t * rate
                current_w = target_w.copy()
            else:
                to_t = 0.0
                cost_t = 0.0
                current_w = drifted_w.copy()
                
            turnover_arr[t] = to_t
            costs[t] = cost_t
            net_ret[t] = r_gross_t - cost_t
            actual_weights[t, :] = current_w
            
        net_series = pd.Series(net_ret, index=common_idx, name="Net_Return")
        gross_series = pd.Series(gross_ret, index=common_idx, name="Gross_Return")
        turnover_series = pd.Series(turnover_arr, index=common_idx, name="Turnover")
        cost_series = pd.Series(costs, index=common_idx, name="Costs")
        
        cum_ret = (1.0 + net_series).cumprod()
        equity = self.initial_capital * cum_ret
        
        weights_df = pd.DataFrame(actual_weights, index=common_idx, columns=prices.columns)
        asset_pnl_df = pd.DataFrame(asset_pnl_arr, index=common_idx, columns=prices.columns)
        
        bench_ret = None
        if benchmark_prices is not None:
            bench_daily = compute_daily_returns(benchmark_prices).loc[common_idx]
            if isinstance(bench_daily, pd.DataFrame):
                bench_ret = bench_daily.mean(axis=1)
            else:
                bench_ret = bench_daily
                
        return BacktestResult(
            daily_returns=net_series,
            gross_returns=gross_series,
            net_returns=net_series,
            cumulative_returns=cum_ret,
            portfolio_equity=equity,
            weights=weights_df,
            turnover=turnover_series,
            transaction_costs=cost_series,
            asset_pnl=asset_pnl_df,
            benchmark_returns=bench_ret,
        )
