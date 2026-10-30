"""
Test Suite for MQ4 Alpha Engine
--------------------------------
Validates tick loading, execution models, strategy signal generation,
backtesting mathematical integrity, and Monte Carlo risk analytics.
"""

import os
import sys
import pytest
import pandas as pd
import numpy as np

# Ensure project root is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.engine.execution import ExecutionEngine, OrderSide, ActivePosition, TradeRecord
from src.engine.strategy import InstitutionalAlphaStrategy
from src.engine.backtester import TickBacktester, BacktestMetrics
from src.engine.monte_carlo import MonteCarloEngine


@pytest.fixture
def sample_tick_df():
    """Generates synthetic tick series for testing."""
    n = 200
    timestamps = [1770000000000 + i * 500 for i in range(n)]
    mid_prices = [1.1500 + 0.0001 * np.sin(i / 10.0) + (0.00002 * (i % 5)) for i in range(n)]
    bids = [round(m - 0.00005, 5) for m in mid_prices]
    asks = [round(m + 0.00005, 5) for m in mid_prices]
    spreads = [round(a - b, 5) for a, b in zip(asks, bids)]
    
    return pd.DataFrame({
        'timestamp_msc': timestamps,
        'bid': bids,
        'ask': asks,
        'mid': mid_prices,
        'spread': spreads
    })


def test_execution_engine_spread_and_commission():
    engine = ExecutionEngine(
        base_slippage_pips=0.1,
        pip_size=0.0001,
        commission_per_lot_round_turn=5.0,
        lot_size=100000.0
    )
    
    pos = engine.open_position(
        side=OrderSide.BUY,
        lots=1.0,
        bid=1.15000,
        ask=1.15010,
        timestamp_msc=1770000000000,
        stop_loss=1.14800,
        take_profit=1.15400
    )
    
    assert pos.open_price >= 1.15010  # Long enters on Ask + slippage
    assert pos.units == 100000.0
    
    # Close trade at higher bid
    trade = engine.close_position(
        pos=pos,
        bid=1.15200,
        ask=1.15210,
        timestamp_msc=1770000010000,
        exit_reason="MANUAL_CLOSE"
    )
    
    assert trade.commission == 5.0
    assert trade.gross_pnl > 0.0
    assert trade.net_pnl == pytest.approx(trade.gross_pnl - trade.commission, rel=1e-4)


def test_strategy_indicators(sample_tick_df):
    strat = InstitutionalAlphaStrategy(
        window=20,
        band_deviation=1.8,
        fast_ma_period=10,
        slow_ma_period=30,
        pip_size=0.0001
    )
    df_ind = strat.compute_indicators(sample_tick_df)
    
    assert 'mean' in df_ind.columns
    assert 'std' in df_ind.columns
    assert 'upper_band' in df_ind.columns
    assert 'lower_band' in df_ind.columns
    assert 'trend_strength' in df_ind.columns
    assert df_ind['upper_band'].iloc[25] > df_ind['lower_band'].iloc[25]


def test_backtest_accounting_integrity(sample_tick_df):
    strat = InstitutionalAlphaStrategy(
        window=20,
        band_deviation=1.5,
        sl_pips=5.0,
        tp_pips=10.0,
        max_spread_pips=2.0,
        pip_size=0.0001
    )
    bt = TickBacktester(strat, initial_capital=10000.0)
    metrics = bt.run(sample_tick_df)
    
    # Mathematical invariant: initial_capital + total_net_pnl == final_equity
    computed_equity = 10000.0 + sum(t.net_pnl for t in metrics.trades)
    assert metrics.final_equity == pytest.approx(computed_equity, abs=1e-2)
    assert metrics.max_drawdown_pct >= 0.0


def test_monte_carlo_resampling():
    sample_trades = [
        TradeRecord(1, OrderSide.BUY, 0, 1.10, 10, 1.11, 100000, 1.0, 100.0, 5.0, 2.0, 95.0, 0.95, 10.0, "TP"),
        TradeRecord(2, OrderSide.SELL, 10, 1.11, 20, 1.105, 100000, 1.0, 50.0, 5.0, 2.0, 45.0, 0.45, 10.0, "TP"),
        TradeRecord(3, OrderSide.BUY, 20, 1.105, 30, 1.102, 100000, 1.0, -30.0, 5.0, 2.0, -35.0, -0.35, 10.0, "SL")
    ]
    
    mc = MonteCarloEngine(
        trades=sample_trades,
        initial_capital=10000.0,
        num_simulations=500,
        ruin_drawdown_pct=30.0,
        random_seed=42
    )
    res = mc.run_simulation()
    
    assert res['num_simulations'] == 500
    assert 'probability_of_ruin_pct' in res
    assert 'final_equity' in res
    assert 'risk_metrics' in res
    assert res['final_equity']['p95_bullish'] >= res['final_equity']['p5_bearish']


def test_sequential_tester_rule_extraction():
    from src.engine.sequential_tester import SequentialMQ4Tester
    
    tick_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "real_ticks_gbpusd.csv")
    mq4_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "MQ4 Source Codes (1300+)")
    
    tester = SequentialMQ4Tester(mq4_dir, tick_path)
    
    sample_content = """
    // Sample EA
    extern double Lots = 0.2;
    extern double StopLoss = 25.0;
    extern double TakeProfit = 50.0;
    int start() {
        double rsi = iRSI(Symbol(), 0, 14, PRICE_CLOSE, 0);
        OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, Ask-StopLoss*Point, Ask+TakeProfit*Point);
        return(0);
    }
    """
    params = tester.extract_strategy_parameters(sample_content)
    assert params['has_ordersend'] is True
    assert params['sl_pips'] == 25.0
    assert params['tp_pips'] == 50.0
    assert params['lot_size'] == 0.2
    assert params['is_martingale'] is False
    assert params['risk_classification'] == 'ASYMMETRIC_POSITIVE_SKEW'


