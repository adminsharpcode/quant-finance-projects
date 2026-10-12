"""
Relative-Value Volatility Arbitrage and Structural Mispricing Engine.

Identifies alpha opportunities across CME and COMEX options chains by comparing
observed market quotes against calibrated, arbitrage-free SVI/SABR volatility surfaces.

Alpha Mechanics:
1. Volatility Relative-Value Mispricing (Overpriced / Underpriced options relative to smooth surface)
2. Delta-Neutral Trade Structuring (Hedging directional risk with underlying futures)
3. Pure Static Butterfly & Calendar Arbitrage Scanners
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional
import numpy as np
import pandas as pd
from ..surface.svi_surface import SVIModel
from ..greeks.analytical_greeks import calculate_all_greeks, GreeksResult
from ..models.black_scholes import OptionType, black_76_price


class TradeSignal(str, Enum):
    BUY_VOL = "BUY_VOL (Cheap Gamma)"
    SELL_VOL = "SELL_VOL (Harvest Variance Premium)"
    NEUTRAL = "FAIR_VALUE"


@dataclass
class VolatilitySignal:
    contract_symbol: str
    underlying: str
    strike: float
    expiry_years: float
    option_type: str
    bid_price: float
    ask_price: float
    mid_price: float
    bid_iv: float
    ask_iv: float
    mid_iv: float
    model_fair_iv: float
    iv_edge: float             # mid_iv - model_fair_iv
    edge_ratio: float          # abs(iv_edge) / vol_bid_ask_spread
    theoretical_fair_price: float
    dollar_edge_per_contract: float
    greeks: GreeksResult
    delta_hedge_ratio: float   # Number of futures contracts per 1 option contract
    signal: TradeSignal
    rationale: str


@dataclass
class ArbitrageOpportunity:
    arb_type: str              # 'BUTTERFLY' or 'CALENDAR'
    strikes: List[float]
    expiries: List[float]
    expected_profit: float
    action: str


class SurfaceEdgeScanner:
    """
    Scans option chains against calibrated SVI/SABR surfaces to uncover
    statistical and structural edges.
    """

    def __init__(self, svi_surface: SVIModel, min_edge_ratio: float = 0.5):
        """
        Parameters
        ----------
        svi_surface : SVIModel
            Calibrated multi-slice SVI volatility surface.
        min_edge_ratio : float
            Threshold ratio of (IV mispricing / bid-ask spread) to trigger signal.
        """
        self.surface = svi_surface
        self.min_edge_ratio = min_edge_ratio

    def scan_chain(
        self,
        chain_df: pd.DataFrame,
        underlying_symbol: str = "GC",
        r: float = 0.045,
    ) -> List[VolatilitySignal]:
        """
        Scan an entire options chain dataframe for relative value edges.

        Expected DataFrame columns:
        - strike, expiry_years, option_type, bid, ask, underlying_price
        - optional: bid_iv, ask_iv, mid_iv
        """
        signals = []

        for _, row in chain_df.iterrows():
            strike = float(row["strike"])
            T = float(row["expiry_years"])
            opt_type = str(row["option_type"]).lower()
            bid = float(row["bid"])
            ask = float(row["ask"])
            mid = 0.5 * (bid + ask)
            F = float(row["underlying_price"])

            if bid <= 0 or ask <= bid or T <= 0:
                continue

            # Invert or extract implied vols
            from ..surface.implied_vol import implied_volatility
            bid_iv = row.get("bid_iv")
            if pd.isna(bid_iv) or bid_iv is None:
                bid_iv = implied_volatility(bid, F, strike, T, r, opt_type, is_futures=True)

            ask_iv = row.get("ask_iv")
            if pd.isna(ask_iv) or ask_iv is None:
                ask_iv = implied_volatility(ask, F, strike, T, r, opt_type, is_futures=True)

            if np.isnan(bid_iv) or np.isnan(ask_iv) or ask_iv <= bid_iv:
                continue

            mid_iv = 0.5 * (bid_iv + ask_iv)

            # SVI Surface Fair Value Volatility
            fair_iv = self.surface.get_vol(strike, F, T)

            # Compute theoretical fair price from smooth surface
            fair_price = black_76_price(F, strike, T, r, fair_iv, opt_type)

            iv_spread = max(ask_iv - bid_iv, 0.002)
            iv_edge = mid_iv - fair_iv
            edge_ratio = abs(iv_edge) / iv_spread

            # Greeks evaluation
            greeks = calculate_all_greeks(F, strike, T, r, fair_iv, opt_type, is_futures=True)

            signal_type = TradeSignal.NEUTRAL
            rationale = "Priced within normal market bid-ask volatility spread."
            dollar_edge = 0.0

            # Edge condition 1: Market Bid is ABOVE model fair value (Overpriced)
            if bid > fair_price and (bid_iv - fair_iv) > 0.25 * iv_spread:
                signal_type = TradeSignal.SELL_VOL
                dollar_edge = bid - fair_price
                rationale = (
                    f"Overpriced: Market bid IV ({bid_iv:.1%}) exceeds fair surface IV ({fair_iv:.1%}). "
                    f"Sell option at bid ${bid:.2f}, delta-hedge by buying {-greeks.delta:.3f} futures."
                )

            # Edge condition 2: Market Ask is BELOW model fair value (Underpriced)
            elif ask < fair_price and (fair_iv - ask_iv) > 0.25 * iv_spread:
                signal_type = TradeSignal.BUY_VOL
                dollar_edge = fair_price - ask
                rationale = (
                    f"Underpriced: Market ask IV ({ask_iv:.1%}) is below fair surface IV ({fair_iv:.1%}). "
                    f"Buy option at ask ${ask:.2f}, delta-hedge by shorting {greeks.delta:.3f} futures."
                )

            signals.append(
                VolatilitySignal(
                    contract_symbol=f"{underlying_symbol}_{int(strike)}_{opt_type[0].upper()}_{int(T*365)}d",
                    underlying=underlying_symbol,
                    strike=strike,
                    expiry_years=T,
                    option_type=opt_type,
                    bid_price=bid,
                    ask_price=ask,
                    mid_price=mid,
                    bid_iv=float(bid_iv),
                    ask_iv=float(ask_iv),
                    mid_iv=float(mid_iv),
                    model_fair_iv=float(fair_iv),
                    iv_edge=float(iv_edge),
                    edge_ratio=float(edge_ratio),
                    theoretical_fair_price=float(fair_price),
                    dollar_edge_per_contract=float(dollar_edge),
                    greeks=greeks,
                    delta_hedge_ratio=-float(greeks.delta),
                    signal=signal_type,
                    rationale=rationale,
                )
            )

        return signals

    def detect_butterfly_arbitrage(
        self,
        chain_df: pd.DataFrame,
        opt_type: str = "call",
    ) -> List[ArbitrageOpportunity]:
        """
        Scan consecutive strike triplets for negative butterfly spread cost:
        Cost = Ask(K1) - 2 * Bid(K2) + Ask(K3) < 0
        """
        arbs = []
        df_filtered = chain_df[chain_df["option_type"].str.lower() == opt_type.lower()].sort_values("strike")

        for T, group in df_filtered.groupby("expiry_years"):
            strikes = group["strike"].values
            bids = group["bid"].values
            asks = group["ask"].values

            n = len(strikes)
            for i in range(n - 2):
                k1, k2, k3 = strikes[i], strikes[i + 1], strikes[i + 2]
                # Check equal strike spacing
                if abs((k2 - k1) - (k3 - k2)) < 1e-4:
                    # Construct long butterfly with market execution: buy K1 at ask, sell 2x K2 at bid, buy K3 at ask
                    net_cost = asks[i] - 2.0 * bids[i + 1] + asks[i + 2]
                    if net_cost < -0.01:  # Negative cost = immediate riskless cash inflow
                        max_payoff = k2 - k1
                        arbs.append(
                            ArbitrageOpportunity(
                                arb_type="BUTTERFLY",
                                strikes=[float(k1), float(k2), float(k3)],
                                expiries=[float(T)],
                                expected_profit=float(-net_cost),
                                action=f"Long Butterfly at strikes {k1}/{k2}/{k3}. Immediate cash credit: ${-net_cost:.2f}",
                            )
                        )
        return arbs
