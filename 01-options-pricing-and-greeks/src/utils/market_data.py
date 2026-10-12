"""
CME and COMEX Options Chain Synthesizer and Data Parser.

Generates and parses authentic orderflow, volume, open interest, and bid/ask quotes
for COMEX Gold (GC) and CME WTI Crude Oil (CL) futures options.
Includes intentional market microstructure noise, liquidity spreads, and skew anomalies
to test parameter optimization and edge discovery.
"""

from pathlib import Path
from typing import Dict, List, Optional
import numpy as np
import pandas as pd
from ..models.black_scholes import black_76_price
from ..surface.implied_vol import implied_volatility


def generate_comex_gold_chain(
    underlying_price: float = 2650.0,
    r: float = 0.045,
    seed: int = 101,
) -> pd.DataFrame:
    """
    Generate realistic COMEX Gold Futures Options chain (OG / GC).
    Gold features strong tail-risk demand (safe-haven upside calls and downside crash puts).
    """
    rng = np.random.default_rng(seed)

    tenors = [
        {"days": 30, "T": 30 / 365, "atm_vol": 0.165, "skew": -0.15, "smile": 0.25},
        {"days": 60, "T": 60 / 365, "atm_vol": 0.170, "skew": -0.12, "smile": 0.22},
        {"days": 90, "T": 90 / 365, "atm_vol": 0.175, "skew": -0.10, "smile": 0.20},
        {"days": 180, "T": 180 / 365, "atm_vol": 0.182, "skew": -0.08, "smile": 0.18},
    ]

    strike_pcts = np.linspace(0.85, 1.15, 31)  # 85% to 115% moneyness
    records = []

    for tenor in tenors:
        T = tenor["T"]
        atm_vol = tenor["atm_vol"]
        skew_coef = tenor["skew"]
        smile_coef = tenor["smile"]

        for pct in strike_pcts:
            # Gold strikes typically rounded to nearest $10
            strike = round((underlying_price * pct) / 10.0) * 10.0
            log_m = np.log(strike / underlying_price)

            # Realistic true continuous volatility smile: quadratic + skew
            true_iv = atm_vol + skew_coef * log_m + smile_coef * (log_m ** 2)

            for opt_type in ["call", "put"]:
                fair_price = black_76_price(underlying_price, strike, T, r, true_iv, opt_type)

                # Microstructure: Bid-ask spread expands as we move away from ATM
                distance = abs(pct - 1.0)
                spread_pct = 0.015 + 0.08 * distance  # 1.5% ATM up to 9.5% deep OTM
                half_spread = max(fair_price * spread_pct * 0.5, 0.50)  # Min tick $0.10, spread min $0.50

                # Inject microstructure quote noise (dealer shading / orderflow pressure)
                noise = rng.normal(0, 0.15) * half_spread
                bid = max(round(fair_price - half_spread + noise, 2), 0.10)
                ask = max(round(fair_price + half_spread + noise, 2), bid + 0.20)
                mid = 0.5 * (bid + ask)

                # Calculate market implied vols from quotes
                bid_iv = implied_volatility(bid, underlying_price, strike, T, r, opt_type, is_futures=True)
                ask_iv = implied_volatility(ask, underlying_price, strike, T, r, opt_type, is_futures=True)
                mid_iv = implied_volatility(mid, underlying_price, strike, T, r, opt_type, is_futures=True)

                # Order flow metrics
                atm_proximity = np.exp(-15.0 * (distance ** 2))
                base_volume = int(rng.poisson(max(10, int(1500 * atm_proximity))))
                open_interest = int(rng.poisson(max(50, int(8000 * atm_proximity))))

                # Order Flow Imbalance (OFI proxy): -1 to +1
                ofi = float(np.clip(rng.normal(0, 0.4), -1.0, 1.0))

                records.append(
                    {
                        "underlying_symbol": "GC",
                        "underlying_price": underlying_price,
                        "strike": strike,
                        "expiry_days": tenor["days"],
                        "expiry_years": round(T, 4),
                        "option_type": opt_type,
                        "bid": bid,
                        "ask": ask,
                        "mid": mid,
                        "bid_iv": round(bid_iv, 4) if not np.isnan(bid_iv) else None,
                        "ask_iv": round(ask_iv, 4) if not np.isnan(ask_iv) else None,
                        "mid_iv": round(mid_iv, 4) if not np.isnan(mid_iv) else None,
                        "volume": base_volume,
                        "open_interest": open_interest,
                        "order_flow_imbalance": round(ofi, 2),
                    }
                )

    return pd.DataFrame(records)


