"""
Unit tests for institutional analytics and crisis alpha metrics.
"""

import numpy as np
import pandas as pd
import pytest

from src.analytics.metrics import calculate_metrics, calculate_drawdown_series
from src.analytics.crisis_alpha import CrisisAlphaAnalyzer


def test_drawdown_calculation():
    returns = pd.Series([0.10, -0.20, 0.05])
    # Wealth index: 1.10, 0.88, 0.924
    # Peak: 1.10, 1.10, 1.10
    # DD: 0.0, (0.88 - 1.10)/1.10 = -0.20, (0.924 - 1.10)/1.10 = -0.16
    dd = calculate_drawdown_series(returns)
    assert dd.iloc[0] == pytest.approx(0.0)
    assert dd.iloc[1] == pytest.approx(-0.20)
    assert dd.iloc[2] == pytest.approx(-0.16)


def test_metrics_synthetic():
    np.random.seed(42)
    # 252 days with mean 0.10/252, std 0.15/sqrt(252)
    daily_mu = 0.10 / 252.0
    daily_sigma = 0.15 / np.sqrt(252.0)
    r = pd.Series(np.random.normal(daily_mu, daily_sigma, 252))
    
    metrics = calculate_metrics(r)
    assert metrics.cagr > 0.0
    assert metrics.annualized_volatility == pytest.approx(0.15, rel=0.15)
    assert metrics.max_drawdown <= 0.0
    assert 0.0 < metrics.win_rate_daily < 1.0


def test_crisis_alpha_regimes():
    dates = pd.date_range("2008-01-01", "2008-12-31", freq="B")
    strat = pd.Series(0.001, index=dates)  # steady positive
    bench = pd.Series(-0.002, index=dates) # steady negative
    
    analyzer = CrisisAlphaAnalyzer()
    df_regimes = analyzer.evaluate_regimes(strat, bench)
    assert len(df_regimes) > 0
    gfc_row = df_regimes[df_regimes["Crisis Regime"] == "2008 Financial Crisis"]
    assert not gfc_row.empty
    assert gfc_row["Alpha Spread (%)"].iloc[0] > 0
