"""
Live market data acquisition module for quantitative statistical arbitrage.
"""
from .live_feed import fetch_live_pair_prices, fetch_crypto_pair_binance, LivePairData

__all__ = ["fetch_live_pair_prices", "fetch_crypto_pair_binance", "LivePairData"]
