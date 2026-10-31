"""
Institutional Production Pipeline Runner
----------------------------------------
Hedge Fund-Grade Quantitative Trading & Risk Evaluation:
1. Loads real broker tick datasets (EURUSD, GBPUSD, XAUUSD)
2. Executes In-Sample / Out-of-Sample Parameter Optimization
3. Evaluates full Event-Driven Tick Backtests with microstructure realism
4. Runs 5,000-Iteration Monte Carlo Simulation (Ruin Probability & VaR/CVaR)
5. Computes Institutional Risk Suite (Sortino, Calmar, Omega, Ulcer Index, CDaR 95%)
6. Executes Purged & Embargoed Walk-Forward Cross-Validation (CPCV)
7. Conducts Multi-Regime Microstructure Stress Testing (Liquidity shocks, latency, flash gaps)
8. Synthesizes Multi-Asset Alpha Portfolio with Volatility Targeting
"""

import os
import sys
import json
import pandas as pd
import numpy as np

# Ensure project root is in path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.engine.strategy import InstitutionalAlphaStrategy
from src.engine.backtester import TickBacktester
from src.engine.optimizer import ParameterOptimizer
from src.engine.monte_carlo import MonteCarloEngine
from src.engine.institutional_metrics import (
    compute_institutional_risk_suite,
    compute_deflated_sharpe_ratio,
    compute_expected_max_sharpe
)
from src.engine.walk_forward_purged import PurgedWalkForwardCV
from src.engine.stress_testing import MicrostructureStressTester
from src.engine.portfolio_allocator import InstitutionalPortfolioEngine


