"""
MQ4 Codebase Extractor and Alpha Miner
---------------------------------------
Parses, analyzes, and extracts algorithmic trading logic, indicators,
parameter distributions, and risk patterns from 1,300+ MQL4 source files.
"""

import os
import re
import json
from collections import Counter, defaultdict
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Any, Optional


@dataclass
class MQ4FileInfo:
    filename: str
    filepath: str
    file_size_bytes: int
    lines_of_code: int
    file_type: str  # 'Expert Advisor', 'Custom Indicator', 'Script', 'Library/Include'
    builtin_indicators: List[str] = field(default_factory=list)
    custom_indicators: List[str] = field(default_factory=list)
    extern_inputs: Dict[str, str] = field(default_factory=dict)
    has_ordersend: bool = False
    has_stoploss: bool = False
    has_takeprofit: bool = False
    has_trailing_stop: bool = False
    is_martingale_or_grid: bool = False
    trading_archetypes: List[str] = field(default_factory=list)
    risk_mechanisms: List[str] = field(default_factory=list)


class MQ4Extractor:
    BUILTIN_INDICATORS = [
        'iMA', 'iRSI', 'iMACD', 'iATR', 'iBands', 'iStochastic', 'iCCI',
        'iADX', 'iAlligator', 'iSAR', 'iEnvelopes', 'iIchimoku', 'iMomentum',
        'iWPR', 'iRVI', 'iDeMarker', 'iStdDev', 'iOBV', 'iVolume', 'iMFI',
        'iFractals', 'iBearsPower', 'iBullsPower'
    ]

    def __init__(self, directory_path: str):
        self.directory_path = directory_path
        self.results: List[MQ4FileInfo] = []
        self.summary_stats: Dict[str, Any] = {}

    def parse_file(self, filename: str) -> Optional[MQ4FileInfo]:
        filepath = os.path.join(self.directory_path, filename)
        try:
            with open(filepath, 'r', encoding='latin1', errors='replace') as f:
                content = f.read()
        except Exception as e:
            return None

        lines = content.splitlines()
        loc = len([line for line in lines if line.strip() and not line.strip().startswith('//')])

        # Determine file type
        is_indicator = '#property indicator' in content or 'SetIndexBuffer' in content or 'SetIndexStyle' in content
        has_ordersend = 'OrderSend' in content
        is_script = '#property show_inputs' in content and not has_ordersend and not is_indicator
        
        if has_ordersend:
            file_type = 'Expert Advisor'
        elif is_indicator:
            file_type = 'Custom Indicator'
        elif is_script:
            file_type = 'Script'
        else:
            file_type = 'Utility / Indicator Helper'

        # Extract Built-in Indicators
        found_builtins = []
        for ind in self.BUILTIN_INDICATORS:
            if re.search(r'\b' + re.escape(ind) + r'\b', content):
                found_builtins.append(ind)

        # Extract Custom Indicators (iCustom calls)
        custom_indicators = []
        icustom_matches = re.findall(r'iCustom\s*\([^,]+,[^,]+,\s*["\']([^"\']+)["\']', content)
        for c in icustom_matches:
            if c not in custom_indicators:
                custom_indicators.append(c)

        # Extract Extern / Input variables
        inputs = {}
        input_matches = re.findall(r'(?:extern|input)\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)\s*=\s*([^;]+);', content)
        for var_type, var_name, default_val in input_matches[:30]:  # limit top 30
            inputs[var_name] = f"{var_type} = {default_val.strip()}"

        # Risk Management Detection
        has_sl = bool(re.search(r'(?:StopLoss|OrderStopLoss|Stop_Loss|SL)\b', content, re.IGNORECASE))
        has_tp = bool(re.search(r'(?:TakeProfit|OrderTakeProfit|Take_Profit|TP)\b', content, re.IGNORECASE))
        has_trailing = bool(re.search(r'(?:TrailingStop|Trailing_Stop|Trailing|Trail)\b', content, re.IGNORECASE))

        # Martingale / Grid Risk Detection
        is_martingale = bool(re.search(r'(?:Martingale|Multiplier|LotMultiplier|PipStep|GridStep|Multiply|double_lot|RecoveryFactor)', content, re.IGNORECASE))
        if re.search(r'Lots\s*\*\s*LotMultiplier|Lots\s*\*\s*2|OrderLots\(\)\s*\*\s*[123]', content):
            is_martingale = True

        # Archetype Identification
        archetypes = []
        if 'iMA' in found_builtins or 'Moving' in content or 'EMA' in content or 'SMA' in content:
            archetypes.append('Moving Average / Trend Following')
        if 'iRSI' in found_builtins or 'iStochastic' in found_builtins or 'iCCI' in found_builtins:
            archetypes.append('Oscillator / Mean Reversion')
        if 'iBands' in found_builtins or 'iEnvelopes' in found_builtins:
            archetypes.append('Volatility Bands Breakout/Mean Reversion')
        if 'iATR' in found_builtins or 'ATR' in content:
            archetypes.append('ATR Dynamic Volatility')
        if 'iMACD' in found_builtins:
            archetypes.append('MACD Momentum')
        if is_martingale:
            archetypes.append('Martingale / Grid Cost-Averaging')
        if re.search(r'(?:Breakout|High\[|Low\[|Highest|Lowest|Donchian)', content):
            archetypes.append('Channel / High-Low Breakout')
        if re.search(r'(?:Pivot|Fibonacci|Support|Resistance)', content, re.IGNORECASE):
            archetypes.append('Pivot / Structural Support-Resistance')

        risk_mechanisms = []
        if has_sl:
            risk_mechanisms.append('Hard Stop Loss')
        if has_tp:
            risk_mechanisms.append('Fixed Take Profit')
        if has_trailing:
            risk_mechanisms.append('Trailing Stop')
        if is_martingale:
            risk_mechanisms.append('Martingale / Multiplier Scaling (High Blowup Risk)')
        if 'AccountEquity' in content or 'AccountBalance' in content:
            risk_mechanisms.append('Dynamic Capital/Equity Sizing')
        if 'TimeHour' in content or 'Hour()' in content:
            risk_mechanisms.append('Time-of-Day / Session Filter')

        return MQ4FileInfo(
            filename=filename,
            filepath=filepath,
            file_size_bytes=os.path.getsize(filepath),
            lines_of_code=loc,
            file_type=file_type,
            builtin_indicators=found_builtins,
            custom_indicators=custom_indicators,
            extern_inputs=inputs,
            has_ordersend=has_ordersend,
            has_stoploss=has_sl,
            has_takeprofit=has_tp,
            has_trailing_stop=has_trailing,
            is_martingale_or_grid=is_martingale,
            trading_archetypes=archetypes,
            risk_mechanisms=risk_mechanisms
        )

    def run_extraction(self) -> Dict[str, Any]:
        files = [f for f in os.listdir(self.directory_path) if f.lower().endswith('.mq4')]
        print(f"Discovered {len(files)} MQ4 files. Beginning extraction...")

        for idx, f in enumerate(files):
            info = self.parse_file(f)
            if info:
                self.results.append(info)
            if (idx + 1) % 250 == 0 or idx == len(files) - 1:
                print(f"Processed {idx + 1}/{len(files)} files...")

        # Aggregate Statistics
        total_files = len(self.results)
        file_type_counts = Counter(r.file_type for r in self.results)
        
        indicator_counts = Counter()
        for r in self.results:
            for ind in r.builtin_indicators:
                indicator_counts[ind] += 1

        archetype_counts = Counter()
        for r in self.results:
            for arch in r.trading_archetypes:
                archetype_counts[arch] += 1

        risk_counts = Counter()
        for r in self.results:
            for rm in r.risk_mechanisms:
                risk_counts[rm] += 1

        ea_files = [r for r in self.results if r.file_type == 'Expert Advisor']
        ea_total = len(ea_files)
        ea_with_sl = sum(1 for r in ea_files if r.has_stoploss)
        ea_with_tp = sum(1 for r in ea_files if r.has_takeprofit)
        ea_with_trailing = sum(1 for r in ea_files if r.has_trailing_stop)
        ea_martingale = sum(1 for r in ea_files if r.is_martingale_or_grid)

        self.summary_stats = {
            "total_files_analyzed": total_files,
            "file_type_breakdown": dict(file_type_counts),
            "top_builtin_indicators": dict(indicator_counts.most_common(20)),
            "trading_archetypes": dict(archetype_counts.most_common(20)),
            "risk_mechanisms": dict(risk_counts.most_common(20)),
            "ea_statistics": {
                "total_expert_advisors": ea_total,
                "with_stop_loss": ea_with_sl,
                "pct_with_stop_loss": round((ea_with_sl / max(1, ea_total)) * 100, 2),
                "with_take_profit": ea_with_tp,
                "pct_with_take_profit": round((ea_with_tp / max(1, ea_total)) * 100, 2),
                "with_trailing_stop": ea_with_trailing,
                "pct_with_trailing_stop": round((ea_with_trailing / max(1, ea_total)) * 100, 2),
                "martingale_or_grid_count": ea_martingale,
                "pct_martingale_or_grid": round((ea_martingale / max(1, ea_total)) * 100, 2)
            }
        }
        return self.summary_stats

    def save_results(self, output_json_path: str):
        payload = {
            "summary": self.summary_stats,
            "catalog": [asdict(r) for r in self.results]
        }
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(payload, f, indent=2)
        print(f"Results successfully saved to {output_json_path}")


if __name__ == "__main__":
    mq4_dir = r"e:\Github Submissions\MQ4 Source Codes (1300+)"
    output_path = r"e:\Github Submissions\06-mq4-tick-alpha-engine\data\mq4_strategy_catalog.json"
    extractor = MQ4Extractor(mq4_dir)
    stats = extractor.run_extraction()
    extractor.save_results(output_path)
    print("\n--- EXTRACTION COMPLETE ---")
    print(json.dumps(stats, indent=2))
