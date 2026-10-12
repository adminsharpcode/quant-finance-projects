# Mathematical Foundations of Quantitative Options Pricing, Greeks & Volatility Surfaces

This document details the first-principles mathematics underlying the pricing engine, numerical schemes, Greek risk sensitivities, volatility surface models (SVI and SABR), and relative-value arbitrage mechanics.

---

## 1. Continuous-Time Dynamics & The Black-Scholes PDE

### 1.1 Asset Price Stochastic Differential Equation (SDE)
We assume the underlying spot asset price $S_t$ follows Geometric Brownian Motion (GBM) under the physical probability measure $\mathbb{P}$:

$$dS_t = \mu S_t \, dt + \sigma S_t \, dW_t^\mathbb{P}$$

where:
- $\mu \in \mathbb{R}$ is the instantaneous expected rate of return (drift).
- $\sigma > 0$ is the constant instantaneous volatility.
- $W_t^\mathbb{P}$ is a standard 1D Brownian motion on the filtered probability space $(\Omega, \mathcal{F}, (\mathcal{F}_t)_{t \ge 0}, \mathbb{P})$.

### 1.2 Ito's Lemma for Derivative Pricing
Let $V(S, t) \in C^{2,1}((0, \infty) \times [0, T])$ denote the price of a European derivative on $S$. Applying Ito's formula to $V(S_t, t)$:

$$dV(S_t, t) = \frac{\partial V}{\partial t} dt + \frac{\partial V}{\partial S} dS_t + \frac{1}{2} \frac{\partial^2 V}{\partial S^2} (dS_t)^2$$

Using $(dt)^2 = 0$, $dt \cdot dW_t = 0$, and $(dW_t)^2 = dt$:

$$(dS_t)^2 = \left(\mu S_t dt + \sigma S_t dW_t\right)^2 = \sigma^2 S_t^2 dt$$

Substituting into the differential:

$$dV = \left( \frac{\partial V}{\partial t} + \mu S_t \frac{\partial V}{\partial S} + \frac{1}{2} \sigma^2 S_t^2 \frac{\partial^2 V}{\partial S^2} \right) dt + \sigma S_t \frac{\partial V}{\partial S} dW_t$$

### 1.3 Delta-Hedging & Elimination of Drift
Construct a continuous-time self-financing portfolio $\Pi_t$ consisting of:
- Long 1 unit of derivative $V(S_t, t)$.
- Short $\Delta_t$ units of underlying asset $S_t$.

$$\Pi_t = V(S_t, t) - \Delta_t S_t$$

Over an infinitesimal interval $dt$:

$$d\Pi_t = dV_t - \Delta_t dS_t$$

Substituting $dV$ and $dS_t$:

$$d\Pi_t = \left( \frac{\partial V}{\partial t} + \mu S_t \frac{\partial V}{\partial S} + \frac{1}{2} \sigma^2 S_t^2 \frac{\partial^2 V}{\partial S^2} - \Delta_t \mu S_t \right) dt + \sigma S_t \left( \frac{\partial V}{\partial S} - \Delta_t \right) dW_t$$

To eliminate the stochastic noise $dW_t$, choose the delta hedge ratio:

$$\Delta_t = \frac{\partial V}{\partial S}$$

The portfolio becomes locally risk-free:

$$d\Pi_t = \left( \frac{\partial V}{\partial t} + \frac{1}{2} \sigma^2 S_t^2 \frac{\partial^2 V}{\partial S^2} \right) dt$$

Under the absence of arbitrage (No-Arbitrage Principle / First Fundamental Theorem of Asset Pricing), any risk-free portfolio must earn the risk-free short rate $r$:

$$d\Pi_t = r \Pi_t dt = r \left( V - \frac{\partial V}{\partial S} S_t \right) dt$$

Equating the two expressions yields the **Black-Scholes-Merton Partial Differential Equation (PDE)**:

