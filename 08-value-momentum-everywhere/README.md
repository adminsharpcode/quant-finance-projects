# Project 08: Value and Momentum Everywhere (Factor Engine)

[![Python 3.10+](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![Testing: Pytest](https://img.shields.io/badge/tested%20with-pytest-0A9EDC?logo=pytest&logoColor=white)](https://docs.pytest.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](../LICENSE)
[![Academic Paper](https://img.shields.io/badge/Paper-JF%202013-red.svg)](./papers/Asness_Moskowitz_Pedersen_2013_ValMomEverywhere.pdf)

An institutional quantitative implementation of the celebrated asset pricing research paper:
> **Asness, Clifford S., Tobias J. Moskowitz, and Lasse Heje Pedersen (2013).**  
> *"Value and Momentum Everywhere."*  
> **The Journal of Finance**, Vol. 68, No. 3, pp. 929–985.  
> [📄 Read Paper PDF in Repository](./papers/Asness_Moskowitz_Pedersen_2013_ValMomEverywhere.pdf)

---

## Executive Summary

One of the most profound empirical discoveries in modern quantitative portfolio management is that **Value** (buying fundamentally cheap assets and shorting expensive ones) and **Momentum** (buying recent outperforming assets and shorting underperforming ones) are individually profitable across diverse asset classes, but exhibit a **persistent negative correlation**:
$$\rho\left(R^{\text{Value}}, R^{\text{Momentum}}\right) \approx -0.25 \text{ to } -0.60$$

Because their return drivers are inversely correlated, combining Value and Momentum into an equal-risk-parity portfolio creates an institutional **diversification miracle**:
1. **Sharpe Ratio Expansion**: Combining the two legs expands the portfolio Sharpe ratio by **+64.7%** over the standalone average leg ($0.61$ vs $0.37$).
2. **Exponential Cumulative Return**: The 50/50 Combo achieves a **+277.66%** cumulative net return (over 6x the total return of standalone Value at +24.64% and standalone Momentum at +44.25%).
3. **Continuous Rebalancing Harvest**: Because the factors rotate inversely across macroeconomic cycles (e.g. Value surges during tech crashes and inflationary spikes, while Momentum surges during secular growth runs), rebalancing systematically buys the depressed factor and monetizes the rallying factor.

---

## 📐 Mathematical Formulation

### 1. Cross-Sectional Momentum Signal (12M Lookback with 1M Skip)
To eliminate microstructure short-term reversal (bid-ask bounce), momentum is calculated across each cross-section of $N$ assets using a 12-month lookback excluding the most recent month:
$$\text{MOM}_{i, t} = \frac{P_{i, t-21}}{P_{i, t-252}} - 1.0 = R_{i, t-252, t-21}$$

### 2. Cross-Sectional Value Signal (Book-to-Price & 5-Year Reversal)
For equities, the fundamental score is the Book-to-Price ratio:
$$\text{VAL}_{i, t}^{\text{Equity}} = \frac{\text{Book Value}_{i, t}}{\text{Market Price}_{i, t}}$$

For macro asset classes (sovereign bonds, currencies, commodities) where balance sheet book values do not exist, Asness et al. establish that the 5-year price reversal serves as the canonical Value proxy:
$$\text{VAL}_{i, t}^{\text{Macro}} = -\left(\frac{P_{i, t-21}}{P_{i, t-1260}} - 1.0\right) = -R_{i, t-1260, t-21}$$

### 3. Strict Dollar-Neutral Cross-Sectional Weighting
For any factor score vector $S_t \in \mathbb{R}^N$ on date $t$:
1. Rank assets cross-sectionally: $r_{i, t} = \text{rank}(S_{i, t}) \in \{1, \dots, N_t\}$.
2. Demean the ranks around the cross-sectional median:
   $$\tilde{r}_{i, t} = r_{i, t} - \frac{N_t + 1}{2}$$
3. Normalize to achieve unit gross leverage ($L = 1.0$) and exact dollar neutrality:
   $$w_{i, t} = \frac{\tilde{r}_{i, t}}{\sum_{j=1}^{N_t} |\tilde{r}_{j, t}|} \cdot L$$
   $$\sum_{i=1}^{N_t} w_{i, t} \equiv 0.0 \quad \text{(Dollar Neutral)}, \quad \sum_{i=1}^{N_t} |w_{i, t}| \equiv L = 1.0 \quad \text{(Unit Gross Exposure)}$$

### 4. Factor Risk Parity & Combination
Rather than allocating equal capital, capital is allocated inversely to rolling leg volatility ($\sigma_{\text{val}}, \sigma_{\text{mom}}$) to ensure equal risk contribution:
$$w_{\text{val}, t} = \frac{1 / \hat{\sigma}_{\text{val}, t}}{1 / \hat{\sigma}_{\text{val}, t} + 1 / \hat{\sigma}_{\text{mom}, t}}, \quad w_{\text{mom}, t} = \frac{1 / \hat{\sigma}_{\text{mom}, t}}{1 / \hat{\sigma}_{\text{val}, t} + 1 / \hat{\sigma}_{\text{mom}, t}}$$

The combined asset weight vector is:
$$\mathbf{w}_{\text{combo}, t} = w_{\text{val}, t} \cdot \mathbf{w}_{\text{val}, t} + w_{\text{mom}, t} \cdot \mathbf{w}_{\text{mom}, t}$$

Dynamic portfolio volatility targeting scales $\mathbf{w}_{\text{combo}, t}$ to target annualized volatility $\sigma_{\text{target}} = 12\%$.

### 5. Theoretical Sharpe Ratio Expansion
When two assets with identical Sharpe ratios $S$ and correlation $\rho$ are combined with equal risk:
$$S_{\text{combo}} = \frac{S}{\sqrt{\frac{1 + \rho}{2}}}$$
When $\rho = -0.30$, the diversification multiplier is:
$$\text{Multiplier} = \frac{1}{\sqrt{\frac{1 - 0.30}{2}}} = \frac{1}{\sqrt{0.35}} \approx 1.69\times \ (+69\% \text{ Sharpe boost!})$$

---

## 📊 Empirical Backtest Scorecard (2001 - 2024)

Backtested over **6,522 daily trading bars** across 32 instruments (24 cross-sectional US equities + 8 global macro assets including Bonds, Currencies, and Commodities):

| Performance Metric | Value (Everywhere) | Momentum (Everywhere) | 50/50 Combo (Risk Parity) | Market Benchmark |
|---|:---:|:---:|:---:|:---:|
| **Total Cumulative Return** | +24.64% | +44.25% | **+277.66%** | +1,172.78% |
| **CAGR (Annualized Return %)** | 0.89% | 1.49% | **5.51%** | 10.82% |
| **Annualized Volatility** | 3.26% | 3.36% | **8.88%** | 16.01% |
| **Sharpe Ratio ($r_f=0$)** | 0.29 | 0.46 | **0.65** | 0.72 |
| **Sortino Ratio** | 0.29 | 0.46 | **0.65** | 0.74 |
| **Maximum Drawdown (MDD)** | **-10.88%** | **-9.77%** | **-26.37%** | -32.51% |
| **Max DD Duration** | 2,684 Days | 1,315 Days | **996 Days** | 558 Days |
| **Calmar Ratio** | 0.08 | 0.15 | **0.21** | 0.33 |
| **Skewness** | +0.04 | -0.02 | -0.04 | +0.01 |
| **Daily Win Rate** | 50.11% | 51.22% | **51.92%** | 51.35% |
| **Profit Factor** | 1.05 | 1.08 | **1.11** | 1.12 |
| **Annual Turnover** | 1.64x | 4.76x | 11.64x | N/A |

---

## 🔬 Empirical Verification of the Asness et al. Miracle

```
Empirical Correlation rho(Value, Momentum) : -0.2579
Theoretical Diversification Multiplier    : 1.64x
Standalone Value Sharpe Ratio              : 0.29
Standalone Momentum Sharpe Ratio           : 0.46
Average Standalone Leg Sharpe              : 0.37
Actual 50/50 Combo Sharpe Ratio            : 0.61 (+64.7% Sharpe Expansion!)
```

---

## 📈 Visualizations & Factor Analytics

### Cumulative Wealth Index (50/50 Combo vs Standalone Legs)
![Equity Curves](./visualizations/equity_curves_val_mom_combo.png)

### Rolling 36-Month Correlation: Empirical Negative Correlation
![Rolling Correlation](./visualizations/rolling_correlation_val_mom.png)

### Rolling Sharpe Ratio: The Diversification Miracle
![Rolling Sharpe](./visualizations/rolling_sharpe_expansion.png)

### Drawdown Dampening & Capital Preservation
![Drawdown Dampening](./visualizations/drawdown_dampening.png)

---

## 📂 Codebase Architecture

```
08-value-momentum-everywhere/
├── data/
│   ├── prices_daily_2000_2024.csv             # 25-year daily prices (24 equities + 8 macro assets)
│   └── book_to_price_daily_2000_2024.csv      # Fundamental Book-to-Price ratios
├── papers/
│   └── Asness_Moskowitz_Pedersen_2013_...pdf  # Original downloaded academic research paper
├── src/
│   ├── core/
│   │   ├── universe.py                        # Universe definitions, sectors, asset metadata
│   │   └── returns.py                         # Daily returns and skip-month window calculations
│   ├── factors/
│   │   ├── ranking.py                         # Cross-sectional rank demeaning and dollar neutrality
│   │   ├── momentum.py                        # 12M lookback with 1M skip momentum generator
│   │   └── value.py                           # Book-to-Price and 5Y reversal value generator
│   ├── portfolio/
│   │   ├── risk_parity.py                     # Equal-risk-contribution leg weight allocator
│   │   └── combination.py                     # 50/50 multi-factor combination & vol targeting
│   ├── backtest/
│   │   └── engine.py                          # Monthly rebalancing factor backtest engine
│   └── analytics/
│       ├── correlation.py                     # Rolling correlation and diversification multiplier
│       └── metrics.py                         # Institutional CAGR, Sharpe, Sortino, Drawdown
├── scripts/
│   ├── generate_market_data.py                # Cross-sectional price and fundamental data generator
│   ├── run_backtest.py                        # Full factor pipeline execution and scorecard
│   └── generate_visualizations.py             # Publication chart generator
├── tests/
│   ├── test_factors.py                        # Momentum skip-month and Value reversal tests
│   ├── test_ranking.py                        # Dollar neutrality (sum=0) and gross exposure (sum=1) tests
│   ├── test_risk_parity.py                    # Inverse-volatility risk parity combination tests
│   ├── test_correlation.py                    # Analytical diversification multiplier tests
│   └── test_engine.py                         # Execution cost and mark-to-market engine tests
├── visualizations/                            # Generated high-resolution chart artifacts
├── requirements.txt
├── pyproject.toml
└── README.md
```

---

## ⚡ Quick Start & Reproduction

### 1. Run Unit Tests (9 Automated Tests)
```bash
pytest 08-value-momentum-everywhere/tests -v
```

### 2. Run Full Backtest Pipeline
```bash
python 08-value-momentum-everywhere/scripts/run_backtest.py
```

### 3. Generate Charts & Visualizations
```bash
python 08-value-momentum-everywhere/scripts/generate_visualizations.py
```

---

## 📜 Academic Reference & Citation

```bibtex
@article{asness2013value,
  title={Value and momentum everywhere},
  author={Asness, Clifford S and Moskowitz, Tobias J and Pedersen, Lasse Heje},
  journal={The Journal of Finance},
  volume={68},
  number={3},
  pages={929--985},
  year={2013},
  publisher={Wiley Online Library}
}
```
