"""
Tick-Level Execution Simulator (High Precision)
-----------------------------------------------
Provides realistic microstructure order filling including:
- Bid-Ask spread crossing (Longs execute on Ask, Shorts on Bid)
- Adverse market impact & tick slippage
- Institutional broker commissions
- Sub-millisecond Stop Loss, Take Profit, Breakeven Lock, & Trailing Stop triggers
"""

from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, List


class OrderSide(Enum):
    BUY = "BUY"
    SELL = "SELL"


class OrderStatus(Enum):
    PENDING = "PENDING"
    OPEN = "OPEN"
    CLOSED = "CLOSED"
    CANCELLED = "CANCELLED"


@dataclass
class TradeRecord:
    order_id: int
    side: OrderSide
    open_time_msc: int
    open_price: float
    close_time_msc: int
    close_price: float
    units: float
    lots: float
    gross_pnl: float
    commission: float
    slippage_cost: float
    net_pnl: float
    return_pct: float
    holding_time_seconds: float
    exit_reason: str  # 'STOP_LOSS', 'TAKE_PROFIT', 'TRAILING_STOP', 'BREAKEVEN', 'END_OF_SERIES'


@dataclass
class ActivePosition:
    order_id: int
    side: OrderSide
    open_time_msc: int
    open_price: float
    units: float
    lots: float
    stop_loss: Optional[float] = None
    take_profit: Optional[float] = None
    breakeven_dist: Optional[float] = None
    trailing_stop_dist: Optional[float] = None
    trailing_activation_price: Optional[float] = None
    is_breakeven_locked: bool = False
    highest_price: float = field(init=False)
    lowest_price: float = field(init=False)

    def __post_init__(self):
        self.highest_price = self.open_price
        self.lowest_price = self.open_price


