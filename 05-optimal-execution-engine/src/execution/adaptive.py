"""
Adaptive Real-Time Algorithmic Execution Engine.

Dynamically modulates execution trajectory based on:
1. Bid-ask spread regime (tight vs wide spread)
2. Real-time realized volatility shocks
3. Adverse selection / price drift vs arrival price
"""

from dataclasses import dataclass
from typing import List, Dict, Any, Tuple
import numpy as np
from ..models.almgren_chriss import AlmgrenChrissEngine, ExecutionConfig


@dataclass
class AdaptiveState:
    """State tracking for adaptive execution decisions."""
    step: int
    remaining_shares: float
    current_mid_price: float
    realized_spread: float
    local_volatility: float
    dynamic_urgency_kappa: float
    allocated_slice: float
    is_passive_order: bool


class AdaptiveExecutionStrategy:
    """
    Adaptive Execution Engine adjusting child order sizing and aggressiveness
    in response to order book microstructure feedback.
    """

    def __init__(
        self,
        base_engine: AlmgrenChrissEngine,
        spread_sensitivity: float = 0.5,
        drift_acceleration_threshold: float = 0.01  # 1% adverse drift accelerates execution
    ):
        self.engine = base_engine
        self.spread_sensitivity = spread_sensitivity
        self.drift_threshold = drift_acceleration_threshold
        self.initial_price = self.engine.config.initial_price
        self.total_shares = self.engine.config.total_shares
        self.N = self.engine.N
        self.tau = self.engine.tau

    def execute_adaptive_schedule(
        self,
        simulated_prices: np.ndarray,
        simulated_spreads: np.ndarray
    ) -> Tuple[np.ndarray, List[AdaptiveState]]:
        """
        Dynamically execute across N steps given simulated price and spread paths.
        
        Returns:
            trades: np.ndarray of shape (N,) with child order sizes
            states: List[AdaptiveState] telemetry
        """
        assert len(simulated_prices) >= self.N + 1
        assert len(simulated_spreads) >= self.N

        remaining = float(self.total_shares)
        trades = np.zeros(self.N)
        telemetry: List[AdaptiveState] = []

        base_kappa = self.engine.compute_kappa(self.engine.config.risk_aversion)
        if base_kappa <= 1e-12:
            base_kappa = 0.001

        mean_spread = np.mean(simulated_spreads)

        for k in range(self.N):
            steps_left = self.N - k
            if steps_left == 1:
                # Must liquidate remaining shares in final interval
                trade_size = remaining
                trades[k] = trade_size
                telemetry.append(AdaptiveState(
                    step=k,
                    remaining_shares=0.0,
                    current_mid_price=simulated_prices[k],
                    realized_spread=simulated_spreads[k],
                    local_volatility=self.engine.sigma,
                    dynamic_urgency_kappa=base_kappa,
                    allocated_slice=trade_size,
                    is_passive_order=False
                ))
                break

            current_price = simulated_prices[k]
            spread = simulated_spreads[k]

            # 1. Microstructure spread modifier: if spread is wider than average, slow down
            spread_ratio = spread / max(1e-6, mean_spread)
            spread_factor = 1.0 / (1.0 + self.spread_sensitivity * (spread_ratio - 1.0))
            spread_factor = np.clip(spread_factor, 0.5, 1.5)

            # 2. Adverse drift penalty: if price dropped significantly below arrival price (for sell), accelerate
            price_drift = (self.initial_price - current_price) / self.initial_price
            drift_factor = 1.0 + max(0.0, price_drift / self.drift_threshold)

            # 3. Dynamic urgency modulation
            effective_kappa = base_kappa * drift_factor * spread_factor
            effective_kappa = np.clip(effective_kappa, 1e-6, 0.1)

            # Sub-horizon optimal step size:
            sub_T = steps_left * self.tau
            sinh_full = np.sinh(effective_kappa * sub_T)
            if sinh_full == 0.0 or np.isnan(sinh_full):
                ideal_slice = remaining / steps_left
            else:
                next_x = remaining * np.sinh(effective_kappa * (sub_T - self.tau)) / sinh_full
                ideal_slice = max(0.0, remaining - next_x)

            trade_size = float(np.clip(ideal_slice, 0.0, remaining))
            trades[k] = trade_size
            remaining -= trade_size

            # Mark order type: passive if spread was wide and rate was suppressed
            is_passive = bool(spread_ratio > 1.2)

            telemetry.append(AdaptiveState(
                step=k,
                remaining_shares=remaining,
                current_mid_price=current_price,
                realized_spread=spread,
                local_volatility=self.engine.sigma,
                dynamic_urgency_kappa=effective_kappa,
                allocated_slice=trade_size,
                is_passive_order=is_passive
            ))

        return trades, telemetry
