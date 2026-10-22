"""
Robust Intraday Volatility Estimators.

Implements continuous-diffusion estimators utilizing high, low, open, and close prices:
1. Close-to-Close Standard Volatility (Benchmark)
2. Parkinson (1980) Extreme Value Volatility
3. Garman-Klass (1980) OHLC Volatility
4. Yang-Zhang (2000) Overnight Jump-Robust Volatility
5. Volatility Term Structure / Ratio (Short-term vs Medium-term)
"""

import numpy as np
import pandas as pd


def compute_historical_volatility(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Standard annualized close-to-close sample standard deviation.
    """
    def _calc_hist(group: pd.Series) -> pd.Series:
        log_ret = np.log(group / group.shift(1))
        return log_ret.rolling(window=window, min_periods=int(window * 0.7)).std() * np.sqrt(252.0)

    return df.groupby("ticker")["close"].transform(_calc_hist)


def compute_parkinson_volatility(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Parkinson (1980) High-Low Range Volatility Estimator.
    Under geometric Brownian motion, Parkinson volatility is ~5x more efficient
    than close-to-close volatility.
    
    Formula:
        sigma_P = sqrt( (252 / (4 * ln(2) * window)) * sum( (ln(High / Low))^2 ) )
    """
    hl_ratio_sq = (np.log(df["high"] / df["low"])) ** 2
    factor = 252.0 / (4.0 * np.log(2.0))

    def _calc_parkinson(group: pd.Series) -> pd.Series:
        roll_sum = group.rolling(window=window, min_periods=int(window * 0.7)).mean()
        return np.sqrt(roll_sum * factor)

    return df.groupby("ticker", group_keys=False)[hl_ratio_sq.name or 0].apply(
        lambda s: np.sqrt(s.rolling(window=window, min_periods=int(window * 0.7)).mean() * factor)
    ) if hasattr(hl_ratio_sq, 'name') and hl_ratio_sq.name else pd.Series(
        df.assign(_hl_sq=hl_ratio_sq).groupby("ticker")["_hl_sq"].transform(
            lambda s: np.sqrt(s.rolling(window=window, min_periods=int(window * 0.7)).mean() * factor)
        ),
        index=df.index
    )


def compute_garman_klass_volatility(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Garman-Klass (1980) Volatility Estimator.
    Combines High, Low, Open, and Close to achieve ~8x efficiency over close-to-close.
    
    Formula:
        term1 = 0.5 * (ln(High / Low))^2
        term2 = (2 * ln(2) - 1) * (ln(Close / Open))^2
        sigma_GK = sqrt( 252 * mean(term1 - term2) )
    """
    log_hl = np.log(df["high"] / df["low"])
    log_co = np.log(df["close"] / df["open"])
    
    gk_component = 0.5 * (log_hl ** 2) - (2.0 * np.log(2.0) - 1.0) * (log_co ** 2)
    
    df_temp = df[["ticker"]].copy()
    df_temp["gk_comp"] = gk_component
    
    def _rolling_gk(s: pd.Series) -> pd.Series:
        roll_mean = s.rolling(window=window, min_periods=int(window * 0.7)).mean()
        # Ensure non-negative under discrete approximations
        return np.sqrt(np.maximum(roll_mean, 0.0) * 252.0)

    return df_temp.groupby("ticker")["gk_comp"].transform(_rolling_gk)


def compute_yang_zhang_volatility(df: pd.DataFrame, window: int = 20) -> pd.Series:
    """
    Yang-Zhang (2000) Continuous Volatility Estimator.
    The minimum-variance unbiased estimator incorporating overnight jump risk,
    intraday open-to-close drift, and Rogers-Satchell high-low dynamics.
    
    Formula:
        sigma_YZ^2 = sigma_open^2 + k * sigma_close^2 + (1 - k) * sigma_RS^2
        k = 0.34 / (1.34 + (window + 1) / (window - 1))
    """
    k = 0.34 / (1.34 + (window + 1.0) / (window - 1.0))

    def _calc_yz(sub: pd.DataFrame) -> pd.Series:
        o = sub["open"].values
        h = sub["high"].values
        l = sub["low"].values
        c = sub["close"].values
        n = len(sub)
        
        # Overnight return: ln(Open_t / Close_{t-1})
        o_lag = np.roll(c, 1)
        o_lag[0] = o[0]
        r_open = np.log(np.maximum(o, 1e-8) / np.maximum(o_lag, 1e-8))
        r_open[0] = 0.0
        
        # Open-to-close return: ln(Close_t / Open_t)
        r_close = np.log(np.maximum(c, 1e-8) / np.maximum(o, 1e-8))
        
        # Rogers-Satchell component:
        # ln(H/C)*ln(H/O) + ln(L/C)*ln(L/O)
        rs = (np.log(np.maximum(h, 1e-8) / np.maximum(c, 1e-8)) * np.log(np.maximum(h, 1e-8) / np.maximum(o, 1e-8)) +
              np.log(np.maximum(l, 1e-8) / np.maximum(c, 1e-8)) * np.log(np.maximum(l, 1e-8) / np.maximum(o, 1e-8)))
        
        s_open = pd.Series(r_open, index=sub.index).rolling(window=window, min_periods=int(window * 0.7)).var(ddof=1)
        s_close = pd.Series(r_close, index=sub.index).rolling(window=window, min_periods=int(window * 0.7)).var(ddof=1)
        s_rs = pd.Series(rs, index=sub.index).rolling(window=window, min_periods=int(window * 0.7)).mean()
        
        yz_var = s_open + k * s_close + (1.0 - k) * s_rs
        yz_vol = np.sqrt(np.maximum(yz_var, 0.0) * 252.0)
        return yz_vol

    return df.groupby("ticker", group_keys=False).apply(_calc_yz)


def compute_volatility_ratio(df: pd.DataFrame, short_window: int = 5, long_window: int = 20) -> pd.Series:
    """
    Term-structure volatility ratio: short-term Garman-Klass / long-term Garman-Klass.
    Values > 1.0 indicate impending volatility compression or shock expansion.
    """
    gk_short = compute_garman_klass_volatility(df, window=short_window)
    gk_long = compute_garman_klass_volatility(df, window=long_window)
    return gk_short / np.maximum(gk_long, 1e-6)
