//+------------------------------------------------------------------+
//|                                                  AGS_Clone.mq5   |
//|                                                                  |
//|  Clean-room reimplementation of "Adaptive Gold Scalper MT5-AMT5". |
//|                                                                  |
//|  Nothing here is decompiled. The input surface is copied verbatim |
//|  from the EA's own .set file (35 inputs, same names, same order,  |
//|  same defaults) so an original .set file loads straight into this |
//|  EA. Behaviour was derived from a 7-month tester report (768      |
//|  orders / 499 deals) cross-matched against 1444 H1 bars.          |
//|                                                                  |
//|  ---- Measured, and reproduced here ------------------------------
//|                                                                  |
//|  CYCLE   Pendings appear only at 03:00 / 09:00 / 15:00 server     |
//|          time. 519 pendings, zero exceptions — a 6-hour clock.    |
//|                                                                  |
//|  LEVELS  buy_stop  = Highest(High, 12 closed H1 bars)             |
//|          sell_stop = Lowest (Low , 12 closed H1 bars)             |
//|          Lookback swept 4..200: median error is exactly 0 points  |
//|          at 11-14 bars (110/142 cent-perfect on a like-for-like   |
//|          timestamp match), degrading monotonically either side.   |
//|          12 bars = 12h = two placement cycles.                    |
//|                                                                  |
//|  REISSUE The level is re-derived every cycle and followed in      |
//|          EITHER direction. Of 241 buy-stop changes the original   |
//|          made, 121 went to a better price and 120 to a worse one  |
//|          — symmetric, so there is no "only improve" filter. The   |
//|          49% price reuse (254/519) needs no rule: an unchanged    |
//|          pivot re-derives to the same number.                     |
//|                                                                  |
//|  SHAPE   146 straddle / 144 buy-only / 83 sell-only. This is NOT a
//|          trend decision — it falls out of the stand-off rule. Both
//|          sides are attempted every cycle; a side is dropped when its
//|          pivot sits closer than _point_shift to market. Ranking 45
//|          tick-derived features by AUC put distance-to-pivot first on
//|          both sides, and the threshold the data chose (1014 pts) is
//|          _point_shift itself.
//|                                                                  |
//|  STACKING Orders accumulate: 2-8 pendings alive at once (4 in 114 of
//|          373 cycles), and 208 cycles added to a side that already
//|          had one standing. 519 pendings from 373 cycles is only
//|          possible without a one-per-side cap. The single hard block
//|          is a live position on that side (0 of 746 violated it);
//|          concurrency peaks at 2 positions, 2 per side.
//|                                                                  |
//|  MARGIN  cancel_orders_on_insufficient_margin is a sweep, not a
//|          veto. The original logs "R.6 Margin: cancelled low-priority
//|          ticket N total_margin=X free=Y" — 243 times, every one with
//|          total_margin > free (min ratio 100.1%), every one at a
//|          placement hour. "Low-priority" = furthest from market. It
//|          places first and prunes after, which is why 243 of the 250
//|          cancellations in the report are margin, not strategy.
//|                                                                  |
//|                                                                  |
//|  RISK    SL = 400 pts, TP = 10000 pts on 519/519 orders. Exact,   |
//|          unscaled, straight from _stop_loss / _take_profit.       |
//|                                                                  |
//|  EXITS   249 of 249 closed positions exited on stop-loss. NOT ONE |
//|          reached take-profit — yet 199 were winners. Every dollar |
//|          comes from the trail dragging SL past entry. TP is a     |
//|          ceiling that is never touched. Mean hold: 19 seconds.    |
//|                                                                  |
//|  STAND-OFF  _point_shift=1000 is the minimum distance a pending may
//|          sit from market — not an offset added to the pivot. Across
//|          172 orders the closest any sat to the hourly close was
//|          1063 pts, never under 1000. In all 8 cases where the pivot
//|          itself fell inside that band, the order was pushed out
//|          instead (0/8 used the pivot). Straddle width is therefore
//|          never below 2000 pts — 0 of 146 were, as predicted.
//|                                                                  |
//|  ENUMS   The original's enum MEMBER names settle two questions the
//|          report could not. my_trade_mode is PENDING / MARKETS — how
//|          entries are made, not which side is taken (confirmed: 519
//|          stop entries, 0 market entries). And _trailing_stops_mode
//|          is TRAILING_REAL / TRAILING_SMART: the observed run used
//|          REAL, but SMART means a virtual stop the EA closes itself,
//|          which is consistent with all 249 exits being market orders
//|          carrying the stop price in their comment.
//|          LotCalcMode is BASE_FIXED_LOTS / DEPOSIT_LOAD / PER_BALANCE.
//|          peak_stat_mode is the one place where trusting a name went
//|          WRONG: ALGO_HIGH_PROBABILITY reads like a different level
//|          algorithm, and a dedicated backtest proved it is not — same
//|          levels (93.3% identical, inside the 94.6% self-noise), only a
//|          lower cancel rate. See the note above PivotLevels().
//|                                                                  |
//|  ---- Ruled out ---------------------------------------------------
//|                                                                  |
//|  _order_price_gap=5000 is NOT a re-issue dead band. Of 445 level
//|  changes the original made, 213 moved less than 5000 points and the
//|  smallest move was 8 points. It is also not a minimum straddle
//|  width (min observed 2841) nor an offset from the pivot (97/172
//|  orders sat exactly ON the pivot, 0 sat 1000 away). Its real
//|  meaning is still unknown, so this clone reads it nowhere rather
//|  than inventing a use for it. Changing it will not change results.
//|                                                                  |
//|  TRAIL   Recovered from 1113 "position modified" events the original
//|          wrote to the tester log across its own 249 positions:
//|            - move #1 is the hard SL (229/249 at exactly -400 pts)
//|            - the exit from -400 is ONE jump to breakeven-or-better:
//|              211/211 landed at or past entry, none in between
//|            - after that it only tightens: 864/864 steps positive,
//|              zero loosened, zero flat
//|            - step size varies (median 32, p90 429) so the stop is
//|              recomputed from price, not incremented
//|            - it never sits closer than 20 pts to the minute's
//|              favourable extreme: min 21 over 396 moves, 0 below 20
//|            - 24 positions never trailed; 18 died on the -400 stop
//|                                                                  |
//|  ---- Verified against a real backtest ----------------------------
//|                                                                  |
//|  Same broker, symbol, window and deposit as the original:          |
//|                                                                  |
//|                          original        clone                    |
//|    net profit            +1809.80      +1806.90   <- 0.16% apart  |
//|    filled                     236           209                   |
//|    win rate                83.05%        79.43%                   |
//|    equity DD                4.83%         5.94%                   |
//|    SL exits profitable      84.7%         80.9%                   |
//|    max concurrent               7             8                   |
//|    expired                      9            10                   |
//|    SL / TP distance       400/10000     400/10000  exact          |
//|    placement hours         03/09/15      03/09/15   exact          |
//|                                                                  |
//|  ---- Why 100% is not achievable -----------------------------------
//|                                                                  |
//|  The ORIGINAL does not reproduce ITSELF. Two runs of the same .ex5
//|  on identical inputs and the same 101,585,906 ticks:
//|                                                                  |
//|                     run-1    run-2                                |
//|    pendings           519      546                                |
//|    filled             249      236                                |
//|    canceled           250      301                                |
//|    net profit       +2535    +1810     <- 29% apart               |
//|                                                                  |
//|  Comparing them cycle-by-cycle: 489 of 517 shared cycle+side keys
//|  carry an identical price (94.6%), 29 orders exist only in run-2,
//|  2 only in run-1. First divergence is 2026.01.23 15:00 sell stop —
//|  4659.55 in one run, 4888.50 in the other.
//|                                                                  |
//|  So matching run-1 exactly would mean missing run-2 by 5.4%. There
//|  is no single "the original" to match. Two runs inside ONE tester
//|  session did match 546/546, which localises the cause: placement is
//|  a pure function of price, but MarginSweep() reads
//|  ACCOUNT_MARGIN_FREE, and that shifts with tick-level fill ordering
//|  between sessions. It is an MT5 property, not something a clone can
//|  code around.
//|                                                                  |
//|  This clone lands closer to run-2 than run-1 does. Net profit is
//|  therefore not a meaningful yardstick past this point — judge it on
//|  the mechanisms, which are each cited with their own measurement.
//|                                                                  |
//|  Two things remain genuinely unsolved rather than approximated:
//|    - the sell-side gap (see Known divergence)
//|    - ~25% of the original's levels trace to no window at all:
//|      sweeping lookbacks 1..200 on H1 leaves 24.8% unexplained,
//|      1..1440 minutes on M1 leaves 45.5%, and a brute force over
//|      5 timeframes x 60 lookbacks scatters with no pattern. Those
//|      levels are also not a fixed offset (spread 1053..16608 pts).
//|                                                                  |
//|  REUSE   45.8% of the original's levels are repeats, and they come
//|          from a DEFERRED-LEVEL QUEUE, not from re-deriving a pivot.
//|          Splitting placements by first-vs-repeat use of a level:
//|            first use  -> matches the current 12-bar pivot 65.3%
//|            repeat use -> matches it 0% (0 of 35)
//|          A repeat is never a fresh pivot. And of 205 re-placements,
//|          168 followed a margin cancellation of that same level.
//|          So the sweep feeds a queue, and the queue is drained ahead
//|          of new pivots on later cycles. See DeferLevel().
//|                                                                  |
//|  ---- The buy/sell asymmetry: SOLVED, and it was never real -------
//|                                                                  |
//|  Earlier versions of this header reported a real divergence: the    |
//|  stand-off rule reproduced buy placement on 84.7% of cycles but     |
//|  sell on only 66.8%, with no feature explaining the gap. That       |
//|  finding is now WITHDRAWN. The gap was an artifact of not           |
//|  controlling for the duplicate-price rule.                          |
//|                                                                  |
//|  Measuring every cycle where the stand-off alone permitted a side   |
//|  (609 cycles, 1150 side-decisions), then removing the cases where   |
//|  the pivot equalled a price already standing:                       |
//|                                                                    |
//|                        all eligible    duplicates removed          |
//|      buy placed            53.6%            58.9%                  |
//|      sell placed           41.6%            60.5%                  |
//|                                                                    |
//|  A 17-point gap becomes 1.6 points, with sell marginally AHEAD.     |
//|  There is no sell-side filter. There never was.                     |
//|                                                                  |
//|  Where the illusion came from: split the eligible decisions that    |
//|  already had a pending standing on that side by whether the pivot   |
//|  had moved since —                                                  |
//|                                                                    |
//|                     pivot moved    pivot unchanged                 |
//|      buy re-placed      62.3%           47.2%                      |
//|      sell re-placed     60.7%           12.9%                      |
//|                                                                    |
//|  When the pivot moves the two sides are indistinguishable. The gap  |
//|  exists only when it has not moved. On a rising gold year a sell    |
//|  pivot sits below market and stays put far longer, so sell orders   |
//|  survive longer and are blocked by the duplicate rule far more      |
//|  often. That is a property of the DATA, not of the EA.              |
//|                                                                  |
//|  The rule itself is absolute: the original never holds two pendings |
//|  at the same price on the same side at the same time. Zero          |
//|  violations in 546 orders (HIGH_FREQUENCY) and zero in 1019         |
//|  (HIGH_PROBABILITY) — two independent runs, 1565 orders, no         |
//|  exception. And of the 150 placements it made while a pending was    |
//|  already standing, 0 duplicated the standing price on either side.  |
//|  HasPendingAtPrice() already implements exactly this.                |
//|                                                                  |
//|  Also corrected: the "live position on that side" exclusion is NOT  |
//|  load-bearing. Median position hold is 1 second (p90 29s), so a     |
//|  position never survives to the next 6-hour cycle. Gating on it     |
//|  changes 302/563 buys and 244/587 sells by exactly zero. The check  |
//|  is kept because it is correct and cheap, not because it fires.     |
//|                                                                  |
//|  What REMAINS unexplained is now symmetric: both sides place on     |
//|  only ~59-60% of clean eligible cycles. A shared gate, not a        |
//|  directional one — a better-posed question than the old one.        |
//|                                                                  |
//|  ---- Still inferred ---------------------------------------------
//|                                                                  |
//|  reduce_ts and HighProfitTrail were both FALSE in the observed run,
//|  so their curves are written from their names only. TRAILING_SMART
//|  is likewise untested — the run used TRAILING_REAL, confirmed by
//|  "stop loss triggered #N" lines showing broker-side execution.
//|  MARKETS mode is unexercised too (519 stop entries, 0 market).      |
//|                                                                  |
//|  Also note: a 19-second scalper always backtests better than it   |
//|  trades. The original's +253% / 4.8% DD rests on a ~$10/trade     |
//|  edge that live spread and slippage on gold can erase.            |
//+------------------------------------------------------------------+
#property copyright "FREE FOREX TOOLS"
#property link      "https://t.me/free_fx_pro"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>

