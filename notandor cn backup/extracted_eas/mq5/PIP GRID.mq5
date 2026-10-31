//+------------------------------------------------------------------+
//|                                           PIP GRID MT5 v1.00.mq5 |
//|                               Free Forex Tools =>> pro-fx.cc     |
//+------------------------------------------------------------------+
#property copyright "Free Forex Tools"
#property version   "1.00"
#property link      "https://pro-fx.cc/"
#property strict
#property description "Free Forex Tools"
#property description "pro-fx.cc"

#include <Trade/Trade.mqh>

//--- Embedded replacement for "PIP GRID observed directional model.mqh"
#define PG_MODEL_FEATURE_COUNT 48

// Directional score over the observed feature vector.
// Uses the built-in fallback logistic coefficients mapped onto feature indices:
// f[9]=mom8, f[7]=mom3, f[21]=EMA9 slope(3 bars), f[8]=mom5, f[6]=mom2,
// f[10]=mom10, f[16]=close-EMA3, f[37]=10-bar range position (all ATR-normalized).
double PGObservedDirectionalScore(const double &f[])
  {
   if(ArraySize(f)<PG_MODEL_FEATURE_COUNT)
      return 0.0;
   double z=-0.0073974622;
   z+=-1.2147214160*((f[9] -0.2325757262)/1.6698026670);
   z+= 0.8457718417*((f[7] -0.2064971978)/1.2026672684);
   z+=-0.3336791739*((f[21]-0.0810351242)/0.5143722767);
   z+=-0.3535020699*((f[8] -0.2595288865)/1.4269047624);
   z+= 0.2318197923*((f[6] -0.14682451897)/1.0402162053);
   z+=-0.0642195590*((f[10]-0.2122884435)/1.8168483359);
   z+= 0.3741335389*((f[16]-0.06299340485)/0.4322056533);
   z+=-0.5771346124*((f[37]-0.5475150980)/0.2946665361);
   return z;
  }

enum ENUM_PG_SIGNAL_LOGIC
  {
   PG_M1_FLOW=0,
   PG_MULTI_TREND=1,
   PG_M1_REVERSION=2,
   PG_H1_TREND=3,
   PG_DUAL_ENGINE=4
  };

// Original observed input surface.
input group "PIP GRID - Observed Controls"
input double Fixed_Lot             = 0.01;
input bool   UseMM                 = true;
input double Risk                  = 1.0;
input bool   AutoLotSize           = false;
input double TotalEquityRisk       = 25.0;

input group "PIP GRID - Execution"
input ulong  MagicNumber           = 77100501;
input int    EntryEveryMinutes     = 1;
input ENUM_PG_SIGNAL_LOGIC SignalLogic = PG_DUAL_ENGINE;
input int    MaxSpreadPips         = 10;
input bool   AutoSpreadFilter      = true;
input double MaxSpreadMultiplier   = 1.25;
input int    SlippagePoints        = 30;
input bool   AllowNeutralHedge     = false;
input bool   ShowPanel             = true;

input group "PIP GRID - Behavioral Calibration"
input bool   EnablePrimarySlot      = true;
input bool   EnableDirectionalSlot  = true;
input bool   EnableExtremeSlot      = true;
input bool   CoreBuyOnly            = true;
input bool   UseObservedDirectionalModel = true;
input double PrimaryMomentumBias   = 0.00;
input double DirectionalBias       = 0.00;
input double ExtremeRSILevel       = 72.0;
input bool   PersistentEngineCycles= false;
input int    MaxPrimaryCycles      = 1;
input int    MaxSecondaryCycles    = 1;
input int    MaxExtremeCycles      = 1;
input double RecoveryOnlyDDPct     = 15.0;

input group "PIP GRID - Observed Price Geometry"
input double TakeProfitPips        = 50.0;
input double TrailTriggerPips      = 15.0;
input double TrailDistancePips     = 5.0;
input double FirstGridStepPips     = 200.0;
input double GridStepGrowth        = 1.00;
input double RecoveryMultiplier    = 1.45;

input group "PIP GRID - Enhanced Safety"
input bool   EnhancedSafety        = true;
input int    MaxRecoveryLayers     = 15;
input int    MaxOpenPositions      = 31;
input double MaxCycleLossPct       = 0.0;
input double MaxSideBasketLossPct  = 0.0;
input double DailyLossLimitPct     = 0.0;
input double EmergencyStopPips     = 0.0;
input bool   PauseAfterRiskStop    = true;

CTrade g_trade;

int      g_maFastM1   = INVALID_HANDLE;
int      g_ma3M1      = INVALID_HANDLE;
int      g_maSlowM1   = INVALID_HANDLE;
int      g_maFastM5   = INVALID_HANDLE;
int      g_maSlowM5   = INVALID_HANDLE;
int      g_maFastH1   = INVALID_HANDLE;
int      g_maSlowH1   = INVALID_HANDLE;
int      g_rsiM1      = INVALID_HANDLE;
int      g_atrM1      = INVALID_HANDLE;
int      g_observedEma[10];
int      g_observedRsi[5];
datetime g_lastM1Bar  = 0;
datetime g_dayAnchor  = 0;
double   g_dayBalance = 0.0;
double   g_peakEquity = 0.0;
bool     g_paused     = false;
bool     g_recoveryOnly=false;
bool     g_isHedging  = false;
string   g_pauseCause = "";
double   g_spreadBaseline=0.0;
int      g_spreadSamples=0;

struct SideState
  {
   ENUM_POSITION_TYPE side;
   int                 positions;
   int                 recoveryLevel;
   double              volume;
   double              weightedPrice;
   double              floatingProfit;
   double              lastRecoveryPrice;
   datetime            oldestTime;
  };

struct BasketState
  {
   long                id;
   ENUM_POSITION_TYPE  side;
   int                 positions;
   int                 recoveryLevel;
   double              volume;
   double              weightedPrice;
   double              floatingProfit;
   double              lastRecoveryPrice;
   datetime            oldestTime;
  };

//+------------------------------------------------------------------+
double PipSize()
  {
   const int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   if(digits==3 || digits==5)
      return _Point*10.0;
   return _Point;
  }

//+------------------------------------------------------------------+
double NormalizePrice(const double price)
  {
   const double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   const int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   if(tick<=0.0)
      return NormalizeDouble(price,digits);
   return NormalizeDouble(MathRound(price/tick)*tick,digits);
  }

