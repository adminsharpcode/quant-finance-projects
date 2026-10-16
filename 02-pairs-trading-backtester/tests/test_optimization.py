"""
Unit tests for PairGridOptimizer parameter optimization engine.
"""

import numpy as np
import pytest
from src.optimization.grid_search import PairGridOptimizer, OptimizationResult


def generate_cointegrated_series(n=400, seed=42):
    np.random.seed(seed)
    x = 100.0 + np.cumsum(np.random.normal(0, 1.0, n))
    ou = np.zeros(n)
    for t in range(1, n):
        ou[t] = 0.85 * ou[t - 1] + np.random.normal(0, 0.8)
    y = 1.25 * x + 15.0 + ou
    return y, x


def test_grid_optimizer_basic():
    y, x = generate_cointegrated_series(300)
    optimizer = PairGridOptimizer()
    grid = {
        "z_entry": [1.5, 2.0],
        "z_exit": [0.0],
        "z_stop": [3.5],
        "kalman_delta": [1e-4],
    }
    res = optimizer.optimize(y, x, param_grid=grid, objective="sharpe", min_trades=2)
    assert isinstance(res, OptimizationResult)
    assert res.total_combinations_tested == 2
    assert "z_entry" in res.best_params
    assert "sharpe_ratio" in res.best_metrics
    assert res.walk_forward_efficiency >= 0.0
    assert len(res.results_df) == 2


def test_grid_optimizer_objectives():
    y, x = generate_cointegrated_series(300)
    optimizer = PairGridOptimizer()
    grid = {
        "z_entry": [1.5, 2.0],
        "z_exit": [-0.1, 0.1],
        "z_stop": [3.5],
        "kalman_delta": [1e-4],
    }
    # Test calmar objective
    res_calmar = optimizer.optimize(y, x, param_grid=grid, objective="calmar", min_trades=1)
    assert res_calmar.objective_metric == "calmar"
    assert "calmar_ratio" in str(res_calmar.best_metrics) or "score" in res_calmar.best_metrics

    # Test return objective
    res_ret = optimizer.optimize(y, x, param_grid=grid, objective="return", min_trades=1)
    assert res_ret.objective_metric == "return"
