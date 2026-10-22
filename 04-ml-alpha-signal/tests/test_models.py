"""
Unit tests for alpha models (LightGBM, ElasticNet) and evaluation metrics (Rank IC, turnover).
"""

import pytest
import numpy as np
import pandas as pd
from src.models.lightgbm_alpha import LightGBMAlphaModel
from src.models.elasticnet_alpha import ElasticNetAlphaModel
from src.evaluation.information_coefficient import (
    compute_daily_ic,
    compute_ic_metrics,
    compute_quantile_returns,
)
from src.evaluation.factor_turnover import (
    compute_rank_autocorrelation,
    generate_dollar_neutral_weights,
    compute_portfolio_turnover,
    estimate_fee_drag,
)


@pytest.fixture
def regression_data():
    np.random.seed(42)
    n = 200
    X = pd.DataFrame({
        "mom_60": np.random.randn(n),
        "vol_gk": np.random.uniform(0.1, 0.5, n),
        "illiq": np.random.exponential(1.0, n),
    })
    # Target return has positive exposure to momentum and negative to illiquidity
    y = 0.05 * X["mom_60"] - 0.03 * X["illiq"] + np.random.normal(0, 0.02, n)
    return X, y


def test_lightgbm_alpha_fit_predict(regression_data):
    X, y = regression_data
    model = LightGBMAlphaModel(n_estimators=30, max_depth=3, learning_rate=0.05)
    model.fit(X, y)
    
    preds = model.predict(X)
    assert len(preds) == len(y)
    assert not np.isnan(preds).any()
    
    importances = model.feature_importances_
    assert len(importances) == 3
    assert importances.iloc[0] > 0


def test_elasticnet_alpha_fit_predict(regression_data):
    X, y = regression_data
    model = ElasticNetAlphaModel(alpha=0.001, l1_ratio=0.5)
    model.fit(X, y)
    
    preds = model.predict(X)
    assert len(preds) == len(y)
    assert len(model.coefficients_) == 3


def test_spearman_rank_ic():
    # Perfectly monotonic predictions should have Rank IC = 1.0
    dates = ["2024-01-01"] * 10
    actual = np.arange(10, dtype=float)
    predicted = actual * 2.0 + 5.0
    
    df = pd.DataFrame({"date": dates, "pred": predicted, "target": actual})
    ic_series = compute_daily_ic(df, pred_col="pred", target_col="target")
    
    assert np.isclose(ic_series.iloc[0], 1.0, atol=1e-5)
    
    metrics = compute_ic_metrics(ic_series)
    assert np.isclose(metrics["mean_ic"], 1.0, atol=1e-5)
    assert metrics["hit_rate"] == 1.0


def test_quantile_portfolio_returns():
    dates = ["2024-01-01"] * 20
    pred = np.linspace(1, 20, 20)
    target = np.linspace(0.01, 0.20, 20) # perfectly monotonic
    
    df = pd.DataFrame({"date": dates, "pred": pred, "target": target})
    q_rets, summary = compute_quantile_returns(df, pred_col="pred", target_col="target", n_quantiles=5)
    
    assert summary["is_strictly_monotonic"] is True
    assert summary["ls_mean_annualized"] > 0


def test_portfolio_turnover_and_fees():
    dates = pd.bdate_range("2024-01-01", periods=10)
    # 4 stocks
    weights_data = {
        "S1": [0.5, 0.5, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.5, 0.5],
        "S2": [0.5, 0.5, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.5, 0.5],
        "S3": [-0.5, -0.5, 0.0, 0.0, -0.5, -0.5, 0.0, 0.0, -0.5, -0.5],
        "S4": [-0.5, -0.5, 0.0, 0.0, -0.5, -0.5, 0.0, 0.0, -0.5, -0.5],
    }
    w_df = pd.DataFrame(weights_data, index=dates)
    
    turnover = compute_portfolio_turnover(w_df)
    assert len(turnover) == 10
    assert (turnover >= 0).all()
    
    fees = estimate_fee_drag(turnover, cost_per_turn_bps=5.0)
    assert fees["mean_daily_turnover"] >= 0.0
    assert fees["annual_fee_drag_pct"] >= 0.0


def test_tree_shap_attributions(regression_data):
    from src.evaluation.shap_attribution import compute_tree_shap_attributions, decompose_single_prediction
    X, y = regression_data
    model = LightGBMAlphaModel(n_estimators=20, max_depth=3)
    model.fit(X, y)
    
    shap_df, mean_shap = compute_tree_shap_attributions(model, X, max_samples=50)
    assert len(shap_df) == 50
    assert len(mean_shap) == 3
    assert (mean_shap >= 0).all()
    
    decomp = decompose_single_prediction(model, X.iloc[[0]])
    assert "expected_value" in decomp
    assert "prediction" in decomp
    assert len(decomp["contributions"]) == 3


def test_rank_autocorrelation_decay():
    # Synthetic factor with decaying persistence
    dates = pd.bdate_range("2024-01-01", periods=30)
    tickers = ["A", "B", "C", "D", "E"]
    rows = []
    for d in dates:
        for t in tickers:
            rows.append({
                "date": d,
                "ticker": t,
                "alpha": np.random.randn()
            })
    df = pd.DataFrame(rows)
    decay = compute_rank_autocorrelation(df, factor_col="alpha", lags=[1, 5])
    assert 1 in decay
    assert 5 in decay
