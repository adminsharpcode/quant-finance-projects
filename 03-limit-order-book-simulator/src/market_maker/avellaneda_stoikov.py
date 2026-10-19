"""
Avellaneda-Stoikov (2008) Optimal Market Making Model.
Closed-form reservation price and inventory-skewed quoting calculations.
"""

from __future__ import annotations
import math
from typing import Tuple, Optional


class AvellanedaStoikovModel:
    """
    Implements the Avellaneda & Stoikov (2008) optimal market-making framework.
    Reference: Avellaneda, M., & Stoikov, S. (2008). High-frequency trading in a limit order book.
    Quantitative Finance, 8(3), 217-224.
    """

    def __init__(
        self,
        gamma: float = 0.1,        # Risk aversion parameter
        sigma: float = 0.05,       # Mid-price asset volatility (in $/sec or $/min)
        T: float = 60.0,           # Trading session horizon (seconds)
        kappa: float = 1.5,        # Order book liquidity intensity parameter
        A: float = 140.0,          # Base Poisson arrival intensity
        q_max: int = 10,           # Hard inventory capacity limit
        tick_size: float = 0.25,   # Minimum price increment
    ):
        self.gamma = max(1e-5, gamma)
        self.sigma = max(1e-5, sigma)
        self.T = max(1.0, T)
        self.kappa = max(1e-5, kappa)
        self.A = max(1e-5, A)
        self.q_max = abs(q_max)
        self.tick_size = tick_size

    def reservation_price(self, mid_price: float, inventory: int, t_remaining: Optional[float] = None) -> float:
        """
        Calculates the agent's indifference (reservation) price r(s, q, t):
        r(s, q, t) = s - q * gamma * sigma^2 * (T - t)
        """
        t_rem = self.T if t_remaining is None else max(0.0, t_remaining)
        return mid_price - (inventory * self.gamma * (self.sigma ** 2) * t_rem)

    def optimal_spread(self, t_remaining: Optional[float] = None) -> float:
        """
        Calculates the total optimal bid-ask spread:
        s*(t) = gamma * sigma^2 * (T - t) + (2 / gamma) * ln(1 + gamma / kappa)
        """
        t_rem = self.T if t_remaining is None else max(0.0, t_remaining)
        term1 = self.gamma * (self.sigma ** 2) * t_rem
        term2 = (2.0 / self.gamma) * math.log(1.0 + (self.gamma / self.kappa))
        return term1 + term2

    def optimal_quotes(
        self,
        mid_price: float,
        inventory: int,
        t_remaining: Optional[float] = None,
        round_to_tick: bool = True
    ) -> Tuple[Optional[float], Optional[float]]:
        """
        Computes the optimal (bid, ask) quotes:
        p^b = r(s, q, t) - spread / 2
        p^a = r(s, q, t) + spread / 2

        Applies inventory capacity boundaries [-q_max, q_max].
        """
        t_rem = self.T if t_remaining is None else max(0.0, t_remaining)
        r = self.reservation_price(mid_price, inventory, t_rem)
        spread = self.optimal_spread(t_rem)
        half_spread = spread / 2.0

        bid = r - half_spread
        ask = r + half_spread

        # Enforce that bid is strictly below ask
        if bid >= ask:
            bid = mid_price - self.tick_size
            ask = mid_price + self.tick_size

        if round_to_tick:
            bid = round(math.floor(bid / self.tick_size) * self.tick_size, 4)
            ask = round(math.ceil(ask / self.tick_size) * self.tick_size, 4)
            if bid >= ask:
                ask = round(bid + self.tick_size, 4)

        # Inventory capacity restrictions
        # If at max long inventory (+q_max), stop buying (pull bid)
        opt_bid: Optional[float] = bid if inventory < self.q_max else None
        # If at max short inventory (-q_max), stop selling (pull ask)
        opt_ask: Optional[float] = ask if inventory > -self.q_max else None

        return opt_bid, opt_ask

    def stationary_quotes(
        self,
        mid_price: float,
        inventory: int,
        round_to_tick: bool = True
    ) -> Tuple[Optional[float], Optional[float]]:
        """
        Infinite-horizon stationary approximation by Guéant, Tapia, & Manziadi (2012).
        Provides stable quotes independent of remaining session time.
        """
        c1 = (1.0 / self.gamma) * math.log(1.0 + (self.gamma / self.kappa))
        c2 = (self.gamma * (self.sigma ** 2)) / (2.0 * self.kappa * self.sigma * math.sqrt(1.0 + (self.gamma / self.kappa)))

        delta_ask = c1 + (2 * inventory + 1) * c2
        delta_bid = c1 - (2 * inventory - 1) * c2

        ask = mid_price + max(self.tick_size, delta_ask)
        bid = mid_price - max(self.tick_size, delta_bid)

        if round_to_tick:
            bid = round(math.floor(bid / self.tick_size) * self.tick_size, 4)
            ask = round(math.ceil(ask / self.tick_size) * self.tick_size, 4)
            if bid >= ask:
                ask = round(bid + self.tick_size, 4)

        opt_bid = bid if inventory < self.q_max else None
        opt_ask = ask if inventory > -self.q_max else None

        return opt_bid, opt_ask