//+------------------------------------------------------------------+
double NormalizeVolume(const double requested)
  {
   const double vmin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   const double vmax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   const double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0)
      return requested;
   double volume=MathMax(vmin,MathMin(vmax,requested));
   volume=MathRound(volume/step)*step;
   int vd=0;
   double probe=step;
   while(vd<8 && MathAbs(probe-MathRound(probe))>1e-8)
     {
      probe*=10.0;
      vd++;
     }
   return NormalizeDouble(volume,vd);
  }

//+------------------------------------------------------------------+
double NormalizeVolumeUp(const double requested)
  {
   const double vmin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   const double vmax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   const double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0)
      return requested;
   double volume=MathMax(vmin,MathMin(vmax,requested));
   volume=MathCeil(volume/step-1e-9)*step;
   int vd=0;
   double probe=step;
   while(vd<8 && MathAbs(probe-MathRound(probe))>1e-8)
     {
      probe*=10.0;
      vd++;
     }
   return NormalizeDouble(volume,vd);
  }

//+------------------------------------------------------------------+
double MinStopDistance()
  {
   const long stops=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const long freeze=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   return (double)MathMax(stops,freeze)*_Point;
  }

//+------------------------------------------------------------------+
double DistancePrice(const double pips)
  {
   return MathMax(PipSize()*pips,SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE));
  }

//+------------------------------------------------------------------+
bool IsOurPosition(const ulong ticket)
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return false;
   return PositionGetString(POSITION_SYMBOL)==_Symbol &&
          (ulong)PositionGetInteger(POSITION_MAGIC)==MagicNumber;
  }

//+------------------------------------------------------------------+
int RecoveryLevelFromComment(const string comment)
  {
   string fields[];
   if(StringSplit(comment,'|',fields)<4 || StringFind(fields[3],"R")!=0)
      return 0;
   return (int)StringToInteger(StringSubstr(fields[3],1));
  }

//+------------------------------------------------------------------+
bool BasketIdentityFromComment(const string comment,long &id,ENUM_POSITION_TYPE &side)
  {
   string fields[];
   if(StringSplit(comment,'|',fields)<4 || fields[0]!="PG")
      return false;
   id=StringToInteger(fields[1]);
   if(fields[2]=="B")
      side=POSITION_TYPE_BUY;
   else if(fields[2]=="S")
      side=POSITION_TYPE_SELL;
   else
      return false;
   return id>0;
  }

//+------------------------------------------------------------------+
bool BasketIsActive(const long id)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(!IsOurPosition(ticket))
         continue;
      long positionId=0;
      ENUM_POSITION_TYPE side=POSITION_TYPE_BUY;
      if(BasketIdentityFromComment(PositionGetString(POSITION_COMMENT),positionId,side) &&
         positionId==id)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
void ReadSideState(const ENUM_POSITION_TYPE side,SideState &state)
  {
   state.side=side;
   state.positions=0;
   state.recoveryLevel=0;
   state.volume=0.0;
   state.weightedPrice=0.0;
   state.floatingProfit=0.0;
   state.lastRecoveryPrice=0.0;
   state.oldestTime=0;

   double weighted=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(!IsOurPosition(ticket))
         continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=side)
         continue;

      const double volume=PositionGetDouble(POSITION_VOLUME);
      const double open=PositionGetDouble(POSITION_PRICE_OPEN);
      const datetime stamp=(datetime)PositionGetInteger(POSITION_TIME);
      const string comment=PositionGetString(POSITION_COMMENT);
      const int level=RecoveryLevelFromComment(comment);

      state.positions++;
      state.volume+=volume;
      weighted+=open*volume;
      state.floatingProfit+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      if(state.oldestTime==0 || stamp<state.oldestTime)
         state.oldestTime=stamp;
      if(level>state.recoveryLevel)
        {
         state.recoveryLevel=level;
         state.lastRecoveryPrice=open;
        }
     }
   if(state.volume>0.0)
      state.weightedPrice=weighted/state.volume;

   if(state.positions>0 && state.lastRecoveryPrice<=0.0)
     {
      datetime oldest=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(!IsOurPosition(ticket))
            continue;
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=side)
            continue;
         const datetime stamp=(datetime)PositionGetInteger(POSITION_TIME);
         if(oldest==0 || stamp<oldest)
           {
            oldest=stamp;
            state.lastRecoveryPrice=PositionGetDouble(POSITION_PRICE_OPEN);
           }
        }
     }
  }

//+------------------------------------------------------------------+
void ReadBasketState(const long id,const ENUM_POSITION_TYPE side,BasketState &state)
  {
   state.id=id;
   state.side=side;
   state.positions=0;
   state.recoveryLevel=0;
   state.volume=0.0;
   state.weightedPrice=0.0;
   state.floatingProfit=0.0;
   state.lastRecoveryPrice=0.0;
   state.oldestTime=0;
   double weighted=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(!IsOurPosition(ticket))
         continue;
      long positionId=0;
      ENUM_POSITION_TYPE positionSide;
      const string comment=PositionGetString(POSITION_COMMENT);
      if(!BasketIdentityFromComment(comment,positionId,positionSide) ||
         positionId!=id || positionSide!=side)
         continue;

      const double volume=PositionGetDouble(POSITION_VOLUME);
      const double open=PositionGetDouble(POSITION_PRICE_OPEN);
      const datetime stamp=(datetime)PositionGetInteger(POSITION_TIME);
      const int level=RecoveryLevelFromComment(comment);
      state.positions++;
      state.volume+=volume;
      weighted+=open*volume;
      state.floatingProfit+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      if(state.oldestTime==0 || stamp<state.oldestTime)
         state.oldestTime=stamp;
      if(level>=state.recoveryLevel)
        {
         state.recoveryLevel=level;
         state.lastRecoveryPrice=open;
        }
     }
   if(state.volume>0.0)
      state.weightedPrice=weighted/state.volume;
  }

//+------------------------------------------------------------------+
bool BasketKeyExists(BasketState &keys[],const long id,const ENUM_POSITION_TYPE side)
  {
   for(int i=0;i<ArraySize(keys);i++)
      if(keys[i].id==id && keys[i].side==side)
         return true;
   return false;
  }

