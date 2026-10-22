"""
Feature extraction suite for cross-sectional alpha generation.
"""

from .price_momentum import (
    compute_reversal,
    compute_dual_momentum,
    compute_residual_momentum,
    compute_macd_spread,
)
from .volatility_estimators import (
    compute_historical_volatility,
    compute_parkinson_volatility,
    compute_garman_klass_volatility,
    compute_yang_zhang_volatility,
    compute_volatility_ratio,
)
from .microstructure import (
    compute_amihud_illiquidity,
    compute_roll_spread,
    compute_corwin_schultz_spread,
    compute_volume_surprise,
)

__all__ = [
    "compute_reversal",
    "compute_dual_momentum",
    "compute_residual_momentum",
    "compute_macd_spread",
    "compute_historical_volatility",
    "compute_parkinson_volatility",
    "compute_garman_klass_volatility",
    "compute_yang_zhang_volatility",
    "compute_volatility_ratio",
    "compute_amihud_illiquidity",
    "compute_roll_spread",
    "compute_corwin_schultz_spread",
    "compute_volume_surprise",
]
