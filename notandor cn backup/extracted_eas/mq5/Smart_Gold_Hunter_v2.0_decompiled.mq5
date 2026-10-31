//+------------------------------------------------------------------+
//| Smart Gold Hunter v2.0 decompiled by Jamo886                     |
//| Built from authorized Strategy Tester observations and JIT audit.|
//| This is NOT the vendor's original MQ5 source.                     |
//+------------------------------------------------------------------+
#property copyright "Smart Gold Hunter v2.0 decompiled by Jamo886"
#property description "Smart Gold Hunter v2.0 decompiled by Jamo886"
#property link      "https://t.me/FUNDEDTODAY"
#property version   "2.00"
#property strict

#include "SGH_SignalEngine.mqh"
#include "SGH_TradeEngine.mqh"

input group "MODE SETTINGS"
input ENUM_SGH_PROFILE_MODE inp_Mode=SGH_MODE_SCALPER;

input group "RISK SETTINGS"
input bool   inp_MM=false;
input double inp_RiskPercent=1.0;
input double inp_Lots=0.01;
input int    inp_MaxSpread=0;
input bool   inp_UseHighSpreadDeletePending=false;

input group "CUSTOM MODE SETTINGS"
input double inp_TP=250.0;
input double inp_SL=1500.0;
input double inp_TrailStart=100.0;
input double inp_TrailStop=50.0;
input int    inp_Pause=300;
input double inp_CustomPointsAway=0.0;

input group "PROP FIRM PROTECTION"
input bool   inp_UsePropFirmMode=true;
input bool   inp_UseDailyProfitTarget=false;
input double inp_DailyProfitTargetUSD=200.0;
input bool   inp_UseDailyLossLimit=false;
input double inp_DailyLossLimitUSD=100.0;
input bool   inp_UseEquityProtection=false;
input double inp_DailyEquityProtectionPercent=3.0;
input ENUM_SGH_DD_REFERENCE inp_DailyDDReference=SGH_DD_DAY_START_BALANCE;
input bool   inp_UseNewsFilter=false;
input int    inp_NewsMinutesBefore=30;
input int    inp_NewsMinutesAfter=30;
input bool   inp_UseManualDailyCloseTime=true;
input int    inp_DailyCloseHour=22;
input int    inp_DailyCloseMinute=15;
input int    inp_DailyReopenHour=1;
input int    inp_DailyReopenMinute=15;
input bool   inp_DailyCloseDeletePendings=true;
input bool   inp_DailyCloseClosePositions=true;
input bool   inp_UseFridayCloseProtection=true;
input bool   inp_UseManualFridayCloseTime=true;
input int    inp_FridayCloseHour=22;
input int    inp_FridayCloseMinute=15;
input bool   inp_FridayCloseDeletePendings=true;
input bool   inp_FridayCloseClosePositions=true;
input bool   inp_ShowPanel=false;

input group "EXPERT SETTINGS"
input long   inp_MagicNo=878787;
input string inp_TradeComment="@fundedtoday updatedV3";

SGHEffectiveProfile g_sghProfile;
int                 g_sghLastSignalBars=-1;

// Native sticky exposure memory.  Seeing a matching open position latches
// that side even after it closes.  The opposite raw ZigZag direction clears
// it.  Pending orders alone never set these latches.
bool g_sghBuyExposureLatch =false;
bool g_sghSellExposureLatch=false;

// Capture the native directional-exposure view before any tick-driven
// management can close a position or delete an expired pending.  The native
// signal gate consumes this frozen view later in the same tick, while the
// trade engine still performs its normal post-management live/duplicate scan.
void SGHSnapshotPreManageDirectionalExposure(int &buyExposureCount,
                                              int &sellExposureCount)
  {
   buyExposureCount=0;
   sellExposureCount=0;

   const int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=inp_MagicNo)
         continue;

      const ENUM_POSITION_TYPE type=
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type==POSITION_TYPE_BUY)
        {
         buyExposureCount++;
         g_sghBuyExposureLatch=true;
        }
      else if(type==POSITION_TYPE_SELL)
        {
         sellExposureCount++;
         g_sghSellExposureLatch=true;
        }
     }

   const int orderTotal=OrdersTotal();
   for(int i=0;i<orderTotal;i++)
     {
      const ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC)!=inp_MagicNo)
         continue;

      // The recovered native counters are exact BUY_STOP/SELL_STOP counts;
      // limit and stop-limit orders do not participate in this gate.
      const ENUM_ORDER_TYPE type=
         (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type==ORDER_TYPE_BUY_STOP)
         buyExposureCount++;
      else if(type==ORDER_TYPE_SELL_STOP)
         sellExposureCount++;
     }
  }

