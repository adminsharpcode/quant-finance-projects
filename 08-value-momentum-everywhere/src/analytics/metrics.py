"""
Institutional performance evaluation metrics for factor strategies.
"""

from dataclasses import dataclass
from typing import Dict, Optional
import numpy as np
import pandas as pd
from scipy import stats


@dataclass
class FactorPerformanceMetrics:
    total_return: float
    cagr: float
    annualized_volatility: float
    sharpe_ratio: float
    sortino_ratio: float
    max_drawdown: float
    max_drawdown_duration_days: int
    calmar_ratio: float
    skewness: float
    kurtosis: float
    win_rate_daily: float
    profit_factor: float
    annual_turnover: float


def calculate_drawdown_series(returns: pd.Series) -> pd.Series:
    cum = (1.0 + returns).cumprod()
    peak = cum.cummax()
    return (cum - peak) / peak


def calculate_factor_metrics(
    daily_returns: pd.Series, 
    turnover: Optional[pd.Series] = None
) -> FactorPerformanceMetrics:
    r = daily_returns.dropna()
    n_days = len(r)
    if n_days == 0:
        raise ValueError("Empty return series.")
        
    cum_ret = float((1.0 + r).prod() - 1.0)
    years = n_days / 252.0
    cagr = float((1.0 + cum_ret) ** (1.0 / max(years, 1e-4)) - 1.0)
    
    daily_std = float(r.std())
    ann_vol = daily_std * np.sqrt(252.0)
    sharpe = float(r.mean() / daily_std * np.sqrt(252.0)) if daily_std > 1e-8 else 0.0
    
    downside_r = r[r < 0.0]
    downside_std = float(np.sqrt(np.mean(downside_r ** 2))) if len(downside_r) > 0 else 1e-6
    sortino = float(r.mean() / downside_std * np.sqrt(252.0)) if downside_std > 1e-8 else 0.0
    
    dd = calculate_drawdown_series(r)
    max_dd = float(dd.min())
    
    # Drawdown duration
    in_dd = dd < 0.0
    durations = []
    curr = 0
    for v in in_dd:
        if v:
            curr += 1
        else:
            if curr > 0:
                durations.append(curr)
            curr = 0
    if curr > 0:
        durations.append(curr)
    max_duration = max(durations) if durations else 0
    
    calmar = float(cagr / abs(max_dd)) if abs(max_dd) > 1e-6 else 0.0
    skew = float(stats.skew(r))
    kurt = float(stats.kurtosis(r))
    
    pos = r[r > 0.0]
    neg = r[r < 0.0]
    win_rate = float(len(pos) / n_days)
    sum_gain = float(pos.sum())
    sum_loss = float(abs(neg.sum()))
    pf = (sum_gain / sum_loss) if sum_loss > 1e-8 else 999.0
    
    ann_to = float(turnover.sum() / max(years, 1e-4)) if turnover is not None else 0.0
    
    return FactorPerformanceMetrics(
        total_return=cum_ret,
        cagr=cagr,
        annualized_volatility=ann_vol,
        sharpe_ratio=sharpe,
        sortino_ratio=sortino,
        max_drawdown=max_dd,
        max_drawdown_duration_days=max_duration,
        calmar_ratio=calmar,
        skewness=skew,
        kurtosis=kurt,
        win_rate_daily=win_rate,
        profit_factor=pf,
        annual_turnover=ann_to,
    )
