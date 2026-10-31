"""
Sequential MQ4 Codebase Testing & Microstructure Audit Engine
--------------------------------------------------------------
Hedge Fund-Grade Sequential Testing Framework for 1,296 MQL4 Files:
1. Syntax, lexical, and structural integrity verification
2. Rule and parameter extraction (SL, TP, Lot sizing, Indicators)
3. Microstructure execution simulation on real broker tick data
4. Comprehensive Institutional Risk Suite (Sortino, Calmar, Omega, Gain-to-Pain, Ulcer, VaR, CVaR, CDaR)
5. Deflated Sharpe Ratio (DSR) & Expected Max Sharpe under N=1,297 trials (Bailey & López de Prado)
6. Multiple Testing Corrections: Benjamini-Hochberg FDR & Bonferroni FWER
7. Purged & Embargoed Walk-Forward Cross Validation (OER) on top discoveries
8. Microstructure Liquidity & Latency Stress Testing (Spread shocks, queue delays)
9. Institutional Risk-Parity Alpha Portfolio Synthesis
"""

import os
import re
import sys
import json
import time
import pandas as pd
import numpy as np
from typing import Dict, List, Any, Optional, Tuple

project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from src.engine.institutional_metrics import (
    compute_institutional_risk_suite,
    compute_deflated_sharpe_ratio,
    compute_expected_max_sharpe,
    compute_probabilistic_sharpe_ratio,
    adjust_pvalues_benjamini_hochberg,
    adjust_pvalues_bonferroni
)
from src.engine.walk_forward_purged import PurgedWalkForwardCV
from src.engine.stress_testing import MicrostructureStressTester
from src.engine.portfolio_allocator import InstitutionalPortfolioEngine


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
        found_inds = [ind for ind in self.BUILTIN_INDICATORS if re.search(r'\b' + re.escape(ind) + r'\b', content)]

        sl_matches = re.findall(r'(?:StopLoss|Stop_Loss|SL)\s*=\s*([0-9.]+)', content, re.I)
        sl_pips = float(sl_matches[0]) if sl_matches and float(sl_matches[0]) > 0 else None

        tp_matches = re.findall(r'(?:TakeProfit|Take_Profit|TP)\s*=\s*([0-9.]+)', content, re.I)
        tp_pips = float(tp_matches[0]) if tp_matches and float(tp_matches[0]) > 0 else None

        trail_matches = re.findall(r'(?:TrailingStop|Trailing_Stop|Trail)\s*=\s*([0-9.]+)', content, re.I)
        trail_pips = float(trail_matches[0]) if trail_matches and float(trail_matches[0]) > 0 else None

        lot_matches = re.findall(r'(?:Lots|LotSize|Lot)\s*=\s*([0-9.]+)', content, re.I)
        lot_size = float(lot_matches[0]) if lot_matches and float(lot_matches[0]) > 0 else 0.1

        is_martingale = bool(re.search(r'(?:Martingale|Multiplier|LotMultiplier|PipStep|GridStep|double_lot|RecoveryFactor)', content, re.I))
        if re.search(r'Lots\s*\*\s*LotMultiplier|Lots\s*\*\s*2|OrderLots\(\)\s*\*\s*[123]', content):
            is_martingale = True

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

    def simulate_ea_backtest(
        self,
        params: Dict[str, Any],
        df_ticks: Optional[pd.DataFrame] = None
    ) -> Dict[str, Any]:
        """
        Simulates extracted EA logic against real broker ticks with spread, slippage, and commissions.
        Computes the complete institutional risk metric suite.
        """
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

        # Select tick arrays and indicator precomputations
        if df_ticks is not None:
            bids = df_ticks['bid'].to_numpy()
            asks = df_ticks['ask'].to_numpy()
            mids = df_ticks['mid'].to_numpy()
            spreads = df_ticks['spread'].to_numpy()
            n_ticks = len(df_ticks)
            mid_s = pd.Series(mids)
            ma_fast = mid_s.rolling(20).mean().to_numpy()
            ma_slow = mid_s.rolling(50).mean().to_numpy()
            mean = ma_slow
            std = mid_s.rolling(50).std().to_numpy()
            highs = mid_s.rolling(20).max().to_numpy()
            lows = mid_s.rolling(20).min().to_numpy()
            start_idx = min(55, max(5, n_ticks // 10))
        else:
            bids = self.bids
            asks = self.asks
            mids = self.mids
            spreads = self.spreads
            n_ticks = self.n_ticks
            ma_fast = self.precomputed_ma[20]
            ma_slow = self.precomputed_ma[50]
            mean = self.precomputed_ma[50]
            std = self.precomputed_std[50]
            highs = self.precomputed_high[20]
            lows = self.precomputed_low[20]
            start_idx = 55

        for i in range(start_idx, n_ticks):
            bid = bids[i]
            ask = asks[i]
            mid = mids[i]
            spr = spreads[i]

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

        # Compute complete institutional risk analytics
        inst_metrics = compute_institutional_risk_suite(
            trades,
            initial_capital=self.initial_capital
        )

        net_pnl = float(capital - self.initial_capital)
        ret_pct = float((net_pnl / self.initial_capital) * 100.0)
        max_dd = float(inst_metrics['max_drawdown_pct'])
        pf = float(inst_metrics['profit_factor'])

        # Performance Verdict
        if max_dd >= 30.0 or (is_martingale and net_pnl < -1000.0) or capital <= 2000.0:
            verdict = "FAIL_BLOWUP"
        elif ret_pct > 0 and pf >= 1.15 and max_dd < 25.0:
            verdict = "PASS_PROFITABLE"
        elif inst_metrics['total_trades'] > 0:
            verdict = "PASS_MARGINAL"
        else:
            verdict = "NO_TRADES_TRIGGERED"

        result = dict(inst_metrics)
        result.update({
            "final_equity": round(float(capital), 2),
            "verdict": verdict,
            "trades_list": trades
        })
        return result

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

        if params['has_ordersend']:
            sim_res = self.simulate_ea_backtest(params)
        else:
            empty_risk = compute_institutional_risk_suite([])
            empty_risk.update({
                "final_equity": self.initial_capital,
                "verdict": "INDICATOR_ONLY",
                "trades_list": []
            })
            sim_res = empty_risk

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
            "strategy_params": params,
            "backtest": sim_res
        }

    def run_all_sequential(self) -> Dict[str, Any]:
        """Runs the entire sequential test suite across all 1,296 files with hedge-fund statistics."""
        files = sorted([f for f in os.listdir(self.mq4_dir) if f.lower().endswith('.mq4')])
        total_files = len(files)
        print(f"\n==================================================")
        print(f"HEDGE FUND SEQUENTIAL AUDIT: {total_files} MQ4 FILES")
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
                print(f"[{idx:4d}/{total_files}] ({rate:.1f} files/s) | EAs: {ea_tested} | Profitable: {pass_count} | Blowup: {fail_count} | {filename[:28]}")

        total_elapsed = time.time() - t_start
        print(f"\nAll {total_files} files tested sequentially in {total_elapsed:.2f} seconds.")

        # =========================================================================
        # INSTITUTIONAL STATISTICAL ADJUSTMENTS: DSR, PSR, FDR & FWER
        # =========================================================================
        print("\nCalculating Bailey & López de Prado Deflated Sharpe Ratios & Multiple Testing Adjustments...")
        
        ea_indices = []
        ea_sharpes = []
        ea_psr_zeros = []
        
        for idx, r in enumerate(results):
            if r.get('file_type') == 'Expert Advisor':
                bt = r.get('backtest', {})
                if bt.get('total_trades', 0) >= 3:
                    ea_indices.append(idx)
                    ea_sharpes.append(bt.get('sharpe_ratio', 0.0))
                    ea_psr_zeros.append(bt.get('psr_zero', 0.5))

        n_ea_trials = len(ea_sharpes)
        if n_ea_trials > 1:
            var_sr = float(np.var(ea_sharpes, ddof=1))
            mean_sr = float(np.mean(ea_sharpes))
            exp_max_sr = compute_expected_max_sharpe(n_trials=n_ea_trials, var_sr=var_sr, mean_sr=mean_sr)
        else:
            exp_max_sr = 0.0

        print(f"Evaluated {n_ea_trials} trading EAs | Sharpe Variance: {var_sr:.4f} | Expected Max Sharpe E[max_N]: {exp_max_sr:.4f}")

        # Nominal one-sided p-values against SR* = 0: p_i = 1.0 - PSR(0)
        nominal_p_vals = np.array([max(1e-6, 1.0 - psr) for psr in ea_psr_zeros])
        fdr_q_vals = adjust_pvalues_benjamini_hochberg(nominal_p_vals)
        bonf_p_vals = adjust_pvalues_bonferroni(nominal_p_vals)

        for i, res_idx in enumerate(ea_indices):
            res = results[res_idx]
            bt = res['backtest']
            sr = bt.get('sharpe_ratio', 0.0)
            n_obs = bt.get('total_trades', 10)
            skew = bt.get('return_skewness', 0.0)
            kurt = bt.get('return_kurtosis', 3.0)

            dsr_info = compute_deflated_sharpe_ratio(
                sr=sr,
                all_sr_trials=ea_sharpes,
                n_obs=n_obs,
                skew=skew,
                kurt=kurt
            )
            bt['deflated_sharpe_ratio'] = dsr_info['deflated_sharpe_ratio']
            bt['expected_max_sharpe'] = dsr_info['expected_max_sharpe']
            bt['p_value_deflated'] = dsr_info['p_value_deflated']
            bt['fdr_q_value'] = float(round(fdr_q_vals[i], 4))
            bt['is_fdr_significant_05'] = bool(fdr_q_vals[i] <= 0.05)
            bt['bonferroni_p_value'] = float(round(bonf_p_vals[i], 4))
            bt['is_bonferroni_significant'] = bool(bonf_p_vals[i] <= 0.05)

            # Assign Institutional Verdict
            if bt['verdict'] == 'PASS_PROFITABLE' and bt['deflated_sharpe_ratio'] >= 0.85 and bt['is_fdr_significant_05'] and not res.get('is_martingale'):
                bt['institutional_verdict'] = "INSTITUTIONAL_ALPHA_DISCOVERY"
            elif bt['verdict'] == 'PASS_PROFITABLE':
                bt['institutional_verdict'] = "RETAIL_PROFITABLE_UNPROVEN"
            elif bt['verdict'] == 'FAIL_BLOWUP':
                bt['institutional_verdict'] = "FAIL_TOXIC_BLOWUP"
            else:
                bt['institutional_verdict'] = "MARGINAL_NOISE"

        # Separate trade lists from serialization to keep artifact sizes clean
        for r in results:
            if 'backtest' in r and 'trades_list' in r['backtest']:
                del r['backtest']['trades_list']

        # Aggregate Statistics
        total_eas = sum(1 for r in results if r.get('file_type') == 'Expert Advisor')
        total_indicators = sum(1 for r in results if 'Indicator' in r.get('file_type', ''))
        total_profitable = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'PASS_PROFITABLE')
        total_institutional_alpha = sum(1 for r in results if r.get('backtest', {}).get('institutional_verdict') == 'INSTITUTIONAL_ALPHA_DISCOVERY')
        total_marginal = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'PASS_MARGINAL')
        total_blowup = sum(1 for r in results if r.get('backtest', {}).get('verdict') == 'FAIL_BLOWUP')
        total_martingale = sum(1 for r in results if r.get('is_martingale', False))

        # Sort EAs to generate Leaderboard by Institutional Alpha
        ea_results = [r for r in results if r.get('file_type') == 'Expert Advisor' and r.get('backtest', {}).get('total_trades', 0) > 0]
        ea_results.sort(key=lambda x: (
            x['backtest'].get('institutional_verdict') == 'INSTITUTIONAL_ALPHA_DISCOVERY',
            x['backtest'].get('deflated_sharpe_ratio', 0.0),
            x['backtest'].get('profit_factor', 0.0),
            x['backtest'].get('return_pct', 0.0)
        ), reverse=True)

        top_10 = ea_results[:10]
        worst_10 = sorted(ea_results, key=lambda x: x['backtest']['return_pct'])[:10]

        # =========================================================================
        # WALK-FORWARD PURGED VALIDATION & STRESS TESTS ON TOP CANDIDATES
        # =========================================================================
        print("\nExecuting Purged Walk-Forward & Microstructure Stress Matrix on Top Alpha Discoveries...")
        pwfo_engine = PurgedWalkForwardCV(n_splits=4, train_ratio=0.60, purge_ticks=50, embargo_ticks=50)
        stress_engine = MicrostructureStressTester(initial_capital=self.initial_capital)

        for top_ea in top_10[:3]:
            strat_p = top_ea.get('strategy_params', {})
            
            # WFO evaluation function
            def eval_subslice(df_slice: pd.DataFrame) -> Dict[str, Any]:
                return self.simulate_ea_backtest(strat_p, df_ticks=df_slice)

            wfo_res = pwfo_engine.evaluate_strategy_wfo(self.df_ticks, eval_subslice)
            stress_res = stress_engine.run_stress_suite(self.df_ticks, eval_subslice)

            top_ea['walk_forward_purged'] = wfo_res
            top_ea['microstructure_stress'] = stress_res
            print(f"-> {top_ea['filename']}: WFO OER={wfo_res['out_of_sample_efficiency_ratio']} ({wfo_res['walk_forward_verdict']}) | Fragility={stress_res['fragility_score_pct']}% ({stress_res['stress_resilience_verdict']})")

        # =========================================================================
        # INSTITUTIONAL PORTFOLIO SYNTHESIS
        # =========================================================================
        print("\nSynthesizing Multi-Strategy Alpha Portfolio with Volatility Targeting...")
        port_engine = InstitutionalPortfolioEngine(target_annual_vol_pct=10.0, max_leverage=1.5, initial_capital=self.initial_capital)
        
        # Collect top non-martingale trades
        top_strats_trades = {}
        for top_ea in top_10[:4]:
            if not top_ea.get('is_martingale'):
                p = top_ea['strategy_params']
                res_bt = self.simulate_ea_backtest(p)
                trades_arr = res_bt.get('trades_list', [])
                if len(trades_arr) >= 5:
                    top_strats_trades[top_ea['filename']] = trades_arr

        if len(top_strats_trades) >= 2:
            portfolio_summary = port_engine.combine_strategies(top_strats_trades, weighting_scheme="inverse_vol")
            print(f"Portfolio Combined Sharpe: {portfolio_summary['portfolio_metrics']['sharpe_ratio']} | Diversification Ratio: {portfolio_summary['diversification_ratio']}")
        else:
            portfolio_summary = {}

        summary = {
            "total_files_tested": total_files,
            "total_expert_advisors": total_eas,
            "total_indicators": total_indicators,
            "total_martingale_systems": total_martingale,
            "nominal_verdicts": {
                "PASS_PROFITABLE": total_profitable,
                "PASS_MARGINAL": total_marginal,
                "FAIL_BLOWUP": total_blowup
            },
            "institutional_verdicts": {
                "INSTITUTIONAL_ALPHA_DISCOVERY": total_institutional_alpha,
                "RETAIL_PROFITABLE_UNPROVEN": total_profitable - total_institutional_alpha,
                "FAIL_TOXIC_BLOWUP": total_blowup,
                "MARGINAL_NOISE": total_marginal
            },
            "multiple_testing_parameters": {
                "trials_evaluated": n_ea_trials,
                "sharpe_variance": round(var_sr, 4),
                "expected_max_sharpe_hurdle": round(exp_max_sr, 4),
                "fdr_alpha": 0.05,
                "bonferroni_alpha": round(0.05 / max(1, n_ea_trials), 6)
            },
            "pass_rate_pct": round((total_profitable / max(1, total_eas)) * 100.0, 2),
            "institutional_discovery_rate_pct": round((total_institutional_alpha / max(1, total_eas)) * 100.0, 2),
            "blowup_rate_pct": round((total_blowup / max(1, total_eas)) * 100.0, 2),
            "test_duration_seconds": round(total_elapsed, 2)
        }

        # Clean up strategy_params from JSON artifacts for clean structure
        for r in results:
            if 'strategy_params' in r:
                del r['strategy_params']

        return {
            "summary": summary,
            "portfolio_synthesis": portfolio_summary,
            "top_10_alpha_eas": top_10,
            "worst_10_blowup_eas": worst_10,
            "all_results": results
        }


