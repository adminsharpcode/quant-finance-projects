"""
Unit & Integration Tests for Matching Engine & Trade Generation.
"""

import pytest
from src.engine.order import Order, Side, OrderType, TimeInForce
from src.engine.order_book import LimitOrderBook
from src.engine.matching_engine import MatchingEngine


def test_market_order_sweep_multiple_levels():
    book = LimitOrderBook(symbol="ES", tick_size=0.25)
    engine = MatchingEngine(book=book)

    # Rest ask liquidity across 3 levels
    book.add_limit_order(Order(order_id=1, side=Side.SELL, price=100.0, quantity=10))
    book.add_limit_order(Order(order_id=2, side=Side.SELL, price=100.25, quantity=20))
    book.add_limit_order(Order(order_id=3, side=Side.SELL, price=100.50, quantity=50))

    # Market buy for 25 shares (should sweep all 10 @ 100.0, and 15 @ 100.25)
    market_buy = Order(order_id=99, side=Side.BUY, price=0.0, quantity=25, order_type=OrderType.MARKET)
    trades = engine.process_order(market_buy)

    assert len(trades) == 2
    assert trades[0].price == 100.0
    assert trades[0].quantity == 10
    assert trades[0].maker_order_id == 1

    assert trades[1].price == 100.25
    assert trades[1].quantity == 15
    assert trades[1].maker_order_id == 2

    assert market_buy.is_filled
    assert book.best_ask == 100.25
    assert book.best_ask_volume == 5  # 20 - 15 = 5 remaining


def test_crossing_limit_order_with_passive_remainder():
    book = LimitOrderBook(symbol="ES", tick_size=0.25)
    engine = MatchingEngine(book=book)

    # Ask of 10 @ 100.25
    book.add_limit_order(Order(order_id=1, side=Side.SELL, price=100.25, quantity=10))

    # Aggressive Limit Buy for 25 @ 100.50 (crosses 100.25, fills 10, then rests 15 @ 100.50)
    limit_buy = Order(order_id=2, side=Side.BUY, price=100.50, quantity=25, order_type=OrderType.LIMIT)
    trades = engine.process_order(limit_buy)

    assert len(trades) == 1
    assert trades[0].price == 100.25
    assert trades[0].quantity == 10

    # Remaining 15 shares should now rest on the Bid side at 100.50
    assert book.best_bid == 100.50
    assert book.best_bid_volume == 15


def test_ioc_cancellation_of_unfilled_portion():
    book = LimitOrderBook(symbol="ES", tick_size=0.25)
    engine = MatchingEngine(book=book)

    book.add_limit_order(Order(order_id=1, side=Side.SELL, price=100.0, quantity=10))

    # IOC Buy for 30 shares @ 100.0
    ioc_buy = Order(order_id=2, side=Side.BUY, price=100.0, quantity=30, order_type=OrderType.LIMIT, time_in_force=TimeInForce.IOC)
    trades = engine.process_order(ioc_buy)

    assert len(trades) == 1
    assert trades[0].quantity == 10
    # Remaining 20 shares must NOT rest in the book
    assert book.best_bid is None
