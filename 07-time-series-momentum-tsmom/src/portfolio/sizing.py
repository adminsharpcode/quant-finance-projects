"""
Portfolio sizing and risk parity allocation for Time Series Momentum.
Formulates the exact inverse-volatility weighting and aggregate volatility targeting
from Moskowitz, Ooi, & Pedersen (2012).
"""

from typing import Optional
import numpy as np
import pandas as pd


class VolatilityTargetingSizer:
    """
    Inverse-volatility position sizer with aggregate portfolio volatility targeting.
    
    Formula from Moskowitz et al. (2012):
      w_{i, t} = (1 / sigma_{i, t}) * sign(R_{t-12, t}^i) * (sigma_target / N_t)
      
    With optional second-stage dynamic portfolio-level volatility scaling:
      w_{i, t}^{scaled} = w_{i, t} * (sigma_target / sigma_port_ex_ante)
      
    Parameters
    ----------
    target_vol : float, default 0.12 (12% annualized volatility)
    max_gross_leverage : float, default 3.5 (Max total absolute exposure)
    portfolio_vol_scaling : bool, default True
    """

    def __init__(
        self,
        target_vol: float = 0.12,
        max_gross_leverage: float = 3.5,
        portfolio_vol_scaling: bool = True,
    ):
        self.target_vol = target_vol
        self.max_gross_leverage = max_gross_leverage
        self.portfolio_vol_scaling = portfolio_vol_scaling

    def compute_weights(
        self,
        signals: pd.DataFrame,
        volatilities: pd.DataFrame,
        returns: Optional[pd.DataFrame] = None,
    ) -> pd.DataFrame:
        """
        Calculates daily asset weights for the entire backtest horizon.
        
        Parameters
        ----------
        signals : pd.DataFrame
            Directional signals S_{i, t} in [-1, 1].
        volatilities : pd.DataFrame
            Annualized ex-ante volatilities sigma_{i, t}.
        returns : pd.DataFrame, optional
            Historical returns for rolling covariance estimation (if portfolio_vol_scaling is True).
            
        Returns
        -------
        pd.DataFrame
            Target weights w_{i, t} indexed by date.
        """
        # Align indices
        common_idx = signals.index.intersection(volatilities.index)
        sig = signals.loc[common_idx]
        vol = volatilities.loc[common_idx]
        
        # Step 1: Inverse-volatility scaling per asset
        # Sizing: w_i = (1 / sigma_i) * S_i
        inv_vol = 1.0 / vol
        raw_weights = inv_vol * sig
        
        # Scale by (target_vol / N)
        n_assets = raw_weights.shape[1]
        base_weights = raw_weights * (self.target_vol / n_assets)
        
        if not self.portfolio_vol_scaling or returns is None:
            # Clip by gross leverage
            gross_leverage = base_weights.abs().sum(axis=1)
            scale = np.where(gross_leverage > self.max_gross_leverage, self.max_gross_leverage / gross_leverage, 1.0)
            return base_weights.multiply(scale, axis=0).fillna(0.0)
            
        # Step 2: Dynamic Portfolio-level Volatility Scaling
        # Estimate ex-ante portfolio volatility using rolling 60-day covariance
        cov_rolling = returns.rolling(window=60, min_periods=30).cov() * 252.0
        
        scaled_weights = pd.DataFrame(index=common_idx, columns=base_weights.columns, dtype=float)
        
        for dt in common_idx:
            w_row = base_weights.loc[dt].values
            if np.all(w_row == 0.0) or np.isnan(w_row).any():
                scaled_weights.loc[dt] = 0.0
                continue
                
            try:
                cov_t = cov_rolling.loc[dt].values
                if np.isnan(cov_t).any():
                    # Fallback to sum of variances
                    var_t = np.sum((w_row ** 2) * np.diag(cov_rolling.loc[dt].values))
                else:
                    var_t = float(w_row.T @ cov_t @ w_row)
                    
                port_vol_t = np.sqrt(max(1e-6, var_t))
                # Volatility scaler
                c_t = self.target_vol / port_vol_t
                # Apply scaler
                adj_w = w_row * c_t
                
                # Clip leverage
                total_lev = np.sum(np.abs(adj_w))
                if total_lev > self.max_gross_leverage:
                    adj_w = adj_w * (self.max_gross_leverage / total_lev)
                    
                scaled_weights.loc[dt] = adj_w
            except KeyError:
                scaled_weights.loc[dt] = w_row
                
        return scaled_weights.fillna(0.0)
