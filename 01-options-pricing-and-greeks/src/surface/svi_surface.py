"""
Gatheral's Stochastic Volatility Inspired (SVI) Surface Calibration.

Implements Raw SVI parameterization:
    w(k) = a + b * (rho * (k - m) + sqrt((k - m)^2 + sigma^2))
where:
    k = ln(K / F) (log-moneyness)
    w = total implied variance (sigma^2 * T)

Includes:
- Robust non-linear least squares calibration with Cauchy loss function
- Strict mathematical no-arbitrage boundary validation (Gatheral & Jacquier conditions)
- Lee's moment formula wing constraints
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
import numpy as np
from scipy.optimize import least_squares


@dataclass
class SVIParameters:
    a: float      # Overall variance level
    b: float      # Asymptotic angle (wing slope)
    rho: float    # Skew asymmetry (-1 < rho < 1)
    m: float      # Horizontal shift (minimum vertex location)
    sigma: float  # Curvature / smoothness parameter
    T: float      # Expiration slice tenor
    rmse: float   # Root Mean Squared Error of fit


def svi_total_variance(
    k: np.ndarray,
    a: float,
    b: float,
    rho: float,
    m: float,
    sigma: float,
) -> np.ndarray:
    """
    Compute Raw SVI total implied variance w(k) = sigma^2 * T.
    """
    diff = k - m
    return a + b * (rho * diff + np.sqrt(diff**2 + sigma**2))


def svi_implied_vol(
    k: np.ndarray,
    params: SVIParameters,
) -> np.ndarray:
    """
    Convert SVI total variance w(k) to annualized implied volatility sigma(k) = sqrt(w(k) / T).
    """
    w = svi_total_variance(k, params.a, params.b, params.rho, params.m, params.sigma)
    w = np.maximum(w, 1e-8)
    return np.sqrt(w / max(params.T, 1e-4))


def arbitrage_free_check(params: SVIParameters, k_grid: Optional[np.ndarray] = None) -> Dict[str, bool]:
    """
    Verify Gatheral & Jacquier (2014) arbitrage-free conditions:
    1. b >= 0
    2. |rho| < 1
    3. sigma > 0
    4. a + b * sigma * sqrt(1 - rho^2) >= 0 (strictly non-negative variance)
    5. b * (1 + |rho|) < 4 (no butterfly arbitrage at asymptotic wings)
    6. g(k) >= 0 everywhere on k_grid (no butterfly arbitrage / non-negative risk-neutral density)
    """
    cond1 = params.b >= 0.0
    cond2 = abs(params.rho) < 1.0
    cond3 = params.sigma > 0.0
    cond4 = (params.a + params.b * params.sigma * np.sqrt(max(1.0 - params.rho**2, 0.0))) >= 0.0
    cond5 = (params.b * (1.0 + abs(params.rho))) < 4.0

    # Butterfly density condition g(k) >= 0 over traded strike moneyness domain
    if k_grid is None:
        k_grid = np.linspace(-0.15, 0.15, 150)

    diff = k_grid - params.m
    hypot = np.sqrt(diff**2 + params.sigma**2)

    w = params.a + params.b * (params.rho * diff + hypot)
    w_prime = params.b * (params.rho + diff / hypot)
    w_double_prime = params.b * (params.sigma**2 / (hypot**3))

    # Gatheral's density formula g(k):
    # g(k) = (1 - k*w'/(2w))^2 - (w'^2 / 4)*(1/w + 1/4) + w''/2
    term1 = (1.0 - (k_grid * w_prime) / (2.0 * np.maximum(w, 1e-8))) ** 2
    term2 = ((w_prime**2) / 4.0) * (1.0 / np.maximum(w, 1e-8) + 0.25)
    term3 = 0.5 * w_double_prime
    g_k = term1 - term2 + term3

    cond6 = bool(np.all(g_k >= -1e-6))

    all_passed = cond1 and cond2 and cond3 and cond4 and cond5 and cond6

    return {
        "b_positive": cond1,
        "rho_bounded": cond2,
        "sigma_positive": cond3,
        "variance_positive": cond4,
        "lee_wing_bound": cond5,
        "no_butterfly_arbitrage": cond6,
        "is_arbitrage_free": all_passed,
    }


def calibrate_svi(
    strikes: np.ndarray,
    implied_vols: np.ndarray,
    F: float,
    T: float,
) -> SVIParameters:
    """
    Calibrate Raw SVI parameters to market implied volatilities for a specific tenor slice.

    Uses bounded Non-Linear Least Squares with Cauchy loss (resilient to quote outliers).

    Parameters
    ----------
    strikes : np.ndarray
        Array of option strike prices.
    implied_vols : np.ndarray
        Array of observed market implied volatilities.
    F : float
        Forward / futures price for this tenor.
    T : float
        Time to expiration in years.

    Returns
    -------
    SVIParameters
        Calibrated parameters (a, b, rho, m, sigma) and goodness of fit RMSE.
    """
    strikes = np.asarray(strikes, dtype=np.float64)
    implied_vols = np.asarray(implied_vols, dtype=np.float64)

    # Filter invalid/NaN entries
    mask = (~np.isnan(implied_vols)) & (implied_vols > 0.005) & (strikes > 0.0)
    strikes = strikes[mask]
    implied_vols = implied_vols[mask]

    if len(strikes) < 5:
        # Fallback to defaults if insufficient data
        atm_vol = float(np.mean(implied_vols)) if len(implied_vols) > 0 else 0.20
        return SVIParameters(
            a=atm_vol**2 * T * 0.5,
            b=0.1,
            rho=-0.2,
            m=0.0,
            sigma=0.1,
            T=T,
            rmse=0.0,
        )

    # Compute log-moneyness k = ln(K / F)
    k = np.log(strikes / F)
    # Target total implied variance w_mkt = sigma_imp^2 * T
    w_mkt = (implied_vols ** 2) * T

    atm_w = np.interp(0.0, k, w_mkt)

    # Initial parameter guess: [a, b, rho, m, sigma]
    x0 = [
        max(0.5 * atm_w, 1e-4),  # a
        0.15,                    # b
        -0.3,                    # rho (typical commodity / equity negative skew)
        0.0,                     # m
        0.1,                     # sigma
    ]

    # Parameter bounds:
    # a: [-0.5, 2.0]
    # b: [0.001, 2.0]
    # rho: [-0.99, 0.99]
    # m: [min(k), max(k)]
    # sigma: [0.001, 1.5]
    bounds = (
        [0.0, 0.001, -0.99, min(k) - 0.2, 0.001],
        [2.0, 1.5, 0.99, max(k) + 0.2, 1.5],
    )

    def residuals(params: np.ndarray) -> np.ndarray:
        a_val, b_val, rho_val, m_val, sigma_val = params
        w_model = svi_total_variance(k, a_val, b_val, rho_val, m_val, sigma_val)
        res = (w_model - w_mkt) * 100.0

        # Regularization: penalize butterfly density violation g(k) < 0
        diff = k - m_val
        hypot = np.sqrt(diff**2 + sigma_val**2)
        w_p = b_val * (rho_val + diff / hypot)
        w_pp = b_val * (sigma_val**2 / (hypot**3))
        g_k = (1.0 - (k * w_p) / (2.0 * np.maximum(w_model, 1e-8)))**2 - ((w_p**2) / 4.0) * (1.0 / np.maximum(w_model, 1e-8) + 0.25) + 0.5 * w_pp
        violation = np.maximum(-g_k, 0.0)
        return np.concatenate([res, violation * 200.0])

    res = least_squares(
        residuals,
        x0=x0,
        bounds=bounds,
        loss="cauchy",  # robust loss function suppresses bad prints / stale quotes
        ftol=1e-8,
        xtol=1e-8,
        max_nfev=1000,
    )

    a, b, rho, m, sigma = res.x
    w_pred = svi_total_variance(k, a, b, rho, m, sigma)
    vol_pred = np.sqrt(np.maximum(w_pred, 1e-8) / T)
    rmse = float(np.sqrt(np.mean((vol_pred - implied_vols) ** 2)))

    return SVIParameters(
        a=float(a),
        b=float(b),
        rho=float(rho),
        m=float(m),
        sigma=float(sigma),
        T=float(T),
        rmse=rmse,
    )


class SVIModel:
    """Multi-slice Volatility Surface calibrated via Gatheral's SVI model."""

    def __init__(self):
        self.slices: Dict[float, SVIParameters] = {}

    def fit_surface(
        self,
        expiries: List[float],
        strikes_list: List[np.ndarray],
        implied_vols_list: List[np.ndarray],
        forwards: List[float],
    ) -> None:
        """Calibrate SVI parameters across multiple expiration slices."""
        for T, strikes, vols, F in zip(expiries, strikes_list, implied_vols_list, forwards):
            params = calibrate_svi(strikes, vols, F, T)
            self.slices[T] = params

    def get_vol(self, K: float, F: float, T: float) -> float:
        """
        Interpolate implied volatility at arbitrary strike K, forward F, and tenor T.
        Interpolates total implied variance linearly across adjacent slices.
        """
        if not self.slices:
            return 0.20

        expiries = sorted(self.slices.keys())
        k = np.log(K / F)

        if T in self.slices:
            return float(svi_implied_vol(np.array([k]), self.slices[T])[0])

        if T <= expiries[0]:
            return float(svi_implied_vol(np.array([k]), self.slices[expiries[0]])[0])
        if T >= expiries[-1]:
            return float(svi_implied_vol(np.array([k]), self.slices[expiries[-1]])[0])

        # Find bounding tenors T1 < T < T2
        t1, t2 = expiries[0], expiries[-1]
        for i in range(len(expiries) - 1):
            if expiries[i] <= T <= expiries[i + 1]:
                t1, t2 = expiries[i], expiries[i + 1]
                break

        w1 = svi_total_variance(k, self.slices[t1].a, self.slices[t1].b, self.slices[t1].rho, self.slices[t1].m, self.slices[t1].sigma)
        w2 = svi_total_variance(k, self.slices[t2].a, self.slices[t2].b, self.slices[t2].rho, self.slices[t2].m, self.slices[t2].sigma)

        # Linear interpolation in total variance w
        weight = (T - t1) / (t2 - t1)
        w_interp = (1.0 - weight) * w1 + weight * w2
        return float(np.sqrt(max(w_interp, 1e-8) / max(T, 1e-4)))
