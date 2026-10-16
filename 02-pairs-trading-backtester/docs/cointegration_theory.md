# Mathematical Foundations of Pairs Trading, Cointegration & State-Space Systems

This document presents the first-principles mathematical derivations underlying the pairs trading backtesting engine, including integrated time series, Engle-Granger and Johansen cointegration, continuous state-space Kalman filtering, Ornstein-Uhlenbeck stochastic calibration, microstructure friction models, and walk-forward cross-validation.

---

## 1. Integrated Time Series & The Spurious Regression Problem

### 1.1 Order of Integration $I(d)$
A stochastic process $\{X_t\}$ is integrated of order $d$, denoted $X_t \sim I(d)$, if it requires differencing $d$ times to achieve covariance stationarity:
$$(1 - L)^d X_t = \epsilon_t, \quad \epsilon_t \sim \text{WN}(0, \sigma^2)$$
where $L$ is the lag operator $L X_t = X_{t-1}$.
- Asset prices $S_t$ (equities, commodities, foreign exchange) are almost universally non-stationary $I(1)$ processes:
  $$\Delta S_t = S_t - S_{t-1} = \mu + \sigma \epsilon_t \sim I(0)$$
- A linear combination of two independent $I(1)$ processes is generically $I(1)$:
  $$Z_t = Y_t - \beta X_t \sim I(1)$$

### 1.2 Granger-Newbold Spurious Regression Phenomenon (1974)
If two independent random walks $Y_t = Y_{t-1} + u_t$ and $X_t = X_{t-1} + v_t$ (where $\text{Cov}(u_t, v_s) = 0, \forall t, s$) are regressed using Ordinary Least Squares (OLS):
$$Y_t = \alpha + \beta X_t + \epsilon_t$$
standard OLS t-statistics and $R^2$ diverge asymptotically to infinity:
$$t_\beta \xrightarrow{d} \mathcal{O}_p(\sqrt{T}), \quad R^2 \xrightarrow{d} \xi \in (0, 1)$$
The Durbin-Watson statistic $DW \xrightarrow{p} 0$. Standard hypothesis testing falsely rejects the null hypothesis of no relationship ($H_0: \beta = 0$) virtually 100% of the time as sample size $T \to \infty$.

---

## 2. Engle-Granger Two-Step Cointegration Methodology

### 2.1 Definition of Cointegration (Engle & Granger, 1987)
Two non-stationary series $Y_t \sim I(1)$ and $X_t \sim I(1)$ are **cointegrated of order $(1, 1)$**, denoted $Y_t, X_t \sim \text{CI}(1, 1)$, if there exists a non-zero vector $\mathbf{\beta} = [1, -\beta]^T$ such that their linear combination is stationary $I(0)$:
$$Z_t = Y_t - \beta X_t - \alpha \sim I(0)$$
The vector $\mathbf{\beta}$ defines the **cointegrating vector**, and $Z_t$ is the stationary, mean-reverting **synthetic spread**.

### 2.2 Step 1: OLS Cointegrating Regression
Estimate the static hedge ratio $\hat{\beta}$ and intercept $\hat{\alpha}$ via OLS:
$$\min_{\alpha, \beta} \sum_{t=1}^T \left( y_t - \alpha - \beta x_t \right)^2$$
Under cointegration, the OLS estimator $\hat{\beta}$ is **super-consistent**:
$$\hat{\beta} - \beta = \mathcal{O}_p(T^{-1})$$
converging at rate $T$ rather than the classical $\sqrt{T}$ rate.

### 2.3 Step 2: Augmented Dickey-Fuller (ADF) on Residuals
Compute the residual spread series:
$$\hat{\epsilon}_t = y_t - \hat{\alpha} - \hat{\beta} x_t$$
Test for the presence of a unit root using the auxiliary regression:
$$\Delta \hat{\epsilon}_t = \gamma \hat{\epsilon}_{t-1} + \sum_{i=1}^p \delta_i \Delta \hat{\epsilon}_{t-i} + u_t$$
The hypotheses are:
- $H_0: \gamma = 0$ (Unit root exists $\implies$ Spread is non-stationary $\implies$ Series are NOT cointegrated)
- $H_1: \gamma < 0$ (Spread is covariance stationary $I(0) \implies$ Series ARE cointegrated)

Because $\hat{\epsilon}_t$ is calculated from estimated regression parameters $(\hat{\alpha}, \hat{\beta})$, its variance is strictly smaller than that of the true unobserved errors. Consequently, the test statistic:
$$t_\gamma = \frac{\hat{\gamma}}{\text{SE}(\hat{\gamma})}$$
does not follow the standard Student-t or Dickey-Fuller distribution. It follows the **Engle-Granger / MacKinnon response surface distribution**, requiring more negative critical values (e.g. $-3.34$ at 5% significance rather than $-2.86$).

