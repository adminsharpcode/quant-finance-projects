"""
Factor Turnover, Rank Autocorrelation, and Transaction Cost Drag.

Implements:
1. Cross-Sectional Rank Autocorrelation (Signal Persistence).
2. Portfolio Weight Allocation (Dollar-neutral top/bottom quantiles).
3. Daily Portfolio Turnover: Turnover_t = 0.5 * sum(|w_{i, t} - w_{i, t-1}|).
4. Transaction Drag Estimation under exchange commission and bid-ask half-spread.
"""

from typing import Dict, List, Optional, Tuple, Union
import numpy as np
import pandas as pd
from scipy import stats


def compute_rank_autocorrelation(
    df: pd.DataFrame,
    factor_col: str,
    date_col: str = "date",
    ticker_col: str = "ticker",
    lags: List[int] = [1, 2, 5, 10, 20]
) -> Dict[int, float]:
    """
    Calculate cross-sectional Spearman rank autocorrelation across different time horizons.
    Measures alpha decay and signal stability.
    """
    pivoted = df.pivot(index=date_col, columns=ticker_col, values=factor_col)
    ranked = pivoted.rank(axis=1, pct=True)
    
    decay_curve = {}
    for lag in lags:
        corrs = []
        for i in range(lag, len(ranked)):
            r_t = ranked.iloc[i].values
            r_prev = ranked.iloc[i - lag].values
            valid = (~np.isnan(r_t)) & (~np.isnan(r_prev))
            if np.sum(valid) >= 4:
                corr, _ = stats.spearmanr(r_t[valid], r_prev[valid])
                if not np.isnan(corr):
                    corrs.append(corr)
        decay_curve[lag] = float(np.mean(corrs)) if corrs else 0.0
        
    return decay_curve


def generate_dollar_neutral_weights(
    df: pd.DataFrame,
    alpha_col: str,
    top_pct: float = 0.25,
    bottom_pct: float = 0.25,
    date_col: str = "date",
    ticker_col: str = "ticker"
) -> pd.DataFrame:
    """
    Construct dollar-neutral long-short portfolio weights:
    - Long top top_pct (+1 / N_long)
    - Short bottom bottom_pct (-1 / N_short)
    - Sum(weights) = 0, Sum(|weights|) = 2.0 (100% long, 100% short)
    """
    df_temp = df[[date_col, ticker_col, alpha_col]].dropna().copy()
    
    def _calc_weights(sub: pd.DataFrame) -> pd.Series:
        n = len(sub)
        if n < 4:
            return pd.Series(0.0, index=sub.index)
            
        ranks = sub[alpha_col].rank(pct=True)
        w = pd.Series(0.0, index=sub.index)
        
        long_mask = ranks >= (1.0 - top_pct)
        short_mask = ranks <= bottom_pct
        
        n_long = long_mask.sum()
        n_short = short_mask.sum()
        
        if n_long > 0:
            w[long_mask] = 1.0 / n_long
        if n_short > 0:
            w[short_mask] = -1.0 / n_short
            
        return w

    df_temp["weight"] = df_temp.groupby(date_col).apply(_calc_weights, include_groups=False).values
    pivoted_weights = df_temp.pivot(index=date_col, columns=ticker_col, values="weight").fillna(0.0)
    return pivoted_weights


def compute_portfolio_turnover(weights_df: pd.DataFrame) -> pd.Series:
    """
    Calculate daily portfolio turnover:
    
    Formula:
        Turnover_t = 0.5 * sum_{i} |w_{i, t} - w_{i, t-1}|
    """
    delta_w = weights_df.diff().abs()
    turnover = 0.5 * delta_w.sum(axis=1)
    turnover.iloc[0] = 0.0 # First day initial deployment
    return turnover


def estimate_fee_drag(
    turnover_series: pd.Series,
    cost_per_turn_bps: float = 5.0
) -> Dict[str, float]:
    """
    Estimate transaction cost drag on portfolio returns.
    
    Parameters:
        turnover_series: Daily turnover proportions
        cost_per_turn_bps: Execution cost per unit turned over in basis points (1 bp = 0.0001)
    """
    mean_daily_turnover = float(turnover_series.mean())
    annual_turnover = mean_daily_turnover * 252.0
    daily_drag = mean_daily_turnover * (cost_per_turn_bps * 1e-4)
    annual_fee_drag_pct = annual_turnover * (cost_per_turn_bps * 1e-4) * 100.0
    
    return {
        "mean_daily_turnover": mean_daily_turnover,
        "annualized_turnover": annual_turnover,
        "daily_cost_drag": daily_drag,
        "annual_fee_drag_pct": annual_fee_drag_pct,
        "cost_bps": cost_per_turn_bps,
    }
