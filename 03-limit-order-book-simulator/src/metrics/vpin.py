"""
Volume-Synchronized Probability of Toxicity (VPIN) Calculator.
Easley, López de Prado, & O'Hara (2012) toxic flow detection.
"""

from __future__ import annotations
from typing import List, Dict, Optional
import numpy as np
from ..engine.order import Side
from ..engine.matching_engine import Trade


class VolumeBucket:
    __slots__ = ("bucket_size", "buy_volume", "sell_volume")

    def __init__(self, bucket_size: int):
        self.bucket_size = bucket_size
        self.buy_volume: int = 0
        self.sell_volume: int = 0

    @property
    def total_volume(self) -> int:
        return self.buy_volume + self.sell_volume

    @property
    def remaining(self) -> int:
        return max(0, self.bucket_size - self.total_volume)

    @property
    def is_full(self) -> bool:
        return self.total_volume >= self.bucket_size

    @property
    def imbalance(self) -> int:
        return abs(self.buy_volume - self.sell_volume)


class VPINCalculator:
    def __init__(self, bucket_size: int = 500, window_size: int = 30):
        self.bucket_size = bucket_size
        self.window_size = window_size

        self.current_bucket = VolumeBucket(bucket_size)
        self.completed_buckets: List[VolumeBucket] = []

    def update_trade(self, trade: Trade) -> Optional[float]:
        """
        Ingests a trade into volume buckets.
        Returns updated VPIN if at least one bucket completes, otherwise current VPIN.
        """
        remaining_trade_qty = trade.quantity
        is_buy = trade.taker_side == Side.BUY

        while remaining_trade_qty > 0:
            fill_space = self.current_bucket.remaining
            qty_to_bucket = min(remaining_trade_qty, fill_space)

            if is_buy:
                self.current_bucket.buy_volume += qty_to_bucket
            else:
                self.current_bucket.sell_volume += qty_to_bucket

            remaining_trade_qty -= qty_to_bucket

            if self.current_bucket.is_full:
                self.completed_buckets.append(self.current_bucket)
                self.current_bucket = VolumeBucket(self.bucket_size)

        return self.vpin

    @property
    def vpin(self) -> float:
        """
        VPIN = (sum of |V_B - V_S|) / (N * V)
        over the last N completed buckets.
        """
        if not self.completed_buckets:
            return 0.20  # Neutral baseline prior to first bucket completion

        active_window = self.completed_buckets[-self.window_size:]
        total_imbalance = sum(b.imbalance for b in active_window)
        total_volume = len(active_window) * self.bucket_size

        if total_volume == 0:
            return 0.20

        raw_vpin = total_imbalance / total_volume
        return round(float(np.clip(raw_vpin, 0.0, 1.0)), 4)

    @property
    def is_toxic(self) -> bool:
        """Flagged when VPIN exceeds the 75th percentile danger threshold (0.50)."""
        return self.vpin > 0.50

    def to_dict(self) -> Dict[str, float]:
        return {
            "vpin": self.vpin,
            "buckets_completed": float(len(self.completed_buckets)),
            "bucket_fill_pct": round(self.current_bucket.total_volume / self.bucket_size * 100.0, 1),
            "is_toxic": 1.0 if self.is_toxic else 0.0,
        }
