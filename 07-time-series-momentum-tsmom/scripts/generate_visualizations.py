"""
Generates publication-quality charts for Project 07:
1. Cumulative Equity Curves (TSMOM vs Benchmarks on Log Scale)
2. Underwater Drawdown Profiles
3. Crisis Alpha Stress Test Comparison (Bar Chart)
4. Rolling 12-Month Sharpe Ratio Distributions
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


def generate_plots():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    viz_dir = os.path.join(project_root, "visualizations")
    returns_path = os.path.join(viz_dir, "strategy_daily_returns.csv")
    
    if not os.path.exists(returns_path):
        print("Daily returns CSV not found. Run run_backtest.py first.")
        return
        
    df = pd.read_csv(returns_path, index_col=0, parse_dates=True)
    
    plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")
    
    # -------------------------------------------------------------
    # Chart 1: Cumulative Equity Curves (Log Scale)
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 6), dpi=300)
    
    cum_12m = (1.0 + df["TSMOM_12M_Net"]).cumprod()
    cum_multi = (1.0 + df["TSMOM_Multi_Net"]).cumprod()
    cum_6040 = (1.0 + df["Benchmark_6040"]).cumprod()
    cum_sp500 = (1.0 + df["SP500_ES"]).cumprod()
    
    ax.plot(cum_12m.index, cum_12m.values, label="TSMOM (12M Moskowitz et al.)", color="#1f77b4", linewidth=2.0)
    ax.plot(cum_multi.index, cum_multi.values, label="TSMOM Multi-Horizon (1M+3M+6M+12M)", color="#2ca02c", linewidth=1.8, linestyle="--")
    ax.plot(cum_6040.index, cum_6040.values, label="Benchmark 60/40 Equity/Bond", color="#ff7f0e", linewidth=1.5)
    ax.plot(cum_sp500.index, cum_sp500.values, label="S&P 500 Futures (ES Buy & Hold)", color="#d62728", linewidth=1.2, alpha=0.7)
    
    ax.set_yscale("log")
    ax.set_title("Time Series Momentum (TSMOM) vs Benchmarks (2001 - 2024)\nInitial Capital: $10,000,000 | 12% Target Volatility | 7 bps Friction", fontsize=13, fontweight="bold")
    ax.set_ylabel("Wealth Index (Log Scale)", fontsize=11)
    ax.set_xlabel("Date", fontsize=11)
    ax.legend(loc="upper left", frameon=True, fontsize=10)
    ax.grid(True, which="both", ls="--", alpha=0.5)
    
    chart1_path = os.path.join(viz_dir, "equity_curves_tsmom_vs_benchmarks.png")
    fig.tight_layout()
    fig.savefig(chart1_path)
    plt.close(fig)
    print(f"[✓] Saved {chart1_path}")
    
    # -------------------------------------------------------------
    # Chart 2: Drawdown Comparison
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 4.5), dpi=300)
    
    dd_12m = calculate_drawdown_series(df["TSMOM_12M_Net"]) * 100.0
    dd_6040 = calculate_drawdown_series(df["Benchmark_6040"]) * 100.0
    dd_sp500 = calculate_drawdown_series(df["SP500_ES"]) * 100.0
    
    ax.plot(dd_sp500.index, dd_sp500.values, label="S&P 500 Drawdown", color="#d62728", linewidth=1.0, alpha=0.6)
    ax.plot(dd_6040.index, dd_6040.values, label="60/40 Drawdown", color="#ff7f0e", linewidth=1.2, alpha=0.8)
    ax.plot(dd_12m.index, dd_12m.values, label="TSMOM (12M) Drawdown", color="#1f77b4", linewidth=1.6)
    ax.fill_between(dd_12m.index, dd_12m.values, 0, color="#1f77b4", alpha=0.2)
    
    ax.set_title("Drawdown Profile: TSMOM Capital Preservation vs Equity Drawdowns", fontsize=13, fontweight="bold")
    ax.set_ylabel("Drawdown (%)", fontsize=11)
    ax.set_xlabel("Date", fontsize=11)
    ax.set_ylim(-85, 5)
    ax.legend(loc="lower left", frameon=True, fontsize=10)
    ax.grid(True, ls="--", alpha=0.5)
    
    chart2_path = os.path.join(viz_dir, "drawdown_comparison.png")
    fig.tight_layout()
    fig.savefig(chart2_path)
    plt.close(fig)
    print(f"[✓] Saved {chart2_path}")
    
    # -------------------------------------------------------------
    # Chart 3: Crisis Alpha Stress Attribution
    # -------------------------------------------------------------
    crisis_path = os.path.join(viz_dir, "crisis_alpha_regimes.csv")
    if os.path.exists(crisis_path):
        cdf = pd.read_csv(crisis_path)
        fig, ax = plt.subplots(figsize=(10, 5), dpi=300)
        
        x = np.arange(len(cdf))
        width = 0.35
        
        rects1 = ax.bar(x - width/2, cdf["Strategy Return (%)"], width, label="TSMOM 12M Return (%)", color="#1f77b4")
        rects2 = ax.bar(x + width/2, cdf["Benchmark Return (%)"], width, label="S&P 500 Return (%)", color="#d62728")
        
        ax.set_title("Crisis Alpha Verification: Performance During Major Historical Market Crashes", fontsize=12, fontweight="bold")
        ax.set_xticks(x)
        ax.set_xticklabels(cdf["Crisis Regime"], rotation=15, ha="right", fontsize=9)
        ax.set_ylabel("Cumulative Return (%)", fontsize=11)
        ax.legend(frameon=True)
        ax.axhline(0, color="black", linewidth=0.8, linestyle="--")
        ax.grid(True, axis="y", ls="--", alpha=0.5)
        
        # Add labels
        for rect in rects1:
            h = rect.get_height()
            ax.annotate(f"{h:+.1f}%", xy=(rect.get_x() + rect.get_width() / 2, h),
                        xytext=(0, 3 if h >= 0 else -10), textcoords="offset points",
                        ha="center", va="bottom" if h >= 0 else "top", fontsize=8, fontweight="bold")
                        
        for rect in rects2:
            h = rect.get_height()
            ax.annotate(f"{h:+.1f}%", xy=(rect.get_x() + rect.get_width() / 2, h),
                        xytext=(0, 3 if h >= 0 else -10), textcoords="offset points",
                        ha="center", va="bottom" if h >= 0 else "top", fontsize=8, color="#8b0000")
                        
        chart3_path = os.path.join(viz_dir, "crisis_alpha_stress_performance.png")
        fig.tight_layout()
        fig.savefig(chart3_path)
        plt.close(fig)
        print(f"[✓] Saved {chart3_path}")
        
    # -------------------------------------------------------------
    # Chart 4: Rolling 12-Month Sharpe Ratio
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(12, 4.5), dpi=300)
    
    roll_12m = df["TSMOM_12M_Net"].rolling(252).mean() / df["TSMOM_12M_Net"].rolling(252).std() * np.sqrt(252)
    roll_sp = df["SP500_ES"].rolling(252).mean() / df["SP500_ES"].rolling(252).std() * np.sqrt(252)
    
    ax.plot(roll_12m.index, roll_12m.values, label="TSMOM Rolling 12M Sharpe", color="#1f77b4", linewidth=1.5)
    ax.plot(roll_sp.index, roll_sp.values, label="S&P 500 Rolling 12M Sharpe", color="#d62728", linewidth=1.2, alpha=0.6)
    ax.axhline(0.0, color="gray", linestyle="--", linewidth=0.8)
    ax.axhline(1.0, color="green", linestyle=":", linewidth=0.8, alpha=0.7)
    
    ax.set_title("Rolling 12-Month Annualized Sharpe Ratio", fontsize=12, fontweight="bold")
    ax.set_ylabel("Sharpe Ratio", fontsize=11)
    ax.legend(frameon=True, loc="upper right")
    ax.grid(True, ls="--", alpha=0.5)
    
    chart4_path = os.path.join(viz_dir, "rolling_sharpe_distribution.png")
    fig.tight_layout()
    fig.savefig(chart4_path)
    plt.close(fig)
    print(f"[✓] Saved {chart4_path}")


if __name__ == "__main__":
    generate_plots()
