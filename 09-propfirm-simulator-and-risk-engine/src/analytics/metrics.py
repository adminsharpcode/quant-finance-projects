"""
Performance metrics and risk-adjusted challenge survival scores.
"""

from typing import Dict
import numpy as np


def compute_edge_requirement(target_pct: float, max_dd_pct: float, risk_pct: float) -> Dict[str, float]:
    """
    Computes required win rate for a given reward-to-risk ratio
    to achieve at least 50% analytical probability of passing.
    """
    # For Gambler's ruin with drift mu:
    # We want s = 2*mu / sigma^2 > 0 -> mu > 0
    # E[R] = p * R - (1-p) > 0 -> p > 1 / (1 + R)
    ratios = [1.0, 1.5, 2.0, 2.5, 3.0]
    breakeven_p = {}
    for R in ratios:
        p_be = 1.0 / (1.0 + R)
        breakeven_p[f"R:R_{R}"] = round(p_be * 100.0, 1)
    return breakeven_p
