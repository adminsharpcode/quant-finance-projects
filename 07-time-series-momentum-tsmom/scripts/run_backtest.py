"""
Execution script for Time Series Momentum (TSMOM).
Loads 25-year multi-asset data, executes backtests across TSMOM (12M),
Multi-Horizon Blend, and 60/40 Equity/Bond Benchmark, and displays full performance metrics.
"""

import os
import sys
import numpy as np
import pandas as pd

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.core.returns import compute_daily_returns
from src.estimator.volatility import RollingVolatilityEstimator
from src.strategy.tsmom import TSMOMStrategy
from src.portfolio.sizing import VolatilityTargetingSizer
from src.backtest.engine import TSMOMBacktestEngine
from src.backtest.execution import ExecutionCostModel
from src.analytics.metrics import calculate_metrics
from src.analytics.crisis_alpha import CrisisAlphaAnalyzer


def run_pipeline():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    data_path = os.path.join(project_root, "data", "futures_daily_2000_2024.csv")
    
    if not os.path.exists(data_path):
        print(f"Dataset not found at {data_path}. Running generator...")
        from scripts.generate_market_data import generate_futures_dataset
        df = generate_futures_dataset()
        df.to_csv(data_path)
    else:
        df = pd.read_csv(data_path, index_col=0, parse_dates=True)
        
    print("=" * 80)
    print("PROJECT 07: TIME SERIES MOMENTUM (TSMOM) & CRISIS ALPHA ENGINE")
    print("Reference: Moskowitz, Ooi, & Pedersen (2012), Journal of Financial Economics")
    print("=" * 80)
    print(f"Loaded {len(df)} daily bars from {df.index[0].date()} to {df.index[-1].date()}")
    print(f"Universe ({len(df.columns)} contracts): {list(df.columns)}")
    print("-" * 80)
    
    # Target volatility: 12% annualized
    TARGET_VOL = 0.12
    cost_model = ExecutionCostModel(cost_bps=5.0, slippage_bps=2.0)
    engine = TSMOMBacktestEngine(initial_capital=10_000_000.0, cost_model=cost_model, rebalance_freq="M")
    
    # -------------------------------------------------------------
    # 1. Moskowitz 12M TSMOM Strategy
    # -------------------------------------------------------------
    strat_12m = TSMOMStrategy(lookback_days=252, multi_horizon=False)
    sig_12m = strat_12m.compute_signals(df)
    rets_daily = compute_daily_returns(df)
    vol_est = RollingVolatilityEstimator(window=60)
    vols = vol_est.estimate(rets_daily)
    
    sizer = VolatilityTargetingSizer(target_vol=TARGET_VOL, max_gross_leverage=3.5, portfolio_vol_scaling=True)
    weights_12m = sizer.compute_weights(sig_12m, vols, rets_daily)
    
    # Filter valid lookback window (start after 252 days + 60 days vol estimation = 312 days)
    valid_idx = df.index[315:]
    res_12m = engine.run(df.loc[valid_idx], weights_12m.loc[valid_idx])
    metrics_12m = calculate_metrics(res_12m.net_returns, res_12m.turnover)
    
    # -------------------------------------------------------------
    # 2. Multi-Horizon TSMOM Strategy (1M + 3M + 6M + 12M Blend)
    # -------------------------------------------------------------
    strat_multi = TSMOMStrategy(multi_horizon=True)
    sig_multi = strat_multi.compute_signals(df)
    weights_multi = sizer.compute_weights(sig_multi, vols, rets_daily)
    res_multi = engine.run(df.loc[valid_idx], weights_multi.loc[valid_idx])
    metrics_multi = calculate_metrics(res_multi.net_returns, res_multi.turnover)
    
    # -------------------------------------------------------------
    # 3. Benchmark 1: 60/40 Equity/Bond (60% ES + 40% TY)
    # -------------------------------------------------------------
    es_ret = rets_daily["ES"].loc[valid_idx]
    ty_ret = rets_daily["TY"].loc[valid_idx]
    bench_6040_ret = 0.60 * es_ret + 0.40 * ty_ret
    metrics_6040 = calculate_metrics(bench_6040_ret)
    
    # -------------------------------------------------------------
    # 4. Benchmark 2: S&P 500 Buy & Hold (ES)
    # -------------------------------------------------------------
    metrics_sp500 = calculate_metrics(es_ret)
    
    # -------------------------------------------------------------
    # Display Institutional Performance Comparison
    # -------------------------------------------------------------
    comparison_data = {
        "Metric": [
            "Total Return (%)",
            "CAGR (%)",
            "Annualized Volatility (%)",
            "Sharpe Ratio",
            "Sortino Ratio",
            "Maximum Drawdown (%)",
            "Max DD Duration (Days)",
            "Calmar Ratio",
            "Skewness (Convexity)",
            "Excess Kurtosis",
            "Daily Win Rate (%)",
            "Profit Factor",
            "Annual Turnover (x)",
        ],
        "TSMOM (12M Paper)": [
            f"{metrics_12m.total_return * 100:.2f}%",
            f"{metrics_12m.cagr * 100:.2f}%",
            f"{metrics_12m.annualized_volatility * 100:.2f}%",
            f"{metrics_12m.sharpe_ratio:.2f}",
            f"{metrics_12m.sortino_ratio:.2f}",
            f"{metrics_12m.max_drawdown * 100:.2f}%",
            f"{metrics_12m.max_drawdown_duration_days}",
            f"{metrics_12m.calmar_ratio:.2f}",
            f"{metrics_12m.skewness:+.2f}",
            f"{metrics_12m.kurtosis:.2f}",
            f"{metrics_12m.win_rate_daily * 100:.2f}%",
            f"{metrics_12m.profit_factor:.2f}",
            f"{metrics_12m.annual_turnover:.2f}",
        ],
        "TSMOM Multi-Horizon": [
            f"{metrics_multi.total_return * 100:.2f}%",
            f"{metrics_multi.cagr * 100:.2f}%",
            f"{metrics_multi.annualized_volatility * 100:.2f}%",
            f"{metrics_multi.sharpe_ratio:.2f}",
            f"{metrics_multi.sortino_ratio:.2f}",
            f"{metrics_multi.max_drawdown * 100:.2f}%",
            f"{metrics_multi.max_drawdown_duration_days}",
            f"{metrics_multi.calmar_ratio:.2f}",
            f"{metrics_multi.skewness:+.2f}",
            f"{metrics_multi.kurtosis:.2f}",
            f"{metrics_multi.win_rate_daily * 100:.2f}%",
            f"{metrics_multi.profit_factor:.2f}",
            f"{metrics_multi.annual_turnover:.2f}",
        ],
        "Benchmark 60/40": [
            f"{metrics_6040.total_return * 100:.2f}%",
            f"{metrics_6040.cagr * 100:.2f}%",
            f"{metrics_6040.annualized_volatility * 100:.2f}%",
            f"{metrics_6040.sharpe_ratio:.2f}",
            f"{metrics_6040.sortino_ratio:.2f}",
            f"{metrics_6040.max_drawdown * 100:.2f}%",
            f"{metrics_6040.max_drawdown_duration_days}",
            f"{metrics_6040.calmar_ratio:.2f}",
            f"{metrics_6040.skewness:+.2f}",
            f"{metrics_6040.kurtosis:.2f}",
            f"{metrics_6040.win_rate_daily * 100:.2f}%",
            f"{metrics_6040.profit_factor:.2f}",
            "N/A",
        ],
        "S&P 500 (ES Long)": [
            f"{metrics_sp500.total_return * 100:.2f}%",
            f"{metrics_sp500.cagr * 100:.2f}%",
            f"{metrics_sp500.annualized_volatility * 100:.2f}%",
            f"{metrics_sp500.sharpe_ratio:.2f}",
            f"{metrics_sp500.sortino_ratio:.2f}",
            f"{metrics_sp500.max_drawdown * 100:.2f}%",
            f"{metrics_sp500.max_drawdown_duration_days}",
            f"{metrics_sp500.calmar_ratio:.2f}",
            f"{metrics_sp500.skewness:+.2f}",
            f"{metrics_sp500.kurtosis:.2f}",
            f"{metrics_sp500.win_rate_daily * 100:.2f}%",
            f"{metrics_sp500.profit_factor:.2f}",
            "N/A",
        ],
    }
    
    comp_df = pd.DataFrame(comparison_data)
    print(comp_df.to_string(index=False))
    print("=" * 80)
    
    # -------------------------------------------------------------
    # Crisis Alpha Stress Attribution
    # -------------------------------------------------------------
    print("\nCRISIS ALPHA STRESS TEST BREAKDOWN (Historical Drawdown Regimes)")
    print("-" * 80)
    crisis_analyzer = CrisisAlphaAnalyzer()
    regimes_df = crisis_analyzer.evaluate_regimes(res_12m.net_returns, es_ret)
    print(regimes_df.to_string(index=False))
    
    betas = crisis_analyzer.compute_regime_betas(res_12m.net_returns, es_ret)
    print("\nMarket Asymmetry & Convexity Betas:")
    for k, v in betas.items():
        print(f"  {k:28s}: {v:+.4f}")
    print("=" * 80)
    
    # Save results to visualizations directory
    viz_dir = os.path.join(project_root, "visualizations")
    os.makedirs(viz_dir, exist_ok=True)
    comp_df.to_csv(os.path.join(viz_dir, "performance_summary.csv"), index=False)
    regimes_df.to_csv(os.path.join(viz_dir, "crisis_alpha_regimes.csv"), index=False)
    
    # Save daily time series for plotting
    export_df = pd.DataFrame({
        "TSMOM_12M_Net": res_12m.net_returns,
        "TSMOM_Multi_Net": res_multi.net_returns,
        "Benchmark_6040": bench_6040_ret,
        "SP500_ES": es_ret,
    })
    export_df.to_csv(os.path.join(viz_dir, "strategy_daily_returns.csv"))
    print(f"\n[✓] Results successfully exported to {viz_dir}")


if __name__ == "__main__":
    run_pipeline()
