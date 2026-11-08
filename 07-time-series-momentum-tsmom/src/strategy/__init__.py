"""
Strategy components for Time Series Momentum.
"""

from .signals import (
    compute_lookback_returns,
    generate_sign_signal,
    generate_continuous_signal,
    generate_multi_horizon_tsmom,
)
from .tsmom import TSMOMStrategy

__all__ = [
    "compute_lookback_returns",
    "generate_sign_signal",
    "generate_continuous_signal",
    "generate_multi_horizon_tsmom",
    "TSMOMStrategy",
]