$$\frac{\partial V}{\partial t} + r S \frac{\partial V}{\partial S} + \frac{1}{2}\sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} - rV = 0$$

> **Crucial Observation**: The drift $\mu$ cancels out completely. The derivative's value is independent of risk preferences and depends solely on $S, K, T-t, r, \sigma$.

---

## 2. Commodity Futures & The Black-76 Model (CME / COMEX)

On exchanges like CME and COMEX (e.g. Gold `GC`, Crude Oil `CL`, E-mini `ES`), options are exercised into **Futures contracts**, not physical spot.

### 2.1 Futures Dynamics Under Risk-Neutral Measure $\mathbb{Q}$
A futures contract requires zero cash investment at inception (mark-to-market settlement). Consequently, under the risk-neutral measure $\mathbb{Q}$, the futures price $F_t$ is a martingale:

$$dF_t = \sigma F_t dW_t^\mathbb{Q}$$

Notice that the drift is identically zero ($0 \cdot dt$).

### 2.2 Derivation of the Black-76 Closed Form
For a European call option with strike $K$ and expiration $T$:

$$C_0 = e^{-rT} \mathbb{E}^\mathbb{Q} \left[ \max(F_T - K, 0) \right]$$

Since $\ln(F_T / F_0) \sim \mathcal{N}\left(-\frac{1}{2}\sigma^2 T, \sigma^2 T\right)$:

$$C_0 = e^{-rT} \left[ F_0 \Phi(d_1) - K \Phi(d_2) \right]$$
$$P_0 = e^{-rT} \left[ K \Phi(-d_2) - F_0 \Phi(-d_1) \right]$$

where:

$$d_1 = \frac{\ln(F_0 / K) + \frac{1}{2}\sigma^2 T}{\sigma \sqrt{T}}$$
$$d_2 = d_1 - \sigma \sqrt{T}$$

and $\Phi(x) = \frac{1}{\sqrt{2\pi}} \int_{-\infty}^x e^{-u^2/2} du$ is the standard normal cumulative distribution function (CDF).

---

## 3. Binomial Tree (Cox-Ross-Rubinstein Lattice) & American Options

CME and COMEX commodity options are typically **American-style**, allowing exercise at any time before expiration $T$. Because no general closed-form analytical solution exists for American options, we use the Cox-Ross-Rubinstein (CRR) discrete recombining lattice.

### 3.1 Parameterization
Discretize time into $N$ steps of length $\Delta t = T / N$. At each node, the price can move up by factor $u$ or down by factor $d$:

$$u = e^{\sigma \sqrt{\Delta t}}, \quad d = \frac{1}{u} = e^{-\sigma \sqrt{\Delta t}}$$

To ensure that the discounted futures price remains a martingale:
- For Spot Asset with dividend/convenience yield $q$:
  $$p = \frac{e^{(r - q)\Delta t} - d}{u - d}$$
- For Futures Asset (Black-76 lattice):
  $$p = \frac{1 - d}{u - d}$$

### 3.2 Backward Induction & The Snell Envelope
At terminal step $N$, the payoff for node $j \in \{0, 1, \dots, N\}$ is:

$$V_{N, j} = \max\left(\phi \cdot (F_0 u^j d^{N-j} - K), 0\right) \quad (\phi = 1 \text{ for Call}, -1 \text{ for Put})$$

At intermediate steps $i = N-1, N-2, \dots, 0$:
1. **Continuation Value** (discounted expected payoff):
   $$C_{i, j} = e^{-r \Delta t} \left[ p V_{i+1, j+1} + (1-p) V_{i+1, j} \right]$$
2. **Early Exercise Intrinsic Value**:
   $$E_{i, j} = \max\left(\phi \cdot (F_0 u^j d^{i-j} - K), 0\right)$$
3. **American Option Price**:
   $$V_{i, j} = \max\left(E_{i, j}, C_{i, j}\right)$$

