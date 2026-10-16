"""Unit and integration tests for dynamic Kalman filter state-space tracker."""

import numpy as np
import pytest
from src.state_space.kalman_filter import KalmanHedgeTracker


def test_kalman_static_beta_convergence():
    """Verify that Kalman filter converges to true fixed beta and alpha."""
    np.random.seed(42)
    n = 300
    x = 50.0 + np.cumsum(np.random.normal(0, 0.5, n))
    true_alpha = 4.0
    true_beta = 1.8
    y = true_alpha + true_beta * x + np.random.normal(0, 0.2, n)

    kf = KalmanHedgeTracker(delta=1e-4, r_var=1e-3, initial_beta=1.0)
    res = kf.filter_series(y, x)

    # By step 300, beta estimate is close to true_beta and fitted prediction matches y
    assert np.isclose(res.beta_history[-1], true_beta, atol=0.10)
    y_pred = res.alpha_history[-1] + res.beta_history[-1] * x[-1]
    assert np.isclose(y_pred, y[-1], atol=0.5)


def test_kalman_dynamic_beta_tracking():
    """Verify that Kalman filter adapts to a regime shift in market beta."""
    np.random.seed(99)
    n = 400
    x = 100.0 + np.cumsum(np.random.normal(0, 0.5, n))
    # Beta shifts from 1.2 to 2.2 halfway through
    betas_true = np.ones(n) * 1.2
    betas_true[200:] = 2.2
    y = 5.0 + betas_true * x + np.random.normal(0, 0.3, n)

    kf = KalmanHedgeTracker(delta=1e-3, r_var=1e-2)
    res = kf.filter_series(y, x)

    # Initial regime
    assert np.isclose(res.beta_history[180], 1.2, atol=0.15)
    # Post-shift regime
    assert np.isclose(res.beta_history[380], 2.2, atol=0.20)


def test_kalman_step_matches_series():
    """Verify that sequential step yields identical output to batch filter_series."""
    np.random.seed(7)
    n = 50
    x = np.random.uniform(50, 100, n)
    y = 2.0 + 1.5 * x + np.random.normal(0, 0.5, n)

    kf_batch = KalmanHedgeTracker(delta=1e-4, r_var=1e-3)
    res_batch = kf_batch.filter_series(y, x, rolling_window=None)

    kf_step = KalmanHedgeTracker(delta=1e-4, r_var=1e-3)
    for i in range(n):
        a, b, e, s, z = kf_step.step(y[i], x[i])
        assert np.isclose(a, res_batch.alpha_history[i])
        assert np.isclose(b, res_batch.beta_history[i])
        assert np.isclose(e, res_batch.spread_history[i])
        assert np.isclose(z, res_batch.zscore_history[i])


def test_covariance_matrix_positive_definite():
    """Verify Joseph form guarantees positive semi-definiteness of state covariance."""
    kf = KalmanHedgeTracker()
    for _ in range(50):
        kf.step(np.random.uniform(90, 110), np.random.uniform(40, 60))
        evals = np.linalg.eigvals(kf.p_matrix)
        assert np.all(evals >= -1e-12)
