"""
Unit tests for Factor Risk Parity and Combination.
"""

import numpy as np
import pandas as pd
import pytest

from src.portfolio.risk_parity import FactorRiskParity
from src.portfolio.combination import ValMomCombiner


def test_factor_risk_parity_inverse_vol():
    dates = pd.date_range("2020-01-01", periods=100, freq="B")
    np.random.seed(42)
    # Val leg has 10% vol, Mom leg has 20% vol
    val_rets = pd.Series(np.random.normal(0, 0.10 / np.sqrt(252), 100), index=dates)
    mom_rets = pd.Series(np.random.normal(0, 0.20 / np.sqrt(252), 100), index=dates)
    
    engine = FactorRiskParity(rolling_window=60, min_periods=20)
    w_val, w_mom = engine.compute_leg_weights(val_rets, mom_rets)
    
    # Parity should assign higher weight to lower-volatility leg (Val)
    assert w_val.iloc[-1] > w_mom.iloc[-1]
    assert (w_val.iloc[-1] + w_mom.iloc[-1]) == pytest.approx(1.0, rel=1e-5)


def test_valmom_combiner_execution():
    dates = pd.date_range("2020-01-01", periods=80, freq="B")
    val_w = pd.DataFrame({"A": [0.5]*80, "B": [-0.5]*80}, index=dates)
    mom_w = pd.DataFrame({"A": [-0.5]*80, "B": [0.5]*80}, index=dates)
    rets = pd.DataFrame({"A": [0.01]*80, "B": [-0.01]*80}, index=dates)
    
    combiner = ValMomCombiner(target_vol=0.12, risk_parity=False, max_leverage=2.0)
    final_w = combiner.combine(val_w, mom_w, rets)
    
    # When val is (0.5, -0.5) and mom is (-0.5, 0.5) with equal weights, net should cancel out to 0
    assert final_w["A"].iloc[50] == pytest.approx(0.0, abs=1e-5)
    assert final_w["B"].iloc[50] == pytest.approx(0.0, abs=1e-5)
