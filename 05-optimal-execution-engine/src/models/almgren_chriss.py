"""
Almgren-Chriss (2000) & Advanced Quantitative Execution Frameworks.

Implements institutional liquidation models:
1. Analytical Closed-Form Almgren-Chriss (2000)
2. Non-Linear Power-Law / Square-Root Dynamic Optimization (SLSQP)
3. Obizhaeva & Wang (2013) Transient Impact & Book Resilience Engine
4. Multi-Asset Portfolio Liquidation with Covariance & Cross-Impact Matrix
"""

from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict, Any
import numpy as np
from scipy.optimize import minimize
from .impact import (
    BaseMarketImpact,
    LinearMarketImpact,
    SquareRootMarketImpact,
    TransientExponentialImpact,
    CrossAssetImpactMatrix
)


@dataclass
class ExecutionConfig:
    """Configuration parameters for single-asset execution trajectory."""
    total_shares: float          # Total inventory to liquidate (shares X)
    horizon_minutes: float       # Execution duration in minutes (T)
    intervals: int               # Number of trading intervals (N)
    annual_volatility: float     # Asset annual volatility (e.g. 0.30 for 30%)
    initial_price: float         # Starting asset price ($)
    risk_aversion: float = 1e-6  # Risk aversion parameter lambda (>= 0)
    impact: LinearMarketImpact = field(default_factory=LinearMarketImpact)

    def __post_init__(self):
        if self.impact is None:
            self.impact = LinearMarketImpact()


class AlmgrenChrissEngine:
    """
    Institutional engine for Almgren-Chriss (2000) and nonlinear dynamic optimization.
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
        
        arg = 1.0 + 0.5 * (risk_aversion * (sigma ** 2) * (tau ** 2)) / max(1e-12, eta)
        kappa = np.arccosh(max(1.0, arg)) / tau
        return float(kappa)

    def calculate_trajectory(self, risk_aversion: Optional[float] = None) -> np.ndarray:
        """
        Calculate analytical closed-form holdings x_j at time t_j for j = 0, ..., N.
        
        x_j = sinh(kappa * (T - t_j)) / sinh(kappa * T) * X
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

        kappa_T = kappa * self.T
        if kappa_T > 700.0:
            # Immediate liquidation limit
            x = np.zeros(N + 1)
            x[0] = X
            return x

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
        Expected capture cost relative to arrival price:
        E[x] = 0.5 * gamma * X^2 + tau * sum( eta * (n_k / tau)^2 )
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
        x_post = trajectory[1:]
        return float((self.sigma ** 2) * self.tau * np.sum(x_post ** 2))

    def calculate_nonlinear_trajectory(
        self,
        sq_impact: SquareRootMarketImpact,
        risk_aversion: Optional[float] = None
    ) -> np.ndarray:
        """
        Solve optimal execution under non-linear square-root market impact:
            min_{n_k} sum_k [ n_k * eta(n_k/tau) ] + 0.5 * gamma * X^2 + lambda * sigma^2 * tau * sum_k x_k^2
        subject to:
            sum_k n_k = X,  n_k >= 0.
        """
        if risk_aversion is None:
            risk_aversion = self.config.risk_aversion

        X = self.config.total_shares
        N = self.N
        tau = self.tau
        sigma = self.sigma

        # Initial guess: uniform TWAP slices
        n0 = np.full(N, X / N)

        def objective(n):
            # Holdings after each trade: x_k = X - sum_{i=0}^{k-1} n_i
            x_post = X - np.cumsum(n)
            # Market impact cost
            v = np.maximum(0.0, n) / tau
            temp_penalties = np.array([sq_impact.temporary_impact(vk) for vk in v])
            impact_cost = np.sum(n * temp_penalties)
            perm_cost = 0.5 * sq_impact.gamma * (X ** 2)
            # Variance
            variance = (sigma ** 2) * tau * np.sum(x_post ** 2)
            return (impact_cost + perm_cost) + risk_aversion * variance

        constraints = [{'type': 'eq', 'fun': lambda n: np.sum(n) - X}]
        bounds = [(0.0, X) for _ in range(N)]

        res = minimize(
            objective,
            n0,
            method='SLSQP',
            bounds=bounds,
            constraints=constraints,
            options={'maxiter': 200, 'ftol': 1e-7}
        )

        n_opt = res.x if res.success else n0
        # Reconstruct holdings trajectory
        traj = np.zeros(N + 1)
        traj[0] = X
        traj[1:] = np.maximum(0.0, X - np.cumsum(n_opt))
        traj[-1] = 0.0
        return traj

    def calculate_obizhaeva_wang_trajectory(
        self,
        transient_impact: TransientExponentialImpact
    ) -> np.ndarray:
        """
        Analytical optimal trajectory under Obizhaeva & Wang (2013) transient impact
        with exponential order book resilience: G(Delta t) = gamma_0 * exp(-rho * Delta t).
        
        The optimal policy features:
        1. An initial discrete block trade at t = 0: n_0 = X / (2 + rho * T)
        2. A constant continuous liquidation rate: nu = (rho * X) / (2 + rho * T)
        3. A final discrete block trade at t = T: n_N = X / (2 + rho * T)
        """
        X = self.config.total_shares
        T = self.T
        N = self.N
        rho = transient_impact.rho

        denom = 2.0 + rho * T
        n_initial = X / denom
        n_final = X / denom
        continuous_rate = (rho * X) / denom  # shares / sec

        t = np.linspace(0, T, N + 1)
        holdings = np.zeros(N + 1)
        holdings[0] = X

        # Immediately after initial trade at t=0
        for i in range(1, N):
            time_elapsed = t[i]
            holdings[i] = max(0.0, (X - n_initial) - continuous_rate * time_elapsed)

        holdings[-1] = 0.0  # Final block trade liquidates remainder
        return holdings

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


