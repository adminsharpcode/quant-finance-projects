"""
Live Market Data Acquisition for Quantitative Statistical Arbitrage.
=====================================================================
Supports real-time and historical bar downloads for equities, ETFs, commodities,
and crypto via Yahoo Finance (yfinance) and Binance Public API.
"""

from dataclasses import dataclass
from typing import Tuple, Optional, List
import pandas as pd
import numpy as np
import requests


@dataclass
class LivePairData:
    symbol_x: str
    symbol_y: str
    dates: pd.DatetimeIndex
    series_x: pd.Series
    series_y: pd.Series
    df: pd.DataFrame
    last_price_x: float
    last_price_y: float
    pct_change_x_24h: float
    pct_change_y_24h: float


def fetch_live_pair_prices(
    symbol_x: str,
    symbol_y: str,
    period: str = "2y",
    interval: str = "1d",
) -> LivePairData:
    """
    Fetch real market closing prices for any two assets via yfinance.
    
    Args:
        symbol_x: Ticker for asset X (e.g. 'XOM', 'MSFT', 'AMD', 'CL=F', 'BTC-USD')
        symbol_y: Ticker for asset Y (e.g. 'CVX', 'AAPL', 'NVDA', 'BZ=F', 'ETH-USD')
        period: History period ('1mo', '3mo', '6mo', '1y', '2y', '5y', 'max')
        interval: Bar resolution ('1d', '1h', '5m', '15m')
        
    Returns:
        LivePairData with aligned DatetimeIndex and synchronous price series.
    """
    import yfinance as yf

    tickers = [symbol_x, symbol_y]
    raw = yf.download(tickers, period=period, interval=interval, progress=False, auto_adjust=True)

    if raw.empty:
        raise ValueError(f"Failed to fetch market data for {symbol_x} and {symbol_y}.")

    # Handle multi-level columns in modern yfinance
    if isinstance(raw.columns, pd.MultiIndex):
        if "Close" in raw.columns.levels[0]:
            df_close = raw["Close"]
        else:
            df_close = raw.xs("Close", axis=1, level=0)
    else:
        df_close = raw[["Close"]]

    # Ensure both symbols exist
    if symbol_x not in df_close.columns or symbol_y not in df_close.columns:
        raise KeyError(f"Requested tickers ({symbol_x}, {symbol_y}) not found in response columns: {list(df_close.columns)}")

    df_pair = df_close[[symbol_x, symbol_y]].dropna()
    if len(df_pair) < 30:
        raise ValueError(f"Insufficient synchronous trading days ({len(df_pair)}) for cointegration.")

    # Remove timezone if present for clean cross-asset alignment
    if df_pair.index.tz is not None:
        df_pair.index = df_pair.index.tz_localize(None)

    sx = df_pair[symbol_x].astype(float)
    sy = df_pair[symbol_y].astype(float)

    last_x = float(sx.iloc[-1])
    last_y = float(sy.iloc[-1])
    chg_x = float((sx.iloc[-1] / sx.iloc[-2] - 1.0) * 100.0) if len(sx) >= 2 else 0.0
    chg_y = float((sy.iloc[-1] / sy.iloc[-2] - 1.0) * 100.0) if len(sy) >= 2 else 0.0

    return LivePairData(
        symbol_x=symbol_x,
        symbol_y=symbol_y,
        dates=df_pair.index,
        series_x=sx,
        series_y=sy,
        df=df_pair,
        last_price_x=last_x,
        last_price_y=last_y,
        pct_change_x_24h=chg_x,
        pct_change_y_24h=chg_y,
    )


def fetch_crypto_pair_binance(
    symbol_x: str = "BTCUSDT",
    symbol_y: str = "ETHUSDT",
    interval: str = "1d",
    limit: int = 750,
) -> LivePairData:
    """
    Fetch live crypto spot candlestick data directly from Binance Public REST API.
    Does not require API keys or credentials.
    """
    base_url = "https://api.binance.com/api/v3/klines"

    def _fetch_symbol(sym: str) -> pd.DataFrame:
        url = f"{base_url}?symbol={sym.upper()}&interval={interval}&limit={limit}"
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        
        # Columns: [open_time, open, high, low, close, volume, close_time, quote_vol, trades, ...]
        records = []
        for row in data:
            records.append({
                "timestamp": pd.to_datetime(row[0], unit="ms"),
                "close": float(row[4]),
            })
        df = pd.DataFrame(records).set_index("timestamp")
        return df

    df_x = _fetch_symbol(symbol_x)
    df_y = _fetch_symbol(symbol_y)

    merged = pd.concat([df_x["close"].rename(symbol_x), df_y["close"].rename(symbol_y)], axis=1).dropna()
    if len(merged) < 30:
        raise ValueError(f"Insufficient crypto data bars ({len(merged)})")

    sx = merged[symbol_x]
    sy = merged[symbol_y]

    return LivePairData(
        symbol_x=symbol_x,
        symbol_y=symbol_y,
        dates=merged.index,
        series_x=sx,
        series_y=sy,
        df=merged,
        last_price_x=float(sx.iloc[-1]),
        last_price_y=float(sy.iloc[-1]),
        pct_change_x_24h=float((sx.iloc[-1] / sx.iloc[-2] - 1.0) * 100.0),
        pct_change_y_24h=float((sy.iloc[-1] / sy.iloc[-2] - 1.0) * 100.0),
    )