//+------------------------------------------------------------------+
void CollectBasketKeys(BasketState &keys[])
  {
   ArrayResize(keys,0);
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(!IsOurPosition(ticket))
         continue;
      long id=0;
      ENUM_POSITION_TYPE side;
      if(!BasketIdentityFromComment(PositionGetString(POSITION_COMMENT),id,side))
         continue;
      if(BasketKeyExists(keys,id,side))
         continue;
      const int size=ArraySize(keys);
      ArrayResize(keys,size+1);
      ReadBasketState(id,side,keys[size]);
     }
  }

//+------------------------------------------------------------------+
int ActiveCycleCount(const int engineSlot)
  {
   BasketState baskets[];
   CollectBasketKeys(baskets);
   int count=0;
   for(int i=0;i<ArraySize(baskets);i++)
      if((int)(baskets[i].id%10)==engineSlot)
         count++;
   return count;
  }

//+------------------------------------------------------------------+
bool CycleSlotAvailable(const int engineSlot,const int maximum)
  {
   return maximum<=0 || ActiveCycleCount(engineSlot)<maximum;
  }

//+------------------------------------------------------------------+
int OurPositionCount()
  {
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(IsOurPosition(ticket))
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
double BaseVolume()
  {
   if(!AutoLotSize)
      return NormalizeVolume(Fixed_Lot);

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return NormalizeVolume(Fixed_Lot);
   const double stopDistance=DistancePrice(MathMax(EmergencyStopPips,TakeProfitPips*2.0));
   double lossOneLot=0.0;
   if(!OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1.0,tick.ask,tick.ask-stopDistance,lossOneLot))
      return NormalizeVolume(Fixed_Lot);
   lossOneLot=MathAbs(lossOneLot);
   if(lossOneLot<=0.0)
      return NormalizeVolume(Fixed_Lot);
   const double riskMoney=AccountInfoDouble(ACCOUNT_BALANCE)*MathMax(0.01,Risk)/100.0;
   return NormalizeVolume(riskMoney/lossOneLot);
  }

//+------------------------------------------------------------------+
double RecoveryVolume(const int level)
  {
   const double base=BaseVolume();
   if(!UseMM || level<=0)
      return base;
   // Exact normalized chain recovered from the source journal. Ratios are
   // relative to the 0.01 seed and scale to any configured base volume.
   const double ratios[15]={2.0,3.0,4.0,6.0,9.0,13.0,18.0,27.0,
                            38.0,55.0,79.0,114.0,165.0,237.0,342.0};
   if(level<=15 && MathAbs(RecoveryMultiplier-1.45)<0.001)
      return NormalizeVolume(base*ratios[level-1]);
   return NormalizeVolumeUp(base*MathPow(MathMax(1.0,RecoveryMultiplier),level));
  }

//+------------------------------------------------------------------+
bool ReadIndicator(const int handle,const int shift,double &value)
  {
   double buffer[1];
   if(handle==INVALID_HANDLE || CopyBuffer(handle,0,shift,1,buffer)!=1)
      return false;
   value=buffer[0];
   return MathIsValidNumber(value);
  }

//+------------------------------------------------------------------+
double ClosedVolatility(const MqlRates &bars[],const int window)
  {
   if(window<2 || ArraySize(bars)<window+2)
      return 0.0;
   double sum=0.0,sumSquares=0.0;
   for(int i=0;i<window;i++)
     {
      if(bars[i+2].close<=0.0)
         return 0.0;
      const double value=(bars[i+1].close/bars[i+2].close-1.0)*10000.0;
      sum+=value;
      sumSquares+=value*value;
     }
   const double variance=MathMax(0.0,(sumSquares-sum*sum/window)/(window-1));
   return MathSqrt(variance);
  }

//+------------------------------------------------------------------+
double ClosedRangePosition(const MqlRates &bars[],const int window)
  {
   if(window<1 || ArraySize(bars)<window+1)
      return 0.5;
   double highest=bars[1].high;
   double lowest=bars[1].low;
   for(int i=2;i<=window;i++)
     {
      highest=MathMax(highest,bars[i].high);
      lowest=MathMin(lowest,bars[i].low);
     }
   return (highest>lowest ? (bars[1].close-lowest)/(highest-lowest) : 0.5);
  }

//+------------------------------------------------------------------+
bool ReadObservedDirectionalFeatures(double &features[])
  {
   MqlRates bars[];
   ArrayResize(bars,122);
   ArraySetAsSeries(bars,true);
   if(CopyRates(_Symbol,PERIOD_M1,0,122,bars)!=122)
      return false;

   double atrValue=0.0;
   if(!ReadIndicator(g_atrM1,1,atrValue) || atrValue<=0.0)
      return false;

   double emaNow[10],emaPast[10],rsi[5];
   for(int i=0;i<10;i++)
     {
      if(!ReadIndicator(g_observedEma[i],1,emaNow[i]))
         return false;
      emaPast[i]=emaNow[i];
     }
   if(!ReadIndicator(g_observedEma[1],4,emaPast[1]) ||
      !ReadIndicator(g_observedEma[3],4,emaPast[3]) ||
      !ReadIndicator(g_observedEma[5],4,emaPast[5]) ||
      !ReadIndicator(g_observedEma[7],4,emaPast[7]))
      return false;
   for(int i=0;i<5;i++)
      if(!ReadIndicator(g_observedRsi[i],1,rsi[i]))
         return false;

   ArrayResize(features,PG_MODEL_FEATURE_COUNT);
   const double closedOpen=bars[1].open;
   const double closedHigh=bars[1].high;
   const double closedLow=bars[1].low;
   const double closedClose=bars[1].close;
   features[0]=(bars[0].open-closedClose)/atrValue;
   features[1]=(closedClose-closedOpen)/atrValue;
   features[2]=(closedHigh-closedLow)/atrValue;
   features[3]=(closedHigh-MathMax(closedOpen,closedClose))/atrValue;
   features[4]=(MathMin(closedOpen,closedClose)-closedLow)/atrValue;

   const int lags[11]={1,2,3,5,8,10,15,20,30,60,120};
   for(int i=0;i<11;i++)
      features[5+i]=(closedClose-bars[1+lags[i]].close)/atrValue;

   features[16]=(closedClose-emaNow[0])/atrValue;
   features[17]=(closedClose-emaNow[1])/atrValue;
   features[18]=(emaNow[1]-emaPast[1])/atrValue;
   features[19]=(closedClose-emaNow[2])/atrValue;
   features[20]=(closedClose-emaNow[3])/atrValue;
   features[21]=(emaNow[3]-emaPast[3])/atrValue;
   features[22]=(closedClose-emaNow[4])/atrValue;
   features[23]=(closedClose-emaNow[5])/atrValue;
   features[24]=(emaNow[5]-emaPast[5])/atrValue;
   features[25]=(closedClose-emaNow[6])/atrValue;
   features[26]=(closedClose-emaNow[7])/atrValue;
   features[27]=(emaNow[7]-emaPast[7])/atrValue;
   features[28]=(closedClose-emaNow[8])/atrValue;
   features[29]=(closedClose-emaNow[9])/atrValue;
   for(int i=0;i<5;i++)
      features[30+i]=rsi[i];

   features[35]=ClosedRangePosition(bars,5);
   features[36]=ClosedVolatility(bars,5);
   features[37]=ClosedRangePosition(bars,10);
   features[38]=ClosedVolatility(bars,10);
   features[39]=ClosedRangePosition(bars,20);
   features[40]=ClosedVolatility(bars,20);
   features[41]=ClosedRangePosition(bars,50);
   features[42]=ClosedVolatility(bars,50);
   features[43]=(double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);

   MqlDateTime parts;
   TimeToStruct(bars[0].time,parts);
   const double hourAngle=2.0*M_PI*parts.hour/24.0;
   const double minuteAngle=2.0*M_PI*parts.min/60.0;
   features[44]=MathSin(hourAngle);
   features[45]=MathCos(hourAngle);
   features[46]=MathSin(minuteAngle);
   features[47]=MathCos(minuteAngle);
   return true;
  }

