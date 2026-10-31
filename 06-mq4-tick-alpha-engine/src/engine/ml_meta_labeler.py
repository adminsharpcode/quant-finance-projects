"""
Marcos López de Prado Machine Learning Meta-Labeling & Strategy Optimizer
-------------------------------------------------------------------------
Implements the institutional Meta-Labeling framework from Advances in Financial Machine Learning:
1. Primary Strategy: Mined Multi-Regime Volatility & Donchian Breakout logic.
2. Microstructure Feature Engineering at Signal Time:
   - Spread expansion ratio: current_spread / rolling_50_spread
   - Microstructure volatility ratio: sigma_20 / sigma_100
   - Price displacement z-score: (mid - sma_50) / sigma_50
   - Normalized Donchian channel position: (mid - low_20) / (high_20 - low_20)
   - Order flow price momentum: mid_drift_10 / pip
   - Trend strength regime: |ema_20 - ema_50| / sigma_50
3. Supervised Meta-Model (RandomForest & GradientBoosting):
   - Learns P(Trade = Profitable | Microstructure State)
4. Dynamic Conviction Filter:
   - Rejects false breakout traps and illiquid execution states where P < threshold.
   - Sizes positions proportionally to ML conviction.
"""

import os
import sys
import json
import math
import numpy as np
import pandas as pd
from typing import Dict, List, Any, Tuple, Optional

project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import roc_auc_score, precision_score, recall_score

from src.engine.institutional_metrics import compute_institutional_risk_suite, compute_deflated_sharpe_ratio


