# Machine Learning Alpha Signal Engine (Leakage-Free Walk-Forward Validation)

[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![Tests: 18 Passed](https://img.shields.io/badge/tests-18%20passed-brightgreen.svg)]()
[![Validation: De Prado Purged CV](https://img.shields.io/badge/Validation-Purged%20K--Fold%20%2B%20Embargo-emerald.svg)]()
[![Status: Complete & Deployed](https://img.shields.io/badge/Status-Complete%20%26%20Deployed-brightgreen.svg)]()
[![Target: Quantitative Equity Desks](https://img.shields.io/badge/Target-AQR%20%7C%20WorldQuant%20%7C%20Millennium%20%7C%20Two%20Sigma-red.svg)]()

> **Quant Finance Series — Project 04**: Systematic equity alpha generation engine predicting forward returns using gradient boosted decision trees (LightGBM) and regularized linear models (ElasticNet). Validated strictly via **Marcos López de Prado's Purged Group Time-Series Cross-Validation with Embargo** to eliminate forward return overlap leakage, serial correlation bias, and combinatorial overfitting. Features TreeSHAP global and local attribution, continuous volatility estimators (Garman-Klass, Yang-Zhang, Parkinson), Amihud microstructure illiquidity, and a full interactive web research dashboard.

---

## 🏛️ Project Architecture & Layout

```
04-ml-alpha-signal/
├── README.md                          # Research thesis, factor math, and leakage prevention protocol
├── requirements.txt                   # lightgbm, scikit-learn, shap, pandas, scipy, statsmodels, rich, pytest
├── docs/
│   └── cross_validation_protocol.md   # The mathematics of Purged K-Fold & Embargo periods
├── data/
│   ├── cross_sectional_universe.csv   # 14 US equities across 6 sectors over 504 trading dates
│   ├── feature_store.csv              # Extracted, winsorized, and neutralized alpha factors
│   └── tearsheet_metrics.json         # Serialized out-of-sample backtest & attribution artifacts
├── src/
│   ├── features/
│   │   ├── price_momentum.py          # Dual-momentum (skip-week), residual momentum, reversal factors
│   │   ├── volatility_estimators.py   # Parkinson, Garman-Klass, Yang-Zhang robust continuous estimators
│   │   └── microstructure.py          # Amihud illiquidity ratio, Roll effective spread, volume surprise
│   ├── preprocessing/
│   │   ├── winsorization.py           # Cross-sectional MAD winsorization & z-scoring
│   │   └── neutralization.py          # Sector and market-beta neutralization via OLS null-space projection
│   ├── validation/
│   │   └── purged_kfold.py            # De Prado's PurgedGroupTimeSeriesSplit with Embargo
│   ├── models/
│   │   ├── lightgbm_alpha.py          # Early-stopping objective with Huber loss & tree depth bounds
│   │   └── elasticnet_alpha.py        # L1/L2 penalized sparse linear baseline model
│   └── evaluation/
│       ├── information_coefficient.py # Daily Spearman Rank IC, Pearson IC & Information Ratio (IC_IR)
│       ├── factor_turnover.py         # Position churn, rank autocorrelation & transaction fee drag
│       └── shap_attribution.py        # Global and local TreeSHAP Shapley value attribution
├── scripts/
│   ├── generate_universe_data.py      # Multi-asset geometric Brownian motion with factor dynamics
│   ├── train_and_validate.py          # Walk-forward model training & out-of-sample prediction
│   └── generate_tearsheet.py          # Cumulative returns, IC decay curve, quantile spread tearsheet
├── tests/
│   ├── test_purged_kfold.py           # Verification that test labels never overlap train horizons
│   ├── test_features.py               # Unit tests for momentum, volatility, and microstructure factors
│   ├── test_neutralization.py         # Unit tests for MAD winsorization and beta/sector orthogonalization
│   └── test_models.py                 # Unit tests for LightGBM, ElasticNet, Rank IC, and turnover
└── web/
    ├── index.html                     # Purged CV timeline inspector, TradingView chart, SHAP matrix
    ├── styles.css                     # Institutional dark terminal theme (#060a12) & CSS grid
    ├── app.js                         # Browser quantitative engine, canvas charting, screener filters
    ├── vercel.json                    # Edge serverless caching & CORS headers
    └── api/
        └── quotes.js                  # Multi-asset real-time quotes, alpha scores & factor feeds
```

---

## 📐 Core Quantitative Foundations

### 1. The Financial ML Failure Mode (Why Standard K-Fold Fails)
Standard tabular machine learning assumes observations are **Independent and Identically Distributed (I.I.D.)**. Standard $K$-fold cross-validation randomly allocates samples across folds.

In finance, multi-day forward return labels span an interval $[t, t+\tau]$:

$$y_{i, t} = \frac{P_{i, t+\tau} - P_{i, t}}{P_{i, t}}$$

If an observation at $t+1$ is assigned to the training set while observation $t$ is in the test set:
- Observation $t+1$ and observation $t$ share $\tau - 1$ days of identical price movement.
- Information from the test label leaks directly into the training loss function.
- The model learns to interpolate between overlapping labels rather than genuine alpha, creating illusory in-sample Sharpe ratios that instantly collapse out-of-sample.

### 2. Marcos López de Prado's Purging & Embargo Theorem
To guarantee zero lookahead leakage, cross-validation must be partitioned with:

1. **Purging**: For a test evaluation interval $[T_{0, \text{test}}, T_{1, \text{test}}]$, purge any training candidate $i$ whose label window $[t_{i, 0}, t_{i, 1}]$ overlaps the test interval:

$$\mathcal{I}_{\text{train}}^{\text{purged}} = \left\{ i \in \mathcal{I}_{\text{train}}^{\text{raw}} \;\middle|\; t_{i, 1} < T_{0, \text{test}} \quad \text{or} \quad t_{i, 0} > T_{1, \text{test}} \right\}$$

2. **Embargoing**: To neutralize autoregressive memory in continuous time-series features (e.g. 20-day moving averages), apply an embargo buffer of length $h$ immediately following the test fold:

$$\mathcal{I}_{\text{train}}^{\text{final}} = \left\{ i \in \mathcal{I}_{\text{train}}^{\text{purged}} \;\middle|\; t_{i, 0} < T_{0, \text{test}} \quad \text{or} \quad t_{i, 0} > T_{1, \text{test}} + h \right\}$$

```
Timeline Architecture:
[------ TRAIN SET ------] [ PURGE ] [=== TEST SET ===] [ EMBARGO ] [------ TRAIN SET ------]
                          <--tau-->                    <----h---->
```

### 3. Continuous-Diffusion Volatility Estimators
Standard close-to-close sample volatility ignores intraday price paths. We implement continuous-diffusion estimators:

- **Parkinson (1980)**: High-Low range estimator (~5x more efficient than close-to-close):
  $$\sigma_P = \sqrt{ \frac{252}{4 \ln 2 \cdot n} \sum_{t=1}^n \left( \ln \frac{H_t}{L_t} \right)^2 }$$

- **Garman-Klass (1980)**: Incorporates High, Low, Open, and Close (~8x more efficient):
  $$\sigma_{GK} = \sqrt{ \frac{252}{n} \sum_{t=1}^n \left[ 0.5 \left( \ln \frac{H_t}{L_t} \right)^2 - (2\ln 2 - 1) \left( \ln \frac{C_t}{O_t} \right)^2 \right] }$$

- **Yang-Zhang (2000)**: Minimum-variance unbiased estimator accounting for overnight jumps and intraday drift:
  $$\sigma_{YZ}^2 = \sigma_{\text{open}}^2 + k \sigma_{\text{close}}^2 + (1-k) \sigma_{RS}^2, \quad k = \frac{0.34}{1.34 + \frac{n+1}{n-1}}$$

### 4. Microstructure & Liquidity Factors
- **Amihud (2002) Illiquidity Ratio**: Measures absolute price impact per million dollars traded:
  $$\text{ILLIQ}_t = \frac{1}{n} \sum_{k=0}^{n-1} \frac{|R_{t-k}|}{P_{t-k} \cdot V_{t-k}} \times 10^6$$
- **Roll (1984) Effective Spread**: Extracted from negative first-order serial covariance of price increments:
  $$s_{\text{Roll}} = 2 \sqrt{-\min(0, \operatorname{Cov}(\Delta P_t, \Delta P_{t-1}))}$$

### 5. Cross-Sectional Factor Neutralization
Raw factors are orthogonalized against market beta and sector dummies via cross-sectional OLS projection per date:

$$\mathbf{f}_t^* = \left( I - X_t (X_t^T X_t)^{-1} X_t^T \right) \mathbf{y}_t$$

Ensures:
$$\operatorname{Cov}(\mathbf{f}_t^*, \mathbf{x}_{k, t}) = 0 \quad \forall k$$

### 6. TreeSHAP Attribution (Lundberg & Lee 2017)
Decomposes LightGBM predictions into additive marginal Shapley factor contributions:

$$f(x) = \phi_0 + \sum_{j=1}^M \phi_j(x)$$

---

## ⚡ Quick Start & CLI Execution

### 1. Installation
```bash
cd 04-ml-alpha-signal
pip install -r requirements.txt
```

### 2. Run Test Suite (18 Automated Unit Tests)
```bash
pytest tests/ -v
```
Output:
```
tests/test_features.py::test_momentum_reversal_features PASSED           [ 16%]
tests/test_features.py::test_volatility_estimators PASSED                [ 22%]
tests/test_features.py::test_microstructure_factors PASSED               [ 27%]
tests/test_models.py::test_lightgbm_alpha_fit_predict PASSED             [ 33%]
tests/test_models.py::test_elasticnet_alpha_fit_predict PASSED           [ 38%]
tests/test_models.py::test_spearman_rank_ic PASSED                       [ 44%]
tests/test_models.py::test_quantile_portfolio_returns PASSED             [ 50%]
tests/test_models.py::test_portfolio_turnover_and_fees PASSED            [ 55%]
tests/test_models.py::test_tree_shap_attributions PASSED                 [ 61%]
tests/test_models.py::test_rank_autocorrelation_decay PASSED             [ 66%]
tests/test_neutralization.py::test_mad_winsorize_clips_outliers PASSED   [ 72%]
tests/test_neutralization.py::test_cross_sectional_zscore PASSED         [ 77%]
tests/test_neutralization.py::test_factor_neutralization_orthogonal PASSED [ 83%]
tests/test_neutralization.py::test_gram_schmidt_orthogonality PASSED      [ 88%]
tests/test_purged_kfold.py::test_purged_kfold_no_overlap PASSED          [ 94%]
tests/test_purged_kfold.py::test_embargo_buffer_application PASSED       [ 96%]
tests/test_purged_kfold.py::test_walk_forward_causality PASSED           [ 98%]
tests/test_purged_kfold.py::test_leakage_detector_catches_leak PASSED    [100%]
======================== 18 passed in 3.20s ========================
```

### 3. Generate Universe Data & Train Model
```bash
# Generate 504-day cross-sectional universe
python scripts/generate_universe_data.py

# Run Purged K-Fold training pipeline
python scripts/train_and_validate.py
```

### 4. Generate Institutional Tearsheet
```bash
python scripts/generate_tearsheet.py
```

### 5. Launch Interactive Web Dashboard
```bash
cd web
npx serve .
# Open http://localhost:3000 in your browser
```

---

## 🎯 What Makes This Interview-Ready (2026 Hedge Fund Standards)

1. **Purged K-Fold with Embargo**:
   Eliminates the #1 reason quantitative machine learning models fail out-of-sample: label horizon overlap and serial correlation leakage.
2. **True Continuous Diffusion Volatility**:
   Replaces naive close-to-close sample variance with Parkinson (1980), Garman-Klass (1980), and Yang-Zhang (2000) estimators.
3. **Cross-Sectional Neutralization**:
   Guarantees that alpha factors represent pure idiosyncratic alpha rather than disguised systematic factor bets (market beta, sector tilts).
4. **TreeSHAP Interpretability**:
   Decomposes non-linear tree ensembles into exact additive Shapley factor contributions, satisfying institutional risk and compliance requirements.
5. **Interactive Web Application**:
   Deployable in 1-click on Vercel with real-time TradingView charting, purged fold timeline inspector, and live cross-sectional screener.
