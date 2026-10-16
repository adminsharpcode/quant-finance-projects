"""Cointegrated Augmented Dickey-Fuller (CADF) & Engle-Granger Test.

Implements the Engle-Granger two-step cointegration methodology to verify
whether a linear combination of two non-stationary I(1) asset price series
forms a stationary I(0) mean-reverting spread.
"""

from dataclasses import dataclass
from typing import Optional, Tuple
import numpy as np
import pandas as pd
from statsmodels.tsa.stattools import adfuller, coint


@dataclass
class CADFResult:
    """Container for Engle-Granger CADF cointegration test results."""
    is_cointegrated: bool
    p_value: float
    test_statistic: float
    critical_values: dict
    hedge_ratio: float
    intercept: float
    r_squared: float
    half_life: float
    residuals: np.ndarray
    spread_mean: float
    spread_std: float


def estimate_half_life(series: np.ndarray) -> float:
    """Estimate the mean-reversion half-life of a stationary spread using an AR(1) model.

    The continuous Ornstein-Uhlenbeck process dX_t = theta * (mu - X_t) dt + sigma dW_t
    discretizes to:
        Delta X_t = lambda * X_{t-1} + const + epsilon_t
    where lambda = -(1 - e^{-theta * dt}).
    The half-life of mean-reversion is given by:
        tau_{1/2} = ln(2) / theta = -ln(2) / ln(1 + lambda)

    Args:
        series: 1D numpy array representing the spread series.

    Returns:
        Half-life in trading periods (days). Returns np.inf if non-stationary (lambda >= 0).
    """
    x = np.asarray(series, dtype=float)
    if len(x) < 5:
        return np.inf

    # Lagged series and first difference
    lag_x = x[:-1]
    delta_x = np.diff(x)

    # Regress delta_x on lag_x with intercept
    design_matrix = np.column_stack([np.ones_like(lag_x), lag_x])
    try:
        coeffs, _, _, _ = np.linalg.lstsq(design_matrix, delta_x, rcond=None)
        lambda_val = coeffs[1]
    except Exception:
        return np.inf

    # Check for mean-reverting property (lambda < 0)
    if lambda_val >= 0:
        return np.inf

    phi = 1.0 + lambda_val
    if phi <= 0:
        # Immediate mean reversion within 1 step
        return 1.0

    theta = -np.log(phi)
    if theta <= 0:
        return np.inf

    half_life = np.log(2.0) / theta
    return float(max(half_life, 0.5))


def cadf_test(
    series_y: np.ndarray | pd.Series,
    series_x: np.ndarray | pd.Series,
    significance_level: float = 0.05,
    max_lags: Optional[int] = None
) -> CADFResult:
    """Execute the Engle-Granger two-step Cointegrated ADF test.

    Step 1: OLS regression of y on x: y_t = alpha + beta * x_t + epsilon_t
    Step 2: ADF test on regression residuals: Delta epsilon_t = gamma * epsilon_{t-1} + sum(...)

    Args:
        series_y: Dependent asset price series (Y leg).
        series_x: Independent asset price series (X leg).
        significance_level: Alpha threshold for cointegration (e.g. 0.05 for 95% confidence).
        max_lags: Maximum lag order for ADF test. Default is auto-selected by AIC.

    Returns:
        CADFResult dataclass populated with statistical metrics.
    """
    y = np.asarray(series_y, dtype=float)
    x = np.asarray(series_x, dtype=float)

    if len(y) != len(x):
        raise ValueError(f"Series lengths must match. Got len(y)={len(y)}, len(x)={len(x)}")

    n = len(y)
    if n < 20:
        raise ValueError(f"Insufficient observations for cointegration test. Got {n}, need >= 20")

    # Step 1: OLS regression y ~ alpha + beta * x
    design = np.column_stack([np.ones(n), x])
    params, residuals_sum, rank, s = np.linalg.lstsq(design, y, rcond=None)
    alpha, beta = params[0], params[1]

    # Compute spread / residuals
    fitted = alpha + beta * x
    residuals = y - fitted

    # Coefficient of determination R^2
    ss_tot = np.sum((y - np.mean(y)) ** 2)
    ss_res = np.sum(residuals ** 2)
    r_squared = float(1.0 - (ss_res / ss_tot)) if ss_tot > 0 else 0.0

    # Step 2: Use statsmodels coint (applies MacKinnon critical value adjustments)
    score, p_value, crit_values = coint(y, x, maxlag=max_lags, autolag='aic')

    crit_dict = {
        '1%': float(crit_values[0]),
        '5%': float(crit_values[1]),
        '10%': float(crit_values[2])
    }

    is_cointegrated = bool(p_value < significance_level)
    half_life = estimate_half_life(residuals)

    return CADFResult(
        is_cointegrated=is_cointegrated,
        p_value=float(p_value),
        test_statistic=float(score),
        critical_values=crit_dict,
        hedge_ratio=float(beta),
        intercept=float(alpha),
        r_squared=float(r_squared),
        half_life=float(half_life),
        residuals=residuals,
        spread_mean=float(np.mean(residuals)),
        spread_std=float(np.std(residuals, ddof=1))
    )