class ExecutionEngine:
    def __init__(
        self,
        base_slippage_pips: float = 0.15,
        pip_size: float = 0.0001,
        commission_per_lot_round_turn: float = 5.0,  # $5 per 100k round turn
        lot_size: float = 100000.0
    ):
        self.base_slippage_pips = base_slippage_pips
        self.pip_size = pip_size
        self.commission_per_lot = commission_per_lot_round_turn
        self.lot_size = lot_size
        self.next_order_id = 1

    def calculate_commission(self, lots: float) -> float:
        return round(lots * self.commission_per_lot, 4)

    def calculate_slippage(self, spread: float, volatility: float = 1.0) -> float:
        """Dynamic slippage based on spread width and market volatility."""
        return max(0.0, (self.base_slippage_pips * self.pip_size) + (spread * 0.05 * volatility))

    def open_position(
        self,
        side: OrderSide,
        lots: float,
        bid: float,
        ask: float,
        timestamp_msc: int,
        stop_loss: Optional[float] = None,
        take_profit: Optional[float] = None,
        breakeven_dist: Optional[float] = None,
        trailing_stop_dist: Optional[float] = None,
        trailing_activation_dist: Optional[float] = None
    ) -> ActivePosition:
        spread = ask - bid
        slippage = self.calculate_slippage(spread)

        if side == OrderSide.BUY:
            exec_price = ask + slippage
            act_price = (exec_price + trailing_activation_dist) if trailing_activation_dist else None
        else:
            exec_price = bid - slippage
            act_price = (exec_price - trailing_activation_dist) if trailing_activation_dist else None

        pos = ActivePosition(
            order_id=self.next_order_id,
            side=side,
            open_time_msc=timestamp_msc,
            open_price=round(exec_price, 6),
            units=lots * self.lot_size,
            lots=lots,
            stop_loss=round(stop_loss, 6) if stop_loss else None,
            take_profit=round(take_profit, 6) if take_profit else None,
            breakeven_dist=breakeven_dist,
            trailing_stop_dist=trailing_stop_dist,
            trailing_activation_price=round(act_price, 6) if act_price else None
        )
        self.next_order_id += 1
        return pos

    def close_position(
        self,
        pos: ActivePosition,
        bid: float,
        ask: float,
        timestamp_msc: int,
        exit_reason: str
    ) -> TradeRecord:
        spread = ask - bid
        slippage = self.calculate_slippage(spread)

        if pos.side == OrderSide.BUY:
            close_price = bid - slippage
            gross_pnl = (close_price - pos.open_price) * pos.units
        else:
            close_price = ask + slippage
            gross_pnl = (pos.open_price - close_price) * pos.units

        commission = self.calculate_commission(pos.lots)
        slippage_cost = 2.0 * slippage * pos.units
        net_pnl = gross_pnl - commission

        notional_entry = pos.open_price * pos.units
        return_pct = (net_pnl / notional_entry) * 100.0 if notional_entry > 0 else 0.0
        holding_sec = max(0.001, (timestamp_msc - pos.open_time_msc) / 1000.0)

        return TradeRecord(
            order_id=pos.order_id,
            side=pos.side,
            open_time_msc=pos.open_time_msc,
            open_price=pos.open_price,
            close_time_msc=timestamp_msc,
            close_price=round(close_price, 6),
            units=pos.units,
            lots=pos.lots,
            gross_pnl=round(gross_pnl, 4),
            commission=round(commission, 4),
            slippage_cost=round(slippage_cost, 4),
            net_pnl=round(net_pnl, 4),
            return_pct=round(return_pct, 6),
            holding_time_seconds=round(holding_sec, 3),
            exit_reason=exit_reason
        )

    def check_stops(
        self,
        pos: ActivePosition,
        bid: float,
        ask: float,
        timestamp_msc: int
    ) -> Optional[TradeRecord]:
        """Evaluates Stop Loss, Take Profit, Breakeven Lock, and Trailing Stop."""
        if pos.side == OrderSide.BUY:
            pos.highest_price = max(pos.highest_price, bid)

            # Check Hard Stop Loss
            if pos.stop_loss is not None and bid <= pos.stop_loss:
                reason = "BREAKEVEN" if pos.is_breakeven_locked and pos.stop_loss >= pos.open_price else "STOP_LOSS"
                return self.close_position(pos, bid, ask, timestamp_msc, reason)

            # Check Take Profit
            if pos.take_profit is not None and bid >= pos.take_profit:
                return self.close_position(pos, bid, ask, timestamp_msc, "TAKE_PROFIT")

            # Breakeven Lock trigger
            if not pos.is_breakeven_locked and pos.breakeven_dist is not None:
                if pos.highest_price >= pos.open_price + pos.breakeven_dist:
                    pos.stop_loss = round(pos.open_price + (self.pip_size * 0.5), 6)
                    pos.is_breakeven_locked = True

            # Trailing Stop update
            if pos.trailing_stop_dist is not None:
                if pos.trailing_activation_price is None or pos.highest_price >= pos.trailing_activation_price:
                    new_sl = pos.highest_price - pos.trailing_stop_dist
                    if pos.stop_loss is None or new_sl > pos.stop_loss:
                        pos.stop_loss = round(new_sl, 6)

        elif pos.side == OrderSide.SELL:
            pos.lowest_price = min(pos.lowest_price, ask)

            # Check Hard Stop Loss
            if pos.stop_loss is not None and ask >= pos.stop_loss:
                reason = "BREAKEVEN" if pos.is_breakeven_locked and pos.stop_loss <= pos.open_price else "STOP_LOSS"
                return self.close_position(pos, bid, ask, timestamp_msc, reason)

            # Check Take Profit
            if pos.take_profit is not None and ask <= pos.take_profit:
                return self.close_position(pos, bid, ask, timestamp_msc, "TAKE_PROFIT")

            # Breakeven Lock trigger
            if not pos.is_breakeven_locked and pos.breakeven_dist is not None:
                if pos.lowest_price <= pos.open_price - pos.breakeven_dist:
                    pos.stop_loss = round(pos.open_price - (self.pip_size * 0.5), 6)
                    pos.is_breakeven_locked = True

            # Trailing Stop update
            if pos.trailing_stop_dist is not None:
                if pos.trailing_activation_price is None or pos.lowest_price <= pos.trailing_activation_price:
                    new_sl = pos.lowest_price + pos.trailing_stop_dist
                    if pos.stop_loss is None or new_sl < pos.stop_loss:
                        pos.stop_loss = round(new_sl, 6)

        return None
