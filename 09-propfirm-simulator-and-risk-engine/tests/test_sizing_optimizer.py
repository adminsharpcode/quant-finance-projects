"""
Unit tests for the sizing optimizer.
"""

import pytest
from src.rules.firm_catalog import PROP_FIRMS
from src.optimization.sizing_optimizer import PropFirmSizingOptimizer


def test_optimizer_bounds_daily_risk():
    firm = PROP_FIRMS["ftmo_standard"]
    optimizer = PropFirmSizingOptimizer(firm, win_rate=0.52, reward_to_risk=1.5, trades_per_day=2)
    rec = optimizer.find_optimal_risk(risk_candidates=(0.25, 0.50, 1.0, 2.0), num_simulations_per_point=300)
    
    assert rec.optimal_risk_pct > 0.0
    assert rec.max_safe_risk_pct > 0.0
    # Optimal risk shouldn't exceed safe bounds
    assert rec.optimal_risk_pct <= 1.5
    assert len(rec.actionable_rules) >= 3
