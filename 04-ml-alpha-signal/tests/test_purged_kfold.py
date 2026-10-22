"""
Unit tests for Marcos López de Prado's Purged K-Fold Cross-Validation with Embargo.
"""

import pytest
import numpy as np
import pandas as pd
from src.validation.purged_kfold import (
    PurgedKFold,
    PurgedWalkForwardCV,
    verify_no_temporal_leakage,
)


@pytest.fixture
def sample_market_data():
    """Generates synthetic panel dataset with 10 tickers over 100 business dates."""
    dates = pd.bdate_range(start="2024-01-01", periods=100)
    tickers = [f"TICK_{i}" for i in range(10)]
    
    rows = []
    for d in dates:
        for t in tickers:
            rows.append({
                "date": d,
                "ticker": t,
                "feature_1": np.random.randn(),
                "feature_2": np.random.randn(),
            })
            
    df = pd.DataFrame(rows)
    return df


def test_purged_kfold_no_overlap(sample_market_data):
    df = sample_market_data
    
    # 5-day forward return horizon: label ends at date + 5 business days
    t0 = pd.to_datetime(df["date"])
    t1 = t0 + pd.Timedelta(days=7) # ~5 business days
    
    pkf = PurgedKFold(n_splits=5, samples_info=t1, embargo_pct=0.02)
    
    for fold, (train_idx, test_idx) in enumerate(pkf.split(df, groups=df["date"])):
        # Train and test must be completely disjoint
        intersect = np.intersect1d(train_idx, test_idx)
        assert len(intersect) == 0, f"Fold {fold}: Train and test share {len(intersect)} indices"
        
        # Verify no temporal overlap: no training sample should have label span overlapping test span
        verify_no_temporal_leakage(train_idx, test_idx, t0, t1)


def test_embargo_buffer_application(sample_market_data):
    df = sample_market_data
    t0 = pd.to_datetime(df["date"])
    t1 = t0 # 1-day labels
    
    # Compare train set size with 0% vs 5% embargo
    pkf_no_embargo = PurgedKFold(n_splits=5, samples_info=t1, embargo_pct=0.0)
    pkf_with_embargo = PurgedKFold(n_splits=5, samples_info=t1, embargo_pct=0.05)
    
    train_lens_no = [len(tr) for tr, _ in pkf_no_embargo.split(df, groups=df["date"])]
    train_lens_emb = [len(tr) for tr, _ in pkf_with_embargo.split(df, groups=df["date"])]
    
    # Folds with subsequent dates should have fewer training samples due to embargo
    # Fold 0 has following dates, so embargo must remove some training dates
    assert train_lens_emb[0] < train_lens_no[0]


def test_walk_forward_causality(sample_market_data):
    df = sample_market_data
    t0 = pd.to_datetime(df["date"])
    t1 = t0 + pd.Timedelta(days=7)
    
    wf = PurgedWalkForwardCV(n_splits=4, min_train_pct=0.40, samples_info=t1, embargo_pct=0.02)
    
    for fold, (train_idx, test_idx) in enumerate(wf.split(df, groups=df["date"])):
        # In walk-forward, all training samples must strictly precede test window start
        test_start = t0.iloc[test_idx].min()
        train_end_label = t1.iloc[train_idx].max()
        
        assert train_end_label < test_start, (
            f"Fold {fold}: Walk forward causality violated! Train label ends at {train_end_label}, "
            f"while test begins at {test_start}"
        )


def test_leakage_detector_catches_intentional_leak():
    dates = pd.date_range("2024-01-01", periods=10, freq="D")
    t0 = pd.Series(dates)
    t1 = pd.Series(dates + pd.Timedelta(days=3))
    
    # Train index 0 has label window [Jan 1, Jan 4]
    # Test index 2 has label window [Jan 3, Jan 6] -> overlap!
    train_idx = np.array([0, 1])
    test_idx = np.array([2, 3])
    
    with pytest.raises(AssertionError):
        verify_no_temporal_leakage(train_idx, test_idx, t0, t1)
