"""
generate_visualizations.py
Generates publication-quality charts for Project 09:
1. Pass Rate Comparison across 22 Prop Firms
2. Trader Archetype Survival Heatmap
3. Optimal Risk Curve (Pass Rate vs Daily Ruin Rate)
4. Monte Carlo Equity Fan Chart with Confidence Intervals
"""

import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from src.rules.firm_catalog import PROP_FIRMS
from src.models.monte_carlo import PropFirmSimulator, TraderProfile
from src.optimization.sizing_optimizer import PropFirmSizingOptimizer


def generate_charts():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    viz_dir = os.path.join(project_root, "visualizations")
    ranking_path = os.path.join(viz_dir, "prop_firm_ranking.csv")
    archetype_path = os.path.join(viz_dir, "archetype_matrix.csv")

    plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")

    # -------------------------------------------------------------
    # Chart 1: Pass Rate Comparison across 22 Prop Firms
    # -------------------------------------------------------------
    if os.path.exists(ranking_path):
        df_rank = pd.read_csv(ranking_path)
        fig, ax = plt.subplots(figsize=(12, 7), dpi=300)
        
        # Sort ascending for horizontal bar chart
        df_plot = df_rank.sort_values(by="Pass Rate (%)", ascending=True)
        colors = ["#2ca02c" if p >= 98.0 else "#1f77b4" if p >= 94.0 else "#ff7f0e" for p in df_plot["Pass Rate (%)"]]
        
        bars = ax.barh(df_plot["Firm Name"], df_plot["Pass Rate (%)"], color=colors, height=0.65)
        ax.set_xlim(85, 102)
        ax.set_title("Mathematical Challenge Pass Rate Across 22 Prop Firms\n(Disciplined Scalper: 55% Win Rate, 1.3 R:R, 0.5% Risk per Trade)", fontsize=12, fontweight="bold")
        ax.set_xlabel("Monte Carlo Pass Rate (%)", fontsize=11)
        ax.grid(True, axis="x", ls="--", alpha=0.5)
        
        for bar in bars:
            w = bar.get_width()
            ax.annotate(f"{w:.1f}%", xy=(w, bar.get_y() + bar.get_height() / 2),
                        xytext=(3, 0), textcoords="offset points",
                        ha="left", va="center", fontsize=8, fontweight="bold")
                        
        chart1_path = os.path.join(viz_dir, "prop_firm_pass_rates_ranked.png")
        fig.tight_layout()
        fig.savefig(chart1_path)
        plt.close(fig)
        print(f"[✓] Saved {chart1_path}")

    # -------------------------------------------------------------
    # Chart 2: Archetype Survival Heatmap
    # -------------------------------------------------------------
    if os.path.exists(archetype_path):
        df_arch = pd.read_csv(archetype_path).set_index("Firm")
        # Clean percentage strings
        numeric_df = df_arch.map(lambda x: float(str(x).replace("%", "")) if isinstance(x, str) else x)
        
        fig, ax = plt.subplots(figsize=(10, 5), dpi=300)
        cax = ax.matshow(numeric_df.values, cmap="RdYlGn", vmin=0, vmax=100)
        fig.colorbar(cax, fraction=0.046, pad=0.04, label="Pass Probability (%)")
        
        ax.set_xticks(range(len(numeric_df.columns)))
        ax.set_xticklabels([c.replace("_", " ") for c in numeric_df.columns], rotation=20, ha="left", fontsize=9)
        ax.set_yticks(range(len(numeric_df.index)))
        ax.set_yticklabels(numeric_df.index, fontsize=9)
        
        # Annotate cells
        for r in range(len(numeric_df.index)):
            for c in range(len(numeric_df.columns)):
                val = numeric_df.iloc[r, c]
                text_color = "black" if 25 <= val <= 75 else "white"
                ax.text(c, r, f"{val:.1f}%", ha="center", va="center", fontsize=10, fontweight="bold", color=text_color)
                
        ax.set_title("Prop Firm Survival Probability Matrix: Trader Archetype vs Firm Rules", fontsize=12, fontweight="bold", pad=25)
        
        chart2_path = os.path.join(viz_dir, "archetype_survival_heatmap.png")
        fig.tight_layout()
        fig.savefig(chart2_path)
        plt.close(fig)
        print(f"[✓] Saved {chart2_path}")

    # -------------------------------------------------------------
    # Chart 3: Optimal Sizing Risk Curve (FTMO Example)
    # -------------------------------------------------------------
    ftmo = PROP_FIRMS["ftmo_standard"]
    optimizer = PropFirmSizingOptimizer(ftmo, win_rate=0.52, reward_to_risk=1.5, trades_per_day=2)
    rec = optimizer.find_optimal_risk(risk_candidates=(0.25, 0.50, 0.75, 1.0, 1.25, 1.5, 2.0), num_simulations_per_point=1000)
    
    r_df = pd.DataFrame(rec.risk_curve)
    
    fig, ax1 = plt.subplots(figsize=(10, 5), dpi=300)
    ax2 = ax1.twinx()
    
    line1 = ax1.plot(r_df["risk_pct"], r_df["pass_rate_pct"], color="#1f77b4", marker="o", linewidth=2.0, label="Overall Pass Rate (%)")
    line2 = ax2.plot(r_df["risk_pct"], r_df["daily_breach_pct"], color="#d62728", marker="s", linewidth=2.0, linestyle="--", label="Daily Drawdown Ruin Rate (%)")
    
    ax1.axvline(rec.optimal_risk_pct, color="green", linestyle=":", linewidth=1.5, label=f"Optimal f* ({rec.optimal_risk_pct:.2f}%)")
    ax1.axvline(rec.max_safe_risk_pct, color="red", linestyle=":", linewidth=1.5, label=f"Max Safe Boundary ({rec.max_safe_risk_pct:.2f}%)")
    
    ax1.set_title("Optimal Risk per Trade Optimization (FTMO Standard 2-Step)\nTrade-Off Between Speed of Passing and Daily Ruin Risk", fontsize=12, fontweight="bold")
    ax1.set_xlabel("Risk per Trade (%)", fontsize=11)
    ax1.set_ylabel("Pass Rate (%)", color="#1f77b4", fontsize=11)
    ax2.set_ylabel("Daily Drawdown Ruin Rate (%)", color="#d62728", fontsize=11)
    ax1.grid(True, ls="--", alpha=0.5)
    
    lines = line1 + line2 + [ax1.get_lines()[-2], ax1.get_lines()[-1]]
    labels = [l.get_label() for l in lines]
    ax1.legend(lines, labels, loc="center right", frameon=True)
    
    chart3_path = os.path.join(viz_dir, "optimal_risk_curve.png")
    fig.tight_layout()
    fig.savefig(chart3_path)
    plt.close(fig)
    print(f"[✓] Saved {chart3_path}")

    # -------------------------------------------------------------
    # Chart 4: Monte Carlo Equity Fan Chart
    # -------------------------------------------------------------
    trader = TraderProfile(win_rate=0.54, reward_to_risk=1.4, risk_per_trade_pct=0.0075, trades_per_day=2)
    sim = PropFirmSimulator(ftmo, trader, account_size=100_000.0, max_simulation_days=60, seed=42)
    res = sim.simulate(num_paths=2000)
    
    fig, ax = plt.subplots(figsize=(12, 6), dpi=300)
    days = np.arange(len(res.percentiles["p50"]))
    
    ax.fill_between(days, res.percentiles["p5"], res.percentiles["p95"], color="#1f77b4", alpha=0.15, label="5th - 95th Percentile Band")
    ax.fill_between(days, res.percentiles["p25"], res.percentiles["p75"], color="#1f77b4", alpha=0.30, label="25th - 75th Percentile Band")
    ax.plot(days, res.percentiles["p50"], color="#1f77b4", linewidth=2.2, label="Median Trajectory (50th Percentile)")
    
    # Target and Drawdown thresholds
    ax.axhline(110_000.0, color="green", linestyle="--", linewidth=1.5, label="Phase 1 Target (+10% / $110,000)")
    ax.axhline(90_000.0, color="red", linestyle="--", linewidth=1.5, label="Max Drawdown Barrier (-10% / $90,000)")
    ax.axhline(100_000.0, color="gray", linestyle="-", linewidth=0.8, alpha=0.7)
    
    # Plot 8 sample individual paths
    for p in res.sample_equity_curves[:8]:
        ax.plot(days, p, color="black", linewidth=0.7, alpha=0.25)
        
    ax.set_title("Monte Carlo 2,000-Path Equity Fan Chart ($100,000 FTMO Evaluation)\nStochastic Challenge Progression (f = 0.75% Risk per Trade)", fontsize=12, fontweight="bold")
    ax.set_xlabel("Trading Days", fontsize=11)
    ax.set_ylabel("Account Balance ($ USD)", fontsize=11)
    ax.set_ylim(88_000, 115_000)
    ax.legend(loc="upper left", frameon=True, fontsize=9)
    ax.grid(True, ls="--", alpha=0.5)
    
    chart4_path = os.path.join(viz_dir, "simulated_equity_fan_chart.png")
    fig.tight_layout()
    fig.savefig(chart4_path)
    plt.close(fig)
    print(f"[✓] Saved {chart4_path}")


if __name__ == "__main__":
    generate_charts()
