"""
Unit Tests for OFI, VPIN, and PnL Attribution Metrics.
"""

import pytest
from src.engine.order import Side
from src.engine.matching_engine import Trade
from src.market_maker.inventory_manager import InventoryManager
from src.metrics.ofi import OrderFlowImbalanceTracker
from src.metrics.vpin import VPINCalculator
from src.metrics.pnl_attribution import PnLAttributionEngine


def test_order_flow_imbalance_bid_advance():
    tracker = OrderFlowImbalanceTracker(rolling_window=10)

    # Base state: Bid 100 (vol 10), Ask 101 (vol 10)
    tracker.update(best_bid=100.0, best_bid_vol=10, best_ask=101.0, best_ask_vol=10)

    # Event 1: New bid enters higher at 100.25 (vol 25) -> OFI should be +25
    ofi1 = tracker.update(best_bid=100.25, best_bid_vol=25, best_ask=101.0, best_ask_vol=10)
    assert ofi1 == 25.0

    # Event 2: Ask rises to 101.50 (vol 15) -> positive OFI because ask volume was deleted/pushed up
    # In Cont formula: Ask rose (P^a_k >= P^a_{k-1}) so delta_ask = -v_{k-1}^a = -10. delta_bid - delta_ask = 0 - (-10) = +10
    ofi2 = tracker.update(best_bid=100.25, best_bid_vol=25, best_ask=101.50, best_ask_vol=15)
    assert ofi2 == 10.0


def test_vpin_calculation():
    vpin_calc = VPINCalculator(bucket_size=100, window_size=5)

    # Ingest 100 shares of pure buy orders (Bucket 1 filled: Imbalance = 100)
    trade_buy = Trade(trade_id=1, timestamp_ns=1, price=100.0, quantity=100, maker_order_id=1, taker_order_id=2, taker_side=Side.BUY)
    vpin_calc.update_trade(trade_buy)

    assert len(vpin_calc.completed_buckets) == 1
    assert vpin_calc.vpin == 1.0  # 100% toxicity (pure one-sided flow)
    assert vpin_calc.is_toxic

    # Ingest 100 shares of pure sell orders (Bucket 2 filled: Imbalance = 100)
    trade_sell = Trade(trade_id=2, timestamp_ns=2, price=100.0, quantity=100, maker_order_id=3, taker_order_id=4, taker_side=Side.SELL)
    vpin_calc.update_trade(trade_sell)

    assert len(vpin_calc.completed_buckets) == 2


def test_inventory_manager_roundtrip_accounting():
    inv_mgr = InventoryManager(initial_cash=10_000.0, maker_rebate_bps=0.0, taker_fee_bps=0.0)

    # MM buys 10 @ 100.0 (taker sold)
    t1 = Trade(trade_id=1, timestamp_ns=1, price=100.0, quantity=10, maker_order_id=1, taker_order_id=2, taker_side=Side.SELL)
    inv_mgr.on_trade(t1, is_maker=True)

    assert inv_mgr.inventory == 10
    assert inv_mgr.cash == 9000.0
    assert inv_mgr.realized_pnl == 0.0

    # MM sells 10 @ 100.50 (taker bought)
    t2 = Trade(trade_id=2, timestamp_ns=2, price=100.50, quantity=10, maker_order_id=3, taker_order_id=4, taker_side=Side.BUY)
    inv_mgr.on_trade(t2, is_maker=True)

    assert inv_mgr.inventory == 0
    assert inv_mgr.cash == 10005.0
    assert inv_mgr.realized_pnl == 5.0
    assert inv_mgr.roundtrips_count == 1


def test_pnl_attribution_decomposition():
    engine = PnLAttributionEngine()

    # Fill buy at 99.80 when mid is 100.0 -> spread capture is +0.20 * 10 = +$2.00
    engine.record_fill(exec_price=99.80, mid_at_fill=100.0, quantity=10, is_buy=True, maker_rebate=0.10)
    # Price rises to 100.50 while holding 10 shares -> drift is +$5.00
    engine.record_mid_step(inventory=10, prev_mid=100.0, curr_mid=100.50)

    report = engine.generate_report(observed_total_pnl=7.10)
    assert pytest.approx(report.spread_capture) == 2.0
    assert pytest.approx(report.inventory_drift) == 5.0
    assert pytest.approx(report.net_rebates) == 0.10
    assert pytest.approx(report.total_pnl) == 7.10