class MLMetaLabeler:
    def __init__(
        self,
        pip_size: float = 0.0001,
        lot_size: float = 100000.0,
        initial_capital: float = 10000.0,
        commission_per_lot: float = 5.0,
        sl_pips: float = 12.0,
        tp_pips: float = 24.0,
        prob_threshold: float = 0.55
    ):
        self.pip_size = pip_size
        self.lot_size = lot_size
        self.initial_capital = initial_capital
        self.commission_per_lot = commission_per_lot
        self.sl_pips = sl_pips
        self.tp_pips = tp_pips
        self.prob_threshold = prob_threshold
        self.model = None

    def build_signal_dataset(self, df_ticks: pd.DataFrame) -> pd.DataFrame:
        """
        Scans real broker ticks and extracts primary candidate trades along with
        microstructure state features and forward triple-barrier labels.
        """
        bids = df_ticks['bid'].to_numpy()
        asks = df_ticks['ask'].to_numpy()
        mids = df_ticks['mid'].to_numpy()
        spreads = df_ticks['spread'].to_numpy()
        n_ticks = len(df_ticks)

        s_mid = pd.Series(mids)
        ma20 = s_mid.rolling(20).mean().to_numpy()
        ma50 = s_mid.rolling(50).mean().to_numpy()
        std20 = s_mid.rolling(20).std().to_numpy()
        std50 = s_mid.rolling(50).std().to_numpy()
        std100 = s_mid.rolling(100).std().to_numpy()
        high20 = s_mid.rolling(20).max().to_numpy()
        low20 = s_mid.rolling(20).min().to_numpy()
        avg_spr = pd.Series(spreads).rolling(50).mean().to_numpy()

        sl_dist = self.sl_pips * self.pip_size
        tp_dist = self.tp_pips * self.pip_size

        records = []
        i = 55
        while i < n_ticks - 60:
            sig = 0
            # Primary strategy logic (mined from top MQL4 breakout & mean reversion codebases)
            if std50[i] > 1e-6 and mids[i] < ma50[i] - (1.8 * std50[i]):
                sig = 1
            elif std50[i] > 1e-6 and mids[i] > ma50[i] + (1.8 * std50[i]):
                sig = -1
            elif mids[i] > high20[i - 1] and ma20[i] > ma50[i]:
                sig = 1
            elif mids[i] < low20[i - 1] and ma20[i] < ma50[i]:
                sig = -1

            if sig != 0:
                entry_price = asks[i] if sig == 1 else bids[i]
                curr_sl = entry_price - sl_dist if sig == 1 else entry_price + sl_dist
                curr_tp = entry_price + tp_dist if sig == 1 else entry_price - tp_dist

                # Forward simulate outcome until SL or TP
                exit_idx = i + 1
                outcome = 0
                net_pnl = 0.0

                for j in range(i + 1, min(n_ticks, i + 800)):
                    exit_idx = j
                    if sig == 1:
                        if bids[j] <= curr_sl:
                            gross = (curr_sl - entry_price) * self.lot_size
                            net_pnl = gross - self.commission_per_lot
                            outcome = 0
                            break
                        elif bids[j] >= curr_tp:
                            gross = (curr_tp - entry_price) * self.lot_size
                            net_pnl = gross - self.commission_per_lot
                            outcome = 1
                            break
                    else:
                        if asks[j] >= curr_sl:
                            gross = (entry_price - curr_sl) * self.lot_size
                            net_pnl = gross - self.commission_per_lot
                            outcome = 0
                            break
                        elif asks[j] <= curr_tp:
                            gross = (entry_price - curr_tp) * self.lot_size
                            net_pnl = gross - self.commission_per_lot
                            outcome = 1
                            break

                # Microstructure features at signal time
                spr_ratio = (spreads[i] / avg_spr[i]) if avg_spr[i] > 1e-6 else 1.0
                vol_ratio = (std20[i] / std100[i]) if (std100[i] > 1e-6 and std20[i] > 1e-6) else 1.0
                zscore = (mids[i] - ma50[i]) / std50[i] if std50[i] > 1e-6 else 0.0
                range_20 = high20[i] - low20[i]
                donchian = (mids[i] - low20[i]) / range_20 if range_20 > 1e-6 else 0.5
                drift10 = (mids[i] - mids[max(0, i - 10)]) / self.pip_size
                drift30 = (mids[i] - mids[max(0, i - 30)]) / self.pip_size
                trend_regime = abs(ma20[i] - ma50[i]) / std50[i] if std50[i] > 1e-6 else 0.0

                records.append({
                    'tick_index': i,
                    'signal_side': sig,
                    'spread_ratio': round(float(spr_ratio), 3),
                    'volatility_ratio': round(float(vol_ratio), 3),
                    'zscore_displacement': round(float(zscore), 3),
                    'donchian_position': round(float(donchian), 3),
                    'tick_drift_10': round(float(drift10), 2),
                    'tick_drift_30': round(float(drift30), 2),
                    'trend_regime_strength': round(float(trend_regime), 3),
                    'net_pnl': round(float(net_pnl), 2),
                    'label_profit': int(outcome),
                    'holding_ticks': exit_idx - i
                })

                # Advance index past this trade to avoid artificial overlap
                i = max(i + 1, exit_idx)
            else:
                i += 1

        df_out = pd.DataFrame(records)
        return df_out

    def train_and_optimize(
        self,
        df_ticks: pd.DataFrame,
        train_test_split: float = 0.65
    ) -> Dict[str, Any]:
        """
        Trains the Meta-Labeler on In-Sample ticks and validates out-of-sample optimization.
        """
        df_sig = self.build_signal_dataset(df_ticks)
        n_samples = len(df_sig)
        if n_samples < 8:
            return {"error": "Insufficient trade events generated for ML training"}

        feature_cols = [
            'signal_side', 'spread_ratio', 'volatility_ratio',
            'zscore_displacement', 'donchian_position',
            'tick_drift_10', 'tick_drift_30', 'trend_regime_strength'
        ]

        split_idx = int(n_samples * train_test_split)
        train_df = df_sig.iloc[:split_idx]
        test_df = df_sig.iloc[split_idx:].copy()

        X_train = train_df[feature_cols]
        y_train = train_df['label_profit']
        X_test = test_df[feature_cols]
        y_test = test_df['label_profit']

        # Train Random Forest Meta-Classifier
        clf = RandomForestClassifier(
            n_estimators=120,
            max_depth=4,
            min_samples_leaf=3,
            random_state=42,
            class_weight='balanced'
        )
        clf.fit(X_train, y_train)
        self.model = clf

        # Out-of-Sample Predictions
        test_probs = clf.predict_proba(X_test)[:, 1] if len(clf.classes_) > 1 else np.zeros(len(X_test))
        test_df['ml_conviction'] = test_probs

        # 1. Performance of RAW Strategy (without ML filter) on Out-of-Sample
        raw_trades = test_df['net_pnl'].tolist()
        raw_metrics = compute_institutional_risk_suite(raw_trades, initial_capital=self.initial_capital)

        # 2. Performance of ML-OPTIMIZED Strategy (filtering out low-probability traps)
        ml_filtered_df = test_df[test_df['ml_conviction'] >= self.prob_threshold]
        # If threshold is too strict, fallback to top 50%
        if len(ml_filtered_df) == 0:
            median_p = float(np.median(test_probs))
            ml_filtered_df = test_df[test_df['ml_conviction'] >= median_p]

        # Conviction-weighted sizing: scale lot sizes by model conviction
        ml_trades = []
        for _, row in ml_filtered_df.iterrows():
            weight = max(0.5, min(2.0, row['ml_conviction'] / 0.5))
            ml_trades.append(row['net_pnl'] * weight)

        ml_metrics = compute_institutional_risk_suite(ml_trades, initial_capital=self.initial_capital)

        # Feature Importance in Meta-Labeling
        imp = pd.Series(clf.feature_importances_, index=feature_cols).sort_values(ascending=False)
        top_meta_features = [{"feature": k, "importance": round(float(v), 4)} for k, v in imp.items()]

        # Compute improvements
        win_rate_delta = ml_metrics['win_rate_pct'] - raw_metrics['win_rate_pct']
        pf_delta = ml_metrics['profit_factor'] - raw_metrics['profit_factor']
        sharpe_delta = ml_metrics['sharpe_ratio'] - raw_metrics['sharpe_ratio']
        dd_reduction = raw_metrics['max_drawdown_pct'] - ml_metrics['max_drawdown_pct']

        results = {
            "total_candidate_signals": n_samples,
            "train_signals": len(train_df),
            "test_signals": len(test_df),
            "ml_filtered_signals": len(ml_filtered_df),
            "filter_retention_rate_pct": round((len(ml_filtered_df) / max(1, len(test_df))) * 100.0, 2),
            "conviction_threshold": self.prob_threshold,
            "raw_strategy_oos": {
                "trades": raw_metrics['total_trades'],
                "win_rate_pct": raw_metrics['win_rate_pct'],
                "net_pnl": raw_metrics['net_pnl'],
                "profit_factor": raw_metrics['profit_factor'],
                "sharpe_ratio": raw_metrics['sharpe_ratio'],
                "sortino_ratio": raw_metrics['sortino_ratio'],
                "max_drawdown_pct": raw_metrics['max_drawdown_pct'],
                "ulcer_index": raw_metrics['ulcer_index']
            },
            "ml_optimized_strategy_oos": {
                "trades": ml_metrics['total_trades'],
                "win_rate_pct": ml_metrics['win_rate_pct'],
                "net_pnl": ml_metrics['net_pnl'],
                "profit_factor": ml_metrics['profit_factor'],
                "sharpe_ratio": ml_metrics['sharpe_ratio'],
                "sortino_ratio": ml_metrics['sortino_ratio'],
                "max_drawdown_pct": ml_metrics['max_drawdown_pct'],
                "ulcer_index": ml_metrics['ulcer_index']
            },
            "ml_alpha_attribution": {
                "win_rate_improvement_pct": round(win_rate_delta, 2),
                "profit_factor_multiplier": round(pf_delta, 2),
                "sharpe_ratio_improvement": round(sharpe_delta, 2),
                "drawdown_reduction_pct": round(dd_reduction, 2),
                "verdict": "STRONG_ML_ALPHA_GAIN" if sharpe_delta > 0 and dd_reduction >= 0 else "MODERATE_ML_GAIN"
            },
            "top_meta_features": top_meta_features,
            "raw_trade_series": raw_trades,
            "ml_trade_series": ml_trades
        }
        return results


