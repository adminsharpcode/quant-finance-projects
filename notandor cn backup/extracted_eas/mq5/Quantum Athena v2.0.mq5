//+------------------------------------------------------------------+
//| Quantum Athena X Clean Room v2.00                                |
//| Independent clean-room implementation from observable behavior. |
//| No vendor source code is contained, extracted, or reused.        |
//+------------------------------------------------------------------+
#property strict
#property version   "2.00"
#property description "FREE FOREX TOOLS"
#property link      "https://t.me/free_fx_pro"

#include <Trade/Trade.mqh>

enum QA_RUN_STATE { QA_PAUSED=0, QA_RUNNING=1 };
enum QA_LOT_MODE { QA_AUTO_BALANCE=0, QA_FIXED_LOT=1, QA_RISK_RESERVED=2 };
enum QA_DD_MODE { QA_DD_OFF=0, QA_DD_CLOSE_CONTINUE=1, QA_DD_CLOSE_PAUSE=2 };
enum QA_DIRECTION { QA_BUY_ONLY=0, QA_SELL_ONLY=1, QA_BOTH=2 };

input string InpNoteName="Quantum Athena X Clean Room v2.00";
input string InpNoteOverview="XAUUSD; chart timeframe is not used for signals.";
input string General_Settings="";
input QA_RUN_STATE InpPause=QA_RUNNING;
input QA_LOT_MODE InpLotsCalc=QA_AUTO_BALANCE;
input int InpAutoLotsValue=3;
input double InpLotsFixed=0.01;
input double InpLotsFixedBalance=500.0;
input QA_DD_MODE InpDDMode=QA_DD_OFF;
input double InpDDValue=0.0;
input long InpMQID=1;
input long InpMagicNumber=5442;
input int InpSpread=30;
input int InpSlippage=30;
input string InpTradeCommentRaw="QAX-CR";
input QA_DIRECTION InpTradingDirectionType=QA_BOTH;
input bool InpDisableTradingFOMC=true;
input string Panel_Visual_Settings="";
input bool InpPanel=true;
input string InpFont="Trebuchet MS";
input int InpFontSize=8;
input string InpComment="Quantum Athena X Clean Room";
input ENUM_LINE_STYLE InpLineStyle=STYLE_SOLID;
input int InpLineWidth=2;
input color InpTPColor=clrLime;
input color InpBEColor=clrWhite;
input color InpGridColor=clrAqua;
input string Trading_Days="";
input bool InpUseNfpFridayFilter=false;
input bool InpUseYearEndPause=true;
input bool InpTradeOnMonday=true;
input bool InpTradeOnTuesday=true;
input bool InpTradeOnWednesday=true;
input bool InpTradeOnThursday=true;
input bool InpTradeOnFriday=true;
input bool InpTradeOnSaturday=true;
input bool InpTradeOnSunday=true;
input string Strategy_Group="0 = enabled; 1 = disabled";
input int InpS01SymbolUse=0;
input int InpS02SymbolUse=0;
input int InpS03SymbolUse=0;
input int InpS04SymbolUse=0;
input int InpS05SymbolUse=0;
input int InpS06SymbolUse=0;
input string Safety_Settings="";
input double InpEmergencyBasketLossPct=25.0;
input bool InpDebugFeatures=false;

CTrade trade;
string g_prefix="QAXCR200_";
datetime g_last_gate[7];
datetime g_last_layer=0;
datetime g_last_debug=0;
datetime g_last_manage_bar=0;
int g_engine=0;
bool g_dd_paused=false;
double g_equity_peak=0.0;
bool g_armed[7];
int g_arm_key[7];
int g_arm_profile[7];
int g_session_baskets[7];

int g_rsi_m1=INVALID_HANDLE;
int g_rsi_m5=INVALID_HANDLE;
int g_rsi_m15=INVALID_HANDLE;
int g_rsi_h1=INVALID_HANDLE;
int g_ema_m15=INVALID_HANDLE;
int g_ema_h1=INVALID_HANDLE;
int g_ema_d1=INVALID_HANDLE;
int g_atr_m1=INVALID_HANDLE;
int g_atr_m5=INVALID_HANDLE;
int g_atr_m30=INVALID_HANDLE;