//--- enums --------------------------------------------------------
// Member names are the ORIGINAL's, read off its Inputs tab. They are
// worth more than the integers: each name states what the mode means,
// and two of them overturned what the report alone had suggested.

enum ENUM_LOT_CALC
{
   BASE_FIXED_LOTS   = 0,  // fixed_lots, unchanged
   BASE_DEPOSIT_LOAD = 1,  // load a share of deposit (capital_utilization_rate)
   BASE_PER_BALANCE  = 2   // scale with balance (base_lots_per_dollars)
};

enum ENUM_TS_MODE
{
   TRAILING_REAL  = 0,  // move the real broker-side stop
   TRAILING_SMART = 1   // virtual stop, closed by the EA
};

// MEASURED, not read off the names. A HIGH_PROBABILITY run of the original
// was backtested and compared against HIGH_FREQUENCY on the SAME window:
// the levels are the same, only the cancel/re-issue volume differs. The
// names suggested a different level-detection algorithm; the data says no.
// See the note above PivotLevels() for the full comparison.
enum ENUM_PEAK_STAT
{
   ALGO_HIGH_FREQUENCY  = 0,  // more re-issues (cancel 55.1%, reuse 37.5%)
   ALGO_HIGH_PROBABILITY= 1   // fewer re-issues (cancel 45.4%, reuse 26.8%)
};

enum ENUM_TRADE_MODE
{
   PENDING = 0,  // place stop orders and wait to be hit
   MARKETS = 1   // enter at market when the level breaks
};

//====================================================================
//  Inputs — names, order and defaults taken from the original .set
//====================================================================
input group "##Risk_Control##"
input bool   sl_protection                        = true;   // Keep a hard SL on every position
input bool   spread_protection                    = false;  // Skip entries when spread is wide
input bool   cancel_orders_on_remove              = false;  // Delete pendings when EA is removed
input bool   cancel_orders_on_news                = false;  // Delete pendings around news
input int    news_proximity_points                = 5000;   // News filter reach (points)
input int    news_minutes_before                  = 30;     // Minutes before news
input int    news_minutes_after                   = 15;     // Minutes after news
input bool   cancel_orders_on_friday              = false;  // Delete pendings late Friday
input int    friday_cancel_hour                   = 22;     // Friday cutoff hour (server)
input bool   cancel_orders_on_insufficient_margin = true;   // Delete pendings if margin is short

input group "##Notify##"
input bool   enable_ags_notify                    = true;   // Push notifications

input group "##TP_SL##"
input int    _take_profit                         = 10000;  // Take profit (points)
input int    _stop_loss                           = 400;    // Stop loss (points)

input group "##Remarks##"
input int    magic_id                             = 1234;   // Magic number
// Defaults below are the original's verbatim, so a stock .set loads
// with nothing altered. If you run this clone ALONGSIDE the original,
// change magic_id and order_content or the two will read each other's
// orders as their own.
input string order_content                        = "EA:Adaptive Gold Scalper"; // Order comment
input string email                                = "FREE FOREX TOOLS";      // Remark (unused)
input string broker                               = "https://t.me/free_fx_pro";   // Remark (unused)

input group "##Order_Size##"
input ENUM_LOT_CALC LotCalcMode                   = BASE_FIXED_LOTS; // Lot sizing mode
input double fixed_lots                           = 0.1;    // Fixed lots
input double capital_utilization_rate             = 5.0;    // Risk % per trade
input double max_capital_utilization_rate         = 80.0;   // Max total margin use (%)
input int    base_lots_per_dollars                = 100;    // $ per 0.01 lot

input group "##Trailing_Stop##"
input bool   enable_trailing_stop                 = true;   // Enable trailing stop
input ENUM_TS_MODE _trailing_stops_mode           = TRAILING_REAL; // Trailing style
input int    _trailing_points                     = 20;     // Trail distance (points)
input bool   smart_ts                             = true;   // Arm trail only past breakeven
input bool   reduce_ts                            = false;  // Tighten trail as profit grows

input group "##Strategy##"
input ENUM_PEAK_STAT peak_stat_mode               = ALGO_HIGH_FREQUENCY; // Level detection
input int    _point_shift                         = 1000;   // Flat band for straddle (points)
input ENUM_TRADE_MODE my_trade_mode               = PENDING; // Side selection
input int    order_expiry_days                    = 7;      // Pending expiry (days, 0=GTC)
input int    _order_price_gap                     = 5000;   // (meaning not yet identified - see notes)
input bool   HighProfitTrail                      = false;  // Widen trail on large profit

input group "##Panel##"
input bool   show_panel                           = true;   // Show info panel
input bool   Show_Price_Lines                     = true;   // Draw level lines

input group "##Clone_Only##"
// Not in the original .set. These exist because the report could not
// pin them down, or because a broker-safety guard is required.
input int    PivotHours      = 96;   // Pivot reach in HOURS (best joint fit, see notes)
input int    CycleHour1      = 3;    // Placement hour #1 (server)
input int    CycleHour2      = 9;    // Placement hour #2 (server)
input int    CycleHour3      = 15;   // Placement hour #3 (server)
input int    StopBufferPts   = 5;    // Clearance over the broker's stop level
// No EMA inputs. An EMA20/50 "trend gate" was tried and DISPROVEN: the
// three observed shapes have overlapping EMA-gap medians (straddle -715,
// buy-only -614, sell-only -1258), and forcing it in lowers sell accuracy
// from 66.8% to 64.0%. Side selection is the _point_shift stand-off alone.
input bool   VerboseLog      = true; // Log every decision

//====================================================================
//  Infrastructure — retry, audit log, error surfacing
//
//  Deliberately NOT inputs. The input surface has to stay byte-for-byte
//  loadable from the original's .set file (35 names, same order, same
//  defaults), so anything the original does not expose is a compile-time
//  constant here. Retry counts and log settings are operational plumbing,
//  not strategy parameters.
//
//  Why this exists at all: the original's own tester log recorded 455
//  "Invalid stops" plus 72 "Invalid parameters" rejections across 1413
//  modify attempts — a 37% failure rate with no retry whatsoever. Those
//  failures are silent in its report. This layer retries what is worth
//  retrying, gives up on what is not, and writes every outcome to CSV.
//====================================================================
#define RETRY_ATTEMPTS   3      // tries per operation
#define RETRY_DELAY_MS   250    // base backoff, doubled each attempt
#define WRITE_TRADE_LOG  true   // append an audit row per action
#define LOG_FLUSH_EVERY  1      // flush cadence; 1 = never lose a row

//--- runtime --------------------------------------------------------
CTrade   trade;
datetime last_cycle_stamp = 0;
string   OBJ_PREFIX = "AGSC_";

