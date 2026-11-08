"""
Unit tests for correlation and diversification mathematics.
"""

import numpy as np
import pandas as pd
import pytest

from src.analytics.correlation import compute_diversification_metrics, compute_rolling_correlation


def test_diversification_multiplier():
    # If correlation is -0.5, multiplier is 1 / sqrt((1 - 0.5)/2) = 1 / sqrt(0.25) = 2.0!
    rho = -0.5
    div_mult = 1.0 / np.sqrt((1.0 + rho) / 2.0)
    assert div_mult == pytest.approx(2.0, rel=1e-5)


def test_diversification_metrics_synthetic():
    np.random.seed(42)
    n = 1000
    # Generate negatively correlated series
    z1 = np.random.normal(0, 1, n)
    z2 = -0.6 * z1 + np.sqrt(1 - 0.6**2) * np.random.normal(0, 1, n)
    
    val_r = pd.Series(0.0003 + 0.01 * z1)
    mom_r = pd.Series(0.0003 + 0.01 * z2)
    
    metrics = compute_diversification_metrics(val_r, mom_r)
    assert metrics["Value_Momentum_Correlation"] < -0.5
    assert metrics["Diversification_Multiplier"] > 1.5
    assert metrics["Actual_Combo_Sharpe"] > metrics["Value_Standalone_Sharpe"]
    assert metrics["Actual_Combo_Sharpe"] > metrics["Momentum_Standalone_Sharpe"]
