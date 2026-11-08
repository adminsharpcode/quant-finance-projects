"""
Unit tests for portfolio sizing and risk budgeting.
"""

import numpy as np
import pandas as pd
import pytest

from src.portfolio.sizing import VolatilityTargetingSizer
from src.portfolio.risk_budget import RiskBudgetAnalyzer


def test_inverse_volatility_allocation():
    dates = pd.date_range("2020-01-01", periods=10, freq="B")
    signals = pd.DataFrame({"LowVol": [1.0]*10, "HighVol": [1.0]*10}, index=dates)
    # LowVol has 10% vol, HighVol has 20% vol
    volatilities = pd.DataFrame({"LowVol": [0.10]*10, "HighVol": [0.20]*10}, index=dates)
    
    sizer = VolatilityTargetingSizer(target_vol=0.10, portfolio_vol_scaling=False)
    weights = sizer.compute_weights(signals, volatilities)
    
    # LowVol should have 2x the weight of HighVol
    w_low = weights["LowVol"].iloc[0]
    w_high = weights["HighVol"].iloc[0]
    assert w_low == pytest.approx(2.0 * w_high, rel=1e-4)


def test_gross_leverage_capping():
    dates = pd.date_range("2020-01-01", periods=5, freq="B")
    signals = pd.DataFrame({"A": [1.0]*5, "B": [1.0]*5}, index=dates)
    # Extremely low volatility -> would imply huge leverage
    volatilities = pd.DataFrame({"A": [0.01]*5, "B": [0.01]*5}, index=dates)
    
    max_lev = 3.0
    sizer = VolatilityTargetingSizer(target_vol=0.15, max_gross_leverage=max_lev, portfolio_vol_scaling=False)
    weights = sizer.compute_weights(signals, volatilities)
    
    total_leverage = weights.abs().sum(axis=1)
    assert (total_leverage <= max_lev + 1e-6).all()


def test_marginal_risk_contribution():
    analyzer = RiskBudgetAnalyzer()
    weights = np.array([0.5, 0.5])
    cov = np.array([[0.04, 0.0], [0.0, 0.04]])
    
    rc = analyzer.compute_marginal_risk_contributions(weights, cov)
    # Equal risk contribution for symmetric uncorrelated assets
    assert rc[0] == pytest.approx(0.5, rel=1e-4)
    assert rc[1] == pytest.approx(0.5, rel=1e-4)
