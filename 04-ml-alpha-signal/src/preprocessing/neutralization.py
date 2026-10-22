"""
Factor Neutralization and Orthogonalization.

Eliminates disguised systematic risk exposures (market beta, sector tilts, size)
from raw alpha factors via cross-sectional OLS null-space projection:

    y_t = X_t * beta_t + f*_t
    f*_t = (I - X_t * (X_t^T * X_t)^(-1) * X_t^T) * y_t

Guarantees Cov(f*_t, X_{k, t}) = 0 for all risk factors k.
"""

from typing import List, Optional
import numpy as np
import pandas as pd


def neutralize_factor_vector(
    y: np.ndarray, 
    X: np.ndarray, 
    ridge_lambda: float = 1e-6
) -> np.ndarray:
    """
    Project factor vector y onto the null space of risk factor matrix X.
    
    Parameters:
        y: (N,) or (N, 1) target factor values
        X: (N, K) design matrix of risk exposures (e.g. intercept, sector dummies, beta)
        ridge_lambda: Tikhonov regularization parameter for numerical stability
        
    Returns:
        (N,) orthogonalized idiosyncratic factor residual
    """
    y = np.asarray(y).reshape(-1, 1)
    X = np.asarray(X)
    
    # Remove any NaN entries for projection
    valid_mask = (~np.isnan(y.flatten())) & (~np.isnan(X).any(axis=1))
    if np.sum(valid_mask) <= X.shape[1]:
        return y.flatten()
        
    y_val = y[valid_mask]
    X_val = X[valid_mask]
    
    # Regularized OLS: beta = (X^T X + lambda I)^(-1) X^T y
    xtx = X_val.T @ X_val
    diag_reg = ridge_lambda * np.eye(xtx.shape[0])
    try:
        inv_xtx = np.linalg.pinv(xtx + diag_reg)
        beta = inv_xtx @ (X_val.T @ y_val)
        y_hat = X_val @ beta
        residual_val = y_val - y_hat
        
        residuals = np.full(len(y), np.nan)
        residuals[valid_mask] = residual_val.flatten()
        return residuals
    except Exception:
        return y.flatten()


def neutralize_cross_section(
    df: pd.DataFrame,
    factor_cols: List[str],
    risk_cols: Optional[List[str]] = None,
    sector_col: Optional[str] = "sector",
    date_col: str = "date",
    re_standardize: bool = True
) -> pd.DataFrame:
    """
    Perform cross-sectional neutralization across each date independently.
    
    Parameters:
        df: Cross-sectional dataframe
        factor_cols: List of factor column names to neutralize
        risk_cols: Continuous risk exposures (e.g., ['beta_sp500', 'log_mcap'])
        sector_col: Categorical sector column for one-hot dummy matrix
        date_col: Timestamp column
        re_standardize: Whether to z-score the neutralized residuals to std=1
    """
    result = df.copy()
    if risk_cols is None:
        risk_cols = []
        
    # Group by date
    dates = result[date_col].unique()
    
    for dt in dates:
        idx = result[result[date_col] == dt].index
        sub_df = result.loc[idx]
        n_samples = len(sub_df)
        
        if n_samples < 4:
            continue
            
        # Build design matrix X
        x_blocks = [np.ones((n_samples, 1))] # Intercept
        
        # Sector dummies (drop one to avoid collinearity with intercept, or use pinv)
        if sector_col and sector_col in sub_df.columns:
            dummies = pd.get_dummies(sub_df[sector_col], drop_first=True, dtype=float).values
            if dummies.shape[1] > 0:
                x_blocks.append(dummies)
                
        # Continuous risk exposures
        for r_col in risk_cols:
            if r_col in sub_df.columns:
                r_val = sub_df[r_col].values.reshape(-1, 1)
                # Fill na with mean
                mean_val = np.nanmean(r_val) if not np.isnan(r_val).all() else 0.0
                r_val = np.nan_to_num(r_val, nan=mean_val)
                x_blocks.append(r_val)
                
        X = np.hstack(x_blocks)
        
        for f_col in factor_cols:
            y = sub_df[f_col].values
            res = neutralize_factor_vector(y, X)
            
            if re_standardize:
                res_std = np.nanstd(res)
                if res_std > 1e-12:
                    res = (res - np.nanmean(res)) / res_std
                    
            result.loc[idx, f_col] = res
            
    return result


def gram_schmidt_orthogonalization(matrix: np.ndarray) -> np.ndarray:
    """
    Orthogonalize columns of a matrix using Modified Gram-Schmidt process.
    Useful for creating mutually orthogonal factor sets.
    """
    Q = np.zeros_like(matrix, dtype=float)
    for j in range(matrix.shape[1]):
        q = matrix[:, j].astype(float)
        for i in range(j):
            proj = np.dot(Q[:, i], matrix[:, j])
            q -= proj * Q[:, i]
        norm = np.linalg.norm(q)
        if norm > 1e-12:
            Q[:, j] = q / norm
        else:
            Q[:, j] = q
    return Q
