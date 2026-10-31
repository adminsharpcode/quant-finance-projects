"""
Comprehensive Institutional Quantitative Test Suite
---------------------------------------------------
Validates:
1. Marcos López de Prado Probabilistic Sharpe Ratio (PSR)
2. Bailey & López de Prado Deflated Sharpe Ratio (DSR) & Multiple Testing Bias
3. Benjamini-Hochberg False Discovery Rate & Bonferroni FWER Corrections
4. Institutional Downside Risk Metrics (Sortino, Calmar, Omega, Ulcer Index, CVaR, CDaR)
5. Purged & Embargoed Cross-Validation (CPCV) boundary leak elimination
6. Microstructure Liquidity & Latency Stress Testing
7. Institutional Multi-Strategy Portfolio & Volatility Targeting
"""

import os
import sys
import pytest
import numpy as np
import pandas as pd

# Add project root to sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.engine.institutional_metrics import (
    compute_probabilistic_sharpe_ratio,
    compute_expected_max_sharpe,
    compute_deflated_sharpe_ratio,
    adjust_pvalues_benjamini_hochberg,
    adjust_pvalues_bonferroni,
    compute_institutional_risk_suite
)
from src.engine.walk_forward_purged import PurgedWalkForwardCV
from src.engine.stress_testing import MicrostructureStressTester
from src.engine.portfolio_allocator import InstitutionalPortfolioEngine


def test_probabilistic_sharpe_ratio_properties():
    # 1. Zero benchmark with zero Sharpe gives 50% probability
    psr_zero = compute_probabilistic_sharpe_ratio(sr=0.0, sr_benchmark=0.0, n_obs=100)
    assert psr_zero == pytest.approx(0.5, abs=1e-4)

    # 2. High positive Sharpe ratio gives near certainty
    psr_high = compute_probabilistic_sharpe_ratio(sr=2.5, sr_benchmark=0.0, n_obs=100)
    assert psr_high > 0.99

    # 3. Negative skewness (left tail risk) penalizes the PSR
    psr_normal = compute_probabilistic_sharpe_ratio(sr=1.5, sr_benchmark=0.0, n_obs=100, skew=0.0, kurt=3.0)
    psr_neg_skew = compute_probabilistic_sharpe_ratio(sr=1.5, sr_benchmark=0.0, n_obs=100, skew=-1.5, kurt=5.0)
    assert psr_neg_skew < psr_normal


def test_expected_max_sharpe_monotonicity():
    var_sr = 0.25  # std = 0.5
    emax_10 = compute_expected_max_sharpe(n_trials=10, var_sr=var_sr)
    emax_100 = compute_expected_max_sharpe(n_trials=100, var_sr=var_sr)
    emax_1297 = compute_expected_max_sharpe(n_trials=1297, var_sr=var_sr)

    # Hurdle must strictly increase as number of tested trials increases
    assert emax_10 < emax_100 < emax_1297
    assert emax_1297 > 1.5  # For 1297 trials with std 0.5, expected max noise > 1.5


def test_deflated_sharpe_ratio_haircut():
    # Simulate a corpus of 100 trials with average Sharpe 0.5 and std 0.5
    np.random.seed(42)
    corpus_sharpes = np.random.normal(loc=0.5, scale=0.5, size=100)

    # A strategy with nominal Sharpe of 1.0 (appears good on the surface)
    dsr_res_weak = compute_deflated_sharpe_ratio(sr=1.0, all_sr_trials=corpus_sharpes, n_obs=50)
    # Expected max is ~1.7, so nominal Sharpe 1.0 fails deflated test
    assert dsr_res_weak['deflated_sharpe_ratio'] < 0.50

    # A strategy with exceptional Sharpe of 3.5 survives deflation
    dsr_res_strong = compute_deflated_sharpe_ratio(sr=3.5, all_sr_trials=corpus_sharpes, n_obs=100)
    assert dsr_res_strong['deflated_sharpe_ratio'] > 0.95


