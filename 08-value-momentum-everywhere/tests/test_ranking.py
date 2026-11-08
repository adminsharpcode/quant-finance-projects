"""
Unit tests for cross-sectional ranking and dollar-neutral weight construction.
"""

import numpy as np
import pandas as pd
import pytest

from src.factors.ranking import (
    rank_cross_sectional,
    construct_dollar_neutral_weights,
    construct_tercile_long_short_weights,
)


def test_dollar_neutrality():
    dates = pd.date_range("2020-01-01", periods=5, freq="B")
    scores = pd.DataFrame({
        "A": [1.0, 5.0, 3.0, 2.0, 4.0],
        "B": [2.0, 4.0, 1.0, 5.0, 3.0],
        "C": [3.0, 3.0, 2.0, 4.0, 1.0],
        "D": [4.0, 2.0, 5.0, 1.0, 2.0],
        "E": [5.0, 1.0, 4.0, 3.0, 5.0],
    }, index=dates)
    
    ranks = rank_cross_sectional(scores)
    weights = construct_dollar_neutral_weights(ranks, gross_leverage=1.0)
    
    # 1. Dollar neutrality: net sum across columns must be exactly 0.0
    net_exposure = weights.sum(axis=1)
    for val in net_exposure:
        assert val == pytest.approx(0.0, abs=1e-7)
        
    # 2. Gross exposure: sum of absolute weights must be exactly 1.0
    gross_exposure = weights.abs().sum(axis=1)
    for val in gross_exposure:
        assert val == pytest.approx(1.0, rel=1e-5)


def test_tercile_weights():
    dates = pd.date_range("2020-01-01", periods=3, freq="B")
    scores = pd.DataFrame({
        "A": [1.0, 1.0, 1.0], # bottom
        "B": [2.0, 2.0, 2.0], # bottom
        "C": [3.0, 3.0, 3.0], # middle
        "D": [4.0, 4.0, 4.0], # middle
        "E": [5.0, 5.0, 5.0], # top
        "F": [6.0, 6.0, 6.0], # top
    }, index=dates)
    
    weights = construct_tercile_long_short_weights(scores, gross_leverage=1.0)
    
    # Top 2 (E, F) should be +0.25 each -> sum = +0.5
    # Bottom 2 (A, B) should be -0.25 each -> sum = -0.5
    # Middle 2 (C, D) should be 0.0
    assert weights["E"].iloc[0] == pytest.approx(0.25)
    assert weights["F"].iloc[0] == pytest.approx(0.25)
    assert weights["A"].iloc[0] == pytest.approx(-0.25)
    assert weights["B"].iloc[0] == pytest.approx(-0.25)
    assert weights["C"].iloc[0] == pytest.approx(0.0)
    assert weights["D"].iloc[0] == pytest.approx(0.0)
