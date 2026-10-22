"""
Price Momentum and Reversal Alpha Factors.

Implements:
1. Short-term Reversal: 1-day and 5-day negative return exposures.
2. Intermediate Dual-Momentum: Multi-month cumulative returns with short-term skip window
   (e.g., 12-1 month or 60-5 day) to prevent microstructure reversal contamination.
3. Residual Momentum: Idiosyncratic return momentum orthogonalized against market benchmark.
4. Moving Average Convergence-Divergence (MACD) normalized spread.
"""

from typing import Optional
import numpy as np
import pandas as pd


def compute_reversal(df: pd.DataFrame, window: int = 5) -> pd.Series:
    """
    Compute short-term reversal factor: negative past return over specified window.
    
    Formula:
        Reversal_t = - (P_t - P_{t-window}) / P_{t-window}
    """
    grouped = df.groupby("ticker")["close"]
    ret = grouped.pct_change(periods=window)
    return -ret


def compute_dual_momentum(
    df: pd.DataFrame, 
    lookback_window: int = 60, 
    skip_window: int = 5
) -> pd.Series:
    """
    Compute intermediate dual-momentum with short-term skip window.
    Captures medium-term trending while eliminating short-term 1-week mean-reverting noise.
    
    Formula:
        DualMom_t = (P_{t - skip} - P_{t - lookback}) / P_{t - lookback}
    """
    def _calc_group(group: pd.Series) -> pd.Series:
        p_lag_skip = group.shift(skip_window)
        p_lag_lookback = group.shift(lookback_window)
        return (p_lag_skip - p_lag_lookback) / p_lag_lookback

    return df.groupby("ticker")["close"].transform(_calc_group)


def compute_residual_momentum(
    df: pd.DataFrame, 
    window: int = 60, 
    skip_window: int = 5
) -> pd.Series:
    """
    Compute idiosyncratic residual momentum (Blitz, Pang, van Vliet, 2011).
    Orthogonalizes daily stock returns against the cross-sectional equal-weighted market return,
    then sums residual returns over the lookback window excluding the skip window.
    """
    df = df.copy()
    if "daily_ret" not in df.columns:
        df["daily_ret"] = df.groupby("ticker")["close"].pct_change()
        
    # Cross-sectional equal-weighted market return per date
    mkt_ret = df.groupby("date")["daily_ret"].transform("mean")
    df["mkt_ret"] = mkt_ret
    
    # Calculate rolling beta & residual
    def _ticker_residual(sub_df: pd.DataFrame) -> pd.Series:
        y = sub_df["daily_ret"].values
        x = sub_df["mkt_ret"].values
        n = len(y)
        residuals = np.full(n, np.nan)
        
        for i in range(window, n):
            y_win = y[i - window : i]
            x_win = x[i - window : i]
            valid = (~np.isnan(y_win)) & (~np.isnan(x_win))
            if np.sum(valid) > 20:
                y_v = y_win[valid]
                x_v = x_win[valid]
                cov = np.cov(x_v, y_v)[0, 1]
                var_x = np.var(x_v)
                beta = cov / var_x if var_x > 1e-12 else 1.0
                alpha = np.mean(y_v) - beta * np.mean(x_v)
                # Current residual
                residuals[i] = y[i] - (alpha + beta * x[i])
                
        # Now roll-sum residuals over [lookback - skip]
        res_series = pd.Series(residuals, index=sub_df.index)
        shifted = res_series.shift(skip_window)
        roll_res = shifted.rolling(window - skip_window, min_periods=int((window - skip_window) * 0.7)).sum()
        return roll_res

    res_mom = df.groupby("ticker", group_keys=False).apply(_ticker_residual)
    return res_mom


def compute_macd_spread(
    df: pd.DataFrame, 
    fast_span: int = 12, 
    slow_span: int = 26
) -> pd.Series:
    """
    Compute normalized Moving Average Convergence Divergence (MACD) spread:
    
    Formula:
        MACD_Spread = (EMA_fast - EMA_slow) / Close
    """
    def _calc_macd(group: pd.Series) -> pd.Series:
        ema_fast = group.ewm(span=fast_span, adjust=False).mean()
        ema_slow = group.ewm(span=slow_span, adjust=False).mean()
        return (ema_fast - ema_slow) / group

    return df.groupby("ticker")["close"].transform(_calc_macd)
