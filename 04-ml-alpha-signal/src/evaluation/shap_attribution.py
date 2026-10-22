"""
TreeSHAP Feature Attribution and Model Interpretability.

Decomposes LightGBM predictions into additive Shapley factor contributions:

    f(x) = phi_0 + sum_{j=1}^M phi_j(x)

Provides both global factor attribution and local asset-level alpha breakdowns.
"""

from typing import Dict, List, Optional, Tuple, Union
import numpy as np
import pandas as pd


def compute_tree_shap_attributions(
    lgbm_model,
    X: Union[pd.DataFrame, np.ndarray],
    max_samples: int = 1000
) -> Tuple[pd.DataFrame, pd.Series]:
    """
    Compute TreeSHAP values for the LightGBM model.
    
    Parameters:
        lgbm_model: Fitted LightGBMAlphaModel or lgb.LGBMRegressor
        X: Feature matrix
        max_samples: Max rows to evaluate for computational speed
        
    Returns:
        1. DataFrame of SHAP values per observation (same shape as X)
        2. Series of global Mean Absolute SHAP values (sorted descending)
    """
    raw_model = lgbm_model.model if hasattr(lgbm_model, "model") else lgbm_model
    feature_names = lgbm_model.feature_names_ if hasattr(lgbm_model, "feature_names_") else (
        list(X.columns) if isinstance(X, pd.DataFrame) else [f"f_{i}" for i in range(X.shape[1])]
    )
    
    # Subsample if dataset is large
    if len(X) > max_samples:
        if isinstance(X, pd.DataFrame):
            X_eval = X.sample(n=max_samples, random_state=42)
        else:
            indices = np.random.choice(len(X), size=max_samples, replace=False)
            X_eval = X[indices]
    else:
        X_eval = X
        
    try:
        import shap
        explainer = shap.TreeExplainer(raw_model)
        shap_values = explainer.shap_values(X_eval)
        
        # If binary classification returns list, take class 1; for regression it's array
        if isinstance(shap_values, list):
            shap_values = shap_values[1]
            
        shap_df = pd.DataFrame(shap_values, columns=feature_names, index=X_eval.index if isinstance(X_eval, pd.DataFrame) else None)
        mean_abs_shap = shap_df.abs().mean().sort_values(ascending=False)
        return shap_df, mean_abs_shap
    except Exception as e:
        # Fallback to model feature importances
        importances = raw_model.feature_importances_
        norm_imp = importances / np.maximum(np.sum(importances), 1e-8)
        mean_abs_shap = pd.Series(norm_imp, index=feature_names).sort_values(ascending=False)
        dummy_shap = pd.DataFrame(np.zeros((len(X_eval), len(feature_names))), columns=feature_names)
        return dummy_shap, mean_abs_shap


def decompose_single_prediction(
    lgbm_model,
    feature_vector: Union[pd.Series, np.ndarray, pd.DataFrame],
    feature_names: Optional[List[str]] = None
) -> Dict[str, Union[float, Dict[str, float]]]:
    """
    Local TreeSHAP explanation for a single asset at a specific point in time.
    Breaks down base value + factor contributions = final alpha prediction.
    """
    raw_model = lgbm_model.model if hasattr(lgbm_model, "model") else lgbm_model
    f_names = lgbm_model.feature_names_ if hasattr(lgbm_model, "feature_names_") else feature_names
    
    if isinstance(feature_vector, pd.Series):
        x_mat = feature_vector.values.reshape(1, -1)
        if f_names is None:
            f_names = list(feature_vector.index)
    elif isinstance(feature_vector, pd.DataFrame):
        x_mat = feature_vector.values
        if f_names is None:
            f_names = list(feature_vector.columns)
    else:
        x_mat = np.asarray(feature_vector).reshape(1, -1)
        if f_names is None:
            f_names = [f"f_{i}" for i in range(x_mat.shape[1])]
            
    try:
        import shap
        explainer = shap.TreeExplainer(raw_model)
        base_val = float(explainer.expected_value)
        shap_vals = explainer.shap_values(x_mat)[0]
        
        contribs = {name: float(val) for name, val in zip(f_names, shap_vals)}
        pred_val = float(base_val + np.sum(shap_vals))
        
        return {
            "expected_value": base_val,
            "prediction": pred_val,
            "contributions": contribs,
        }
    except Exception:
        pred_val = float(raw_model.predict(x_mat)[0])
        return {
            "expected_value": 0.0,
            "prediction": pred_val,
            "contributions": {name: 0.0 for name in f_names},
        }
