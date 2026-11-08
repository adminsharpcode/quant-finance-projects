"""
Cross-sectional factor backtest engine.
Simulates daily mark-to-market performance, monthly rebalancing, and realistic transaction costs.
"""

from dataclasses import dataclass
from typing import Optional
import numpy as np
import pandas as pd


@dataclass
class FactorBacktestResult:
    daily_returns: pd.Series
    gross_returns: pd.Series
    net_returns: pd.Series
    cumulative_returns: pd.Series
    portfolio_equity: pd.Series
    weights: pd.DataFrame
    turnover: pd.Series
    transaction_costs: pd.Series


class FactorBacktestEngine:
    """
    Simulates cross-sectional factor execution with monthly or daily rebalancing.
    """

    def __init__(
        self,
        initial_capital: float = 10_000_000.0,
        cost_bps: float = 5.0,
        rebalance_freq: str = "M",
    ):
        self.initial_capital = initial_capital
        self.cost_rate = cost_bps / 10000.0
        self.rebalance_freq = rebalance_freq

    def run(self, prices: pd.DataFrame, target_weights: pd.DataFrame) -> FactorBacktestResult:
        daily_returns = prices.pct_change().fillna(0.0)
        common_idx = daily_returns.index.intersection(target_weights.index)
        daily_returns = daily_returns.loc[common_idx]
        target_weights = target_weights.loc[common_idx]
        
        n_days = len(common_idx)
        n_assets = len(prices.columns)
        
        if self.rebalance_freq == "M":
            dates_s = pd.Series(common_idx, index=common_idx)
            rebalance_dates = set(dates_s.groupby([dates_s.dt.year, dates_s.dt.month]).last().values)
        else:
            rebalance_dates = set(common_idx)
            
        current_w = np.zeros(n_assets)
        actual_weights = np.zeros((n_days, n_assets))
        gross_ret = np.zeros(n_days)
        costs = np.zeros(n_days)
        net_ret = np.zeros(n_days)
        turnover_arr = np.zeros(n_days)
        
        for t in range(n_days):
            dt = common_idx[t]
            r_t = daily_returns.iloc[t].values
            
            # Holding return
            r_gross_t = float(np.sum(current_w * r_t))
            gross_ret[t] = r_gross_t
            
            # Drifted weights
            drifted_w = current_w * (1.0 + r_t) / (1.0 + r_gross_t) if abs(1.0 + r_gross_t) > 1e-8 else current_w
            
            # Rebalance check
            if dt in rebalance_dates or t == 0:
                target_w = target_weights.iloc[t].values
                to_t = float(np.sum(np.abs(target_w - drifted_w)))
                cost_t = to_t * self.cost_rate
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
        turnover_s = pd.Series(turnover_arr, index=common_idx, name="Turnover")
        costs_s = pd.Series(costs, index=common_idx, name="Costs")
        
        cum_ret = (1.0 + net_series).cumprod()
        equity = self.initial_capital * cum_ret
        weights_df = pd.DataFrame(actual_weights, index=common_idx, columns=prices.columns)
        
        return FactorBacktestResult(
            daily_returns=net_series,
            gross_returns=gross_series,
            net_returns=net_series,
            cumulative_returns=cum_ret,
            portfolio_equity=equity,
            weights=weights_df,
            turnover=turnover_s,
            transaction_costs=costs_s,
        )
