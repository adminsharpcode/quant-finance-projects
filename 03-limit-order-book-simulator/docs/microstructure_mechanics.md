# Market Microstructure & High-Frequency Market Making Mechanics

This document establishes the mathematical foundations of electronic limit order books (LOB), continuous double auctions, the Avellaneda-Stoikov optimal inventory market making model, adverse selection metrics (Kyle's $\lambda$, Hasbrouck drift), Order Flow Imbalance (OFI), and Volume-Synchronized Probability of Toxicity (VPIN).

---

## 1. Electronic Limit Order Book Architecture

An electronic Limit Order Book (LOB) is a continuous double auction mechanism operating under strict **Price-Time Priority (FIFO)**.

### 1.1 State Space Representation
At any time $t \ge 0$, the state of the book is characterized by two discrete sets of open limit orders:

$$\mathcal{B}_t = \{(p_i^b, v_i^b)\}_{i=1}^{N_b}, \quad \mathcal{A}_t = \{(p_j^a, v_j^a)\}_{j=1}^{N_a}$$

where:
- $p_1^b > p_2^b > \dots > p_{N_b}^b$ represents the descending sorted schedule of buy limit orders (**Bids**).
- $p_1^a < p_2^a < \dots < p_{N_a}^a$ represents the ascending sorted schedule of sell limit orders (**Asks**).
- The **Best Bid** and **Best Ask** are denoted by:

$$S_t^b = \max_{i} p_i^b = p_1^b, \quad S_t^a = \min_{j} p_j^a = p_1^a$$

- The **Bid-Ask Spread** $\Phi_t$ and **Mid-Price** $S_t$ satisfy:

$$\Phi_t = S_t^a - S_t^b \ge \Delta p_{tick}$$

$$S_t = \frac{S_t^a + S_t^b}{2}$$

where $\Delta p_{tick}$ is the minimum exchange price increment (tick size).

### 1.2 Micro-Price (Volume-Weighted Midpoint)
To account for immediate order book queue imbalance, the **Micro-Price** $P_t^{\text{micro}}$ weights quotes by available top-of-book depth:

$$P_t^{\text{micro}} = \frac{v_1^b S_t^a + v_1^a S_t^b}{v_1^b + v_1^a} = S_t + \left( \frac{v_1^b - v_1^a}{v_1^b + v_1^a} \right) \frac{\Phi_t}{2}$$

The micro-price serves as a leading Martingale indicator of the next mid-price tick direction: when $v_1^b \gg v_1^a$, $P_t^{\text{micro}} \to S_t^a$, signaling an imminent upward tick.

---

## 2. The Avellaneda-Stoikov (2008) Market Making Model

The canonical high-frequency market making model solves the stochastic control problem of an agent quoting two-sided limit orders under inventory risk.

### 2.1 Mid-Price & Inventory Dynamics
Let $S_t$ be the mid-price following a driftless arithmetic Brownian motion on $[0, T]$:

$$dS_t = \sigma dW_t$$

where $\sigma$ is mid-price return volatility and $W_t$ is a standard Brownian motion.

The market maker posts a bid at distance $\delta_t^b = S_t - p_t^b$ and an ask at distance $\delta_t^a = p_t^a - S_t$.

The agent's inventory $q_t \in \mathbb{Z}$ and cash balance $X_t$ evolve via point processes $N_t^a, N_t^b$:

$$dq_t = dN_t^b - dN_t^a$$

$$dX_t = (S_t + \delta_t^a) dN_t^a - (S_t - \delta_t^b) dN_t^b$$

### 2.2 Execution Arrival Intensities
The arrival of taker market orders that fill the agent's quotes follows Poisson intensities decreasing exponentially with distance from the mid:

$$\lambda^a(\delta^a) = A e^{-\kappa \delta^a}, \quad \lambda^b(\delta^b) = A e^{-\kappa \delta^b}$$

where:
- $A$ represents overall market trading activity (orders per second).
- $\kappa$ parameterizes order book depth elasticity and liquidity concentration.

### 2.3 Optimization Objective & HJB Equation
The market maker maximizes expected terminal utility of wealth with constant absolute risk aversion (CARA) $\gamma > 0$:

$$v(x, q, s, t) = \sup_{\delta^a, \delta^b} \mathbb{E} \left[ -e^{-\gamma (X_T + q_T S_T - \alpha q_T^2)} \;\Big|\; X_t=x, q_t=q, S_t=s \right]$$

Applying dynamic programming yields the Hamilton-Jacobi-Bellman (HJB) PDE:

$$\partial_t v + \frac{1}{2} \sigma^2 \partial_{ss} v + \max_{\delta^a} \lambda^a(\delta^a) \left[ v(x + s + \delta^a, q-1, s, t) - v(x, q, s, t) \right] + \max_{\delta^b} \lambda^b(\delta^b) \left[ v(x - s + \delta^b, q+1, s, t) - v(x, q, s, t) \right] = 0$$

Using the ansatz $v(x, q, s, t) = -e^{-\gamma x} e^{-\gamma \theta(s, q, t)}$ and computing the indifference pricing boundary yields the closed-form **Reservation (Indifference) Price** $r(s, q, t)$:

$$r(s, q, t) = s - q \gamma \sigma^2 (T - t)$$

### 2.4 Optimal Quoting Spreads
The total optimal bid-ask spread $\delta^a + \delta^b$ and individual optimal quote distances are:

$$\delta_t^a + \delta_t^b = \gamma \sigma^2 (T - t) + \frac{2}{\gamma} \ln\left(1 + \frac{\gamma}{\kappa}\right)$$

$$p_t^a = r(s, q, t) + \frac{1}{2} \left[ \gamma \sigma^2 (T - t) + \frac{2}{\gamma} \ln\left(1 + \frac{\gamma}{\kappa}\right) \right] = s + \frac{1}{\gamma}\ln\left(1 + \frac{\gamma}{\kappa}\right) + \frac{1 - 2q}{2} \gamma \sigma^2 (T - t)$$

$$p_t^b = r(s, q, t) - \frac{1}{2} \left[ \gamma \sigma^2 (T - t) + \frac{2}{\gamma} \ln\left(1 + \frac{\gamma}{\kappa}\right) \right] = s - \frac{1}{\gamma}\ln\left(1 + \frac{\gamma}{\kappa}\right) - \frac{1 + 2q}{2} \gamma \sigma^2 (T - t)$$

### 2.5 Intuition of Inventory Shading:
- When $q > 0$ (long inventory), $r(s, q, t) < s$. The market maker lowers both quotes, making the ask more attractive to aggressive buyers and shading the bid further away from the market to prevent accumulating more long positions.
- When $q < 0$ (short inventory), $r(s, q, t) > s$. The market maker raises both quotes to attract selling market orders.

---

## 3. Order Flow Imbalance (OFI) - Cont, Kukanov, Stoikov (2014)

Order Flow Imbalance measures net changes in volume at the best bid and ask over consecutive order book events:

$$e_k = I_{\{S_k^b \ge S_{k-1}^b\}} v_k^b - I_{\{S_k^b \le S_{k-1}^b\}} v_{k-1}^b - I_{\{S_k^a \le S_{k-1}^a\}} v_k^a + I_{\{S_k^a \ge S_{k-1}^a\}} v_{k-1}^a$$

where:
- When the bid price rises ($S_k^b > S_{k-1}^b$), all volume $v_k^b$ is new aggressive buying demand ($+v_k^b$).
- When the bid price drops ($S_k^b < S_{k-1}^b$), the prior volume was consumed or cancelled ($-v_{k-1}^b$).
- When the bid price is unchanged ($S_k^b = S_{k-1}^b$), the contribution is the delta $v_k^b - v_{k-1}^b$.

Linear contemporaneous price impact regression:

$$\Delta S_k = \beta \cdot \text{OFI}_k + \epsilon_k$$

where $\beta$ measures the **empirical market depth elasticity** (price change per share of imbalance).

---

## 4. Volume-Synchronized Probability of Toxicity (VPIN)

Developed by Easley, López de Prado, and O'Hara (2012), VPIN quantifies order flow toxicity based on trade volume buckets:

### 4.1 Volume Bucket Construction
Trades are partitioned into equal volume buckets of constant size $V$ (e.g., $V = 10,000$ shares). Within each bucket $\tau$, trades are classified into buy volume $V_\tau^B$ and sell volume $V_\tau^S$ using the tick rule or BVC (Bulk Volume Classification):

$$V_\tau^B = \sum_{i \in \tau} v_i \cdot \Phi\left( \frac{P_i - P_{i-1}}{\sigma_{\Delta P}} \right), \quad V_\tau^S = V - V_\tau^B$$

### 4.2 VPIN Formula
Across a rolling window of $N$ volume buckets:

$$\text{VPIN} = \frac{\sum_{\tau=1}^N |V_\tau^B - V_\tau^S|}{N \cdot V}$$

- $\text{VPIN} \in [0, 1]$.
- In normal balanced markets, $\text{VPIN} \approx 0.15 - 0.25$.
- When informed traders aggressively sweep quotes prior to major market movements, $\text{VPIN} > 0.60$, triggering an automated quote withdrawal or spread widening in our simulator.

---

## 5. PnL Attribution in High-Frequency Market Making

Every filled trade generates exposure that is quantitatively decomposed into:

$$\text{Total PnL} = \Pi_{\text{spread}} + \Pi_{\text{inventory}} - \Pi_{\text{adverse}} + \Pi_{\text{rebate}}$$

1. **Spread Capture ($\Pi_{\text{spread}}$)**:
   $$\Pi_{\text{spread}} = \sum_{t} \text{Volume}_t \cdot \frac{\Phi_t}{2}$$
2. **Inventory Mark-to-Market ($\Pi_{\text{inventory}}$)**:
   $$\Pi_{\text{inventory}} = \int_0^T q_t \, dS_t$$
3. **Adverse Selection Cost ($\Pi_{\text{adverse}}$)**:
   $$\Pi_{\text{adverse}} = \sum_{i} \text{Sign}_i \cdot q_i \cdot (S_{t_i + \tau} - S_{t_i})$$
   where $\tau$ is a short evaluation horizon (e.g., 5 seconds / 20 events). If the price drifts against the maker post-fill, this cost is positive.
4. **Exchange Maker-Taker Rebate ($\Pi_{\text{rebate}}$)**:
   Maker rebates earned on passive limit fills vs. taker fees paid on aggressive hedge orders.
