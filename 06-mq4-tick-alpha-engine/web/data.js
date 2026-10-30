// Auto-generated quantitative data bundle for web dashboard
const MQ4_SUMMARY = {
  "total_files_analyzed": 1297,
  "file_type_breakdown": {
    "Custom Indicator": 550,
    "Utility / Indicator Helper": 267,
    "Expert Advisor": 475,
    "Script": 5
  },
  "top_builtin_indicators": {
    "iMA": 368,
    "iATR": 152,
    "iRSI": 149,
    "iMACD": 58,
    "iStochastic": 51,
    "iCCI": 41,
    "iBands": 36,
    "iSAR": 27,
    "iADX": 25,
    "iVolume": 23,
    "iEnvelopes": 22,
    "iWPR": 15,
    "iStdDev": 13,
    "iBearsPower": 13,
    "iBullsPower": 12,
    "iMomentum": 11,
    "iFractals": 10,
    "iRVI": 7,
    "iDeMarker": 6,
    "iIchimoku": 5
  },
  "trading_archetypes": {
    "Channel / High-Low Breakout": 491,
    "Moving Average / Trend Following": 444,
    "Oscillator / Mean Reversion": 187,
    "ATR Dynamic Volatility": 178,
    "Martingale / Grid Cost-Averaging": 165,
    "Pivot / Structural Support-Resistance": 160,
    "MACD Momentum": 58,
    "Volatility Bands Breakout/Mean Reversion": 49
  },
  "risk_mechanisms": {
    "Fixed Take Profit": 752,
    "Hard Stop Loss": 484,
    "Trailing Stop": 289,
    "Dynamic Capital/Equity Sizing": 210,
    "Time-of-Day / Session Filter": 188,
    "Martingale / Multiplier Scaling (High Blowup Risk)": 165
  },
  "ea_statistics": {
    "total_expert_advisors": 475,
    "with_stop_loss": 442,
    "pct_with_stop_loss": 93.05,
    "with_take_profit": 444,
    "pct_with_take_profit": 93.47,
    "with_trailing_stop": 276,
    "pct_with_trailing_stop": 58.11,
    "martingale_or_grid_count": 134,
    "pct_martingale_or_grid": 28.21
  }
};

const PIPELINE_RESULTS = {
  "optimization": {
    "total_evaluated": 54,
    "best_model": {
      "params": {
        "window": 50,
        "band_deviation": 1.8,
        "sl_pips": 15.0,
        "tp_pips": 30.0,
        "max_spread_pips": 1.8
      },
      "in_sample": {
        "return_pct": 16.26,
        "sharpe_ratio": 40.99,
        "profit_factor": 293.09,
        "max_drawdown_pct": 0.77,
        "total_trades": 3
      },
      "out_of_sample": {
        "return_pct": -11.73,
        "sharpe_ratio": -15.72,
        "profit_factor": 0.28,
        "max_drawdown_pct": 16.27,
        "total_trades": 3
      }
    },
    "top_candidates": [
      {
        "params": {
          "window": 50,
          "band_deviation": 1.8,
          "sl_pips": 15.0,
          "tp_pips": 30.0,
          "max_spread_pips": 1.8
        },
        "in_sample": {
          "return_pct": 16.26,
          "sharpe_ratio": 40.99,
          "profit_factor": 293.09,
          "max_drawdown_pct": 0.77,
          "total_trades": 3
        },
        "out_of_sample": {
          "return_pct": -11.73,
          "sharpe_ratio": -15.72,
          "profit_factor": 0.28,
          "max_drawdown_pct": 16.27,
          "total_trades": 3
        }
      },
      {
        "params": {
          "window": 50,
          "band_deviation": 1.8,
          "sl_pips": 12.0,
          "tp_pips": 30.0,
          "max_spread_pips": 1.8
        },
        "in_sample": {
          "return_pct": 20.52,
          "sharpe_ratio": 40.79,
          "profit_factor": 284.07,
          "max_drawdown_pct": 0.96,
          "total_trades": 3
        },
        "out_of_sample": {
          "return_pct": -14.93,
          "sharpe_ratio": -16.13,
          "profit_factor": 0.27,
          "max_drawdown_pct": 20.33,
          "total_trades": 3
        }
      },
      {
        "params": {
          "window": 50,
          "band_deviation": 1.8,
          "sl_pips": 10.0,
          "tp_pips": 30.0,
          "max_spread_pips": 1.8
        },
        "in_sample": {
          "return_pct": 24.77,
          "sharpe_ratio": 40.67,
          "profit_factor": 276.95,
          "max_drawdown_pct": 1.15,
          "total_trades": 3
        },
        "out_of_sample": {
          "return_pct": -18.22,
          "sharpe_ratio": -16.54,
          "profit_factor": 0.25,
          "max_drawdown_pct": 24.38,
          "total_trades": 3
        }
      }
    ]
  },
  "backtest_eurusd": {
    "initial_capital": 10000.0,
    "final_equity": 10292.77,
    "total_net_pnl": 292.77,
    "return_pct": 2.93,
    "total_trades": 5,
    "win_rate_pct": 60.0,
    "profit_factor": 1.16,
    "sharpe_ratio": 2.03,
    "sortino_ratio": 2.28,
    "calmar_ratio": 0.18,
    "max_drawdown_pct": 16.2,
    "max_drawdown_dollars": 1888.26,
    "expectancy_per_trade": 58.55,
    "payoff_ratio": 0.77,
    "avg_win": 721.24,
    "avg_loss": 935.48
  },
  "backtest_gbpusd": {
    "initial_capital": 10000.0,
    "final_equity": 12717.26,
    "total_net_pnl": 2717.26,
    "return_pct": 27.17,
    "total_trades": 5,
    "win_rate_pct": 60.0,
    "profit_factor": 3.27,
    "sharpe_ratio": 16.34,
    "sortino_ratio": 58.72,
    "calmar_ratio": 2.12,
    "max_drawdown_pct": 12.8,
    "max_drawdown_dollars": 1287.71,
    "expectancy_per_trade": 543.45,
    "payoff_ratio": 2.18,
    "avg_win": 1304.62,
    "avg_loss": 598.3
  },
  "backtest_xauusd": {
    "initial_capital": 10000.0,
    "final_equity": 11401.53,
    "total_net_pnl": 1401.53,
    "return_pct": 14.02,
    "total_trades": 13,
    "win_rate_pct": 38.46,
    "profit_factor": 1.76,
    "sharpe_ratio": 5.36,
    "sortino_ratio": 8.08,
    "calmar_ratio": 1.18,
    "max_drawdown_pct": 11.85,
    "max_drawdown_dollars": 1494.3,
    "expectancy_per_trade": 107.81,
    "payoff_ratio": 2.82,
    "avg_win": 647.27,
    "avg_loss": 229.35
  },
  "monte_carlo": {
    "num_simulations": 5000,
    "ruin_threshold_drawdown_pct": 30.0,
    "probability_of_ruin_pct": 24.1,
    "final_equity": {
      "p5_bearish": 7078.6,
      "p50_median": 14453.06,
      "p95_bullish": 21565.27
    },
    "max_drawdown_pct": {
      "p5_mild": 6.11,
      "p50_median": 18.85,
      "p95_stress": 51.56
    },
    "sharpe_ratio": {
      "p5_conservative": -5.23,
      "p50_median": 7.74,
      "p95_optimistic": 20.58
    },
    "risk_metrics": {
      "var_95_pct": -29.21,
      "var_99_pct": -57.61,
      "cvar_95_expected_shortfall_pct": -47.66
    },
    "sample_trajectories": {
      "trades_count": 23,
      "median_curve": [
        10000.0,
        9996.76,
        10262.01,
        10495.35,
        10700.11,
        10895.66,
        11117.39,
        11305.02,
        11525.87,
        11725.11,
        11940.06,
        12104.21,
        12260.21,
        12539.52,
        12685.09,
        12882.23,
        13059.17,
        13255.95,
        13478.07,
        13570.74,
        13871.6,
        14026.29,
        14268.43,
        14453.06
      ],
      "lower_95_curve": [
        10000.0,
        8528.98,
        8148.76,
        8093.06,
        7823.27,
        7660.5,
        7522.43,
        7428.35,
        7265.02,
        7148.6,
        7096.55,
        7038.58,
        7107.47,
        7181.57,
        7127.11,
        7119.22,
        7092.17,
        7080.49,
        7085.86,
        7119.75,
        7167.63,
        7042.82,
        6981.07,
        7078.6
      ],
      "upper_95_curve": [
        10000.0,
        11923.76,
        12494.62,
        13261.71,
        13894.55,
        14385.2,
        14911.77,
        15430.54,
        15938.81,
        16385.23,
        16768.6,
        17132.69,
        17680.84,
        18105.46,
        18549.8,
        18937.18,
        19310.07,
        19665.36,
        19986.5,
        20359.03,
        20622.27,
        20986.67,
        21335.67,
        21565.27
      ]
    }
  }
};

