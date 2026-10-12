"""
Institutional Implied Volatility Engine.

Hybrid architecture combining:
1. Vectorized Corrado-Miller rational initial seed
2. Newton-Raphson iteration with gradient bounds
3. Automatic failover to Brent's method for illiquid/deep OTM strikes where Vega -> 0.
"""

from typing import Union
import numpy as np
from scipy.optimize import brentq
from ..models.black_scholes import OptionType, black_scholes_price
from ..greeks.analytical_greeks import vega


def initial_vol_guess(
    price: float,
    S: float,
    K: float,
    T: float,
    r: float,
    q: float = 0.0,
) -> float:
    """
    Corrado-Miller (1996) analytical approximation for initial implied volatility.
    Provides rapid convergence for ATM and near-ATM strikes.
    """
    df_q = np.exp(-q * T)
    df_r = np.exp(-r * T)
    f_diff = S * df_q - K * df_r
    denom = S * df_q + K * df_r

    # Brenner-Subrahmanyam base approximation
    approx = (np.sqrt(2.0 * np.pi / max(T, 1e-4)) * (price - 0.5 * f_diff)) / max(denom, 1e-6)
    return float(np.clip(approx, 0.05, 1.5))


def implied_volatility(
    price: float,
    S: float,
    K: float,
    T: float,
    r: float,
    option_type: Union[OptionType, str] = OptionType.CALL,
    q: float = 0.0,
    is_futures: bool = False,
    max_iter: int = 100,
    tol: float = 1e-7,
    vol_min: float = 0.001,
    vol_max: float = 5.0,
) -> float:
    """
    Solve for Black-Scholes implied volatility given market price.

    Parameters
    ----------
    price : float
        Observed market price (e.g. midpoint of bid-ask or last settle).
    S : float
        Underlying spot or futures price.
    K : float
        Strike price.
    T : float
        Time to maturity in years.
    r : float
        Risk-free rate.
    option_type : OptionType or str
        'call' or 'put'.
    q : float, optional
        Dividend / convenience yield.
    is_futures : bool, optional
        True if underlying is futures (Black-76 model).
    max_iter : int
        Maximum Newton-Raphson iterations.
    tol : float
        Absolute price tolerance.
    vol_min, vol_max : float
        Search bounds for implied volatility.

    Returns
    -------
    float
        Implied volatility (sigma), or np.nan if no arbitrage-free root exists.
    """
    effective_q = r if is_futures else q
    is_call = "call" in str(option_type).lower()

    if T <= 0 or price <= 0:
        return np.nan

    # Arbitrage bounds check
    df_q = np.exp(-effective_q * T)
    df_r = np.exp(-r * T)
    intrinsic = max(S * df_q - K * df_r, 0.0) if is_call else max(K * df_r - S * df_q, 0.0)
    upper_bound = S * df_q if is_call else K * df_r

    if price < intrinsic or price > upper_bound:
        # Violates no-arbitrage bounds
        return np.nan

    # Initial guess
    sigma = initial_vol_guess(price, S, K, T, r, effective_q)

    # 1. Newton-Raphson loop
    for _ in range(max_iter):
        p_est = black_scholes_price(S, K, T, r, sigma, option_type, q=effective_q)
        diff = p_est - price

        if abs(diff) < tol:
            return float(sigma)

        v = vega(S, K, T, r, sigma, q=effective_q, is_futures=is_futures)
        if abs(v) < 1e-8:
            # Vega too small for Newton-Raphson; trigger Brent failover
            break

        step = diff / v
        sigma -= step

        if sigma < vol_min or sigma > vol_max or np.isnan(sigma):
            break

    # 2. Brent's Root-Finding Fallback Routine
    def objective(vol_test: float) -> float:
        return black_scholes_price(S, K, T, r, vol_test, option_type, q=effective_q) - price

    try:
        f_min = objective(vol_min)
        f_max = objective(vol_max)
        if f_min * f_max <= 0:
            return float(brentq(objective, vol_min, vol_max, xtol=tol, maxiter=100))
    except (ValueError, RuntimeError):
        pass

    return np.nan


def implied_volatility_vectorized(
    prices: np.ndarray,
    S: float,
    strikes: np.ndarray,
    T: float,
    r: float,
    option_types: Union[str, np.ndarray] = "call",
    q: float = 0.0,
    is_futures: bool = False,
) -> np.ndarray:
    """
    Vectorized implied volatility extraction across a strike chain.
    """
    prices = np.asarray(prices, dtype=np.float64)
    strikes = np.asarray(strikes, dtype=np.float64)

    if isinstance(option_types, str):
        option_types = np.full_like(strikes, option_types, dtype=object)

    vols = np.empty_like(strikes, dtype=np.float64)
    for i in range(len(strikes)):
        vols[i] = implied_volatility(
            price=prices[i],
            S=S,
            K=strikes[i],
            T=T,
            r=r,
            option_type=option_types[i],
            q=q,
            is_futures=is_futures,
        )
    return vols
