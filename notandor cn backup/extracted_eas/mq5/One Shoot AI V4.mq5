#property strict
#property version   "4.0"
#property copyright "Life IN Dreams world"
#property link      "https://t.me/LifeInDreamsWorld"
#property description "Enhanced clean-room multi-frame swing-breakout engine for MT5"
#property description "Broker-normalized execution, portfolio risk control, and ultra-fast trailing"

#include <Trade/Trade.mqh>

input group "OBSERVED PRESET INTERFACE"
input uint   TrailingCheckMs=1;
input bool   FlippingMoney=false;
input int    FlippingFrame=1;
input bool   DuplicateOrderFilter=false;
input bool   DashboardShow=true;
input int    GMTOffset=3;
input bool   AutoLot=true;
input int    RiskManagement=1;

input group "SYMBOL 1"
input bool   S1Enabled=true;
input ulong  S1MagicNumber=111101;
input int    S1MaxSpread=65;
input int    S1MaxSlippage=65;
input double S1InitialLot=0.01;
input string S1SymbolManual="";

input group "SYMBOL 2 (RESERVED; ATTACH A SECOND INSTANCE)"
input bool   S2Enabled=false;
input ulong  S2MagicNumber=111102;
input int    S2MaxSpread=65;
input int    S2MaxSlippage=65;
input double S2InitialLot=0.01;
input string S2SymbolManual="";

input group "SYMBOL 3 (RESERVED; ATTACH A THIRD INSTANCE)"
input bool   S3Enabled=false;
input ulong  S3MagicNumber=111103;
input int    S3MaxSpread=65;
input int    S3MaxSlippage=65;
input double S3InitialLot=0.01;
input string S3SymbolManual="";

input group "CLEAN-ROOM BREAKOUT MODEL"
input ENUM_TIMEFRAMES InpSignalTimeframe=PERIOD_M30;
input int             InpPivotWing=2;
input int             InpFreshPivotBars=96;
input int             InpMaximumPendingPerSide=8;
input double          InpEntryBufferPrice=0.01;
input double          InpInitialStopPrice=5.00;
input bool            InpFridayExpiration=true;
input int             InpExpirationHour=20;
input int             InpExpirationMinute=55;
input bool            InpUseTrendQualityFilter=false;
input int             InpTrendEMAPeriod=34;

input group "ENHANCED INTRABAR HUNT ENGINE"
input bool            InpEnableIntrabarEngine=false;
input ENUM_TIMEFRAMES InpIntrabarTimeframe=PERIOD_M1;
input int             InpIntrabarPivotWing=2;
input int             InpIntrabarRangeBars=16;
input double          InpIntrabarMinimumRangePrice=1.80;
input double          InpIntrabarRangeATRMultiplier=2.40;
input int             InpIntrabarCooldownMinutes=45;
input bool            InpIntrabarUseM30TrendBias=true;
input bool            InpIntrabarRequireFreshExtreme=true;
input int             InpIntrabarExtremeLookback=30;
input bool            InpReframeCrossedLevels=false;
input int             InpMaximumPositionsTotal=10;
input double          InpMaximumAggregateRiskPercent=120.0;

input group "ULTRA-FAST EXIT ENGINE"
input double InpTrailArmPrice=0.28;
input double InpTrailDistancePrice=0.05;
input double InpTrailStepPrice=0.01;
input bool   InpUseVirtualBrokerFallback=true;
input int    InpMaximumCloseAttempts=3;
input bool   InpHolidayFlatProtection=false;
input int    InpHolidayCloseHour=18;

input group "CROSS-BROKER NORMALIZATION"
input double InpStrategyPoint=0.01;
input double InpMaximumFillGapPrice=0.0;
input bool   InpRejectInsteadOfDistortEntry=true;
input bool   InpVerboseLog=false;

input group "MATCHING DASHBOARD"
input ENUM_BASE_CORNER InpDashboardCorner=CORNER_LEFT_UPPER;
input int              InpDashboardX=18;
input int              InpDashboardY=35;
input int              InpDashboardWidth=610;
input int              InpDashboardFontSize=11;

CTrade g_trade;
string g_symbol="";
datetime g_lastSignalBar=0;
datetime g_lastIntrabarBar=0;
datetime g_lastIntrabarBuy=0;
datetime g_lastIntrabarSell=0;
long g_seenPivots[];
int g_ema=INVALID_HANDLE;
int g_intrabarATR=INVALID_HANDLE;
string g_uiPrefix="OSV4_UI_";
ulong g_lastDashboardMs=0;
double g_peakEquity=0.0;

double SymPoint()
  {
   double value=SymbolInfoDouble(g_symbol,SYMBOL_POINT);
   return (value>0.0 ? value : 0.00001);
  }

double TickSize()
  {
   double value=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_SIZE);
   return (value>0.0 ? value : SymPoint());
  }

double PriceFloor(const double value)
  {
   double tick=TickSize();
   return NormalizeDouble(MathFloor((value+1e-10)/tick)*tick,(int)SymbolInfoInteger(g_symbol,SYMBOL_DIGITS));
  }

double PriceCeil(const double value)
  {
   double tick=TickSize();
   return NormalizeDouble(MathCeil((value-1e-10)/tick)*tick,(int)SymbolInfoInteger(g_symbol,SYMBOL_DIGITS));
  }

double NormalizeVolume(const double requested)
  {
   double minimum=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0) step=minimum;
   if(step<=0.0) return 0.0;
   double volume=MathFloor((MathMin(maximum,MathMax(minimum,requested))+1e-12)/step)*step;
   int digits=0;
   double probe=step;
   while(digits<8 && MathAbs(probe-MathRound(probe))>1e-9) { probe*=10.0; digits++; }
   return NormalizeDouble(volume,digits);
  }

double BrokerMinimumDistance()
  {
   long stops=SymbolInfoInteger(g_symbol,SYMBOL_TRADE_STOPS_LEVEL);
   long freeze=SymbolInfoInteger(g_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   return MathMax((double)stops,(double)freeze)*SymPoint()+TickSize();
  }

string ResolveSymbol(const string requested)
  {
   if(requested=="") return _Symbol;
   bool custom=false;
   if(SymbolExist(requested,custom) && SymbolSelect(requested,true)) return requested;
   if(StringFind(_Symbol,requested)==0) return _Symbol;
   int total=SymbolsTotal(false);
   for(int i=0;i<total;i++)
     {
      string candidate=SymbolName(i,false);
      if(StringFind(candidate,requested)==0 && SymbolSelect(candidate,true)) return candidate;
     }
   total=SymbolsTotal(true);
   for(int i=0;i<total;i++)
     {
      string candidate=SymbolName(i,true);
      if(StringFind(candidate,requested)==0) return candidate;
     }
   return "";
  }

bool SpreadAllowed()
  {
   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0) return false;
   double unit=(InpStrategyPoint>0.0 ? InpStrategyPoint : SymPoint());
   return (tick.ask-tick.bid)<=S1MaxSpread*unit+TickSize()*0.5;
  }

