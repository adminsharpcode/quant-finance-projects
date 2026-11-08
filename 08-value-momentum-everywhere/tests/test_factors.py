"""
Unit tests for Value and Momentum factor generation.
"""

import numpy as np
import pandas as pd
import pytest

from src.factors.momentum import MomentumFactor
from src.factors.value import ValueFactor


def test_momentum_factor_computation():
    dates = pd.date_range("2020-01-01", periods=300, freq="B")
    # Asset A steadily grows, Asset B is flat
    prices = pd.DataFrame({
        "A": np.linspace(100.0, 200.0, 300),
        "B": np.full(300, 100.0)
    }, index=dates)
    
    mom = MomentumFactor(lookback_days=252, skip_days=21)
    scores = mom.compute_scores(prices)
    
    # At t=280: Asset A past return > 0, Asset B past return == 0
    assert scores["A"].iloc[280] > 0.0
    assert scores["B"].iloc[280] == pytest.approx(0.0, abs=1e-5)
    
    weights = mom.compute_weights(prices, gross_leverage=1.0)
    # A should be long (+0.5), B should be short (-0.5)
    assert weights["A"].iloc[280] == pytest.approx(0.5, rel=1e-4)
    assert weights["B"].iloc[280] == pytest.approx(-0.5, rel=1e-4)


def test_value_factor_reversal():
    dates = pd.date_range("2015-01-01", periods=1400, freq="B")
    # Asset A declined over 5 years (cheap!), Asset B rose over 5 years (expensive!)
    prices = pd.DataFrame({
        "Cheap": np.linspace(200.0, 100.0, 1400),
        "Expensive": np.linspace(100.0, 300.0, 1400)
    }, index=dates)
    
    val = ValueFactor(mode="reversal", reversal_lookback_days=1260, skip_days=21)
    scores = val.compute_scores(prices)
    
    # Cheap should have positive score (past return was negative, -(-ret) > 0)
    assert scores["Cheap"].iloc[1350] > 0.0
    assert scores["Expensive"].iloc[1350] < 0.0
    
    weights = val.compute_weights(prices, gross_leverage=1.0)
    assert weights["Cheap"].iloc[1350] == pytest.approx(0.5, rel=1e-4)
    assert weights["Expensive"].iloc[1350] == pytest.approx(-0.5, rel=1e-4)