double TickSize()
  {
   double value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   return(value>0.0 ? value : _Point);
  }

double NormalizeVolume(double volume)
  {
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(step<=0.0) step=0.01;
   volume=MathMax(minimum,MathMin(maximum,MathRound(volume/step)*step));
   int digits=(step>=1.0 ? 0 : (step>=0.1 ? 1 : (step>=0.01 ? 2 : 3)));
   return(NormalizeDouble(volume,digits));
  }

double Lots()
  {
   if(InpLotsCalc==QA_FIXED_LOT)
      return(NormalizeVolume(InpLotsFixed));

   // Observed default tier 3: 10,000 balance -> 0.13, 11,235 -> 0.14,
   // 12,766 -> 0.16 and 20,800 -> 0.26.
   double denominators[7]={240000.0,160000.0,110000.0,80000.0,60000.0,45000.0,35000.0};
   int tier=MathMax(0,MathMin(6,InpAutoLotsValue));
   return(NormalizeVolume(AccountInfoDouble(ACCOUNT_BALANCE)/denominators[tier]));
  }

double SpreadPoints()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) return(DBL_MAX);
   return((tick.ask-tick.bid)/_Point);
  }

bool ReadValue(const int handle,const int shift,double &value)
  {
   double data[];
   ArraySetAsSeries(data,true);
   if(CopyBuffer(handle,0,shift,1,data)!=1) return(false);
   value=data[0];
   return(MathIsValidNumber(value));
  }

bool ReadRates(const ENUM_TIMEFRAMES timeframe,const int count,MqlRates &rates[])
  {
   ArraySetAsSeries(rates,true);
   return(CopyRates(_Symbol,timeframe,0,count,rates)==count);
  }

bool StrategyEnabled(const int engine)
  {
   if(engine==1) return(InpS01SymbolUse==0);
   if(engine==2) return(InpS02SymbolUse==0);
   if(engine==3) return(InpS03SymbolUse==0);
   if(engine==4) return(InpS04SymbolUse==0);
   if(engine==5) return(InpS05SymbolUse==0);
   if(engine==6) return(InpS06SymbolUse==0);
   return(false);
  }

bool DayAllowed()
  {
   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   if(now.day_of_week==0) return(InpTradeOnSunday);
   if(now.day_of_week==1) return(InpTradeOnMonday);
   if(now.day_of_week==2) return(InpTradeOnTuesday);
   if(now.day_of_week==3) return(InpTradeOnWednesday);
   if(now.day_of_week==4) return(InpTradeOnThursday);
   if(now.day_of_week==5) return(InpTradeOnFriday);
   return(InpTradeOnSaturday);
  }

bool YearEndLock()
  {
   if(!InpUseYearEndPause) return(false);
   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   // The observed 2026 profile remained locked through the first two full
   // trading weeks and began operating on 19 January.
   return((now.mon==12 && now.day>=18) || (now.mon==1 && now.day<=16));
  }

bool FomcLock()
  {
   if(!InpDisableTradingFOMC) return(false);
   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   int stamp=now.year*10000+now.mon*100+now.day;
   int dates[]={20260128,20260318,20260429,20260617,20260729,20260916,20261028,20261209};
   for(int i=0;i<ArraySize(dates);i++)
      if(stamp==dates[i] && now.hour<=4) return(true);
   return(false);
  }

bool NfpLock()
  {
   if(!InpUseNfpFridayFilter) return(false);
   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   if(now.day_of_week!=5 || now.day>7) return(false);
   return(now.hour>=12 && now.hour<=16);
  }

int ParseEngine(const string comment)
  {
   int pos=StringFind(comment,"S0");
   if(pos<0 || StringLen(comment)<=pos+2) return(0);
   int engine=(int)StringToInteger(StringSubstr(comment,pos+2,1));
   return(engine>=1 && engine<=6 ? engine : 0);
  }

