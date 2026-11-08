"""
Return calculation utilities and continuous compounding functions.
"""

from typing import Union
import numpy as np
import pandas as pd


def compute_daily_returns(prices: Union[pd.DataFrame, pd.Series], log_returns: bool = False) -> Union[pd.DataFrame, pd.Series]:
    """
    Computes daily percentage or log returns from continuous settlement prices.
    
    Parameters
    ----------
    prices : pd.DataFrame or pd.Series
        Historical price series indexed by date.
    log_returns : bool, default False
        If True, returns ln(P_t / P_{t-1}). If False, returns (P_t - P_{t-1}) / P_{t-1}.
        
    Returns
    -------
    pd.DataFrame or pd.Series
        Aligned returns with the first row filled or dropped.
    """
    if log_returns:
        ret = np.log(prices / prices.shift(1))
    else:
        ret = prices.pct_change()
    return ret.fillna(0.0)


def compute_cumulative_return(returns: Union[pd.DataFrame, pd.Series]) -> Union[pd.DataFrame, pd.Series]:
    """
    Computes cumulative wealth index: W_t = prod(1 + r_t).
    """
    return (1.0 + returns).cumprod()


def compute_excess_returns(
    returns: Union[pd.DataFrame, pd.Series], 
    rf_rate: Union[float, pd.Series] = 0.0
) -> Union[pd.DataFrame, pd.Series]:
    """
    Calculates excess return over the risk-free rate r_f (expressed daily).
    """
    if isinstance(rf_rate, float):
        daily_rf = rf_rate / 252.0
    else:
        daily_rf = rf_rate / 252.0
    return returns - daily_rf
