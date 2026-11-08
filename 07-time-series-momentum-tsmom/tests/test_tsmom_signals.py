"""
Unit tests for Time Series Momentum signal generation.
"""

import numpy as np
import pandas as pd
import pytest

from src.strategy.signals import (
    compute_lookback_returns,
    generate_sign_signal,
    generate_continuous_signal,
    generate_multi_horizon_tsmom,
)


def test_lookback_returns():
    dates = pd.date_range("2020-01-01", periods=10, freq="B")
    prices = pd.DataFrame({"AssetA": [100.0 * (1.1 ** i) for i in range(10)]}, index=dates)
    
    # 2-day lookback return: (P_t / P_{t-2}) - 1 = (1.1)^2 - 1 = 0.21
    ret_2 = compute_lookback_returns(prices, 2)
    assert ret_2["AssetA"].iloc[2] == pytest.approx(0.21, rel=1e-5)
    assert pd.isna(ret_2["AssetA"].iloc[1])


def test_sign_signal():
    dates = pd.date_range("2020-01-01", periods=5, freq="B")
    lookback = pd.DataFrame({"A": [np.nan, 0.05, -0.02, 0.10, -0.01]}, index=dates)
    
    sig = generate_sign_signal(lookback)
    assert sig["A"].iloc[0] == 0.0  # NaN becomes 0
    assert sig["A"].iloc[1] == 1.0  # +0.05 -> +1
    assert sig["A"].iloc[2] == -1.0 # -0.02 -> -1
    assert sig["A"].iloc[3] == 1.0  # +0.10 -> +1
    assert sig["A"].iloc[4] == -1.0 # -0.01 -> -1


def test_continuous_signal_clipping():
    dates = pd.date_range("2020-01-01", periods=5, freq="B")
    rets = pd.DataFrame({"A": [0.5, -0.5, 0.01, -0.01, 0.0]}, index=dates)
    vol = pd.DataFrame({"A": [0.1, 0.1, 0.1, 0.1, 0.1]}, index=dates)
    
    sig = generate_continuous_signal(rets, vol, lookback_days=252, max_leverage=2.0)
    assert (sig["A"] <= 2.0).all()
    assert (sig["A"] >= -2.0).all()


def test_multi_horizon_blend():
    dates = pd.date_range("2020-01-01", periods=300, freq="B")
    # Upward trending asset
    prices = pd.DataFrame({"ES": np.linspace(1000, 2000, 300)}, index=dates)
    
    blended = generate_multi_horizon_tsmom(prices)
    # Once lookback reaches 252 days, all horizons (1M, 3M, 6M, 12M) should be +1, so blend = 1.0
    assert blended["ES"].iloc[260] == pytest.approx(1.0)