bool IsPivotHighTF(const ENUM_TIMEFRAMES timeframe,const int wing,const int shift)
  {
   double value=iHigh(g_symbol,timeframe,shift);
   if(value<=0.0) return false;
   for(int i=1;i<=wing;i++)
      if(iHigh(g_symbol,timeframe,shift-i)>=value || iHigh(g_symbol,timeframe,shift+i)>value) return false;
   return true;
  }

bool IsPivotLowTF(const ENUM_TIMEFRAMES timeframe,const int wing,const int shift)
  {
   double value=iLow(g_symbol,timeframe,shift);
   if(value<=0.0) return false;
   for(int i=1;i<=wing;i++)
      if(iLow(g_symbol,timeframe,shift-i)<=value || iLow(g_symbol,timeframe,shift+i)<value) return false;
   return true;
  }

bool IsPivotHigh(const int shift)
  {
   return IsPivotHighTF(InpSignalTimeframe,InpPivotWing,shift);
  }

bool IsPivotLow(const int shift)
  {
   return IsPivotLowTF(InpSignalTimeframe,InpPivotWing,shift);
  }

long PivotKey(const datetime pivotTime,const bool buy,const int engine)
  {
   return (long)pivotTime*4+(long)engine*2+(buy ? 1 : 0);
  }

bool PivotWasSeen(const long key)
  {
   for(int i=0;i<ArraySize(g_seenPivots);i++) if(g_seenPivots[i]==key) return true;
   return false;
  }

void MarkPivotSeen(const long key)
  {
   if(PivotWasSeen(key)) return;
   int size=ArraySize(g_seenPivots);
   ArrayResize(g_seenPivots,size+1);
   g_seenPivots[size]=key;
   if(ArraySize(g_seenPivots)>2000)
     {
      for(int i=500;i<ArraySize(g_seenPivots);i++) g_seenPivots[i-500]=g_seenPivots[i];
      ArrayResize(g_seenPivots,1500);
     }
  }

int PendingCount(const bool buy)
  {
   int count=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !OrderSelect(ticket)) continue;
      if(OrderGetString(ORDER_SYMBOL)!=g_symbol || (ulong)OrderGetInteger(ORDER_MAGIC)!=S1MagicNumber) continue;
      long type=OrderGetInteger(ORDER_TYPE);
      if((buy && type==ORDER_TYPE_BUY_STOP) || (!buy && type==ORDER_TYPE_SELL_STOP)) count++;
     }
   return count;
  }

bool PendingNear(const bool buy,const double price)
  {
   double tolerance=MathMax(TickSize(),InpEntryBufferPrice)*1.5;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !OrderSelect(ticket)) continue;
      if(OrderGetString(ORDER_SYMBOL)!=g_symbol || (ulong)OrderGetInteger(ORDER_MAGIC)!=S1MagicNumber) continue;
      long type=OrderGetInteger(ORDER_TYPE);
      if((buy && type!=ORDER_TYPE_BUY_STOP) || (!buy && type!=ORDER_TYPE_SELL_STOP)) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-price)<=tolerance) return true;
     }
   return false;
  }

int ManagedPositionCount()
  {
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)==g_symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==S1MagicNumber) count++;
     }
   return count;
  }

double LossAtStop(const ENUM_ORDER_TYPE type,const double volume,const double open,const double stop)
  {
   if(volume<=0.0 || open<=0.0 || stop<=0.0) return 0.0;
   double result=0.0;
   if(!OrderCalcProfit(type,g_symbol,volume,open,stop,result)) return 0.0;
   return MathMax(0.0,-result);
  }

double AggregateOpenRiskMoney()
  {
   double risk=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol || (ulong)PositionGetInteger(POSITION_MAGIC)!=S1MagicNumber) continue;
      bool buy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      double open=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      risk+=LossAtStop((buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL),PositionGetDouble(POSITION_VOLUME),open,sl);
     }
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !OrderSelect(ticket)) continue;
      if(OrderGetString(ORDER_SYMBOL)!=g_symbol || (ulong)OrderGetInteger(ORDER_MAGIC)!=S1MagicNumber) continue;
      long type=OrderGetInteger(ORDER_TYPE);
      if(type!=ORDER_TYPE_BUY_STOP && type!=ORDER_TYPE_SELL_STOP) continue;
      risk+=LossAtStop((type==ORDER_TYPE_BUY_STOP ? ORDER_TYPE_BUY : ORDER_TYPE_SELL),OrderGetDouble(ORDER_VOLUME_CURRENT),OrderGetDouble(ORDER_PRICE_OPEN),OrderGetDouble(ORDER_SL));
     }
   return risk;
  }

bool AggregateRiskAllows(const bool buy,const double volume,const double entry,const double stop)
  {
   if(InpMaximumAggregateRiskPercent<=0.0) return true;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double newRisk=LossAtStop((buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL),volume,entry,stop);
   return AggregateOpenRiskMoney()+newRisk<=equity*InpMaximumAggregateRiskPercent/100.0+0.01;
  }

datetime ExpirationTime()
  {
   if(!InpFridayExpiration) return 0;
   datetime now=TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now,dt);
   int days=(5-dt.day_of_week+7)%7;
   if(days==0 && (dt.hour>InpExpirationHour || (dt.hour==InpExpirationHour && dt.min>=InpExpirationMinute))) days=7;
   datetime target=now+days*86400;
   TimeToStruct(target,dt);
   dt.hour=InpExpirationHour; dt.min=InpExpirationMinute; dt.sec=0;
   return StructToTime(dt);
  }

