"""
Unit tests for alpha feature extractors (momentum, volatility estimators, microstructure).
"""

import pytest
import numpy as np
import pandas as pd
from src.features.price_momentum import (
    compute_reversal,
    compute_dual_momentum,
    compute_residual_momentum,
    compute_macd_spread,
)
from src.features.volatility_estimators import (
    compute_historical_volatility,
    compute_parkinson_volatility,
    compute_garman_klass_volatility,
    compute_yang_zhang_volatility,
    compute_volatility_ratio,
)
from src.features.microstructure import (
    compute_amihud_illiquidity,
    compute_roll_spread,
    compute_corwin_schultz_spread,
    compute_volume_surprise,
)


@pytest.fixture
def ohlcv_dataframe():
    """Create 100 days of synthetic OHLCV data for 2 tickers."""
    dates = pd.bdate_range("2024-01-01", periods=100)
    rows = []
    np.random.seed(42)
    
    for t in ["AAPL", "MSFT"]:
        p = 150.0
        for d in dates:
            ret = np.random.normal(0.0005, 0.015)
            p_close = p * np.exp(ret)
            p_open = p * np.exp(np.random.normal(0, 0.005))
            p_high = max(p_open, p_close) * (1.0 + abs(np.random.normal(0, 0.008)))
            p_low = min(p_open, p_close) * (1.0 - abs(np.random.normal(0, 0.008)))
            vol = int(np.random.lognormal(16, 0.3))
            
            rows.append({
                "date": d,
                "ticker": t,
                "open": p_open,
                "high": p_high,
                "low": p_low,
                "close": p_close,
                "volume": vol,
            })
            p = p_close
            
    df = pd.DataFrame(rows)
    return df


def test_momentum_reversal_features(ohlcv_dataframe):
    df = ohlcv_dataframe
    
    rev = compute_reversal(df, window=5)
    assert len(rev) == len(df)
    assert not rev.dropna().empty
    
    dual_mom = compute_dual_momentum(df, lookback_window=30, skip_window=5)
    assert len(dual_mom) == len(df)
    assert not dual_mom.dropna().empty
    
    macd = compute_macd_spread(df, fast_span=12, slow_span=26)
    assert len(macd) == len(df)
    assert not macd.dropna().empty


def test_volatility_estimators(ohlcv_dataframe):
    df = ohlcv_dataframe
    
    hist_vol = compute_historical_volatility(df, window=20)
    parkinson = compute_parkinson_volatility(df, window=20)
    garman_klass = compute_garman_klass_volatility(df, window=20)
    yang_zhang = compute_yang_zhang_volatility(df, window=20)
    
    # Must all be non-negative
    assert (parkinson.dropna() >= 0).all()
    assert (garman_klass.dropna() >= 0).all()
    assert (yang_zhang.dropna() >= 0).all()
    assert (hist_vol.dropna() >= 0).all()
    
    # Check reasonable annualized bounds (typically 5% to 150%)
    assert parkinson.dropna().median() > 0.05
    assert garman_klass.dropna().median() > 0.05
    assert yang_zhang.dropna().median() > 0.05


def test_microstructure_factors(ohlcv_dataframe):
    df = ohlcv_dataframe
    
    amihud = compute_amihud_illiquidity(df, window=20)
    roll = compute_roll_spread(df, window=20)
    cs_spread = compute_corwin_schultz_spread(df, window=20)
    vol_surprise = compute_volume_surprise(df, short_window=5, long_window=20)
    
    assert (amihud.dropna() >= 0).all()
    assert (roll.dropna() >= 0).all()
    assert (cs_spread.dropna() >= 0).all()
    assert (vol_surprise.dropna() > 0).all()
