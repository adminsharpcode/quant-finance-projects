
//+------------------------------------------------------------------+
//| GoldLevelBreakoutEnhanced.mq4                                    |
//| MT4 conversion of Gold level breakout Enhanced v1.80            |
//| Adaptive level-recovery scalper                                   |
//| CPU-optimized build – UI/history off tick path                   |
//+------------------------------------------------------------------+
#property strict
#property version   "1.80"
#property copyright "FREE FOREX TOOLS"
#property link "https://t.me/free_fx_pro"

//--- Entry quality
enum ENUM_GLB_ENTRY_QUALITY
{
   GLB_EXTREME_ONLY = 0,
   GLB_BODY_CONFIRM = 1,
   GLB_CLOSE_LOCATION = 2,
   GLB_FULL_REJECTION = 3
};

//--- Entry logic
enum ENUM_GLB_ENTRY_LOGIC
{
   GLB_PULLBACK_EXTREME = 0,
   GLB_TREND_BREAKOUT   = 1,
   GLB_BOTH_EXTREMES    = 2
};

//--- Entry execution
enum ENUM_GLB_ENTRY_EXECUTION
{
   GLB_ENTER_IMMEDIATE   = 0,
   GLB_ENTER_ON_RECLAIM  = 1,
   GLB_ENTER_LEVEL_TOUCH = 2
};

input double Lots               = 0.03;
input double LotMultiplier      = 1.0;
input int    MinBarsBetween     = 2;
input int    MinDistancePoints  = 51;
input int    TrailingPoints     = 90;
input int    TrailingArmPoints  = 110;
input int    TrailLockPercent   = 75;
input int    MinTrailStepPoints = 5;
input int    Dist               = 33;
input int    STPeriod           = 11;
input double STMultiplier       = 9.0;
input int    STBars             = 20;
input int    Slippage           = 3000;
input int    Magic              = 778001;
input bool   PanelShow          = true;
input int    PanelX             = 20;
input int    PanelY             = 20;
input bool   ForecastShow       = true;
input int    ForecastRefreshSec = 300;
input bool   TimeFilter         = false;
input int    StartHour          = 9;
input int    EndHour            = 18;
input bool   AdaptiveSession    = true;
input int    CoreStartHour      = 7;
input int    CoreEndHour        = 18;
input int    ExtendedHoursADX   = 35;
input bool   WeekendProtection  = true;
input int    FridayCloseHour    = 22;
input bool   SafetyGuard        = true;
input double MaxBasketLoss      = 20.0;
input int    SafetyCooldownBars = 20;
input int    HardStopCooldownBars = 2;

input string HardStopControls = "Hard stop-loss controls";
input double HardStopLossUSDPerPosition = 9.0;
input double TakeProfitUSDPerPosition  = 0.0;

input string EnhancedQualityControls = "Enhanced quality controls";
input int    MacroEMAPeriod            = 20;
input ENUM_GLB_ENTRY_LOGIC EntryLogic  = GLB_PULLBACK_EXTREME;
input ENUM_GLB_ENTRY_EXECUTION EntryExecution = GLB_ENTER_IMMEDIATE;
input int    ReclaimPercent            = 50;
input int    ReclaimValidityBars       = 3;
input int    ReclaimBufferPoints       = 0;
input ENUM_GLB_ENTRY_QUALITY EntryQuality = GLB_EXTREME_ONLY;
input int    RejectionClosePercent     = 60;
input int    MaxSignalRangeATRPercent  = 0;
input int    MaxSpreadPoints           = 20;
input bool   RecoveryRequiresMacro     = true;
input bool   EnableRecovery            = true;
input bool   RecoveryRequiresRejection = false;
input int    RecoveryConfirmAfterSafetyBars = 288;
input double RecoveryBasketProfitUSD   = 5.0;

//--- Cached symbol trading properties (set once in OnInit, opt #4)
double g_tickSize       = 0.0;
double g_tickValue      = 0.0;
double g_minLot         = 0.0;
double g_maxLot         = 0.0;
double g_lotStep        = 0.0;
int    g_stopLevel      = 0;
double g_brokerMinStop  = 0.0;

//--- Pre-normalized input values (set once in OnInit, opt #7)
int    g_cFridayCloseHour;
int    g_cCoreStartHour;
int    g_cCoreEndHour;
int    g_cSTPeriod;
int    g_cSTBars;
double g_cSTMultiplier;
int    g_cDist;
int    g_cTrailLockPct;
int    g_cMinTrailStep;
int    g_cTrailingArm;
int    g_cSafetyCooldown;
int    g_cHardStopCooldown;
int    g_cMinDist;
int    g_cMinBars;
double g_cLotMult;
int    g_cReclaimPct;
int    g_cReclaimBuf;
int    g_cReclaimValidity;
int    g_cRejectionClose;

//--- Runtime state (g_prevAsk/g_prevBid removed per opt #8)
int      g_signalTf = 0;
datetime g_lastBarTime = 0;
datetime g_lastForecastRefresh = 0;
datetime g_lastSafetyExit = 0;
datetime g_lastHardStopExit = 0;
double   g_buyLevel = 0.0;
double   g_sellLevel = 0.0;
double   g_stLine = 0.0;
int      g_bias = 0;
int      g_prevBias = 0;
bool     g_touchArmed = true;
int      g_armedDirection = 0;
double   g_armedTrigger = 0.0;
datetime g_armedAt = 0;
string   PFX = "GLB_CR_";

struct DealStats
{
   int trades;
   int wins;
   int losses;
   double net;
   double grossProfit;
   double grossLoss;
   double profitFactor;
   double winRate;
   double avgTrade;
   double bestTrade;
   double worstTrade;
   double maxDrawdown;
};

//--- Stats cache: recalculated only when OrdersHistoryTotal() changes (opt #2/#3)
int      g_cachedHistoryTotal = -1;
DealStats g_cachedStats;
bool     g_statsReady = false;

//--- Histogram cache: rebuilt only when history changes (opt #3 extended)
double   g_histVals[36];
int      g_histCount = 0;

