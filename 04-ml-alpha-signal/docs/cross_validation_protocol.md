# Leakage-Free Walk-Forward Validation Protocol & Factor Architecture

This document establishes the mathematical foundations, statistical failure modes, and algorithmic safeguards governing **Project 04: Machine Learning Alpha Signal Engine**. It details Marcos López de Prado's Purged Cross-Validation with Embargo, cross-sectional factor neutralization, evaluation metrics, and TreeSHAP attribution.

---

## 1. The Financial Machine Learning Failure Mode

In standard tabular machine learning, observations $(x_i, y_i)$ are assumed to be **Independent and Identically Distributed (I.I.D.)**. Standard $K$-fold cross-validation randomly partitions indices $\{1, \dots, N\}$ into $K$ disjoint subsets.

In quantitative finance, this assumption is catastrophically violated due to three distinct structural mechanisms:

### 1.1 Overlapping Label Return Windows
When predicting forward returns over a multi-period horizon $\tau$ (e.g., $\tau = 5$ trading days):

$$y_{i, t} = \frac{P_{i, t+\tau} - P_{i, t}}{P_{i, t}}$$

The label for time $t$ spans the interval $[t, t+\tau]$. If an observation at $t+1$ is allocated to the training set while observation $t$ is allocated to the test set:
- The training label $y_{i, t+1} = \frac{P_{i, t+1+\tau} - P_{i, t+1}}{P_{i, t+1}}$ shares $\tau - 1$ days of identical market price trajectories with test label $y_{i, t}$.
- Information from the test label directly leaks into the training objective, yielding artificially inflated Sharpe ratios and out-of-sample breakdown in live trading.

### 1.2 Serial Autocorrelation in Features
Even if labels do not overlap, continuous features such as rolling moving averages, historical volatility estimators, and microstructure indicators exhibit high autoregressive persistence:

$$x_t = \phi x_{t-1} + \varepsilon_t, \quad |\phi| \approx 1$$

Randomly interleaving train and test folds allows the model to interpolate between adjacent temporal samples rather than learning genuine predictive patterns.

### 1.3 Combinatorial Overfitting & Backtest Sifting
Testing thousands of factor combinations across the same unpurged historical dataset guarantees discovering statistically spurious relationships (Harvey, Liu & Zhu 2016).

---

## 2. Marcos López de Prado's Purging and Embargo Framework

To restore statistical validity to time-series cross-validation without discarding the efficiency of cross-fold evaluation, we implement **Purged Group Time-Series Split with Embargo** (López de Prado, *Advances in Financial Machine Learning*, 2018).

### 2.1 Formal Definitions
Let each sample $i \in \{1, \dots, N\}$ be defined by:
- Feature generation timestamp: $t_{i, 0}$ (the moment the prediction is made).
- Label evaluation window: $[t_{i, 0}, t_{i, 1}]$ where $t_{i, 1} = t_{i, 0} + \tau$.

Let $\mathcal{I}_{\text{test}} \subset \{1, \dots, N\}$ denote the set of indices assigned to a test fold. The test evaluation time interval is bounded by:

$$T_{0, \text{test}} = \min_{j \in \mathcal{I}_{\text{test}}} t_{j, 0}, \quad T_{1, \text{test}} = \max_{j \in \mathcal{I}_{\text{test}}} t_{j, 1}$$

### 2.2 The Purging Operator
Any training candidate $i \in \mathcal{I}_{\text{train}}^{\text{raw}}$ whose label window $[t_{i, 0}, t_{i, 1}]$ overlaps with the test evaluation span $[T_{0, \text{test}}, T_{1, \text{test}}]$ must be purged:

$$\mathcal{I}_{\text{train}}^{\text{purged}} = \left\{ i \in \mathcal{I}_{\text{train}}^{\text{raw}} \;\middle|\; t_{i, 1} < T_{0, \text{test}} \quad \text{or} \quad t_{i, 0} > T_{1, \text{test}} \right\}$$

This condition guarantees that no training sample contains forward information generated during the test period.

### 2.3 The Embargo Operator
Because financial time series possess autoregressive memory, training samples generated immediately *after* the test set may still carry residual information from the test horizon.

To eliminate this post-test leak, an **Embargo Buffer** of length $h$ is applied immediately after $T_{1, \text{test}}$:

