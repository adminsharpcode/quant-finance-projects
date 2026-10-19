# High-Frequency Limit Order Book (LOB) Simulator & Avellaneda-Stoikov Market Making Engine

[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![Tests: 18 Passed](https://img.shields.io/badge/tests-18%20passed-brightgreen.svg)]()
[![Status: Production Ready](https://img.shields.io/badge/Status-Complete%20%26%20Deployed-brightgreen.svg)]()
[![Target: HFT & AMM Desks](https://img.shields.io/badge/Target-Jane%20Street%20%7C%20Citadel%20Securities%20%7C%20Optiver-red.svg)]()

> **Quant Finance Series — Project 03**: An institutional-grade Limit Order Book matching engine and algorithmic market making simulator. Implements continuous double auction matching (FIFO price-time priority), Avellaneda-Stoikov optimal inventory-risk quoting, Order Flow Imbalance (OFI), Volume-Synchronized Probability of Toxicity (VPIN), Kyle's Lambda adverse selection, and an interactive TradingView-powered simulation desk.

---

## 🏛️ System Architecture

```
03-limit-order-book-simulator/
├── README.md                          # Architecture, mathematical models & deployment guide
├── requirements.txt                   # numpy, pandas, scipy, sortedcontainers, rich, pytest
├── docs/
│   └── microstructure_mechanics.md    # Full HJB derivations, Avellaneda-Stoikov, OFI, VPIN
├── data/
│   ├── sample_itch_orders.csv         # 3,000 reconstructed NASDAQ ITCH messages (Add, Cancel, Execute)
│   └── lob_snapshot_l2.csv            # 10-level multi-depth L2 order book snapshots
├── src/
│   ├── engine/
│   │   ├── order.py                   # Order struct (id, side, price, qty, timestamp, TIF)
│   │   ├── price_level.py             # FIFO order queue per tick with dynamic volume aggregation
│   │   ├── order_book.py              # Dual SortedDict order book with O(1) cancel & micro-price
│   │   └── matching_engine.py         # Continuous double auction & trade event generator
│   ├── market_maker/
│   │   ├── avellaneda_stoikov.py      # Finite-horizon & stationary Avellaneda-Stoikov quoting
│   │   ├── inventory_manager.py       # Inventory skew adjustments, cash, and PnL accounting
│   │   └── adverse_selection.py       # Informed flow detection & Kyle's lambda estimation
│   ├── metrics/
│   │   ├── ofi.py                     # Order Flow Imbalance (Cont et al. 2014) & β regression
│   │   ├── vpin.py                    # Volume-Synchronized Probability of Toxicity (Easley et al. 2012)
│   │   └── pnl_attribution.py         # Spread capture vs inventory drift vs adverse selection
│   └── simulation/
│       ├── order_arrival_poisson.py   # Stochastic arrival process for retail & taker sweeps
│       └── hawkes_arrival.py          # Mutually exciting Hawkes clustering process (Ogata thinning)
├── scripts/
│   ├── run_lob_simulation.py          # Real-time CLI depth ladder with Rich terminal visualization
│   └── analyze_market_maker_pnl.py    # Benchmark: Avellaneda-Stoikov vs Naive Fixed-Spread MM
├── tests/
│   ├── test_order_book.py             # FIFO execution, queue positioning, cancellation
│   ├── test_matching_engine.py        # Market sweeps, crossing limits, IOC cancellation
│   ├── test_avellaneda_stoikov.py     # Reservation price monotonicity, skew shading, boundary caps
│   └── test_metrics.py                # OFI delta, VPIN volume buckets, PnL decomposition
└── web/
    ├── index.html                     # TradingView candlestick desk, L2 depth ladder, AS MM controls
    ├── styles.css                     # Institutional dark terminal theme (#070c18) & CSS grid
    ├── app.js                         # In-browser matching engine, real-time AS solver, trade tape
    ├── vercel.json                    # Edge caching & serverless rewrite configuration
    └── api/
        └── quotes.js                  # Multi-asset real-time quote feed (SPY, QQQ, NVDA, AAPL, BTC)
```

---

## 📐 Core Microstructure Mathematics

### 1. Avellaneda-Stoikov (2008) Reservation Price
A market maker holding inventory $q$ at time $t$ with terminal horizon $T$, subject to price volatility $\sigma$ and risk aversion $\gamma$, prices mid-market indifference as:

$$r(s, q, t) = s - q \gamma \sigma^2 (T - t)$$

- When **long** ($q > 0$): $r(s,q,t) < s$ $\implies$ quote bids and asks lower to attract buyers and deter sellers.
- When **short** ($q < 0$): $r(s,q,t) > s$ $\implies$ quote bids and asks higher to attract sellers and deter buyers.

### 2. Optimal Quoting Spreads
Given order fill Poisson arrival intensity $\lambda(\delta) = A e^{-\kappa \delta}$, the optimal bid and ask spreads are:

$$\delta^a(s, q, t) = r(s, q, t) - s + \frac{1}{\gamma} \ln\left(1 + \frac{\gamma}{\kappa}\right)$$

$$\delta^b(s, q, t) = s - r(s, q, t) + \frac{1}{\gamma} \ln\left(1 + \frac{\gamma}{\kappa}\right)$$

Total optimal spread:
$$s^*(t) = \delta^a + \delta^b = \frac{2}{\gamma} \ln\left(1 + \frac{\gamma}{\kappa}\right)$$

In stationary formulation (Guéant, Tapia & Manziadi 2012):
$$\delta^a(q) = \frac{1}{\kappa} + \frac{1}{2} (2q + 1) \gamma \sigma^2, \quad \delta^b(q) = \frac{1}{\kappa} - \frac{1}{2} (2q - 1) \gamma \sigma^2$$

### 3. Volume-Weighted Micro-Price
Incorporates queue imbalance across best bid ($P_b, V_b$) and best ask ($P_a, V_a$):

$$P_{micro} = \frac{V_b P_a + V_a P_b}{V_b + V_a}$$

### 4. Order Flow Imbalance (OFI - Cont, Kukanov & Stoikov 2014)
Measures net directional order book pressure:

$$OFI_n = I_{\{P_{b,n} \ge P_{b,n-1}\}} V_{b,n} - I_{\{P_{b,n} \le P_{b,n-1}\}} V_{b,n-1} - I_{\{P_{a,n} \le P_{a,n-1}\}} V_{a,n} + I_{\{P_{a,n} \ge P_{a,n-1}\}} V_{a,n-1}$$

Linear price impact relationship:
$$\Delta P_n = \beta \cdot OFI_n + \varepsilon_n$$

### 5. Volume-Synchronized Probability of Toxicity (VPIN - Easley et al. 2012)
Measures the proportion of informed volume across $N$ equal-volume buckets:

$$VPIN = \frac{\sum_{\tau=1}^N |V_\tau^B - V_\tau^S|}{N \cdot V}$$

---

## ⚡ Quick Start & CLI Execution

### 1. Install Dependencies
```bash
python -m pip install -r requirements.txt
```

### 2. Run All Tests
```bash
python -m pytest tests/ -v
# 18 passed in 0.18s
```

### 3. Real-Time Terminal Order Book Ladder
```bash
python scripts/run_lob_simulation.py --steps 50 --speed 0.05
```

### 4. Market Maker PnL & Attribution Benchmark
```bash
python scripts/analyze_market_maker_pnl.py
```

---

## 🌐 Web Application & Live Deployment

The interactive web simulator features:
- **TradingView Real-Time Candlestick Chart**: Multi-asset feeds (SPY, QQQ, NVDA, AAPL, BTC/USDT).
- **Interactive Level 2 Depth Ladder**: Dual bid/ask book with proportional liquidity volume bars and real-time spread metrics.
- **Avellaneda-Stoikov MM Desk**: Dynamic controls for risk aversion $\gamma$, liquidity intensity $\kappa$, asset volatility $\sigma$, inventory cap $Q_{max}$, and model formulation (Finite vs. Stationary).
- **Direct Order Entry Ticket**: Submit manual Limit / Market orders with Peg Bid/Ask shortcuts, GTC/IOC execution, and instant execution response.
- **Microstructure Telemetry**: Real-time Mid vs. Micro-price, Spread in basis points, Cont OFI, Easley VPIN toxicity, inventory skew, and Sharpe ratio.
- **PnL Attribution Blotter**: Decomposes performance into Spread Capture, Inventory Drift MTM, Adverse Selection Drag, and Exchange Maker Rebates.

Run locally:
```bash
cd web
npx serve .
```
Deploy to Vercel:
```bash
cd web
npx vercel --prod
```