This dynamic programming recursion implements the optimal stopping problem (Snell envelope), naturally identifying the early exercise boundary.

---

## 4. Monte Carlo Simulation Engine & Variance Reduction

### 4.1 Path Generation
Under the risk-neutral measure, log-prices evolve as:

$$S_{t_{k+1}} = S_{t_k} \exp\left( \left(r - q - \frac{1}{2}\sigma^2\right)\Delta t + \sigma \sqrt{\Delta t} Z_k \right), \quad Z_k \sim \mathcal{N}(0, 1)$$

For $M$ paths, the estimator of derivative price is:

$$\hat{V}_0 = e^{-rT} \frac{1}{M} \sum_{m=1}^M h(S_T^{(m)})$$

The standard error is given by:

$$\text{SE} = \frac{\hat{\sigma}_V}{\sqrt{M}}, \quad \hat{\sigma}_V^2 = \frac{1}{M-1} \sum_{m=1}^M \left(e^{-rT} h(S_T^{(m)}) - \hat{V}_0\right)^2$$

### 4.2 Variance Reduction: Antithetic Variates
Standard pseudo-random numbers generate statistical asymmetry in finite samples. We pair every Gaussian draw $Z_k$ with its mirror $-Z_k$:

$$S_T^{(m)+} = S_0 \exp\left( \nu T + \sigma \sqrt{T} Z \right)$$
$$S_T^{(m)-} = S_0 \exp\left( \nu T - \sigma \sqrt{T} Z \right)$$

The antithetic estimator is:

$$\hat{V}_{\text{anti}} = \frac{1}{M} \sum_{m=1}^{M/2} \frac{h(S_T^{(m)+}) + h(S_T^{(m)-})}{2}$$

Because $\text{Cov}\left(h(S^+), h(S^-)\right) \le 0$, the variance of the average is:

$$\operatorname{Var}\left(\frac{h^+ + h^-}{2}\right) = \frac{1}{4} \left[ \operatorname{Var}(h^+) + \operatorname{Var}(h^-) + 2 \operatorname{Cov}(h^+, h^-) \right] < \frac{1}{2} \operatorname{Var}(h)$$

This reduces sample variance by up to $60-80\%$ with negligible computational overhead.

---

## 5. Analytical Greeks: First, Second, and Cross Derivatives

The Greeks quantify sensitivities to state variables and model parameters.

| Greek | Mathematical Definition | Black-76 Formula (Call) | Financial / Risk Interpretation |
|---|---|---|---|
| **Delta** ($\Delta$) | $\frac{\partial V}{\partial F}$ | $e^{-rT}\Phi(d_1)$ | Units of underlying required to hedge first-order directional risk |
| **Gamma** ($\Gamma$) | $\frac{\partial^2 V}{\partial F^2}$ | $\frac{e^{-rT}\phi(d_1)}{F \sigma \sqrt{T}}$ | Curvature of Delta; rate at which delta-hedges must be rebalanced |
| **Vega** ($\mathcal{V}$) | $\frac{\partial V}{\partial \sigma}$ | $e^{-rT} F \sqrt{T} \phi(d_1)$ | Exposure to parallel shifts in implied volatility |
| **Theta** ($\Theta$) | $-\frac{\partial V}{\partial T}$ | $-\frac{e^{-rT}F\phi(d_1)\sigma}{2\sqrt{T}} + r e^{-rT}[F\Phi(d_1) - K\Phi(d_2)]$ | Calendar decay per calendar day elapsed |
| **Rho** ($\rho$) | $\frac{\partial V}{\partial r}$ | $-T \cdot V$ (for futures) | Sensitivity to changes in the risk-free benchmark discount curve |
| **Vanna** | $\frac{\partial^2 V}{\partial F \partial \sigma} = \frac{\partial \Delta}{\partial \sigma}$ | $-\frac{e^{-rT}\phi(d_1) d_2}{\sigma}$ | Cross-sensitivity: how delta drifts when volatility spikes |
| **Volga (Vomma)** | $\frac{\partial^2 V}{\partial \sigma^2} = \frac{\partial \mathcal{V}}{\partial \sigma}$ | $\mathcal{V} \frac{d_1 d_2}{\sigma}$ | Convexity of Vega; critical for wing and smile tail-risk management |

