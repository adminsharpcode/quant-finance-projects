r"""
Marcos López de Prado's Purged K-Fold Cross-Validation with Embargo.

Reference:
    Marcos López de Prado (2018), "Advances in Financial Machine Learning",
    Chapter 7: Cross-Validation in Finance.

Key Innovations:
1. Purging: Removes training samples whose forward label evaluation horizons
   overlap with the test evaluation span:
       [t_{i, 0}, t_{i, 1}] \cap [T_{0, test}, T_{1, test}] \ne \emptyset
2. Embargoing: Discards training samples immediately following test periods
   to neutralize autoregressive memory leakage:
       t_{i, 0} \in [T_{1, test}, T_{1, test} + h]
3. Multi-Asset Grouping: Handles multi-ticker panels by grouping cross-sectional
   dates together so test folds evaluate all universe assets simultaneously.
"""

from typing import Generator, List, Optional, Tuple, Union
import numpy as np
import pandas as pd


class PurgedKFold:
    """
    Purged K-Fold Cross-Validation with Embargo for Financial Time Series.
    
    Parameters:
        n_splits: Number of cross-validation folds.
        samples_info: Series or DataFrame indexed identically to X, containing:
                      - index: Sample index
                      - values / 'event_end': Timestamp when the forward label horizon concludes
                        (e.g., t + 5 days for a 5-day forward return).
                      If None, assumes 1-period non-overlapping labels.
        embargo_pct: Percentage of total observations/dates to embargo after each test fold.
    """
    def __init__(
        self,
        n_splits: int = 5,
        samples_info: Optional[pd.Series] = None,
        embargo_pct: float = 0.02
    ):
        if n_splits < 2:
            raise ValueError(f"n_splits must be at least 2, got {n_splits}")
        self.n_splits = n_splits
        self.samples_info = samples_info
        self.embargo_pct = max(0.0, embargo_pct)

    def split(
        self,
        X: pd.DataFrame,
        y: Optional[pd.Series] = None,
        groups: Optional[pd.Series] = None
    ) -> Generator[Tuple[np.ndarray, np.ndarray], None, None]:
        """
        Generate train and test indices guaranteeing zero data leakage.
        
        Parameters:
            X: Feature matrix with datetime or integer index
            y: Optional target labels
            groups: Grouping array (e.g. date series) to ensure cross-sectional dates
                    are never split between train and test.
        """
        n_samples = len(X)
        indices = np.arange(n_samples)
        
        # If groups (dates) provided, split on unique dates
        if groups is not None:
            unique_groups = pd.Series(groups).drop_duplicates().sort_values().values
            n_groups = len(unique_groups)
            group_indices = np.arange(n_groups)
            fold_bounds = np.linspace(0, n_groups, self.n_splits + 1, dtype=int)
        else:
            n_groups = n_samples
            group_indices = indices
            fold_bounds = np.linspace(0, n_samples, self.n_splits + 1, dtype=int)
            
        embargo_size = int(n_groups * self.embargo_pct)
        
        # Build event end times mapping
        if self.samples_info is not None:
            t1 = self.samples_info
        else:
            # Fallback: assume sample index is chronological timestamp or integer
            t1 = pd.Series(X.index if not isinstance(X.index, pd.RangeIndex) else indices, index=X.index)

        # Dates / timestamps for each row
        t0 = pd.Series(groups.values if groups is not None else X.index, index=X.index)

        for fold in range(self.n_splits):
            start_grp_idx = fold_bounds[fold]
            end_grp_idx = fold_bounds[fold + 1]
            
            if groups is not None:
                test_grps = unique_groups[start_grp_idx:end_grp_idx]
                test_mask = pd.Series(groups).isin(test_grps).values
                test_idx = indices[test_mask]
            else:
                test_idx = indices[start_grp_idx:end_grp_idx]
                
            if len(test_idx) == 0:
                continue
                
            # Test fold time span
            test_t0_min = t0.iloc[test_idx].min()
            test_t1_max = t1.iloc[test_idx].max()
            
            # 1. Purge: remove training samples whose label window overlaps test span
            # Condition for overlap: (sample_t0 <= test_t1_max) & (sample_t1 >= test_t0_min)
            overlap_mask = (t0 <= test_t1_max) & (t1 >= test_t0_min)
            train_mask = ~overlap_mask.values
            
            # 2. Embargo: remove training samples occurring within embargo window after test_t1_max
            if embargo_size > 0 and groups is not None:
                post_test_grps = unique_groups[end_grp_idx : min(end_grp_idx + embargo_size, n_groups)]
                if len(post_test_grps) > 0:
                    embargo_mask = pd.Series(groups).isin(post_test_grps).values
                    train_mask = train_mask & (~embargo_mask)
            elif embargo_size > 0:
                embargo_end_idx = min(end_grp_idx + embargo_size, n_samples)
                embargo_mask = np.zeros(n_samples, dtype=bool)
                embargo_mask[end_grp_idx:embargo_end_idx] = True
                train_mask = train_mask & (~embargo_mask)
                
            train_idx = indices[train_mask]
            
            # Verify disjointness
            assert len(np.intersect1d(train_idx, test_idx)) == 0, "Train and test overlap detected!"
            
            yield train_idx, test_idx


