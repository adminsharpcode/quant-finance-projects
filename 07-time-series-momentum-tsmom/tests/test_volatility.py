"""
Unit tests for volatility estimators.
"""

import numpy as np
import pandas as pd
import pytest

from src.estimator.volatility import (
    RollingVolatilityEstimator,
    EWMAVolatilityEstimator,
    estimate_portfolio_volatility,
)


def test_rolling_volatility_calculation():
    # Constant daily returns -> zero variance, should return min_vol floor
    dates = pd.date_range("2020-01-01", periods=100, freq="B")
    returns = pd.Series(0.01, index=dates)
    
    estimator = RollingVolatilityEstimator(window=60, annualization_factor=252.0, min_vol=0.02)
    vol = estimator.estimate(returns)
    
    assert len(vol) == 100
    # From day 30 onwards (min_periods), std is 0.0, clipped to 0.02
    assert vol.iloc[60] == pytest.approx(0.02)


def test_rolling_volatility_known_std():
    np.random.seed(42)
    daily_std = 0.01  # ~15.87% annualized
    returns = pd.Series(np.random.normal(0, daily_std, 500))
    
    estimator = RollingVolatilityEstimator(window=60, annualization_factor=252.0)
    vol = estimator.estimate(returns)
    
    expected_ann = daily_std * np.sqrt(252.0)
    mean_estimated = vol.iloc[60:].mean()
    assert mean_estimated == pytest.approx(expected_ann, rel=0.10)


def test_ewma_volatility():
    np.random.seed(123)
    returns = pd.Series(np.random.normal(0, 0.02, 300))
    
    estimator = EWMAVolatilityEstimator(decay=0.94, min_periods=20, annualization_factor=252.0)
    vol = estimator.estimate(returns)
    
    assert len(vol) == 300
    assert not vol.iloc[25:].isna().any()
    assert (vol.dropna() >= 0.01).all()


def test_portfolio_volatility_quadratic():
    weights = pd.DataFrame([0.5, 0.5])
    cov = pd.DataFrame([[0.04, 0.0], [0.0, 0.04]])  # 20% vol each, uncorrelated
    # Var = 0.25*0.04 + 0.25*0.04 = 0.02 -> Vol = sqrt(0.02) = 0.14142
    port_vol = estimate_portfolio_volatility(weights, cov)
    assert port_vol == pytest.approx(np.sqrt(0.02), rel=1e-4)