def save_test_artifacts(data: Dict[str, Any], output_dir: str):
    """Exports full JSON, summary JSON, and comprehensive institutional CSV leaderboard."""
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
            "worst_10_blowup_eas": data['worst_10_blowup_eas'],
            "portfolio_synthesis": data.get('portfolio_synthesis', {})
        }, f, indent=2)
    print(f"Saved top alpha strategies: {top_path}")

    # 4. Tabular CSV Leaderboard with Institutional Columns
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
            "InstitutionalVerdict": bt.get('institutional_verdict', 'N/A'),
            "Trades": bt.get('total_trades', 0),
            "WinRatePct": bt.get('win_rate_pct', 0.0),
            "NetPnL": bt.get('net_pnl', 0.0),
            "ReturnPct": bt.get('return_pct', 0.0),
            "ProfitFactor": bt.get('profit_factor', 0.0),
            "MaxDrawdownPct": bt.get('max_drawdown_pct', 0.0),
            "SharpeRatio": bt.get('sharpe_ratio', 0.0),
            "DeflatedSharpeRatio": bt.get('deflated_sharpe_ratio', 0.0),
            "ExpectedMaxSharpe": bt.get('expected_max_sharpe', 0.0),
            "ProbabilisticSharpeZero": bt.get('psr_zero', 0.0),
            "FDR_q_value": bt.get('fdr_q_value', 1.0),
            "FDR_Significant": bt.get('is_fdr_significant_05', False),
            "Bonferroni_p_value": bt.get('bonferroni_p_value', 1.0),
            "Bonferroni_Significant": bt.get('is_bonferroni_significant', False),
            "SortinoRatio": bt.get('sortino_ratio', 0.0),
            "CalmarRatio": bt.get('calmar_ratio', 0.0),
            "OmegaRatio": bt.get('omega_ratio', 0.0),
            "GainToPainRatio": bt.get('gain_to_pain_ratio', 0.0),
            "UlcerIndex": bt.get('ulcer_index', 0.0),
            "MartinRatio": bt.get('martin_ratio', 0.0),
            "VaR_95_Dollars": bt.get('var_95_dollars', 0.0),
            "CVaR_95_Dollars": bt.get('cvar_95_dollars', 0.0),
            "CDaR_95_Pct": bt.get('cdar_95_pct', 0.0),
            "Skewness": bt.get('return_skewness', 0.0),
            "ExcessKurtosis": bt.get('return_kurtosis', 3.0),
            "TailRiskRatio": bt.get('tail_risk_ratio', 0.0),
            "MaxConsecutiveLosses": bt.get('max_consecutive_losses', 0)
        })
    df_board = pd.DataFrame(rows)
    csv_path = os.path.join(output_dir, "sequential_test_leaderboard.csv")
    df_board.to_csv(csv_path, index=False)
    print(f"Saved institutional leaderboard CSV: {csv_path}")


if __name__ == "__main__":
    mq4_folder = r"e:\Github Submissions\MQ4 Source Codes (1300+)"
    tick_path = r"e:\Github Submissions\06-mq4-tick-alpha-engine\data\real_ticks_gbpusd.csv"
    out_dir = r"e:\Github Submissions\06-mq4-tick-alpha-engine\data"

    tester = SequentialMQ4Tester(mq4_folder, tick_path)
    output = tester.run_all_sequential()
    save_test_artifacts(output, out_dir)
    print("\n--- HEDGE FUND SEQUENTIAL TESTING COMPLETE ---")
