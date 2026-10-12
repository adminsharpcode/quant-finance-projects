# Pairs Trading & Cointegration Backtesting Engine

[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![Status: Day 2 Blueprint](https://img.shields.io/badge/Status-Day%202%20Blueprint-orange.svg)]()
[![Method: Cointegration](https://img.shields.io/badge/Math-Johansen%20%7C%20Kalman%20Filter-purple.svg)]()

> **Quant Series Project 02**: Statistical arbitrage engine that identifies pairs of stationary linear combinations, estimates dynamic hedge ratios via state-space Kalman filtering, and validates profitability with realistic transaction costs and out-of-sample walk-forward testing.

---

## 🏛️ Project Architecture & Layout

```
02-pairs-trading-backtester/
├── README.md                          # Full mathematical specification & backtest analysis
├── requirements.txt                   # statsmodels, filterpy, scipy, pandas, vectorbt
├── docs/
│   └── cointegration_theory.md        # Engle-Granger vs Johansen, Ornstein-Uhlenbeck drift
├── data/
│   ├── equity_pairs_universe.csv      # Daily/minutely price series for pair candidates
│   └── commodity_spreads.csv          # Energy & metals crack spreads (WTI vs Brent, Gold vs Silver)
├── src/
│   ├── analysis/
│   │   ├── cadf_test.py               # Augmented Dickey-Fuller & Engle-Granger tests
│   │   └── johansen_test.py           # Vector Autoregression (VAR) & Johansen trace tests
│   ├── state_space/
│   │   └── kalman_filter.py           # Dynamic hedge ratio (beta) & intercept tracking
│   ├── strategy/
│   │   ├── ou_process.py              # Ornstein-Uhlenbeck parameter calibration (theta, mu, sigma)
│   │   └── zscore_signals.py          # Entry, exit, and stop-loss threshold generation
│   ├── backtest/
│   │   ├── execution_sim.py           # Slippage, bid-ask half spread crossing & borrow costs
│   │   └── performance.py             # Sharpe, Sortino, Max Drawdown, Calmar, PnL curve
│   └── validation/
│       └── walk_forward.py            # Rolling in-sample train vs out-of-sample test splits
├── scripts/
│   ├── run_pairs_backtest.py          # End-to-end backtest runner
│   └── plot_performance.py            # Cumulative returns, underwater drawdown, spread charts
└── tests/
    ├── test_cointegration.py
    ├── test_kalman.py
    └── test_backtest_engine.py
```

---

## 🎯 What Makes This Interview-Ready (2026 Standards)
1. **Dynamic Hedge Ratio via Kalman Filter**: Replaces static OLS with a continuous state-space Kalman filter tracking time-varying market beta:
   $$y_t = \alpha_t + \beta_t x_t + \epsilon_t, \quad \beta_t = \beta_{t-1} + \eta_t$$
2. **Ornstein-Uhlenbeck Mean-Reversion Calibration**: Estimates the half-life of mean reversion:
   $$dX_t = \theta (\mu - X_t) dt + \sigma dW_t \implies \tau_{1/2} = \frac{\ln 2}{\theta}$$
3. **Institutional Realism**: Includes borrow fees on short legs (1.5% annualized), transaction commissions ($0.005/share), and half-spread bid-ask crossing.
4. **Out-of-Sample Walk-Forward Testing**: Avoids the "fake backtest" trap by strictly tuning parameters on rolling in-sample windows and evaluating on unseen data.