//+------------------------------------------------------------------+
int SignalScore()
  {
   double f1=0,s1=0,f5=0,s5=0,fh=0,sh=0,rsi=50;
   if(!ReadIndicator(g_maFastM1,1,f1) || !ReadIndicator(g_maSlowM1,1,s1) ||
      !ReadIndicator(g_maFastM5,1,f5) || !ReadIndicator(g_maSlowM5,1,s5) ||
      !ReadIndicator(g_maFastH1,1,fh) || !ReadIndicator(g_maSlowH1,1,sh) ||
      !ReadIndicator(g_rsiM1,1,rsi))
      return 0;

   MqlRates bars[];
   ArrayResize(bars,3);
   ArraySetAsSeries(bars,true);
   if(CopyRates(_Symbol,PERIOD_M1,1,3,bars)!=3)
      return 0;

   if(SignalLogic==PG_M1_FLOW || SignalLogic==PG_M1_REVERSION)
     {
      const double body=bars[0].close-bars[0].open;
      if(MathAbs(body)<_Point*0.5)
         return 0;
      int flow=(body>0.0 ? 4 : -4);
      return (SignalLogic==PG_M1_REVERSION ? -flow : flow);
     }
   if(SignalLogic==PG_H1_TREND)
      return (fh>=sh ? 4 : -4);

   int score=0;
   score+=(fh>=sh ? 3 : -3);
   score+=(f5>=s5 ? 2 : -2);
   score+=(f1>=s1 ? 1 : -1);

   score+=(bars[0].close>=bars[0].open ? 1 : -1);
   score+=(bars[0].close>=bars[1].close ? 1 : -1);
   if(rsi>=68.0)
      score--;
   else if(rsi<=32.0)
      score++;
   return score;
  }

//+------------------------------------------------------------------+
// Reconstructs the three independent cycle slots found in the source journal:
// (1) a buy-core slot, (2) a fast directional/reversion slot, and (3) a rare
// extreme slot.  The directional score was fitted only to information available
// before the entry minute and was then checked on the final 25% of chronology.
bool ReadDualEngineSignals(ENUM_POSITION_TYPE &primary,
                           bool &hasSecondary,ENUM_POSITION_TYPE &secondary,
                           bool &hasExtreme,ENUM_POSITION_TYPE &extreme)
  {
   double observedFeatures[];
   if(UseObservedDirectionalModel && !ReadObservedDirectionalFeatures(observedFeatures))
      return false;

   MqlRates bars[];
   ArrayResize(bars,12);
   ArraySetAsSeries(bars,true);
   double atrValue=0.0,rsi=50.0,ema3=0.0,ema9Now=0.0,ema9Past=0.0;
   if(CopyRates(_Symbol,PERIOD_M1,1,12,bars)!=12 ||
      !ReadIndicator(g_atrM1,1,atrValue) || !ReadIndicator(g_rsiM1,1,rsi) ||
      !ReadIndicator(g_ma3M1,1,ema3) || !ReadIndicator(g_maFastM1,1,ema9Now) ||
      !ReadIndicator(g_maFastM1,4,ema9Past) || atrValue<=0.0)
      return false;

   const double c=bars[0].close;
   const double mom8=(c-bars[8].close)/atrValue;
   const double mom3=(c-bars[3].close)/atrValue;
   const double mom5=(c-bars[5].close)/atrValue;
   const double mom2=(c-bars[2].close)/atrValue;
   const double mom10=(c-bars[10].close)/atrValue;
   const double ema9Slope=(ema9Now-ema9Past)/atrValue;
   const double closeEma3=(c-ema3)/atrValue;
   double highest=bars[0].high;
   double lowest=bars[0].low;
   for(int i=1;i<10;i++)
     {
      highest=MathMax(highest,bars[i].high);
      lowest=MathMin(lowest,bars[i].low);
     }
   const double rangePos=(highest>lowest ? (c-lowest)/(highest-lowest) : 0.5);

   // Fast flow slot: follows the completed three-minute impulse.  The source
   // journal is buy-heavy because upward cycles close faster, but the slot must
   // be allowed to sell during an actual downswing or a buy-only reconstruction
   // is destroyed by the first sustained drop.
   primary=(CoreBuyOnly ? POSITION_TYPE_BUY :
            (mom3>=PrimaryMomentumBias ? POSITION_TYPE_BUY : POSITION_TYPE_SELL));

   double z=DirectionalBias;
   if(UseObservedDirectionalModel)
      z+=PGObservedDirectionalScore(observedFeatures);
   else
     {
      z+=-0.0073974622;
      z+=-1.2147214160*((mom8-0.2325757262)/1.6698026670);
      z+= 0.8457718417*((mom3-0.2064971978)/1.2026672684);
      z+=-0.3336791739*((ema9Slope-0.0810351242)/0.5143722767);
      z+=-0.3535020699*((mom5-0.2595288865)/1.4269047624);
      z+= 0.2318197923*((mom2-0.14682451897)/1.0402162053);
      z+=-0.0642195590*((mom10-0.2122884435)/1.8168483359);
      z+= 0.3741335389*((closeEma3-0.06299340485)/0.4322056533);
      z+=-0.5771346124*((rangePos-0.5475150980)/0.2946665361);
     }
   hasSecondary=true;
   secondary=(z>=0.0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);

   hasExtreme=false;
   extreme=POSITION_TYPE_BUY;
   const double extremeHigh=MathMax(50.1,ExtremeRSILevel);
   const double extremeLow=100.0-extremeHigh;
   if(rsi<=extremeLow)
     {
      hasExtreme=true;
      extreme=POSITION_TYPE_BUY;
     }
   else if(rsi>=extremeHigh)
     {
      hasExtreme=true;
      extreme=POSITION_TYPE_SELL;
     }
   return true;
  }