class MultiAssetExecutionEngine:
    """
    Coordinated multi-asset portfolio liquidation under cross-asset covariance
    and cross-impact matrix (Lehalle & Neuman 2019, Schied et al.).
    
    Objective:
        min_{X(t)} integral_0^T [ x'(t) Sigma x(t) * lambda + v'(t) Eta v(t) ] dt
    """

    def __init__(
        self,
        initial_holdings: np.ndarray,      # Vector of initial share quantities X in R^M
        prices: np.ndarray,                # Initial prices in R^M
        covariance_matrix: np.ndarray,     # Covariance matrix Sigma in R^{M x M} ($^2 / s)
        cross_impact: CrossAssetImpactMatrix,
        horizon_seconds: float,
        intervals: int,
        risk_aversion: float = 1e-6
    ):
        self.X0 = np.asarray(initial_holdings, dtype=float)
        self.prices = np.asarray(prices, dtype=float)
        self.Sigma = np.asarray(covariance_matrix, dtype=float)
        self.impact = cross_impact
        self.T = horizon_seconds
        self.N = intervals
        self.tau = self.T / self.N
        self.risk_aversion = risk_aversion
        self.M = len(self.X0)

    def calculate_multi_asset_trajectories(self) -> np.ndarray:
        """
        Compute simultaneous liquidation paths for M assets across N+1 time steps.
        
        Returns:
            np.ndarray of shape (M, N + 1) containing holdings of each asset over time.
        """
        M = self.M
        N = self.N
        tau = self.tau
        X0 = self.X0
        Sigma = self.Sigma
        Eta = self.impact.eta_matrix
        lam = self.risk_aversion

        # Initial uniform TWAP guess for all assets: shape (M, N) trades
        trades_init = np.outer(X0, np.full(N, 1.0 / N)).flatten()

        def objective(trades_flat):
            # Reshape to (M, N)
            trades = trades_flat.reshape(M, N)
            # Rates: v_k in R^{M x N}
            v = trades / tau
            
            # Temporary impact cost: sum_k v_k' Eta v_k * tau
            impact_cost = 0.0
            for k in range(N):
                vk = v[:, k]
                impact_cost += (vk.T @ Eta @ vk) * tau
            
            # Inventory risk: lambda * tau * sum_k x_k' Sigma x_k
            holdings_post = X0[:, np.newaxis] - np.cumsum(trades, axis=1)
            var_cost = 0.0
            for k in range(N):
                xk = holdings_post[:, k]
                var_cost += (xk.T @ Sigma @ xk) * tau

            return impact_cost + lam * var_cost

        # Constraints: for each asset i, sum_{k=0}^{N-1} trades[i, k] = X0[i]
        constraints = []
        for i in range(M):
            constraints.append({
                'type': 'eq',
                'fun': lambda tf, idx=i: np.sum(tf.reshape(M, N)[idx, :]) - X0[idx]
            })

        bounds = [(0.0, None) for _ in range(M * N)]

        res = minimize(
            objective,
            trades_init,
            method='SLSQP',
            bounds=bounds,
            constraints=constraints,
            options={'maxiter': 250, 'ftol': 1e-6}
        )

        opt_trades = res.x.reshape(M, N) if res.success else trades_init.reshape(M, N)
        trajectories = np.zeros((M, N + 1))
        trajectories[:, 0] = X0
        for i in range(M):
            trajectories[i, 1:] = np.maximum(0.0, X0[i] - np.cumsum(opt_trades[i, :]))
            trajectories[i, -1] = 0.0

        return trajectories
