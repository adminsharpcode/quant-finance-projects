//+------------------------------------------------------------------+
//|                                      3X Combo AI v7.mq5         |
//|                        Clean-room behavioral implementation      |
//+------------------------------------------------------------------+
#property copyright "Free Forex Tools"
#property link      "https://t.me/free_fx_pro"
#property version   "7.00"
#property strict
#property description "3X Combo AI v7 - M15/M30/H1 fresh-pivot breakout and peak-trailing EA"

#include <Trade/Trade.mqh>

input int    InpTrailingCheckMs=1;              // Trailing check (ms):
input bool   InpEnableHybridAntiSlippage=true;   // Hybrid Anti-Slippage:
input bool   InpSmartEarlyExitGuard=true;        // Smart Early Exit Guard:
input bool   InpContinuousPeakTrail=true;        // Continuous Peak Trail:
input bool   InpSLFailBackupGuard=true;          // SL Fail Backup Guard:
input bool   InpAllPendingDeleteFriday=true;     // Delete pending orders Friday:

input bool   InpDashboardShow=true;              // Dashboard:
input int    InpLandscapePanelWidth=380;         // Landscape panel width:
input int    InpPortraitPanelWidth=480;          // Portrait panel width:

input int    InpGMTOffset=3;                     // GMT offset:
input bool   InpAutoRiskManagement=true;         // Auto Risk Management:
input int    InpRiskManagement=1;                // Risk Management mode:

input bool   InpFlippingMoney=false;             // Flipping Money:
input int    InpFlippingFrame=0;                 // Flipping frame (0 M15, 1 M30, 2 H1):

input bool   InpSymbol1Enabled=true;              // XAUUSD enabled:
input double InpSymbol1MaxSpreadPips=15;          // XAUUSD max spread:
input double InpSymbol1MaxSlippagePips=15;        // XAUUSD max slippage:
input double InpSymbol1Lot=0.01;                  // XAUUSD lot:
input string InpSymbol1ManualSymbol="";           // XAUUSD manual symbol:

input bool   InpSymbol2Enabled=false;             // BTCUSD enabled:
input double InpSymbol2MaxSpreadPips=1300;        // BTCUSD max spread:
input double InpSymbol2MaxSlippagePips=1300;      // BTCUSD max slippage:
input double InpSymbol2Lot=0.01;                  // BTCUSD lot:
input string InpSymbol2ManualSymbol="";           // BTCUSD manual symbol:

input bool   InpSymbol3Enabled=false;             // NASDAQ enabled:
input double InpSymbol3MaxSpreadPips=90;          // NASDAQ max spread:
input double InpSymbol3MaxSlippagePips=90;        // NASDAQ max slippage:
input double InpSymbol3Lot=0.10;                  // NASDAQ lot:
input string InpSymbol3ManualSymbol="";           // NASDAQ manual symbol:

// The observed licensed EA keeps these values internal.  They are reproduced
// here from execution behavior, not from proprietary source code.
#define COMBOAI7_TIMEFRAME_COUNT 3
#define COMBOAI7_MAX_SYMBOLS     3
#define COMBOAI7_MAX_TRACKED     256
const long   COMBOAI7_MAGIC_BASE       =73107000;
const int    COMBOAI7_MAX_AGE_HOURS    =250;
const int    COMBOAI7_PIVOT_WING       =1;
const int    COMBOAI7_RETRY_SECONDS    =5;
const int    COMBOAI7_DASHBOARD_MS     =500;
const string COMBOAI7_PANEL_PREFIX     ="COMBOAI7_UI_";

CTrade trade;

string          g_symbol[COMBOAI7_MAX_SYMBOLS];
bool            g_enabled[COMBOAI7_MAX_SYMBOLS];
double          g_lot[COMBOAI7_MAX_SYMBOLS];
double          g_max_spread[COMBOAI7_MAX_SYMBOLS];
double          g_max_slippage[COMBOAI7_MAX_SYMBOLS];
double          g_scale[COMBOAI7_MAX_SYMBOLS];
datetime        g_last_bar[COMBOAI7_MAX_SYMBOLS][COMBOAI7_TIMEFRAME_COUNT];
datetime        g_next_retry[COMBOAI7_MAX_SYMBOLS];
datetime        g_last_spread_notice[COMBOAI7_MAX_SYMBOLS];
datetime        g_last_scan_notice[COMBOAI7_MAX_SYMBOLS][COMBOAI7_TIMEFRAME_COUNT];
bool            g_friday_cleaned=false;
ulong           g_last_dashboard_ms=0;

ulong           g_track_ticket[COMBOAI7_MAX_TRACKED];
double          g_track_peak[COMBOAI7_MAX_TRACKED];
double          g_track_virtual_sl[COMBOAI7_MAX_TRACKED];

ENUM_TIMEFRAMES ComboTimeframe(const int slot)
  {
   if(slot==0) return PERIOD_M15;
   if(slot==1) return PERIOD_M30;
   return PERIOD_H1;
  }