def execute_pipeline():
    data_dir = os.path.join(os.path.dirname(__file__), "data")
    eurusd_csv = os.path.join(data_dir, "real_ticks_eurusd.csv")
    gbpusd_csv = os.path.join(data_dir, "real_ticks_gbpusd.csv")
    xauusd_csv = os.path.join(data_dir, "real_ticks_xauusd.csv")

    print("==================================================")
    print("STEP 1: LOADING REAL BROKER TICK DATASETS")
    print("==================================================")
    df_eurusd = pd.read_csv(eurusd_csv)
    df_gbpusd = pd.read_csv(gbpusd_csv)
    df_xauusd = pd.read_csv(xauusd_csv)
    print(f"Loaded EURUSD: {len(df_eurusd)} ticks | Avg Spread: {df_eurusd['spread'].mean():.5f}")
    print(f"Loaded GBPUSD: {len(df_gbpusd)} ticks | Avg Spread: {df_gbpusd['spread'].mean():.5f}")
    print(f"Loaded XAUUSD: {len(df_xauusd)} ticks | Avg Spread: {df_xauusd['spread'].mean():.5f}")

    print("\n==================================================")
    print("STEP 2: RUNNING PARAMETER OPTIMIZATION (EURUSD)")
    print("==================================================")
    optimizer = ParameterOptimizer(
        df_ticks=df_eurusd,
        initial_capital=10000.0,
        train_test_split=0.65,
        pip_size=0.0001,
        lot_size=100000.0
    )

    param_grid = {
        "window": [40, 50, 60],
        "band_deviation": [1.6, 1.8],
        "sl_pips": [10.0, 12.0, 15.0],
        "tp_pips": [20.0, 24.0, 30.0],
        "max_spread_pips": [1.8]
    }

    opt_results = optimizer.optimize_grid(param_grid, metric_key="sharpe_ratio", top_k=3)
    best_params = opt_results["best_model"]["params"]
    print("Best Parameters Identified:", json.dumps(best_params, indent=2))
    print("In-Sample Return:", opt_results["best_model"]["in_sample"]["return_pct"], "%")
    print("Out-of-Sample Return:", opt_results["best_model"]["out_of_sample"]["return_pct"], "%")

    print("\n==================================================")
    print("STEP 3: FULL TICK-BY-TICK REAL BROKER BACKTESTS")
    print("==================================================")
    # EURUSD
    strategy_eur = InstitutionalAlphaStrategy(pip_size=0.0001, **best_params)
    bt_eur = TickBacktester(
        strategy=strategy_eur,
        initial_capital=10000.0,
        base_slippage_pips=0.1,
        pip_size=0.0001,
        commission_per_lot=5.0,
        lot_size=100000.0
    ).run(df_eurusd)
    bt_eur_dict = bt_eur.to_dict()
    print("EURUSD Performance:", json.dumps(bt_eur_dict, indent=2))

    # GBPUSD
    strategy_gbp = InstitutionalAlphaStrategy(
        window=50,
        band_deviation=1.8,
        sl_pips=12.0,
        tp_pips=24.0,
        max_spread_pips=2.0,
        pip_size=0.0001
    )
    bt_gbp = TickBacktester(
        strategy=strategy_gbp,
        initial_capital=10000.0,
        base_slippage_pips=0.1,
        pip_size=0.0001,
        commission_per_lot=5.0,
        lot_size=100000.0
    ).run(df_gbpusd)
    bt_gbp_dict = bt_gbp.to_dict()
    print("GBPUSD Performance:", json.dumps(bt_gbp_dict, indent=2))

    # XAUUSD (Gold: pip=0.1, SL=25 pips = $2.50, TP=75 pips = $7.50, max_spread=4.0 pips = $0.40)
    strategy_gold = InstitutionalAlphaStrategy(
        window=120,
        band_deviation=1.9,
        sl_pips=25.0,
        tp_pips=75.0,
        max_spread_pips=4.0,
        pip_size=0.10,
        symbol_type="gold"
    )
    bt_gold = TickBacktester(
        strategy=strategy_gold,
        initial_capital=10000.0,
        base_slippage_pips=0.2,
        pip_size=0.10,
        commission_per_lot=5.0,
        lot_size=100.0
    ).run(df_xauusd)
    bt_gold_dict = bt_gold.to_dict()
    print("XAUUSD Performance:", json.dumps(bt_gold_dict, indent=2))

    print("\n==================================================")
    print("STEP 4: 5,000-RUN MONTE CARLO RISK SIMULATION")
    print("==================================================")
    all_portfolio_trades = bt_eur.trades + bt_gbp.trades + bt_gold.trades
    print(f"Total trades across portfolio: {len(all_portfolio_trades)}")

    mc = MonteCarloEngine(
        trades=all_portfolio_trades,
        initial_capital=10000.0,
        num_simulations=5000,
        ruin_drawdown_pct=30.0,
        random_seed=42
    )
    mc_results = mc.run_simulation()
    print("Monte Carlo Risk Summary:")
    print(f"- Probability of Ruin (DD > 30%): {mc_results['probability_of_ruin_pct']}%")
    print(f"- Median Final Equity: ${mc_results['final_equity']['p50_median']}")
    print(f"- 5th Percentile (Conservative) Final Equity: ${mc_results['final_equity']['p5_bearish']}")
    print(f"- 95th Percentile (Optimistic) Final Equity: ${mc_results['final_equity']['p95_bullish']}")
    print(f"- VaR 95%: {mc_results['risk_metrics']['var_95_pct']}%")
    print(f"- CVaR (Expected Shortfall): {mc_results['risk_metrics']['cvar_95_expected_shortfall_pct']}%")

    print("\n==================================================")
    print("STEP 5: INSTITUTIONAL QUANTITATIVE RISK SUITE")
    print("==================================================")
    trade_pnls = [t.net_pnl for t in all_portfolio_trades]
    inst_risk = compute_institutional_risk_suite(trade_pnls, initial_capital=10000.0)
    print("Institutional Risk Suite:")
    print(f"- Sharpe Ratio: {inst_risk['sharpe_ratio']} | Sortino: {inst_risk['sortino_ratio']} | Calmar: {inst_risk['calmar_ratio']}")
    print(f"- Omega Ratio: {inst_risk['omega_ratio']} | Gain-to-Pain: {inst_risk['gain_to_pain_ratio']}")
    print(f"- Ulcer Index: {inst_risk['ulcer_index']} | Martin Ratio: {inst_risk['martin_ratio']}")
    print(f"- Tail Risk Ratio: {inst_risk['tail_risk_ratio']} | CDaR 95%: {inst_risk['cdar_95_pct']}%")

    # Deflated Sharpe against the 1,297 corpus hurdle
    # Load corpus summary to extract expected max hurdle
    summary_path = os.path.join(data_dir, "sequential_test_summary.json")
    if os.path.exists(summary_path):
        with open(summary_path, 'r', encoding='utf-8') as f:
            audit_summary = json.load(f)
        trials_n = audit_summary.get('multiple_testing_parameters', {}).get('trials_evaluated', 393)
        sharpe_var = audit_summary.get('multiple_testing_parameters', {}).get('sharpe_variance', 200.0)
    else:
        trials_n = 393
        sharpe_var = 200.0

    dsr_portfolio = compute_deflated_sharpe_ratio(
        sr=inst_risk['sharpe_ratio'],
        all_sr_trials=np.random.normal(0, np.sqrt(sharpe_var), size=trials_n),
        n_obs=len(trade_pnls),
        skew=inst_risk['return_skewness'],
        kurt=inst_risk['return_kurtosis']
    )
    print(f"- Expected Max Sharpe Hurdle (N={trials_n}): {dsr_portfolio['expected_max_sharpe']}")
    print(f"- Deflated Sharpe Ratio: {dsr_portfolio['deflated_sharpe_ratio']} (p-value: {dsr_portfolio['p_value_deflated']})")

    print("\n==================================================")
    print("STEP 6: PURGED & EMBARGOED WALK-FORWARD CV (CPCV)")
    print("==================================================")
    pwfo = PurgedWalkForwardCV(n_splits=4, train_ratio=0.60, purge_ticks=50, embargo_ticks=50)

    def eval_gbp_slice(df_slice: pd.DataFrame) -> dict:
        bt = TickBacktester(
            strategy=strategy_gbp,
            initial_capital=10000.0,
            base_slippage_pips=0.1,
            pip_size=0.0001,
            commission_per_lot=5.0,
            lot_size=100000.0
        ).run(df_slice)
        d = bt.to_dict()
        return {
            "sharpe_ratio": d["sharpe_ratio"],
            "return_pct": d["return_pct"],
            "win_rate_pct": d["win_rate_pct"],
            "total_trades": d["total_trades"],
            "profit_factor": d["profit_factor"],
            "max_drawdown_pct": d["max_drawdown_pct"]
        }

    wfo_results = pwfo.evaluate_strategy_wfo(df_gbpusd, eval_gbp_slice)
    print(f"Purged WFO Out-of-Sample Efficiency Ratio (OER): {wfo_results['out_of_sample_efficiency_ratio']}")
    print(f"Walk-Forward Verdict: {wfo_results['walk_forward_verdict']}")

    print("\n==================================================")
    print("STEP 7: MICROSTRUCTURE LIQUIDITY & LATENCY STRESS")
    print("==================================================")
    stress_engine = MicrostructureStressTester(initial_capital=10000.0)
    stress_results = stress_engine.run_stress_suite(df_gbpusd, eval_gbp_slice)
    print(f"Baseline Sharpe: {stress_results['baseline']['sharpe_ratio']}")
    print(f"3.0x Spread Blowout Sharpe: {stress_results['spread_stress']['3.0x_spread']['sharpe_ratio']}")
    print(f"150ms Latency Shock Sharpe: {stress_results['latency_stress']['150ms_latency']['sharpe_ratio']}")
    print(f"Fragility Score: {stress_results['fragility_score_pct']}% -> {stress_results['stress_resilience_verdict']}")

    print("\n==================================================")
    print("STEP 8: INSTITUTIONAL PORTFOLIO ALLOCATION")
    print("==================================================")
    port_engine = InstitutionalPortfolioEngine(target_annual_vol_pct=10.0, max_leverage=1.5, initial_capital=10000.0)
    port_input = {
        "EURUSD_Alpha": [t.net_pnl for t in bt_eur.trades],
        "GBPUSD_Alpha": [t.net_pnl for t in bt_gbp.trades],
        "XAUUSD_Alpha": [t.net_pnl for t in bt_gold.trades]
    }
    portfolio_summary = port_engine.combine_strategies(port_input, weighting_scheme="inverse_vol")
    print(f"Diversification Ratio: {portfolio_summary.get('diversification_ratio')}")
    print(f"Realized Annual Volatility: {portfolio_summary.get('realized_vol_pct')}%")
    print("Component Weights:", {k: v['weight'] for k, v in portfolio_summary.get('components', {}).items()})

    final_output = {
        "optimization": opt_results,
        "backtest_eurusd": bt_eur_dict,
        "backtest_gbpusd": bt_gbp_dict,
        "backtest_xauusd": bt_gold_dict,
        "monte_carlo": mc_results,
        "institutional_risk_suite": inst_risk,
        "deflated_sharpe": dsr_portfolio,
        "purged_walk_forward": wfo_results,
        "microstructure_stress_tests": stress_results,
        "portfolio_allocation": portfolio_summary
    }

    results_path = os.path.join(data_dir, "pipeline_results.json")
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump(final_output, f, indent=2)
    print(f"\nAll institutional pipeline results successfully saved to {results_path}")
    return final_output


if __name__ == "__main__":
    execute_pipeline()
