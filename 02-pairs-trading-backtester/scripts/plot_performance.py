"""Publication-grade visualization suite for Pairs Trading & Cointegration Engine.

Generates multi-panel figures:
1. Cumulative Equity Curve vs Buy & Hold Benchmarks
2. Dynamic Kalman Filter Beta tracking vs Static OLS
3. Spread Z-Score with Entry, Exit and Stop-Loss execution markers
4. Underwater Drawdown Profile
5. Rolling Walk-Forward In-Sample vs Out-of-Sample Sharpe Stability
"""

import os
import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.analysis.cadf_test import cadf_test
from src.state_space.kalman_filter import KalmanHedgeTracker
from src.strategy.zscore_signals import ZScoreSignalGenerator
from src.backtest.execution_sim import PairsExecutionSimulator
from src.backtest.performance import PerformanceAnalyzer
from src.validation.walk_forward import WalkForwardValidator


def set_plot_style():
    """Configure modern dark-theme quant aesthetic."""
    plt.style.use("dark_background")
    plt.rcParams["font.family"] = "sans-serif"
    plt.rcParams["font.size"] = 10
    plt.rcParams["axes.titlesize"] = 12
    plt.rcParams["axes.labelsize"] = 10
    plt.rcParams["axes.grid"] = True
    plt.rcParams["grid.color"] = "#2A2E39"
    plt.rcParams["grid.alpha"] = 0.6
    plt.rcParams["axes.facecolor"] = "#131722"
    plt.rcParams["figure.facecolor"] = "#0D1117"