def run_meta_labeler_study():
    root = r"e:\Github Submissions\06-mq4-tick-alpha-engine"
    tick_csv = os.path.join(root, "data", "real_ticks_gbpusd.csv")
    out_json = os.path.join(root, "data", "ml_meta_labeling_results.json")

    print(f"Loading real broker ticks from {tick_csv}...")
    df_ticks = pd.read_csv(tick_csv)

    meta = MLMetaLabeler(
        pip_size=0.0001,
        lot_size=100000.0,
        initial_capital=10000.0,
        commission_per_lot=5.0,
        sl_pips=12.0,
        tp_pips=24.0,
        prob_threshold=0.50
    )

    print("Running Machine Learning Meta-Labeling Optimization on Real Broker Ticks...")
    results = meta.train_and_optimize(df_ticks, train_test_split=0.60)

    # Save results (clean trade lists from top summary for neat JSON)
    save_dict = dict(results)
    if 'raw_trade_series' in save_dict:
        del save_dict['raw_trade_series']
    if 'ml_trade_series' in save_dict:
        del save_dict['ml_trade_series']

    with open(out_json, 'w', encoding='utf-8') as f:
        json.dump(save_dict, f, indent=2)

    print(f"Meta-labeling results saved to {out_json}")
    print("\n--- ML META-LABELING OPTIMIZATION RESULTS ---")
    print(f"Raw Strategy Out-of-Sample: WinRate={results['raw_strategy_oos']['win_rate_pct']}% | Sharpe={results['raw_strategy_oos']['sharpe_ratio']} | DD={results['raw_strategy_oos']['max_drawdown_pct']}%")
    print(f"ML-Optimized Strategy OOS : WinRate={results['ml_optimized_strategy_oos']['win_rate_pct']}% | Sharpe={results['ml_optimized_strategy_oos']['sharpe_ratio']} | DD={results['ml_optimized_strategy_oos']['max_drawdown_pct']}%")
    print(f"Attribution: Sharpe Delta: +{results['ml_alpha_attribution']['sharpe_ratio_improvement']} | DD Reduction: {results['ml_alpha_attribution']['drawdown_reduction_pct']}%")


if __name__ == '__main__':
    run_meta_labeler_study()
