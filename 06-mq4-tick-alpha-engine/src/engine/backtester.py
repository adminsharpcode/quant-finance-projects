"""
Event-Driven High-Speed Tick Backtester
----------------------------------------
High-performance vectorized tick-by-tick simulation on real broker feeds.
Models spread crossing, slippage, round-turn commissions, and returns
comprehensive performance metrics.
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Any
from .execution import ExecutionEngine, OrderSide, ActivePosition, TradeRecord
from .strategy import InstitutionalAlphaStrategy


class BacktestMetrics:
    def __init__(
        self,
        initial_capital: float,
        final_equity: float,
        trades: List[TradeRecord],
        equity_curve: pd.Series
    ):
        self.initial_capital = initial_capital
        self.final_equity = final_equity
        self.total_net_pnl = final_equity - initial_capital
        self.return_pct = (self.total_net_pnl / initial_capital) * 100.0
        self.trades = trades
        self.equity_curve = equity_curve

        self.total_trades = len(trades)
        wins = [t.net_pnl for t in trades if t.net_pnl > 0]
        losses = [abs(t.net_pnl) for t in trades if t.net_pnl < 0]

        self.win_count = len(wins)
        self.loss_count = len(losses)
        self.win_rate = (self.win_count / self.total_trades * 100.0) if self.total_trades > 0 else 0.0

        self.gross_profit = sum(wins)
        self.gross_loss = sum(losses)
        self.profit_factor = (self.gross_profit / self.gross_loss) if self.gross_loss > 0 else float('inf')

        self.avg_win = float(np.mean(wins)) if wins else 0.0
        self.avg_loss = float(np.mean(losses)) if losses else 0.0
        self.payoff_ratio = (self.avg_win / self.avg_loss) if self.avg_loss > 0 else float('inf')
        self.expectancy = (self.total_net_pnl / self.total_trades) if self.total_trades > 0 else 0.0

        # Drawdown calculation
        roll_max = equity_curve.cummax()
        drawdowns = (roll_max - equity_curve) / np.maximum(1.0, roll_max)
        self.max_drawdown_pct = float(drawdowns.max() * 100.0)
        self.max_drawdown_dollars = float((roll_max - equity_curve).max())

        # Returns and Sharpe
        trade_returns = np.array([t.net_pnl / initial_capital for t in trades]) if trades else np.array([0.0])
        std = np.std(trade_returns)
        mean_ret = np.mean(trade_returns)
        self.sharpe_ratio = float((mean_ret / std) * np.sqrt(252 * 5)) if std > 1e-9 else 0.0

        downside = trade_returns[trade_returns < 0]
        downside_std = np.std(downside) if len(downside) > 1 else std
        self.sortino_ratio = float((mean_ret / downside_std) * np.sqrt(252 * 5)) if downside_std > 1e-9 else 0.0

        self.calmar_ratio = float(self.return_pct / max(0.01, self.max_drawdown_pct))

    def to_dict(self) -> Dict[str, Any]:
        return {
            "initial_capital": round(float(self.initial_capital), 2),
            "final_equity": round(float(self.final_equity), 2),
            "total_net_pnl": round(float(self.total_net_pnl), 2),
            "return_pct": round(float(self.return_pct), 2),
            "total_trades": self.total_trades,
            "win_rate_pct": round(float(self.win_rate), 2),
            "profit_factor": round(float(self.profit_factor), 2) if self.profit_factor != float('inf') else 99.0,
            "sharpe_ratio": round(float(self.sharpe_ratio), 2),
            "sortino_ratio": round(float(self.sortino_ratio), 2),
            "calmar_ratio": round(float(self.calmar_ratio), 2),
            "max_drawdown_pct": round(float(self.max_drawdown_pct), 2),
            "max_drawdown_dollars": round(float(self.max_drawdown_dollars), 2),
            "expectancy_per_trade": round(float(self.expectancy), 2),
            "payoff_ratio": round(float(self.payoff_ratio), 2) if self.payoff_ratio != float('inf') else 99.0,
            "avg_win": round(float(self.avg_win), 2),
            "avg_loss": round(float(self.avg_loss), 2)
        }


class TickBacktester:
    def __init__(
        self,
        strategy: InstitutionalAlphaStrategy,
        initial_capital: float = 10000.0,
        base_slippage_pips: float = 0.1,
        pip_size: float = 0.0001,
        commission_per_lot: float = 5.0,
        lot_size: float = 100000.0
    ):
        self.strategy = strategy
        self.initial_capital = initial_capital
        self.execution = ExecutionEngine(
            base_slippage_pips=base_slippage_pips,
            pip_size=pip_size,
            commission_per_lot_round_turn=commission_per_lot,
            lot_size=lot_size
        )
        self.pip_size = pip_size
        self.lot_size = lot_size

    def run(self, df_ticks: pd.DataFrame) -> BacktestMetrics:
        """Runs fast tick-by-tick simulation."""
        df = self.strategy.compute_indicators(df_ticks)

        current_equity = self.initial_capital
        active_position: Optional[ActivePosition] = None
        closed_trades: List[TradeRecord] = []
        equity_records: List[float] = [current_equity]

        warmup_period = max(self.strategy.window, self.strategy.slow_ma) + 5

        mids = df['mid'].to_numpy()
        bids = df['bid'].to_numpy()
        asks = df['ask'].to_numpy()
        spreads = df['spread'].to_numpy()
        timestamps = df['timestamp_msc'].to_numpy()
        means = df['mean'].to_numpy()
        stds = df['std'].to_numpy()
        upper_bands = df['upper_band'].to_numpy()
        lower_bands = df['lower_band'].to_numpy()
        fast_mas = df['fast_ma'].to_numpy()
        slow_mas = df['slow_ma'].to_numpy()
        donch_highs = df['donch_high'].to_numpy()
        donch_lows = df['donch_low'].to_numpy()
        trend_strengths = df['trend_strength'].to_numpy()

        n = len(df)
        max_spr = self.strategy.max_spread
        trend_th = self.strategy.trend_threshold

        for i in range(warmup_period, n):
            curr_mid = mids[i]
            curr_bid = bids[i]
            curr_ask = asks[i]
            curr_spr = spreads[i]
            curr_time = timestamps[i]

            # 1. Evaluate Stops on Active Position
            if active_position is not None:
                closed = self.execution.check_stops(active_position, curr_bid, curr_ask, curr_time)
                if closed is not None:
                    closed_trades.append(closed)
                    current_equity += closed.net_pnl
                    active_position = None

            # 2. Check Signal if Flat and Spread within threshold
            if active_position is None and curr_spr <= max_spr and stds[i] > 1e-7:
                signal = None
                is_trend = False

                # Check Trend vs Mean Reversion Regime
                if trend_strengths[i] > trend_th:
                    is_trend = True
                    if fast_mas[i] > slow_mas[i] and curr_mid > donch_highs[i - 1]:
                        signal = OrderSide.BUY
                    elif fast_mas[i] < slow_mas[i] and curr_mid < donch_lows[i - 1]:
                        signal = OrderSide.SELL
                else:
                    if curr_mid < lower_bands[i]:
                        signal = OrderSide.BUY
                    elif curr_mid > upper_bands[i]:
                        signal = OrderSide.SELL

                if signal is not None:
                    entry_p = curr_ask if signal == OrderSide.BUY else curr_bid
                    sl, tp, lots = self.strategy.calculate_trade_levels(
                        side=signal,
                        entry_price=entry_p,
                        account_equity=current_equity,
                        lot_size=self.lot_size,
                        is_trend_trade=is_trend
                    )
                    active_position = self.execution.open_position(
                        side=signal,
                        lots=lots,
                        bid=curr_bid,
                        ask=curr_ask,
                        timestamp_msc=curr_time,
                        stop_loss=sl,
                        take_profit=tp
                    )

            # Record floating equity
            floating_pnl = 0.0
            if active_position is not None:
                if active_position.side == OrderSide.BUY:
                    floating_pnl = (curr_bid - active_position.open_price) * active_position.units
                else:
                    floating_pnl = (active_position.open_price - curr_ask) * active_position.units

            equity_records.append(current_equity + floating_pnl)

        # Close any lingering open position at end
        if active_position is not None:
            closed = self.execution.close_position(active_position, bids[-1], asks[-1], timestamps[-1], "END_OF_SERIES")
            closed_trades.append(closed)
            current_equity += closed.net_pnl
            equity_records[-1] = current_equity

        equity_series = pd.Series(equity_records)
        return BacktestMetrics(
            initial_capital=self.initial_capital,
            final_equity=current_equity,
            trades=closed_trades,
            equity_curve=equity_series
        )