def test_multiple_testing_adjustments():
    # P-values from 5 tests
    p_vals = np.array([0.001, 0.01, 0.04, 0.08, 0.50])
    
    bonf = adjust_pvalues_bonferroni(p_vals)
    bh = adjust_pvalues_benjamini_hochberg(p_vals)

    # Bonferroni is always >= BH (more conservative)
    assert np.all(bonf >= bh)
    assert bonf[0] == pytest.approx(0.005)
    assert bh[0] == pytest.approx(0.005)
    assert bh[2] == pytest.approx(0.04 * (5 / 3))


def test_institutional_risk_suite_math():
    # Simulated trade series with known properties
    trades = [100.0, -50.0, 120.0, -40.0, 80.0, -30.0, 110.0, -45.0, 95.0, -25.0]
    res = compute_institutional_risk_suite(trades, initial_capital=10000.0)

    assert res['total_trades'] == 10
    assert res['win_rate_pct'] == 50.0
    assert res['net_pnl'] == sum(trades)
    assert res['sortino_ratio'] > 0.0
    assert res['omega_ratio'] > 1.0
    assert res['gain_to_pain_ratio'] > 1.0
    assert res['ulcer_index'] >= 0.0
    assert res['var_95_dollars'] > 0.0
    assert res['cvar_95_dollars'] >= res['var_95_dollars']
    assert res['cdar_95_pct'] >= 0.0


def test_purged_walk_forward_cv_no_leakage():
    cv = PurgedWalkForwardCV(n_splits=3, train_ratio=0.6, purge_ticks=20, embargo_ticks=20)
    splits = cv.generate_splits(n_ticks=1000)

    assert len(splits) > 0
    for train_idx, test_idx in splits:
        # Train and test must be disjoint
        assert len(np.intersect1d(train_idx, test_idx)) == 0
        # Train must strictly precede test with a purge buffer
        assert np.max(train_idx) < np.min(test_idx)
        purge_gap = np.min(test_idx) - np.max(train_idx)
        assert purge_gap >= 20


def test_microstructure_stress_spread_and_latency():
    df = pd.DataFrame({
        'bid': [1.1000, 1.1002, 1.1005, 1.1004],
        'ask': [1.1002, 1.1004, 1.1007, 1.1006],
        'mid': [1.1001, 1.1003, 1.1006, 1.1005],
        'spread': [0.0002, 0.0002, 0.0002, 0.0002]
    })
    stress = MicrostructureStressTester()
    df_shock = stress.apply_spread_shock(df, spread_multiplier=3.0)

    assert df_shock['spread'].iloc[0] == pytest.approx(0.0006)
    assert df_shock['mid'].iloc[0] == pytest.approx(df['mid'].iloc[0])

    df_lat = stress.apply_latency_shock(df, latency_ticks=1)
    # Execution shifted forward
    assert df_lat['ask'].iloc[0] == df['ask'].iloc[1]


def test_portfolio_inverse_vol_and_diversification():
    port = InstitutionalPortfolioEngine(target_annual_vol_pct=10.0, initial_capital=10000.0)
    
    # Strat 1: low volatility; Strat 2: high volatility
    s1 = [10.0, -8.0, 12.0, -9.0, 11.0, -7.0, 10.0, -8.0]
    s2 = [40.0, -35.0, 45.0, -38.0, 42.0, -30.0, 39.0, -34.0]

    res = port.combine_strategies({'StratLowVol': s1, 'StratHighVol': s2}, weighting_scheme="inverse_vol")

    # Low vol strat should get higher weight in risk parity
    w_low = res['components']['StratLowVol']['weight']
    w_high = res['components']['StratHighVol']['weight']
    assert w_low > w_high
    assert w_low + w_high == pytest.approx(1.0, abs=1e-2)
    assert res['diversification_ratio'] >= 1.0

