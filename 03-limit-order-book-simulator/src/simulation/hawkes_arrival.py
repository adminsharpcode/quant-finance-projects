"""
Mutually Exciting Hawkes Process Simulation for Order Flow Clustering.
Simulates endogenous market order avalanches via Ogata's thinning method.
"""

from __future__ import annotations
import math
import random
from typing import List, Tuple
import numpy as np


class HawkesProcessSimulator:
    """
    1D Hawkes self-exciting point process:
    lambda(t) = mu + sum_{t_i < t} alpha * exp(-beta * (t - t_i))
    Branching ratio eta = alpha / beta < 1 ensures stationarity.
    """

    def __init__(
        self,
        mu: float = 2.0,      # Baseline arrival intensity (events / sec)
        alpha: float = 4.0,   # Excitation jump size
        beta: float = 6.0,    # Exponential decay rate
    ):
        self.mu = max(1e-4, mu)
        self.alpha = max(0.0, alpha)
        self.beta = max(1e-4, beta)
        # Check subcritical stability condition
        self.branching_ratio = self.alpha / self.beta
        if self.branching_ratio >= 1.0:
            # Re-scale to ensure stable process without explosion
            self.alpha = 0.85 * self.beta
            self.branching_ratio = 0.85

    def intensity(self, t: float, history: List[float]) -> float:
        """Evaluates lambda(t) given prior event timestamps."""
        val = self.mu
        for ti in history:
            if ti >= t:
                break
            val += self.alpha * math.exp(-self.beta * (t - ti))
        return val

    def simulate(self, horizon: float = 60.0) -> List[float]:
        """
        Simulates arrival timestamps over [0, horizon] using Lewis-Shedler / Ogata thinning.
        """
        timestamps: List[float] = []
        t = 0.0
        lambda_bar = self.mu

        while t < horizon:
            # Generate homogeneous candidate step
            u1 = max(1e-12, random.random())
            w = -math.log(u1) / lambda_bar
            t += w
            if t > horizon:
                break

            # Evaluate intensity at candidate t
            lam_t = self.intensity(t, timestamps)
            u2 = random.random()

            # Accept with probability lam_t / lambda_bar
            if u2 <= (lam_t / lambda_bar):
                timestamps.append(round(t, 6))
                lambda_bar = lam_t + self.alpha
            else:
                lambda_bar = lam_t

        return timestamps