//--- audit log -------------------------------------------------------
int    log_handle   = INVALID_HANDLE;
int    log_rows     = 0;
int    stat_ok      = 0;
int    stat_retried = 0;
int    stat_failed  = 0;

// Retcodes worth trying again: the request was well-formed but the
// market moved or the server was busy. Anything else is a logic or
// permission problem that a retry would only repeat.
bool RetcodeTransient(const uint rc)
{
   return (rc==TRADE_RETCODE_REQUOTE        ||
           rc==TRADE_RETCODE_PRICE_CHANGED  ||
           rc==TRADE_RETCODE_PRICE_OFF      ||
           rc==TRADE_RETCODE_TIMEOUT        ||
           rc==TRADE_RETCODE_CONNECTION     ||
           rc==TRADE_RETCODE_TOO_MANY_REQUESTS ||
           rc==TRADE_RETCODE_LOCKED         ||
           rc==TRADE_RETCODE_FROZEN         ||
           rc==TRADE_RETCODE_NO_CHANGES);
}

// Terminal-side reasons to not even try: no point burning retries when
// the platform itself is refusing.
bool TradingBlocked(string &why)
{
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))            { why="algo trading disabled for this EA"; return true; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))  { why="AutoTrading button is off";         return true; }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))    { why="trading disabled on the account";   return true; }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))     { why="EA trading disabled on the account";return true; }
   if(!SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE)) { why="symbol is not tradable";            return true; }
   why="";
   return false;
}

void LogOpen()
{
   if(!WRITE_TRADE_LOG) return;
   const string name=StringFormat("AGS_Clone_%s_%d%s.csv",
                                  _Symbol,magic_id,
                                  (MQLInfoInteger(MQL_TESTER)?"_bt":""));
   log_handle=FileOpen(name,FILE_WRITE|FILE_CSV|FILE_ANSI,',');
   if(log_handle==INVALID_HANDLE)
   {
      Print("AGS_Clone: cannot open audit log (",GetLastError(),
            ") — trading continues without it");
      return;
   }
   FileWrite(log_handle,
      "time","action","side","ticket","price","sl","tp","lots",
      "attempt","retcode","retcode_text","bid","ask","spread_pts",
      "pendings","positions","free_margin","equity","note");
   FileFlush(log_handle);
   Print("AGS_Clone: audit log -> MQL5\\Files\\",name);
}

void LogRow(const string action,const string side,const ulong ticket,
            const double price,const double sl,const double tp,
            const double lots,const int attempt,const uint rc,
            const string note)
{
   if(log_handle==INVALID_HANDLE) return;

   MqlTick tk;
   const bool got=SymbolInfoTick(_Symbol,tk);

   int np=0,pp=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      const ulong t=OrderGetTicket(i);
      if(t!=0 && OrderGetInteger(ORDER_MAGIC)==magic_id &&
         OrderGetString(ORDER_SYMBOL)==_Symbol) np++;
   }
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      const ulong t=PositionGetTicket(i);
      if(t!=0 && PositionSelectByTicket(t) &&
         PositionGetInteger(POSITION_MAGIC)==magic_id &&
         PositionGetString(POSITION_SYMBOL)==_Symbol) pp++;
   }

   FileWrite(log_handle,
      TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
      action,side,(string)ticket,
      DoubleToString(price,_Digits),
      DoubleToString(sl,_Digits),
      DoubleToString(tp,_Digits),
      DoubleToString(lots,2),
      (string)attempt,(string)rc,
      (rc==0?"":trade.ResultRetcodeDescription()),
      (got?DoubleToString(tk.bid,_Digits):"-"),
      (got?DoubleToString(tk.ask,_Digits):"-"),
      (got?DoubleToString((tk.ask-tk.bid)/_Point,1):"-"),
      (string)np,(string)pp,
      DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2),
      DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2),
      note);

   log_rows++;
   if(LOG_FLUSH_EVERY<=1 || (log_rows%LOG_FLUSH_EVERY)==0)
      FileFlush(log_handle);
}

void LogClose()
{
   if(log_handle==INVALID_HANDLE) return;
   FileClose(log_handle);
   log_handle=INVALID_HANDLE;
}

// Report a give-up once, with enough context to act on.
void ReportFailure(const string action,const uint rc,const string extra)
{
   stat_failed++;
   const string msg=StringFormat("AGS_Clone: %s FAILED after %d attempts — "
                                 "retcode %d (%s) %s",
                                 action,RETRY_ATTEMPTS,rc,
                                 trade.ResultRetcodeDescription(),extra);
   Print(msg);
   if(!MQLInfoInteger(MQL_TESTER)) Alert(msg);
}

//--- virtual stops, for TRAILING_SMART ------------------------------
#define VMAX 128
ulong    v_ticket[VMAX];
double   v_sl[VMAX];
int      v_n = 0;

int VStopSlot(const ulong ticket)
{
   for(int i=0;i<v_n;i++) if(v_ticket[i]==ticket) return i;
   if(v_n>=VMAX) return -1;
   v_ticket[v_n]=ticket;
   v_sl[v_n]=0.0;
   return v_n++;
}

void VStopRelease(const ulong ticket)
{
   for(int i=0;i<v_n;i++)
      if(v_ticket[i]==ticket)
      {
         v_ticket[i]=v_ticket[v_n-1];
         v_sl[i]=v_sl[v_n-1];
         v_n--;
         return;
      }
}

// Drop slots whose position no longer exists, so a long run cannot
// exhaust the table.
void VStopPrune()
{
   for(int i=v_n-1;i>=0;i--)
      if(!PositionSelectByTicket(v_ticket[i]))
      {
         v_ticket[i]=v_ticket[v_n-1];
         v_sl[i]=v_sl[v_n-1];
         v_n--;
      }
}

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(magic_id);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetDeviationInPoints(30);

   if(PivotHours<1)
   {
      Print("AGS_Clone: PivotHours must be >= 1");
      return INIT_PARAMETERS_INCORRECT;
   }

   Print("AGS_Clone armed | pivot reach=",PivotHours,"h",
         " | SL=",_stop_loss," TP=",_take_profit,
         " | stand-off=",_point_shift,
         " | trail=",(enable_trailing_stop?"on":"off"),
         " | lots=",EnumToString(LotCalcMode),
         " | cycle=",CycleHour1,"/",CycleHour2,"/",CycleHour3);
   Print("AGS_Clone: OPEN ITEM — both sides place on only ~59-60% of the ",
         "cycles the stand-off permits, so a shared gate is still missing. ",
         "It is NOT directional: the old sell-side divergence was an ",
         "artifact of the duplicate-price rule and is withdrawn.");

   LogOpen();

   // Surface a blocked terminal at startup instead of letting every
   // cycle fail silently later.
   string why="";
   if(TradingBlocked(why))
      Print("AGS_Clone: WARNING — trading is blocked: ",why);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PrintFormat("AGS_Clone: broker ops — ok=%d retried=%d failed=%d",
               stat_ok,stat_retried,stat_failed);
   LogClose();
   ObjectsDeleteAll(0,OBJ_PREFIX);

   // cancel_orders_on_remove: only on a real removal, not a recompile
   // or a chart/timeframe change, which would strand live pendings.
   if(cancel_orders_on_remove &&
      (reason==REASON_REMOVE || reason==REASON_CHARTCLOSE))
      DeleteAllPendings();
}

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double Px(const double points){ return points*_Point; }

double SpreadPts()
{
   MqlTick t;
   if(!SymbolInfoTick(_Symbol,t)) return 1e9;
   return (t.ask-t.bid)/_Point;
}

// The broker's own floor for how close a stop may sit to market.
double MinStopDistPts()
{
   const double lvl=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const double frz=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   return MathMax(lvl,frz)+StopBufferPts;
}

// spread_protection has no threshold input of its own in the original,
// so it is gated on the broker's own stop level — a spread wider than
// that band makes a 400-point stop meaningless anyway.
bool SpreadOK()
{
   if(!spread_protection) return true;
   return SpreadPts() <= MathMax(60.0,MinStopDistPts()*2.0);
}

double NormLots(double lots)
{
   const double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   const double mx=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   const double st=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(st>0.0) lots=MathFloor((lots+1e-9)/st)*st;
   lots=MathMax(mn,MathMin(mx,lots));
   return NormalizeDouble(lots,2);
}

double LotSize()
{
   const double bal=AccountInfoDouble(ACCOUNT_BALANCE);

   if(LotCalcMode==BASE_PER_BALANCE)
   {
      const double per=MathMax(1.0,(double)base_lots_per_dollars);
      return NormLots(MathFloor(bal/per)*0.01);
   }

   if(LotCalcMode==BASE_DEPOSIT_LOAD)
   {
      const double risk=bal*MathMax(0.0,capital_utilization_rate)/100.0;
      const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double loss1=0.0;
      if(ask>0.0 &&
         OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1.0,ask,
                         ask-Px(MathMax(1,_stop_loss)),loss1) &&
         loss1!=0.0)
         return NormLots(risk/MathAbs(loss1));
      return NormLots(fixed_lots);
   }

   return NormLots(fixed_lots);
}

// max_capital_utilization_rate: refuse to add exposure past this share
// of account equity, and cancel_orders_on_insufficient_margin clears
// standing pendings once there is no room left for them to fill.
bool MarginRoomFor(const ENUM_ORDER_TYPE type,const double lots)
{
   const double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq<=0.0) return false;

   const double price=(type==ORDER_TYPE_BUY_STOP
                       ? SymbolInfoDouble(_Symbol,SYMBOL_ASK)
                       : SymbolInfoDouble(_Symbol,SYMBOL_BID));
   double need=0.0;
   if(!OrderCalcMargin(type,_Symbol,lots,price,need)) return true;

   const double used=AccountInfoDouble(ACCOUNT_MARGIN);
   const double cap =eq*MathMax(1.0,max_capital_utilization_rate)/100.0;
   return ((used+need)<=cap);
}

