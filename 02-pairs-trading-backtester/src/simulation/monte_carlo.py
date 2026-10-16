"""Monte Carlo Simulation & First Passage Time Engine for Pairs Trading.

Simulates thousands of stochastic Ornstein-Uhlenbeck spread trajectories to compute:
1. Exact First Passage Time (FPT) probability distributions.
2. Probability of Profit (PoP) vs Probability of Stop-Loss.
3. Parametric Value at Risk (VaR 95%, 99%) and Expected Shortfall (CVaR).
4. Bootstrap confidence intervals for Strategy Sharpe Ratio and Maximum Drawdown.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
import numpy as np


@dataclass
class MonteCarloSimulationResult:
    """Comprehensive outputs from Ornstein-Uhlenbeck Monte Carlo simulation."""
    paths: np.ndarray                 # Shape: (num_paths, horizon_steps + 1)
    time_grid: np.ndarray             # Time step array (days)
    percentiles: Dict[str, np.ndarray]# 5th, 25th, 50th (median), 75th, 95th paths
    probability_of_profit: float      # % of paths reaching mean-reversion target before stop
    probability_of_stop_loss: float   # % of paths hitting stop loss first
    probability_of_timeout: float     # % of paths unresolved at end of horizon
    expected_exit_days: float         # Mean trading days until position resolution
    median_exit_days: float           # Median trading days until resolution
    terminal_spread_mean: float       # Expected terminal spread value
    terminal_spread_std: float        # Standard deviation of terminal spread
    var_95_pct: float                 # Value at Risk at 95% confidence
    var_99_pct: float                 # Value at Risk at 99% confidence
    cvar_95_pct: float                # Conditional VaR (Expected Shortfall) at 95%
    cvar_99_pct: float                # Conditional VaR (Expected Shortfall) at 99%
    sharpe_confidence_interval: Tuple[float, float] # 95% bootstrap CI [2.5%, 97.5%]
    mdd_confidence_interval: Tuple[float, float]    # 95% bootstrap CI


class PairsMonteCarloEngine:
    """Stochastic Monte Carlo engine for mean-reverting pairs arbitrage."""

    def __init__(
        self,
        num_paths: int = 5000,
        horizon_days: int = 60,
        dt: float = 1.0,
        random_seed: Optional[int] = 42
    ):
        """Initialize engine parameters.

        Args:
            num_paths: Number of simulated sample paths (e.g. 5,000 to 10,000).
            horizon_days: Forward simulation horizon in trading days.
            dt: Time step size (1.0 for daily).
            random_seed: Seed for pseudo-random number generator repeatability.
        """
        self.num_paths = num_paths
        self.horizon_days = horizon_days
        self.dt = dt
        self.random_seed = random_seed

    def simulate_ou_paths(
        self,
        initial_spread: float,
        theta: float,
        mu: float,
        sigma: float
    ) -> np.ndarray:
        """Simulate discrete Ornstein-Uhlenbeck paths using exact Gaussian transition distribution.

        Exact Solution:
            X_{t+dt} = X_t * e^{-theta*dt} + mu*(1 - e^{-theta*dt}) + sigma_noise * Z
        where sigma_noise = sqrt( (sigma^2 / (2*theta)) * (1 - e^{-2*theta*dt}) ).

        Returns:
            numpy array of shape (num_paths, horizon_days + 1)
        """
        if self.random_seed is not None:
            np.random.seed(self.random_seed)

        theta = max(theta, 1e-5)
        sigma = max(sigma, 1e-5)

        decay = np.exp(-theta * self.dt)
        drift_const = mu * (1.0 - decay)
        var_noise = (sigma ** 2 / (2.0 * theta)) * (1.0 - np.exp(-2.0 * theta * self.dt))
        std_noise = np.sqrt(max(var_noise, 1e-12))

        paths = np.zeros((self.num_paths, self.horizon_days + 1), dtype=float)
        paths[:, 0] = initial_spread

        # Vectorized path propagation across all M paths simultaneously
        for t in range(1, self.horizon_days + 1):
            z = np.random.normal(0.0, 1.0, size=self.num_paths)
            paths[:, t] = paths[:, t - 1] * decay + drift_const + std_noise * z

        return paths

    def run_first_passage_analysis(
        self,
        initial_spread: float,
        theta: float,
        mu: float,
        sigma: float,
        target_reversion_spread: float = 0.0,
        stop_loss_spread: float = 3.5,
        position_direction: int = 1, # +1: Long Spread (entered at depressed spread, expects up)
        historical_returns: Optional[np.ndarray] = None
    ) -> MonteCarloSimulationResult:
        """Execute full Monte Carlo First Passage Time and Risk Analysis.

        Args:
            initial_spread: Spread level at entry.
            theta: Mean-reversion speed.
            mu: Equilibrium mean.
            sigma: Spread diffusion volatility.
            target_reversion_spread: Target spread for take-profit exit.
            stop_loss_spread: Divergence boundary for hard stop-loss.
            position_direction: +1 for Long Spread, -1 for Short Spread.
            historical_returns: Optional historical returns array for bootstrap CI.

        Returns:
            MonteCarloSimulationResult dataclass.
        """
        paths = self.simulate_ou_paths(initial_spread, theta, mu, sigma)
        time_grid = np.arange(self.horizon_days + 1)

        # First Passage Time (FPT) detection
        exit_steps = []
        outcomes = [] # 'TP', 'SL', 'TIMEOUT'

        for i in range(self.num_paths):
            path = paths[i]
            resolved = False

            for step in range(1, self.horizon_days + 1):
                s = path[step]

                if position_direction == 1:
                    # Long Spread: entered below mean. Target is >= target_reversion_spread.
                    if s >= target_reversion_spread:
                        exit_steps.append(step)
                        outcomes.append('TP')
                        resolved = True
                        break
                    elif s <= stop_loss_spread:
                        exit_steps.append(step)
                        outcomes.append('SL')
                        resolved = True
                        break
                else:
                    # Short Spread: entered above mean. Target is <= target_reversion_spread.
                    if s <= target_reversion_spread:
                        exit_steps.append(step)
                        outcomes.append('TP')
                        resolved = True
                        break
                    elif s >= stop_loss_spread:
                        exit_steps.append(step)
                        outcomes.append('SL')
                        resolved = True
                        break

            if not resolved:
                exit_steps.append(self.horizon_days)
                outcomes.append('TIMEOUT')

        total = float(self.num_paths)
        pop = (outcomes.count('TP') / total) * 100.0
        p_stop = (outcomes.count('SL') / total) * 100.0
        p_timeout = (outcomes.count('TIMEOUT') / total) * 100.0

        mean_exit_days = float(np.mean(exit_steps))
        median_exit_days = float(np.median(exit_steps))

        # Terminal Spread Distribution
        terminal_spreads = paths[:, -1]
        terminal_mean = float(np.mean(terminal_spreads))
        terminal_std = float(np.std(terminal_spreads, ddof=1))

        # Compute Parametric Value at Risk (VaR) & CVaR on simulated terminal PnL
        # PnL proportional to position_direction * (terminal - initial)
        simulated_pnl = position_direction * (terminal_spreads - initial_spread)
        simulated_losses = -simulated_pnl # positive values represent losses

        var_95 = float(np.percentile(simulated_losses, 95))
        var_99 = float(np.percentile(simulated_losses, 99))

        tail_95 = simulated_losses[simulated_losses >= var_95]
        cvar_95 = float(np.mean(tail_95)) if len(tail_95) > 0 else var_95

        tail_99 = simulated_losses[simulated_losses >= var_99]
        cvar_99 = float(np.mean(tail_99)) if len(tail_99) > 0 else var_99

        # Bootstrap Confidence Intervals on Historical Performance
        sharpe_ci = (0.0, 0.0)
        mdd_ci = (0.0, 0.0)

        if historical_returns is not None and len(historical_returns) > 30:
            rets = np.asarray(historical_returns, dtype=float)
            n_obs = len(rets)
            boot_sharpes = []
            boot_mdds = []
            rf_daily = 0.04 / 252.0

            for _ in range(1000):
                boot_idx = np.random.choice(n_obs, size=n_obs, replace=True)
                sample = rets[boot_idx]
                s_mean = np.mean(sample) - rf_daily
                s_std = np.std(sample, ddof=1)
                sh = (s_mean * np.sqrt(252.0) / s_std) if s_std > 1e-8 else 0.0
                boot_sharpes.append(sh)

                # MDD on sample
                cum = np.cumprod(1.0 + sample)
                cum_max = np.maximum.accumulate(cum)
                mdd = np.min((cum - cum_max) / cum_max)
                boot_mdds.append(abs(mdd) * 100.0)

            sharpe_ci = (float(np.percentile(boot_sharpes, 2.5)), float(np.percentile(boot_sharpes, 97.5)))
            mdd_ci = (float(np.percentile(boot_mdds, 2.5)), float(np.percentile(boot_mdds, 97.5)))

        percentiles = {
            "5th": np.percentile(paths, 5, axis=0),
            "25th": np.percentile(paths, 25, axis=0),
            "50th": np.percentile(paths, 50, axis=0),
            "75th": np.percentile(paths, 75, axis=0),
            "95th": np.percentile(paths, 95, axis=0)
        }

        return MonteCarloSimulationResult(
            paths=paths,
            time_grid=time_grid,
            percentiles=percentiles,
            probability_of_profit=pop,
            probability_of_stop_loss=p_stop,
            probability_of_timeout=p_timeout,
            expected_exit_days=mean_exit_days,
            median_exit_days=median_exit_days,
            terminal_spread_mean=terminal_mean,
            terminal_spread_std=terminal_std,
            var_95_pct=var_95,
            var_99_pct=var_99,
            cvar_95_pct=cvar_95,
            cvar_99_pct=cvar_99,
            sharpe_confidence_interval=sharpe_ci,
            mdd_confidence_interval=mdd_ci
        )
