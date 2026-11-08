"""
Risk budgeting, marginal risk contribution (MRC), and asset class exposure attribution.
"""

from typing import Dict
import numpy as np
import pandas as pd

from ..core.contract import CONTRACT_SPECS, AssetClass


class RiskBudgetAnalyzer:
    """
    Decomposes portfolio risk and capital allocation by asset class:
    Equities, Fixed Income, FX, and Commodities.
    """

    def __init__(self, specs: Dict = CONTRACT_SPECS):
        self.specs = specs

    def compute_asset_class_weights(self, weights: pd.DataFrame) -> pd.DataFrame:
        """
        Aggregates individual contract weights into asset-class level gross and net exposures.
        """
        ac_map = {sym: spec.asset_class.value for sym, spec in self.specs.items() if sym in weights.columns}
        
        # Gross exposure by asset class
        gross_weights = weights.abs().T.groupby(ac_map).sum().T
        return gross_weights

    def compute_asset_class_net_weights(self, weights: pd.DataFrame) -> pd.DataFrame:
        """
        Aggregates net exposure by asset class.
        """
        ac_map = {sym: spec.asset_class.value for sym, spec in self.specs.items() if sym in weights.columns}
        return weights.T.groupby(ac_map).sum().T

    def compute_marginal_risk_contributions(
        self, 
        weights: np.ndarray, 
        cov_matrix: np.ndarray
    ) -> np.ndarray:
        """
        Calculates Marginal Contribution to Risk (MCR):
        MCR_i = (Sigma * w)_i / sigma_p
        Risk_Contribution_i = w_i * MCR_i
        """
        port_var = float(weights.T @ cov_matrix @ weights)
        if port_var <= 1e-12:
            return np.zeros_like(weights)
        port_vol = np.sqrt(port_var)
        mcr = (cov_matrix @ weights) / port_vol
        rc = weights * mcr
        return rc / port_vol  # Normalized to sum to 1.0
