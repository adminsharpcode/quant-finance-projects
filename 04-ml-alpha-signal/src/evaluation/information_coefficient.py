"""
Information Coefficient (IC) and Quantile Portfolio Analysis.

Implements:
1. Daily Spearman Rank Information Coefficient (Rank IC).
2. Daily Pearson Linear Information Coefficient.
3. Annualized Information Ratio (IC_IR) and t-statistic.
4. Quantile Bucket Sorting (Q1 to Q5) and Long-Short Spread.
5. Monotonicity Test.
"""

from typing import Dict, List, Optional, Tuple, Union
import numpy as np
import pandas as pd
from scipy import stats


def compute_daily_ic(
    df: pd.DataFrame,
    pred_col: str,
    target_col: str,
    date_col: str = "date",
    method: str = "spearman"
) -> pd.Series:
    """
    Calculate cross-sectional Information Coefficient for each timestamp.
    
    Parameters:
        df: Dataframe with predictions, targets, and dates
        pred_col: Alpha prediction column name
        target_col: Realized forward return column name
        date_col: Timestamp column
        method: 'spearman' (Rank IC, robust) or 'pearson'
        
    Returns:
        pd.Series of daily IC values indexed by date
    """
    def _calc_ic(sub: pd.DataFrame) -> float:
        x = sub[pred_col].values
        y = sub[target_col].values
        valid = (~np.isnan(x)) & (~np.isnan(y))
        if np.sum(valid) < 3:
            return np.nan
        if method == "spearman":
            res = stats.spearmanr(x[valid], y[valid])
            return float(res.statistic if hasattr(res, 'statistic') else res[0])
        else:
            res = stats.pearsonr(x[valid], y[valid])
            return float(res.statistic if hasattr(res, 'statistic') else res[0])

    return df.groupby(date_col).apply(_calc_ic, include_groups=False)


def compute_ic_metrics(ic_series: pd.Series) -> Dict[str, float]:
    """
    Compute comprehensive IC summary metrics:
    - Mean IC
    - Std IC
    - IC Information Ratio (IC_IR = Mean / Std * sqrt(252))
    - T-statistic of IC
    - P-value (two-tailed)
    - Positive IC Percentage (Hit Rate)
    """
    valid_ic = ic_series.dropna()
    n = len(valid_ic)
    if n == 0:
        return {
            "mean_ic": 0.0,
            "std_ic": 0.0,
            "ic_ir": 0.0,
            "t_stat": 0.0,
            "p_value": 1.0,
            "hit_rate": 0.5,
            "n_dates": 0,
        }
        
    mean_ic = float(valid_ic.mean())
    if n < 2:
        return {
            "mean_ic": mean_ic,
            "std_ic": 0.0,
            "ic_ir": 0.0,
            "t_stat": 0.0,
            "p_value": 0.0,
            "hit_rate": 1.0 if mean_ic > 0 else 0.0,
            "n_dates": 1,
        }
        
    std_ic = float(valid_ic.std(ddof=1))
    
    if std_ic < 1e-12:
        ic_ir = 0.0
        t_stat = 0.0
        p_val = 1.0
    else:
        ic_ir = (mean_ic / std_ic) * np.sqrt(252.0)
        t_stat = mean_ic / (std_ic / np.sqrt(n))
        p_val = float(2.0 * (1.0 - stats.t.cdf(np.abs(t_stat), df=n - 1)))
        
    hit_rate = float((valid_ic > 0).mean())
    
    return {
        "mean_ic": mean_ic,
        "std_ic": std_ic,
        "ic_ir": ic_ir,
        "t_stat": t_stat,
        "p_value": p_val,
        "hit_rate": hit_rate,
        "n_dates": n,
    }


def compute_quantile_returns(
    df: pd.DataFrame,
    pred_col: str,
    target_col: str,
    n_quantiles: int = 5,
    date_col: str = "date"
) -> Tuple[pd.DataFrame, Dict[str, float]]:
    """
    Partition cross-section into n equal quantiles (e.g. Q1...Q5 quintiles) per date.
    
    Returns:
        1. DataFrame with daily return per quantile and Long-Short spread (Q_top - Q_bottom)
        2. Dict of summary statistics (Sharpe, annualized return, spread, monotonicity)
    """
    df_eval = df[[date_col, pred_col, target_col]].dropna().copy()
    
    def _assign_quantile(s: pd.Series) -> pd.Series:
        return pd.qcut(s, q=n_quantiles, labels=[f"Q{i+1}" for i in range(n_quantiles)], duplicates="drop")

    df_eval["quantile"] = df_eval.groupby(date_col)[pred_col].transform(_assign_quantile)
    
    # Daily mean return per quantile
    q_returns = df_eval.groupby([date_col, "quantile"])[target_col].mean().unstack("quantile")
    
    top_col = f"Q{n_quantiles}"
    bottom_col = "Q1"
    
    if top_col in q_returns.columns and bottom_col in q_returns.columns:
        q_returns["Long_Short"] = q_returns[top_col] - q_returns[bottom_col]
    else:
        q_returns["Long_Short"] = 0.0
        
    # Summary metrics
    mean_q = q_returns.mean()
    ls_series = q_returns["Long_Short"]
    ls_mean = float(ls_series.mean())
    ls_std = float(ls_series.std())
    ls_sharpe = (ls_mean / ls_std * np.sqrt(252.0)) if ls_std > 1e-12 else 0.0
    
    # Monotonicity test: check if Q1 < Q2 < ... < Qn
    q_means = [mean_q[f"Q{i+1}"] for i in range(n_quantiles) if f"Q{i+1}" in mean_q]
    monotonic = all(x <= y for x, y in zip(q_means, q_means[1:]))
    
    summary = {
        "ls_mean_annualized": ls_mean * 252.0,
        "ls_std_annualized": ls_std * np.sqrt(252.0),
        "ls_sharpe": ls_sharpe,
        "is_strictly_monotonic": monotonic,
        "mean_returns_by_quantile": mean_q.to_dict(),
    }
    
    return q_returns, summary
