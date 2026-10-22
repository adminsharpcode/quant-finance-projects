"""
Unit tests for MAD winsorization, z-scoring, and cross-sectional factor neutralization.
"""

import pytest
import numpy as np
import pandas as pd
from src.preprocessing.winsorization import (
    mad_winsorize_series,
    cross_sectional_mad_winsorize,
    cross_sectional_zscore,
    cross_sectional_rank_normalize,
)
from src.preprocessing.neutralization import (
    neutralize_factor_vector,
    neutralize_cross_section,
    gram_schmidt_orthogonalization,
)


def test_mad_winsorize_clips_outliers():
    # 95 normal samples + 5 extreme outliers
    np.random.seed(42)
    s = pd.Series(np.random.normal(0, 1, 100))
    s.iloc[0] = 50.0 # massive outlier
    s.iloc[1] = -50.0 # massive outlier
    
    winsorized = mad_winsorize_series(s, n_mads=3.0)
    
    assert winsorized.max() < 10.0
    assert winsorized.min() > -10.0
    assert winsorized.max() > 2.0


def test_cross_sectional_zscore():
    dates = ["2024-01-01"] * 10 + ["2024-01-02"] * 10
    vals = np.random.uniform(10, 100, 20)
    df = pd.DataFrame({"date": dates, "factor": vals})
    
    df_z = cross_sectional_zscore(df, factor_cols=["factor"], date_col="date")
    
    # Each date cross-section should have mean ~ 0 and std ~ 1
    for dt, group in df_z.groupby("date"):
        assert np.isclose(group["factor"].mean(), 0.0, atol=1e-7)
        assert np.isclose(group["factor"].std(), 1.0, atol=1e-7)


def test_factor_neutralization_orthogonal_to_beta():
    # Synthetic universe of 20 stocks
    np.random.seed(42)
    n = 20
    betas = np.random.uniform(0.5, 1.8, n)
    sectors = np.random.choice(["Tech", "Fin", "Health"], size=n)
    
    # Raw factor with heavy beta exposure
    raw_factor = 2.5 * betas + np.random.normal(0, 0.5, n)
    
    # Neutralize
    df = pd.DataFrame({
        "date": ["2024-01-01"] * n,
        "ticker": [f"S_{i}" for i in range(n)],
        "sector": sectors,
        "beta": betas,
        "raw_factor": raw_factor,
    })
    
    df_neut = neutralize_cross_section(
        df,
        factor_cols=["raw_factor"],
        risk_cols=["beta"],
        sector_col="sector",
        date_col="date",
        re_standardize=True
    )
    
    # Correlation with beta after neutralization should be virtually zero
    corr = np.corrcoef(df_neut["raw_factor"].values, betas)[0, 1]
    assert abs(corr) < 0.10, f"Residual correlation with beta is {corr:.4f}, expected ~0"


def test_gram_schmidt_orthogonality():
    np.random.seed(42)
    X = np.random.randn(50, 4)
    Q = gram_schmidt_orthogonalization(X)
    
    # Q^T Q should be close to identity
    qtq = Q.T @ Q
    identity = np.eye(4)
    assert np.allclose(qtq, identity, atol=1e-6)