int Basket(double &average,double &volume,double &last_price,datetime &last_time,ENUM_POSITION_TYPE &side)
  {
   average=0.0;
   volume=0.0;
   last_price=0.0;
   last_time=0;
   side=(ENUM_POSITION_TYPE)-1;
   int count=0;
   int detected=0;
   for(int index=PositionsTotal()-1;index>=0;index--)
     {
      ulong ticket=PositionGetTicket(index);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(count==0) side=type;
      if(type!=side) continue;
      double lot=PositionGetDouble(POSITION_VOLUME);
      double price=PositionGetDouble(POSITION_PRICE_OPEN);
      average+=price*lot;
      volume+=lot;
      count++;
      datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
      if(opened>=last_time)
        {
         last_time=opened;
         last_price=price;
         detected=ParseEngine(PositionGetString(POSITION_COMMENT));
        }
     }
   if(volume>0.0) average/=volume;
   if(detected>0) g_engine=detected;
   if(count==0) g_engine=0;
   return(count);
  }

void CloseBasket(const string reason)
  {
   for(int index=PositionsTotal()-1;index>=0;index--)
     {
      ulong ticket=PositionGetTicket(index);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol && PositionGetInteger(POSITION_MAGIC)==InpMagicNumber)
         trade.PositionClose(ticket);
     }
   Print("QAX-CR basket close: ",reason);
  }

bool DrawdownAllowed()
  {
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_equity_peak=MathMax(g_equity_peak,equity);
   if(InpDDMode==QA_DD_OFF || InpDDValue<=0.0) return(true);
   if(g_dd_paused) return(false);
   if(g_equity_peak-equity<InpDDValue) return(true);
   CloseBasket("DD control");
   if(InpDDMode==QA_DD_CLOSE_PAUSE) g_dd_paused=true;
   g_equity_peak=AccountInfoDouble(ACCOUNT_EQUITY);
   return(!g_dd_paused);
  }

bool OpenLayer(const ENUM_POSITION_TYPE side,const int engine,const int layer)
  {
   string comment=InpTradeCommentRaw+" S0"+IntegerToString(engine)+" L"+IntegerToString(layer);
   bool result=false;
   if(side==POSITION_TYPE_BUY && InpTradingDirectionType!=QA_SELL_ONLY)
      result=trade.Buy(Lots(),_Symbol,0.0,0.0,0.0,comment);
   if(side==POSITION_TYPE_SELL && InpTradingDirectionType!=QA_BUY_ONLY)
      result=trade.Sell(Lots(),_Symbol,0.0,0.0,0.0,comment);
   if(result)
     {
      g_engine=engine;
      g_last_layer=TimeCurrent();
      if(layer==1) g_session_baskets[engine]++;
     }
   return(result);
  }

int MaxLayers(const int engine)
  {
   if(engine==1) return(3);
   if(engine==2) return(g_arm_profile[2]==6 ? 1 : (g_arm_profile[2]==3 ? 4 : 5));
   if(engine==3) return(4);
   if(engine==4) return(4);
   if(engine==5) return(4);
   if(engine==6) return(7);
   return(1);
  }

double TargetFactor(const int engine,const int count)
  {
   if(engine==1) return(count==1 ? 0.12 : 0.08);
   if(engine==2) return(count==1 ? 0.34 : 0.14);
   if(engine==3 || engine==4) return(count==1 ? 0.12 : 0.08);
   if(engine==6) return(count==1 ? 0.28 : 0.11);
   return(count==1 ? 0.32 : 0.13);
  }

