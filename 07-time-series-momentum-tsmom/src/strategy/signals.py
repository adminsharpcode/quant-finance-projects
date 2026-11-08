"""
Time Series Momentum signal generation modules.
Implements lookback sign signals and multi-horizon trend indicators
per Moskowitz, Ooi, & Pedersen (2012).
"""

from typing import Dict, List, Optional, Union
import numpy as np
import pandas as pd


def compute_lookback_returns(
    prices: pd.DataFrame, 
    lookback_days: int
) -> pd.DataFrame:
    """
    Computes rolling k-day holding period return:
    R_{t-k, t} = (P_t / P_{t-k}) - 1.0
    
    Parameters
    ----------
    prices : pd.DataFrame
        Daily price series indexed by date.
    lookback_days : int
        Number of trading days in lookback window (e.g., 252 for 12 months).
        
    Returns
    -------
    pd.DataFrame
        Rolling past return.
    """
    return prices.pct_change(periods=lookback_days)


def generate_sign_signal(
    lookback_returns: pd.DataFrame, 
    threshold: float = 0.0
) -> pd.DataFrame:
    """
    Extracts binary directional sign signal:
    S_t = +1 if R_{t-k, t} > threshold else -1 (or 0 if NaN)
    
    Parameters
    ----------
    lookback_returns : pd.DataFrame
        Cumulative return over lookback horizon.
    threshold : float, default 0.0
        Hurdle rate / threshold for entering long vs short.
        
    Returns
    -------
    pd.DataFrame
        Signal matrix with values in {-1.0, 0.0, 1.0}.
    """
    signal = np.where(lookback_returns > threshold, 1.0, -1.0)
    # Mask NaNs
    signal = np.where(lookback_returns.isna(), 0.0, signal)
    return pd.DataFrame(signal, index=lookback_returns.index, columns=lookback_returns.columns)


def generate_continuous_signal(
    lookback_returns: pd.DataFrame, 
    volatility: pd.DataFrame, 
    lookback_days: int,
    max_leverage: float = 2.0
) -> pd.DataFrame:
    """
    Computes t-statistic scaled continuous momentum signal:
    z_t = clip( R_{t-k, t} / (sigma_t * sqrt(k / 252)), -max_leverage, max_leverage )
    """
    horizon_vol = volatility * np.sqrt(lookback_days / 252.0)
    z_score = lookback_returns / horizon_vol
    clipped = z_score.clip(lower=-max_leverage, upper=max_leverage)
    return clipped.fillna(0.0)


def generate_multi_horizon_tsmom(
    prices: pd.DataFrame,
    horizons: Optional[Dict[str, int]] = None,
    weights: Optional[Dict[str, float]] = None
) -> pd.DataFrame:
    """
    Generates a blended multi-horizon Time Series Momentum signal.
    Default horizons: 1M (21d), 3M (63d), 6M (126d), 12M (252d) with equal weights.
    """
    if horizons is None:
        horizons = {"1M": 21, "3M": 63, "6M": 126, "12M": 252}
    if weights is None:
        weights = {k: 1.0 / len(horizons) for k in horizons}
        
    blended = pd.DataFrame(0.0, index=prices.index, columns=prices.columns)
    for name, days in horizons.items():
        ret_k = compute_lookback_returns(prices, days)
        sig_k = generate_sign_signal(ret_k)
        blended += sig_k * weights[name]
        
    return blended
