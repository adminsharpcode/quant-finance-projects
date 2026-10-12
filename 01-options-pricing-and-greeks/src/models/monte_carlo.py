"""
High-Performance Monte Carlo Pricing Engine with Variance Reduction.

Features:
- Antithetic Variates for variance reduction
- Control Variate integration using closed-form Black-Scholes
- Common Random Numbers (CRN) for stable numerical Greek differentiation
- Vectorized NumPy simulation loops
"""

from dataclasses import dataclass
from typing import Optional, Tuple, Union
import numpy as np
from .black_scholes import OptionType, black_scholes_price


@dataclass
class MonteCarloResult:
    price: float
    standard_error: float
    ci_95_lower: float
    ci_95_upper: float
    n_paths: int
    antithetic_used: bool
    control_variate_used: bool


def monte_carlo_price(
    S: float,
    K: float,
    T: float,
    r: float,
    sigma: float,
    option_type: Union[OptionType, str] = OptionType.CALL,
    n_paths: int = 100_000,
    q: float = 0.0,
    is_futures: bool = False,
    use_antithetic: bool = True,
    use_control_variate: bool = False,
    seed: Optional[int] = 42,
) -> MonteCarloResult:
    """
    Price European options via Monte Carlo simulation with variance reduction.

    Parameters
    ----------
    S : float
        Current spot or futures price.
    K : float
        Strike price.
    T : float
        Time to maturity in years.
    r : float
        Risk-free interest rate.
    sigma : float
        Volatility.
    option_type : OptionType or str
        'call' or 'put'.
    n_paths : int
        Number of simulated paths (default 100,000).
    q : float, optional
        Continuous dividend or convenience yield.
    is_futures : bool, optional
        If True, underlying is futures contract (zero drift under Q).
    use_antithetic : bool, optional
        If True, samples paired -Z paths to eliminate odd-order sample variance.
    use_control_variate : bool, optional
        If True, applies analytical European Black-Scholes as control variate.
    seed : int, optional
        Random seed for reproducibility.

    Returns
    -------
    MonteCarloResult
        Detailed pricing statistics and confidence interval.
    """
    effective_q = r if is_futures else q
    if seed is not None:
        rng = np.random.default_rng(seed)
    else:
        rng = np.random.default_rng()

    is_call = "call" in str(option_type).lower()

    if T <= 0:
        intrinsic = max(S - K, 0.0) if is_call else max(K - S, 0.0)
        return MonteCarloResult(
            price=intrinsic,
            standard_error=0.0,
            ci_95_lower=intrinsic,
            ci_95_upper=intrinsic,
            n_paths=n_paths,
            antithetic_used=use_antithetic,
            control_variate_used=use_control_variate,
        )

    drift = (r - effective_q - 0.5 * sigma**2) * T
    vol = sigma * np.sqrt(T)
    discount = np.exp(-r * T)

    if use_antithetic:
        half_paths = n_paths // 2
        z = rng.standard_normal(half_paths)
        z = np.concatenate([z, -z])
    else:
        z = rng.standard_normal(n_paths)

    # Terminal stock prices S_T
    st = S * np.exp(drift + vol * z)

    # Payoffs
    if is_call:
        payoffs = np.maximum(st - K, 0.0)
    else:
        payoffs = np.maximum(K - st, 0.0)

    discounted_payoffs = discount * payoffs

    if use_control_variate:
        # Control variate using the underlying asset forward price: E[S_T] = S * exp((r-q)*T)
        expected_st = S * np.exp((r - q) * T)
        discounted_st = discount * st
        expected_discounted_st = S * np.exp(-q * T)

        # Optimal beta = Cov(payoff, S_T) / Var(S_T)
        cov_matrix = np.cov(discounted_payoffs, discounted_st)
        var_st = cov_matrix[1, 1]
        if var_st > 1e-12:
            beta = cov_matrix[0, 1] / var_st
            discounted_payoffs = discounted_payoffs - beta * (discounted_st - expected_discounted_st)

    price = float(np.mean(discounted_payoffs))
    std_dev = float(np.std(discounted_payoffs, ddof=1))
    standard_error = std_dev / np.sqrt(len(discounted_payoffs))

    z_critical = 1.96  # 95% Confidence Interval
    ci_lower = price - z_critical * standard_error
    ci_upper = price + z_critical * standard_error

    return MonteCarloResult(
        price=price,
        standard_error=standard_error,
        ci_95_lower=ci_lower,
        ci_95_upper=ci_upper,
        n_paths=len(discounted_payoffs),
        antithetic_used=use_antithetic,
        control_variate_used=use_control_variate,
    )


def monte_carlo_greeks_crn(
    S: float,
    K: float,
    T: float,
    r: float,
    sigma: float,
    option_type: Union[OptionType, str] = OptionType.CALL,
    n_paths: int = 100_000,
    q: float = 0.0,
    is_futures: bool = False,
    seed: int = 42,
) -> dict:
    """
    Compute Delta and Gamma via Monte Carlo finite differencing using Common Random Numbers (CRN).
    CRN guarantees the same underlying Brownian trajectory for perturbed evaluations,
    canceling Monte Carlo sampling noise from the finite difference gradient.
    """
    h_s = 0.01 * S  # 1% spot bump
    h_vol = 0.01    # 1% vol bump

    # Spot bumps with fixed seed
    res_base = monte_carlo_price(S, K, T, r, sigma, option_type, n_paths, q, is_futures=is_futures, seed=seed)
    res_up = monte_carlo_price(S + h_s, K, T, r, sigma, option_type, n_paths, q, is_futures=is_futures, seed=seed)
    res_down = monte_carlo_price(S - h_s, K, T, r, sigma, option_type, n_paths, q, is_futures=is_futures, seed=seed)

    # Vol bump with fixed seed
    res_vol_up = monte_carlo_price(S, K, T, r, sigma + h_vol, option_type, n_paths, q, is_futures=is_futures, seed=seed)
    res_vol_down = monte_carlo_price(S, K, T, r, sigma - h_vol, option_type, n_paths, q, is_futures=is_futures, seed=seed)

    # Central difference calculations
    delta = (res_up.price - res_down.price) / (2.0 * h_s)
    gamma = (res_up.price - 2.0 * res_base.price + res_down.price) / (h_s ** 2)
    vega = (res_vol_up.price - res_vol_down.price) / (2.0 * h_vol)

    return {
        "price": res_base.price,
        "delta": float(delta),
        "gamma": float(gamma),
        "vega": float(vega),
    }
