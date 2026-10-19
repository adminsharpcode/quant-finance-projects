"""
Order Flow Imbalance (OFI) Calculator.
Cont, Kukanov, & Stoikov (2014) microstructure order flow metric.
"""

from __future__ import annotations
from typing import Optional, List, Dict
import numpy as np


class OrderFlowImbalanceTracker:
    def __init__(self, rolling_window: int = 50):
        self.rolling_window = rolling_window
        self.prev_bid_price: Optional[float] = None
        self.prev_bid_volume: int = 0
        self.prev_ask_price: Optional[float] = None
        self.prev_ask_volume: int = 0

        self.ofi_history: List[float] = []
        self.mid_price_diffs: List[float] = []

    def update(
        self,
        best_bid: Optional[float],
        best_bid_vol: int,
        best_ask: Optional[float],
        best_ask_vol: int,
        mid_price: Optional[float] = None
    ) -> float:
        """
        Updates OFI based on new top-of-book quotes.
        Returns the instantaneous event OFI value.
        """
        if best_bid is None or best_ask is None:
            return 0.0

        if self.prev_bid_price is None or self.prev_ask_price is None:
            self.prev_bid_price = best_bid
            self.prev_bid_volume = best_bid_vol
            self.prev_ask_price = best_ask
            self.prev_ask_volume = best_ask_vol
            return 0.0

        # Bid side contribution
        if best_bid > self.prev_bid_price:
            delta_bid = best_bid_vol
        elif best_bid == self.prev_bid_price:
            delta_bid = best_bid_vol - self.prev_bid_volume
        else:
            delta_bid = -self.prev_bid_volume

        # Ask side contribution
        if best_ask < self.prev_ask_price:
            delta_ask = best_ask_vol
        elif best_ask == self.prev_ask_price:
            delta_ask = best_ask_vol - self.prev_ask_volume
        else:
            delta_ask = -self.prev_ask_volume

        ofi_val = float(delta_bid - delta_ask)

        # Mid price delta
        prev_mid = (self.prev_bid_price + self.prev_ask_price) / 2.0
        curr_mid = mid_price if mid_price is not None else (best_bid + best_ask) / 2.0
        dp = curr_mid - prev_mid

        self.ofi_history.append(ofi_val)
        self.mid_price_diffs.append(dp)

        self.prev_bid_price = best_bid
        self.prev_bid_volume = best_bid_vol
        self.prev_ask_price = best_ask
        self.prev_ask_volume = best_ask_vol

        return ofi_val

    @property
    def rolling_ofi(self) -> float:
        """Sum of OFI over the active rolling window."""
        if not self.ofi_history:
            return 0.0
        return float(np.sum(self.ofi_history[-self.rolling_window:]))

    def estimate_price_impact_beta(self) -> float:
        """
        Estimates market depth elasticity beta:
        Delta P_t = beta * OFI_t + epsilon
        Returns price change per unit of order imbalance.
        """
        if len(self.ofi_history) < 10:
            return 0.0005

        n = min(len(self.ofi_history), 200)
        x = np.array(self.ofi_history[-n:])
        y = np.array(self.mid_price_diffs[-n:])

        var_x = np.sum(x ** 2)
        if var_x == 0:
            return 0.0005
        beta = float(np.sum(x * y) / var_x)
        return max(1e-6, beta)

    def to_dict(self) -> Dict[str, float]:
        return {
            "current_ofi": self.ofi_history[-1] if self.ofi_history else 0.0,
            "rolling_ofi": self.rolling_ofi,
            "price_impact_beta": self.estimate_price_impact_beta(),
        }
