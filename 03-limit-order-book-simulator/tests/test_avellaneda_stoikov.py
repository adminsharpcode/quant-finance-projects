"""
Unit Tests for Avellaneda-Stoikov (2008) Market Making Formulations.
"""

import pytest
from src.market_maker.avellaneda_stoikov import AvellanedaStoikovModel


def test_reservation_price_monotonicity():
    model = AvellanedaStoikovModel(gamma=0.1, sigma=0.05, T=60.0, kappa=1.5, q_max=10)
    mid = 100.0

    r_neutral = model.reservation_price(mid, inventory=0)
    r_long = model.reservation_price(mid, inventory=5)
    r_short = model.reservation_price(mid, inventory=-5)

    assert r_neutral == mid
    assert r_long < mid, "Long inventory must depress reservation price below mid"
    assert r_short > mid, "Short inventory must elevate reservation price above mid"


def test_inventory_skewed_quote_shading():
    model = AvellanedaStoikovModel(gamma=0.2, sigma=0.04, T=30.0, kappa=10.0, q_max=10, tick_size=0.05)
    mid = 500.0

    bid_neutral, ask_neutral = model.optimal_quotes(mid, inventory=0)
    bid_long, ask_long = model.optimal_quotes(mid, inventory=6)
    bid_short, ask_short = model.optimal_quotes(mid, inventory=-6)

    # When long inventory, quotes should be shaded downward to attract selling takers (ask hit)
    assert bid_long <= bid_neutral
    assert ask_long <= ask_neutral

    # When short inventory, quotes should be shaded upward to attract buying takers (bid hit)
    assert bid_short >= bid_neutral
    assert ask_short >= ask_neutral


def test_spread_widens_with_volatility_and_risk_aversion():
    model_low_vol = AvellanedaStoikovModel(gamma=0.1, sigma=0.01, T=60.0, kappa=1.5)
    model_high_vol = AvellanedaStoikovModel(gamma=0.1, sigma=0.05, T=60.0, kappa=1.5)
    model_high_risk = AvellanedaStoikovModel(gamma=0.5, sigma=0.15, T=60.0, kappa=1.5)
    model_base_risk = AvellanedaStoikovModel(gamma=0.1, sigma=0.15, T=60.0, kappa=1.5)

    s_base = model_low_vol.optimal_spread()
    s_vol = model_high_vol.optimal_spread()
    assert s_vol > s_base, "Higher volatility must widen optimal spread"

    s_base_r = model_base_risk.optimal_spread()
    s_risk = model_high_risk.optimal_spread()
    assert s_risk > s_base_r, "Higher risk aversion must widen optimal spread when volatility exists"


def test_hard_inventory_capacity_boundaries():
    model = AvellanedaStoikovModel(gamma=0.1, sigma=0.05, T=60.0, kappa=1.5, q_max=5)
    mid = 100.0

    # At max long inventory (+5), stop buying -> bid is None
    bid_at_max, ask_at_max = model.optimal_quotes(mid, inventory=5)
    assert bid_at_max is None
    assert ask_at_max is not None

    # At max short inventory (-5), stop selling -> ask is None
    bid_at_min, ask_at_min = model.optimal_quotes(mid, inventory=-5)
    assert bid_at_min is not None
    assert ask_at_min is None


def test_stationary_quotes_validity():
    model = AvellanedaStoikovModel(gamma=0.1, sigma=0.03, kappa=10.0, q_max=10, tick_size=0.05)
    mid = 100.0

    bid, ask = model.stationary_quotes(mid, inventory=0)
    assert bid is not None
    assert ask is not None
    assert bid < ask
    assert bid < mid < ask
