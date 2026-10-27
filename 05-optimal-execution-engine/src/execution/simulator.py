"""
Stochastic Market Execution Simulator.

Simulates discrete order execution against stochastic price paths, applying
permanent price impact, temporary execution penalty, and random Brownian noise.
"""

from dataclasses import dataclass
from typing import Dict, Any
import numpy as np
from ..models.impact import BaseMarketImpact, LinearMarketImpact


@dataclass
class SimulationResult:
    """Execution metrics from a simulated liquidation run."""
    arrival_price: float
    average_executed_price: float
    implementation_shortfall_usd: float
    implementation_shortfall_bps: float
    market_impact_cost: float
    unaffected_final_price: float
    realized_final_price: float
    executed_cash: float
    price_trajectory: np.ndarray
    effective_prices: np.ndarray
    trades: np.ndarray


class MarketExecutionSimulator:
    """Simulates child order fills across discrete intervals."""

    def __init__(
        self,
        initial_price: float,
        tau_seconds: float,
        sigma_sec: float,
        impact: BaseMarketImpact = None,
        seed: int = 42
    ):
        self.initial_price = initial_price
        self.tau = tau_seconds
        self.sigma = sigma_sec
        self.impact = impact if impact is not None else LinearMarketImpact()
        self.rng = np.random.default_rng(seed)

    def run_simulation(self, trades: np.ndarray) -> SimulationResult:
        """
        Execute trade sequence:
        trades[k]: shares liquidated during interval k.
        """
        N = len(trades)
        total_shares = np.sum(trades)
        
        # Tracking arrays
        S = np.zeros(N + 1)            # Mid-price before impact
        S_exec = np.zeros(N)           # Execution price obtained for slice k
        S[0] = self.initial_price

        total_cash = 0.0
        total_impact_cost = 0.0

        for k in range(N):
            n_k = trades[k]
            v_k = n_k / self.tau  # trading rate (shares/sec)

            # 1. Temporary impact penalty
            temp_penalty = self.impact.temporary_impact(v_k)

            # 2. Execution price for slice k (Arrival - temporary impact)
            S_exec[k] = S[k] - temp_penalty
            total_cash += n_k * S_exec[k]
            total_impact_cost += n_k * temp_penalty

            # 3. Permanent impact drops mid-price for subsequent steps
            perm_drop = self.impact.permanent_impact(v_k) * self.tau

            # 4. Brownian motion step
            dW = self.rng.normal(0.0, np.sqrt(self.tau))
            vol_step = self.sigma * dW

            S[k + 1] = max(0.01, S[k] - perm_drop + vol_step)

        avg_price = total_cash / total_shares if total_shares > 0 else self.initial_price
        ideal_cash = total_shares * self.initial_price
        is_usd = ideal_cash - total_cash
        is_bps = (is_usd / ideal_cash) * 10_000.0 if ideal_cash > 0 else 0.0

        return SimulationResult(
            arrival_price=self.initial_price,
            average_executed_price=avg_price,
            implementation_shortfall_usd=is_usd,
            implementation_shortfall_bps=is_bps,
            market_impact_cost=total_impact_cost,
            unaffected_final_price=S[0],
            realized_final_price=S[-1],
            executed_cash=total_cash,
            price_trajectory=S,
            effective_prices=S_exec,
            trades=trades
        )