*(Note: $\phi(x) = \frac{1}{\sqrt{2\pi}} e^{-x^2 / 2}$ denotes the standard normal probability density function).*

---

## 6. Implied Volatility Inversion: Vectorized Newton-Raphson & Brent

Observed market prices $C_{\text{mkt}}$ must be inverted to find the Black-Scholes implied volatility $\sigma_{\text{imp}}$:

$$f(\sigma) = V_{\text{model}}(\sigma) - C_{\text{mkt}} = 0$$

### 6.1 Newton-Raphson Step
The gradient-based iteration is:

$$\sigma_{n+1} = \sigma_n - \frac{V(\sigma_n) - C_{\text{mkt}}}{\mathcal{V}(\sigma_n)}$$

### 6.2 Degeneracy in the Wings & Stefanica-Rados / Brent Hybrid
When $|k| = |\ln(K/F)| \gg 0$ or $T \to 0$, Vega approaches machine epsilon:

$$\lim_{|d_1| \to \infty} \mathcal{V}(\sigma) = 0$$

Dividing by near-zero causes standard Newton-Raphson to diverge to infinity or NaN.

**Our Institutional Engine Solution**:
1. Compute the **Corrado-Miller / Stefanica-Rados** rational approximation to initialize $\sigma_0$ close to the root.
2. Execute bounded Newton-Raphson iterations with step clipping.
3. Fallback automatically to **Brent's method** (guaranteed superlinear bracketing algorithm combining bisection, secant, and inverse quadratic interpolation) if Newton fails to converge within tolerance $\epsilon = 10^{-7}$.

---

## 7. Volatility Surface Calibration: SVI & SABR

Exchange-traded options exhibit a pronounced "smile" or "skew" (out-of-the-money puts trade at higher implied vols due to crash risk and downside leverage). A flat Black-Scholes volatility surface is invalid.

### 7.1 Gatheral's Stochastic Volatility Inspired (SVI) Model
Jim Gatheral (2004) proved that total implied variance $w(k, \tau) = \sigma^2(k, \tau) \tau$ as a function of log-moneyness $k = \ln(K/F)$ can be parameterized as:

$$w(k) = a + b \left( \rho (k - m) + \sqrt{(k - m)^2 + \sigma^2} \right)$$

where the parameters have intuitive geometric meanings:
- $a \in \mathbb{R}$: Overall vertical variance level (shifts entire curve up/down).
- $b > 0$: Angle between the left and right asymptotes (overall smile steepness).
- $\rho \in (-1, 1)$: Asymmetry / orientation of the skew ($\rho < 0$ for equity/commodity downside skew).
- $m \in \mathbb{R}$: Horizontal translation (location of the minimum variance point).
- $\sigma > 0$: Smoothness / curvature of the vertex around $k = m$.

#### Arbitrage-Free Constraints:
To guarantee that the calibrated surface contains **no butterfly arbitrage** (i.e., risk-neutral density $g(k) \ge 0$) and **no calendar arbitrage** ($\frac{\partial w}{\partial \tau} \ge 0$):
1. $b \ge 0$
2. $|\rho| < 1$
3. $\sigma > 0$
4. $a + b \sigma \sqrt{1 - \rho^2} \ge 0$ (total variance strictly non-negative everywhere)
5. $b(1 + |\rho|) < 4$ (wing slope constraint preventing negative call prices at infinity)