const SEQUENTIAL_SUMMARY = {
  "total_files_tested": 1297,
  "total_expert_advisors": 475,
  "total_indicators": 527,
  "total_martingale_systems": 160,
  "ea_verdict_breakdown": {
    "PASS_PROFITABLE": 361,
    "PASS_MARGINAL": 82,
    "FAIL_BLOWUP": 19
  },
  "pass_rate_pct": 76.0,
  "blowup_rate_pct": 4.0,
  "test_duration_seconds": 29.91
};

const SEQUENTIAL_LEADERBOARD = [
  {
    "Index": 1278,
    "Filename": "tiger.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 169,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iADX",
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 13.9,
    "ReturnPct": 0.14,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 14,
    "Filename": "ASSAR V10 Final.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 1429,
    "Archetype": "Volatility Bands Reversion",
    "Indicators": "iMA,iBands,iEnvelopes",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 9.9,
    "ReturnPct": 0.1,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 18,
    "Filename": "Adenan Scalping.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 675,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 9,
    "WinRatePct": 100.0,
    "NetPnL": 2.25,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1272,
    "Filename": "souce of fx pips blaster.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 721,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1257,
    "Filename": "simple-macd-EA.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 182,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 245.0,
    "ReturnPct": 2.45,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1211,
    "Filename": "parabolic_DMI2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 40,
    "Archetype": "Directional Trend Following",
    "Indicators": "iADX",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 112.5,
    "ReturnPct": 1.12,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1210,
    "Filename": "parabolic_DMI.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 45,
    "Archetype": "Directional Trend Following",
    "Indicators": "iSAR,iADX",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 112.5,
    "ReturnPct": 1.12,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1209,
    "Filename": "parabolic_2_screen.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 44,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iSAR",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 112.5,
    "ReturnPct": 1.12,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1198,
    "Filename": "my.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 68,
    "Archetype": "General Market Order EA",
    "Indicators": "iBearsPower,iBullsPower",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 4,
    "WinRatePct": 100.0,
    "NetPnL": 17100.0,
    "ReturnPct": 171.0,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 987,
    "Filename": "Trend Racing 3.51 ME Lite_tral_lasttp.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 1032,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iCCI,iADX",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 3.75,
    "ReturnPct": 0.04,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1193,
    "Filename": "multilot scalper.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 295,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 202,
    "Filename": "EasyRobot.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 214,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": "iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 192,
    "Filename": "EA-HOKKYDJONG.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 462,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 7,
    "WinRatePct": 100.0,
    "NetPnL": 245.0,
    "ReturnPct": 2.45,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1153,
    "Filename": "iCustom_EA1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 278,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 186,
    "Filename": "EA Sarapan-Pagi_2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 267,
    "Archetype": "Volatility Bands Reversion",
    "Indicators": "iRSI,iBands,iStochastic",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 19.0,
    "ReturnPct": 0.19,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1116,
    "Filename": "amingrid.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 130,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": "iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1148,
    "Filename": "high profit EA.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 769,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1065,
    "Filename": "Two_MA_Cross_EA.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 685,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 292.5,
    "ReturnPct": 2.92,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 248,
    "Filename": "Firebird v0.62 [ea].mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 186,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1089,
    "Filename": "Waygrow_edu v1.8 best.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 805,
    "Archetype": "Volatility Bands Reversion",
    "Indicators": "iMA,iEnvelopes",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 4.9,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1069,
    "Filename": "UnNomGuaiV1.132.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 811,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iCCI,iSAR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 235,
    "Filename": "Firebird MC v0583.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 184,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 237,
    "Filename": "Firebird v0.50(26JUL05).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 75,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 238,
    "Filename": "Firebird v0.50.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 75,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 239,
    "Filename": "Firebird v0.51.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 71,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 880,
    "Filename": "SilverTrendTrader_v7.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 282,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iCCI",
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 475.0,
    "ReturnPct": 4.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 984,
    "Filename": "Transformer_EA_V(3).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 509,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 890,
    "Filename": "Simple-macd-ea_www_forex-instruments_info.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 182,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 245.0,
    "ReturnPct": 2.45,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 891,
    "Filename": "SimpleH1_GBPUSD_EAv9.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 442,
    "Archetype": "Trend Breakout (MA + Donchian)",
    "Indicators": "iMA,iFractals",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 49.0,
    "ReturnPct": 0.49,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 234,
    "Filename": "Firebird MC v0582.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 184,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 233,
    "Filename": "Firebird MC v0581.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 184,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 232,
    "Filename": "Firebird MC v058.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 184,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1016,
    "Filename": "TrendTrading_EA_v1.1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 154,
    "Archetype": "Trend Breakout (MA + Donchian)",
    "Indicators": "iMA,iSAR,iADX",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 199.5,
    "ReturnPct": 2.0,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 833,
    "Filename": "Sergey_0.2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 349,
    "Archetype": "Volatility Bands Reversion",
    "Indicators": "iATR,iBands,iVolume",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 49.0,
    "ReturnPct": 0.49,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 838,
    "Filename": "Session breakout v01_mbk.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 53,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 725.0,
    "ReturnPct": 7.25,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 853,
    "Filename": "ShockBar_v_1_1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 645,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 22.5,
    "ReturnPct": 0.22,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 249,
    "Filename": "Firebird v0.63 [ea].mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 193,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 295.0,
    "ReturnPct": 2.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 259,
    "Filename": "Firebird v63 TVD1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 387,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 2.95,
    "ReturnPct": 0.03,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 260,
    "Filename": "Firebird v63 TVD2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 387,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 2.95,
    "ReturnPct": 0.03,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 261,
    "Filename": "Firebird v63B1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 210,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 88.5,
    "ReturnPct": 0.88,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 262,
    "Filename": "Firebird v63D1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 436,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 2.95,
    "ReturnPct": 0.03,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 125,
    "Filename": "Daydream01.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 99,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 725.0,
    "ReturnPct": 7.25,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 181,
    "Filename": "EA Predator Pips.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 533,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 167,
    "Filename": "Dragon Expert Advisor v4.1 updated 2019 .mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 813,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 165,
    "Filename": "Double(Ilan1_5&Ilan1_6).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 820,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 47,
    "Filename": "Beast_EA_V5.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 271,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 1224,
    "Filename": "pipschart_revamp_v3P.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 1672,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": "iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 185,
    "Filename": "EA SPARTAN BOLT_.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 684,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 576,
    "Filename": "Overlay Positive Hedging v1a_.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 823,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 4,
    "WinRatePct": 100.0,
    "NetPnL": 318.0,
    "ReturnPct": 3.18,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 799,
    "Filename": "SMC eur usd2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 151,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 975.0,
    "ReturnPct": 9.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 281,
    "Filename": "ForexMission.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 2406,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iMACD,iStochastic,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 293,
    "Filename": "GEBA ROBOT.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 169,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iADX",
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 4,
    "WinRatePct": 100.0,
    "NetPnL": 29.8,
    "ReturnPct": 0.3,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 294,
    "Filename": "GEBA ROBOT2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 169,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iADX",
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 4,
    "WinRatePct": 100.0,
    "NetPnL": 298.0,
    "ReturnPct": 2.98,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 794,
    "Filename": "SMC USD JPY cci test.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 146,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD,iCCI",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 475.0,
    "ReturnPct": 4.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 795,
    "Filename": "SMC eur usd(26AUG05).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 156,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 975.0,
    "ReturnPct": 9.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 796,
    "Filename": "SMC eur usd(28AUG05).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 108,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 975.0,
    "ReturnPct": 9.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 797,
    "Filename": "SMC eur usd1(26AUG05).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 156,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 975.0,
    "ReturnPct": 9.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 784,
    "Filename": "SMC Trader Camel CCI MACD -ron02.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 49,
    "Archetype": "Trend Breakout (MA + Donchian)",
    "Indicators": "iMA,iMACD,iCCI",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 1195.0,
    "ReturnPct": 11.95,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 788,
    "Filename": "SMC Trader Kurt1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 151,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 975.0,
    "ReturnPct": 9.75,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 364,
    "Filename": "Ilan_RSI_MACD.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 393,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iMACD",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 363,
    "Filename": "Ilan_Nikolaus_mod.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 463,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 19.0,
    "ReturnPct": 0.19,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 370,
    "Filename": "Ilan_VS_TrendTrading_Trail.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 482,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 344,
    "Filename": "Ilan-1.8.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 447,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 345,
    "Filename": "Ilan-Combi V2.1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 1856,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR,iRSI,iMACD,iStochastic,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 380,
    "Filename": "Jum+StoC+v2.3F~.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 1017,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iStochastic",
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 7,
    "WinRatePct": 100.0,
    "NetPnL": 1225.0,
    "ReturnPct": 12.25,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 349,
    "Filename": "Ilan-Trio V1.43.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 2186,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iMACD,iStochastic,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 4.75,
    "ReturnPct": 0.05,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 351,
    "Filename": "Ilan-Trio V1.47.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 2239,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iRSI,iMACD,iStochastic,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 9.75,
    "ReturnPct": 0.1,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 354,
    "Filename": "Ilan_1.5_ZeroProfit.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 444,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iMACD,iStochastic",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 16,
    "WinRatePct": 100.0,
    "NetPnL": 8.0,
    "ReturnPct": 0.08,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 353,
    "Filename": "Ilan1.6.Prof6.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 388,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 355,
    "Filename": "Ilan_1.6_Dynamic_MM.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 415,
    "Archetype": "Trend Breakout (MA + Donchian)",
    "Indicators": "iMA,iRSI,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 19.0,
    "ReturnPct": 0.19,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 356,
    "Filename": "Ilan_16TD_CCI_1.3.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 491,
    "Archetype": "Trend Breakout (MA + Donchian)",
    "Indicators": "iMA,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 357,
    "Filename": "Ilan_16TD_SCT.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 504,
    "Archetype": "Trend Breakout (MA + Donchian)",
    "Indicators": "iMA,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 359,
    "Filename": "Ilan_HiLo_RSI.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 388,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 739,
    "Filename": "SHE_Lucky.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 59,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 711,
    "Filename": "Robot Forex 2051MAC (RUS).mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 568,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iMACD",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 709,
    "Filename": "Robot Forex 2013 Profesional Demo~.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 524,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 439,
    "Filename": "Mission Impossible Power Two Open Version 2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 450,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": NaN,
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 3.25,
    "ReturnPct": 0.03,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 362,
    "Filename": "Ilan_Lite_1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 159,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 361,
    "Filename": "Ilan_HiLo_RSI_fixed_by_Vespertilio.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 388,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 360,
    "Filename": "Ilan_HiLo_RSI_Dinamic.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 401,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 1.9,
    "ReturnPct": 0.02,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 740,
    "Filename": "SHE_Lucky_reinvest.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 59,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 443,
    "Filename": "Multi Lot Scalper.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 335,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 369,
    "Filename": "Ilan_VS_TrendTrading_LastTP_v1_2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 572,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iCCI",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 368,
    "Filename": "Ilan_Tren_AHP_2010.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 458,
    "Archetype": "Martingale Grid Scalper",
    "Indicators": "iBearsPower,iBullsPower",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 23.75,
    "ReturnPct": 0.24,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 462,
    "Filename": "Multi_Lot_Scalper_Psars1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 258,
    "Archetype": "MACD Momentum",
    "Indicators": "iMACD,iSAR",
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 464,
    "Filename": "Multi_Lot_Scapler_P_DAY_JLY.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 295,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 465,
    "Filename": "Multi_Lot_Scapler_P_DAY_JLY1.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 295,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 466,
    "Filename": "Multi_Lot_Scapler_P_DAY_JLY2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 295,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 593,
    "Filename": "PairTrader_Exp v41.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 236,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 24.5,
    "ReturnPct": 0.24,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 467,
    "Filename": "Multi_Lot_Scapler_P_DAY_JLY3.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 295,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 468,
    "Filename": "Multi_Lot_Scapler_P_DAY_MT4.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 334,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "UNPROTECTED_NO_STOP_LOSS",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 644,
    "Filename": "Profit Seven EA2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 769,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 643,
    "Filename": "Profit Seven EA 2.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 889,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iATR",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 659,
    "Filename": "RPT_AUD.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 87,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 24.5,
    "ReturnPct": 0.24,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 660,
    "Filename": "RPT_AUD_TAKE.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 88,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 24.5,
    "ReturnPct": 0.24,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 661,
    "Filename": "RPT_EUR.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 87,
    "Archetype": "General Market Order EA",
    "Indicators": NaN,
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 1,
    "WinRatePct": 100.0,
    "NetPnL": 24.5,
    "ReturnPct": 0.24,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 655,
    "Filename": "RPLine_v01H1.ex4.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 262,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iCCI",
    "IsMartingale": false,
    "RiskClass": "NEGATIVE_ASYMMETRY (High Risk)",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 159.0,
    "ReturnPct": 1.59,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 682,
    "Filename": "RSI_Tradexperts.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 203,
    "Archetype": "Oscillator Mean Reversion",
    "Indicators": "iRSI",
    "IsMartingale": false,
    "RiskClass": "SYMMETRIC_OR_DEFAULT",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 2,
    "WinRatePct": 100.0,
    "NetPnL": 49.0,
    "ReturnPct": 0.49,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 399,
    "Filename": "MACD Cross Zero EA v1.02.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 684,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA,iMACD",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 47.5,
    "ReturnPct": 0.47,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  },
  {
    "Index": 404,
    "Filename": "MA_Cross_with_Exit_EA.mq4",
    "Type": "Expert Advisor",
    "LinesOfCode": 717,
    "Archetype": "Moving Average Crossover",
    "Indicators": "iMA",
    "IsMartingale": true,
    "RiskClass": "MARTINGALE_GRID_TOXIC",
    "Verdict": "PASS_PROFITABLE",
    "Trades": 5,
    "WinRatePct": 100.0,
    "NetPnL": 292.5,
    "ReturnPct": 2.92,
    "ProfitFactor": 99.0,
    "MaxDrawdownPct": 0.0,
    "SharpeRatio": 0.0
  }
];