//--- Session ADX cache: D1 ADX changes once per day bar (opt #6)
bool     g_adxResult = false;
int      g_adxDay    = -1;

//--- Forward declarations
void CacheSymbolProperties(void);
void NormalizeInputs(void);
void RefreshCachedStats(void);
bool CheckSessionADX(void);
void CloseAllManaged(void);

//+------------------------------------------------------------------+
int OnInit()
{
   g_signalTf = (_Period == PERIOD_M1 ? PERIOD_M5 : _Period);
   if(g_signalTf <= 0) g_signalTf = PERIOD_M5;

   CacheSymbolProperties();
   NormalizeInputs();

   RefreshLevels(true);
   BuildPanel();
   EventSetTimer(1);
   RefreshCachedStats();

   if(_Period > PERIOD_M5)
      Print("GLB CR: M1 or M5 attachment recommended.");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   DeleteObjects();
}

//+------------------------------------------------------------------+
//| Cache symbol trading properties to avoid repeated MarketInfo()   |
//+------------------------------------------------------------------+
void CacheSymbolProperties(void)
{
   g_tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
   g_tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   g_minLot    = MarketInfo(Symbol(), MODE_MINLOT);
   g_maxLot    = MarketInfo(Symbol(), MODE_MAXLOT);
   g_lotStep   = MarketInfo(Symbol(), MODE_LOTSTEP);
   g_stopLevel = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);

   if(g_tickSize <= 0.0) g_tickSize  = Point;
   if(g_minLot   <= 0.0) g_minLot    = 0.01;
   if(g_lotStep  <= 0.0) g_lotStep   = g_minLot;

   g_brokerMinStop = (g_stopLevel + 2) * Point;
}

//+------------------------------------------------------------------+
//| Pre-normalize input parameters once                              |
//+------------------------------------------------------------------+
void NormalizeInputs(void)
{
   g_cFridayCloseHour  = MathMax(0, MathMin(23, FridayCloseHour));
   g_cCoreStartHour    = MathMax(0, MathMin(23, CoreStartHour));
   g_cCoreEndHour      = MathMax(0, MathMin(23, CoreEndHour));
   g_cSTPeriod         = MathMax(2, STPeriod);
   g_cSTBars           = MathMax(2, STBars);
   g_cSTMultiplier     = MathMax(0.10, STMultiplier);
   g_cDist             = MathMax(0, Dist);
   g_cTrailLockPct     = MathMax(0, MathMin(100, TrailLockPercent));
   g_cMinTrailStep     = MathMax(1, MinTrailStepPoints);
   g_cTrailingArm      = (TrailingArmPoints > 0 ? TrailingArmPoints : TrailingPoints);
   g_cSafetyCooldown   = MathMax(1, SafetyCooldownBars);
   g_cHardStopCooldown = MathMax(0, HardStopCooldownBars);
   g_cMinDist          = MathMax(1, MinDistancePoints);
   g_cMinBars          = MathMax(0, MinBarsBetween);
   g_cLotMult          = MathMax(0.01, LotMultiplier);
   g_cReclaimPct       = MathMax(0, MathMin(100, ReclaimPercent));
   g_cReclaimBuf       = MathMax(0, ReclaimBufferPoints);
   g_cReclaimValidity  = MathMax(1, ReclaimValidityBars);
   g_cRejectionClose   = MathMax(50, MathMin(95, RejectionClosePercent));
}

//+------------------------------------------------------------------+
//| OnTick – trading logic only; NO UI/history work               |
//+------------------------------------------------------------------+
void OnTick()
{
   RefreshRates();

   datetime barTime = iTime(Symbol(), g_signalTf, 0);
   bool newBar = (barTime != g_lastBarTime);
   if(newBar)
   {
      g_lastBarTime = barTime;
      RefreshLevels(false);
   }

   if(ManageWeekendProtection())
      return;

   if(ManageBasketAndRecovery())
      return;

   ManageIndependentTrailing();

   if(IsTradingTime())
      ProcessEntries(newBar);
}

//+------------------------------------------------------------------+
//| OnTimer – 1-second UI/history/forecast refresh only            |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(!PanelShow && !ForecastShow) return;

   RefreshCachedStats();
   UpdatePanel();
}

//+------------------------------------------------------------------+
//| Recalculate statistics only when account history changes         |
//+------------------------------------------------------------------+
void RefreshCachedStats(void)
{
   int total = OrdersHistoryTotal();
   if(total == g_cachedHistoryTotal) return;
   g_cachedHistoryTotal = total;
   CalculateStats(g_cachedStats);
   g_statsReady = true;

   // Rebuild histogram data from same history window
   g_histCount = 0;
   ArrayInitialize(g_histVals, 0.0);
   for(int i = total - 1; i >= 0 && g_histCount < 36; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      g_histVals[g_histCount] = OrderProfit() + OrderCommission() + OrderSwap();
      g_histCount++;
   }
}

//+------------------------------------------------------------------+
//| Cache D1 ADX per calendar day                                    |
//+------------------------------------------------------------------+
bool CheckSessionADX(void)
{
   if(ExtendedHoursADX <= 0) return(true);

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int today = dt.day_of_year;

   if(today != g_adxDay)
   {
      g_adxDay = today;
      double adx = iADX(Symbol(), PERIOD_D1, 14, PRICE_CLOSE, MODE_MAIN, 1);
      g_adxResult = (adx > 0.0 && adx >= ExtendedHoursADX);
   }

   return(g_adxResult);
}

//+------------------------------------------------------------------+
bool IsTradingTime()
{
   int dow = TimeDayOfWeek(TimeCurrent());
   int hr  = TimeHour(TimeCurrent());

   if(WeekendProtection)
   {
      if(dow == 0 || dow == 6) return(false);
      if(dow == 5 && hr >= g_cFridayCloseHour)
         return(false);
   }

   if(AdaptiveSession)
   {
      int cs = g_cCoreStartHour;
      int ce = g_cCoreEndHour;
      bool inCore = (cs == ce ? true :
                       cs < ce ? (hr >= cs && hr < ce) :
                                 (hr >= cs || hr < ce));
      if(inCore) return(true);
      return(CheckSessionADX());
   }

   if(!TimeFilter) return(true);
   if(StartHour == EndHour) return(true);
   if(StartHour < EndHour)
      return(hr >= StartHour && hr < EndHour);
   return(hr >= StartHour || hr < EndHour);
}

