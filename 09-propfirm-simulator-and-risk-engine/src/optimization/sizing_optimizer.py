"""
sizing_optimizer.py
Calculates the mathematically optimal risk-per-trade (f*) to maximize prop firm
challenge pass rates while strictly bounding daily drawdown ruin probabilities.
Directly addresses 'how to pass them' through stochastic optimization.
"""

from dataclasses import dataclass
from typing import Dict, List, Tuple
import numpy as np

from ..rules.firm_catalog import PropFirmRule
from ..models.monte_carlo import PropFirmSimulator, TraderProfile
from ..models.first_passage import DoubleBarrierBrownianMotion


@dataclass
class OptimalSizingRecommendation:
    firm_name: str
    optimal_risk_pct: float
    max_safe_risk_pct: float
    pass_rate_at_optimal: float
    daily_breach_rate_at_optimal: float
    expected_days_at_optimal: float
    risk_curve: List[Dict[str, float]]
    actionable_rules: List[str]


class PropFirmSizingOptimizer:
    """
    Optimizes risk per trade f* across the parameter space.
    """

    def __init__(self, firm_rule: PropFirmRule, win_rate: float, reward_to_risk: float, trades_per_day: int = 2):
        self.firm = firm_rule
        self.win_rate = win_rate
        self.reward_to_risk = reward_to_risk
        self.trades_per_day = trades_per_day

    def find_optimal_risk(
        self,
        risk_candidates: Tuple[float, ...] = (0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 2.00),
        num_simulations_per_point: int = 1500,
    ) -> OptimalSizingRecommendation:
        """
        Evaluates pass rates and daily breach rates across candidate risk percentages.
        """
        curve = []
        best_risk = 0.50
        max_pass_rate = -1.0
        best_daily_breach = 1.0
        best_days = 999.0

        for r_pct in risk_candidates:
            f_decimal = r_pct / 100.0
            profile = TraderProfile(
                win_rate=self.win_rate,
                reward_to_risk=self.reward_to_risk,
                risk_per_trade_pct=f_decimal,
                trades_per_day=self.trades_per_day,
            )
            sim = PropFirmSimulator(self.firm, profile, account_size=100_000.0, max_simulation_days=90, seed=123)
            res = sim.simulate(num_paths=num_simulations_per_point)

            point = {
                "risk_pct": r_pct,
                "pass_rate_pct": res.pass_rate_overall * 100.0,
                "daily_breach_pct": res.ruin_due_to_daily_dd_pct * 100.0,
                "max_breach_pct": res.ruin_due_to_max_dd_pct * 100.0,
                "expected_days": res.expected_days_to_pass,
            }
            curve.append(point)

            # Optimization criterion:
            # We want maximum pass rate, with penalty if daily breach > 5%
            score = res.pass_rate_overall - 1.5 * res.ruin_due_to_daily_dd_pct
            if score > max_pass_rate and res.ruin_due_to_daily_dd_pct <= 0.08:
                max_pass_rate = score
                best_risk = r_pct
                best_daily_breach = res.ruin_due_to_daily_dd_pct
                best_days = res.expected_days_to_pass

        # Maximum safe risk calculation
        # To survive 4 consecutive losses in a day without hitting daily limit:
        # 4 * f < daily_dd -> f < daily_dd / 4
        if self.firm.daily_drawdown_pct > 0:
            max_safe = min(1.0, self.firm.daily_drawdown_pct / (self.trades_per_day * 1.5))
        else:
            max_safe = self.firm.max_drawdown_pct / 6.0

        # Actionable rules
        rules = [
            f"Set risk-per-trade strictly to {best_risk:.2f}% (Never exceed {max_safe:.2f}%).",
            f"Daily Stop: Cease trading immediately for the day if you hit 2 consecutive losses (-{best_risk*2:.2f}%).",
            f"Phase 2 De-risking: Cut risk in half (to {best_risk/2:.2f}%) once within 1.5% of the target.",
            f"Consistency Protection: Never let any single winning trade represent > 30% of total challenge profit.",
        ]

        return OptimalSizingRecommendation(
            firm_name=self.firm.name,
            optimal_risk_pct=best_risk,
            max_safe_risk_pct=max_safe,
            pass_rate_at_optimal=max(0.0, max_pass_rate),
            daily_breach_rate_at_optimal=best_daily_breach,
            expected_days_at_optimal=best_days,
            risk_curve=curve,
            actionable_rules=rules,
        )
