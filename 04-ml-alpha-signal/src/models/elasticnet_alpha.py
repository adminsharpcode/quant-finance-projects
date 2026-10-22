"""
ElasticNet Linear Alpha Model.

Regularized linear baseline combining L1 (sparsity/feature selection)
and L2 (collinear shrinkage) penalties:

    min_w (1 / (2n)) ||y - Xw||_2^2 + alpha * l1_ratio * ||w||_1 + 0.5 * alpha * (1 - l1_ratio) * ||w||_2^2
"""

from typing import Dict, List, Optional, Union
import numpy as np
import pandas as pd
from sklearn.linear_model import ElasticNet


class ElasticNetAlphaModel:
    """
    ElasticNet Regularized Linear Alpha Model.
    
    Parameters:
        alpha: Constant multiplying penalty terms (regularization strength).
        l1_ratio: Mixing parameter (1.0 = Lasso, 0.0 = Ridge).
        max_iter: Maximum solver iterations.
        random_state: Seed.
    """
    def __init__(
        self,
        alpha: float = 0.01,
        l1_ratio: float = 0.5,
        max_iter: int = 2000,
        random_state: int = 42
    ):
        self.alpha = alpha
        self.l1_ratio = l1_ratio
        self.max_iter = max_iter
        self.random_state = random_state
        
        self.model = ElasticNet(
            alpha=self.alpha,
            l1_ratio=self.l1_ratio,
            max_iter=self.max_iter,
            random_state=self.random_state
        )
        self.feature_names_: List[str] = []

    def fit(
        self,
        X: Union[pd.DataFrame, np.ndarray],
        y: Union[pd.Series, np.ndarray]
    ) -> "ElasticNetAlphaModel":
        if isinstance(X, pd.DataFrame):
            self.feature_names_ = list(X.columns)
        else:
            self.feature_names_ = [f"f_{i}" for i in range(X.shape[1])]
            
        self.model.fit(X, y)
        return self

    def predict(self, X: Union[pd.DataFrame, np.ndarray]) -> np.ndarray:
        return self.model.predict(X)

    @property
    def coefficients_(self) -> pd.Series:
        return pd.Series(self.model.coef_, index=self.feature_names_).sort_values(ascending=False)

    @property
    def intercept_(self) -> float:
        return float(self.model.intercept_)