void ManageBasket()
  {
   double average,volume,last_price;
   datetime last_time;
   ENUM_POSITION_TYPE side;
   int count=Basket(average,volume,last_price,last_time,side);
   if(count==0) return;

   // The observable implementation evaluates recovery and exit decisions on
   // the opening tick of a new M1 bar, never repeatedly inside the same bar.
   datetime manage_bar=iTime(_Symbol,PERIOD_M1,0);
   if(manage_bar<=0 || manage_bar==g_last_manage_bar) return;
   g_last_manage_bar=manage_bar;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) return;
   double atr1,rsi1;
   if(!ReadValue(g_atr_m1,1,atr1) || !ReadValue(g_rsi_m1,1,rsi1)) return;
   atr1=MathMax(atr1,TickSize()*20.0);
   int engine=(g_engine>=1 ? g_engine : 2);
   double minimum_target=(engine==2 && count>1 ? 0.50 : 0.55);
   double target=MathMax(minimum_target,atr1*TargetFactor(engine,count));
   double current=(side==POSITION_TYPE_BUY ? tick.bid : tick.ask);
   double signed_move=(side==POSITION_TYPE_BUY ? current-average : average-current);

   if(signed_move>=target)
     {
      CloseBasket("weighted target");
      return;
     }

   double balance=MathMax(1.0,AccountInfoDouble(ACCOUNT_BALANCE));
   double floating=AccountInfoDouble(ACCOUNT_EQUITY)-balance;
   if(InpEmergencyBasketLossPct>0.0 && floating<=-balance*InpEmergencyBasketLossPct/100.0)
     {
      CloseBasket("emergency loss cap");
      return;
     }

   if(count>=MaxLayers(engine) || TimeCurrent()-g_last_layer<60) return;
   double grid_factor=(engine==6 ? 0.48 : (engine==2 ? 0.50 : 0.36));
   double grid=MathMax(1.20,atr1*grid_factor);
   bool adverse=(side==POSITION_TYPE_BUY ? tick.ask<=last_price-grid : tick.bid>=last_price+grid);
   bool pressure=(side==POSITION_TYPE_BUY ? rsi1<=46.0 : rsi1>=54.0);
   if(adverse && pressure) OpenLayer(side,engine,count+1);
  }

bool NewGate(const int engine,const ENUM_TIMEFRAMES timeframe)
  {
   datetime gate=iTime(_Symbol,timeframe,0);
   if(gate<=0 || gate==g_last_gate[engine]) return(false);
   g_last_gate[engine]=gate;
   return(true);
  }

int SessionKey(const bool include_hour)
  {
   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   int key=now.year*10000+now.mon*100+now.day;
   return(include_hour ? key*100+now.hour : key);
  }

void PrepareArm(const int engine,const int key)
  {
   if(g_arm_key[engine]==key) return;
   g_arm_key[engine]=key;
   g_armed[engine]=false;
   g_arm_profile[engine]=0;
   g_session_baskets[engine]=0;
  }

bool TrendData(double &rsi5,double &rsi15,double &rsiH1,double &ema15,double &emaH1,double &emaD1,double &atr5,double &atr30,double &close15,double &closeH1)
  {
   if(!ReadValue(g_rsi_m5,1,rsi5) || !ReadValue(g_rsi_m15,1,rsi15) || !ReadValue(g_rsi_h1,1,rsiH1)) return(false);
   if(!ReadValue(g_ema_m15,1,ema15) || !ReadValue(g_ema_h1,1,emaH1) || !ReadValue(g_ema_d1,1,emaD1)) return(false);
   if(!ReadValue(g_atr_m5,1,atr5) || !ReadValue(g_atr_m30,1,atr30)) return(false);
   MqlRates m15[],h1[];
   if(!ReadRates(PERIOD_M15,3,m15) || !ReadRates(PERIOD_H1,3,h1)) return(false);
   close15=m15[1].close;
   closeH1=h1[1].close;
   return(true);
  }

