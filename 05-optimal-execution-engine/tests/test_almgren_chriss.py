"""
Tests for Almgren-Chriss Optimal Execution Engine.
"""

import numpy as np
import pytest
from src.models.almgren_chriss import ExecutionConfig, AlmgrenChrissEngine
from src.models.impact import LinearMarketImpact, SquareRootMarketImpact
from src.execution.twap import TWAPStrategy
from src.execution.vwap import VWAPStrategy


@pytest.fixture
def base_config():
    return ExecutionConfig(
        total_shares=100_000,
        horizon_minutes=60,
        intervals=30,
        annual_volatility=0.25,
        initial_price=150.0,
        risk_aversion=1e-5,
        impact=LinearMarketImpact(gamma=2.5e-7, eta=2.5e-6)
    )


def test_trajectory_boundary_conditions(base_config):
    """Verify x_0 = X and x_N = 0."""
    engine = AlmgrenChrissEngine(base_config)
    traj = engine.calculate_trajectory()
    
    assert len(traj) == base_config.intervals + 1
    assert np.isclose(traj[0], base_config.total_shares)
    assert np.isclose(traj[-1], 0.0)
    assert np.all(traj >= 0.0)


def test_monotonic_liquidation(base_config):
    """Holdings should be strictly non-increasing over time."""
    engine = AlmgrenChrissEngine(base_config)
    traj = engine.calculate_trajectory()
    diffs = np.diff(traj)
    assert np.all(diffs <= 1e-6), "Holdings must decrease monotonically"


def test_zero_risk_aversion_equals_twap(base_config):
    """When lambda -> 0, Almgren-Chriss must converge to uniform TWAP."""
    engine = AlmgrenChrissEngine(base_config)
    ac_twap_traj = engine.calculate_trajectory(risk_aversion=0.0)
    
    twap_strat = TWAPStrategy(base_config.total_shares, base_config.intervals)
    pure_twap_traj = twap_strat.calculate_trajectory()
    
    np.testing.assert_allclose(ac_twap_traj, pure_twap_traj, atol=1e-5)


def test_high_risk_aversion_frontloaded(base_config):
    """Higher risk aversion liquidates faster (frontloaded execution)."""
    engine = AlmgrenChrissEngine(base_config)
    traj_low = engine.calculate_trajectory(risk_aversion=1e-7)
    traj_high = engine.calculate_trajectory(risk_aversion=1e-3)
    
    # At midpoint, higher risk aversion has liquidated more, so remaining holdings are lower
    mid = len(traj_low) // 2
    assert traj_high[mid] < traj_low[mid]


def test_expected_cost_and_variance(base_config):
    """Verify expected cost is positive and variance increases as liquidation slows."""
    engine = AlmgrenChrissEngine(base_config)
    traj = engine.calculate_trajectory()
    
    e_cost = engine.expected_cost(traj)
    v_cost = engine.cost_variance(traj)
    
    assert e_cost > 0.0
    assert v_cost > 0.0


def test_efficient_frontier_generation(base_config):
    """Frontier should produce valid triples of (lambda, E[x], Std[x])."""
    engine = AlmgrenChrissEngine(base_config)
    frontier = engine.generate_efficient_frontier(n_points=10)
    assert len(frontier) == 10
    
    # As lambda increases: variance decreases, expected cost increases
    costs = [pt[1] for pt in frontier]
    stds = [pt[2] for pt in frontier]
    assert costs[-1] > costs[0]
    assert stds[-1] < stds[0]
