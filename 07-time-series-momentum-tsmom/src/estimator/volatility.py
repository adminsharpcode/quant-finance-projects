"""
Volatility estimation modules for risk-scaling and volatility targeting.
Implements rolling sample standard deviation and Exponentially Weighted Moving Average (EWMA)
as formulated in Moskowitz, Ooi, & Pedersen (2012).
"""

from abc import ABC, abstractmethod
from typing import Union
import numpy as np
import pandas as pd


class BaseVolatilityEstimator(ABC):
    """Abstract base class for ex-ante volatility estimators."""
    
    def __init__(self, annualization_factor: float = 252.0, min_vol: float = 0.01):
        self.annualization_factor = annualization_factor
        self.min_vol = min_vol

    @abstractmethod
    def estimate(self, returns: Union[pd.DataFrame, pd.Series]) -> Union[pd.DataFrame, pd.Series]:
        """
        Calculates annualized ex-ante volatility.
        
        Parameters
        ----------
        returns : pd.DataFrame or pd.Series
            Daily asset returns.
            
        Returns
        -------
        pd.DataFrame or pd.Series
            Annualized standard deviations.
        """
        pass


class RollingVolatilityEstimator(BaseVolatilityEstimator):
    """
    Standard rolling window sample standard deviation estimator.
    sigma_t = sqrt(252) * std(r_{t-W+1 : t})
    """
    
    def __init__(self, window: int = 60, annualization_factor: float = 252.0, min_vol: float = 0.01):
        super().__init__(annualization_factor=annualization_factor, min_vol=min_vol)
        self.window = window

    def estimate(self, returns: Union[pd.DataFrame, pd.Series]) -> Union[pd.DataFrame, pd.Series]:
        # Minimum periods can be half window or window
        min_p = max(5, self.window // 2)
        rolling_std = returns.rolling(window=self.window, min_periods=min_p).std()
        ann_vol = rolling_std * np.sqrt(self.annualization_factor)
        # Floor at min_vol to avoid zero division
        return ann_vol.clip(lower=self.min_vol)


class EWMAVolatilityEstimator(BaseVolatilityEstimator):
    """
    Exponentially Weighted Moving Average (EWMA) volatility estimator.
    sigma_t^2 = (1 - lambda) * sum_{k=0}^inf lambda^k * (r_{t-k} - mu)^2
    Standard RiskMetrics parameter lambda = 0.94 (daily decay).
    """
    
    def __init__(
        self, 
        decay: float = 0.94, 
        min_periods: int = 20, 
        annualization_factor: float = 252.0, 
        min_vol: float = 0.01
    ):
        super().__init__(annualization_factor=annualization_factor, min_vol=min_vol)
        self.decay = decay
        self.min_periods = min_periods

    def estimate(self, returns: Union[pd.DataFrame, pd.Series]) -> Union[pd.DataFrame, pd.Series]:
        # pandas ewm parameter: alpha = 1 - lambda
        alpha = 1.0 - self.decay
        ewm_var = returns.pow(2).ewm(alpha=alpha, min_periods=self.min_periods).mean()
        ann_vol = np.sqrt(ewm_var * self.annualization_factor)
        return ann_vol.clip(lower=self.min_vol)


def estimate_portfolio_volatility(
    weights: pd.DataFrame, 
    cov_matrix: pd.DataFrame
) -> float:
    """
    Computes annualized portfolio ex-ante volatility given weight vector w and covariance Sigma:
    sigma_p = sqrt(w^T * Sigma * w)
    """
    w = weights.values.flatten()
    sigma = cov_matrix.values
    var = float(w.T @ sigma @ w)
    return np.sqrt(max(0.0, var))