//+------------------------------------------------------------------+
bool ManageWeekendProtection()
{
   if(!WeekendProtection) return(false);

   int dow    = TimeDayOfWeek(TimeCurrent());
   int cutoff = g_cFridayCloseHour;
   if(dow != 5 || TimeHour(TimeCurrent()) < cutoff) return(false);

   bool attempted = false;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(!IsManagedOrder()) continue;
      attempted = true;
      CloseSelectedOrder();
   }

   if(attempted)
      ResetArmedState();

   return(attempted);
}

//+------------------------------------------------------------------+
void RefreshLevels(bool force)
{
   int minBars = MathMax(g_cSTBars, g_cSTPeriod) + 20;
   if(iBars(Symbol(), g_signalTf) < minBars) return;

   double st = 0.0;
   int trend = 0;
   if(!CalculateSuperTrend(st, trend)) return;

   g_prevBias = g_bias;
   g_bias     = MacroDirection();
   g_stLine   = st;

   int lookback = g_cSTBars;
   double pad   = g_cDist * Point;

   int lowShift  = iLowest(Symbol(), g_signalTf, MODE_LOW, lookback, 1);
   int highShift = iHighest(Symbol(), g_signalTf, MODE_HIGH, lookback, 1);

   g_buyLevel  = (lowShift >= 1 ?
                  NormalizeDouble(iLow(Symbol(), g_signalTf, lowShift) - pad, Digits) : 0.0);
   g_sellLevel = (highShift >= 1 ?
                  NormalizeDouble(iHigh(Symbol(), g_signalTf, highShift) + pad, Digits) : 0.0);

   if(g_prevBias != 0 && g_bias != g_prevBias)
      g_touchArmed = true;

   if(force || TimeCurrent() - g_lastForecastRefresh >= ForecastRefreshSec)
   {
      g_lastForecastRefresh = TimeCurrent();
      DrawForecastLevel();
   }
}

//+------------------------------------------------------------------+
int MacroDirection()
{
   double ema = iMA(Symbol(), PERIOD_D1, MathMax(2, MacroEMAPeriod), 0, MODE_EMA, PRICE_CLOSE, 1);
   double cls = iClose(Symbol(), PERIOD_D1, 1);
   if(ema <= 0.0 || cls <= 0.0) return(1);
   return(cls >= ema ? 1 : -1);
}

//+------------------------------------------------------------------+
bool CalculateSuperTrend(double &line, int &trend)
{
   int need = MathMax(80, MathMax(g_cSTBars + g_cSTPeriod + 20, g_cSTPeriod * 4));
   int got  = iBars(Symbol(), g_signalTf);
   if(got < MathMax(g_cSTBars, g_cSTPeriod) + 5) return(false);
   need = MathMin(need, got - 1);

   double upper[], lower[], st[];
   ArrayResize(upper, need);
   ArrayResize(lower, need);
   ArrayResize(st, need);

   int oldest = need - 1;

   double h   = iHigh(Symbol(), g_signalTf, oldest);
   double l   = iLow(Symbol(), g_signalTf, oldest);
   double c   = iClose(Symbol(), g_signalTf, oldest);
   double atr = iATR(Symbol(), g_signalTf, g_cSTPeriod, oldest);

   double hl2 = (h + l) * 0.5;
   double a0  = MathMax(atr, Point);
   upper[oldest] = hl2 + g_cSTMultiplier * a0;
   lower[oldest] = hl2 - g_cSTMultiplier * a0;
   st[oldest]    = (c >= hl2 ? lower[oldest] : upper[oldest]);

   for(int i = oldest - 1; i >= 1; i--)
   {
      int p = i + 1;
      h   = iHigh(Symbol(), g_signalTf, i);
      l   = iLow(Symbol(), g_signalTf, i);
      c   = iClose(Symbol(), g_signalTf, i);
      double pc = iClose(Symbol(), g_signalTf, p);
      double av = MathMax(iATR(Symbol(), g_signalTf, g_cSTPeriod, i), Point);

      double mid        = (h + l) * 0.5;
      double basicUpper = mid + g_cSTMultiplier * av;
      double basicLower = mid - g_cSTMultiplier * av;

      upper[i] = (basicUpper < upper[p] || pc > upper[p]) ? basicUpper : upper[p];
      lower[i] = (basicLower > lower[p] || pc < lower[p]) ? basicLower : lower[p];

      bool prevWasUpper = (MathAbs(st[p] - upper[p]) <= MathAbs(st[p] - lower[p]));
      st[i] = (prevWasUpper ?
               (c <= upper[i] ? upper[i] : lower[i]) :
               (c >= lower[i] ? lower[i] : upper[i]));
   }

   bool onLower = (MathAbs(st[1] - lower[1]) <= MathAbs(st[1] - upper[1]));
   trend = onLower ? 1 : -1;
   line  = NormalizeDouble(st[1], Digits);
   return(line > 0.0);
}