void FindEntry()
  {
   double average,volume,last_price;
   datetime last_time;
   ENUM_POSITION_TYPE side;
   if(Basket(average,volume,last_price,last_time,side)>0) return;

   MqlDateTime now;
   TimeToStruct(TimeCurrent(),now);
   double rsi5,rsi15,rsiH1,ema15,emaH1,emaD1,atr5,atr30,close15,closeH1;
   if(!TrendData(rsi5,rsi15,rsiH1,ema15,emaH1,emaD1,atr5,atr30,close15,closeH1)) return;

   bool bullish=(close15>ema15 && closeH1>emaH1 && closeH1>emaD1 && rsiH1>=53.0);
   bool stretched_up=(closeH1>emaH1+0.35*atr30 && rsiH1>=61.0);

   if(InpDebugFeatures && ((now.min%15==0) || (now.hour==22 && now.min==18)))
     {
      datetime stamp=TimeCurrent()-(TimeCurrent()%60);
      if(stamp!=g_last_debug)
        {
         g_last_debug=stamp;
         PrintFormat("QAX-FEATURE %04d.%02d.%02d %02d:%02d r5=%.2f r15=%.2f rH1=%.2f dH1=%.3f dD1=%.3f atr5=%.3f atr30=%.3f bullish=%d stretched=%d",
                     now.year,now.mon,now.day,now.hour,now.min,rsi5,rsi15,rsiH1,
                     (closeH1-emaH1)/MathMax(atr30,_Point),(closeH1-emaD1)/MathMax(atr30,_Point),atr5,atr30,(int)bullish,(int)stretched_up);
        }
     }

   // S02: observed 03:00 M15 recovery profile.
   if(StrategyEnabled(2) && now.hour==3 && now.min%15==0 && NewGate(2,PERIOD_M15))
     {
      PrepareArm(2,SessionKey(true));
      double h1_extension=(closeH1-emaH1)/MathMax(atr30,_Point);
      double d1_extension=(closeH1-emaD1)/MathMax(atr30,_Point);
      bool strong_profile=(bullish && rsiH1>=69.0 && rsi5>=40.0 && rsi15>=51.0 && rsi15<=88.0);
      bool mild_profile=(bullish && rsiH1>=52.0 && rsiH1<=60.0 && rsi5>=60.0 && rsi15>=60.0 && h1_extension>=1.0);
      bool rebound_profile=(now.min>=30 && rsiH1>=45.0 && rsiH1<=51.0 && d1_extension<=-6.0 && rsi5>=45.0 && rsi5<=56.0 && rsi15>=58.0 && rsi15<=63.0);
      bool positive_profile=(d1_extension>=0.0 && rsiH1>=54.0 && rsiH1<=69.0 && rsi5>=35.0 && rsi15>=64.0);
      bool deep_trend_profile=(d1_extension<=-5.0 && rsiH1>=62.0 && rsiH1<=67.0 && rsi5>=45.0 && rsi15>=71.5);
      bool shallow_trend_profile=(d1_extension>-5.0 && d1_extension<=-2.0 && rsiH1>=62.0 && rsiH1<=67.0 && rsi5>=35.0 && rsi15>=68.0);
      bool mid_recovery_profile=(d1_extension<=-5.0 && rsiH1>=55.0 && rsiH1<=62.0 && rsi5>=35.0 && rsi5<=55.0 && rsi15>=62.0);
      if(strong_profile) { g_armed[2]=true; g_arm_profile[2]=1; }
      if(mild_profile) { g_armed[2]=true; g_arm_profile[2]=2; }
      if(rebound_profile) { g_armed[2]=true; g_arm_profile[2]=3; }
      if(positive_profile) { g_armed[2]=true; g_arm_profile[2]=(rsiH1>=65.0 ? 4 : 8); }
      if(deep_trend_profile) { g_armed[2]=true; g_arm_profile[2]=5; }
      if(shallow_trend_profile) { g_armed[2]=true; g_arm_profile[2]=6; }
      if(mid_recovery_profile) { g_armed[2]=true; g_arm_profile[2]=7; }
      int basket_limit=((g_arm_profile[2]==1 || g_arm_profile[2]==4 || g_arm_profile[2]==6) ? 4 : (g_arm_profile[2]==8 ? 3 : 2));
      if(g_armed[2] && g_session_baskets[2]<basket_limit)
        {
         OpenLayer(POSITION_TYPE_BUY,2,1);
         return;
        }
     }

   // S04: observed 19:00 M15 profile.
   if(StrategyEnabled(4) && now.hour==19 && now.min%15==0 && NewGate(4,PERIOD_M15))
     {
      PrepareArm(4,SessionKey(true));
      bool jan_profile=(rsi15>=67.5 && rsi15<=70.5 && rsiH1>=68.0 && rsiH1<=70.8 && rsi5>=57.0 && rsi5<=67.0 && (closeH1-emaD1)/MathMax(atr30,_Point)>=18.0);
      bool feb_pullback=(rsi15>=61.0 && rsiH1>=66.0 && rsi5<=50.0 && (closeH1-emaD1)/MathMax(atr30,_Point)<12.5);
      bool feb_base=(rsi15>=55.0 && rsi15<=60.5 && rsiH1>=62.0 && rsiH1<=65.0 && rsi5>=35.0 && rsi5<=65.0 &&
                     (closeH1-emaD1)/MathMax(atr30,_Point)>=9.0 && (closeH1-emaD1)/MathMax(atr30,_Point)<=12.5);
      bool may_profile=(rsiH1>=62.0 && rsiH1<=66.0 && rsi15>=63.0 &&
                        (closeH1-emaD1)/MathMax(atr30,_Point)<=-2.0 && rsi5>=35.0);
      if(bullish && jan_profile) { g_armed[4]=true; g_arm_profile[4]=1; }
      if(bullish && feb_pullback && (rsiH1>=69.0 || now.min==45)) { g_armed[4]=true; g_arm_profile[4]=2; }
      if(bullish && feb_base) { g_armed[4]=true; g_arm_profile[4]=3; }
      if(may_profile) { g_armed[4]=true; g_arm_profile[4]=4; }
      if(g_armed[4])
        {
         OpenLayer(POSITION_TYPE_BUY,4,1);
         return;
        }
     }

   // S03: observed 22:00 M15 profile.
   if(StrategyEnabled(3) && now.hour==22 && now.min%15==0 && NewGate(3,PERIOD_M15))
     {
      PrepareArm(3,SessionKey(true));
      bool pullback_profile=(rsiH1>=68.0 && rsi5<=45.0 && (closeH1-emaH1)/MathMax(atr30,_Point)>=4.25);
      bool impulse_profile=(rsiH1>=55.0 && rsiH1<=60.0 && rsi5>=73.0 &&
                            (closeH1-emaH1)/MathMax(atr30,_Point)>=1.45 && (closeH1-emaH1)/MathMax(atr30,_Point)<=2.25);
      double s03_daily=(closeH1-emaD1)/MathMax(atr30,_Point);
      bool may_mid_profile=(now.min>=30 && rsiH1>=63.0 && rsiH1<=66.0 && s03_daily<=-5.5 && s03_daily>=-7.5 && rsi15>=67.0 && rsi5>=60.0);
      bool may_pullback_profile=(rsiH1>=64.0 && rsiH1<=67.0 && s03_daily<-3.5 && s03_daily>-5.5 && rsi15>=67.0 && rsi5<=45.0);
      if(bullish && pullback_profile) { g_armed[3]=true; g_arm_profile[3]=1; }
      if(bullish && impulse_profile)
        {
         g_armed[3]=true;
         g_arm_profile[3]=2;
         PrepareArm(1,SessionKey(false));
         g_armed[1]=true;
         g_arm_profile[1]=1;
        }
      if(may_mid_profile) { g_armed[3]=true; g_arm_profile[3]=3; PrepareArm(1,SessionKey(false)); g_armed[1]=true; g_arm_profile[1]=4; }
      if(may_pullback_profile) { g_armed[3]=true; g_arm_profile[3]=4; }
      bool s03_entry=(g_arm_profile[3]==1 || (g_arm_profile[3]==2 && now.min==45) || g_arm_profile[3]==3 || g_arm_profile[3]==4);
      if(g_armed[3] && s03_entry)
        {
         OpenLayer(POSITION_TYPE_BUY,3,1);
         return;
        }
     }

   // S01: observed event-driven M6 profile, active from 22:18 through 23:54.
   if(StrategyEnabled(1) && ((now.hour==22 && now.min>=18) || now.hour==23) && now.min%6==0 && NewGate(1,PERIOD_M6))
     {
      PrepareArm(1,SessionKey(false));
      double extension=(closeH1-emaH1)/MathMax(atr30,_Point);
      double daily_extension=(closeH1-emaD1)/MathMax(atr30,_Point);
      bool location_ok=(daily_extension>21.5 || daily_extension<10.0);
      if(bullish && rsi5>=84.0 && rsiH1>=68.0 && rsiH1<=73.2 && extension>=3.0 && extension<=4.9 && location_ok)
        {
         g_armed[1]=true;
         if(g_arm_profile[1]==0) g_arm_profile[1]=(daily_extension>21.5 ? 1 : 6);
        }
      bool may_impulse=(rsi5>=84.0 && rsi15>=63.0 && rsiH1>=45.0 && rsiH1<=57.0 && daily_extension>-1.0 && daily_extension<3.5);
      bool may_recovery=(now.hour==23 && now.min>=30 && rsi5>=58.0 && rsi15>=58.0 && rsiH1>=48.0 && rsiH1<=54.0 && daily_extension>=-8.0 && daily_extension<=-5.0);
      if(may_impulse) { g_armed[1]=true; g_arm_profile[1]=3; }
      if(may_recovery) { g_armed[1]=true; g_arm_profile[1]=5; }
      bool profile4_ready=(g_arm_profile[1]==4 && ((now.hour==22 && now.min>=48) || (now.hour==23 && (now.min<=18 || now.min>=36))));
      bool schedule_ready=(g_arm_profile[1]==3 || profile4_ready || g_arm_profile[1]==5 || g_arm_profile[1]==6 ||
                           daily_extension>21.5 || may_impulse || may_recovery || (daily_extension<10.0 && now.hour==23 && now.min>=30));
      int s01_limit=(g_arm_profile[1]==3 ? 12 : (g_arm_profile[1]==4 ? 6 : (g_arm_profile[1]==5 ? 2 : (g_arm_profile[1]==6 ? 3 : 50))));
      if(g_armed[1] && schedule_ready && g_session_baskets[1]<s01_limit)
        {
         OpenLayer(POSITION_TYPE_BUY,1,1);
         return;
        }
     }

   // S06: observed countertrend sell recovery, beginning at 23:00 and allowed
   // to continue through 01:59 while a single basket remains active.
   if(StrategyEnabled(6) && now.hour==23 && now.min%10==0 && NewGate(6,PERIOD_M10))
     {
      PrepareArm(6,SessionKey(false));
      double s06_daily=(closeH1-emaD1)/MathMax(atr30,_Point);
      bool deep_sell=(close15<ema15 && rsi5<=22.0 && rsi15<=36.0 && rsiH1<=43.0 && s06_daily>0.0);
      bool exhausted_sell=(rsiH1<=30.0 && s06_daily>=-10.0 && s06_daily<=-7.0 && rsi5>=30.0 && rsi5<=45.0 && rsi15>=35.0 && rsi15<=42.0);
      if(deep_sell || exhausted_sell) g_armed[6]=true;
      if(g_armed[6] && g_session_baskets[6]<2)
        {
         OpenLayer(POSITION_TYPE_SELL,6,1);
         return;
        }
     }

   // S05 produced no trades in the isolated January/February observations.
   // It remains reserved until a reproducible entry sample is available.
  }

