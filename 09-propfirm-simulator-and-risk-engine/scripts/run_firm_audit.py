"""
run_firm_audit.py
Audits 22 proprietary trading firms across 5 trader archetypes.
Calculates exact mathematical survival rates, Mathematical Difficulty Index (MDI),
and optimal sizing recommendations for challenge passing.
"""

import os
import sys
import numpy as np
import pandas as pd

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.rules.firm_catalog import PROP_FIRMS
from src.analytics.firm_comparison import (
    TRADER_ARCHETYPES,
    calculate_mathematical_difficulty_index,
    run_cross_firm_benchmark,
)
from src.optimization.sizing_optimizer import PropFirmSizingOptimizer


def run_audit():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    viz_dir = os.path.join(project_root, "visualizations")
    os.makedirs(viz_dir, exist_ok=True)

    print("=" * 90)
    print("PROJECT 09: PROPFIRM MATHEMATICAL SURVIVAL ENGINE & STOCHASTIC AUDIT")
    print("Auditing 22 Leading Global Prop Firms across Multiple Trader Archetypes")
    print("=" * 90)

    # 1. Cross-Firm Benchmark (Disciplined Scalper: 55% Win, 1.3 R:R, 0.5% Risk)
    print("\n[+] Running Monte Carlo Benchmark (1,000 paths per firm)...")
    ranking_df = run_cross_firm_benchmark(num_paths=1000)

    display_cols = [
        "Firm Name", "Market", "Phases", "Target (%)", "Daily DD (%)", "Max DD (%)",
        "DD Type", "MDI Difficulty", "Pass Rate (%)", "Daily Breach (%)", "Avg Days"
    ]
    print("\nTOP 22 PROPFIRMS RANKED BY MATHEMATICAL PASS RATE:")
    print("-" * 90)
    print(ranking_df[display_cols].to_string(index=False))
    print("=" * 90)

    # 2. Archetype Stress Matrix across Benchmark Firms
    print("\n[+] Simulating 5 Trader Archetypes on Benchmark Firms (FTMO, Topstep, Apex, Funding Pips)...")
    benchmark_firms = ["ftmo_standard", "funding_pips_2step", "topstep_combine", "apex_futures", "the5ers_high_stakes"]
    archetype_results = []

    for fid in benchmark_firms:
        firm = PROP_FIRMS[fid]
        row = {"Firm": firm.name}
        for arch_name, profile in TRADER_ARCHETYPES.items():
            from src.models.monte_carlo import PropFirmSimulator
            sim = PropFirmSimulator(firm, profile, seed=42)
            res = sim.simulate(num_paths=1000)
            clean_name = arch_name.split("_", 1)[1]
            row[clean_name] = f"{res.pass_rate_overall * 100.0:.1f}%"
        archetype_results.append(row)

    arch_df = pd.DataFrame(archetype_results)
    print("-" * 90)
    print(arch_df.to_string(index=False))
    print("=" * 90)

    # 3. Optimal Sizing Solutions ('How to Pass Them')
    print("\n[+] MATHEMATICAL SIZING SOLUTIONS: HOW TO PASS THEM SAFELY")
    print("-" * 90)
    key_firms = ["ftmo_standard", "topstep_combine", "apex_futures"]
    for fid in key_firms:
        firm = PROP_FIRMS[fid]
        optimizer = PropFirmSizingOptimizer(firm, win_rate=0.52, reward_to_risk=1.5, trades_per_day=2)
        rec = optimizer.find_optimal_risk(risk_candidates=(0.25, 0.50, 0.75, 1.0, 1.5), num_simulations_per_point=1000)
        print(f"\nFirm: {firm.name}")
        print(f"  Recommended Optimal Risk per Trade (f*) : {rec.optimal_risk_pct:.2f}%")
        print(f"  Maximum Safe Risk Threshold             : {rec.max_safe_risk_pct:.2f}%")
        print(f"  Expected Pass Rate at f*                : {rec.pass_rate_at_optimal:.1f}%")
        print(f"  Daily Drawdown Violation Rate           : {rec.daily_breach_rate_at_optimal * 100:.2f}%")
        print(f"  Expected Days to Completion             : {rec.expected_days_at_optimal:.1f} days")
        print("  Core Survival Rules:")
        for rule in rec.actionable_rules:
            print(f"    • {rule}")

    # Export CSVs
    ranking_df.to_csv(os.path.join(viz_dir, "prop_firm_ranking.csv"), index=False)
    arch_df.to_csv(os.path.join(viz_dir, "archetype_matrix.csv"), index=False)
    print(f"\n[✓] Audit datasets successfully exported to {viz_dir}")


if __name__ == "__main__":
    run_audit()