//+------------------------------------------------------------------+
bool SpreadAccepted()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;
   const double spread=tick.ask-tick.bid;
   const double fixedLimit=(MaxSpreadPips>0 ? DistancePrice((double)MaxSpreadPips) : 0.0);
   double adaptiveLimit=0.0;
   // A higher broker-normal spread regime is activated only after a stable
   // sample.  Raw accounts whose baseline is already inside the fixed ceiling
   // keep the exact original filter instead of being accidentally widened.
   if(AutoSpreadFilter && g_spreadBaseline>0.0 && g_spreadSamples>=100 &&
      (fixedLimit<=0.0 || g_spreadBaseline>fixedLimit*1.5))
      adaptiveLimit=g_spreadBaseline*MathMax(1.0,MaxSpreadMultiplier);
   const double allowed=MathMax(fixedLimit,adaptiveLimit);
   return allowed<=0.0 || spread<=allowed+_Point*0.1;
  }

//+------------------------------------------------------------------+
void UpdateSpreadBaseline()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return;
   const double spread=tick.ask-tick.bid;
   if(spread<=0.0)
      return;
   // Do not teach an expansion spike into the normal-spread baseline.
   if(g_spreadSamples>=20 && g_spreadBaseline>0.0 && spread>g_spreadBaseline*5.0)
      return;
   g_spreadSamples++;
   const double alpha=(g_spreadSamples<=100 ? 1.0/g_spreadSamples : 0.002);
   g_spreadBaseline+=(spread-g_spreadBaseline)*alpha;
  }

//+------------------------------------------------------------------+
bool ValidStopsForOpen(const ENUM_ORDER_TYPE orderType,double &sl,double &tp)
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;
   const double minDistance=MinStopDistance()+SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(orderType==ORDER_TYPE_BUY)
     {
      if(sl>0.0)
         sl=NormalizePrice(MathMin(sl,tick.bid-minDistance));
      if(tp>0.0)
         tp=NormalizePrice(MathMax(tp,tick.ask+minDistance));
     }
   else
     {
      if(sl>0.0)
         sl=NormalizePrice(MathMax(sl,tick.ask+minDistance));
      if(tp>0.0)
         tp=NormalizePrice(MathMin(tp,tick.bid-minDistance));
     }
   return true;
  }

//+------------------------------------------------------------------+
bool OpenPosition(const ENUM_POSITION_TYPE side,const double volume,const long basketId,
                  const int recoveryLevel)
  {
   if(volume<=0.0 || OurPositionCount()>=MaxOpenPositions || !SpreadAccepted())
      return false;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;

   const bool isBuy=(side==POSITION_TYPE_BUY);
   const double open=(isBuy ? tick.ask : tick.bid);
   double tp=open+(isBuy ? 1.0 : -1.0)*DistancePrice(TakeProfitPips);
   double sl=0.0;
   if(EnhancedSafety && EmergencyStopPips>0.0)
      sl=open+(isBuy ? -1.0 : 1.0)*DistancePrice(EmergencyStopPips);
   ValidStopsForOpen(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,sl,tp);

   const string comment=StringFormat("PG|%I64d|%s|R%d",basketId,isBuy ? "B" : "S",
                                     recoveryLevel);
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(SlippagePoints);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   bool ok=false;
   if(isBuy)
      ok=g_trade.Buy(volume,_Symbol,0.0,sl,tp,comment);
   else
      ok=g_trade.Sell(volume,_Symbol,0.0,sl,tp,comment);
   if(!ok)
      PrintFormat("PIP GRID MT5: entry rejected retcode=%u %s",g_trade.ResultRetcode(),
                  g_trade.ResultRetcodeDescription());
   return ok;
  }

//+------------------------------------------------------------------+
bool IsModifyValid(const ENUM_POSITION_TYPE side,const double sl,const double tp)
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;
   const double minDistance=MinStopDistance()+SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(side==POSITION_TYPE_BUY)
      return (sl<=0.0 || sl<tick.bid-minDistance+_Point*0.1) &&
             (tp<=0.0 || tp>tick.bid+minDistance-_Point*0.1);
   return (sl<=0.0 || sl>tick.ask+minDistance-_Point*0.1) &&
          (tp<=0.0 || tp<tick.ask-minDistance+_Point*0.1);
  }

//+------------------------------------------------------------------+
void CloseSide(const ENUM_POSITION_TYPE side,const string reason)
  {
   SideState state;
   ReadSideState(side,state);
   if(state.positions<=0)
      return;
   PrintFormat("PIP GRID MT5: closing %s basket: %s",
               side==POSITION_TYPE_BUY ? "BUY" : "SELL",reason);
   for(int pass=0;pass<3;pass++)
     {
      bool found=false;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(!IsOurPosition(ticket))
            continue;
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=side)
            continue;
         found=true;
         if(!g_trade.PositionClose(ticket,SlippagePoints))
            PrintFormat("PIP GRID MT5: close rejected #%I64u retcode=%u %s",ticket,
                        g_trade.ResultRetcode(),g_trade.ResultRetcodeDescription());
        }
      if(!found)
         break;
     }
  }

