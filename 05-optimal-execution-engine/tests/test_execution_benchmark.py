"""
Unit tests for TWAP, VWAP, Simulator, and TCA evaluation.
"""

import numpy as np
import pytest
from src.execution.twap import TWAPStrategy
from src.execution.vwap import VWAPStrategy
from src.execution.simulator import MarketExecutionSimulator
from src.analytics.tca import TransactionCostAnalyzer


def test_twap_execution_sums_to_total():
    total_shares = 50_000
    intervals = 20
    twap = TWAPStrategy(total_shares, intervals)
    
    trades = twap.calculate_trade_sizes()
    traj = twap.calculate_trajectory()
    
    assert len(trades) == intervals
    assert np.isclose(np.sum(trades), total_shares)
    assert np.isclose(traj[0], total_shares)
    assert np.isclose(traj[-1], 0.0)


def test_vwap_u_curve_sums_to_total():
    total_shares = 100_000
    intervals = 26
    vwap = VWAPStrategy(total_shares, intervals)
    
    trades = vwap.calculate_trade_sizes()
    traj = vwap.calculate_trajectory()
    
    assert len(trades) == intervals
    assert np.isclose(np.sum(trades), total_shares)
    assert np.isclose(traj[0], total_shares)
    assert np.isclose(traj[-1], 0.0)
    
    # Check U-shape: open and close trades should be higher than midpoint trades
    assert trades[0] > trades[intervals // 2]
    assert trades[-1] > trades[intervals // 2]


def test_market_execution_simulation():
    initial_price = 100.0
    sim = MarketExecutionSimulator(
        initial_price=initial_price,
        tau_seconds=120.0,
        sigma_sec=0.05,
        seed=42
    )
    
    trades = np.full(10, 1000.0)
    res = sim.run_simulation(trades)
    
    assert res.arrival_price == initial_price
    assert res.average_executed_price > 0.0
    assert len(res.price_trajectory) == 11
    assert len(res.effective_prices) == 10
    assert res.implementation_shortfall_usd > 0.0
    assert res.implementation_shortfall_bps > 0.0


def test_tca_analyzer():
    trades = np.array([500.0, 500.0])
    effective_prices = np.array([99.5, 99.0])
    arrival_price = 100.0
    
    report = TransactionCostAnalyzer.evaluate(
        strategy_name="TestStrat",
        trades=trades,
        effective_prices=effective_prices,
        arrival_price=arrival_price,
        cost_std=150.0
    )
    
    assert report.total_shares == 1000.0
    assert report.average_fill_price == 99.25
    assert np.isclose(report.implementation_shortfall_usd, 750.0)
    assert np.isclose(report.slippage_bps, 75.0)
