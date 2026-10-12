"""Unit tests for Binomial Tree (CRR / Jarrow-Rudd) pricing models."""

import pytest
from src.models.binomial_tree import (
    ExerciseStyle,
    binomial_early_exercise_premium,
    binomial_tree_price,
)
from src.models.black_scholes import OptionType, black_76_price, black_scholes_price


def test_binomial_european_convergence():
    """Verify CRR European price converges to Black-Scholes analytical price."""
    S = 100.0
    K = 100.0
    T = 1.0
    r = 0.05
    sigma = 0.20

    bs_call = black_scholes_price(S, K, T, r, sigma, OptionType.CALL)
    tree_call = binomial_tree_price(
        S, K, T, r, sigma, OptionType.CALL, ExerciseStyle.EUROPEAN, n_steps=500
    )

    assert pytest.approx(tree_call, abs=0.03) == bs_call


def test_american_early_exercise_premium():
    """Verify American Put exhibits strictly positive early exercise premium."""
    S = 80.0
    K = 100.0  # Deep ITM Put
    T = 1.0
    r = 0.08
    sigma = 0.20

    premium_info = binomial_early_exercise_premium(
        S, K, T, r, sigma, OptionType.PUT, n_steps=400
    )

    assert premium_info["american_price"] > premium_info["european_price"]
    assert premium_info["early_exercise_premium"] > 0.50
    # American price must be >= intrinsic value
    assert premium_info["american_price"] >= (K - S)


def test_american_call_without_dividend_equals_european():
    """Mathematical theorem: American call on non-dividend stock has zero early exercise premium."""
    S = 100.0
    K = 90.0
    T = 0.5
    r = 0.05
    sigma = 0.25

    p_american = binomial_tree_price(
        S, K, T, r, sigma, OptionType.CALL, ExerciseStyle.AMERICAN, n_steps=300, q=0.0
    )
    p_european = binomial_tree_price(
        S, K, T, r, sigma, OptionType.CALL, ExerciseStyle.EUROPEAN, n_steps=300, q=0.0
    )

    assert pytest.approx(p_american, abs=0.02) == p_european


def test_binomial_futures_convergence():
    """Verify binomial lattice on futures converges to Black-76."""
    F = 2650.0
    K = 2600.0
    T = 0.25
    r = 0.045
    sigma = 0.17

    b76_call = black_76_price(F, K, T, r, sigma, OptionType.CALL)
    tree_call = binomial_tree_price(
        F, K, T, r, sigma, OptionType.CALL, ExerciseStyle.EUROPEAN, n_steps=300, is_futures=True
    )

    assert pytest.approx(tree_call, abs=0.50) == b76_call