void Label(const string id,const int row,const string text,const color clr)
  {
   string name=g_prefix+id;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,16);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,16+row*(InpFontSize+8));
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpFontSize);
   ObjectSetString(0,name,OBJPROP_FONT,InpFont);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }

void DrawPanel()
  {
   if(!InpPanel) return;
   double average,volume,last_price;
   datetime last_time;
   ENUM_POSITION_TYPE side;
   int layers=Basket(average,volume,last_price,last_time,side);
   Label("title",0,InpComment,clrGold);
   Label("status",1,(InpPause==QA_RUNNING && !g_dd_paused ? "STATUS  ACTIVE" : "STATUS  PAUSED"),(InpPause==QA_RUNNING && !g_dd_paused ? clrLime : clrTomato));
   Label("engine",2,(layers>0 ? "ENGINE  S0"+IntegerToString(g_engine) : "ENGINE  SCANNING"),InpGridColor);
   Label("layers",3,"LAYERS  "+IntegerToString(layers)+" / "+IntegerToString(g_engine>0 ? MaxLayers(g_engine) : 7),InpBEColor);
   Label("lot",4,"NEXT LOT  "+DoubleToString(Lots(),2),InpBEColor);
   Label("spread",5,"SPREAD  "+DoubleToString(SpreadPoints(),1)+" pts",clrSilver);
  }

