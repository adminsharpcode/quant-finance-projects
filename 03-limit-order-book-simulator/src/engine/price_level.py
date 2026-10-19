"""
Price Level Data Structure.
Maintains FIFO queue order priority for a specific discrete price tick.
"""

from __future__ import annotations
from collections import deque
from typing import Optional, Deque
from .order import Order


class PriceLevel:
    __slots__ = ("price", "orders")

    def __init__(self, price: float):
        self.price: float = price
        self.orders: Deque[Order] = deque()

    @property
    def total_volume(self) -> int:
        return sum(o.remaining_qty for o in self.orders)

    @property
    def order_count(self) -> int:
        return len(self.orders)

    def is_empty(self) -> bool:
        return len(self.orders) == 0

    def add_order(self, order: Order) -> None:
        """Appends order to the back of the queue (Time priority)."""
        self.orders.append(order)

    def remove_order(self, order_id: int) -> Optional[Order]:
        """
        Removes an order by ID (e.g. on cancellation).
        O(N) search within the single price level bucket.
        """
        for i, order in enumerate(self.orders):
            if order.order_id == order_id:
                del self.orders[i]
                return order
        return None

    def peek(self) -> Optional[Order]:
        """Returns the oldest order with highest time priority without removing it."""
        return self.orders[0] if self.orders else None

    def pop_head(self) -> Optional[Order]:
        """Pops the oldest order (when fully filled)."""
        if self.orders:
            return self.orders.popleft()
        return None

    def to_dict(self) -> dict:
        return {
            "price": self.price,
            "volume": self.total_volume,
            "order_count": self.order_count,
        }
