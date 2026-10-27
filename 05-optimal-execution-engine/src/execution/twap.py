"""
Time-Weighted Average Price (TWAP) Execution Strategy.

Splits an institutional order into uniform slices across discrete time bins.
Corresponds mathematically to the risk-neutral (lambda -> 0) limit of Almgren-Chriss.
"""

import numpy as np


class TWAPStrategy:
    """TWAP execution benchmark schedule generator."""

    def __init__(self, total_shares: float, intervals: int):
        self.total_shares = total_shares
        self.intervals = intervals

    def calculate_trajectory(self) -> np.ndarray:
        """
        Holdings trajectory x_k decreasing linearly from X to 0.
        Length: intervals + 1
        """
        return np.linspace(self.total_shares, 0.0, self.intervals + 1)

    def calculate_trade_sizes(self) -> np.ndarray:
        """Equal sized slices for all intervals."""
        slice_size = self.total_shares / self.intervals
        return np.full(self.intervals, slice_size)