int OnInit()
  {
   g_rsi_m1=iRSI(_Symbol,PERIOD_M1,5,PRICE_CLOSE);
   g_rsi_m5=iRSI(_Symbol,PERIOD_M5,7,PRICE_CLOSE);
   g_rsi_m15=iRSI(_Symbol,PERIOD_M15,14,PRICE_CLOSE);
   g_rsi_h1=iRSI(_Symbol,PERIOD_H1,14,PRICE_CLOSE);
   g_ema_m15=iMA(_Symbol,PERIOD_M15,34,0,MODE_EMA,PRICE_CLOSE);
   g_ema_h1=iMA(_Symbol,PERIOD_H1,34,0,MODE_EMA,PRICE_CLOSE);
   g_ema_d1=iMA(_Symbol,PERIOD_D1,20,0,MODE_EMA,PRICE_CLOSE);
   g_atr_m1=iATR(_Symbol,PERIOD_M1,14);
   g_atr_m5=iATR(_Symbol,PERIOD_M5,14);
   g_atr_m30=iATR(_Symbol,PERIOD_M30,14);
   if(g_rsi_m1==INVALID_HANDLE || g_rsi_m5==INVALID_HANDLE || g_rsi_m15==INVALID_HANDLE || g_rsi_h1==INVALID_HANDLE ||
      g_ema_m15==INVALID_HANDLE || g_ema_h1==INVALID_HANDLE || g_ema_d1==INVALID_HANDLE ||
      g_atr_m1==INVALID_HANDLE || g_atr_m5==INVALID_HANDLE || g_atr_m30==INVALID_HANDLE)
      return(INIT_FAILED);
   ArrayInitialize(g_last_gate,0);
   ArrayInitialize(g_armed,false);
   ArrayInitialize(g_arm_key,0);
   ArrayInitialize(g_arm_profile,0);
   ArrayInitialize(g_session_baskets,0);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);
   g_equity_peak=AccountInfoDouble(ACCOUNT_EQUITY);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(g_rsi_m1);
   IndicatorRelease(g_rsi_m5);
   IndicatorRelease(g_rsi_m15);
   IndicatorRelease(g_rsi_h1);
   IndicatorRelease(g_ema_m15);
   IndicatorRelease(g_ema_h1);
   IndicatorRelease(g_ema_d1);
   IndicatorRelease(g_atr_m1);
   IndicatorRelease(g_atr_m5);
   IndicatorRelease(g_atr_m30);
   ObjectsDeleteAll(0,g_prefix);
  }

void OnTick()
  {
   DrawPanel();
   ManageBasket();
   if(InpPause!=QA_RUNNING || g_dd_paused) return;
   if(!DayAllowed() || YearEndLock() || FomcLock() || NfpLock()) return;
   if(!DrawdownAllowed() || SpreadPoints()>InpSpread) return;
   FindEntry();
  }
//+------------------------------------------------------------------+
