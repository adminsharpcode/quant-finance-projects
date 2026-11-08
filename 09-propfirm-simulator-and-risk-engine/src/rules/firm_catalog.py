"""
prop_firms_catalog.py
Comprehensive rule specifications for 22 leading proprietary trading firms
(Forex/CFDs and Futures). Includes drawdown calculations, phase targets,
daily limits, and consistency rules.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional
import json


class DrawdownType(str, Enum):
    STATIC = "Static"                  # Fixed relative to initial balance (e.g. FTMO)
    TRAILING_EOD = "Trailing_EOD"      # Trails high water mark at end of day (e.g. Topstep)
    TRAILING_INTRADAY = "Trailing_Intraday"  # Trails highest unrealized equity in real-time (e.g. Apex)
    RELATIVE = "Relative"              # Trailing relative to peak balance until initial balance


class MarketType(str, Enum):
    FX_CFD = "Forex & CFDs"
    FUTURES = "CME Futures"


@dataclass
class PhaseRule:
    phase_number: int
    profit_target_pct: float
    min_trading_days: int
    max_days: Optional[int] = None  # None = Unlimited


@dataclass
class PropFirmRule:
    firm_id: str
    name: str
    market: MarketType
    phases: List[PhaseRule]
    daily_drawdown_pct: float
    max_drawdown_pct: float
    drawdown_type: DrawdownType
    daily_drawdown_type: str = "Balance"  # "Balance" or "Equity"
    weekend_holding: bool = True
    news_trading: bool = True
    consistency_rule: bool = False  # e.g., no single trade can make > 30% or 40% of profit
    profit_split_pct: float = 80.0
    notes: str = ""

    @property
    def total_phases(self) -> int:
        return len(self.phases)

    def to_dict(self) -> Dict:
        return {
            "firm_id": self.firm_id,
            "name": self.name,
            "market": self.market.value,
            "total_phases": self.total_phases,
            "phases": [
                {
                    "phase": p.phase_number,
                    "target_pct": p.profit_target_pct,
                    "min_days": p.min_trading_days,
                    "max_days": p.max_days,
                }
                for p in self.phases
            ],
            "daily_drawdown_pct": self.daily_drawdown_pct,
            "max_drawdown_pct": self.max_drawdown_pct,
            "drawdown_type": self.drawdown_type.value,
            "daily_drawdown_type": self.daily_drawdown_type,
            "weekend_holding": self.weekend_holding,
            "news_trading": self.news_trading,
            "consistency_rule": self.consistency_rule,
            "profit_split_pct": self.profit_split_pct,
            "notes": self.notes,
        }


# Comprehensive Catalog of 22 Real Prop Firms (2026 Standards)
PROP_FIRMS: Dict[str, PropFirmRule] = {
    # 1. FTMO Standard
    "ftmo_standard": PropFirmRule(
        firm_id="ftmo_standard",
        name="FTMO (Standard 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=10.0, min_trading_days=4),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=4),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=False,
        profit_split_pct=80.0,
        notes="Gold standard retail firm. Static max drawdown from initial balance. Daily loss calculated from start-of-day balance/equity max.",
    ),
    
    # 2. FTMO Aggressive
    "ftmo_aggressive": PropFirmRule(
        firm_id="ftmo_aggressive",
        name="FTMO (Aggressive 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=20.0, min_trading_days=4),
            PhaseRule(phase_number=2, profit_target_pct=10.0, min_trading_days=4),
        ],
        daily_drawdown_pct=10.0,
        max_drawdown_pct=20.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=False,
        profit_split_pct=80.0,
        notes="Double targets and double drawdowns. Suitable for higher volatility strategies.",
    ),

    # 3. Funding Pips 2-Step
    "funding_pips_2step": PropFirmRule(
        firm_id="funding_pips_2step",
        name="Funding Pips (Student 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=0),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=85.0,
        notes="Zero minimum trading days. Static 10% drawdown.",
    ),

    # 4. Funding Pips 1-Step
    "funding_pips_1step": PropFirmRule(
        firm_id="funding_pips_1step",
        name="Funding Pips (Master 1-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=12.0, min_trading_days=0),
        ],
        daily_drawdown_pct=3.0,
        max_drawdown_pct=6.0,
        drawdown_type=DrawdownType.RELATIVE,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=90.0,
        notes="1-step evaluation with tighter 3% daily and 6% trailing drawdown.",
    ),

    # 5. The 5%ers High Stakes
    "the5ers_high_stakes": PropFirmRule(
        firm_id="the5ers_high_stakes",
        name="The 5%ers (High Stakes 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=3),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=3),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Balance",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="Balance-based daily loss limit (more lenient than equity-based). Scaling plan up to $4M.",
    ),

    # 6. The 5%ers Bootcamp
    "the5ers_bootcamp": PropFirmRule(
        firm_id="the5ers_bootcamp",
        name="The 5%ers (Bootcamp 3-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=6.0, min_trading_days=0),
            PhaseRule(phase_number=3, profit_target_pct=6.0, min_trading_days=0),
        ],
        daily_drawdown_pct=0.0,  # No daily drawdown, purely 5% max
        max_drawdown_pct=5.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="None",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=85.0,
        notes="Low cost, 3 phases at 6% target, strict 5% max drawdown with no daily loss limit.",
    ),

    # 7. Topstep Trading Combine
    "topstep_combine": PropFirmRule(
        firm_id="topstep_combine",
        name="Topstep (Trading Combine Futures)",
        market=MarketType.FUTURES,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=2),
        ],
        daily_drawdown_pct=2.0,  # $1,000 on $50k
        max_drawdown_pct=4.0,    # $2,000 on $50k EOD Trailing
        drawdown_type=DrawdownType.TRAILING_EOD,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=True,
        consistency_rule=True,
        profit_split_pct=90.0,
        notes="Premier futures firm. End-of-Day (EOD) trailing drawdown locks at initial balance.",
    ),

    # 8. Apex Trader Funding
    "apex_futures": PropFirmRule(
        firm_id="apex_futures",
        name="Apex Trader Funding (Futures Trailing)",
        market=MarketType.FUTURES,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=1),
        ],
        daily_drawdown_pct=0.0,  # No daily limit
        max_drawdown_pct=5.0,    # $2,500 on $50k Trailing Intraday Peak
        drawdown_type=DrawdownType.TRAILING_INTRADAY,
        daily_drawdown_type="None",
        weekend_holding=False,
        news_trading=True,
        profit_split_pct=90.0,
        notes="Intraday trailing peak drawdown (trails open unrealized profits). High mathematical ruin rate if trades aren't capped.",
    ),

    # 9. FundedNext Stellar 2-Step
    "fundednext_stellar_2step": PropFirmRule(
        firm_id="fundednext_stellar_2step",
        name="FundedNext (Stellar 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=5),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=5),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Balance",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="Balance-based daily loss limit with 15% profit sharing during challenge phase.",
    ),

    # 10. FundedNext Stellar 1-Step
    "fundednext_stellar_1step": PropFirmRule(
        firm_id="fundednext_stellar_1step",
        name="FundedNext (Stellar 1-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=10.0, min_trading_days=2),
        ],
        daily_drawdown_pct=3.0,
        max_drawdown_pct=6.0,
        drawdown_type=DrawdownType.TRAILING_EOD,
        daily_drawdown_type="Balance",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=90.0,
        notes="1-step challenge with 10% target, 3% daily, 6% trailing.",
    ),

    # 11. E8 Markets Classic
    "e8_markets_classic": PropFirmRule(
        firm_id="e8_markets_classic",
        name="E8 Markets (E8 Classic 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=4.0, min_trading_days=0),
        ],
        daily_drawdown_pct=4.0,
        max_drawdown_pct=8.0,
        drawdown_type=DrawdownType.RELATIVE,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="E8 custom dashboard with dynamic trailing drawdown that locks at initial balance.",
    ),

    # 12. E8 Markets Track
    "e8_markets_track": PropFirmRule(
        firm_id="e8_markets_track",
        name="E8 Markets (E8 Track 3-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=5.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=0),
            PhaseRule(phase_number=3, profit_target_pct=5.0, min_trading_days=0),
        ],
        daily_drawdown_pct=4.0,
        max_drawdown_pct=8.0,
        drawdown_type=DrawdownType.RELATIVE,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="3-step evaluation with 5% target each phase.",
    ),

    # 13. Alpha Capital Group Pro
    "alpha_capital_pro": PropFirmRule(
        firm_id="alpha_capital_pro",
        name="Alpha Capital Group (Alpha Pro 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=0),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="Raw spread zero commission broker structure with zero minimum trading days.",
    ),

    # 14. City Traders Imperium (CTI)
    "city_traders_imperium": PropFirmRule(
        firm_id="city_traders_imperium",
        name="City Traders Imperium (Challenge 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=9.0, min_trading_days=5),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=5),
        ],
        daily_drawdown_pct=4.0,
        max_drawdown_pct=8.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="Institutional prop firm with strict risk management culture.",
    ),

    # 15. Blue Guardian
    "blue_guardian": PropFirmRule(
        firm_id="blue_guardian",
        name="Blue Guardian (Unlimited 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=4.0, min_trading_days=0),
        ],
        daily_drawdown_pct=4.0,
        max_drawdown_pct=8.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=85.0,
        notes="Guardian Protector feature automatically stops trading before daily limit breach.",
    ),

    # 16. The Funded Trader (Standard)
    "the_funded_trader_standard": PropFirmRule(
        firm_id="the_funded_trader_standard",
        name="The Funded Trader (Standard 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=10.0, min_trading_days=3),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=3),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=False,
        profit_split_pct=80.0,
        notes="10% and 5% targets, static 10% maximum drawdown.",
    ),

    # 17. Goat Funded Trader
    "goat_funded_trader": PropFirmRule(
        firm_id="goat_funded_trader",
        name="Goat Funded Trader (Classic 2-Step)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=8.0, min_trading_days=0),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=0),
        ],
        daily_drawdown_pct=4.0,
        max_drawdown_pct=8.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Balance",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=80.0,
        notes="Balance-based daily loss limit with no time limit.",
    ),

    # 18. FXIFY
    "fxify_2step": PropFirmRule(
        firm_id="fxify_2step",
        name="FXIFY (2-Step Assessment)",
        market=MarketType.FX_CFD,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=10.0, min_trading_days=5),
            PhaseRule(phase_number=2, profit_target_pct=5.0, min_trading_days=5),
        ],
        daily_drawdown_pct=5.0,
        max_drawdown_pct=10.0,
        drawdown_type=DrawdownType.STATIC,
        daily_drawdown_type="Equity",
        weekend_holding=True,
        news_trading=True,
        profit_split_pct=85.0,
        notes="Customizable leverage up to 1:50, automated payout on demand.",
    ),

    # 19. Take Profit Trader
    "take_profit_trader": PropFirmRule(
        firm_id="take_profit_trader",
        name="Take Profit Trader (ProDay Futures)",
        market=MarketType.FUTURES,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=5),
        ],
        daily_drawdown_pct=2.2,  # $1,100 on $50k
        max_drawdown_pct=4.0,    # $2,000 on $50k EOD Trailing
        drawdown_type=DrawdownType.TRAILING_EOD,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=True,
        consistency_rule=True,
        profit_split_pct=80.0,
        notes="Day 1 withdrawals allowed upon funding, EOD trailing drawdown.",
    ),

    # 20. TradeDay
    "tradeday_evaluation": PropFirmRule(
        firm_id="tradeday_evaluation",
        name="TradeDay (Futures Evaluation)",
        market=MarketType.FUTURES,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=7),
        ],
        daily_drawdown_pct=2.0,  # $1,000 on $50k
        max_drawdown_pct=4.0,    # $2,000 on $50k EOD Trailing
        drawdown_type=DrawdownType.TRAILING_EOD,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=True,
        consistency_rule=True,
        profit_split_pct=90.0,
        notes="CFTC regulated backing, strict consistency rules, EOD trailing.",
    ),

    # 21. Earn2Trade (TCP)
    "earn2trade_tcp": PropFirmRule(
        firm_id="earn2trade_tcp",
        name="Earn2Trade (Trader Career Path)",
        market=MarketType.FUTURES,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=10),
        ],
        daily_drawdown_pct=2.2,
        max_drawdown_pct=4.0,
        drawdown_type=DrawdownType.TRAILING_EOD,
        daily_drawdown_type="Equity",
        weekend_holding=False,
        news_trading=True,
        consistency_rule=True,
        profit_split_pct=80.0,
        notes="Structured career progression path from $25k to $400k account.",
    ),

    # 22. Bulenox
    "bulenox_master": PropFirmRule(
        firm_id="bulenox_master",
        name="Bulenox (Futures Master Trailing)",
        market=MarketType.FUTURES,
        phases=[
            PhaseRule(phase_number=1, profit_target_pct=6.0, min_trading_days=5),
        ],
        daily_drawdown_pct=0.0,
        max_drawdown_pct=5.0,    # $2,500 on $50k
        drawdown_type=DrawdownType.TRAILING_INTRADAY,
        daily_drawdown_type="None",
        weekend_holding=False,
        news_trading=True,
        profit_split_pct=90.0,
        notes="Intraday trailing drawdown, no daily loss limit.",
    ),
}


def export_catalog_json(filepath: str):
    data = {k: v.to_dict() for k, v in PROP_FIRMS.items()}
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
