"""
Market Maker Inventory Risk & PnL Accounting Manager.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import List, Dict, Optional
import numpy as np
from ..engine.order import Side
from ..engine.matching_engine import Trade


@dataclass
class InventorySnapshot:
    timestamp_ns: int
    inventory: int
    mid_price: float
    cash: float
    realized_pnl: float
    unrealized_pnl: float
    total_pnl: float


class InventoryManager:
    def __init__(
        self,
        initial_cash: float = 100_000.0,
        max_inventory: int = 10,
        maker_rebate_bps: float = 0.20,  # +0.20 bps maker rebate
        taker_fee_bps: float = 0.50,     # -0.50 bps taker fee
    ):
        self.initial_cash = initial_cash
        self.cash = initial_cash
        self.inventory: int = 0
        self.max_inventory = abs(max_inventory)
        self.maker_rebate_bps = maker_rebate_bps
        self.taker_fee_bps = taker_fee_bps

        # Accounting state
        self.avg_entry_price: float = 0.0
        self.realized_pnl: float = 0.0
        self.unrealized_pnl: float = 0.0
        self.total_rebates_collected: float = 0.0
        self.total_fees_paid: float = 0.0
        self.volume_traded: int = 0
        self.roundtrips_count: int = 0

        # High-resolution time-series for quantitative telemetry
        self.history: List[InventorySnapshot] = []

    @property
    def total_pnl(self) -> float:
        return self.realized_pnl + self.unrealized_pnl + self.total_rebates_collected - self.total_fees_paid

    def on_trade(self, trade: Trade, is_maker: bool = True) -> None:
        """
        Updates cash, inventory, and realized PnL upon execution of a trade.
        """
        # Determine the direction for this market maker:
        # If taker_side == BUY: taker is buying, maker is SELLING.
        # If taker_side == SELL: taker is selling, maker is BUYING.
        if is_maker:
            mm_bought = (trade.taker_side == Side.SELL)
        else:
            mm_bought = (trade.taker_side == Side.BUY)

        qty = trade.quantity
        price = trade.price
        notional = price * qty

        self.volume_traded += qty

        # Exchange Fee / Rebate
        if is_maker:
            rebate = (self.maker_rebate_bps * 1e-4) * notional
            self.total_rebates_collected += rebate
        else:
            fee = (self.taker_fee_bps * 1e-4) * notional
            self.total_fees_paid += fee

        if mm_bought:
            # Buying
            self.cash -= notional
            if self.inventory < 0:
                # Covering short position
                covered_qty = min(qty, abs(self.inventory))
                pnl = covered_qty * (self.avg_entry_price - price)
                self.realized_pnl += pnl
                self.roundtrips_count += 1

                new_inv = self.inventory + qty
                if new_inv > 0:
                    self.avg_entry_price = price
                elif new_inv == 0:
                    self.avg_entry_price = 0.0
                self.inventory = new_inv
            else:
                # Adding to existing long
                prev_val = self.inventory * self.avg_entry_price
                new_val = prev_val + notional
                self.inventory += qty
                self.avg_entry_price = new_val / self.inventory if self.inventory > 0 else 0.0
        else:
            # Selling
            self.cash += notional
            if self.inventory > 0:
                # Liquidating long position
                closed_qty = min(qty, self.inventory)
                pnl = closed_qty * (price - self.avg_entry_price)
                self.realized_pnl += pnl
                self.roundtrips_count += 1

                new_inv = self.inventory - qty
                if new_inv < 0:
                    self.avg_entry_price = price
                elif new_inv == 0:
                    self.avg_entry_price = 0.0
                self.inventory = new_inv
            else:
                # Adding to existing short
                prev_val = abs(self.inventory) * self.avg_entry_price
                new_val = prev_val + notional
                self.inventory -= qty
                self.avg_entry_price = new_val / abs(self.inventory) if self.inventory < 0 else 0.0

    def mark_to_market(self, mid_price: float, timestamp_ns: int = 0) -> None:
        """Computes current unrealized PnL against current mid-price."""
        if self.inventory > 0:
            self.unrealized_pnl = self.inventory * (mid_price - self.avg_entry_price)
        elif self.inventory < 0:
            self.unrealized_pnl = abs(self.inventory) * (self.avg_entry_price - mid_price)
        else:
            self.unrealized_pnl = 0.0

        self.history.append(
            InventorySnapshot(
                timestamp_ns=timestamp_ns,
                inventory=self.inventory,
                mid_price=mid_price,
                cash=self.cash,
                realized_pnl=self.realized_pnl,
                unrealized_pnl=self.unrealized_pnl,
                total_pnl=self.total_pnl,
            )
        )

    def get_summary_metrics(self) -> Dict[str, float]:
        """Calculates institutional performance statistics."""
        if len(self.history) < 2:
            return {
                "total_pnl": self.total_pnl,
                "realized_pnl": self.realized_pnl,
                "unrealized_pnl": self.unrealized_pnl,
                "sharpe_ratio": 0.0,
                "max_drawdown": 0.0,
                "inventory_std": 0.0,
                "volume_traded": float(self.volume_traded),
            }

        pnls = np.array([s.total_pnl for s in self.history])
        invs = np.array([s.inventory for s in self.history])

        # Step returns
        diffs = np.diff(pnls)
        std_diff = np.std(diffs)
        mean_diff = np.mean(diffs)
        sharpe = float((mean_diff / std_diff) * np.sqrt(252 * 6.5 * 3600)) if std_diff > 1e-8 else 0.0

        # Maximum Drawdown
        cum_max = np.maximum.accumulate(pnls)
        dd = cum_max - pnls
        max_dd = float(np.max(dd)) if len(dd) > 0 else 0.0

        return {
            "total_pnl": round(self.total_pnl, 2),
            "realized_pnl": round(self.realized_pnl, 2),
            "unrealized_pnl": round(self.unrealized_pnl, 2),
            "rebates": round(self.total_rebates_collected, 2),
            "fees": round(self.total_fees_paid, 2),
            "sharpe_ratio": round(sharpe, 2),
            "max_drawdown": round(max_dd, 2),
            "inventory_std": round(float(np.std(invs)), 2),
            "volume_traded": float(self.volume_traded),
            "roundtrips": float(self.roundtrips_count),
        }
