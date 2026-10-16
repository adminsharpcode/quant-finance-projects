"""End-to-end Pairs Trading & Cointegration Backtest Runner.

Executes cointegration diagnostics (CADF, Johansen), Ornstein-Uhlenbeck calibration,
dynamic Kalman filtering, institutional backtesting with borrow fees, and
rolling walk-forward out-of-sample cross validation across equity and commodity universes.
"""

import os
import sys
import numpy as np
import pandas as pd

# Add src to system path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.analysis.cadf_test import cadf_test
from src.analysis.johansen_test import johansen_test
from src.state_space.kalman_filter import KalmanHedgeTracker
from src.strategy.ou_process import OrnsteinUhlenbeckCalibrator
from src.strategy.zscore_signals import ZScoreSignalGenerator
from src.backtest.execution_sim import PairsExecutionSimulator
from src.backtest.performance import PerformanceAnalyzer
from src.validation.walk_forward import WalkForwardValidator


def run_pipeline_for_pair(
    pair_name: str,
    series_y: np.ndarray,
    series_x: np.ndarray,
    dates: list,
    y_label: str,
    x_label: str,
    z_entry: float = 2.0,
    z_exit: float = 0.0,
    z_stop: float = 3.5
):
    """Run full quantitative pipeline on a single asset pair."""
    print(f"\n{'='*75}")
    print(f"  QUANT PAIR ENGINE: {pair_name} ({y_label} vs {x_label})")
    print(f"{'='*75}")

    # 1. Cointegration Diagnostics
    cadf_res = cadf_test(series_y, series_x)
    joh_data = np.column_stack([series_y, series_x])
    joh_res = johansen_test(joh_data)

    print(f"[1] COINTEGRATION & STATIONARITY ANALYSIS:")
    print(f"    CADF Test Statistic   : {cadf_res.test_statistic:.4f} (p-value: {cadf_res.p_value:.4e})")
    print(f"    Cointegration Status  : {'CONFIRMED (p < 0.05)' if cadf_res.is_cointegrated else 'WEAK / NON-COINTEGRATED'}")
    print(f"    Static OLS Beta (Hedge): {cadf_res.hedge_ratio:.4f} (Intercept: {cadf_res.intercept:.4f}, R^2: {cadf_res.r_squared:.4f})")
    print(f"    Johansen Trace Stat   : {joh_res.trace_statistics[0]:.2f} (95% Crit: {joh_res.trace_critical_values[0, 1]:.2f}, Rank: {joh_res.cointegration_rank})")

    # 2. Ornstein-Uhlenbeck Calibration
    ou_cal = OrnsteinUhlenbeckCalibrator(dt=1.0)
    ou_params = ou_cal.fit(cadf_res.residuals)
    print(f"\n[2] ORNSTEIN-UHLENBECK SDE CALIBRATION:")
    print(f"    Mean-Reversion Speed theta : {ou_params.theta:.4f}")
    print(f"    Equilibrium Mean mu        : {ou_params.mu:.4f}")
    print(f"    Spread Volatility sigma    : {ou_params.sigma:.4f}")
    print(f"    Half-Life of Reversion tau : {ou_params.half_life:.2f} trading days")
    print(f"    Stationary Std Dev         : {ou_params.eq_std:.4f}")

    # 3. Dynamic State-Space Kalman Filter Tracking
    kf = KalmanHedgeTracker(delta=1e-4, r_var=1e-3, initial_beta=cadf_res.hedge_ratio)
    kf_res = kf.filter_series(series_y, series_x)
    print(f"\n[3] DYNAMIC KALMAN FILTER TRACKING:")
    print(f"    Initial Beta : {kf_res.beta_history[0]:.4f}")
    print(f"    Final Beta   : {kf_res.beta_history[-1]:.4f} (Min: {np.min(kf_res.beta_history):.4f}, Max: {np.max(kf_res.beta_history):.4f})")
    print(f"    Current Z-Score: {kf_res.zscore_history[-1]:.2f} sigma")

    # 4. Signal Generation
    sig_gen = ZScoreSignalGenerator(z_entry=z_entry, z_exit=z_exit, z_stop=z_stop)
    signals = sig_gen.generate(kf_res.zscore_history)

    # 5. Realistic Microstructure Backtest
    sim = PairsExecutionSimulator(
        initial_capital=100_000.0,
        commission_per_share=0.005,
        half_spread_bps=3.0,
        slippage_bps=2.0,
        short_borrow_fee_annual=0.015
    )
    btest = sim.simulate(series_y, series_x, signals.positions, kf_res.beta_history, dates)
    analyzer = PerformanceAnalyzer(risk_free_rate_annual=0.04)
    perf = analyzer.analyze(btest)

    print(f"\n[4] INSTITUTIONAL BACKTEST METRICS (Net of Borrow Fees & Slippage):")
    print(f"    Initial Capital       : ${btest.initial_capital:,.2f}")
    print(f"    Final Portfolio Equity: ${btest.final_equity:,.2f}")
    print(f"    Total Net Profit/Loss : ${btest.total_net_pnl:,.2f} ({perf.total_return_pct:+.2f}%)")
    print(f"    Compound Annual Growth: {perf.cagr_pct:+.2f}%")
    print(f"    Annualized Volatility : {perf.annualized_vol_pct:.2f}%")
    print(f"    Sharpe Ratio (Rf=4.0%): {perf.sharpe_ratio:.2f}")
    print(f"    Sortino Ratio         : {perf.sortino_ratio:.2f}")
    print(f"    Maximum Drawdown      : -{perf.max_drawdown_pct:.2f}% (Duration: {perf.max_drawdown_duration_bars} days)")
    print(f"    Calmar Ratio          : {perf.calmar_ratio:.2f}")
    print(f"    Total Roundtrips      : {perf.total_trades} (Win Rate: {perf.win_rate_pct:.1f}%)")
    print(f"    Profit Factor         : {perf.profit_factor:.2f}")
    print(f"    Avg Trade Holding Time: {perf.avg_holding_duration_bars:.1f} days")
    print(f"    Friction Drag Breakdown:")
    print(f"      • Broker Commissions: ${btest.total_commissions:,.2f}")
    print(f"      • Half-Spread Crossing & Slippage: ${btest.total_slippage:,.2f}")
    print(f"      • Short Borrow Fees (1.5% p.a.):   ${btest.total_borrow_fees:,.2f}")

    # 6. Walk-Forward Cross Validation
    validator = WalkForwardValidator(
        train_window=252,
        test_window=63,
        z_entry_grid=[1.5, 2.0, 2.5],
        z_exit_grid=[0.0, 0.5]
    )
    wf_res = validator.run(series_y, series_x, dates)
    print(f"\n[5] OUT-OF-SAMPLE WALK-FORWARD VALIDATION (Zero Lookahead Bias):")
    print(f"    Total Rolling Folds   : {len(wf_res.folds)}")
    print(f"    Mean In-Sample Sharpe : {wf_res.average_is_sharpe:.2f}")
    print(f"    Mean Out-of-Sample Sh : {wf_res.average_oos_sharpe:.2f}")
    print(f"    Walk-Forward Efficiency: {wf_res.walk_forward_efficiency * 100:.1f}%")
    print(f"    Robustness Status     : {'PASSED (WFE >= 50%)' if wf_res.is_robust else 'MARGINAL / OVERFIT RISK'}")

    # 7. Monte Carlo Stochastic Path Simulation
    from src.simulation.monte_carlo import PairsMonteCarloEngine
    mc_engine = PairsMonteCarloEngine(num_paths=2000, horizon_days=60, random_seed=42)
    mc_res = mc_engine.run_first_passage_analysis(
        initial_spread=-z_entry,
        theta=ou_params.theta,
        mu=0.0,
        sigma=ou_params.sigma,
        target_reversion_spread=z_exit,
        stop_loss_spread=-z_stop,
        position_direction=1,
        historical_returns=btest.returns
    )
    print(f"\n[6] MONTE CARLO STOCHASTIC SIMULATION (2,000 Paths, 60-Day Horizon):")
    print(f"    Probability of Profit (PoP) : {mc_res.probability_of_profit:.1f}% (Reversion to {z_exit:.1f} sigma)")
    print(f"    Probability of Stop-Loss    : {mc_res.probability_of_stop_loss:.1f}% (Boundary at -{z_stop:.1f} sigma)")
    print(f"    Expected Days to Exit       : {mc_res.expected_exit_days:.1f} days (Median: {mc_res.median_exit_days:.1f} days)")
    print(f"    Parametric 95% Value at Risk: -${mc_res.var_95_pct:,.2f}")
    print(f"    99% Expected Shortfall(CVaR): -${mc_res.cvar_99_pct:,.2f}")

    return {
        "pair_name": pair_name,
        "cadf": cadf_res,
        "ou": ou_params,
        "kf": kf_res,
        "backtest": btest,
        "perf": perf,
        "walk_forward": wf_res
    }