//+------------------------------------------------------------------+
bool SignalQualityPass(int direction, bool forceRejection)
{
   if(!forceRejection && EntryQuality == GLB_EXTREME_ONLY &&
      MaxSignalRangeATRPercent <= 0)
      return(true);

   double o = iOpen(Symbol(), g_signalTf, 1);
   double h = iHigh(Symbol(), g_signalTf, 1);
   double l = iLow(Symbol(), g_signalTf, 1);
   double c = iClose(Symbol(), g_signalTf, 1);

   double range = h - l;
   if(range <= Point) return(false);

   if(MaxSignalRangeATRPercent > 0)
   {
      double atr = iATR(Symbol(), g_signalTf, g_cSTPeriod, 1);
      if(atr <= Point) return(false);
      if(range * 100.0 > atr * MaxSignalRangeATRPercent)
         return(false);
   }

   bool body         = (direction > 0 ? c > o : c < o);
   double closeLoc   = 100.0 * (c - l) / range;
   int threshold     = g_cRejectionClose;
   bool location     = (direction > 0 ?
                        closeLoc >= threshold :
                        closeLoc <= 100 - threshold);

   if(forceRejection) return(body && location);
   if(EntryQuality == GLB_BODY_CONFIRM) return(body);
   if(EntryQuality == GLB_CLOSE_LOCATION) return(location);
   if(EntryQuality == GLB_FULL_REJECTION) return(body && location);
   return(true);
}

//+------------------------------------------------------------------+
void ProcessEntries(bool newBar)
{
   int buys, sells;
   double lastBuy, lastSell;
   datetime lastBuyTime, lastSellTime;
   GetOpenState(buys, sells, lastBuy, lastSell, lastBuyTime, lastSellTime);

   if(buys > 0 && sells > 0) return;

   if(MaxSpreadPoints > 0)
   {
      double spread = (Ask - Bid) / Point;
      if(spread > MaxSpreadPoints) return;
   }

   if(g_lastSafetyExit > 0 &&
      BarsSince(g_lastSafetyExit) < g_cSafetyCooldown)
      return;

   if(g_lastHardStopExit > 0 &&
      BarsSince(g_lastHardStopExit) < g_cHardStopCooldown)
      return;

   if(buys == 0 && sells == 0)
   {
      if(EntryExecution == GLB_ENTER_LEVEL_TOUCH)
      {
         if(newBar)
         {
            if(g_bias >= 0 && g_buyLevel > 0.0 && Ask > g_buyLevel)
               g_touchArmed = true;
            else if(g_bias < 0 && g_sellLevel > 0.0 && Bid < g_sellLevel)
               g_touchArmed = true;
         }

         if(g_touchArmed)
         {
            if(g_bias >= 0 && g_buyLevel > 0.0 && Ask <= g_buyLevel)
            {
               g_touchArmed = false;
               OpenMarket(OP_BUY, Lots, "Gold level touch buy");
            }
            else if(g_bias < 0 && g_sellLevel > 0.0 && Bid >= g_sellLevel)
            {
               g_touchArmed = false;
               OpenMarket(OP_SELL, Lots, "Gold level touch sell");
            }
         }
         return;
      }

      if(EntryExecution == GLB_ENTER_ON_RECLAIM && g_armedDirection != 0)
      {
         bool expired     = BarsSince(g_armedAt) > g_cReclaimValidity;
         bool invalidBias = (g_armedDirection > 0 ? g_bias < 0 : g_bias > 0);

         if(expired || invalidBias)
            ResetArmedState();
         else
         {
            bool crossed = (g_armedDirection > 0 ?
                           Ask >= g_armedTrigger :
                           Bid <= g_armedTrigger);
            if(crossed)
            {
               int dir = g_armedDirection;
               ResetArmedState();
               OpenMarket(dir > 0 ? OP_BUY : OP_SELL, Lots,
                          dir > 0 ? "Gold reclaim buy" : "Gold reclaim sell");
               return;
            }
         }
      }

      if(!newBar) return;

      int lookback   = g_cSTBars;
      double signalLow  = iLow(Symbol(), g_signalTf, 1);
      double signalHigh = iHigh(Symbol(), g_signalTf, 1);

      int lowShift  = iLowest(Symbol(), g_signalTf, MODE_LOW, lookback, 2);
      int highShift = iHighest(Symbol(), g_signalTf, MODE_HIGH, lookback, 2);

      double olderLow  = (lowShift >= 2 ? iLow(Symbol(), g_signalTf, lowShift) : 0.0);
      double olderHigh = (highShift >= 2 ? iHigh(Symbol(), g_signalTf, highShift) : 0.0);

      if(g_bias >= 0)
      {
         bool pullback = (signalLow > 0 && olderLow > 0 && signalLow <= olderLow);
         bool breakout = (signalHigh > 0 && olderHigh > 0 && signalHigh >= olderHigh);
         bool triggered = (EntryLogic == GLB_PULLBACK_EXTREME ? pullback :
                           EntryLogic == GLB_TREND_BREAKOUT ? breakout :
                           pullback || breakout);

         if(triggered && SignalQualityPass(1, false))
         {
            if(EntryExecution == GLB_ENTER_IMMEDIATE)
               OpenMarket(OP_BUY, Lots, "Gold level buy");
            else if(EntryExecution == GLB_ENTER_ON_RECLAIM)
               ArmReclaim(1, signalLow, signalHigh);
         }
      }
      else
      {
         bool breakout = (signalLow > 0 && olderLow > 0 && signalLow <= olderLow);
         bool pullback = (signalHigh > 0 && olderHigh > 0 && signalHigh >= olderHigh);
         bool triggered = (EntryLogic == GLB_PULLBACK_EXTREME ? pullback :
                           EntryLogic == GLB_TREND_BREAKOUT ? breakout :
                           pullback || breakout);

         if(triggered && SignalQualityPass(-1, false))
         {
            if(EntryExecution == GLB_ENTER_IMMEDIATE)
               OpenMarket(OP_SELL, Lots, "Gold level sell");
            else if(EntryExecution == GLB_ENTER_ON_RECLAIM)
               ArmReclaim(-1, signalLow, signalHigh);
         }
      }
      return;
   }

   if(!newBar || !EnableRecovery) return;

   if(buys == 1)
   {
      if(RecoveryRequiresMacro && g_bias < 0) return;

      bool confirm = RecoveryRequiresRejection ||
         (RecoveryConfirmAfterSafetyBars > 0 && g_lastSafetyExit > 0 &&
          BarsSince(g_lastSafetyExit) < RecoveryConfirmAfterSafetyBars);

      if(confirm && !SignalQualityPass(1, true)) return;

      if(BarsSince(lastBuyTime) >= g_cMinBars &&
         Ask <= lastBuy - g_cMinDist * Point)
      {
         double v = Lots * MathPow(g_cLotMult, buys);
         OpenMarket(OP_BUY, v, "GLB buy layer");
      }
   }
   else if(sells == 1)
   {
      if(RecoveryRequiresMacro && g_bias > 0) return;

      bool confirm = RecoveryRequiresRejection ||
         (RecoveryConfirmAfterSafetyBars > 0 && g_lastSafetyExit > 0 &&
          BarsSince(g_lastSafetyExit) < RecoveryConfirmAfterSafetyBars);

      if(confirm && !SignalQualityPass(-1, true)) return;

      if(BarsSince(lastSellTime) >= g_cMinBars &&
         Bid >= lastSell + g_cMinDist * Point)
      {
         double v = Lots * MathPow(g_cLotMult, sells);
         OpenMarket(OP_SELL, v, "GLB sell layer");
      }
   }
}

