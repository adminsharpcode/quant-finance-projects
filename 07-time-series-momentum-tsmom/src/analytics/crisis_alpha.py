"""
Crisis Alpha evaluation and stress test attribution.
Validates trend-following's convex payout during systemic equity drawdowns.
"""

from typing import Dict, List
import pandas as pd
import numpy as np


# Historical Stress Windows (2000 - 2024)
STRESS_REGIMES = {
    "Dot-Com Crash": ("2000-03-24", "2002-10-09"),
    "2008 Financial Crisis": ("2007-10-09", "2009-03-09"),
    "2011 US Debt Downgrade": ("2011-05-02", "2011-10-04"),
    "2020 COVID Shock": ("2020-02-19", "2020-03-23"),
    "2022 Inflation/Rate Shock": ("2022-01-03", "2022-10-12"),
}


class CrisisAlphaAnalyzer:
    """
    Evaluates strategy performance and convexity during extreme historical equity stress windows.
    """

    def __init__(self, regimes: Dict[str, tuple] = STRESS_REGIMES):
        self.regimes = regimes

    def evaluate_regimes(
        self,
        strategy_returns: pd.Series,
        equity_benchmark_returns: pd.Series,
    ) -> pd.DataFrame:
        """
        Calculates cumulative return of Strategy vs Equity Benchmark across stress windows.
        
        Returns
        -------
        pd.DataFrame
            Stress window summary with Strategy Return, Benchmark Return, and Outperformance.
        """
        records = []
        for name, (start_dt, end_dt) in self.regimes.items():
            strat_window = strategy_returns.loc[start_dt:end_dt]
            bench_window = equity_benchmark_returns.loc[start_dt:end_dt]
            
            if len(strat_window) == 0 or len(bench_window) == 0:
                continue
                
            strat_cum = (1.0 + strat_window).prod() - 1.0
            bench_cum = (1.0 + bench_window).prod() - 1.0
            diff = strat_cum - bench_cum
            
            records.append({
                "Crisis Regime": name,
                "Start Date": start_dt,
                "End Date": end_dt,
                "Trading Days": len(strat_window),
                "Strategy Return (%)": strat_cum * 100.0,
                "Benchmark Return (%)": bench_cum * 100.0,
                "Alpha Spread (%)": diff * 100.0,
            })
            
        return pd.DataFrame(records)

    def compute_regime_betas(
        self,
        strategy_returns: pd.Series,
        equity_returns: pd.Series,
    ) -> Dict[str, float]:
        """
        Computes strategy beta in normal markets vs crash markets (equity return < -1.5% daily).
        """
        common = strategy_returns.index.intersection(equity_returns.index)
        s = strategy_returns.loc[common]
        e = equity_returns.loc[common]
        
        # Overall beta
        cov_all = np.cov(s, e)
        beta_all = cov_all[0, 1] / max(cov_all[1, 1], 1e-8)
        
        # Crash days (ES < -1.5%)
        crash_mask = e < -0.015
        if np.sum(crash_mask) > 10:
            cov_crash = np.cov(s[crash_mask], e[crash_mask])
            beta_crash = cov_crash[0, 1] / max(cov_crash[1, 1], 1e-8)
        else:
            beta_crash = 0.0
            
        # Rally days (ES > +1.5%)
        rally_mask = e > 0.015
        if np.sum(rally_mask) > 10:
            cov_rally = np.cov(s[rally_mask], e[rally_mask])
            beta_rally = cov_rally[0, 1] / max(cov_rally[1, 1], 1e-8)
        else:
            beta_rally = 0.0
            
        return {
            "Overall Beta": float(beta_all),
            "Crash Beta (Down Days)": float(beta_crash),
            "Rally Beta (Up Days)": float(beta_rally),
        }
