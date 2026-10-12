# Quant Finance Production Engineering Series

A collection of 4 production-grade quantitative finance systems engineered from first principles. Each project includes complete mathematical derivations, modular C++/Python implementations, calibration against real exchange data (CME, COMEX, CBOE), and actionable systematic alpha engines.

---

## 🗺️ Master Curriculum & Series Roadmap

| # | Project | Focus & Core Mathematics | Exchange / Data | Status |
|---|---|---|---|---|
| **01** | **[Options Pricing, Greek Engine & Volatility Surface Calibration](./01-options-pricing-and-greeks)** | Black-76, CRR American Trees, Monte Carlo Variance Reduction, SVI/SABR Calibration, Vanna/Volga Greeks, Relative-Value Volatility Arbitrage | COMEX Gold (`GC`), CME Crude (`CL`) | 🟢 **Complete** |
| **02** | **Limit Order Book (LOB) Dynamics & Microstructure Alpha** | L2/L3 Order Flow Imbalance (OFI), Volume Synchronized Probability of Toxicity (VPIN), Queue Reactive Hawkes Processes, VWAP/TWAP Execution | CME Globex, NASDAQ ITCH | ⏳ *Upcoming* |
| **03** | **Statistical Arbitrage & Cointegration Engine** | Johansen Cointegration, Dynamic State-Space Kalman Filtering, Ornstein-Uhlenbeck Optimal Stopping, Pairs & Basket Execution | CME Futures, US Equities | ⏳ *Upcoming* |
| **04** | **Multi-Asset Portfolio Optimization & Factor Risk Engine** | Hierarchical Risk Parity (HRP), Black-Litterman Bayesian Updating, Conditional Value-at-Risk (CVaR), Barra-style Multi-Factor Attribution | Cross-Asset Macro Futures | ⏳ *Upcoming* |

---

## 🏛️ System Architecture Standards
- **Zero Black Boxes**: Every pricing equation, gradient, and tree recursion is derived from stochastic calculus first principles.
- **Production Performance**: Vectorized NumPy/SciPy kernels with JIT/analytical shortcuts and root-finding fallback routines.
- **Market Microstructure Fidelity**: Distinct handling of spot equity options vs. cash-settled futures options (Black-76, American exercise on futures).
- **Automated Validation**: Comprehensive test suites verifying Put-Call parity, martingale pricing, and numerical derivative convergence.
