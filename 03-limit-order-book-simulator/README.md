# High-Frequency Limit Order Book (LOB) Simulator & Market Making Engine

[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![Status: Day 3 Blueprint](https://img.shields.io/badge/Status-Day%203%20Blueprint-orange.svg)]()
[![Focus: Prop Trading](https://img.shields.io/badge/Target-Jane%20Street%20%7C%20Citadel%20Securities%20%7C%20Optiver-red.svg)]()

> **Quant Series Project 03**: Event-driven L2/L3 order book matching engine simulating high-frequency market making, optimal spread quoting via Avellaneda-Stoikov, queue-position tracking, adverse selection, and inventory risk controls.

---

## 🏛️ Project Architecture & Layout

```
03-limit-order-book-simulator/
├── README.md                          # Microstructure theory & matching engine spec
├── requirements.txt                   # numpy, pandas, numba, sortedcontainers, rich
├── docs/
│   └── microstructure_mechanics.md    # Avellaneda-Stoikov, Hawkes process, Queue reactive models
├── data/
│   ├── sample_itch_orders.csv         # Reconstructed L3 message feed (Add, Cancel, Execute)
│   └── lob_snapshot_l2.csv            # 10-level bid/ask depth snapshots
├── src/
│   ├── engine/
│   │   ├── order.py                   # Order struct (id, side, price, qty, timestamp)
│   │   ├── price_level.py             # Doubly-linked list / FIFO queue per tick
│   │   ├── order_book.py              # Bids & Asks sorted maps with O(1) cancel/lookup
│   │   └── matching_engine.py         # Cross-matching logic & trade event generator
│   ├── market_maker/
│   │   ├── avellaneda_stoikov.py      # Optimal reservation price & spread quotation
│   │   ├── inventory_manager.py       # Inventory skew adjustments & position caps
│   │   └── adverse_selection.py       # Informed flow detection & Kyle's lambda estimation
│   ├── metrics/
│   │   ├── ofi.py                     # Order Flow Imbalance (OFI) time-series
│   │   ├── vpin.py                    # Volume-Synchronized Probability of Toxicity
│   │   └── pnl_attribution.py         # Spread capture vs adverse selection vs liquidation loss
│   └── simulation/
│       ├── order_arrival_poisson.py   # Stochastic arrival process for retail/institutional orders
│       └── hawkes_arrival.py          # Mutually exciting Hawkes clustering process
├── scripts/
│   ├── run_lob_simulation.py          # Live terminal simulation with visual depth ladder
│   └── analyze_market_maker_pnl.py    # Sharp ratio, inventory drift, and spread capture analysis
└── tests/
    ├── test_order_book.py             # FIFO execution, cancellation, price-time priority
    ├── test_matching_engine.py
    └── test_avellaneda_stoikov.py
```

---

## 🎯 What Makes This Interview-Ready (2026 Standards)
1. **Avellaneda-Stoikov (2008) Reservation Price**:
   $$r(s, q, t) = s - q \gamma \sigma^2 (T - t)$$
   Optimal half-spreads $\delta^a, \delta^b$ dynamically adjust when inventory $q$ builds up, shading quotes to attract offset volume.
2. **Microstructure Adverse Selection Metric**: Distinguishes between uninformed flow (spread profit) and toxic order flow (price moves through quotes).
3. **High-Speed Architecture**: Implemented with `sortedcontainers` and typed Python/NumPy structures replicating C++ matching engine logic.
4. **Target Role Alignment**: Directly targets Quantitative Trading and Automated Market Making (AMM) interview assessments.
