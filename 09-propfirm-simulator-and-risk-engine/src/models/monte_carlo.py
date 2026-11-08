"""
monte_carlo.py
High-performance vectorized Monte Carlo simulation engine for prop firm evaluations.
Accurately models trade-by-trade and intraday equity dynamics under:
  - Static Drawdown
  - End-of-Day (EOD) Trailing Drawdown
  - Real-Time Intraday Trailing Peak Drawdown
  - Daily Loss Limits (Balance vs Equity based)
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple
import numpy as np
import pandas as pd

from ..rules.firm_catalog import PropFirmRule, DrawdownType


@dataclass
class TraderProfile:
    win_rate: float            # e.g. 0.52 (52%)
    reward_to_risk: float      # e.g. 1.5 (Wins pay 1.5x risk)
    risk_per_trade_pct: float  # e.g. 0.0075 (0.75% per trade)
    trades_per_day: int        # e.g. 3 trades/day
    slippage_commission_pct: float = 0.0003  # 3 bps friction per trade

    @property
    def expected_trade_return_pct(self) -> float:
        # E[R] = p * (f * R) - (1-p) * f - friction
        return (self.win_rate * self.reward_to_risk - (1.0 - self.win_rate)) * self.risk_per_trade_pct - self.slippage_commission_pct

    @property
    def trade_variance(self) -> float:
        w_gain = self.risk_per_trade_pct * self.reward_to_risk
        l_loss = -self.risk_per_trade_pct
        p = self.win_rate
        e_r = p * w_gain + (1.0 - p) * l_loss
        var = p * ((w_gain - e_r) ** 2) + (1.0 - p) * ((l_loss - e_r) ** 2)
        return var


@dataclass
class SimulationSummary:
    firm_name: str
    total_paths: int
    pass_rate_overall: float
    pass_rate_phase1: float
    pass_rate_phase2: float
    ruin_rate_overall: float
    ruin_due_to_daily_dd_pct: float
    ruin_due_to_max_dd_pct: float
    expected_days_to_pass: float
    median_days_to_pass: float
    min_days_required: int
    percentiles: Dict[str, np.ndarray]
    sample_equity_curves: List[np.ndarray]

    def to_dict(self) -> Dict:
        return {
            "Firm": self.firm_name,
            "Overall Pass Rate (%)": round(self.pass_rate_overall * 100.0, 2),
            "Phase 1 Pass Rate (%)": round(self.pass_rate_phase1 * 100.0, 2),
            "Phase 2 Pass Rate (%)": round(self.pass_rate_phase2 * 100.0, 2),
            "Overall Ruin Rate (%)": round(self.ruin_rate_overall * 100.0, 2),
            "Daily DD Breach Rate (%)": round(self.ruin_due_to_daily_dd_pct * 100.0, 2),
            "Max DD Breach Rate (%)": round(self.ruin_due_to_max_dd_pct * 100.0, 2),
            "Expected Days to Pass": round(self.expected_days_to_pass, 1),
            "Median Days to Pass": round(self.median_days_to_pass, 1),
        }


class PropFirmSimulator:
    """
    Simulates thousands of trader evaluation attempts against exact prop firm rules.
    """

    def __init__(
        self,
        firm_rule: PropFirmRule,
        trader_profile: TraderProfile,
        account_size: float = 100_000.0,
        max_simulation_days: int = 120,
        seed: Optional[int] = 42,
    ):
        self.firm = firm_rule
        self.trader = trader_profile
        self.account_size = account_size
        self.max_simulation_days = max_simulation_days
        self.seed = seed

    def simulate(self, num_paths: int = 5000) -> SimulationSummary:
        if self.seed is not None:
            np.random.seed(self.seed)

        n_phases = len(self.firm.phases)
        paths_completed = np.zeros(num_paths, dtype=bool)
        phase1_passed = np.zeros(num_paths, dtype=bool)
        phase2_passed = np.zeros(num_paths, dtype=bool)
        
        daily_breach = np.zeros(num_paths, dtype=bool)
        max_breach = np.zeros(num_paths, dtype=bool)
        
        days_to_pass = []
        equity_trajectories = np.zeros((num_paths, self.max_simulation_days + 1))
        equity_trajectories[:, 0] = self.account_size

        for i in range(num_paths):
            current_balance = self.account_size
            current_phase_idx = 0
            is_active = True
            days_spent = 0

            # Set up Phase 1
            phase_initial_balance = current_balance
            target_amount = phase_initial_balance * (1.0 + self.firm.phases[current_phase_idx].profit_target_pct / 100.0)
            
            # Drawdown floor
            if self.firm.drawdown_type == DrawdownType.STATIC:
                max_dd_floor = phase_initial_balance * (1.0 - self.firm.max_drawdown_pct / 100.0)
            else:
                max_dd_floor = phase_initial_balance * (1.0 - self.firm.max_drawdown_pct / 100.0)
                
            high_water_mark = current_balance
            phase_trading_days = 0

            for day in range(1, self.max_simulation_days + 1):
                if not is_active:
                    equity_trajectories[i, day:] = current_balance
                    break

                days_spent += 1
                phase_trading_days += 1
                start_of_day_balance = current_balance
                start_of_day_equity = current_balance

                # Daily loss limit threshold
                if self.firm.daily_drawdown_pct > 0:
                    daily_loss_limit = start_of_day_balance * (self.firm.daily_drawdown_pct / 100.0)
                else:
                    daily_loss_limit = float("inf")

                # Generate trades for this day
                n_trades = self.trader.trades_per_day
                wins = np.random.rand(n_trades) < self.trader.win_rate
                
                day_pnl = 0.0
                day_min_pnl = 0.0
                intraday_equity = start_of_day_equity

                for t_idx in range(n_trades):
                    is_win = wins[t_idx]
                    # Risk amount
                    risk_dollars = current_balance * self.trader.risk_per_trade_pct
                    friction = risk_dollars * self.trader.slippage_commission_pct

                    if is_win:
                        trade_pnl = risk_dollars * self.trader.reward_to_risk - friction
                    else:
                        trade_pnl = -risk_dollars - friction

                    intraday_equity += trade_pnl
                    day_pnl += trade_pnl
                    day_min_pnl = min(day_min_pnl, day_pnl)

                    # Update trailing peak if intraday trailing
                    if self.firm.drawdown_type == DrawdownType.TRAILING_INTRADAY:
                        if intraday_equity > high_water_mark:
                            high_water_mark = intraday_equity
                            # Move trailing floor up
                            new_floor = high_water_mark * (1.0 - self.firm.max_drawdown_pct / 100.0)
                            # Cap trailing floor at initial balance if firm stops trailing at starting balance
                            max_dd_floor = max(max_dd_floor, new_floor)

                        # Check intraday breach
                        if intraday_equity <= max_dd_floor:
                            is_active = False
                            max_breach[i] = True
                            current_balance = intraday_equity
                            break

                if not is_active:
                    equity_trajectories[i, day] = current_balance
                    break

                # Check Daily Drawdown breach
                if abs(day_min_pnl) >= daily_loss_limit:
                    is_active = False
                    daily_breach[i] = True
                    current_balance += day_min_pnl
                    equity_trajectories[i, day] = current_balance
                    break

                # End of day balance update
                current_balance += day_pnl
                equity_trajectories[i, day] = current_balance

                # Update trailing peak for EOD or Relative
                if self.firm.drawdown_type in [DrawdownType.TRAILING_EOD, DrawdownType.RELATIVE]:
                    if current_balance > high_water_mark:
                        high_water_mark = current_balance
                        new_floor = high_water_mark * (1.0 - self.firm.max_drawdown_pct / 100.0)
                        # Topstep and E8 lock trailing drawdown at initial balance
                        if self.firm.firm_id in ["topstep_combine", "take_profit_trader", "tradeday_evaluation", "e8_markets_classic"]:
                            new_floor = min(phase_initial_balance, new_floor)
                        max_dd_floor = max(max_dd_floor, new_floor)

                # Check EOD Max Drawdown breach
                if current_balance <= max_dd_floor:
                    is_active = False
                    max_breach[i] = True
                    break

                # Check Phase Profit Target Passed
                min_days = self.firm.phases[current_phase_idx].min_trading_days
                if current_balance >= target_amount and phase_trading_days >= min_days:
                    if current_phase_idx == 0:
                        phase1_passed[i] = True
                    elif current_phase_idx == 1:
                        phase2_passed[i] = True

                    current_phase_idx += 1
                    if current_phase_idx >= n_phases:
                        # Fully passed all phases!
                        paths_completed[i] = True
                        days_to_pass.append(days_spent)
                        is_active = False
                        equity_trajectories[i, day:] = current_balance
                        break
                    else:
                        # Advance to next phase
                        phase_initial_balance = current_balance
                        target_amount = phase_initial_balance * (1.0 + self.firm.phases[current_phase_idx].profit_target_pct / 100.0)
                        if self.firm.drawdown_type == DrawdownType.STATIC:
                            max_dd_floor = phase_initial_balance * (1.0 - self.firm.max_drawdown_pct / 100.0)
                        else:
                            max_dd_floor = phase_initial_balance * (1.0 - self.firm.max_drawdown_pct / 100.0)
                        high_water_mark = current_balance
                        phase_trading_days = 0

        # Compile statistics
        p_pass = float(np.mean(paths_completed))
        p_p1 = float(np.mean(phase1_passed))
        p_p2 = float(np.mean(phase2_passed)) if n_phases > 1 else p_p1
        p_daily = float(np.mean(daily_breach))
        p_max = float(np.mean(max_breach))
        p_ruin = float(np.mean(daily_breach | max_breach))
        
        avg_days = float(np.mean(days_to_pass)) if days_to_pass else float(self.max_simulation_days)
        med_days = float(np.median(days_to_pass)) if days_to_pass else float(self.max_simulation_days)

        # Percentile fans
        p5 = np.percentile(equity_trajectories, 5, axis=0)
        p25 = np.percentile(equity_trajectories, 25, axis=0)
        p50 = np.percentile(equity_trajectories, 50, axis=0)
        p75 = np.percentile(equity_trajectories, 75, axis=0)
        p95 = np.percentile(equity_trajectories, 95, axis=0)

        sample_paths = [equity_trajectories[k] for k in range(min(15, num_paths))]

        return SimulationSummary(
            firm_name=self.firm.name,
            total_paths=num_paths,
            pass_rate_overall=p_pass,
            pass_rate_phase1=p_p1,
            pass_rate_phase2=p_p2,
            ruin_rate_overall=p_ruin,
            ruin_due_to_daily_dd_pct=p_daily,
            ruin_due_to_max_dd_pct=p_max,
            expected_days_to_pass=avg_days,
            median_days_to_pass=med_days,
            min_days_required=sum(p.min_trading_days for p in self.firm.phases),
            percentiles={"p5": p5, "p25": p25, "p50": p50, "p75": p75, "p95": p95},
            sample_equity_curves=sample_paths,
        )
