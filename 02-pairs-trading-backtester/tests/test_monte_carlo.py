"""Unit tests for Monte Carlo Ornstein-Uhlenbeck simulation engine."""

import numpy as np
import pytest
from src.simulation.monte_carlo import PairsMonteCarloEngine


def test_monte_carlo_path_generation_shape():
    """Verify generated paths matrix matches expected dimensions."""
    engine = PairsMonteCarloEngine(num_paths=500, horizon_days=30, random_seed=42)
    paths = engine.simulate_ou_paths(initial_spread=-2.0, theta=0.05, mu=0.0, sigma=1.0)
    assert paths.shape == (500, 31)
    assert np.all(paths[:, 0] == -2.0)


def test_monte_carlo_convergence_to_theoretical_mean():
    """Verify sample mean of paths converges to theoretical conditional mean."""
    engine = PairsMonteCarloEngine(num_paths=10000, horizon_days=40, random_seed=42)
    x0 = -3.0
    theta = 0.08
    mu = 0.5
    sigma = 1.0

    paths = engine.simulate_ou_paths(initial_spread=x0, theta=theta, mu=mu, sigma=sigma)
    t = 40
    theoretical_mean = x0 * np.exp(-theta * t) + mu * (1.0 - np.exp(-theta * t))
    sample_mean = np.mean(paths[:, t])

    assert np.isclose(sample_mean, theoretical_mean, atol=0.1)


def test_monte_carlo_first_passage_and_risk():
    """Verify first passage time probabilities and risk metrics (VaR & CVaR)."""
    engine = PairsMonteCarloEngine(num_paths=1000, horizon_days=45, random_seed=42)
    res = engine.run_first_passage_analysis(
        initial_spread=-2.0,
        theta=0.06,
        mu=0.0,
        sigma=0.8,
        target_reversion_spread=0.0,
        stop_loss_spread=-4.0,
        position_direction=1
    )

    # Probability of profit should be significant since starting at -2.0 reverting to 0.0
    assert 50.0 <= res.probability_of_profit <= 100.0
    assert 0.0 <= res.probability_of_stop_loss <= 30.0
    assert 0.0 < res.expected_exit_days <= 45.0
    assert "50th" in res.percentiles
    assert len(res.percentiles["50th"]) == 46

    # Expected shortfall CVaR must be >= VaR
    assert res.cvar_95_pct >= res.var_95_pct
    assert res.cvar_99_pct >= res.var_99_pct
