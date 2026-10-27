"""
Transaction Cost Analysis (TCA) and Execution Benchmarking.

Provides institutional decomposition of execution quality:
- Implementation Shortfall (Perold 1988)
- Permanent vs Temporary Impact Attribution
- Basis Points (bps) Slippage vs Arrival Price
"""

from dataclasses import dataclass
from typing import Dict, List
import numpy as np


@dataclass
class TCAReport:
    """Institutional execution cost summary."""
    strategy_name: str
    total_shares: float
    arrival_price: float
    average_fill_price: float
    implementation_shortfall_usd: float
    slippage_bps: float
    total_impact_cost: float
    volatility_risk_std: float


class TransactionCostAnalyzer:
    """Computes comparative TCA across multiple execution strategies."""

    @staticmethod
    def evaluate(
        strategy_name: str,
        trades: np.ndarray,
        effective_prices: np.ndarray,
        arrival_price: float,
        cost_std: float = 0.0
    ) -> TCAReport:
        total_shares = float(np.sum(trades))
        total_cash = float(np.sum(trades * effective_prices))
        avg_fill = total_cash / total_shares if total_shares > 0 else arrival_price
        
        ideal_cash = total_shares * arrival_price
        shortfall_usd = ideal_cash - total_cash
        slippage_bps = (shortfall_usd / ideal_cash) * 10_000.0 if ideal_cash > 0 else 0.0
        
        # Approximate impact cost as deviation from arrival
        impact_cost = np.sum(trades * np.maximum(0.0, arrival_price - effective_prices))

        return TCAReport(
            strategy_name=strategy_name,
            total_shares=total_shares,
            arrival_price=arrival_price,
            average_fill_price=avg_fill,
            implementation_shortfall_usd=shortfall_usd,
            slippage_bps=slippage_bps,
            total_impact_cost=impact_cost,
            volatility_risk_std=cost_std
        )
