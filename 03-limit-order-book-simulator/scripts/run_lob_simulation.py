"""
Real-Time Limit Order Book (LOB) Terminal Depth Visualizer.
Runs an event-driven simulation with Avellaneda-Stoikov market making and Rich UI depth ladder.
"""

from __future__ import annotations
import sys
import time
import random
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from rich.console import Console
from rich.table import Table
from rich.layout import Layout
from rich.panel import Panel
from rich.live import Live

from src.engine.order import Order, Side, OrderType, TimeInForce
from src.engine.order_book import LimitOrderBook
from src.engine.matching_engine import MatchingEngine
from src.market_maker.avellaneda_stoikov import AvellanedaStoikovModel
from src.market_maker.inventory_manager import InventoryManager
from src.metrics.ofi import OrderFlowImbalanceTracker
from src.metrics.vpin import VPINCalculator
from src.simulation.order_arrival_poisson import PoissonOrderGenerator


def create_depth_table(book: LimitOrderBook, mm_bid: float | None, mm_ask: float | None, r_price: float) -> Table:
    table = Table(title="🏛️ LEVEL 2 DEPTH LADDER & QUEUE ALLOCATION", title_style="bold cyan", border_style="bright_blue")
    table.add_column("Orders", justify="right", style="dim")
    table.add_column("Bid Vol", justify="right", style="bold green")
    table.add_column("Bid Price", justify="right", style="green")
    table.add_column("Ask Price", justify="left", style="red")
    table.add_column("Ask Vol", justify="left", style="bold red")
    table.add_column("Orders", justify="left", style="dim")
    table.add_column("MM Quote Flag", justify="center", style="bold yellow")

    snap = book.get_l2_snapshot(depth=7)
    bids = snap["bids"]
    asks = snap["asks"]
    depth_len = max(len(bids), len(asks), 7)

    for i in range(depth_len):
        b_ord = str(bids[i]["orders"]) if i < len(bids) else ""
        b_vol = str(bids[i]["volume"]) if i < len(bids) else ""
        b_p = f"${bids[i]['price']:.2f}" if i < len(bids) else ""

        a_p = f"${asks[i]['price']:.2f}" if i < len(asks) else ""
        a_vol = str(asks[i]["volume"]) if i < len(asks) else ""
        a_ord = str(asks[i]["orders"]) if i < len(asks) else ""

        mm_flag = ""
        if i < len(bids) and mm_bid and abs(bids[i]["price"] - mm_bid) < 1e-4:
            mm_flag += "[bold cyan]← MM BID*[/] "
        if i < len(asks) and mm_ask and abs(asks[i]["price"] - mm_ask) < 1e-4:
            mm_flag += "[bold magenta]MM ASK* →[/]"

        table.add_row(b_ord, b_vol, b_p, a_p, a_vol, a_ord, mm_flag)

    return table


