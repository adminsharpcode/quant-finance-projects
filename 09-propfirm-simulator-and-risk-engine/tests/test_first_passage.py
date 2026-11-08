"""
Unit tests for Double-Barrier Brownian Motion first-passage mathematics.
"""

import pytest
import numpy as np
from src.models.first_passage import DoubleBarrierBrownianMotion


def test_martingale_fair_game():
    # When drift mu = 0: P(Pass) = D / (D + T)
    target = 0.10   # 10%
    drawdown = 0.10 # 10%
    res = DoubleBarrierBrownianMotion.calculate_pass_probability(
        drift_mu=0.0,
        vol_sigma=0.02,
        target_pct=target,
        drawdown_pct=drawdown,
    )
    # Expected: 0.10 / (0.10 + 0.10) = 50%
    assert res.pass_probability == pytest.approx(0.50, abs=1e-4)
    assert res.ruin_probability == pytest.approx(0.50, abs=1e-4)


def test_positive_drift_increases_survival():
    target = 0.10
    drawdown = 0.10
    # Positive edge: mu = +0.005 per step
    res_pos = DoubleBarrierBrownianMotion.calculate_pass_probability(
        drift_mu=0.005,
        vol_sigma=0.02,
        target_pct=target,
        drawdown_pct=drawdown,
    )
    # With positive edge, pass probability must be strictly greater than 50%
    assert res_pos.pass_probability > 0.50


def test_negative_drift_decreases_survival():
    target = 0.10
    drawdown = 0.10
    # Negative drift (friction / negative edge)
    res_neg = DoubleBarrierBrownianMotion.calculate_pass_probability(
        drift_mu=-0.005,
        vol_sigma=0.02,
        target_pct=target,
        drawdown_pct=drawdown,
    )
    assert res_neg.pass_probability < 0.50


def test_asymmetric_barriers():
    # Target 10%, Drawdown 5% (like many 1-step challenges)
    target = 0.10
    drawdown = 0.05
    res = DoubleBarrierBrownianMotion.calculate_pass_probability(
        drift_mu=0.0,
        vol_sigma=0.02,
        target_pct=target,
        drawdown_pct=drawdown,
    )
    # Fair game: 0.05 / (0.05 + 0.10) = 33.33%
    assert res.pass_probability == pytest.approx(1.0 / 3.0, abs=1e-4)
