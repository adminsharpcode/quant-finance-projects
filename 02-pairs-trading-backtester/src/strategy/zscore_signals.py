"""Dynamic Z-Score Signal Generator.

Transforms standardized spread z-scores into position regimes (+1, -1, 0)
using dual-threshold entry, mean-reversion exit, and divergence stop-loss rules.
"""

from dataclasses import dataclass
from enum import IntEnum
from typing import Optional, Tuple
import numpy as np


class SignalType(IntEnum):
    """Trading action signal type."""
    EXIT_ALL = 0
    LONG_SPREAD = 1       # Long Y, Short beta * X
    SHORT_SPREAD = -1     # Short Y, Long beta * X


@dataclass
class SignalResult:
    """Container for signal generation outputs."""
    positions: np.ndarray        # Position state array: +1 (Long), -1 (Short), 0 (Flat)
    trade_events: list           # List of discrete execution event dicts
    entries_long: np.ndarray     # Boolean mask of long entries
    entries_short: np.ndarray    # Boolean mask of short entries
    exits_take_profit: np.ndarray# Boolean mask of profit-taking exits
    exits_stop_loss: np.ndarray  # Boolean mask of stop-loss exits


class ZScoreSignalGenerator:
    """Generates pairs trading positions from a standardized z-score trajectory."""

    def __init__(
        self,
        z_entry: float = 2.0,
        z_exit: float = 0.0,
        z_stop: float = 3.5,
        max_holding_period: Optional[int] = None
    ):
        """Initialize signal thresholds.

        Args:
            z_entry: Absolute z-score required to initiate a position (e.g. 2.0).
            z_exit: Absolute z-score threshold for taking profit on reversion (e.g. 0.0).
            z_stop: Absolute z-score threshold for hard stop-loss on regime divergence (e.g. 3.5).
            max_holding_period: Optional maximum holding days before forcing an exit.
        """
        if z_entry <= z_exit:
            raise ValueError(f"z_entry ({z_entry}) must be strictly greater than z_exit ({z_exit})")
        if z_stop <= z_entry:
            raise ValueError(f"z_stop ({z_stop}) must be strictly greater than z_entry ({z_entry})")

        self.z_entry = z_entry
        self.z_exit = z_exit
        self.z_stop = z_stop
        self.max_holding_period = max_holding_period

    def generate(self, zscores: np.ndarray) -> SignalResult:
        """Generate time series of position states and discrete trading events.

        Args:
            zscores: 1D array of standardized spread z-scores.

        Returns:
            SignalResult containing positions and boolean event masks.
        """
        z = np.asarray(zscores, dtype=float)
        n = len(z)

        positions = np.zeros(n, dtype=int)
        entries_long = np.zeros(n, dtype=bool)
        entries_short = np.zeros(n, dtype=bool)
        exits_tp = np.zeros(n, dtype=bool)
        exits_sl = np.zeros(n, dtype=bool)
        trade_events = []

        current_pos = 0
        bars_in_trade = 0
        entry_idx = 0

        for t in range(n):
            z_t = z[t]

            # Inactive or NaN check
            if np.isnan(z_t):
                positions[t] = 0
                current_pos = 0
                bars_in_trade = 0
                continue

            if current_pos == 0:
                # Flat state: scan for entry
                if z_t <= -self.z_entry:
                    current_pos = 1  # Long Spread
                    entries_long[t] = True
                    entry_idx = t
                    bars_in_trade = 1
                    trade_events.append({
                        "step": t,
                        "type": "ENTRY_LONG",
                        "zscore": float(z_t),
                        "position": 1
                    })
                elif z_t >= self.z_entry:
                    current_pos = -1  # Short Spread
                    entries_short[t] = True
                    entry_idx = t
                    bars_in_trade = 1
                    trade_events.append({
                        "step": t,
                        "type": "ENTRY_SHORT",
                        "zscore": float(z_t),
                        "position": -1
                    })
            elif current_pos == 1:
                bars_in_trade += 1
                # Long Spread state: check stop-loss first
                if z_t <= -self.z_stop:
                    current_pos = 0
                    exits_sl[t] = True
                    trade_events.append({
                        "step": t,
                        "type": "EXIT_STOP_LOSS",
                        "zscore": float(z_t),
                        "holding_period": bars_in_trade,
                        "position": 0
                    })
                    bars_in_trade = 0
                elif z_t >= -self.z_exit:
                    # Profit-taking exit (reverted back towards mean)
                    current_pos = 0
                    exits_tp[t] = True
                    trade_events.append({
                        "step": t,
                        "type": "EXIT_TAKE_PROFIT",
                        "zscore": float(z_t),
                        "holding_period": bars_in_trade,
                        "position": 0
                    })
                    bars_in_trade = 0
                elif self.max_holding_period is not None and bars_in_trade >= self.max_holding_period:
                    # Time stop
                    current_pos = 0
                    exits_sl[t] = True
                    trade_events.append({
                        "step": t,
                        "type": "EXIT_TIME_STOP",
                        "zscore": float(z_t),
                        "holding_period": bars_in_trade,
                        "position": 0
                    })
                    bars_in_trade = 0
            elif current_pos == -1:
                bars_in_trade += 1
                # Short Spread state: check stop-loss first
                if z_t >= self.z_stop:
                    current_pos = 0
                    exits_sl[t] = True
                    trade_events.append({
                        "step": t,
                        "type": "EXIT_STOP_LOSS",
                        "zscore": float(z_t),
                        "holding_period": bars_in_trade,
                        "position": 0
                    })
                    bars_in_trade = 0
                elif z_t <= self.z_exit:
                    # Profit-taking exit (reverted back towards mean)
                    current_pos = 0
                    exits_tp[t] = True
                    trade_events.append({
                        "step": t,
                        "type": "EXIT_TAKE_PROFIT",
                        "zscore": float(z_t),
                        "holding_period": bars_in_trade,
                        "position": 0
                    })
                    bars_in_trade = 0
                elif self.max_holding_period is not None and bars_in_trade >= self.max_holding_period:
                    # Time stop
                    current_pos = 0
                    exits_sl[t] = True
                    trade_events.append({
                        "step": t,
                        "type": "EXIT_TIME_STOP",
                        "zscore": float(z_t),
                        "holding_period": bars_in_trade,
                        "position": 0
                    })
                    bars_in_trade = 0

            positions[t] = current_pos

        return SignalResult(
            positions=positions,
            trade_events=trade_events,
            entries_long=entries_long,
            entries_short=entries_short,
            exits_take_profit=exits_tp,
            exits_stop_loss=exits_sl
        )
