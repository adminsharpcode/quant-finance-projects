"""
Unit & Integration Tests for Limit Order Book & Price-Time Priority.
"""

import pytest
from src.engine.order import Order, Side, OrderType, TimeInForce
from src.engine.price_level import PriceLevel
from src.engine.order_book import LimitOrderBook


def test_order_creation_and_fill():
    order = Order(order_id=1, side=Side.BUY, price=100.0, quantity=10)
    assert order.remaining_qty == 10
    assert not order.is_filled

    filled = order.fill(4)
    assert filled == 4
    assert order.filled_qty == 4
    assert order.remaining_qty == 6
    assert not order.is_filled

    filled_rest = order.fill(10)
    assert filled_rest == 6
    assert order.is_filled
    assert order.remaining_qty == 0


def test_price_level_fifo_queue():
    level = PriceLevel(price=100.0)
    o1 = Order(order_id=1, side=Side.BUY, price=100.0, quantity=10)
    o2 = Order(order_id=2, side=Side.BUY, price=100.0, quantity=25)

    level.add_order(o1)
    level.add_order(o2)

    assert level.total_volume == 35
    assert level.order_count == 2
    assert level.peek().order_id == 1

    popped = level.pop_head()
    assert popped.order_id == 1
    assert level.total_volume == 25
    assert level.order_count == 1
    assert level.peek().order_id == 2


def test_book_best_bid_ask_spread():
    book = LimitOrderBook(symbol="TEST", tick_size=0.25)
    assert book.best_bid is None
    assert book.best_ask is None
    assert book.spread is None

    book.add_limit_order(Order(order_id=1, side=Side.BUY, price=100.0, quantity=10))
    book.add_limit_order(Order(order_id=2, side=Side.BUY, price=99.75, quantity=15))
    book.add_limit_order(Order(order_id=3, side=Side.SELL, price=100.50, quantity=20))
    book.add_limit_order(Order(order_id=4, side=Side.SELL, price=100.75, quantity=30))

    assert book.best_bid == 100.0
    assert book.best_ask == 100.50
    assert book.spread == 0.50
    assert book.mid_price == 100.25


def test_micro_price_volume_weighting():
    book = LimitOrderBook(symbol="TEST", tick_size=0.25)
    # Heavy bid volume (90 vs 10) should pull micro-price closer to ask (100.50)
    book.add_limit_order(Order(order_id=1, side=Side.BUY, price=100.0, quantity=90))
    book.add_limit_order(Order(order_id=2, side=Side.SELL, price=100.50, quantity=10))

    mid = book.mid_price  # 100.25
    micro = book.micro_price  # (90 * 100.50 + 10 * 100.0) / 100 = 100.45
    assert micro == 100.45
    assert micro > mid


def test_order_cancellation():
    book = LimitOrderBook(symbol="TEST", tick_size=0.25)
    book.add_limit_order(Order(order_id=101, side=Side.BUY, price=100.0, quantity=10))
    book.add_limit_order(Order(order_id=102, side=Side.BUY, price=100.0, quantity=20))

    assert book.best_bid_volume == 30

    cancelled = book.cancel_order(101)
    assert cancelled is not None
    assert cancelled.order_id == 101
    assert book.best_bid_volume == 20

    # Cancel remaining order - price level should be cleared
    book.cancel_order(102)
    assert book.best_bid is None


def test_queue_position_tracking():
    book = LimitOrderBook(symbol="TEST", tick_size=0.25)
    book.add_limit_order(Order(order_id=1, side=Side.BUY, price=100.0, quantity=10))
    book.add_limit_order(Order(order_id=2, side=Side.BUY, price=100.0, quantity=25))
    book.add_limit_order(Order(order_id=3, side=Side.BUY, price=100.0, quantity=50))

    pos1 = book.get_queue_position(1)
    assert pos1 == (1, 0)  # Position 1, 0 volume ahead

    pos2 = book.get_queue_position(2)
    assert pos2 == (2, 10)  # Position 2, 10 shares ahead

    pos3 = book.get_queue_position(3)
    assert pos3 == (3, 35)  # Position 3, 35 shares ahead
