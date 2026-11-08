"""
first_passage.py
Analytical closed-form stochastic solutions for First-Passage Time
and Gambler's Ruin with two absorbing barriers under Arithmetic Brownian Motion.
Provides exact theoretical pass rates and expected challenge durations.
"""

from dataclasses import dataclass
from typing import Dict, Tuple
import numpy as np


@dataclass
class AnalyticalResult:
    pass_probability: float
    ruin_probability: float
    drift_parameter_s: float
    expected_steps_overall: float
    expected_steps_given_pass: float


class DoubleBarrierBrownianMotion:
    """
    Solves Gambler's Ruin / First Passage for Brownian Motion:
      dX_t = mu * dt + sigma * dW_t
      Upper barrier: +T (Profit Target)
      Lower barrier: -D (Max Drawdown)
    """

    @staticmethod
    def calculate_pass_probability(
        drift_mu: float,
        vol_sigma: float,
        target_pct: float,
        drawdown_pct: float,
    ) -> AnalyticalResult:
        """
        Calculates theoretical probability of hitting +target before -drawdown.
        
        Parameters
        ----------
        drift_mu : float
            Expected return per trade/period (e.g. p*R - (1-p)).
        vol_sigma : float
            Standard deviation per trade/period.
        target_pct : float
            Profit target as positive decimal (e.g. 0.10 for 10%).
        drawdown_pct : float
            Maximum drawdown as positive decimal (e.g. 0.10 for 10%).
            
        Returns
        -------
        AnalyticalResult
        """
        D = abs(drawdown_pct)
        T = abs(target_pct)
        
        if vol_sigma <= 1e-9:
            # Deterministic case
            if drift_mu > 0:
                return AnalyticalResult(1.0, 0.0, 999.0, T / drift_mu, T / drift_mu)
            else:
                return AnalyticalResult(0.0, 1.0, -999.0, D / abs(drift_mu), 0.0)
                
        # Scale parameter: s = 2 * mu / sigma^2
        s = 2.0 * drift_mu / (vol_sigma ** 2)
        
        if abs(s) < 1e-6:
            # Case 1: Zero drift (Martingale / Fair coin toss)
            p_pass = D / (D + T)
            p_ruin = T / (D + T)
            e_steps = (D * T) / (vol_sigma ** 2)
            e_steps_pass = e_steps
        else:
            # Case 2: Non-zero drift
            # P(Pass) = (1 - exp(-s * D)) / (1 - exp(-s * (D + T)))
            denom = 1.0 - np.exp(-s * (D + T))
            if abs(denom) < 1e-12:
                p_pass = 1.0 if s > 0 else 0.0
            else:
                p_pass = float((1.0 - np.exp(-s * D)) / denom)
                
            p_pass = float(np.clip(p_pass, 0.0, 1.0))
            p_ruin = 1.0 - p_pass
            
            # Expected time to absorption:
            # E[Tau] = [T * P(Pass) - D * (1 - P(Pass))] / mu
            e_steps = (T * p_pass - D * p_ruin) / drift_mu if abs(drift_mu) > 1e-9 else (D * T) / (vol_sigma ** 2)
            e_steps_pass = e_steps  # Approximation for conditioned path
            
        return AnalyticalResult(
            pass_probability=p_pass,
            ruin_probability=p_ruin,
            drift_parameter_s=s,
            expected_steps_overall=max(0.0, e_steps),
            expected_steps_given_pass=max(0.0, e_steps_pass),
        )

    @classmethod
    def calculate_multiphase_survival(
        cls,
        drift_mu: float,
        vol_sigma: float,
        targets: list,
        drawdowns: list,
    ) -> float:
        """
        Calculates joint probability of passing all challenge phases sequentially.
        """
        overall_pass_prob = 1.0
        for t, d in zip(targets, drawdowns):
            res = cls.calculate_pass_probability(drift_mu, vol_sigma, t, d)
            overall_pass_prob *= res.pass_probability
        return overall_pass_prob
