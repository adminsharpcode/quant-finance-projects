#!/usr/bin/env python3
"""
Interactive Quantitative Options Pricing, Greeks & Volatility Surface Workbench.
Built with Streamlit and Plotly.
"""

import sys
from pathlib import Path

# Add project root to path
ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

import numpy as np
import pandas as pd
import streamlit as st
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from src.models.black_scholes import OptionType, black_76_price
from src.models.binomial_tree import binomial_tree_price, ExerciseStyle
from src.models.monte_carlo import monte_carlo_price
from src.greeks.analytical_greeks import calculate_all_greeks
from src.surface.svi_surface import SVIModel, calibrate_svi, arbitrage_free_check
from src.surface.sabr_model import calibrate_sabr, sabr_implied_vol
from src.edge.mispricing_detector import SurfaceEdgeScanner, TradeSignal
from src.utils.market_data import generate_comex_gold_chain, generate_cme_crude_chain


st.set_page_config(
    page_title="Institutional Options Pricing & Volatility Engine",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.title("🏛️ Institutional Options Pricing, Greeks & Volatility Surface Engine")
st.caption("Quantitative Finance Production Series — Project 01 | COMEX Gold & CME Crude Oil")


# Sidebar Controls
st.sidebar.header("Asset & Contract Selection")
asset = st.sidebar.selectbox("Market Contract", ["COMEX Gold Futures (GC)", "CME WTI Crude Oil (CL)"])

if "Gold" in asset:
    default_F = 2650.0
    default_K = 2650.0
    default_vol = 0.175
    step_K = 10.0
    unit = "$/oz"
    symbol = "GC"
    df_chain = generate_comex_gold_chain(underlying_price=default_F, seed=101)
else:
    default_F = 72.50
    default_K = 72.50
    default_vol = 0.315
    step_K = 0.50
    unit = "$/bbl"
    symbol = "CL"
    df_chain = generate_cme_crude_chain(underlying_price=default_F, seed=202)

st.sidebar.subheader("Pricing Parameters")
F = st.sidebar.number_input(f"Underlying Futures Price ({unit})", value=float(default_F), step=step_K)
K = st.sidebar.number_input(f"Option Strike Price ({unit})", value=float(default_K), step=step_K)
T_days = st.sidebar.slider("Days to Expiration", min_value=5, max_value=365, value=60)
T = T_days / 365.0
vol = st.sidebar.slider("Annualized Volatility (σ)", min_value=0.05, max_value=0.80, value=float(default_vol), step=0.005)
r = st.sidebar.slider("Risk-Free Rate (r)", min_value=0.0, max_value=0.10, value=0.045, step=0.005)
opt_type = st.sidebar.radio("Option Type", ["Call", "Put"]).lower()

tabs = st.tabs([
    "📊 Numerical Pricing Benchmark",
    "⚡ Greeks Risk Engine",
    "🌐 3D Volatility Surface & Calibration",
    "🎯 Systematic Alpha & Arbitrage Signals",
])

# ----------------- TAB 1: Numerical Pricing Benchmark -----------------
with tabs[0]:
    st.subheader("Model Comparison: Black-76 vs Binomial (American) vs Monte Carlo")

    col1, col2, col3, col4 = st.columns(4)

    # 1. Black-76
    b76_p = black_76_price(F, K, T, r, vol, opt_type)
    # 2. Binomial European
    tree_eur = binomial_tree_price(F, K, T, r, vol, opt_type, ExerciseStyle.EUROPEAN, n_steps=500, is_futures=True)
    # 3. Binomial American
    tree_ame = binomial_tree_price(F, K, T, r, vol, opt_type, ExerciseStyle.AMERICAN, n_steps=500, is_futures=True)
    early_prem = max(tree_ame - tree_eur, 0.0)
    # 4. Monte Carlo
    mc = monte_carlo_price(F, K, T, r, vol, opt_type, n_paths=80_000, is_futures=True, use_antithetic=True, seed=42)

    col1.metric("Black-76 (European)", f"${b76_p:.3f}", "Analytical Closed-Form")
    col2.metric("CRR Binomial (European)", f"${tree_eur:.3f}", f"Diff: ${abs(tree_eur - b76_p):.4f}")
    col3.metric("CRR Binomial (American)", f"${tree_ame:.3f}", f"Early Prem: +${early_prem:.3f}")
    col4.metric("Monte Carlo (Antithetic)", f"${mc.price:.3f}", f"95% CI: ±${mc.standard_error * 1.96:.3f}")

    st.markdown("---")
    st.markdown("### Convergence of Binomial Tree Steps to Black-76 Limit")

    steps_range = [20, 50, 100, 200, 350, 500, 750]
    tree_prices = [
        binomial_tree_price(F, K, T, r, vol, opt_type, ExerciseStyle.EUROPEAN, n_steps=s, is_futures=True)
        for s in steps_range
    ]

    fig_conv = go.Figure()
    fig_conv.add_trace(go.Scatter(x=steps_range, y=tree_prices, mode="lines+markers", name="Binomial CRR Lattice", line=dict(color="#00f0ff", width=2.5)))
    fig_conv.add_hline(y=b76_p, line_dash="dash", line_color="#ff007f", annotation_text="Black-76 Continuous Limit")
    fig_conv.update_layout(template="plotly_dark", height=400, xaxis_title="Lattice Steps (N)", yaxis_title="Option Price ($)")
    st.plotly_chart(fig_conv, use_container_width=True)

# ----------------- TAB 2: Greeks Risk Engine -----------------
with tabs[1]:
    st.subheader(f"Greeks Risk Desk ({symbol} {opt_type.upper()} K=${K:.2f})")

    g = calculate_all_greeks(F, K, T, r, vol, opt_type, is_futures=True)

    g_col1, g_col2, g_col3, g_col4 = st.columns(4)
    g_col1.metric("Delta (Δ)", f"{g.delta:+.4f}", "Directional Hedge Ratio")
    g_col2.metric("Gamma (Γ)", f"{g.gamma:.5f}", "Curvature / Convexity")
    g_col3.metric("Vega (1%)", f"${g.vega_1pct:.2f}", "Exposure per +1% Vol")
    g_col4.metric("Theta (1-Day)", f"-${abs(g.theta_1day):.2f}", "Daily Calendar Decay")

    g_col5, g_col6, g_col7, g_col8 = st.columns(4)
    g_col5.metric("Rho (100bp)", f"${g.rho_1pct:+.2f}", "Rate Sensitivity")
    g_col6.metric("Vanna", f"{g.vanna:+.4f}", "dDelta / dVol")
    g_col7.metric("Volga (Vomma)", f"{g.volga:.4f}", "dVega / dVol (Smile Convexity)")
    g_col8.metric("Moneyness (K/F)", f"{K/F:.2%}", "ATM = 100%")

    st.markdown("---")
    st.subheader("Interactive Greeks Sensitivity Across Spot Continuum")

    spots = np.linspace(F * 0.85, F * 1.15, 80)
    all_g = [calculate_all_greeks(s, K, T, r, vol, opt_type, is_futures=True) for s in spots]

    greek_sel = st.selectbox("Select Greek Curve to Plot", ["Delta", "Gamma", "Vega", "Theta", "Vanna", "Volga"])
    attr_map = {
        "Delta": [x.delta for x in all_g],
        "Gamma": [x.gamma for x in all_g],
        "Vega": [x.vega_1pct for x in all_g],
        "Theta": [x.theta_1day for x in all_g],
        "Vanna": [x.vanna for x in all_g],
        "Volga": [x.volga for x in all_g],
    }

    fig_greek = go.Figure()
    fig_greek.add_trace(go.Scatter(x=spots, y=attr_map[greek_sel], mode="lines", name=greek_sel, line=dict(color="#39ff14", width=3)))
    fig_greek.add_vline(x=F, line_dash="dash", line_color="#ffe600", annotation_text="Current Underlying Spot")
    fig_greek.update_layout(template="plotly_dark", height=420, xaxis_title="Underlying Price ($)", yaxis_title=f"{greek_sel} Exposure")
    st.plotly_chart(fig_greek, use_container_width=True)

# ----------------- TAB 3: 3D Volatility Surface & Calibration -----------------
with tabs[2]:
    st.subheader(f"Gatheral's SVI & Hagan's SABR Calibration ({asset})")

    expiries = sorted(df_chain["expiry_years"].unique())
    svi_surface = SVIModel()
    strikes_list, vols_list = [], []

    for exp_t in expiries:
        sub = df_chain[(df_chain["expiry_years"] == exp_t) & (df_chain["option_type"] == "call")].dropna(subset=["mid_iv"])
        strikes_list.append(sub["strike"].values)
        vols_list.append(sub["mid_iv"].values)

    svi_surface.fit_surface(expiries, strikes_list, vols_list, [F] * len(expiries))

    calib_rows = []
    for exp_t in expiries:
        p = svi_surface.slices[exp_t]
        arb = arbitrage_free_check(p)
        calib_rows.append({
            "Tenor (Days)": f"{int(round(exp_t * 365))}d",
            "a (Level)": f"{p.a:.5f}",
            "b (Wing Slope)": f"{p.b:.5f}",
            "ρ (Skew)": f"{p.rho:+.4f}",
            "m (Shift)": f"{p.m:+.4f}",
            "σ (Smoothness)": f"{p.sigma:.4f}",
            "RMSE": f"{p.rmse:.4%}",
            "Arbitrage-Free": "✅ PASS" if arb["is_arbitrage_free"] else "❌ FAIL",
        })
    st.table(pd.DataFrame(calib_rows))

    # 3D Mesh Plot
    tenors_mesh = np.linspace(0.05, 0.60, 40)
    strikes_mesh = np.linspace(F * 0.88, F * 1.12, 50)
    T_g, K_g = np.meshgrid(tenors_mesh, strikes_mesh)
    v_g = np.zeros_like(T_g)

    for i in range(T_g.shape[0]):
        for j in range(T_g.shape[1]):
            v_g[i, j] = svi_surface.get_vol(K_g[i, j], F, T_g[i, j])

    fig_3d = go.Figure(
        data=[
            go.Surface(
                x=K_g / F,
                y=T_g * 365,
                z=v_g * 100,
                colorscale="Viridis",
                colorbar=dict(title="IV (%)"),
            )
        ]
    )
    fig_3d.update_layout(
        title="<b>Interactive 3D Implied Volatility Surface</b>",
        scene=dict(xaxis_title="Moneyness (K/F)", yaxis_title="Tenor (Days)", zaxis_title="Implied Vol (%)"),
        template="plotly_dark",
        height=600,
    )
    st.plotly_chart(fig_3d, use_container_width=True)

# ----------------- TAB 4: Systematic Alpha & Arbitrage Signals -----------------
with tabs[3]:
    st.subheader("🎯 Systematic Alpha Engine: Relative-Value Mispricing Signals")

    scanner = SurfaceEdgeScanner(svi_surface, min_edge_ratio=0.35)
    signals = scanner.scan_chain(df_chain, underlying_symbol=symbol, r=r)
    actionable = [s for s in signals if s.signal in (TradeSignal.BUY_VOL, TradeSignal.SELL_VOL)]

    st.write(f"Scanned **{len(signals)}** contracts in active chain. Discovered **{len(actionable)}** statistically mispriced contracts exceeding volatility bid-ask spread threshold.")

    signal_data = []
    for s in actionable:
        signal_data.append({
            "Contract": s.contract_symbol,
            "Market Bid/Ask": f"${s.bid_price:.2f} / ${s.ask_price:.2f}",
            "Fair Value": f"${s.theoretical_fair_price:.2f}",
            "Market IV": f"{s.mid_iv:.1%}",
            "Surface IV": f"{s.model_fair_iv:.1%}",
            "IV Edge": f"{s.iv_edge:+.2%}",
            "Signal": s.signal.value,
            "Delta Hedge": f"{s.delta_hedge_ratio:+.3f} {symbol}",
            "Dollar Edge": f"${s.dollar_edge_per_contract:.2f}",
        })

    if signal_data:
        st.dataframe(pd.DataFrame(signal_data), use_container_width=True)
    else:
        st.info("All market contracts are currently priced within theoretical arbitrage bounds.")
