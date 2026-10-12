"""Unit tests for analytical and higher-order Greeks."""

import pytest
from src.greeks.analytical_greeks import (
    calculate_all_greeks,
    delta,
    gamma,
    rho,
    theta,
    vanna,
    vega,
    volga,
)
from src.models.black_scholes import OptionType, black_scholes_price


def test_delta_gamma_numerical_consistency():
    """Verify analytical Delta and Gamma match central finite difference within 1e-4."""
    S = 100.0
    K = 105.0
    T = 0.5
    r = 0.05
    sigma = 0.20
    h = 0.001

    ana_delta = delta(S, K, T, r, sigma, OptionType.CALL)
    ana_gamma = gamma(S, K, T, r, sigma)

    c_up = black_scholes_price(S + h, K, T, r, sigma, OptionType.CALL)
    c_down = black_scholes_price(S - h, K, T, r, sigma, OptionType.CALL)
    c_mid = black_scholes_price(S, K, T, r, sigma, OptionType.CALL)

    num_delta = (c_up - c_down) / (2.0 * h)
    num_gamma = (c_up - 2.0 * c_mid + c_down) / (h**2)

    assert pytest.approx(ana_delta, abs=1e-4) == num_delta
    assert pytest.approx(ana_gamma, abs=1e-4) == num_gamma


def test_vega_numerical_consistency():
    """Verify analytical Vega matches numerical differentiation."""
    S = 100.0
    K = 100.0
    T = 1.0
    r = 0.05
    sigma = 0.25
    h = 0.0005

    ana_vega = vega(S, K, T, r, sigma)
    c_up = black_scholes_price(S, K, T, r, sigma + h, OptionType.CALL)
    c_down = black_scholes_price(S, K, T, r, sigma - h, OptionType.CALL)
    num_vega = (c_up - c_down) / (2.0 * h)

    assert pytest.approx(ana_vega, abs=1e-3) == num_vega


def test_vanna_cross_derivative():
    """Verify Vanna: dVega / dS == dDelta / dVol."""
    S = 100.0
    K = 100.0
    T = 0.5
    r = 0.05
    sigma = 0.20
    h_s = 0.001
    h_v = 0.001

    ana_vanna = vanna(S, K, T, r, sigma)

    # dVega / dS
    v_up = vega(S + h_s, K, T, r, sigma)
    v_down = vega(S - h_s, K, T, r, sigma)
    num_vanna_s = (v_up - v_down) / (2.0 * h_s)

    # dDelta / dVol
    d_up = delta(S, K, T, r, sigma + h_v, OptionType.CALL)
    d_down = delta(S, K, T, r, sigma - h_v, OptionType.CALL)
    num_vanna_v = (d_up - d_down) / (2.0 * h_v)

    assert pytest.approx(ana_vanna, abs=1e-3) == num_vanna_s
    assert pytest.approx(ana_vanna, abs=1e-3) == num_vanna_v


def test_volga_convexity():
    """Verify Volga (dVega / dVol) matches numerical second derivative."""
    S = 100.0
    K = 110.0
    T = 0.75
    r = 0.05
    sigma = 0.22
    h = 0.001

    ana_volga = volga(S, K, T, r, sigma)
    v_up = vega(S, K, T, r, sigma + h)
    v_down = vega(S, K, T, r, sigma - h)
    num_volga = (v_up - v_down) / (2.0 * h)

    assert pytest.approx(ana_volga, abs=1e-3) == num_volga


def test_call_put_greeks_identities():
    """Verify fundamental Call and Put symmetry relationships."""
    S = 2650.0  # COMEX Gold
    K = 2650.0
    T = 0.25
    r = 0.045
    sigma = 0.18

    call_g = calculate_all_greeks(S, K, T, r, sigma, OptionType.CALL, is_futures=True)
    put_g = calculate_all_greeks(S, K, T, r, sigma, OptionType.PUT, is_futures=True)

    # Gamma and Vega are identical for Calls and Puts
    assert pytest.approx(call_g.gamma, rel=1e-6) == put_g.gamma
    assert pytest.approx(call_g.vega, rel=1e-6) == put_g.vega
    # Delta relationship on futures: Delta_call - Delta_put = exp(-r*T)
    import numpy as np
    assert pytest.approx(call_g.delta - put_g.delta, abs=1e-5) == np.exp(-r * T)