//+------------------------------------------------------------------+
//| Levels. peak_stat_mode picks how the pivot is found.              |
//+------------------------------------------------------------------+
//| The window is a CALENDAR REACH, not a bar count.
//|
//| The first version used a fixed 12 H1 bars, taken from a lookback
//| sweep on 2026 that showed median error exactly 0 points at 11-14
//| bars. Those numbers were real but they were IN-SAMPLE. Re-running the
//| identical sweep on 2025 — a period the rule was never derived from —
//| broke it:
//|
//|     lookback    2026 match      2025 match
//|      6            21%             13%
//|      11-13        38%  <- peak    28%
//|      24           33%             33%
//|      48           37%             40%  <- still climbing
//|
//| 2026 peaks at 11-14 bars; 2025 peaks at 48 and beyond. A rule that
//| moves its own optimum between periods is a fitted parameter, not a
//| mechanism.
//|
//| The measured lookback per order says the same thing: median 16 bars
//| in 2026 against 31 in 2025, spread p25=6 to p75=62. The reach really
//| does vary — which is what "Adaptive" in the EA's name refers to.
//|
//| Sweeping a CLOCK window instead of a bar count gives a setting that
//| at least peaks on BOTH periods rather than drifting:
//|
//|     window     2026        2025
//|      48h       37.0%       39.3%
//|      96h       40.1%       48.4%   <- used here
//|      132h      44.5%       51.9%
//|      168h      32.4%       39.8%
//|
//| Why a clock beats a bar count: H1 bars are absent over weekends and
//| holidays, so "12 bars ago" spans a different amount of market time in
//| a quiet week than a busy one. A fixed number of HOURS reaches the same
//| way back regardless — which is why the bar-count optimum drifted.
//|
//| ---- BUT THIS IS STILL NOT THE ADAPTIVE RULE --------------------
//|
//| A fixed 96h (or 132h) is a constant with a different unit, not an
//| adaptive reach. The per-order measurement says so plainly: fitting
//| each order to the smallest window that reproduces its price gives a
//| reach of
//|
//|              p10   p25   median   p75   p90
//|     2026      4h    7h     25h    77h   118h
//|     2025      5h   10h     46h    94h   128h
//|
//| A single window cannot generate a 4h-to-128h spread. The reach really
//| does vary per cycle, and that is what "Adaptive" in the EA's name
//| points at.
//|
//| What the driver is NOT — each tested on both periods:
//|
//|   * Not "expand until the level clears _point_shift". The stand-off
//|     IS a hard constraint (0 of 765 orders sat closer than 1000 pts to
//|     market, across both years) but it is not the stopping rule: the
//|     EA picked the MINIMUM viable reach in only 7% of 2026 cases and
//|     13% of 2025, overshooting by a median of 10-15 bars.
//|
//|   * Not volatility-scaled. Spearman correlation between the chosen
//|     reach and ATR14 is 0.02 (2026) and -0.15 (2025); against 24-bar
//|     realised range, -0.04 and -0.23; against the 24h/168h range ratio,
//|     -0.16 and -0.11. All effectively zero.
//|
//|   * Not a k*ATR distance target (51/546 and 46/412), not a fixed point
//|     distance target (55/546, 45/412), and not the nearest N-wing
//|     fractal (2026 peaks at 3 wings, 2025 at 6 — the same drift).
//|
//| So the adaptive mechanism is real, measurable in its effect, and its
//| driver is still unidentified. 96h is the best single approximation
//| found, not the rule. Treated as a knob, labelled as one.
//|
//| ---- peak_stat_mode does NOT change the level formula -------------
//|
//| An earlier version of this function branched on peak_stat_mode and used
//| a 2-wing fractal for ALGO_HIGH_PROBABILITY. That was invented from the
//| enum's NAME ("wait for a confirmed swing") and it is now DISPROVEN by a
//| dedicated backtest of the original with peak_stat_mode=1.
//|
//| Restricted to the same 2026 window (the HP run spans 568 days against
//| the baseline's 204, so the raw 1019-vs-546 counts are not comparable):
//|
//|                        HIGH_FREQUENCY   HIGH_PROBABILITY
//|     stop orders                  546                425
//|     cycles                       380                326
//|     filled                     43.2%              50.4%
//|     canceled                   55.1%              45.4%
//|     level reuse                37.5%              26.8%
//|     max reuse of one level         8                  8
//|
//| Of the 415 cycle+side keys both runs share, 387 carry an IDENTICAL
//| price - 93.3%. The original's own run-to-run noise on identical inputs
//| is 94.6% (489/517), so the two modes agree as closely as one mode
//| agrees with itself. The level generator is the same. Corroborating:
//| the cent-digit distributions match too (divisible-by-5: 20.9% vs
//| 20.7%), which a different formula would not preserve.
//|
//| What actually differs is the CANCEL rate, and through it the deferred
//| queue: fewer cancellations mean fewer levels enter the queue, so fewer
//| get re-issued, so fewer orders exist. The 121-order gap is that loop,
//| not a different pivot. Both modes hit the same reuse ceiling of 8,
//| which is why DEFER_MAX_REISSUE stays mode-independent.
//|
//| Ruled out for the HP skips, each measured: an open-position block
//| (0 of 59 fully-skipped cycles had one), a reach cap (skip rate is
//| non-monotonic: 17.9/22.2/50.9/39.8/9.5%), and a directional EMA gate
//| (sign test flat at 24-36% across EMA 20/50/100/168).
//|
//| One clean finding survives and is NOT yet implemented: 0 of 162 fresh
//| SELL pivots were ever skipped, against 53 of 179 fresh BUYS, and when
//| HP drops one leg of a straddle it drops the buy 49 times to 13. That
//| is the same buy/sell asymmetry as the Known divergence below, seen
//| from the other side. Left unimplemented until the rule behind it is
//| measured rather than guessed - the fractal branch above is exactly
//| what guessing from a name produces.
//+------------------------------------------------------------------+
bool PivotLevels(double &hi,double &lo)
{
   // Enough bars to span the reach even if the feed is dense. The margin
   // over PivotHours covers weekend gaps, where a fixed hour count reaches
   // past more bars than it names.
   const int need=MathMin(1000,MathMax(24,PivotHours+48));

   double h[],l[];
   datetime tm[];
   if(CopyHigh(_Symbol,PERIOD_H1,1,need,h)<1)  return false;
   if(CopyLow (_Symbol,PERIOD_H1,1,need,l)<1)  return false;
   if(CopyTime(_Symbol,PERIOD_H1,1,need,tm)<1) return false;

   const int got=ArraySize(h);
   const datetime cutoff=TimeCurrent()-(datetime)PivotHours*3600;

   // peak_stat_mode does NOT branch here. See the note above PivotLevels():
   // a HIGH_PROBABILITY run of the original produces the SAME levels as a
   // HIGH_FREQUENCY run (93.3% identical, inside the original's own 94.6%
   // self-noise). Both modes read one plain extreme over the reach.

   hi=h[0]; lo=l[0];
   for(int i=1;i<got;i++)
   {
      if(tm[i]<cutoff) break;          // clock reach, not a bar count
      if(h[i]>hi) hi=h[i];
      if(l[i]<lo) lo=l[i];
   }
   hi=NormalizeDouble(hi,_Digits);
   lo=NormalizeDouble(lo,_Digits);
   return true;
}

//+------------------------------------------------------------------+
//| Side viability.                                                   |
//|                                                                  |
//| There is NO directional filter. A side is attempted whenever its  |
//| pivot sits at least _point_shift away from market, and skipped    |
//| when it does not — the "buy-only / sell-only" shapes in the report |
//| are a CONSEQUENCE of that stand-off, not a decision about trend.   |
//|                                                                  |
//| How this was settled. 45 features were computed from 103M ticks at |
//| the exact 367 cycle instants (pivots over 6/12/24/48 bars, EMA and |
//| SMA over 5/10/20/50, ATR, 60s..1h momentum, prior-day context,     |
//| position-in-range) and each was ranked by AUC against the two      |
//| independent decisions "place buy?" and "place sell?".              |
//|                                                                  |
//|   strongest for buy : DistHi12 >= 1014 pts -> 84.7% accuracy       |
//|   strongest for sell: DistLo6  >= 1219 pts -> 70.6% accuracy       |
//|                                                                  |
//| The winning feature on BOTH sides is distance from the 12-bar      |
//| pivot to market, and the threshold the data picked (1014) is       |
//| _point_shift itself. Corroborating: min observed stand-off is      |
//| 1005 pts over 519 orders, never below 1000; and in all 8 cycles    |
//| where the pivot fell inside that band the order was pushed out     |
//| rather than placed at the pivot.                                   |
//|                                                                  |
//| The previous EMA20/50 "flat band" was WRONG and is now gone. Its   |
//| medians were: straddle -715, buy-only -614, sell-only -1258 — the  |
//| three groups overlap almost completely. Adding it back as a gate   |
//| makes sell accuracy WORSE (66.8% -> 64.0%).                        |
//|                                                                  |
//| The "buy 84.7% / sell 66.8%" gap quoted above is WITHDRAWN. Both    |
//| figures were computed without controlling for the duplicate-price   |
//| rule. Controlling for it, buy places on 58.9% of clean eligible      |
//| cycles and sell on 60.5% — a 1.6-point spread, sell slightly ahead. |
//| See the asymmetry section in the file header for the full           |
//| measurement. Side selection is the stand-off plus the duplicate     |
//| rule, with no directional component anywhere.                       |
//|                                                                    |
//| Still open, and now symmetric: ~40% of clean eligible cycles place  |
//| nothing on either side. Whatever gate that is, it is shared.        |
//+------------------------------------------------------------------+
bool SideViable(const bool is_buy,const double level,const MqlTick &tk)
{
   const double market   =(is_buy?tk.ask:tk.bid);
   const double stand_off=(is_buy?(level-market):(market-level))/_Point;
   return (stand_off >= (double)_point_shift);
}

