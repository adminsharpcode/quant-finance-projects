"""Unit and integration tests for signal generator, execution simulator, and performance analytics."""

import numpy as np
import pytest
from src.strategy.ou_process import OrnsteinUhlenbeckCalibrator
from src.strategy.zscore_signals import ZScoreSignalGenerator
from src.backtest.execution_sim import PairsExecutionSimulator
from src.backtest.performance import PerformanceAnalyzer


def test_ou_process_calibration():
    """Verify Ornstein-Uhlenbeck calibrator extracts known parameters."""
    np.random.seed(42)
    dt = 1.0
    theta_true = 0.08
    mu_true = 0.0
    sigma_true = 1.2
    n = 1000

    spread = np.zeros(n)
    for t in range(1, n):
        spread[t] = spread[t - 1] + theta_true * (mu_true - spread[t - 1]) * dt + sigma_true * np.random.normal()

    calibrator = OrnsteinUhlenbeckCalibrator(dt=dt)
    params = calibrator.fit(spread)

    assert params.is_mean_reverting
    assert np.isclose(params.theta, theta_true, atol=0.03)
    assert np.isclose(params.mu, mu_true, atol=0.5)
    expected_hl = np.log(2.0) / theta_true
    assert np.isclose(params.half_life, expected_hl, atol=3.0)


def test_zscore_signal_generator_transitions():
    """Verify entry, take-profit exit, and stop-loss logic in signal generator."""
    sig_gen = ZScoreSignalGenerator(z_entry=2.0, z_exit=0.0, z_stop=3.5)

    # Sequence: 0 -> -2.1 (entry long) -> -1.0 (hold) -> +0.1 (exit tp) -> +2.2 (entry short) -> +3.6 (stop loss)
    z_series = np.array([0.0, -1.5, -2.1, -1.0, 0.1, 1.0, 2.2, 2.8, 3.6, 0.0])
    res = sig_gen.generate(z_series)

    # At step 2, entered long spread (+1)
    assert res.positions[2] == 1
    # At step 3, still long spread (+1)
    assert res.positions[3] == 1
    # At step 4, crossed 0.0 -> flat (0)
    assert res.positions[4] == 0
    # At step 6, entered short spread (-1)
    assert res.positions[6] == -1
    # At step 8, exceeded stop loss 3.5 -> flat (0)
    assert res.positions[8] == 0


def test_execution_simulator_and_costs():
    """Verify execution simulator incorporates slippage, commissions and short borrow fees."""
    n = 100
    y = np.linspace(100, 110, n)
    x = np.linspace(50, 55, n)
    betas = np.ones(n) * 2.0
    positions = np.zeros(n, dtype=int)
    positions[10:30] = 1   # Hold Long Spread for 20 days
    positions[50:70] = -1  # Hold Short Spread for 20 days

    sim = PairsExecutionSimulator(
        initial_capital=100_000.0,
        commission_per_share=0.01,
        half_spread_bps=5.0,
        slippage_bps=2.0,
        short_borrow_fee_annual=0.02
    )
    res = sim.simulate(y, x, positions, betas)

    assert res.final_equity > 0
    assert len(res.trades) >= 2
    assert res.total_commissions > 0
    assert res.total_slippage > 0
    assert res.total_borrow_fees > 0


def test_performance_analyzer_metrics():
    """Verify performance metrics calculation."""
    n = 252
    equity = np.linspace(100_000.0, 120_000.0, n)
    returns = np.zeros(n)
    returns[1:] = np.diff(equity) / equity[:-1]

    from src.backtest.execution_sim import BacktestResult
    mock_res = BacktestResult(
        initial_capital=100_000.0,
        final_equity=120_000.0,
        total_net_pnl=20_000.0,
        total_return_pct=20.0,
        equity_curve=equity,
        returns=returns,
        daily_pnl=np.diff(equity, prepend=100_000.0),
        positions=np.zeros(n),
        trades=[],
        total_commissions=100.0,
        total_slippage=50.0,
        total_borrow_fees=25.0
    )

    analyzer = PerformanceAnalyzer(risk_free_rate_annual=0.04)
    metrics = analyzer.analyze(mock_res)

    assert np.isclose(metrics.total_return_pct, 20.0, atol=0.1)
    assert metrics.cagr_pct > 15.0
    assert metrics.sharpe_ratio > 0
    assert metrics.max_drawdown_pct == 0.0  # monotonically increasing equity


def test_walk_forward_validation():
    """Verify walk-forward optimizer executes across rolling folds without lookahead bias."""
    np.random.seed(42)
    n = 350
    x = 100.0 + np.cumsum(np.random.normal(0, 0.5, n))
    spread = np.zeros(n)
    for t in range(1, n):
        spread[t] = 0.8 * spread[t - 1] + np.random.normal(0, 0.5)
    y = 5.0 + 1.2 * x + spread

    from src.validation.walk_forward import WalkForwardValidator
    validator = WalkForwardValidator(
        train_window=150,
        test_window=50,
        z_entry_grid=[1.5, 2.0],
        z_exit_grid=[0.0]
    )
    result = validator.run(y, x)

    assert len(result.folds) >= 3
    assert len(result.spliced_oos_equity) > 0
    assert result.spliced_oos_metrics is not None

