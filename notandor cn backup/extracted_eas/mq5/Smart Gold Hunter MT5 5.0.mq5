#property strict
#property version "5.00"
#property copyright "Free forex tools"
#property link "https://t.me/free_fx_pro"
#property description "Smart Gold Hunter 5.0"


#ifndef SMART_GOLD_HUNTER_INPUTS_MQH
#define SMART_GOLD_HUNTER_INPUTS_MQH


enum SGH_PROFILE_MODE
{
   SGH_STRIKER=0,          // Striker
   SGH_ULTIMATE_SCALPER=1, // Ultimate Scalper
   SGH_CLASSIC_SCALPER=2,  // Classic Scalper
   SGH_SWINGER=3,          // Swinger
   SGH_PROP_SCALPER=4,     // Prop Firm Scalper
   SGH_POSITIVE_RR=5,      // Positive RR
   SGH_CUSTOM=6           // Custom
};
enum SGH_LOT_METHOD
{
   SGH_FIXED_LOTS=0,       // Fixed Lot
   SGH_RISK_PERCENT=1,     // Risk Percent
   SGH_BALANCE_PER_001=2   // Balance Per 0.01 Lot
};
enum SGH_PORTFOLIO_LOT_METHOD
{
   SGH_PORTFOLIO_FIXED_LOTS=0,  // Fixed Lot
   SGH_PORTFOLIO_RISK_PERCENT=1 // Risk Percent
};
enum SGH_DAILY_DD_REFERENCE
{
   SGH_PREV_DAY_BALANCE=0, // Balance
   SGH_PREV_DAY_EQUITY=1   // Equity
};

input group "MODE SETTINGS"
input SGH_PROFILE_MODE inp_Mode = SGH_POSITIVE_RR; // Strategy Profile

input group "ADDITIONAL OPTIONS"
input bool inp_UltimateEntryRandomizer = false; // Entry Randomizer
input bool inp_UltimateBreakEven = false; // Break Even (Not Applicable to Positive RR / Swinger / Prop Firm
input bool inp_UltimateFalseInitialSL = false; // False Initial SL On Pending Order
input double inp_UltimateFalseSLPoints = 1000.0; // False Initial SL Distance (points)
input bool inp_UltimateSLFromExecution = false; // Recalculate SL From Execution

input group "RISK SETTINGS (ALL PROFILES)"
input SGH_LOT_METHOD inp_LotMethod = SGH_FIXED_LOTS; // Lot Size Method
input double inp_Lots = 0.01; // Fixed Lot
input double inp_RiskPercent = 1.0; // Risk Percent
input double inp_BalancePer001Lot = 100.0; // Balance Per 0.01 Lot
input int inp_MaxSpread = 0; // Max Spread (points, 0=off)
input bool inp_UseHighSpreadDeletePending = false; // High Spread Protection

input group "CUSTOM PROFILE SETTINGS"
input double inp_TP = 250.0; // Custom Take Profit (points, 0=off)
input double inp_SL = 500.0; // Custom Stop Loss (points, 0=off)
input double inp_TrailStart = 100.0; // Custom Trailing Start (points, 0=off)
input double inp_TrailStop = 50.0; // Custom Trailing Stop (points)
input int inp_Pause = 300; // Custom Pause Between Positions (sec)
input double inp_CustomPointsAway = 0.0; // Entry distance adjustment (+/- points)

input group "ACCOUNT PROTECTIONS"
input bool inp_UsePropFirmMode = true; // Enable Daily Profit/Loss Protections
input bool inp_UseDailyProfitTarget = false; // Stop After Daily Profit Target
input double inp_DailyProfitTargetUSD = 200.0; // Daily Profit Target
input bool inp_UseDailyLossLimit = false; // Stop After Daily Loss Limit
input double inp_DailyLossLimitUSD = 100.0; // Daily Loss Limit
input bool inp_UseEquityProtection = false; // Close All If Daily DD Is Hit
input double inp_DailyEquityProtectionPercent = 3.0; // Daily Drawdown %
input SGH_DAILY_DD_REFERENCE inp_DailyDDReference = SGH_PREV_DAY_BALANCE; // Daily Drawdown Based On
input bool inp_UseHighImpactNewsFilter = false; // Use All High-Impact News
input bool inp_UseMajorNewsFilter = true; // Use Selected High-Impact News Only
input string inp_NewsCurrencies = "USD"; // News Currencies: USD,EUR,GBP
input string inp_MajorNewsKeywords = "NFP,CPI,FOMC,Fed Chair,Core PCE"; // Selected High-Impact News
input int inp_NewsMinutesBefore = 5; // Minutes Before News
input int inp_NewsMinutesAfter = 5; // Minutes After Normal News
input bool inp_FullFedChairSpeechProtection = true; // Full Fed Chair Speech Protection
input int inp_FedChairSpeechMinutes = 60; // Fed Chair Protection Minutes
input bool inp_UseManualDailyCloseTime = true; // Use manual daily close/reopen time
input int inp_DailyCloseHour = 21; // Daily close hour
input int inp_DailyCloseMinute = 15; // Daily close minute
input int inp_DailyReopenHour = 1; // Daily reopen hour
input int inp_DailyReopenMinute = 15; // Daily reopen minute
input bool inp_DailyCloseDeletePendings = true; // Delete pending orders at daily close
input bool inp_DailyCloseClosePositions = true; // Close positions at daily close
input bool inp_UseFridayCloseProtection = true; // Friday Close Protection
input bool inp_UseManualFridayCloseTime = true; // Friday close time
input int inp_FridayCloseHour = 15; // Friday close hour
input int inp_FridayCloseMinute = 25; // Friday close minute
input bool inp_FridayCloseDeletePendings = true; // Delete Pending Orders on Friday
input bool inp_FridayCloseClosePositions = true; // Close Open Positions on Friday

input group "OPTIONAL TIME SETTINGS"
input bool inp_UseAutoBrokerGMTOffset = false; // Auto Detect Broker GMT Offset
input int inp_ManualBrokerGMTOffset = 2; // Manual Broker GMT Offset
input bool inp_UseBrokerEarlyCloseDetection = false; // Broker Early/Holiday Close Detection
input int inp_EarlyCloseProtectionMinutes = 30; // Minutes Before Broker Session Close
input bool inp_ShowPanel = true; // Show Info Panel On Chart

input group "EXPERT SETTINGS"
input int inp_MagicNo = 888777; // Magic Number
input string inp_TradeComment = "@fundedtoday SGH 5 MQLume"; // Trade Comment (single-profile mode)

input group "MULTI-PROFILE / PORTFOLIO MODE"
input bool inp_UseMultiProfileMode = false; // Multi-Profile Mode (OFF = single profile)
input double inp_PortfolioMaxDirectionalRiskPercent = 3.0; // Max Combined Risk Per Buy/Sell Side % (0=off)
input bool inp_PortfolioSLFromExecution = false; // Recalculate SL From Execution
input bool inp_PortfolioFalseInitialSL = false; // False Initial SL
input double inp_PortfolioFalseSLPoints = 1000.0; // False SL Distance (points)
input bool inp_PortfolioUseStriker = false; // Enable Striker
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioStrikerLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Striker Lot Method
input double inp_PortfolioStrikerRiskPercent = 1.0; // Striker Risk % Per Trade
input double inp_PortfolioStrikerFixedLot = 0.01; // Striker Fixed Lot
input bool inp_PortfolioUseUltimateScalper = false; // Enable Ultimate Scalper
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioUltimateLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Ultimate Scalper Lot Method
input double inp_PortfolioUltimateRiskPercent = 1.0; // Ultimate Scalper Risk % Per Trade
input double inp_PortfolioUltimateFixedLot = 0.01; // Ultimate Scalper Fixed Lot
input bool inp_PortfolioUseScalper = false; // Enable Classic Scalper
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioScalperLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Classic Scalper Lot Method
input double inp_PortfolioScalperRiskPercent = 1.0; // Classic Scalper Risk % Per Trade
input double inp_PortfolioScalperFixedLot = 0.01; // Classic Scalper Fixed Lot
input bool inp_PortfolioUsePRRScalping = false; // Enable Positive RR
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioPRRLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Positive RR Lot Method
input double inp_PortfolioPRRRiskPercent = 1.0; // Positive RR Risk % Per Trade
input double inp_PortfolioPRRFixedLot = 0.01; // Positive RR Fixed Lot
input bool inp_PortfolioUseSwinger = false; // Enable Swinger
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioSwingerLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Swinger Lot Method
input double inp_PortfolioSwingerRiskPercent = 1.0; // Swinger Risk % Per Trade
input double inp_PortfolioSwingerFixedLot = 0.01; // Swinger Fixed Lot
input bool inp_PortfolioUsePropScalper = false; // Enable Prop Firm Scalper
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioPropLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Prop Firm Scalper Lot Method
input double inp_PortfolioPropRiskPercent = 1.0; // Prop Firm Scalper Risk % Per Trade
input double inp_PortfolioPropFixedLot = 0.01; // Prop Firm Scalper Fixed Lot
input bool inp_PortfolioUseCustom = false; // Enable Custom Profile
input SGH_PORTFOLIO_LOT_METHOD inp_PortfolioCustomLotMethod = SGH_PORTFOLIO_FIXED_LOTS; // Custom Lot Method
input double inp_PortfolioCustomRiskPercent = 1.0; // Custom Risk % Per Trade
input double inp_PortfolioCustomFixedLot = 0.01; // Custom Fixed Lot

#endif // SMART_GOLD_HUNTER_INPUTS_MQH


// Single-mode repairs use the shared execution request and result.
bool HunterUpdateSingleStops(const ulong ticket,double sl,double tp);
// Effective settings loaded into the shared hunter_profile below.
// Distance fields use HunterPip() units, not necessarily the raw _Point.
// expiration_hours is in hours; pause_seconds is in seconds.
struct HunterProfile
{
   ENUM_TIMEFRAMES timeframe;
   int expiration_hours,
      depth,
      pause_seconds;
   double take_profit,
      stop_loss,
      trail_start,
      trail_distance,
      entry_offset;
   double break_even_trigger,
      break_even_lock;
   bool prop_mode,
      use_deviation,
      use_backstep;
};
struct HunterQueuedSignal
{
   bool active;
   int profile;
   bool buy;
   ENUM_ORDER_TYPE type;
   // volume: lots; entry/sl/tp/risk_sl: absolute prices.
   // sl is the submitted stop; risk_sl retains the intended sizing stop.
   double volume,
      entry,
      sl,
      tp,
      risk_sl;
   datetime created,
      expires;
};
// Shared mutable effective profile. Loaders overwrite it, including loaders
// reached by directional-risk fallback. Do not cache or restore it implicitly.
HunterProfile hunter_profile;
HunterQueuedSignal hunter_queue[14];
// Bars() latch per profile: consumed before pivot and order-gate evaluation.
int hunter_profile_bar_count[7];
bool hunter_buy_seen[7],hunter_sell_seen[7];
ulong hunter_adjusted_tickets[],hunter_prop_initial_tickets[];
bool hunter_prop_delay_enabled=true;
double hunter_pivots[],hunter_high_pivots[],hunter_low_pivots[];

void HunterInitializeStrategy()
{
   ZeroMemory(hunter_queue);
   ArrayInitialize(hunter_profile_bar_count,-1);
   ArrayInitialize(hunter_buy_seen,false);
   ArrayInitialize(hunter_sell_seen,false);
   ArrayResize(hunter_adjusted_tickets,0);
   ArrayResize(hunter_prop_initial_tickets,0);
   hunter_prop_delay_enabled=true;
}

// Price increment used by strategy distances: 10 raw points on 3/5 digits.
double HunterPip()
{
   return _Point*((_Digits==3 || _Digits==5)?10.0:1.0);
}

double HunterDecimalRound(const double value,const int digits)
{
   // Decimal rounding includes a small tolerance at half-step ties.
   const double factor=MathPow(10.0,MathMin(digits,11));
   const long integral=(long)value;
   return (double)(long)((value-(double)integral)*factor+(value>0.0?0.5000001:-0.5000001))/factor+(double)integral;
}

// Round to the tick size, then normalize to the symbol decimal precision.
double HunterNormalizePrice(double price)
{
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   if(tick>0.0) price=MathRound(price/tick)*tick;
   return HunterDecimalRound(price,_Digits);
}

double HunterSpreadPips() // Read Ask before Bid.
{
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   return (ask-bid)/HunterPip();
}

// Fixed volume is raised to the minimum before rounding down to the lot step.
double HunterClampVolume(double volume)
{
   const double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   const double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   volume=MathMax(minimum,volume);
   volume=MathMin(maximum,volume);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0) step=0.01;
   volume=HunterDecimalRound(MathFloor(volume/step)*step,2);
   return volume<minimum?0.0:volume;
}

// Risk volume must not be increased to the broker minimum.
double HunterRiskVolume(double volume)
{
   const double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   const double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(volume<=0.0 || minimum<=0.0 || volume+1.0e-12<minimum) return 0.0;
   if(step<=0.0) step=0.01;
   volume=HunterDecimalRound(MathFloor(MathMin(volume,maximum)/step)*step,2);
   return volume<minimum?0.0:volume;
}

// Use 98% of free margin, with a calculation fallback and bounded lot reductions.
double HunterFitMargin(const ENUM_ORDER_TYPE type,double volume,const double price,string &reason)
{
   volume=HunterClampVolume(volume);
   if(volume<=0.0)
   {
      reason="Volume below minimum";
      return 0.0;
   }
   double available=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(available<=0.0)
   {
      reason="No free margin";
      return 0.0;
   }
   const double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0) step=0.01;
   available*=0.98;
   double margin=0.0;
   if(volume>=minimum)
   {
      for(int attempt=0;;attempt++)
      {
         if(!OrderCalcMargin(type,_Symbol,volume,price,margin) || margin<=0.0)
         {
            double contract=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE);
            long leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
            margin=(contract>0.0 && leverage>0)?volume*price*contract/(double)leverage:volume*price;
         }
         if(margin<=available) break;
         volume=HunterClampVolume(volume-step);
         // Check the previous counter against 1998 after each reduction.
         if(volume<minimum || attempt>1998) break;
      }
   }
   if(volume<minimum || margin>available)
   {
      reason="Not enough free margin";
      return 0.0;
   }
   reason="";
   return volume;
}

bool HunterValidatePending(const ENUM_ORDER_TYPE type,double &entry,double &sl,double &tp,string &reason)
{
   entry=HunterNormalizePrice(entry);
   if(sl>0.0) sl=HunterNormalizePrice(sl);
   if(tp>0.0) tp=HunterNormalizePrice(tp);
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   const double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const int stops=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const int freeze=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double limit=MathMax(stops,freeze)*_Point;
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   if(type==ORDER_TYPE_BUY_STOP)
   {
      if(entry<=ask+limit)
      {
         reason="Buy Stop too close to Ask";
         return false;
      }
      if(sl>0.0)
      {
         if(sl>=entry-tick)
         {
            reason="Buy Stop SL invalid side";
            return false;
         }
         if(entry-sl<limit)
         {
            reason="Buy Stop SL too close";
            return false;
         }
      }
      if(tp<=0.0) return true;
      if(tp<=entry+tick)
      {
         reason="Buy Stop TP invalid side";
         return false;
      }
      if(tp-entry<limit)
      {
         reason="Buy Stop TP too close";
         return false;
      }
      return true;
   }
   if(type==ORDER_TYPE_SELL_STOP)
   {
      if(entry>=bid-limit)
      {
         reason="Sell Stop too close to Bid";
         return false;
      }
      if(sl>0.0)
      {
         if(sl<=entry+tick)
         {
            reason="Sell Stop SL invalid side";
            return false;
         }
         if(sl-entry<limit)
         {
            reason="Sell Stop SL too close";
            return false;
         }
      }
      if(tp<=0.0) return true;
      if(tp>=entry-tick)
      {
         reason="Sell Stop TP invalid side";
         return false;
      }
      if(entry-tp<limit)
      {
         reason="Sell Stop TP too close";
         return false;
      }
      return true;
   }
   reason="Unsupported pending type";
   return false;
}

// Missing session metadata falls back to trade modes 1 through 4.
bool HunterTradingSessionOpen(const string symbol)
{
   datetime now=TimeTradeServer();
   if(now==0) now=TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now,t);
   const int second=t.hour*3600+t.min*60+t.sec;
   datetime from,to;
   if(!SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)t.day_of_week,0,from,to))
   {
      const long mode=SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
      return mode>=1 && mode<=4;
   }
   for(int session=0;session<10;session++)
   {
      MqlDateTime start,end;
      TimeToStruct(from,start);
      TimeToStruct(to,end);
      const int first=start.hour*3600+start.min*60+start.sec;
      const int last=end.hour*3600+end.min*60+end.sec;
      if(last<first)
      {
         if(second>=first || second<last) return true;
      }
      else if(second>=first && second<last) return true;
      if(session==9 || !SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)t.day_of_week,session+1,from,to)) break;
   }
   return false;
}

bool HunterTicketMarked(const ulong &tickets[],const ulong ticket)
{
   for(int i=0;i<ArraySize(tickets);i++) if(tickets[i]==ticket) return true;
   return false;
}
void HunterMarkTicket(ulong &tickets[],const ulong ticket)
{
   if(HunterTicketMarked(tickets,ticket)) return;
   const int size=ArraySize(tickets);
   ArrayResize(tickets,size+1);
   tickets[size]=ticket;
}
void HunterMarkAdjusted(const ulong ticket)
{
   HunterMarkTicket(hunter_adjusted_tickets,ticket);
}
void HunterMarkPropInitial(const ulong ticket)
{
   HunterMarkTicket(hunter_prop_initial_tickets,ticket);
}

// Overwrites hunter_profile; downstream pivot and management helpers read it.
// Array indices: Striker, Ultimate, Classic, Swinger, Prop Firm, Positive RR, Custom.
void HunterLoadPortfolioProfile(const int mode)
{
   const int tf[7]={30,15,15,15,15,30,0};
   const int depth[7]={18,20,18,12,18,18,12};
   const int expiry[7]={8,8,12,27000,12,12,27000};
   const double tp[7]={1750,1500,1500,4500,2500,2250,250};
   const double sl[7]={425,300,300,2500,350,325,500};
   const double trail_start[7]={525,130,140,1500,165,575,100};
   const double trail_stop[7]={150,50,50,500,40,165,50};
   const double offset[7]={-150,-200,-175,50,-150,-190,0};
   const int p=(mode>=0 && mode<7)?mode:6;
   hunter_profile.timeframe=(ENUM_TIMEFRAMES)tf[p];
   hunter_profile.expiration_hours=expiry[p];
   hunter_profile.depth=depth[p];
   hunter_profile.take_profit=tp[p];
   hunter_profile.stop_loss=sl[p];
   hunter_profile.trail_start=trail_start[p];
   hunter_profile.trail_distance=trail_stop[p];
   hunter_profile.entry_offset=offset[p];
   hunter_profile.pause_seconds=p==6?300:60;
   hunter_profile.prop_mode=p==4;
   hunter_profile.use_deviation=true;
   hunter_profile.use_backstep=true;
   hunter_profile.break_even_trigger=80.0;
   hunter_profile.break_even_lock=10.0;
}

void HunterLoadSingleProfile()
{
   HunterLoadPortfolioProfile((int)inp_Mode);
   const double offset[6]={-185,-175,-160,50,-150,-175};
   int mode=(int)inp_Mode;
   if(mode>=0 && mode<6) hunter_profile.entry_offset=offset[mode];
   else
   {
      hunter_profile.take_profit=inp_TP;
      hunter_profile.stop_loss=inp_SL;
      hunter_profile.trail_start=inp_TrailStart;
      hunter_profile.trail_distance=inp_TrailStop;
      hunter_profile.pause_seconds=inp_Pause;
      hunter_profile.entry_offset=inp_CustomPointsAway;
   }
}

