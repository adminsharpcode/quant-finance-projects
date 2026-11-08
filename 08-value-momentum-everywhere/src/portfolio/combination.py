"""
Value and Momentum portfolio combination and volatility scaling.
"""

from typing import Optional
import numpy as np
import pandas as pd

from .risk_parity import FactorRiskParity


class ValMomCombiner:
    """
    Combines Value and Momentum factor weight matrices into a single multi-factor portfolio
    using Risk Parity factor weighting and aggregate volatility targeting.
    """

    def __init__(
        self,
        target_vol: float = 0.12,
        risk_parity: bool = True,
        max_leverage: float = 3.0,
    ):
        self.target_vol = target_vol
        self.risk_parity = risk_parity
        self.max_leverage = max_leverage
        self.parity_engine = FactorRiskParity()

    def combine(
        self,
        val_weights: pd.DataFrame,
        mom_weights: pd.DataFrame,
        asset_returns: pd.DataFrame,
    ) -> pd.DataFrame:
        """
        Calculates combined daily portfolio weights.
        """
        common_idx = val_weights.index.intersection(mom_weights.index).intersection(asset_returns.index)
        val_w = val_weights.loc[common_idx]
        mom_w = mom_weights.loc[common_idx]
        rets = asset_returns.loc[common_idx]
        
        # Calculate daily leg returns
        val_leg_ret = (val_w.shift(1) * rets).sum(axis=1)
        mom_leg_ret = (mom_w.shift(1) * rets).sum(axis=1)
        
        if self.risk_parity:
            w_val_factor, w_mom_factor = self.parity_engine.compute_leg_weights(val_leg_ret, mom_leg_ret)
        else:
            w_val_factor = pd.Series(0.5, index=common_idx)
            w_mom_factor = pd.Series(0.5, index=common_idx)
            
        combined_w = pd.DataFrame(index=common_idx, columns=val_w.columns, dtype=float)
        for col in val_w.columns:
            combined_w[col] = val_w[col] * w_val_factor + mom_w[col] * w_mom_factor
            
        # Volatility targeting
        # Rolling combined returns
        comb_ret_unscaled = (combined_w.shift(1) * rets).sum(axis=1)
        comb_vol = comb_ret_unscaled.rolling(60, min_periods=30).std() * np.sqrt(252.0)
        comb_vol = comb_vol.clip(lower=0.01)
        
        scaler = (self.target_vol / comb_vol).fillna(1.0)
        
        final_w = combined_w.multiply(scaler, axis=0)
        
        # Clip gross leverage
        gross_lev = final_w.abs().sum(axis=1)
        cap_scale = np.where(gross_lev > self.max_leverage, self.max_leverage / gross_lev, 1.0)
        final_w = final_w.multiply(cap_scale, axis=0)
        
        return final_w.fillna(0.0)
