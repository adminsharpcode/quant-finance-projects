#!/usr/bin/env python3
"""
Interactive Volatility Surface & Greek Sensitivity Visualizer.

Generates standalone, institutional-grade HTML visualizers using Plotly:
1. 3D Interactive Volatility Surface Mesh (Moneyness vs Tenor vs Implied Volatility)
2. 2D Volatility Smiles (SVI/SABR Fitted Splines vs Raw Market Quotes)
3. Greeks Risk Sensitivity Profiles & Heatmaps
"""

import sys
from pathlib import Path

# Add project root to path
ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from src.surface.svi_surface import SVIModel
from src.greeks.analytical_greeks import calculate_all_greeks
from src.models.black_scholes import OptionType
from src.utils.market_data import generate_comex_gold_chain


def generate_3d_surface_plot(svi_surface: SVIModel, F: float = 2650.0, output_path: Path = None):
    """Generate 3D mesh volatility surface."""
    tenors = np.linspace(0.05, 0.75, 50)
    strikes = np.linspace(F * 0.85, F * 1.15, 60)

    T_grid, K_grid = np.meshgrid(tenors, strikes)
    vol_grid = np.zeros_like(T_grid)

    for i in range(T_grid.shape[0]):
        for j in range(T_grid.shape[1]):
            vol_grid[i, j] = svi_surface.get_vol(K_grid[i, j], F, T_grid[i, j])

    fig = go.Figure(
        data=[
            go.Surface(
                x=K_grid / F,  # Moneyness K / F
                y=T_grid * 365,  # Days to Expiry
                z=vol_grid * 100,  # Implied Volatility %
                colorscale="Viridis",
                colorbar=dict(title="Implied Vol (%)"),
                contours={
                    "z": {"show": True, "usecolormap": True, "highlightcolor": "limegreen", "project_z": True}
                },
            )
        ]
    )

    fig.update_layout(
        title="<b>COMEX Gold (GC) Calibrated SVI Implied Volatility Surface</b>",
        scene=dict(
            xaxis_title="Moneyness (K / F)",
            yaxis_title="Tenor (Days to Expiration)",
            zaxis_title="Implied Volatility (%)",
            camera=dict(eye=dict(x=-1.6, y=-1.5, z=1.2)),
        ),
        template="plotly_dark",
        margin=dict(l=10, r=10, b=10, t=50),
        height=700,
    )

    if output_path:
        fig.write_html(str(output_path))
        print(f"[3D Surface] Saved to {output_path}")

    return fig


def generate_2d_smiles_plot(svi_surface: SVIModel, df_gold: pd.DataFrame, F: float = 2650.0, output_path: Path = None):
    """Generate 2D smile slices comparing market quotes with calibrated SVI curves."""
    expiries = sorted(df_gold["expiry_years"].unique())
    fig = go.Figure()

    colors = ["#00f0ff", "#ff007f", "#39ff14", "#ffe600"]

    for idx, T in enumerate(expiries):
        days = int(round(T * 365))
        sub = df_gold[(df_gold["expiry_years"] == T) & (df_gold["option_type"] == "call")].dropna(subset=["mid_iv"])

        # Market Quotes (Scatter)
        fig.add_trace(
            go.Scatter(
                x=sub["strike"] / F,
                y=sub["mid_iv"] * 100,
                mode="markers",
                name=f"Market {days}d Quotes",
                marker=dict(size=7, color=colors[idx % len(colors)], symbol="circle-open-dot"),
            )
        )

        # SVI Continuous Curve (Line)
        k_dense = np.linspace(-0.16, 0.16, 120)
        strikes_dense = F * np.exp(k_dense)
        vols_dense = [svi_surface.get_vol(K, F, T) * 100 for K in strikes_dense]

        fig.add_trace(
            go.Scatter(
                x=strikes_dense / F,
                y=vols_dense,
                mode="lines",
                name=f"SVI Fitted {days}d Model",
                line=dict(color=colors[idx % len(colors)], width=2.5),
            )
        )

    fig.update_layout(
        title="<b>COMEX Gold Implied Volatility Smiles (SVI Fit vs Traded Quotes)</b>",
        xaxis_title="Moneyness (K / F)",
        yaxis_title="Implied Volatility (%)",
        template="plotly_dark",
        height=600,
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    )

    if output_path:
        fig.write_html(str(output_path))
        print(f"[2D Smiles] Saved to {output_path}")

    return fig