//+------------------------------------------------------------------+
void ArmReclaim(int direction, double signalLow, double signalHigh)
{
   double range = signalHigh - signalLow;
   if(range <= Point) return;

   int reclaim = g_cReclaimPct;
   double reclaimDist = range * reclaim / 100.0;
   double buffer      = g_cReclaimBuf * Point;

   g_armedDirection = direction;
   g_armedTrigger = (direction > 0 ?
                     signalLow + reclaimDist + buffer :
                     signalHigh - reclaimDist - buffer);
   g_armedTrigger = NormalizeDouble(g_armedTrigger, Digits);
   g_armedAt = iTime(Symbol(), g_signalTf, 0);
}

//+------------------------------------------------------------------+
//| Combined basket safety + recovery in single order scan (opt #5) |
//+------------------------------------------------------------------+
bool ManageBasketAndRecovery()
{
   bool checkSafety   = SafetyGuard && MaxBasketLoss > 0.0;
   bool checkRecovery = RecoveryBasketProfitUSD > 0.0;

   if(!checkSafety && !checkRecovery) return(false);

   double floating = 0.0;
   int managed = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(!IsManagedOrder()) continue;
      floating += OrderProfit() + OrderSwap() + OrderCommission();
      managed++;
   }

   if(managed == 0) return(false);

   // Safety guard (higher priority)
   if(checkSafety && floating <= -MathAbs(MaxBasketLoss))
   {
      CloseAllManaged();
      g_lastSafetyExit = iTime(Symbol(), g_signalTf, 0);
      ResetArmedState();
      Print("GLB CR basket guard triggered at floating ",
            DoubleToString(floating, 2));
      return(true);
   }

   // Recovery basket profit target
   if(checkRecovery && managed >= 2 && floating >= RecoveryBasketProfitUSD)
   {
      CloseAllManaged();
      return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+
void CloseAllManaged()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(!IsManagedOrder()) continue;
      CloseSelectedOrder();
   }
}

//+------------------------------------------------------------------+
int BarsSince(datetime when)
{
   if(when <= 0) return(999999);
   int shift = iBarShift(Symbol(), g_signalTf, when, false);
   if(shift < 0) return(999999);
   return(shift);
}

//+------------------------------------------------------------------+
void GetOpenState(int &buys, int &sells,
                  double &lastBuy, double &lastSell,
                  datetime &lastBuyTime, datetime &lastSellTime)
{
   buys = 0; sells = 0;
   lastBuy = 0; lastSell = 0;
   lastBuyTime = 0; lastSellTime = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(!IsManagedOrder()) continue;

      int type = OrderType();
      datetime t = OrderOpenTime();
      double p  = OrderOpenPrice();

      if(type == OP_BUY)
      {
         buys++;
         if(t >= lastBuyTime)
         {
            lastBuyTime = t;
            lastBuy = p;
         }
      }
      else if(type == OP_SELL)
      {
         sells++;
         if(t >= lastSellTime)
         {
            lastSellTime = t;
            lastSell = p;
         }
      }
   }
}

//+------------------------------------------------------------------+
bool OpenMarket(int type, double rawVolume, string comment)
{
   double volume = NormalizeVolume(rawVolume);
   if(volume <= 0.0) return(false);

   RefreshRates();

   double price = (type == OP_BUY ? Ask : Bid);
   double sl    = BuildHardStopPrice(type, volume, price);
   double tp    = BuildTakeProfitPrice(type, volume, price);

   ResetLastError();
   int ticket = OrderSend(Symbol(), type, volume, price, Slippage, sl, tp,
                          comment, Magic, 0, clrNONE);

   if(ticket < 0)
   {
      Print("GLB CR order failed: ", GetLastError(),
            " type=", type, " lots=", DoubleToString(volume, 2));
      return(false);
   }

   return(true);
}

//+------------------------------------------------------------------+
double BuildHardStopPrice(int type, double volume, double entryPrice)
{
   if(HardStopLossUSDPerPosition <= 0.0) return(0.0);

   // Use cached values (opt #4)
   double ts = g_tickSize;
   double tv = g_tickValue;

   if(ts <= 0.0) ts = Point;
   if(tv <= 0.0 || volume <= 0.0) return(0.0);

   double distance = HardStopLossUSDPerPosition * ts / (tv * volume);
   double brokerMin = g_brokerMinStop;
   distance = MathMax(distance, brokerMin);

   RefreshRates();

   double stop = (type == OP_BUY ? entryPrice - distance
                                 : entryPrice + distance);

   if(type == OP_BUY)
   {
      stop = MathMin(stop, Bid - brokerMin);
      stop = MathFloor(stop / ts) * ts;
   }
   else
   {
      stop = MathMax(stop, Ask + brokerMin);
      stop = MathCeil(stop / ts) * ts;
   }

   return(NormalizeDouble(stop, Digits));
}