string TfName(const ENUM_TIMEFRAMES tf)
  {
   if(tf==PERIOD_M15) return "M15";
   if(tf==PERIOD_M30) return "M30";
   return "H1";
  }

int VolumeDigits(const double step)
  {
   if(step>=1.0) return 0;
   if(step>=0.1) return 1;
   if(step>=0.01) return 2;
   if(step>=0.001) return 3;
   return 4;
  }

double NormalizeVolumeForSymbol(const string symbol,const double requested)
  {
   double minimum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0) step=0.01;
   double volume=MathFloor((requested+step*0.0001)/step)*step;
   volume=MathMax(minimum,MathMin(maximum,volume));
   return NormalizeDouble(volume,VolumeDigits(step));
  }

double NormalizePriceForSymbol(const string symbol,const double price)
  {
   double tick=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=SymbolInfoDouble(symbol,SYMBOL_POINT);
   int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   if(tick<=0.0) return NormalizeDouble(price,digits);
   return NormalizeDouble(MathRound(price/tick)*tick,digits);
  }

bool SelectIfUsable(const string symbol)
  {
   if(symbol=="") return false;
   if(!SymbolSelect(symbol,true)) return false;
   if(SymbolInfoDouble(symbol,SYMBOL_POINT)<=0.0) return false;
   long trade_mode=SYMBOL_TRADE_MODE_DISABLED;
   if(SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE,trade_mode) &&
      trade_mode==SYMBOL_TRADE_MODE_DISABLED) return false;
   return true;
  }

bool SymbolMatchesSlot(const string symbol,const int slot)
  {
   string upper=symbol;
   StringToUpper(upper);
   if(slot==0) return StringFind(upper,"XAUUSD")>=0 || StringFind(upper,"GOLD")>=0;
   if(slot==1) return StringFind(upper,"BTCUSD")>=0;
   return StringFind(upper,"USTEC")>=0 || StringFind(upper,"NAS100")>=0 ||
          StringFind(upper,"US100")>=0 || StringFind(upper,"NASDAQ")>=0;
  }

string FindBrokerSymbol(const int slot,const string manual)
  {
   if(manual!="" && SelectIfUsable(manual)) return manual;

   // Prefer the symbol of the chart/test currently running the EA.  Brokers
   // often expose several XAUUSD variants (for example .crp, -VIPc or raw),
   // and selecting the first catalog match can trade the wrong instrument.
   if(SymbolMatchesSlot(_Symbol,slot) && SelectIfUsable(_Symbol)) return _Symbol;

   // Prefer symbols already visible in Market Watch.  This normally identifies
   // the account-specific tradable suffix before catalog-only variants.
   int total=SymbolsTotal(true);
   string visible_best="";
   int visible_score=-100000;
   for(int i=0;i<total;i++)
     {
      string name=SymbolName(i,true);
      if(!SymbolMatchesSlot(name,slot) || !SelectIfUsable(name)) continue;
      string upper=name;
      StringToUpper(upper);
      int score=0;
      if(StringFind(upper,"VIP")>=0) score+=400;
      if(slot==0 && upper=="XAUUSD") score+=300;
      if(slot==1 && upper=="BTCUSD") score+=300;
      if(score>visible_score) { visible_best=name; visible_score=score; }
     }
   if(visible_best!="") return visible_best;

   string candidates[8];
   int count=0;
   if(slot==0)
     {
      candidates[count++]="XAUUSD";
      candidates[count++]="GOLD";
     }
   else if(slot==1)
     {
      candidates[count++]="BTCUSD";
      candidates[count++]="BTCUSDm";
     }
   else
     {
      candidates[count++]="USTEC";
      candidates[count++]="NAS100";
      candidates[count++]="US100";
      candidates[count++]="NASDAQ";
     }

   for(int i=0;i<count;i++) if(SelectIfUsable(candidates[i])) return candidates[i];

   // Fall back to the complete catalog, but never return trade-disabled pairs.
   total=SymbolsTotal(false);
   string best="";
   int best_score=-100000;
   for(int i=0;i<total;i++)
     {
      string name=SymbolName(i,false);
      if(!SymbolMatchesSlot(name,slot) || !SelectIfUsable(name)) continue;
      string upper=name;
      StringToUpper(upper);
      int score=0;
      if((bool)SymbolInfoInteger(name,SYMBOL_VISIBLE)) score+=500;
      if(StringFind(upper,"VIP")>=0) score+=400;
      if(slot==0 && upper=="XAUUSD") score+=300;
      if(slot==1 && upper=="BTCUSD") score+=300;
      if(score>best_score) { best=name; best_score=score; }
     }
   if(best!="") return best;
   return "";
  }

int SymbolSlot(const string symbol)
  {
   for(int i=0;i<COMBOAI7_MAX_SYMBOLS;i++) if(g_enabled[i] && g_symbol[i]==symbol) return i;
   return -1;
  }

