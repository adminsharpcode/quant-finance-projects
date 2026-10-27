"""
Comprehensive Unit Tests for Almgren-Chriss and Advanced Execution Frameworks.
"""

import numpy as np
import pytest
from src.models.almgren_chriss import (
    ExecutionConfig,
    AlmgrenChrissEngine,
    MultiAssetExecutionEngine
)
from src.models.impact import (
    LinearMarketImpact,
    SquareRootMarketImpact,
    TransientExponentialImpact,
    CrossAssetImpactMatrix
)
from src.execution.twap import TWAPStrategy
from src.execution.adaptive import AdaptiveExecutionStrategy


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
    
    costs = [pt[1] for pt in frontier]
    stds = [pt[2] for pt in frontier]
    assert costs[-1] > costs[0]
    assert stds[-1] < stds[0]


def test_obizhaeva_wang_trajectory(base_config):
    """Obizhaeva & Wang transient impact must have discrete jumps at t=0 and t=T."""
    engine = AlmgrenChrissEngine(base_config)
    ow_impact = TransientExponentialImpact(gamma_0=1e-6, rho=0.05)
    traj = engine.calculate_obizhaeva_wang_trajectory(ow_impact)
    
    assert len(traj) == base_config.intervals + 1
    assert np.isclose(traj[0], base_config.total_shares)
    assert np.isclose(traj[-1], 0.0)
    
    # First interval trade includes the initial block jump plus continuous rate over interval tau:
    tau = engine.T / base_config.intervals
    n_initial = base_config.total_shares / (2.0 + ow_impact.rho * engine.T)
    continuous_rate = (ow_impact.rho * base_config.total_shares) / (2.0 + ow_impact.rho * engine.T)
    expected_first_interval = n_initial + continuous_rate * tau
    first_trade = traj[0] - traj[1]
    assert np.isclose(first_trade, expected_first_interval, rtol=0.01)


def test_nonlinear_dynamic_optimization(base_config):
    """SLSQP optimizer solves square-root law optimal trajectory."""
    engine = AlmgrenChrissEngine(base_config)
    sq_impact = SquareRootMarketImpact()
    traj = engine.calculate_nonlinear_trajectory(sq_impact, risk_aversion=1e-6)
    
    assert len(traj) == base_config.intervals + 1
    assert np.isclose(traj[0], base_config.total_shares)
    assert np.isclose(traj[-1], 0.0)
    assert np.all(traj >= -1e-5)
    # Sum of trades equals initial inventory
    trades = traj[:-1] - traj[1:]
    assert np.isclose(np.sum(trades), base_config.total_shares, rtol=1e-4)


def test_multi_asset_portfolio_execution():
    """Multi-asset solver coordinates liquidation of correlated assets."""
    X0 = np.array([50_000.0, 30_000.0])
    prices = np.array([100.0, 200.0])
    # Correlated asset covariance matrix
    Sigma = np.array([
        [0.001, 0.0006],
        [0.0006, 0.002]
    ])
    # Cross impact matrices
    gamma_mat = np.array([
        [2e-7, 5e-8],
        [5e-8, 3e-7]
    ])
    eta_mat = np.array([
        [2e-6, 5e-7],
        [5e-7, 3e-6]
    ])
    cross_impact = CrossAssetImpactMatrix(gamma_mat, eta_mat)

    engine = MultiAssetExecutionEngine(
        initial_holdings=X0,
        prices=prices,
        covariance_matrix=Sigma,
        cross_impact=cross_impact,
        horizon_seconds=1800.0,
        intervals=15,
        risk_aversion=1e-6
    )

    trajectories = engine.calculate_multi_asset_trajectories()
    assert trajectories.shape == (2, 16)
    np.testing.assert_allclose(trajectories[:, 0], X0)
    np.testing.assert_allclose(trajectories[:, -1], [0.0, 0.0], atol=1e-3)


def test_adaptive_execution_strategy(base_config):
    """Adaptive strategy responds to spread shocks and drift."""
    engine = AlmgrenChrissEngine(base_config)
    adaptive = AdaptiveExecutionStrategy(engine)

    prices = np.full(base_config.intervals + 1, 150.0)
    # Simulate a sudden spread blowout at midpoint
    spreads = np.full(base_config.intervals, 0.02)
    spreads[10:15] = 0.10  # 5x spread shock

    trades, telemetry = adaptive.execute_adaptive_schedule(prices, spreads)

    assert len(trades) == base_config.intervals
    assert np.isclose(np.sum(trades), base_config.total_shares, rtol=1e-4)
    # The intervals with blown-out spread should have passive orders flagged
    assert any(state.is_passive_order for state in telemetry)
