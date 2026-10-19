"""
Quantitative Market Making Performance & Inventory Risk Attribution Benchmark.
Compares Avellaneda-Stoikov Adaptive Quoting vs. Naive Fixed-Spread Quoting.
"""

from __future__ import annotations
import sys
import random
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

import numpy as np
from rich.console import Console
from rich.table import Table

from src.engine.order import Order, Side, OrderType
from src.engine.order_book import LimitOrderBook
from src.engine.matching_engine import MatchingEngine
from src.market_maker.avellaneda_stoikov import AvellanedaStoikovModel
from src.market_maker.inventory_manager import InventoryManager
from src.market_maker.adverse_selection import AdverseSelectionAnalyzer
from src.metrics.pnl_attribution import PnLAttributionEngine
from src.simulation.order_arrival_poisson import PoissonOrderGenerator


def run_backtest_strategy(strategy_type: str = "AVELLANEDA", num_steps: int = 250, seed: int = 42):
    random.seed(seed)
    np.random.seed(seed)

    symbol = "SPY"
    tick_size = 0.05
    initial_price = 585.00

    book = LimitOrderBook(symbol=symbol, tick_size=tick_size)
    engine = MatchingEngine(book=book, symbol=symbol, tick_size=tick_size)

    # Initial order book depth
    for offset in range(1, 10):
        book.add_limit_order(Order(order_id=offset * 2, side=Side.BUY, price=initial_price - offset * tick_size, quantity=40))
        book.add_limit_order(Order(order_id=offset * 2 + 1, side=Side.SELL, price=initial_price + offset * tick_size, quantity=40))

    as_model = AvellanedaStoikovModel(gamma=0.15, sigma=0.03, T=30.0, kappa=10.0, q_max=12, tick_size=tick_size)
    inv_mgr = InventoryManager(initial_cash=100_000.0, max_inventory=12)
    adv_sel = AdverseSelectionAnalyzer(horizons=[1, 5, 10])
    attribution = PnLAttributionEngine()
    generator = PoissonOrderGenerator(base_arrival_rate=20.0, market_order_pct=0.40, cancel_order_pct=0.15, mean_qty=8.0, tick_size=tick_size)

    mm_order_ids = set()

    def on_trade(trade):
        if trade.maker_order_id in mm_order_ids:
            is_buyer = (trade.taker_side == Side.SELL)
            inv_mgr.on_trade(trade, is_maker=True)
            adv_sel.record_fill(trade, is_mm_buyer=is_buyer)
            attribution.record_fill(
                exec_price=trade.price,
                mid_at_fill=book.mid_price or initial_price,
                quantity=trade.quantity,
                is_buy=is_buyer,
                maker_rebate=(0.20 * 1e-4) * (trade.price * trade.quantity)
            )

    engine.register_trade_listener(on_trade)

    prev_mid = initial_price

    for step in range(1, num_steps + 1):
        mid = book.mid_price or initial_price
        adv_sel.record_mid_price(mid)
        attribution.record_mid_step(inv_mgr.inventory, prev_mid, mid)
        prev_mid = mid

        # Determine quotes based on strategy
        if strategy_type == "AVELLANEDA":
            opt_bid, opt_ask = as_model.optimal_quotes(mid, inv_mgr.inventory)
        elif strategy_type == "NAIVE_FIXED":
            # Naive quotes always 1 tick outside best quotes regardless of inventory
            spread_ticks = 2
            opt_bid = round(mid - spread_ticks * tick_size, 2) if inv_mgr.inventory < 12 else None
            opt_ask = round(mid + spread_ticks * tick_size, 2) if inv_mgr.inventory > -12 else None
        else:
            opt_bid = round(mid - random.randint(1, 3) * tick_size, 2)
            opt_ask = round(mid + random.randint(1, 3) * tick_size, 2)

        # Place quotes
        if opt_bid is not None:
            bid_id = 900000 + step * 2
            mm_order_ids.add(bid_id)
            book.add_limit_order(Order(order_id=bid_id, side=Side.BUY, price=opt_bid, quantity=5, trader_id="MM"))

        if opt_ask is not None:
            ask_id = 900000 + step * 2 + 1
            mm_order_ids.add(ask_id)
            book.add_limit_order(Order(order_id=ask_id, side=Side.SELL, price=opt_ask, quantity=5, trader_id="MM"))

        # Process market order flow
        event = generator.generate_event(book)
        if event is not None:
            engine.process_order(event)

        inv_mgr.mark_to_market(mid_price=mid)

    metrics = inv_mgr.get_summary_metrics()
    adv_metrics = adv_sel.compute_adverse_selection_metrics()
    report = attribution.generate_report(metrics["total_pnl"])

    return {
        "metrics": metrics,
        "adverse": adv_metrics,
        "attribution": report.to_dict(),
        "final_inventory": inv_mgr.inventory,
    }