long SymbolMagic(const int slot)
  {
   return COMBOAI7_MAGIC_BASE+slot+1;
  }

bool IsOurMagic(const long magic)
  {
   return magic>COMBOAI7_MAGIC_BASE && magic<=COMBOAI7_MAGIC_BASE+COMBOAI7_MAX_SYMBOLS;
  }

double SymbolPointValue(const int slot)
  {
   return SymbolInfoDouble(g_symbol[slot],SYMBOL_POINT);
  }

double InitialSLDistance(const int slot)    { return 4.50*g_scale[slot]; }
double InitialTPDistance(const int slot)    { return 30.00*g_scale[slot]; }
double TrailActivation(const int slot)      { return 0.25*g_scale[slot]; }
double TrailDistance(const int slot)        { return 0.15*g_scale[slot]; }
double TrailStep(const int slot)            { return 0.15*g_scale[slot]; }
double EarlyExitBuffer(const int slot)      { return 0.05*g_scale[slot]; }

double RiskLot(const int slot)
  {
   double requested=g_lot[slot];
   if(!InpAutoRiskManagement || InpRiskManagement<=1)
      return NormalizeVolumeForSymbol(g_symbol[slot],requested);

   double risk_percent=InpRiskManagement==2 ? 0.50 : 1.00;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double money_risk=equity*risk_percent/100.0;
   double tick_value=SymbolInfoDouble(g_symbol[slot],SYMBOL_TRADE_TICK_VALUE_LOSS);
   double tick_size=SymbolInfoDouble(g_symbol[slot],SYMBOL_TRADE_TICK_SIZE);
   if(tick_value<=0.0 || tick_size<=0.0) return NormalizeVolumeForSymbol(g_symbol[slot],requested);
   double loss_per_lot=InitialSLDistance(slot)/tick_size*tick_value;
   if(loss_per_lot<=0.0) return NormalizeVolumeForSymbol(g_symbol[slot],requested);
   return NormalizeVolumeForSymbol(g_symbol[slot],money_risk/loss_per_lot);
  }

datetime GMTNow()
  {
   datetime server=TimeTradeServer();
   if(server<=0) server=TimeCurrent();
   return server-InpGMTOffset*3600;
  }

bool EntrySessionOpen()
  {
   MqlDateTime tm;
   TimeToStruct(GMTNow(),tm);
   if(tm.day_of_week==6 || tm.day_of_week==0) return false;
   if(tm.day_of_week==5 && tm.hour>=20) return false;
   if(tm.day_of_week==1 && tm.hour<1) return false;
   return true;
  }

string PivotComment(const ENUM_TIMEFRAMES tf,const datetime pivot_time)
  {
   return "3XAI v7 "+TfName(tf)+" "+IntegerToString((long)pivot_time);
  }

bool ExistingPivot(const int slot,const string comment)
  {
   long magic=SymbolMagic(slot);
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=magic) continue;
      if(OrderGetString(ORDER_SYMBOL)!=g_symbol[slot]) continue;
      if(OrderGetString(ORDER_COMMENT)==comment) return true;
     }
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol[slot]) continue;
      if(PositionGetString(POSITION_COMMENT)==comment) return true;
     }
   return false;
  }

bool IsPivotHigh(const MqlRates &rates[],const int shift,const int total)
  {
   if(shift-COMBOAI7_PIVOT_WING<0 || shift+COMBOAI7_PIVOT_WING>=total) return false;
   for(int k=1;k<=COMBOAI7_PIVOT_WING;k++)
      if(rates[shift].high<=rates[shift-k].high || rates[shift].high<rates[shift+k].high) return false;
   return true;
  }

bool IsPivotLow(const MqlRates &rates[],const int shift,const int total)
  {
   if(shift-COMBOAI7_PIVOT_WING<0 || shift+COMBOAI7_PIVOT_WING>=total) return false;
   for(int k=1;k<=COMBOAI7_PIVOT_WING;k++)
      if(rates[shift].low>=rates[shift-k].low || rates[shift].low>rates[shift+k].low) return false;
   return true;
  }

bool FreshHighZone(const MqlRates &rates[],const int pivot_shift,const double level)
  {
   for(int newer=0;newer<pivot_shift;newer++) if(rates[newer].high>=level) return false;
   return true;
  }

bool FreshLowZone(const MqlRates &rates[],const int pivot_shift,const double level)
  {
   for(int newer=0;newer<pivot_shift;newer++) if(rates[newer].low<=level) return false;
   return true;
  }

double EffectiveMaxSpreadPoints(const int slot)
  {
   double point=SymbolPointValue(slot);
   double configured=MathMax(0.0,g_max_spread[slot]);
   if(point<=0.0) return configured;

   // The observed XAU setting of 15 came from a differently quoted broker.
   // On two/three-digit gold symbols that legacy value can block every order.
   // Normalize only that legacy range to a conservative $0.60 spread ceiling;
   // explicit values above 15 remain fully user-controlled.
   if(slot==0 && configured<=15.0001)
      return MathMax(configured,0.60/point);
   return configured;
  }

