# Quantitative Statistical Arbitrage & Pairs Trading Desk - System Manual

> **Document Reference:** `QENG-2026-STATARB-PORT`  
> **Classification:** Institutional Quantitative Finance / Production Statistical Arbitrage Engine  
> **Corresponding Theory Document:** [`cointegration_theory.md`](./cointegration_theory.md)

---

## 🏛️ Executive Summary & System Architecture

The **Pairs Trading & Cointegration Backtesting Engine** is an institutional quantitative framework engineered to identify stationary linear relationships across multi-asset universes, dynamically track time-varying hedge ratios via state-space Kalman filtering, calibrate mean-reversion dynamics via continuous Ornstein-Uhlenbeck stochastic processes, and rigorously validate alpha through realistic market microstructure simulation and out-of-sample walk-forward cross-validation.

```
                          ┌────────────────────────┐
                          │ Asset Universe History │
                          │ (Equities / Crudes /   │
                          │   Precious Metals)     │
                          └───────────┬────────────┘
                                      │
                 ┌────────────────────┴────────────────────┐
                 ▼                                         ▼
   ┌───────────────────────────┐             ┌───────────────────────────┐
   │ Cointegration Diagnostics │             │   State-Space Estimation  │
   │ • Engle-Granger CADF Test │             │ • 2-State Kalman Filter   │
   │ • Johansen VECM Trace Test│             │ • Continuous Beta beta_t  │
   │ • Cointegrating Vector    │             │ • Joseph Form Stabilized  │
   └─────────────┬─────────────┘             └─────────────┬─────────────┘
                 │                                         │
                 └────────────────────┬────────────────────┘
                                      ▼
                        ┌───────────────────────────┐
                        │   OU Process Calibration  │
                        │ • Mean-Reversion Speed    │
                        │ • Exact Half-Life tau_1/2 │
                        │ • Equilibrium Mean mu     │
                        └─────────────┬─────────────┘
                                      │
                                      ▼
                        ┌───────────────────────────┐
                        │ Dynamic Signal Generation │
                        │ • Standardized Z-Score    │
                        │ • Entry (+/- z_entry)     │
                        │ • Exit (z_exit / 0.0)     │
                        │ • Stop-Loss (+/- z_stop)  │
                        └─────────────┬─────────────┘
                                      │
                 ┌────────────────────┴────────────────────┐
                 ▼                                         ▼
   ┌───────────────────────────┐             ┌───────────────────────────┐
   │ Realistic Execution Sim   │             │   Walk-Forward Validation │
   │ • Half-Spread Crossing    │             │ • Rolling In-Sample Train │
   │ • Market Impact Slippage  │             │ • Strictly OOS Forward    │
   │ • Prime Short Borrow Fees │             │ • Zero Lookahead Bias     │
   │ • Dollar-Neutral Sizing   │             │ • Walk-Forward Efficiency │
   └───────────────────────────┘             └───────────────────────────┘
```

---

## ⚠️ The 4 Traps of Naive Pairs Backtests (And How This System Solves Them)

### Trap 1: Static OLS Overfitting & Regime Lag
- **The Flaw**: Standard pairs backtests fit a single OLS regression $y = \alpha + \beta x$ across 4 years of data and use that static $\beta$ for trading. This introduces severe lookahead bias (future prices dictate past hedge ratios) and fails when market betas change due to corporate debt issuances, M&A, or industry regime shifts.
- **The Solution**: Continuous online **State-Space Kalman Filter** tracks $\theta_t = [\alpha_t, \beta_t]^T$ sequentially with Joseph-form positive semi-definite covariance updating. Only past information is used at each decision point.

### Trap 2: The Phantom Profit of Ignoring Short Borrow Fees
- **The Flaw**: Half of every pairs trade is a short position. In naive backtests, short legs are treated as free money. In reality, prime brokers charge continuous locate and borrow fees (1.50% to 5.0%+ annualized). Holding a wide spread for 60 days can burn through entire profit margins in borrow costs alone.
- **The Solution**: Our execution simulator continuously accrues overnight borrow fees on short legs:
  $$\text{BorrowFee}_t = V_{\text{short}, t} \times \frac{1.5\%}{360} \times \Delta t$$