double EntryVolume(const bool buy,const double entry,const double stop)
  {
   if(!AutoLot) return NormalizeVolume(S1InitialLot);
   double oneLotLoss=0.0;
   ENUM_ORDER_TYPE type=(buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(!OrderCalcProfit(type,g_symbol,1.0,entry,stop,oneLotLoss) || oneLotLoss>=0.0) return NormalizeVolume(S1InitialLot);
   // Observed preset behavior: RiskManagement=1 corresponds to about 10% of
   // current equity at the fixed five-price-unit emergency stop.
   double riskPercent=MathMax(0.1,(double)RiskManagement*10.0);
   double base=(FlippingMoney ? AccountInfoDouble(ACCOUNT_BALANCE) : AccountInfoDouble(ACCOUNT_EQUITY));
   double volume=(base*riskPercent/100.0)/MathAbs(oneLotLoss);
   return NormalizeVolume(MathMax(S1InitialLot,volume));
  }

bool TrendAllows(const bool buy,const int pivotShift)
  {
   if(!InpUseTrendQualityFilter) return true;
   double ema[1];
   if(g_ema==INVALID_HANDLE || CopyBuffer(g_ema,0,pivotShift,1,ema)!=1) return false;
   double close=iClose(g_symbol,InpSignalTimeframe,pivotShift);
   return (buy ? close>=ema[0] : close<=ema[0]);
  }

bool SubmitPivot(const bool buy,const datetime pivotTime,const double rawPrice,const int pivotShift,const int engine)
  {
   long key=PivotKey(pivotTime,buy,engine);
   if(PivotWasSeen(key)) return false;
   if(engine==0 && !TrendAllows(buy,pivotShift)) { MarkPivotSeen(key); return false; }
   if(InpMaximumPositionsTotal>0 && ManagedPositionCount()>=InpMaximumPositionsTotal) return false;
   if(PendingCount(buy)>=InpMaximumPendingPerSide) return false;
   double entry=(buy ? PriceCeil(rawPrice+InpEntryBufferPrice) : PriceFloor(rawPrice-InpEntryBufferPrice));
   if(DuplicateOrderFilter && PendingNear(buy,entry)) { MarkPivotSeen(key); return false; }

   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick)) return false;
   double minimum=BrokerMinimumDistance();
   bool legal=(buy ? entry>=tick.ask+minimum : entry<=tick.bid-minimum);
   if(!legal && InpReframeCrossedLevels)
     {
      entry=(buy ? PriceCeil(tick.ask+minimum) : PriceFloor(tick.bid-minimum));
      legal=(buy ? entry>=tick.ask+minimum-TickSize()*0.5 : entry<=tick.bid-minimum+TickSize()*0.5);
      if(DuplicateOrderFilter && PendingNear(buy,entry)) { MarkPivotSeen(key); return false; }
     }
   if(!legal)
     {
      // A crossed pivot is no longer the same breakout setup. Skipping it keeps
      // the economic signal consistent instead of moving it per broker.
      if(InpRejectInsteadOfDistortEntry) MarkPivotSeen(key);
      return false;
     }
   double stop=(buy ? PriceFloor(entry-InpInitialStopPrice) : PriceCeil(entry+InpInitialStopPrice));
   if(MathAbs(entry-stop)<minimum) stop=(buy ? PriceFloor(entry-minimum) : PriceCeil(entry+minimum));
   double volume=EntryVolume(buy,entry,stop);
   if(volume<=0.0) return false;
   if(!AggregateRiskAllows(buy,volume,entry,stop)) return false;
   datetime expiry=ExpirationTime();
   ENUM_ORDER_TYPE_TIME timeType=(expiry>0 ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC);
   string comment=(engine==0 ? "OSV4 M30 " : "OSV4 FAST ")+(buy ? "BUY" : "SELL");
   bool sent=(buy ? g_trade.BuyStop(volume,entry,g_symbol,stop,0.0,timeType,expiry,comment)
                  : g_trade.SellStop(volume,entry,g_symbol,stop,0.0,timeType,expiry,comment));
   if(sent)
     {
      MarkPivotSeen(key);
      if(InpVerboseLog) Print("One Shoot CR: armed ",comment," @ ",DoubleToString(entry,(int)SymbolInfoInteger(g_symbol,SYMBOL_DIGITS))," from ",TimeToString(pivotTime));
      return true;
     }
   uint retcode=g_trade.ResultRetcode();
   if(retcode==TRADE_RETCODE_INVALID_EXPIRATION)
     {
      sent=(buy ? g_trade.BuyStop(volume,entry,g_symbol,stop,0.0,ORDER_TIME_GTC,0,comment)
                : g_trade.SellStop(volume,entry,g_symbol,stop,0.0,ORDER_TIME_GTC,0,comment));
      if(sent) { MarkPivotSeen(key); return true; }
     }
   if(InpVerboseLog) Print("One Shoot CR: pending rejected ",g_trade.ResultRetcode()," ",g_trade.ResultRetcodeDescription());
   return false;
  }

void ScanFreshPivots()
  {
   if(!S1Enabled || !SpreadAllowed()) return;
   int bars=Bars(g_symbol,InpSignalTimeframe);
   if(bars<InpPivotWing*2+20) return;
   int start=InpPivotWing+1;
   int maximum=MathMin(InpFreshPivotBars,bars-InpPivotWing-1);
   bool needBuy=PendingCount(true)<InpMaximumPendingPerSide;
   bool needSell=PendingCount(false)<InpMaximumPendingPerSide;
   for(int shift=start;shift<=maximum && (needBuy || needSell);shift++)
     {
      datetime pivotTime=iTime(g_symbol,InpSignalTimeframe,shift);
      if(pivotTime<=0) continue;
      if(needBuy && IsPivotHigh(shift))
        {
         SubmitPivot(true,pivotTime,iHigh(g_symbol,InpSignalTimeframe,shift),shift,0);
         needBuy=PendingCount(true)<InpMaximumPendingPerSide;
        }
      if(needSell && IsPivotLow(shift))
        {
         SubmitPivot(false,pivotTime,iLow(g_symbol,InpSignalTimeframe,shift),shift,0);
         needSell=PendingCount(false)<InpMaximumPendingPerSide;
        }
     }
  }

double IntrabarATRValue(const int shift)
  {
   double value[1];
   if(g_intrabarATR==INVALID_HANDLE || CopyBuffer(g_intrabarATR,0,shift,1,value)!=1) return 0.0;
   return value[0];
  }