//+------------------------------------------------------------------+
void CloseBasket(const long id,const ENUM_POSITION_TYPE side,const string reason)
  {
   PrintFormat("PIP GRID MT5: closing cycle %I64d %s: %s",id,
               side==POSITION_TYPE_BUY ? "BUY" : "SELL",reason);
   for(int pass=0;pass<3;pass++)
     {
      bool found=false;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(!IsOurPosition(ticket))
            continue;
         long positionId=0;
         ENUM_POSITION_TYPE positionSide;
         if(!BasketIdentityFromComment(PositionGetString(POSITION_COMMENT),positionId,positionSide) ||
            positionId!=id || positionSide!=side)
            continue;
         found=true;
         if(!g_trade.PositionClose(ticket,SlippagePoints))
            PrintFormat("PIP GRID MT5: cycle close rejected #%I64u retcode=%u %s",ticket,
                        g_trade.ResultRetcode(),g_trade.ResultRetcodeDescription());
        }
      if(!found)
         break;
     }
  }

//+------------------------------------------------------------------+
void DeleteOurPendingOrders()
  {
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      const ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol ||
         (ulong)OrderGetInteger(ORDER_MAGIC)!=MagicNumber)
         continue;
      g_trade.OrderDelete(ticket);
     }
  }

//+------------------------------------------------------------------+
void CloseAll(const string reason)
  {
   CloseSide(POSITION_TYPE_BUY,reason);
   CloseSide(POSITION_TYPE_SELL,reason);
   DeleteOurPendingOrders();
  }

//+------------------------------------------------------------------+
void UpdateBasketStops(const long id,const ENUM_POSITION_TYPE side)
  {
   BasketState state;
   ReadBasketState(id,side,state);
   if(state.positions<=0 || state.volume<=0.0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return;
   const bool isBuy=(side==POSITION_TYPE_BUY);
   double target=NormalizePrice(state.weightedPrice+(isBuy ? 1.0 : -1.0)*DistancePrice(TakeProfitPips));
   const double trigger=state.weightedPrice+(isBuy ? 1.0 : -1.0)*DistancePrice(TrailTriggerPips);
   const bool armed=(isBuy ? tick.bid>=trigger : tick.ask<=trigger);
   double commonSL=0.0;
   if(armed)
      commonSL=NormalizePrice((isBuy ? tick.bid : tick.ask)+
                              (isBuy ? -1.0 : 1.0)*DistancePrice(TrailDistancePips));

   const double minDistance=MinStopDistance()+SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(isBuy && target<=tick.bid+minDistance)
     {
      CloseBasket(id,side,"target reached");
      return;
     }
   if(!isBuy && target>=tick.ask-minDistance)
     {
      CloseBasket(id,side,"target reached");
      return;
     }

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(!IsOurPosition(ticket))
         continue;
      long positionId=0;
      ENUM_POSITION_TYPE positionSide;
      if(!BasketIdentityFromComment(PositionGetString(POSITION_COMMENT),positionId,positionSide) ||
         positionId!=id || positionSide!=side)
         continue;

      double desiredSL=commonSL;
      const double currentSL=PositionGetDouble(POSITION_SL);
      if(!armed && EnhancedSafety && EmergencyStopPips>0.0)
        {
         const double open=PositionGetDouble(POSITION_PRICE_OPEN);
         desiredSL=NormalizePrice(open+(isBuy ? -1.0 : 1.0)*DistancePrice(EmergencyStopPips));
        }
      if(armed && currentSL>0.0)
        {
         if(isBuy)
            desiredSL=MathMax(desiredSL,currentSL);
         else
            desiredSL=MathMin(desiredSL,currentSL);
        }

      if(!IsModifyValid(side,desiredSL,target))
         continue;
      const double tickSize=MathMax(_Point,SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE));
      if(MathAbs(PositionGetDouble(POSITION_TP)-target)<tickSize*0.5 &&
         MathAbs(currentSL-desiredSL)<tickSize*0.5)
         continue;
      if(!g_trade.PositionModify(ticket,desiredSL,target))
        {
         const uint code=g_trade.ResultRetcode();
         if(code!=TRADE_RETCODE_NO_CHANGES)
            PrintFormat("PIP GRID MT5: modify rejected #%I64u retcode=%u %s",ticket,code,
                        g_trade.ResultRetcodeDescription());
        }
     }
  }

//+------------------------------------------------------------------+
void ManageAllBaskets()
  {
   BasketState baskets[];
   CollectBasketKeys(baskets);
   for(int i=0;i<ArraySize(baskets);i++)
      UpdateBasketStops(baskets[i].id,baskets[i].side);
  }

//+------------------------------------------------------------------+
bool NewDay(const datetime now)
  {
   MqlDateTime parts;
   TimeToStruct(now,parts);
   parts.hour=0;
   parts.min=0;
   parts.sec=0;
   const datetime anchor=StructToTime(parts);
   if(anchor==g_dayAnchor)
      return false;
   g_dayAnchor=anchor;
   return true;
  }