bool SGHStickySideBlocks(const SGHSignal &signal)
  {
   if(signal.direction==SGH_DIRECTION_BUY_STOP)
     {
      // Native resets the opposite latch on raw direction, before the
      // trigger-distance check.
      g_sghSellExposureLatch=false;
      return(g_sghBuyExposureLatch);
     }
   if(signal.direction==SGH_DIRECTION_SELL_STOP)
     {
      g_sghBuyExposureLatch=false;
      return(g_sghSellExposureLatch);
     }
   return(false);
  }

datetime SGHLastMatchingPauseDealTime(const datetime now)
  {
   if(!HistorySelect(0,now))
      return(0);

   datetime latest=0;
   const int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
     {
      const ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0)
         continue;
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(ticket,DEAL_MAGIC)!=inp_MagicNo)
         continue;

      // Native JIT reads integer property 4 (DEAL_TYPE), then applies the
      // exact predicate (value & ~2) == 1.  With the preceding symbol and
      // magic filters this normally selects SELL deals; preserve the bit
      // predicate instead of substituting an entry/exit interpretation.
      const int dealType=(int)HistoryDealGetInteger(ticket,DEAL_TYPE);
      if((dealType & ~2)!=1)
         continue;

      const datetime when=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
      if(when>latest)
         latest=when;
     }
   return(latest);
  }

bool SGHConfigureProfile()
  {
   return(SGHResolveProfile((int)inp_Mode,
                            inp_TP,
                            inp_SL,
                            inp_TrailStart,
                            inp_TrailStop,
                            inp_Pause,
                            inp_CustomPointsAway,
                            g_sghProfile));
  }

void SGHBuildTradeConfiguration(SGHTradeEngineConfig &cfg)
  {
   SGHTradeEngineDefaults(cfg);
   cfg.symbol=_Symbol;
   cfg.magic=inp_MagicNo;
   cfg.comment=inp_TradeComment;
   cfg.verbose=false;
   cfg.deviationPoints=20;

   cfg.useRiskPercent=inp_MM;
   cfg.riskPercent=inp_RiskPercent;
   cfg.fixedLots=inp_Lots;
   cfg.oneShot=true;                    // one exposure per direction
   cfg.duplicateTolerancePoints=0.0;    // retained API field; native band is fixed

   cfg.maxSpreadPoints=inp_MaxSpread;
   cfg.highSpreadDeletePendings=inp_UseHighSpreadDeletePending;

   // The original groups these controls under its Prop Firm Protection
   // master input.  Disabled children remain inert when the master is off.
   cfg.useDailyProfitTarget=(inp_UsePropFirmMode && inp_UseDailyProfitTarget);
   cfg.dailyProfitTargetMoney=inp_DailyProfitTargetUSD;
   cfg.useDailyLossLimit=(inp_UsePropFirmMode && inp_UseDailyLossLimit);
   cfg.dailyLossLimitMoney=inp_DailyLossLimitUSD;
   cfg.useEquityProtection=(inp_UsePropFirmMode && inp_UseEquityProtection);
   cfg.dailyEquityProtectionPercent=inp_DailyEquityProtectionPercent;
   cfg.ddReference=inp_DailyDDReference;
   cfg.dailyTargetUsesEquity=true;
   cfg.protectionsAccountWide=true;
   cfg.useNewsFilter=(inp_UsePropFirmMode && inp_UseNewsFilter);

   cfg.useManualDailyCloseTime=(inp_UsePropFirmMode && inp_UseManualDailyCloseTime);
   cfg.dailyCloseHour=inp_DailyCloseHour;
   cfg.dailyCloseMinute=inp_DailyCloseMinute;
   cfg.dailyReopenHour=inp_DailyReopenHour;
   cfg.dailyReopenMinute=inp_DailyReopenMinute;
   cfg.dailyCloseDeletePendings=inp_DailyCloseDeletePendings;
   cfg.dailyCloseClosePositions=inp_DailyCloseClosePositions;

   cfg.useFridayCloseProtection=(inp_UsePropFirmMode && inp_UseFridayCloseProtection);
   cfg.useManualFridayCloseTime=inp_UseManualFridayCloseTime;
   cfg.fridayCloseHour=inp_FridayCloseHour;
   cfg.fridayCloseMinute=inp_FridayCloseMinute;
   cfg.fridayCloseDeletePendings=inp_FridayCloseDeletePendings;
   cfg.fridayCloseClosePositions=inp_FridayCloseClosePositions;
  }

