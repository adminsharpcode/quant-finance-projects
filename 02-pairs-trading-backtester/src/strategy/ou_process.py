"""Ornstein-Uhlenbeck (OU) Mean-Reversion Process Calibration.

Fits continuous-time Ornstein-Uhlenbeck SDE parameters (theta, mu, sigma) to an
empirical synthetic spread via discrete AR(1) maximum likelihood estimation,
and calculates the theoretical mean-reversion half-life.
"""

from dataclasses import dataclass
from typing import Optional, Tuple
import numpy as np


@dataclass
class OUProcessParams:
    """Fitted Ornstein-Uhlenbeck parameters and diagnostics."""
    theta: float         # Speed of mean reversion (annualized or daily frequency)
    mu: float            # Long-term equilibrium mean
    sigma: float         # Volatility of the spread process
    half_life: float     # Half-life of mean-reversion in time steps (days)
    eq_std: float        # Asymptotic stationary standard deviation: sigma / sqrt(2 * theta)
    is_mean_reverting: bool
    r_squared: float


class OrnsteinUhlenbeckCalibrator:
    """Calibration engine for 1-dimensional continuous Ornstein-Uhlenbeck processes:

        dX_t = theta * (mu - X_t) dt + sigma * dW_t
    """

    def __init__(self, dt: float = 1.0):
        """Initialize calibrator.

        Args:
            dt: Time step size (e.g. 1.0 for daily, 1/252 for annualized).
        """
        self.dt = dt

    def fit(self, spread: np.ndarray) -> OUProcessParams:
        """Calibrate OU parameters using exact discrete Maximum Likelihood / OLS mapping.

        Args:
            spread: 1D array of spread values.

        Returns:
            OUProcessParams containing theta, mu, sigma, half-life, and stationary std.
        """
        x = np.asarray(spread, dtype=float)
        n = len(x)
        if n < 10:
            raise ValueError(f"Insufficient spread length for OU calibration. Got {n}, need >= 10")

        # AR(1) formulation: x_t = a * x_{t-1} + b + epsilon_t
        x_lag = x[:-1]
        x_curr = x[1:]

        # OLS regression of x_curr on x_lag with constant
        design = np.column_stack([np.ones_like(x_lag), x_lag])
        coeffs, _, _, _ = np.linalg.lstsq(design, x_curr, rcond=None)
        b, a = coeffs[0], coeffs[1]

        residuals = x_curr - (b + a * x_lag)
        sse = np.sum(residuals ** 2)
        variance_eps = sse / (n - 2)

        # R^2 of AR(1)
        ss_tot = np.sum((x_curr - np.mean(x_curr)) ** 2)
        r_squared = float(1.0 - (sse / ss_tot)) if ss_tot > 0 else 0.0

        # Check mean-reverting property: requires 0 < a < 1
        if a <= 0.0 or a >= 1.0:
            return OUProcessParams(
                theta=0.0,
                mu=float(np.mean(x)),
                sigma=float(np.std(x, ddof=1)),
                half_life=np.inf,
                eq_std=np.inf,
                is_mean_reverting=False,
                r_squared=r_squared
            )

        # Exact parameter conversions
        theta = -np.log(a) / self.dt
        mu = b / (1.0 - a)
        sigma = np.sqrt(variance_eps * (-2.0 * np.log(a)) / (self.dt * (1.0 - a ** 2)))
        half_life = np.log(2.0) / theta
        eq_std = sigma / np.sqrt(2.0 * theta)

        return OUProcessParams(
            theta=float(theta),
            mu=float(mu),
            sigma=float(sigma),
            half_life=float(max(half_life, 0.5)),
            eq_std=float(eq_std),
            is_mean_reverting=True,
            r_squared=float(r_squared)
        )