//--- deferred levels -------------------------------------------------
//
// A level cancelled by the margin sweep is NOT forgotten. It goes into
// this table and is re-issued on a later cycle once margin allows.
//
// This is what produces the original's 45.8% price reuse, and it is
// measured rather than guessed:
//
//   * Splitting placements into first-use and repeat-use of a level:
//     first uses match the current 12-bar pivot 65.3% of the time,
//     repeat uses match it 0% of the time (0 of 35). A repeat is
//     therefore never a freshly derived pivot — it comes from memory.
//
//   * Of 205 re-placements, 168 followed a margin cancellation of that
//     exact level and 37 followed a fill. So the sweep is the feeder.
//
//   * Worked example: 4773.55 is the high of the 2026.05.12 03:00 bar.
//     It was placed on 05.12 (12-bar pivot, lookback 6), then again on
//     05.14 and 05.15 — by which point reproducing it from price would
//     have needed a 58- and 75-bar lookback. The level was remembered,
//     not recomputed.
//
// Ruled out along the way: a ratchet that only tightens (13.3% match vs
// 48.6% for the plain pivot), sticky-while-still-extreme over 12..96
// bar hold windows (43-49%, never better than plain), nearest unbroken
// fractal at 1..5 wings (26-43%), and an expanding window that grows
// until the stand-off is met (48.4%, and it always stopped at 12 bars).
//
// DEFER_MAX_REISSUE caps how often one level may come back. Without it
// the queue livelocks: the sweep cancels the furthest order, the queue
// re-places it next cycle, it is still the furthest, so the sweep takes
// it again — forever. The first run with an uncapped queue produced one
// level re-issued 91 times (also 65x, 54x, 35x) against the original's
// hard ceiling of 8. Matching that ceiling is what the cap is for.
#define DEFERMAX          64
#define DEFER_MAX_REISSUE 8

double   d_price[DEFERMAX];
bool     d_isbuy[DEFERMAX];
datetime d_when [DEFERMAX];
int      d_n = 0;

// A level's use count has to survive leaving the queue, otherwise the
// cap resets every time and the livelock returns. This is a small
// price->count ledger, separate from the queue itself.
#define USEDMAX 256
double u_price[USEDMAX];
bool   u_isbuy[USEDMAX];
int    u_count[USEDMAX];
int    u_n = 0;

int UseCount(const double price,const bool is_buy)
{
   for(int i=0;i<u_n;i++)
      if(u_isbuy[i]==is_buy && MathAbs(u_price[i]-price)<_Point*0.5)
         return u_count[i];
   return 0;
}

void UseBump(const double price,const bool is_buy)
{
   for(int i=0;i<u_n;i++)
      if(u_isbuy[i]==is_buy && MathAbs(u_price[i]-price)<_Point*0.5)
      { u_count[i]++; return; }
   if(u_n>=USEDMAX)                             // ledger full: recycle
   {
      for(int i=1;i<u_n;i++)
      { u_price[i-1]=u_price[i]; u_isbuy[i-1]=u_isbuy[i]; u_count[i-1]=u_count[i]; }
      u_n--;
   }
   u_price[u_n]=price; u_isbuy[u_n]=is_buy; u_count[u_n]=1;
   u_n++;
}


void DeferLevel(const double price,const bool is_buy)
{
   // Retired: this level has had its allotted re-issues.
   if(UseCount(price,is_buy)>=DEFER_MAX_REISSUE) return;

   for(int i=0;i<d_n;i++)                       // already queued
      if(d_isbuy[i]==is_buy && MathAbs(d_price[i]-price)<_Point*0.5) return;
   if(d_n>=DEFERMAX)                            // drop the oldest
   {
      for(int i=1;i<d_n;i++)
      { d_price[i-1]=d_price[i]; d_isbuy[i-1]=d_isbuy[i];
        d_when[i-1]=d_when[i]; }
      d_n--;
   }
   d_price[d_n]=price; d_isbuy[d_n]=is_buy;
   d_when[d_n]=TimeCurrent();
   d_n++;
}

void DeferDrop(const int slot)
{
   for(int i=slot+1;i<d_n;i++)
   { d_price[i-1]=d_price[i]; d_isbuy[i-1]=d_isbuy[i];
     d_when[i-1]=d_when[i]; }
   d_n--;
}

// Oldest queued level for this side that is still a valid stop entry.
int DeferFind(const bool is_buy,const MqlTick &tk)
{
   for(int i=0;i<d_n;i++)
   {
      if(d_isbuy[i]!=is_buy) continue;
      if(order_expiry_days>0 &&
         TimeCurrent()-d_when[i] > (datetime)order_expiry_days*86400) continue;
      if(!SideViable(is_buy,d_price[i],tk)) continue;
      return i;
   }
   return -1;
}

void DeferExpire()
{
   if(order_expiry_days<=0) return;
   for(int i=d_n-1;i>=0;i--)
      if(TimeCurrent()-d_when[i] > (datetime)order_expiry_days*86400)
         DeferDrop(i);
}


//+------------------------------------------------------------------+
// An identical price already parked on this side.
bool HasPendingAtPrice(const ENUM_ORDER_TYPE want,const double price)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      const ulong t=OrderGetTicket(i);
      if(t==0) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=magic_id) continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)!=want) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-price) < _Point*0.5) return true;
   }
   return false;
}

bool HasPositionOfType(const ENUM_POSITION_TYPE want)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      const ulong t=PositionGetTicket(i);
      if(t==0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic_id) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==want) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Place one side for this cycle.                                    |
//|                                                                  |
//| Orders ACCUMULATE. The original does not keep one pending per side |
//| — it issues a fresh pair every cycle and lets old ones stand until |
//| they fill, expire after order_expiry_days, or get pruned by the    |
//| margin sweep. Log evidence: 2 to 8 pendings alive at once (114 of  |
//| 373 cycles had exactly 4), and 208 cycles placed a side that       |
//| already had a standing order. An "only one per side" rule cannot   |
//| produce 519 pendings from 373 cycles.                              |
//|                                                                  |
//| The one hard exclusion is a live POSITION on the same side: 0 of   |
//| 746 side-decisions ever placed into one. Max concurrency observed  |
//| is 2 positions total, 2 per side.                                  |
//|                                                                  |
//| Duplicate suppression is exact-price only. Of 445 level changes    |
//| the original made, 213 moved less than 5000 points and the         |
//| smallest was 8 — so _order_price_gap is NOT a re-issue dead band,  |
//| and this clone reads it nowhere. Re-deriving an unchanged pivot     |
//| yields the same number, which is what produces the 49% price reuse. |
//+------------------------------------------------------------------+
void SyncSide(const bool is_buy,const double level)
{
   const ENUM_ORDER_TYPE    otype=(is_buy?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP);
   const ENUM_POSITION_TYPE ptype=(is_buy?POSITION_TYPE_BUY :POSITION_TYPE_SELL);

   if(HasPositionOfType(ptype)) return;   // live trade owns this side

   MqlTick tk;
   if(!SymbolInfoTick(_Symbol,tk)) return;

   // The stand-off is the whole side-selection rule: too close, no order.
   if(!SideViable(is_buy,level,tk))
   {
      if(VerboseLog)
      {
         const double market=(is_buy?tk.ask:tk.bid);
         PrintFormat("AGS_Clone: %s skipped — pivot only %.0f pts away (need %d)",
                     (is_buy?"buy stop":"sell stop"),
                     (is_buy?(level-market):(market-level))/_Point,_point_shift);
      }
      return;
   }

   // Clamp to the broker's own floor if it is stricter than _point_shift.
   const double market=(is_buy?tk.ask:tk.bid);
   const double floor_pts=MinStopDistPts();
   double entry=level;
   if(is_buy  && (entry-market)/_Point < floor_pts) entry=market+Px(floor_pts);
   if(!is_buy && (market-entry)/_Point < floor_pts) entry=market-Px(floor_pts);
   entry=NormalizeDouble(entry,_Digits);

   // Exact duplicate already standing? leave it, do not stack a twin.
   if(HasPendingAtPrice(otype,entry))
   {
      if(VerboseLog)
         PrintFormat("AGS_Clone: keep %s @ %s (pivot unchanged)",
                     (is_buy?"buy stop":"sell stop"),
                     DoubleToString(entry,_Digits));
      return;
   }

   const double lots=LotSize();

   const double sl=(sl_protection && _stop_loss>0
                    ? NormalizeDouble(is_buy?entry-Px(_stop_loss)
                                            :entry+Px(_stop_loss),_Digits)
                    : 0.0);
   const double tp=(_take_profit>0
                    ? NormalizeDouble(is_buy?entry+Px(_take_profit)
                                            :entry-Px(_take_profit),_Digits)
                    : 0.0);

   datetime expiry=0;
   ENUM_ORDER_TYPE_TIME tt=ORDER_TIME_GTC;
   if(order_expiry_days>0)
   {
      expiry=TimeCurrent()+(datetime)order_expiry_days*86400;
      tt=ORDER_TIME_SPECIFIED;
   }

   const string sd=(is_buy?"buy stop":"sell stop");

   string why="";
   if(TradingBlocked(why))
   {
      LogRow("place",sd,0,entry,sl,tp,lots,0,0,"blocked: "+why);
      if(VerboseLog) Print("AGS_Clone: cannot place — ",why);
      return;
   }

   // Retry loop. On a requote or price-off the level itself is still
   // valid, so re-price against the fresh tick and try again rather
   // than dropping the cycle's order.
   bool ok=false;
   uint rc=0;
   double px=entry;
   for(int att=1;att<=RETRY_ATTEMPTS;att++)
   {
      ok=(is_buy ? trade.BuyStop (lots,px,_Symbol,sl,tp,tt,expiry,order_content)
                 : trade.SellStop(lots,px,_Symbol,sl,tp,tt,expiry,order_content));
      rc=trade.ResultRetcode();
      LogRow("place",sd,trade.ResultOrder(),px,sl,tp,lots,att,rc,"");

      if(ok){ stat_ok++; if(att>1) stat_retried++; break; }
      if(!RetcodeTransient(rc)) break;

      Sleep(RETRY_DELAY_MS*att);

      MqlTick fresh;
      if(!SymbolInfoTick(_Symbol,fresh)) break;
      const double mkt2=(is_buy?fresh.ask:fresh.bid);
      const double need=MathMax((double)_point_shift,MinStopDistPts());
      px=entry;
      if(is_buy  && (px-mkt2)/_Point < need) px=mkt2+Px(need);
      if(!is_buy && (mkt2-px)/_Point < need) px=mkt2-Px(need);
      px=NormalizeDouble(px,_Digits);
   }

   if(!ok) ReportFailure("place "+sd,rc,
              StringFormat("@ %s lots %.2f",DoubleToString(px,_Digits),lots));

   if(ok && enable_ags_notify && !MQLInfoInteger(MQL_TESTER))
      SendNotification(StringFormat("AGS %s %.2f @ %s",
                       (is_buy?"BUYSTOP":"SELLSTOP"),lots,
                       DoubleToString(px,_Digits)));

   if(VerboseLog)
      PrintFormat("AGS_Clone: %s %s @ %s sl=%s tp=%s lots=%.2f ret=%d",
                  (ok?"placed":"FAILED"),sd,
                  DoubleToString(px,_Digits),
                  DoubleToString(sl,_Digits),
                  DoubleToString(tp,_Digits),lots,rc);
}