bool IntrabarRangeAllows(const bool buy,const int shift)
  {
   int from=MathMax(1,shift-InpIntrabarPivotWing);
   int count=MathMax(InpIntrabarRangeBars,InpIntrabarPivotWing*2+3);
   int highIndex=iHighest(g_symbol,InpIntrabarTimeframe,MODE_HIGH,count,from);
   int lowIndex=iLowest(g_symbol,InpIntrabarTimeframe,MODE_LOW,count,from);
   if(highIndex<0 || lowIndex<0) return false;
   double pivot=(buy ? iHigh(g_symbol,InpIntrabarTimeframe,shift) : iLow(g_symbol,InpIntrabarTimeframe,shift));
   double opposite=(buy ? iLow(g_symbol,InpIntrabarTimeframe,lowIndex) : iHigh(g_symbol,InpIntrabarTimeframe,highIndex));
   double range=MathAbs(pivot-opposite);
   double required=MathMax(InpIntrabarMinimumRangePrice,IntrabarATRValue(shift)*InpIntrabarRangeATRMultiplier);
   if(range+TickSize()*0.5<required) return false;
   if(InpIntrabarRequireFreshExtreme)
     {
      int olderFrom=shift+InpIntrabarPivotWing+1;
      int lookback=MathMax(5,InpIntrabarExtremeLookback);
      int extreme=(buy ? iHighest(g_symbol,InpIntrabarTimeframe,MODE_HIGH,lookback,olderFrom)
                       : iLowest(g_symbol,InpIntrabarTimeframe,MODE_LOW,lookback,olderFrom));
      if(extreme<0) return false;
      double older=(buy ? iHigh(g_symbol,InpIntrabarTimeframe,extreme) : iLow(g_symbol,InpIntrabarTimeframe,extreme));
      if((buy && pivot<older-TickSize()*0.5) || (!buy && pivot>older+TickSize()*0.5)) return false;
     }
   return true;
  }

bool IntrabarTrendAllows(const bool buy)
  {
   if(!InpIntrabarUseM30TrendBias) return true;
   double ema1[1],ema2[1];
   if(g_ema==INVALID_HANDLE || CopyBuffer(g_ema,0,1,1,ema1)!=1 || CopyBuffer(g_ema,0,2,1,ema2)!=1) return false;
   double close1=iClose(g_symbol,InpSignalTimeframe,1);
   if(close1<=0.0) return false;
   return (buy ? close1>=ema1[0] && ema1[0]>=ema2[0]
               : close1<=ema1[0] && ema1[0]<=ema2[0]);
  }

void ScanIntrabarPivot()
  {
   if(!InpEnableIntrabarEngine || !S1Enabled || !SpreadAllowed()) return;
   int wing=MathMax(1,InpIntrabarPivotWing);
   int shift=wing+1;
   if(Bars(g_symbol,InpIntrabarTimeframe)<InpIntrabarRangeBars+shift+10) return;
   datetime pivotTime=iTime(g_symbol,InpIntrabarTimeframe,shift);
   if(pivotTime<=0) return;
   datetime now=TimeCurrent();
   int cooldown=MathMax(0,InpIntrabarCooldownMinutes)*60;
   if(IsPivotHighTF(InpIntrabarTimeframe,wing,shift) && IntrabarRangeAllows(true,shift) && IntrabarTrendAllows(true) && (cooldown==0 || now-g_lastIntrabarBuy>=cooldown))
     {
      if(SubmitPivot(true,pivotTime,iHigh(g_symbol,InpIntrabarTimeframe,shift),shift,1)) g_lastIntrabarBuy=now;
     }
   if(IsPivotLowTF(InpIntrabarTimeframe,wing,shift) && IntrabarRangeAllows(false,shift) && IntrabarTrendAllows(false) && (cooldown==0 || now-g_lastIntrabarSell>=cooldown))
     {
      if(SubmitPivot(false,pivotTime,iLow(g_symbol,InpIntrabarTimeframe,shift),shift,1)) g_lastIntrabarSell=now;
     }
  }

string VirtualKey(const ulong ticket)
  {
   return "OSCR_"+(string)S1MagicNumber+"_"+(string)ticket;
  }

string GapRejectKey(const ulong identifier)
  {
   return "OSCR_GAP_"+(string)S1MagicNumber+"_"+(string)identifier;
  }

void MarkGapRejected(const ulong identifier)
  {
   GlobalVariableSet(GapRejectKey(identifier),1.0);
  }

bool GapWasRejected(const ulong identifier)
  {
   return GlobalVariableCheck(GapRejectKey(identifier));
  }

void ClearGapRejected(const ulong identifier)
  {
   string key=GapRejectKey(identifier);
   if(GlobalVariableCheck(key)) GlobalVariableDel(key);
  }

double VirtualStop(const ulong ticket)
  {
   string key=VirtualKey(ticket);
   return (GlobalVariableCheck(key) ? GlobalVariableGet(key) : 0.0);
  }

void SetVirtualStop(const ulong ticket,const double value)
  {
   string key=VirtualKey(ticket);
   if(value>0.0) GlobalVariableSet(key,value);
  }

void ClearVirtualStop(const ulong ticket)
  {
   string key=VirtualKey(ticket);
   if(GlobalVariableCheck(key)) GlobalVariableDel(key);
  }

bool ClosePositionFast(const ulong ticket)
  {
   for(int attempt=0;attempt<MathMax(1,InpMaximumCloseAttempts);attempt++)
     {
      if(!PositionSelectByTicket(ticket)) return true;
      if(g_trade.PositionClose(ticket,S1MaxSlippage)) return true;
     }
   if(InpVerboseLog) Print("One Shoot CR: close rejected ",ticket," ",g_trade.ResultRetcode()," ",g_trade.ResultRetcodeDescription());
   return false;
  }

ulong FindPositionTicketByIdentifier(const ulong identifier)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol || (ulong)PositionGetInteger(POSITION_MAGIC)!=S1MagicNumber) continue;
      if((ulong)PositionGetInteger(POSITION_IDENTIFIER)==identifier || ticket==identifier) return ticket;
     }
   return 0;
  }

