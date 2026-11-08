"""
Core utilities, contract specs, and return calculations.
"""

from .contract import AssetClass, FuturesContract, CONTRACT_SPECS
from .returns import compute_daily_returns, compute_cumulative_return, compute_excess_returns

__all__ = [
    "AssetClass",
    "FuturesContract",
    "CONTRACT_SPECS",
    "compute_daily_returns",
    "compute_cumulative_return",
    "compute_excess_returns",
]