long HunterPortfolioMagic(const int profile)
{
   const long magic[7]={777771,777777,777772,777774,777775,777773,777776};
   return profile>=0 && profile<7?magic[profile]:777770;
}
int HunterPortfolioModeFromMagic(const long magic)
{
   const int mode[7]={0,2,5,3,4,6,1};
   return magic>=777771 && magic<=777777?mode[(int)(magic-777771)]:-1;
}
bool HunterPortfolioEnabled(const int mode)
{
   switch(mode)
   {
      case 0:return inp_PortfolioUseStriker;
      case 1:return inp_PortfolioUseUltimateScalper;
      case 2:return inp_PortfolioUseScalper;
      case 3:return inp_PortfolioUseSwinger;
      case 4:return inp_PortfolioUsePropScalper;
      case 5:return inp_PortfolioUsePRRScalping;
      case 6:return inp_PortfolioUseCustom;
   }
   return false;
}
void HunterPortfolioLotSettings(const int mode,int &method,double &risk,double &fixed)
{
   method=0;
   risk=0.0;
   fixed=0.01;
   switch(mode)
   {
      case 0:method=(int)inp_PortfolioStrikerLotMethod;
      risk=inp_PortfolioStrikerRiskPercent;
      fixed=inp_PortfolioStrikerFixedLot;
      break;
      case 1:method=(int)inp_PortfolioUltimateLotMethod;
      risk=inp_PortfolioUltimateRiskPercent;
      fixed=inp_PortfolioUltimateFixedLot;
      break;
      case 2:method=(int)inp_PortfolioScalperLotMethod;
      risk=inp_PortfolioScalperRiskPercent;
      fixed=inp_PortfolioScalperFixedLot;
      break;
      case 3:method=(int)inp_PortfolioSwingerLotMethod;
      risk=inp_PortfolioSwingerRiskPercent;
      fixed=inp_PortfolioSwingerFixedLot;
      break;
      case 4:method=(int)inp_PortfolioPropLotMethod;
      risk=inp_PortfolioPropRiskPercent;
      fixed=inp_PortfolioPropFixedLot;
      break;
      case 5:method=(int)inp_PortfolioPRRLotMethod;
      risk=inp_PortfolioPRRRiskPercent;
      fixed=inp_PortfolioPRRFixedLot;
      break;
      case 6:method=(int)inp_PortfolioCustomLotMethod;
      risk=inp_PortfolioCustomRiskPercent;
      fixed=inp_PortfolioCustomFixedLot;
      break;
   }
}

double HunterRandomOffset()
{
   if(!inp_UltimateEntryRandomizer) return 0.0;
   const int magnitude=10+(MathRand()%3)*5;
   return (MathRand()%2)==0?-magnitude:magnitude;
}
double HunterPortfolioRandomOffset(const int mode)
{
   return mode>=0 && mode<7?HunterRandomOffset():0.0;
}
double HunterPortfolioEntryOffset(const int mode)
{
   const double offset[7]={-150,-200,-175,50,-150,-190,0};
   return mode>=0 && mode<7?offset[mode]:0.0;
}

double HunterRiskMoney(const double volume,const double entry,const double sl)
{
   if(volume<=0.0 || entry<=0.0 || sl<=0.0) return 0.0;
   double profit=0.0;
   if(OrderCalcProfit(entry<=sl?ORDER_TYPE_SELL:ORDER_TYPE_BUY,_Symbol,volume,entry,sl,
      profit)) return MathAbs(profit);
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   const double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(tick<=0.0) tick=_Point;
   if(tick<=0.0 || tick_value<=0.0) return -1.0;
   return tick_value*(MathAbs(entry-sl)/tick)*volume;
}

// Risk-mode public OrderCalcProfit path supersedes an earlier tick-value estimate.
double HunterPortfolioVolume(const int profile,const double sl_distance,const ENUM_ORDER_TYPE type,
   const double entry,const double sl)
{
   int method;
   double risk,fixed;
   HunterPortfolioLotSettings(profile,method,risk,fixed);
   if(method!=1) return HunterClampVolume(fixed);
   if(risk<=0.0 || sl_distance<=0.0) return 0.0;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0 || equity*risk/100.0<=0.0) return 0.0;
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(tick<=0.0) tick=_Point;
   if(tick>0.0 && tick_value>0.0)
   {
      double estimated=tick_value*((HunterPip()*sl_distance)/tick);
      if(estimated>0.0) HunterRiskVolume((equity*risk/100.0)/estimated);
   }
   equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0) return 0.0;
   double budget=risk*equity/100.0;
   if(budget<=0.0 || entry<=0.0 || sl<=0.0 || entry==sl) return 0.0;
   double profit=0.0;
   ResetLastError();
   ENUM_ORDER_TYPE side=(type==ORDER_TYPE_BUY_LIMIT
      || type==ORDER_TYPE_BUY_STOP)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   if(!OrderCalcProfit(side,_Symbol,1.0,entry,sl,profit) || profit==0.0) return 0.0;
   const double volume=HunterRiskVolume(budget/MathAbs(profit));
   return volume>0.0?volume:0.0;
}

double HunterSingleVolume(const ENUM_ORDER_TYPE type,const double entry,const double sl)
{
   const int method=(int)inp_LotMethod;
   if(method==2)
   {
      if(inp_BalancePer001Lot<=0.0) return 0.0;
      const double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      if(balance<=0.0) return 0.0;
      return HunterDecimalRound(HunterClampVolume(balance/inp_BalancePer001Lot*0.01),2);
   }
   if(method==0) return HunterDecimalRound(HunterClampVolume(inp_Lots),2);
   double estimate=0.0;
   const double distance=hunter_profile.stop_loss*(hunter_profile.prop_mode?2.0:1.0);
   if(distance>0.0)
   {
      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      const double budget=equity*(inp_RiskPercent/100.0);
      if(equity>0.0 && budget>0.0)
      {
         double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
         double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
         if(tick<=0.0) tick=_Point;
         if(tick>0.0 && tick_value>0.0)
         {
            const double loss=tick_value*((distance*HunterPip())/tick);
            if(loss>0.0) estimate=HunterDecimalRound(HunterRiskVolume(budget/loss),2);
         }
      }
   }
   if(method!=1) return estimate;
   if(inp_RiskPercent<=0.0) return 0.0;
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0) return 0.0;
   const double budget=inp_RiskPercent*equity/100.0;
   if(budget<=0.0 || entry<=0.0 || sl<=0.0 || entry==sl) return 0.0;
   double profit=0.0;
   ResetLastError();
   ENUM_ORDER_TYPE side=(type==ORDER_TYPE_BUY_LIMIT
      || type==ORDER_TYPE_BUY_STOP)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   if(!OrderCalcProfit(side,_Symbol,1.0,entry,sl,profit) || profit==0.0) return 0.0;
   const double volume=HunterRiskVolume(budget/MathAbs(profit));
   return volume>0.0?volume:0.0;
}

bool HunterValidateStops(const ulong ticket,double &sl,double &tp,string &reason)
{
   if(!PositionSelectByTicket(ticket))
   {
      reason="Position not found";
      return false;
   }
   const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   const double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   const int stops=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const int freeze=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double old_sl=PositionGetDouble(POSITION_SL),old_tp=PositionGetDouble(POSITION_TP);
   if(sl>0.0) sl=HunterNormalizePrice(sl);
   if(tp>0.0) tp=HunterNormalizePrice(tp);
   const double safety=MathMax(stops,freeze)*_Point+tick+tick;
   if(type==POSITION_TYPE_BUY)
   {
      if(sl>0.0)
      {
         const double bound=HunterNormalizePrice(bid-safety);
         if(bound<=0.0 || bound>=bid-tick)
         {
            reason="Buy SL cannot be placed safely now";
            return false;
         }
         if(sl>bound) sl=bound;
      }
      if(tp>0.0)
      {
         const double bound=HunterNormalizePrice(bid+safety);
         if(bound<=bid+tick)
         {
            reason="Buy TP cannot be placed safely now";
            return false;
         }
         if(tp<bound) tp=bound;
      }
   }
   else if(type==POSITION_TYPE_SELL)
   {
      if(sl>0.0)
      {
         const double bound=HunterNormalizePrice(ask+safety);
         if(bound<=ask+tick)
         {
            reason="Sell SL cannot be placed safely now";
            return false;
         }
         if(sl<bound) sl=bound;
      }
      if(tp>0.0)
      {
         const double bound=HunterNormalizePrice(ask-safety);
         if(bound<=0.0 || bound>=ask-tick)
         {
            reason="Sell TP cannot be placed safely now";
            return false;
         }
         if(tp>bound) tp=bound;
      }
   }
   else
   {
      reason="Unsupported position type";
      return false;
   }
   const bool same_sl=(sl==0.0 && old_sl==0.0) || MathAbs(sl-old_sl)<=HunterPip()*0.1;
   const bool same_tp=(tp==0.0 && old_tp==0.0) || MathAbs(tp-old_tp)<=HunterPip()*0.1;
   if(same_sl && same_tp)
   {
      reason="No effective stop change";
      return false;
   }
   return true;
}

bool HunterModifyStops(const ulong ticket,double sl,double tp)
{
   if(!PositionSelectByTicket(ticket)) return false;
   string reason="";
   if(!HunterValidateStops(ticket,sl,tp,reason)) return false;
   MqlTradeRequest request={};
   MqlTradeResult result={};
   request.action=TRADE_ACTION_SLTP;
   request.position=ticket;
   request.symbol=PositionGetString(POSITION_SYMBOL);
   request.magic=(ulong)PositionGetInteger(POSITION_MAGIC);
   request.sl=sl;
   request.tp=tp;
   return OrderSend(request,result) && (result.retcode==10009 || result.retcode==10010);
}

void HunterCountProfileOrders(const int profile,int &buys,int &sells,int &buy_stops,int &sell_stops)
{
   buys=0;
   sells=0;
   buy_stops=0;
   sell_stops=0;
   const long magic=HunterPortfolioMagic(profile);
   for(int i=0;i<PositionsTotal();i++)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol || PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      const long type=PositionGetInteger(POSITION_TYPE);
      if(type==POSITION_TYPE_BUY) buys++;
      else if(type==POSITION_TYPE_SELL) sells++;
   }
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol || OrderGetInteger(ORDER_MAGIC)!=magic) continue;
      const long type=OrderGetInteger(ORDER_TYPE);
      if(type==ORDER_TYPE_BUY_STOP) buy_stops++;
      else if(type==ORDER_TYPE_SELL_STOP) sell_stops++;
   }
}

bool HunterHasNearbyProfileOrder(const int profile,const double entry)
{
   const long magic=HunterPortfolioMagic(profile);
   const double range=HunterPip()*50.0;
   for(int i=0;i<PositionsTotal();i++)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol || PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      const double price=PositionGetDouble(POSITION_PRICE_OPEN);
      if(entry>=price-range && entry<=price+range) return true;
   }
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol || OrderGetInteger(ORDER_MAGIC)!=magic) continue;
      const double price=OrderGetDouble(ORDER_PRICE_OPEN);
      if(entry>=price-range && entry<=price+range) return true;
   }
   return false;
}

// Computes existing portfolio directional risk, preserving profile-loader side effects.
double HunterExistingDirectionalRisk(const bool buy)
{
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0) return 0.0;
   double money=0.0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i)==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      const long magic=OrderGetInteger(ORDER_MAGIC);
      if(!inp_UseMultiProfileMode || magic<777771 || magic>777777) continue;
      const ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(buy ? (type!=ORDER_TYPE_BUY_LIMIT && type!=ORDER_TYPE_BUY_STOP) : (type!=ORDER_TYPE_SELL_LIMIT
         && type!=ORDER_TYPE_SELL_STOP)) continue;
      const double entry=OrderGetDouble(ORDER_PRICE_OPEN);
      double sl=OrderGetDouble(ORDER_SL);
      if(sl<=0.0)
      {
         const int mode=HunterPortfolioModeFromMagic(magic);
         HunterLoadPortfolioProfile(mode);
         const double distance=hunter_profile.stop_loss*(mode==4?2.0:1.0)*HunterPip();
         sl=buy?entry-distance:entry+distance;
      }
      const double risk=HunterRiskMoney(OrderGetDouble(ORDER_VOLUME_CURRENT),entry,sl);
      if(risk<0.0) return -1.0;
      money+=risk;
   }
   for(int i=0;i<PositionsTotal();i++)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket) || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      const long magic=PositionGetInteger(POSITION_MAGIC);
      if(!inp_UseMultiProfileMode || magic<777771 || magic>777777) continue;
      const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(buy!=(type==POSITION_TYPE_BUY)) continue;
      const double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      if(sl<=0.0)
      {
         const int mode=HunterPortfolioModeFromMagic(magic);
         HunterLoadPortfolioProfile(mode);
         const double distance=hunter_profile.stop_loss*(mode==4?2.0:1.0)*HunterPip();
         sl=type==POSITION_TYPE_BUY?entry-distance:entry+distance;
      }
      double risk=0.0;
      if(sl>0.0 && (type==POSITION_TYPE_BUY?sl<entry:sl>entry))
      {
         risk=HunterRiskMoney(PositionGetDouble(POSITION_VOLUME),entry,sl);
         if(risk<0.0) return -1.0;
      }
      money+=MathMax(0.0,risk);
   }
   return money/equity*100.0;
}

bool HunterDirectionalRiskAllowed(const bool buy,const double volume,const double entry,
   const double risk_sl,string &reason)
{
   const double maximum=inp_PortfolioMaxDirectionalRiskPercent;
   if(maximum<=0.0) return true;
   const double existing=HunterExistingDirectionalRisk(buy);
   if(existing<0.0)
   {
      reason="risk data not ready";
      return false;
   }
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   const double money=HunterRiskMoney(volume,entry,risk_sl);
   if(money<0.0 || equity<=0.0)
   {
      reason="risk data not ready";
      return false;
   }
   const double next=money/equity*100.0;
   if(existing+next>maximum+1.0e-6)
   {
      reason=StringFormat("directional risk %.2f%% + %.2f%% > %.2f%%",existing,next,maximum);
      return false;
   }
   return true;
}

// Recalculate the chronological pivot arrays on each lookup.
double HunterPivotAt(const int shift)
{
   MqlRates rates[];
   const int count=CopyRates(NULL,hunter_profile.timeframe,0,300,rates);
   const int depth=hunter_profile.depth;
   if(count<=shift+5+depth) return 0.0;
   ArrayResize(hunter_pivots,count);
   ArrayInitialize(hunter_pivots,0.0);
   ArrayResize(hunter_high_pivots,count);
   ArrayInitialize(hunter_high_pivots,0.0);
   ArrayResize(hunter_low_pivots,count);
   ArrayInitialize(hunter_low_pivots,0.0);
   const double deviation=hunter_profile.use_deviation?5.0:0.0;
   double last_low=0.0,last_high=0.0;
   for(int i=depth;i<count;i++)
   {
      int lowest=i,highest=i;
      for(int j=i-1;j>i-depth;j--)
      {
         if(rates[j].low<rates[lowest].low) lowest=j;
         if(rates[j].high>rates[highest].high) highest=j;
      }
      double value=rates[lowest].low;
      double candidate=0.0;
      if(value!=last_low)
      {
         last_low=value;
         if(rates[i].low-value<=HunterPip()*deviation)
         {
            candidate=value;
            if(hunter_profile.use_backstep)
               for(int back=1;back<=3 && i-back>=0;back++)
                  if(hunter_low_pivots[i-back]!=0.0
                     && value<hunter_low_pivots[i-back]) hunter_low_pivots[i-back]=0.0;
         }
      }
      hunter_low_pivots[i]=rates[i].low==candidate?candidate:0.0;
      value=rates[highest].high;
      candidate=0.0;
      if(value!=last_high)
      {
         last_high=value;
         if(value-rates[i].high<=HunterPip()*deviation)
         {
            candidate=value;
            if(hunter_profile.use_backstep)
               for(int back=1;back<=3 && i-back>=0;back++)
                  if(hunter_high_pivots[i-back]!=0.0
                     && hunter_high_pivots[i-back]<value) hunter_high_pivots[i-back]=0.0;
         }
      }
      hunter_high_pivots[i]=rates[i].high==candidate?candidate:0.0;
   }
   int seeking=0,last_high_index=0,last_low_index=0;
   last_high=0.0;
   last_low=0.0;
   for(int i=depth;i<count;i++)
   {
      if(seeking==0)
      {
         if(last_low==0.0 && last_high==0.0)
         {
            if(hunter_high_pivots[i]!=0.0)
            {
               last_high=hunter_high_pivots[i];
               last_high_index=i;
               hunter_pivots[i]=last_high;
               seeking=-1;
            }
            if(hunter_low_pivots[i]!=0.0)
            {
               last_low=hunter_low_pivots[i];
               last_low_index=i;
               hunter_pivots[i]=last_low;
               seeking=1;
            }
         }
      }
      else if(seeking==1)
      {
         if(hunter_low_pivots[i]!=0.0 && hunter_low_pivots[i]<last_low && hunter_high_pivots[i]==0.0)
         {
            hunter_pivots[last_low_index]=0.0;
            last_low=hunter_low_pivots[i];
            last_low_index=i;
            hunter_pivots[i]=last_low;
         }
         if(hunter_high_pivots[i]!=0.0 && hunter_low_pivots[i]==0.0)
         {
            last_high=hunter_high_pivots[i];
            last_high_index=i;
            hunter_pivots[i]=last_high;
            seeking=-1;
         }
      }
      else if(seeking==-1)
      {
         if(hunter_high_pivots[i]!=0.0 && hunter_high_pivots[i]>last_high && hunter_low_pivots[i]==0.0)
         {
            hunter_pivots[last_high_index]=0.0;
            last_high=hunter_high_pivots[i];
            last_high_index=i;
            hunter_pivots[i]=last_high;
         }
         if(hunter_low_pivots[i]!=0.0 && hunter_high_pivots[i]==0.0)
         {
            last_low=hunter_low_pivots[i];
            last_low_index=i;
            hunter_pivots[i]=last_low;
            seeking=1;
         }
      }
   }
   const int index=count-1-shift;
   return index>=0 && index<count?hunter_pivots[index]:0.0;
}

// Queue slots are profile * 2 + direction (buy 0, sell 1). An unexpired
// active candidate is retained; a new candidate does not replace it early.
void HunterQueueSignal(const int profile,const bool buy,const ENUM_ORDER_TYPE type,const double volume,
   const double entry,const double sl,const double tp,const double risk_sl,const datetime expires)
{
   const int slot=profile*2+(buy?0:1);
   if(hunter_queue[slot].active && TimeCurrent()<hunter_queue[slot].expires) return;
   hunter_queue[slot].active=true;
   hunter_queue[slot].profile=profile;
   hunter_queue[slot].buy=buy;
   hunter_queue[slot].type=type;
   hunter_queue[slot].volume=volume;
   hunter_queue[slot].entry=entry;
   hunter_queue[slot].sl=sl;
   hunter_queue[slot].tp=tp;
   hunter_queue[slot].risk_sl=risk_sl;
   hunter_queue[slot].created=TimeCurrent();
   hunter_queue[slot].expires=expires;
}

bool HunterQueuedSignalValid(const int slot)
{
   if(slot<0 || slot>=14 || !hunter_queue[slot].active || !inp_UseMultiProfileMode) return false;
   HunterQueuedSignal signal=hunter_queue[slot];
   if(signal.profile<0 || signal.profile>=7 || !HunterPortfolioEnabled(signal.profile)) return false;
   if(signal.expires>0 && signal.expires<=TimeCurrent()) return false;
   int buys,sells,buy_stops,sell_stops;
   HunterCountProfileOrders(signal.profile,buys,sells,buy_stops,sell_stops);
   if(signal.buy?(buys+buy_stops>0):(sells+sell_stops>0)) return false;
   if(HunterHasNearbyProfileOrder(signal.profile,signal.entry)) return false;
   // Validate local copies while keeping the stored queue fields unchanged.
   string reason="";
   return HunterValidatePending(signal.type,signal.entry,signal.sl,signal.tp,reason);
}

double HunterQueuedRiskPercent(const int slot)
{
   if(slot<0 || slot>=14 || !hunter_queue[slot].active) return 1.0e100;
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0) return 1.0e100;
   const double money=HunterRiskMoney(hunter_queue[slot].volume,hunter_queue[slot].entry,
      hunter_queue[slot].risk_sl);
   if(money<0.0) return 1.0e100;
   return money/equity*100.0;
}

double HunterQueuedDistance(const int slot)
{
   MqlTick tick;
   if(slot<0 || slot>=14 || !hunter_queue[slot].active || !SymbolInfoTick(_Symbol,tick)) return 1.0e100;
   return MathAbs(hunter_queue[slot].entry-(hunter_queue[slot].buy?tick.ask:tick.bid));
}

