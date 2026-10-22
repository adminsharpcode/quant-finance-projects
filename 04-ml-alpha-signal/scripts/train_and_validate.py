"""
End-to-End Walk-Forward Training and Purged Cross-Validation Engine.

Executes:
1. Multi-asset universe loading from data/cross_sectional_universe.csv
2. Modular factor calculation (Momentum, Volatility, Microstructure)
3. Target calculation (5-day forward return horizon: R_{t -> t+5})
4. Cross-sectional MAD winsorization & Sector/Beta neutralization
5. De Prado's Purged K-Fold Cross-Validation with Embargo (zero leakage)
6. LightGBM & ElasticNet model training & out-of-sample prediction
7. Evaluation: Rank IC, Information Ratio (IC_IR), Quantile Spread, Portfolio Turnover
8. TreeSHAP feature attribution analysis
9. Rich terminal report & JSON metrics serialization
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import numpy as np
import pandas as pd
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

from src.features.price_momentum import (
    compute_reversal,
    compute_dual_momentum,
    compute_residual_momentum,
    compute_macd_spread,
)
from src.features.volatility_estimators import (
    compute_historical_volatility,
    compute_parkinson_volatility,
    compute_garman_klass_volatility,
    compute_yang_zhang_volatility,
    compute_volatility_ratio,
)
from src.features.microstructure import (
    compute_amihud_illiquidity,
    compute_roll_spread,
    compute_corwin_schultz_spread,
    compute_volume_surprise,
)
from src.preprocessing.winsorization import (
    cross_sectional_mad_winsorize,
    cross_sectional_zscore,
)
from src.preprocessing.neutralization import neutralize_cross_section
from src.validation.purged_kfold import PurgedKFold, verify_no_temporal_leakage
from src.models.lightgbm_alpha import LightGBMAlphaModel
from src.models.elasticnet_alpha import ElasticNetAlphaModel
from src.evaluation.information_coefficient import (
    compute_daily_ic,
    compute_ic_metrics,
    compute_quantile_returns,
)
from src.evaluation.factor_turnover import (
    compute_rank_autocorrelation,
    generate_dollar_neutral_weights,
    compute_portfolio_turnover,
    estimate_fee_drag,
)
from src.evaluation.shap_attribution import compute_tree_shap_attributions


def build_feature_store(df: pd.DataFrame) -> Tuple[pd.DataFrame, List[str], str]:
    """
    Extract modular alpha factor features and forward target returns.
    """
    df = df.sort_values(["ticker", "date"]).reset_index(drop=True).copy()
    
    # 1. Momentum & Reversal
    df["f_reversal_5d"] = compute_reversal(df, window=5)
    df["f_dual_momentum"] = compute_dual_momentum(df, lookback_window=60, skip_window=5)
    df["f_residual_momentum"] = compute_residual_momentum(df, window=60, skip_window=5)
    df["f_macd_spread"] = compute_macd_spread(df, fast_span=12, slow_span=26)
    
    # 2. Volatility Estimators
    df["f_vol_parkinson"] = compute_parkinson_volatility(df, window=20)
    df["f_vol_garman_klass"] = compute_garman_klass_volatility(df, window=20)
    df["f_vol_yang_zhang"] = compute_yang_zhang_volatility(df, window=20)
    df["f_vol_ratio"] = compute_volatility_ratio(df, short_window=5, long_window=20)
    
    # 3. Microstructure
    df["f_amihud_illiq"] = compute_amihud_illiquidity(df, window=20)
    df["f_roll_spread"] = compute_roll_spread(df, window=20)
    df["f_volume_surprise"] = compute_volume_surprise(df, short_window=5, long_window=20)
    
    factor_cols = [
        "f_reversal_5d",
        "f_dual_momentum",
        "f_residual_momentum",
        "f_macd_spread",
        "f_vol_parkinson",
        "f_vol_garman_klass",
        "f_vol_yang_zhang",
        "f_vol_ratio",
        "f_amihud_illiq",
        "f_roll_spread",
        "f_volume_surprise",
    ]
    
    # Forward 5-day return target: (Close_{t+5} - Close_t) / Close_t
    target_horizon = 5
    df["forward_5d_ret"] = df.groupby("ticker")["close"].shift(-target_horizon)
    raw_target = (df["forward_5d_ret"] - df["close"]) / df["close"]
    # Cross-sectionally demean target to isolate pure idiosyncratic alpha relative to market
    df["target"] = raw_target - df.groupby("date")[raw_target.name or "raw_ret"].transform("mean") if hasattr(raw_target, "name") and raw_target.name else raw_target - df.assign(_raw_t=raw_target).groupby("date")["_raw_t"].transform("mean")
    
    # Label end time for purging: date + 5 business days
    df["date"] = pd.to_datetime(df["date"])
    df["event_end"] = df["date"] + pd.Timedelta(days=7) # accounts for weekends
    
    # Drop warm-up / edge NaN rows
    valid_mask = df[factor_cols + ["target"]].notna().all(axis=1)
    df_clean = df[valid_mask].copy().reset_index(drop=True)
    
    # Preprocessing: MAD Winsorization
    df_clean = cross_sectional_mad_winsorize(df_clean, factor_cols=factor_cols, date_col="date", n_mads=3.0)
    
    # Preprocessing: Sector & Beta Neutralization
    df_clean = neutralize_cross_section(
        df_clean,
        factor_cols=factor_cols,
        risk_cols=["beta_sp500"],
        sector_col="sector",
        date_col="date",
        re_standardize=True
    )
    
    return df_clean, factor_cols, "target"


def run_purged_walk_forward_training(data_path: Path, output_dir: Path):
    console = Console()
    console.print(Panel.fit("[bold cyan]04-ML-ALPHA-SIGNAL: Marcos López de Prado Purged K-Fold Engine[/bold cyan]", border_style="cyan"))
    
    console.print(f"[dim]Loading universe from: {data_path}[/dim]")
    raw_df = pd.read_csv(data_path)
    
    console.print("[dim]Computing orthogonal alpha factor families & forward targets...[/dim]")
    df_features, factor_cols, target_col = build_feature_store(raw_df)
    
    # Save feature store
    feature_store_path = output_dir / "feature_store.csv"
    df_features.to_csv(feature_store_path, index=False)
    console.print(f"[green]Saved feature store ({len(df_features)} samples, {len(factor_cols)} factors) to: {feature_store_path}[/green]")
    
    # Initialize Purged K-Fold CV
    n_splits = 5
    embargo_pct = 0.02
    pkf = PurgedKFold(n_splits=n_splits, samples_info=df_features["event_end"], embargo_pct=embargo_pct)
    
    df_features["pred_lgbm"] = np.nan
    df_features["pred_elasticnet"] = np.nan
    
    fold_reports = []
    
    console.print(f"\n[bold yellow]Starting {n_splits}-Fold Purged Cross-Validation with {embargo_pct*100:.1f}% Embargo...[/bold yellow]")
    
    for fold, (train_idx, test_idx) in enumerate(pkf.split(df_features, groups=df_features["date"])):
        # Verify zero leakage
        verify_no_temporal_leakage(train_idx, test_idx, df_features["date"], df_features["event_end"])
        
        X_train = df_features.loc[train_idx, factor_cols]
        y_train = df_features.loc[train_idx, target_col]
        X_test = df_features.loc[test_idx, factor_cols]
        y_test = df_features.loc[test_idx, target_col]
        
        # Train LightGBM Alpha Model
        lgbm = LightGBMAlphaModel(n_estimators=100, learning_rate=0.03, max_depth=4, num_leaves=15, loss_type="huber")
        lgbm.fit(X_train, y_train)
        preds_lgbm = lgbm.predict(X_test)
        df_features.loc[test_idx, "pred_lgbm"] = preds_lgbm
        
        # Train ElasticNet Alpha Model
        enet = ElasticNetAlphaModel(alpha=0.0001, l1_ratio=0.5)
        enet.fit(X_train, y_train)
        preds_enet = enet.predict(X_test)
        df_features.loc[test_idx, "pred_elasticnet"] = preds_enet
        
        # Fold Rank IC
        test_sub = df_features.loc[test_idx, ["date", "pred_lgbm", "target"]].copy()
        ic_fold = compute_daily_ic(test_sub, pred_col="pred_lgbm", target_col="target")
        mean_ic_fold = float(ic_fold.mean())
        
        fold_reports.append({
            "fold": fold + 1,
            "train_samples": len(train_idx),
            "test_samples": len(test_idx),
            "mean_rank_ic": mean_ic_fold,
            "test_start": str(df_features.loc[test_idx, "date"].min().strftime("%Y-%m-%d")),
            "test_end": str(df_features.loc[test_idx, "date"].max().strftime("%Y-%m-%d")),
        })
        
        console.print(f"  Fold {fold+1}/{n_splits}: Train={len(train_idx):4d} | Test={len(test_idx):4d} | Purged Out-of-Sample Rank IC = [bold green]{mean_ic_fold:+.4f}[/bold green]")
        
    # Full out-of-sample evaluation
    df_eval = df_features.dropna(subset=["pred_lgbm", "pred_elasticnet", "target"]).copy()
    
    # 1. Rank IC Metrics
    ic_series_lgbm = compute_daily_ic(df_eval, pred_col="pred_lgbm", target_col="target")
    ic_metrics_lgbm = compute_ic_metrics(ic_series_lgbm)
    
    ic_series_enet = compute_daily_ic(df_eval, pred_col="pred_elasticnet", target_col="target")
    ic_metrics_enet = compute_ic_metrics(ic_series_enet)
    
    # 2. Quantile Returns (Quintiles Q1...Q5)
    q_rets, q_summary = compute_quantile_returns(df_eval, pred_col="pred_lgbm", target_col="target", n_quantiles=5)
    
    # 3. Portfolio Weights & Turnover
    weights_df = generate_dollar_neutral_weights(df_eval, alpha_col="pred_lgbm", top_pct=0.25, bottom_pct=0.25)
    turnover_series = compute_portfolio_turnover(weights_df)
    fee_drag = estimate_fee_drag(turnover_series, cost_per_turn_bps=5.0)
    
    # 4. Rank Autocorrelation Decay Curve
    autocorr_decay = compute_rank_autocorrelation(df_eval, factor_col="pred_lgbm", lags=[1, 2, 5, 10, 20])
    
    # 5. TreeSHAP Global Feature Attributions
    # Retrain on full sample to extract global attributions
    final_model = LightGBMAlphaModel(n_estimators=100, learning_rate=0.03, max_depth=4)
    final_model.fit(df_eval[factor_cols], df_eval[target_col])
    _, mean_shap = compute_tree_shap_attributions(final_model, df_eval[factor_cols], max_samples=800)
    
    # Render Tables
    table_folds = Table(title="Purged K-Fold Cross-Validation Protocol (Zero Leakage)")
    table_folds.add_column("Fold", justify="center")
    table_folds.add_column("Test Date Window", justify="center")
    table_folds.add_column("Train Samples", justify="right")
    table_folds.add_column("Test Samples", justify="right")
    table_folds.add_column("Rank IC", justify="right")
    for r in fold_reports:
        table_folds.add_row(str(r["fold"]), f"{r['test_start']} to {r['test_end']}", str(r["train_samples"]), str(r["test_samples"]), f"{r['mean_rank_ic']:+.4f}")
    console.print(table_folds)
    
    table_metrics = Table(title="Institutional Performance Summary: LightGBM vs ElasticNet")
    table_metrics.add_column("Performance Metric", justify="left")
    table_metrics.add_column("LightGBM Alpha", justify="right", style="cyan")
    table_metrics.add_column("ElasticNet Alpha", justify="right", style="magenta")
    table_metrics.add_column("Institutional Target", justify="center", style="dim")
    
    table_metrics.add_row("Mean Spearman Rank IC", f"{ic_metrics_lgbm['mean_ic']:+.4f}", f"{ic_metrics_enet['mean_ic']:+.4f}", "> +0.050")
    table_metrics.add_row("Information Ratio (IC_IR)", f"{ic_metrics_lgbm['ic_ir']:.2f}", f"{ic_metrics_enet['ic_ir']:.2f}", "> 1.00")
    table_metrics.add_row("IC T-Statistic (p-val)", f"{ic_metrics_lgbm['t_stat']:.2f} ({ic_metrics_lgbm['p_value']:.3e})", f"{ic_metrics_enet['t_stat']:.2f}", "> 2.00 (p < 0.05)")
    table_metrics.add_row("Daily Alpha Hit Rate", f"{ic_metrics_lgbm['hit_rate']*100:.1f}%", f"{ic_metrics_enet['hit_rate']*100:.1f}%", "> 52.0%")
    table_metrics.add_row("Annualized Long-Short Return", f"{q_summary['ls_mean_annualized']*100:.2f}%", "--", "> 15.0%")
    table_metrics.add_row("Long-Short Sharpe Ratio", f"{q_summary['ls_sharpe']:.2f}", "--", "> 1.50")
    table_metrics.add_row("Mean Daily Portfolio Turnover", f"{fee_drag['mean_daily_turnover']*100:.2f}%", "--", "< 30.0%")
    table_metrics.add_row("Annual Transaction Cost Drag", f"{fee_drag['annual_fee_drag_pct']:.2f}%", "--", "< 4.0%")
    console.print(table_metrics)
    
    table_shap = Table(title="TreeSHAP Global Factor Attribution Ranking")
    table_shap.add_column("Rank", justify="center")
    table_shap.add_column("Factor Identifier", justify="left")
    table_shap.add_column("Mean |SHAP| Value", justify="right", style="green")
    for idx, (f_name, shap_val) in enumerate(mean_shap.items()):
        table_shap.add_row(str(idx + 1), f_name, f"{shap_val:.5f}")
    console.print(table_shap)
    
    # Save artifacts to JSON for web dashboard
    metrics_export = {
        "summary": {
            "mean_rank_ic": round(ic_metrics_lgbm["mean_ic"], 4),
            "ic_ir": round(ic_metrics_lgbm["ic_ir"], 2),
            "t_stat": round(ic_metrics_lgbm["t_stat"], 2),
            "p_value": float(f"{ic_metrics_lgbm['p_value']:.4e}"),
            "hit_rate": round(ic_metrics_lgbm["hit_rate"] * 100, 1),
            "ls_annual_return": round(q_summary["ls_mean_annualized"] * 100, 2),
            "ls_sharpe": round(q_summary["ls_sharpe"], 2),
            "mean_daily_turnover": round(fee_drag["mean_daily_turnover"] * 100, 2),
            "annual_fee_drag": round(fee_drag["annual_fee_drag_pct"], 2),
            "n_folds": n_splits,
            "embargo_pct": embargo_pct,
        },
        "folds": fold_reports,
        "shap_attributions": {k: round(float(v), 5) for k, v in mean_shap.items()},
        "autocorr_decay": {str(k): round(float(v), 4) for k, v in autocorr_decay.items()},
        "quantile_returns": {k: round(float(v) * 252.0 * 100, 2) for k, v in q_summary["mean_returns_by_quantile"].items()},
        "daily_ic_history": [
            {"date": d.strftime("%Y-%m-%d"), "ic": round(float(v), 4)}
            for d, v in ic_series_lgbm.dropna().items()
        ][-60:], # recent 60 trading days for visualization
    }
    
    metrics_path = output_dir / "tearsheet_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(metrics_export, f, indent=2)
    console.print(f"\n[bold green]Successfully saved institutional tearsheet metrics to: {metrics_path}[/bold green]")
    return metrics_export


if __name__ == "__main__":
    base_dir = Path("e:/Github Submissions/04-ml-alpha-signal")
    data_file = base_dir / "data" / "cross_sectional_universe.csv"
    data_dir = base_dir / "data"
    run_purged_walk_forward_training(data_file, data_dir)