def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    equity_file = os.path.join(base_dir, "data", "equity_pairs_universe.csv")
    commodity_file = os.path.join(base_dir, "data", "commodity_spreads.csv")

    if not os.path.exists(equity_file) or not os.path.exists(commodity_file):
        print("Data files not found. Please ensure data directory is populated.")
        return

    df_eq = pd.read_csv(equity_file)
    df_com = pd.read_csv(commodity_file)
    dates = df_eq["Date"].tolist()

    print(f"{'#'*75}")
    print(f" QUANTITATIVE PAIRS TRADING & COINTEGRATION ENGINE (2026 BENCHMARK)")
    print(f" Exchange Data: US Equities (NYSE/NASDAQ) & Commodities (CME/NYMEX)")
    print(f"{'#'*75}")

    # Benchmark 1: Banking Pair (JPM vs BAC)
    run_pipeline_for_pair("US Banking", df_eq["BAC"].values, df_eq["JPM"].values, dates, "BAC", "JPM", z_entry=2.0, z_exit=0.0)

    # Benchmark 2: Energy Pair (XOM vs CVX)
    run_pipeline_for_pair("US Integrated Oil", df_eq["CVX"].values, df_eq["XOM"].values, dates, "CVX", "XOM", z_entry=2.0, z_exit=0.0)

    # Benchmark 3: Crude Crack / Spread (WTI vs Brent)
    run_pipeline_for_pair("Crude Benchmark", df_com["BRENT"].values, df_com["WTI"].values, dates, "BRENT", "WTI", z_entry=2.0, z_exit=0.0)

    # Benchmark 4: Precious Metals (Gold vs Silver)
    run_pipeline_for_pair("Precious Metals", df_com["SILVER"].values, df_com["GOLD"].values, dates, "SILVER", "GOLD", z_entry=2.0, z_exit=0.0)

    print(f"\n{'='*75}")
    print(" ALL PAIRS TRADING BENCHMARKS COMPLETED SUCCESSFULLY.")
    print(f"{'='*75}\n")


if __name__ == "__main__":
    main()