def generate_greeks_sensitivity_plot(F: float = 2650.0, output_path: Path = None):
    """Generate multi-panel Greek sensitivity profiles across spot and time."""
    spots = np.linspace(2400.0, 2900.0, 100)
    K = 2650.0
    r = 0.045
    sigma = 0.175

    tenors = [30 / 365, 90 / 365, 180 / 365]

    fig = make_subplots(
        rows=2,
        cols=3,
        subplot_titles=("Delta (Δ)", "Gamma (Γ)", "Vega (1%)", "Theta (1-day)", "Vanna (dDelta/dVol)", "Volga (dVega/dVol)"),
    )

    colors = ["#00f0ff", "#ff007f", "#39ff14"]

    for idx, T in enumerate(tenors):
        days = int(round(T * 365))
        greeks = [calculate_all_greeks(s, K, T, r, sigma, OptionType.CALL, is_futures=True) for s in spots]

        # Delta
        fig.add_trace(
            go.Scatter(x=spots, y=[g.delta for g in greeks], line=dict(color=colors[idx]), name=f"{days}d", showlegend=(idx == 0)),
            row=1, col=1,
        )
        # Gamma
        fig.add_trace(
            go.Scatter(x=spots, y=[g.gamma for g in greeks], line=dict(color=colors[idx]), showlegend=False),
            row=1, col=2,
        )
        # Vega 1%
        fig.add_trace(
            go.Scatter(x=spots, y=[g.vega_1pct for g in greeks], line=dict(color=colors[idx]), showlegend=False),
            row=1, col=3,
        )
        # Theta 1-day
        fig.add_trace(
            go.Scatter(x=spots, y=[g.theta_1day for g in greeks], line=dict(color=colors[idx]), showlegend=False),
            row=2, col=1,
        )
        # Vanna
        fig.add_trace(
            go.Scatter(x=spots, y=[g.vanna for g in greeks], line=dict(color=colors[idx]), showlegend=False),
            row=2, col=2,
        )
        # Volga
        fig.add_trace(
            go.Scatter(x=spots, y=[g.volga for g in greeks], line=dict(color=colors[idx]), showlegend=False),
            row=2, col=3,
        )

    fig.update_layout(
        title="<b>Institutional Greek Sensitivity Risk Profiles (COMEX Gold Call K=$2650)</b>",
        template="plotly_dark",
        height=700,
    )

    if output_path:
        fig.write_html(str(output_path))
        print(f"[Greeks Sensitivity] Saved to {output_path}")

    return fig


def main():
    print("[*] Generating Interactive Quantitative Visualizers...")
    output_dir = ROOT_DIR / "visualizations"
    output_dir.mkdir(exist_ok=True)

    df_gold = generate_comex_gold_chain(underlying_price=2650.0, seed=101)
    expiries = sorted(df_gold["expiry_years"].unique())

    svi_surface = SVIModel()
    strikes_list = []
    vols_list = []
    for T in expiries:
        sub = df_gold[(df_gold["expiry_years"] == T) & (df_gold["option_type"] == "call")].dropna(subset=["mid_iv"])
        strikes_list.append(sub["strike"].values)
        vols_list.append(sub["mid_iv"].values)

    svi_surface.fit_surface(expiries, strikes_list, vols_list, [2650.0] * len(expiries))

    generate_3d_surface_plot(svi_surface, F=2650.0, output_path=output_dir / "3d_volatility_surface.html")
    generate_2d_smiles_plot(svi_surface, df_gold, F=2650.0, output_path=output_dir / "2d_volatility_smiles.html")
    generate_greeks_sensitivity_plot(F=2650.0, output_path=output_dir / "greeks_sensitivity_profiles.html")

    print("[PASS] All interactive visualizers exported successfully.")


if __name__ == "__main__":
    main()