class PurgedWalkForwardCV:
    """
    Purged Walk-Forward Cross-Validation.
    Expanding-window training with purging and embargo, modeling real-world production deployment.
    
    Timeline:
        [--- Train Window ---] [ Purge ] [ Test Window ] [ Embargo ] ...
    """
    def __init__(
        self,
        n_splits: int = 5,
        min_train_pct: float = 0.40,
        samples_info: Optional[pd.Series] = None,
        embargo_pct: float = 0.02
    ):
        self.n_splits = n_splits
        self.min_train_pct = min_train_pct
        self.samples_info = samples_info
        self.embargo_pct = max(0.0, embargo_pct)

    def split(
        self,
        X: pd.DataFrame,
        groups: Optional[pd.Series] = None
    ) -> Generator[Tuple[np.ndarray, np.ndarray], None, None]:
        n_samples = len(X)
        indices = np.arange(n_samples)
        
        if groups is not None:
            unique_dates = pd.Series(groups).drop_duplicates().sort_values().values
            n_dates = len(unique_dates)
            t0 = pd.Series(groups.values, index=X.index)
        else:
            unique_dates = indices
            n_dates = n_samples
            t0 = pd.Series(indices, index=X.index)
            
        t1 = self.samples_info if self.samples_info is not None else t0
        
        start_date_idx = int(n_dates * self.min_train_pct)
        remaining_dates = n_dates - start_date_idx
        test_step = remaining_dates // self.n_splits
        
        for k in range(self.n_splits):
            test_start_d = start_date_idx + k * test_step
            test_end_d = test_start_d + test_step if k < self.n_splits - 1 else n_dates
            
            if groups is not None:
                test_dates = unique_dates[test_start_d:test_end_d]
                test_idx = indices[pd.Series(groups).isin(test_dates).values]
            else:
                test_idx = indices[test_start_d:test_end_d]
                
            if len(test_idx) == 0:
                continue
                
            test_t0_min = t0.iloc[test_idx].min()
            test_t1_max = t1.iloc[test_idx].max()
            
            # Prior history only for walk-forward: sample_t0 < test_t0_min
            # AND purge forward labels: sample_t1 < test_t0_min
            purge_mask = (t1 < test_t0_min)
            train_idx = indices[purge_mask.values]
            
            assert len(np.intersect1d(train_idx, test_idx)) == 0, "Walk-forward train and test overlap!"
            yield train_idx, test_idx


def verify_no_temporal_leakage(
    train_indices: np.ndarray,
    test_indices: np.ndarray,
    t0_series: pd.Series,
    t1_series: pd.Series
) -> bool:
    """
    Mathematical assertion that zero train observations have label windows
    overlapping test start or end timestamps.
    """
    test_t0_min = t0_series.iloc[test_indices].min()
    test_t1_max = t1_series.iloc[test_indices].max()
    
    train_t0 = t0_series.iloc[train_indices]
    train_t1 = t1_series.iloc[train_indices]
    
    # Check overlap: (train_t0 <= test_t1_max) & (train_t1 >= test_t0_min)
    overlap = (train_t0 <= test_t1_max) & (train_t1 >= test_t0_min)
    if overlap.any():
        num_leaks = overlap.sum()
        raise AssertionError(f"Critical Data Leakage Detected: {num_leaks} train samples overlap test window!")
    return True
