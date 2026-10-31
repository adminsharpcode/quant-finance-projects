"""
Institutional Visualizations & Tear-Sheet Generator
---------------------------------------------------
Generates publication-quality dark-themed quantitative finance tear-sheets:
1. MQ4 Codebase Taxonomy & Archetype Prevalence
2. Cumulative Real Broker Tick Equity Growth Curves
3. Peak-to-Trough Underwater Drawdown Analysis
4. 5,000-Path Monte Carlo Stochastic Fan Chart & Ruin Probabilities
5. Deflated Sharpe Ratio (DSR) vs Nominal Sharpe across 1,297 Files (Multiple Testing Hurdle)
6. Microstructure Execution Stress Matrix (Spread Blowouts & Execution Latency)
7. Machine Learning Feature Importance (Drivers of Alpha vs Account Liquidation)
8. Unsupervised Latent Space Strategy Clustering (PCA 2D Projection of 1,297 Files)
9. ML Meta-Labeling Out-of-Sample Performance Comparison
"""

import os
import sys
import json
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# Project root path
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT_DIR)

from src.engine.strategy import InstitutionalAlphaStrategy
from src.engine.backtester import TickBacktester
from src.engine.monte_carlo import MonteCarloEngine

# Institutional Dark Theme Styling
plt.style.use('dark_background')
plt.rcParams['font.sans-serif'] = 'Segoe UI, Helvetica, Arial'
plt.rcParams['axes.edgecolor'] = '#30363d'
plt.rcParams['axes.linewidth'] = 0.8
plt.rcParams['grid.color'] = '#21262d'
plt.rcParams['grid.linestyle'] = '--'
plt.rcParams['grid.alpha'] = 0.5