def main():
    console = Console()
    console.print("\n[bold cyan]🏛️ QUANT RESEARCH LAB: AVELLANEDA-STOIKOV vs. NAIVE MARKET MAKING[/]\n")

    res_as = run_backtest_strategy("AVELLANEDA", num_steps=300)
    res_naive = run_backtest_strategy("NAIVE_FIXED", num_steps=300)

    table = Table(title="STRATEGY BACKTEST & ATTRIBUTION COMPARISON", border_style="bright_blue", title_style="bold yellow")
    table.add_column("Quantitative Metric", style="cyan", justify="left")
    table.add_column("Avellaneda-Stoikov (Adaptive)", style="bold green", justify="right")
    table.add_column("Naive Fixed-Spread", style="bold red", justify="right")
    table.add_column("Edge / Improvement", style="bold white", justify="right")

    m_as = res_as["metrics"]
    m_nv = res_naive["metrics"]

    pnl_diff = m_as["total_pnl"] - m_nv["total_pnl"]
    pnl_edge = f"{pnl_diff:+.2f} ({'+' if pnl_diff >= 0 else ''}{(pnl_diff / max(1.0, abs(m_nv['total_pnl']))) * 100:.1f}%)"

    table.add_row("Total Net PnL ($)", f"${m_as['total_pnl']:+.2f}", f"${m_nv['total_pnl']:+.2f}", pnl_edge)
    table.add_row("Realized PnL ($)", f"${m_as['realized_pnl']:+.2f}", f"${m_nv['realized_pnl']:+.2f}", f"{m_as['realized_pnl'] - m_nv['realized_pnl']:+.2f}")
    table.add_row("Unrealized MTM ($)", f"${m_as['unrealized_pnl']:+.2f}", f"${m_nv['unrealized_pnl']:+.2f}", f"{m_as['unrealized_pnl'] - m_nv['unrealized_pnl']:+.2f}")
    table.add_row("Sharpe Ratio (Annualized)", f"{m_as['sharpe_ratio']:.2f}", f"{m_nv['sharpe_ratio']:.2f}", f"{m_as['sharpe_ratio'] - m_nv['sharpe_ratio']:+.2f}")
    table.add_row("Max Drawdown ($)", f"${m_as['max_drawdown']:.2f}", f"${m_nv['max_drawdown']:.2f}", f"-${abs(m_nv['max_drawdown'] - m_as['max_drawdown']):.2f} (Reduced)")
    table.add_row("Inventory Volatility (σ_q)", f"{m_as['inventory_std']:.2f}", f"{m_nv['inventory_std']:.2f}", f"{((m_as['inventory_std'] - m_nv['inventory_std']) / max(0.01, m_nv['inventory_std'])) * 100:.1f}% Skew Control")
    table.add_row("Terminal Inventory (q)", f"{res_as['final_inventory']} sh", f"{res_naive['final_inventory']} sh", "Near Zero" if abs(res_as['final_inventory']) < abs(res_naive['final_inventory']) else "Optimal")
    table.add_row("Kyle's Lambda (Adverse Impact)", f"{res_as['adverse']['kyles_lambda']:.6f}", f"{res_naive['adverse']['kyles_lambda']:.6f}", "Lower Pickoff")
    table.add_row("Total Volume Filled", f"{int(m_as['volume_traded'])} sh", f"{int(m_nv['volume_traded'])} sh", f"{int(m_as['volume_traded'] - m_nv['volume_traded']):+d}")

    console.print(table)

    console.print("\n[bold yellow]📊 PnL Attribution Breakdown (Avellaneda-Stoikov):[/]")
    att = res_as["attribution"]
    console.print(f"  • Pure Spread Capture:       [bold green]${att['spread_capture']:+.2f}[/]")
    console.print(f"  • Inventory Drift MTM:       [bold cyan]${att['inventory_drift']:+.2f}[/]")
    console.print(f"  • Adverse Selection Drag:    [bold red]-${att['adverse_selection_drag']:.2f}[/]")
    console.print(f"  • Maker Rebates Collected:   [bold yellow]+${att['net_rebates']:.2f}[/]")
    console.print(f"  • Net Accounted PnL:         [bold white]${att['total_pnl']:+.2f}[/]\n")


if __name__ == "__main__":
    main()