// Selection priority: nearest entry; within price tolerance, lower risk;
// within risk tolerance, lower profile index (equal indices also swap).
// Distance/risk helpers are evaluated separately in the required order.
// Each candidate is revalidated before risk admission and submission.
void HunterSendQueuedDirection(const bool buy)
{
   int selected[14];
   int count=0;
   for(int slot=0;slot<14;slot++)
   {
      if(!hunter_queue[slot].active || hunter_queue[slot].buy!=buy) continue;
      if(!HunterQueuedSignalValid(slot)) hunter_queue[slot].active=false;
      else selected[count++]=slot;
   }
   for(int i=0;i<count-1;i++)
   {
      for(int j=i+1;j<count;j++)
      {
         const int first=selected[i],second=selected[j];
         const double first_distance=HunterQueuedDistance(first),second_distance=HunterQueuedDistance(second);
         const double tolerance=MathMax(HunterPip(),SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE));
         bool swap=false;
         if(MathAbs(first_distance-second_distance)<=tolerance)
         {
            const double first_risk_percent=HunterQueuedRiskPercent(first),
               second_risk_percent=HunterQueuedRiskPercent(second);
            if(MathAbs(first_risk_percent-second_risk_percent)<=1.0e-6) swap=hunter_queue[second].profile<=hunter_queue[first].profile;
            else swap=second_risk_percent<=first_risk_percent;
         }
         else swap=second_distance<=first_distance;
         if(swap)
         {
            selected[i]=second;
            selected[j]=first;
         }
      }
   }
   for(int i=0;i<count;i++)
   {
      const int slot=selected[i];
      if(!hunter_queue[slot].active) continue;
      if(!HunterQueuedSignalValid(slot))
      {
         hunter_queue[slot].active=false;
         continue;
      }
      const HunterQueuedSignal signal=hunter_queue[slot];
      string reason="";
      if(!HunterDirectionalRiskAllowed(signal.buy,signal.volume,signal.entry,signal.risk_sl,reason)) continue;
      MqlTradeRequest request={};
      MqlTradeResult result={};
      MqlTradeCheckResult check={};
      request.action=TRADE_ACTION_PENDING;
      request.symbol=_Symbol;
      request.magic=(ulong)HunterPortfolioMagic(signal.profile);
      request.type=signal.type;
      request.volume=signal.volume;
      request.price=signal.entry;
      request.sl=signal.sl;
      request.tp=signal.tp;
      request.deviation=0;
      const long expiration=SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_MODE);
      request.type_time=(expiration&4)!=0
         ? ORDER_TIME_SPECIFIED
         : ((expiration&1)!=0?ORDER_TIME_GTC:ORDER_TIME_DAY);
      request.expiration=(expiration&4)!=0?signal.expires:0;
      const string comments[7]={"@fundedtoday P-STR","@fundedtoday P-ULT","@fundedtoday P-CLS",
         "@fundedtoday P-SWG","@fundedtoday P-PFS","@fundedtoday P-PRR","@fundedtoday P-CUS"};
      request.comment=(signal.profile>=0 && signal.profile<7)?comments[signal.profile]:"@fundedtoday P";
      const long filling=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
      request.type_filling=(filling&2)!=0
         ? ORDER_FILLING_IOC
         : ((filling&1)!=0?ORDER_FILLING_FOK:ORDER_FILLING_RETURN);
      if(OrderCheck(request,check) && OrderSend(request,result) && (result.retcode==10008
         || result.retcode==10009)) hunter_queue[slot].active=false;
   }
}

void HunterGeneratePortfolioSignal(const int mode)
{
   if(!inp_UseMultiProfileMode || mode<0 || mode>=7 || !HunterPortfolioEnabled(mode)) return;
   HunterLoadPortfolioProfile(mode);
   // History failure bypasses this cooldown block; it does not stop signal evaluation.
   if(HistorySelect(0,TimeCurrent()))
   {
      datetime latest_exit=0;
      const long magic=HunterPortfolioMagic(mode);
      for(int i=HistoryDealsTotal()-1;i>=0;i--)
      {
         const ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0 || HistoryDealGetString(ticket,DEAL_SYMBOL)!=_Symbol || HistoryDealGetInteger(ticket,
            DEAL_MAGIC)!=magic) continue;
         const long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY) continue;
         const datetime when=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         if(when>latest_exit) latest_exit=when;
      }
      if(latest_exit!=0 && TimeCurrent()-latest_exit<hunter_profile.pause_seconds) return;
   }
   const int bars=Bars(_Symbol,hunter_profile.timeframe);
   if(hunter_profile_bar_count[mode]==bars) return;
   // Latch before counting orders or reading pivots. A later return does not
   // roll this back; this function will skip another attempt at the same count.
   hunter_profile_bar_count[mode]=bars;
   int buys,sells,buy_stops,sell_stops;
   // Read terminal order state here, after management and the Bars latch.
   // No saved pre-management order count is substituted at this point.
   HunterCountProfileOrders(mode,buys,sells,buy_stops,sell_stops);
   if(buys>0) hunter_buy_seen[mode]=true;
   if(sells>0) hunter_sell_seen[mode]=true;
   int found=0;
   double older=0.0,newer=0.0;
   for(int shift=1;shift<=99;shift++)
   {
      if(older>0.0) newer=older;
      older=HunterPivotAt(shift);
      if(older>0.0) found++;
      if(found>1) break;
   }
   if(older==0.0 || newer==0.0) return;
   // Keep these separate quote queries and the later time query in place.
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const datetime now=TimeCurrent();
   const datetime expires=now+(datetime)hunter_profile.expiration_hours*3600;
   const double sl_distance=hunter_profile.stop_loss*(mode==4?2.0:1.0);
   const double tp_distance=hunter_profile.take_profit*(mode==4?2.0:1.0);
   bool buy;
   if(newer<older)
   {
      buy=true;
      hunter_sell_seen[mode]=false;
      if(older-ask<=HunterPip()*10.0 || hunter_buy_seen[mode] || buys+buy_stops>0) return;
   }
   else if(newer>older)
   {
      buy=false;
      hunter_buy_seen[mode]=false;
      if(bid-older<=HunterPip()*10.0 || hunter_sell_seen[mode] || sells+sell_stops>0) return;
   }
   else return;
   const int slot=mode*2+(buy?0:1);
   if(hunter_queue[slot].active && TimeCurrent()<hunter_queue[slot].expires) return;
   const double offset=HunterPortfolioEntryOffset(mode)+HunterPortfolioRandomOffset(mode);
   double entry=HunterNormalizePrice(older+(buy?1.0:-1.0)*HunterPip()*offset);
   if(HunterHasNearbyProfileOrder(mode,entry)) return;
   double risk_sl=0.0,tp=0.0;
   if(hunter_profile.stop_loss>0.0) risk_sl=HunterNormalizePrice(entry+(buy?-1.0:1.0)*HunterPip()*sl_distance);
   double actual_sl=risk_sl;
   if(mode!=3 && inp_PortfolioFalseInitialSL)
   {
      const double false_distance=MathMax(inp_PortfolioFalseSLPoints,sl_distance+1.0);
      actual_sl=HunterNormalizePrice(entry+(buy?-1.0:1.0)*HunterPip()*false_distance);
   }
   if(hunter_profile.take_profit>0.0) tp=HunterNormalizePrice(entry+(buy?1.0:-1.0)*HunterPip()*tp_distance);
   const ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP;
   string reason="";
   if(!HunterValidatePending(type,entry,actual_sl,tp,reason)) return;
   double sizing_sl=risk_sl;
   if(sizing_sl<=0.0) sizing_sl=HunterNormalizePrice(entry+(buy?-1.0:1.0)*HunterPip()*sl_distance);
   double volume=HunterPortfolioVolume(mode,sl_distance,type,entry,sizing_sl);
   if(volume<=0.0) return;
   volume=HunterFitMargin(type,volume,entry,reason);
   if(volume<=0.0) return;
   if(risk_sl<=0.0) risk_sl=HunterNormalizePrice(entry+(buy?-1.0:1.0)*HunterPip()*sl_distance);
   HunterQueueSignal(mode,buy,type,volume,entry,actual_sl,tp,risk_sl,expires);
}

// Manage portfolio entry-stop repair, prop delay, break-even and trailing stops.
void HunterManagePortfolioPosition(const ulong ticket,const int mode)
{
   if(!PositionSelectByTicket(ticket)) return;
   HunterLoadPortfolioProfile(mode);
   const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   const double open=PositionGetDouble(POSITION_PRICE_OPEN);
   double sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const bool buy=type==POSITION_TYPE_BUY;
   if(mode==4)
   {
      if((inp_PortfolioFalseInitialSL || inp_PortfolioSLFromExecution)
         && !HunterTicketMarked(hunter_prop_initial_tickets,ticket))
      {
         const double target=HunterNormalizePrice(open+(buy?-1.0:1.0)*HunterPip()*(hunter_profile.stop_loss+hunter_profile.stop_loss));
         bool mark=(sl>0.0 && (buy?sl>target:target>sl));
         if(!mark)
         {
            if(MathAbs(sl-target)>HunterPip())
            {
               if(HunterModifyStops(ticket,target,tp))
               {
                  mark=true;
                  PositionSelectByTicket(ticket);
                  sl=PositionGetDouble(POSITION_SL);
                  tp=PositionGetDouble(POSITION_TP);
               }
            }
            else mark=true;
         }
         if(mark) HunterMarkPropInitial(ticket);
      }
      const datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
      if(TimeCurrent()-opened<(hunter_prop_delay_enabled?120:0)) return;
      const double target_sl=HunterNormalizePrice(open+(buy?-1.0:1.0)*HunterPip()*hunter_profile.stop_loss);
      const double target_tp=HunterNormalizePrice(open+(buy?1.0:-1.0)*HunterPip()*hunter_profile.take_profit);
      if(!HunterTicketMarked(hunter_adjusted_tickets,ticket))
      {
         if(HunterModifyStops(ticket,target_sl,target_tp)) HunterMarkAdjusted(ticket);
         PositionSelectByTicket(ticket);
         sl=PositionGetDouble(POSITION_SL);
         tp=PositionGetDouble(POSITION_TP);
      }
   }
   else if(mode>=0 && mode<7 && ((mode!=3 && inp_PortfolioFalseInitialSL) || inp_PortfolioSLFromExecution))
   {
      if(!HunterTicketMarked(hunter_adjusted_tickets,ticket))
      {
         double anchor=open;
         if(mode!=3 && inp_PortfolioFalseInitialSL && !inp_PortfolioSLFromExecution)
         {
            const ulong identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
            // Select the historical records associated with this position.
            if(identifier!=0 && HistorySelectByPosition(identifier))
            {
               for(int i=HistoryOrdersTotal()-1;i>=0;i--)
               {
                  const ulong order=HistoryOrderGetTicket(i);
                  if(order==0 || HistoryOrderGetInteger(order,
                     ORDER_MAGIC)!=HunterPortfolioMagic(mode)) continue;
                  const long order_type=HistoryOrderGetInteger(order,ORDER_TYPE);
                  if(order_type==ORDER_TYPE_BUY_STOP || order_type==ORDER_TYPE_SELL_STOP)
                  {
                     const double price=HistoryOrderGetDouble(order,ORDER_PRICE_OPEN);
                     if(price>0.0)
                     {
                        anchor=price;
                        break;
                     }
                  }
               }
            }
         }
         const double target=HunterNormalizePrice(anchor+(buy?-1.0:1.0)*HunterPip()*hunter_profile.stop_loss);
         if((sl!=0.0 && MathAbs(sl-target)<=HunterPip()) || HunterModifyStops(ticket,target,
            tp)) HunterMarkAdjusted(ticket);
         PositionSelectByTicket(ticket);
         sl=PositionGetDouble(POSITION_SL);
         tp=PositionGetDouble(POSITION_TP);
      }
   }
   if(inp_UltimateBreakEven && mode>=0 && mode<7 && mode!=3 && mode!=4 && mode!=5)
   {
      const double profit=buy?bid-open:open-ask;
      if(profit>=hunter_profile.break_even_trigger*HunterPip())
      {
         const double target=HunterNormalizePrice(open+(buy?1.0:-1.0)*hunter_profile.break_even_lock*HunterPip());
         if(sl==0.0 || (buy?target>sl:target<sl))
         {
            if(HunterModifyStops(ticket,target,tp))
            {
               PositionSelectByTicket(ticket);
               sl=PositionGetDouble(POSITION_SL);
            }
         }
      }
   }
   if(hunter_profile.trail_start>0.0)
   {
      const double profit=buy?bid-open:open-ask;
      if(profit>hunter_profile.trail_start*HunterPip())
      {
         const double target=HunterNormalizePrice(buy?bid-hunter_profile.trail_distance*HunterPip():ask+hunter_profile.trail_distance*HunterPip());
         const double step=HunterPip()*(mode==4?20.0:0.1);
         if(sl==0.0 || (buy?target>sl+step:target<sl-step)) HunterModifyStops(ticket,target,tp);
      }
   }
}

// Repair single-profile false or execution-based stops after loading the profile.
void HunterAdjustSingleInitialStop(const ulong selected_order=0,const ulong selected_position=0,
   const double execution_price=0.0)
{
   if((int)inp_Mode==4 || (!((int)inp_Mode!=3 && inp_UltimateFalseInitialSL)
      && !inp_UltimateSLFromExecution) || !HunterTradingSessionOpen(_Symbol)) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol
         || PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo || (selected_position!=0
         && selected_position!=ticket)) continue;
      if(HunterTicketMarked(hunter_adjusted_tickets,ticket)) continue;
      double anchor=PositionGetDouble(POSITION_PRICE_OPEN);
      const double sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
      const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(!inp_UltimateSLFromExecution)
      {
         anchor=0.0;
         if(selected_order!=0
            && HistoryOrderSelect(selected_order)) anchor=HistoryOrderGetDouble(selected_order,
            ORDER_PRICE_OPEN);
         if(anchor<=0.0)
         {
            const ulong identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
            if(HistorySelect(0,TimeCurrent()))
            {
               for(int j=HistoryOrdersTotal()-1;j>=0;j--)
               {
                  const ulong order=HistoryOrderGetTicket(j);
                  if(order==0 || HistoryOrderGetInteger(order,ORDER_POSITION_ID)!=(long)identifier) continue;
                  if(HistoryOrderGetString(order,ORDER_SYMBOL)!=_Symbol || HistoryOrderGetInteger(order,
                     ORDER_MAGIC)!=(long)inp_MagicNo) continue;
                  const long order_type=HistoryOrderGetInteger(order,ORDER_TYPE);
                  if(order_type==ORDER_TYPE_BUY_STOP || order_type==ORDER_TYPE_SELL_STOP)
                  {
                     anchor=HistoryOrderGetDouble(order,ORDER_PRICE_OPEN);
                     if(anchor>0.0) break;
                  }
               }
            }
         }
         if(anchor<=0.0) continue;
      }
      else if(execution_price>0.0) anchor=execution_price;
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL) continue;
      const bool buy=type==POSITION_TYPE_BUY;
      const double target=HunterNormalizePrice(anchor+(buy?-1.0:1.0)*HunterPip()*hunter_profile.stop_loss);
      const bool supplied=execution_price>0.0 || selected_position!=0 || selected_order!=0;
      const bool already_tighter=sl>0.0 && !supplied && (buy?sl>target:sl<target);
      if(!already_tighter && (sl==0.0 || MathAbs(sl-target)>HunterPip()) && !HunterUpdateSingleStops(ticket,
         target,tp)) continue;
      HunterMarkAdjusted(ticket);
   }
}

// Prop profiles use a doubled initial stop, tracked separately from the 120-second repair.
void HunterAdjustPropInitialStop(const ulong selected_position=0,const double execution_price=0.0)
{
   if((int)inp_Mode!=4 || (!inp_UltimateFalseInitialSL && !inp_UltimateSLFromExecution)
      || !HunterTradingSessionOpen(_Symbol)) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol
         || PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo || (selected_position!=0
         && ticket!=selected_position)) continue;
      if(HunterTicketMarked(hunter_prop_initial_tickets,ticket)) continue;
      const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      const double anchor=execution_price>0.0?execution_price:PositionGetDouble(POSITION_PRICE_OPEN);
      const double tp=PositionGetDouble(POSITION_TP),sl=PositionGetDouble(POSITION_SL);
      const double distance=hunter_profile.stop_loss*(hunter_profile.prop_mode?2.0:1.0)*HunterPip();
      const double target=HunterNormalizePrice(anchor+(type==POSITION_TYPE_BUY?-distance:distance));
      const bool already_tighter=sl>0.0 && (type==POSITION_TYPE_BUY?sl>target:target>sl);
      if(!already_tighter && MathAbs(sl-target)>HunterPip() && !HunterUpdateSingleStops(ticket,target,
         tp)) continue;
      HunterMarkPropInitial(ticket);
   }
}

#ifndef SGH_PROTECTION_MQH
#define SGH_PROTECTION_MQH

// Integration hooks: preserve the caller's ownership, request ordering and failures.
void SGH_DeleteOwnedPendings();
void SGH_CloseOwnedPositionsAndPendings();
void SGH_InvalidateEntryBar();
bool HunterTradingSessionOpen(const string symbol);
double HunterNormalizePrice(double price);
bool HunterValidateStops(const ulong ticket,double &sl,double &tp,string &reason);

struct SGH_ProtectionState
{
   datetime dayStart; // Day boundary derived from quote time.
   double dayStartBalance;
   double dayStartEquity;
   bool dayLocked;
   string lockReason;
   bool equityTriggered;
   datetime lastNewsRefresh;
   bool newsBlocked;
   bool newsDeleteAttempted; // Attempt latch, not confirmation of successful deletion.
   datetime newsTime;
   string newsName;
   string newsCurrency;
   string newsDescription;
   bool dailyBlocked;
   bool dailyActionAttempted; // Preserve one-attempt behavior within the protection phase.
   bool fridayBlocked;
   bool fridayDeleteAttempted; // Attempt latch; do not silently add retries.
   bool fridayCloseAttempted; // Attempt latch; do not silently add retries.
   bool spreadBlocked;
   bool spreadDeleteAttempted; // Attempt latch; do not silently add retries.
   datetime highSpreadSince;
   datetime normalSpreadSince;
};
SGH_ProtectionState g_sghProtection;

// Use server time for protection windows and quote time for day reset.
datetime SGH_ProtectionServerNow()
{
   datetime value=TimeTradeServer();
   if(value==0) value=TimeCurrent();
   return value;
}

datetime SGH_ServerMidnight(const datetime value)
{
   MqlDateTime parts;
   TimeToStruct(value,parts);
   parts.hour=0;
   parts.min=0;
   parts.sec=0;
   return StructToTime(parts);
}

void SGH_ResetProtectionDay() // Initialization must zero the protection state before calling this reset.
{
   datetime start=SGH_ServerMidnight(TimeCurrent());
   if(start==g_sghProtection.dayStart) return;
   g_sghProtection.dayStart=start;
   g_sghProtection.dayStartBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   g_sghProtection.dayStartEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_sghProtection.dayLocked=false;
   g_sghProtection.lockReason="";
   g_sghProtection.equityTriggered=false;
   g_sghProtection.lastNewsRefresh=0;
   g_sghProtection.newsBlocked=false;
   g_sghProtection.newsDeleteAttempted=false;
   g_sghProtection.newsTime=0;
   g_sghProtection.newsName="";
   g_sghProtection.newsCurrency="";
   g_sghProtection.newsDescription="";
   g_sghProtection.dailyBlocked=false;
   g_sghProtection.dailyActionAttempted=false;
   g_sghProtection.fridayBlocked=false;
   g_sghProtection.fridayDeleteAttempted=false;
   g_sghProtection.fridayCloseAttempted=false;
   g_sghProtection.spreadBlocked=false;
   g_sghProtection.spreadDeleteAttempted=false;
   g_sghProtection.highSpreadSince=0;
   g_sghProtection.normalSpreadSince=0;
}

void SGH_CheckEquityProtection()
{
   if(!inp_UsePropFirmMode || !inp_UseEquityProtection || g_sghProtection.equityTriggered)
      return;
   const double basis=(inp_DailyDDReference==1 ? g_sghProtection.dayStartEquity :
                                               g_sghProtection.dayStartBalance);
   double floor=0.0;
   if(inp_DailyEquityProtectionPercent>0.0 && basis>0.0)
      floor=basis*(inp_DailyEquityProtectionPercent/-100.0+1.0);
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(floor<=0.0 || floor<equity) return;
   g_sghProtection.equityTriggered=true;
   SGH_CloseOwnedPositionsAndPendings();
   g_sghProtection.dayLocked=true;
   g_sghProtection.lockReason="Daily equity protection triggered ("+
      DoubleToString(inp_DailyEquityProtectionPercent,2)+"% of "+
      (inp_DailyDDReference==1 ? "prev day equity" : "prev day balance")+")";
}