$$h = \lfloor \varepsilon \cdot N_{\text{dates}} \rfloor$$

where $\varepsilon \in [0.01, 0.05]$ is the embargo parameter (typically 1% to 5% of total observation dates). Any training sample occurring within the embargo window is discarded:

$$\mathcal{I}_{\text{train}}^{\text{final}} = \left\{ i \in \mathcal{I}_{\text{train}}^{\text{purged}} \;\middle|\; t_{i, 0} < T_{0, \text{test}} \quad \text{or} \quad t_{i, 0} > T_{1, \text{test}} + h \right\}$$

```
Temporal Timeline:
[------ TRAIN SET ------] [ PURGE ] [=== TEST SET ===] [ EMBARGO ] [------ TRAIN SET ------]
                          <--tau-->                    <----h---->
```

---

## 3. Alpha Factor Mathematics & Extraction

Our engine extracts orthogonal factor families representing distinct economic and structural drivers.

### 3.1 Volatility Estimators
Standard sample volatility $\sigma_{CC}$ using close-to-close returns ignores extreme intraday path information. We compute continuous-diffusion estimators:

#### Parkinson Volatility (1980)
Measures diffusion using high and low prices under zero drift:

$$\sigma_P = \sqrt{ \frac{252}{4 \ln 2 \cdot n} \sum_{t=1}^n \left( \ln \frac{H_t}{L_t} \right)^2 }$$

Parkinson volatility is approximately $5\times$ more statistically efficient than standard close-to-close volatility.

#### Garman-Klass Volatility (1980)
Extends Parkinson to account for opening and closing jumps:

$$\sigma_{GK} = \sqrt{ \frac{252}{n} \sum_{t=1}^n \left[ 0.5 \left( \ln \frac{H_t}{L_t} \right)^2 - (2\ln 2 - 1) \left( \ln \frac{C_t}{O_t} \right)^2 \right] }$$

Garman-Klass is up to $8\times$ more efficient than close-to-close variance.

#### Yang-Zhang Volatility (2000)
A minimum-variance unbiased estimator that handles both overnight jumps and intraday drift:

$$\sigma_{YZ}^2 = \sigma_{\text{open}}^2 + k \sigma_{\text{close}}^2 + (1-k) \sigma_{RS}^2$$

$$k = \frac{0.34}{1.34 + \frac{n+1}{n-1}}$$

$$\sigma_{RS}^2 = \frac{1}{n} \sum_{t=1}^n \left[ \ln \frac{H_t}{C_t} \ln \frac{H_t}{O_t} + \ln \frac{L_t}{C_t} \ln \frac{L_t}{O_t} \right]$$

### 3.2 Momentum & Reversal Factors
- **Short-Term Reversal**: 1-day and 5-day negative return exposure:
  $$\text{Rev}_5(t) = - \frac{P_t - P_{t-5}}{P_{t-5}}$$
- **Dual Intermediate Momentum**: Cumulative return over $[t-60, t-5]$, intentionally skipping the most recent 5 days to isolate pure trend from microstructure reversal.
- **Residual Momentum (Blitz et al. 2011)**: Asset return residual after orthogonalizing against market benchmark returns:
  $$R_{i, t} = \alpha_i + \beta_i R_{m, t} + \varepsilon_{i, t}$$
  Cumulative residual $\sum_{k=5}^{60} \varepsilon_{i, t-k}$ captures pure firm-specific alpha.

### 3.3 Microstructure & Liquidity Factors
- **Amihud (2002) Illiquidity Ratio**: Daily price impact per dollar volume:
  $$\text{ILLIQ}_t = \frac{1}{n} \sum_{k=0}^{n-1} \frac{|R_{t-k}|}{P_{t-k} \cdot V_{t-k}} \times 10^6$$
- **Roll (1984) Effective Spread**: Extracted from serial covariance of price differences:
  $$s_{\text{Roll}} = 2 \sqrt{-\min\left(0, \operatorname{Cov}(\Delta P_t, \Delta P_{t-1})\right)}$$
- **Volume Turnover Acceleration**: Ratio of 5-day volume to 20-day moving average volume.

---

## 4. Preprocessing & Factor Neutralization

Raw factors contain outlier distortion, market beta confounding, and sector concentration.

### 4.1 Cross-Sectional MAD Winsorization
Rather than sensitive standard deviation trimming, we apply robust Median Absolute Deviation:

$$\text{MAD}_t = \operatorname{median}\left( |f_{i, t} - \operatorname{median}(f_{\cdot, t})| \right)$$

Factors are bounded to $[\operatorname{median} - 3 \times 1.4826 \cdot \text{MAD}_t, \; \operatorname{median} + 3 \times 1.4826 \cdot \text{MAD}_t]$ and subsequently standardized to zero mean, unit variance per timestamp $t$:

$$z_{i, t} = \frac{f_{i, t}^{\text{winsor}} - \mu_t}{\sigma_t}$$

### 4.2 Sector & Beta Orthogonalization (Neutralization)
To prevent the model from merely making disguised bets on market direction or sector rotations, raw factor vectors are projected onto the null space of risk factor exposures:

$$y_t = X_t \beta_t + \mathbf{f}_t^*$$

where $X_t \in \mathbb{R}^{M \times (K + 1)}$ contains market beta and sector dummy indicators. The neutralized alpha factor is the OLS residual vector:

$$\mathbf{f}_t^* = \left( I - X_t (X_t^T X_t)^{-1} X_t^T \right) \mathbf{y}_t$$

By construction:
$$\operatorname{Cov}(\mathbf{f}_t^*, \mathbf{x}_{k, t}) = 0 \quad \forall k$$

---

## 5. Model Architecture & Attributions

### 5.1 Regularized LightGBM Alpha Regressor
We employ gradient boosted decision trees with:
- Objective: Huber loss (robust to fat-tailed financial returns):
  $$L_\delta(y, \hat{y}) = \begin{cases} \frac{1}{2}(y - \hat{y})^2 & \text{for } |y - \hat{y}| \le \delta \\ \delta(|y - \hat{y}| - \frac{1}{2}\delta) & \text{otherwise} \end{cases}$$
- Regularization: Tree depth bounded to $3 \le \text{depth} \le 5$, feature subsampling (`colsample_bytree = 0.8`), and $L_1/L_2$ leaf weight penalties to mitigate combinatorial overfitting.
- Early stopping monitored on the purged out-of-fold validation set.

### 5.2 TreeSHAP Feature Attribution
Using Lundberg & Lee (2017), local prediction explanations satisfy the efficiency, symmetry, and dummy axioms:

$$f(x) = \phi_0 + \sum_{j=1}^M \phi_j(x)$$

where $\phi_j(x)$ represents the marginal contribution of factor $j$ to the expected forward return.

---

## 6. Performance Evaluation Metrics

### 6.1 Rank Information Coefficient (Rank IC)
The cross-sectional Spearman rank correlation between model predictions $\hat{y}_t$ and realized forward returns $y_t$:

$$\text{Rank IC}_t = \rho\left(\operatorname{rank}(\hat{y}_t), \operatorname{rank}(y_t)\right) = 1 - \frac{6 \sum_{i=1}^M d_{i, t}^2}{M (M^2 - 1)}$$

### 6.2 Information Ratio ($IC\_IR$)
Measures the risk-adjusted consistency of predictive alpha:

$$IC\_IR = \frac{\operatorname{Mean}(\text{Rank IC})}{\operatorname{Std}(\text{Rank IC})} \times \sqrt{252}$$

Institutional Benchmarks:
- $\text{Rank IC} > 0.05$: Statistically significant predictive power.
- $IC\_IR > 1.0$: Institutional-grade production alpha.
- $IC\_IR > 1.5$: Top-decile systematic hedge fund signal.

### 6.3 Quantile Portfolio Spread & Factor Turnover
Assets are sorted into 5 quintile portfolios $(Q_1 \dots Q_5)$ daily:
- **Long-Short Spread**: $R_{L/S} = R_{Q5} - R_{Q1}$.
- **Monotonicity Ratio**: Percentage of evaluation days where mean return strictly increases from $Q_1 \to Q_5$.
- **Portfolio Turnover**:
  $$\text{Turnover}_t = \frac{1}{2} \sum_{i=1}^M |w_{i, t} - w_{i, t-1}|$$
- **Net Alpha after Transaction Costs**:
  $$R_t^{\text{net}} = R_t^{\text{gross}} - 2 \times c \times \text{Turnover}_t$$
  where $c$ is the exchange half-spread and commission cost (typically $5 - 10 \text{ bps}$).