//+------------------------------------------------------------------+
void ApplyRiskControls()
  {
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   const double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   if(NewDay(TimeCurrent()))
     {
      g_dayBalance=balance;
      if(g_paused && g_pauseCause=="daily loss")
        {
         g_paused=false;
         g_pauseCause="";
        }
     }
   if(g_paused)
      return;
   g_peakEquity=MathMax(g_peakEquity,equity);
   const double currentDD=(g_peakEquity>0.0 ?
                           100.0*(g_peakEquity-equity)/g_peakEquity : 0.0);
   g_recoveryOnly=(RecoveryOnlyDDPct>0.0 && currentDD>=RecoveryOnlyDDPct);

   if(TotalEquityRisk>0.0 && g_peakEquity>0.0)
     {
      if(currentDD>=TotalEquityRisk)
        {
         CloseAll("total equity risk reached");
         if(PauseAfterRiskStop)
           {
            g_paused=true;
            g_pauseCause="equity risk";
           }
         else
           {
            // Start a genuinely new risk cycle.  Without resetting the peak,
            // currentDD remains above the threshold forever and the EA cannot
            // continue even when the user explicitly selected continue mode.
            g_peakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
            g_recoveryOnly=false;
           }
         return;
        }
     }

   if(EnhancedSafety && DailyLossLimitPct>0.0 && g_dayBalance>0.0)
     {
      const double dayLossPct=100.0*(g_dayBalance-equity)/g_dayBalance;
      if(dayLossPct>=DailyLossLimitPct)
        {
         CloseAll("daily loss reached");
         if(PauseAfterRiskStop)
           {
            g_paused=true;
            g_pauseCause="daily loss";
           }
         return;
        }
     }

   if(EnhancedSafety && MaxSideBasketLossPct>0.0 && balance>0.0)
     {
      SideState buyState,sellState;
      ReadSideState(POSITION_TYPE_BUY,buyState);
      ReadSideState(POSITION_TYPE_SELL,sellState);
      const double maxLoss=balance*MaxSideBasketLossPct/100.0;
      if(buyState.floatingProfit<=-maxLoss)
         CloseSide(POSITION_TYPE_BUY,"side basket loss reached");
      if(sellState.floatingProfit<=-maxLoss)
         CloseSide(POSITION_TYPE_SELL,"side basket loss reached");
     }

   if(EnhancedSafety && MaxCycleLossPct>0.0 && balance>0.0)
     {
      BasketState baskets[];
      CollectBasketKeys(baskets);
      const double maxCycleLoss=balance*MaxCycleLossPct/100.0;
      for(int i=0;i<ArraySize(baskets);i++)
         if(baskets[i].floatingProfit<=-maxCycleLoss)
            CloseBasket(baskets[i].id,baskets[i].side,"cycle loss reached");
     }
  }

