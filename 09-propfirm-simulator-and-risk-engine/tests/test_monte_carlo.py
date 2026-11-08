"""
Unit tests for the Monte Carlo simulator.
"""

import pytest
import numpy as np
from src.rules.firm_catalog import PROP_FIRMS
from src.models.monte_carlo import PropFirmSimulator, TraderProfile


def test_simulation_runs_successfully():
    firm = PROP_FIRMS["ftmo_standard"]
    # High edge trader
    trader = TraderProfile(
        win_rate=0.60,
        reward_to_risk=1.5,
        risk_per_trade_pct=0.005,
        trades_per_day=2,
    )
    sim = PropFirmSimulator(firm, trader, account_size=100_000.0, max_simulation_days=60, seed=42)
    summary = sim.simulate(num_paths=200)
    
    assert summary.total_paths == 200
    assert 0.0 <= summary.pass_rate_overall <= 1.0
    assert 0.0 <= summary.ruin_rate_overall <= 1.0
    assert len(summary.percentiles["p50"]) == 61
    assert len(summary.sample_equity_curves) > 0


def test_high_risk_triggers_daily_breach():
    firm = PROP_FIRMS["ftmo_standard"]  # 5% daily limit
    # Dangerously aggressive trader: risks 3% per trade, 3 trades/day
    reckless_trader = TraderProfile(
        win_rate=0.40,
        reward_to_risk=1.0,
        risk_per_trade_pct=0.03,  # 3% risk! 2 losses in a day = -6% > 5% limit!
        trades_per_day=3,
    )
    sim = PropFirmSimulator(firm, reckless_trader, seed=123)
    summary = sim.simulate(num_paths=300)
    
    # Reckless sizing should have massive daily breach rate
    assert summary.ruin_due_to_daily_dd_pct > 0.40