// No symbol filter: only exit and out-by deals contribute. Add the
// three amounts in their existing order, preserving per-addition rounding.
double SGH_TodayClosedProfit()
{
   datetime day=SGH_ServerMidnight(TimeCurrent());
   if(!HistorySelect(day,TimeCurrent())) return 0.0;
   double total=0.0;
   int count=HistoryDealsTotal();
   for(int index=0;index<count;index++)
   {
      ulong deal=HistoryDealGetTicket(index);
      if(deal==0) continue;
      long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
      bool owned=(magic==(long)inp_MagicNo || magic==888778);
      if(inp_UseMultiProfileMode && magic>=777771 && magic<=777777) owned=true;
      if(!owned) continue;
      long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY) continue;
      total+=HistoryDealGetDouble(deal,DEAL_PROFIT);
      total+=HistoryDealGetDouble(deal,DEAL_COMMISSION);
      total+=HistoryDealGetDouble(deal,DEAL_SWAP);
   }
   return total;
}

void SGH_CheckDailyProfitLoss() // Apply the same daily profit/loss limits in single and portfolio modes.
{
   if(!inp_UsePropFirmMode) return;
   double profit=SGH_TodayClosedProfit();
   string reason;
   if(inp_UseDailyProfitTarget && profit>=inp_DailyProfitTargetUSD)
      reason="Daily profit target reached";
   else if(inp_UseDailyLossLimit && profit<=-inp_DailyLossLimitUSD)
      reason="Daily loss limit reached";
   else return;
   SGH_DeleteOwnedPendings();
   g_sghProtection.dayLocked=true;
   g_sghProtection.lockReason=reason;
}

// User clock is GMT+2. Apply the offset to the server calendar date.
datetime SGH_ManualProtectionTime(const datetime date,const int hour,const int minute)
{
   int offset=inp_ManualBrokerGMTOffset;
   if(inp_UseAutoBrokerGMTOffset)
   {
      datetime server=SGH_ProtectionServerNow();
      datetime gmt=TimeGMT();
      if(server!=0 && gmt!=0) offset=(int)MathRound((double)(server-gmt)/3600.0);
   }
   // Convert hours and minutes to uint32 before widening to 64 bits.
   return (datetime)((long)SGH_ServerMidnight(date)+(long)(uint)hour*3600+(long)(uint)minute*60+
          (long)(offset*3600-7200));
}

// Check session indices 0 through 9; stop at the first failed lookup.
bool SGH_LastSessionEnd(const datetime day,datetime &end)
{
   end=0;
   MqlDateTime parts;
   TimeToStruct(day,parts);
   for(uint index=0;index<10;index++)
   {
      datetime from=0,to=0;
      if(!SymbolInfoSessionTrade(NULL,(ENUM_DAY_OF_WEEK)parts.day_of_week,index,from,to))
         break;
      datetime candidate=day+to;
      if(from>=to) candidate+=86400;
      if(end==0 || candidate>end) end=candidate;
   }
   return end>0;
}

bool SGH_NextSessionStart(const datetime after,datetime &next)
{
   next=0;
   datetime day=SGH_ServerMidnight(after);
   for(int delta=0;delta<8;delta++)
   {
      datetime current=day+delta*86400;
      MqlDateTime parts;
      TimeToStruct(current,parts);
      for(uint index=0;index<10;index++)
      {
         datetime from=0,to=0;
         if(!SymbolInfoSessionTrade(NULL,(ENUM_DAY_OF_WEEK)parts.day_of_week,index,from,to))
            break;
         datetime candidate=current+from;
         if(candidate>after && (next==0 || candidate<next)) next=candidate;
      }
      if(next>0) return true;
   }
   return false;
}

bool SGH_CheckFridayClose()
{
   if(inp_UseFridayCloseProtection)
   {
      datetime now=SGH_ProtectionServerNow();
      MqlDateTime parts;
      TimeToStruct(now,parts);
      datetime friday=SGH_ServerMidnight(now)+(5-parts.day_of_week)*86400;
      datetime close=0,reopen=0;
      if(inp_UseManualFridayCloseTime)
      {
         close=SGH_ManualProtectionTime(friday,inp_FridayCloseHour,inp_FridayCloseMinute);
         if(!SGH_NextSessionStart(close,reopen))
            reopen=SGH_ManualProtectionTime(friday+3*86400,inp_DailyReopenHour,
                                          inp_DailyReopenMinute);
      }
      else
      {
         if(!SGH_LastSessionEnd(friday,close)) return false;
         if(!SGH_NextSessionStart(close,reopen)) return false;
         close-=1800; // Apply a fixed 30-minute lead.
      }
      if(close<=now && now<reopen)
      {
         if(inp_FridayCloseDeletePendings && !g_sghProtection.fridayDeleteAttempted)
         {
            SGH_DeleteOwnedPendings();
            g_sghProtection.fridayDeleteAttempted=true;
         }
         if(inp_FridayCloseClosePositions && !g_sghProtection.fridayCloseAttempted)
         {
            SGH_CloseOwnedPositionsAndPendings();
            g_sghProtection.fridayCloseAttempted=true;
            g_sghProtection.fridayDeleteAttempted=true;
         }
         g_sghProtection.fridayBlocked=true;
         return true;
      }
   }
   if(g_sghProtection.fridayBlocked)
   {
      g_sghProtection.fridayBlocked=false;
      g_sghProtection.fridayDeleteAttempted=false;
      g_sghProtection.fridayCloseAttempted=false;
      SGH_InvalidateEntryBar();
   }
   return false;
}

bool SGH_CheckDailyClose() // The internal daily-close gate is enabled at startup.
{
   datetime now=SGH_ProtectionServerNow();
   datetime close=0,reopen=0;
   if(inp_UseManualDailyCloseTime)
   {
      close=SGH_ManualProtectionTime(now,inp_DailyCloseHour,inp_DailyCloseMinute);
      reopen=SGH_ManualProtectionTime(now,inp_DailyReopenHour,inp_DailyReopenMinute);
      if(reopen<=close)
      {
         if(now<reopen) close-=86400;
         else reopen+=86400;
      }
   }
   else
   {
      if(!SGH_LastSessionEnd(SGH_ServerMidnight(now),close)) return false;
      if(!SGH_NextSessionStart(close,reopen)) return false;
   }
   if(inp_UseBrokerEarlyCloseDetection)
   {
      datetime sessionEnd=0,nextStart=0;
      if(SGH_LastSessionEnd(SGH_ServerMidnight(now),sessionEnd) &&
         SGH_NextSessionStart(sessionEnd,nextStart))
      {
         datetime earlier=sessionEnd-(inp_EarlyCloseProtectionMinutes>0 ?
                                      inp_EarlyCloseProtectionMinutes : 0)*60;
         if(earlier<close || close==0)
         {
            close=earlier;
            reopen=nextStart;
         }
      }
   }
   if(close<=now && now<reopen)
   {
      if(!g_sghProtection.dailyActionAttempted)
      {
         if(inp_DailyCloseDeletePendings) SGH_DeleteOwnedPendings();
         if(inp_DailyCloseClosePositions) SGH_CloseOwnedPositionsAndPendings();
         g_sghProtection.dailyActionAttempted=true;
      }
      g_sghProtection.dailyBlocked=true;
      return true;
   }
   if(g_sghProtection.dailyBlocked)
   {
      g_sghProtection.dailyBlocked=false;
      g_sghProtection.dailyActionAttempted=false;
      SGH_InvalidateEntryBar();
   }
   return false;
}

// Spread uses ten-point units on symbols quoted to 3 or 5 decimal places.
double SGH_CurrentSpreadPoints()
{
   double ask=SymbolInfoDouble(NULL,SYMBOL_ASK);
   double bid=SymbolInfoDouble(NULL,SYMBOL_BID);
   double unit=_Point*((_Digits==3 || _Digits==5) ? 10.0 : 1.0);
   return (ask-bid)/unit;
}

bool SGH_CheckSpread()
{
   if(inp_MaxSpread<1) g_sghProtection.spreadBlocked=false;
   else
   {
      double spread=SGH_CurrentSpreadPoints();
      datetime now=SGH_ProtectionServerNow();
      if(!inp_UseHighSpreadDeletePending)
      {
         g_sghProtection.spreadBlocked=(spread>inp_MaxSpread);
         if(g_sghProtection.spreadBlocked) return true;
      }
      else
      {
         if(spread>inp_MaxSpread)
         {
            g_sghProtection.normalSpreadSince=0;
            if(g_sghProtection.highSpreadSince==0) g_sghProtection.highSpreadSince=now;
            if(!g_sghProtection.spreadBlocked &&
               now-g_sghProtection.highSpreadSince>=60)
            {
               g_sghProtection.spreadBlocked=true;
               if(!g_sghProtection.spreadDeleteAttempted)
               {
                  SGH_DeleteOwnedPendings();
                  g_sghProtection.spreadDeleteAttempted=true;
               }
            }
            return g_sghProtection.spreadBlocked;
         }
         g_sghProtection.highSpreadSince=0;
         if(g_sghProtection.spreadBlocked)
         {
            if(g_sghProtection.normalSpreadSince==0) g_sghProtection.normalSpreadSince=now;
            if(now-g_sghProtection.normalSpreadSince<60) return true;
            g_sghProtection.spreadBlocked=false;
            SGH_InvalidateEntryBar();
         }
      }
   }
   g_sghProtection.normalSpreadSince=0;
   g_sghProtection.highSpreadSince=0;
   g_sghProtection.spreadDeleteAttempted=false;
   return false;
}

string SGH_Lowercase(string value)
{
   StringToLower(value);
   return value;
}

bool SGH_ContainsAny(string text,string a,string b="",string c="",string d="",string e="")
{
   text=SGH_Lowercase(text);
   return (a!="" && StringFind(text,SGH_Lowercase(a))>=0) ||
          (b!="" && StringFind(text,SGH_Lowercase(b))>=0) ||
          (c!="" && StringFind(text,SGH_Lowercase(c))>=0) ||
          (d!="" && StringFind(text,SGH_Lowercase(d))>=0) ||
          (e!="" && StringFind(text,SGH_Lowercase(e))>=0);
}

bool SGH_IsFedChairEvent(const MqlCalendarEvent &event)
{
   return SGH_ContainsAny(event.event_code,"fed-chair","chair-powell","powell",
                          "federal-reserve-chair") ||
          SGH_ContainsAny(event.name,"fed chair","federal reserve chair","chair powell",
                          "powell speaks","powell testifies");
}

bool SGH_IsSelectedMajorNews(const MqlCalendarEvent &event)
{
   string keywords[];
   int count=StringSplit(inp_MajorNewsKeywords,',',keywords);
   string code=SGH_Lowercase(event.event_code);
   string name=SGH_Lowercase(event.name);
   for(int index=0;index<count;index++)
   {
      string key=SGH_Lowercase(keywords[index]);
      StringTrimLeft(key);
      StringTrimRight(key);
      if(key=="") continue;
      if(key=="nfp")
      {
         if(SGH_ContainsAny(code,"nonfarm","non-farm","payroll") ||
            SGH_ContainsAny(name,"nonfarm","non-farm","payroll")) return true;
      }
      else if(key=="cpi")
      {
         if(SGH_ContainsAny(code,"cpi","consumer-price","consumer_price") ||
            SGH_ContainsAny(name,"cpi","consumer price")) return true;
      }
      else if(key=="fomc")
      {
         if(SGH_ContainsAny(code,"fomc","federal-funds","fed-funds","interest-rate") ||
            SGH_ContainsAny(name,"fomc","federal funds rate","fed funds rate")) return true;
      }
      else if(key=="fed chair" || key=="chairman" || key=="fed chairman")
      {
         if(SGH_IsFedChairEvent(event)) return true;
      }
      else if(key=="core pce")
      {
         if(SGH_ContainsAny(code,"core-pce","core_pce","personal-consumption",
                            "personal_consumption") ||
            SGH_ContainsAny(name,"core pce","core personal consumption",
                            "personal consumption expenditures")) return true;
      }
      else if(StringFind(name,key)>=0 || StringFind(code,key)>=0) return true;
   }
   return false;
}

void SGH_NewsCurrencies(string &currencies[])
{
   ArrayResize(currencies,0);
   string source[];
   int count=StringSplit(inp_NewsCurrencies,',',source);
   for(int index=0;index<count;index++)
   {
      string value=source[index];
      StringTrimLeft(value);
      StringTrimRight(value);
      StringToUpper(value);
      if(StringLen(value)!=3) continue;
      bool found=false;
      for(int previous=0;previous<ArraySize(currencies);previous++)
         if(currencies[previous]==value)
         {
            found=true;
            break;
         }
      if(found) continue;
      int size=ArraySize(currencies);
      ArrayResize(currencies,size+1);
      currencies[size]=value;
   }
   if(ArraySize(currencies)==0)
   {
      ArrayResize(currencies,1);
      currencies[0]="USD";
   }
}

bool SGH_CheckNews()
{
   bool wasBlocked=g_sghProtection.newsBlocked;
   if(!inp_UseHighImpactNewsFilter && !inp_UseMajorNewsFilter)
   {
      if(g_sghProtection.newsDeleteAttempted) g_sghProtection.newsDeleteAttempted=false;
      return false;
   }
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) ||
      MQLInfoInteger(MQL_VISUAL_MODE))
   {
      g_sghProtection.newsBlocked=false;
      g_sghProtection.newsTime=0;
      g_sghProtection.newsName="";
      g_sghProtection.newsCurrency="";
      g_sghProtection.newsDescription="NO DATA (TEST MODE)";
   }
   else
   {
      datetime now=SGH_ProtectionServerNow();
      if(g_sghProtection.lastNewsRefresh==0 || now-g_sghProtection.lastNewsRefresh>29)
      {
         g_sghProtection.lastNewsRefresh=now;
         g_sghProtection.newsBlocked=false;
         g_sghProtection.newsTime=0;
         g_sghProtection.newsName="";
         g_sghProtection.newsCurrency="";
         g_sghProtection.newsDescription="";
         datetime nearestUpcoming=0;
         string upcomingName="",upcomingCurrency="";
         string currencies[];
         SGH_NewsCurrencies(currencies);
         datetime start=now-3600-inp_NewsMinutesAfter*60;
         datetime end=now+86400;
         for(int currencyIndex=0;currencyIndex<ArraySize(currencies);currencyIndex++)
         {
            ResetLastError();
            MqlCalendarValue values[];
            int count=CalendarValueHistory(values,start,end,NULL,currencies[currencyIndex]);
            for(int index=0;index<count;index++)
            {
               MqlCalendarEvent event;
               if(!CalendarEventById(values[index].event_id,event) ||
                  event.importance!=CALENDAR_IMPORTANCE_HIGH) continue;
               if(!inp_UseHighImpactNewsFilter &&
                  (!inp_UseMajorNewsFilter || !SGH_IsSelectedMajorNews(event))) continue;
               datetime eventTime=values[index].time;
               int after=inp_NewsMinutesAfter;
               if(inp_FullFedChairSpeechProtection && SGH_IsFedChairEvent(event))
                  if(inp_FedChairSpeechMinutes>after) after=inp_FedChairSpeechMinutes;
               if(eventTime-inp_NewsMinutesBefore*60<=now && now<=eventTime+after*60)
               {
                  g_sghProtection.newsBlocked=true;
                  if(g_sghProtection.newsTime==0 || eventTime<g_sghProtection.newsTime)
                  {
                     g_sghProtection.newsTime=eventTime;
                     g_sghProtection.newsName=event.name;
                     g_sghProtection.newsCurrency=currencies[currencyIndex];
                  }
               }
               if(now<=eventTime && (nearestUpcoming==0 || eventTime<nearestUpcoming))
               {
                  nearestUpcoming=eventTime;
                  upcomingName=event.name;
                  upcomingCurrency=currencies[currencyIndex];
               }
            }
         }
         if(!g_sghProtection.newsBlocked && nearestUpcoming>0)
         {
            g_sghProtection.newsTime=nearestUpcoming;
            g_sghProtection.newsName=upcomingName;
            g_sghProtection.newsCurrency=upcomingCurrency;
         }
         if(g_sghProtection.newsTime>0)
         {
            g_sghProtection.newsDescription=g_sghProtection.newsCurrency+" | "+
                                             g_sghProtection.newsName;
            if(g_sghProtection.newsBlocked) g_sghProtection.newsDescription+=" | ACTIVE";
            else
            {
               long minutes=(g_sghProtection.newsTime-now)/60;
               if(minutes<0) minutes=0;
               g_sghProtection.newsDescription+=" | "+IntegerToString(minutes)+"m";
            }
         }
         else if(inp_UseHighImpactNewsFilter)
            g_sghProtection.newsDescription="No high impact news";
         else if(inp_UseMajorNewsFilter)
            g_sghProtection.newsDescription="No selected high-impact news";
         else g_sghProtection.newsDescription="News filter OFF";
      }
   }
   if(g_sghProtection.newsBlocked)
   {
      if(!g_sghProtection.newsDeleteAttempted)
      {
         SGH_DeleteOwnedPendings();
         g_sghProtection.newsDeleteAttempted=true;
      }
      return true;
   }
   if(wasBlocked)
   {
      g_sghProtection.newsDeleteAttempted=false;
      SGH_InvalidateEntryBar();
   }
   return false;
}
// Manage the auxiliary 888778 strategy independently from visible profiles.
void SGH_ManageAuxiliaryTrailing()
{
   if(!HunterTradingSessionOpen(_Symbol)) return;
   double ask=SymbolInfoDouble(NULL,SYMBOL_ASK);
   double bid=SymbolInfoDouble(NULL,SYMBOL_BID);
   if(ask<=0.0 || bid<=0.0) return;
   double unit=_Point*((_Digits==3 || _Digits==5) ? 10.0 : 1.0);
   for(int index=PositionsTotal()-1;index>=0;index--)
   {
      ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol ||
         PositionGetInteger(POSITION_MAGIC)!=888778) continue;
      long side=PositionGetInteger(POSITION_TYPE);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double oldSL=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double candidate;
      if(side==POSITION_TYPE_BUY)
      {
         if((bid-entry)/unit<150.0) continue;
         candidate=bid-50.0*unit;
      }
      else
      {
         if((entry-ask)/unit<150.0) continue;
         candidate=ask+50.0*unit;
      }
      double sl=HunterNormalizePrice(candidate);
      if(oldSL>0.0 &&
         ((side==POSITION_TYPE_BUY && !(oldSL+25.0*unit<sl)) ||
          (side==POSITION_TYPE_SELL && !(sl<oldSL-25.0*unit)))) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      string reason="";
      if(!HunterValidateStops(ticket,sl,tp,reason)) continue;
      MqlTradeRequest request={};
      MqlTradeResult result={};
      request.action=TRADE_ACTION_SLTP;
      request.position=ticket;
      request.symbol=_Symbol;
      request.magic=888778;
      request.sl=sl;
      request.tp=tp;
      // This branch does not latch successful fills or inspect the result.
      if(!OrderSend(request,result)) continue;
   }
}
#endif


// Logo pixels, without resampling or recoloring.

bool g_hunter_logo_attempted=false;
bool g_hunter_logo_created=false;

