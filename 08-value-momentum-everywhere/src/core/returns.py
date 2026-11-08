"""
Return calculations and skip-month window transformations.
"""

from typing import Union
import numpy as np
import pandas as pd


def compute_daily_returns(prices: pd.DataFrame) -> pd.DataFrame:
    """Computes daily percentage returns."""
    return prices.pct_change().fillna(0.0)


def compute_skip_month_return(
    prices: pd.DataFrame, 
    lookback_start: int, 
    skip_days: int = 21
) -> pd.DataFrame:
    """
    Computes cumulative return from (t - lookback_start) to (t - skip_days).
    Asness et al. (2013) use skip_days = 1 month (21 days) to prevent 1-month bid-ask bounce / reversal.
    
    Formula: R = (P_{t - skip_days} / P_{t - lookback_start}) - 1.0
    """
    p_end = prices.shift(skip_days)
    p_start = prices.shift(lookback_start)
    ret = (p_end / p_start) - 1.0
    return ret
