# Machine Learning Alpha Signal Engine (Leakage-Free Walk-Forward Validation)

[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![Status: Day 4 Blueprint](https://img.shields.io/badge/Status-Day%204%20Blueprint-orange.svg)]()
[![Validation: De Prado Purged CV](https://img.shields.io/badge/Validation-Purged%20K--Fold%20%2B%20Embargo-emerald.svg)]()

> **Quant Series Project 04**: Systematic equity alpha generation engine predicting forward returns using gradient boosted trees (LightGBM) and regularized linear models, validated strictly via Marcos López de Prado's Purged Group Time-Series Cross-Validation to eliminate data leakage and combinatorial overfitting.

---

## 🏛️ Project Architecture & Layout

```
04-ml-alpha-signal/
├── README.md                          # Research thesis, factor math, and leakage prevention protocol
├── requirements.txt                   # lightgbm, scikit-learn, shap, pandas, scipy, statsmodels
├── docs/
│   └── cross_validation_protocol.md   # The mathematics of Purged K-Fold & Embargo periods
├── data/
│   ├── cross_sectional_universe.csv   # Multi-asset daily pricing & fundamental metrics
│   └── feature_store.csv              # Extracted normalized alpha factors
├── src/
│   ├── features/
│   │   ├── price_momentum.py          # Dual-momentum, residual momentum, reversal factors
│   │   ├── volatility_estimators.py   # Parkinson, Garman-Klass, Yang-Zhang robust estimators
│   │   └── microstructure.py          # Amihud illiquidity ratio, Roll effective spread proxy
│   ├── preprocessing/
│   │   ├── winsorization.py           # Cross-sectional MAD winsorization & z-scoring
│   │   └── neutralization.py          # Sector and market-beta neutralization via OLS projection
│   ├── validation/
│   │   └── purged_kfold.py            # De Prado's PurgedGroupTimeSeriesSplit with Embargo
│   ├── models/
│   │   ├── lightgbm_alpha.py          # Early-stopping objective with Huber/MSE loss
│   │   └── elasticnet_alpha.py        # L1/L2 penalized sparse linear model
│   └── evaluation/
│       ├── information_coefficient.py # Daily Spearman Rank IC & Information Ratio (IC_IR)
│       ├── factor_turnover.py         # Position churn & transaction fee drag estimation
│       └── shap_attribution.py        # Global and local TreeSHAP feature attribution
├── scripts/
│   ├── train_and_validate.py          # Walk-forward model training & out-of-sample prediction
│   └── generate_tearsheet.py          # Cumulative returns, IC decay curve, quantile spread chart
└── tests/
    ├── test_purged_kfold.py           # Verification that test labels never overlap train horizons
    ├── test_features.py
    └── test_neutralization.py
```

---

## 🎯 What Makes This Interview-Ready (2026 Standards)
1. **Marcos López de Prado's Purged K-Fold with Embargo**:
   Standard k-fold cross-validation is fundamentally flawed for financial time-series because overlapping return horizons cause severe serial correlation leakage. We implement:
   - **Purging**: Eliminating training samples whose labels overlap test evaluation periods.
   - **Embargoing**: Discarding training samples immediately following test periods to counter autoregressive memory.
2. **Rank Information Coefficient (Rank IC)**: Measures true monotonicity of alpha predictions ($IC > 0.05$ with $IR > 1.0$ is institutional standard).
3. **Cross-Sectional Neutralization**: Alpha factors are orthogonalized against market beta and sector dummies to ensure pure idiosyncratic alpha without disguised factor exposures.