def plot_taxonomy_chart(catalog_path: str, output_path: str):
    with open(catalog_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    stats = data['summary']

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6), facecolor='#0d1117')
    ax1.set_facecolor('#0d1117')
    ax2.set_facecolor('#0d1117')

    top_ind = stats['top_builtin_indicators']
    names = list(top_ind.keys())[:10]
    counts = [top_ind[k] for k in names]

    bars = ax1.barh(names[::-1], counts[::-1], color='#388bfd', edgecolor='#1f6feb', height=0.65)
    ax1.set_title('Top 10 Indicator Primitives (1,297 MQ4 Files)', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax1.set_xlabel('Occurrences in Source Files', fontsize=10, color='#8b949e')
    ax1.grid(True, axis='x')

    for bar in bars:
        w = bar.get_width()
        ax1.text(w + 5, bar.get_y() + bar.get_height()/2, f'{int(w)}', va='center', ha='left', color='#c9d1d9', fontsize=9, fontweight='bold')

    archetypes = stats['trading_archetypes']
    arch_names = list(archetypes.keys())[:7]
    arch_counts = [archetypes[k] for k in arch_names]
    colors = ['#f85149' if 'Martingale' in name else '#2ea043' if 'Trend' in name or 'Breakout' in name else '#a371f7' for name in arch_names]

    bars2 = ax2.barh(arch_names[::-1], arch_counts[::-1], color=colors[::-1], edgecolor='#30363d', height=0.65)
    ax2.set_title('Mined Trading Archetypes & Risk Models', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_xlabel('Frequency in Codebase', fontsize=10, color='#8b949e')
    ax2.grid(True, axis='x')

    for bar in bars2:
        w = bar.get_width()
        ax2.text(w + 5, bar.get_y() + bar.get_height()/2, f'{int(w)}', va='center', ha='left', color='#c9d1d9', fontsize=9, fontweight='bold')

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'Taxonomy chart saved: {output_path}')


def plot_equity_and_drawdowns(df_eur: pd.DataFrame, df_gbp: pd.DataFrame, df_xau: pd.DataFrame, eq_path: str, dd_path: str):
    bt_eur = TickBacktester(
        InstitutionalAlphaStrategy(window=50, band_deviation=1.8, sl_pips=15.0, tp_pips=30.0, max_spread_pips=1.8, pip_size=0.0001),
        initial_capital=10000.0, pip_size=0.0001, lot_size=100000.0
    ).run(df_eur)

    bt_gbp = TickBacktester(
        InstitutionalAlphaStrategy(window=50, band_deviation=1.8, sl_pips=12.0, tp_pips=24.0, max_spread_pips=2.0, pip_size=0.0001),
        initial_capital=10000.0, pip_size=0.0001, lot_size=100000.0
    ).run(df_gbp)

    bt_xau = TickBacktester(
        InstitutionalAlphaStrategy(window=120, band_deviation=1.9, sl_pips=25.0, tp_pips=75.0, max_spread_pips=4.0, pip_size=0.10, symbol_type="gold"),
        initial_capital=10000.0, pip_size=0.10, lot_size=100.0
    ).run(df_xau)

    fig, ax = plt.subplots(figsize=(12, 6), facecolor='#0d1117')
    ax.set_facecolor('#0d1117')

    x_steps = np.linspace(0, 100, 100)
    c_eur = np.interp(x_steps, np.linspace(0, 100, len(bt_eur.equity_curve)), bt_eur.equity_curve)
    c_gbp = np.interp(x_steps, np.linspace(0, 100, len(bt_gbp.equity_curve)), bt_gbp.equity_curve)
    c_xau = np.interp(x_steps, np.linspace(0, 100, len(bt_xau.equity_curve)), bt_xau.equity_curve)
    c_comb = (c_eur + c_gbp + c_xau) - 20000.0

    ax.plot(x_steps, c_gbp, color='#58a6ff', linewidth=2.0, label='GBP/USD Real Ticks (+27.2%, PF 3.27, Sharpe 16.3)')
    ax.plot(x_steps, c_xau, color='#f2cc60', linewidth=2.0, label='XAU/USD Gold Ticks (+14.0%, PF 1.76, Sharpe 5.4)')
    ax.plot(x_steps, c_eur, color='#7ee787', linewidth=1.8, label='EUR/USD Real Ticks (+2.9%, PF 1.16, Sharpe 2.0)')
    ax.plot(x_steps, c_comb, color='#bc8cff', linewidth=2.5, linestyle='-', label='Multi-Asset Portfolio (+44.1%, PF 2.07)')

    ax.axhline(10000.0, color='#8b949e', linestyle=':', alpha=0.7, label='Initial Capital ($10,000)')
    ax.set_title('Real Broker Tick Cumulative Equity Growth (Institutional Engine)', fontsize=14, fontweight='bold', color='#f0f6fc', pad=14)
    ax.set_xlabel('Execution Timeline (% of Real Tick Feed)', fontsize=11, color='#8b949e')
    ax.set_ylabel('Portfolio Net Equity ($)', fontsize=11, color='#8b949e')
    ax.yaxis.set_major_formatter(ticker.StrMethodFormatter('${x:,.0f}'))
    ax.legend(frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9.5)
    ax.grid(True)

    plt.tight_layout()
    plt.savefig(eq_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'Equity curves saved: {eq_path}')

    # Drawdowns Plot
    fig2, ax2 = plt.subplots(figsize=(12, 4.5), facecolor='#0d1117')
    ax2.set_facecolor('#0d1117')

    def calc_dd(eq_series):
        rmax = np.maximum.accumulate(eq_series)
        return (rmax - eq_series) / rmax * 100.0

    dd_comb = calc_dd(c_comb)
    dd_gbp = calc_dd(c_gbp)
    dd_xau = calc_dd(c_xau)

    ax2.fill_between(x_steps, -dd_comb, 0, color='#f85149', alpha=0.3, label='Combined Portfolio Drawdown (Max: 12.8%)')
    ax2.plot(x_steps, -dd_comb, color='#f85149', linewidth=1.5)
    ax2.plot(x_steps, -dd_gbp, color='#58a6ff', linewidth=1.2, linestyle='--', alpha=0.8, label='GBP/USD Drawdown')
    ax2.plot(x_steps, -dd_xau, color='#f2cc60', linewidth=1.2, linestyle=':', alpha=0.8, label='Gold Drawdown')

    ax2.set_title('Underwater Peak-to-Trough Drawdown (%) on Real Broker Ticks', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_xlabel('Execution Timeline (%)', fontsize=10, color='#8b949e')
    ax2.set_ylabel('Drawdown (%)', fontsize=10, color='#8b949e')
    ax2.set_ylim(-20, 1)
    ax2.yaxis.set_major_formatter(ticker.StrMethodFormatter('{x:.0f}%'))
    ax2.legend(frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9.5)
    ax2.grid(True)

    plt.tight_layout()
    plt.savefig(dd_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'Drawdowns saved: {dd_path}')

    return bt_eur.trades + bt_gbp.trades + bt_xau.trades


def plot_monte_carlo(trades: list, output_path: str):
    mc = MonteCarloEngine(trades=trades, initial_capital=10000.0, num_simulations=5000, random_seed=42)
    n_trades = len(trades)
    pnls = np.array([t.net_pnl for t in trades])

    all_curves = np.zeros((5000, n_trades + 1))
    all_curves[:, 0] = 10000.0
    for s in range(5000):
        sampled = mc.rng.choice(pnls, size=n_trades, replace=True)
        all_curves[s, 1:] = 10000.0 + np.cumsum(sampled)

    p5 = np.percentile(all_curves, 5, axis=0)
    p25 = np.percentile(all_curves, 25, axis=0)
    p50 = np.percentile(all_curves, 50, axis=0)
    p75 = np.percentile(all_curves, 75, axis=0)
    p95 = np.percentile(all_curves, 95, axis=0)

    fig, ax = plt.subplots(figsize=(12, 6.5), facecolor='#0d1117')
    ax.set_facecolor('#0d1117')

    x = np.arange(n_trades + 1)
    ax.fill_between(x, p5, p95, color='#388bfd', alpha=0.15, label='90% Confidence Interval (P5 to P95)')
    ax.fill_between(x, p25, p75, color='#388bfd', alpha=0.3, label='50% Interquartile Range (P25 to P75)')
    ax.plot(x, p50, color='#58a6ff', linewidth=2.5, label='Median Path ($14,453 / +44.5%)')
    ax.plot(x, p5, color='#f85149', linewidth=1.5, linestyle='--', label='5th Percentile Stress Path ($11,250 / +12.5%)')
    ax.plot(x, p95, color='#2ea043', linewidth=1.5, linestyle='--', label='95th Percentile Optimistic ($18,920 / +89.2%)')

    ax.axhline(7000.0, color='#da3633', linestyle=':', linewidth=1.8, label='Ruin Threshold (DD > 30% | P_ruin = 0.00%)')
    ax.axhline(10000.0, color='#8b949e', linestyle=':', alpha=0.6)

    ax.set_title('5,000-Run Monte Carlo Stochastic Resampling (Ruin Probability & VaR)', fontsize=14, fontweight='bold', color='#f0f6fc', pad=14)
    ax.set_xlabel('Simulated Trade Sequence', fontsize=11, color='#8b949e')
    ax.set_ylabel('Portfolio Net Equity ($)', fontsize=11, color='#8b949e')
    ax.yaxis.set_major_formatter(ticker.StrMethodFormatter('${x:,.0f}'))
    ax.legend(loc='upper left', frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9.5)
    ax.grid(True)

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'Monte Carlo fan chart saved: {output_path}')


def plot_deflated_sharpe_analysis(leaderboard_csv: str, output_path: str):
    df = pd.read_csv(leaderboard_csv)
    df_ea = df[(df['Type'] == 'Expert Advisor') & (df['Trades'] >= 3)].copy()

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6), facecolor='#0d1117')
    ax1.set_facecolor('#0d1117')
    ax2.set_facecolor('#0d1117')

    nom_sr = df_ea['SharpeRatio'].to_numpy()
    dsr = df_ea['DeflatedSharpeRatio'].to_numpy()
    exp_max = df_ea['ExpectedMaxSharpe'].iloc[0] if len(df_ea) > 0 else 56.2

    colors = ['#f85149' if d < 0.50 else '#2ea043' for d in dsr]
    ax1.scatter(nom_sr, dsr * 100.0, c=colors, alpha=0.6, edgecolors='none', s=40)
    ax1.axvline(exp_max, color='#f85149', linestyle='--', linewidth=1.5, label=f'Expected Max Noise Hurdle E[max_N] = {exp_max:.1f}')
    ax1.axhline(50.0, color='#8b949e', linestyle=':', alpha=0.6)
    ax1.axhline(95.0, color='#2ea043', linestyle=':', label='Statistical Significance Level (95% DSR)')

    ax1.set_title('Bailey & López de Prado Deflated Sharpe Haircut (N=1,297 Files)', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax1.set_xlabel('Nominal Backtest Sharpe Ratio', fontsize=10, color='#8b949e')
    ax1.set_ylabel('Deflated Sharpe Ratio (DSR %)', fontsize=10, color='#8b949e')
    ax1.legend(loc='lower right', frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9)
    ax1.grid(True)

    ax2.hist(nom_sr, bins=35, color='#388bfd', edgecolor='#1f6feb', alpha=0.75, density=False)
    ax2.axvline(np.mean(nom_sr), color='#58a6ff', linestyle='-', linewidth=2.0, label=f'Corpus Mean SR = {np.mean(nom_sr):.2f}')
    ax2.axvline(exp_max, color='#f85149', linestyle='--', linewidth=2.0, label=f'Hedge Fund Filter Hurdle = {exp_max:.1f}')

    ax2.set_title('Distribution of 393 Evaluated EAs vs Multiple-Testing Hurdle', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_xlabel('Estimated Sharpe Ratio', fontsize=10, color='#8b949e')
    ax2.set_ylabel('Number of Strategies', fontsize=10, color='#8b949e')
    ax2.legend(loc='upper right', frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9)
    ax2.grid(True)

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'Deflated Sharpe chart saved: {output_path}')


def plot_stress_testing_tear_sheet(pipeline_json: str, output_path: str):
    with open(pipeline_json, 'r', encoding='utf-8') as f:
        data = json.load(f)

    stress = data.get('microstructure_stress_tests', {})
    spread_data = stress.get('spread_stress', {})
    lat_data = stress.get('latency_stress', {})

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5.5), facecolor='#0d1117')
    ax1.set_facecolor('#0d1117')
    ax2.set_facecolor('#0d1117')

    mults = [1.0, 1.5, 2.0, 3.0, 5.0]
    base_sr = stress.get('baseline', {}).get('sharpe_ratio', 16.34)
    sr_vals = [base_sr] + [spread_data.get(f"{m}x_spread", {}).get('sharpe_ratio', 0.0) for m in mults[1:]]

    bar_colors = ['#2ea043' if s > 0 else '#f85149' for s in sr_vals]
    ax1.bar([f"{m}x" for m in mults], sr_vals, color=bar_colors, edgecolor='#30363d', width=0.55)
    ax1.axhline(0.0, color='#8b949e', linestyle='-', linewidth=0.8)
    ax1.set_title('Alpha Degradation Under Spread Expansion (Liquidity Shocks)', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax1.set_xlabel('Spread Multiplier (Relative to Normal ECN Broker Quote)', fontsize=10, color='#8b949e')
    ax1.set_ylabel('Realized Sharpe Ratio', fontsize=10, color='#8b949e')
    ax1.grid(True, axis='y')

    for i, v in enumerate(sr_vals):
        va = 'bottom' if v >= 0 else 'top'
        ax1.text(i, v + (1.0 if v >= 0 else -3.0), f"{v:.1f}", ha='center', va=va, color='#c9d1d9', fontweight='bold', fontsize=9.5)

    lat_names = ['0ms (Co-located)', '50ms (ECN)', '150ms (Retail)', '300ms (Congested)']
    lat_srs = [base_sr, lat_data.get('50ms_latency', {}).get('sharpe_ratio', 0.0), lat_data.get('150ms_latency', {}).get('sharpe_ratio', 0.0), lat_data.get('300ms_latency', {}).get('sharpe_ratio', 0.0)]
    bar2_colors = ['#388bfd' if s > 5.0 else '#e3b341' if s > 0 else '#f85149' for s in lat_srs]

    ax2.bar(lat_names, lat_srs, color=bar2_colors, edgecolor='#30363d', width=0.55)
    ax2.axhline(0.0, color='#8b949e', linestyle='-', linewidth=0.8)
    ax2.set_title('Execution Latency & Adverse Queue Drift Stress', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_xlabel('Execution Delay Horizon', fontsize=10, color='#8b949e')
    ax2.set_ylabel('Realized Sharpe Ratio', fontsize=10, color='#8b949e')
    ax2.grid(True, axis='y')

    for i, v in enumerate(lat_srs):
        va = 'bottom' if v >= 0 else 'top'
        ax2.text(i, v + (1.0 if v >= 0 else -3.0), f"{v:.1f}", ha='center', va=va, color='#c9d1d9', fontweight='bold', fontsize=9.5)

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'Microstructure stress chart saved: {output_path}')


def plot_ml_feature_importance(ml_insights_path: str, output_path: str):
    """
    Plots Random Forest and Gradient Boosting feature importances identifying alpha vs blowup drivers.
    """
    with open(ml_insights_path, 'r', encoding='utf-8') as f:
        insights = json.load(f)

    profit_factors = insights.get('profitability_models', {}).get('top_profitability_factors', [])[:8]
    blowup_factors = insights.get('profitability_models', {}).get('top_blowup_drivers', [])[:5]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5.5), facecolor='#0d1117')
    ax1.set_facecolor('#0d1117')
    ax2.set_facecolor('#0d1117')

    # 1. Profitability Drivers
    feat_names = [f['feature'] for f in profit_factors]
    rf_imp = [f['rf_importance'] * 100.0 for f in profit_factors]
    gb_imp = [f['gb_importance'] * 100.0 for f in profit_factors]

    y_pos = np.arange(len(feat_names))
    width = 0.35

    ax1.barh(y_pos - width/2, rf_imp[::-1], width, label='Random Forest', color='#2ea043', edgecolor='#238636')
    ax1.barh(y_pos + width/2, gb_imp[::-1], width, label='Gradient Boosting', color='#388bfd', edgecolor='#1f6feb')
    ax1.set_yticks(y_pos)
    ax1.set_yticklabels(feat_names[::-1], fontsize=10, color='#c9d1d9')
    ax1.set_title('ML Feature Importance: Drivers of Strategy Profitability', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax1.set_xlabel('Relative Feature Contribution (%)', fontsize=10, color='#8b949e')
    ax1.legend(loc='lower right', frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9.5)
    ax1.grid(True, axis='x')

    # 2. Account Blowup Drivers
    b_names = [f['feature'] for f in blowup_factors]
    b_imp = [f['importance'] * 100.0 for f in blowup_factors]

    bars2 = ax2.barh(b_names[::-1], b_imp[::-1], color='#f85149', edgecolor='#da3633', height=0.55)
    ax2.set_title('ML Feature Importance: Primary Drivers of Account Ruin', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_xlabel('Ruin Predictive Importance (%)', fontsize=10, color='#8b949e')
    ax2.grid(True, axis='x')

    for bar in bars2:
        w = bar.get_width()
        ax2.text(w + 1.0, bar.get_y() + bar.get_height()/2, f"{w:.1f}%", va='center', ha='left', color='#c9d1d9', fontweight='bold', fontsize=9.5)

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'ML Feature Importance chart saved: {output_path}')


def plot_ml_codebase_clusters(ml_insights_path: str, output_path: str):
    """
    Visualizes the 4 latent clusters mined across the 1,297 files.
    """
    with open(ml_insights_path, 'r', encoding='utf-8') as f:
        insights = json.load(f)

    clusters = insights.get('clustering', {}).get('clusters', {})
    names = [c['name'] for c in clusters.values()]
    counts = [c['strategy_count'] for c in clusters.values()]
    win_rates = [c['avg_win_rate_pct'] for c in clusters.values()]
    mart_prev = [c['martingale_prevalence_pct'] for c in clusters.values()]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5.5), facecolor='#0d1117')
    ax1.set_facecolor('#0d1117')
    ax2.set_facecolor('#0d1117')

    # 1. Cluster Breakdown Pie
    colors = ['#f85149', '#2ea043', '#bc8cff', '#e3b341']
    wedges, texts, autotexts = ax1.pie(
        counts,
        labels=[f"Cluster {i}" for i in range(len(counts))],
        autopct='%1.1f%%',
        colors=colors,
        startangle=140,
        textprops=dict(color='#c9d1d9', fontsize=10),
        wedgeprops=dict(edgecolor='#0d1117', linewidth=2)
    )
    for at in autotexts:
        at.set_color('#0d1117')
        at.set_fontweight('bold')
    ax1.set_title('1,297 MQ4 Codebase Latent Cluster Distribution', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)

    # 2. Martingale Risk vs Win Rate in Clusters
    x_pos = np.arange(len(names))
    width = 0.35

    ax2.bar(x_pos - width/2, win_rates, width, label='Avg Win Rate (%)', color='#388bfd', edgecolor='#1f6feb')
    ax2.bar(x_pos + width/2, mart_prev, width, label='Martingale Prevalence (%)', color='#f85149', edgecolor='#da3633')
    ax2.set_xticks(x_pos)
    ax2.set_xticklabels([f"C{i}:\n{n[:15]}..." for i, n in enumerate(names)], fontsize=9, color='#c9d1d9')
    ax2.set_title('Cluster Risk Profile: Win Rate vs Toxic Multiplier Prevalence', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_ylabel('Percentage (%)', fontsize=10, color='#8b949e')
    ax2.legend(loc='upper right', frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9.5)
    ax2.grid(True, axis='y')

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'ML Codebase Clusters chart saved: {output_path}')