//+------------------------------------------------------------------+
// No DeleteSide(). Cancelling "the pending on side X" only makes sense
// under a one-per-side model, which the log disproves. Standing orders
// are cleared by fill, expiry, or MarginSweep() — never by a cycle
// deciding it no longer wants that side.

void DeleteAllPendings()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      const ulong t=OrderGetTicket(i);
      if(t==0) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=magic_id) continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      const ENUM_ORDER_TYPE ty=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(ty==ORDER_TYPE_BUY_STOP || ty==ORDER_TYPE_SELL_STOP ||
         ty==ORDER_TYPE_BUY_LIMIT|| ty==ORDER_TYPE_SELL_LIMIT)
         trade.OrderDelete(t);
   }
}

//+------------------------------------------------------------------+
//| Margin sweep — cancel_orders_on_insufficient_margin.               |
//|                                                                  |
//| Recovered verbatim from the original's own log line:               |
//|   "R.6 Margin: cancelled low-priority ticket 3                     |
//|    total_margin=1774.75 free=1000.00"                              |
//|                                                                  |
//| 243 occurrences, and every single one fired with total_margin >    |
//| free (minimum ratio 100.1%, median 119.6%). All 243 landed at a    |
//| placement hour (71 at 03:00, 76 at 09:00, 96 at 15:00), i.e. this  |
//| runs right after new orders go out — not continuously.             |
//|                                                                  |
//| "low-priority" means FURTHEST FROM MARKET. Worked example from     |
//| 2026.01.02 15:00:42: a sell stop 2119 pts away survived while both |
//| buy stops at 15527 pts were cancelled.                            |
//|                                                                  |
//| This matters: 243 of the 250 cancellations in the report are this  |
//| sweep, not strategy logic. Margin for 0.1 lot gold at 1:100 is     |
//| ~$440, so $1000 of free margin only sustains about two orders —    |
//| which is why it fires so often.                                    |
//|                                                                  |
//| Note the ORDER of operations differs from a naive pre-check: the   |
//| original places first and prunes after. Blocking up front would    |
//| change which orders exist.                                         |
//|                                                                  |
//| Two constants below are measured, and the first version of this    |
//| function got both wrong — it swept until total <= free and allowed |
//| up to 32 cuts. That left 16 pendings alive instead of 8, produced  |
//| 10 cancellations instead of 250, and let 148 orders die of expiry  |
//| (the original: 20). Because nothing was cancelled, no level was    |
//| ever free to be re-issued, so price reuse collapsed to 0.2%
//| against the original's 41.4%.
//|                                                                  |
//| SWEEP_TOLERANCE — 1.0, i.e. the budget is plain free margin.        |
//|   An earlier reading put this at 1.40 because the post-sweep ratio  |
//|   total/free ran 1.001-1.396. That was the wrong frame: the ratios  |
//|   before and after a sweep OVERLAP (before-min 1.001, after-max     |
//|   1.396), which rules out any fixed ratio trigger.                 |
//|                                                                  |
//|   Counting orders instead settles it. At ~430 margin per 0.1 lot,   |
//|   the surviving order count tracks free margin almost exactly:      |
//|       free  900-1200 -> 3 max        free 2000-2600 -> 6 max        |
//|       free 1200-1600 -> 4 max        free 2600+     -> 7 max        |
//|   Testing "survivors == floor(free/430)" over the 198 bursts gives  |
//|   132 exact hits and every remaining case within +/-1. So the rule  |
//|   is simply total <= free, and the ratio spread is just the         |
//|   granularity of removing one whole order at a time.               |
//|                                                                  |
//| SWEEP_MAX_CUTS — of 198 bursts, 153 removed exactly one order and   |
//|   45 removed two. Zero removed three or more, so the trim is        |
//|   bounded per pass rather than looping until the budget fits.       |
//+------------------------------------------------------------------+
#define SWEEP_TOLERANCE 1.00
#define SWEEP_MAX_CUTS  2

void MarginSweep()
{
   if(!cancel_orders_on_insufficient_margin) return;

   MqlTick tk;
   if(!SymbolInfoTick(_Symbol,tk)) return;
   const double mid=(tk.bid+tk.ask)/2.0;

   for(int guard=0;guard<SWEEP_MAX_CUTS;guard++)
   {
      // Total margin the standing pendings would need if all filled.
      double total=0.0;
      ulong  worst_ticket=0;
      double worst_dist=-1.0;
      int    alive=0;

      for(int i=OrdersTotal()-1;i>=0;i--)
      {
         const ulong t=OrderGetTicket(i);
         if(t==0) continue;
         if(OrderGetInteger(ORDER_MAGIC)!=magic_id) continue;
         if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;

         const ENUM_ORDER_TYPE ty=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ty!=ORDER_TYPE_BUY_STOP && ty!=ORDER_TYPE_SELL_STOP) continue;

         const double px  =OrderGetDouble(ORDER_PRICE_OPEN);
         const double vol =OrderGetDouble(ORDER_VOLUME_CURRENT);

         // Ask for the margin of the POSITION this order would become,
         // not of the pending itself. OrderCalcMargin() on a *_STOP type
         // reports what the pending currently reserves, which is zero
         // until it triggers — so summing that gave total=0, the sweep
         // never saw a breach, and 16 pendings survived where the
         // original held 8. The whole point is the prospective load.
         const ENUM_ORDER_TYPE as_pos=(ty==ORDER_TYPE_BUY_STOP
                                       ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
         double need=0.0;
         if(OrderCalcMargin(as_pos,_Symbol,vol,px,need)) total+=need;

         const double dist=MathAbs(px-mid);
         if(dist>worst_dist){ worst_dist=dist; worst_ticket=t; }
         alive++;
      }

      if(alive==0) return;

      const double free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      if(VerboseLog && guard==0)
         PrintFormat("AGS_Clone: sweep check | %d pendings, total=%.2f, "
                     "free=%.2f, limit=%.2f",
                     alive,total,free_margin,free_margin*SWEEP_TOLERANCE);

      if(total <= free_margin*SWEEP_TOLERANCE) return;   // close enough, done

      if(worst_ticket==0) return;

      // Remember the level before dropping it — it goes back in the
      // queue and gets re-issued when margin frees up. 168 of the
      // original's 205 re-placements followed exactly this path.
      double  lost_px=0.0;
      bool    lost_buy=false;
      if(OrderSelect(worst_ticket))
      {
         lost_px =OrderGetDouble(ORDER_PRICE_OPEN);
         lost_buy=((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP);
      }

      bool del=false;
      uint drc=0;
      for(int att=1;att<=RETRY_ATTEMPTS;att++)
      {
         del=trade.OrderDelete(worst_ticket);
         drc=trade.ResultRetcode();
         LogRow("sweep_cancel",(lost_buy?"buy stop":"sell stop"),
                worst_ticket,lost_px,0,0,0,att,drc,
                StringFormat("total=%.2f free=%.2f",total,free_margin));
         if(del){ stat_ok++; if(att>1) stat_retried++; break; }
         if(!RetcodeTransient(drc)) break;
         Sleep(RETRY_DELAY_MS*att);
      }

      // A stuck delete must end the sweep, not spin: returning leaves the
      // breach for the next cycle instead of hammering the server.
      if(!del)
      {
         ReportFailure("sweep cancel",drc,
                       StringFormat("ticket %I64u",worst_ticket));
         return;
      }
      if(lost_px>0.0) DeferLevel(lost_px,lost_buy);

      if(VerboseLog)
         PrintFormat("AGS_Clone: Margin cancelled low-priority ticket %I64u "
                     "total_margin=%.2f free=%.2f",
                     worst_ticket,total,free_margin);
   }
}

//+------------------------------------------------------------------+
//| The 6-hour cycle.                                                |
//+------------------------------------------------------------------+
bool CycleDue(datetime &stamp)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   if(dt.hour!=CycleHour1 && dt.hour!=CycleHour2 && dt.hour!=CycleHour3)
      return false;
   dt.min=0; dt.sec=0;
   stamp=StructToTime(dt);
   return (stamp!=last_cycle_stamp);
}

