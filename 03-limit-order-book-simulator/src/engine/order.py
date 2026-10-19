"""
Order Data Structures & Enumerations.
High-performance representation of limit and market orders.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum, auto
import time


class Side(str, Enum):
    BUY = "BUY"
    SELL = "SELL"

    @property
    def opposite(self) -> Side:
        return Side.SELL if self == Side.BUY else Side.BUY

    @property
    def sign(self) -> int:
        return 1 if self == Side.BUY else -1


class OrderType(str, Enum):
    LIMIT = "LIMIT"
    MARKET = "MARKET"
    CANCEL = "CANCEL"


class TimeInForce(str, Enum):
    GTC = "GTC"  # Good Till Cancel
    IOC = "IOC"  # Immediate or Cancel
    FOK = "FOK"  # Fill or Kill


@dataclass(slots=True)
class Order:
    order_id: int
    side: Side
    price: float
    quantity: int
    order_type: OrderType = OrderType.LIMIT
    time_in_force: TimeInForce = TimeInForce.GTC
    timestamp_ns: int = field(default_factory=time.time_ns)
    trader_id: str = "ANON"
    filled_qty: int = 0

    @property
    def remaining_qty(self) -> int:
        return max(0, self.quantity - self.filled_qty)

    @property
    def is_filled(self) -> bool:
        return self.filled_qty >= self.quantity

    def fill(self, fill_qty: int) -> int:
        """
        Executes a partial or full fill. Returns the actual quantity filled.
        """
        exec_qty = min(fill_qty, self.remaining_qty)
        self.filled_qty += exec_qty
        return exec_qty

    def to_dict(self) -> dict:
        return {
            "order_id": self.order_id,
            "side": self.side.value,
            "price": self.price,
            "quantity": self.quantity,
            "filled_qty": self.filled_qty,
            "remaining_qty": self.remaining_qty,
            "order_type": self.order_type.value,
            "timestamp_ns": self.timestamp_ns,
            "trader_id": self.trader_id,
        }
