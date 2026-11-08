"""
Cross-sectional universe classifications and asset metadata for Asness et al. (2013).
"""

from typing import Dict, List


EQUITIES_UNIVERSE = [
    "AAPL", "MSFT", "INTC", "CSCO", "IBM", "ORCL",
    "JPM", "BAC", "C", "WFC", "GS", "MS",
    "JNJ", "PFE", "MRK", "PG", "KO", "PEP",
    "XOM", "CVX", "GE", "BA", "CAT", "MMM"
]

MACRO_UNIVERSE = [
    "TY", "FGBL", "EURUSD", "USDJPY", "GBPUSD", "CL", "GC", "HG"
]

ALL_UNIVERSE = EQUITIES_UNIVERSE + MACRO_UNIVERSE

ASSET_METADATA: Dict[str, Dict[str, str]] = {
    # Equities
    **{sym: {"type": "Equity", "market": "US"} for sym in EQUITIES_UNIVERSE},
    # Macro
    "TY": {"type": "FixedIncome", "market": "US"},
    "FGBL": {"type": "FixedIncome", "market": "Europe"},
    "EURUSD": {"type": "FX", "market": "Global"},
    "USDJPY": {"type": "FX", "market": "Global"},
    "GBPUSD": {"type": "FX", "market": "Global"},
    "CL": {"type": "Commodity", "market": "Global"},
    "GC": {"type": "Commodity", "market": "Global"},
    "HG": {"type": "Commodity", "market": "Global"},
}
