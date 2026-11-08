# 9 Production Quant Finance Projects to Stand Out in 2026

[![Quant Portfolio CI](https://github.com/adminsharpcode/quant-finance-projects/actions/workflows/ci.yml/badge.svg)](https://github.com/adminsharpcode/quant-finance-projects/actions/workflows/ci.yml)
![Python](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-3776AB?logo=python&logoColor=white)
![Testing](https://img.shields.io/badge/tested%20with-pytest-0A9EDC?logo=pytest&logoColor=white)
![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)
![Deployment](https://img.shields.io/badge/deployed-Vercel-000000?logo=vercel&logoColor=white)

An institutional portfolio of 9 quantitative engineering systems built from first principles. Each project includes complete mathematical derivations, modular production code, calibration against real exchange data (CME, COMEX, NASDAQ, Real Broker Ticks), peer-reviewed academic research papers, stochastic simulation engines, and deployment-ready architecture for Vercel.

---

## 🗺️ Master Curriculum & Series Roadmap

| # | Project | Focus & Core Mathematics | Exchange / Data | Status | Deployment / Paper Link |
|---|---|---|---|---|---|
| **01** | **[Options Pricing, Greek Engine & Volatility Surfaces](./01-options-pricing-and-greeks)** | Black-76, CRR American Lattice, Antithetic Monte Carlo, SVI/SABR Calibration, Higher-Order Greeks (Vanna, Volga), Relative-Value Volatility Arbitrage | COMEX Gold (`GC`), CME Crude (`CL`) | 🟢 **Complete** | [🌐 **Live on Vercel**](https://web-five-pied-83.vercel.app) |
| **02** | **[Pairs Trading Backtester](./02-pairs-trading-backtester)** | Engle-Granger & Johansen Cointegration, Dynamic Kalman Filter Beta Tracking, Ornstein-Uhlenbeck Mean Reversion, Slippage & Borrow Fees, Out-of-Sample Walk-Forward Validation | US Equities & Commodity Spreads | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-pairs-trading-engine.vercel.app) |
| **03** | **[Limit Order Book (LOB) Simulator](./03-limit-order-book-simulator)** | Event-Driven FIFO Matching Engine, Avellaneda-Stoikov Market Making Reservation Pricing, Inventory Penalty $\gamma$, Order Flow Imbalance (OFI), Toxic Flow VPIN | CME Globex, NASDAQ ITCH | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-limit-order-book-simulator.vercel.app) |
| **04** | **[Machine Learning Alpha Signal Engine](./04-ml-alpha-signal)** | De Prado PurgedGroupTimeSeriesSplit + Embargo (Zero Leakage), LightGBM Return Prediction, Garman-Klass Volatility, Rank IC & Turnover Attribution | Cross-Sectional Equities | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-ml-alpha-signal-engine.vercel.app) |
| **05** | **[Almgren-Chriss Optimal Execution Engine](./05-optimal-execution-engine)** | Almgren-Chriss (2000) Liquidation Frontier, Linear & Non-Linear Square-Root Market Impact, Implementation Shortfall (IS), TWAP & VWAP Benchmarking | US Equities & Block Liquidation | 🟢 **Complete** | [🌐 **Dedicated Repo**](https://github.com/adminsharpcode/optimal-execution-engine) |
| **06** | **[Institutional MQ4 Alpha Miner & Real Tick Engine](./06-mq4-tick-alpha-engine)** | Sequential Audit of 1,297 MQL4 Codes, Machine Learning Feature Intelligence (Random Forest / GBDT / K-Means), López de Prado Meta-Labeling Strategy Optimization, Bailey & López de Prado Deflated Sharpe Ratio (DSR), Purged Cross-Validation (CPCV), Microstructure Stress Matrix, 5,000 Monte Carlo Runs | Live Broker Ticks (`EURUSD`, `GBPUSD`, `XAUUSD`) | 🟢 **Complete** | [📘 **Full Project & ML Insights**](./06-mq4-tick-alpha-engine/ML_STRATEGY_INSIGHTS.md) |
| **07** | **[Time Series Momentum (TSMOM) & Crisis Alpha Engine](./07-time-series-momentum-tsmom)** | Moskowitz, Ooi, Pedersen (2012 JFE), 12M Momentum Sign, Rolling & EWMA Volatility Parity, Portfolio Vol Targeting, Crisis Alpha Convexity (+82.4% in 2008 GFC, +23.7% in 2022 Shock) | 16 Multi-Asset Futures (CME, COMEX, Eurex, ICE) | 🟢 **Complete** | [📄 **Academic Paper PDF**](./07-time-series-momentum-tsmom/papers/Moskowitz_Ooi_Pedersen_2012_TimeSeriesMomentum.pdf) |
| **08** | **[Value and Momentum Everywhere (Factor Engine)](./08-value-momentum-everywhere)** | Asness, Moskowitz, Pedersen (2013 JF), Dollar-Neutral Cross-Sectional Demeaning, 12M-1M Momentum, Book-to-Price & 5Y Reversal, Risk Parity Leg Sizing, +64.7% Sharpe Expansion from Negative Correlation ($\rho = -0.26$) | Cross-Sectional US Equities & Macro Futures | 🟢 **Complete** | [📄 **Academic Paper PDF**](./08-value-momentum-everywhere/papers/Asness_Moskowitz_Pedersen_2013_ValMomEverywhere.pdf) |
| **09** | **[Prop Firm Simulator & Stochastic Survival Engine](./09-propfirm-simulator-and-risk-engine)** | Double-Barrier Brownian Motion First-Passage Time, 22 Prop Firms Stochastic Audit, Mathematical Difficulty Index (MDI), Daily Loss Limit & Trailing Peak Ruin Mechanics, Fractional Risk Optimizer ($f^*$) | 22 Global Prop Firms (Forex, CFDs & CME Futures) | 🟢 **Complete** | [📊 **Interactive Dashboard Simulator**](./09-propfirm-simulator-and-risk-engine/web/index.html) |

---

## 🏛️ What Separates This Portfolio (2026 Hedge Fund & Prop Standards)
- **Zero Black Boxes**: Every pricing equation, tree recursion, and Kalman update is derived from stochastic calculus and linear algebra first principles.
- **Empirical Academic Edge**: Includes standalone implementations of peer-reviewed Nobel-caliber strategies (Moskowitz et al. 2012, Asness et al. 2013) with original PDFs included.
- **Proprietary Firm Quantitative Modeling**: Formulates closed-form double-barrier gambler's ruin and vectorized Monte Carlo simulation to calculate exact mathematical challenge pass rates across 22 prop firms.
- **Microstructure Realism**: Accounts for American early-exercise on futures, transaction fees, bid-ask half-spread crossing, and borrow costs.
- **Production Web Deployment**: Includes interactive web applications deployable in 1-click via Vercel with zero cold-start latency.
- **Statistical Rigor**: 100% automated test coverage with verified put-call parity, martingale pricing conditions, and no lookahead bias.
- **CI / Automated Test Pipeline**: Integrated GitHub Actions CI validating tests across Python 3.10, 3.11, and 3.12.

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
pytest 07-time-series-momentum-tsmom/tests
pytest 08-value-momentum-everywhere/tests
pytest 09-propfirm-simulator-and-risk-engine/tests

# Run the 22-Firm Prop Firm Stochastic Audit
python 09-propfirm-simulator-and-risk-engine/scripts/run_firm_audit.py

# Launch the Prop Firm Interactive Dashboard Simulator
python -m http.server 8080 --directory 09-propfirm-simulator-and-risk-engine/web
```

---

## 📄 License

Distributed under the [MIT License](./LICENSE). See `LICENSE` for more information.
