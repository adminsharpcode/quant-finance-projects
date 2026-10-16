"""Johansen Cointegration Test Engine.

Implements the multivariate Johansen cointegration procedure based on Vector
Autoregressive (VAR) error-correction representation. Computes both the
Trace test statistic and Maximum Eigenvalue statistic, along with normalized
cointegrating eigenvectors for multi-asset baskets and pairs.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional
import numpy as np
import pandas as pd
from statsmodels.tsa.vector_ar.vecm import coint_johansen


@dataclass
class JohansenResult:
    """Container for Johansen multivariate cointegration test results."""
    cointegration_rank: int
    is_cointegrated: bool
    trace_statistics: np.ndarray
    trace_critical_values: np.ndarray  # [90%, 95%, 99%]
    max_eigen_statistics: np.ndarray
    max_eigen_critical_values: np.ndarray
    eigenvalues: np.ndarray
    eigenvectors: np.ndarray  # raw cointegrating vectors
    normalized_weights: np.ndarray  # normalized so weight on asset 1 is 1.0


def johansen_test(
    data: np.ndarray | pd.DataFrame,
    det_order: int = 0,
    k_ar_diff: int = 1,
    significance_index: int = 1  # 0: 90%, 1: 95%, 2: 99%
) -> JohansenResult:
    """Perform the Johansen cointegration test.

    Args:
        data: (T x K) matrix of price series, where K >= 2.
        det_order: Deterministic trend order.
            -1: No deterministic term
             0: Constant term inside cointegrating relation (standard)
             1: Linear trend
        k_ar_diff: Number of lagged differences in VECM (p - 1). Default 1.
        significance_index: Index for critical values (0=90%, 1=95%, 2=99%). Default 1 (95%).

    Returns:
        JohansenResult dataclass with test statistics, rank, and normalized eigenvector.
    """
    if isinstance(data, pd.DataFrame):
        arr = data.values
    else:
        arr = np.asarray(data, dtype=float)

    if arr.ndim != 2 or arr.shape[1] < 2:
        raise ValueError(f"Johansen test requires a 2D matrix with >= 2 series. Got shape {arr.shape}")

    t_obs, k_assets = arr.shape
    if t_obs < 30:
        raise ValueError(f"Insufficient observations for Johansen test. Got {t_obs}, need >= 30")

    # Run statsmodels coint_johansen
    res = coint_johansen(arr, det_order=det_order, k_ar_diff=k_ar_diff)

    trace_stats = res.lr1
    trace_crit = res.cvt
    max_eigen_stats = res.lr2
    max_eigen_crit = res.cvm
    eigenvalues = res.eig
    eigenvectors = res.evec

    # Determine cointegrating rank (number of cointegrating vectors at chosen sig level)
    # Testing H0: r <= 0, r <= 1, ...
    rank = 0
    for r in range(k_assets):
        if trace_stats[r] > trace_crit[r, significance_index]:
            rank = r + 1
        else:
            break

    is_coint = rank > 0

    # Extract primary cointegrating vector (corresponding to largest eigenvalue)
    primary_vec = eigenvectors[:, 0]
    # Normalize with respect to the first asset
    if abs(primary_vec[0]) > 1e-12:
        normalized_weights = primary_vec / primary_vec[0]
    else:
        normalized_weights = primary_vec

    return JohansenResult(
        cointegration_rank=rank,
        is_cointegrated=is_coint,
        trace_statistics=trace_stats,
        trace_critical_values=trace_crit,
        max_eigen_statistics=max_eigen_stats,
        max_eigen_critical_values=max_eigen_crit,
        eigenvalues=eigenvalues,
        eigenvectors=eigenvectors,
        normalized_weights=normalized_weights
    )
