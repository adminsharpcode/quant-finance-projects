"""
Value and Momentum correlation analysis and diversification multiplier calculations.
Empirically proves the negative correlation documented in Asness, Moskowitz, & Pedersen (2013).
"""

from typing import Dict
import numpy as np
import pandas as pd


def compute_rolling_correlation(
    val_returns: pd.Series, 
    mom_returns: pd.Series, 
    window: int = 252
) -> pd.Series:
    """
    Computes rolling correlation between Value and Momentum legs over a specified window.
    """
    return val_returns.rolling(window=window, min_periods=window // 2).corr(mom_returns)


def compute_diversification_metrics(
    val_returns: pd.Series, 
    mom_returns: pd.Series
) -> Dict[str, float]:
    """
    Calculates overall correlation, standalone Sharpe ratios, theoretical combo Sharpe,
    and actual empirical combo Sharpe.
    """
    common = val_returns.dropna().index.intersection(mom_returns.dropna().index)
    v = val_returns.loc[common]
    m = mom_returns.loc[common]
    
    rho = float(v.corr(m))
    
    std_v = float(v.std()) * np.sqrt(252.0)
    std_m = float(m.std()) * np.sqrt(252.0)
    mean_v = float(v.mean()) * 252.0
    mean_m = float(m.mean()) * 252.0
    
    sharpe_v = (mean_v / std_v) if std_v > 1e-6 else 0.0
    sharpe_m = (mean_m / std_m) if std_m > 1e-6 else 0.0
    
    # Diversification multiplier: 1 / sqrt((1 + rho)/2)
    div_mult = 1.0 / np.sqrt(max(1e-4, (1.0 + rho) / 2.0))
    avg_sharpe = 0.5 * (sharpe_v + sharpe_m)
    theoretical_combo_sharpe = avg_sharpe * div_mult
    
    # Empirical 50/50 combination
    combo = 0.5 * v + 0.5 * m
    std_combo = float(combo.std()) * np.sqrt(252.0)
    mean_combo = float(combo.mean()) * 252.0
    actual_combo_sharpe = (mean_combo / std_combo) if std_combo > 1e-6 else 0.0
    
    return {
        "Value_Momentum_Correlation": rho,
        "Value_Standalone_Sharpe": sharpe_v,
        "Momentum_Standalone_Sharpe": sharpe_m,
        "Diversification_Multiplier": div_mult,
        "Theoretical_Combo_Sharpe": theoretical_combo_sharpe,
        "Actual_Combo_Sharpe": actual_combo_sharpe,
        "Sharpe_Gain_Pct": ((actual_combo_sharpe / max(1e-4, avg_sharpe)) - 1.0) * 100.0,
    }
