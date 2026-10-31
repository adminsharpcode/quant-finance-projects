"""
Test Suite for Machine Learning Strategy Miner & Meta-Labeler
--------------------------------------------------------------
Validates:
1. Feature extraction from 1,297 codebase metadata
2. Random Forest and Gradient Boosting classifier training
3. Feature importance calculation & ranking
4. K-Means clustering and PCA latent dimension reduction
5. Marcos López de Prado Meta-Labeling signal generation & execution filter
"""

import os
import sys
import pytest
import numpy as np
import pandas as pd

# Add project root to sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.engine.ml_strategy_miner import MLStrategyMiner
from src.engine.ml_meta_labeler import MLMetaLabeler


@pytest.fixture
def sample_miner():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cat_p = os.path.join(root, "data", "mq4_strategy_catalog.json")
    seq_p = os.path.join(root, "data", "sequential_test_results.json")
    return MLStrategyMiner(cat_p, seq_p)


def test_ml_miner_feature_extraction(sample_miner):
    df = sample_miner.extract_dataset()
    assert len(df) > 100
    assert 'tp_sl_ratio' in df.columns
    assert 'is_martingale' in df.columns
    assert 'is_profitable' in df.columns
    assert 'has_iMA' in df.columns
    assert 'has_iATR' in df.columns
    assert df['tp_sl_ratio'].min() >= 0.0


def test_ml_miner_supervised_training(sample_miner):
    sample_miner.extract_dataset()
    results = sample_miner.train_profitability_models()
    
    assert results['dataset_samples'] > 100
    assert results['rf_cv_auc_mean'] > 0.70  # Model has strong discriminative power
    assert len(results['top_profitability_factors']) >= 5
    # tp_sl_ratio or extracted_tp should be top drivers
    top_feature_names = [f['feature'] for f in results['top_profitability_factors'][:3]]
    assert any('tp' in f or 'sl' in f for f in top_feature_names)


def test_ml_miner_unsupervised_clustering(sample_miner):
    sample_miner.extract_dataset()
    clustering = sample_miner.perform_unsupervised_clustering(n_clusters=4)
    
    assert clustering['total_clusters'] == 4
    assert len(clustering['pca_explained_variance']) == 2
    assert sum(clustering['pca_explained_variance']) > 0.30
    assert 'cluster_0' in clustering['clusters']
    assert 'cluster_1' in clustering['clusters']


def test_ml_meta_labeler_execution():
    # Synthetic micro-dataset
    n = 200
    mids = [1.2500 + 0.0001 * np.sin(i / 8.0) for i in range(n)]
    df = pd.DataFrame({
        'bid': [round(m - 0.00005, 5) for m in mids],
        'ask': [round(m + 0.00005, 5) for m in mids],
        'mid': mids,
        'spread': [0.00010 for _ in mids]
    })
    
    meta = MLMetaLabeler(
        pip_size=0.0001,
        lot_size=100000.0,
        initial_capital=10000.0,
        sl_pips=10.0,
        tp_pips=20.0,
        prob_threshold=0.50
    )
    sig_df = meta.build_signal_dataset(df)
    assert 'spread_ratio' in sig_df.columns
    assert 'volatility_ratio' in sig_df.columns
    assert 'zscore_displacement' in sig_df.columns
    assert 'label_profit' in sig_df.columns