//+------------------------------------------------------------------+
double BuildTakeProfitPrice(int type, double volume, double entryPrice)
{
   if(TakeProfitUSDPerPosition <= 0.0) return(0.0);

   double ts = g_tickSize;
   double tv = g_tickValue;

   if(ts <= 0.0) ts = Point;
   if(tv <= 0.0 || volume <= 0.0) return(0.0);

   double distance = TakeProfitUSDPerPosition * ts / (tv * volume);
   double brokerMin = g_brokerMinStop;
   distance = MathMax(distance, brokerMin);

   RefreshRates();

   double target = (type == OP_BUY ? entryPrice + distance
                                   : entryPrice - distance);

   if(type == OP_BUY)
   {
      target = MathMax(target, Ask + brokerMin);
      target = MathCeil(target / ts) * ts;
   }
   else
   {
      target = MathMin(target, Bid - brokerMin);
      target = MathFloor(target / ts) * ts;
   }

   return(NormalizeDouble(target, Digits));
}

//+------------------------------------------------------------------+
double NormalizeVolume(double volume)
{
   // Use cached values (opt #4)
   double minv = g_minLot;
   double maxv = g_maxLot;
   double step = g_lotStep;

   if(step <= 0.0) step = minv;
   if(minv <= 0.0) minv = 0.01;

   volume = MathMax(minv, MathMin(maxv, volume));
   volume = MathRound(volume / step) * step;

   int vd = 0;
   double s = step;
   while(vd < 8 && MathAbs(s - MathRound(s)) > 1e-10)
   {
      s *= 10.0;
      vd++;
   }

   return(NormalizeDouble(volume, vd));
}

