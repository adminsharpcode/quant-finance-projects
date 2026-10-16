"""Unit and integration tests for cointegration analysis (CADF & Johansen)."""

import numpy as np
import pytest
from src.analysis.cadf_test import cadf_test, estimate_half_life
from src.analysis.johansen_test import johansen_test


@pytest.fixture
def cointegrated_pair():
    """Generate known cointegrated pair series."""
    np.random.seed(42)
    n = 500
    x = 100.0 + np.cumsum(np.random.normal(0, 1.0, n))
    # Spread is a stationary AR(1) process with theta = 0.1
    spread = np.zeros(n)
    for t in range(1, n):
        spread[t] = 0.85 * spread[t - 1] + np.random.normal(0, 0.5)
    true_beta = 1.5
    true_alpha = 10.0
    y = true_alpha + true_beta * x + spread
    return y, x, spread


@pytest.fixture
def independent_random_walks():
    """Generate two independent I(1) random walks (spurious regression)."""
    np.random.seed(123)
    n = 500
    x = 100.0 + np.cumsum(np.random.normal(0, 1.0, n))
    y = 50.0 + np.cumsum(np.random.normal(0, 1.0, n))
    return y, x


def test_cadf_detects_cointegration(cointegrated_pair):
    """Verify that CADF identifies true cointegration with p < 0.05."""
    y, x, _ = cointegrated_pair
    result = cadf_test(y, x, significance_level=0.05)
    assert result.is_cointegrated
    assert result.p_value < 0.05
    assert np.isclose(result.hedge_ratio, 1.5, atol=0.15)
    assert result.half_life < 20.0  # AR(1) with 0.85 has half-life approx ln(2)/-ln(0.85) = 4.26 days


def test_cadf_rejects_spurious_pair(independent_random_walks):
    """Verify that CADF rejects independent random walks."""
    y, x = independent_random_walks
    result = cadf_test(y, x, significance_level=0.05)
    # p-value for independent random walks should typically exceed 0.05
    assert result.p_value > 0.01


def test_estimate_half_life():
    """Verify half-life calibration on AR(1) process with known parameter."""
    np.random.seed(42)
    phi = 0.80  # theta = -ln(0.80) = 0.2231 -> tau = ln(2)/0.2231 = 3.106
    n = 2000
    spread = np.zeros(n)
    for t in range(1, n):
        spread[t] = phi * spread[t - 1] + np.random.normal(0, 1.0)

    hl = estimate_half_life(spread)
    assert 2.5 <= hl <= 4.0


def test_johansen_multivariate_test(cointegrated_pair):
    """Verify Johansen test detects rank 1 for cointegrated pair."""
    y, x, _ = cointegrated_pair
    data = np.column_stack([y, x])
    res = johansen_test(data, det_order=0, k_ar_diff=1)
    assert res.cointegration_rank >= 1
    assert res.is_cointegrated
    assert len(res.normalized_weights) == 2
    assert res.normalized_weights[0] == 1.0