bool SpreadAllowed(const int slot,const MqlTick &tick,double &actual_points,double &limit_points)
  {
   double point=SymbolPointValue(slot);
   if(point<=0.0)
     {
      actual_points=0.0;
      limit_points=0.0;
      return false;
     }
   actual_points=(tick.ask-tick.bid)/point;
   limit_points=EffectiveMaxSpreadPoints(slot);
   return actual_points<=limit_points+0.0001;
  }

bool PendingPriceValid(const string symbol,const ENUM_ORDER_TYPE type,const double entry,const MqlTick &tick)
  {
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   double distance=(double)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL)*point;
   if(type==ORDER_TYPE_BUY_STOP)  return entry>=tick.ask+distance;
   if(type==ORDER_TYPE_SELL_STOP) return entry<=tick.bid-distance;
   if(type==ORDER_TYPE_BUY_LIMIT) return entry<=tick.ask-distance;
   if(type==ORDER_TYPE_SELL_LIMIT)return entry>=tick.bid+distance;
   return false;
  }

bool PlacePivot(const int slot,const ENUM_TIMEFRAMES tf,const datetime pivot_time,const bool pivot_high,const double raw_level)
  {
   string symbol=g_symbol[slot];
   string comment=PivotComment(tf,pivot_time);
   if(ExistingPivot(slot,comment)) return true;

   MqlTick tick;
   if(!SymbolInfoTick(symbol,tick)) return false;
   double actual_spread=0.0,spread_limit=0.0;
   if(!SpreadAllowed(slot,tick,actual_spread,spread_limit))
     {
      datetime now=TimeCurrent();
      if(g_last_spread_notice[slot]==0 || now-g_last_spread_notice[slot]>=60)
        {
         PrintFormat("3X Combo AI v7 [%s]: pending layers waiting - spread %.1f pts exceeds effective limit %.1f pts",
                     symbol,actual_spread,spread_limit);
         g_last_spread_notice[slot]=now;
        }
      return false;
     }

   bool flipped=InpFlippingMoney && MathMax(0,MathMin(2,InpFlippingFrame))==(tf==PERIOD_M15 ? 0 : (tf==PERIOD_M30 ? 1 : 2));
   ENUM_ORDER_TYPE type;
   if(!flipped) type=pivot_high ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP;
   else type=pivot_high ? ORDER_TYPE_SELL_LIMIT : ORDER_TYPE_BUY_LIMIT;

   double entry=NormalizePriceForSymbol(symbol,raw_level);
   if(!PendingPriceValid(symbol,type,entry,tick)) return false;

   bool buy=type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_BUY_LIMIT;
   double sl=NormalizePriceForSymbol(symbol,entry+(buy ? -1.0 : 1.0)*InitialSLDistance(slot));
   double tp=NormalizePriceForSymbol(symbol,entry+(buy ? 1.0 : -1.0)*InitialTPDistance(slot));
   double volume=RiskLot(slot);

   trade.SetExpertMagicNumber(SymbolMagic(slot));
   trade.SetDeviationInPoints((ulong)MathMax(0.0,g_max_slippage[slot]));
   trade.SetTypeFillingBySymbol(symbol);

   bool sent=false;
   if(type==ORDER_TYPE_BUY_STOP)       sent=trade.BuyStop(volume,entry,symbol,sl,tp,ORDER_TIME_GTC,0,comment);
   else if(type==ORDER_TYPE_SELL_STOP) sent=trade.SellStop(volume,entry,symbol,sl,tp,ORDER_TIME_GTC,0,comment);
   else if(type==ORDER_TYPE_BUY_LIMIT) sent=trade.BuyLimit(volume,entry,symbol,sl,tp,ORDER_TIME_GTC,0,comment);
   else                                sent=trade.SellLimit(volume,entry,symbol,sl,tp,ORDER_TIME_GTC,0,comment);

   if(!sent)
     {
      if(trade.ResultRetcode()!=TRADE_RETCODE_MARKET_CLOSED)
         PrintFormat("3X Combo AI v7 [%s]: pivot order rejected at %.2f (%u) %s",symbol,entry,trade.ResultRetcode(),trade.ResultRetcodeDescription());
      return false;
     }

   PrintFormat("3X Combo AI v7 [%s]: %s pivot %s placed at %.2f | SL %.2f | TP %.2f",
               symbol,TfName(tf),pivot_high ? "HIGH" : "LOW",entry,sl,tp);
   return true;
  }

