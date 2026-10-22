"""
Market Microstructure & Liquidity Alpha Factors.

Implements:
1. Amihud (2002) Illiquidity Ratio (price impact per dollar volume).
2. Roll (1984) Effective Spread Proxy (from serial price covariance).
3. Corwin-Schultz (2012) High-Low Spread Estimator.
4. Volume Turnover Surprise (abnormal volume vs rolling 20-day baseline).
"""

import numpy as np
import pandas as pd


def compute_amihud_illiquidity(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Amihud (2002) Illiquidity Ratio.
    Measures the absolute return price impact generated per million dollars of trading volume.
    
    Formula:
        ILLIQ_t = (1 / window) * sum_{k=0}^{window-1} ( |R_{t-k}| / (P_{t-k} * Vol_{t-k}) ) * 1e6
    """
    df_temp = df[["ticker", "close", "volume"]].copy()
    df_temp["abs_ret"] = df.groupby("ticker")["close"].pct_change().abs()
    dollar_vol = (df_temp["close"] * df_temp["volume"]).replace(0, np.nan)
    
    df_temp["daily_impact"] = (df_temp["abs_ret"] / dollar_vol) * 1e6

    def _roll_amihud(s: pd.Series) -> pd.Series:
        return s.rolling(window=window, min_periods=int(window * 0.7)).mean()

    return df_temp.groupby("ticker")["daily_impact"].transform(_roll_amihud)


def compute_roll_spread(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Roll (1984) Effective Bid-Ask Spread Proxy.
    Derived from the first-order serial covariance of price increments.
    If markets oscillate between bid and ask bounds, delta P has negative autocorrelation.
    
    Formula:
        s_Roll = 2 * sqrt( max(0, -cov(Delta P_t, Delta P_{t-1})) ) / P_t
    """
    def _calc_roll(sub: pd.DataFrame) -> pd.Series:
        p = sub["close"].values
        dp = np.diff(p, prepend=p[0])
        dp_lag = np.roll(dp, 1)
        dp_lag[0] = 0.0
        n = len(p)
        spread = np.full(n, np.nan)
        
        for i in range(window, n):
            dp_w = dp[i - window : i]
            dpl_w = dp_lag[i - window : i]
            cov = np.cov(dp_w, dpl_w)[0, 1]
            if cov < 0:
                spread[i] = 2.0 * np.sqrt(-cov) / max(p[i], 1e-4)
            else:
                spread[i] = 0.0
                
        return pd.Series(spread, index=sub.index)

    return df.groupby("ticker", group_keys=False).apply(_calc_roll)


def compute_corwin_schultz_spread(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Corwin & Schultz (2012) High-Low Bid-Ask Spread Estimator.
    Exploits the fact that 2-day high-low price ratios reflect both volatility and spread,
    while 1-day high-low reflects primarily volatility.
    """
    def _calc_cs(sub: pd.DataFrame) -> pd.Series:
        h = sub["high"].values
        l = sub["low"].values
        n = len(sub)
        
        h_lag = np.roll(h, 1)
        l_lag = np.roll(l, 1)
        
        # 2-day high and low
        h2 = np.maximum(h, h_lag)
        l2 = np.minimum(l, l_lag)
        
        gamma = (np.log(np.maximum(h2, 1e-6) / np.maximum(l2, 1e-6))) ** 2
        beta = (np.log(np.maximum(h, 1e-6) / np.maximum(l, 1e-6))) ** 2 + \
               (np.log(np.maximum(h_lag, 1e-6) / np.maximum(l_lag, 1e-6))) ** 2
        
        # alpha parameter
        denom = 3.0 - 2.0 * np.sqrt(2.0)
        alpha = (np.sqrt(2.0 * beta) - np.sqrt(beta)) / denom - np.sqrt(gamma / denom)
        
        # Spread = 2 * (e^alpha - 1) / (1 + e^alpha)
        spread = 2.0 * (np.exp(np.maximum(alpha, 0.0)) - 1.0) / (1.0 + np.exp(np.maximum(alpha, 0.0)))
        spread[:2] = 0.0
        
        s_series = pd.Series(spread, index=sub.index)
        return s_series.rolling(window=window, min_periods=int(window * 0.7)).mean()

    return df.groupby("ticker", group_keys=False).apply(_calc_cs)


def compute_volume_surprise(df: pd.DataFrame, short_window: int = 5, long_window: int = 20) -> pd.Series:
    """
    Abnormal volume ratio: short-term rolling average volume / long-term rolling average volume.
    Spikes > 1.5 represent institutional accumulation or distribution order flow.
    """
    def _vol_surprise(group: pd.Series) -> pd.Series:
        v_short = group.rolling(window=short_window, min_periods=3).mean()
        v_long = group.rolling(window=long_window, min_periods=int(long_window * 0.7)).mean()
        return v_short / np.maximum(v_long, 1.0)

    return df.groupby("ticker")["volume"].transform(_vol_surprise)