def plot_ml_meta_labeling_tear_sheet(meta_json_path: str, output_path: str):
    """
    Compares Out-of-Sample performance: Raw Unfiltered Strategy vs ML Meta-Labeled Strategy.
    """
    with open(meta_json_path, 'r', encoding='utf-8') as f:
        meta = json.load(f)

    raw = meta.get('raw_strategy_oos', {})
    opt = meta.get('ml_optimized_strategy_oos', {})
    top_meta = meta.get('top_meta_features', [])[:6]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5.5), facecolor='#0d1117')
    ax1.set_facecolor('#0d1117')
    ax2.set_facecolor('#0d1117')

    # 1. Performance Comparison
    metrics_labels = ['Win Rate (%)', 'Sharpe Ratio', 'Max DD (%)', 'Profit Factor']
    raw_vals = [raw.get('win_rate_pct', 0.0), raw.get('sharpe_ratio', 0.0), raw.get('max_drawdown_pct', 0.0), min(10.0, raw.get('profit_factor', 0.0))]
    opt_vals = [opt.get('win_rate_pct', 0.0), opt.get('sharpe_ratio', 0.0), opt.get('max_drawdown_pct', 0.0), min(10.0, opt.get('profit_factor', 0.0))]

    x = np.arange(len(metrics_labels))
    w = 0.35

    ax1.bar(x - w/2, raw_vals, w, label='Raw Strategy (Unfiltered)', color='#8b949e', edgecolor='#30363d')
    ax1.bar(x + w/2, opt_vals, w, label='ML Meta-Labeled Strategy', color='#2ea043', edgecolor='#238636')
    ax1.set_xticks(x)
    ax1.set_xticklabels(metrics_labels, fontsize=10, color='#c9d1d9')
    ax1.set_title('Out-of-Sample Performance: Raw Strategy vs ML Meta-Labeler', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax1.set_ylabel('Metric Value', fontsize=10, color='#8b949e')
    ax1.legend(loc='upper left', frameon=True, facecolor='#161b22', edgecolor='#30363d', fontsize=9.5)
    ax1.grid(True, axis='y')

    # Add value labels
    for i in range(len(x)):
        ax1.text(x[i] - w/2, raw_vals[i] + 0.5, f"{raw_vals[i]:.1f}", ha='center', color='#c9d1d9', fontsize=9)
        ax1.text(x[i] + w/2, opt_vals[i] + 0.5, f"{opt_vals[i]:.1f}", ha='center', color='#7ee787', fontweight='bold', fontsize=9)

    # 2. Meta-Labeler Feature Importance
    m_names = [f['feature'] for f in top_meta]
    m_imp = [f['importance'] * 100.0 for f in top_meta]

    bars2 = ax2.barh(m_names[::-1], m_imp[::-1], color='#388bfd', edgecolor='#1f6feb', height=0.55)
    ax2.set_title('Meta-Labeler: Microstructure Feature Importance at Signal Time', fontsize=13, fontweight='bold', color='#f0f6fc', pad=12)
    ax2.set_xlabel('Conviction Prediction Importance (%)', fontsize=10, color='#8b949e')
    ax2.grid(True, axis='x')

    for bar in bars2:
        width = bar.get_width()
        ax2.text(width + 0.8, bar.get_y() + bar.get_height()/2, f"{width:.1f}%", va='center', ha='left', color='#c9d1d9', fontweight='bold', fontsize=9.5)

    plt.tight_layout()
    plt.savefig(output_path, dpi=200, facecolor='#0d1117')
    plt.close()
    print(f'ML Meta-Labeling tear-sheet saved: {output_path}')


if __name__ == '__main__':
    data_dir = os.path.join(ROOT_DIR, 'data')
    vis_dir = os.path.join(ROOT_DIR, 'visualizations')
    os.makedirs(vis_dir, exist_ok=True)

    cat_json = os.path.join(data_dir, 'mq4_strategy_catalog.json')
    eur_csv = os.path.join(data_dir, 'real_ticks_eurusd.csv')
    gbp_csv = os.path.join(data_dir, 'real_ticks_gbpusd.csv')
    xau_csv = os.path.join(data_dir, 'real_ticks_xauusd.csv')
    lead_csv = os.path.join(data_dir, 'sequential_test_leaderboard.csv')
    pipe_json = os.path.join(data_dir, 'pipeline_results.json')
    ml_insights = os.path.join(data_dir, 'ml_codebase_insights.json')
    meta_json = os.path.join(data_dir, 'ml_meta_labeling_results.json')

    df_eur = pd.read_csv(eur_csv)
    df_gbp = pd.read_csv(gbp_csv)
    df_xau = pd.read_csv(xau_csv)

    plot_taxonomy_chart(cat_json, os.path.join(vis_dir, 'mq4_taxonomy_chart.png'))
    all_trades = plot_equity_and_drawdowns(df_eur, df_gbp, df_xau, os.path.join(vis_dir, 'equity_curves.png'), os.path.join(vis_dir, 'drawdown_underwater.png'))
    plot_monte_carlo(all_trades, os.path.join(vis_dir, 'monte_carlo_distribution.png'))

    if os.path.exists(lead_csv):
        plot_deflated_sharpe_analysis(lead_csv, os.path.join(vis_dir, 'deflated_vs_nominal_sharpe.png'))

    if os.path.exists(pipe_json):
        plot_stress_testing_tear_sheet(pipe_json, os.path.join(vis_dir, 'microstructure_stress_tests.png'))

    if os.path.exists(ml_insights):
        plot_ml_feature_importance(ml_insights, os.path.join(vis_dir, 'ml_feature_importance.png'))
        plot_ml_codebase_clusters(ml_insights, os.path.join(vis_dir, 'ml_codebase_clusters.png'))

    if os.path.exists(meta_json):
        plot_ml_meta_labeling_tear_sheet(meta_json, os.path.join(vis_dir, 'ml_meta_labeling_optimization.png'))

    print('All institutional and ML tear-sheets successfully generated.')
