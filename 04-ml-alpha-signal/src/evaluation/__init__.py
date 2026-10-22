"""
Evaluation and performance attribution suite.
"""

from .information_coefficient import (
    compute_daily_ic,
    compute_ic_metrics,
    compute_quantile_returns,
)
from .factor_turnover import (
    compute_rank_autocorrelation,
    generate_dollar_neutral_weights,
    compute_portfolio_turnover,
    estimate_fee_drag,
)
from .shap_attribution import (
    compute_tree_shap_attributions,
    decompose_single_prediction,
)

__all__ = [
    "compute_daily_ic",
    "compute_ic_metrics",
    "compute_quantile_returns",
    "compute_rank_autocorrelation",
    "generate_dollar_neutral_weights",
    "compute_portfolio_turnover",
    "estimate_fee_drag",
    "compute_tree_shap_attributions",
    "decompose_single_prediction",
]
