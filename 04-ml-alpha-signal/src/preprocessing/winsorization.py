"""
Robust Cross-Sectional Factor Winsorization and Standardization.

Implements:
1. Median Absolute Deviation (MAD) Winsorization:
   Robust to fat-tailed financial distributions unlike Gaussian standard deviation.
2. Cross-Sectional Z-Score Standardization per timestamp.
3. Uniform Quantile / Percentile Normalization.
"""

from typing import List, Union
import numpy as np
import pandas as pd


def mad_winsorize_series(s: pd.Series, n_mads: float = 3.0) -> pd.Series:
    """
    Winsorize a pandas Series using Median Absolute Deviation (MAD).
    
    Formula:
        MAD = median(|x - median(x)|)
        scale = 1.4826 (for asymptotic normal consistency)
        lower_bound = median - n_mads * scale * MAD
        upper_bound = median + n_mads * scale * MAD
    """
    valid = s.dropna()
    if len(valid) < 3:
        return s
        
    med = valid.median()
    mad = np.median(np.abs(valid - med))
    if mad < 1e-12:
        return s
        
    bound = n_mads * 1.4826 * mad
    return s.clip(lower=med - bound, upper=med + bound)


def cross_sectional_mad_winsorize(
    df: pd.DataFrame, 
    factor_cols: List[str], 
    date_col: str = "date", 
    n_mads: float = 3.0
) -> pd.DataFrame:
    """
    Apply MAD winsorization cross-sectionally per timestamp.
    """
    result = df.copy()
    for col in factor_cols:
        result[col] = result.groupby(date_col)[col].transform(
            lambda s: mad_winsorize_series(s, n_mads=n_mads)
        )
    return result


def cross_sectional_zscore(
    df: pd.DataFrame, 
    factor_cols: List[str], 
    date_col: str = "date"
) -> pd.DataFrame:
    """
    Standardize factors cross-sectionally per date:
    
    Formula:
        z_{i, t} = (f_{i, t} - mean(f_{., t})) / std(f_{., t})
    """
    result = df.copy()
    for col in factor_cols:
        def _zscore(s: pd.Series) -> pd.Series:
            mean = s.mean()
            std = s.std()
            if std is None or std < 1e-12 or np.isnan(std):
                return s - mean
            return (s - mean) / std

        result[col] = result.groupby(date_col)[col].transform(_zscore)
    return result


def cross_sectional_rank_normalize(
    df: pd.DataFrame, 
    factor_cols: List[str], 
    date_col: str = "date"
) -> pd.DataFrame:
    """
    Convert raw factors to uniform percentile rank scores centered at 0: [-0.5, +0.5].
    """
    result = df.copy()
    for col in factor_cols:
        def _rank(s: pd.Series) -> pd.Series:
            ranks = s.rank(pct=True)
            return ranks - 0.5

        result[col] = result.groupby(date_col)[col].transform(_rank)
    return result
