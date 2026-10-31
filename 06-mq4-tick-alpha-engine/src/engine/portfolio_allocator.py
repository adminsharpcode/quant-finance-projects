"""
Institutional Portfolio Allocation & Volatility Targeting Engine
-----------------------------------------------------------------
Combines vetted non-martingale alpha strategies into an institutional multi-asset portfolio:
1. Equal Weighting (1/N)
2. Inverse Volatility Risk Parity Weighting (1/sigma_i)
3. Dynamic Volatility Targeting Overlay (e.g., 10.0% target annual volatility)
4. Portfolio Diversification Metrics:
   - Diversification Ratio
   - Strategy Return Correlation Matrix
   - Combined Portfolio Sharpe, Sortino, Calmar, and Underwater Profile
"""

import math
import numpy as np
import pandas as pd
from typing import Dict, List, Any, Tuple, Optional
from src.engine.institutional_metrics import compute_institutional_risk_suite


class InstitutionalPortfolioEngine:
    """
    Manages multi-strategy alpha aggregation, risk budgeting, and volatility targeting.
    """
    def __init__(
        self,
        target_annual_vol_pct: float = 12.0,
        max_leverage: float = 2.0,
        initial_capital: float = 10000.0,
        annualization_factor: float = np.sqrt(252 * 5)
    ):
        self.target_annual_vol_pct = target_annual_vol_pct
        self.max_leverage = max_leverage
        self.initial_capital = initial_capital
        self.annualization_factor = annualization_factor

    def compute_weights_inverse_vol(self, returns_matrix: np.ndarray) -> np.ndarray:
        """
        Computes inverse volatility weights: w_i = (1 / sigma_i) / sum(1 / sigma_j)
        """
        n_assets = returns_matrix.shape[1]
        stds = np.std(returns_matrix, axis=0, ddof=1)
        stds = np.where(stds < 1e-6, 1e-6, stds)
        
        inv_vols = 1.0 / stds
        weights = inv_vols / np.sum(inv_vols)
        return weights

    def compute_diversification_ratio(self, returns_matrix: np.ndarray, weights: np.ndarray) -> float:
        """
        Computes Choueifaty & Coignard (2008) Diversification Ratio:
        DR = sum(w_i * sigma_i) / sigma_portfolio
        DR > 1.0 indicates diversification benefit.
        """
        stds = np.std(returns_matrix, axis=0, ddof=1)
        weighted_vol_sum = float(np.sum(weights * stds))
        
        cov_matrix = np.cov(returns_matrix, rowvar=False)
        port_variance = float(weights.T @ cov_matrix @ weights)
        port_vol = math.sqrt(max(1e-12, port_variance))
        
        return weighted_vol_sum / port_vol if port_vol > 1e-8 else 1.0

    def combine_strategies(
        self,
        strategy_returns: Dict[str, List[float]],
        weighting_scheme: str = "inverse_vol"
    ) -> Dict[str, Any]:
        """
        Aggregates multiple strategy trade return streams into a unified portfolio.
        """
        names = list(strategy_returns.keys())
        n_strats = len(names)
        if n_strats == 0:
            return {}

        # Align series lengths by padding/truncating to minimum common length or equal length
        min_len = min(len(s) for s in strategy_returns.values())
        if min_len < 3:
            return {"error": "Insufficient trade data for portfolio allocation"}

        aligned_returns = np.column_stack([np.array(strategy_returns[name][:min_len]) for name in names])

        # Compute Weights
        if weighting_scheme == "inverse_vol":
            weights = self.compute_weights_inverse_vol(aligned_returns)
        else:
            weights = np.ones(n_strats) / n_strats

        # Raw weighted portfolio returns
        raw_port_returns = aligned_returns @ weights

        # Volatility Targeting Overlay
        realized_vol = float(np.std(raw_port_returns, ddof=1) * self.annualization_factor)
        # Convert dollar std to percentage of initial capital
        realized_vol_pct = (realized_vol / self.initial_capital) * 100.0

        if realized_vol_pct > 0.01:
            vol_target_scalar = min(self.max_leverage, self.target_annual_vol_pct / realized_vol_pct)
        else:
            vol_target_scalar = 1.0

        scaled_port_returns = raw_port_returns * vol_target_scalar

        # Compute Institutional Risk Suite for the Portfolio
        port_metrics = compute_institutional_risk_suite(
            scaled_port_returns,
            initial_capital=self.initial_capital,
            annualization_factor=self.annualization_factor
        )

        # Correlation Matrix
        if min_len >= 2:
            corr_mat = np.corrcoef(aligned_returns, rowvar=False)
            corr_dict = {}
            for i, name_i in enumerate(names):
                corr_dict[name_i] = {}
                for j, name_j in enumerate(names):
                    corr_dict[name_i][name_j] = round(float(corr_mat[i, j]), 3)
        else:
            corr_dict = {}

        # Diversification Ratio
        dr = self.compute_diversification_ratio(aligned_returns, weights)

        # Component summaries
        components = {}
        for idx, name in enumerate(names):
            comp_metrics = compute_institutional_risk_suite(
                strategy_returns[name],
                initial_capital=self.initial_capital,
                annualization_factor=self.annualization_factor
            )
            components[name] = {
                "weight": round(float(weights[idx]), 3),
                "sharpe_ratio": comp_metrics['sharpe_ratio'],
                "sortino_ratio": comp_metrics['sortino_ratio'],
                "return_pct": comp_metrics['return_pct'],
                "max_drawdown_pct": comp_metrics['max_drawdown_pct']
            }

        return {
            "weighting_scheme": weighting_scheme,
            "target_annual_vol_pct": self.target_annual_vol_pct,
            "realized_vol_pct": round(realized_vol_pct, 2),
            "vol_target_scalar": round(float(vol_target_scalar), 2),
            "diversification_ratio": round(float(dr), 2),
            "correlation_matrix": corr_dict,
            "components": components,
            "portfolio_metrics": port_metrics
        }

