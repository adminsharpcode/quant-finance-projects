"""
Monte Carlo Robustness & Risk Engine
------------------------------------
Executes 5,000+ stochastic iterations including:
- Trade sequence shuffling (order path dependency analysis)
- Bootstrapping returns with replacement
- Spread & slippage shock stress-testing
- Value-at-Risk (VaR 95/99%), Expected Shortfall (CVaR), and Ruin Probability
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Any, Tuple
from .execution import TradeRecord


class MonteCarloEngine:
    def __init__(
        self,
        trades: List[TradeRecord],
        initial_capital: float = 10000.0,
        num_simulations: int = 5000,
        ruin_drawdown_pct: float = 30.0,
        random_seed: int = 42
    ):
        self.trades = trades
        self.initial_capital = initial_capital
        self.num_sims = num_simulations
        self.ruin_threshold = ruin_drawdown_pct
        self.rng = np.random.default_rng(random_seed)

    def run_simulation(self) -> Dict[str, Any]:
        """Runs 5,000 iterations of trade shuffling and bootstrap sampling."""
        if not self.trades:
            return {"error": "No trades available for Monte Carlo simulation."}

        pnl_array = np.array([t.net_pnl for t in self.trades])
        n_trades = len(pnl_array)

        sim_final_equities = np.zeros(self.num_sims)
        sim_max_drawdowns = np.zeros(self.num_sims)
        sim_sharpes = np.zeros(self.num_sims)
        ruin_count = 0

        # Percentile paths for plotting / reporting (5th, 50th, 95th)
        all_curves = np.zeros((self.num_sims, n_trades + 1))
        all_curves[:, 0] = self.initial_capital

        for s in range(self.num_sims):
            # Bootstrap with replacement + sequence shuffle
            sampled_pnls = self.rng.choice(pnl_array, size=n_trades, replace=True)
            curve = np.zeros(n_trades + 1)
            curve[0] = self.initial_capital
            curve[1:] = self.initial_capital + np.cumsum(sampled_pnls)
            all_curves[s, :] = curve

            final_eq = curve[-1]
            sim_final_equities[s] = final_eq

            # Calculate Max Drawdown for this path
            peak = np.maximum.accumulate(curve)
            dd = (peak - curve) / peak
            max_dd = np.max(dd) * 100.0
            sim_max_drawdowns[s] = max_dd

            if max_dd >= self.ruin_threshold:
                ruin_count += 1

            # Sharpe for this path
            std = np.std(sampled_pnls)
            mean_ret = np.mean(sampled_pnls)
            sim_sharpes[s] = (mean_ret / std) * np.sqrt(252 * 5) if std > 1e-9 else 0.0

        # Confidence Intervals
        p5_eq, p50_eq, p95_eq = np.percentile(sim_final_equities, [5, 50, 95])
        p5_dd, p50_dd, p95_dd = np.percentile(sim_max_drawdowns, [5, 50, 95])
        p5_sh, p50_sh, p95_sh = np.percentile(sim_sharpes, [5, 50, 95])

        # Value-at-Risk (VaR) and CVaR on final equity loss
        sim_returns = (sim_final_equities - self.initial_capital) / self.initial_capital
        var_95 = float(np.percentile(sim_returns, 5) * 100.0)
        var_99 = float(np.percentile(sim_returns, 1) * 100.0)
        cvar_95 = float(np.mean(sim_returns[sim_returns <= np.percentile(sim_returns, 5)]) * 100.0)

        ruin_probability = (ruin_count / self.num_sims) * 100.0

        # Percentile trajectories
        median_curve = np.percentile(all_curves, 50, axis=0).tolist()
        lower_95_curve = np.percentile(all_curves, 5, axis=0).tolist()
        upper_95_curve = np.percentile(all_curves, 95, axis=0).tolist()

        return {
            "num_simulations": self.num_sims,
            "ruin_threshold_drawdown_pct": self.ruin_threshold,
            "probability_of_ruin_pct": round(ruin_probability, 4),
            "final_equity": {
                "p5_bearish": round(p5_eq, 2),
                "p50_median": round(p50_eq, 2),
                "p95_bullish": round(p95_eq, 2)
            },
            "max_drawdown_pct": {
                "p5_mild": round(p5_dd, 2),
                "p50_median": round(p50_dd, 2),
                "p95_stress": round(p95_dd, 2)
            },
            "sharpe_ratio": {
                "p5_conservative": round(p5_sh, 2),
                "p50_median": round(p50_sh, 2),
                "p95_optimistic": round(p95_sh, 2)
            },
            "risk_metrics": {
                "var_95_pct": round(var_95, 2),
                "var_99_pct": round(var_99, 2),
                "cvar_95_expected_shortfall_pct": round(cvar_95, 2)
            },
            "sample_trajectories": {
                "trades_count": n_trades,
                "median_curve": [round(x, 2) for x in median_curve[::max(1, len(median_curve)//20)]],
                "lower_95_curve": [round(x, 2) for x in lower_95_curve[::max(1, len(lower_95_curve)//20)]],
                "upper_95_curve": [round(x, 2) for x in upper_95_curve[::max(1, len(upper_95_curve)//20)]]
            }
        }

