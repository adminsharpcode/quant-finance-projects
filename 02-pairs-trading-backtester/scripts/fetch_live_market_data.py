"""
Script to fetch real-world live market data via yfinance and Binance
and update both CSV universes and the Web pairs_data.js bundle.
"""

import os
import json
import numpy as np
import pandas as pd
import yfinance as yf

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
WEB_DIR = os.path.join(PROJECT_ROOT, "web")


def fetch_and_save_live_universe():
    print("[1/3] Downloading live equity universe from Yahoo Finance...")
    equity_tickers = ["JPM", "BAC", "XOM", "CVX", "MSFT", "AAPL", "NVDA", "AMD"]
    raw_eq = yf.download(equity_tickers, period="3y", interval="1d", progress=False, auto_adjust=True)

    if isinstance(raw_eq.columns, pd.MultiIndex):
        if "Close" in raw_eq.columns.levels[0]:
            df_eq = raw_eq["Close"]
        else:
            df_eq = raw_eq.xs("Close", axis=1, level=0)
    else:
        df_eq = raw_eq[["Close"]]

    df_eq = df_eq[equity_tickers].dropna().round(2)
    df_eq.index.name = "Date"
    eq_path = os.path.join(DATA_DIR, "equity_pairs_universe.csv")
    df_eq.to_csv(eq_path)
    print(f" -> Saved {len(df_eq)} live daily bars to {eq_path}")

    print("[2/3] Downloading live commodity & future spreads...")
    # CL=F (WTI), BZ=F (Brent), GC=F (Gold), SI=F (Silver)
    comm_map = {"CL=F": "WTI", "BZ=F": "BRENT", "GC=F": "GOLD", "SI=F": "SILVER"}
    raw_comm = yf.download(list(comm_map.keys()), period="3y", interval="1d", progress=False, auto_adjust=True)
    if isinstance(raw_comm.columns, pd.MultiIndex):
        if "Close" in raw_comm.columns.levels[0]:
            df_comm = raw_comm["Close"]
        else:
            df_comm = raw_comm.xs("Close", axis=1, level=0)
    else:
        df_comm = raw_comm[["Close"]]

    df_comm = df_comm.rename(columns=comm_map)[["WTI", "BRENT", "GOLD", "SILVER"]].dropna().round(2)
    df_comm.index.name = "Date"
    comm_path = os.path.join(DATA_DIR, "commodity_spreads.csv")
    df_comm.to_csv(comm_path)
    print(f" -> Saved {len(df_comm)} live daily bars to {comm_path}")

    print("[3/3] Generating live bundle for web/pairs_data.js...")
    # Bundle pairs into pairs_data.js
    pairs_config = [
        {"id": "CVX_XOM", "name": "US Integrated Oil", "cat": "Energy", "symX": "XOM", "symY": "CVX", "src": df_eq},
        {"id": "BAC_JPM", "name": "US Banking", "cat": "Financials", "symX": "JPM", "symY": "BAC", "src": df_eq},
        {"id": "MSFT_AAPL", "name": "Mega-Cap Tech", "cat": "Technology", "symX": "AAPL", "symY": "MSFT", "src": df_eq},
        {"id": "NVDA_AMD", "name": "Semiconductors", "cat": "Technology", "symX": "AMD", "symY": "NVDA", "src": df_eq},
        {"id": "BRENT_WTI", "name": "Crude Benchmark Spread", "cat": "Commodities", "symX": "WTI", "symY": "BRENT", "src": df_comm},
        {"id": "SILVER_GOLD", "name": "Gold / Silver Ratio", "cat": "Commodities", "symX": "GOLD", "symY": "SILVER", "src": df_comm},
    ]

    pairs_dict = {}
    for p in pairs_config:
        src_df = p["src"]
        sub = src_df[[p["symX"], p["symY"]]].dropna()
        dates = [d.strftime("%Y-%m-%d") for d in sub.index]
        x_vals = sub[p["symX"]].tolist()
        y_vals = sub[p["symY"]].tolist()

        pairs_dict[p["id"]] = {
            "name": p["name"],
            "category": p["cat"],
            "symbolX": p["symX"],
            "symbolY": p["symY"],
            "dates": dates,
            "x": x_vals,
            "y": y_vals,
            "lastPriceX": float(x_vals[-1]),
            "lastPriceY": float(y_vals[-1]),
            "isLive": True,
            "lastUpdated": dates[-1],
        }

    web_js_content = f"// REAL LIVE MARKET DATA BUNDLE - Generated directly from Yahoo Finance\nwindow.PAIRS_DATA = {json.dumps(pairs_dict, indent=2)};\n"
    web_js_path = os.path.join(WEB_DIR, "pairs_data.js")
    with open(web_js_path, "w", encoding="utf-8") as f:
        f.write(web_js_content)
    print(f" -> Successfully updated {web_js_path} with {len(pairs_dict)} live real market pairs!")


if __name__ == "__main__":
    fetch_and_save_live_universe()