---

## 3. Johansen Maximum Likelihood Cointegration Architecture

While Engle-Granger is restricted to pairwise regressions and is sensitive to the choice of dependent variable ($y$ on $x$ vs $x$ on $y$), the **Johansen Procedure (1988, 1991)** provides a symmetric, multivariate framework based on Vector Autoregressions (VAR).

### 3.1 Vector Error Correction Model (VECM)
Consider a $K$-dimensional vector of $I(1)$ asset prices $\mathbf{Y}_t = [Y_{1, t}, Y_{2, t}, \dots, Y_{K, t}]^T$. A $\text{VAR}(p)$ model:
$$\mathbf{Y}_t = \mathbf{\mu} + \sum_{i=1}^p \mathbf{A}_i \mathbf{Y}_{t-i} + \mathbf{\epsilon}_t$$
can be algebraically rewritten in first-differenced VECM form:
$$\Delta \mathbf{Y}_t = \mathbf{\mu} + \mathbf{\Pi} \mathbf{Y}_{t-1} + \sum_{i=1}^{p-1} \mathbf{\Gamma}_i \Delta \mathbf{Y}_{t-i} + \mathbf{\epsilon}_t$$
where the impact matrix $\mathbf{\Pi}$ and transient short-run matrices $\mathbf{\Gamma}_i$ are:
$$\mathbf{\Pi} = \sum_{i=1}^p \mathbf{A}_i - \mathbf{I}_K, \quad \mathbf{\Gamma}_i = -\sum_{j=i+1}^p \mathbf{A}_j$$

### 3.2 Rank of the Impact Matrix $\mathbf{\Pi}$
The rank $r = \text{rank}(\mathbf{\Pi})$ dictates the cointegration properties of the system:
1. $r = 0$: $\mathbf{\Pi} = \mathbf{0}$. No linear combinations are stationary. All $K$ assets are independent $I(1)$ random walks.
2. $r = K$: $\mathbf{\Pi}$ has full rank. The process $\mathbf{Y}_t$ is already stationary $I(0)$.
3. $0 < r < K$: There exist $r$ linearly independent cointegrating vectors. $\mathbf{\Pi}$ factors into:
   $$\mathbf{\Pi} = \mathbf{\alpha} \mathbf{\beta}^T$$
   where:
   - $\mathbf{\beta} \in \mathbb{R}^{K \times r}$ contains the $r$ cointegrating vectors such that $\mathbf{\beta}^T \mathbf{Y}_{t-1} \sim I(0)$.
   - $\mathbf{\alpha} \in \mathbb{R}^{K \times r}$ is the adjustment / speed-of-reversion matrix describing how each asset responds to deviations from equilibrium.

### 3.3 Likelihood Ratio Test Statistics
Solving the generalized eigenvalue problem $|\lambda \mathbf{S}_{11} - \mathbf{S}_{10} \mathbf{S}_{00}^{-1} \mathbf{S}_{01}| = 0$ yields sorted eigenvalues $\hat{\lambda}_1 > \hat{\lambda}_2 > \dots > \hat{\lambda}_K$.
Johansen provides two likelihood ratio tests:

#### 1. Trace Statistic:
$$\lambda_{\text{trace}}(r) = -T \sum_{i=r+1}^K \ln(1 - \hat{\lambda}_i)$$
Tests the null hypothesis $H_0: \text{rank}(\mathbf{\Pi}) \le r$ against the alternative $H_1: \text{rank}(\mathbf{\Pi}) > r$.

#### 2. Maximum Eigenvalue Statistic:
$$\lambda_{\text{max}}(r, r+1) = -T \ln(1 - \hat{\lambda}_{r+1})$$
Tests the null hypothesis $H_0: \text{rank}(\mathbf{\Pi}) = r$ against $H_1: \text{rank}(\mathbf{\Pi}) = r+1$.

---

## 4. State-Space Kalman Filtering for Dynamic Beta Tracking

Static OLS regressions assume a fixed hedge ratio $\beta$ across multiple years. In modern financial markets, corporate capital structures, volatility regimes, and fundamental correlations drift continuously. We formulate pairs trading as a continuous linear quadratic state-space system.

### 4.1 State-Space Formulation
Define the unobserved state vector $\mathbf{\theta}_t = [\alpha_t, \beta_t]^T \in \mathbb{R}^2$.

#### State Transition Equation (Latent Random Walk):
$$\mathbf{\theta}_t = \mathbf{G} \mathbf{\theta}_{t-1} + \mathbf{w}_t, \quad \mathbf{w}_t \sim \mathcal{N}(\mathbf{0}, \mathbf{Q})$$
where $\mathbf{G} = \mathbf{I}_2$ and $\mathbf{Q} \in \mathbb{R}^{2 \times 2}$ is the process noise covariance matrix governing parameter drift:
$$\mathbf{Q} = \frac{\delta}{1 - \delta} \mathbf{I}_2$$

