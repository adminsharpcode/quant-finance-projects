"""
Unit tests for the backtest engine and transaction cost execution.
"""

import numpy as np
import pandas as pd
import pytest

from src.backtest.engine import TSMOMBacktestEngine
from src.backtest.execution import ExecutionCostModel


def test_backtest_mark_to_market():
    dates = pd.date_range("2020-01-01", periods=5, freq="B")
    # Asset goes up 1% every day: 100, 101, 102.01, 103.0301, 104.0604
    prices = pd.DataFrame({"Asset": [100.0 * (1.01 ** i) for i in range(5)]}, index=dates)
    weights = pd.DataFrame({"Asset": [1.0] * 5}, index=dates)
    
    # Zero cost model to isolate mark-to-market
    cost_model = ExecutionCostModel(cost_bps=0.0, slippage_bps=0.0)
    engine = TSMOMBacktestEngine(initial_capital=1_000_000.0, cost_model=cost_model, rebalance_freq="D")
    
    result = engine.run(prices, weights)
    
    assert len(result.net_returns) == 5
    # Daily returns after day 0 should be approx 1%
    assert result.net_returns.iloc[1] == pytest.approx(0.01, rel=1e-4)
    # Total cumulative return over 4 periods: (1.01)^4 - 1 approx 0.040604
    assert result.cumulative_returns.iloc[-1] == pytest.approx((1.01 ** 4), rel=1e-4)


def test_transaction_cost_deduction():
    dates = pd.date_range("2020-01-01", periods=3, freq="B")
    # Flat price
    prices = pd.DataFrame({"A": [100.0, 100.0, 100.0]}, index=dates)
    # Target weight jumps from 0 to 1.0 (turnover = 1.0)
    weights = pd.DataFrame({"A": [1.0, 1.0, 1.0]}, index=dates)
    
    cost_model = ExecutionCostModel(cost_bps=10.0, slippage_bps=0.0)  # 10 bps = 0.0010
    engine = TSMOMBacktestEngine(initial_capital=100_000.0, cost_model=cost_model, rebalance_freq="D")
    
    result = engine.run(prices, weights)
    
    # On day 0: gross return 0.0, turnover 1.0 -> cost = 0.0010, net return = -0.0010
    assert result.transaction_costs.iloc[0] == pytest.approx(0.0010, rel=1e-5)
    assert result.net_returns.iloc[0] == pytest.approx(-0.0010, rel=1e-5)
