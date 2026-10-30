"""
Real Tick Data Loader and Preprocessor
--------------------------------------
Extracts and normalizes millisecond-resolution real broker tick feeds
from proprietary MetaTrader 5 ticks.dat binary storage into high-performance
pandas DataFrames and CSV data stores.
"""

import os
import glob
import struct
import pandas as pd
import numpy as np
from typing import List, Dict, Optional, Tuple


class TickDataLoader:
    MT5_TICK_STRUCT = '<qdddQqId'  # 60 bytes: time, bid, ask, last, vol, t_msc, flags, vol_real

    def __init__(self, base_search_path: Optional[str] = None):
        self.base_search_path = base_search_path or r"C:\Users\ROG\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\bases"

    def parse_mt5_ticks_file(self, filepath: str) -> List[Dict]:
        """Parses a single MT5 ticks.dat binary file."""
        if not os.path.exists(filepath):
            return []

        with open(filepath, 'rb') as f:
            data = f.read()

        if len(data) < 512:
            return []

        # Find initial timestamp offset in range 128..1024
        start_offset = None
        for i in range(128, min(1024, len(data) - 60)):
            t = struct.unpack('<q', data[i:i + 8])[0]
            if 1500000000 < t < 1900000000:
                bid, ask = struct.unpack('<dd', data[i + 8:i + 24])
                if 0 < bid < 10000 and 0 < ask < 10000 and ask >= bid:
                    start_offset = i
                    break

        if start_offset is None:
            return []

        records = []
        pos = start_offset
        while pos + 60 <= len(data):
            chunk = data[pos:pos + 60]
            t, bid, ask, last, vol, t_msc, flags, vol_real = struct.unpack(self.MT5_TICK_STRUCT, chunk)
            if bid > 0 and ask > 0 and 1500000000 < t < 1900000000:
                spread = round(ask - bid, 6)
                records.append({
                    'timestamp_msc': t_msc,
                    'bid': bid,
                    'ask': ask,
                    'mid': round((bid + ask) / 2.0, 6),
                    'spread': spread,
                    'flags': flags
                })
            pos += 60

        return records

    def load_symbol_ticks(self, symbol: str) -> pd.DataFrame:
        """Finds all tick files matching symbol across installed broker profiles and aggregates them."""
        search_pattern = os.path.join(self.base_search_path, f"*\\ticks\\{symbol}*\\ticks.dat")
        matches = glob.glob(search_pattern)

        all_records = []
        for match in matches:
            recs = self.parse_mt5_ticks_file(match)
            all_records.extend(recs)

        if not all_records:
            raise FileNotFoundError(f"No valid tick data discovered for symbol '{symbol}'.")

        df = pd.DataFrame(all_records)
        df = df.drop_duplicates(subset=['timestamp_msc', 'bid', 'ask'])
        df = df.sort_values('timestamp_msc').reset_index(drop=True)
        df['datetime'] = pd.to_datetime(df['timestamp_msc'], unit='ms')
        return df

    def export_ticks_to_csv(self, symbol: str, output_csv_path: str) -> pd.DataFrame:
        """Extracts and saves symbol ticks to CSV for rapid access."""
        df = self.load_symbol_ticks(symbol)
        os.makedirs(os.path.dirname(output_csv_path), exist_ok=True)
        df.to_csv(output_csv_path, index=False)
        print(f"Exported {len(df)} real ticks for {symbol} to {output_csv_path}")
        return df


def prepare_benchmark_datasets(output_dir: str):
    """Prepares and exports datasets for EURUSD, GBPUSD, and XAUUSD."""
    loader = TickDataLoader()
    symbols = ['EURUSD', 'GBPUSD', 'XAUUSD']
    exported = {}
    for sym in symbols:
        out_path = os.path.join(output_dir, f"real_ticks_{sym.lower()}.csv")
        df = loader.export_ticks_to_csv(sym, out_path)
        exported[sym] = df
    return exported


if __name__ == "__main__":
    out_dir = r"e:\Github Submissions\06-mq4-tick-alpha-engine\data"
    prepare_benchmark_datasets(out_dir)
