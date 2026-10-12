"""
Black-Scholes-Merton and Black-76 Analytical Pricing Engines.

Supports both Spot underlying assets (with continuous dividend / convenience yield)
and Futures underlying assets (Black-76 model for CME/COMEX contracts).
All functions support both scalar floats and vectorized NumPy arrays.
"""

from enum import Enum
from typing import Tuple, Union
import numpy as np
from scipy.stats import norm


class OptionType(str, Enum):
    CALL = "call"
    PUT = "put"


def d1_d2(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    q: Union[float, np.ndarray] = 0.0,
) -> Tuple[Union[float, np.ndarray], Union[float, np.ndarray]]:
    """
    Compute standard Black-Scholes normalized coordinates d1 and d2.

    Parameters
    ----------
    S : float or np.ndarray
        Underlying spot price (or forward price F if r=q=0).
    K : float or np.ndarray
        Strike price.
    T : float or np.ndarray
        Time to maturity in years (annualized).
    r : float or np.ndarray
        Continuously compounded risk-free rate.
    sigma : float or np.ndarray
        Annualized volatility (sigma > 0).
    q : float or np.ndarray, optional
        Continuous dividend or convenience yield (default 0.0).

    Returns
    -------
    Tuple[d1, d2] : Tuple of float or np.ndarray
    """
    S = np.maximum(np.asarray(S, dtype=np.float64), 1e-12)
    K = np.maximum(np.asarray(K, dtype=np.float64), 1e-12)
    T = np.maximum(np.asarray(T, dtype=np.float64), 1e-12)
    sigma = np.maximum(np.asarray(sigma, dtype=np.float64), 1e-12)
    r = np.asarray(r, dtype=np.float64)
    q = np.asarray(q, dtype=np.float64)

    vol_sqrt_t = sigma * np.sqrt(T)
    d1 = (np.log(S / K) + (r - q + 0.5 * sigma**2) * T) / vol_sqrt_t
    d2 = d1 - vol_sqrt_t

    if np.ndim(d1) == 0:
        return float(d1), float(d2)
    return d1, d2


def black_scholes_price(
    S: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    option_type: Union[OptionType, str] = OptionType.CALL,
    q: Union[float, np.ndarray] = 0.0,
) -> Union[float, np.ndarray]:
    """
    Calculate the European option price using the Black-Scholes-Merton model.

    Formula:
        C = S * exp(-q*T) * N(d1) - K * exp(-r*T) * N(d2)
        P = K * exp(-r*T) * N(-d2) - S * exp(-q*T) * N(-d1)

    Parameters
    ----------
    S : float or np.ndarray
        Current spot price of underlying asset.
    K : float or np.ndarray
        Strike price.
    T : float or np.ndarray
        Time to expiration in years. If T <= 0, returns intrinsic value.
    r : float or np.ndarray
        Annualized risk-free interest rate.
    sigma : float or np.ndarray
        Annualized volatility of underlying returns.
    option_type : OptionType or str
        'call' or 'put'.
    q : float or np.ndarray, optional
        Continuous dividend or foreign interest rate / convenience yield.

    Returns
    -------
    float or np.ndarray
        Analytical Black-Scholes option price.
    """
    opt_str = str(option_type).lower()
    is_call = "call" in opt_str

    S_arr = np.asarray(S, dtype=np.float64)
    K_arr = np.asarray(K, dtype=np.float64)
    T_arr = np.asarray(T, dtype=np.float64)

    # Handle expired options (T <= 0)
    is_scalar = np.ndim(S_arr) == 0 and np.ndim(K_arr) == 0 and np.ndim(T_arr) == 0
    if is_scalar and T_arr <= 0:
        intrinsic = np.maximum(S_arr - K_arr, 0.0) if is_call else np.maximum(K_arr - S_arr, 0.0)
        return float(intrinsic)

    d1, d2 = d1_d2(S_arr, K_arr, T_arr, r, sigma, q)

    df_q = np.exp(-q * T_arr)
    df_r = np.exp(-r * T_arr)

    if is_call:
        price = S_arr * df_q * norm.cdf(d1) - K_arr * df_r * norm.cdf(d2)
    else:
        price = K_arr * df_r * norm.cdf(-d2) - S_arr * df_q * norm.cdf(-d1)

    # Intrinsic floor check
    if is_call:
        intrinsic = np.maximum(S_arr * df_q - K_arr * df_r, 0.0)
    else:
        intrinsic = np.maximum(K_arr * df_r - S_arr * df_q, 0.0)
    price = np.maximum(price, intrinsic)

    if is_scalar:
        return float(price)
    return price


def black_76_price(
    F: Union[float, np.ndarray],
    K: Union[float, np.ndarray],
    T: Union[float, np.ndarray],
    r: Union[float, np.ndarray],
    sigma: Union[float, np.ndarray],
    option_type: Union[OptionType, str] = OptionType.CALL,
) -> Union[float, np.ndarray]:
    """
    Calculate the European option price on Futures using Fischer Black's 1976 model.
    Standard pricing benchmark for CME and COMEX futures options (e.g. Gold GC, Crude CL).

    Formula:
        d1 = [ln(F/K) + 0.5 * sigma^2 * T] / (sigma * sqrt(T))
        d2 = d1 - sigma * sqrt(T)
        C = exp(-r*T) * [F * N(d1) - K * N(d2)]
        P = exp(-r*T) * [K * N(-d2) - F * N(-d1)]

    Parameters
    ----------
    F : float or np.ndarray
        Underlying futures contract price.
    K : float or np.ndarray
        Strike price.
    T : float or np.ndarray
        Time to expiration in years.
    r : float or np.ndarray
        Annualized risk-free discount rate.
    sigma : float or np.ndarray
        Annualized implied volatility of the futures price.
    option_type : OptionType or str
        'call' or 'put'.

    Returns
    -------
    float or np.ndarray
        Black-76 option price.
    """
    # In Black-76, the underlying is the forward/futures price F, and spot discount factor applies
    # Equivalent to Merton model with spot S = F and dividend yield q = r.
    return black_scholes_price(
        S=F,
        K=K,
        T=T,
        r=r,
        sigma=sigma,
        option_type=option_type,
        q=r,
    )


def verify_put_call_parity(
    call_price: float,
    put_price: float,
    S: float,
    K: float,
    T: float,
    r: float,
    q: float = 0.0,
    tolerance: float = 1e-4,
) -> bool:
    """
    Verify European Put-Call Parity:
        C - P = S * exp(-q*T) - K * exp(-r*T)

    Returns True if disparity is within numerical tolerance.
    """
    lhs = call_price - put_price
    rhs = S * np.exp(-q * T) - K * np.exp(-r * T)
    return abs(lhs - rhs) < tolerance
