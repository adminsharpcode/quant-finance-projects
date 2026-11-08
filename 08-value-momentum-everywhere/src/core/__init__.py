"""
Core universe and return processing.
"""

from .universe import EQUITIES_UNIVERSE, MACRO_UNIVERSE, ALL_UNIVERSE, ASSET_METADATA
from .returns import compute_daily_returns, compute_skip_month_return

__all__ = [
    "EQUITIES_UNIVERSE",
    "MACRO_UNIVERSE",
    "ALL_UNIVERSE",
    "ASSET_METADATA",
    "compute_daily_returns",
    "compute_skip_month_return",
]
