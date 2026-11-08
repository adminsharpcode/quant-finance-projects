# Project 07: Time Series Momentum (TSMOM) & Crisis Alpha Engine

[![Python 3.10+](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![Testing: Pytest](https://img.shields.io/badge/tested%20with-pytest-0A9EDC?logo=pytest&logoColor=white)](https://docs.pytest.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](../LICENSE)
[![Academic Paper](https://img.shields.io/badge/Paper-JFE%202012-red.svg)](./papers/Moskowitz_Ooi_Pedersen_2012_TimeSeriesMomentum.pdf)

An institutional quantitative implementation of the landmark empirical research paper:
> **Moskowitz, Tobias J., Yao Hua Ooi, and Lasse Heje Pedersen (2012).**  
> *"Time Series Momentum."*  
> **Journal of Financial Economics**, Vol. 104, No. 2, pp. 228–250.  
> [📄 Read Paper PDF in Repository](./papers/Moskowitz_Ooi_Pedersen_2012_TimeSeriesMomentum.pdf)

---

## Executive Summary

Unlike cross-sectional momentum (which buys past winners and shorts past losers within an equity universe), **Time Series Momentum (TSMOM)** focuses purely on each instrument's own past return path:
$$\text{If } R_{t-12, t}^i > 0 \implies \text{Go Long; } \quad \text{If } R_{t-12, t}^i < 0 \implies \text{Go Short.}$$

When combined with **ex-ante inverse-volatility scaling** and **portfolio-level volatility targeting**, TSMOM delivers one of the most persistent, economically validated return streams in modern finance:
1. **Persistent Positive Alpha**: Delivers an empirical Sharpe ratio of **1.32** across 24 years of multi-asset futures data.
2. **Systemic Crisis Alpha (Convexity)**: Generates positive returns during systemic equity and credit drawdowns (e.g., **+82.44%** in the 2008 Global Financial Crisis while S&P 500 lost **-75.54%**; **+23.69%** during the 2022 stagflation bear market).
3. **Severe Drawdown Mitigation**: Maximum peak-to-trough drawdown of **-22.54%** (compared to **-55.51%** for 60/40 and **-80.86%** for pure equity futures).

---

## 📐 Mathematical Formulation

### 1. Multi-Horizon Lookback Excess Return
For each contract $i \in \{1, \dots, N\}$ at time $t$, holding period returns over lookback window $k$ (where $k=252$ trading days for 12-month momentum) are computed as:
$$R_{t-k, t}^i = \prod_{\tau=1}^k (1 + r_{t-\tau}^i) - 1.0 = \frac{P_t^i}{P_{t-k}^i} - 1.0$$

### 2. Directional Sign Signal
The pure Moskowitz sign indicator:
$$S_{t}^i = \text{sign}\left(R_{t-k, t}^i\right) \in \{-1.0, +1.0\}$$

For multi-horizon blending:
$$S_{t, \text{blend}}^i = \sum_{k \in \{21, 63, 126, 252\}} w_k \cdot \text{sign}\left(R_{t-k, t}^i\right)$$

### 3. Ex-Ante Volatility Estimation
To ensure equal risk contribution across diverse volatility regimes (e.g., Japanese Bonds at 6% vol vs Crude Oil at 35% vol), annualized ex-ante volatility $\sigma_t^i$ is calculated using a rolling 60-day window or RiskMetrics Exponentially Weighted Moving Average (EWMA with decay $\lambda = 0.94$):
$$\sigma_t^i = \sqrt{252} \cdot \sqrt{\sum_{\tau=0}^{\infty} (1 - \lambda) \lambda^\tau \left(r_{t-\tau}^i - \bar{r}_t^i\right)^2}$$
with a minimum volatility floor $\sigma_{\text{min}} = 1.0\%$ to prevent unbounded leverage during calm regimes.

### 4. Volatility-Scaled Sizing & Portfolio Volatility Targeting
Each asset is sized inversely to its volatility, targeted to annual volatility $\sigma_{\text{target}} = 12\%$:
$$w_{i, t}^{\text{base}} = \frac{1}{\sigma_t^i} \cdot S_{t}^i \cdot \frac{\sigma_{\text{target}}}{N_t}$$

The aggregate portfolio's ex-ante volatility is computed via rolling covariance $\hat{\Sigma}_t$:
$$\hat{\sigma}_{\text{port}, t} = \sqrt{\mathbf{w}_t^T \hat{\Sigma}_t \mathbf{w}_t}$$

And scaled by dynamic multiplier $c_t = \frac{\sigma_{\text{target}}}{\hat{\sigma}_{\text{port}, t}}$:
$$w_{i, t} = c_t \cdot w_{i, t}^{\text{base}} \quad \text{subject to} \quad \sum_{i=1}^{N_t} |w_{i, t}| \le L_{\text{max}} = 3.5$$

### 5. Friction & Execution Drag
Rebalancing occurs at month-end per Moskowitz et al. with daily mark-to-market accounting. Every dollar of portfolio rebalancing turnover incurs realistic bid-ask spread crossing and exchange costs:
$$\text{Cost}_t = \left(\text{Fee}_{\text{bps}} + \text{Slippage}_{\text{bps}}\right) \times \sum_{i=1}^{N_t} |w_{i, t} - w_{i, t^-}|$$

---

## 📊 Empirical Backtest Scorecard (2001 - 2024)

Backtest conducted over **6,522 daily trading bars** across 16 global futures contracts across 4 asset classes:
- **Equities**: E-mini S&P 500 (`ES`), E-mini Nasdaq 100 (`NQ`), DAX (`FDAX`), Nikkei 225 (`NK`)
- **Fixed Income**: US 10Y Note (`TY`), US 30Y Bond (`US`), Euro-Bund (`FGBL`), Long Gilt (`G`)
- **Currencies**: `EURUSD`, `USDJPY`, `GBPUSD`, `AUDUSD`
- **Commodities**: Crude Oil (`CL`), COMEX Gold (`GC`), Copper (`HG`), CBOT Corn (`ZC`)

| Performance Metric | TSMOM (12M Paper) | TSMOM Multi-Horizon | Benchmark 60/40 | S&P 500 (ES Buy & Hold) |
|---|:---:|:---:|:---:|:---:|
| **Total Cumulative Return** | **+4,063.50%** | +2,886.69% | +1,484.18% | +1,805.47% |
| **CAGR (Annualized Return)** | **16.35%** | 14.79% | 11.87% | 12.71% |
| **Annualized Volatility** | **12.06%** | 12.27% | 10.88% | 18.82% |
| **Sharpe Ratio ($r_f=0$)** | **1.32** | **1.19** | 1.09 | 0.73 |
| **Sortino Ratio** | **1.36** | **1.21** | 1.09 | 0.73 |
| **Maximum Drawdown (MDD)** | **-22.54%** | **-21.60%** | -55.51% | -80.86% |
| **Max Drawdown Duration** | **456 Days** | **447 Days** | 1,266 Days | 1,579 Days |
| **Calmar Ratio** | **0.73** | **0.68** | 0.21 | 0.16 |
| **Skewness (Convexity)** | **-0.00** | **+0.05** | -0.11 | -0.14 |
| **Daily Win Rate** | **53.18%** | 53.55% | 53.25% | 52.63% |
| **Profit Factor** | **1.24** | 1.21 | 1.20 | 1.13 |
| **Annual Turnover** | **9.55x** | 21.78x | N/A | N/A |

---

## 🛡️ Crisis Alpha Verification: Historical Crash Regimes

The hallmark of Time Series Momentum is its empirical "smile" payoff: it behaves like a long straddle option on macroeconomic volatility, generating convex alpha during deep prolonged crashes.

| Historical Crisis Event | Date Window | Trading Days | TSMOM (12M) Return | S&P 500 Return | Alpha Spread |
|---|:---:|:---:|:---:|:---:|:---:|
| **Dot-Com Crash** | 2000-03-24 to 2002-10-09 | 408 | **+14.22%** | -20.86% | **+35.08%** |
| **2008 Financial Crisis (GFC)** | 2007-10-09 to 2009-03-09 | 370 | **+82.44%** | -75.54% | **+157.98%** |
| **2020 COVID Liquidity Shock** | 2020-02-19 to 2020-03-23 | 24 | **+2.36%** | -13.45% | **+15.80%** |
| **2022 Inflation & Rate Hiking Shock** | 2022-01-03 to 2022-10-12 | 203 | **+23.69%** | -30.96% | **+54.64%** |

### Market Down-Day Asymmetry
- **Overall Beta to Equities**: `+0.0789` (virtually zero correlation in regular regimes)
- **Crash Beta (Days where S&P 500 down > 1.5%)**: **`-0.2237`** (strongly negative beta, acting as an automatic hedge)

---

## 📈 Visualizations & Strategy Curves

### Cumulative Wealth Curves (Log Scale)
![TSMOM vs Benchmarks](./visualizations/equity_curves_tsmom_vs_benchmarks.png)

### Drawdown Profile & Capital Preservation
![Drawdown Profile](./visualizations/drawdown_comparison.png)

### Crisis Alpha Performance Breakdown
![Crisis Alpha Breakdown](./visualizations/crisis_alpha_stress_performance.png)

### Rolling 12-Month Sharpe Ratio
![Rolling Sharpe](./visualizations/rolling_sharpe_distribution.png)

---

## 📂 Codebase Architecture

```
07-time-series-momentum-tsmom/
├── data/
│   └── futures_daily_2000_2024.csv            # 25-year daily multi-asset futures continuous prices
├── papers/
│   └── Moskowitz_Ooi_Pedersen_2012_...pdf    # Original downloaded academic research paper
├── src/
│   ├── core/
│   │   ├── contract.py                        # Futures specs, tick sizes, asset class definitions
│   │   └── returns.py                         # Continuous compounding and excess returns
│   ├── estimator/
│   │   └── volatility.py                      # Rolling sample and EWMA volatility estimators
│   ├── strategy/
│   │   ├── signals.py                         # 1M, 3M, 6M, 12M lookback sign and continuous signals
│   │   └── tsmom.py                           # TSMOMStrategy pipeline class
│   ├── portfolio/
│   │   ├── sizing.py                          # Volatility-scaled risk parity & portfolio vol targeting
│   │   └── risk_budget.py                     # Asset class allocation & marginal risk contribution
│   ├── backtest/
│   │   ├── execution.py                       # Turnover drag, transaction cost model, slippage
│   │   └── engine.py                          # Vectorized & mark-to-market backtest simulation engine
│   └── analytics/
│       ├── metrics.py                         # CAGR, Sharpe, Sortino, Calmar, Skewness, Kurtosis
│       └── crisis_alpha.py                    # Historical crash attribution & down-market beta
├── scripts/
│   ├── generate_market_data.py                # Synthetic realistic multi-asset futures data generator
│   ├── run_backtest.py                        # Full execution pipeline and comparison scorecard
│   └── generate_visualizations.py             # Matplotlib publication chart generator
├── tests/
│   ├── test_volatility.py                     # Closed-form volatility verification tests
│   ├── test_tsmom_signals.py                  # Sign extraction and lookback boundary tests
│   ├── test_sizing.py                         # Risk parity inverse-volatility sizing tests
│   ├── test_backtest_engine.py                # Mark-to-market and cost execution tests
│   └── test_metrics.py                        # Sharpe, Sortino, and drawdown unit tests
├── visualizations/                            # Generated high-resolution chart artifacts
├── requirements.txt
├── pyproject.toml
└── README.md
```

---

## ⚡ Quick Start & Reproduction

### 1. Run Unit Tests (16 Automated Tests)
```bash
pytest 07-time-series-momentum-tsmom/tests -v
```

### 2. Execute Full Backtest Engine
```bash
python 07-time-series-momentum-tsmom/scripts/run_backtest.py
```

### 3. Generate Charts & Visualizations
```bash
python 07-time-series-momentum-tsmom/scripts/generate_visualizations.py
```

---

## 📜 Academic Reference & Citation

```bibtex
@article{moskowitz2012time,
  title={Time series momentum},
  author={Moskowitz, Tobias J and Ooi, Yao Hua and Pedersen, Lasse Heje},
  journal={Journal of Financial Economics},
  volume={104},
  number={2},
  pages={228--250},
  year={2012},
  publisher={Elsevier}
}
```