void ScanTimeframe(const int slot,const int tf_slot,const bool force_scan)
  {
   if(!g_enabled[slot] || g_symbol[slot]=="") return;
   ENUM_TIMEFRAMES tf=ComboTimeframe(tf_slot);
   datetime bar=iTime(g_symbol[slot],tf,0);
   if(!force_scan && bar>0 && bar==g_last_bar[slot][tf_slot]) return;
   if(bar>0) g_last_bar[slot][tf_slot]=bar;

   int seconds=PeriodSeconds(tf);
   int wanted=(int)MathCeil((double)COMBOAI7_MAX_AGE_HOURS*3600.0/MathMax(1,seconds))+COMBOAI7_PIVOT_WING+10;
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(g_symbol[slot],tf,0,wanted,rates);
   if(copied<COMBOAI7_PIVOT_WING*2+10) return;

   datetime cutoff=TimeCurrent()-COMBOAI7_MAX_AGE_HOURS*3600;
   int confirmed=0,eligible=0,failed=0;
   for(int shift=COMBOAI7_PIVOT_WING;shift<copied-COMBOAI7_PIVOT_WING;shift++)
     {
      if(rates[shift].time<cutoff) break;
      bool high=IsPivotHigh(rates,shift,copied);
      bool low=IsPivotLow(rates,shift,copied);
      if(!high && !low) continue;
      confirmed++;

      if(high && FreshHighZone(rates,shift,rates[shift].high))
        {
         eligible++;
         if(!PlacePivot(slot,tf,rates[shift].time,true,rates[shift].high)) failed++;
        }
      if(low && FreshLowZone(rates,shift,rates[shift].low))
        {
         eligible++;
         if(!PlacePivot(slot,tf,rates[shift].time,false,rates[shift].low)) failed++;
        }
     }

   if(force_scan && (g_last_scan_notice[slot][tf_slot]==0 ||
                     TimeCurrent()-g_last_scan_notice[slot][tf_slot]>=3600))
     {
       PrintFormat("3X Combo AI v7 [%s,%s]: confirmed pivots=%d | eligible fresh zones=%d | max age=%dh",
                   g_symbol[slot],TfName(tf),confirmed,eligible,COMBOAI7_MAX_AGE_HOURS);
      g_last_scan_notice[slot][tf_slot]=TimeCurrent();
     }
   if(failed>0) g_next_retry[slot]=TimeCurrent()+COMBOAI7_RETRY_SECONDS;
  }

void ScanSymbol(const int slot,const bool force_scan)
  {
   if(!g_enabled[slot] || !EntrySessionOpen()) return;
   for(int tf_slot=0;tf_slot<COMBOAI7_TIMEFRAME_COUNT;tf_slot++) ScanTimeframe(slot,tf_slot,force_scan);
  }

int TrackerIndex(const ulong ticket,const double current)
  {
   int free_slot=-1;
   for(int i=0;i<COMBOAI7_MAX_TRACKED;i++)
     {
      if(g_track_ticket[i]==ticket) return i;
      if(g_track_ticket[i]==0 && free_slot<0) free_slot=i;
     }
   if(free_slot<0) return -1;
   g_track_ticket[free_slot]=ticket;
   g_track_peak[free_slot]=current;
   g_track_virtual_sl[free_slot]=0.0;
   return free_slot;
  }

void ClearMissingTrackers()
  {
   for(int i=0;i<COMBOAI7_MAX_TRACKED;i++)
     {
      if(g_track_ticket[i]==0) continue;
      if(!PositionSelectByTicket(g_track_ticket[i]))
        {
         g_track_ticket[i]=0;
         g_track_peak[i]=0.0;
         g_track_virtual_sl[i]=0.0;
        }
     }
  }

bool ServerSLValid(const string symbol,const bool buy,const double sl,const MqlTick &tick)
  {
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   double distance=(double)MathMax(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL),SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL))*point;
   if(buy) return sl<=tick.bid-distance;
   return sl>=tick.ask+distance;
  }

void ManagePositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(!IsOurMagic(magic)) continue;
      string symbol=PositionGetString(POSITION_SYMBOL);
      int slot=SymbolSlot(symbol);
      if(slot<0) continue;

      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      bool buy=type==POSITION_TYPE_BUY;
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double server_sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      MqlTick tick;
      if(!SymbolInfoTick(symbol,tick)) continue;
      double current=buy ? tick.bid : tick.ask;
      int tracker=TrackerIndex(ticket,current);
      if(tracker<0) continue;

      if(buy) g_track_peak[tracker]=MathMax(g_track_peak[tracker],current);
      else g_track_peak[tracker]=MathMin(g_track_peak[tracker],current);
      double favorable=(buy ? 1.0 : -1.0)*(current-entry);
      if(!InpContinuousPeakTrail || favorable<TrailActivation(slot)) continue;

      double desired=g_track_peak[tracker]+(buy ? -1.0 : 1.0)*TrailDistance(slot);
      desired=NormalizePriceForSymbol(symbol,desired);
      bool better_virtual=g_track_virtual_sl[tracker]<=0.0 || (buy ? desired>g_track_virtual_sl[tracker] : desired<g_track_virtual_sl[tracker]);
      if(better_virtual) g_track_virtual_sl[tracker]=desired;

      bool improve_server=server_sl<=0.0 || (buy ? desired>=server_sl+TrailStep(slot)-SymbolPointValue(slot)*0.5
                                                : desired<=server_sl-TrailStep(slot)+SymbolPointValue(slot)*0.5);
      if(improve_server && ServerSLValid(symbol,buy,desired,tick))
        {
         trade.SetExpertMagicNumber(magic);
         trade.SetDeviationInPoints((ulong)MathMax(0.0,g_max_slippage[slot]));
         if(trade.PositionModify(ticket,desired,tp)) server_sl=desired;
         else if(!InpSLFailBackupGuard)
            g_track_virtual_sl[tracker]=server_sl;
        }

      double virtual_sl=g_track_virtual_sl[tracker];
      if(virtual_sl<=0.0) continue;
      bool crossed=buy ? current<=virtual_sl : current>=virtual_sl;
      bool near_guard=InpSmartEarlyExitGuard && (buy ? current<=virtual_sl+EarlyExitBuffer(slot)
                                                   : current>=virtual_sl-EarlyExitBuffer(slot));
      if(crossed || near_guard)
        {
         trade.SetExpertMagicNumber(magic);
         trade.SetDeviationInPoints((ulong)MathMax(0.0,g_max_slippage[slot]));
         if(!trade.PositionClose(ticket) && InpEnableHybridAntiSlippage)
            PrintFormat("3X Combo AI v7 [%s]: protected close retry pending on position %I64u (%u) %s",
                        symbol,ticket,trade.ResultRetcode(),trade.ResultRetcodeDescription());
        }
     }
   ClearMissingTrackers();
  }

void DeleteOurPendingOrders(const string reason)
  {
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || !IsOurMagic(OrderGetInteger(ORDER_MAGIC))) continue;
      trade.SetExpertMagicNumber(OrderGetInteger(ORDER_MAGIC));
      if(!trade.OrderDelete(ticket))
         PrintFormat("3X Combo AI v7: pending delete failed on %I64u (%u) %s",ticket,trade.ResultRetcode(),trade.ResultRetcodeDescription());
     }
   Print("3X Combo AI v7: "+reason);
  }

void ManageWeeklySession()
  {
   MqlDateTime tm;
   TimeToStruct(GMTNow(),tm);
   if(tm.day_of_week==5 && tm.hour>=20)
     {
      if(InpAllPendingDeleteFriday && !g_friday_cleaned)
        {
         DeleteOurPendingOrders("Friday 20:00 GMT pending cleanup completed.");
         g_friday_cleaned=true;
        }
      return;
     }
   if(tm.day_of_week==1 && tm.hour>=1 && g_friday_cleaned)
     {
      g_friday_cleaned=false;
      for(int slot=0;slot<COMBOAI7_MAX_SYMBOLS;slot++) ScanSymbol(slot,true);
      Print("3X Combo AI v7: Monday 01:00 GMT fresh-pivot scan completed.");
     }
  }

int OurPositionCount(const string symbol)
  {
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && PositionGetString(POSITION_SYMBOL)==symbol && IsOurMagic(PositionGetInteger(POSITION_MAGIC))) count++;
     }
   return count;
  }

int OurOrderCount(const string symbol)
  {
   int count=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket>0 && OrderGetString(ORDER_SYMBOL)==symbol && IsOurMagic(OrderGetInteger(ORDER_MAGIC))) count++;
     }
   return count;
  }

void TradeStatistics(int &wins,int &losses,double &profit_factor,double &net)
  {
   wins=0; losses=0; net=0.0;
   double gross_profit=0.0,gross_loss=0.0;
   if(!HistorySelect(0,TimeCurrent())) { profit_factor=0.0; return; }
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || !IsOurMagic(HistoryDealGetInteger(deal,DEAL_MAGIC))) continue;
      ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY) continue;
      double result=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_FEE);
      net+=result;
      if(result>0.0) { wins++; gross_profit+=result; }
      else if(result<0.0) { losses++; gross_loss-=result; }
     }
   profit_factor=gross_loss>0.0 ? gross_profit/gross_loss : (gross_profit>0.0 ? 999.0 : 0.0);
  }

void DeleteDashboard()
  {
   for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
     {
      string name=ObjectName(0,i,0,-1);
      if(StringFind(name,COMBOAI7_PANEL_PREFIX)==0) ObjectDelete(0,name);
     }
  }

void PanelRectangle(const string name,const int x,const int y,const int width,const int height,
                    const color background,const color border)
  {
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);
   ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
  }

void PanelLabel(const string name,const string text,const int x,const int y,const color text_color,
                const ENUM_ANCHOR_POINT anchor,const int font_size)
  {
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_FONT,"Times New Roman");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
  }