void AnchorStopToActualFill(const ulong positionIdentifier,const bool buy,const double fillPrice)
  {
   ulong ticket=FindPositionTicketByIdentifier(positionIdentifier);
   if(ticket==0 || !PositionSelectByTicket(ticket)) return;
   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick)) return;
   double minimum=BrokerMinimumDistance();
   double desired=(buy ? PriceFloor(fillPrice-InpInitialStopPrice) : PriceCeil(fillPrice+InpInitialStopPrice));
   double current=(buy ? tick.bid : tick.ask);
   if((buy && current<=desired) || (!buy && current>=desired))
     {
      // The market has already crossed the intended loss boundary. Never leave
      // a gap-filled position carrying a much larger stale order-level stop.
      ClosePositionFast(ticket);
      return;
     }
   double legal=(buy ? PriceFloor(MathMin(desired,tick.bid-minimum))
                     : PriceCeil(MathMax(desired,tick.ask+minimum)));
   double tp=PositionGetDouble(POSITION_TP);
   if(!g_trade.PositionModify(ticket,legal,tp))
     {
      if(InpVerboseLog) Print("One Shoot CR: protection attach failed; closing ",ticket," ",g_trade.ResultRetcode()," ",g_trade.ResultRetcodeDescription());
      ClosePositionFast(ticket);
     }
  }

void ManagePositions()
  {
   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick)) return;
   double minimum=BrokerMinimumDistance();
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol || (ulong)PositionGetInteger(POSITION_MAGIC)!=S1MagicNumber) continue;
      long type=PositionGetInteger(POSITION_TYPE);
      ulong identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(GapWasRejected(identifier))
        {
         if(ClosePositionFast(ticket)) ClearGapRejected(identifier);
         continue;
        }
      bool buy=(type==POSITION_TYPE_BUY);
      double open=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double current=(buy ? tick.bid : tick.ask);
      bool staleInitial=(sl==0.0 || (buy && open-sl>InpInitialStopPrice+TickSize()*1.5) || (!buy && sl-open>InpInitialStopPrice+TickSize()*1.5));
      if(staleInitial)
        {
         double intended=(buy ? PriceFloor(open-InpInitialStopPrice) : PriceCeil(open+InpInitialStopPrice));
         if((buy && current<=intended) || (!buy && current>=intended))
           {
            ClosePositionFast(ticket);
            continue;
           }
         double corrected=(buy ? PriceFloor(MathMin(intended,tick.bid-minimum))
                               : PriceCeil(MathMax(intended,tick.ask+minimum)));
         if(sl>0.0 && MathAbs(sl-corrected)<=TickSize()*1.5)
           {
            sl=corrected;
           }
         else if(!g_trade.PositionModify(ticket,corrected,tp))
           {
            double currentSL=(PositionSelectByTicket(ticket) ? PositionGetDouble(POSITION_SL) : 0.0);
            if(currentSL<=0.0 || MathAbs(currentSL-corrected)>TickSize()*1.5)
              {
               if(InpVerboseLog) Print("One Shoot CR: stale protection repair failed; closing ",ticket);
               ClosePositionFast(ticket);
               continue;
              }
            sl=currentSL;
           }
         else sl=corrected;
        }
      double virtualSL=VirtualStop(ticket);
      if(virtualSL>0.0 && ((buy && current<=virtualSL) || (!buy && current>=virtualSL)))
        {
         if(ClosePositionFast(ticket)) ClearVirtualStop(ticket);
         continue;
        }
      double favorable=(buy ? current-open : open-current);
      if(favorable<InpTrailArmPrice) continue;
      double desired=(buy ? PriceFloor(current-InpTrailDistancePrice) : PriceCeil(current+InpTrailDistancePrice));
      bool virtualImproves=(buy ? desired>virtualSL+InpTrailStepPrice-TickSize()*0.5
                                : virtualSL==0.0 || desired<virtualSL-InpTrailStepPrice+TickSize()*0.5);
      if(InpUseVirtualBrokerFallback && virtualImproves) SetVirtualStop(ticket,desired);

      double physical=(buy ? PriceFloor(current-MathMax(InpTrailDistancePrice,minimum))
                           : PriceCeil(current+MathMax(InpTrailDistancePrice,minimum)));
      bool physicalImproves=(buy ? physical>open && (sl==0.0 || physical>sl+InpTrailStepPrice-TickSize()*0.5)
                                 : physical<open && (sl==0.0 || physical<sl-InpTrailStepPrice+TickSize()*0.5));
      if(physicalImproves && !g_trade.PositionModify(ticket,physical,tp) && InpVerboseLog)
         Print("One Shoot CR: physical trail rejected ",ticket," ",g_trade.ResultRetcode()," ",g_trade.ResultRetcodeDescription());
     }
  }

bool HolidayBlocked()
  {
   if(!InpHolidayFlatProtection) return false;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   if(dt.mon==12 && ((dt.day==24 && dt.hour>=InpHolidayCloseHour) || dt.day==25 || dt.day==26)) return true;
   if((dt.mon==12 && dt.day==31 && dt.hour>=InpHolidayCloseHour) || (dt.mon==1 && dt.day==1)) return true;
   return false;
  }

void EnforceHolidayFlat()
  {
   if(!HolidayBlocked()) return;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong order=OrderGetTicket(i);
      if(order==0 || !OrderSelect(order)) continue;
      if(OrderGetString(ORDER_SYMBOL)==g_symbol && (ulong)OrderGetInteger(ORDER_MAGIC)==S1MagicNumber) g_trade.OrderDelete(order);
     }
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)==g_symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==S1MagicNumber) ClosePositionFast(ticket);
     }
  }

int UIX(const int localX,const int objectWidth=0)
  {
   bool right=(InpDashboardCorner==CORNER_RIGHT_UPPER || InpDashboardCorner==CORNER_RIGHT_LOWER);
   return (right ? InpDashboardX+InpDashboardWidth-localX-objectWidth : InpDashboardX+localX);
  }

int UIY(const int localY,const int objectHeight=0)
  {
   bool lower=(InpDashboardCorner==CORNER_LEFT_LOWER || InpDashboardCorner==CORNER_RIGHT_LOWER);
   const int panelHeight=730;
   return (lower ? InpDashboardY+panelHeight-localY-objectHeight : InpDashboardY+localY);
  }

ENUM_ANCHOR_POINT UIAnchor(const bool rightAligned=false)
  {
   bool lower=(InpDashboardCorner==CORNER_LEFT_LOWER || InpDashboardCorner==CORNER_RIGHT_LOWER);
   if(lower) return (rightAligned ? ANCHOR_RIGHT_LOWER : ANCHOR_LEFT_LOWER);
   return (rightAligned ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER);
  }

