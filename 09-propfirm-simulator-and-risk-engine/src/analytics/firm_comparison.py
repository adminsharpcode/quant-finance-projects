"""
firm_comparison.py
Ranks all 22 proprietary trading firms by Mathematical Difficulty Index (MDI)
and benchmarks survival rates across diverse trader archetypes.
"""

from dataclasses import dataclass
from typing import Dict, List
import pandas as pd
import numpy as np

from ..rules.firm_catalog import PROP_FIRMS, PropFirmRule, DrawdownType
from ..models.monte_carlo import PropFirmSimulator, TraderProfile


TRADER_ARCHETYPES: Dict[str, TraderProfile] = {
    "1_Random_Gambler": TraderProfile(win_rate=0.45, reward_to_risk=1.0, risk_per_trade_pct=0.015, trades_per_day=4),
    "2_Average_Retail": TraderProfile(win_rate=0.50, reward_to_risk=1.2, risk_per_trade_pct=0.010, trades_per_day=3),
    "3_Disciplined_Scalper": TraderProfile(win_rate=0.55, reward_to_risk=1.3, risk_per_trade_pct=0.005, trades_per_day=3),
    "4_Trend_Quant": TraderProfile(win_rate=0.42, reward_to_risk=2.5, risk_per_trade_pct=0.006, trades_per_day=2),
    "5_High_Win_Sniper": TraderProfile(win_rate=0.65, reward_to_risk=1.2, risk_per_trade_pct=0.005, trades_per_day=2),
}


def calculate_mathematical_difficulty_index(rule: PropFirmRule) -> float:
    """
    Computes Mathematical Difficulty Index (MDI):
      Lower = Trader-Friendly / Higher Mathematical Survival
      Higher = Tougher / Predatory Trailing Traps
    """
    total_target = sum(p.profit_target_pct for p in rule.phases)
    max_dd = rule.max_drawdown_pct
    
    base_ratio = total_target / max(1.0, max_dd)
    
    # Penalties for trailing drawdowns
    if rule.drawdown_type == DrawdownType.TRAILING_INTRADAY:
        trailing_mult = 2.2 # Intraday trailing is notorious for stopping out winning trades
    elif rule.drawdown_type == DrawdownType.TRAILING_EOD:
        trailing_mult = 1.4
    elif rule.drawdown_type == DrawdownType.RELATIVE:
        trailing_mult = 1.3
    else:
        trailing_mult = 1.0 # Static is most lenient
        
    # Penalty for tight daily limits
    if rule.daily_drawdown_pct > 0:
        daily_penalty = 5.0 / rule.daily_drawdown_pct
    else:
        daily_penalty = 1.0
        
    mdi = base_ratio * trailing_mult * (0.8 + 0.2 * daily_penalty)
    return round(float(mdi), 2)


def run_cross_firm_benchmark(num_paths: int = 1000) -> pd.DataFrame:
    """
    Runs benchmark matrix of all 22 prop firms against the Disciplined Scalper archetype.
    """
    profile = TRADER_ARCHETYPES["3_Disciplined_Scalper"]
    records = []
    
    for fid, firm in PROP_FIRMS.items():
        sim = PropFirmSimulator(firm, profile, seed=42)
        res = sim.simulate(num_paths=num_paths)
        mdi = calculate_mathematical_difficulty_index(firm)
        
        records.append({
            "Firm ID": fid,
            "Firm Name": firm.name,
            "Market": firm.market.value,
            "Phases": firm.total_phases,
            "Target (%)": sum(p.profit_target_pct for p in firm.phases),
            "Daily DD (%)": firm.daily_drawdown_pct,
            "Max DD (%)": firm.max_drawdown_pct,
            "DD Type": firm.drawdown_type.value,
            "MDI Difficulty": mdi,
            "Pass Rate (%)": res.pass_rate_overall * 100.0,
            "Ruin Rate (%)": res.ruin_rate_overall * 100.0,
            "Daily Breach (%)": res.ruin_due_to_daily_dd_pct * 100.0,
            "Avg Days": res.expected_days_to_pass,
        })
        
    df = pd.DataFrame(records)
    # Sort by Pass Rate descending
    return df.sort_values(by="Pass Rate (%)", ascending=False).reset_index(drop=True)