//+------------------------------------------------------------------+
void ManageIndependentTrailing()
{
   if(TrailingPoints <= 0) return;

   double d        = TrailingPoints * Point;
   double arm      = g_cTrailingArm * Point;
   int lockPct     = g_cTrailLockPct;
   double lockDist = MathMax(Point, arm * lockPct / 100.0);
   double minAdv   = g_cMinTrailStep * Point;
   double minStop  = g_brokerMinStop;  // cached (opt #4)

   RefreshRates();

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(!IsManagedOrder()) continue;

      int type = OrderType();
      double open = OrderOpenPrice();
      double sl   = OrderStopLoss();
      double tp   = OrderTakeProfit();
      double newSL = 0.0;

      if(type == OP_BUY)
      {
         if(Bid - open < arm) continue;

         double allowed = Bid - minStop;
         double locked  = open + lockDist;
         if(locked > allowed) continue;

         newSL = MathMax(Bid - MathMax(d, minStop), locked);
         newSL = NormalizeDouble(newSL, Digits);

         if(sl == 0.0 || newSL >= sl + minAdv)
         {
            ResetLastError();
            if(!OrderModify(OrderTicket(), open, newSL, tp, 0, clrNONE))
               Print("GLB CR buy trail failed: ", GetLastError());
         }
      }
      else if(type == OP_SELL)
      {
         if(open - Ask < arm) continue;

         double allowed = Ask + minStop;
         double locked  = open - lockDist;
         if(locked < allowed) continue;

         newSL = MathMin(Ask + MathMax(d, minStop), locked);
         newSL = NormalizeDouble(newSL, Digits);

         if(sl == 0.0 || newSL <= sl - minAdv)
         {
            ResetLastError();
            if(!OrderModify(OrderTicket(), open, newSL, tp, 0, clrNONE))
               Print("GLB CR sell trail failed: ", GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
bool IsManagedOrder()
{
   if(OrderSymbol() != Symbol()) return(false);
   if(OrderMagicNumber() != Magic) return(false);
   if(OrderType() != OP_BUY && OrderType() != OP_SELL) return(false);
   return(true);
}

//+------------------------------------------------------------------+
bool CloseSelectedOrder()
{
   RefreshRates();
   double price = (OrderType() == OP_BUY ? Bid : Ask);

   ResetLastError();
   bool ok = OrderClose(OrderTicket(), OrderLots(), price, Slippage, clrNONE);
   if(!ok)
      Print("GLB CR close failed ticket=", OrderTicket(),
            " error=", GetLastError());
   return(ok);
}

//+------------------------------------------------------------------+
void ResetArmedState()
{
   g_armedDirection = 0;
   g_armedTrigger   = 0.0;
   g_armedAt        = 0;
}

//+------------------------------------------------------------------+
void DeleteObjects()
{
   int total = ObjectsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, PFX, 0) == 0)
         ObjectDelete(name);
   }
}

//+------------------------------------------------------------------+
//| BuildPanel: creates panel background objects once (opt #9)       |
//+------------------------------------------------------------------+
void BuildPanel()
{
   if(PanelShow)
   {
      Rect("PANEL_BG",   PanelX, PanelY,     760, 520, clrBlack,        clrBlack);
      Rect("PANEL_TOP",  PanelX, PanelY,     760, 6,   clrLimeGreen,    clrLimeGreen);
      Rect("PANEL_HEAD", PanelX, PanelY + 6, 760, 64,  clrDarkSlateGray,clrDarkSlateGray);
   }

   if(ForecastShow)
      Rect("FC_BG", PanelX + 600, PanelY + 535, 340, 126, clrDarkSlateGray, clrDarkSlateGray);
}

//+------------------------------------------------------------------+
//| UpdatePanel: uses cached stats, no history scan (opt #1,#2,#9)   |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   if(!PanelShow && !ForecastShow) return;

   if(PanelShow)
   {
      DealStats s;
      if(g_statsReady)
         s = g_cachedStats;   // #2: use cached stats
      else
      {
         CalculateStats(s);  // fallback on first call before timer fires
         g_cachedStats = s;
         g_statsReady  = true;
      }

      int x = PanelX, y = PanelY;

      // #9: static backgrounds already created by BuildPanel, skip re-creating

      Label("TITLE", "EA Gold level breakout", x + 28, y + 26, 16, clrWhite);
      Label("SYM", Symbol() + " - " + TfText(g_signalTf), x + 735, y + 26, 14, clrSilver);

      Label("NP", "NET PROFIT", x + 28, y + 92, 12, clrSilver);
      Label("WR", "WIN RATE", x + 705, y + 92, 12, clrSilver);

      color npColor = (s.net >= 0 ? clrLimeGreen : clrTomato);
      Label("NET", MoneySigned(s.net), x + 28, y + 120, 34, npColor);
      Label("WINRATE", DoubleToString(s.winRate, 1) + "%", x + 705, y + 124, 28, clrWhite);

      int barX = x + 28, barY = y + 195, barW = 680;
      double wr = MathMax(0.0, MathMin(100.0, s.winRate));
      int gw = (int)MathRound(barW * wr / 100.0);

      Rect("BAR_R", barX, barY, barW, 16, clrFireBrick, clrFireBrick);
      if(gw > 0) Rect("BAR_G", barX, barY, gw, 16, clrLimeGreen, clrLimeGreen);
      else ObjectDelete(PFX + "BAR_G");

      Label("WINS", "Wins: " + IntegerToString(s.wins), x + 28, y + 222, 12, clrSilver);
      Label("LOSSES", "Losses: " + IntegerToString(s.losses), x + 705, y + 222, 12, clrSilver);

      Label("TRD_L", "Trades", x + 28, y + 260, 13, clrSilver);
      Label("TRD_V", IntegerToString(s.trades), x + 350, y + 260, 14, clrWhite);
      Label("PF_L", "Profit factor", x + 405, y + 260, 13, clrSilver);
      Label("PF_V", DoubleToString(s.profitFactor, 2), x + 705, y + 260, 14, clrWhite);
      HLine("SEP1", x + 28, y + 288, 680, clrDimGray);

      Label("GP_L", "Gross profit", x + 28, y + 302, 13, clrSilver);
      Label("GP_V", DoubleToString(s.grossProfit, 2), x + 350, y + 302, 14, clrLimeGreen);
      Label("GL_L", "Gross loss", x + 405, y + 302, 13, clrSilver);
      Label("GL_V", DoubleToString(s.grossLoss, 2), x + 705, y + 302, 14, clrTomato);
      HLine("SEP2", x + 28, y + 332, 680, clrDimGray);

      Label("DD_L", "Max drawdown", x + 28, y + 345, 13, clrSilver);
      Label("DD_V", "-" + DoubleToString(s.maxDrawdown, 2), x + 350, y + 345, 14, clrTomato);
      Label("AV_L", "Average trade", x + 405, y + 345, 13, clrSilver);
      Label("AV_V", MoneySigned(s.avgTrade), x + 705, y + 345, 14,
            (s.avgTrade >= 0 ? clrLimeGreen : clrTomato));
      HLine("SEP3", x + 28, y + 375, 680, clrDimGray);

      Label("BT_L", "Best trade", x + 28, y + 388, 13, clrSilver);
      Label("BT_V", MoneySigned(s.bestTrade), x + 350, y + 388, 14,
            (s.bestTrade >= 0 ? clrLimeGreen : clrTomato));
      Label("WT_L", "Worst trade", x + 405, y + 388, 13, clrSilver);
      Label("WT_V", MoneySigned(s.worstTrade), x + 705, y + 388, 14,
            (s.worstTrade >= 0 ? clrLimeGreen : clrTomato));

      Label("CTR", "CLOSED TRADE RESULTS", x + 28, y + 428, 12, clrSilver);
      DrawCachedHistogram(x + 28, y + 455, 680, 48);
   }

   if(ForecastShow)
   {
      int fx = PanelX + 600, fy = PanelY + 535;
      // #9: FC_BG created in BuildPanel, but FC_EDGE is dynamic so kept here
      Rect("FC_EDGE", fx, fy, 3, 126, clrLimeGreen, clrLimeGreen);

      Label("FC_STATUS", "EA RUNNING - SCANNING MARKET", fx + 20, fy + 16, 10, clrLimeGreen);

      double level = (g_bias >= 0 ? g_buyLevel : g_sellLevel);
      string side  = (g_bias >= 0 ? "BUY" : "SELL");

      Label("FC_SIDE", side + " WILL OPEN AT", fx + 20, fy + 42, 9, clrSilver);
      Label("FC_PRICE", DoubleToString(level, Digits), fx + 20, fy + 58, 19, clrLimeGreen);

      double px  = (g_bias >= 0 ? Ask : Bid);
      int pts    = (int)MathRound(MathAbs(px - level) / Point);

      double atrv  = iATR(Symbol(), g_signalTf, g_cSTPeriod, 0);
      double span  = MathMax(1.0, (atrv * MathMax(g_cSTMultiplier, 1.0) + g_cDist * Point) / Point);
      int progress = (int)MathRound(100.0 - MathMin(100.0, 100.0 * pts / span));

      Label("FC_DIST", IntegerToString(pts) + " pts away", fx + 20, fy + 84, 10, clrSilver);
      Label("FC_PC", IntegerToString(progress) + "%", fx + 315, fy + 84, 10, clrSilver);

      Rect("FC_BAR_BG", fx + 20, fy + 104, 295, 7, clrDimGray, clrDimGray);
      int pw = (int)MathRound(295.0 * progress / 100.0);
      if(pw > 0) Rect("FC_BAR", fx + 20, fy + 104, pw, 7, clrLimeGreen, clrLimeGreen);
      else ObjectDelete(PFX + "FC_BAR");
   }

   // #10: WindowRedraw only in timer-driven path
   WindowRedraw();
}