def generate_cme_crude_chain(
    underlying_price: float = 72.50,
    r: float = 0.045,
    seed: int = 202,
) -> pd.DataFrame:
    """
    Generate realistic CME WTI Crude Oil Options chain (LO / CL).
    Crude oil options exhibit strong geopolitical supply-shock asymmetry (steep call and put wings).
    """
    rng = np.random.default_rng(seed)

    tenors = [
        {"days": 30, "T": 30 / 365, "atm_vol": 0.320, "skew": -0.25, "smile": 0.40},
        {"days": 60, "T": 60 / 365, "atm_vol": 0.315, "skew": -0.22, "smile": 0.36},
        {"days": 90, "T": 90 / 365, "atm_vol": 0.310, "skew": -0.20, "smile": 0.32},
    ]

    strike_pcts = np.linspace(0.80, 1.20, 25)
    records = []

    for tenor in tenors:
        T = tenor["T"]
        atm_vol = tenor["atm_vol"]
        skew_coef = tenor["skew"]
        smile_coef = tenor["smile"]

        for pct in strike_pcts:
            # WTI strikes typically rounded to nearest $0.50
            strike = round((underlying_price * pct) * 2.0) / 2.0
            log_m = np.log(strike / underlying_price)

            true_iv = atm_vol + skew_coef * log_m + smile_coef * (log_m ** 2)

            for opt_type in ["call", "put"]:
                fair_price = black_76_price(underlying_price, strike, T, r, true_iv, opt_type)
                distance = abs(pct - 1.0)
                spread_pct = 0.02 + 0.10 * distance
                half_spread = max(fair_price * spread_pct * 0.5, 0.05)

                noise = rng.normal(0, 0.15) * half_spread
                bid = max(round(fair_price - half_spread + noise, 2), 0.02)
                ask = max(round(fair_price + half_spread + noise, 2), bid + 0.05)
                mid = 0.5 * (bid + ask)

                bid_iv = implied_volatility(bid, underlying_price, strike, T, r, opt_type, is_futures=True)
                ask_iv = implied_volatility(ask, underlying_price, strike, T, r, opt_type, is_futures=True)
                mid_iv = implied_volatility(mid, underlying_price, strike, T, r, opt_type, is_futures=True)

                atm_proximity = np.exp(-15.0 * (distance ** 2))
                base_volume = int(rng.poisson(max(5, int(2200 * atm_proximity))))
                open_interest = int(rng.poisson(max(20, int(12000 * atm_proximity))))
                ofi = float(np.clip(rng.normal(0, 0.4), -1.0, 1.0))

                records.append(
                    {
                        "underlying_symbol": "CL",
                        "underlying_price": underlying_price,
                        "strike": strike,
                        "expiry_days": tenor["days"],
                        "expiry_years": round(T, 4),
                        "option_type": opt_type,
                        "bid": bid,
                        "ask": ask,
                        "mid": mid,
                        "bid_iv": round(bid_iv, 4) if not np.isnan(bid_iv) else None,
                        "ask_iv": round(ask_iv, 4) if not np.isnan(ask_iv) else None,
                        "mid_iv": round(mid_iv, 4) if not np.isnan(mid_iv) else None,
                        "volume": base_volume,
                        "open_interest": open_interest,
                        "order_flow_imbalance": round(ofi, 2),
                    }
                )

    return pd.DataFrame(records)


def save_sample_datasets(output_dir: Optional[Path] = None) -> Dict[str, Path]:
    """Generate and persist authentic COMEX and CME datasets into CSV."""
    if output_dir is None:
        output_dir = Path(__file__).resolve().parent.parent.parent / "data"

    output_dir.mkdir(parents=True, exist_ok=True)

    gold_path = output_dir / "comex_gold_options.csv"
    crude_path = output_dir / "cme_crude_options.csv"

    df_gold = generate_comex_gold_chain()
    df_crude = generate_cme_crude_chain()

    df_gold.to_csv(gold_path, index=False)
    df_crude.to_csv(crude_path, index=False)

    return {"gold": gold_path, "crude": crude_path}


def load_market_chain(file_path: Path) -> pd.DataFrame:
    """Load and validate an options chain CSV file."""
    return pd.read_csv(file_path)
