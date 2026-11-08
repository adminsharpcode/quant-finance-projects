"""
Time Series Momentum (TSMOM) Strategy pipeline.
Integrates volatility estimators with multi-horizon sign signals.
"""

from typing import Dict, Optional
import pandas as pd

from ..estimator.volatility import BaseVolatilityEstimator, RollingVolatilityEstimator
from .signals import compute_lookback_returns, generate_sign_signal, generate_multi_horizon_tsmom


class TSMOMStrategy:
    """
    Moskowitz, Ooi, & Pedersen (2012) Time Series Momentum Strategy.
    
    Parameters
    ----------
    lookback_days : int, default 252 (12 Months)
        Lookback window in trading days.
    vol_estimator : BaseVolatilityEstimator, optional
        Estimator for ex-ante volatility scaling. Default 60-day rolling.
    multi_horizon : bool, default False
        Whether to blend 1M, 3M, 6M, 12M lookbacks.
    threshold : float, default 0.0
        Sign activation threshold.
    """
    
    def __init__(
        self,
        lookback_days: int = 252,
        vol_estimator: Optional[BaseVolatilityEstimator] = None,
        multi_horizon: bool = False,
        threshold: float = 0.0,
    ):
        self.lookback_days = lookback_days
        self.vol_estimator = vol_estimator or RollingVolatilityEstimator(window=60)
        self.multi_horizon = multi_horizon
        self.threshold = threshold

    def compute_signals(self, prices: pd.DataFrame) -> pd.DataFrame:
        """
        Computes directional signals S_{i, t} in [-1, +1].
        """
        if self.multi_horizon:
            return generate_multi_horizon_tsmom(prices)
        else:
            lookback_rets = compute_lookback_returns(prices, self.lookback_days)
            return generate_sign_signal(lookback_rets, self.threshold)

    def compute_volatilities(self, daily_returns: pd.DataFrame) -> pd.DataFrame:
        """
        Computes ex-ante volatilities sigma_{i, t}.
        """
        return self.vol_estimator.estimate(daily_returns)