bool HunterCreateOriginalLogo()
{
   if(g_hunter_logo_attempted) return g_hunter_logo_created;
   g_hunter_logo_attempted=true;
   static const uint pixels[]={
      0xFF0C1524,0xFF0C1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0C1524,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1525,0xFF0C1526,0xFF0C1526,0xFF0B1424,0xFF0B1524,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1323,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,
      0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1524,
      0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0A1424,0xFF0B1423,0xFF0C1524,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1424,0xFF0B1424,0xFF0B1323,0xFF0B1423,0xFF0B1424,0xFF0B1524,0xFF0C1524,0xFF0A1323,
      0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0B1524,0xFF0B1524,
      0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1525,0xFF0B1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0C1525,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1423,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1424,0xFF0C1424,0xFF0A1323,
      0xFF0B1423,0xFF0B1424,0xFF0C1525,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1525,0xFF0B1525,0xFF0C1525,0xFF0C1526,0xFF0B1424,0xFF0B1525,0xFF0C1525,0xFF0C1525,
      0xFF0B1525,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0A1424,0xFF0B1424,0xFF0B1525,0xFF0B1525,0xFF0B1525,0xFF0B1524,0xFF0B1525,0xFF0B1525,
      0xFF0B1424,0xFF0B1424,0xFF0A1323,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1423,
      0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1424,0xFF0B1524,0xFF0B1524,0xFF0B1424,0xFF0B1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0C1525,0xFF0B1525,0xFF0C1525,0xFF0B1526,0xFF0A1425,0xFF091424,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1626,
      0xFF0D1526,0xFF0B1524,0xFF0B1524,0xFF0C1526,0xFF0D1527,0xFF0A1424,0xFF0B1525,0xFF0B1525,0xFF0B1525,0xFF0B1525,0xFF0A101F,0xFF090C1B,
      0xFF0B1525,0xFF0B1424,0xFF0A1323,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1425,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1423,
      0xFF0B1424,0xFF0B1524,0xFF0B1524,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1424,0xFF0B1424,0xFF0B1424,
      0xFF0C1525,0xFF0C1525,0xFF0B1525,0xFF0C1526,0xFF0A1526,0xFF0C1527,0xFF101829,0xFF0B1526,0xFF0B1525,0xFF0A1221,0xFF0A1120,0xFF091021,
      0xFF02101E,0xFF0E1223,0xFF000F1D,0xFF3F203D,0xFF893563,0xFF01101D,0xFF0D1627,0xFF0B1525,0xFF0B1525,0xFF0A1020,0xFF10283C,0xFF13374E,
      0xFF091021,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1525,0xFF0B1525,0xFF0B1524,0xFF0B1524,0xFF0B1524,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,
      0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1626,0xFF071223,0xFF181F34,0xFF31415F,0xFF000A18,0xFF08101F,0xFF0D1A2B,0xFF0D2132,0xFF17283B,
      0xFF4A3455,0xFF4E3454,0xFF131E31,0xFF19273C,0xFF201F33,0xFF091323,0xFF0A1020,0xFF091222,0xFF0B1626,0xFF090715,0xFF1C5F7D,0xFF248BB2,
      0xFF080817,0xFF0B1626,0xFF0C1424,0xFF0C1424,0xFF0B1424,0xFF0B1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1425,0xFF0C1524,0xFF0B1424,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,
      0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1526,0xFF091020,0xFF051525,0xFF3C4363,0xFF293F5B,0xFF0F2C43,0xFF112B43,0xFF132B43,
      0xFF303856,0xFF182F43,0xFF183A53,0xFF112F47,0xFF0F2C41,0xFF153248,0xFF122B3F,0xFF131C2E,0xFF0E1628,0xFF0A1628,0xFF0C1626,0xFF0A182A,
      0xFF0B1324,0xFF0C1424,0xFF071222,0xFF00101E,0xFF0A1424,0xFF0B1525,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1324,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0A1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0C1525,
      0xFF0C1525,0xFF0B1424,0xFF0C1425,0xFF081323,0xFF061222,0xFF13273A,0xFF122D41,0xFF1E344E,0xFF1D3C57,0xFF0E2941,0xFF081224,0xFF0F2940,
      0xFF0B3F5C,0xFF0F2A3D,0xFF225576,0xFF153B58,0xFF0C2136,0xFF0D243A,0xFF0B354C,0xFF46587A,0xFF35496C,0xFF071828,0xFF0B0F1E,0xFF114166,
      0xFF0D1A2C,0xFF081120,0xFF171629,0xFF36203B,0xFF091324,0xFF0B1524,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1525,0xFF0B1525,0xFF0B1425,
      0xFF0B1424,0xFF0C1526,0xFF041220,0xFF2C1B34,0xFF513F62,0xFF0D2F43,0xFF194A68,0xFF0D273E,0xFF0F1D2F,0xFF132C42,0xFF266385,0xFF17344B,
      0xFF142D44,0xFF0F1D2F,0xFF080E1F,0xFF0E2134,0xFF0E1C2E,0xFF0E2033,0xFF11273A,0xFF08233A,0xFF0D2E47,0xFF14334B,0xFF112437,0xFF060816,
      0xFF0C1121,0xFF021321,0xFF482645,0xFFC0467F,0xFF071223,0xFF0B1525,0xFF0B1424,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0B1424,
      0xFF0B1423,0xFF0B1423,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0C1525,0xFF0C1525,0xFF0B1424,
      0xFF0B1424,0xFF0B1525,0xFF0A1322,0xFF172134,0xFF203B5A,0xFF0E2A43,0xFF113756,0xFF113150,0xFF090F1D,0xFF205C7D,0xFF287296,0xFF11273F,
      0xFF0A1425,0xFF0E273F,0xFF0D1D34,0xFF060F1C,0xFF3F4362,0xFF2B3855,0xFF071322,0xFF0B2B48,0xFF0F2F4A,0xFF0F2B44,0xFF17374E,0xFF317DA3,
      0xFF133149,0xFF091122,0xFF0D1629,0xFF101527,0xFF0B1526,0xFF0C1526,0xFF0B1524,0xFF0C1524,0xFF0C1525,0xFF0D1625,0xFF0C1525,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0C1526,0xFF0C1526,0xFF0B1425,
      0xFF0B1526,0xFF0B1322,0xFF102941,0xFF0D2943,0xFF071526,0xFF112337,0xFF0A1E30,0xFF041120,0xFF143046,0xFF0B1D31,0xFF102539,0xFF142D41,
      0xFF122F43,0xFF09304B,0xFF042137,0xFF132A3C,0xFF0C1828,0xFF0D1D2E,0xFF0F2235,0xFF060F22,0xFF0B1B33,0xFF152D43,0xFF12253A,0xFF3184AE,
      0xFF1F4B67,0xFF090A18,0xFF0C1526,0xFF081222,0xFF0A0E1D,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1524,0xFF0B1423,0xFF0B1323,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1626,0xFF0C1526,0xFF0B1727,
      0xFF0B111F,0xFF061833,0xFF0A3561,0xFF0F3A64,0xFF113659,0xFF03111E,0xFF39223F,0xFF483861,0xFF071F30,0xFF0B0E1F,0xFF0A1424,0xFF142F49,
      0xFF031B2B,0xFF80426F,0xFF704D7A,0xFF062235,0xFF0E1B31,0xFF0C1E30,0xFF142F44,0xFF17354A,0xFF0C3653,0xFF12334E,0xFF102B45,0xFF0B1E31,
      0xFF16364F,0xFF112B3F,0xFF040E1C,0xFF0D1729,0xFF144F6A,0xFF0B1627,0xFF0B1424,0xFF0B1525,0xFF0B1524,0xFF0B1424,0xFF0B1423,0xFF0B1423,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1424,0xFF0B1525,0xFF0C1525,0xFF0C1526,0xFF0B1627,0xFF0B1121,
      0xFF0A1E32,0xFF3186AE,0xFF3B98C0,0xFF185984,0xFF0E3D6B,0xFF0D385C,0xFF141023,0xFF232B47,0xFF091221,0xFF0C1C33,0xFF081E37,0xFF193A57,
      0xFF0A2D44,0xFF6E2F53,0xFF844C7E,0xFF0D394F,0xFF173350,0xFF0F2C43,0xFF0E1F31,0xFF1B4D6B,0xFF144261,0xFF070817,0xFF102236,0xFF133550,
      0xFF08182C,0xFF172D46,0xFF28233C,0xFF091627,0xFF0F2538,0xFF0B1525,0xFF0B1525,0xFF0B1525,0xFF0B1424,0xFF0B1423,0xFF0C1424,0xFF0B1423,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0D1627,0xFF040818,
      0xFF4990AD,0xFF90F3FF,0xFF88EAFF,0xFF5ED4F7,0xFF1B6793,0xFF0D3C6A,0xFF082743,0xFF071321,0xFF15334E,0xFF072D51,0xFF071429,0xFF111D2F,
      0xFF182B40,0xFF0C1B2D,0xFF0E2237,0xFF0E2035,0xFF0F1F31,0xFF080715,0xFF0E2135,0xFF091323,0xFF112539,0xFF122A41,0xFF0E1525,0xFF153856,
      0xFF082036,0xFF11233C,0xFF363B5E,0xFF091523,0xFF0C1120,0xFF0B1525,0xFF0B1626,0xFF0C1525,0xFF0B1524,0xFF0B1423,0xFF0B1424,0xFF0B1323,
      0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0C1626,0xFF070D1D,0xFF1C3547,
      0xFF8EE3FA,0xFF8ADFFA,0xFF85DEF9,0xFF8AE7FF,0xFF51CAF0,0xFF104D7B,0xFF0E3761,0xFF0A1323,0xFF0F243A,0xFF142D4E,0xFF0E2235,0xFF0B1C31,
      0xFF0A2C4C,0xFF124365,0xFF0D192D,0xFF091428,0xFF09192D,0xFF235777,0xFF112538,0xFF090E1C,0xFF0C0F1D,0xFF0D2B3F,0xFF082235,0xFF041D2E,
      0xFF103B5A,0xFF051528,0xFF0C2F43,0xFF11273D,0xFF0A101F,0xFF0B1323,0xFF0A0E1C,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,
      0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0C1525,0xFF0C1525,0xFF0B1525,0xFF0D1728,0xFF010616,0xFF447184,
      0xFFAFF6FF,0xFF9CE2F9,0xFF88E2FC,0xFF88E0FB,0xFF7AE4FF,0xFF2A8DB8,0xFF0D3864,0xFF092138,0xFF141325,0xFFC84A83,0xFF323856,0xFF063350,
      0xFF08375C,0xFF11324D,0xFF18405A,0xFF091A30,0xFF0B1A2C,0xFF103149,0xFF133048,0xFF0E2034,0xFF081C34,0xFF262946,0xFF513D5E,0xFF5D4067,
      0xFF0F263C,0xFF091123,0xFF0E2D4C,0xFF154361,0xFF0B1424,0xFF0C1C2D,0xFF103148,0xFF0A1323,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1323,
      0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0D1727,0xFF010717,0xFF6195AA,
      0xFFC2FAFF,0xFFADE9FB,0xFF94E5FD,0xFF8AE1FC,0xFF88E5FE,0xFF41B2DB,0xFF0C406D,0xFF0D2846,0xFF060E1B,0xFF352B47,0xFF192E50,0xFF0A1627,
      0xFF0C0E18,0xFF081325,0xFF185D89,0xFF143551,0xFF0F3B5C,0xFF126389,0xFF113F60,0xFF163E5D,0xFF011D35,0xFF1F2640,0xFF80406C,0xFFAF477B,
      0xFF152941,0xFF072141,0xFF0A213B,0xFF153E59,0xFF0E1F33,0xFF133B54,0xFF2191BC,0xFF0A1121,0xFF0B1424,0xFF0B1524,0xFF0B1423,0xFF0B1423,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0E1726,0xFF00091A,0xFF6FA2B9,
      0xFFC4F9FF,0xFFB2EAFA,0xFF9BE5FC,0xFF8DE2FC,0xFF8DE6FF,0xFF4BBEE6,0xFF0E4876,0xFF082949,0xFF22152B,0xFF172036,0xFF071F32,0xFF0C1120,
      0xFF0C223C,0xFF07294C,0xFF123552,0xFF132F45,0xFF09182E,0xFF0C1C2E,0xFF0C1323,0xFF0A1525,0xFF38425B,0xFF263E5A,0xFF011423,0xFF13304E,
      0xFF144868,0xFF0E2134,0xFF0E1D2E,0xFF0B243B,0xFF0A2032,0xFF0C1222,0xFF0B1627,0xFF0B1423,0xFF0B1524,0xFF0C1525,0xFF0C1524,0xFF0B1424,
      0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1425,0xFF0C1524,0xFF0E1727,0xFF000717,0xFF6394AA,
      0xFFC7FCFF,0xFFB4E9FA,0xFF9BE5FD,0xFF8CE2FC,0xFF90E7FF,0xFF4DBEE6,0xFF114D7B,0xFF092C4D,0xFF241930,0xFF20192F,0xFF153351,0xFF113B60,
      0xFF08223E,0xFF08152A,0xFF0D1523,0xFF17415E,0xFF0F2031,0xFF0F263C,0xFF143653,0xFF102335,0xFF2C4763,0xFF244465,0xFF091525,0xFF081D34,
      0xFF15334A,0xFF112F49,0xFF0B2A46,0xFF152A3F,0xFF222D44,0xFF0A1222,0xFF0C1525,0xFF0B1424,0xFF0B1524,0xFF0C1525,0xFF0C1525,0xFF0C1524,
      0xFF0C1525,0xFF0B1424,0xFF0B1423,0xFF0C1524,0xFF0B1524,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0E1727,0xFF000617,0xFF538095,
      0xFFC6FCFF,0xFFB2E9FA,0xFF96E4FC,0xFF91E4FC,0xFF85E2FD,0xFF3BB5E1,0xFF114B77,0xFF0D2E51,0xFF071220,0xFF00101E,0xFF46355B,0xFF31446B,
      0xFF081A2A,0xFF0C1F36,0xFF102840,0xFF2A78A2,0xFF1A3E58,0xFF102235,0xFF0C223B,0xFF082237,0xFF09213A,0xFF071223,0xFF11304A,0xFF0C2137,
      0xFF091322,0xFF0D2137,0xFF071F39,0xFF14364F,0xFF4D3E5F,0xFF0A1222,0xFF0D1627,0xFF0D1526,0xFF0C1524,0xFF0C1525,0xFF0C1525,0xFF0B1424,
      0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0C1525,0xFF0C1525,0xFF0C1524,0xFF0C1424,0xFF0E1727,0xFF000617,0xFF54859D,
      0xFFC9FCFF,0xFFA9E7F9,0xFF93E3FC,0xFF96E5FD,0xFF5CD1F6,0xFF30AEDB,0xFF12466F,0xFF0D2F52,0xFF0C1323,0xFF0A0E1F,0xFF091526,0xFF0D1F31,
      0xFF0F2539,0xFF0C1929,0xFF0E3556,0xFF0F2D46,0xFF0C243C,0xFF10304A,0xFF1B273A,0xFF463E63,0xFF0F243C,0xFF0D1626,0xFF0A1426,0xFF153F5A,
      0xFF19445E,0xFF12283C,0xFF144465,0xFF03385B,0xFF613464,0xFF18162B,0xFF00101D,0xFF00111E,0xFF0C1526,0xFF0C1525,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1323,0xFF0B1524,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0E1726,0xFF000A1D,0xFF77AEC4,
      0xFFC9F9FF,0xFF9BE4FA,0xFF9CE7FE,0xFF7FDEFA,0xFF3BC4F3,0xFF34AED9,0xFF11406A,0xFF0F3459,0xFF0A0917,0xFF0F5B83,0xFF145479,0xFF276089,
      0xFF101F32,0xFF0C2744,0xFF0D2B49,0xFF163045,0xFF143C60,0xFF061222,0xFF214970,0xFF523D68,0xFF15374D,0xFF132D43,0xFF0E2740,0xFF1A4E6C,
      0xFF257194,0xFF0D1D31,0xFF133A56,0xFF08172A,0xFF172C43,0xFF071627,0xFF432442,0xFF462544,0xFF051220,0xFF0D1526,0xFF0B1424,0xFF0C1525,
      0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1626,0xFF090D1C,0xFF17344B,0xFFB0E8F7,
      0xFFB3ECFD,0xFF97E5FD,0xFF95E7FD,0xFF50CDF4,0xFF3DC7F3,0xFF36AEDA,0xFF103D68,0xFF0E385F,0xFF0B1323,0xFF0E2C44,0xFF0E2C43,0xFF174B6A,
      0xFF093249,0xFF0B223C,0xFF090D1D,0xFF0F2137,0xFF0F2943,0xFF111E2E,0xFF0E3858,0xFF00213B,0xFF0E1B2B,0xFF0C1425,0xFF0C1528,0xFF0E283F,
      0xFF0A1526,0xFF132B40,0xFF102436,0xFF0C1F35,0xFF15283C,0xFF011522,0xFF823562,0xFF843664,0xFF010F1C,0xFF0E1526,0xFF0C1524,0xFF0C1525,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1425,0xFF0B1526,0xFF0E1827,0xFF00091B,0xFF6CA4BB,0xFFC8FAFF,
      0xFF99E2F9,0xFF9EE8FE,0xFF6FD9F9,0xFF3DC5F3,0xFF43CAF5,0xFF37B6E2,0xFF113F68,0xFF0F3C66,0xFF0D1F35,0xFF0C0D1B,0xFF040E1B,0xFF3D1935,
      0xFF583660,0xFF0C1F30,0xFF13263B,0xFF0E2136,0xFF18445C,0xFF0E1F32,0xFF090917,0xFF0C0B18,0xFF0D2741,0xFF031C33,0xFF041B2C,0xFF0E2034,
      0xFF090E1C,0xFF0F2337,0xFF123D58,0xFF071527,0xFF132539,0xFF0C192B,0xFF041121,0xFF051221,0xFF0B1425,0xFF0B1424,0xFF0C1525,0xFF0C1525,
      0xFF0B1424,0xFF0B1524,0xFF0B1524,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0A1324,0xFF152A3D,0xFF020817,0xFF325C76,0xFFC0F8FF,0xFFAFE8FA,
      0xFF95E2FB,0xFF9BE7FD,0xFF5ED3F8,0xFF40C6F3,0xFF43C7F2,0xFF42C8F3,0xFF19537C,0xFF0E3B65,0xFF0E3052,0xFF0C1221,0xFF091727,0xFF271931,
      0xFF312642,0xFF112D41,0xFF0E2235,0xFF267094,0xFF43D4FF,0xFF154769,0xFF102D47,0xFF12283D,0xFF07263D,0xFF76547F,0xFF724871,0xFF041626,
      0xFF0F1A2D,0xFF080F1E,0xFF163751,0xFF0C2943,0xFF052130,0xFF0C1626,0xFF0B1424,0xFF0C1526,0xFF0B1425,0xFF0C1525,0xFF0C1525,0xFF0C1525,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF080F1F,0xFF182E3F,0xFF142535,0xFF0D2136,0xFF9DD7EB,0xFFC7F2FB,0xFFA0E4FB,
      0xFF96E3FC,0xFF9AE6FD,0xFF6FD9FA,0xFF3CC7F5,0xFF42C5F0,0xFF47D2FE,0xFF2980AB,0xFF0B305B,0xFF114470,0xFF0C2541,0xFF0B101F,0xFF041422,
      0xFF041423,0xFF152C42,0xFF0B1B2F,0xFF112F48,0xFF226B8F,0xFF0D3A60,0xFF0D243D,0xFF102034,0xFF041726,0xFF785981,0xFF704D75,0xFF09263A,
      0xFF142D43,0xFF0E3048,0xFF2D3A5A,0xFF36466E,0xFF463658,0xFF081121,0xFF0D1727,0xFF0C1525,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0A1424,0xFF0C1726,0xFF26485A,0xFF070D1D,0xFF18354E,0xFFACE9FD,0xFFC4F9FF,0xFFABE9FC,
      0xFF98E4FD,0xFF97E4FC,0xFF95E5FD,0xFF61D5F8,0xFF3EC5F2,0xFF40C7F3,0xFF41C1EC,0xFF174F78,0xFF0A325C,0xFF0F426D,0xFF0E2D4B,0xFF0C1525,
      0xFF070F1E,0xFF1D1E34,0xFF313F5C,0xFF071021,0xFF10273D,0xFF0C1628,0xFF0A192E,0xFF091C34,0xFF0A1426,0xFF06253A,0xFF062335,0xFF0B1324,
      0xFF090F1E,0xFF08284B,0xFF05253E,0xFF193553,0xFF4B2C4E,0xFF071323,0xFF0C1424,0xFF0D1728,0xFF0D1A2C,0xFF0A1323,0xFF0C1525,0xFF0B1424,
      0xFF0B1424,0xFF0A1423,0xFF0A1423,0xFF0C1525,0xFF060B1B,0xFF1E394B,0xFF213D4F,0xFF080D1E,0xFF091325,0xFF1F4460,0xFF60A8C3,0xFFACF0FF,
      0xFFA8E9FD,0xFF93E1FB,0xFF94E3FC,0xFF96E4FC,0xFF7DDCFA,0xFF56CDF3,0xFF40CAF6,0xFF39B9E5,0xFF1D628D,0xFF0B335D,0xFF0E3B67,0xFF103A60,
      0xFF0C1E34,0xFF0B0E1D,0xFF122133,0xFF0D2538,0xFF073053,0xFF0F1F34,0xFF0A2D4B,0xFF0A3B61,0xFF102539,0xFF0E1C30,0xFF11263C,0xFF0F1C2C,
      0xFF0A2D50,0xFF082D4F,0xFF0D2033,0xFF113550,0xFF021420,0xFF0A1121,0xFF0C1627,0xFF17354B,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0B1524,
      0xFF0C1525,0xFF0B1424,0xFF0B1323,0xFF0B1525,0xFF060C1C,0xFF3A677A,0xFF142436,0xFF091021,0xFF0C1625,0xFF080E1D,0xFF000517,0xFF437288,
      0xFFB8F3FE,0xFFAFE8FB,0xFF9EE5FC,0xFF93E3FC,0xFF98E5FD,0xFF97E7FE,0xFF7FDDF9,0xFF5AD2F8,0xFF41CCF8,0xFF329BC6,0xFF18537D,0xFF0B3561,
      0xFF10416C,0xFF0E2844,0xFF050C1A,0xFF232138,0xFF454470,0xFF091F35,0xFF0B1224,0xFF0A1121,0xFF113149,0xFF0B1222,0xFF0D1D2F,0xFF0E1A2D,
      0xFF0A2B49,0xFF0A1527,0xFF123956,0xFF12293F,0xFF0B0D1C,0xFF0B1424,0xFF215976,0xFF102135,0xFF0A1120,0xFF0B1525,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0A1323,0xFF080F1F,0xFF132232,0xFF487E8E,0xFF080F20,0xFF0C1626,0xFF0B1424,0xFF0D1829,0xFF0A1120,0xFF132131,
      0xFF9FDEF2,0xFFB6EEFF,0xFFBDEEFC,0xFFB8EDFD,0xFFA4E7FD,0xFF97E4FC,0xFF97E4FD,0xFF90E2FC,0xFF73D8F8,0xFF4DD2FC,0xFF43C9F4,0xFF2983AC,
      0xFF0E3964,0xFF10416E,0xFF0D2B47,0xFF291227,0xFF352A47,0xFF0B2437,0xFF031628,0xFF0A2539,0xFF0F1F33,0xFF0B1221,0xFF0A192C,0xFF0F4466,
      0xFF0D2136,0xFF0C2338,0xFF14354D,0xFF080B19,0xFF0D1828,0xFF2C7B9C,0xFF14334A,0xFF090D1B,0xFF0C1626,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1423,0xFF0B1323,0xFF0B1525,0xFF040918,0xFF274454,0xFF437485,0xFF030617,0xFF0E1828,0xFF0B1525,0xFF0D1727,0xFF040B1B,0xFF2E4555,
      0xFFA9F0FF,0xFF9CE4FD,0xFFA2E6FC,0xFFB4EBFD,0xFFBFEFFD,0xFFAFEAFC,0xFF98E3FC,0xFF8BE1FC,0xFF92E3FD,0xFF80DCF8,0xFF47C8F1,0xFF49D3FD,
      0xFF36A0CA,0xFF0F3F6A,0xFF114371,0xFF082A46,0xFF030D19,0xFF0E2034,0xFF3F3454,0xFF2D2740,0xFF060E1C,0xFF0D1425,0xFF0B1627,0xFF14557C,
      0xFF0E2036,0xFF153852,0xFF060819,0xFF182D3F,0xFF3BA1C7,0xFF16415A,0xFF080817,0xFF0C1828,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,
      0xFF0B1323,0xFF0B1323,0xFF0C1727,0xFF030514,0xFF315F73,0xFF39697C,0xFF030516,0xFF0E1828,0xFF0C1525,0xFF0D1626,0xFF0B1424,0xFF0D1727,
      0xFF76B0C1,0xFFA0EBFD,0xFF9BE1F9,0xFF9BE3FC,0xFFACE9FD,0xFFBCEFFD,0xFFAAE8FC,0xFF91E1FB,0xFF8BE0FC,0xFF93E6FE,0xFF5ED0F4,0xFF3EC1ED,
      0xFF49D1FC,0xFF339BC8,0xFF0D3A67,0xFF124574,0xFF102643,0xFF000B16,0xFFC74784,0xFF863E6F,0xFF052332,0xFF101B2F,0xFF0C2038,0xFF06314A,
      0xFF0A2B42,0xFF0C1628,0xFF2D5668,0xFF4EC6EC,0xFF194865,0xFF070614,0xFF0C1828,0xFF0B1525,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1423,0xFF0D1727,0xFF020211,0xFF3F7B93,0xFF457C91,0xFF020414,0xFF0E1829,0xFF0C1525,0xFF0C1525,0xFF0E1829,0xFF000414,
      0xFF6B98A8,0xFFB3F9FF,0xFF9EE1F9,0xFF9DE3FB,0xFF9FE5FD,0xFFB6EDFD,0xFFB1EBFC,0xFF94E1FB,0xFF8BE1FC,0xFF8EE3FD,0xFF55CCF3,0xFF41C5F0,
      0xFF43C2ED,0xFF46CFF9,0xFF2273A0,0xFF0B3764,0xFF11426E,0xFF09192D,0xFF1C1428,0xFF13182D,0xFF112133,0xFF154162,0xFF044A6E,0xFF441E3E,
      0xFF614668,0xFF4593A6,0xFF55D6F9,0xFF15435D,0xFF080715,0xFF0C1829,0xFF0B1524,0xFF0B1524,0xFF0C1524,0xFF0B1424,0xFF0B1423,0xFF0B1424,
      0xFF0B1423,0xFF0B1323,0xFF0D1727,0xFF020312,0xFF3F819B,0xFF5FAEC7,0xFF030615,0xFF0D1828,0xFF0B1424,0xFF0C1525,0xFF0B1525,0xFF0A1324,
      0xFF111F2F,0xFF7EB6C8,0xFFA8EEFE,0xFF9DE2FA,0xFFA1E5FC,0xFFB6EDFE,0xFFAEEAFC,0xFF8DE0FB,0xFF91E4FD,0xFF75D9F8,0xFF42C4F0,0xFF47C8F2,
      0xFF42C5F0,0xFF43C9F3,0xFF3CB4DF,0xFF0F3F6B,0xFF104270,0xFF0E2F50,0xFF05111D,0xFF0A1727,0xFF0A0F1F,0xFF040719,0xFF091828,0xFF537492,
      0xFF7CD5F9,0xFF4BCBF2,0xFF11354F,0xFF080816,0xFF0C1828,0xFF0B1424,0xFF0B1524,0xFF0C1524,0xFF0B1524,0xFF0B1423,0xFF0B1423,0xFF0B1424,
      0xFF0B1423,0xFF0B1423,0xFF0C1727,0xFF050615,0xFF2A617A,0xFF79E5FA,0xFF162738,0xFF080F1F,0xFF0D1727,0xFF0C1525,0xFF0B1424,0xFF0E192A,
      0xFF000214,0xFF416171,0xFFADF5FF,0xFF9BE1FA,0xFFABE9FD,0xFFB7ECFD,0xFF9EE5FC,0xFF92E3FC,0xFF81DDF9,0xFF49CAF4,0xFF46CCF7,0xFF40BEE9,
      0xFF37ACD9,0xFF41C6F0,0xFF45CAF4,0xFF1A5D88,0xFF0E3B67,0xFF103E67,0xFF080F20,0xFF050514,0xFF0E1C2D,0xFF2D6379,0xFF56BFDC,0xFF5CECFF,
      0xFF35ABD0,0xFF0C283E,0xFF090B1A,0xFF0C1828,0xFF0B1423,0xFF0B1424,0xFF0C1524,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1423,0xFF0C1626,0xFF080B1A,0xFF153B50,0xFF74ECFF,0xFF579CB4,0xFF030818,0xFF0B1424,0xFF0D1929,0xFF0B1525,0xFF0F1929,
      0xFF010717,0xFF52798C,0xFFAEF3FD,0xFFA7E2F6,0xFFB8ECFB,0xFFAAE6F9,0xFF94E1FA,0xFF7CDEFC,0xFF4FD2FC,0xFF45CAF4,0xFF3EB7E2,0xFF309FCD,
      0xFF319FCD,0xFF41C2EC,0xFF47CEF8,0xFF236F9A,0xFF072A56,0xFF0C3762,0xFF142E44,0xFF32718A,0xFF56C2E0,0xFF62E5FF,0xFF55E0FF,0xFF2F8BAE,
      0xFF0C192B,0xFF0A0E1D,0xFF0C1829,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0B1525,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0B1323,0xFF0A1828,0xFF4DB9DD,0xFF7EEDFF,0xFF4991A9,0xFF0A1324,0xFF050717,0xFF0B1424,0xFF0E1A2B,
      0xFF060C1C,0xFF325469,0xFFA3F4FF,0xFFB0F1FF,0xFFA4EEFF,0xFF87E9FF,0xFF65E2FF,0xFF42C4F1,0xFF37A6D1,0xFF3399C3,0xFF319ECB,0xFF2F9FCC,
      0xFF31A1CF,0xFF42C0E9,0xFF47CDF5,0xFF27739B,0xFF246188,0xFF43A7CB,0xFF5AD0F3,0xFF60E1FF,0xFF5DE0FF,0xFF48CBF5,0xFF1F6584,0xFF090D1C,
      0xFF0B1222,0xFF0C1627,0xFF0B1423,0xFF0B1424,0xFF0B1524,0xFF0B1524,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0A1323,0xFF0B1423,0xFF0C1727,0xFF070715,0xFF266885,0xFF6CE4FF,0xFF78E4FF,0xFF5BBAD7,0xFF295469,0xFF0C1626,0xFF050615,
      0xFF060919,0xFF020718,0xFF295F7A,0xFF47A7CC,0xFF3EA6CD,0xFF2D8DB1,0xFF1B6384,0xFF1D6692,0xFF2A8AB7,0xFF319CC9,0xFF329DC9,0xFF2E98C5,
      0xFF37ABD7,0xFF4CCBF3,0xFF4FCDF6,0xFF54CAF1,0xFF60DCFF,0xFF61DEFF,0xFF5AD6FE,0xFF4DD3FF,0xFF35A5CB,0xFF163B52,0xFF080816,0xFF0B1525,
      0xFF0B1526,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1625,0xFF0C1525,0xFF0C1524,0xFF0C1525,
      0xFF0B1423,0xFF0A1323,0xFF0A1323,0xFF0B1423,0xFF0B1423,0xFF0A1324,0xFF43ADD0,0xFF6DE1FF,0xFF71DDFF,0xFF6DE5FF,0xFF59BFDC,0xFF3F87A1,
      0xFF2B5A70,0xFF1C394D,0xFF0D1C2D,0xFF07182B,0xFF091C31,0xFF0D2640,0xFF154367,0xFF2477A2,0xFF3CB0DA,0xFF3EB2DD,0xFF44B9E4,0xFF4BC5EE,
      0xFF51D2FA,0xFF56D6FE,0xFF59D5FE,0xFF5AD4FC,0xFF57D0F7,0xFF4FD4FF,0xFF41C4EE,0xFF226C8A,0xFF0B1526,0xFF090C1B,0xFF0D1828,0xFF0B1525,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1524,0xFF0C1524,0xFF0C1525,0xFF0C1525,0xFF0C1525,
      0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1423,0xFF0C1626,0xFF0A0E1E,0xFF10273B,0xFF46BADF,0xFF65E0FF,0xFF68D4F6,0xFF6BDEFF,0xFF6AE5FF,
      0xFF68E4FF,0xFF65DBFE,0xFF5ED0F1,0xFF57C2E2,0xFF53C0E3,0xFF51C9F2,0xFF4ECDF6,0xFF4ED0F9,0xFF52D3FC,0xFF54D6FF,0xFF53D6FF,0xFF53D6FF,
      0xFF54D5FD,0xFF55D2FA,0xFF53D1F9,0xFF4FD5FF,0xFF43C8F3,0xFF2A87AA,0xFF132F42,0xFF080916,0xFF0C1424,0xFF0C1728,0xFF0C1525,0xFF0C1525,
      0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0B1524,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,
      0xFF0B1323,0xFF0B1423,0xFF0B1423,0xFF0B1423,0xFF0B1423,0xFF0C1626,0xFF090C1C,0xFF102436,0xFF3BA2C4,0xFF5CE1FF,0xFF63DBFF,0xFF62D2F6,
      0xFF62D3F7,0xFF64D8FA,0xFF65DAFE,0xFF64DBFF,0xFF62DAFF,0xFF5BD6FB,0xFF53D3FB,0xFF51D3FE,0xFF52D2FC,0xFF53D2FB,0xFF52D0F8,0xFF51D0F9,
      0xFF4ED4FF,0xFF4AD5FF,0xFF41C1EB,0xFF2E88A9,0xFF15384D,0xFF090B19,0xFF0A0E1E,0xFF0D1829,0xFF0C1626,0xFF0C1625,0xFF0C1525,0xFF0C1525,
      0xFF0C1525,0xFF0C1424,0xFF0B1424,0xFF0B1424,0xFF0A1423,0xFF0B1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0B1424,
      0xFF0B1323,0xFF0B1323,0xFF0B1423,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0C1727,0xFF0A0F1F,0xFF0A1020,0xFF26637B,0xFF45B7DA,0xFF50D7FF,
      0xFF55DBFF,0xFF5CDBFF,0xFF5FD7FC,0xFF5ED5F9,0xFF5DD4F8,0xFF58D1F7,0xFF52D0F8,0xFF4FD2FC,0xFF4ED4FF,0xFF4CD6FF,0xFF4AD4FF,0xFF43C6F1,
      0xFF34A4CA,0xFF246A88,0xFF122D40,0xFF090B19,0xFF090C1C,0xFF0C1627,0xFF0B1626,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0C1525,0xFF0B1424,
      0xFF0B1323,0xFF0B1322,0xFF0B1423,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0C1626,0xFF0B1425,0xFF070716,0xFF0D1829,0xFF1B4960,
      0xFF2B80A0,0xFF3AA9D0,0xFF41BDE6,0xFF43C7F0,0xFF44CAF4,0xFF43C9F2,0xFF43C6EF,0xFF40BCE3,0xFF39A8CC,0xFF2D8AAB,0xFF22627C,0xFF15354A,
      0xFF0B1323,0xFF080716,0xFF090F1E,0xFF0C1627,0xFF0C1625,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1525,
      0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0C1424,0xFF0C1525,0xFF0D1625,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0C1524,
      0xFF0B1322,0xFF0A1322,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0C1727,0xFF0B1323,0xFF080917,
      0xFF080716,0xFF0B1323,0xFF102334,0xFF143145,0xFF17374D,0xFF16364B,0xFF153044,0xFF112334,0xFF0C1524,0xFF080B1A,0xFF080916,0xFF090D1C,
      0xFF0B1424,0xFF0C1727,0xFF0B1525,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1524,0xFF0C1524,0xFF0C1524,
      0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0D1626,0xFF0C1524,0xFF0C1525,0xFF0C1525,0xFF0C1524,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1524,
      0xFF0B1322,0xFF0B1323,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1525,0xFF0C1627,
      0xFF0C1727,0xFF0B1424,0xFF0A1020,0xFF0A0E1E,0xFF090D1C,0xFF090D1C,0xFF0A0E1E,0xFF0A1020,0xFF0B1424,0xFF0C1627,0xFF0C1728,0xFF0C1626,
      0xFF0B1424,0xFF0B1423,0xFF0B1423,0xFF0B1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0B1424,0xFF0B1524,0xFF0C1525,0xFF0B1424,
      0xFF0B1423,0xFF0C1524,0xFF0C1524,0xFF0B1423,0xFF0B1424,0xFF0B1424,0xFF0B1423,0xFF0B1323,0xFF0B1424,0xFF0B1424,0xFF0C1424,0xFF0C1524,
      0xFF0C1524,0xFF0C1524,0xFF0B1524,0xFF0B1525,0xFF0B1626,0xFF0C1626,0xFF0B1526,0xFF0B1525,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,
      0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0C1524,0xFF0C1524,0xFF0C1525,0xFF0C1525,0xFF0B1525,
      0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1524,0xFF0C1525,0xFF0C1424,0xFF0B1424,0xFF0C1524,0xFF0C1524,0xFF0C1525,0xFF0C1525,0xFF0C1524,
      0xFF0C1524,0xFF0C1524,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0C1524,0xFF0B1424,0xFF0C1524,
      0xFF0C1524,0xFF0C1524,0xFF0B1424,0xFF0B1423,0xFF0B1424,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0C1524,0xFF0C1524,0xFF0B1424,0xFF0C1524,
      0xFF0C1525,0xFF0B1525,0xFF0B1424,0xFF0C1525,0xFF0C1525,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0B1525,0xFF0B1525,0xFF0C1525,0xFF0B1525,
      0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1525,0xFF0C1524,0xFF0C1524,0xFF0B1424,0xFF0B1424,0xFF0C1525,0xFF0C1524
   };
   ResetLastError();
   g_hunter_logo_created=ResourceCreate("SGH5_Dashboard_Logo_48.bmp",pixels,48,48,0,0,48,
      COLOR_FORMAT_ARGB_NORMALIZE);
   if(!g_hunter_logo_created) Print("Smart Gold Hunter logo creation failed. Error=",GetLastError());
   return g_hunter_logo_created;
}

