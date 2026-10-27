"""
Almgren-Chriss (2000) Optimal Execution Framework.

Calculates the mathematically optimal liquidation trajectory balancing
market impact (temporary + permanent) against inventory price risk.
"""

from dataclasses import dataclass
from typing import List, Tuple
import numpy as np
from .impact import LinearMarketImpact


@dataclass
class ExecutionConfig:
    """Configuration parameters for execution trajectory."""
    total_shares: float          # Total inventory to liquidate (shares X)
    horizon_minutes: float       # Execution duration in minutes (T)
    intervals: int               # Number of trading intervals (N)
    annual_volatility: float     # Asset annual volatility (e.g. 0.30 for 30%)
    initial_price: float         # Starting asset price ($)
    risk_aversion: float         # Risk aversion parameter lambda (>= 0)
    impact: LinearMarketImpact = None

    def __post_init__(self):
        if self.impact is None:
            self.impact = LinearMarketImpact()


class AlmgrenChrissEngine:
    """
    Implements closed-form analytical solutions to the Almgren-Chriss (2000)
    mean-variance optimal execution problem.
    """

    def __init__(self, config: ExecutionConfig):
        self.config = config
        self.T = self.config.horizon_minutes * 60.0  # seconds
        self.N = self.config.intervals
        self.tau = self.T / self.N                   # interval step in seconds
        
        # Volatility converted to $/second: sigma_sec = S0 * (annual_vol / sqrt(252 * 6.5 * 3600))
        trading_seconds_per_year = 252.0 * 6.5 * 3600.0
        self.sigma = self.config.initial_price * (self.config.annual_volatility / np.sqrt(trading_seconds_per_year))

    def compute_kappa(self, risk_aversion: float) -> float:
        """
        Compute urgency parameter kappa.
        kappa * tau = arccosh(1 + 0.5 * (lambda * sigma^2 * tau^2) / eta)
        """
        if risk_aversion <= 1e-12:
            return 0.0  # Linear TWAP limit

        eta = self.config.impact.eta
        tau = self.tau
        sigma = self.sigma
        
        arg = 1.0 + 0.5 * (risk_aversion * (sigma ** 2) * (tau ** 2)) / eta
        # arccosh(y) for y >= 1
        kappa = np.arccosh(max(1.0, arg)) / tau
        return float(kappa)

    def calculate_trajectory(self, risk_aversion: float = None) -> np.ndarray:
        """
        Calculate remaining holdings x_j at time t_j for j = 0, ..., N.
        
        Returns:
            np.ndarray of shape (N + 1,) containing holdings x_j,
            where x_0 = X and x_N = 0.
        """
        if risk_aversion is None:
            risk_aversion = self.config.risk_aversion

        X = self.config.total_shares
        N = self.N
        t = np.linspace(0, self.T, N + 1)

        kappa = self.compute_kappa(risk_aversion)

        # Extreme case 1: risk_aversion -> 0 (Pure TWAP)
        if kappa == 0.0 or np.isnan(kappa):
            return X * (1.0 - t / self.T)

        # Numerical stability check for large kappa * T
        kappa_T = kappa * self.T
        if kappa_T > 700.0:
            # Immediate liquidation limit
            x = np.zeros(N + 1)
            x[0] = X
            return x

        # Closed-form formula: x_j = sinh(kappa * (T - t_j)) / sinh(kappa * T) * X
        sinh_kappa_T = np.sinh(kappa_T)
        if sinh_kappa_T == 0.0:
            return X * (1.0 - t / self.T)

        x = X * np.sinh(kappa * (self.T - t)) / sinh_kappa_T
        x[0] = X
        x[-1] = 0.0
        return np.maximum(0.0, x)

    def compute_trade_sizes(self, trajectory: np.ndarray) -> np.ndarray:
        """Calculate shares traded in each interval: n_k = x_{k-1} - x_k."""
        return trajectory[:-1] - trajectory[1:]

    def expected_cost(self, trajectory: np.ndarray) -> float:
        """
        Expected execution cost (capture vs arrival price):
        E[x] = 0.5 * gamma * X^2 + tau * eta * sum( (n_k / tau)^2 )
        """
        trades = self.compute_trade_sizes(trajectory)
        gamma = self.config.impact.gamma
        eta = self.config.impact.eta
        tau = self.tau
        X = self.config.total_shares

        permanent_cost = 0.5 * gamma * (X ** 2)
        temporary_cost = np.sum(eta * (trades ** 2) / tau)
        return float(permanent_cost + temporary_cost)

    def cost_variance(self, trajectory: np.ndarray) -> float:
        """
        Execution cost variance:
        V[x] = sigma^2 * tau * sum( x_k^2 ) for k = 1..N
        """
        # x_k after trading at step k:
        x_post = trajectory[1:]
        return float((self.sigma ** 2) * self.tau * np.sum(x_post ** 2))

    def generate_efficient_frontier(self, n_points: int = 50) -> List[Tuple[float, float, float]]:
        """
        Generate (risk_aversion, expected_cost, cost_std) triples along the
        Almgren-Chriss efficient execution frontier.
        """
        lambdas = np.logspace(-9, -2, n_points)
        frontier = []
        for lam in lambdas:
            traj = self.calculate_trajectory(lam)
            e_cost = self.expected_cost(traj)
            var_cost = self.cost_variance(traj)
            frontier.append((float(lam), float(e_cost), float(np.sqrt(max(0.0, var_cost)))))
        return frontier