string FitPanelText(const string source,const int max_chars)
  {
   int limit=MathMax(4,max_chars);
   if(StringLen(source)<=limit) return source;
   return StringSubstr(source,0,limit-3)+"...";
  }

int PanelFontForWidth(const string text,const int available,const int preferred)
  {
   int length=MathMax(1,StringLen(text));
   int fitted=(int)MathFloor((double)available/(0.57*(double)length));
   return MathMax(9,MathMin(preferred,fitted));
  }

double AccountDailyProfit()
  {
   MqlDateTime day;
   TimeToStruct(TimeCurrent(),day);
   day.hour=0;
   day.min=0;
   day.sec=0;
   datetime from=StructToTime(day);
   if(!HistorySelect(from,TimeCurrent())) return 0.0;

   double result=0.0;
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0) continue;
      ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      result+=HistoryDealGetDouble(deal,DEAL_PROFIT);
      result+=HistoryDealGetDouble(deal,DEAL_SWAP);
      result+=HistoryDealGetDouble(deal,DEAL_COMMISSION);
      result+=HistoryDealGetDouble(deal,DEAL_FEE);
     }
   return result;
  }

void DrawDashboard()
  {
   Comment("");
   if(!InpDashboardShow)
     {
      DeleteDashboard();
      return;
     }

   const int panel_x=16;
   const int panel_y=28;
   int chart_width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int available_width=chart_width-panel_x-12;
   int panel_width=440;
   if(available_width>0) panel_width=MathMin(panel_width,available_width);
   panel_width=MathMax(180,panel_width);
   bool compact=panel_width<360;
   int row_height=compact ? 56 : 60;
   int row_gap=7;
   int panel_height=18+4*row_height+3*row_gap+13;

   // New palette: obsidian, aubergine, ultraviolet and rose metal.  Red and
   // green remain reserved for the live profit state.
   color shadow=C'2,2,5';
   color obsidian=C'12,9,18';
   color aubergine=C'24,17,37';
   color card_dark=C'29,22,44';
   color card_light=C'35,26,52';
   color border=C'78,55,108';
   color ultraviolet=C'155,109,255';
   color violet_soft=C'188,158,255';
   color rose_metal=C'218,126,158';
   color muted=C'170,161,184';
   color pearl=C'244,238,249';
   color profit_green=C'70,226,169';
   color loss_red=C'255,82,116';

   PanelRectangle(COMBOAI7_PANEL_PREFIX+"SHADOW",panel_x+5,panel_y+6,panel_width,panel_height,shadow,shadow);
   PanelRectangle(COMBOAI7_PANEL_PREFIX+"BG",panel_x,panel_y,panel_width,panel_height,obsidian,border);

   int stripe_x=panel_x+10;
   int stripe_width=panel_width-20;
   int segment_width=MathMax(1,stripe_width/5);
   color stripe_colors[5]={ultraviolet,C'183,105,235',rose_metal,C'206,108,181',violet_soft};
   for(int segment=0;segment<5;segment++)
     {
      int width=segment==4 ? stripe_width-segment_width*4 : segment_width;
      PanelRectangle(COMBOAI7_PANEL_PREFIX+"TOP_"+(string)segment,
                     stripe_x+segment*segment_width,panel_y+9,width,3,stripe_colors[segment],stripe_colors[segment]);
     }

   double daily=AccountDailyProfit();
   color daily_color=daily>0.0 ? profit_green : (daily<0.0 ? loss_red : violet_soft);
   string currency=AccountInfoString(ACCOUNT_CURRENCY);
   string spread_symbol=_Symbol;
   for(int slot=0;slot<COMBOAI7_MAX_SYMBOLS;slot++)
      if(g_enabled[slot] && g_symbol[slot]!="") { spread_symbol=g_symbol[slot]; break; }
   double point=SymbolInfoDouble(spread_symbol,SYMBOL_POINT);
   MqlTick tick;
   double spread=0.0;
   if(point>0.0 && SymbolInfoTick(spread_symbol,tick)) spread=(tick.ask-tick.bid)/point;
   string owner=AccountInfoString(ACCOUNT_NAME);
   if(owner=="") owner="--";

   string labels[4]={"DAILY PROFIT","CURRENT SPREAD","BALANCE","ACCOUNT OWNER"};
   string values[4];
   values[0]=StringFormat("%+.2f %s",daily,currency);
   values[1]=StringFormat("%.1f pts",spread);
   values[2]=StringFormat("%.2f %s",AccountInfoDouble(ACCOUNT_BALANCE),currency);
   values[3]=owner;
   color value_colors[4]={daily_color,rose_metal,pearl,violet_soft};
   color accent_colors[4]={daily_color,rose_metal,ultraviolet,violet_soft};

   for(int row=0;row<4;row++)
     {
      int card_x=panel_x+10;
      int card_y=panel_y+18+row*(row_height+row_gap);
      int card_width=panel_width-20;
      color card_color=row%2==0 ? card_dark : card_light;
      PanelRectangle(COMBOAI7_PANEL_PREFIX+"CARD_"+(string)row,card_x,card_y,card_width,row_height,card_color,border);
      PanelRectangle(COMBOAI7_PANEL_PREFIX+"ACCENT_"+(string)row,card_x,card_y,4,row_height,accent_colors[row],accent_colors[row]);

      int label_font=compact ? 9 : 10;
      int value_area=MathMax(40,card_width-32);
      int value_font=PanelFontForWidth(values[row],value_area,compact ? 12 : 14);
      int max_chars=(int)MathFloor((double)value_area/(0.57*9.0));
      string fitted_value=FitPanelText(values[row],max_chars);

      // Every card uses two dedicated lines.  Values never share horizontal
      // space with labels, so long owner names cannot overlap or escape.
      PanelLabel(COMBOAI7_PANEL_PREFIX+"LABEL_"+(string)row,labels[row],card_x+16,card_y+7,muted,ANCHOR_LEFT_UPPER,label_font);
      PanelLabel(COMBOAI7_PANEL_PREFIX+"VALUE_"+(string)row,fitted_value,card_x+16,card_y+(compact ? 27 : 29),value_colors[row],ANCHOR_LEFT_UPPER,value_font);
     }
   ChartRedraw(0);
  }

