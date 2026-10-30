# 6 Production Quant Finance Projects to Stand Out in 2026

[![Quant Portfolio CI](https://github.com/adminsharpcode/quant-finance-projects/actions/workflows/ci.yml/badge.svg)](https://github.com/adminsharpcode/quant-finance-projects/actions/workflows/ci.yml)
![Python](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-3776AB?logo=python&logoColor=white)
![Testing](https://img.shields.io/badge/tested%20with-pytest-0A9EDC?logo=pytest&logoColor=white)
![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)
![Deployment](https://img.shields.io/badge/deployed-Vercel-000000?logo=vercel&logoColor=white)

An institutional portfolio of 6 quantitative engineering systems built from first principles. Each project includes complete mathematical derivations, modular production code, calibration against real exchange data (CME, COMEX, NASDAQ, Real Broker Ticks), and deployment-ready architecture for Vercel.

---

## 🗺️ Master Curriculum & Series Roadmap

| # | Project | Focus & Core Mathematics | Exchange / Data | Status | Vercel Deployment |
|---|---|---|---|---|---|
| **01** | **[Options Pricing, Greek Engine & Volatility Surfaces](./01-options-pricing-and-greeks)** | Black-76, CRR American Lattice, Antithetic Monte Carlo, SVI/SABR Calibration, Higher-Order Greeks (Vanna, Volga), Relative-Value Volatility Arbitrage | COMEX Gold (`GC`), CME Crude (`CL`) | 🟢 **Complete** | [🌐 **Live on Vercel**](https://web-five-pied-83.vercel.app) |
| **02** | **[Pairs Trading Backtester](./02-pairs-trading-backtester)** | Engle-Granger & Johansen Cointegration, Dynamic Kalman Filter Beta Tracking, Ornstein-Uhlenbeck Mean Reversion, Slippage & Borrow Fees, Out-of-Sample Walk-Forward Validation | US Equities & Commodity Spreads | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-pairs-trading-engine.vercel.app) |
| **03** | **[Limit Order Book (LOB) Simulator](./03-limit-order-book-simulator)** | Event-Driven FIFO Matching Engine, Avellaneda-Stoikov Market Making Reservation Pricing, Inventory Penalty $\gamma$, Order Flow Imbalance (OFI), Toxic Flow VPIN | CME Globex, NASDAQ ITCH | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-limit-order-book-simulator.vercel.app) |
| **04** | **[Machine Learning Alpha Signal Engine](./04-ml-alpha-signal)** | De Prado PurgedGroupTimeSeriesSplit + Embargo (Zero Leakage), LightGBM Return Prediction, Garman-Klass Volatility, Rank IC & Turnover Attribution | Cross-Sectional Equities | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-ml-alpha-signal-engine.vercel.app) |
| **05** | **[Almgren-Chriss Optimal Execution Engine](./05-optimal-execution-engine)** | Almgren-Chriss (2000) Liquidation Frontier, Linear & Non-Linear Square-Root Market Impact, Implementation Shortfall (IS), TWAP & VWAP Benchmarking | US Equities & Block Liquidation | 🟢 **Complete** | [🌐 **Dedicated Repo**](https://github.com/adminsharpcode/optimal-execution-engine) |
| **06** | **[MQ4 Alpha Miner & Real Tick Engine](./06-mq4-tick-alpha-engine)** | Static Feature Extraction from 1,297 MQL4 Codes, Multi-Regime Volatility Exhaustion & Trend Breakout, Real Broker Millisecond Ticks, 5,000-Run Monte Carlo Simulation, Production MQL4 EA | Live Broker Ticks (`EURUSD`, `GBPUSD`, `XAUUSD`) | 🟢 **Complete** | [📘 **Full Project Documentation**](./06-mq4-tick-alpha-engine) |

---

## 🏛️ What Separates This Portfolio (2026 Hedge Fund & Prop Standards)
- **Zero Black Boxes**: Every pricing equation, tree recursion, and Kalman update is derived from stochastic calculus and linear algebra first principles.
- **Microstructure Realism**: Accounts for American early-exercise on futures, transaction fees, bid-ask half-spread crossing, and borrow costs.
- **Production Web Deployment**: Includes interactive web applications deployable in 1-click via Vercel with zero cold-start latency.
- **Statistical Rigor**: 100% automated test coverage with verified put-call parity, martingale pricing conditions, and no lookahead bias.
- **CI / Automated Test Pipeline**: Integrated GitHub Actions CI validating tests across Python 3.10 and 3.11.

---

## ⚡ Quick Start

```bash
# Clone the repository
git clone https://github.com/adminsharpcode/quant-finance-projects.git
cd quant-finance-projects

# Run test suites across engines
pytest 01-options-pricing-and-greeks/tests
pytest 03-limit-order-book-simulator/tests
pytest 06-mq4-tick-alpha-engine/tests

# Run the 1,297 MQ4 Alpha Miner & 5,000 Monte Carlo Engine
python 06-mq4-tick-alpha-engine/run_pipeline.py
```

---

## 📄 License

Distributed under the [MIT License](./LICENSE). See `LICENSE` for more information.
