"""
Unit tests for prop firm catalog and rule specifications.
"""

import pytest
from src.rules.firm_catalog import PROP_FIRMS, DrawdownType, MarketType


def test_catalog_minimum_firms():
    # User requested at least 20 prop firms
    assert len(PROP_FIRMS) >= 20


def test_firm_rules_validity():
    for fid, firm in PROP_FIRMS.items():
        assert firm.firm_id == fid
        assert len(firm.name) > 0
        assert firm.max_drawdown_pct > 0.0
        assert len(firm.phases) >= 1
        
        # Check each phase has positive target
        for p in firm.phases:
            assert p.profit_target_pct > 0.0
            assert p.min_trading_days >= 0
            
        # Drawdown type must be one of the enum
        assert firm.drawdown_type in [
            DrawdownType.STATIC,
            DrawdownType.TRAILING_EOD,
            DrawdownType.TRAILING_INTRADAY,
            DrawdownType.RELATIVE,
        ]


def test_ftmo_specs():
    ftmo = PROP_FIRMS["ftmo_standard"]
    assert ftmo.daily_drawdown_pct == 5.0
    assert ftmo.max_drawdown_pct == 10.0
    assert ftmo.phases[0].profit_target_pct == 10.0
    assert ftmo.phases[1].profit_target_pct == 5.0
    assert ftmo.drawdown_type == DrawdownType.STATIC


def test_topstep_specs():
    topstep = PROP_FIRMS["topstep_combine"]
    assert topstep.market == MarketType.FUTURES
    assert topstep.drawdown_type == DrawdownType.TRAILING_EOD
    assert topstep.daily_drawdown_pct == 2.0
    assert topstep.max_drawdown_pct == 4.0