int OnInit()
  {
   if(!SGHConfigureProfile())
     {
      Print("Smart Gold Hunter v2.0 decompiled by Jamo886: invalid profile configuration");
      return(INIT_PARAMETERS_INCORRECT);
     }

   SGHTradeEngineConfig cfg;
   SGHBuildTradeConfiguration(cfg);
   if(!SGHTradeInit(cfg))
     {
      Print("Smart Gold Hunter v2.0 decompiled by Jamo886: trade engine initialization failed");
      return(INIT_FAILED);
     }

   SGHTradeApplyProfile(g_sghProfile);
   g_sghLastSignalBars=-1;
   g_sghBuyExposureLatch=false;
   g_sghSellExposureLatch=false;

   PrintFormat("Smart Gold Hunter v2.0 decompiled by Jamo886 initialized | profile=%s tf=%s depth=%d",
               g_sghProfile.profileName,
               EnumToString(g_sghProfile.signalTimeframe),
               g_sghProfile.swingDepth);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   PrintFormat("Smart Gold Hunter v2.0 decompiled by Jamo886 terminated | reason=%d",reason);
  }

void OnTick()
  {
   // Native snapshots matching directional exposure before management.  An
   // expired pending deleted below therefore still blocks a replacement on
   // this tick/bar, and a position closed below remains visible to the gate.
   int preManageBuyExposureCount=0;
   int preManageSellExposureCount=0;
   SGHSnapshotPreManageDirectionalExposure(preManageBuyExposureCount,
                                           preManageSellExposureCount);

   // Protection and trailing paths are tick-driven in the oracle.
   SGHManage();

   // Native order is safety -> SELL-deal pause -> Bars() latch -> signal.
   // A blocked/paused bar is intentionally not consumed and can be retried
   // later in that same bar when the gate clears.
   if(!SGHSafetyGate())
      return;

   const datetime now=TimeCurrent();
   const datetime lastPauseDeal=SGHLastMatchingPauseDealTime(now);
   if(lastPauseDeal>0 && now-lastPauseDeal<g_sghProfile.pauseSeconds)
      return;

   const int signalBars=Bars(_Symbol,g_sghProfile.signalTimeframe);
   if(signalBars<=0 || signalBars==g_sghLastSignalBars)
      return;
   // Native latch starts at -1: the first eligible tick is evaluated rather
   // than merely seeding and returning.
   g_sghLastSignalBars=signalBars;

   SGHSignal signal;
   const bool ready=SGHGenerateSignal(_Symbol,g_sghProfile,signal);

   // Apply the raw-direction reset even when distance/actionability failed.
   const bool stickyBlocked=SGHStickySideBlocks(signal);
   if(!ready || stickyBlocked)
      return;

   // Consume the frozen pre-management counters.  SGHSubmitSignal retains
   // the independent live directional and duplicate-price checks against the
   // post-management order book.
   if((signal.direction==SGH_DIRECTION_BUY_STOP &&
       preManageBuyExposureCount>0) ||
      (signal.direction==SGH_DIRECTION_SELL_STOP &&
       preManageSellExposureCount>0))
      return;

   ulong ticket=0;
   SGHSubmitSignal(signal,ticket);
  }
