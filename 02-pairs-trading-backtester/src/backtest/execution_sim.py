"""Institutional Pairs Execution & Realistic Microstructure Simulator.

Models bid-ask half-spread crossing, non-linear slippage, broker share commissions,
and continuous prime-broker short borrow fees.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional
import numpy as np
import pandas as pd


@dataclass
class TradeRecord:
    """Detailed record of a round-trip pairs trade."""
    trade_id: int
    direction: str            # 'LONG_SPREAD' or 'SHORT_SPREAD'
    entry_index: int
    exit_index: int
    duration_bars: int
    y_entry_price: float
    y_exit_price: float
    x_entry_price: float
    x_exit_price: float
    y_shares: float
    x_shares: float
    hedge_ratio: float
    gross_pnl: float
    commissions: float
    slippage_cost: float
    borrow_fees: float
    net_pnl: float
    return_pct: float
    exit_reason: str          # 'TAKE_PROFIT', 'STOP_LOSS', 'END_OF_SERIES'


@dataclass
class BacktestResult:
    """Comprehensive container for backtest simulation results."""
    initial_capital: float
    final_equity: float
    total_net_pnl: float
    total_return_pct: float
    equity_curve: np.ndarray
    returns: np.ndarray
    daily_pnl: np.ndarray
    positions: np.ndarray
    trades: List[TradeRecord]
    total_commissions: float
    total_slippage: float
    total_borrow_fees: float
    dates: Optional[List[str]] = None


class PairsExecutionSimulator:
    """Simulates realistic institutional trade execution for a cointegrated pair."""

    def __init__(
        self,
        initial_capital: float = 100_000.0,
        commission_per_share: float = 0.005,
        half_spread_bps: float = 3.0,       # 3 basis points half-spread
        slippage_bps: float = 2.0,          # 2 basis points impact slippage
        short_borrow_fee_annual: float = 0.015, # 1.5% p.a. prime broker borrow rate
        allocation_pct: float = 1.0         # % of portfolio capital allocated to this pair
    ):
        """Initialize simulator parameters."""
        self.initial_capital = initial_capital
        self.commission_per_share = commission_per_share
        self.half_spread = half_spread_bps * 1e-4
        self.slippage = slippage_bps * 1e-4
        self.daily_borrow_rate = short_borrow_fee_annual / 360.0
        self.allocation_pct = allocation_pct

    def simulate(
        self,
        series_y: np.ndarray,
        series_x: np.ndarray,
        positions: np.ndarray,
        hedge_ratios: np.ndarray,
        dates: Optional[List[str]] = None
    ) -> BacktestResult:
        """Run step-by-step mark-to-market backtest simulation.

        Args:
            series_y: Price series of asset Y.
            series_x: Price series of asset X.
            positions: Position regime array (+1, -1, 0).
            hedge_ratios: Dynamic beta array beta_t.
            dates: Optional list of date strings.

        Returns:
            BacktestResult containing equity curves, metrics, and trade records.
        """
        y = np.asarray(series_y, dtype=float)
        x = np.asarray(series_x, dtype=float)
        pos = np.asarray(positions, dtype=int)
        betas = np.asarray(hedge_ratios, dtype=float)
        n = len(y)

        equity = np.zeros(n)
        equity[0] = self.initial_capital
        daily_pnl = np.zeros(n)
        returns = np.zeros(n)

        trades: List[TradeRecord] = []
        trade_counter = 0

        # State tracking
        current_pos = 0
        y_shares = 0.0
        x_shares = 0.0
        trade_entry_idx = 0
        trade_direction = ""
        trade_entry_y = 0.0
        trade_entry_x = 0.0
        accum_commissions = 0.0
        accum_slippage = 0.0
        accum_borrow = 0.0

        total_commissions_all = 0.0
        total_slippage_all = 0.0
        total_borrow_all = 0.0

        for t in range(1, n):
            target_pos = pos[t]
            prior_equity = equity[t - 1]
            pnl_t = 0.0
            borrow_fee_t = 0.0
            cost_t = 0.0

            # 1. Accrue borrow fee on overnight short positions
            if current_pos != 0:
                short_val = 0.0
                if y_shares < 0:
                    short_val += abs(y_shares) * y[t - 1]
                if x_shares < 0:
                    short_val += abs(x_shares) * x[t - 1]

                borrow_fee_t = short_val * self.daily_borrow_rate
                accum_borrow += borrow_fee_t
                total_borrow_all += borrow_fee_t

            # 2. Mark-to-market PnL from held positions from t-1 to t
            if current_pos != 0:
                pnl_y = y_shares * (y[t] - y[t - 1])
                pnl_x = x_shares * (x[t] - x[t - 1])
                pnl_t += (pnl_y + pnl_x)

            # 3. Handle Position Transitions (Entries / Exits / Flips)
            if target_pos != current_pos:
                # Close existing position if any
                if current_pos != 0:
                    # Execution prices with crossing spread & slippage
                    exit_y_price = y[t] * (1.0 - np.sign(y_shares) * (self.half_spread + self.slippage))
                    exit_x_price = x[t] * (1.0 - np.sign(x_shares) * (self.half_spread + self.slippage))

                    exit_comm = (abs(y_shares) + abs(x_shares)) * self.commission_per_share
                    exit_slip = (abs(y_shares) * y[t] + abs(x_shares) * x[t]) * (self.half_spread + self.slippage)

                    cost_t += (exit_comm + exit_slip)
                    accum_commissions += exit_comm
                    accum_slippage += exit_slip
                    total_commissions_all += exit_comm
                    total_slippage_all += exit_slip

                    # Record round-trip trade
                    trade_counter += 1
                    gross_pnl = y_shares * (y[t] - trade_entry_y) + x_shares * (x[t] - trade_entry_x)
                    net_pnl = gross_pnl - (accum_commissions + accum_slippage + accum_borrow)
                    invested = abs(trade_entry_y * y_shares) + abs(trade_entry_x * x_shares)
                    ret_pct = (net_pnl / invested * 100.0) if invested > 0 else 0.0

                    reason = "TAKE_PROFIT" if target_pos == 0 else "FLIP"

                    trades.append(TradeRecord(
                        trade_id=trade_counter,
                        direction=trade_direction,
                        entry_index=trade_entry_idx,
                        exit_index=t,
                        duration_bars=t - trade_entry_idx,
                        y_entry_price=trade_entry_y,
                        y_exit_price=y[t],
                        x_entry_price=trade_entry_x,
                        x_exit_price=x[t],
                        y_shares=y_shares,
                        x_shares=x_shares,
                        hedge_ratio=betas[trade_entry_idx],
                        gross_pnl=float(gross_pnl),
                        commissions=float(accum_commissions),
                        slippage_cost=float(accum_slippage),
                        borrow_fees=float(accum_borrow),
                        net_pnl=float(net_pnl),
                        return_pct=float(ret_pct),
                        exit_reason=reason
                    ))

                    y_shares = 0.0
                    x_shares = 0.0
                    accum_commissions = 0.0
                    accum_slippage = 0.0
                    accum_borrow = 0.0

                # Open new position
                if target_pos != 0:
                    current_beta = max(abs(betas[t]), 0.01)
                    alloc_capital = prior_equity * self.allocation_pct

                    # Dollar-neutral allocation: Half capital on Y, half on X
                    leg_capital = alloc_capital / 2.0

                    # If target_pos == +1: Long Y, Short X
                    # If target_pos == -1: Short Y, Long X
                    if target_pos == 1:
                        raw_y_shares = leg_capital / y[t]
                        raw_x_shares = -(leg_capital / x[t])
                        trade_direction = "LONG_SPREAD"
                    else:
                        raw_y_shares = -(leg_capital / y[t])
                        raw_x_shares = leg_capital / x[t]
                        trade_direction = "SHORT_SPREAD"

                    # Entry execution cost with spread crossing
                    entry_comm = (abs(raw_y_shares) + abs(raw_x_shares)) * self.commission_per_share
                    entry_slip = (abs(raw_y_shares) * y[t] + abs(raw_x_shares) * x[t]) * (self.half_spread + self.slippage)

                    cost_t += (entry_comm + entry_slip)
                    accum_commissions += entry_comm
                    accum_slippage += entry_slip
                    total_commissions_all += entry_comm
                    total_slippage_all += entry_slip

                    y_shares = raw_y_shares
                    x_shares = raw_x_shares
                    trade_entry_idx = t
                    trade_entry_y = y[t]
                    trade_entry_x = x[t]

                current_pos = target_pos

            # Net daily PnL
            daily_net_pnl = pnl_t - cost_t - borrow_fee_t
            daily_pnl[t] = daily_net_pnl
            new_equity = max(prior_equity + daily_net_pnl, 10.0)
            equity[t] = new_equity
            returns[t] = (new_equity - prior_equity) / prior_equity

        # Close open position at end of backtest if present
        if current_pos != 0:
            final_t = n - 1
            exit_comm = (abs(y_shares) + abs(x_shares)) * self.commission_per_share
            exit_slip = (abs(y_shares) * y[final_t] + abs(x_shares) * x[final_t]) * (self.half_spread + self.slippage)
            total_commissions_all += exit_comm
            total_slippage_all += exit_slip
            accum_commissions += exit_comm
            accum_slippage += exit_slip

            gross_pnl = y_shares * (y[final_t] - trade_entry_y) + x_shares * (x[final_t] - trade_entry_x)
            net_pnl = gross_pnl - (accum_commissions + accum_slippage + accum_borrow)
            invested = abs(trade_entry_y * y_shares) + abs(trade_entry_x * x_shares)
            ret_pct = (net_pnl / invested * 100.0) if invested > 0 else 0.0

            trades.append(TradeRecord(
                trade_id=trade_counter + 1,
                direction=trade_direction,
                entry_index=trade_entry_idx,
                exit_index=final_t,
                duration_bars=final_t - trade_entry_idx,
                y_entry_price=trade_entry_y,
                y_exit_price=y[final_t],
                x_entry_price=trade_entry_x,
                x_exit_price=x[final_t],
                y_shares=y_shares,
                x_shares=x_shares,
                hedge_ratio=betas[trade_entry_idx],
                gross_pnl=float(gross_pnl),
                commissions=float(accum_commissions),
                slippage_cost=float(accum_slippage),
                borrow_fees=float(accum_borrow),
                net_pnl=float(net_pnl),
                return_pct=float(ret_pct),
                exit_reason="END_OF_SERIES"
            ))

        total_net = float(equity[-1] - self.initial_capital)
        total_ret = float((equity[-1] / self.initial_capital - 1.0) * 100.0)

        return BacktestResult(
            initial_capital=self.initial_capital,
            final_equity=float(equity[-1]),
            total_net_pnl=total_net,
            total_return_pct=total_ret,
            equity_curve=equity,
            returns=returns,
            daily_pnl=daily_pnl,
            positions=pos,
            trades=trades,
            total_commissions=float(total_commissions_all),
            total_slippage=float(total_slippage_all),
            total_borrow_fees=float(total_borrow_all),
            dates=dates
        )
