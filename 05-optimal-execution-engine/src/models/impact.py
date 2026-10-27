"""
Market Impact Models for Algorithmic Execution.

Implements standard institutional market impact formulations:
- Linear permanent and temporary impact (Almgren-Chriss 2000)
- Non-linear Square-Root Law of Market Impact (Barra / Bouchaud et al.)
"""

from dataclasses import dataclass
from abc import ABC, abstractmethod
import numpy as np


class BaseMarketImpact(ABC):
    """Abstract base class for market impact models."""

    @abstractmethod
    def permanent_impact(self, trade_rate: float) -> float:
        """Calculate permanent price shift per unit time."""
        pass

    @abstractmethod
    def temporary_impact(self, trade_rate: float) -> float:
        """Calculate temporary price deviation during execution."""
        pass


@dataclass
class LinearMarketImpact(BaseMarketImpact):
    """
    Standard linear impact model from Almgren and Chriss (2000).

    gamma: Permanent impact parameter ($/share per share traded).
    eta: Temporary impact parameter ($/share per unit trading rate).
    """
    gamma: float = 2.5e-7
    eta: float = 2.5e-6

    def permanent_impact(self, trade_rate: float) -> float:
        return self.gamma * trade_rate

    def temporary_impact(self, trade_rate: float) -> float:
        return self.eta * trade_rate


@dataclass
class SquareRootMarketImpact(BaseMarketImpact):
    """
    Square-root law of market impact (Bouchaud, Farmer, Lillo 2004).

    Temporary impact scales proportionally to the daily volatility and
    the square root of the participation rate:
        eta(v) = Y * sigma * sqrt(v / ADV)
    """
    gamma: float = 1.0e-7
    daily_volatility: float = 0.02
    daily_volume: float = 5_000_000.0
    Y_constant: float = 0.5  # Institutional Kyle/Barra constant ~ 0.5 - 0.7

    def permanent_impact(self, trade_rate: float) -> float:
        return self.gamma * trade_rate

    def temporary_impact(self, trade_rate: float) -> float:
        participation = max(0.0, trade_rate / (self.daily_volume / 23400.0))  # 6.5 trading hours in seconds
        return self.Y_constant * self.daily_volatility * np.sqrt(participation)