//+------------------------------------------------------------------+
void CalculateStats(DealStats &s)
{
   s.trades = 0; s.wins = 0; s.losses = 0;
   s.net = 0; s.grossProfit = 0; s.grossLoss = 0;
   s.profitFactor = 0; s.winRate = 0; s.avgTrade = 0;
   s.bestTrade = 0; s.worstTrade = 0; s.maxDrawdown = 0;

   int total = OrdersHistoryTotal();
   double curve = 0.0, peak = 0.0;
   bool first = true;

   for(int i = 0; i < total; i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double p = OrderProfit() + OrderCommission() + OrderSwap();

      s.trades++;
      s.net += p;

      if(p >= 0)
      {
         s.wins++;
         s.grossProfit += p;
      }
      else
      {
         s.losses++;
         s.grossLoss += p;
      }

      if(first)
      {
         s.bestTrade  = p;
         s.worstTrade = p;
         first = false;
      }
      else
      {
         if(p > s.bestTrade)  s.bestTrade  = p;
         if(p < s.worstTrade) s.worstTrade = p;
      }

      curve += p;
      if(curve > peak) peak = curve;
      double dd = peak - curve;
      if(dd > s.maxDrawdown) s.maxDrawdown = dd;
   }

   if(s.trades > 0)
   {
      s.winRate  = 100.0 * s.wins / s.trades;
      s.avgTrade = s.net / s.trades;
   }

   if(s.grossLoss < 0.0)
      s.profitFactor = s.grossProfit / MathAbs(s.grossLoss);
   else if(s.grossProfit > 0.0)
      s.profitFactor = 99.99;
}

//+------------------------------------------------------------------+
void DrawCachedHistogram(int x, int y, int w, int h)
{
   Rect("HIST_BG", x, y, w, h, clrBlack, clrBlack);

   int n = g_histCount;
   if(n <= 0) return;

   double maxAbs = 0.0;
   for(int i = 0; i < n; i++)
      maxAbs = MathMax(maxAbs, MathAbs(g_histVals[i]));
   if(maxAbs <= 0.0) maxAbs = 1.0;

   int base = y + h / 2;
   HLine("HIST_ZERO", x, base, w, clrGray);

   int bw = MathMax(2, w / 36 - 2);

   for(int i = 0; i < 36; i++)
      ObjectDelete(PFX + "HB" + IntegerToString(i));

   for(int j = 0; j < n; j++)
   {
      double v  = g_histVals[n - 1 - j];
      int bh    = (int)MathRound((h / 2 - 3) * MathAbs(v) / maxAbs);
      if(bh < 1) bh = 1;

      int bx = x + j * (w / 36);
      int by = (v >= 0 ? base - bh : base);
      color c = (v >= 0 ? clrLimeGreen : clrTomato);

      Rect("HB" + IntegerToString(j), bx, by, bw, bh, c, c);
   }
}

//+------------------------------------------------------------------+
void DrawForecastLevel()
{
   string name = PFX + "FORECAST_LEVEL";

   if(!ForecastShow)
   {
      ObjectDelete(name);
      return;
   }

   double level = (g_bias >= 0 ? g_buyLevel : g_sellLevel);
   if(level <= 0.0) return;

   int totalBars  = iBars(Symbol(), g_signalTf);
   int levelShift = g_cSTBars;
   if(levelShift > totalBars - 1) levelShift = totalBars - 1;

   datetime t1 = iTime(Symbol(), g_signalTf, levelShift);
   datetime t2 = iTime(Symbol(), g_signalTf, 0);

   if(t1 <= 0) t1 = TimeCurrent() - 60 * 5 * MathMax(1, g_cSTBars);
   if(t2 <= 0) t2 = TimeCurrent();

   if(ObjectFind(name) < 0)
      ObjectCreate(name, OBJ_TREND, 0, t1, level, t2, level);

   ObjectMove(name, 0, t1, level);
   ObjectMove(name, 1, t2, level);
   ObjectSet(name, OBJPROP_RAY, false);
   ObjectSet(name, OBJPROP_COLOR, clrLimeGreen);
   ObjectSet(name, OBJPROP_WIDTH, 2);
   ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(name, OBJPROP_BACK, false);
   ObjectSet(name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
void Rect(string id, int x, int y, int w, int h, color bg, color border)
{
   string n = PFX + id;

   if(ObjectFind(n) < 0)
      ObjectCreate(n, OBJ_RECTANGLE_LABEL, 0, 0, 0);

   ObjectSet(n, OBJPROP_CORNER, 0);
   ObjectSet(n, OBJPROP_XDISTANCE, x);
   ObjectSet(n, OBJPROP_YDISTANCE, y);
   ObjectSet(n, OBJPROP_XSIZE, w);
   ObjectSet(n, OBJPROP_YSIZE, h);
   ObjectSet(n, OBJPROP_BGCOLOR, bg);
   ObjectSet(n, OBJPROP_BORDER_COLOR, border);
   ObjectSet(n, OBJPROP_SELECTABLE, false);
   ObjectSet(n, OBJPROP_HIDDEN, true);
   ObjectSet(n, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
void Label(string id, string txt, int x, int y, int size, color c)
{
   string n = PFX + id;

   if(ObjectFind(n) < 0)
      ObjectCreate(n, OBJ_LABEL, 0, 0, 0);

   ObjectSet(n, OBJPROP_CORNER, 0);
   ObjectSet(n, OBJPROP_XDISTANCE, x);
   ObjectSet(n, OBJPROP_YDISTANCE, y);
   ObjectSet(n, OBJPROP_FONTSIZE, size);
   ObjectSet(n, OBJPROP_COLOR, c);
   ObjectSetText(n, txt, size, "Arial", c);
   ObjectSet(n, OBJPROP_SELECTABLE, false);
   ObjectSet(n, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
void HLine(string id, int x, int y, int w, color c)
{
   Rect(id, x, y, w, 1, c, c);
}

//+------------------------------------------------------------------+
string MoneySigned(double v)
{
   if(v > 0.0) return("+" + DoubleToString(v, 2));
   return(DoubleToString(v, 2));
}

//+------------------------------------------------------------------+
string TfText(int tf)
{
   if(tf == PERIOD_M1)  return("M1");
   if(tf == PERIOD_M5)  return("M5");
   if(tf == PERIOD_M15) return("M15");
   if(tf == PERIOD_M30) return("M30");
   if(tf == PERIOD_H1)  return("H1");
   if(tf == PERIOD_H4)  return("H4");
   if(tf == PERIOD_D1)  return("D1");
   if(tf == PERIOD_W1)  return("W1");
   if(tf == PERIOD_MN1) return("MN1");
   return(IntegerToString(tf));
}
//+------------------------------------------------------------------+
