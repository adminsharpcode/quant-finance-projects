"""
High-Precision Analytical Greeks Engine.

Computes 1st order (Delta, Vega, Theta, Rho), 2nd order (Gamma, Vanna, Volga/Vomma),
and higher-order risk sensitivities under Black-Scholes-Merton and Black-76 (Futures).
Fully supports vectorized NumPy inputs and scalar calculations.
"""

from dataclasses import dataclass
from typing import Dict, Union
import numpy as np
from scipy.stats import norm
from ..models.black_scholes import OptionType, d1_d2


@dataclass
class GreeksResult:
    price: Union[float, np.ndarray]
    delta: Union[float, np.ndarray]
    gamma: Union[float, np.ndarray]
    vega: Union[float, np.ndarray]          # Per 1.0 unit vol change
    vega_1pct: Union[float, np.ndarray]     # Per 1% (0.01) vol change
    theta: Union[float, np.ndarray]         # Annualized decay
    theta_1day: Union[float, np.ndarray]    # Per 1 calendar day decay (annual / 365)
    rho: Union[float, np.ndarray]           # Per 1.0 unit rate change
    rho_1pct: Union[float, np.ndarray]      # Per 100 bps (0.01) rate change
    vanna: Union[float, np.ndarray]         # dDelta/dVol or dVega/dSpot
    volga: Union[float, np.ndarray]         # dVega/dVol


