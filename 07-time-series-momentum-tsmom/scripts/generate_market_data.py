"""
generate_market_data.py
Generates institutional multi-asset futures daily continuous settlement prices
from 2000-01-03 to 2024-12-31 across 16 global futures contracts in 4 asset classes:
  - Equities: ES, NQ, FDAX, NK
  - Fixed Income: TY, US, FGBL, G
  - Currencies: EURUSD, USDJPY, GBPUSD, AUDUSD
  - Commodities: CL, GC, HG, ZC

Calibrated with empirical macro regimes (Dot-Com Bust, 2008 GFC, 2020 COVID, 2022 Rate Shock).
"""

import numpy as np
import pandas as pd
import os

def generate_futures_dataset(seed: int = 42) -> pd.DataFrame:
    np.random.seed(seed)
    
    # 25-year business day calendar
    dates = pd.date_range(start="2000-01-03", end="2024-12-31", freq="B")
    n_days = len(dates)
    
    # Contract specs: initial price, annual base drift, annual base vol, asset class
    specs = {
        # Equities
        'ES': {'p0': 1469.0, 'drift': 0.075, 'vol': 0.18, 'class': 'Equities'},
        'NQ': {'p0': 3790.0, 'drift': 0.100, 'vol': 0.24, 'class': 'Equities'},
        'FDAX': {'p0': 6958.0, 'drift': 0.065, 'vol': 0.20, 'class': 'Equities'},
        'NK': {'p0': 18934.0, 'drift': 0.045, 'vol': 0.21, 'class': 'Equities'},
        # Fixed Income (price index)
        'TY': {'p0': 95.0, 'drift': 0.040, 'vol': 0.065, 'class': 'FixedIncome'},
        'US': {'p0': 93.0, 'drift': 0.050, 'vol': 0.100, 'class': 'FixedIncome'},
        'FGBL': {'p0': 105.0, 'drift': 0.038, 'vol': 0.060, 'class': 'FixedIncome'},
        'G': {'p0': 108.0, 'drift': 0.035, 'vol': 0.075, 'class': 'FixedIncome'},
        # Currencies (FX)
        'EURUSD': {'p0': 1.015, 'drift': 0.005, 'vol': 0.095, 'class': 'FX'},
        'USDJPY': {'p0': 102.5, 'drift': 0.015, 'vol': 0.105, 'class': 'FX'},
        'GBPUSD': {'p0': 1.635, 'drift': -0.010, 'vol': 0.098, 'class': 'FX'},
        'AUDUSD': {'p0': 0.655, 'drift': 0.010, 'vol': 0.125, 'class': 'FX'},
        # Commodities
        'CL': {'p0': 25.6, 'drift': 0.060, 'vol': 0.35, 'class': 'Commodities'},
        'GC': {'p0': 288.0, 'drift': 0.080, 'vol': 0.16, 'class': 'Commodities'},
        'HG': {'p0': 0.85, 'drift': 0.065, 'vol': 0.24, 'class': 'Commodities'},
        'ZC': {'p0': 205.0, 'drift': 0.035, 'vol': 0.22, 'class': 'Commodities'},
    }
    
    symbols = list(specs.keys())
    n_syms = len(symbols)
    
    # Correlation structure within and across asset classes
    # 1. Base correlation matrix
    base_corr = np.eye(n_syms)
    for i, s1 in enumerate(symbols):
        for j, s2 in enumerate(symbols):
            if i == j:
                continue
            c1, c2 = specs[s1]['class'], specs[s2]['class']
            if c1 == c2:
                if c1 == 'Equities':
                    base_corr[i, j] = 0.75
                elif c1 == 'FixedIncome':
                    base_corr[i, j] = 0.70
                elif c1 == 'FX':
                    base_corr[i, j] = 0.35
                elif c1 == 'Commodities':
                    base_corr[i, j] = 0.30
            else:
                if (c1 == 'Equities' and c2 == 'FixedIncome') or (c2 == 'Equities' and c1 == 'FixedIncome'):
                    base_corr[i, j] = -0.25
                elif (c1 == 'Equities' and c2 == 'Commodities') or (c2 == 'Equities' and c1 == 'Commodities'):
                    base_corr[i, j] = 0.25
                else:
                    base_corr[i, j] = 0.05
                    
    # Ensure positive semi-definiteness
    eigvals, eigvecs = np.linalg.eigh(base_corr)
    eigvals = np.maximum(eigvals, 1e-4)
    corr_psd = eigvecs @ np.diag(eigvals) @ eigvecs.T
    d_inv = 1.0 / np.sqrt(np.diag(corr_psd))
    corr_psd = d_inv[:, None] * corr_psd * d_inv[None, :]
    L = np.linalg.cholesky(corr_psd)
    
    # Generate daily returns with regime conditioning
    daily_returns = np.zeros((n_days, n_syms))
    
    years = dates.year.values
    
    for t in range(n_days):
        y = years[t]
        dt = dates[t]
        
        # Standard correlated shock
        z = np.random.normal(0, 1, n_syms)
        shock = L @ z
        
        # Regime adjustments
        # Dot-Com bust (2000 - 2002)
        if 2000 <= y <= 2002:
            regime_eq_drift = -0.15 / 252.0
            regime_fi_drift = +0.08 / 252.0
            vol_mult = 1.3
        # 2003-2007 Global Bull & Commodity Supercycle
        elif 2003 <= y <= 2007:
            regime_eq_drift = +0.14 / 252.0
            regime_fi_drift = +0.02 / 252.0
            vol_mult = 0.8
        # 2008 Global Financial Crisis
        elif y == 2008:
            regime_eq_drift = -0.45 / 252.0
            regime_fi_drift = +0.18 / 252.0
            vol_mult = 2.2
        # 2009-2019 Long Bull & QE
        elif 2009 <= y <= 2019:
            regime_eq_drift = +0.13 / 252.0
            regime_fi_drift = +0.035 / 252.0
            vol_mult = 0.9
        # 2020 COVID shock & rebound
        elif y == 2020:
            if dt.month in [2, 3]:
                regime_eq_drift = -0.50 / 252.0
                regime_fi_drift = +0.15 / 252.0
                vol_mult = 3.0
            else:
                regime_eq_drift = +0.35 / 252.0
                regime_fi_drift = +0.02 / 252.0
                vol_mult = 1.2
        # 2022 Inflation & Rate Hiking Crisis
        elif y == 2022:
            regime_eq_drift = -0.20 / 252.0
            regime_fi_drift = -0.16 / 252.0  # Historic bond crash!
            vol_mult = 1.4
        # 2023-2024 AI rally & normalization
        else:
            regime_eq_drift = +0.18 / 252.0
            regime_fi_drift = +0.01 / 252.0
            vol_mult = 0.95
            
        for i, sym in enumerate(symbols):
            c = specs[sym]['class']
            daily_vol = (specs[sym]['vol'] / np.sqrt(252.0)) * vol_mult
            
            if c == 'Equities':
                drift = specs[sym]['drift'] / 252.0 + regime_eq_drift
            elif c == 'FixedIncome':
                drift = specs[sym]['drift'] / 252.0 + regime_fi_drift
            elif c == 'Commodities':
                if 2003 <= y <= 2007 or y == 2022:
                    drift = (specs[sym]['drift'] + 0.15) / 252.0
                elif y == 2008 or (y == 2020 and dt.month in [3, 4]):
                    drift = (specs[sym]['drift'] - 0.40) / 252.0
                else:
                    drift = specs[sym]['drift'] / 252.0
            else: # FX
                drift = specs[sym]['drift'] / 252.0
                if y == 2022 and sym == 'EURUSD':
                    drift -= 0.10 / 252.0  # EUR parity break in 2022
                elif y == 2022 and sym == 'USDJPY':
                    drift += 0.20 / 252.0  # Yen depreciation in 2022
                    
            daily_returns[t, i] = drift + daily_vol * shock[i]
            
    # Convert returns to prices
    prices = np.zeros((n_days, n_syms))
    for i, sym in enumerate(symbols):
        p0 = specs[sym]['p0']
        # Geometric compounding: P_t = P_0 * exp(cumsum(r))
        prices[:, i] = p0 * np.exp(np.cumsum(daily_returns[:, i]))
        
    df = pd.DataFrame(prices, index=dates, columns=symbols)
    df.index.name = 'Date'
    return df

if __name__ == '__main__':
    data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data')
    os.makedirs(data_dir, exist_ok=True)
    out_path = os.path.join(data_dir, 'futures_daily_2000_2024.csv')
    
    print('Generating 25-year multi-asset futures dataset...')
    df = generate_futures_dataset()
    df.to_csv(out_path)
    print(f'Saved {df.shape[0]} trading days x {df.shape[1]} contracts to {out_path}')
    print('Summary of annualized return and endpoints:')
    for col in df.columns:
        cagr = (df[col].iloc[-1] / df[col].iloc[0]) ** (252.0 / len(df)) - 1.0
        print(f'  {col:6s}: start={df[col].iloc[0]:9.2f}, end={df[col].iloc[-1]:9.2f}, CAGR={cagr*100:6.2f}%')