### 7.2 Hagan's SABR Stochastic Volatility Model
The SABR (Stochastic Alpha Beta Rho) model (Hagan et al., 2002) is the interest rate and commodity futures standard:

$$dF_t = \alpha_t F_t^\beta dW_{1,t}$$
$$d\alpha_t = \nu \alpha_t dW_{2,t}$$
$$d\langle W_1, W_2 \rangle_t = \rho dt$$

where:
- $\alpha$: Initial instantaneous volatility.
- $\beta \in [0, 1]$: Elasticity parameter ($\beta = 1$ is log-normal, $\beta = 0$ is normal/Bachelier).
- $\nu$: Volatility of volatility (controls smile curvature/wings).
- $\rho \in [-1, 1]$: Correlation between forward price and volatility (controls skew slope).

The celebrated Hagan asymptotic formula approximates the implied Black-76 volatility $\sigma_{\text{SABR}}(K, F)$:

$$\sigma_{\text{SABR}}(K, F) \approx \frac{\alpha}{(F K)^{(1-\beta)/2} \left[ 1 + \frac{(1-\beta)^2}{24} \ln^2\left(\frac{F}{K}\right) + \frac{(1-\beta)^4}{1920} \ln^4\left(\frac{F}{K}\right) \right]} \cdot \left(\frac{z}{x(z)}\right) \cdot \left[ 1 + \left( \frac{(1-\beta)^2}{24}\frac{\alpha^2}{(FK)^{1-\beta}} + \frac{1}{4}\frac{\rho \beta \nu \alpha}{(FK)^{(1-\beta)/2}} + \frac{2-3\rho^2}{24}\nu^2 \right) T \right]$$

where:

$$z = \frac{\nu}{\alpha} (F K)^{(1-\beta)/2} \ln\left(\frac{F}{K}\right)$$
$$x(z) = \ln\left( \frac{\sqrt{1 - 2\rho z + z^2} + z - \rho}{1 - \rho} \right)$$

---

## 8. Quantitative Edge: Relative-Value Volatility Arbitrage

### 8.1 The Core Thesis
Market quotes are contaminated by order-book microstructure noise:
- Bid-ask bouncing
- Illiquid strikes / dealer inventory hedging premia
- Retail demand skew in out-of-the-money puts/calls

A calibrated, arbitrage-free parametric surface (SVI/SABR) acts as a **maximum-likelihood estimator of fair value** across the joint strike-expiry continuum.

### 8.2 Mispricing Metric: Volatility Spread Z-Score
For each strike $K_i$ and expiration $T_j$:

$$\Delta \sigma_{i, j} = \sigma_{\text{market\_mid}}(K_i, T_j) - \sigma_{\text{surface}}(K_i, T_j)$$

Normalize by the market quoted bid-ask volatility spread:

$$\text{Edge Ratio} = \frac{|\Delta \sigma_{i, j}|}{\sigma_{\text{ask}} - \sigma_{\text{bid}}}$$

### 8.3 Execution Strategies
1. **Delta-Neutral Volatility Capture**:
   - When $\sigma_{\text{market}} > \sigma_{\text{surface}} + \text{Spread}$ (Overpriced):
     - **Sell** the overpriced market option.
     - **Delta-hedge** with futures contracts: $\Delta_{\text{hedge}} = -\Delta_{\text{option}}$.
     - Collect theta while delta-hedging dynamically. As implied vol mean-reverts to the surface, capture pure variance premium.
   - When $\sigma_{\text{market}} < \sigma_{\text{surface}} - \text{Spread}$ (Underpriced):
     - **Buy** the underpriced option.
     - **Delta-hedge** with futures contracts.
     - Long gamma position with subsidized cost of carry.
2. **Butterfly Arbitrage**:
   - If market density $g(K) < 0$ at any strike triplet $\{K-\Delta K, K, K+\Delta K\}$, execute a butterfly spread (Long wings, Short body) to harvest risk-free static arbitrage.
