"""
Hagan's SABR (Stochastic Alpha Beta Rho) Volatility Model.

Standard benchmark model across commodity derivatives desks (CME/COMEX) and fixed income.
Calculates closed-form asymptotic Black-76 implied volatility and calibrates parameters
(alpha, rho, nu) with fixed or floating beta.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional
import numpy as np
from scipy.optimize import least_squares


@dataclass
class SABRParameters:
    alpha: float  # Instantaneous volatility level
    beta: float   # Backbone elasticity (typically 0.5 for commodities or 1.0 for lognormal)
    rho: float    # Correlation between forward price and volatility
    nu: float     # Volatility of volatility (smile curvature)
    T: float      # Tenor in years
    rmse: float   # Root Mean Squared Error


def sabr_implied_vol(
    F: float,
    K: np.ndarray,
    T: float,
    alpha: float,
    beta: float,
    rho: float,
    nu: float,
) -> np.ndarray:
    """
    Hagan et al. (2002) asymptotic implied volatility formula for SABR model.

    Parameters
    ----------
    F : float
        Forward price.
    K : np.ndarray
        Array of strikes.
    T : float
        Time to maturity in years.
    alpha : float
        Initial volatility (alpha > 0).
    beta : float
        CEV elasticity exponent (0 <= beta <= 1).
    rho : float
        Correlation (-1 < rho < 1).
    nu : float
        Vol of vol (nu >= 0).

    Returns
    -------
    np.ndarray
        Black-76 equivalent implied volatility.
    """
    K = np.asarray(K, dtype=np.float64)
    F = float(max(F, 1e-6))
    T = float(max(T, 1e-4))
    alpha = float(max(alpha, 1e-6))
    nu = float(max(nu, 1e-6))
    rho = float(np.clip(rho, -0.999, 0.999))

    vols = np.empty_like(K, dtype=np.float64)

    one_minus_beta = 1.0 - beta

    for i, strike in enumerate(K):
        strike = max(float(strike), 1e-6)

        # ATM special case
        if abs(F - strike) < 1e-8:
            term1 = alpha / (F ** one_minus_beta)
            term2 = 1.0 + (
                (one_minus_beta**2 / 24.0) * (alpha**2 / (F ** (2.0 * one_minus_beta)))
                + (0.25 * rho * beta * nu * alpha) / (F ** one_minus_beta)
                + ((2.0 - 3.0 * rho**2) / 24.0) * (nu**2)
            ) * T
            vols[i] = term1 * term2
            continue

        log_fk = np.log(F / strike)
        fk_mid = F * strike
        fk_pow = fk_mid ** (one_minus_beta * 0.5)

        # Expansion denominator
        denom = fk_pow * (
            1.0
            + (one_minus_beta**2 / 24.0) * (log_fk**2)
            + (one_minus_beta**4 / 1920.0) * (log_fk**4)
        )

        z = (nu / alpha) * fk_pow * log_fk
        arg = (np.sqrt(1.0 - 2.0 * rho * z + z**2) + z - rho) / (1.0 - rho)
        if arg <= 0.0 or np.isnan(arg):
            x_z = 1.0
        else:
            x_z = np.log(arg)

        # z / x(z) ratio with L'Hopital limit at z -> 0
        z_over_xz = 1.0 if abs(z) < 1e-8 else (z / x_z)

        # Second-order time expansion factor
        factor = 1.0 + (
            (one_minus_beta**2 / 24.0) * (alpha**2 / (fk_mid ** one_minus_beta))
            + (0.25 * rho * beta * nu * alpha) / fk_pow
            + ((2.0 - 3.0 * rho**2) / 24.0) * (nu**2)
        ) * T

        sigma = (alpha / denom) * z_over_xz * factor
        vols[i] = max(float(sigma), 0.001)

    return vols


def calibrate_sabr(
    strikes: np.ndarray,
    implied_vols: np.ndarray,
    F: float,
    T: float,
    beta: float = 0.5,
) -> SABRParameters:
    """
    Calibrate SABR parameters (alpha, rho, nu) to market implied volatility slice.

    Parameters
    ----------
    strikes : np.ndarray
        Array of strikes.
    implied_vols : np.ndarray
        Observed implied vols.
    F : float
        Forward price.
    T : float
        Maturity in years.
    beta : float, optional
        Pre-set elasticity exponent (default 0.5 for commodities).

    Returns
    -------
    SABRParameters
    """
    strikes = np.asarray(strikes, dtype=np.float64)
    implied_vols = np.asarray(implied_vols, dtype=np.float64)

    mask = (~np.isnan(implied_vols)) & (implied_vols > 0.005) & (strikes > 0.0)
    strikes = strikes[mask]
    implied_vols = implied_vols[mask]

    if len(strikes) < 3:
        atm_vol = float(np.mean(implied_vols)) if len(implied_vols) > 0 else 0.25
        return SABRParameters(
            alpha=atm_vol * (F ** (1.0 - beta)),
            beta=beta,
            rho=-0.2,
            nu=0.4,
            T=T,
            rmse=0.0,
        )

    # Find approximate ATM vol to initialize alpha
    atm_idx = np.argmin(np.abs(strikes - F))
    atm_vol = implied_vols[atm_idx]
    init_alpha = atm_vol * (F ** (1.0 - beta))

    # Initial guess [alpha, rho, nu]
    x0 = [init_alpha, -0.2, 0.4]

    # Bounds: alpha > 0, -0.999 < rho < 0.999, nu >= 0.001
    bounds = (
        [1e-4, -0.99, 1e-4],
        [5.0, 0.99, 5.0],
    )

    def residuals(params: np.ndarray) -> np.ndarray:
        alpha_val, rho_val, nu_val = params
        model_vols = sabr_implied_vol(F, strikes, T, alpha_val, beta, rho_val, nu_val)
        return (model_vols - implied_vols) * 100.0

    res = least_squares(
        residuals,
        x0=x0,
        bounds=bounds,
        loss="soft_l1",
        ftol=1e-8,
        xtol=1e-8,
        max_nfev=800,
    )

    alpha, rho, nu = res.x
    pred_vols = sabr_implied_vol(F, strikes, T, alpha, beta, rho, nu)
    rmse = float(np.sqrt(np.mean((pred_vols - implied_vols) ** 2)))

    return SABRParameters(
        alpha=float(alpha),
        beta=float(beta),
        rho=float(rho),
        nu=float(nu),
        T=float(T),
        rmse=rmse,
    )


class SABRModel:
    """Multi-tenor SABR model manager."""

    def __init__(self, beta: float = 0.5):
        self.beta = beta
        self.slices: Dict[float, SABRParameters] = {}

    def fit_surface(
        self,
        expiries: List[float],
        strikes_list: List[np.ndarray],
        implied_vols_list: List[np.ndarray],
        forwards: List[float],
    ) -> None:
        """Calibrate across multiple expiration slices."""
        for T, strikes, vols, F in zip(expiries, strikes_list, implied_vols_list, forwards):
            params = calibrate_sabr(strikes, vols, F, T, beta=self.beta)
            self.slices[T] = params

    def get_vol(self, K: float, F: float, T: float) -> float:
        """Interpolate SABR implied volatility."""
        if not self.slices:
            return 0.25
        expiries = sorted(self.slices.keys())
        nearest_t = min(expiries, key=lambda t: abs(t - T))
        params = self.slices[nearest_t]
        return float(sabr_implied_vol(F, np.array([K]), T, params.alpha, params.beta, params.rho, params.nu)[0])