void UISetRect(const string id,const int x,const int y,const int width,const int height,const color background,const color border)
  {
   string name=g_uiPrefix+id;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpDashboardCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,UIX(x,width));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,UIY(y,height));
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void UISetText(const string id,const string value,const int x,const int y,const color clr,const int size,const bool rightAligned=false)
  {
   string name=g_uiPrefix+id;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   bool cornerRight=(InpDashboardCorner==CORNER_RIGHT_UPPER || InpDashboardCorner==CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpDashboardCorner);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,UIAnchor(rightAligned));
   int distance=0;
   if(!cornerRight) distance=(rightAligned ? InpDashboardX+InpDashboardWidth-x : InpDashboardX+x);
   else distance=(rightAligned ? InpDashboardX+x : InpDashboardX+InpDashboardWidth-x);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,distance);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,UIY(y,0));
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,value);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void ClearDashboard()
  {
   ObjectsDeleteAll(0,g_uiPrefix);
   Comment("");
  }

double ManagedFloatingProfit()
  {
   double total=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)==g_symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==S1MagicNumber)
         total+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
     }
   return total;
  }

struct DashboardStats
  {
   double total;
   double today;
   double yesterday;
   double lastWeek;
   double thisMonth;
   double grossProfit;
   double grossLoss;
   int wins;
   int losses;
  };

void CollectDashboardStats(DashboardStats &stats)
  {
   ZeroMemory(stats);
   datetime now=TimeCurrent();
   MqlDateTime parts;
   TimeToStruct(now,parts);
   parts.hour=0; parts.min=0; parts.sec=0;
   datetime dayStart=StructToTime(parts);
   datetime yesterdayStart=dayStart-86400;
   datetime lastWeekStart=dayStart-7*86400;
   parts.day=1;
   datetime monthStart=StructToTime(parts);
   if(!HistorySelect(0,now)) return;
   for(int i=0;i<HistoryDealsTotal();i++)
     {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0) continue;
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=g_symbol || (ulong)HistoryDealGetInteger(ticket,DEAL_MAGIC)!=S1MagicNumber) continue;
      double net=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_COMMISSION)+HistoryDealGetDouble(ticket,DEAL_SWAP);
      datetime when=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
      stats.total+=net;
      if(when>=dayStart) stats.today+=net;
      if(when>=yesterdayStart && when<dayStart) stats.yesterday+=net;
      if(when>=lastWeekStart && when<dayStart) stats.lastWeek+=net;
      if(when>=monthStart) stats.thisMonth+=net;
      long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY && entry!=DEAL_ENTRY_INOUT) continue;
      if(net>=0.0) { stats.wins++; stats.grossProfit+=net; }
      else { stats.losses++; stats.grossLoss+=net; }
     }
  }

string MoneyText(const double value)
  {
   return (value>=0.0 ? "+" : "")+DoubleToString(value,2)+" "+AccountInfoString(ACCOUNT_CURRENCY);
  }