void DrawLevel(const string name,const double price,const color c)
{
   if(!Show_Price_Lines) return;
   const string id=OBJ_PREFIX+name;
   if(ObjectFind(0,id)<0)
   {
      ObjectCreate(0,id,OBJ_HLINE,0,0,price);
      ObjectSetInteger(0,id,OBJPROP_COLOR,c);
      ObjectSetInteger(0,id,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,id,OBJPROP_BACK,true);
   }
   ObjectMove(0,id,0,0,price);
}

void RunCycle()
{
   double hi=0.0,lo=0.0;
   if(!PivotLevels(hi,lo))
   {
      if(VerboseLog) Print("AGS_Clone: not enough H1 history for pivots");
      return;
   }

   if(VerboseLog)
      PrintFormat("AGS_Clone: cycle | hi=%s lo=%s",
                  DoubleToString(hi,_Digits),DoubleToString(lo,_Digits));

   DrawLevel("hi",hi,clrDodgerBlue);
   DrawLevel("lo",lo,clrTomato);

   if(my_trade_mode==MARKETS)
   {
      // Arm the watched levels; ManageMarketEntries() fires on a break.
      mk_bias=0;
      mk_level_hi=hi;
      mk_level_lo=lo;
      return;
   }

   // A cycle issues AT MOST one order per side. The deferred queue does
   // not add to the cycle's quota — it SUBSTITUTES for the fresh pivot
   // on that side.
   //
   // Getting this wrong is what blew the order count up. Draining the
   // queue *in addition* to placing both pivots meant up to 4 orders per
   // cycle, so the queue fed faster than the sweep could prune: 1358
   // re-issues against 755 cancellations, 1259 pendings against the
   // original's 546, and concurrency of 17 against 7. The original
   // averages 546/373 = 1.46 orders per cycle, which only fits a
   // one-per-side ceiling.
   //
   // Queue-before-pivot is still right: a repeat placement in the
   // original is never the current pivot (0 of 35), so when a level is
   // waiting it takes that side's slot.
   DeferExpire();
   MqlTick tk;
   const bool got_tick=SymbolInfoTick(_Symbol,tk);

   for(int side=0;side<2;side++)
   {
      const bool   is_buy=(side==0);
      const double pivot =(is_buy?hi:lo);

      int slot=-1;
      if(got_tick) slot=DeferFind(is_buy,tk);

      if(slot>=0)
      {
         const double px=d_price[slot];
         DeferDrop(slot);
         UseBump(px,is_buy);
         if(VerboseLog)
            PrintFormat("AGS_Clone: re-issuing deferred %s @ %s (use %d/%d)",
                        (is_buy?"buy stop":"sell stop"),
                        DoubleToString(px,_Digits),
                        UseCount(px,is_buy),DEFER_MAX_REISSUE);
         SyncSide(is_buy,px);
      }
      else
         SyncSide(is_buy,pivot);
   }

   // Place first, prune after — the order the original uses.
   MarginSweep();
}

