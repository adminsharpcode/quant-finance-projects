"""
Cox-Ross-Rubinstein (CRR) and Jarrow-Rudd Binomial Lattice Engines.

Implements backward induction dynamic programming for both European and American
options on spot assets and futures contracts. Fully handles the Snell envelope
early-exercise boundary condition.
"""

from enum import Enum
from typing import Dict, Optional, Tuple, Union
import numpy as np
from .black_scholes import OptionType


class ExerciseStyle(str, Enum):
    EUROPEAN = "european"
    AMERICAN = "american"


class LatticeMethod(str, Enum):
    CRR = "crr"          # Cox-Ross-Rubinstein (u * d = 1)
    JR = "jr"            # Jarrow-Rudd (equal probabilities p = 0.5)


def binomial_tree_price(
    S: float,
    K: float,
    T: float,
    r: float,
    sigma: float,
    option_type: Union[OptionType, str] = OptionType.CALL,
    exercise_style: Union[ExerciseStyle, str] = ExerciseStyle.AMERICAN,
    n_steps: int = 500,
    q: float = 0.0,
    is_futures: bool = False,
    method: LatticeMethod = LatticeMethod.CRR,
) -> float:
    """
    Price European or American options via Binomial Tree Lattice.

    Parameters
    ----------
    S : float
        Current spot or futures price.
    K : float
        Strike price.
    T : float
        Time to expiration in years.
    r : float
        Continuously compounded risk-free rate.
    sigma : float
        Volatility of underlying asset.
    option_type : OptionType or str
        'call' or 'put'.
    exercise_style : ExerciseStyle or str
        'american' (early exercise permitted) or 'european'.
    n_steps : int
        Number of time discretization steps (higher = more accurate, O(N^2)).
    q : float, optional
        Dividend / convenience yield (ignored if is_futures is True).
    is_futures : bool, optional
        If True, underlying is a futures contract (CME/COMEX Black-76 style).
    method : LatticeMethod, optional
        Lattice parameterization (CRR or JR).

    Returns
    -------
    float
        Option price at t=0 node.
    """
    if T <= 0:
        is_call = "call" in str(option_type).lower()
        return max(S - K, 0.0) if is_call else max(K - S, 0.0)

    n_steps = max(int(n_steps), 2)
    dt = T / n_steps
    is_call = "call" in str(option_type).lower()
    is_american = "american" in str(exercise_style).lower()

    effective_q = r if is_futures else q

    if method == LatticeMethod.CRR:
        u = np.exp(sigma * np.sqrt(dt))
        d = 1.0 / u
        p = (np.exp((r - effective_q) * dt) - d) / (u - d)
    else:  # Jarrow-Rudd
        drift = (r - effective_q - 0.5 * sigma**2) * dt
        u = np.exp(drift + sigma * np.sqrt(dt))
        d = np.exp(drift - sigma * np.sqrt(dt))
        p = 0.5

    # Numerical safeguard for risk-neutral probability
    if p < 0.0 or p > 1.0:
        p = np.clip(p, 0.0, 1.0)

    discount = np.exp(-r * dt)

    # Vectorized terminal asset prices at step N
    # j = 0, 1, ..., N representing number of down/up moves
    # S_T = S * u^(j) * d^(N-j)
    j = np.arange(n_steps + 1)
    if method == LatticeMethod.CRR:
        underlying_terminal = S * (u ** j) * (d ** (n_steps - j))
    else:
        underlying_terminal = S * (u ** j) * (d ** (n_steps - j))

    # Terminal payoffs
    if is_call:
        values = np.maximum(underlying_terminal - K, 0.0)
    else:
        values = np.maximum(K - underlying_terminal, 0.0)

    # Backward induction
    for i in range(n_steps - 1, -1, -1):
        # Continuation value: discounted expectation
        values = discount * (p * values[1:] + (1.0 - p) * values[:-1])

        if is_american:
            # Asset prices at current step i
            j_curr = np.arange(i + 1)
            underlying_curr = S * (u ** j_curr) * (d ** (i - j_curr))
            if is_call:
                intrinsic = np.maximum(underlying_curr - K, 0.0)
            else:
                intrinsic = np.maximum(K - underlying_curr, 0.0)
            values = np.maximum(values, intrinsic)

    return float(values[0])


def binomial_early_exercise_premium(
    S: float,
    K: float,
    T: float,
    r: float,
    sigma: float,
    option_type: Union[OptionType, str] = OptionType.PUT,
    n_steps: int = 500,
    q: float = 0.0,
    is_futures: bool = False,
) -> Dict[str, float]:
    """
    Quantify American early exercise premium:
        Premium = Price_American - Price_European

    Especially prominent in deep ITM American Puts or Futures Calls.
    """
    p_american = binomial_tree_price(
        S, K, T, r, sigma, option_type, ExerciseStyle.AMERICAN, n_steps, q, is_futures
    )
    p_european = binomial_tree_price(
        S, K, T, r, sigma, option_type, ExerciseStyle.EUROPEAN, n_steps, q, is_futures
    )
    premium = max(p_american - p_european, 0.0)

    return {
        "american_price": p_american,
        "european_price": p_european,
        "early_exercise_premium": premium,
        "premium_percentage": (premium / p_european * 100.0) if p_european > 0 else 0.0,
    }