void ProcessComboAI7()
  {
   ManageWeeklySession();
   ManagePositions();

   if(EntrySessionOpen())
     {
      for(int slot=0;slot<COMBOAI7_MAX_SYMBOLS;slot++)
        {
         if(!g_enabled[slot]) continue;
         bool retry=g_next_retry[slot]>0 && TimeCurrent()>=g_next_retry[slot];
         if(retry) g_next_retry[slot]=0;
         ScanSymbol(slot,retry);
        }
     }

   ulong now=GetTickCount64();
   if(now-g_last_dashboard_ms>=(ulong)COMBOAI7_DASHBOARD_MS)
     {
      DrawDashboard();
      g_last_dashboard_ms=now;
     }
  }

int OnInit()
  {
   ArrayInitialize(g_track_ticket,0);
   ArrayInitialize(g_track_peak,0.0);
   ArrayInitialize(g_track_virtual_sl,0.0);
   ArrayInitialize(g_next_retry,0);
   ArrayInitialize(g_last_spread_notice,0);
   ArrayInitialize(g_last_scan_notice,0);

   g_enabled[0]=InpSymbol1Enabled;
   g_enabled[1]=InpSymbol2Enabled;
   g_enabled[2]=InpSymbol3Enabled;
   g_lot[0]=InpSymbol1Lot; g_lot[1]=InpSymbol2Lot; g_lot[2]=InpSymbol3Lot;
   g_max_spread[0]=InpSymbol1MaxSpreadPips; g_max_spread[1]=InpSymbol2MaxSpreadPips; g_max_spread[2]=InpSymbol3MaxSpreadPips;
   g_max_slippage[0]=InpSymbol1MaxSlippagePips; g_max_slippage[1]=InpSymbol2MaxSlippagePips; g_max_slippage[2]=InpSymbol3MaxSlippagePips;
   g_scale[0]=1.0; g_scale[1]=100.0; g_scale[2]=10.0;

   g_symbol[0]=FindBrokerSymbol(0,InpSymbol1ManualSymbol);
   g_symbol[1]=FindBrokerSymbol(1,InpSymbol2ManualSymbol);
   g_symbol[2]=FindBrokerSymbol(2,InpSymbol3ManualSymbol);

   int active=0;
   for(int slot=0;slot<COMBOAI7_MAX_SYMBOLS;slot++)
     {
      if(!g_enabled[slot]) continue;
      if(g_symbol[slot]=="")
        {
         PrintFormat("3X Combo AI v7: enabled symbol slot %d could not be resolved on this broker.",slot+1);
         g_enabled[slot]=false;
         continue;
        }
      active++;
      PrintFormat("3X Combo AI v7: slot %d resolved to %s",slot+1,g_symbol[slot]);
     }
   if(active==0) return INIT_FAILED;

   // Real-tick testing already calls OnTick for every price change.  A 1 ms
   // tester timer would only create millions of duplicate events, so the
   // tester uses a one-second safety timer while live charts honor the input.
   if(MQLInfoInteger(MQL_TESTER)) EventSetTimer(1);
   else
     {
      int timer=MathMax(1,InpTrailingCheckMs);
      if(!EventSetMillisecondTimer(timer)) EventSetTimer(1);
     }
   if(EntrySessionOpen()) for(int slot=0;slot<COMBOAI7_MAX_SYMBOLS;slot++) ScanSymbol(slot,true);
   DrawDashboard();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
   DeleteDashboard();
   ChartRedraw(0);
  }

void OnTimer()
  {
   ProcessComboAI7();
  }

void OnTick()
  {
   ProcessComboAI7();
  }