void HunterReleaseOriginalLogo()
{
   if(g_hunter_logo_created) ResourceFree("::SGH5_Dashboard_Logo_48.bmp");
   g_hunter_logo_created=false;
   g_hunter_logo_attempted=false;
}

// Preserve the panel pixel coordinates.
struct HunterPanelState
{
   bool blocked;
   string block_reason;
   bool news_pause;
   bool high_spread;
   bool daily_close;
   bool friday_close;
   string next_news;
   datetime header_warning_until;
   bool auxiliary_enabled;
};
const string HUNTER_PANEL_PREFIX="SGH_PANEL_";
datetime g_hunter_panel_last_time=0;
string g_hunter_panel_logo="::SGH5_Dashboard_Logo_48.bmp";

void HunterResetPanelTiming()
{
   g_hunter_panel_last_time=0;
}

void HunterPanelDelete()
{
   ObjectsDeleteAll(0,HUNTER_PANEL_PREFIX,-1,-1);
   g_hunter_panel_last_time=0;
   Comment("");
}

void HunterPanelUnload()
{
   HunterPanelDelete();
   HunterReleaseOriginalLogo();
}

void HunterPanelLabel(const string id,const int x,const int y,const string text,
                      const int font_size,const color ink,const string font="Arial Bold")
{
   const string name=HUNTER_PANEL_PREFIX+id;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
}

void HunterPanelRectangle(const string id,const int x,const int y,const int width,
                          const int height,const color fill,const color edge)
{
   const string name=HUNTER_PANEL_PREFIX+id;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill);
   ObjectSetInteger(0,name,OBJPROP_COLOR,edge);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
}

void HunterPanelLogo()
{
   if(!HunterCreateOriginalLogo()) return;
   const string name=HUNTER_PANEL_PREFIX+"LOGO";
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BITMAP_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,25);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,26);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,48);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,48);
   ObjectSetString(0,name,OBJPROP_BMPFILE,0,g_hunter_panel_logo);
   ObjectSetString(0,name,OBJPROP_BMPFILE,1,g_hunter_panel_logo);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
}

string HunterPanelModeName(const int mode)
{
   switch(mode)
   {
      case 0: return "Striker";
      case 1: return "Ultimate Scalper";
      case 2: return "Classic Scalper";
      case 3: return "Swinger";
      case 4: return "Prop Firm Scalper";
      case 5: return "Positive RR";
   }
   return "Custom";
}

string HunterPanelReason(const string reason)
{
   string key=reason;
   StringToLower(key);
   if(key=="") return "";
   if(StringFind(key,"equity")>=0) return "Equity protection";
   if(StringFind(key,"daily loss")>=0 || StringFind(key,"loss limit")>=0) return "Daily loss protection";
   if(StringFind(key,"daily profit")>=0 || StringFind(key,"profit target")>=0) return "Daily profit target";
   if(StringFind(key,"news")>=0) return "News filter";
   if(StringFind(key,"spread")>=0) return "High spread";
   if(StringFind(key,"friday")>=0) return "Friday close protection";
   if(StringFind(key,"market close")>=0) return "Market close protection";
   return StringLen(reason)>28 ? StringSubstr(reason,0,28)+"..." : reason;
}