#### Measurement Equation (Observation Model):
$$y_t = \mathbf{F}_t^T \mathbf{\theta}_t + v_t, \quad v_t \sim \mathcal{N}(0, R)$$
where $\mathbf{F}_t = [1, x_t]^T$ is the measurement design vector and $R = \sigma_v^2 > 0$ represents microstructural market noise.

### 4.2 Recursive Kalman Filtering Algorithm
At each discrete trading bar $t = 1, 2, \dots, T$:

#### 1. Time Update (Prior Prediction):
$$\hat{\mathbf{\theta}}_{t|t-1} = \hat{\mathbf{\theta}}_{t-1|t-1}$$
$$\mathbf{P}_{t|t-1} = \mathbf{P}_{t-1|t-1} + \mathbf{Q}$$

#### 2. Innovation & Predicted Measurement:
$$\hat{y}_t = \mathbf{F}_t^T \hat{\mathbf{\theta}}_{t|t-1} = \hat{\alpha}_{t|t-1} + \hat{\beta}_{t|t-1} x_t$$
$$e_t = y_t - \hat{y}_t \quad \text{(Instantaneous Spread Innovation)}$$
$$S_t = \mathbf{F}_t^T \mathbf{P}_{t|t-1} \mathbf{F}_t + R \quad \text{(Innovation Variance)}$$

#### 3. Optimal Kalman Gain:
$$\mathbf{K}_t = \frac{\mathbf{P}_{t|t-1} \mathbf{F}_t}{S_t} \in \mathbb{R}^{2 \times 1}$$

#### 4. Measurement Update (Posterior Correction):
$$\hat{\mathbf{\theta}}_{t|t} = \hat{\mathbf{\theta}}_{t|t-1} + \mathbf{K}_t e_t$$

#### 5. Joseph Form Covariance Update:
Standard covariance updates $\mathbf{P} = (\mathbf{I} - \mathbf{K} \mathbf{F}^T)\mathbf{P}$ are susceptible to numerical truncation errors that can destroy positive semi-definiteness. We implement the **Joseph stabilized formulation**:
$$\mathbf{P}_{t|t} = (\mathbf{I} - \mathbf{K}_t \mathbf{F}_t^T) \mathbf{P}_{t|t-1} (\mathbf{I} - \mathbf{K}_t \mathbf{F}_t^T)^T + \mathbf{K}_t R \mathbf{K}_t^T$$
guaranteeing $\mathbf{P}_{t|t} \succeq 0$ and mathematical symmetry $\mathbf{P}_{t|t} = \mathbf{P}_{t|t}^T$ for all $t$.

#### 6. Standardized Z-Score:
$$Z_t = \frac{e_t}{\sqrt{S_t}}$$
Because $\sqrt{S_t}$ reflects both parameter estimation uncertainty $\mathbf{F}_t^T \mathbf{P}_{t|t-1} \mathbf{F}_t$ and observational noise $R$, the standardized innovation $Z_t \sim \mathcal{N}(0, 1)$ under the null hypothesis of cointegration.

---

## 5. Ornstein-Uhlenbeck Continuous Stochastic Drift & Half-Life Calibration

The synthetic spread $X_t$ is modeled as a continuous-time 1-dimensional **Ornstein-Uhlenbeck (OU) process**:
$$dX_t = \theta (\mu - X_t) dt + \sigma dW_t$$
where:
- $\theta > 0$: Speed of mean reversion.
- $\mu \in \mathbb{R}$: Long-term equilibrium mean.
- $\sigma > 0$: Diffusion coefficient / spread volatility.
- $W_t$: Standard Brownian motion.

### 5.1 Conditional Distribution & Exact Solution
Applying Ito's lemma to $f(X_t, t) = X_t e^{\theta t}$:
$$d\left(X_t e^{\theta t}\right) = \theta X_t e^{\theta t} dt + e^{\theta t} dX_t = \theta \mu e^{\theta t} dt + \sigma e^{\theta t} dW_t$$
Integrating from $s$ to $t$ (with $\Delta t = t - s$):
$$X_t = X_s e^{-\theta \Delta t} + \mu \left(1 - e^{-\theta \Delta t}\right) + \sigma \int_s^t e^{-\theta(t - u)} dW_u$$

By Ito isometry, the integral has mean zero and variance:
$$\text{Var}\left(\sigma \int_s^t e^{-\theta(t - u)} dW_u\right) = \sigma^2 \int_s^t e^{-2\theta(t - u)} du = \frac{\sigma^2}{2\theta} \left(1 - e^{-2\theta \Delta t}\right)$$

