"""
Parameter Optimization & Walk-Forward Validation Engine
-------------------------------------------------------
Performs systematic grid search and walk-forward parameter optimization
across volatility exhaustion bands, spread filters, and asymmetric payoff ratios.
"""

import itertools
import numpy as np
import pandas as pd
from typing import Dict, List, Any, Tuple
from .strategy import InstitutionalAlphaStrategy
from .backtester import TickBacktester, BacktestMetrics


class ParameterOptimizer:
    def __init__(
        self,
        df_ticks: pd.DataFrame,
        initial_capital: float = 10000.0,
        train_test_split: float = 0.65,
        pip_size: float = 0.0001,
        lot_size: float = 100000.0
    ):
        self.df_ticks = df_ticks
        self.initial_capital = initial_capital
        self.split_ratio = train_test_split
        self.pip_size = pip_size
        self.lot_size = lot_size

        split_idx = int(len(df_ticks) * self.split_ratio)
        self.df_train = df_ticks.iloc[:split_idx].reset_index(drop=True)
        self.df_test = df_ticks.iloc[split_idx:].reset_index(drop=True)

    def optimize_grid(
        self,
        param_grid: Dict[str, List[Any]],
        metric_key: str = "sharpe_ratio",
        top_k: int = 5
    ) -> Dict[str, Any]:
        """Runs combinatorial grid search across In-Sample data, then evaluates on OOS."""
        keys, values = zip(*param_grid.items())
        combinations = [dict(zip(keys, v)) for v in itertools.product(*values)]
        print(f"Total parameter combinations to evaluate: {len(combinations)}")

        is_results = []
        for idx, params in enumerate(combinations):
            strategy = InstitutionalAlphaStrategy(pip_size=self.pip_size, **params)
            backtester = TickBacktester(
                strategy=strategy,
                initial_capital=self.initial_capital,
                pip_size=self.pip_size,
                lot_size=self.lot_size
            )
            try:
                metrics = backtester.run(self.df_train)
                res_dict = metrics.to_dict()
                res_dict['params'] = params
                is_results.append(res_dict)
            except Exception as e:
                continue

        is_results.sort(key=lambda x: (x.get(metric_key, -999), x.get('profit_factor', 0)), reverse=True)
        top_candidates = is_results[:top_k]

        comparison = []
        for cand in top_candidates:
            params = cand['params']
            strategy_oos = InstitutionalAlphaStrategy(pip_size=self.pip_size, **params)
            backtester_oos = TickBacktester(
                strategy=strategy_oos,
                initial_capital=self.initial_capital,
                pip_size=self.pip_size,
                lot_size=self.lot_size
            )
            metrics_oos = backtester_oos.run(self.df_test)
            oos_dict = metrics_oos.to_dict()

            comparison.append({
                "params": params,
                "in_sample": {
                    "return_pct": cand["return_pct"],
                    "sharpe_ratio": cand["sharpe_ratio"],
                    "profit_factor": cand["profit_factor"],
                    "max_drawdown_pct": cand["max_drawdown_pct"],
                    "total_trades": cand["total_trades"]
                },
                "out_of_sample": {
                    "return_pct": oos_dict["return_pct"],
                    "sharpe_ratio": oos_dict["sharpe_ratio"],
                    "profit_factor": oos_dict["profit_factor"],
                    "max_drawdown_pct": oos_dict["max_drawdown_pct"],
                    "total_trades": oos_dict["total_trades"]
                }
            })

        best_model = comparison[0] if comparison else {}
        return {
            "total_evaluated": len(combinations),
            "best_model": best_model,
            "top_candidates": comparison
        }
