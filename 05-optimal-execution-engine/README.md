# Project 05: Institutional Almgren-Chriss Optimal Execution & Market Impact Engine

[![Python 3.10+](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Tested with Pytest](https://img.shields.io/badge/tested%20with-pytest-0A9EDC?logo=pytest&logoColor=white)](https://docs.pytest.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Quantitative Finance](https://img.shields.io/badge/quant-institutional-8A2BE2)](https://github.com/adminsharpcode/optimal-execution-engine)
[![Deployment](https://img.shields.io/badge/deployed-Vercel-000000?logo=vercel&logoColor=white)](https://github.com/adminsharpcode/optimal-execution-engine)

An institutional algorithmic trade execution and market impact engine built from first principles. Implements **Almgren-Chriss (2000)** mean-variance liquidation, non-linear **Square-Root Law dynamic optimization (SLSQP)**, **Obizhaeva & Wang (2013)** transient impact resilience, **multi-asset cross-impact liquidation**, adaptive spread-sensing execution, and an interactive **institutional TCA (Transaction Cost Analysis) web terminal**.

---

## 🏛️ Theoretical Foundations & Core Mathematics

When executing an institutional block order (e.g., \$15,000,000 notional), algorithmic execution desks face the fundamental trade-off:
1. **Market Impact (Liquidity Cost)**: Aggressive execution walks the order book, creating temporary price spikes $\eta(v)$ and permanent adverse price displacement $\gamma(v)$.
2. **Timing Risk (Inventory Volatility Risk)**: Passive, prolonged execution exposes the remaining inventory to unhedged Brownian price diffusion $\sigma dW_t$.

The Almgren-Chriss framework computes the Pareto-optimal liquidation trajectory by minimizing the mean-variance utility:

$$\min_{\{x_k\}} U(x) = \mathbb{E}[x] + \lambda \mathbb{V}[x]$$

where $\lambda \ge 0$ is the fund's risk-aversion parameter, $X$ is initial inventory, and $T$ is the execution horizon divided into $N$ discrete intervals $\tau = T/N$.

---

### 1. Market Impact Formulations

#### A. Classical Linear Impact (Almgren & Chriss 2000)
Price dynamics under continuous liquidation rate $v_k = n_k / \tau$:

$$S_k = S_{k-1} + \sigma \tau^{1/2} \xi_k - \tau \gamma(v_k)$$
$$\tilde{S}_k = S_{k-1} - \eta(v_k)$$

Where $\gamma(v) = \gamma v$ (permanent drift) and $\eta(v) = \eta v$ (temporary execution penalty).

#### B. Non-Linear Square-Root Law (Barra, Bouchaud et al. 2004)
Empirical microstructure demonstrates that temporary impact follows a sub-linear power law:

$$\eta(v) = Y \cdot \sigma_{\text{daily}} \left(\frac{v}{\text{ADV} / 23400}\right)^\alpha, \quad \alpha \approx 0.5$$

Solved via high-precision Constrained Sequential Least Squares Programming (`scipy.optimize.minimize`).

#### C. Transient Impact & Order Book Resilience (Obizhaeva & Wang 2013)
Real order books possess finite replenishment speed $\rho$ with exponential decay kernel $G(t - s) = \gamma_0 e^{-\rho (t - s)}$. The exact analytical solution proves why discrete block orders are mathematically required at open and close:

$$n_0 = \frac{X}{2 + \rho T}, \quad \nu(t) = \frac{\rho X}{2 + \rho T}, \quad n_N = \frac{X}{2 + \rho T}$$

#### D. Multi-Asset Correlated Portfolio Liquidation
Simultaneous execution of an $M$-asset basket under cross-asset asset covariance $\Sigma$ and cross-impact matrix $\Gamma$:

$$\min_{\{X(t)\}} \int_0^T \left[ \lambda \cdot x(t)^\top \Sigma x(t) + v(t)^\top \text{H} v(t) \right] dt$$

---

### 2. Analytical Closed-Form Solution (Almgren-Chriss)
The discrete Euler-Lagrange variational problem yields:

$$x_j = \frac{\sinh(\kappa (T - t_j))}{\sinh(\kappa T)} X$$

where the execution urgency parameter $\kappa$ satisfies:

$$\kappa = \frac{1}{\tau} \text{arccosh}\left(1 + \frac{\lambda \sigma^2 \tau^2}{2 \eta}\right) \approx \sqrt{\frac{\lambda \sigma^2}{\eta}}$$

* **$\lambda \to 0$ (Risk Neutral)**: Recovers uniform **TWAP** (constant rate, minimal impact, maximal timing variance).
* **$\lambda \to \infty$ (Risk Averse)**: Recovers immediate frontloaded execution (zero inventory risk, maximal market impact).

---

## ⚡ Architecture Overview

```
05-optimal-execution-engine/
├── src/
│   ├── models/
│   │   ├── almgren_chriss.py      # Analytical closed-form, SLSQP non-linear, & multi-asset
│   │   └── impact.py              # Linear, Square-Root, Transient, & Cross-Impact matrices
│   ├── execution/
│   │   ├── twap.py                # Time-Weighted Average Price benchmark
│   │   ├── vwap.py                # Volume-Weighted Average Price with intraday U-curve
│   │   ├── adaptive.py            # Real-time spread & volatility sensing execution
│   │   └── simulator.py           # Stochastic execution engine with Brownian noise
│   └── analytics/
│       └── tca.py                 # Institutional Transaction Cost Analysis (IS, slippage)
├── web/
│   ├── index.html                 # Institutional dark terminal UI
│   ├── styles.css                 # Quantitative design system tokens
│   ├── app.js                     # First-principles math & Chart.js live visualizers
│   └── vercel.json                # 1-click Vercel deployment configuration
├── tests/
│   ├── test_almgren_chriss.py     # 10 comprehensive model unit tests
│   └── test_execution_benchmark.py# 4 benchmark & simulator verification tests
├── examples/
│   └── run_execution_frontier.py  # Full institutional liquidation CLI demo
└── pyproject.toml
```

---

## 📊 Comparative Performance (TCA Benchmark)

Simulation of a **\$15,000,000** liquidation (100,000 shares @ \$150.00) over 60 minutes ($\tau = 120\text{s}$, annual $\sigma = 30\%$):

| Execution Strategy | Avg Fill Price | Implementation Shortfall | Slippage (bps) | Volatility Risk ($\text{Std}$) | Execution Urgency |
|---|---|---|---|---|---|
| **Almgren-Chriss (Urgent, $\lambda = 10^{-4}$)** | **\$149.998** | **\$214.58** | **0.14 bps** | **\$101.60** | $\kappa = 0.0345\text{ s}^{-1}$ |
| **Almgren-Chriss (Balanced, $\lambda = 10^{-6}$)** | **\$150.001** | **-\$121.94** | **-0.08 bps** | **\$5,684.69** | $\kappa = 0.0034\text{ s}^{-1}$ |
| **TWAP Benchmark (Linear)** | \$150.674 | -\$67,431.50 | -44.95 bps | \$62,586.94 | Uniform rate |
| **VWAP Benchmark (U-Curve)** | \$150.690 | -\$69,034.68 | -46.02 bps | \$60,366.94 | Intraday curve |

---

## 🌐 Interactive Web Terminal Features

The included browser application provides an institutional execution cockpit:
* **Real-Time Parameter Modulation**: Sliders for notional, execution horizon $T$, intervals $N$, volatility $\sigma$, and risk aversion $\lambda$ with instant mathematical re-computation.
* **4-Quadrant Interactive Visualizers**:
  1. *Holdings Trajectory $x(t)$*: Real-time comparison across AC Optimal, TWAP, VWAP, and Obizhaeva-Wang.
  2. *Child Order Slicing $v_k$*: Bar chart of shares liquidated per interval.
  3. *Efficient Execution Frontier*: Complete $\mathbb{E}[x]$ vs $\sqrt{\mathbb{V}[x]}$ Pareto frontier with the active operating point highlighted.
  4. *Stochastic Price & Executed Fills Simulator*: Simulates child order fills against stochastic price paths with permanent/temporary impact.
* **TCA Attribution**: Real-time breakdown of Implementation Shortfall, Slippage in bps, Permanent vs Temporary Impact, and Timing Risk exposure.
* **Institutional Presets**: 1-click calibration for CME E-mini S&P 500, Illiquid Mid-Cap, Volatility Shock, and VWAP Glider.

---

## 🚀 Quick Start

### 1. Installation
```bash
git clone https://github.com/adminsharpcode/optimal-execution-engine.git
cd optimal-execution-engine
pip install -e .
```

### 2. Run Institutional CLI Benchmark Demo
```bash
python examples/run_execution_frontier.py
```

### 3. Run Automated Unit Tests (14 Tests)
```bash
pytest tests/ -v
```

### 4. Launch Interactive Web Terminal Locally
```bash
cd web
npx serve .
# Or open web/index.html directly in any browser with zero build step!
```

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
