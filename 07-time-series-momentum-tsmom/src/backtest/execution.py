"""
Execution cost modeling and turnover accounting for futures trading.
Includes linear cost, exchange fees, and bid-ask spread impact.
"""

from dataclasses import dataclass
import numpy as np
import pandas as pd


@dataclass
class ExecutionCostModel:
    """
    Transaction cost parameters.
    
    Parameters
    ----------
    cost_bps : float, default 5.0 (0.0005 or 5 basis points of traded volume)
    fixed_fee_per_turn : float, default 0.0
    slippage_bps : float, default 2.0 (0.0002 or 2 bps market impact)
    """
    cost_bps: float = 5.0
    fixed_fee_per_turn: float = 0.0
    slippage_bps: float = 2.0

    @property
    def total_rate(self) -> float:
        return (self.cost_bps + self.slippage_bps) / 10000.0

    def calculate_turnover_drag(self, target_weights: np.ndarray, current_weights: np.ndarray) -> float:
        """
        Calculates percentage drag from rebalancing:
        Drag = Rate * sum(|w_target - w_current|)
        """
        turnover = np.sum(np.abs(target_weights - current_weights))
        return turnover * self.total_rate