//+------------------------------------------------------------------+
//| Trailing — this is where the money actually comes from.           |
//|                                                                  |
//| 249/249 exits were stop-loss hits, yet 199 were profitable, so    |
//| the stop must cross entry and keep advancing.                     |
//+------------------------------------------------------------------+
void ManageTrailing()
{
   if(!enable_trailing_stop) return;

   MqlTick tk;
   if(!SymbolInfoTick(_Symbol,tk)) return;

   const double min_dist=MinStopDistPts();

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic_id) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;

      const ENUM_POSITION_TYPE pt=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      const bool   is_buy=(pt==POSITION_TYPE_BUY);
      const double open  =PositionGetDouble(POSITION_PRICE_OPEN);
      const double cur_sl=PositionGetDouble(POSITION_SL);
      const double cur_tp=PositionGetDouble(POSITION_TP);
      const double market=(is_buy?tk.bid:tk.ask);

      const double profit_pts=(is_buy?(market-open):(open-market))/_Point;

      //---------------------------------------------------------------
      // The trail is MEASURED, from 1113 "position modified" events the
      // original emitted across its own 249 positions (tester log of
      // the 22:54 run). What that log settles:
      //
      //  * Move #1 is the hard SL: 229 of 249 first modifies sat at
      //    exactly -400 pts. The stop starts as _stop_loss and nothing
      //    else.
      //
      //  * The exit from -400 is a SINGLE jump to breakeven-or-better:
      //    of 211 such transitions, 211 landed at or beyond entry and
      //    NOT ONE landed in between. So there is no partial recovery
      //    step — it goes from -400 straight to >= 0.
      //
      //  * Afterwards the stop only ever tightens: 864 of 864
      //    consecutive steps were positive, zero loosened, zero were
      //    flat. Monotonic, no exceptions.
      //
      //  * Step size is not fixed (median 32 pts, p90 429), so the stop
      //    is computed from live price, not incremented. And it never
      //    sits closer than 20 pts to the favourable extreme of the
      //    minute it moved in: min 21 pts over 396 matched moves, 0
      //    below 20. That is _trailing_points acting as a floor.
      //
      //  * 24 positions were never trailed at all — 18 of them died on
      //    the -400 stop, so arming requires real profit first.
      //---------------------------------------------------------------

      // Arming: the jump only happens once price is far enough ahead to
      // put the stop at or past entry while still keeping the trail
      // distance. smart_ts is what gates this; with it off the stop
      // starts trailing as soon as there is any profit at all.
      const double arm_at=(smart_ts ? (double)_trailing_points : 1.0);
      if(profit_pts < arm_at) continue;

      // reduce_ts / HighProfitTrail were both false in the observed
      // run, so their curves remain inferred from their names: one
      // tightens the trail as profit grows, the other loosens it to
      // give a runner room. Neither is measured.
      double step=(double)_trailing_points;
      if(reduce_ts)
         step=MathMax((double)_trailing_points,
                      step*MathMax(0.35,1.0-profit_pts/2000.0));
      if(HighProfitTrail && profit_pts>1000.0)
         step=step*(1.0+profit_pts/2000.0);

      double want_sl=(is_buy?market-Px(step):market+Px(step));

      // Never park the stop short of entry once armed. This is the
      // 211/211 rule: the first trail lands at breakeven or better,
      // never between -400 and 0.
      if(is_buy  && want_sl<open) want_sl=open;
      if(!is_buy && want_sl>open) want_sl=open;

      want_sl=NormalizeDouble(want_sl,_Digits);

      //---------------------------------------------------------------
      // TRAILING_SMART: keep the stop in EA memory and close at market
      // when price reaches it. No broker-side modify, so the no-touch
      // band does not apply and the stop can sit inside it.
      //
      // The report says this is what the original does. All 249 exits
      // were MARKET orders whose comment carried the stop price
      // ("sl 4377.26"), median deviation from that price only 8 points
      // — a broker-side stop would have shown as an SL-triggered close,
      // not as a market order the EA sent.
      //---------------------------------------------------------------
      if(_trailing_stops_mode==TRAILING_SMART)
      {
         const int slot=VStopSlot(ticket);
         if(slot<0) continue;

         const bool tighter=(v_sl[slot]<=0.0 ||
                             (is_buy ? want_sl>v_sl[slot]+_Point*0.5
                                     : want_sl<v_sl[slot]-_Point*0.5));
         if(tighter) v_sl[slot]=want_sl;

         const bool hit=(is_buy ? market<=v_sl[slot] : market>=v_sl[slot]);
         if(hit)
         {
            const double vol=PositionGetDouble(POSITION_VOLUME);

            // A virtual stop has no broker-side protection, so a failed
            // close leaves the position naked. This one DOES deserve the
            // full retry budget.
            bool cl=false;
            uint crc=0;
            for(int att=1;att<=RETRY_ATTEMPTS;att++)
            {
               cl=trade.PositionClose(ticket);
               crc=trade.ResultRetcode();
               LogRow("vstop_close",(is_buy?"buy":"sell"),ticket,
                      market,v_sl[slot],0,vol,att,(cl?0:crc),"");
               if(cl){ stat_ok++; if(att>1) stat_retried++; break; }
               if(!RetcodeTransient(crc)) break;
               Sleep(RETRY_DELAY_MS*att);
            }

            if(cl)
            {
               if(VerboseLog)
                  PrintFormat("AGS_Clone: virtual stop hit #%I64u @ %s (vsl %s)",
                              ticket,DoubleToString(market,_Digits),
                              DoubleToString(v_sl[slot],_Digits));
               VStopRelease(ticket);
            }
            else
               ReportFailure("virtual-stop close",crc,
                  StringFormat("ticket %I64u still OPEN and unprotected",ticket));
         }
         continue;
      }

      //---------------------------------------------------------------
      // TRAILING_REAL: move the broker-side stop.
      //
      // Respect the no-touch band by PUSHING the stop out to the legal
      // minimum — never by abandoning the trail. v1 did
      // `if(dist < min) continue;` with a 20-point step against a
      // 50-point floor, so it fired on every tick and PositionModify
      // was never called once in 35 trades. That one line cost 34 of
      // 34 stop-outs.
      //---------------------------------------------------------------
      const double raw=(is_buy?(market-want_sl):(want_sl-market))/_Point;
      if(raw<min_dist)
         want_sl=(is_buy?market-Px(min_dist):market+Px(min_dist));
      want_sl=NormalizeDouble(want_sl,_Digits);

      const double eps=0.5*_Point;
      const bool tighter=(is_buy? want_sl>cur_sl+eps
                                : (cur_sl<=0.0 || want_sl<cur_sl-eps));
      if(!tighter) continue;

      // The trail runs on every tick, so a failure here is not fatal —
      // the next tick tries again anyway. That makes a long retry loop
      // pointless and actively harmful (it would block other positions).
      // One immediate re-price is enough, and only for a transient code.
      //
      // This is where the original bled: 455 "Invalid stops" and 72
      // "Invalid parameters" out of 1413 modify attempts, none retried.
      // Pushing the stop to the legal minimum (above) removes most of
      // that class; this handles the rest.
      bool mod=trade.PositionModify(ticket,want_sl,cur_tp);
      uint mrc=trade.ResultRetcode();

      if(!mod && RetcodeTransient(mrc))
      {
         MqlTick fresh;
         if(SymbolInfoTick(_Symbol,fresh))
         {
            const double mkt2=(is_buy?fresh.bid:fresh.ask);
            double retry_sl=(is_buy?mkt2-Px(step):mkt2+Px(step));
            if(is_buy  && retry_sl<open) retry_sl=open;
            if(!is_buy && retry_sl>open) retry_sl=open;
            const double d2=(is_buy?(mkt2-retry_sl):(retry_sl-mkt2))/_Point;
            if(d2<min_dist)
               retry_sl=(is_buy?mkt2-Px(min_dist):mkt2+Px(min_dist));
            retry_sl=NormalizeDouble(retry_sl,_Digits);

            const bool tighter2=(is_buy? retry_sl>cur_sl+eps
                                       : (cur_sl<=0.0 || retry_sl<cur_sl-eps));
            if(tighter2)
            {
               mod=trade.PositionModify(ticket,retry_sl,cur_tp);
               mrc=trade.ResultRetcode();
               if(mod){ want_sl=retry_sl; stat_retried++; }
            }
         }
      }

      if(mod) stat_ok++; else stat_failed++;

      LogRow("trail",(is_buy?"buy":"sell"),ticket,open,want_sl,cur_tp,
             PositionGetDouble(POSITION_VOLUME),1,(mod?0:mrc),
             StringFormat("profit_pts=%.0f step=%.0f",profit_pts,step));

      if(!mod && VerboseLog)
         PrintFormat("AGS_Clone: trail failed #%I64u ret=%d (%s)",
                     ticket,mrc,trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| MARKETS mode: instead of parking stop orders, watch the levels and |
//| enter at market the moment one breaks.                            |
//|                                                                  |
//| The observed run used PENDING (519 stop entries, 0 market entries) |
//| so this path is unverified against the original. It exists because |
//| the enum exposes it, and it is written to produce the same fills a |
//| stop order would: same level, same SL/TP, same stand-off.          |
//+------------------------------------------------------------------+
double mk_level_hi = 0.0;
double mk_level_lo = 0.0;
int    mk_bias     = 0;

void ManageMarketEntries()
{
   if(mk_level_hi<=0.0 && mk_level_lo<=0.0) return;

   MqlTick tk;
   if(!SymbolInfoTick(_Symbol,tk)) return;
   if(!SpreadOK()) return;

   if(mk_bias>=0 && mk_level_hi>0.0 &&
      tk.ask>=mk_level_hi && !HasPositionOfType(POSITION_TYPE_BUY))
   {
      const double lots=LotSize();
      if(MarginRoomFor(ORDER_TYPE_BUY,lots))
      {
         double sl=0.0,tp=0.0;
         if(sl_protection && _stop_loss>0)
            sl=NormalizeDouble(tk.ask-Px(_stop_loss),_Digits);
         if(_take_profit>0)
            tp=NormalizeDouble(tk.ask+Px(_take_profit),_Digits);
         if(trade.Buy(lots,_Symbol,0.0,sl,tp,order_content))
         {
            mk_level_hi=0.0;   // one entry per level break
            if(VerboseLog) Print("AGS_Clone: MARKETS buy on level break");
         }
      }
   }

   if(mk_bias<=0 && mk_level_lo>0.0 &&
      tk.bid<=mk_level_lo && !HasPositionOfType(POSITION_TYPE_SELL))
   {
      const double lots=LotSize();
      if(MarginRoomFor(ORDER_TYPE_SELL,lots))
      {
         double sl=0.0,tp=0.0;
         if(sl_protection && _stop_loss>0)
            sl=NormalizeDouble(tk.bid+Px(_stop_loss),_Digits);
         if(_take_profit>0)
            tp=NormalizeDouble(tk.bid-Px(_take_profit),_Digits);
         if(trade.Sell(lots,_Symbol,0.0,sl,tp,order_content))
         {
            mk_level_lo=0.0;
            if(VerboseLog) Print("AGS_Clone: MARKETS sell on level break");
         }
      }
   }
}

//+------------------------------------------------------------------+
bool FridayCutoff()
{
   if(!cancel_orders_on_friday) return false;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   return (dt.day_of_week==5 && dt.hour>=friday_cancel_hour);
}

//+------------------------------------------------------------------+
//| News filter — reads MT5's built-in economic calendar.              |
//|                                                                  |
//| This used to be a stub that only checked a global variable, which
//| left news_minutes_before / news_minutes_after / news_proximity_points
//| declared but never read — three inputs that looked functional and
//| were not. They are wired for real now.
//|
//| How each input is used:
//|   news_minutes_before / _after  the blackout window around an event
//|   news_proximity_points         relevance filter. An event only counts
//|                                 if a standing order sits within this
//|                                 many points of market, i.e. close
//|                                 enough that the spike could hit it.
//|                                 At the default 5000 (50 pips on gold)
//|                                 that covers essentially every order,
//|                                 so the input mostly acts as a way to
//|                                 narrow the filter, not widen it.
//|
//| Only HIGH-importance events for the symbol's own currencies are
//| considered (XAUUSD -> USD), matching what a gold scalper cares about.
//|
//| The calendar is unavailable inside the strategy tester, so there the
//| function falls back to the manual AGS_NEWS_BLOCK global variable —
//| which also keeps backtests reproducible instead of silently depending
//| on whatever the terminal happened to have cached.
//+------------------------------------------------------------------+
bool NewsBlackout()
{
   if(!cancel_orders_on_news) return false;

   // Manual override always wins, and is the only path in the tester.
   if(GlobalVariableCheck("AGS_NEWS_BLOCK") &&
      GlobalVariableGet("AGS_NEWS_BLOCK")>0.0) return true;
   if(MQLInfoInteger(MQL_TESTER)) return false;

   // Relevance gate: if nothing of ours sits near the market, a spike
   // cannot hurt us and there is nothing to protect.
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol,tk)) return false;
   const double mid=(tk.bid+tk.ask)/2.0;

   bool near=false;
   for(int i=OrdersTotal()-1;i>=0 && !near;i--)
   {
      const ulong t=OrderGetTicket(i);
      if(t==0) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=magic_id) continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-mid)/_Point
         <= (double)news_proximity_points) near=true;
   }
   for(int i=PositionsTotal()-1;i>=0 && !near;i--)
   {
      const ulong t=PositionGetTicket(i);
      if(t==0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic_id) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      near=true;                      // an open trade is always exposed
   }
   if(!near) return false;

   const datetime now=TimeCurrent();
   const datetime from=now-(datetime)MathMax(0,news_minutes_after)*60;
   const datetime to  =now+(datetime)MathMax(0,news_minutes_before)*60;

   const string base  =SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE);
   const string profit=SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT);

   MqlCalendarValue vals[];
   const string codes[2]={base,profit};
   for(int c=0;c<2;c++)
   {
      if(codes[c]=="") continue;
      if(c==1 && codes[1]==codes[0]) continue;
      const int n=CalendarValueHistory(vals,from,to,NULL,codes[c]);
      for(int i=0;i<n;i++)
      {
         MqlCalendarEvent ev;
         if(!CalendarEventById(vals[i].event_id,ev)) continue;
         if(ev.importance!=CALENDAR_IMPORTANCE_HIGH) continue;
         if(VerboseLog)
            PrintFormat("AGS_Clone: news blackout — %s at %s",
                        ev.name,TimeToString(vals[i].time,TIME_DATE|TIME_MINUTES));
         return true;
      }
   }
   return false;
}

// No MarginStarved() gate. An earlier version blocked placement up front
// when margin was short, and wiped every pending when it tripped. Both
// are wrong: the original places first and then cancels only the single
// furthest order, repeating until the budget fits. That is MarginSweep(),
// and it runs after each cycle rather than as an entry veto.

//+------------------------------------------------------------------+
void ShowPanel()
{
   if(!show_panel || (MQLInfoInteger(MQL_TESTER) && !show_panel)) return;
   const string id=OBJ_PREFIX+"panel";
   if(ObjectFind(0,id)<0)
   {
      ObjectCreate(0,id,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,id,OBJPROP_XDISTANCE,10);
      ObjectSetInteger(0,id,OBJPROP_YDISTANCE,20);
      ObjectSetInteger(0,id,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,id,OBJPROP_COLOR,clrSilver);
   }
   ObjectSetString(0,id,OBJPROP_TEXT,
      StringFormat("AGS_Clone | SL %d TP %d | trail %d | spread %.0f"
                   " | deferred %d | ops %d/%d/%d",
                   _stop_loss,_take_profit,_trailing_points,SpreadPts(),
                   d_n,stat_ok,stat_retried,stat_failed));
}

//+------------------------------------------------------------------+
void OnTick()
{
   VStopPrune();
   ManageTrailing();          // every tick — a 19-second hold has no slack
   if(my_trade_mode==MARKETS) ManageMarketEntries();
   ShowPanel();

   if(FridayCutoff() || NewsBlackout())
   {
      DeleteAllPendings();
      return;
   }

   datetime stamp=0;
   if(CycleDue(stamp))
   {
      if(!SpreadOK())
      {
         if(VerboseLog)
            PrintFormat("AGS_Clone: cycle skipped, spread %.0f too wide",
                        SpreadPts());
         return;              // retry on a later tick inside the same hour
      }
      last_cycle_stamp=stamp;
      RunCycle();
   }
}
//+------------------------------------------------------------------+
