"""
Cross-sectional Value factor generator.
Implements fundamental Book-to-Price (B/P) and 5-Year Reversal per Asness et al. (2013).
"""

from typing import Optional
import pandas as pd
from ..core.returns import compute_skip_month_return
from .ranking import rank_cross_sectional, construct_dollar_neutral_weights


class ValueFactor:
    """
    Computes cross-sectional value scores.
    Supports:
      1. Fundamental Book-to-Price (B/P)
      2. 5-Year Reversal (-R_{t-1260, t-21}) as established in Asness et al. (2013)
    """

    def __init__(self, mode: str = "book_to_price", reversal_lookback_days: int = 1260, skip_days: int = 21):
        self.mode = mode
        self.reversal_lookback_days = reversal_lookback_days
        self.skip_days = skip_days

    def compute_scores(self, prices: pd.DataFrame, bp_data: Optional[pd.DataFrame] = None) -> pd.DataFrame:
        """
        Computes raw value scores: higher score = cheaper asset.
        """
        if self.mode == "book_to_price" and bp_data is not None:
            return bp_data
        else:
            # 5-Year price reversal: - (P_{t-skip} / P_{t-lookback} - 1.0)
            # Declining assets over 5 years are cheap; appreciating assets are expensive.
            ret_5y = compute_skip_month_return(prices, self.reversal_lookback_days, self.skip_days)
            return -ret_5y

    def compute_weights(
        self, 
        prices: pd.DataFrame, 
        bp_data: Optional[pd.DataFrame] = None, 
        gross_leverage: float = 1.0
    ) -> pd.DataFrame:
        """Computes dollar-neutral portfolio weights."""
        scores = self.compute_scores(prices, bp_data)
        ranks = rank_cross_sectional(scores, ascending=True) # highest value score = highest rank (long cheap)
        return construct_dollar_neutral_weights(ranks, gross_leverage=gross_leverage)