def generate_all_plots():
    set_plot_style()
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    out_dir = os.path.join(base_dir, "visualizations")
    os.makedirs(out_dir, exist_ok=True)

    equity_file = os.path.join(base_dir, "data", "equity_pairs_universe.csv")
    df = pd.read_csv(equity_file)
    dates = pd.to_datetime(df["Date"])

    # Primary pair: Energy (CVX vs XOM)
    y = df["CVX"].values
    x = df["XOM"].values

    # Run Kalman Filter and backtest
    cadf_res = cadf_test(y, x)
    kf = KalmanHedgeTracker(delta=1e-4, r_var=1e-3, initial_beta=cadf_res.hedge_ratio)
    kf_res = kf.filter_series(y, x, rolling_window=30)

    sig_gen = ZScoreSignalGenerator(z_entry=2.0, z_exit=0.0, z_stop=3.5)
    signals = sig_gen.generate(kf_res.zscore_history)

    sim = PairsExecutionSimulator(
        initial_capital=100_000.0,
        commission_per_share=0.005,
        half_spread_bps=3.0,
        slippage_bps=2.0,
        short_borrow_fee_annual=0.015
    )
    btest = sim.simulate(y, x, signals.positions, kf_res.beta_history, df["Date"].tolist())
    analyzer = PerformanceAnalyzer(risk_free_rate_annual=0.04)
    perf = analyzer.analyze(btest)

    # 1. Plot Equity Curve vs Buy & Hold
    fig, ax = plt.subplots(figsize=(12, 6), dpi=300)
    norm_y = (y / y[0]) * 100_000.0
    norm_x = (x / x[0]) * 100_000.0
    
    ax.plot(dates, btest.equity_curve, label=f"Pairs Strategy Net PnL (Sharpe: {perf.sharpe_ratio:.2f})", color="#00E676", linewidth=2.0)
    ax.plot(dates, norm_y, label="CVX Buy & Hold", color="#2979FF", linestyle="--", alpha=0.7)
    ax.plot(dates, norm_x, label="XOM Buy & Hold", color="#FF9100", linestyle="--", alpha=0.7)

    ax.set_title("Institutional Pairs Strategy Cumulative Equity vs Single Asset Benchmarks", fontweight="bold", pad=12)
    ax.set_ylabel("Portfolio Value ($ USD)")
    ax.legend(loc="upper left", framealpha=0.8)
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "pairs_pnl_benchmark.png"))
    plt.close(fig)
    print("Saved pairs_pnl_benchmark.png")

    # 2. Plot Dynamic Kalman Beta vs Static OLS
    fig, ax = plt.subplots(figsize=(12, 5), dpi=300)
    ax.plot(dates, kf_res.beta_history, label="Dynamic Kalman Filter Beta beta_t", color="#00E5FF", linewidth=2.0)
    ax.axhline(cadf_res.hedge_ratio, color="#FF1744", linestyle="--", linewidth=1.5, label=f"Static OLS Beta ({cadf_res.hedge_ratio:.3f})")
    ax.set_title("Dynamic State-Space Kalman Filter Beta Tracking vs Static OLS", fontweight="bold", pad=12)
    ax.set_ylabel("Hedge Ratio (Beta)")
    ax.legend(loc="best", framealpha=0.8)
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "dynamic_kalman_beta.png"))
    plt.close(fig)
    print("Saved dynamic_kalman_beta.png")

    # 3. Spread Z-Score & Signals
    fig, ax = plt.subplots(figsize=(12, 6), dpi=300)
    ax.plot(dates, kf_res.zscore_history, label="Standardized Spread Z-Score", color="#ECEFF1", alpha=0.85, linewidth=1.2)
    ax.axhline(2.0, color="#FF5252", linestyle="--", alpha=0.8, label="Entry Short (+2.0 sigma)")
    ax.axhline(-2.0, color="#69F0AE", linestyle="--", alpha=0.8, label="Entry Long (-2.0 sigma)")
    ax.axhline(0.0, color="#90A4AE", linestyle=":", alpha=0.6, label="Mean Reversion Exit (0.0)")
    ax.axhline(3.5, color="#D50000", linestyle="-.", alpha=0.5, label="Stop Loss (+3.5 sigma)")
    ax.axhline(-3.5, color="#00C853", linestyle="-.", alpha=0.5, label="Stop Loss (-3.5 sigma)")

    # Execution markers
    long_mask = signals.entries_long
    short_mask = signals.entries_short
    exit_mask = signals.exits_take_profit

    ax.scatter(dates[long_mask], kf_res.zscore_history[long_mask], color="#00E676", marker="^", s=45, label="Long Spread Entry", zorder=5)
    ax.scatter(dates[short_mask], kf_res.zscore_history[short_mask], color="#FF1744", marker="v", s=45, label="Short Spread Entry", zorder=5)
    ax.scatter(dates[exit_mask], kf_res.zscore_history[exit_mask], color="#FFD600", marker="x", s=30, label="Take Profit Exit", zorder=5)

    ax.set_title("Spread Z-Score Dynamic Trading Regime & Execution Signals", fontweight="bold", pad=12)
    ax.set_ylabel("Z-Score (sigma)")
    ax.set_ylim(-4.2, 4.2)
    ax.legend(loc="upper right", framealpha=0.8, ncol=2)
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "spread_zscore_signals.png"))
    plt.close(fig)
    print("Saved spread_zscore_signals.png")

    # 4. Underwater Drawdown
    fig, ax = plt.subplots(figsize=(12, 4.5), dpi=300)
    dd_pct = perf.drawdown_series * 100.0
    ax.fill_between(dates, dd_pct, 0, color="#FF1744", alpha=0.35)
    ax.plot(dates, dd_pct, color="#FF5252", linewidth=1.5)
    ax.set_title(f"Underwater Drawdown Profile (Max DD: -{perf.max_drawdown_pct:.2f}%)", fontweight="bold", pad=12)
    ax.set_ylabel("Drawdown (%)")
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "underwater_drawdown.png"))
    plt.close(fig)
    print("Saved underwater_drawdown.png")

    # 5. Walk-Forward Stability
    validator = WalkForwardValidator(train_window=252, test_window=63)
    wf_res = validator.run(y, x, df["Date"].tolist())

    fig, ax = plt.subplots(figsize=(12, 5), dpi=300)
    folds = [f"F{f.fold_id}" for f in wf_res.folds]
    is_sharpes = [f.in_sample_sharpe for f in wf_res.folds]
    oos_sharpes = [f.out_sample_sharpe for f in wf_res.folds]

    bar_width = 0.35
    idx = np.arange(len(folds))

    ax.bar(idx - bar_width/2, is_sharpes, bar_width, label="In-Sample Sharpe", color="#2979FF", alpha=0.85)
    ax.bar(idx + bar_width/2, oos_sharpes, bar_width, label="Out-of-Sample Sharpe", color="#00E676", alpha=0.85)
    ax.axhline(0, color="#546E7A", linewidth=1.0)

    ax.set_title(f"Walk-Forward Parameter Stability Across 12 Rolling Folds (WFE: {wf_res.walk_forward_efficiency * 100:.1f}%)", fontweight="bold", pad=12)
    ax.set_xticks(idx)
    ax.set_xticklabels(folds)
    ax.set_ylabel("Sharpe Ratio")
    ax.legend(loc="upper right", framealpha=0.8)
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "walk_forward_stability.png"))
    plt.close(fig)
    print("Saved walk_forward_stability.png")

    # 6. Monte Carlo Stochastic OU Path Fan
    from src.simulation.monte_carlo import PairsMonteCarloEngine
    from src.strategy.ou_process import OrnsteinUhlenbeckCalibrator

    ou_cal = OrnsteinUhlenbeckCalibrator(dt=1.0)
    ou_p = ou_cal.fit(cadf_res.residuals)

    mc_engine = PairsMonteCarloEngine(num_paths=3000, horizon_days=60, random_seed=42)
    mc_res = mc_engine.run_first_passage_analysis(
        initial_spread=-2.0,
        theta=ou_p.theta,
        mu=ou_p.mu,
        sigma=ou_p.sigma,
        target_reversion_spread=0.0,
        stop_loss_spread=-3.5,
        position_direction=1,
        historical_returns=btest.returns
    )

    fig, ax = plt.subplots(figsize=(12, 5.5), dpi=300)
    t_grid = mc_res.time_grid

    # Plot sample individual paths
    for i in range(40):
        ax.plot(t_grid, mc_res.paths[i], color="#00E5FF", alpha=0.08, linewidth=0.8)

    # Plot confidence percentile envelopes
    ax.fill_between(t_grid, mc_res.percentiles["5th"], mc_res.percentiles["95th"], color="#2979FF", alpha=0.18, label="90% Confidence Interval [5th - 95th]")
    ax.fill_between(t_grid, mc_res.percentiles["25th"], mc_res.percentiles["75th"], color="#00E676", alpha=0.25, label="50% Interquartile Range [25th - 75th]")
    ax.plot(t_grid, mc_res.percentiles["50th"], color="#FFD600", linewidth=2.0, label="Median Path (50th %ile)")

    # Target & Stop lines
    ax.axhline(0.0, color="#FFD600", linestyle="--", linewidth=1.5, label="Mean-Reversion Target (0.0)")
    ax.axhline(-3.5, color="#FF1744", linestyle="-.", linewidth=1.5, label="Stop-Loss Boundary (-3.5σ)")

    ax.set_title(f"Monte Carlo Stochastic OU Spread Simulation (PoP: {mc_res.probability_of_profit:.1f}% | Median Days to Exit: {mc_res.median_exit_days:.1f}d | VaR 95%: -${mc_res.var_95_pct:,.2f})", fontweight="bold", pad=12)
    ax.set_xlabel("Forward Trading Days")
    ax.set_ylabel("Synthetic Spread Deviation")
    ax.legend(loc="upper right", framealpha=0.85)
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "monte_carlo_paths.png"))
    plt.close(fig)
    print("Saved monte_carlo_paths.png")


if __name__ == "__main__":
    generate_all_plots()