bool HunterPanelOwnMagic(const long magic,const bool auxiliary_enabled)
{
   // Include magic zero when its auxiliary branch is disabled.
   const long auxiliary_magic=auxiliary_enabled ? 888778 : 0;
   return magic==inp_MagicNo || magic==auxiliary_magic ||
          (inp_UseMultiProfileMode && magic>=777771 && magic<=777777);
}

// Include orders in one direction only; use account equity as the denominator.
double HunterPanelPendingRisk(const bool buy,const bool auxiliary_enabled)
{
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0) return 0.0;
   double amount=0.0;
   for(int i=OrdersTotal()-1;i>=0;--i)
   {
      if(OrderGetTicket(i)==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol ||
         !HunterPanelOwnMagic(OrderGetInteger(ORDER_MAGIC),auxiliary_enabled)) continue;
      const ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(buy ? (type!=ORDER_TYPE_BUY_LIMIT && type!=ORDER_TYPE_BUY_STOP)
             : (type!=ORDER_TYPE_SELL_LIMIT && type!=ORDER_TYPE_SELL_STOP)) continue;
      const double entry=OrderGetDouble(ORDER_PRICE_OPEN);
      const double stop=OrderGetDouble(ORDER_SL);
      const double volume=OrderGetDouble(ORDER_VOLUME_CURRENT);
      if(entry<=0.0 || stop<=0.0 || volume<=0.0) continue;
      const double risk=HunterRiskMoney(volume,entry,stop);
      if(risk>0.0) amount+=risk;
   }
   return amount/equity*100.0;
}

string HunterPanelAmount(const bool enabled,const double amount)
{
   return inp_UsePropFirmMode && enabled ? "ON  $"+DoubleToString(amount,0) : "OFF";
}

void HunterPanelProfile(const string id,const string caption,const int mode,
                        const bool portfolio_enabled,const int x,const int y)
{
   const bool enabled=inp_UseMultiProfileMode ? portfolio_enabled : ((int)inp_Mode==mode);
   HunterPanelLabel(id,x,y,caption+(enabled ? "ON" : "OFF"),8,
                    enabled ? (color)0x32cd32 : (color)0x7e8a96);
}

