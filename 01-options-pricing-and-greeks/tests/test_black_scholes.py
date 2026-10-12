"""Unit tests for Black-Scholes and Black-76 pricing models."""

import numpy as np
import pytest
from src.models.black_scholes import (
    OptionType,
    black_scholes_price,
    black_76_price,
    verify_put_call_parity,
    d1_d2,
)


def test_black_scholes_known_values():
    """Verify Black-Scholes against standard academic benchmark value."""
    # S=100, K=100, T=1, r=0.05, sigma=0.20
    # Expected Call price ~ 10.4506, Put price ~ 5.5735
    call = black_scholes_price(100.0, 100.0, 1.0, 0.05, 0.20, OptionType.CALL)
    put = black_scholes_price(100.0, 100.0, 1.0, 0.05, 0.20, OptionType.PUT)

    assert pytest.approx(call, abs=1e-3) == 10.4506
    assert pytest.approx(put, abs=1e-3) == 5.5735


def test_put_call_parity():
    """Verify European Put-Call parity holds across spot levels."""
    S = 120.0
    K = 115.0
    T = 0.5
    r = 0.04
    sigma = 0.25
    q = 0.015

    call = black_scholes_price(S, K, T, r, sigma, OptionType.CALL, q=q)
    put = black_scholes_price(S, K, T, r, sigma, OptionType.PUT, q=q)

    assert verify_put_call_parity(call, put, S, K, T, r, q=q)


def test_black_76_futures_pricing():
    """Verify Black-76 futures options formula."""
    F = 2650.0  # COMEX Gold
    K = 2650.0
    T = 0.25
    r = 0.045
    sigma = 0.16

    call = black_76_price(F, K, T, r, sigma, OptionType.CALL)
    put = black_76_price(F, K, T, r, sigma, OptionType.PUT)

    # For ATM futures option with F = K, Call = Put
    assert pytest.approx(call, abs=1e-4) == put
    assert call > 0.0


def test_vectorization():
    """Verify that vectorized array inputs match scalar outputs."""
    strikes = np.array([90.0, 100.0, 110.0])
    calls_vec = black_scholes_price(100.0, strikes, 1.0, 0.05, 0.20, OptionType.CALL)

    for i, K in enumerate(strikes):
        call_single = black_scholes_price(100.0, K, 1.0, 0.05, 0.20, OptionType.CALL)
        assert pytest.approx(calls_vec[i], abs=1e-6) == call_single


def test_boundary_conditions():
    """Test expiry (T=0) and deep ITM/OTM conditions."""
    # At T=0, price = max(S - K, 0)
    assert black_scholes_price(100.0, 90.0, 0.0, 0.05, 0.20, OptionType.CALL) == 10.0
    assert black_scholes_price(100.0, 110.0, 0.0, 0.05, 0.20, OptionType.CALL) == 0.0
    assert black_scholes_price(100.0, 110.0, 0.0, 0.05, 0.20, OptionType.PUT) == 10.0
