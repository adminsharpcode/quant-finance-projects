#property copyright "FREE FOREX TOOLS"
#property link      "https://t.me/free_fx_pro"
#property description ""
#property version   "2.60"
#property strict

#include <Trade/Trade.mqh>
CTrade g_trade;

input double Lots            = 0.02;
input int    MaxTrades       = 10;     // max grid legs
input double TP_Min_USD      = 1.4;    // per-leg take profit
input double TP_Max_USD      = 5.0;
input double Trail_Start_USD = 3.0;
input int    TrailStepPips   = 10;
input int    FastEMA         = 10;
input int    SlowEMA         = 20;
input ENUM_TIMEFRAMES TrendTF = PERIOD_M1;
input long   MagicNumber     = 20260720;
input string TradeComment    = "fury flipper v2";
input int    CooldownSeconds = 5;      // grid time step

datetime g_lastGridBeat = 0;
datetime g_lastBar      = 0;
int      g_dir          = 0;
int      g_fastHandle   = INVALID_HANDLE;
int      g_slowHandle   = INVALID_HANDLE;
ENUM_TIMEFRAMES g_emaTF = PERIOD_M5;

int OnInit()
  {
   if(FastEMA < 1 || SlowEMA <= FastEMA)
      return INIT_PARAMETERS_INCORRECT;
   // Live TrendTF=1 (M1). Sell-episode timing on tape fits M5 EMA crosses better.
   g_emaTF = (TrendTF == PERIOD_M1 ? PERIOD_M5 : TrendTF);
   g_fastHandle = iMA(_Symbol, g_emaTF, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_slowHandle = iMA(_Symbol, g_emaTF, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_fastHandle == INVALID_HANDLE || g_slowHandle == INVALID_HANDLE)
      return INIT_FAILED;
   g_trade.SetExpertMagicNumber((ulong)MagicNumber);
   g_trade.SetDeviationInPoints(30);
   g_lastGridBeat = 0;
   g_lastBar = 0;
   g_dir = 0;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(g_fastHandle != INVALID_HANDLE) IndicatorRelease(g_fastHandle);
   if(g_slowHandle != INVALID_HANDLE) IndicatorRelease(g_slowHandle);
  }

bool IsOurs()
  {
   return((long)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
          PositionGetString(POSITION_SYMBOL) == _Symbol);
  }

int CountOurs()
  {
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket != 0 && PositionSelectByTicket(ticket) && IsOurs())
         ++n;
     }
   return n;
  }

int CountOpposite(const int dir)
  {
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket) || !IsOurs())
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if(dir > 0 && type == POSITION_TYPE_SELL) ++n;
      if(dir < 0 && type == POSITION_TYPE_BUY) ++n;
     }
   return n;
  }

// Sticky EMA cross → grid direction
int GridDirection()
  {
   double fast[], slow[];
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   if(CopyBuffer(g_fastHandle, 0, 0, 3, fast) < 3)
      return g_dir;
   if(CopyBuffer(g_slowHandle, 0, 0, 3, slow) < 3)
      return g_dir;

   datetime bar = iTime(_Symbol, g_emaTF, 0);
   if(bar != 0 && bar != g_lastBar)
     {
      g_lastBar = bar;
      if(fast[1] > slow[1] && fast[2] <= slow[2])
         g_dir = 1;
      else if(fast[1] < slow[1] && fast[2] >= slow[2])
         g_dir = -1;
     }
   if(g_dir == 0)
     {
      if(fast[0] > slow[0]) g_dir = 1;
      else if(fast[0] < slow[0]) g_dir = -1;
     }
   return g_dir;
  }

void ManageLegExits()
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pip = point * ((digits == 3 || digits == 5) ? 10.0 : 1.0);
   double step = TrailStepPips * pip;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket) || !IsOurs())
         continue;

      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      long type = PositionGetInteger(POSITION_TYPE);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);

      // per-leg grid TP
      if(profit >= TP_Max_USD || profit >= TP_Min_USD)
        {
         g_trade.PositionClose(ticket);
         continue;
        }

      if(profit >= Trail_Start_USD && TrailStepPips > 0)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double newSL = bid - step;
            if(sl == 0.0 || newSL > sl)
               g_trade.PositionModify(ticket, NormalizeDouble(newSL, digits), tp);
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double newSL = ask + step;
            if(sl == 0.0 || newSL < sl)
               g_trade.PositionModify(ticket, NormalizeDouble(newSL, digits), tp);
           }
        }
     }
  }

bool CloseOneOpposite(const int dir)
  {
   for(int i = PositionsTotal() - 1; i >= 0; --i)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket) || !IsOurs())
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if(dir > 0 && type == POSITION_TYPE_SELL)
         return g_trade.PositionClose(ticket);
      if(dir < 0 && type == POSITION_TYPE_BUY)
         return g_trade.PositionClose(ticket);
     }
   return false;
  }

bool OpenGridLeg(const int dir)
  {
   if(dir == 0 || CountOurs() >= MaxTrades)
      return false;
   double lots = Lots;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(volStep <= 0.0)
      return false;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   lots = MathFloor(lots / volStep + 1e-12) * volStep;
   g_trade.SetExpertMagicNumber((ulong)MagicNumber);
   if(dir > 0)
      return g_trade.Buy(lots, _Symbol, 0.0, 0.0, 0.0, TradeComment);
   return g_trade.Sell(lots, _Symbol, 0.0, 0.0, 0.0, TradeComment);
  }

void OnTick()
  {
   ManageLegExits();

   datetime now = TimeCurrent();
   if(CooldownSeconds > 0 && g_lastGridBeat != 0 && (now - g_lastGridBeat) < CooldownSeconds)
      return;
   g_lastGridBeat = now;

   int dir = GridDirection();
   if(dir == 0)
      return;

   // Pure time-grid stack in current direction.
   // SoftFlip-every-beat was tested: blows the account (too many EMA flips).
   // Original does rare reverse pairs; exact flip rule still not recovered.
   if(CountOurs() < MaxTrades)
      OpenGridLeg(dir);
  }
//+------------------------------------------------------------------+