"""
Cross-sectional ranking and dollar-neutral portfolio construction.
Implements the exact Asness, Moskowitz, & Pedersen (2013) ranking transformation.
"""

from typing import Optional
import numpy as np
import pandas as pd


def rank_cross_sectional(raw_factors: pd.DataFrame, ascending: bool = True) -> pd.DataFrame:
    """
    Ranks assets cross-sectionally across columns on each date.
    
    Parameters
    ----------
    raw_factors : pd.DataFrame
        Matrix of raw factor scores (dates x assets).
    ascending : bool, default True
        If True, lowest value receives rank 1, highest receives rank N.
        
    Returns
    -------
    pd.DataFrame
        Cross-sectional ranks.
    """
    return raw_factors.rank(axis=1, ascending=ascending, method="average")


def construct_dollar_neutral_weights(
    ranks: pd.DataFrame, 
    gross_leverage: float = 1.0
) -> pd.DataFrame:
    """
    Transforms cross-sectional ranks into strictly dollar-neutral weights:
      w_{i, t} = (rank_{i, t} - (N_t + 1) / 2) / sum(|rank_{j, t} - (N_t + 1) / 2|) * gross_leverage
      
    Guarantees:
      1. sum(w_{i, t}) == 0.0 (Zero net exposure / dollar neutral)
      2. sum(|w_{i, t}|) == gross_leverage
    """
    # Count valid assets per row
    valid_count = ranks.notna().sum(axis=1)
    center = (valid_count + 1.0) / 2.0
    
    # Demean
    demeaned = ranks.sub(center, axis=0)
    
    # Absolute sum
    abs_sum = demeaned.abs().sum(axis=1)
    
    # Weights
    weights = demeaned.div(abs_sum, axis=0) * gross_leverage
    return weights.fillna(0.0)


def construct_tercile_long_short_weights(
    raw_factors: pd.DataFrame, 
    gross_leverage: float = 1.0
) -> pd.DataFrame:
    """
    Alternative classic academic construction:
    Long top 33.3% equal-weighted (+0.5 * gross_leverage),
    Short bottom 33.3% equal-weighted (-0.5 * gross_leverage),
    Zero weight on middle 33.3%.
    """
    ranks = rank_cross_sectional(raw_factors, ascending=True)
    n_assets = ranks.shape[1]
    
    tercile_size = max(1, n_assets // 3)
    
    weights = pd.DataFrame(0.0, index=raw_factors.index, columns=raw_factors.columns)
    
    for dt in raw_factors.index:
        row = ranks.loc[dt].dropna()
        if len(row) < 3:
            continue
            
        k = max(1, len(row) // 3)
        sorted_symbols = row.sort_values().index
        shorts = sorted_symbols[:k]
        longs = sorted_symbols[-k:]
        
        # Long leg sum = +0.5 * gross_leverage
        # Short leg sum = -0.5 * gross_leverage
        weights.loc[dt, longs] = (0.5 * gross_leverage) / k
        weights.loc[dt, shorts] = -(0.5 * gross_leverage) / k
        
    return weights
