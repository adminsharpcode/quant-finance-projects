"""Backtesting engine package."""

from .execution_sim import BacktestResult, PairsExecutionSimulator, TradeRecord
from .performance import PerformanceAnalyzer, PerformanceMetrics

__all__ = [
    "BacktestResult",
    "PairsExecutionSimulator",
    "TradeRecord",
    "PerformanceAnalyzer",
    "PerformanceMetrics",
]
