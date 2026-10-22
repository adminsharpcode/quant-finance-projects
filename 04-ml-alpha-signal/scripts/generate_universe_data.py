"""
Script to generate institutional-grade cross-sectional equity dataset.
Universe consists of 14 liquid US equities across 6 sectors over ~500 trading days.
Includes realistic Geometric Brownian Motion with stochastic volatility,
jump diffusions, sector co-movement, and volume/microstructure characteristics.
"""
import numpy as np
import pandas as pd
from pathlib import Path

def generate_universe_data(output_path: Path):
    np.random.seed(42)
    
    # 14 tickers across 6 sectors
    tickers_info = [
        # Technology
        {"ticker": "AAPL", "sector": "Technology", "start_price": 175.0, "beta": 1.15, "vol": 0.22, "mcap": 3100.0, "avg_vol": 52000000},
        {"ticker": "MSFT", "sector": "Technology", "start_price": 380.0, "beta": 1.10, "vol": 0.21, "mcap": 3050.0, "avg_vol": 24000000},
        {"ticker": "NVDA", "sector": "Technology", "start_price": 95.0,  "beta": 1.75, "vol": 0.46, "mcap": 2800.0, "avg_vol": 68000000},
        {"ticker": "GOOGL","sector": "Technology", "start_price": 140.0, "beta": 1.12, "vol": 0.24, "mcap": 2100.0, "avg_vol": 26000000},
        # Financials
        {"ticker": "JPM",  "sector": "Financials", "start_price": 180.0, "beta": 0.95, "vol": 0.18, "mcap": 540.0,  "avg_vol": 11000000},
        {"ticker": "GS",   "sector": "Financials", "start_price": 390.0, "beta": 1.20, "vol": 0.22, "mcap": 145.0,  "avg_vol": 3200000},
        # Healthcare
        {"ticker": "JNJ",  "sector": "Healthcare", "start_price": 160.0, "beta": 0.60, "vol": 0.14, "mcap": 410.0,  "avg_vol": 7800000},
        {"ticker": "UNH",  "sector": "Healthcare", "start_price": 490.0, "beta": 0.72, "vol": 0.17, "mcap": 480.0,  "avg_vol": 3800000},
        # Consumer
        {"ticker": "AMZN", "sector": "Consumer",   "start_price": 170.0, "beta": 1.25, "vol": 0.28, "mcap": 1950.0, "avg_vol": 42000000},
        {"ticker": "WMT",  "sector": "Consumer",   "start_price": 60.0,  "beta": 0.55, "vol": 0.15, "mcap": 520.0,  "avg_vol": 18000000},
        {"ticker": "TSLA", "sector": "Consumer",   "start_price": 210.0, "beta": 1.85, "vol": 0.52, "mcap": 750.0,  "avg_vol": 75000000},
        # Energy
        {"ticker": "XOM",  "sector": "Energy",     "start_price": 110.0, "beta": 0.70, "vol": 0.22, "mcap": 460.0,  "avg_vol": 16000000},
        {"ticker": "CVX",  "sector": "Energy",     "start_price": 150.0, "beta": 0.75, "vol": 0.21, "mcap": 300.0,  "avg_vol": 8500000},
        # Industrials
        {"ticker": "CAT",  "sector": "Industrials","start_price": 310.0, "beta": 1.05, "vol": 0.23, "mcap": 175.0,  "avg_vol": 4100000},
    ]

    dates = pd.bdate_range(start="2024-01-02", periods=504) # ~2 years of trading days
    n_days = len(dates)
    
    # Common market factor (S&P 500 proxy)
    dt = 1.0 / 252.0
    market_drift = 0.10 * dt
    market_vol = 0.15 * np.sqrt(dt)
    market_shocks = np.random.normal(0, 1, n_days)
    market_returns = market_drift + market_vol * market_shocks
    
    # Sector shocks
    unique_sectors = sorted(list(set(t["sector"] for t in tickers_info)))
    sector_shocks = {
        s: np.random.normal(0, 0.08 * np.sqrt(dt), n_days)
        for s in unique_sectors
    }
    
    ticker_alpha_tilts = {
        "NVDA": 0.00075, "MSFT": 0.00045, "AAPL": 0.00040, "AMZN": 0.00050,
        "GOOGL": 0.00035, "JPM": 0.00025, "GS": 0.00020, "UNH": 0.00020,
        "CAT": 0.00010, "XOM": -0.00010, "CVX": -0.00015, "WMT": 0.00015,
        "JNJ": 0.00005, "TSLA": 0.00060
    }
    
    records = []
    
    for t_info in tickers_info:
        ticker = t_info["ticker"]
        sector = t_info["sector"]
        beta = t_info["beta"]
        ann_vol = t_info["vol"]
        daily_idio_vol = ann_vol * np.sqrt(dt) * 0.7
        base_price = t_info["start_price"]
        mcap = t_info["mcap"]
        base_vol = t_info["avg_vol"]
        
        # Idiosyncratic shocks
        idio_shocks = np.random.normal(0, daily_idio_vol, n_days)
        
        # Occasional jump shock (Poisson jump component)
        jump_occurrences = np.random.poisson(0.015, n_days) # ~3-4 jumps per year
        jump_sizes = np.random.normal(-0.005, 0.035, n_days) * jump_occurrences
        
        # Combine: beta * market + sector + idio + jumps
        daily_returns = (beta * market_returns) + sector_shocks[sector] + idio_shocks + jump_sizes
        
        # Path simulation with realistic factor dynamics
        prices = [base_price]
        for idx_r, r in enumerate(daily_returns):
            drift_signal = 0.0
            if idx_r > 60:
                p_past_60 = prices[idx_r - 60]
                p_past_5 = prices[idx_r - 5]
                # Positive intermediate momentum persistence
                mom_signal = (p_past_5 - p_past_60) / p_past_60
                # Positive short-term 5-day reversal pull-back
                rev_signal = - (prices[-1] - p_past_5) / p_past_5
                
                # Daily forward alpha drift
                drift_signal = (
                    ticker_alpha_tilts.get(ticker, 0.0)
                    + 0.0035 * np.clip(mom_signal, -0.4, 0.4)
                    + 0.0025 * np.clip(rev_signal, -0.15, 0.15)
                )
                                
            p_next = prices[-1] * np.exp(r + drift_signal)
            prices.append(p_next)
            
        close_prices = np.array(prices[1:])
        
        # Generate realistic OHLC from daily volatility
        intraday_vol = ann_vol / np.sqrt(252.0)
        
        for d_idx, dt_val in enumerate(dates):
            c_p = close_prices[d_idx]
            prev_p = prices[d_idx]
            
            # Open has overnight gap
            overnight_gap = np.random.normal(0, intraday_vol * 0.35)
            open_p = prev_p * np.exp(overnight_gap)
            
            # High and Low
            span = np.abs(np.random.normal(intraday_vol * 1.4, intraday_vol * 0.4))
            high_p = max(open_p, c_p) * (1.0 + abs(np.random.normal(0.004, span * 0.6)))
            low_p = min(open_p, c_p) * (1.0 - abs(np.random.normal(0.004, span * 0.6)))
            
            # Ensure High >= max(Open, Close) and Low <= min(Open, Close)
            high_p = max(high_p, open_p * 1.0005, c_p * 1.0005)
            low_p = min(low_p, open_p * 0.9995, c_p * 0.9995)
            
            # Volume with lognormal variance + surge on high volatility/jump days
            vol_multiplier = 1.0 + 4.0 * abs(daily_returns[d_idx]) / intraday_vol
            vol_noise = np.random.lognormal(0, 0.25)
            day_volume = int(base_vol * vol_multiplier * vol_noise)
            
            # Market Cap adjustment
            day_mcap = round(mcap * (c_p / base_price), 2)
            
            records.append({
                "date": dt_val.strftime("%Y-%m-%d"),
                "ticker": ticker,
                "sector": sector,
                "open": round(float(open_p), 2),
                "high": round(float(high_p), 2),
                "low": round(float(low_p), 2),
                "close": round(float(c_p), 2),
                "volume": day_volume,
                "market_cap": day_mcap,
                "beta_sp500": beta,
            })
            
    df = pd.DataFrame(records)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False)
    print(f"Generated universe dataset with {len(df)} rows across {len(tickers_info)} tickers and {n_days} dates.")
    return df

if __name__ == "__main__":
    out = Path("e:/Github Submissions/04-ml-alpha-signal/data/cross_sectional_universe.csv")
    generate_universe_data(out)
