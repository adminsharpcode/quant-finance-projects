"""
Generates publication-quality charts for Project 08:
1. Cumulative Equity Curves (Value vs Momentum vs 50/50 Risk Parity Combo)
2. Rolling 36-Month Correlation (Empirical Proof of Negative Correlation)
3. Rolling Sharpe Ratio Comparison (The Diversification Miracle)
4. Drawdown Comparison
"""

import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from src.analytics.metrics import calculate_drawdown_series
from src.analytics.correlation import compute_rolling_correlation


def generate_plots():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    viz_dir = os.path.join(project_root, "visualizations")
    returns_path = os.path.join(viz_dir, "factor_daily_returns.csv")
    
    if not os.path.exists(returns_path):
        print("Daily returns CSV not found. Run run_backtest.py first.")
        return
        
    df = pd.read_csv(returns_path, index_col=0, parse_dates=True)
    
    plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")
    
    # -------------------------------------------------------------
    # Chart 1: Cumulative Equity Curves
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 6), dpi=300)
    
    cum_val = (1.0 + df["Value_Net"]).cumprod()
    cum_mom = (1.0 + df["Momentum_Net"]).cumprod()
    cum_combo = (1.0 + df["Combo_50_50_Net"]).cumprod()
    cum_mkt = (1.0 + df["Market_Benchmark"]).cumprod()
    
    ax.plot(cum_combo.index, cum_combo.values, label="50/50 Value + Momentum (Risk Parity)", color="#1f77b4", linewidth=2.2)
    ax.plot(cum_mom.index, cum_mom.values, label="Standalone Momentum (Everywhere)", color="#2ca02c", linewidth=1.5, linestyle="--")
    ax.plot(cum_val.index, cum_val.values, label="Standalone Value (Everywhere)", color="#ff7f0e", linewidth=1.5, linestyle=":")
    ax.plot(cum_mkt.index, cum_mkt.values, label="Market Benchmark (Equal Weight)", color="#7f7f7f", linewidth=1.2, alpha=0.5)
    
    ax.set_title("Value and Momentum Everywhere (2001 - 2024)\nAsness, Moskowitz, & Pedersen (2013) Factor Performance", fontsize=13, fontweight="bold")
    ax.set_ylabel("Wealth Index", fontsize=11)
    ax.set_xlabel("Date", fontsize=11)
    ax.legend(loc="upper left", frameon=True, fontsize=10)
    ax.grid(True, ls="--", alpha=0.5)
    
    chart1_path = os.path.join(viz_dir, "equity_curves_val_mom_combo.png")
    fig.tight_layout()
    fig.savefig(chart1_path)
    plt.close(fig)
    print(f"[✓] Saved {chart1_path}")
    
    # -------------------------------------------------------------
    # Chart 2: Rolling 36-Month Correlation
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 4.5), dpi=300)
    
    roll_corr = compute_rolling_correlation(df["Value_Net"], df["Momentum_Net"], window=756)
    
    ax.plot(roll_corr.index, roll_corr.values, color="#9467bd", linewidth=1.8, label="Rolling 36-Month Correlation rho(Value, Mom)")
    ax.axhline(0.0, color="black", linestyle="-", linewidth=0.8)
    ax.axhline(df["Value_Net"].corr(df["Momentum_Net"]), color="red", linestyle="--", linewidth=1.2, label=f"Full-Sample Mean rho = {df['Value_Net'].corr(df['Momentum_Net']):.2f}")
    ax.fill_between(roll_corr.index, roll_corr.values, 0, where=(roll_corr.values < 0), color="#9467bd", alpha=0.25)
    
    ax.set_title("Empirical Correlation: Value vs Momentum Returns (Rolling 36-Month)", fontsize=12, fontweight="bold")
    ax.set_ylabel("Pearson Correlation", fontsize=11)
    ax.set_ylim(-0.8, 0.4)
    ax.legend(loc="lower left", frameon=True)
    ax.grid(True, ls="--", alpha=0.5)
    
    chart2_path = os.path.join(viz_dir, "rolling_correlation_val_mom.png")
    fig.tight_layout()
    fig.savefig(chart2_path)
    plt.close(fig)
    print(f"[✓] Saved {chart2_path}")
    
    # -------------------------------------------------------------
    # Chart 3: Rolling 24-Month Sharpe Ratio
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 4.5), dpi=300)
    
    w_roll = 504
    roll_val_s = df["Value_Net"].rolling(w_roll).mean() / df["Value_Net"].rolling(w_roll).std() * np.sqrt(252)
    roll_mom_s = df["Momentum_Net"].rolling(w_roll).mean() / df["Momentum_Net"].rolling(w_roll).std() * np.sqrt(252)
    roll_com_s = df["Combo_50_50_Net"].rolling(w_roll).mean() / df["Combo_50_50_Net"].rolling(w_roll).std() * np.sqrt(252)
    
    ax.plot(roll_com_s.index, roll_com_s.values, label="50/50 Combo Sharpe", color="#1f77b4", linewidth=2.0)
    ax.plot(roll_mom_s.index, roll_mom_s.values, label="Momentum Sharpe", color="#2ca02c", linewidth=1.2, alpha=0.7)
    ax.plot(roll_val_s.index, roll_val_s.values, label="Value Sharpe", color="#ff7f0e", linewidth=1.2, alpha=0.7)
    ax.axhline(0.0, color="gray", linestyle="--", linewidth=0.8)
    
    ax.set_title("Rolling 24-Month Annualized Sharpe Ratio: Combo Dominance", fontsize=12, fontweight="bold")
    ax.set_ylabel("Sharpe Ratio", fontsize=11)
    ax.legend(loc="upper left", frameon=True)
    ax.grid(True, ls="--", alpha=0.5)
    
    chart3_path = os.path.join(viz_dir, "rolling_sharpe_expansion.png")
    fig.tight_layout()
    fig.savefig(chart3_path)
    plt.close(fig)
    print(f"[✓] Saved {chart3_path}")
    
    # -------------------------------------------------------------
    # Chart 4: Drawdown Profiles
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 4.5), dpi=300)
    
    dd_val = calculate_drawdown_series(df["Value_Net"]) * 100.0
    dd_mom = calculate_drawdown_series(df["Momentum_Net"]) * 100.0
    dd_combo = calculate_drawdown_series(df["Combo_50_50_Net"]) * 100.0
    
    ax.plot(dd_val.index, dd_val.values, label="Value Drawdown", color="#ff7f0e", linewidth=1.0, alpha=0.7)
    ax.plot(dd_mom.index, dd_mom.values, label="Momentum Drawdown", color="#2ca02c", linewidth=1.0, alpha=0.7)
    ax.plot(dd_combo.index, dd_combo.values, label="50/50 Combo Drawdown", color="#1f77b4", linewidth=1.6)
    ax.fill_between(dd_combo.index, dd_combo.values, 0, color="#1f77b4", alpha=0.2)
    
    ax.set_title("Drawdown Dampening: How Diversification Protects Capital", fontsize=12, fontweight="bold")
    ax.set_ylabel("Drawdown (%)", fontsize=11)
    ax.set_xlabel("Date", fontsize=11)
    ax.legend(loc="lower left", frameon=True)
    ax.grid(True, ls="--", alpha=0.5)
    
    chart4_path = os.path.join(viz_dir, "drawdown_dampening.png")
    fig.tight_layout()
    fig.savefig(chart4_path)
    plt.close(fig)
    print(f"[✓] Saved {chart4_path}")


if __name__ == "__main__":
    generate_plots()
