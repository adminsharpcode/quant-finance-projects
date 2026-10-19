"""
Event-Driven FIFO Matching Engine.
Cross-matching logic, multi-level market order sweeps, and trade generation.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import List, Callable, Optional
import time
from .order import Order, Side, OrderType, TimeInForce
from .order_book import LimitOrderBook


@dataclass(slots=True)
class Trade:
    trade_id: int
    timestamp_ns: int
    price: float
    quantity: int
    maker_order_id: int
    taker_order_id: int
    taker_side: Side
    maker_trader_id: str = "MAKER"
    taker_trader_id: str = "TAKER"

    def to_dict(self) -> dict:
        return {
            "trade_id": self.trade_id,
            "timestamp_ns": self.timestamp_ns,
            "price": self.price,
            "quantity": self.quantity,
            "maker_order_id": self.maker_order_id,
            "taker_order_id": self.taker_order_id,
            "taker_side": self.taker_side.value,
            "maker_trader_id": self.maker_trader_id,
            "taker_trader_id": self.taker_trader_id,
        }


class MatchingEngine:
    def __init__(self, book: Optional[LimitOrderBook] = None, symbol: str = "ES", tick_size: float = 0.25):
        self.book: LimitOrderBook = book if book is not None else LimitOrderBook(symbol=symbol, tick_size=tick_size)
        self._trade_id_counter: int = 1
        self.trade_history: List[Trade] = []
        self._trade_listeners: List[Callable[[Trade], None]] = []

    def register_trade_listener(self, callback: Callable[[Trade], None]) -> None:
        self._trade_listeners.append(callback)

    def process_order(self, order: Order) -> List[Trade]:
        """
        Main matching engine event loop processor.
        Dispatches limit, market, and cancellation orders.
        """
        trades: List[Trade] = []

        if order.order_type == OrderType.CANCEL:
            self.book.cancel_order(order.order_id)
            return trades

        if order.order_type == OrderType.MARKET:
            trades = self._match_market_order(order)
            return trades

        if order.order_type == OrderType.LIMIT:
            trades = self._match_limit_order(order)
            return trades

        return trades

    def _match_market_order(self, taker_order: Order) -> List[Trade]:
        trades: List[Trade] = []
        is_buy = taker_order.side == Side.BUY

        while taker_order.remaining_qty > 0:
            target_side = self.book._asks if is_buy else self.book._bids
            if not target_side:
                # Liquidity exhausted
                break

            best_key = next(iter(target_side.keys()))
            best_level = target_side[best_key]

            while best_level.orders and taker_order.remaining_qty > 0:
                maker_order = best_level.peek()
                if maker_order is None:
                    break

                match_qty = min(taker_order.remaining_qty, maker_order.remaining_qty)
                exec_price = best_level.price

                # Execute fill
                maker_order.fill(match_qty)
                taker_order.fill(match_qty)

                trade = Trade(
                    trade_id=self._trade_id_counter,
                    timestamp_ns=time.time_ns(),
                    price=exec_price,
                    quantity=match_qty,
                    maker_order_id=maker_order.order_id,
                    taker_order_id=taker_order.order_id,
                    taker_side=taker_order.side,
                    maker_trader_id=maker_order.trader_id,
                    taker_trader_id=taker_order.trader_id,
                )
                self._trade_id_counter += 1
                trades.append(trade)
                self.trade_history.append(trade)

                # Update book trade telemetry
                self.book.last_traded_price = exec_price
                self.book.last_traded_size = match_qty
                self.book.total_volume_traded += match_qty

                # Notify listeners
                for listener in self._trade_listeners:
                    listener(trade)

                # Pop maker if fully filled
                if maker_order.is_filled:
                    best_level.pop_head()
                    self.book._orders_map.pop(maker_order.order_id, None)

            # If level is depleted, clean up
            if best_level.is_empty():
                target_side.pop(best_key, None)

        return trades

    def _match_limit_order(self, taker_order: Order) -> List[Trade]:
        trades: List[Trade] = []
        is_buy = taker_order.side == Side.BUY

        # 1. Match aggressive crossing portion
        while taker_order.remaining_qty > 0:
            target_side = self.book._asks if is_buy else self.book._bids
            if not target_side:
                break

            best_key = next(iter(target_side.keys()))
            best_level = target_side[best_key]
            exec_price = best_level.price

            # Check price boundary condition
            if is_buy and exec_price > taker_order.price:
                break  # Best ask higher than buy limit price
            if not is_buy and exec_price < taker_order.price:
                break  # Best bid lower than sell limit price

            while best_level.orders and taker_order.remaining_qty > 0:
                maker_order = best_level.peek()
                if maker_order is None:
                    break

                match_qty = min(taker_order.remaining_qty, maker_order.remaining_qty)

                maker_order.fill(match_qty)
                taker_order.fill(match_qty)

                trade = Trade(
                    trade_id=self._trade_id_counter,
                    timestamp_ns=time.time_ns(),
                    price=exec_price,
                    quantity=match_qty,
                    maker_order_id=maker_order.order_id,
                    taker_order_id=taker_order.order_id,
                    taker_side=taker_order.side,
                    maker_trader_id=maker_order.trader_id,
                    taker_trader_id=taker_order.trader_id,
                )
                self._trade_id_counter += 1
                trades.append(trade)
                self.trade_history.append(trade)

                self.book.last_traded_price = exec_price
                self.book.last_traded_size = match_qty
                self.book.total_volume_traded += match_qty

                for listener in self._trade_listeners:
                    listener(trade)

                if maker_order.is_filled:
                    best_level.pop_head()
                    self.book._orders_map.pop(maker_order.order_id, None)

            if best_level.is_empty():
                target_side.pop(best_key, None)

        # 2. If remaining unfilled quantity and GTC, place resting order in book
        if taker_order.remaining_qty > 0 and taker_order.time_in_force == TimeInForce.GTC:
            self.book.add_limit_order(taker_order)

        return trades
