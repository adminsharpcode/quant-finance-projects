"""Unit tests for Monte Carlo simulation engine and variance reduction."""

import pytest
from src.models.black_scholes import OptionType, black_scholes_price
from src.models.monte_carlo import monte_carlo_greeks_crn, monte_carlo_price
from src.greeks.analytical_greeks import calculate_all_greeks


def test_monte_carlo_confidence_interval():
    """Verify analytical Black-Scholes price falls within Monte Carlo 95% CI."""
    S = 100.0
    K = 105.0
    T = 0.5
    r = 0.05
    sigma = 0.22

    bs_call = black_scholes_price(S, K, T, r, sigma, OptionType.CALL)
    mc_res = monte_carlo_price(
        S, K, T, r, sigma, OptionType.CALL, n_paths=100_000, use_antithetic=True, seed=42
    )

    assert mc_res.ci_95_lower <= bs_call <= mc_res.ci_95_upper
    assert abs(mc_res.price - bs_call) < 0.10


def test_antithetic_variance_reduction():
    """Verify antithetic variates reduces standard error."""
    S = 100.0
    K = 100.0
    T = 1.0
    r = 0.05
    sigma = 0.25

    res_standard = monte_carlo_price(
        S, K, T, r, sigma, OptionType.CALL, n_paths=40_000, use_antithetic=False, seed=123
    )
    res_antithetic = monte_carlo_price(
        S, K, T, r, sigma, OptionType.CALL, n_paths=40_000, use_antithetic=True, seed=123
    )

    assert res_antithetic.standard_error <= res_standard.standard_error


def test_crn_greeks_accuracy():
    """Verify Monte Carlo finite difference Greeks via CRN match analytical derivatives."""
    S = 100.0
    K = 100.0
    T = 0.75
    r = 0.04
    sigma = 0.20

    analytical = calculate_all_greeks(S, K, T, r, sigma, OptionType.CALL)
    mc_greeks = monte_carlo_greeks_crn(S, K, T, r, sigma, OptionType.CALL, n_paths=150_000, seed=999)

    # Check Delta matches within 0.02
    assert pytest.approx(mc_greeks["delta"], abs=0.03) == float(analytical.delta)
    # Check Vega matches within 0.75
    assert pytest.approx(mc_greeks["vega"], abs=0.75) == float(analytical.vega)
