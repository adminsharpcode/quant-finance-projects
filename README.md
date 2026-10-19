# 4 Production Quant Finance Projects to Stand Out in 2026

An institutional portfolio of 4 quantitative engineering systems built from first principles. Each project includes complete mathematical derivations, modular production code, calibration against real exchange data (CME, COMEX, NASDAQ), and deployment-ready architecture for Vercel.

---

## 🗺️ Master Curriculum & Series Roadmap

| # | Project | Focus & Core Mathematics | Exchange / Data | Status | Vercel Deployment |
|---|---|---|---|---|---|
| **01** | **[Options Pricing, Greek Engine & Volatility Surfaces](./01-options-pricing-and-greeks)** | Black-76, CRR American Lattice, Antithetic Monte Carlo, SVI/SABR Calibration, Higher-Order Greeks (Vanna, Volga), Relative-Value Volatility Arbitrage | COMEX Gold (`GC`), CME Crude (`CL`) | 🟢 **Complete** | [🌐 **Live on Vercel**](https://web-five-pied-83.vercel.app) |
| **02** | **[Pairs Trading Backtester](./02-pairs-trading-backtester)** | Engle-Granger & Johansen Cointegration, Dynamic Kalman Filter Beta Tracking, Ornstein-Uhlenbeck Mean Reversion, Slippage & Borrow Fees, Out-of-Sample Walk-Forward Validation | US Equities & Commodity Spreads | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-pairs-trading-engine.vercel.app) |
| **03** | **[Limit Order Book (LOB) Simulator](./03-limit-order-book-simulator)** | Event-Driven FIFO Matching Engine, Avellaneda-Stoikov Market Making Reservation Pricing, Inventory Penalty $\gamma$, Order Flow Imbalance (OFI), Toxic Flow VPIN | CME Globex, NASDAQ ITCH | 🟢 **Complete** | [🌐 **Live on Vercel**](https://quant-limit-order-book-simulator.vercel.app) |
| **04** | **[Machine Learning Alpha Signal Engine](./04-ml-alpha-signal)** | De Prado PurgedGroupTimeSeriesSplit + Embargo (Zero Leakage), LightGBM Return Prediction, Garman-Klass Volatility, Rank IC & Turnover Attribution | Cross-Sectional Equities | ⏳ *Day 4* | *Configured* |

---

## 🏛️ What Separates This Portfolio (2026 Hedge Fund & Prop Standards)
- **Zero Black Boxes**: Every pricing equation, tree recursion, and Kalman update is derived from stochastic calculus and linear algebra first principles.
- **Microstructure Realism**: Accounts for American early-exercise on futures, transaction fees, bid-ask half-spread crossing, and borrow costs.
- **Production Web Deployment**: Includes interactive web applications deployable in 1-click via Vercel with zero cold-start latency.
- **Statistical Rigor**: 100% automated test coverage with verified put-call parity, martingale pricing conditions, and no lookahead bias.
