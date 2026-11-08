"""
Cross-sectional Momentum factor generator.
Implements the 12-month momentum with 1-month skip per Asness et al. (2013).
"""

import pandas as pd
from ..core.returns import compute_skip_month_return
from .ranking import rank_cross_sectional, construct_dollar_neutral_weights


class MomentumFactor:
    """
    Computes cross-sectional momentum:
      MOM_{i, t} = (P_{t-skip} / P_{t-lookback}) - 1.0
      Default: lookback = 252 days (12M), skip = 21 days (1M).
    """

    def __init__(self, lookback_days: int = 252, skip_days: int = 21):
        self.lookback_days = lookback_days
        self.skip_days = skip_days

    def compute_scores(self, prices: pd.DataFrame) -> pd.DataFrame:
        """Computes raw momentum score (past return)."""
        return compute_skip_month_return(prices, self.lookback_days, self.skip_days)

    def compute_weights(self, prices: pd.DataFrame, gross_leverage: float = 1.0) -> pd.DataFrame:
        """Computes dollar-neutral portfolio weights."""
        scores = self.compute_scores(prices)
        ranks = rank_cross_sectional(scores, ascending=True) # highest return = highest rank (long winners)
        return construct_dollar_neutral_weights(ranks, gross_leverage=gross_leverage)
