"""
Risk parity factor weighting.
Calculates inverse-volatility parity weights between Value and Momentum legs.
"""

from typing import Tuple
import numpy as np
import pandas as pd


class FactorRiskParity:
    """
    Computes equal-risk-contribution weights between Value and Momentum legs:
      w_val = (1 / sigma_val) / (1 / sigma_val + 1 / sigma_mom)
      w_mom = (1 / sigma_mom) / (1 / sigma_val + 1 / sigma_mom)
    """

    def __init__(self, rolling_window: int = 60, min_periods: int = 20):
        self.rolling_window = rolling_window
        self.min_periods = min_periods

    def compute_leg_weights(
        self, 
        val_returns: pd.Series, 
        mom_returns: pd.Series
    ) -> Tuple[pd.Series, pd.Series]:
        """
        Returns rolling daily risk-parity weights for Value and Momentum legs.
        """
        val_vol = val_returns.rolling(self.rolling_window, min_periods=self.min_periods).std() * np.sqrt(252.0)
        mom_vol = mom_returns.rolling(self.rolling_window, min_periods=self.min_periods).std() * np.sqrt(252.0)
        
        val_vol = val_vol.clip(lower=0.01)
        mom_vol = mom_vol.clip(lower=0.01)
        
        inv_val = 1.0 / val_vol
        inv_mom = 1.0 / mom_vol
        sum_inv = inv_val + inv_mom
        
        w_val = inv_val / sum_inv
        w_mom = inv_mom / sum_inv
        
        # Fill warm-up with 50/50
        return w_val.fillna(0.5), w_mom.fillna(0.5)
