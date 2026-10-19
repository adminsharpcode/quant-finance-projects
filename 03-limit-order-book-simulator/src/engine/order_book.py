"""
Limit Order Book (LOB) Engine.
Dual-sorted tree maps for Bids and Asks with O(1) order lookup and cancel.
"""

from __future__ import annotations
from typing import Dict, Tuple, Optional, List
from sortedcontainers import SortedDict
from .order import Order, Side
from .price_level import PriceLevel


class LimitOrderBook:
    def __init__(self, symbol: str = "ES", tick_size: float = 0.25):
        self.symbol: str = symbol
        self.tick_size: float = tick_size

        # Bids sorted descending: key = -price (so index 0 is best bid)
        self._bids: SortedDict[float, PriceLevel] = SortedDict()
        # Asks sorted ascending: key = +price (so index 0 is best ask)
        self._asks: SortedDict[float, PriceLevel] = SortedDict()

        # O(1) order map: order_id -> (PriceLevel, Order)
        self._orders_map: Dict[int, Tuple[PriceLevel, Order]] = {}

        # Last trade cache
        self.last_traded_price: Optional[float] = None
        self.last_traded_size: int = 0
        self.total_volume_traded: int = 0

    @property
    def best_bid(self) -> Optional[float]:
        """Returns the highest active bid price, or None if empty."""
        if not self._bids:
            return None
        neg_price = next(iter(self._bids.keys()))
        return -neg_price

    @property
    def best_ask(self) -> Optional[float]:
        """Returns the lowest active ask price, or None if empty."""
        if not self._asks:
            return None
        return next(iter(self._asks.keys()))

    @property
    def best_bid_volume(self) -> int:
        if not self._bids:
            return 0
        first_level = next(iter(self._bids.values()))
        return first_level.total_volume

    @property
    def best_ask_volume(self) -> int:
        if not self._asks:
            return 0
        first_level = next(iter(self._asks.values()))
        return first_level.total_volume

    @property
    def spread(self) -> Optional[float]:
        """Bid-Ask spread: Best Ask - Best Bid."""
        bb = self.best_bid
        ba = self.best_ask
        if bb is not None and ba is not None:
            return round(ba - bb, 4)
        return None

    @property
    def mid_price(self) -> Optional[float]:
        """Midpoint price: (Best Bid + Best Ask) / 2."""
        bb = self.best_bid
        ba = self.best_ask
        if bb is not None and ba is not None:
            return round((bb + ba) / 2.0, 4)
        return self.last_traded_price

    @property
    def micro_price(self) -> Optional[float]:
        """
        Volume-weighted midpoint price:
        P_micro = (V_bid * P_ask + V_ask * P_bid) / (V_bid + V_ask)
        """
        bb = self.best_bid
        ba = self.best_ask
        vb = self.best_bid_volume
        va = self.best_ask_volume

        if bb is None or ba is None or (vb + va) == 0:
            return self.mid_price
        return round((vb * ba + va * bb) / (vb + va), 4)

    @property
    def volume_imbalance(self) -> float:
        """
        Top-of-book volume imbalance in [-1.0, 1.0]:
        Imb = (V_bid - V_ask) / (V_bid + V_ask)
        """
        vb = self.best_bid_volume
        va = self.best_ask_volume
        if (vb + va) == 0:
            return 0.0
        return round((vb - va) / (vb + va), 4)

    def add_limit_order(self, order: Order) -> None:
        """Inserts a passive limit order into the book maintaining price-time priority."""
        rounded_price = round(round(order.price / self.tick_size) * self.tick_size, 4)
        order.price = rounded_price

        if order.side == Side.BUY:
            key = -rounded_price
            if key not in self._bids:
                self._bids[key] = PriceLevel(rounded_price)
            level = self._bids[key]
        else:
            key = rounded_price
            if key not in self._asks:
                self._asks[key] = PriceLevel(rounded_price)
            level = self._asks[key]

        level.add_order(order)
        self._orders_map[order.order_id] = (level, order)

    def cancel_order(self, order_id: int) -> Optional[Order]:
        """Cancels an open order by ID with O(1) map lookup."""
        if order_id not in self._orders_map:
            return None

        level, order = self._orders_map.pop(order_id)
        removed_order = level.remove_order(order_id)

        # Clean up empty price level
        if level.is_empty():
            if order.side == Side.BUY:
                self._bids.pop(-level.price, None)
            else:
                self._asks.pop(level.price, None)

        return removed_order

    def get_order(self, order_id: int) -> Optional[Order]:
        return self._orders_map.get(order_id, (None, None))[1]

    def get_queue_position(self, order_id: int) -> Optional[Tuple[int, int]]:
        """
        Returns (queue_position, total_volume_ahead) for an open order.
        1-indexed (position 1 means front of the queue).
        """
        if order_id not in self._orders_map:
            return None

        level, target_order = self._orders_map[order_id]
        pos = 1
        vol_ahead = 0

        for ord_item in level.orders:
            if ord_item.order_id == order_id:
                return (pos, vol_ahead)
            pos += 1
            vol_ahead += ord_item.remaining_qty

        return None

    def get_l2_snapshot(self, depth: int = 10) -> dict:
        """
        Extracts up to `depth` levels of Bids and Asks for L2 visualization.
        """
        bids = []
        for i, (neg_p, level) in enumerate(self._bids.items()):
            if i >= depth:
                break
            bids.append({
                "price": level.price,
                "volume": level.total_volume,
                "orders": level.order_count
            })

        asks = []
        for j, (p, level) in enumerate(self._asks.items()):
            if j >= depth:
                break
            asks.append({
                "price": level.price,
                "volume": level.total_volume,
                "orders": level.order_count
            })

        return {
            "symbol": self.symbol,
            "mid_price": self.mid_price,
            "micro_price": self.micro_price,
            "spread": self.spread,
            "imbalance": self.volume_imbalance,
            "bids": bids,
            "asks": asks,
        }

    def clear(self) -> None:
        self._bids.clear()
        self._asks.clear()
        self._orders_map.clear()
        self.last_traded_price = None
        self.last_traded_size = 0
        self.total_volume_traded = 0