### Trap 3: Spurious Mean Reversion & Unlimited Divergence Risk
- **The Flaw**: Traders assume every widening spread must mean-revert. In structural breaks (e.g. one firm files for Chapter 11 or loses its key patent), the spread diverges to infinity, wiping out the account.
- **The Solution**: 
  1. We calibrate the **Ornstein-Uhlenbeck continuous half-life** $\tau_{1/2}$. Pairs with $\tau_{1/2} > 45\text{ days}$ or non-stationary AR(1) roots ($a \ge 1.0$) are rejected.
  2. Strict multi-sigma stop-loss boundaries ($|Z| \ge 3.5\sigma$) immediately liquidate diverging positions.

### Trap 4: Lookahead Bias in Threshold Optimization
- **The Flaw**: Naively optimizing entry and exit thresholds ($Z_{\text{entry}} = 2.1$, $Z_{\text{exit}} = 0.2$) over the whole backtest yields spectacular retrospective Sharpes that collapse in live execution.
- **The Solution**: **Walk-Forward Cross-Validation (WFO)**. Parameters are optimized strictly on a rolling 252-day in-sample window and evaluated on the subsequent unseen 63-day out-of-sample forward horizon. Walk-Forward Efficiency ($\text{WFE} = \text{Sharpe}_{\text{OOS}} / \text{Sharpe}_{\text{IS}}$) confirms genuine out-of-sample edge.

---

## 🚀 Step-by-Step Operator Instructions

### 1. Running the Automated Quantitative Pipeline
Execute the full multi-pair backtest across equities and commodities:
```powershell
python scripts/run_pairs_backtest.py
```
This script computes:
- CADF test statistics and MacKinnon p-values.
- Johansen multivariate trace statistics and cointegrating rank.
- Ornstein-Uhlenbeck $\theta$, $\mu$, $\sigma$, and $\tau_{1/2}$ in trading days.
- Dynamic Kalman filter beta trajectories.
- Institutional mark-to-market performance net of fees, slippage, and borrow costs.
- Spliced out-of-sample walk-forward efficiency metrics.

### 2. Generating High-Resolution Visualizations
Create publication-ready charts in the `visualizations/` directory:
```powershell
python scripts/plot_performance.py
```
Outputs:
- `visualizations/pairs_pnl_benchmark.png`: Strategy equity vs single-asset buy-and-hold.
- `visualizations/dynamic_kalman_beta.png`: Time-varying beta vs static OLS.
- `visualizations/spread_zscore_signals.png`: Standardized spread with entries, exits, and stop-loss markers.
- `visualizations/underwater_drawdown.png`: High-resolution drawdown area profile.
- `visualizations/walk_forward_stability.png`: In-sample vs Out-of-sample Sharpe per rolling fold.

### 3. Running the Test Suite
Verify that all unit and integration tests pass with 100% success:
```powershell
pytest tests/ -v
```

---

## 📊 Summary of Asset Pair Calibrations

| Asset Pair | Category | CADF p-value | Cointegrated? | Half-Life $\tau_{1/2}$ | Kalman Beta Range | Strategy Return | Max DD | Win Rate |
|---|---|---|---|---|---|---|---|---|
| **CVX vs XOM** | Energy Equities | $4.74 \times 10^{-3}$ | **Yes (p < 0.01)** | 20.4 days | $1.39 - 1.92$ | **+21.55%** | -10.90% | **65.1%** |
| **BAC vs JPM** | Banking Equities | $1.30 \times 10^{-4}$ | **Yes (p < 0.001)** | 13.5 days | $0.24 - 0.34$ | **+0.92%** | -0.06% | **100.0%** |
| **BRENT vs WTI** | Crude Spreads | $7.00 \times 10^{-8}$ | **Yes (p < 0.001)** | 7.97 days | $1.03 - 1.24$ | **-1.92%** | -6.72% | **54.5%** |
| **SILVER vs GOLD** | Precious Metals | $1.13 \times 10^{-3}$ | **Yes (p < 0.01)** | 16.3 days | $0.014 - 0.019$ | **0.00%** | 0.00% | N/A |