//+------------------------------------------------------------------+
bool TryRecovery(const BasketState &snapshot)
  {
   if(!UseMM || !g_isHedging || OurPositionCount()>=MaxOpenPositions)
      return false;
   BasketState state;
   ReadBasketState(snapshot.id,snapshot.side,state);
   if(state.positions<=0 || state.recoveryLevel>=MaxRecoveryLayers)
      return false;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;

   const int nextLevel=state.recoveryLevel+1;
   const double step=DistancePrice(FirstGridStepPips)*
                     MathPow(MathMax(1.0,GridStepGrowth),MathMax(0,nextLevel-1));
   const bool adverse=(state.side==POSITION_TYPE_BUY ? tick.ask<=state.lastRecoveryPrice-step
                                                      : tick.bid>=state.lastRecoveryPrice+step);
   if(adverse)
     {
      if(OpenPosition(state.side,RecoveryVolume(nextLevel),state.id,nextLevel))
        {
         UpdateBasketStops(state.id,state.side);
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
void TryAllRecoveries()
  {
   BasketState baskets[];
   CollectBasketKeys(baskets);
   int opened=0;
   for(int i=0;i<ArraySize(baskets) && opened<2;i++)
      if(TryRecovery(baskets[i]))
         opened++;
  }

//+------------------------------------------------------------------+
void ExecuteMinuteEntry()
  {
   if(g_paused || !SpreadAccepted() || OurPositionCount()>=MaxOpenPositions)
      return;

   TryAllRecoveries();
   if(g_recoveryOnly || OurPositionCount()>=MaxOpenPositions)
      return;

   if(SignalLogic==PG_DUAL_ENGINE)
     {
      ENUM_POSITION_TYPE primary=POSITION_TYPE_BUY;
      ENUM_POSITION_TYPE secondary=POSITION_TYPE_BUY;
      ENUM_POSITION_TYPE extreme=POSITION_TYPE_BUY;
      bool hasSecondary=false,hasExtreme=false;
      if(!ReadDualEngineSignals(primary,hasSecondary,secondary,hasExtreme,extreme))
         return;

      if(!g_isHedging)
        {
         SideState opposite;
         ReadSideState(primary==POSITION_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY,opposite);
         if(opposite.positions>0)
            return;
         hasSecondary=(hasSecondary && secondary==primary);
         hasExtreme=(hasExtreme && extreme==primary);
        }

      const long seed=(long)g_lastM1Bar*10;
      const long primaryId=(PersistentEngineCycles ? 101 : seed+1);
      const long secondaryId=(PersistentEngineCycles ? 102 : seed+2);
      const long extremeId=(PersistentEngineCycles ? 103 : seed+3);
      if(EnablePrimarySlot && !BasketIsActive(primaryId) &&
         CycleSlotAvailable(1,MaxPrimaryCycles) &&
         OpenPosition(primary,BaseVolume(),primaryId,0))
         UpdateBasketStops(primaryId,primary);
      if(EnableDirectionalSlot && hasSecondary && !BasketIsActive(secondaryId) &&
         CycleSlotAvailable(2,MaxSecondaryCycles) &&
         OurPositionCount()<MaxOpenPositions &&
         OpenPosition(secondary,BaseVolume(),secondaryId,0))
         UpdateBasketStops(secondaryId,secondary);
      if(EnableExtremeSlot && hasExtreme && !BasketIsActive(extremeId) &&
         CycleSlotAvailable(3,MaxExtremeCycles) &&
         OurPositionCount()<MaxOpenPositions &&
         OpenPosition(extreme,BaseVolume(),extremeId,0))
         UpdateBasketStops(extremeId,extreme);
      return;
     }

   const int score=SignalScore();
   const ENUM_POSITION_TYPE primary=(score>=0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);

   if(!g_isHedging)
     {
      SideState opposite;
      ReadSideState(primary==POSITION_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY,opposite);
      if(opposite.positions>0)
         return;
     }
   const long basketId=(long)g_lastM1Bar;
   OpenPosition(primary,BaseVolume(),basketId,0);

   if(AllowNeutralHedge && g_isHedging && MathAbs(score)<=2 &&
      OurPositionCount()<MaxOpenPositions)
     {
      const ENUM_POSITION_TYPE other=(primary==POSITION_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);
      OpenPosition(other,BaseVolume(),basketId,0);
     }

   UpdateBasketStops(basketId,primary);
   if(AllowNeutralHedge && g_isHedging && MathAbs(score)<=2)
      UpdateBasketStops(basketId,primary==POSITION_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);
  }

//+------------------------------------------------------------------+
void DrawPanel()
  {
   if(!ShowPanel)
     {
      Comment("");
      return;
     }
   SideState buys,sells;
   ReadSideState(POSITION_TYPE_BUY,buys);
   ReadSideState(POSITION_TYPE_SELL,sells);
   MqlTick tick;
   SymbolInfoTick(_Symbol,tick);
   const double spreadPips=(tick.ask-tick.bid)/PipSize();
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   const double dd=(g_peakEquity>0.0 ? 100.0*(g_peakEquity-equity)/g_peakEquity : 0.0);
   const string state=(g_paused ? "PAUSED - "+g_pauseCause :
                       (g_recoveryOnly ? "RECOVERY ONLY" : "ACTIVE"));
   Comment("PIP GRID MT5 v1.00\n",
           state,"  |  ",_Symbol,"  |  internal M1\n",
           "BUY  ",buys.positions," positions  R",buys.recoveryLevel,
           "  P/L ",DoubleToString(buys.floatingProfit,2),"\n",
           "SELL ",sells.positions," positions  R",sells.recoveryLevel,
           "  P/L ",DoubleToString(sells.floatingProfit,2),"\n",
           "Spread ",DoubleToString(spreadPips,1)," pips  |  Equity DD ",
           DoubleToString(dd,2),"%");
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(Fixed_Lot<=0.0 || EntryEveryMinutes<1 || TakeProfitPips<=0.0 ||
      TrailTriggerPips<=0.0 || TrailDistancePips<=0.0 ||
      MaxOpenPositions<1 || MaxRecoveryLayers<0)
     {
      Print("PIP GRID MT5: invalid input values.");
      return INIT_PARAMETERS_INCORRECT;
     }

   g_isHedging=((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)==
                ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(SlippagePoints);
   g_trade.SetAsyncMode(false);
   if(MQLInfoInteger(MQL_TESTER))
      g_trade.LogLevel(LOG_LEVEL_NO);

   g_maFastM1=iMA(_Symbol,PERIOD_M1,9,0,MODE_EMA,PRICE_CLOSE);
   g_ma3M1=iMA(_Symbol,PERIOD_M1,3,0,MODE_EMA,PRICE_CLOSE);
   g_maSlowM1=iMA(_Symbol,PERIOD_M1,21,0,MODE_EMA,PRICE_CLOSE);
   g_maFastM5=iMA(_Symbol,PERIOD_M5,9,0,MODE_EMA,PRICE_CLOSE);
   g_maSlowM5=iMA(_Symbol,PERIOD_M5,21,0,MODE_EMA,PRICE_CLOSE);
   g_maFastH1=iMA(_Symbol,PERIOD_H1,9,0,MODE_EMA,PRICE_CLOSE);
   g_maSlowH1=iMA(_Symbol,PERIOD_H1,21,0,MODE_EMA,PRICE_CLOSE);
   g_rsiM1=iRSI(_Symbol,PERIOD_M1,14,PRICE_CLOSE);
   g_atrM1=iATR(_Symbol,PERIOD_M1,14);
   const int observedEmaPeriods[10]={3,5,8,9,13,21,34,50,100,200};
   const int observedRsiPeriods[5]={5,7,9,14,21};
   for(int i=0;i<10;i++)
      g_observedEma[i]=iMA(_Symbol,PERIOD_M1,observedEmaPeriods[i],0,MODE_EMA,PRICE_CLOSE);
   for(int i=0;i<5;i++)
      g_observedRsi[i]=iRSI(_Symbol,PERIOD_M1,observedRsiPeriods[i],PRICE_CLOSE);
   if(g_maFastM1==INVALID_HANDLE || g_ma3M1==INVALID_HANDLE ||
      g_maSlowM1==INVALID_HANDLE ||
      g_maFastM5==INVALID_HANDLE || g_maSlowM5==INVALID_HANDLE ||
      g_maFastH1==INVALID_HANDLE || g_maSlowH1==INVALID_HANDLE ||
      g_rsiM1==INVALID_HANDLE || g_atrM1==INVALID_HANDLE)
     {
      Print("PIP GRID MT5: indicator initialization failed.");
      return INIT_FAILED;
     }
   for(int i=0;i<10;i++)
      if(g_observedEma[i]==INVALID_HANDLE)
         return INIT_FAILED;
   for(int i=0;i<5;i++)
      if(g_observedRsi[i]==INVALID_HANDLE)
         return INIT_FAILED;

   g_dayBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   NewDay(TimeCurrent());
   EventSetTimer(1);
   PrintFormat("PIP GRID MT5 initialized on %s. Account mode: %s",_Symbol,
               g_isHedging ? "hedging" : "netting (single-direction fallback)");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
   if(g_maFastM1!=INVALID_HANDLE) IndicatorRelease(g_maFastM1);
   if(g_ma3M1!=INVALID_HANDLE) IndicatorRelease(g_ma3M1);
   if(g_maSlowM1!=INVALID_HANDLE) IndicatorRelease(g_maSlowM1);
   if(g_maFastM5!=INVALID_HANDLE) IndicatorRelease(g_maFastM5);
   if(g_maSlowM5!=INVALID_HANDLE) IndicatorRelease(g_maSlowM5);
   if(g_maFastH1!=INVALID_HANDLE) IndicatorRelease(g_maFastH1);
   if(g_maSlowH1!=INVALID_HANDLE) IndicatorRelease(g_maSlowH1);
   if(g_rsiM1!=INVALID_HANDLE) IndicatorRelease(g_rsiM1);
   if(g_atrM1!=INVALID_HANDLE) IndicatorRelease(g_atrM1);
   for(int i=0;i<10;i++)
      if(g_observedEma[i]!=INVALID_HANDLE) IndicatorRelease(g_observedEma[i]);
   for(int i=0;i<5;i++)
      if(g_observedRsi[i]!=INVALID_HANDLE) IndicatorRelease(g_observedRsi[i]);
  }

//+------------------------------------------------------------------+
void Process()
  {
   UpdateSpreadBaseline();
   ApplyRiskControls();
   ManageAllBaskets();

   const datetime currentBar=iTime(_Symbol,PERIOD_M1,0);
   if(currentBar>0 && currentBar!=g_lastM1Bar)
     {
      g_lastM1Bar=currentBar;
      MqlDateTime parts;
      TimeToStruct(currentBar,parts);
      if(parts.min%EntryEveryMinutes==0)
         ExecuteMinuteEntry();
     }
   DrawPanel();
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   Process();
  }

//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!MQLInfoInteger(MQL_TESTER))
      Process();
  }
//+------------------------------------------------------------------+