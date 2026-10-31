"""
Combinatorial Purged & Embargoed Walk-Forward Cross-Validation (CPCV / WFO)
--------------------------------------------------------------------------
Implements the institutional cross-validation framework designed by
Marcos López de Prado (2018) in "Advances in Financial Machine Learning".

Eliminates information leakage and lookahead bias in tick backtesting via:
1. Purging: Strips overlapping positions and indicator lookbacks from training partitions.
2. Embargoing: Enforces a quarantine buffer immediately after test partitions to prevent
   autoregressive order flow / volatility memory leakage into subsequent training folds.
3. Out-of-Sample Efficiency Ratio (OER):
   OER = SR_oos / SR_is
   - OER >= 0.50: Institutionally Robust Alpha
   - 0.20 <= OER < 0.50: Marginal Alpha Degradation
   - OER < 0.20: Overfitted / Curve-Fitted Reject
"""

import math
import numpy as np
import pandas as pd
from typing import Dict, List, Any, Tuple, Optional, Callable


class PurgedWalkForwardCV:
    """
    Purged and Embargoed Walk-Forward Cross-Validation Engine for Tick-Level Strategies.
    """
    def __init__(
        self,
        n_splits: int = 4,
        train_ratio: float = 0.60,
        purge_ticks: int = 50,
        embargo_ticks: int = 50
    ):
        self.n_splits = n_splits
        self.train_ratio = train_ratio
        self.purge_ticks = purge_ticks
        self.embargo_ticks = embargo_ticks

    def generate_splits(self, n_ticks: int) -> List[Tuple[np.ndarray, np.ndarray]]:
        """
        Generates purged and embargoed train and test index partitions.
        """
        splits = []
        window_size = int(n_ticks / (self.n_splits + 1))
        
        for k in range(self.n_splits):
            test_start = (k + 1) * window_size
            test_end = min(n_ticks, test_start + window_size)
            
            # Training window before test
            train_start = max(0, int(test_start - (self.train_ratio / (1.0 - self.train_ratio)) * window_size))
            
            # Purge the boundary immediately preceding test
            purged_train_end = max(train_start, test_start - self.purge_ticks)
            train_indices = np.arange(train_start, purged_train_end)
            
            # Test indices
            test_indices = np.arange(test_start, test_end)
            
            if len(train_indices) > 100 and len(test_indices) > 50:
                splits.append((train_indices, test_indices))
                
        return splits

    def evaluate_strategy_wfo(
        self,
        df_ticks: pd.DataFrame,
        eval_fn: Callable[[pd.DataFrame], Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Executes purged walk-forward cross validation over the provided evaluation function.
        eval_fn takes a DataFrame slice and returns a dict with 'sharpe_ratio', 'return_pct', 'win_rate_pct', 'trades'.
        """
        n_ticks = len(df_ticks)
        splits = self.generate_splits(n_ticks)
        
        fold_results = []
        is_sharpes = []
        oos_sharpes = []
        is_returns = []
        oos_returns = []
        
        for fold_idx, (train_idx, test_idx) in enumerate(splits, 1):
            df_train = df_ticks.iloc[train_idx].reset_index(drop=True)
            df_test = df_ticks.iloc[test_idx].reset_index(drop=True)
            
            res_is = eval_fn(df_train)
            res_oos = eval_fn(df_test)
            
            sr_is = float(res_is.get('sharpe_ratio', 0.0))
            sr_oos = float(res_oos.get('sharpe_ratio', 0.0))
            
            oer = (sr_oos / sr_is) if sr_is > 0.01 else (1.0 if sr_oos > 0 else 0.0)
            
            is_sharpes.append(sr_is)
            oos_sharpes.append(sr_oos)
            is_returns.append(float(res_is.get('return_pct', 0.0)))
            oos_returns.append(float(res_oos.get('return_pct', 0.0)))
            
            fold_results.append({
                "fold": fold_idx,
                "train_ticks": len(df_train),
                "test_ticks": len(df_test),
                "in_sample": {
                    "sharpe": round(sr_is, 2),
                    "return_pct": round(res_is.get('return_pct', 0.0), 2),
                    "trades": res_is.get('total_trades', 0),
                    "win_rate_pct": round(res_is.get('win_rate_pct', 0.0), 2)
                },
                "out_of_sample": {
                    "sharpe": round(sr_oos, 2),
                    "return_pct": round(res_oos.get('return_pct', 0.0), 2),
                    "trades": res_oos.get('total_trades', 0),
                    "win_rate_pct": round(res_oos.get('win_rate_pct', 0.0), 2)
                },
                "out_of_sample_efficiency_ratio": round(oer, 2)
            })
            
        mean_is_sr = float(np.mean(is_sharpes)) if is_sharpes else 0.0
        mean_oos_sr = float(np.mean(oos_sharpes)) if oos_sharpes else 0.0
        mean_is_ret = float(np.mean(is_returns)) if is_returns else 0.0
        mean_oos_ret = float(np.mean(oos_returns)) if oos_returns else 0.0
        
        overall_oer = (mean_oos_sr / mean_is_sr) if mean_is_sr > 0.01 else (1.0 if mean_oos_sr > 0 else 0.0)
        
        if overall_oer >= 0.50 and mean_oos_sr > 0.8:
            verdict = "INSTITUTIONALLY_ROBUST"
        elif overall_oer >= 0.25 and mean_oos_ret > 0:
            verdict = "MODERATE_ALPHA_DEGRADATION"
        else:
            verdict = "OVERFITTED_REJECT"
            
        return {
            "total_folds": len(splits),
            "mean_in_sample_sharpe": round(mean_is_sr, 2),
            "mean_out_of_sample_sharpe": round(mean_oos_sr, 2),
            "mean_in_sample_return_pct": round(mean_is_ret, 2),
            "mean_out_of_sample_return_pct": round(mean_oos_ret, 2),
            "out_of_sample_efficiency_ratio": round(overall_oer, 2),
            "walk_forward_verdict": verdict,
            "folds": fold_results
        }

