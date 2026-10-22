"""
LightGBM Gradient Boosted Decision Tree Model for Financial Alpha Signals.

Configured with conservative depth limits, feature subsampling,
L1/L2 regularization, and Huber loss to resist financial noise and overfitting.
"""

from typing import Dict, List, Optional, Tuple, Union
import numpy as np
import pandas as pd
import lightgbm as lgb


class LightGBMAlphaModel:
    """
    LightGBM Alpha Signal Regressor.
    
    Parameters:
        n_estimators: Number of boosting iterations.
        learning_rate: Shrinkage parameter.
        max_depth: Maximum tree depth (kept small: 3-5 to curb combinatorial overfitting).
        num_leaves: Max leaves per tree (typically 2^max_depth - 1).
        subsample: Row bagging fraction per tree.
        colsample_bytree: Feature fraction per tree.
        reg_alpha: L1 regularization penalty on leaf weights.
        reg_lambda: L2 regularization penalty on leaf weights.
        loss_type: 'huber' (robust to heavy-tailed return spikes) or 'mse'.
        huber_delta: Delta threshold for Huber loss.
        random_state: Seed for reproducibility.
    """
    def __init__(
        self,
        n_estimators: int = 150,
        learning_rate: float = 0.03,
        max_depth: int = 4,
        num_leaves: int = 15,
        subsample: float = 0.8,
        colsample_bytree: float = 0.8,
        reg_alpha: float = 0.1,
        reg_lambda: float = 1.0,
        loss_type: str = "huber",
        huber_delta: float = 1.0,
        random_state: int = 42
    ):
        self.n_estimators = n_estimators
        self.learning_rate = learning_rate
        self.max_depth = max_depth
        self.num_leaves = num_leaves
        self.subsample = subsample
        self.colsample_bytree = colsample_bytree
        self.reg_alpha = reg_alpha
        self.reg_lambda = reg_lambda
        self.loss_type = loss_type
        self.huber_delta = huber_delta
        self.random_state = random_state
        
        self.model: Optional[lgb.LGBMRegressor] = None
        self.feature_names_: List[str] = []

    def fit(
        self,
        X: Union[pd.DataFrame, np.ndarray],
        y: Union[pd.Series, np.ndarray],
        eval_set: Optional[Tuple[Union[pd.DataFrame, np.ndarray], Union[pd.Series, np.ndarray]]] = None,
        early_stopping_rounds: int = 25,
        verbose: bool = False
    ) -> "LightGBMAlphaModel":
        """
        Fit model using out-of-fold validation set for early stopping if provided.
        """
        if isinstance(X, pd.DataFrame):
            self.feature_names_ = list(X.columns)
        else:
            self.feature_names_ = [f"f_{i}" for i in range(X.shape[1])]
            
        objective = "huber" if self.loss_type == "huber" else "regression"
        
        self.model = lgb.LGBMRegressor(
            n_estimators=self.n_estimators,
            learning_rate=self.learning_rate,
            max_depth=self.max_depth,
            num_leaves=self.num_leaves,
            subsample=self.subsample,
            colsample_bytree=self.colsample_bytree,
            reg_alpha=self.reg_alpha,
            reg_lambda=self.reg_lambda,
            objective=objective,
            alpha=self.huber_delta if objective == "huber" else None,
            random_state=self.random_state,
            n_jobs=-1,
            importance_type="gain",
            verbose=-1
        )
        
        callbacks = []
        if eval_set is not None and early_stopping_rounds > 0:
            callbacks.append(lgb.early_stopping(stopping_rounds=early_stopping_rounds, verbose=verbose))
            
        eval_data = [eval_set] if eval_set is not None else None
        
        self.model.fit(
            X, y,
            eval_set=eval_data,
            callbacks=callbacks
        )
        return self

    def predict(self, X: Union[pd.DataFrame, np.ndarray]) -> np.ndarray:
        if self.model is None:
            raise RuntimeError("Model has not been fitted yet.")
        return self.model.predict(X)

    @property
    def feature_importances_(self) -> pd.Series:
        if self.model is None:
            raise RuntimeError("Model has not been fitted yet.")
        return pd.Series(self.model.feature_importances_, index=self.feature_names_).sort_values(ascending=False)
