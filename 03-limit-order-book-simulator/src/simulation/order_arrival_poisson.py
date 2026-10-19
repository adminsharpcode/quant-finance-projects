"""
Poisson Order Flow Simulator.
Simulates retail noise flow, institutional taker sweeps, and passive liquidity placement.
"""

from __future__ import annotations
import random
import time
from typing import Optional, List
import numpy as np
from ..engine.order import Order, Side, OrderType, TimeInForce
from ..engine.order_book import LimitOrderBook


class PoissonOrderGenerator:
    def __init__(
        self,
        base_arrival_rate: float = 12.0,    # Orders per second
        market_order_pct: float = 0.35,     # 35% of orders are aggressive market orders
        cancel_order_pct: float = 0.20,     # 20% of events are cancellations
        mean_qty: float = 5.0,              # Mean order quantity
        informed_bias: float = 0.0,         # Directional drift in [-1.0, 1.0]
        tick_size: float = 0.25,
    ):
        self.base_arrival_rate = base_arrival_rate
        self.market_order_pct = market_order_pct
        self.cancel_order_pct = cancel_order_pct
        self.mean_qty = mean_qty
        self.informed_bias = informed_bias
        self.tick_size = tick_size
        self._order_id_seq: int = 100_000

    def generate_event(self, book: LimitOrderBook) -> Optional[Order]:
        """
        Generates the next stochastic order or cancel event based on the current book state.
        """
        self._order_id_seq += 1
        oid = self._order_id_seq

        # Determine order side with informed drift bias
        p_buy = 0.5 + 0.5 * self.informed_bias
        side = Side.BUY if random.random() < p_buy else Side.SELL

        # Quantity: Poisson or geometric with minimum of 1
        qty = max(1, int(np.random.geometric(p=1.0 / self.mean_qty)))

        rand_event = random.random()

        # 1. Cancel Event
        if rand_event < self.cancel_order_pct and len(book._orders_map) > 5:
            # Pick an existing non-market maker order to cancel
            target_ids = list(book._orders_map.keys())
            cancel_id = random.choice(target_ids)
            return Order(
                order_id=cancel_id,
                side=side,
                price=0.0,
                quantity=0,
                order_type=OrderType.CANCEL,
            )

        # 2. Aggressive Market Order
        if rand_event < (self.cancel_order_pct + self.market_order_pct):
            return Order(
                order_id=oid,
                side=side,
                price=0.0,
                quantity=qty,
                order_type=OrderType.MARKET,
                trader_id="NOISE_TAKER",
            )

        # 3. Passive Limit Order
        mid = book.mid_price or 100.0
        # Depth offset: exponential distribution of ticks from mid
        tick_depth = int(np.random.exponential(scale=2.5)) + 1
        offset = tick_depth * self.tick_size

        if side == Side.BUY:
            bb = book.best_bid or (mid - self.tick_size)
            # Quote near or slightly below best bid
            price = bb - (tick_depth - 1) * self.tick_size
        else:
            ba = book.best_ask or (mid + self.tick_size)
            # Quote near or slightly above best ask
            price = ba + (tick_depth - 1) * self.tick_size

        price = round(round(price / self.tick_size) * self.tick_size, 4)

        return Order(
            order_id=oid,
            side=side,
            price=price,
            quantity=qty,
            order_type=OrderType.LIMIT,
            time_in_force=TimeInForce.GTC,
            trader_id="RETAIL_LIMIT",
        )
