"""
Institutional Microstructure Stress Testing Engine
---------------------------------------------------
Stress-tests algorithmic trading strategies against institutional liquidity shocks,
execution latency bottlenecks, and flash-crash jump events:

1. Liquidity Shock Engine:
   - Spread expansion: 1.0x, 2.0x, 3.0x, 5.0x, 10.0x baseline spreads.
2. Microstructure Latency Engine:
   - Execution lag: 0ms, 50ms, 150ms, 500ms queue delays with adverse price drift.
3. Jump-Diffusion / Flash Crash Gap Engine:
   - Poisson jump shocks past stop levels.
4. Institutional Fragility Index:
   - Quantifies alpha degradation rate under adverse execution environments.
"""

import math
import numpy as np
import pandas as pd
from typing import Dict, List, Any, Optional, Tuple, Callable


class MicrostructureStressTester:
    """
    Simulates severe institutional microstructure dislocations on tick execution.
    """
    def __init__(
        self,
        base_slippage_pips: float = 0.1,
        pip_size: float = 0.0001,
        commission_per_lot: float = 5.0,
        lot_size: float = 100000.0,
        initial_capital: float = 10000.0
    ):
        self.base_slippage_pips = base_slippage_pips
        self.pip_size = pip_size
        self.commission_per_lot = commission_per_lot
        self.lot_size = lot_size
        self.initial_capital = initial_capital

    def apply_spread_shock(self, df_ticks: pd.DataFrame, spread_multiplier: float) -> pd.DataFrame:
        """
        Expands the bid-ask spread by spread_multiplier while preserving mid price.
        """
        df = df_ticks.copy()
        half_new_spread = (df['spread'] * spread_multiplier) / 2.0
        df['ask'] = df['mid'] + half_new_spread
        df['bid'] = df['mid'] - half_new_spread
        df['spread'] = df['ask'] - df['bid']
        return df

    def apply_latency_shock(self, df_ticks: pd.DataFrame, latency_ticks: int = 2) -> pd.DataFrame:
        """
        Shifts execution fills forward by latency_ticks to simulate queue latency.
        """
        df = df_ticks.copy()
        if latency_ticks > 0:
            # Entry ask price drifts adversely
            df['ask'] = df['ask'].shift(-latency_ticks).bfill()
            df['bid'] = df['bid'].shift(-latency_ticks).bfill()
        return df

    def apply_flash_crash_jumps(
        self,
        df_ticks: pd.DataFrame,
        n_jumps: int = 3,
        jump_pips: float = 25.0,
        random_seed: int = 42
    ) -> pd.DataFrame:
        """
        Injects Poisson jump shocks simulating black-swan price gaps.
        """
        np.random.seed(random_seed)
        df = df_ticks.copy()
        n = len(df)
        if n < 100:
            return df
            
        jump_indices = np.random.choice(np.arange(50, n - 50), size=min(n_jumps, n // 50), replace=False)
        for idx in jump_indices:
            direction = -1.0 if np.random.rand() > 0.4 else 1.0
            shock = direction * (jump_pips * self.pip_size)
            df.loc[idx:, 'mid'] += shock
            df.loc[idx:, 'bid'] += shock
            df.loc[idx:, 'ask'] += shock
            
        return df

    def run_stress_suite(
        self,
        df_ticks: pd.DataFrame,
        eval_fn: Callable[[pd.DataFrame], Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Executes complete multi-regime stress test matrix:
        1. Baseline Execution (1.0x Spread, 0ms Latency)
        2. Spread Shock 2.0x (Mild Illiquidity)
        3. Spread Shock 3.0x (Major News / Event Risk)
        4. Spread Shock 5.0x (Severe Liquidity Dry-Up)
        5. Latency Shock 50ms (~1-2 ticks)
        6. Latency Shock 250ms (~5 ticks)
        7. Flash Crash Jump Scenario (25 pip gap)
        """
        # 1. Baseline
        base_res = eval_fn(df_ticks)
        base_sr = float(base_res.get('sharpe_ratio', 0.0))
        base_ret = float(base_res.get('return_pct', 0.0))
        base_dd = float(base_res.get('max_drawdown_pct', 0.0))

        # 2. Spread Shocks
        spread_results = {}
        for mult in [1.5, 2.0, 3.0, 5.0]:
            df_shock = self.apply_spread_shock(df_ticks, mult)
            res = eval_fn(df_shock)
            spread_results[f"{mult}x_spread"] = {
                "multiplier": mult,
                "sharpe_ratio": round(float(res.get('sharpe_ratio', 0.0)), 2),
                "return_pct": round(float(res.get('return_pct', 0.0)), 2),
                "max_drawdown_pct": round(float(res.get('max_drawdown_pct', 0.0)), 2),
                "profit_factor": round(float(res.get('profit_factor', 0.0)), 2),
                "trades": res.get('total_trades', 0)
            }

        # 3. Latency Shocks
        latency_results = {}
        for lat_ticks, label in [(1, "50ms_latency"), (3, "150ms_latency"), (6, "300ms_latency")]:
            df_lat = self.apply_latency_shock(df_ticks, lat_ticks)
            res = eval_fn(df_lat)
            latency_results[label] = {
                "lag_ticks": lat_ticks,
                "sharpe_ratio": round(float(res.get('sharpe_ratio', 0.0)), 2),
                "return_pct": round(float(res.get('return_pct', 0.0)), 2),
                "max_drawdown_pct": round(float(res.get('max_drawdown_pct', 0.0)), 2),
                "trades": res.get('total_trades', 0)
            }

        # 4. Flash Crash Jump
        df_flash = self.apply_flash_crash_jumps(df_ticks, n_jumps=2, jump_pips=20.0)
        flash_res = eval_fn(df_flash)

        # 5. Fragility Index Calculation
        # How much does Sharpe drop at 3x spread?
        sr_3x = spread_results["3.0x_spread"]["sharpe_ratio"]
        if base_sr > 0.1:
            retention = max(0.0, sr_3x / base_sr)
            fragility = (1.0 - retention) * 100.0
        else:
            fragility = 100.0

        if fragility < 40.0 and sr_3x > 0.5:
            verdict = "INSTITUTIONALLY_RESILIENT"
        elif fragility < 75.0 and spread_results["2.0x_spread"]["sharpe_ratio"] > 0:
            verdict = "MODERATELY_VULNERABLE_TO_SHOCKS"
        else:
            verdict = "HIGHLY_FRAGILE_RETAIL_CURVEFIT"

        return {
            "baseline": {
                "sharpe_ratio": round(base_sr, 2),
                "return_pct": round(base_ret, 2),
                "max_drawdown_pct": round(base_dd, 2)
            },
            "spread_stress": spread_results,
            "latency_stress": latency_results,
            "flash_crash_stress": {
                "sharpe_ratio": round(float(flash_res.get('sharpe_ratio', 0.0)), 2),
                "return_pct": round(float(flash_res.get('return_pct', 0.0)), 2),
                "max_drawdown_pct": round(float(flash_res.get('max_drawdown_pct', 0.0)), 2)
            },
            "fragility_score_pct": round(fragility, 1),
            "stress_resilience_verdict": verdict
        }
