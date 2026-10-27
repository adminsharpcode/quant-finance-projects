# Project 05: Almgren-Chriss Optimal Execution & Market Impact Engine

[![Python 3.10+](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Tested with Pytest](https://img.shields.io/badge/tested%20with-pytest-0A9EDC?logo=pytest&logoColor=white)](https://docs.pytest.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Institutional Finance](https://img.shields.io/badge/quant-institutional-8A2BE2)](https://github.com/adminsharpcode/optimal-execution-engine)

An institutional algorithmic execution engine implementing the **Almgren-Chriss (2000)** optimal liquidation framework, non-linear market impact models (Linear and Square-Root Law), stochastic price simulation, and automated **Transaction Cost Analysis (TCA)** benchmarking against TWAP and VWAP.

---

## 🏛️ Theoretical Foundations & Mathematics

When an institutional fund liquidates a large block order (e.g. \$15,000,000 notional), executing too quickly incurs severe **market impact** (slippage against the limit order book), while executing too slowly incurs **timing/inventory risk** (the price may drift against the fund due to market volatility).

The Almgren-Chriss framework derives the Pareto-optimal liquidation schedule by minimizing an objective function balancing expected cost and cost variance:

$$\min_{\{x_k\}} U(x) = \mathbb{E}[x] + \lambda \mathbb{V}[x]$$

where:
- $X$: Total initial shares to liquidate at $t = 0$.
- $T$: Total liquidation horizon divided into $N$ intervals of length $\tau = T/N$.
- $x_k$: Shares remaining in inventory at time $t_k$ ($x_0 = X, x_N = 0$).
- $n_k = x_{k-1} - x_k$: Shares liquidated in interval $k$.
- $v_k = n_k / \tau$: Trading rate.
- $\lambda$: Fund risk-aversion coefficient ($\lambda \ge 0$).

### 1. Market Impact Dynamics
Asset price evolves under permanent impact $\gamma(v)$ and temporary impact $\eta(v)$:

$$S_k = S_{k-1} + \sigma \tau^{1/2} \xi_k - \tau \gamma(v_k)$$
$$\tilde{S}_k = S_{k-1} - \eta(v_k)$$

### 2. Expected Cost & Variance
Total capture cost relative to arrival price $S_0$:

$$\mathbb{E}[x] = \frac{1}{2} \gamma X^2 + \tau \eta \sum_{k=1}^N \left(\frac{x_{k-1} - x_k}{\tau}\right)^2$$
$$\mathbb{V}[x] = \sigma^2 \tau \sum_{k=1}^N x_k^2$$

### 3. Closed-Form Analytical Solution
The discrete Euler-Lagrange equations yield the hyperbolic sine solution:

$$x_j = \frac{\sinh(\kappa (T - t_j))}{\sinh(\kappa T)} X$$

where the execution urgency parameter $\kappa$ satisfies:

$$\kappa = \frac{1}{\tau} \text{arccosh}\left(1 + \frac{\lambda \sigma^2 \tau^2}{2 \eta}\right) \approx \sqrt{\frac{\lambda \sigma^2}{\eta}}$$

#### Boundary Limits
- **$\lambda \to 0$ (Risk Neutral)**: Recovers uniform **TWAP** (constant liquidation rate, minimal impact cost, maximum volatility risk).
- **$\lambda \to \infty$ (Risk Averse)**: Recovers immediate frontloaded execution (zero inventory risk, maximum temporary impact).

---

## ⚡ Execution Architecture

```
05-optimal-execution-engine/
├── src/
│   ├── models/
│   │   ├── almgren_chriss.py      # Analytical closed-form trajectory & efficient frontier
│   │   └── impact.py              # Linear and Square-Root market impact laws
│   ├── execution/
│   │   ├── twap.py                # Time-Weighted Average Price benchmark
│   │   ├── vwap.py                # Volume-Weighted Average Price with intraday U-curve
│   │   └── simulator.py           # Stochastic execution simulator with Brownian motion
│   └── analytics/
│       └── tca.py                 # Transaction Cost Analysis & Implementation Shortfall
├── tests/
│   ├── test_almgren_chriss.py     # Boundary condition & monotonicity unit tests
│   └── test_execution_benchmark.py# TWAP, VWAP, and TCA verification
├── examples/
│   └── run_execution_frontier.py  # End-to-end institutional liquidation demo
└── pyproject.toml
```

---

## 📊 Comparative Performance (TCA Benchmark)

Simulation of a **\$15,000,000** liquidation (100,000 shares @ \$150.00) over 60 minutes ($\tau = 120\text{s}$, annual $\sigma = 30\%$):

| Execution Strategy | Avg Fill Price | Implementation Shortfall | Slippage (bps) | Volatility Risk ($\text{Std}$) |
|---|---|---|---|---|
| **Almgren-Chriss (Urgent, $\lambda = 10^{-4}$)** | **\$149.998** | **\$214.58** | **0.14 bps** | **\$101.60** |
| **Almgren-Chriss (Balanced, $\lambda = 10^{-6}$)** | **\$150.001** | **-\$121.94** | **-0.08 bps** | **\$5,684.69** |
| **TWAP Benchmark (Linear)** | \$150.674 | -\$67,431.50 | -44.95 bps | \$62,586.94 |
| **VWAP Benchmark (U-Curve)** | \$150.690 | -\$69,034.68 | -46.02 bps | \$60,366.94 |

*Note: In rising random paths, TWAP/VWAP experience drift gain at the expense of massive timing variance (\$62.5k risk exposure vs \$101 in urgent AC).*

---

## 🚀 Quick Start

### 1. Installation
```bash
git clone https://github.com/adminsharpcode/optimal-execution-engine.git
cd optimal-execution-engine
pip install -e .
```

### 2. Run the Benchmark Execution
```bash
python examples/run_execution_frontier.py
```

### 3. Run Automated Unit Tests
```bash
pytest tests/ -v
```

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
