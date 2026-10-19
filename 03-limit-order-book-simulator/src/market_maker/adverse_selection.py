"""
Adverse Selection & Kyle's Lambda Microstructure Analyzer.
Measures post-fill price drift and distinguishes informed vs noise flow.
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import List, Dict, Optional
import numpy as np
from ..engine.order import Side
from ..engine.matching_engine import Trade


@dataclass
class FillRecord:
    trade_id: int
    exec_price: float
    quantity: int
    mm_bought: bool
    fill_time_ns: int
    event_idx: int


class AdverseSelectionAnalyzer:
    def __init__(self, horizons: Optional[List[int]] = None):
        # Horizons in number of subsequent trades (e.g. 1, 5, 10, 20 trades ahead)
        self.horizons: List[int] = horizons if horizons is not None else [1, 5, 10, 20]
        self._fills: List[FillRecord] = []
        self._mid_history: List[float] = []

    def record_fill(self, trade: Trade, is_mm_buyer: bool) -> None:
        idx = len(self._mid_history)
        self._fills.append(
            FillRecord(
                trade_id=trade.trade_id,
                exec_price=trade.price,
                quantity=trade.quantity,
                mm_bought=is_mm_buyer,
                fill_time_ns=trade.timestamp_ns,
                event_idx=idx,
            )
        )

    def record_mid_price(self, mid_price: float) -> None:
        self._mid_history.append(mid_price)

    def compute_adverse_selection_metrics(self) -> Dict[str, float]:
        """
        Calculates average post-trade adverse price drift across horizons:
        Drift_tau = Sign(MM_Position) * (Mid_{t+tau} - ExecPrice)
        If MM bought: drift < 0 means price dropped post-fill (adverse selection).
        If MM sold: drift > 0 means price rose post-fill (adverse selection).
        """
        if not self._fills or not self._mid_history:
            defaults = {f"drift_{h}_trades": 0.0 for h in self.horizons}
            defaults["kyles_lambda"] = 0.0012
            defaults["total_adverse_cost"] = 0.0
            return defaults

        n_mids = len(self._mid_history)
        results: Dict[str, float] = {}
        total_adverse_loss = 0.0

        for h in self.horizons:
            drifts = []
            for fill in self._fills:
                target_idx = fill.event_idx + h
                if target_idx < n_mids:
                    future_mid = self._mid_history[target_idx]
                    if fill.mm_bought:
                        # Bought: price drop is adverse
                        drift = future_mid - fill.exec_price
                        loss = max(0.0, fill.exec_price - future_mid) * fill.quantity
                    else:
                        # Sold: price rise is adverse
                        drift = fill.exec_price - future_mid
                        loss = max(0.0, future_mid - fill.exec_price) * fill.quantity
                    drifts.append(drift)
                    if h == self.horizons[0]:
                        total_adverse_loss += loss

            results[f"drift_{h}_trades"] = round(float(np.mean(drifts)), 4) if drifts else 0.0

        # Estimate Kyle's Lambda (price impact per share)
        kyles_lambda = self._estimate_kyles_lambda()
        results["kyles_lambda"] = round(kyles_lambda, 6)
        results["total_adverse_cost"] = round(total_adverse_loss, 2)
        return results

    def _estimate_kyles_lambda(self) -> float:
        """
        Regresses delta P on signed square-root volume:
        Delta P_t = lambda * Sign_t * sqrt(V_t) + eps
        """
        if len(self._fills) < 10 or len(self._mid_history) < 10:
            return 0.0012

        y = []
        x = []
        for fill in self._fills:
            if fill.event_idx + 1 < len(self._mid_history):
                dp = self._mid_history[fill.event_idx + 1] - fill.exec_price
                signed_sqrt_v = (1 if fill.mm_bought else -1) * np.sqrt(fill.quantity)
                y.append(dp)
                x.append(signed_sqrt_v)

        if not x:
            return 0.0012

        x_arr = np.array(x)
        y_arr = np.array(y)
        denominator = np.sum(x_arr ** 2)
        if denominator == 0:
            return 0.0012
        return float(np.sum(x_arr * y_arr) / denominator)