void UpdateDashboard()
  {
   if(!DashboardShow) return;
   if((bool)MQLInfoInteger(MQL_TESTER) && !(bool)MQLInfoInteger(MQL_VISUAL_MODE)) return;
   ulong nowMs=GetTickCount64();
   if(nowMs-g_lastDashboardMs<500) return;
   g_lastDashboardMs=nowMs;

   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick)) return;
   DashboardStats stats;
   CollectDashboardStats(stats);
   int pendingBuy=PendingCount(true);
   int pendingSell=PendingCount(false);
   int positions=ManagedPositionCount();
   double floating=ManagedFloatingProfit();
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_peakEquity=MathMax(g_peakEquity,equity);
   double drawdown=(g_peakEquity>0.0 ? 100.0*MathMax(0.0,g_peakEquity-equity)/g_peakEquity : 0.0);
   double risk=(equity>0.0 ? 100.0*AggregateOpenRiskMoney()/equity : 0.0);
   double spread=tick.ask-tick.bid;
   int totalClosed=stats.wins+stats.losses;
   double winRate=(totalClosed>0 ? 100.0*stats.wins/totalClosed : 0.0);
   double profitFactor=(stats.grossLoss<0.0 ? stats.grossProfit/MathAbs(stats.grossLoss) : 0.0);
   string state=(HolidayBlocked() ? "PAUSED" : positions>0 ? "ACTIVE" : "WAITING");
   string tf=EnumToString(InpSignalTimeframe);
   StringReplace(tf,"PERIOD_","");
   long ping=(long)TerminalInfoInteger(TERMINAL_PING_LAST)/1000;

   color bg=C'5,4,15';
   color card=C'17,12,30';
   color violet=C'92,119,255';
   color magenta=C'224,52,226';
   color cyan=C'50,207,255';
   color green=C'74,236,135';
   color yellow=C'255,211,69';
   color text=C'244,240,250';
   color muted=C'123,119,151';
   color red=C'255,84,112';
   color profit=(stats.total>=0.0 ? green : red);
   color floatColor=(floating>=0.0 ? C'34,229,166' : C'255,84,112');

   UISetRect("BG",0,0,InpDashboardWidth,730,bg,magenta);
   UISetRect("FRAME",5,5,InpDashboardWidth-10,720,bg,magenta);
   UISetRect("LOGO",18,15,42,42,C'74,16,92',magenta);
   UISetText("LOGOT","AI",30,25,text,InpDashboardFontSize+2,false);
   UISetText("TITLE","@LifeInDreamsWorld",72,17,magenta,InpDashboardFontSize+10,false);
   UISetText("SYMBOL",g_symbol,72,49,cyan,InpDashboardFontSize+2,false);
   UISetRect("ENABLED",300,14,165,30,C'11,67,41',green);
   UISetText("ENABLEDT","ENABLED",337,18,green,InpDashboardFontSize+2,false);
   UISetText("BUILD","BUILD v1.10",500,19,muted,InpDashboardFontSize+1,false);
   UISetText("ACCOUNTMODE","Raw / ECN Account Only",370,49,muted,InpDashboardFontSize+1,false);
   UISetRect("HEADLINE",10,70,InpDashboardWidth-20,1,magenta,magenta);

   UISetText("ACCOUNTHEAD","ACCOUNT OVERVIEW",18,83,cyan,InpDashboardFontSize+2,false);
   UISetText("PERFHEAD","PERFORMANCE STATS",315,83,cyan,InpDashboardFontSize+2,false);
   string deposit=MoneyText(AccountInfoDouble(ACCOUNT_BALANCE)-stats.total);
   UISetText("DEPOSITL","Deposit",18,110,violet,InpDashboardFontSize+1,false);
   UISetText("DEPOSITV",deposit,180,110,text,InpDashboardFontSize+1,false);
   UISetText("BALANCEL","Balance",18,135,violet,InpDashboardFontSize+1,false);
   UISetText("BALANCEV",MoneyText(AccountInfoDouble(ACCOUNT_BALANCE)),180,135,text,InpDashboardFontSize+1,false);
   UISetText("EQUITYL","Equity",18,160,violet,InpDashboardFontSize+1,false);
   UISetText("EQUITYV",MoneyText(equity),180,160,text,InpDashboardFontSize+1,false);
   UISetText("FLOATL","Floating P/L",18,185,violet,InpDashboardFontSize+1,false);
   UISetText("FLOATV",MoneyText(floating),180,185,floatColor,InpDashboardFontSize+1,false);
   UISetText("FREEL","Free Margin",18,210,violet,InpDashboardFontSize+1,false);
   UISetText("FREEV",MoneyText(AccountInfoDouble(ACCOUNT_MARGIN_FREE)),180,210,text,InpDashboardFontSize+1,false);

   UISetText("WINL","Win Rate",315,110,violet,InpDashboardFontSize+1,false);
   UISetText("WINV",DoubleToString(winRate,2)+"%",485,110,text,InpDashboardFontSize+1,false);
   UISetText("PFL","Profit Factor",315,135,violet,InpDashboardFontSize+1,false);
   UISetText("PFV",DoubleToString(profitFactor,2),485,135,(profitFactor>=1.0 ? green : red),InpDashboardFontSize+1,false);
   UISetText("WINTRADESL","Profit Trades",315,160,violet,InpDashboardFontSize+1,false);
   UISetText("WINTRADESV",(string)stats.wins,485,160,text,InpDashboardFontSize+1,false);
   UISetText("LOSSTRADESL","Loss Trades",315,185,violet,InpDashboardFontSize+1,false);
   UISetText("LOSSTRADESV",(string)stats.losses,485,185,text,InpDashboardFontSize+1,false);
   UISetText("DDL","Drawdown",315,210,violet,InpDashboardFontSize+1,false);
   UISetText("DDV",DoubleToString(drawdown,2)+"%",485,210,(drawdown>25.0 ? red : text),InpDashboardFontSize+1,false);

   UISetRect("PERIODBG",10,237,InpDashboardWidth-20,52,card,card);
   UISetText("TODAYL","TODAY",20,244,muted,InpDashboardFontSize,false);
   UISetText("YESTL","YESTERDAY",165,244,muted,InpDashboardFontSize,false);
   UISetText("WEEKL","LAST WEEK",310,244,muted,InpDashboardFontSize,false);
   UISetText("MONTHL","THIS MONTH",455,244,muted,InpDashboardFontSize,false);
   UISetText("TODAYV",MoneyText(stats.today),20,265,text,InpDashboardFontSize+1,false);
   UISetText("YESTV",MoneyText(stats.yesterday),165,265,text,InpDashboardFontSize+1,false);
   UISetText("WEEKV",MoneyText(stats.lastWeek),310,265,text,InpDashboardFontSize+1,false);
   UISetText("MONTHV",MoneyText(stats.thisMonth),455,265,text,InpDashboardFontSize+1,false);

   UISetRect("TOTALBG",10,301,InpDashboardWidth-20,44,C'8,44,29',green);
   UISetText("TOTALL","TOTAL PROFIT",20,311,yellow,InpDashboardFontSize+2,false);
   UISetText("TOTALV",MoneyText(stats.total),180,308,profit,InpDashboardFontSize+8,false);
   UISetText("ALLTIME","ALL TIME",515,313,muted,InpDashboardFontSize,false);
   UISetRect("MIDLINE",10,356,InpDashboardWidth-20,1,magenta,magenta);

   UISetText("SYSTEMHEAD","SYSTEM STATUS",18,370,cyan,InpDashboardFontSize+2,false);
   UISetText("MODEHEAD",((bool)MQLInfoInteger(MQL_TESTER) ? "TESTER" : "LIVE"),510,370,cyan,InpDashboardFontSize+2,false);
   UISetText("RISKROW","▪ Risk Engine",18,399,green,InpDashboardFontSize+1,false);
   UISetText("RISKVAL","ACTIVE  "+DoubleToString(risk,1)+"%",185,399,text,InpDashboardFontSize+1,false);
   UISetText("RISKMODE",(AutoLot ? "AUTO" : "FIXED"),520,399,muted,InpDashboardFontSize+1,false);
   UISetText("TRADEROW","▪ Trade Engine",18,426,green,InpDashboardFontSize+1,false);
   UISetText("TRADEVAL",(HolidayBlocked() ? "PAUSED" : "RUNNING"),185,426,text,InpDashboardFontSize+1,false);
   UISetText("TRADEMODE",(InpEnableIntrabarEngine ? "M30 + FAST" : "M30 CORE"),480,426,muted,InpDashboardFontSize+1,false);
   UISetText("MULTIROW","▪ Multi-Market",18,453,green,InpDashboardFontSize+1,false);
   UISetText("MULTIVAL","1 SYMBOL",185,453,text,InpDashboardFontSize+1,false);
   UISetText("ORDERSMODE",(string)(pendingBuy+pendingSell)+" pend / "+(string)positions+" open",445,453,muted,InpDashboardFontSize+1,false);
   UISetText("CLOSEROW","▪ Market Close",18,480,green,InpDashboardFontSize+1,false);
   UISetText("CLOSEVAL","ACTIVE",185,480,text,InpDashboardFontSize+1,false);
   UISetText("CLOSETIME","closes Fri "+IntegerToString(InpExpirationHour,2,'0')+":"+IntegerToString(InpExpirationMinute,2,'0'),450,480,muted,InpDashboardFontSize+1,false);
   UISetText("CONNROW","▪ Connection",18,507,muted,InpDashboardFontSize+1,false);
   UISetText("CONNVAL",AccountInfoString(ACCOUNT_SERVER),185,507,text,InpDashboardFontSize+1,false);
   UISetText("PING",(ping>0 ? (string)ping+" ms" : "-- ms"),530,507,muted,InpDashboardFontSize+1,false);
   UISetRect("MARKETLINE",10,540,InpDashboardWidth-20,1,magenta,magenta);

   UISetText("MARKETHEAD","MARKET STATUS",18,553,cyan,InpDashboardFontSize+2,false);
   UISetText("MHSYM","SYMBOL",18,580,muted,InpDashboardFontSize-1,false);
   UISetText("MHTF","TF",140,580,muted,InpDashboardFontSize-1,false);
   UISetText("MHSPREAD","SPREAD",200,580,muted,InpDashboardFontSize-1,false);
   UISetText("MHPEND","PEND",295,580,muted,InpDashboardFontSize-1,false);
   UISetText("MHPOS","POS",370,580,muted,InpDashboardFontSize-1,false);
   UISetText("MHSTATE","STATE",440,580,muted,InpDashboardFontSize-1,false);
   UISetText("MVSYM",g_symbol,18,603,text,InpDashboardFontSize,false);
   UISetText("MVTF",tf,140,603,text,InpDashboardFontSize,false);
   UISetText("MVSPREAD",DoubleToString(spread,2),200,603,text,InpDashboardFontSize,false);
   UISetText("MVPEND",(string)(pendingBuy+pendingSell),295,603,text,InpDashboardFontSize,false);
   UISetText("MVPOS",(string)positions,370,603,text,InpDashboardFontSize,false);
   UISetText("MVSTATE",state,440,603,(HolidayBlocked() ? red : green),InpDashboardFontSize,false);
   UISetRect("FOOTLINE",10,630,InpDashboardWidth-20,1,magenta,magenta);

   UISetRect("FOOTCARD",10,642,InpDashboardWidth-20,72,C'31,12,42',yellow);
   UISetText("FOOTTITLE","ENHANCED v1.10",20,651,yellow,InpDashboardFontSize+6,false);
   UISetText("FOOT1","BROKER NORMALIZED",20,681,text,InpDashboardFontSize+1,false);
   UISetText("FOOT2","REAL-TICK VALIDATED",315,681,cyan,InpDashboardFontSize+1,false);
   ChartRedraw();
  }