const MQ4_CATALOG = [
  {
    "name": "3D-oscilator-v2-indicator.mq4",
    "type": "Custom Indicator",
    "loc": 65,
    "indicators": [
      "iRSI",
      "iCCI"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "3DMA MT4 Indicator.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 265,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "4 time frame stochastic 2.mq4",
    "type": "Custom Indicator",
    "loc": 187,
    "indicators": [
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "4_Period_MA_w_Regr_STD.mq4",
    "type": "Custom Indicator",
    "loc": 887,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AA_MTF_RSIOMA_Line V1.02.mq4",
    "type": "Custom Indicator",
    "loc": 439,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "absolutelynolaglwma -2.mq4",
    "type": "Custom Indicator",
    "loc": 50,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AccountEquityAnalyzer.mq4",
    "type": "Custom Indicator",
    "loc": 308,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AddCandles.mq4",
    "type": "Custom Indicator",
    "loc": 169,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Adenan Scalping.mq4",
    "type": "Expert Advisor",
    "loc": 675,
    "indicators": [],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "ADR.mq4",
    "type": "Custom Indicator",
    "loc": 48,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Advanced StepRSI v2.2 dz's alerts mtf arrows.mq4",
    "type": "Custom Indicator",
    "loc": 345,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Advanced StepRSI v2.3 dz's alerts mtf arrows.mq4",
    "type": "Custom Indicator",
    "loc": 456,
    "indicators": [
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "ADX-STOCHhisto-AWESOME.mq4",
    "type": "Custom Indicator",
    "loc": 151,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AF-Global Expert Full.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 4261,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AF-Investing.Cv.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 4451,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "afstar-indicator.mq4",
    "type": "Custom Indicator",
    "loc": 151,
    "indicators": [
      "iMA",
      "iWPR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "ain-dicad-ormry3.mq4",
    "type": "Custom Indicator",
    "loc": 156,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AIO Divergence.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2937,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AK_ZigZag Noble Pointer.mq4",
    "type": "Custom Indicator",
    "loc": 112,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AK_ZigZag ROYAL Pointer.mq4",
    "type": "Custom Indicator",
    "loc": 112,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Alert2.mq4",
    "type": "Custom Indicator",
    "loc": 321,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "alex_v1_1.mq4",
    "type": "Expert Advisor",
    "loc": 138,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Algo Samurai.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1073,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AllClusterFilter_v1.1 600+.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2033,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "ALMA_v2 atr bands.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 393,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "amingrid.mq4",
    "type": "Expert Advisor",
    "loc": 130,
    "indicators": [
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "another martingale fix.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 717,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AntiAlligator.mq4",
    "type": "Custom Indicator",
    "loc": 87,
    "indicators": [
      "iAlligator"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "aParabolic SAR 2 histo_mtf+alerts+arrows - nmc.mq4",
    "type": "Custom Indicator",
    "loc": 257,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Arnold.mq4",
    "type": "Expert Advisor",
    "loc": 398,
    "indicators": [
      "iRSI",
      "iStochastic",
      "iMFI"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Aroon_Oscillator_v1.mq4",
    "type": "Custom Indicator",
    "loc": 98,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "ArrowsAndCurves_Alert.mq4",
    "type": "Custom Indicator",
    "loc": 111,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AsiaScalperPro_.mq4",
    "type": "Expert Advisor",
    "loc": 516,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "ASSAR V10 Final.mq4",
    "type": "Expert Advisor",
    "loc": 1429,
    "indicators": [
      "iMA",
      "iBands",
      "iEnvelopes"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "ATR Bands 2.01.mq4",
    "type": "Custom Indicator",
    "loc": 324,
    "indicators": [],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "atr_3lwma.mq4",
    "type": "Custom Indicator",
    "loc": 173,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Auto Recommendations_WithAlert.mq4",
    "type": "Custom Indicator",
    "loc": 143,
    "indicators": [
      "iBands"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Auto Trading_v2.02.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 92,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AutoFib TradeZones.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 485,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "autofibo-trading-zones.mq4",
    "type": "Custom Indicator",
    "loc": 209,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AutoFibu button.mq4",
    "type": "Custom Indicator",
    "loc": 384,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "AutoPivotIndicator_ver5.mq4",
    "type": "Custom Indicator",
    "loc": 983,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "AutoRefresh.mq4",
    "type": "Custom Indicator",
    "loc": 31,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Auto_Targets.mq4",
    "type": "Expert Advisor",
    "loc": 279,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Avg Daily Range.mq4",
    "type": "Custom Indicator",
    "loc": 66,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Bar-reversal-indicator.mq4",
    "type": "Custom Indicator",
    "loc": 81,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "bar-stop-loss-indicator.mq4",
    "type": "Custom Indicator",
    "loc": 97,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Barreversal.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 341,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Barros_Swing_Fix.mq4",
    "type": "Custom Indicator",
    "loc": 725,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BBCI_v2 (2).mq4",
    "type": "Custom Indicator",
    "loc": 282,
    "indicators": [
      "iATR",
      "iStdDev"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BEAST SUPER SIGNAL EXPERT ADVISOR.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 9016,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Beast_EA_V4.mq4",
    "type": "Expert Advisor",
    "loc": 258,
    "indicators": [],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Beast_EA_V5.mq4",
    "type": "Expert Advisor",
    "loc": 271,
    "indicators": [],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "beovb_buovb_bar.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 789,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Best Indicator Forever.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 827,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BetterVolumeTicks_ alerts  + text.mq4",
    "type": "Custom Indicator",
    "loc": 294,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Bheurekso_pattern@totusmod@.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1007,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Big Rise EA.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 3714,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BigRise EA.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 3714,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Bismillah Hedge..mq4",
    "type": "Expert Advisor",
    "loc": 288,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Black.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 610,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Blessing 3 v3.9.6.09.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 5819,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BlessingLite-gamma.mq4",
    "type": "Expert Advisor",
    "loc": 2560,
    "indicators": [
      "iMA",
      "iRSI",
      "iMACD",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Blessing_3_v3.9.6.18.mq4",
    "type": "Expert Advisor",
    "loc": 3055,
    "indicators": [
      "iMA",
      "iRSI",
      "iMACD",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Blubbb MightyZones [kokoveni].mq4",
    "type": "Custom Indicator",
    "loc": 229,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BLUE GOLD EA (FMP.SA).mq4",
    "type": "Utility / Indicator Helper",
    "loc": 8207,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BlueTrernd.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 241,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BNfx Signals - Indicator-3.mq4",
    "type": "Custom Indicator",
    "loc": 372,
    "indicators": [
      "iMA",
      "iATR",
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Bollinger_Bands_Exit_Strategy.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 242,
    "indicators": [
      "iBands"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "bot gold.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 3302,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Braid_Filter.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 141,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BrainTrend2SigALERT2.mq4",
    "type": "Custom Indicator",
    "loc": 165,
    "indicators": [
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Breakeven.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 325,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BreakOutBoxesV2.06.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2525,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BreakOut_BOX_5_Asian_Session_HLbox_SCREEN_TEXT_indicator.mq4",
    "type": "Custom Indicator",
    "loc": 323,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Breakout_PANCA_EAGLE.mq4",
    "type": "Custom Indicator",
    "loc": 98,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Brooky_Garnish_Levels.mq4",
    "type": "Custom Indicator",
    "loc": 180,
    "indicators": [
      "iSAR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Brooky_PSAR_Levels_MTF_TT.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 553,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BTFX-Dynamic_Trend_Multi_Currency~.mq4",
    "type": "Custom Indicator",
    "loc": 3450,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "BullBearRSI.mq4",
    "type": "Custom Indicator",
    "loc": 93,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BUY-SELL.SIGNAL.mq4",
    "type": "Custom Indicator",
    "loc": 81,
    "indicators": [
      "iMA",
      "iRSI"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Buy-Sell_Alerts.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 151,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "BuySell_Filter.mq4",
    "type": "Custom Indicator",
    "loc": 96,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Buy_-Sel_l_Alert.mq4",
    "type": "Custom Indicator",
    "loc": 1999,
    "indicators": [
      "iMA",
      "iRSI",
      "iMACD",
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "Buy_Sell_Signal.mq4",
    "type": "Custom Indicator",
    "loc": 150,
    "indicators": [
      "iMA",
      "iRSI"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "buzzer.mq4",
    "type": "Custom Indicator",
    "loc": 152,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Calculate Trendline Script.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 16,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CalendarFX-DeactivateEAs_v1.02_danEdit.mq4",
    "type": "Custom Indicator",
    "loc": 1629,
    "indicators": [],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "camarilladt7v11.mq4",
    "type": "Custom Indicator",
    "loc": 1475,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "CAMARILLA_ZONES_02.mq4",
    "type": "Custom Indicator",
    "loc": 530,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Candlestick - CustomCandle_TRO_MODIFIED_VERSION.mq4",
    "type": "Custom Indicator",
    "loc": 197,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "Candlestick alerts.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1055,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Candlestick_alerts_Set 3.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1111,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CAP Channel.mq4",
    "type": "Custom Indicator",
    "loc": 351,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "CCI zones.mq4",
    "type": "Custom Indicator",
    "loc": 122,
    "indicators": [
      "iCCI"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CCI'HMA MinMax Levels AA MTF SV+TT 1.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 533,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "cci_nma_alerts_mtf_1.2.mq4",
    "type": "Custom Indicator",
    "loc": 299,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "ChandelierExit.mq4",
    "type": "Custom Indicator",
    "loc": 67,
    "indicators": [
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Cheeta xpMA.mq4",
    "type": "Custom Indicator",
    "loc": 544,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "CHV.mq4",
    "type": "Custom Indicator",
    "loc": 67,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "CK_Speed.mq4",
    "type": "Custom Indicator",
    "loc": 73,
    "indicators": [
      "iATR",
      "iStdDev"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Clear method-SD v1.11.mq4",
    "type": "Custom Indicator",
    "loc": 409,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "ClickCloseAllv01.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 60,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Close all positions at profit target v1.1.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 126,
    "indicators": [],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Close All.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 177,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Close Losses.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 177,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Close Open.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 177,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Close Pendings.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 175,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Close Profits.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 177,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAfterXpips EA.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 217,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTrades.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 38,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesBuy.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 35,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesBuyCurrent.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 41,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesCurrent.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 58,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesOpened.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 37,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesOpenedCurrent.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 42,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesPending.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 37,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesPendingCurrent.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 42,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesSell.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 35,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAllTradesSellCurrent.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 41,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CloseAtProfit.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 375,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "closeattime.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 187,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "closetrades_after_account_loss_toomuch.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 40,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "cm-Trade-System-201119.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2303,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CM_Strength.mq4",
    "type": "Custom Indicator",
    "loc": 358,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Color Levels.mq4",
    "type": "Custom Indicator",
    "loc": 368,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "colorzerolagrvi.mq4",
    "type": "Custom Indicator",
    "loc": 681,
    "indicators": [
      "iRVI",
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "correl8.mq4",
    "type": "Custom Indicator",
    "loc": 371,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "COTCustomInd.mq4",
    "type": "Custom Indicator",
    "loc": 323,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "CPIv1.5 ENG.mq4",
    "type": "Custom Indicator",
    "loc": 476,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CRIPTOBOT EA - New Version 8.5.7.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1921,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Cronex_Taichi.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 233,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Crypto Amazing Analysis 2.6.0.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1265,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "CTG-Modify_Date.mq4",
    "type": "Script",
    "loc": 161,
    "indicators": [],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "CumulativeDelta.mq4",
    "type": "Custom Indicator",
    "loc": 388,
    "indicators": [
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Currency Slope Strength_STOC_v1.4.mq4",
    "type": "Custom Indicator",
    "loc": 822,
    "indicators": [
      "iRSI",
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "CurrencyStrengthIndicator.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 601,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "custom-bb-macd-indicator.mq4",
    "type": "Custom Indicator",
    "loc": 115,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "DailyLinesBoxes.mq4",
    "type": "Custom Indicator",
    "loc": 1415,
    "indicators": [
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Daily_Research.mq4",
    "type": "Script",
    "loc": 111,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "DarvasBoxes nmc.mq4",
    "type": "Custom Indicator",
    "loc": 408,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Dat cloud.mq4",
    "type": "Custom Indicator",
    "loc": 201,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "day open .mq4",
    "type": "Expert Advisor",
    "loc": 35,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Daydream01.mq4",
    "type": "Expert Advisor",
    "loc": 99,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "DeleteAllObjects.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 21,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Delta Trend_v1 600+.mq4",
    "type": "Custom Indicator",
    "loc": 134,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "dema macd zones amp alerts 2.mq4",
    "type": "Custom Indicator",
    "loc": 177,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "DIDI Index MTF.mq4",
    "type": "Custom Indicator",
    "loc": 160,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Digital 123Pattern.mq4",
    "type": "Custom Indicator",
    "loc": 499,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital 30 MASHEK PODVAL.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1865,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital ADR Calc_mod.mq4",
    "type": "Custom Indicator",
    "loc": 828,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital ADX Crossing 2.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 249,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital Buy Sell Arrow.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 179,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital BUYSELL VOLUME 3 MTF.mq4",
    "type": "Custom Indicator",
    "loc": 665,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital BuySell ZONE.mq4",
    "type": "Custom Indicator",
    "loc": 79,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital CandleAbsoluteStrengthTrend.mq4",
    "type": "Custom Indicator",
    "loc": 1095,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "Digital FAST TMA LINE.mq4",
    "type": "Custom Indicator",
    "loc": 407,
    "indicators": [
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital HMA TRICOLOR ZERO Alert NO-REPAINT.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 319,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital HULL & Alerts & Arrows.mq4",
    "type": "Custom Indicator",
    "loc": 249,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital HULL OHLC Candle TT.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 277,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital HULL OHLC Candle.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 303,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital HULL _ Alerts _ Arrows.mq4",
    "type": "Custom Indicator",
    "loc": 249,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital Jeepers Creepers Alert.mq4",
    "type": "Custom Indicator",
    "loc": 168,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital MA2Color.mq4",
    "type": "Custom Indicator",
    "loc": 239,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Digital MarketProfile vPOC.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2149,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital Murrey Math Line RUS.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 635,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital OBOS ZZ.mq4",
    "type": "Custom Indicator",
    "loc": 331,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital SNR SND.mq4",
    "type": "Custom Indicator",
    "loc": 198,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital SupDem CHANNEL.mq4",
    "type": "Custom Indicator",
    "loc": 356,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "Digital TargetLines.mq4",
    "type": "Custom Indicator",
    "loc": 156,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Digital Trend Lord NRP.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 247,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital X-DAILY TARGETS.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 357,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digital ZZ Arrow NO REPAINT.mq4",
    "type": "Custom Indicator",
    "loc": 146,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Digitel FLET ColorMOD.mq4",
    "type": "Custom Indicator",
    "loc": 101,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Donchian Bands.mq4",
    "type": "Custom Indicator",
    "loc": 47,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Donchian Breakout Modified by Yogi.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1609,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Donchian Breakout Syste.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1609,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Donchian Channels - Generalized version.mq4",
    "type": "Custom Indicator",
    "loc": 55,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Donchian Channels - Generalized version1.mq4",
    "type": "Custom Indicator",
    "loc": 55,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "DonchianBreakoutSystem_v1.1.2 600+.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1609,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dope.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1949,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dope_mod.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2075,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dope_mod_2.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2269,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Doske_Scalping_EA_ver1.mq4",
    "type": "Expert Advisor",
    "loc": 451,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Double Stochastic RSI.mq4",
    "type": "Custom Indicator",
    "loc": 334,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Double(Ilan1_5&Ilan1_6).mq4",
    "type": "Expert Advisor",
    "loc": 820,
    "indicators": [
      "iRSI"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "DoubleMeanRenkoBuilder.mq4",
    "type": "Custom Indicator",
    "loc": 525,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "double_ema_crossover_with_arrow_and_email.mq4",
    "type": "Custom Indicator",
    "loc": 205,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Dragon Expert Advisor v4.1 updated 2019 .mq4",
    "type": "Expert Advisor",
    "loc": 813,
    "indicators": [
      "iMA",
      "iCCI"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dragon Pips v2.02 Rev.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2361,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dream EA.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1131,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dreko.mq4",
    "type": "Expert Advisor",
    "loc": 921,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "Dserg-LinRegressionBreakout_v1 (1).1.mq4",
    "type": "Custom Indicator",
    "loc": 174,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Dserg-LinRegressionBreakout_v1.1.mq4",
    "type": "Custom Indicator",
    "loc": 174,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "DSS Bressert.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 223,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "DT_ZZ_alerts rus.mq4",
    "type": "Custom Indicator",
    "loc": 111,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "dual stoch - divergences 2.1 (alerts).mq4",
    "type": "Custom Indicator",
    "loc": 218,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "DuettoFX.MQ4",
    "type": "Custom Indicator",
    "loc": 281,
    "indicators": [
      "iMA",
      "iRSI"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Dynamic cycle explorer.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 636,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Dynamic zones Polychromatic momentum 5.13.mq4",
    "type": "Custom Indicator",
    "loc": 579,
    "indicators": [
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "DynamicCycleExplorer.mq4",
    "type": "Custom Indicator",
    "loc": 126,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "dynamic_zones_absolutestrength_of_averages_diff_2.mq4",
    "type": "Custom Indicator",
    "loc": 842,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EA - Budak Ubat v1.51.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1137,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EA for Set TP-SL.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 58,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Masyuk V3..mq4",
    "type": "Expert Advisor",
    "loc": 151,
    "indicators": [
      "iMA",
      "iSAR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA noName(1).mq4",
    "type": "Expert Advisor",
    "loc": 5493,
    "indicators": [],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Phoenix 2021.mq4",
    "type": "Expert Advisor",
    "loc": 623,
    "indicators": [
      "iATR",
      "iWPR",
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Phoenix 2021_edited.mq4",
    "type": "Expert Advisor",
    "loc": 616,
    "indicators": [
      "iATR",
      "iWPR",
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Predator Pips.mq4",
    "type": "Expert Advisor",
    "loc": 533,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Profit V10.mq4",
    "type": "Expert Advisor",
    "loc": 269,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Pyramid 7.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1575,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EA RoboFibo v.11.2.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 4727,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EA Sarapan-Pagi_2.mq4",
    "type": "Expert Advisor",
    "loc": 267,
    "indicators": [
      "iRSI",
      "iBands",
      "iStochastic"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Scalping Asia.mq4",
    "type": "Expert Advisor",
    "loc": 233,
    "indicators": [
      "iMACD",
      "iEnvelopes"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA Smart Neural V1.mq4",
    "type": "Expert Advisor",
    "loc": 1407,
    "indicators": [
      "iATR",
      "iWPR",
      "iVolume"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA SPARTAN BOLT_.mq4",
    "type": "Expert Advisor",
    "loc": 684,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA-2MACrossover_v1-0.mq4",
    "type": "Expert Advisor",
    "loc": 158,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA-HOKKYDJONG.mq4",
    "type": "Expert Advisor",
    "loc": 462,
    "indicators": [],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Ea-Tesshinso.mq4",
    "type": "Expert Advisor",
    "loc": 734,
    "indicators": [
      "iATR",
      "iWPR",
      "iVolume"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EasyRobot.mq4",
    "type": "Expert Advisor",
    "loc": 214,
    "indicators": [
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA_Close_All_v5.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 711,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EA_eurusd m15.mq4",
    "type": "Expert Advisor",
    "loc": 1312,
    "indicators": [
      "iMA",
      "iATR",
      "iBands",
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "EA_LUCRE.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 973,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EA_TheOne.mq4",
    "type": "Expert Advisor",
    "loc": 763,
    "indicators": [
      "iMA",
      "iBands",
      "iEnvelopes"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "elder-impulse-system.mq4",
    "type": "Custom Indicator",
    "loc": 93,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Elite_eFibo_Trader_v2_1.mq4",
    "type": "Expert Advisor",
    "loc": 606,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Elliott Wave Oscillator.mq4",
    "type": "Custom Indicator",
    "loc": 27,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EMA MACD indi.mq4",
    "type": "Custom Indicator",
    "loc": 112,
    "indicators": [
      "iMA",
      "iMACD",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EMA-color-alerts-indicator.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 268,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EMA_Cross__SES__BDv8_12_31.mq4",
    "type": "Custom Indicator",
    "loc": 76,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "engulfing EA.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 789,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "EquityGuard1.2c.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 268,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Extreme_Spike-123.mq4",
    "type": "Custom Indicator",
    "loc": 418,
    "indicators": [
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "EZTrender-swing.mq4",
    "type": "Custom Indicator",
    "loc": 146,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Falcon Zone MTF.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 765,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Fast Scalper.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 762,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FDM Buy Sell Pressure.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 165,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FDM Oscillator.mq4",
    "type": "Custom Indicator",
    "loc": 250,
    "indicators": [
      "iATR",
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FEDTM Billioner.mq4",
    "type": "Expert Advisor",
    "loc": 691,
    "indicators": [],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "FFCal Panel (Black).mq4",
    "type": "Custom Indicator",
    "loc": 885,
    "indicators": [],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FFCal.mq4",
    "type": "Custom Indicator",
    "loc": 830,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "fibo retracement 1.01.mq4",
    "type": "Custom Indicator",
    "loc": 457,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FiboFan_8_TRO_MODIFIED_VERSION.mq4",
    "type": "Custom Indicator",
    "loc": 459,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FiboPivotandRSI.mq4",
    "type": "Expert Advisor",
    "loc": 400,
    "indicators": [
      "iRSI"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "FiboRetracement3.mq4",
    "type": "Custom Indicator",
    "loc": 420,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FiboSequenceMTF 600+.mq4",
    "type": "Custom Indicator",
    "loc": 190,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "fibo_s 600+.mq4",
    "type": "Custom Indicator",
    "loc": 262,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FibProgression.mq4",
    "type": "Custom Indicator",
    "loc": 60,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "fiji-bb-alert.mq4",
    "type": "Custom Indicator",
    "loc": 126,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "fiji-trend-indicator.mq4",
    "type": "Custom Indicator",
    "loc": 210,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Filter overRSI.mq4",
    "type": "Custom Indicator",
    "loc": 81,
    "indicators": [
      "iRSI"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Filter v2.01.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 383,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FILTER-EXTRA.mq4",
    "type": "Custom Indicator",
    "loc": 187,
    "indicators": [
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Filter_AO.mq4",
    "type": "Custom Indicator",
    "loc": 54,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Find Data Holes.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 26,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Firebird HMA [i].mq4",
    "type": "Custom Indicator",
    "loc": 45,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Firebird MC v058.mq4",
    "type": "Expert Advisor",
    "loc": 184,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird MC v0581.mq4",
    "type": "Expert Advisor",
    "loc": 184,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird MC v0582.mq4",
    "type": "Expert Advisor",
    "loc": 184,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird MC v0583.mq4",
    "type": "Expert Advisor",
    "loc": 184,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.50(26JUL05).mq4",
    "type": "Expert Advisor",
    "loc": 75,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.50.mq4",
    "type": "Expert Advisor",
    "loc": 75,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.51.mq4",
    "type": "Expert Advisor",
    "loc": 71,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.55.mq4",
    "type": "Expert Advisor",
    "loc": 114,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.56 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 122,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.57 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 123,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.57.mq4",
    "type": "Expert Advisor",
    "loc": 123,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.58 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 147,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.60 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 174,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.61.01 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 185,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.61.01 [ea]5.mq4",
    "type": "Expert Advisor",
    "loc": 185,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.62 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 186,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.63 [ea].mq4",
    "type": "Expert Advisor",
    "loc": 193,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.63.mq4",
    "type": "Expert Advisor",
    "loc": 246,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.64.mq4",
    "type": "Expert Advisor",
    "loc": 235,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0.65.mq4",
    "type": "Expert Advisor",
    "loc": 236,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v01.57.mq4",
    "type": "Expert Advisor",
    "loc": 123,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v060.mq4",
    "type": "Expert Advisor",
    "loc": 174,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v065tf.mq4",
    "type": "Expert Advisor",
    "loc": 244,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0_58_JD.mq4",
    "type": "Expert Advisor",
    "loc": 180,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v0_58_symbol_fix.mq4",
    "type": "Expert Advisor",
    "loc": 175,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v3[1].2-fixed.mq4",
    "type": "Expert Advisor",
    "loc": 581,
    "indicators": [
      "iMA",
      "iRSI",
      "iATR",
      "iRVI"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v63 TVD1.mq4",
    "type": "Expert Advisor",
    "loc": 387,
    "indicators": [
      "iMA",
      "iRVI"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v63 TVD2.mq4",
    "type": "Expert Advisor",
    "loc": 387,
    "indicators": [
      "iMA",
      "iRVI"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v63B1.mq4",
    "type": "Expert Advisor",
    "loc": 210,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird v63D1.mq4",
    "type": "Expert Advisor",
    "loc": 436,
    "indicators": [
      "iMA",
      "iRVI"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird [i].mq4",
    "type": "Custom Indicator",
    "loc": 72,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Firebird_v0[1].60__ea_.mq4",
    "type": "Expert Advisor",
    "loc": 174,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firebird_v0_60_deaz1.mq4",
    "type": "Expert Advisor",
    "loc": 178,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Firestats v0.5.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 37,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Fisher_mbk.mq4",
    "type": "Custom Indicator",
    "loc": 90,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FL11.mq4",
    "type": "Custom Indicator",
    "loc": 104,
    "indicators": [
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FlyBot EA 2.0.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1131,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Forex Distance.mq4",
    "type": "Custom Indicator",
    "loc": 142,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Forex Fireball by Forex Robot Nation~.mq4",
    "type": "Expert Advisor",
    "loc": 578,
    "indicators": [
      "iMA",
      "iRSI",
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Forex Goats SA Bar Meter.mq4",
    "type": "Custom Indicator",
    "loc": 1509,
    "indicators": [
      "iMA",
      "iMACD",
      "iStochastic",
      "iSAR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Forex hacked Pro~.mq4",
    "type": "Expert Advisor",
    "loc": 1438,
    "indicators": [
      "iRSI"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Forex PiP Killer .mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1087,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Forex Robotron v1.3_fix_x.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1828,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Forex scalping indicator.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 243,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Forex WINNER EA (FULL2019).mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1069,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Forex-Gold-Trader-V.2.0.mq4",
    "type": "Expert Advisor",
    "loc": 392,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "forex-reversal-indicator.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 689,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "forex50pips.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 229,
    "indicators": [
      "iMA",
      "iBands"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "ForexCurrencyIndex.mq4",
    "type": "Custom Indicator",
    "loc": 523,
    "indicators": [
      "iMA",
      "iADX",
      "iSAR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "ForexHub Non Repaint King.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 233,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "ForexMission.mq4",
    "type": "Expert Advisor",
    "loc": 2406,
    "indicators": [
      "iMA",
      "iRSI",
      "iMACD",
      "iStochastic"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "ForexMT4Systems_Cycle.mq4",
    "type": "Custom Indicator",
    "loc": 439,
    "indicators": [
      "iMA",
      "iRSI",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "ForexOffTrend_Alert.mq4",
    "type": "Custom Indicator",
    "loc": 99,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "ForexProfitSupreme Meter-2.mq4",
    "type": "Custom Indicator",
    "loc": 1128,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Forexprofitsupreme Signal.mq4",
    "type": "Custom Indicator",
    "loc": 128,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Fourier_extrapolator.mq4",
    "type": "Custom Indicator",
    "loc": 186,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FoZo System.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 394,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Fractal - channel breakout 1.01.mq4",
    "type": "Custom Indicator",
    "loc": 228,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Fractal - channel breakout.mq4",
    "type": "Custom Indicator",
    "loc": 225,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Fractals (Bill Williams).mq4",
    "type": "Custom Indicator",
    "loc": 131,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FractalsMD_v3.2 600+.mq4",
    "type": "Custom Indicator",
    "loc": 250,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FractalZigZagNoRepaint.mq4",
    "type": "Custom Indicator",
    "loc": 116,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Fracture-7.4.0.mq4",
    "type": "Expert Advisor",
    "loc": 287,
    "indicators": [
      "iMA",
      "iATR",
      "iADX",
      "iFractals"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": false
  },
  {
    "name": "FreeScalper.mq4",
    "type": "Expert Advisor",
    "loc": 238,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "fx street 2.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 14,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FX5 Fibospiral v1.2.mq4",
    "type": "Custom Indicator",
    "loc": 148,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FX87 code.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2075,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "FXCore100.mq4",
    "type": "Expert Advisor",
    "loc": 440,
    "indicators": [
      "iMA",
      "iRSI",
      "iBands",
      "iStochastic"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "FXMIND SCALPANDO H1 STANDARD 300$.mq4",
    "type": "Expert Advisor",
    "loc": 2134,
    "indicators": [
      "iMA",
      "iRSI",
      "iMACD",
      "iStochastic"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "FXMIND SCALPANDO H1 STANDARD.mq4",
    "type": "Expert Advisor",
    "loc": 2134,
    "indicators": [
      "iMA",
      "iRSI",
      "iMACD",
      "iStochastic"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "FXTT_Fx_Scanner.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1901,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Gann_SQ9_2.mq4",
    "type": "Custom Indicator",
    "loc": 372,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Gary.BaludaSuperCSS.v.2.0.mq4",
    "type": "Custom Indicator",
    "loc": 1563,
    "indicators": [
      "iMA",
      "iATR"
    ],
    "is_martingale": true,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "GEBA ROBOT.mq4",
    "type": "Expert Advisor",
    "loc": 169,
    "indicators": [
      "iMA",
      "iRSI",
      "iADX"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "GEBA ROBOT2.mq4",
    "type": "Expert Advisor",
    "loc": 169,
    "indicators": [
      "iMA",
      "iRSI",
      "iADX"
    ],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Generic v13.20.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 3195,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Givonly_SnR_SnD_modM15 [saol].mq4",
    "type": "Custom Indicator",
    "loc": 215,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "GMACD2.mq4",
    "type": "Custom Indicator",
    "loc": 238,
    "indicators": [
      "iMACD"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "goertzel_browser_5.602 @freeindecators.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 1754,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "GOLD SMART EA 1.mq4",
    "type": "Expert Advisor",
    "loc": 109,
    "indicators": [
      "iMA"
    ],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Gold.mq4",
    "type": "Expert Advisor",
    "loc": 117,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Golden MA MTF TT [x5] (1).mq4",
    "type": "Utility / Indicator Helper",
    "loc": 516,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Golden MA MTF TT [x5] button.mq4",
    "type": "Custom Indicator",
    "loc": 289,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": true
  },
  {
    "name": "Golden MA MTF TT [x5].mq4",
    "type": "Utility / Indicator Helper",
    "loc": 516,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Golden Owl source code.mq4",
    "type": "Expert Advisor",
    "loc": 1595,
    "indicators": [
      "iMA"
    ],
    "is_martingale": true,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Golden_section_v3.2.mq4",
    "type": "Custom Indicator",
    "loc": 765,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "GoldFX_Filter.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 401,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Gold_Line_FX_CM_Pro.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 2239,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "Good good.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 955,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "GoWithFlow.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 927,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  },
  {
    "name": "GPSForexRobotEURGBP_edu.mq4",
    "type": "Expert Advisor",
    "loc": 1187,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "GPSForexRobotEURUSD_edu.mq4",
    "type": "Expert Advisor",
    "loc": 1177,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "GPSForexRobotUSDCHF_edu.mq4",
    "type": "Expert Advisor",
    "loc": 1187,
    "indicators": [],
    "is_martingale": false,
    "has_sl": true,
    "has_tp": true
  },
  {
    "name": "Grail.mq4",
    "type": "Utility / Indicator Helper",
    "loc": 259,
    "indicators": [],
    "is_martingale": false,
    "has_sl": false,
    "has_tp": false
  }
];
