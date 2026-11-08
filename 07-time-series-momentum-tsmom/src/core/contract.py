"""
Contract specifications for multi-asset futures instruments.
Defines asset classes, multiplier, tick size, and margin requirements.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict


class AssetClass(str, Enum):
    EQUITIES = "Equities"
    FIXED_INCOME = "FixedIncome"
    FX = "FX"
    COMMODITIES = "Commodities"


@dataclass(frozen=True)
class FuturesContract:
    symbol: str
    name: str
    asset_class: AssetClass
    multiplier: float
    tick_size: float
    margin_pct: float  # e.g., 0.05 for 5% initial margin


# Canonical catalog of contracts studied in Moskowitz et al. (2012)
CONTRACT_SPECS: Dict[str, FuturesContract] = {
    # Equities
    "ES": FuturesContract("ES", "E-mini S&P 500", AssetClass.EQUITIES, 50.0, 0.25, 0.06),
    "NQ": FuturesContract("NQ", "E-mini Nasdaq 100", AssetClass.EQUITIES, 20.0, 0.25, 0.08),
    "FDAX": FuturesContract("FDAX", "DAX Futures", AssetClass.EQUITIES, 25.0, 0.50, 0.07),
    "NK": FuturesContract("NK", "Nikkei 225 Futures", AssetClass.EQUITIES, 500.0, 5.0, 0.07),
    
    # Fixed Income / Rates
    "TY": FuturesContract("TY", "10-Year US Treasury Note", AssetClass.FIXED_INCOME, 1000.0, 0.015625, 0.02),
    "US": FuturesContract("US", "30-Year US Treasury Bond", AssetClass.FIXED_INCOME, 1000.0, 0.03125, 0.03),
    "FGBL": FuturesContract("FGBL", "Euro-Bund Futures", AssetClass.FIXED_INCOME, 1000.0, 0.01, 0.02),
    "G": FuturesContract("G", "Long Gilt Futures", AssetClass.FIXED_INCOME, 1000.0, 0.01, 0.025),
    
    # FX
    "EURUSD": FuturesContract("EURUSD", "Euro / US Dollar", AssetClass.FX, 125000.0, 0.00005, 0.025),
    "USDJPY": FuturesContract("USDJPY", "US Dollar / Japanese Yen", AssetClass.FX, 100000.0, 0.005, 0.025),
    "GBPUSD": FuturesContract("GBPUSD", "British Pound / US Dollar", AssetClass.FX, 62500.0, 0.0001, 0.025),
    "AUDUSD": FuturesContract("AUDUSD", "Australian Dollar / US Dollar", AssetClass.FX, 100000.0, 0.0001, 0.025),
    
    # Commodities
    "CL": FuturesContract("CL", "WTI Light Sweet Crude Oil", AssetClass.COMMODITIES, 1000.0, 0.01, 0.07),
    "GC": FuturesContract("GC", "COMEX Gold Futures", AssetClass.COMMODITIES, 100.0, 0.10, 0.05),
    "HG": FuturesContract("HG", "Copper Futures", AssetClass.COMMODITIES, 25000.0, 0.0005, 0.06),
    "ZC": FuturesContract("ZC", "CBOT Corn Futures", AssetClass.COMMODITIES, 5000.0, 0.25, 0.05),
}
