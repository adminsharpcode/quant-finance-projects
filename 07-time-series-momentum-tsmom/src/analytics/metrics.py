"""
Institutional performance evaluation metrics.
Calculates CAGR, Sharpe, Sortino, Calmar, Max Drawdown, Skewness, Kurtosis, and Win Rate.
"""

from dataclasses import dataclass
from typing import Dict, Optional, Union
import numpy as np
import pandas as pd
from scipy import stats


@dataclass
class PerformanceMetrics:
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

    def to_dict(self) -> Dict[str, float]:
        return {
            "Total Return (%)": self.total_return * 100.0,
            "CAGR (%)": self.cagr * 100.0,
            "Annualized Volatility (%)": self.annualized_volatility * 100.0,
            "Sharpe Ratio": self.sharpe_ratio,
            "Sortino Ratio": self.sortino_ratio,
            "Max Drawdown (%)": self.max_drawdown * 100.0,
            "Max Drawdown Duration (Days)": self.max_drawdown_duration_days,
            "Calmar Ratio": self.calmar_ratio,
            "Skewness": self.skewness,
            "Excess Kurtosis": self.kurtosis,
            "Daily Win Rate (%)": self.win_rate_daily * 100.0,
            "Profit Factor": self.profit_factor,
            "Annual Turnover (x)": self.annual_turnover,
        }


def calculate_drawdown_series(returns: pd.Series) -> pd.Series:
    """
    Computes percentage underwater drawdown series:
    DD_t = (W_t - max_{tau <= t} W_tau) / max_{tau <= t} W_tau
    """
    cum = (1.0 + returns).cumprod()
    peak = cum.cummax()
    dd = (cum - peak) / peak
    return dd


def calculate_metrics(
    daily_returns: pd.Series, 
    turnover: Optional[pd.Series] = None, 
    rf_rate: float = 0.0
) -> PerformanceMetrics:
    """
    Calculates comprehensive institutional metrics from daily return series.
    """
    r = daily_returns.dropna()
    n_days = len(r)
    if n_days == 0:
        raise ValueError("Cannot calculate metrics on empty return series.")
        
    cum_ret = (1.0 + r).prod() - 1.0
    years = n_days / 252.0
    cagr = (1.0 + cum_ret) ** (1.0 / max(years, 1e-4)) - 1.0
    
    # Volatility
    daily_std = float(r.std())
    ann_vol = daily_std * np.sqrt(252.0)
    
    # Excess return for Sharpe
    excess_r = r - (rf_rate / 252.0)
    sharpe = float(excess_r.mean() / daily_std * np.sqrt(252.0)) if daily_std > 1e-8 else 0.0
    
    # Downside volatility for Sortino
    downside_r = r[r < 0.0]
    downside_std = float(np.sqrt(np.mean(downside_r ** 2))) if len(downside_r) > 0 else 1e-6
    sortino = float(excess_r.mean() / downside_std * np.sqrt(252.0)) if downside_std > 1e-8 else 0.0
    
    # Drawdowns
    dd = calculate_drawdown_series(r)
    max_dd = float(dd.min())
    
    # Drawdown duration
    in_dd = dd < 0.0
    dd_durations = []
    curr_dur = 0
    for val in in_dd:
        if val:
            curr_dur += 1
        else:
            if curr_dur > 0:
                dd_durations.append(curr_dur)
            curr_dur = 0
    if curr_dur > 0:
        dd_durations.append(curr_dur)
    max_duration = max(dd_durations) if dd_durations else 0
    
    # Calmar
    calmar = float(cagr / abs(max_dd)) if abs(max_dd) > 1e-6 else 0.0
    
    # Higher moments
    skew = float(stats.skew(r))
    kurt = float(stats.kurtosis(r))
    
    # Win rate & Profit factor
    pos = r[r > 0.0]
    neg = r[r < 0.0]
    win_rate = float(len(pos) / n_days)
    sum_gain = float(pos.sum())
    sum_loss = float(abs(neg.sum()))
    profit_factor = (sum_gain / sum_loss) if sum_loss > 1e-8 else 999.0
    
    # Annual Turnover
    if turnover is not None and len(turnover) > 0:
        ann_to = float(turnover.sum() / max(years, 1e-4))
    else:
        ann_to = 0.0
        
    return PerformanceMetrics(
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
        profit_factor=profit_factor,
        annual_turnover=ann_to,
    )