void HunterPanelRender(const HunterPanelState &s)
{
   if(!inp_ShowPanel)
   {
      HunterPanelDelete();
      return;
   }
   const datetime now=TimeCurrent();
   if(g_hunter_panel_last_time!=0 && now==g_hunter_panel_last_time) return;
   g_hunter_panel_last_time=now;
   const string mode=inp_UseMultiProfileMode ? "PORTFOLIO" : HunterPanelModeName((int)inp_Mode);
   string status="RUNNING | "+mode,reason="";
   color status_color=(color)0x008a28;
   if(s.blocked)
   {
      status="BLOCKED | "+mode;
      reason=HunterPanelReason(s.block_reason);
      status_color=(color)0x3c14dc;
   }
   else if(s.friday_close || s.daily_close || s.news_pause || s.high_spread)
   {
      status="PAUSED | "+mode;
      status_color=(color)0x008cff;
      if(s.friday_close) reason="Friday close protection";
      else if(s.daily_close) reason="Market close protection";
      else if(s.news_pause) reason="News filter";
      else reason="High spread";
   }

   // History selection is a side effect: keep this after both panel gates.
   const double today_pl=SGH_TodayClosedProfit();

   int positions=0,pending=0;
   double floating=0.0;
   for(int i=PositionsTotal()-1;i>=0;--i)
   {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket) || PositionGetString(POSITION_SYMBOL)!=_Symbol ||
         !HunterPanelOwnMagic(PositionGetInteger(POSITION_MAGIC),s.auxiliary_enabled)) continue;
      ++positions;
      floating+=PositionGetDouble(POSITION_PROFIT);
      floating+=PositionGetDouble(POSITION_SWAP);
   }
   const double buy_risk=HunterPanelPendingRisk(true,s.auxiliary_enabled);
   const double sell_risk=HunterPanelPendingRisk(false,s.auxiliary_enabled);
   string risk="0.00%";
   if(buy_risk>0.000001 || sell_risk>0.000001)
      risk=DoubleToString(MathMax(buy_risk,sell_risk),2)+"% "+(sell_risk<=buy_risk ? "BUY" : "SELL");
   const string cap=inp_UseMultiProfileMode && inp_PortfolioMaxDirectionalRiskPercent>0.0 ?
                    DoubleToString(inp_PortfolioMaxDirectionalRiskPercent,2)+"%" : "OFF";
   string next_news=inp_UseHighImpactNewsFilter ? "No high impact news" :
                    (inp_UseMajorNewsFilter ? "No selected high-impact news" : "News filter OFF");
   if(!inp_UseHighImpactNewsFilter && !inp_UseMajorNewsFilter) next_news="News filter OFF";
   else if(s.next_news!="") next_news=s.next_news;
   if(StringLen(next_news)>34) next_news=StringSubstr(next_news,0,34)+"...";

   HunterPanelRectangle("BG",10,12,520,410,(color)0x11161b,(color)0x3b4957);
   HunterPanelRectangle("INNER",18,20,504,394,(color)0x0f1419,(color)0x2d3843);
   HunterPanelLogo();
   HunterPanelLabel("TITLE",106,30,"SMART GOLD HUNTER",18,clrWhite);
   if(now<s.header_warning_until)
      HunterPanelLabel("HEADER_WARN",108,55,"Please verify your profile, lot size and risk settings before trading.",8,(color)0x4763ff);
   else ObjectDelete(0,HUNTER_PANEL_PREFIX+"HEADER_WARN");
   HunterPanelRectangle("STATUS_BG",106,71,404,25,status_color,(color)0x1e2a34);
   HunterPanelLabel("STATUS",186,76,"STATUS: "+status,10,clrWhite);
   if(reason!="") HunterPanelLabel("STATUS_DETAIL",108,99,"Reason: "+reason,10,(color)0x00a5ff);
   else ObjectDelete(0,HUNTER_PANEL_PREFIX+"STATUS_DETAIL");
   HunterPanelRectangle("SEP1",24,118,492,1,(color)0x5b6570,(color)0x5b6570);
   HunterPanelLabel("ACC_TITLE",30,130,"ACCOUNT",10,(color)0xd5b55a);
   HunterPanelLabel("RISK_L",30,151,"Total Pending Risk",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("RISK_V",155,150,risk,9,clrWhite);
   HunterPanelLabel("CAP_L",30,171,"Max Exposure",9,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("CAP_V",155,170,cap,10,clrWhite);
   HunterPanelLabel("DAY_L",30,191,"Today P/L",9,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("DAY_V",155,190,(today_pl>=0.0 ? "+" : "")+DoubleToString(today_pl,2),10,today_pl>=0.0 ? (color)0x32cd32 : (color)0x4763ff);
   HunterPanelLabel("FLT_L",30,211,"Floating P/L",9,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("FLT_V",155,210,(floating>=0.0 ? "+" : "")+DoubleToString(floating,2),10,floating>=0.0 ? (color)0x32cd32 : (color)0x4763ff);
   HunterPanelRectangle("PROT_BOX",265,128,245,94,(color)0x141b21,(color)0x43515e);
   HunterPanelLabel("PROT_TITLE",277,136,"PROTECTIONS",10,(color)0xd5b55a);
   HunterPanelLabel("DP_L",277,157,"Daily Profit",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("DP_V",367,156,HunterPanelAmount(inp_UseDailyProfitTarget,inp_DailyProfitTargetUSD),9,
      clrWhite);
   HunterPanelLabel("DL_L",277,178,"Daily Loss",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("DL_V",367,177,HunterPanelAmount(inp_UseDailyLossLimit,inp_DailyLossLimitUSD),9,clrWhite);
   HunterPanelLabel("DD_L",277,199,"Daily DD",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("DD_V",367,198,inp_UsePropFirmMode
      && inp_UseEquityProtection ? "ON  "+DoubleToString(inp_DailyEquityProtectionPercent,1)+"%" : "OFF",9,
      clrWhite);
   HunterPanelRectangle("SEP2",24,231,492,1,(color)0x5b6570,(color)0x5b6570);
   HunterPanelLabel("TRD_TITLE",30,243,"TRADING",10,(color)0xd5b55a);
   HunterPanelLabel("PM",358,243,"PORTFOLIO: "+(inp_UseMultiProfileMode ? "ON" : "OFF"),9,inp_UseMultiProfileMode ? (color)0xe6a43a : (color)0x7e8a96);
   HunterPanelProfile("P1","Striker: ",0,inp_PortfolioUseStriker,30,263);
   HunterPanelProfile("P2","ULT Scalper: ",1,inp_PortfolioUseUltimateScalper,175,263);
   HunterPanelProfile("P3","Classic: ",2,inp_PortfolioUseScalper,340,263);
   HunterPanelProfile("P4","Positive RR: ",5,inp_PortfolioUsePRRScalping,30,282);
   HunterPanelProfile("P5","Swinger: ",3,inp_PortfolioUseSwinger,175,282);
   HunterPanelProfile("P6","Prop Firm: ",4,inp_PortfolioUsePropScalper,340,282);
   HunterPanelProfile("P7","Custom: ",6,inp_PortfolioUseCustom,30,301);
   HunterPanelLabel("POS_L",175,302,"Positions",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("POS_V",235,301,IntegerToString(positions),9,clrWhite);
   for(int i=OrdersTotal()-1;i>=0;--i)
   {
      if(OrderGetTicket(i)==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol ||
         !HunterPanelOwnMagic(OrderGetInteger(ORDER_MAGIC),s.auxiliary_enabled)) continue;
      const long type=OrderGetInteger(ORDER_TYPE);
      if(type>=ORDER_TYPE_BUY_LIMIT && type<=ORDER_TYPE_SELL_STOP) ++pending;
   }
   HunterPanelLabel("ORD_L",340,302,"Pending",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("ORD_V",390,301,IntegerToString(pending),9,clrWhite);
   HunterPanelRectangle("SEP3",24,321,492,1,(color)0x5b6570,(color)0x5b6570);
   HunterPanelLabel("NEWS_TITLE",30,333,"NEWS",10,(color)0xd5b55a);
   HunterPanelLabel("FRIDAY_TITLE",350,333,"FRIDAY",10,(color)0xd5b55a);
   HunterPanelLabel("NEWS_FILTER",30,354,
      "Filter: "+(inp_UseHighImpactNewsFilter ? "ALL HIGH" : (inp_UseMajorNewsFilter ? "SELECTED" : "OFF")),
      9,clrWhite);
   string friday="OFF";
   if(inp_UseFridayCloseProtection)
      friday=inp_UseManualFridayCloseTime ? "ON | "+StringFormat("%02d:%02d",inp_FridayCloseHour,
         inp_FridayCloseMinute) : "ON | SESSION";
   HunterPanelLabel("FRIDAY",350,354,friday,9,clrWhite);
   HunterPanelLabel("NEWS_NEXT_L",30,375,"Next:",8,(color)0xaeb8c2,"Arial");
   HunterPanelLabel("NEWS_NEXT_V",67,374,next_news,9,clrWhite,"Arial");
   datetime server=TimeTradeServer();
   if(server==0) server=TimeCurrent();
   const double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   const int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   const double unit=point*((digits==3 || digits==5) ? 10.0 : 1.0);
   const double spread=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/unit;
   HunterPanelLabel("FOOT",30,401,"Server "+TimeToString(server,TIME_MINUTES)+"   |   Spread "+DoubleToString(spread,1)+" pts",8,(color)0xaeb8c2,"Arial");
   Comment("");
   ChartRedraw(0);
}

#ifndef HUNTER_EXECUTION_MQH
#define HUNTER_EXECUTION_MQH

void HunterResetOrchestration();
void HunterResetPanelTiming();

MqlTradeRequest hunter_trade_request;
MqlTradeResult hunter_trade_result;
datetime hunter_panel_ready_at=0;
bool hunter_auxiliary_magic_enabled=true; // Auxiliary order ownership is enabled at startup.

long HunterAuxiliaryMagic()
{
   return hunter_auxiliary_magic_enabled?888778:0;
}
bool HunterOwnsMagic(const long magic)
{
   return magic==(long)inp_MagicNo || magic==HunterAuxiliaryMagic() ||
      (inp_UseMultiProfileMode && magic>=777771 && magic<=777777);
}
ENUM_ORDER_TYPE_FILLING HunterExecutionFillPolicy(const string symbol)
{
   long flags=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
   if((flags&2)!=0) return ORDER_FILLING_IOC;
   return (flags&1)!=0?ORDER_FILLING_FOK:ORDER_FILLING_RETURN;
}
void HunterClearTradeRequest()
{
   ResetLastError();
   ZeroMemory(hunter_trade_request);
   ZeroMemory(hunter_trade_result);
}

// Consume the marker during initialization after parameters have changed.
string HunterRepriceKey()
{
   return "SGH5_REPRICE_"+(string)AccountInfoInteger(ACCOUNT_LOGIN)+"_"+_Symbol+"_"+(string)inp_MagicNo;
}

// The main-magic removal request leaves its symbol field empty.
void HunterDeletePending(const ulong ticket)
{
   if(!OrderSelect(ticket)) return;
   string symbol=OrderGetString(ORDER_SYMBOL);
   if(!HunterTradingSessionOpen(symbol)) return;
   HunterClearTradeRequest();
   hunter_trade_request.action=TRADE_ACTION_REMOVE;
   hunter_trade_request.magic=(ulong)(long)inp_MagicNo;
   hunter_trade_request.order=ticket;
   bool sent=OrderSend(hunter_trade_request,hunter_trade_result);
}

// A distinct local request path used for auxiliary/portfolio removal.
bool HunterRemoveLocalPending(const ulong ticket,const long magic,MqlTradeResult &result)
{
   MqlTradeRequest request={};
   ZeroMemory(result);
   request.action=TRADE_ACTION_REMOVE;
   request.order=ticket;
   request.symbol=_Symbol;
   request.magic=(ulong)magic;
   return OrderSend(request,result);
}

// Portfolio expiry path: direct request, no session or retcode check here.
void HunterDeletePortfolioPending(const ulong ticket,const long magic)
{
   MqlTradeResult result={};
   bool sent=HunterRemoveLocalPending(ticket,magic,result);
}

// Remove only auxiliary buy/sell stops, reselecting each order before submission.
void HunterProcessAuxiliaryOrders()
{
   for(int index=OrdersTotal()-1;index>=0;index--)
   {
      ulong ticket=OrderGetTicket(index);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=HunterAuxiliaryMagic()) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type!=ORDER_TYPE_BUY_STOP && type!=ORDER_TYPE_SELL_STOP) continue;
      if(!OrderSelect(ticket) || OrderGetInteger(ORDER_MAGIC)!=HunterAuxiliaryMagic()) continue;
      if(!HunterTradingSessionOpen(_Symbol)) continue;
      MqlTradeResult result={};
      bool sent=HunterRemoveLocalPending(ticket,HunterAuxiliaryMagic(),result);
   }
}

// Preserve both session checks and the distinct main/other-magic removal requests.
void SGH_DeleteOwnedPendings()
{
   if(!HunterTradingSessionOpen(_Symbol)) return;
   for(int index=OrdersTotal()-1;index>=0;index--)
   {
      ulong ticket=OrderGetTicket(index);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      if(!HunterOwnsMagic(magic)) continue;
      magic=OrderGetInteger(ORDER_MAGIC);
      if(magic==(long)inp_MagicNo) HunterDeletePending(ticket);
      else
      {
         MqlTradeResult result={};
         bool sent=HunterRemoveLocalPending(ticket,magic,result);
      }
   }
}

// Check all position/order types with the main magic in an inclusive price band.
bool HunterHasNearbySingleOrder(const double entry)
{
   bool found=false;
   const double radius=HunterPip()*50.0;
   for(int index=PositionsTotal()-1;index>=0;index--)
   {
      ulong ticket=PositionGetTicket(index);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol
         || PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo) continue;
      double price=PositionGetDouble(POSITION_PRICE_OPEN);
      if(price-radius<=entry && entry<=price+radius)
      {
         found=true;
         break;
      }
   }
   // Continue scanning orders after finding a matching position.
   for(int index=OrdersTotal()-1;index>=0;index--)
   {
      ulong ticket=OrderGetTicket(index);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol
         || OrderGetInteger(ORDER_MAGIC)!=(long)inp_MagicNo) continue;
      double price=OrderGetDouble(ORDER_PRICE_OPEN);
      if(price-radius<=entry && entry<=price+radius) return true;
   }
   return found;
}

// Submit directly, without OrderCheck or additional price normalization.
void HunterPlaceSinglePending(const ENUM_ORDER_TYPE type,const double volume,const double entry,
                              const double sl,const double tp,const datetime expires)
{
   HunterClearTradeRequest();
   ENUM_ORDER_TYPE_TIME lifetime=ORDER_TIME_GTC;
   if(expires==0)
   {
      long flags=SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_MODE);
      if((flags&1)==0)
      {
         lifetime=ORDER_TIME_DAY;
         if((flags&2)==0)
         {
            hunter_trade_result.retcode=TRADE_RETCODE_INVALID_EXPIRATION;
            hunter_trade_result.comment="Invalid expiration type";
            return;
         }
      }
   }
   hunter_trade_request.action=TRADE_ACTION_PENDING;
   hunter_trade_request.symbol=_Symbol;
   hunter_trade_request.magic=(ulong)(long)inp_MagicNo;
   hunter_trade_request.type=type;
   hunter_trade_request.volume=volume;
   hunter_trade_request.price=entry;
   hunter_trade_request.sl=sl;
   hunter_trade_request.tp=tp;
   hunter_trade_request.deviation=0;
   hunter_trade_request.type_time=lifetime;
   hunter_trade_request.expiration=expires;
   hunter_trade_request.type_filling=HunterExecutionFillPolicy(_Symbol);
   hunter_trade_request.comment=inp_TradeComment;
   bool sent=OrderSend(hunter_trade_request,hunter_trade_result);
}

// Accept PLACED, DONE and DONE_PARTIAL; strategy stop updates use a different policy.
bool HunterUpdateSingleStops(const ulong ticket,double sl,double tp)
{
   if(!PositionSelectByTicket(ticket)) return false;
   string reason="";
   if(!HunterValidateStops(ticket,sl,tp,reason)) return false;
   HunterClearTradeRequest();
   hunter_trade_request.action=TRADE_ACTION_SLTP;
   hunter_trade_request.position=ticket;
   hunter_trade_request.symbol=PositionGetString(POSITION_SYMBOL);
   hunter_trade_request.magic=(ulong)(long)inp_MagicNo;
   hunter_trade_request.sl=sl;
   hunter_trade_request.tp=tp;
   if(!OrderSend(hunter_trade_request,hunter_trade_result)) return false;
   return hunter_trade_result.retcode>=10008 && hunter_trade_result.retcode<=10010;
}

// Delete pending orders first, then scan positions in reverse. Request acceptance is the
// only success gate here; actual final fills are not checked.
void SGH_CloseOwnedPositionsAndPendings()
{
   SGH_DeleteOwnedPendings();
   for(int index=PositionsTotal()-1;index>=0;index--)
   {
      ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(!HunterOwnsMagic(magic)) continue;
      ENUM_POSITION_TYPE side=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(side==POSITION_TYPE_BUY || side==POSITION_TYPE_SELL)
      {
         HunterClearTradeRequest();
         hunter_trade_request.action=TRADE_ACTION_DEAL;
         hunter_trade_request.symbol=_Symbol;
         hunter_trade_request.volume=volume;
         hunter_trade_request.magic=(ulong)magic;
         hunter_trade_request.position=ticket;
         hunter_trade_request.type=side==POSITION_TYPE_BUY?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
         hunter_trade_request.price=SymbolInfoDouble(_Symbol,side==POSITION_TYPE_BUY?SYMBOL_BID:SYMBOL_ASK);
         hunter_trade_request.comment="EquityProtection";
         hunter_trade_request.type_filling=HunterExecutionFillPolicy(_Symbol);
         if(OrderSend(hunter_trade_request,hunter_trade_result)) continue;
         Print("Position close failed. Error=",GetLastError()," Retcode=",hunter_trade_result.retcode);
      }
      // Emit a second error line after a failed close request.
      Print("Position close failed. Error=",GetLastError());
   }
}

// Explicit removal deletes orders; a parameter change writes the reprice marker.
void HunterDeinitializeExecution(const int reason)
{
   if(reason==REASON_REMOVE)
   {
      for(int index=OrdersTotal()-1;index>=0;index--)
      {
         ulong ticket=OrderGetTicket(index);
         if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
         long magic=OrderGetInteger(ORDER_MAGIC);
         if(!HunterOwnsMagic(magic)) continue;
         ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(type<ORDER_TYPE_BUY_LIMIT || type>ORDER_TYPE_SELL_STOP) continue;
         MqlTradeResult result={};
         if(!HunterRemoveLocalPending(ticket,magic,result))
            Print("Order cleanup failed. Error=",GetLastError()," Retcode=",result.retcode);
      }
   }
   else if(reason==REASON_PARAMETERS)
   {
      datetime now=TimeCurrent();
      GlobalVariableSet(HunterRepriceKey(),(double)now);
   }
   ObjectsDeleteAll(0,"SGH_PANEL_",-1,-1);
   HunterResetPanelTiming();
   Comment("");
}

void HunterExecutionTradeTransaction(const MqlTradeTransaction &transaction)
{
   if(transaction.type==TRADE_TRANSACTION_DEAL_ADD)
   {
      bool portfolio_position=inp_UseMultiProfileMode && transaction.position!=0 &&
                              PositionSelectByTicket(transaction.position);
      if(portfolio_position)
      {
         long magic=PositionGetInteger(POSITION_MAGIC);
         if(magic>=777771 && magic<=777777)
            HunterManagePortfolioPosition(transaction.position,HunterPortfolioModeFromMagic(magic));
      }
      else
      {
         HunterAdjustSingleInitialStop(transaction.order,transaction.position,transaction.price);
         HunterAdjustPropInitialStop(transaction.position,transaction.price);
      }
   }
   if(transaction.type!=TRADE_TRANSACTION_DEAL_ADD || transaction.deal==0
      || !HistoryDealSelect(transaction.deal)) return;
   long magic=HistoryDealGetInteger(transaction.deal,DEAL_MAGIC);
   long entry=HistoryDealGetInteger(transaction.deal,DEAL_ENTRY);
   if(entry!=DEAL_ENTRY_IN && entry!=DEAL_ENTRY_INOUT) return;
   string comment=HistoryDealGetString(transaction.deal,DEAL_COMMENT);
   ulong order=(ulong)HistoryDealGetInteger(transaction.deal,DEAL_ORDER);
   if(order!=0 && HistoryOrderSelect(order))
   {
      string order_comment=HistoryOrderGetString(order,ORDER_COMMENT);
      if(order_comment!="") comment=order_comment;
   }

   // Keep their input reads above because history selection is an observable effect.
}

// OnInit reprice branch: marker is deleted before any trade request, and a
// successful deletion can be followed by a rejected directional-risk replacement.
void HunterRepriceExistingPendings()
{
   string key=HunterRepriceKey();
   if(!GlobalVariableCheck(key)) return;
   GlobalVariableDel(key);
   for(int index=OrdersTotal()-1;index>=0;index--)
   {
      ulong ticket=OrderGetTicket(index);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type!=ORDER_TYPE_BUY_STOP && type!=ORDER_TYPE_SELL_STOP) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      bool portfolio=inp_UseMultiProfileMode && magic>=777771 && magic<=777777;
      if(magic!=(long)inp_MagicNo && !portfolio) continue;
      double price=OrderGetDouble(ORDER_PRICE_OPEN);
      double old_sl=OrderGetDouble(ORDER_SL);
      double old_tp=OrderGetDouble(ORDER_TP);
      double old_volume=OrderGetDouble(ORDER_VOLUME_CURRENT);
      datetime expiration=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
      string comment=OrderGetString(ORDER_COMMENT);
      int mode=(int)inp_Mode;
      if(portfolio)
      {
         mode=HunterPortfolioModeFromMagic(magic);
         HunterLoadPortfolioProfile(mode);
      }
      else HunterLoadSingleProfile();
      double distance=hunter_profile.stop_loss*(hunter_profile.prop_mode?2.0:1.0);
      double risk_sl=HunterNormalizePrice(price+(type==ORDER_TYPE_BUY_STOP?-1.0:1.0)*HunterPip()*distance);
      double volume=portfolio?HunterPortfolioVolume(mode,distance,type,price,
         risk_sl):HunterSingleVolume(type,price,risk_sl);
      if(volume<=0.0)
      {
         int method=(int)inp_LotMethod;
         if(portfolio)
         {
            double risk,fixed;
            HunterPortfolioLotSettings(mode,method,risk,fixed);
         }
         if(method==1)
         {
            MqlTradeResult removal={};
            bool sent=HunterRemoveLocalPending(ticket,magic,removal);
         }
         continue;
      }
      string reason="";
      volume=HunterFitMargin(type,volume,price,reason);
      if(volume<=0.0) continue;
      double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
      double threshold=step>0.0?0.5*step:0.005;
      if(MathAbs(volume-old_volume)<threshold) continue;
      MqlTradeResult removal={};
      if(!HunterRemoveLocalPending(ticket,magic,removal)) continue;
      if(portfolio && !HunterDirectionalRiskAllowed(type==ORDER_TYPE_BUY_STOP,volume,price,risk_sl,
         reason)) continue;
      MqlTradeRequest request={};
      MqlTradeResult result={};
      MqlTradeCheckResult check={};
      request.action=TRADE_ACTION_PENDING;
      request.symbol=_Symbol;
      request.magic=(ulong)magic;
      request.type=type;
      request.price=price;
      request.sl=old_sl;
      request.tp=old_tp;
      request.volume=volume;
      request.comment=comment;
      long flags=SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_MODE);
      request.type_time=(flags&1)!=0?ORDER_TIME_GTC:ORDER_TIME_DAY;
      if((flags&4)!=0 && expiration>0)
      {
         request.type_time=ORDER_TIME_SPECIFIED;
         request.expiration=expiration;
      }
      request.type_filling=HunterExecutionFillPolicy(_Symbol);
      if(OrderCheck(request,check))
      {
         bool sent=OrderSend(request,result);
      }
   }
   HunterLoadSingleProfile();
}

// Initialize strategy state, protection and chart display.
int HunterInitializeExecution()
{
   ObjectsDeleteAll(0,"SGH_PANEL_",-1,-1);
   HunterResetPanelTiming();
   HunterResetOrchestration();
   uint seed=(uint)GetTickCount()+(uint)(AccountInfoInteger(ACCOUNT_LOGIN)%2147483647);
   MathSrand((int)seed);
   hunter_panel_ready_at=TimeCurrent()+60;
   ZeroMemory(g_sghProtection);
   g_sghProtection.dayStart=-1;
   SGH_ResetProtectionDay();
   HunterLoadSingleProfile();
   if(inp_UseMultiProfileMode && AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      Print("SGH 5 Portfolio Mode requires an MT5 hedging account. Portfolio entries will stay inactive on this account type.");
   HunterInitializeStrategy();
   HunterRepriceExistingPendings();
   return INIT_SUCCEEDED;
}
#endif


// Preserve request ordering and the existing failure behavior.
int hunter_single_bar_count=0;
bool hunter_single_buy_seen=false,hunter_single_sell_seen=false;
ulong hunter_single_prop_adjusted[];

void HunterResetOrchestration()
{
   hunter_single_bar_count=0;
   hunter_single_buy_seen=false;
   hunter_single_sell_seen=false;
   ArrayResize(hunter_single_prop_adjusted,0);
}
void SGH_InvalidateEntryBar()
{
   hunter_single_bar_count=-1;
}

void HunterManageSinglePositions()
{
   const double pip=HunterPip();
   if(hunter_profile.prop_mode)
   {
      if(!HunterTradingSessionOpen(_Symbol)) return;
      HunterAdjustPropInitialStop(0,0);
      datetime now=TimeCurrent();
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      for(int index=PositionsTotal()-1;index>=0;index--)
      {
         ulong ticket=PositionGetTicket(index);
         if(ticket==0 || !PositionSelectByTicket(ticket) ||
            PositionGetString(POSITION_SYMBOL)!=_Symbol ||
            PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo) continue;
         datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
         long type=PositionGetInteger(POSITION_TYPE);
         double entry=PositionGetDouble(POSITION_PRICE_OPEN);
         double sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
         PositionGetDouble(POSITION_VOLUME); // Read volume before the following position fields.
         double normal_sl=HunterNormalizePrice(entry+(type==POSITION_TYPE_BUY?-1.0:1.0)*pip*hunter_profile.stop_loss);
         double normal_tp=HunterNormalizePrice(entry+(type==POSITION_TYPE_BUY?1.0:-1.0)*pip*hunter_profile.take_profit);
         if(now-opened<(hunter_prop_delay_enabled?120:0)) continue;
         if(!HunterTicketMarked(hunter_single_prop_adjusted,ticket))
         {
            if(MathAbs(sl-normal_sl)>pip*5.0 || MathAbs(tp-normal_tp)>pip*5.0)
            {
               if(HunterUpdateSingleStops(ticket,normal_sl,normal_tp))
               {
                  HunterMarkTicket(hunter_single_prop_adjusted,ticket);
                  sl=normal_sl;
                  tp=normal_tp;
               }
            }
         }
         if(type==POSITION_TYPE_BUY)
         {
            if(bid-entry>hunter_profile.trail_start*pip)
            {
               double proposed=HunterNormalizePrice(bid-pip*hunter_profile.trail_distance);
               if(proposed>sl+pip*20.0) HunterUpdateSingleStops(ticket,proposed,tp);
            }
         }
         else if(entry-ask>hunter_profile.trail_start*pip)
         {
            double proposed=HunterNormalizePrice(ask+pip*hunter_profile.trail_distance);
            if(sl==0.0 || proposed<sl-pip*20.0) HunterUpdateSingleStops(ticket,proposed,tp);
         }
      }
      return;
   }
   if((int)inp_Mode!=4)
   {
      HunterAdjustSingleInitialStop(0,0,0.0);
      if(((int)inp_Mode<3 || (int)inp_Mode>5) && inp_UltimateBreakEven && HunterTradingSessionOpen(_Symbol))
      {
         double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         for(int index=PositionsTotal()-1;index>=0;index--)
         {
            ulong ticket=PositionGetTicket(index);
            if(ticket==0 || !PositionSelectByTicket(ticket) ||
               PositionGetString(POSITION_SYMBOL)!=_Symbol ||
               PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo) continue;
            double entry=PositionGetDouble(POSITION_PRICE_OPEN);
            double sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
            long type=PositionGetInteger(POSITION_TYPE);
            if(type==POSITION_TYPE_SELL && entry-ask>=hunter_profile.break_even_trigger*pip)
            {
               double proposed=HunterNormalizePrice(entry-pip*hunter_profile.break_even_lock);
               if(sl==0.0 || proposed<sl) HunterUpdateSingleStops(ticket,proposed,tp);
            }
            else if(type==POSITION_TYPE_BUY && bid-entry>=hunter_profile.break_even_trigger*pip)
            {
               double proposed=HunterNormalizePrice(entry+pip*hunter_profile.break_even_lock);
               if(sl==0.0 || sl<proposed) HunterUpdateSingleStops(ticket,proposed,tp);
            }
         }
      }
   }
   if(hunter_profile.trail_start!=0.0 && HunterTradingSessionOpen(_Symbol))
   {
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      for(int index=PositionsTotal()-1;index>=0;index--)
      {
         ulong ticket=PositionGetTicket(index);
         if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol ||
            PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo) continue;
         double entry=PositionGetDouble(POSITION_PRICE_OPEN);
         double sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
         long type=PositionGetInteger(POSITION_TYPE);
         double proposed=0.0;
         bool modify=false;
         if(type==POSITION_TYPE_SELL && entry-ask>hunter_profile.trail_start*pip)
         {
            proposed=ask+pip*hunter_profile.trail_distance;
            modify=(proposed<sl); // This branch has no exception for a zero stop-loss.
         }
         else if(type==POSITION_TYPE_BUY && bid-entry>hunter_profile.trail_start*pip)
         {
            proposed=bid-pip*hunter_profile.trail_distance;
            modify=(sl<proposed);
         }
         // This path rounds decimals without rounding to the tick size first.
         if(modify && HunterUpdateSingleStops(ticket,HunterDecimalRound(proposed,_Digits),tp)) break;
      }
   }
}

bool HunterApplyEntryProtections()
{
   SGH_CheckDailyProfitLoss();
   bool friday=SGH_CheckFridayClose();
   bool daily=SGH_CheckDailyClose();
   bool news=SGH_CheckNews();
   bool spread=SGH_CheckSpread();
   HunterRenderCurrentPanel(news,spread,daily,friday);
   HunterProcessAuxiliaryOrders();
   return !daily && !friday && !news && !spread && !g_sghProtection.dayLocked;
}

// Tick order is part of the strategy contract: admission/protection, pending
// cleanup, position management, entry protection, generation, then buy/sell.
// No management-before snapshot is introduced into this portfolio path.
void HunterPortfolioTick()
{
   SGH_ResetProtectionDay();
   SGH_CheckEquityProtection();
   for(int index=OrdersTotal()-1;index>=0;index--)
   {
      ulong ticket=OrderGetTicket(index);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      long magic=OrderGetInteger(ORDER_MAGIC);
      if(magic<777771 || magic>777777) continue;
      int mode=HunterPortfolioModeFromMagic(magic);
      HunterLoadPortfolioProfile(mode);
      if(HunterPortfolioEnabled(mode)
         && TimeCurrent()-(datetime)OrderGetInteger(ORDER_TIME_SETUP)<=hunter_profile.expiration_hours*3600) continue;
      if(HunterTradingSessionOpen(_Symbol)) HunterDeletePortfolioPending(ticket,magic);
   }
   for(int index=PositionsTotal()-1;index>=0;index--)
   {
      ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !PositionSelectByTicket(ticket) || PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(magic>=777771 && magic<=777777)
         HunterManagePortfolioPosition(ticket,HunterPortfolioModeFromMagic(magic));
   }
   SGH_ManageAuxiliaryTrailing();
   if(!HunterApplyEntryProtections()
      || AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) return;
   // Evaluation order differs from profile index order: PRR precedes Swinger.
   const int order[7]={0,1,2,5,3,4,6};
   for(int index=0;index<7;index++) HunterGeneratePortfolioSignal(order[index]);
   // Buy submission may change account/order state before sell evaluation.
   HunterSendQueuedDirection(true);
   HunterSendQueuedDirection(false);
}

// Single mode has its own ordering; do not fold it into the portfolio path.
void HunterSingleTick()
{
   HunterLoadSingleProfile();
   SGH_ResetProtectionDay();
   SGH_CheckEquityProtection();
   int buys=0,sells=0;
   for(int index=PositionsTotal()-1;index>=0;index--)
   {
      ulong ticket=PositionGetTicket(index);
      if(!PositionSelectByTicket(ticket) || PositionGetString(POSITION_SYMBOL)!=_Symbol ||
         PositionGetInteger(POSITION_MAGIC)!=(long)inp_MagicNo) continue;
      long type=PositionGetInteger(POSITION_TYPE);
      if(type==POSITION_TYPE_SELL) sells++;
      else if(type==POSITION_TYPE_BUY) buys++;
   }
   datetime latest_exit=0;
   // Only failure enters this scan. Portfolio
   // history selection uses a different condition. Do not silently repair it.
   if(!HistorySelect(0,TimeCurrent()))
   {
      int count=HistoryDealsTotal();
      for(int index=0;index<count && !IsStopped();index++)
      {
         ulong deal=HistoryDealGetTicket(index);
         if(deal==0) continue;
         long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
         HistoryDealGetInteger(deal,DEAL_POSITION_ID);
         long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
         string symbol=HistoryDealGetString(deal,DEAL_SYMBOL);
         if(magic!=(long)inp_MagicNo || symbol!=_Symbol || (entry!=DEAL_ENTRY_OUT
            && entry!=DEAL_ENTRY_OUT_BY)) continue;
         datetime exited=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
         if(exited>latest_exit) latest_exit=exited;
      }
   }
   if(TimeCurrent()-latest_exit<hunter_profile.pause_seconds) return;
   int buy_pending=0,sell_pending=0;
   for(int index=OrdersTotal()-1;index>=0;index--)
   {
      ulong ticket=OrderGetTicket(index);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol
         || OrderGetInteger(ORDER_MAGIC)!=(long)inp_MagicNo) continue;
      if(TimeCurrent()-(datetime)OrderGetInteger(ORDER_TIME_SETUP)>hunter_profile.expiration_hours*3600
         && HunterTradingSessionOpen(_Symbol))
         HunterDeletePending(ticket);
      long type=OrderGetInteger(ORDER_TYPE);
      if(type==ORDER_TYPE_SELL_STOP) sell_pending++;
      else if(type==ORDER_TYPE_BUY_STOP) buy_pending++;
   }
   if(buys>0 || sells>0)
   {
      HunterManageSinglePositions();
      SGH_ManageAuxiliaryTrailing();
      if(buys>0) hunter_single_buy_seen=true;
      if(sells>0) hunter_single_sell_seen=true;
   }
   else SGH_ManageAuxiliaryTrailing();
   if(!HunterApplyEntryProtections() || hunter_single_bar_count==Bars(_Symbol,hunter_profile.timeframe)) return;
   // Preserve the second Bars query and consume the latch before pivots.
   hunter_single_bar_count=Bars(_Symbol,hunter_profile.timeframe);
   double older=0.0,newer=0.0;
   int count=0;
   for(int shift=1;shift<=99;shift++)
   {
      if(older>0.0) newer=older;
      older=HunterPivotAt(shift);
      if(older>0.0) count++;
      if(count>1) break;
   }
   if(older==0.0 || newer==0.0) return;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   HunterSpreadPips();
   datetime expires=TimeCurrent()+hunter_profile.expiration_hours*3600;
   double offset=hunter_profile.entry_offset,pip=HunterPip();
   bool buy=(older>newer);
   if(buy)
   {
      hunter_single_sell_seen=false;
      if(older-ask<=pip*10.0 || hunter_single_buy_seen || buy_pending+buys>0) return;
   }
   else
   {
      if(newer<=older) return;
      hunter_single_buy_seen=false;
      if(bid-older<=pip*10.0 || hunter_single_sell_seen || sell_pending+sells>0) return;
   }
   if(inp_UltimateEntryRandomizer) offset+=HunterRandomOffset();
   double direction=(buy?1.0:-1.0);
   double entry=HunterNormalizePrice(older+direction*pip*offset);
   if(HunterHasNearbySingleOrder(entry)) return;
   double nominal_sl=hunter_profile.stop_loss*(hunter_profile.prop_mode?2.0:1.0);
   double nominal_tp=hunter_profile.take_profit*(hunter_profile.prop_mode?2.0:1.0);
   double sl=(hunter_profile.stop_loss>0.0?HunterNormalizePrice(entry-direction*pip*nominal_sl):0.0);
   if(inp_UltimateFalseInitialSL && (int)inp_Mode!=3)
      sl=HunterNormalizePrice(entry-direction*pip*MathMax(inp_UltimateFalseSLPoints,nominal_sl+1.0));
   double tp=(hunter_profile.take_profit>0.0?HunterNormalizePrice(entry+direction*pip*nominal_tp):0.0);
   ENUM_ORDER_TYPE type=(buy?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP);
   string reason="";
   if(!HunterValidatePending(type,entry,sl,tp,reason)) return;
   double risk_sl=HunterNormalizePrice(entry-direction*pip*nominal_sl);
   double volume=HunterSingleVolume(type,entry,risk_sl);
   if(volume<=0.0) return;
   volume=HunterFitMargin(type,volume,entry,reason);
   if(volume>0.0) HunterPlaceSinglePending(type,volume,entry,sl,tp,expires);
}
void OnTick()
{
   if(inp_UseMultiProfileMode) HunterPortfolioTick();
   else HunterSingleTick();
}

void HunterRenderCurrentPanel(const bool news,const bool spread,const bool daily,const bool friday)
{
   HunterPanelState state;
   state.blocked=g_sghProtection.dayLocked;
   state.block_reason=g_sghProtection.lockReason;
   state.news_pause=news;
   state.high_spread=spread;
   state.daily_close=daily;
   state.friday_close=friday;
   state.next_news=g_sghProtection.newsDescription;
   state.header_warning_until=hunter_panel_ready_at;
   state.auxiliary_enabled=hunter_auxiliary_magic_enabled;
   HunterPanelRender(state);
}
int OnInit()
{
   return HunterInitializeExecution();
}
void OnDeinit(const int reason)
{
   HunterDeinitializeExecution(reason);
   HunterReleaseOriginalLogo();
}
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,
   const MqlTradeResult &result)
{
   HunterExecutionTradeTransaction(trans);
}
