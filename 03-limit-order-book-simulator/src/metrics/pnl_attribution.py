"""
High-Frequency Market Making PnL Attribution Engine.
Decomposes performance into Spread Capture, Inventory Drift, Adverse Selection, and Fees.
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, List
import numpy as np


@dataclass
class AttributionReport:
    total_pnl: float
    spread_capture: float
    inventory_drift: float
    adverse_selection_drag: float
    net_rebates: float
    unaccounted_residual: float

    def to_dict(self) -> Dict[str, float]:
        return {
            "total_pnl": round(self.total_pnl, 2),
            "spread_capture": round(self.spread_capture, 2),
            "inventory_drift": round(self.inventory_drift, 2),
            "adverse_selection_drag": round(self.adverse_selection_drag, 2),
            "net_rebates": round(self.net_rebates, 2),
            "unaccounted_residual": round(self.unaccounted_residual, 2),
        }


class PnLAttributionEngine:
    def __init__(self):
        self.spread_capture_acc: float = 0.0
        self.inventory_drift_acc: float = 0.0
        self.adverse_drag_acc: float = 0.0
        self.net_rebates_acc: float = 0.0

    def record_fill(
        self,
        exec_price: float,
        mid_at_fill: float,
        quantity: int,
        is_buy: bool,
        maker_rebate: float = 0.0
    ) -> None:
        """
        Spread capture on maker fill:
        For buy: mid - exec_price
        For sell: exec_price - mid
        """
        if is_buy:
            spread_profit = (mid_at_fill - exec_price) * quantity
        else:
            spread_profit = (exec_price - mid_at_fill) * quantity

        self.spread_capture_acc += spread_profit
        self.net_rebates_acc += maker_rebate

    def record_mid_step(self, inventory: int, prev_mid: float, curr_mid: float) -> None:
        """Inventory drift: q * (Mid_t - Mid_{t-1})"""
        drift = inventory * (curr_mid - prev_mid)
        self.inventory_drift_acc += drift

    def record_adverse_loss(self, loss_dollars: float) -> None:
        """Adverse selection drag from post-fill price decay."""
        self.adverse_drag_acc += loss_dollars

    def generate_report(self, observed_total_pnl: float) -> AttributionReport:
        model_pnl = (
            self.spread_capture_acc
            + self.inventory_drift_acc
            - self.adverse_drag_acc
            + self.net_rebates_acc
        )
        residual = observed_total_pnl - model_pnl

        return AttributionReport(
            total_pnl=observed_total_pnl,
            spread_capture=self.spread_capture_acc,
            inventory_drift=self.inventory_drift_acc,
            adverse_selection_drag=self.adverse_drag_acc,
            net_rebates=self.net_rebates_acc,
            unaccounted_residual=residual,
        )