Thus, conditional on $X_s$, $X_t$ is normally distributed:
$$X_t \mid X_s \sim \mathcal{N}\left( X_s e^{-\theta \Delta t} + \mu (1 - e^{-\theta \Delta t}), \, \frac{\sigma^2}{2\theta} (1 - e^{-2\theta \Delta t}) \right)$$

### 5.2 Discrete AR(1) Parameter Recovery
In discrete time with step size $\Delta t$:
$$X_t = a X_{t-1} + b + \epsilon_t, \quad \epsilon_t \sim \mathcal{N}(0, \sigma_\epsilon^2)$$
Matching coefficients with the continuous solution yields the exact parameter mappings:
$$a = e^{-\theta \Delta t} \implies \theta = -\frac{\ln(a)}{\Delta t}$$
$$b = \mu (1 - a) \implies \mu = \frac{b}{1 - a}$$
$$\sigma_\epsilon^2 = \frac{\sigma^2}{2\theta} (1 - a^2) \implies \sigma = \sigma_\epsilon \sqrt{\frac{-2 \ln(a)}{\Delta t (1 - a^2)}}$$

### 5.3 Mean-Reversion Half-Life ($\tau_{1/2}$)
The expected duration for the spread deviation $X_t - \mu$ to decay to half of its initial amplitude is:
$$\mathbb{E}[X_t - \mu] = (X_0 - \mu) e^{-\theta t} = \frac{1}{2} (X_0 - \mu)$$
$$e^{-\theta \tau_{1/2}} = \frac{1}{2} \implies \tau_{1/2} = \frac{\ln(2)}{\theta}$$
In discrete parameters:
$$\tau_{1/2} = -\frac{\ln(2) \Delta t}{\ln(a)}$$

---

## 6. Microstructure Realities & Realistic Execution Mechanics

A backtest that ignores market microstructure friction produces artificial profits. We model 4 distinct friction mechanisms:

### 6.1 Bid-Ask Spread Crossing & Impact Slippage
When executing a market order, the trader crosses the prevailing bid-ask spread and incurs market impact:
$$\tilde{P}_{\text{buy}} = P_t \times \left(1 + \delta_{\text{half-spread}} + \delta_{\text{slippage}}\right)$$
$$\tilde{P}_{\text{sell}} = P_t \times \left(1 - \delta_{\text{half-spread}} - \delta_{\text{slippage}}\right)$$
where $\delta_{\text{half-spread}} = 3.0 \text{ bps}$ and $\delta_{\text{slippage}} = 2.0 \text{ bps}$.

### 6.2 Prime Broker Short Borrow Fees
Shorting the short leg of a pair requires locating and borrowing the shares from prime brokers. The fee accrues continuously on the overnight short market value:
$$\text{BorrowFee}_t = V_{\text{short}, t} \times \frac{r_{\text{borrow}}}{360} \times \Delta t$$
where $r_{\text{borrow}} = 1.50\% \text{ p.a.}$ for general collateral (easy-to-borrow).

### 6.3 Broker Exchange Commissions
Direct execution fee charged per share traded:
$$C_{\text{broker}} = c_{\text{share}} \times \left( |N_Y| + |N_X| \right)$$
where $c_{\text{share}} = \$0.005 / \text{share}$.

---

## 7. Out-of-Sample Walk-Forward Cross-Validation

To prevent overfitting / data snooping bias, parameters are calibrated on rolling in-sample windows and tested on unseen out-of-sample forward horizons.

$$\begin{array}{rcc}
\text{Fold 1:} & \overbrace{[\quad\text{Train } W_{\text{in}} = 252\text{d}\quad]}^{\text{Calibrate } Z_{\text{entry}}, Z_{\text{exit}}} & \overbrace{[\quad\text{Test } W_{\text{out}} = 63\text{d}\quad]}^{\text{Evaluate OOS Performance}} \\
\text{Fold 2:} & \qquad\quad [\quad\text{Train } W_{\text{in}} = 252\text{d}\quad] & [\quad\text{Test } W_{\text{out}} = 63\text{d}\quad] \\
\text{Fold 3:} & \qquad\qquad\quad [\quad\text{Train } W_{\text{in}} = 252\text{d}\quad] & [\quad\text{Test } W_{\text{out}} = 63\text{d}\quad]
\end{array}$$

### 7.1 Walk-Forward Efficiency (WFE)
The Walk-Forward Efficiency ratio measures parameter robustness across regime shifts:
$$\text{WFE} = \frac{\overline{\text{Sharpe}}_{\text{Out-of-Sample}}}{\overline{\text{Sharpe}}_{\text{In-Sample}}}$$
- $\text{WFE} \ge 50\%$: The strategy demonstrates genuine predictive alpha across unseen market environments.
- $\text{WFE} < 30\%$: The strategy is rejected due to curve-fitting.
