"""
Execution script for Project 08: Value and Momentum Everywhere.
Executes standalone Value, standalone Momentum, 50/50 Risk Parity Combo,
and prints the empirical verification of the negative correlation and Sharpe expansion.
Based on Asness, Moskowitz, & Pedersen (2013).
"""

import os
import sys
import numpy as np
import pandas as pd

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.factors.momentum import MomentumFactor
from src.factors.value import ValueFactor
from src.portfolio.combination import ValMomCombiner
from src.backtest.engine import FactorBacktestEngine
from src.analytics.metrics import calculate_factor_metrics
from src.analytics.correlation import compute_diversification_metrics, compute_rolling_correlation


def run_pipeline():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    data_dir = os.path.join(project_root, "data")
    prices_path = os.path.join(data_dir, "prices_daily_2000_2024.csv")
    bp_path = os.path.join(data_dir, "book_to_price_daily_2000_2024.csv")
    
    if not os.path.exists(prices_path):
        from scripts.generate_market_data import generate_valmom_dataset
        prices, bp = generate_valmom_dataset()
        prices.to_csv(prices_path)
        bp.to_csv(bp_path)
    else:
        prices = pd.read_csv(prices_path, index_col=0, parse_dates=True)
        bp = pd.read_csv(bp_path, index_col=0, parse_dates=True)
        
    print("=" * 80)
    print("PROJECT 08: VALUE AND MOMENTUM EVERYWHERE (FACTOR ENGINE)")
    print("Reference: Asness, Moskowitz, & Pedersen (2013), The Journal of Finance")
    print("=" * 80)
    print(f"Loaded {len(prices)} daily bars from {prices.index[0].date()} to {prices.index[-1].date()}")
    print(f"Universe ({len(prices.columns)} assets): {list(prices.columns)}")
    print("-" * 80)
    
    # 1. Compute Factor Weights
    mom_engine = MomentumFactor(lookback_days=252, skip_days=21)
    val_engine = ValueFactor(mode="book_to_price")
    
    mom_weights = mom_engine.compute_weights(prices, gross_leverage=1.0)
    val_weights = val_engine.compute_weights(prices, bp_data=bp, gross_leverage=1.0)
    
    asset_returns = prices.pct_change().fillna(0.0)
    
    # 2. Compute 50/50 Risk Parity Combo Weights
    combiner = ValMomCombiner(target_vol=0.12, risk_parity=True, max_leverage=2.5)
    combo_weights = combiner.combine(val_weights, mom_weights, asset_returns)
    
    # Valid index starts after 252 days + 21 days skip = 273 days
    valid_idx = prices.index[280:]
    
    # 3. Execute Backtests (5 bps transaction cost, Monthly rebalancing)
    engine = FactorBacktestEngine(initial_capital=10_000_000.0, cost_bps=5.0, rebalance_freq="M")
    
    res_val = engine.run(prices.loc[valid_idx], val_weights.loc[valid_idx])
    res_mom = engine.run(prices.loc[valid_idx], mom_weights.loc[valid_idx])
    res_combo = engine.run(prices.loc[valid_idx], combo_weights.loc[valid_idx])
    
    # Market benchmark (equal-weight universe buy-and-hold)
    mkt_ret = asset_returns.loc[valid_idx].mean(axis=1)
    metrics_mkt = calculate_factor_metrics(mkt_ret)
    
    metrics_val = calculate_factor_metrics(res_val.net_returns, res_val.turnover)
    metrics_mom = calculate_factor_metrics(res_mom.net_returns, res_mom.turnover)
    metrics_combo = calculate_factor_metrics(res_combo.net_returns, res_combo.turnover)
    
    # 4. Correlation & Diversification Multiplier
    div_metrics = compute_diversification_metrics(res_val.net_returns, res_mom.net_returns)
    
    # Display Scorecard
    scorecard = {
        "Metric": [
            "Total Cumulative Return (%)",
            "CAGR (Annualized Return %)",
            "Annualized Volatility (%)",
            "Sharpe Ratio",
            "Sortino Ratio",
            "Maximum Drawdown (%)",
            "Max DD Duration (Days)",
            "Calmar Ratio",
            "Skewness",
            "Excess Kurtosis",
            "Daily Win Rate (%)",
            "Profit Factor",
            "Annual Turnover (x)",
        ],
        "Value (Everywhere)": [
            f"{metrics_val.total_return * 100:.2f}%",
            f"{metrics_val.cagr * 100:.2f}%",
            f"{metrics_val.annualized_volatility * 100:.2f}%",
            f"{metrics_val.sharpe_ratio:.2f}",
            f"{metrics_val.sortino_ratio:.2f}",
            f"{metrics_val.max_drawdown * 100:.2f}%",
            f"{metrics_val.max_drawdown_duration_days}",
            f"{metrics_val.calmar_ratio:.2f}",
            f"{metrics_val.skewness:+.2f}",
            f"{metrics_val.kurtosis:.2f}",
            f"{metrics_val.win_rate_daily * 100:.2f}%",
            f"{metrics_val.profit_factor:.2f}",
            f"{metrics_val.annual_turnover:.2f}",
        ],
        "Momentum (Everywhere)": [
            f"{metrics_mom.total_return * 100:.2f}%",
            f"{metrics_mom.cagr * 100:.2f}%",
            f"{metrics_mom.annualized_volatility * 100:.2f}%",
            f"{metrics_mom.sharpe_ratio:.2f}",
            f"{metrics_mom.sortino_ratio:.2f}",
            f"{metrics_mom.max_drawdown * 100:.2f}%",
            f"{metrics_mom.max_drawdown_duration_days}",
            f"{metrics_mom.calmar_ratio:.2f}",
            f"{metrics_mom.skewness:+.2f}",
            f"{metrics_mom.kurtosis:.2f}",
            f"{metrics_mom.win_rate_daily * 100:.2f}%",
            f"{metrics_mom.profit_factor:.2f}",
            f"{metrics_mom.annual_turnover:.2f}",
        ],
        "50/50 Combo (Risk Parity)": [
            f"{metrics_combo.total_return * 100:.2f}%",
            f"{metrics_combo.cagr * 100:.2f}%",
            f"{metrics_combo.annualized_volatility * 100:.2f}%",
            f"{metrics_combo.sharpe_ratio:.2f}",
            f"{metrics_combo.sortino_ratio:.2f}",
            f"{metrics_combo.max_drawdown * 100:.2f}%",
            f"{metrics_combo.max_drawdown_duration_days}",
            f"{metrics_combo.calmar_ratio:.2f}",
            f"{metrics_combo.skewness:+.2f}",
            f"{metrics_combo.kurtosis:.2f}",
            f"{metrics_combo.win_rate_daily * 100:.2f}%",
            f"{metrics_combo.profit_factor:.2f}",
            f"{metrics_combo.annual_turnover:.2f}",
        ],
        "Market Benchmark": [
            f"{metrics_mkt.total_return * 100:.2f}%",
            f"{metrics_mkt.cagr * 100:.2f}%",
            f"{metrics_mkt.annualized_volatility * 100:.2f}%",
            f"{metrics_mkt.sharpe_ratio:.2f}",
            f"{metrics_mkt.sortino_ratio:.2f}",
            f"{metrics_mkt.max_drawdown * 100:.2f}%",
            f"{metrics_mkt.max_drawdown_duration_days}",
            f"{metrics_mkt.calmar_ratio:.2f}",
            f"{metrics_mkt.skewness:+.2f}",
            f"{metrics_mkt.kurtosis:.2f}",
            f"{metrics_mkt.win_rate_daily * 100:.2f}%",
            f"{metrics_mkt.profit_factor:.2f}",
            "N/A",
        ],
    }
    
    score_df = pd.DataFrame(scorecard)
    print(score_df.to_string(index=False))
    print("=" * 80)
    
    print("\nTHE ASNESS ET AL. (2013) DIVERSIFICATION MIRACLE:")
    print("-" * 80)
    print(f"  Empirical Correlation (rho_val_mom) : {div_metrics['Value_Momentum_Correlation']:+.4f}")
    print(f"  Theoretical Diversification Multiplier: {div_metrics['Diversification_Multiplier']:.2f}x")
    print(f"  Standalone Value Sharpe               : {div_metrics['Value_Standalone_Sharpe']:.2f}")
    print(f"  Standalone Momentum Sharpe            : {div_metrics['Momentum_Standalone_Sharpe']:.2f}")
    print(f"  Actual 50/50 Combo Sharpe             : {div_metrics['Actual_Combo_Sharpe']:.2f}")
    print(f"  Sharpe Expansion over Average Leg     : +{div_metrics['Sharpe_Gain_Pct']:.1f}%")
    print("=" * 80)
    
    # Export for visualization
    viz_dir = os.path.join(project_root, "visualizations")
    os.makedirs(viz_dir, exist_ok=True)
    score_df.to_csv(os.path.join(viz_dir, "performance_scorecard.csv"), index=False)
    
    export_df = pd.DataFrame({
        "Value_Net": res_val.net_returns,
        "Momentum_Net": res_mom.net_returns,
        "Combo_50_50_Net": res_combo.net_returns,
        "Market_Benchmark": mkt_ret,
    })
    export_df.to_csv(os.path.join(viz_dir, "factor_daily_returns.csv"))
    print(f"\n[✓] Results successfully exported to {viz_dir}")


if __name__ == "__main__":
    run_pipeline()