def main():
    console = Console()
    console.print("[bold green]Initializing High-Frequency Limit Order Book Simulation...[/]")

    symbol = "SPY"
    tick_size = 0.05
    initial_price = 585.00

    book = LimitOrderBook(symbol=symbol, tick_size=tick_size)
    engine = MatchingEngine(book=book, symbol=symbol, tick_size=tick_size)

    # Initialize order book depth with resting liquidity
    for offset_ticks in range(1, 8):
        bid_p = initial_price - offset_ticks * tick_size
        ask_p = initial_price + offset_ticks * tick_size
        book.add_limit_order(Order(order_id=offset_ticks * 2, side=Side.BUY, price=bid_p, quantity=random.randint(20, 100)))
        book.add_limit_order(Order(order_id=offset_ticks * 2 + 1, side=Side.SELL, price=ask_p, quantity=random.randint(20, 100)))

    # Market Maker Model & Inventory
    as_model = AvellanedaStoikovModel(gamma=0.15, sigma=0.03, T=120.0, kappa=1.5, q_max=15, tick_size=tick_size)
    inv_mgr = InventoryManager(initial_cash=100_000.0, max_inventory=15)
    ofi_tracker = OrderFlowImbalanceTracker(rolling_window=30)
    vpin_calc = VPINCalculator(bucket_size=200, window_size=20)
    generator = PoissonOrderGenerator(base_arrival_rate=15.0, market_order_pct=0.35, cancel_order_pct=0.15, mean_qty=6.0, tick_size=tick_size)

    # Connect trade listener for Inventory and VPIN
    mm_order_ids = set()

    def on_trade(trade):
        if trade.maker_order_id in mm_order_ids:
            inv_mgr.on_trade(trade, is_maker=True)
        vpin_calc.update_trade(trade)

    engine.register_trade_listener(on_trade)

    # Simulation loop
    steps = 40
    console.print(f"[bold cyan]Running {steps} microsecond events across Avellaneda-Stoikov Market Making Desk...[/]\n")

    for step in range(1, steps + 1):
        mid = book.mid_price or initial_price

        # Update OFI
        ofi_tracker.update(
            best_bid=book.best_bid,
            best_bid_vol=book.best_bid_volume,
            best_ask=book.best_ask,
            best_ask_vol=book.best_ask_volume,
            mid_price=mid,
        )

        # Compute Avellaneda-Stoikov Quotes
        r_price = as_model.reservation_price(mid, inv_mgr.inventory)
        opt_bid, opt_ask = as_model.optimal_quotes(mid, inv_mgr.inventory)

        # Place MM quotes
        if opt_bid is not None:
            bid_id = 900000 + step * 2
            mm_order_ids.add(bid_id)
            book.add_limit_order(Order(order_id=bid_id, side=Side.BUY, price=opt_bid, quantity=5, trader_id="AVELLANEDA_MM"))

        if opt_ask is not None:
            ask_id = 900000 + step * 2 + 1
            mm_order_ids.add(ask_id)
            book.add_limit_order(Order(order_id=ask_id, side=Side.SELL, price=opt_ask, quantity=5, trader_id="AVELLANEDA_MM"))

        # Generate external order event
        order_event = generator.generate_event(book)
        if order_event is not None:
            engine.process_order(order_event)

        # Mark MM to market
        inv_mgr.mark_to_market(mid_price=mid, timestamp_ns=time.time_ns())

    # Final summary display
    table = create_depth_table(book, opt_bid, opt_ask, r_price)
    metrics = inv_mgr.get_summary_metrics()

    console.print(table)
    console.print("\n[bold cyan]═══ REAL-TIME TELEMETRY & ATTRIBUTION SUMMARY ═══[/]")
    console.print(f"  • Mid Price:          [bold white]${book.mid_price:.2f}[/]")
    console.print(f"  • Micro-Price:        [bold white]${book.micro_price:.2f}[/]")
    console.print(f"  • Spread:             [bold white]${book.spread:.2f}[/]")
    console.print(f"  • Reservation Price:  [bold yellow]${r_price:.2f}[/] (Inventory Skew: {inv_mgr.inventory} contracts)")
    console.print(f"  • Net MM Total PnL:   [bold green]${metrics['total_pnl']:+.2f}[/] (Realized: ${metrics['realized_pnl']:+.2f}, Unrealized: ${metrics['unrealized_pnl']:+.2f})")
    console.print(f"  • Rolling OFI:        [bold cyan]{ofi_tracker.rolling_ofi:+.1f} shares[/]")
    console.print(f"  • VPIN Toxicity:      [bold {'red' if vpin_calc.is_toxic else 'green'}]{vpin_calc.vpin:.3f} ({'TOXIC WARNING' if vpin_calc.is_toxic else 'BALANCED FLOW'})[/]")
    console.print(f"  • Sharpe Ratio:       [bold white]{metrics['sharpe_ratio']:.2f}[/]")
    console.print("[bold green]✔ LOB Simulation & Avellaneda-Stoikov Engine Execution Successful![/]\n")


if __name__ == "__main__":
    main()
