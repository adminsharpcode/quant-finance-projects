"""Unit tests for implied volatility solver, SVI, SABR, and edge scanner."""

import numpy as np
import pytest
from src.surface.implied_vol import implied_volatility
from src.surface.svi_surface import (
    SVIModel,
    arbitrage_free_check,
    calibrate_svi,
    svi_implied_vol,
)
from src.surface.sabr_model import calibrate_sabr, sabr_implied_vol
from src.models.black_scholes import OptionType, black_76_price
from src.edge.mispricing_detector import SurfaceEdgeScanner, TradeSignal
from src.utils.market_data import generate_comex_gold_chain


def test_implied_volatility_inversion():
    """Verify that inverted implied vol exactly recovers ground-truth sigma."""
    F = 2650.0
    strikes = [2500.0, 2650.0, 2800.0]
    T = 0.25
    r = 0.045
    true_sigma = 0.185

    for K in strikes:
        opt_type = OptionType.CALL if K >= F else OptionType.PUT
        price = black_76_price(F, K, T, r, true_sigma, opt_type)
        recovered_sigma = implied_volatility(
            price, F, K, T, r, opt_type, is_futures=True
        )
        assert pytest.approx(recovered_sigma, abs=1e-5) == true_sigma


def test_svi_calibration_convergence():
    """Verify SVI calibration recovers volatility smile with low RMSE."""
    F = 2650.0
    T = 0.25
    strikes = np.linspace(2400.0, 2900.0, 21)
    k = np.log(strikes / F)

    # Synthetic realistic smile: ATM=17%, skew=-15%, smile=25%
    synthetic_vols = 0.17 - 0.15 * k + 0.25 * (k**2)

    params = calibrate_svi(strikes, synthetic_vols, F, T)

    assert params.rmse < 0.01  # Less than 1% vol RMSE
    arb_check = arbitrage_free_check(params)
    assert arb_check["b_positive"]
    assert arb_check["rho_bounded"]
    assert arb_check["variance_positive"]


def test_sabr_calibration_convergence():
    """Verify SABR model calibration converges accurately."""
    F = 72.50  # WTI Crude
    T = 0.25
    strikes = np.linspace(60.0, 85.0, 15)

    # Generate synthetic SABR smile
    true_alpha, true_beta, true_rho, true_nu = 0.35, 0.5, -0.3, 0.45
    synthetic_vols = sabr_implied_vol(F, strikes, T, true_alpha, true_beta, true_rho, true_nu)

    params = calibrate_sabr(strikes, synthetic_vols, F, T, beta=true_beta)
    assert params.rmse < 0.01


def test_edge_scanner_detection():
    """Verify relative-value scanner flags over/underpriced quotes."""
    df_chain = generate_comex_gold_chain(underlying_price=2650.0, seed=123)
    expiries = sorted(df_chain["expiry_years"].unique())

    # Build and calibrate SVI surface
    surface = SVIModel()
    strikes_list = []
    vols_list = []
    for T in expiries:
        sub = df_chain[(df_chain["expiry_years"] == T) & (df_chain["option_type"] == "call")].dropna(subset=["mid_iv"])
        strikes_list.append(sub["strike"].values)
        vols_list.append(sub["mid_iv"].values)

    surface.fit_surface(expiries, strikes_list, vols_list, [2650.0] * len(expiries))

    scanner = SurfaceEdgeScanner(surface, min_edge_ratio=0.5)
    signals = scanner.scan_chain(df_chain, underlying_symbol="GC", r=0.045)

    assert len(signals) > 0
    # Verify that at least some signals identified actionable edges
    actionable = [s for s in signals if s.signal in (TradeSignal.BUY_VOL, TradeSignal.SELL_VOL)]
    assert len(actionable) > 0
