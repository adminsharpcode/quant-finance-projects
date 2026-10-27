"""
Market Impact Models for Algorithmic Execution.

Implements institutional market impact formulations:
- Linear permanent and temporary impact (Almgren and Chriss 2000)
- Square-Root Law of Market Impact (Barra / Bouchaud et al. 2004)
- Transient Market Impact with Exponential Decay Resilience (Obizhaeva and Wang 2013 / Gatheral 2010)
- Cross-Asset Multi-Asset Impact Matrix for correlated portfolio liquidation
"""

from dataclasses import dataclass
from abc import ABC, abstractmethod
from typing import Optional
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

    gamma: Permanent price impact parameter ($/share per share traded).
    eta: Temporary price impact parameter ($/share per unit trading rate).
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
    Non-linear Square-Root Law of Market Impact (Bouchaud et al. 2004, Almgren et al. 2005).

    Temporary impact scales proportionally to the daily volatility and
    the square root of the normalized trading participation rate:
        eta(v) = Y * sigma_daily * (v / (ADV / trading_seconds))^alpha
    where alpha ~ 0.5 (square-root law) or 0.6.
    """
    gamma: float = 1.0e-7
    daily_volatility: float = 0.02
    daily_volume: float = 5_000_000.0
    Y_constant: float = 0.6               # Institutional Kyle/Barra constant
    power_exponent: float = 0.5           # Square-root exponent alpha
    trading_seconds: float = 23400.0      # 6.5 regular trading hours

    def permanent_impact(self, trade_rate: float) -> float:
        return self.gamma * trade_rate

    def temporary_impact(self, trade_rate: float) -> float:
        adv_rate = self.daily_volume / self.trading_seconds
        normalized_rate = max(0.0, trade_rate) / adv_rate
        return float(self.Y_constant * self.daily_volatility * (normalized_rate ** self.power_exponent))


@dataclass
class TransientExponentialImpact:
    """
    Obizhaeva & Wang (2013) / Gatheral (2010) Transient Impact Model.

    Unlike pure temporary impact which dissipates instantly, transient impact
    creates a price displacement that decays exponentially at resilience rate rho:
        G(Delta t) = gamma_0 * exp(-rho * Delta t)

    gamma_0: Initial impact per share traded.
    rho: Order book resilience parameter (rate of liquidity replenishment in 1/sec).
    """
    gamma_0: float = 5.0e-6
    rho: float = 0.05  # Half-life of impact = ln(2)/rho ~ 13.8 seconds

    def kernel(self, delta_t: float) -> float:
        """Value of decay kernel after delta_t seconds."""
        return float(self.gamma_0 * np.exp(-self.rho * max(0.0, delta_t)))

    def cumulative_impact(self, trade_times: np.ndarray, trade_sizes: np.ndarray, target_time: float) -> float:
        """
        Total remaining price displacement at target_time from all past child orders:
        Delta S(t) = sum_{k: t_k <= t} n_k * G(t - t_k)
        """
        mask = trade_times <= target_time
        if not np.any(mask):
            return 0.0
        dt = target_time - trade_times[mask]
        weights = self.gamma_0 * np.exp(-self.rho * dt)
        return float(np.sum(trade_sizes[mask] * weights))


@dataclass
class CrossAssetImpactMatrix:
    """
    Multi-Asset Cross-Impact Model for correlated portfolio liquidation.

    Accounts for cross-asset price pressure when liquidating a basket of assets:
        Delta S_i = sum_j Gamma_ij * v_j
    where Gamma is a positive semi-definite cross-impact matrix.
    """
    gamma_matrix: np.ndarray  # Shape (M, M) permanent impact matrix
    eta_matrix: np.ndarray    # Shape (M, M) temporary impact matrix

    def compute_permanent_impact(self, trade_rates: np.ndarray) -> np.ndarray:
        return self.gamma_matrix @ trade_rates

    def compute_temporary_impact(self, trade_rates: np.ndarray) -> np.ndarray:
        return self.eta_matrix @ trade_rates