def delta(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    option_type: Union[OptionType, str] = OptionType.CALL,
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Delta: dV / dS (or dV / dF for futures)."""
    effective_q = r if is_futures else q
    d1, _ = d1_d2(S, K, T, r, sigma, effective_q)
    df_q = np.exp(-effective_q * np.asarray(T, dtype=np.float64))

    is_call = "call" in str(option_type).lower()
    if is_call:
        res = df_q * norm.cdf(d1)
    else:
        res = -df_q * norm.cdf(-d1)

    return float(res) if np.ndim(res) == 0 else res


def gamma(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Gamma: d^2V / dS^2."""
    effective_q = r if is_futures else q
    d1, _ = d1_d2(S, K, T, r, sigma, effective_q)
    S_arr = np.maximum(np.asarray(S, dtype=np.float64), 1e-12)
    T_arr = np.maximum(np.asarray(T, dtype=np.float64), 1e-12)
    sigma_arr = np.maximum(np.asarray(sigma, dtype=np.float64), 1e-12)

    df_q = np.exp(-effective_q * T_arr)
    denom = S_arr * sigma_arr * np.sqrt(T_arr)
    res = (df_q * norm.pdf(d1)) / denom

    return float(res) if np.ndim(res) == 0 else res


def vega(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Vega: dV / d_sigma (raw, per 1.0 unit vol)."""
    effective_q = r if is_futures else q
    d1, _ = d1_d2(S, K, T, r, sigma, effective_q)
    S_arr = np.asarray(S, dtype=np.float64)
    T_arr = np.maximum(np.asarray(T, dtype=np.float64), 1e-12)

    df_q = np.exp(-effective_q * T_arr)
    res = S_arr * df_q * np.sqrt(T_arr) * norm.pdf(d1)

    return float(res) if np.ndim(res) == 0 else res


def theta(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    option_type: Union[OptionType, str] = OptionType.CALL,
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Theta: dV / dt (annualized calendar decay)."""
    effective_q = r if is_futures else q
    d1, d2 = d1_d2(S, K, T, r, sigma, effective_q)
    S_arr = np.asarray(S, dtype=np.float64)
    K_arr = np.asarray(K, dtype=np.float64)
    T_arr = np.maximum(np.asarray(T, dtype=np.float64), 1e-12)
    sigma_arr = np.maximum(np.asarray(sigma, dtype=np.float64), 1e-12)
    r_arr = np.asarray(r, dtype=np.float64)
    q_arr = np.asarray(effective_q, dtype=np.float64)

    df_q = np.exp(-q_arr * T_arr)
    df_r = np.exp(-r_arr * T_arr)

    term1 = -(S_arr * df_q * norm.pdf(d1) * sigma_arr) / (2.0 * np.sqrt(T_arr))

    is_call = "call" in str(option_type).lower()
    if is_call:
        term2 = -r_arr * K_arr * df_r * norm.cdf(d2) + q_arr * S_arr * df_q * norm.cdf(d1)
    else:
        term2 = r_arr * K_arr * df_r * norm.cdf(-d2) - q_arr * S_arr * df_q * norm.cdf(-d1)

    res = term1 + term2
    return float(res) if np.ndim(res) == 0 else res


def rho(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    option_type: Union[OptionType, str] = OptionType.CALL,
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Rho: dV / dr."""
    effective_q = r if is_futures else q
    _, d2 = d1_d2(S, K, T, r, sigma, effective_q)
    K_arr = np.asarray(K, dtype=np.float64)
    T_arr = np.asarray(T, dtype=np.float64)
    r_arr = np.asarray(r, dtype=np.float64)
    df_r = np.exp(-r_arr * T_arr)

    is_call = "call" in str(option_type).lower()
    if is_futures:
        # For futures, rho = -T * OptionPrice
        from ..models.black_scholes import black_76_price
        p = black_76_price(S, K, T, r, sigma, option_type)
        res = -T_arr * p
    else:
        if is_call:
            res = K_arr * T_arr * df_r * norm.cdf(d2)
        else:
            res = -K_arr * T_arr * df_r * norm.cdf(-d2)

    return float(res) if np.ndim(res) == 0 else res


def vanna(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Vanna: d^2V / (dS d_sigma) = dDelta / d_sigma = dVega / dS."""
    effective_q = r if is_futures else q
    d1, d2 = d1_d2(S, K, T, r, sigma, effective_q)
    T_arr = np.maximum(np.asarray(T, dtype=np.float64), 1e-12)
    sigma_arr = np.maximum(np.asarray(sigma, dtype=np.float64), 1e-12)
    df_q = np.exp(-effective_q * T_arr)

    res = -df_q * norm.pdf(d1) * (d2 / sigma_arr)
    return float(res) if np.ndim(res) == 0 else res


def volga(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> Union[float, np.ndarray]:
    """Calculate Volga (Vomma): d^2V / d_sigma^2 = dVega / d_sigma."""
    effective_q = r if is_futures else q
    d1, d2 = d1_d2(S, K, T, r, sigma, effective_q)
    sigma_arr = np.maximum(np.asarray(sigma, dtype=np.float64), 1e-12)
    v = vega(S, K, T, r, sigma, q=effective_q, is_futures=False)

    res = v * (d1 * d2) / sigma_arr
    return float(res) if np.ndim(res) == 0 else res


def calculate_all_greeks(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    option_type: Union[OptionType, str] = OptionType.CALL,
    q: Union[float, np.ndarray] = 0.0,
    is_futures: bool = False,
) -> GreeksResult:
    """
    Calculate full suite of 1st, 2nd, and cross-order Greeks in a single pass.
    """
    effective_q = r if is_futures else q
    from ..models.black_scholes import black_scholes_price

    p = black_scholes_price(S, K, T, r, sigma, option_type, q=effective_q)
    d = delta(S, K, T, r, sigma, option_type, q=effective_q, is_futures=is_futures)
    g = gamma(S, K, T, r, sigma, q=effective_q, is_futures=is_futures)
    v = vega(S, K, T, r, sigma, q=effective_q, is_futures=is_futures)
    th = theta(S, K, T, r, sigma, option_type, q=effective_q, is_futures=is_futures)
    rh = rho(S, K, T, r, sigma, option_type, q=effective_q, is_futures=is_futures)
    van = vanna(S, K, T, r, sigma, q=effective_q, is_futures=is_futures)
    vol = volga(S, K, T, r, sigma, q=effective_q, is_futures=is_futures)

    return GreeksResult(
        price=p,
        delta=d,
        gamma=g,
        vega=v,
        vega_1pct=v * 0.01,
        theta=th,
        theta_1day=th / 365.0,
        rho=rh,
        rho_1pct=rh * 0.01,
        vanna=van,
        volga=vol,
    )