int OnInit()
  {
   if(!S1Enabled) return INIT_PARAMETERS_INCORRECT;
   g_symbol=ResolveSymbol(S1SymbolManual);
   if(g_symbol=="" || !SymbolSelect(g_symbol,true)) return INIT_FAILED;
   g_trade.SetExpertMagicNumber(S1MagicNumber);
   g_trade.SetDeviationInPoints(S1MaxSlippage);
   g_trade.SetTypeFillingBySymbol(g_symbol);
   g_trade.SetAsyncMode(false);
   // Gap flags only bridge the deal event to the next management cycle. They
   // are not a restart-persistent stop and tester position identifiers repeat.
   GlobalVariablesDeleteAll("OSCR_GAP_"+(string)S1MagicNumber+"_");
   // The Strategy Tester reuses ticket numbers between independent passes.
   // Live terminals keep this namespace so a virtual stop survives restart.
   if((bool)MQLInfoInteger(MQL_TESTER)) GlobalVariablesDeleteAll("OSCR_"+(string)S1MagicNumber+"_");
   g_ema=iMA(g_symbol,InpSignalTimeframe,InpTrendEMAPeriod,0,MODE_EMA,PRICE_CLOSE);
   if(g_ema==INVALID_HANDLE) return INIT_FAILED;
   g_intrabarATR=iATR(g_symbol,InpIntrabarTimeframe,14);
   if(InpEnableIntrabarEngine && g_intrabarATR==INVALID_HANDLE) return INIT_FAILED;
   g_lastSignalBar=iTime(g_symbol,InpSignalTimeframe,0);
   g_lastIntrabarBar=iTime(g_symbol,InpIntrabarTimeframe,0);
   g_peakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   EventSetMillisecondTimer((int)MathMax(16,(int)TrailingCheckMs));
   UpdateDashboard();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(g_ema!=INVALID_HANDLE) IndicatorRelease(g_ema);
   if(g_intrabarATR!=INVALID_HANDLE) IndicatorRelease(g_intrabarATR);
   ClearDashboard();
  }

void EngineCycle()
  {
   if(HolidayBlocked())
     {
      EnforceHolidayFlat();
      UpdateDashboard();
      return;
     }
   ManagePositions();
   datetime bar=iTime(g_symbol,InpSignalTimeframe,0);
   if(bar>0 && bar!=g_lastSignalBar)
     {
      g_lastSignalBar=bar;
      ScanFreshPivots();
     }
   datetime intrabar=iTime(g_symbol,InpIntrabarTimeframe,0);
   if(InpEnableIntrabarEngine && intrabar>0 && intrabar!=g_lastIntrabarBar)
     {
      g_lastIntrabarBar=intrabar;
      ScanIntrabarPivot();
     }
   UpdateDashboard();
  }

void OnTick()
  {
   EngineCycle();
  }

void OnTimer()
  {
   EngineCycle();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD || trans.deal==0 || !HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)!=g_symbol || (ulong)HistoryDealGetInteger(trans.deal,DEAL_MAGIC)!=S1MagicNumber) return;
   long entry=HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   if(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT)
     {
      long dealType=HistoryDealGetInteger(trans.deal,DEAL_TYPE);
      if(dealType==DEAL_TYPE_BUY || dealType==DEAL_TYPE_SELL)
        {
         ulong identifier=(ulong)HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);
         double fill=HistoryDealGetDouble(trans.deal,DEAL_PRICE);
         ulong order=(ulong)HistoryDealGetInteger(trans.deal,DEAL_ORDER);
         if(InpMaximumFillGapPrice>0.0 && HistoryOrderSelect(order))
           {
            double requested=HistoryOrderGetDouble(order,ORDER_PRICE_OPEN);
            if(requested>0.0 && MathAbs(fill-requested)>InpMaximumFillGapPrice+TickSize()*0.5) MarkGapRejected(identifier);
           }
         // The pending order already carries a physical emergency SL. The
         // normal management cycle reanchors it once the MT5 position cache is
         // refreshed; modifying here would create a re-entrant duplicate call.
        }
     }
   if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
     {
      ulong identifier=(ulong)HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);
      ClearVirtualStop(identifier);
      ClearGapRejected(identifier);
     }
  }

double OnTester()
  {
   double profit=TesterStatistics(STAT_PROFIT);
   double factor=TesterStatistics(STAT_PROFIT_FACTOR);
   double drawdown=TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double trades=TesterStatistics(STAT_TRADES);
   if(profit<=0.0 || factor<=1.0 || trades<200.0) return -1.0;
   double frequency=MathMin(1.0,trades/600.0);
   double riskPenalty=MathPow(1.0+drawdown/20.0,2.0);
   return (profit/100.0)*factor*frequency/riskPenalty;
  }
