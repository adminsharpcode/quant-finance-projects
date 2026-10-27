"""
Demonstration Script: Almgren-Chriss Optimal Execution vs TWAP & VWAP.

Runs institutional benchmark analysis across a $15,000,000 block liquidation:
1. Computes Almgren-Chriss optimal trajectories across risk preferences
2. Simulates price impact against empirical market dynamics
3. Prints institutional TCA (Transaction Cost Analysis) attribution
"""

import sys
import os
import numpy as np

# Ensure root is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.models.almgren_chriss import ExecutionConfig, AlmgrenChrissEngine
from src.models.impact import LinearMarketImpact
from src.execution.twap import TWAPStrategy
from src.execution.vwap import VWAPStrategy
from src.execution.simulator import MarketExecutionSimulator
from src.analytics.tca import TransactionCostAnalyzer


def main():
    print("=" * 80)
    print(" Institutional Optimal Execution Engine | Almgren-Chriss (2000)")
    print("=" * 80)

    # 1. Setup Block Order Parameters
    total_shares = 100_000       # 100,000 shares of $150 stock ($15M order)
    initial_price = 150.0
    horizon_minutes = 60.0       # 1 hour liquidation
    intervals = 30               # 2-minute slices
    tau_sec = (horizon_minutes * 60.0) / intervals
    annual_vol = 0.30

    impact = LinearMarketImpact(gamma=2.5e-7, eta=2.5e-6)
    
    config = ExecutionConfig(
        total_shares=total_shares,
        horizon_minutes=horizon_minutes,
        intervals=intervals,
        annual_volatility=annual_vol,
        initial_price=initial_price,
        risk_aversion=1e-6,
        impact=impact
    )
    
    ac_engine = AlmgrenChrissEngine(config)

    # 2. Generate Strategies
    # Risk-averse AC (high urgency)
    ac_urgent_traj = ac_engine.calculate_trajectory(risk_aversion=1e-4)
    ac_urgent_trades = ac_engine.compute_trade_sizes(ac_urgent_traj)

    # Balanced AC (medium risk aversion)
    ac_balanced_traj = ac_engine.calculate_trajectory(risk_aversion=1e-6)
    ac_balanced_trades = ac_engine.compute_trade_sizes(ac_balanced_traj)

    # Pure TWAP (uniform slices)
    twap = TWAPStrategy(total_shares, intervals)
    twap_trades = twap.calculate_trade_sizes()

    # VWAP (intraday U-curve)
    vwap = VWAPStrategy(total_shares, intervals)
    vwap_trades = vwap.calculate_trade_sizes()

    print(f"Order Notional:    ${total_shares * initial_price:,.2f} ({total_shares:,} shares @ ${initial_price:.2f})")
    print(f"Horizon:           {horizon_minutes:.0f} mins across {intervals} intervals (tau = {tau_sec:.0f}s)")
    print(f"Asset Volatility:  {annual_vol * 100:.1f}% annual (sigma_sec = ${ac_engine.sigma:.4f}/s^0.5)")
    print("-" * 80)

    # 3. Simulate Execution
    strategies = [
        ("Almgren-Chriss (Urgent, lambda=1e-4)", ac_urgent_trades, ac_engine.cost_variance(ac_urgent_traj)),
        ("Almgren-Chriss (Balanced, lambda=1e-6)", ac_balanced_trades, ac_engine.cost_variance(ac_balanced_traj)),
        ("TWAP Benchmark (Linear)", twap_trades, ac_engine.cost_variance(twap.calculate_trajectory())),
        ("VWAP Benchmark (U-Curve)", vwap_trades, ac_engine.cost_variance(vwap.calculate_trajectory())),
    ]

    print(f"{'Strategy':<36} | {'Avg Fill':<10} | {'Shortfall ($)':<14} | {'Slippage (bps)':<14} | {'Risk Std ($)':<12}")
    print("-" * 94)

    for name, trades, var in strategies:
        sim = MarketExecutionSimulator(
            initial_price=initial_price,
            tau_seconds=tau_sec,
            sigma_sec=ac_engine.sigma,
            impact=impact,
            seed=1337
        )
        res = sim.run_simulation(trades)
        report = TransactionCostAnalyzer.evaluate(
            strategy_name=name,
            trades=trades,
            effective_prices=res.effective_prices,
            arrival_price=initial_price,
            cost_std=np.sqrt(max(0.0, var))
        )
        print(f"{name:<36} | ${report.average_fill_price:>8.3f} | ${report.implementation_shortfall_usd:>12.2f} | {report.slippage_bps:>12.2f} bps | ${report.volatility_risk_std:>10.2f}")

    print("=" * 94)
    print("Execution completed successfully.")


if __name__ == "__main__":
    main()
