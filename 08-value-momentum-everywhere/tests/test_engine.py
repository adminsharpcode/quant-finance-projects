"""
Unit tests for factor backtest engine.
"""

import numpy as np
import pandas as pd
import pytest

from src.backtest.engine import FactorBacktestEngine


def test_engine_cost_and_returns():
    dates = pd.date_range("2020-01-01", periods=5, freq="B")
    prices = pd.DataFrame({
        "A": [100.0, 102.0, 104.04, 106.12, 108.24],
        "B": [100.0, 98.0, 96.04, 94.12, 92.24],
    }, index=dates)
    
    # Long A (+0.5), Short B (-0.5) -> Dollar neutral
    weights = pd.DataFrame({"A": [0.5]*5, "B": [-0.5]*5}, index=dates)
    
    engine = FactorBacktestEngine(initial_capital=1_000_000.0, cost_bps=0.0, rebalance_freq="D")
    res = engine.run(prices, weights)
    
    assert len(res.net_returns) == 5
    # Day 1: A gained 2%, B lost 2%. Long A (+0.5 * 2% = +1%), Short B (-0.5 * -2% = +1%) -> Net +2%!
    assert res.net_returns.iloc[1] == pytest.approx(0.02, rel=1e-3)
