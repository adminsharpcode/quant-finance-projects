"""
Volume-Weighted Average Price (VWAP) Execution Strategy.

Distributes child orders proportionally to the historical intraday U-curve
volume distribution (heavy at market open and close, thin midday).
"""

from typing import Optional
import numpy as np


class VWAPStrategy:
    """VWAP execution schedule generator."""

    def __init__(self, total_shares: float, intervals: int, volume_profile: Optional[np.ndarray] = None):
        self.total_shares = total_shares
        self.intervals = intervals
        if volume_profile is None:
            self.volume_profile = self._generate_canonical_u_curve(intervals)
        else:
            assert len(volume_profile) == intervals, "Volume profile must match number of intervals"
            self.volume_profile = volume_profile / np.sum(volume_profile)

    @staticmethod
    def _generate_canonical_u_curve(n_bins: int) -> np.ndarray:
        """
        Generate empirical intraday U-shaped volume curve:
        High volume at market open (09:30), lull around 12:30-13:30, high at market close (16:00).
        """
        x = np.linspace(-1, 1, n_bins)
        # Parabolic U-curve + baseline
        curve = 0.5 * (x ** 2) + 0.3
        return curve / np.sum(curve)

    def calculate_trade_sizes(self) -> np.ndarray:
        """Calculate shares traded per bin: n_k = X * w_k."""
        return self.total_shares * self.volume_profile

    def calculate_trajectory(self) -> np.ndarray:
        """
        Holdings trajectory x_k where x_0 = X and x_N = 0.
        """
        trades = self.calculate_trade_sizes()
        x = np.zeros(self.intervals + 1)
        x[0] = self.total_shares
        for i, trade in enumerate(trades):
            x[i + 1] = max(0.0, x[i] - trade)
        x[-1] = 0.0
        return x
