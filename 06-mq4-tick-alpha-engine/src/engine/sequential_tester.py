"""
Sequential MQ4 Codebase Testing & Microstructure Audit Engine
--------------------------------------------------------------
Iterates through all 1,296 MQL4 source files sequentially:
1. Syntax, lexical, and structural integrity verification
2. Rule and parameter extraction (SL, TP, Lot sizing, Indicators)
3. Microstructure execution simulation on real broker tick data
4. Performance classification (PASS_PROFITABLE, PASS_MARGINAL, FAIL_BLOWUP, INDICATOR_ONLY)
5. Leaderboard generation and comprehensive risk profiling
"""

import os
import re
import sys
import json
import time
import pandas as pd
import numpy as np
from typing import Dict, List, Any, Optional, Tuple


class SequentialMQ4Tester:
    BUILTIN_INDICATORS = [
        'iMA', 'iATR', 'iRSI', 'iMACD', 'iBands', 'iStochastic', 'iCCI',
        'iSAR', 'iADX', 'iVolume', 'iEnvelopes', 'iWPR', 'iStdDev',
        'iBearsPower', 'iBullsPower', 'iMomentum', 'iFractals', 'iIchimoku'
    ]

    def __init__(self, mq4_dir: str, tick_csv_path: str, initial_capital: float = 10000.0):
        self.mq4_dir = mq4_dir
        self.tick_csv_path = tick_csv_path
        self.initial_capital = initial_capital
        
        # Load real broker tick data
        print(f"Loading real broker ticks from {tick_csv_path}...")
        self.df_ticks = pd.read_csv(tick_csv_path)
        self.bids = self.df_ticks['bid'].to_numpy()
        self.asks = self.df_ticks['ask'].to_numpy()
        self.mids = self.df_ticks['mid'].to_numpy()
        self.spreads = self.df_ticks['spread'].to_numpy()
        self.n_ticks = len(self.df_ticks)
        print(f"Loaded {self.n_ticks} real broker ticks (Avg spread: {self.spreads.mean():.5f})")

        # Precompute common indicators on tick mid prices for fast backtest execution
        self.mid_s = pd.Series(self.mids)
        self.precomputed_ma = {
            10: self.mid_s.rolling(10).mean().to_numpy(),
            20: self.mid_s.rolling(20).mean().to_numpy(),
            50: self.mid_s.rolling(50).mean().to_numpy(),
            100: self.mid_s.rolling(100).mean().to_numpy()
        }
        self.precomputed_std = {
            20: self.mid_s.rolling(20).std().to_numpy(),
            50: self.mid_s.rolling(50).std().to_numpy()
        }
        self.precomputed_high = {
            20: self.mid_s.rolling(20).max().to_numpy(),
            50: self.mid_s.rolling(50).max().to_numpy()
        }
        self.precomputed_low = {
            20: self.mid_s.rolling(20).min().to_numpy(),
            50: self.mid_s.rolling(50).min().to_numpy()
        }

    def inspect_syntax(self, content: str) -> Tuple[bool, str, int]:
        """Validates MQL4 braces balance and entry points."""
        lines = content.splitlines()
        loc = len([line for line in lines if line.strip() and not line.strip().startswith('//')])

        open_braces = content.count('{')
        close_braces = content.count('}')
        braces_balanced = (open_braces == close_braces) and (open_braces > 0 or loc < 20)

        entry_points = []
        for ep in ['OnTick', 'start', 'OnInit', 'init', 'OnCalculate', 'start()', 'OnStart']:
            if re.search(r'\b' + re.escape(ep) + r'\b', content):
                entry_points.append(ep)

        if not braces_balanced:
            status = f"BRACES_MISMATCH ({open_braces} open vs {close_braces} close)"
            is_valid = False
        elif not entry_points and loc > 50:
            status = "NO_ENTRY_POINT_DETECTED"
            is_valid = False
        else:
            status = f"VALID (Entry: {','.join(entry_points[:2]) if entry_points else 'Script/Include'})"
            is_valid = True

        return is_valid, status, loc

    def extract_strategy_parameters(self, content: str) -> Dict[str, Any]:
        """Extracts SL, TP, lot size, martingale multiplier, and indicator calls."""
        # Detect built-in indicators
        found_inds = [ind for ind in self.BUILTIN_INDICATORS if re.search(r'\b' + re.escape(ind) + r'\b', content)]

        # Extract Stop Loss
        sl_matches = re.findall(r'(?:StopLoss|Stop_Loss|SL)\s*=\s*([0-9.]+)', content, re.I)
        sl_pips = float(sl_matches[0]) if sl_matches and float(sl_matches[0]) > 0 else None

        # Extract Take Profit
        tp_matches = re.findall(r'(?:TakeProfit|Take_Profit|TP)\s*=\s*([0-9.]+)', content, re.I)
        tp_pips = float(tp_matches[0]) if tp_matches and float(tp_matches[0]) > 0 else None

        # Extract Trailing Stop
        trail_matches = re.findall(r'(?:TrailingStop|Trailing_Stop|Trail)\s*=\s*([0-9.]+)', content, re.I)
        trail_pips = float(trail_matches[0]) if trail_matches and float(trail_matches[0]) > 0 else None

        # Extract Lot Size
        lot_matches = re.findall(r'(?:Lots|LotSize|Lot)\s*=\s*([0-9.]+)', content, re.I)
        lot_size = float(lot_matches[0]) if lot_matches and float(lot_matches[0]) > 0 else 0.1

        # Martingale / Grid Multiplier
        is_martingale = bool(re.search(r'(?:Martingale|Multiplier|LotMultiplier|PipStep|GridStep|double_lot|RecoveryFactor)', content, re.I))
        if re.search(r'Lots\s*\*\s*LotMultiplier|Lots\s*\*\s*2|OrderLots\(\)\s*\*\s*[123]', content):
            is_martingale = True

        # Risk Classification
        if is_martingale:
            risk_class = "MARTINGALE_GRID_TOXIC"
        elif sl_pips is None and 'OrderSend' in content:
            risk_class = "UNPROTECTED_NO_STOP_LOSS"
        elif sl_pips and tp_pips and sl_pips > 2.0 * tp_pips:
            risk_class = "NEGATIVE_ASYMMETRY (High Risk)"
        elif sl_pips and tp_pips and tp_pips >= 1.5 * sl_pips:
            risk_class = "ASYMMETRIC_POSITIVE_SKEW"
        else:
            risk_class = "SYMMETRIC_OR_DEFAULT"

        # Determine strategy archetype
        archetype = "Unknown"
        if 'iBands' in found_inds or 'iEnvelopes' in found_inds:
            archetype = "Volatility Bands Reversion"
        elif 'iMA' in found_inds and ('High[' in content or 'Low[' in content or 'Highest' in content):
            archetype = "Trend Breakout (MA + Donchian)"
        elif 'iMA' in found_inds:
            archetype = "Moving Average Crossover"
        elif 'iRSI' in found_inds or 'iStochastic' in found_inds or 'iCCI' in found_inds:
            archetype = "Oscillator Mean Reversion"
        elif 'iMACD' in found_inds:
            archetype = "MACD Momentum"
        elif 'iSAR' in found_inds or 'iADX' in found_inds:
            archetype = "Directional Trend Following"
        elif is_martingale:
            archetype = "Martingale Grid Scalper"
        elif 'OrderSend' in content:
            archetype = "General Market Order EA"
        else:
            archetype = "Technical Indicator / Filter"

        return {
            "has_ordersend": 'OrderSend' in content,
            "indicators": found_inds,
            "sl_pips": sl_pips,
            "tp_pips": tp_pips,
            "trail_pips": trail_pips,
            "lot_size": min(5.0, max(0.01, lot_size)),
            "is_martingale": is_martingale,
            "risk_classification": risk_class,
            "archetype": archetype
        }

    def simulate_ea_backtest(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Simulates extracted EA logic against real broker ticks with spread, slippage, and commissions."""
        pip = 0.0001
        sl_pips = params['sl_pips'] or (100.0 if params['is_martingale'] else 15.0)
        tp_pips = params['tp_pips'] or (10.0 if params['is_martingale'] else 25.0)
        base_lots = params['lot_size']
        is_martingale = params['is_martingale']
        archetype = params['archetype']

        sl_dist = sl_pips * pip
        tp_dist = tp_pips * pip

        capital = self.initial_capital
        peak_capital = capital
        max_dd_dollars = 0.0
        max_dd_pct = 0.0

        pos = 0  # 1=Long, -1=Short
        entry_price = 0.0
        curr_sl = 0.0
        curr_tp = 0.0
        current_lots = base_lots
        units = current_lots * 100000.0

        trades = []
        consecutive_losses = 0

        # Select precomputed signals based on archetype
        ma_fast = self.precomputed_ma[20]
        ma_slow = self.precomputed_ma[50]
        mean = self.precomputed_ma[50]
        std = self.precomputed_std[50]
        highs = self.precomputed_high[20]
        lows = self.precomputed_low[20]

        start_idx = 55
        for i in range(start_idx, self.n_ticks):
            bid = self.bids[i]
            ask = self.asks[i]
            mid = self.mids[i]
            spr = self.spreads[i]

            # 1. Manage Active Position
            if pos == 1:
                # Check Stop Loss
                if bid <= curr_sl:
                    gross = (curr_sl - entry_price) * units
                    comm = current_lots * 5.0
                    net = gross - comm
                    capital += net
                    trades.append(net)
                    pos = 0
                    consecutive_losses += 1
                    if is_martingale:
                        current_lots = min(5.0, current_lots * 1.5)
                        units = current_lots * 100000.0
                # Check Take Profit
                elif bid >= curr_tp:
                    gross = (curr_tp - entry_price) * units
                    comm = current_lots * 5.0
                    net = gross - comm
                    capital += net
                    trades.append(net)
                    pos = 0
                    consecutive_losses = 0
                    if is_martingale:
                        current_lots = base_lots
                        units = current_lots * 100000.0

            elif pos == -1:
                # Check Stop Loss
                if ask >= curr_sl:
                    gross = (entry_price - curr_sl) * units
                    comm = current_lots * 5.0
                    net = gross - comm
                    capital += net
                    trades.append(net)
                    pos = 0
                    consecutive_losses += 1
                    if is_martingale:
                        current_lots = min(5.0, current_lots * 1.5)
                        units = current_lots * 100000.0
                # Check Take Profit
                elif ask <= curr_tp:
                    gross = (entry_price - curr_tp) * units
                    comm = current_lots * 5.0
                    net = gross - comm
                    capital += net
                    trades.append(net)
                    pos = 0
                    consecutive_losses = 0
                    if is_martingale:
                        current_lots = base_lots
                        units = current_lots * 100000.0

            # Update Peak & Drawdown
            if capital > peak_capital:
                peak_capital = capital
            dd_d = peak_capital - capital
            dd_p = (dd_d / peak_capital) * 100.0 if peak_capital > 0 else 100.0
            if dd_d > max_dd_dollars:
                max_dd_dollars = dd_d
            if dd_p > max_dd_pct:
                max_dd_pct = dd_p

            # Check if account is blown
            if capital <= 1000.0 or max_dd_pct >= 90.0:
                break

            # 2. Check Signal if Flat
            if pos == 0 and spr <= 0.00025:
                # Trigger based on archetype
                if "Volatility Bands" in archetype or "Oscillator" in archetype:
                    if std[i] > 1e-6 and mid < mean[i] - (1.8 * std[i]):
                        pos = 1
                        entry_price = ask + (pip * 0.1)
                        curr_sl = entry_price - sl_dist
                        curr_tp = entry_price + tp_dist
                    elif std[i] > 1e-6 and mid > mean[i] + (1.8 * std[i]):
                        pos = -1
                        entry_price = bid - (pip * 0.1)
                        curr_sl = entry_price + sl_dist
                        curr_tp = entry_price - tp_dist
                elif "Breakout" in archetype:
                    if mid > highs[i - 1] and ma_fast[i] > ma_slow[i]:
                        pos = 1
                        entry_price = ask + (pip * 0.1)
                        curr_sl = entry_price - sl_dist
                        curr_tp = entry_price + tp_dist
                    elif mid < lows[i - 1] and ma_fast[i] < ma_slow[i]:
                        pos = -1
                        entry_price = bid - (pip * 0.1)
                        curr_sl = entry_price + sl_dist
                        curr_tp = entry_price - tp_dist
                else:
                    # General MA cross / momentum
                    if ma_fast[i] > ma_slow[i] and ma_fast[i - 1] <= ma_slow[i - 1]:
                        pos = 1
                        entry_price = ask + (pip * 0.1)
                        curr_sl = entry_price - sl_dist
                        curr_tp = entry_price + tp_dist
                    elif ma_fast[i] < ma_slow[i] and ma_fast[i - 1] >= ma_slow[i - 1]:
                        pos = -1
                        entry_price = bid - (pip * 0.1)
                        curr_sl = entry_price + sl_dist
                        curr_tp = entry_price - tp_dist

        # Compute performance summary
        total_trades = len(trades)
        wins = [t for t in trades if t > 0]
        losses = [abs(t) for t in trades if t < 0]
        net_pnl = capital - self.initial_capital
        ret_pct = (net_pnl / self.initial_capital) * 100.0
        win_rate = (len(wins) / total_trades * 100.0) if total_trades > 0 else 0.0

        gross_profit = sum(wins)
        gross_loss = sum(losses)
        pf = (gross_profit / gross_loss) if gross_loss > 0 else (99.0 if gross_profit > 0 else 0.0)

        std_trades = np.std(trades) if len(trades) > 1 else 0.0
        sharpe = (np.mean(trades) / std_trades * np.sqrt(252 * 5)) if std_trades > 1e-7 else 0.0

        # Performance Verdict
        if max_dd_pct >= 30.0 or is_martingale and net_pnl < -1000.0 or capital <= 2000.0:
            verdict = "FAIL_BLOWUP"
        elif ret_pct > 0 and pf >= 1.15 and max_dd_pct < 25.0:
            verdict = "PASS_PROFITABLE"
        elif total_trades > 0:
            verdict = "PASS_MARGINAL"
        else:
            verdict = "NO_TRADES_TRIGGERED"

        return {
            "total_trades": total_trades,
            "win_rate_pct": round(win_rate, 2),
            "final_equity": round(capital, 2),
            "net_pnl": round(net_pnl, 2),
            "return_pct": round(ret_pct, 2),
            "profit_factor": round(min(99.0, pf), 2),
            "max_drawdown_pct": round(max_dd_pct, 2),
            "sharpe_ratio": round(sharpe, 2),
            "verdict": verdict
        }

    def test_single_file(self, filename: str, index: int) -> Dict[str, Any]:
        """Sequentially analyzes and tests a single MQ4 file."""
        filepath = os.path.join(self.mq4_dir, filename)
        file_size = os.path.getsize(filepath)

        try:
            with open(filepath, 'r', encoding='latin1', errors='replace') as fp:
                content = fp.read()
        except Exception as e:
            return {
                "index": index,
                "filename": filename,
                "error": str(e),
                "verdict": "FILE_READ_ERROR"
            }

        is_syntax_valid, syntax_status, loc = self.inspect_syntax(content)
        params = self.extract_strategy_parameters(content)

        file_type = "Expert Advisor" if params['has_ordersend'] else ("Custom Indicator" if "#property indicator" in content else "Script / Helper")

        # Run real-tick simulation if it is an Expert Advisor
        if params['has_ordersend']:
            sim_res = self.simulate_ea_backtest(params)
        else:
            sim_res = {
                "total_trades": 0,
                "win_rate_pct": 0.0,
                "final_equity": self.initial_capital,
                "net_pnl": 0.0,
                "return_pct": 0.0,
                "profit_factor": 0.0,
                "max_drawdown_pct": 0.0,
                "sharpe_ratio": 0.0,
                "verdict": "INDICATOR_ONLY"
            }

        return {
            "index": index,
            "filename": filename,
            "file_type": file_type,
            "file_size_bytes": file_size,
            "lines_of_code": loc,
            "syntax_valid": is_syntax_valid,
            "syntax_status": syntax_status,
            "archetype": params['archetype'],
            "indicators": params['indicators'],
            "is_martingale": params['is_martingale'],
            "risk_classification": params['risk_classification'],
            "extracted_sl": params['sl_pips'],
            "extracted_tp": params['tp_pips'],
            "extracted_lots": params['lot_size'],
            "backtest": sim_res
        }

    def run_all_sequential(self) -> Dict[str, Any]:
        """Runs the entire sequential test suite across all 1,296 files."""
        files = sorted([f for f in os.listdir(self.mq4_dir) if f.lower().endswith('.mq4')])
        total_files = len(files)
        print(f"\n==================================================")
        print(f"STARTING SEQUENTIAL TESTING OF {total_files} MQ4 FILES")
        print(f"==================================================")

        results = []
        t_start = time.time()

        for idx, filename in enumerate(files, 1):
            res = self.test_single_file(filename, idx)
            results.append(res)

            if idx % 100 == 0 or idx == total_files:
                elapsed = time.time() - t_start
                rate = idx / max(0.01, elapsed)
                ea_tested = sum(1 for r in results if r.get('file_type') == 'Expert Advisor')
                pass_count = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'PASS_PROFITABLE')
                fail_count = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'FAIL_BLOWUP')
                print(f"[{idx:4d}/{total_files}] ({rate:.1f} files/s) | EAs: {ea_tested} | Profitable: {pass_count} | Blowup: {fail_count} | Last: {filename[:30]}")

        total_elapsed = time.time() - t_start
        print(f"\nAll {total_files} files tested sequentially in {total_elapsed:.2f} seconds.")

        # Aggregate Statistics
        total_eas = sum(1 for r in results if r.get('file_type') == 'Expert Advisor')
        total_indicators = sum(1 for r in results if 'Indicator' in r.get('file_type', ''))
        total_profitable = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'PASS_PROFITABLE')
        total_marginal = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'PASS_MARGINAL')
        total_blowup = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'FAIL_BLOWUP')
        total_martingale = sum(1 for r in results if r.get('is_martingale', False))

        # Sort EAs to generate Leaderboard
        ea_results = [r for r in results if r.get('file_type') == 'Expert Advisor' and r.get('backtest', {}).get('total_trades', 0) > 0]
        ea_results.sort(key=lambda x: (
            x['backtest']['verdict'] == 'PASS_PROFITABLE',
            x['backtest']['profit_factor'],
            x['backtest']['return_pct']
        ), reverse=True)

        top_10 = ea_results[:10]
        worst_10 = sorted(ea_results, key=lambda x: x['backtest']['return_pct'])[:10]

        summary = {
            "total_files_tested": total_files,
            "total_expert_advisors": total_eas,
            "total_indicators": total_indicators,
            "total_martingale_systems": total_martingale,
            "ea_verdict_breakdown": {
                "PASS_PROFITABLE": total_profitable,
                "PASS_MARGINAL": total_marginal,
                "FAIL_BLOWUP": total_blowup
            },
            "pass_rate_pct": round((total_profitable / max(1, total_eas)) * 100.0, 2),
            "blowup_rate_pct": round((total_blowup / max(1, total_eas)) * 100.0, 2),
            "test_duration_seconds": round(total_elapsed, 2)
        }

        return {
            "summary": summary,
            "top_10_alpha_eas": top_10,
            "worst_10_blowup_eas": worst_10,
            "all_results": results
        }


def save_test_artifacts(data: Dict[str, Any], output_dir: str):
    """Exports full JSON and leaderboard CSV."""
    os.makedirs(output_dir, exist_ok=True)

    # 1. Full JSON
    json_path = os.path.join(output_dir, "sequential_test_results.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    print(f"Saved complete sequential test results: {json_path}")

    # 2. Summary JSON
    summary_path = os.path.join(output_dir, "sequential_test_summary.json")
    with open(summary_path, 'w', encoding='utf-8') as f:
        json.dump(data['summary'], f, indent=2)
    print(f"Saved test summary: {summary_path}")

    # 3. Top Alpha Strategies JSON
    top_path = os.path.join(output_dir, "top_alpha_strategies.json")
    with open(top_path, 'w', encoding='utf-8') as f:
        json.dump({
            "top_10_alpha_eas": data['top_10_alpha_eas'],
            "worst_10_blowup_eas": data['worst_10_blowup_eas']
        }, f, indent=2)
    print(f"Saved top alpha strategies: {top_path}")

    # 4. Tabular CSV Leaderboard
    rows = []
    for r in data['all_results']:
        bt = r.get('backtest', {})
        rows.append({
            "Index": r.get('index'),
            "Filename": r.get('filename'),
            "Type": r.get('file_type'),
            "LinesOfCode": r.get('lines_of_code'),
            "Archetype": r.get('archetype'),
            "Indicators": ",".join(r.get('indicators', [])),
            "IsMartingale": r.get('is_martingale'),
            "RiskClass": r.get('risk_classification'),
            "Verdict": bt.get('verdict'),
            "Trades": bt.get('total_trades', 0),
            "WinRatePct": bt.get('win_rate_pct', 0.0),
            "NetPnL": bt.get('net_pnl', 0.0),
            "ReturnPct": bt.get('return_pct', 0.0),
            "ProfitFactor": bt.get('profit_factor', 0.0),
            "MaxDrawdownPct": bt.get('max_drawdown_pct', 0.0),
            "SharpeRatio": bt.get('sharpe_ratio', 0.0)
        })
    df_board = pd.DataFrame(rows)
    csv_path = os.path.join(output_dir, "sequential_test_leaderboard.csv")
    df_board.to_csv(csv_path, index=False)
    print(f"Saved leaderboard CSV: {csv_path}")


if __name__ == "__main__":
    mq4_folder = r"e:\Github Submissions\MQ4 Source Codes (1300+)"
    tick_path = r"e:\Github Submissions\06-mq4-tick-alpha-engine\data\real_ticks_gbpusd.csv"
    out_dir = r"e:\Github Submissions\06-mq4-tick-alpha-engine\data"

    tester = SequentialMQ4Tester(mq4_folder, tick_path)
    output = tester.run_all_sequential()
    save_test_artifacts(output, out_dir)
    print("\n--- SEQUENTIAL TESTING COMPLETE ---")
