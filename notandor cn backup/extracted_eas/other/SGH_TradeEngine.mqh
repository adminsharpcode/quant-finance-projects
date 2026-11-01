//+------------------------------------------------------------------+
//| SGH_TradeEngine.mqh                                               |
//| Clean-room order, risk and protection helpers for MT5.            |
//|                                                                    |
//| Evidence labels used in this file:                                 |
//|   OBSERVED/JIT      - supported by the authorized runtime audit.   |
//|   OFFICIAL-ONLY     - advertised by the vendor, exact branch       |
//|                       semantics were not recovered.                |
//|   CLEAN-ROOM POLICY - conservative implementation choice.          |
//|                                                                    |
//| This is not original vendor source. It contains no entry-signal     |
//| reconstruction and is intended to be included by the clean-room EA.|
//+------------------------------------------------------------------+
#ifndef __SGH_TRADE_ENGINE_MQH__
#define __SGH_TRADE_ENGINE_MQH__

enum ENUM_SGH_DD_REFERENCE
  {
   SGH_DD_DAY_START_BALANCE = 0,
   SGH_DD_DAY_START_EQUITY  = 1
  };

struct SGHTradeEngineConfig
  {
   string                symbol;
   long                  magic;
   string                comment;
   bool                  verbose;
   int                   deviationPoints;

   // OBSERVED/JIT: fixed lot or equity-risk lot, with fixed-lot fallback
   // when SL is zero or symbol risk data are invalid.
   bool                  useRiskPercent;
   double                riskPercent;
   double                fixedLots;

   // OBSERVED/JIT: one-shot is directional, not global. One Buy Stop and
   // one Sell Stop may coexist; same-direction position+pending blocks.
   bool                  oneShot;
   double                duplicateTolerancePoints;

   // Entry-relative protection and pending lifetime supplied by profile.
   double                stopLossPoints;
   double                takeProfitPoints;
   int                   pendingExpirySeconds;

   // OBSERVED/JIT: trailing activates after a profit threshold and never
   // moves the stop backwards.
   double                trailStartPoints;
   double                trailDistancePoints;

   // OBSERVED/JIT: Prop Scalper starts at 2x normal SL/TP, then restores
   // normal protection after 120 seconds before normal trailing begins.
   bool                  propScalperMode;
   int                   propHoldSeconds;
   double                propInitialProtectionMultiplier;

   // Spread gate. Max <= 0 disables it. Deleting pendings on high spread
   // is directly exposed by the product input surface.
   int                   maxSpreadPoints;
   bool                  highSpreadDeletePendings;

   // OFFICIAL-ONLY: advertised account guards. They default disabled.
   bool                  useDailyProfitTarget;
   double                dailyProfitTargetMoney;
   bool                  useDailyLossLimit;
   double                dailyLossLimitMoney;
   bool                  useEquityProtection;
   double                dailyEquityProtectionPercent;
   ENUM_SGH_DD_REFERENCE ddReference;
   bool                  dailyTargetUsesEquity;
   bool                  protectionsAccountWide;

   // OFFICIAL-ONLY: exact news classification/provider is unverified.
   // The engine never invents news events. SetExternalNewsBlock() must
   // provide a known state; unknown state is fail-open/parity-safe.
   bool                  useNewsFilter;

   // Manual server-time session window recovered from the input surface.
   // Exact logging/gate order is still open: the oracle logged an order
   // attempt at 01:00 with a 01:15 reopen, then accepted on the 01:15 bar.
   bool                  useManualDailyCloseTime;
   int                   dailyCloseHour;
   int                   dailyCloseMinute;
   int                   dailyReopenHour;
   int                   dailyReopenMinute;
   bool                  dailyCloseDeletePendings;
   bool                  dailyCloseClosePositions;

   bool                  useFridayCloseProtection;
   bool                  useManualFridayCloseTime;
   int                   fridayCloseHour;
   int                   fridayCloseMinute;
   bool                  fridayCloseDeletePendings;
   bool                  fridayCloseClosePositions;
  };

struct SGHProtectionDecision
  {
   bool   blockEntries;
   bool   deletePendings;
   bool   closePositions;
   string reason;
  };

void SGHTradeEngineDefaults(SGHTradeEngineConfig &cfg)
  {
   cfg.symbol                          = _Symbol;
   cfg.magic                           = 878787;
   cfg.comment                         = "SGH clean-room";
   cfg.verbose                         = false;
   cfg.deviationPoints                 = 20;

   cfg.useRiskPercent                  = false;
   cfg.riskPercent                     = 1.0;
   cfg.fixedLots                       = 0.01;
   cfg.oneShot                         = true;
   cfg.duplicateTolerancePoints        = 1.0;

   cfg.stopLossPoints                  = 0.0;
   cfg.takeProfitPoints                = 0.0;
   cfg.pendingExpirySeconds            = 0;
   cfg.trailStartPoints                = 0.0;
   cfg.trailDistancePoints             = 0.0;

   cfg.propScalperMode                 = false;
   cfg.propHoldSeconds                 = 120;
   cfg.propInitialProtectionMultiplier = 2.0;

   cfg.maxSpreadPoints                 = 0;
   cfg.highSpreadDeletePendings        = false;

   // Unverified safety branches intentionally default OFF.
   cfg.useDailyProfitTarget            = false;
   cfg.dailyProfitTargetMoney          = 200.0;
   cfg.useDailyLossLimit               = false;
   cfg.dailyLossLimitMoney             = 100.0;
   cfg.useEquityProtection             = false;
   cfg.dailyEquityProtectionPercent    = 3.0;
   cfg.ddReference                     = SGH_DD_DAY_START_BALANCE;
   cfg.dailyTargetUsesEquity           = true;
   cfg.protectionsAccountWide          = true;
   cfg.useNewsFilter                   = false;

   cfg.useManualDailyCloseTime         = false;
   cfg.dailyCloseHour                  = 22;
   cfg.dailyCloseMinute                = 15;
   cfg.dailyReopenHour                 = 1;
   cfg.dailyReopenMinute               = 15;
   cfg.dailyCloseDeletePendings        = true;
   cfg.dailyCloseClosePositions        = true;

   cfg.useFridayCloseProtection        = false;
   cfg.useManualFridayCloseTime        = false;
   cfg.fridayCloseHour                 = 22;
   cfg.fridayCloseMinute               = 15;
   cfg.fridayCloseDeletePendings       = true;
   cfg.fridayCloseClosePositions       = true;
  }

class CSGHTradeEngine
  {
private:
   SGHTradeEngineConfig m_cfg;
   string               m_symbol;
   int                  m_digits;
   double               m_point;
   datetime             m_dayAnchor;
   double               m_dayStartBalance;
   double               m_dayStartEquity;
   bool                 m_newsStateKnown;
   bool                 m_newsBlocked;
   bool                 m_warnedUnknownNews;
   string               m_lastReason;
   ulong                m_propNormalizedTickets[];

   void Log(const string text)
     {
      if(m_cfg.verbose)
         Print("SGH TradeEngine | ",text);
     }

   void SetReason(const string text)
     {
      m_lastReason=text;
      Log(text);
     }

   void AddDecisionReason(SGHProtectionDecision &decision,const string text)
     {
      if(decision.reason=="")
         decision.reason=text;
      else if(StringFind(decision.reason,text)<0)
         decision.reason=decision.reason+"; "+text;
     }

   bool IsOurOrderSelected()
     {
      if(OrderGetString(ORDER_SYMBOL)!=m_symbol)
         return(false);
      if((long)OrderGetInteger(ORDER_MAGIC)!=m_cfg.magic)
         return(false);
      return(true);
     }

   bool IsOurPositionSelected()
     {
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol)
         return(false);
      if((long)PositionGetInteger(POSITION_MAGIC)!=m_cfg.magic)
         return(false);
      return(true);
     }

   bool IsPendingType(const ENUM_ORDER_TYPE type)
     {
      return(type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_SELL_LIMIT ||
             type==ORDER_TYPE_BUY_STOP  || type==ORDER_TYPE_SELL_STOP  ||
             type==ORDER_TYPE_BUY_STOP_LIMIT || type==ORDER_TYPE_SELL_STOP_LIMIT);
     }

   bool IsBuyPendingType(const ENUM_ORDER_TYPE type)
     {
      return(type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_BUY_STOP ||
             type==ORDER_TYPE_BUY_STOP_LIMIT);
     }

   bool IsSellPendingType(const ENUM_ORDER_TYPE type)
     {
      return(type==ORDER_TYPE_SELL_LIMIT || type==ORDER_TYPE_SELL_STOP ||
             type==ORDER_TYPE_SELL_STOP_LIMIT);
     }

   int VolumeDigits(const double step)
     {
      if(step<=0.0)
         return(2);
      for(int digits=0; digits<=8; digits++)
        {
         const double scaled=step*MathPow(10.0,digits);
         if(MathAbs(scaled-MathRound(scaled))<1.0e-8)
            return(digits);
        }
      return(8);
     }

   ENUM_ORDER_TYPE_FILLING MarketFillingMode()
     {
      const long modes=SymbolInfoInteger(m_symbol,SYMBOL_FILLING_MODE);
      if((modes & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
         return(ORDER_FILLING_FOK);
      if((modes & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
         return(ORDER_FILLING_IOC);
      return(ORDER_FILLING_RETURN);
     }

   double BrokerMinimumDistancePrice()
     {
      const long stopLevel=SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL);
      const long freezeLevel=SymbolInfoInteger(m_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
      long distanceLevel=stopLevel;
      if(freezeLevel>distanceLevel)
         distanceLevel=freezeLevel;
      return((double)distanceLevel*m_point);
     }

   ulong Deviation()
     {
      if(m_cfg.deviationPoints<=0)
         return(0);
      return((ulong)m_cfg.deviationPoints);
     }

   bool TradeEnvironmentReady()
     {
      if(!MQLInfoInteger(MQL_TESTER) && !TerminalInfoInteger(TERMINAL_CONNECTED))
        {
         SetReason("Terminal is not connected");
         return(false);
        }
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
         !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
         !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
        {
         SetReason("Trading is not allowed");
         return(false);
        }
      return(true);
     }

   bool TradeResultSucceeded(const MqlTradeResult &result,const bool pendingRequest)
     {
      if(pendingRequest)
         return(result.retcode==TRADE_RETCODE_PLACED ||
                result.retcode==TRADE_RETCODE_DONE ||
                result.retcode==TRADE_RETCODE_DONE_PARTIAL);
      return(result.retcode==TRADE_RETCODE_DONE ||
             result.retcode==TRADE_RETCODE_DONE_PARTIAL ||
             result.retcode==TRADE_RETCODE_PLACED);
     }

   datetime ServerDayAnchor(const datetime when)
     {
      MqlDateTime tm;
      TimeToStruct(when,tm);
      tm.hour=0;
      tm.min=0;
      tm.sec=0;
      return(StructToTime(tm));
     }

   double RealizedTradingPnl(const datetime from,const datetime to)
     {
      if(!HistorySelect(from,to))
         return(0.0);

      double pnl=0.0;
      const int count=HistoryDealsTotal();
      for(int i=0;i<count;i++)
        {
         const ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
            continue;

         const ENUM_DEAL_TYPE dealType=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(dealType!=DEAL_TYPE_BUY && dealType!=DEAL_TYPE_SELL)
            continue;

         if(!m_cfg.protectionsAccountWide)
           {
            if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=m_symbol)
               continue;
            if((long)HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_cfg.magic)
               continue;
           }

         pnl+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         pnl+=HistoryDealGetDouble(ticket,DEAL_SWAP);
         pnl+=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         pnl+=HistoryDealGetDouble(ticket,DEAL_FEE);
        }
      return(pnl);
     }

   void SyncDayState(const datetime now)
     {
      const datetime anchor=ServerDayAnchor(now);
      if(anchor==m_dayAnchor)
         return;

      m_dayAnchor=anchor;
      const double realized=RealizedTradingPnl(anchor,now);
      // CLEAN-ROOM POLICY: reconstruct the day-opening balance so an EA
      // restart does not reset the monetary daily limit.
      m_dayStartBalance=AccountInfoDouble(ACCOUNT_BALANCE)-realized;
      // Exact original handling of pre-existing floating P/L is unverified.
      // Current equity is the least surprising restart-safe reference.
      m_dayStartEquity=AccountInfoDouble(ACCOUNT_EQUITY);
      m_warnedUnknownNews=false;
     }

   bool IsInDailyClosedWindow(const datetime now)
     {
      if(!m_cfg.useManualDailyCloseTime)
         return(false);

      MqlDateTime tm;
      TimeToStruct(now,tm);
      const int current=tm.hour*60+tm.min;
      const int closeAt=m_cfg.dailyCloseHour*60+m_cfg.dailyCloseMinute;
       // Oracle quirk: the reopen minute input is displayed as 15, but the
       // entry gate reopens at the beginning of that hour.  The original then
       // attempts at 01:00 (the broker may reject Market closed) and retries at
       // 01:15.  This is hour-relative behavior, not a date exception.
       const int reopenAt=m_cfg.dailyReopenHour*60;

      if(closeAt==reopenAt)
         return(false);
      if(closeAt>reopenAt)
         return(current>=closeAt || current<reopenAt);
      return(current>=closeAt && current<reopenAt);
     }

   bool IsFridayClosed(const datetime now)
     {
      if(!m_cfg.useFridayCloseProtection || !m_cfg.useManualFridayCloseTime)
         return(false);

      MqlDateTime tm;
      TimeToStruct(now,tm);
      if(tm.day_of_week==0 || tm.day_of_week==6)
         return(true);
      if(tm.day_of_week!=5)
         return(false);

      const int current=tm.hour*60+tm.min;
      const int closeAt=m_cfg.fridayCloseHour*60+m_cfg.fridayCloseMinute;
      return(current>=closeAt);
     }

   bool IsSymbolTradeSessionOpen(const string symbol)
     {
      // Native helper +0x8BD0 checks the broker's recurring trade sessions,
      // not a hardcoded clock window.  Prefer trade-server time and fall back
      // to the latest server tick time if it is temporarily unavailable.
      datetime now=TimeTradeServer();
      if(now<=0)
         now=TimeCurrent();

      MqlDateTime current;
      if(now<=0 || !TimeToStruct(now,current))
         return(false);
      const int currentSeconds=current.hour*3600+current.min*60+current.sec;

      for(uint index=0;index<10;index++)
        {
         datetime from=0;
         datetime to=0;
         if(!SymbolInfoSessionTrade(symbol,
                                    (ENUM_DAY_OF_WEEK)current.day_of_week,
                                    index,from,to))
           {
            if(index==0)
              {
               long mode=SYMBOL_TRADE_MODE_DISABLED;
               if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE,mode))
                  return(false);
               // Exact fallback predicate: (mode-1)<4, i.e. modes 1..4.
               return(mode>=SYMBOL_TRADE_MODE_LONGONLY &&
                      mode<=SYMBOL_TRADE_MODE_FULL);
              }
            break;
           }

         MqlDateTime startParts;
         MqlDateTime endParts;
         if(!TimeToStruct(from,startParts) || !TimeToStruct(to,endParts))
            continue;
         const int startSeconds=
            startParts.hour*3600+startParts.min*60+startParts.sec;
         const int endSeconds=
            endParts.hour*3600+endParts.min*60+endParts.sec;

         // Start is inclusive and end is exclusive.  Wrapped sessions cross
         // midnight and therefore use OR rather than AND.
         if(startSeconds<=endSeconds)
           {
            if(currentSeconds>=startSeconds && currentSeconds<endSeconds)
               return(true);
           }
         else if(currentSeconds>=startSeconds || currentSeconds<endSeconds)
            return(true);
        }
      return(false);
     }

   bool PropTicketProcessed(const ulong ticket)
     {
      const int size=ArraySize(m_propNormalizedTickets);
      for(int i=0;i<size;i++)
         if(m_propNormalizedTickets[i]==ticket)
            return(true);
      return(false);
     }

   void MarkPropTicketProcessed(const ulong ticket)
     {
      if(PropTicketProcessed(ticket))
         return;
      const int size=ArraySize(m_propNormalizedTickets);
      ArrayResize(m_propNormalizedTickets,size+1);
      m_propNormalizedTickets[size]=ticket;
     }

   void PrunePropTickets()
     {
      int writeIndex=0;
      const int size=ArraySize(m_propNormalizedTickets);
      for(int i=0;i<size;i++)
        {
         if(PositionSelectByTicket(m_propNormalizedTickets[i]))
           {
            m_propNormalizedTickets[writeIndex]=m_propNormalizedTickets[i];
            writeIndex++;
           }
        }
      if(writeIndex!=size)
         ArrayResize(m_propNormalizedTickets,writeIndex);
     }

   bool BuildProtectionPrices(const ENUM_ORDER_TYPE orderType,
                              const double entryPrice,
                              const bool initialPropProtection,
                              double &sl,double &tp)
     {
      double multiplier=1.0;
      if(m_cfg.propScalperMode && initialPropProtection)
         multiplier=MathMax(1.0,m_cfg.propInitialProtectionMultiplier);

      const double slDistance=m_cfg.stopLossPoints*m_point*multiplier;
      const double tpDistance=m_cfg.takeProfitPoints*m_point*multiplier;
      sl=0.0;
      tp=0.0;

      if(orderType==ORDER_TYPE_BUY || orderType==ORDER_TYPE_BUY_STOP)
        {
         if(slDistance>0.0)
            sl=NormalizePrice(entryPrice-slDistance);
         if(tpDistance>0.0)
            tp=NormalizePrice(entryPrice+tpDistance);
        }
      else if(orderType==ORDER_TYPE_SELL || orderType==ORDER_TYPE_SELL_STOP)
        {
         if(slDistance>0.0)
            sl=NormalizePrice(entryPrice+slDistance);
         if(tpDistance>0.0)
            tp=NormalizePrice(entryPrice-tpDistance);
        }
      else
         return(false);
      return(true);
     }

   bool ValidatePendingGeometry(const ENUM_ORDER_TYPE orderType,
                                const double entryPrice,
                                const double sl,const double tp)
     {
      MqlTick tick;
      if(!SymbolInfoTick(m_symbol,tick))
        {
         SetReason("No current tick");
         return(false);
        }

      const double minDistance=BrokerMinimumDistancePrice();
      const double epsilon=m_point*0.1;

      if(orderType==ORDER_TYPE_BUY_STOP)
        {
         if(entryPrice+epsilon<tick.ask+minDistance)
           {
            SetReason("Buy Stop too close to Ask");
            return(false);
           }
         if(sl>0.0 && (sl>=entryPrice || entryPrice-sl+epsilon<minDistance))
           {
            SetReason(sl>=entryPrice ? "Buy Stop SL invalid side" : "Buy Stop SL too close");
            return(false);
           }
         if(tp>0.0 && (tp<=entryPrice || tp-entryPrice+epsilon<minDistance))
           {
            SetReason(tp<=entryPrice ? "Buy Stop TP invalid side" : "Buy Stop TP too close");
            return(false);
           }
        }
      else if(orderType==ORDER_TYPE_SELL_STOP)
        {
         if(entryPrice-epsilon>tick.bid-minDistance)
           {
            SetReason("Sell Stop too close to Bid");
            return(false);
           }
         if(sl>0.0 && (sl<=entryPrice || sl-entryPrice+epsilon<minDistance))
           {
            SetReason(sl<=entryPrice ? "Sell Stop SL invalid side" : "Sell Stop SL too close");
            return(false);
           }
         if(tp>0.0 && (tp>=entryPrice || entryPrice-tp+epsilon<minDistance))
           {
            SetReason(tp>=entryPrice ? "Sell Stop TP invalid side" : "Sell Stop TP too close");
            return(false);
           }
        }
      else
        {
         SetReason("Only Buy Stop and Sell Stop are supported");
         return(false);
        }
      return(true);
     }

   bool CheckFreeMargin(const ENUM_ORDER_TYPE pendingType,
                        const double lots,const double entryPrice)
     {
      const ENUM_ORDER_TYPE marketType=(pendingType==ORDER_TYPE_BUY_STOP ?
                                        ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double margin=0.0;
      if(!OrderCalcMargin(marketType,m_symbol,lots,entryPrice,margin))
        {
         SetReason("No free margin: OrderCalcMargin failed");
         return(false);
        }
      if(margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)+0.01)
        {
         SetReason("Not enough free margin");
         return(false);
        }
      return(true);
     }

   bool ModifyPosition(const ulong ticket,const double sl,const double tp)
     {
      if(!PositionSelectByTicket(ticket))
         return(false);

      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action   = TRADE_ACTION_SLTP;
      request.position = ticket;
      request.symbol   = PositionGetString(POSITION_SYMBOL);
      request.magic    = (ulong)m_cfg.magic;
      request.sl       = (sl>0.0 ? NormalizePrice(sl) : 0.0);
      request.tp       = (tp>0.0 ? NormalizePrice(tp) : 0.0);

      ResetLastError();
      if(!OrderSend(request,result) || !TradeResultSucceeded(result,false))
        {
         SetReason(StringFormat("Position modify failed ticket=%I64u retcode=%u error=%d",
                                ticket,result.retcode,GetLastError()));
         return(false);
        }
      return(true);
     }

   bool ClosePositionByTicket(const ulong ticket)
     {
      if(!PositionSelectByTicket(ticket) || !IsOurPositionSelected())
         return(false);

      MqlTick tick;
      if(!SymbolInfoTick(m_symbol,tick))
         return(false);

      const ENUM_POSITION_TYPE positionType=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action       = TRADE_ACTION_DEAL;
      request.position     = ticket;
      request.symbol       = m_symbol;
      request.magic        = (ulong)m_cfg.magic;
      request.volume       = PositionGetDouble(POSITION_VOLUME);
      request.deviation    = Deviation();
      request.type_filling = MarketFillingMode();

      if(positionType==POSITION_TYPE_BUY)
        {
         request.type=ORDER_TYPE_SELL;
         request.price=tick.bid;
        }
      else
        {
         request.type=ORDER_TYPE_BUY;
         request.price=tick.ask;
        }

      ResetLastError();
      if(!OrderSend(request,result) || !TradeResultSucceeded(result,false))
        {
         SetReason(StringFormat("Position close failed ticket=%I64u retcode=%u error=%d",
                                ticket,result.retcode,GetLastError()));
         return(false);
        }
      return(true);
     }

   bool DeletePendingByTicket(const ulong ticket)
     {
      // The original never sends TRADE_ACTION_REMOVE while the order's
      // symbol is outside a broker trade session.  It simply retries the
      // read-only session check on later ticks and deletes on the first open
      // tick, avoiding a flood of Market-closed OrderSend failures.
      if(!OrderSelect(ticket))
         return(false);
      const string orderSymbol=OrderGetString(ORDER_SYMBOL);
      if(orderSymbol=="" || !IsSymbolTradeSessionOpen(orderSymbol))
         return(false);

      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action=TRADE_ACTION_REMOVE;
      request.order=ticket;
      request.magic=(ulong)m_cfg.magic;

      ResetLastError();
      if(!OrderSend(request,result) || !TradeResultSucceeded(result,false))
        {
         SetReason(StringFormat("Pending delete failed ticket=%I64u retcode=%u error=%d",
                                ticket,result.retcode,GetLastError()));
         return(false);
        }
      return(true);
     }

public:
   CSGHTradeEngine()
     {
      SGHTradeEngineDefaults(m_cfg);
      m_symbol=_Symbol;
      m_digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
      m_point=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
      m_dayAnchor=0;
      m_dayStartBalance=0.0;
      m_dayStartEquity=0.0;
      m_newsStateKnown=false;
      m_newsBlocked=false;
      m_warnedUnknownNews=false;
      m_lastReason="";
      ArrayResize(m_propNormalizedTickets,0);
     }

   bool Configure(const SGHTradeEngineConfig &cfg)
     {
      m_cfg=cfg;
      m_symbol=(cfg.symbol=="" ? _Symbol : cfg.symbol);
      if(!SymbolSelect(m_symbol,true))
        {
         SetReason("Unable to select symbol "+m_symbol);
         return(false);
        }

      m_digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
      m_point=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
      if(m_digits<0 || m_point<=0.0)
        {
         SetReason("Invalid symbol point/digits for "+m_symbol);
         return(false);
        }

      if(m_cfg.magic<0)
         m_cfg.magic=0;
      if(m_cfg.propHoldSeconds<=0)
         m_cfg.propHoldSeconds=120;
      if(m_cfg.propInitialProtectionMultiplier<1.0)
         m_cfg.propInitialProtectionMultiplier=2.0;
      if(m_cfg.duplicateTolerancePoints<0.0)
         m_cfg.duplicateTolerancePoints=0.0;

      m_dayAnchor=0;
      SyncDayState(TimeTradeServer());
      return(true);
     }

   string LastReason() const
     {
      return(m_lastReason);
     }

   string Symbol() const
     {
      return(m_symbol);
     }

   double PointSize() const
     {
      return(m_point);
     }

   void ApplyProfileTradeParameters(const double stopLossPoints,
                                    const double takeProfitPoints,
                                    const double trailStartPoints,
                                    const double trailDistancePoints,
                                    const int pendingExpirySeconds,
                                    const bool propScalperMode)
     {
      m_cfg.stopLossPoints=stopLossPoints;
      m_cfg.takeProfitPoints=takeProfitPoints;
      m_cfg.trailStartPoints=trailStartPoints;
      m_cfg.trailDistancePoints=trailDistancePoints;
      m_cfg.pendingExpirySeconds=pendingExpirySeconds;
      m_cfg.propScalperMode=propScalperMode;
     }

   double NormalizePrice(const double price)
     {
      return(NormalizeDouble(price,m_digits));
     }

   double NormalizeVolumeDown(const double requestedLots)
     {
      const double minimum=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN);
      const double maximum=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MAX);
      const double step=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP);
      if(requestedLots<=0.0 || minimum<=0.0 || maximum<=0.0 || step<=0.0)
         return(0.0);

      const double capped=MathMin(requestedLots,maximum);
      const double normalized=MathFloor((capped+step*1.0e-9)/step)*step;
      if(normalized+step*1.0e-9<minimum)
         return(0.0); // OBSERVED/JIT: "Volume below minimum", do not clamp up.
      return(NormalizeDouble(normalized,VolumeDigits(step)));
     }

   double CurrentSpreadPoints()
     {
      MqlTick tick;
      if(!SymbolInfoTick(m_symbol,tick) || m_point<=0.0)
         return(-1.0);
      return((tick.ask-tick.bid)/m_point);
     }

   int CountOurPositions()
     {
      int count=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(ticket!=0 && IsOurPositionSelected())
            count++;
        }
      return(count);
     }

   int CountOurPendings()
     {
      int count=0;
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         const ulong ticket=OrderGetTicket(i);
         if(ticket==0 || !IsOurOrderSelected())
            continue;
         if(IsPendingType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
            count++;
        }
      return(count);
     }

   bool HasExposure()
     {
      return(CountOurPositions()>0 || CountOurPendings()>0);
     }

   bool HasDirectionalExposure(const ENUM_ORDER_TYPE pendingType)
     {
      const bool wantBuy=(pendingType==ORDER_TYPE_BUY_STOP ||
                          pendingType==ORDER_TYPE_BUY_LIMIT ||
                          pendingType==ORDER_TYPE_BUY_STOP_LIMIT);
      const bool wantSell=(pendingType==ORDER_TYPE_SELL_STOP ||
                           pendingType==ORDER_TYPE_SELL_LIMIT ||
                           pendingType==ORDER_TYPE_SELL_STOP_LIMIT);
      if(!wantBuy && !wantSell)
         return(false);

      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !IsOurPositionSelected())
            continue;
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if((wantBuy && type==POSITION_TYPE_BUY) ||
            (wantSell && type==POSITION_TYPE_SELL))
            return(true);
        }

      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         const ulong ticket=OrderGetTicket(i);
         if(ticket==0 || !IsOurOrderSelected())
            continue;
         const ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if((wantBuy && IsBuyPendingType(type)) ||
            (wantSell && IsSellPendingType(type)))
            return(true);
        }
      return(false);
     }

   bool HasDuplicateExposurePrice(const double price)
     {
      // Native helper +0xF670 scans live positions first and active orders
      // second.  It is deliberately side/type agnostic and uses an inclusive
      // 50-pip band, scaled in the standard way for 3/5-digit symbols.
      const double pipScale=(m_digits==3 || m_digits==5 ? 10.0 : 1.0);
      const double tolerance=m_point*pipScale*50.0;

      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !IsOurPositionSelected())
            continue;
         if(MathAbs(PositionGetDouble(POSITION_PRICE_OPEN)-price)<=tolerance)
            return(true);
        }

      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         const ulong ticket=OrderGetTicket(i);
         if(ticket==0 || !IsOurOrderSelected())
            continue;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-price)<=tolerance)
            return(true);
        }
      return(false);
     }

   double ComputeLots(const double entryPrice,const double stopLossPrice)
     {
      if(!m_cfg.useRiskPercent || m_cfg.riskPercent<=0.0 ||
         stopLossPrice<=0.0 || MathAbs(entryPrice-stopLossPrice)<m_point*0.1)
        {
         if(m_cfg.useRiskPercent && stopLossPrice<=0.0)
            Log("Risk lot disabled: SL is zero. Using fixed lot.");
         return(NormalizeVolumeDown(m_cfg.fixedLots));
        }

      double tickSize=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickValue=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(tickValue<=0.0)
         tickValue=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_VALUE);

      const double slPriceDistance=MathAbs(entryPrice-stopLossPrice);
      if(tickSize<=0.0 || tickValue<=0.0 || slPriceDistance<=0.0)
        {
         Log("Risk lot disabled: invalid symbol risk data. Using fixed lot.");
         return(NormalizeVolumeDown(m_cfg.fixedLots));
        }

      const double riskMoney=AccountInfoDouble(ACCOUNT_EQUITY)*m_cfg.riskPercent/100.0;
      const double lossPerOneLot=(slPriceDistance/tickSize)*tickValue;
      if(riskMoney<=0.0 || lossPerOneLot<=0.0)
         return(NormalizeVolumeDown(m_cfg.fixedLots));

      const double rawLots=riskMoney/lossPerOneLot;
      const double lots=NormalizeVolumeDown(rawLots);
      if(m_cfg.verbose)
         PrintFormat("RiskLot Debug | Equity=%.2f Risk%%=%.4f RiskMoney=%.2f "
                     "SLPriceDistance=%.8f TickSize=%.8f TickValue=%.8f "
                     "LossPer1Lot=%.2f RawLots=%.8f Lots=%.8f",
                     AccountInfoDouble(ACCOUNT_EQUITY),m_cfg.riskPercent,riskMoney,
                     slPriceDistance,tickSize,tickValue,lossPerOneLot,rawLots,lots);
      return(lots);
     }

   void SetExternalNewsBlock(const bool stateKnown,const bool blocked)
     {
      m_newsStateKnown=stateKnown;
      m_newsBlocked=(stateKnown && blocked);
      if(stateKnown)
         m_warnedUnknownNews=false;
     }

   void EvaluateProtectionDecision(const datetime now,SGHProtectionDecision &decision)
     {
      decision.blockEntries=false;
      decision.deletePendings=false;
      decision.closePositions=false;
      decision.reason="";
      SyncDayState(now);

      const double spread=CurrentSpreadPoints();
      if(m_cfg.maxSpreadPoints>0 &&
         (spread<0.0 || spread>(double)m_cfg.maxSpreadPoints))
        {
         decision.blockEntries=true;
         decision.deletePendings=m_cfg.highSpreadDeletePendings;
         AddDecisionReason(decision,"HighSpread");
        }

      if(IsFridayClosed(now))
        {
         decision.blockEntries=true;
         decision.deletePendings=(decision.deletePendings ||
                                  m_cfg.fridayCloseDeletePendings);
         decision.closePositions=(decision.closePositions ||
                                  m_cfg.fridayCloseClosePositions);
         AddDecisionReason(decision,"FridayClose");
        }
      else if(IsInDailyClosedWindow(now))
        {
         decision.blockEntries=true;
         decision.deletePendings=(decision.deletePendings ||
                                  m_cfg.dailyCloseDeletePendings);
         decision.closePositions=(decision.closePositions ||
                                  m_cfg.dailyCloseClosePositions);
         AddDecisionReason(decision,"DailyClose");
        }

      if(m_cfg.useNewsFilter)
        {
         if(m_newsStateKnown && m_newsBlocked)
           {
            decision.blockEntries=true;
            AddDecisionReason(decision,"NewsFilter");
           }
         else if(!m_newsStateKnown && !m_warnedUnknownNews)
           {
            // OFFICIAL-ONLY behavior is intentionally fail-open until an
            // external, tested news oracle supplies a state.
            Log("News filter enabled but state is unknown; fail-open.");
            m_warnedUnknownNews=true;
           }
        }

      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      const double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      const double dayMetric=(m_cfg.dailyTargetUsesEquity ? equity : balance);
      const double dayPnl=dayMetric-m_dayStartBalance;

      if(m_cfg.useDailyProfitTarget && m_cfg.dailyProfitTargetMoney>0.0 &&
         dayPnl>=m_cfg.dailyProfitTargetMoney)
        {
         decision.blockEntries=true;
         decision.deletePendings=true;
         decision.closePositions=true;
         AddDecisionReason(decision,"DailyProfitTarget");
        }

      if(m_cfg.useDailyLossLimit && m_cfg.dailyLossLimitMoney>0.0 &&
         dayPnl<=-m_cfg.dailyLossLimitMoney)
        {
         decision.blockEntries=true;
         decision.deletePendings=true;
         decision.closePositions=true;
         AddDecisionReason(decision,"DailyLossLimit");
        }

      if(m_cfg.useEquityProtection && m_cfg.dailyEquityProtectionPercent>0.0)
        {
         const double reference=(m_cfg.ddReference==SGH_DD_DAY_START_EQUITY ?
                                 m_dayStartEquity : m_dayStartBalance);
         if(reference>0.0)
           {
            const double drawdownPercent=(reference-equity)*100.0/reference;
            if(drawdownPercent>=m_cfg.dailyEquityProtectionPercent)
              {
               decision.blockEntries=true;
               decision.deletePendings=true;
               decision.closePositions=true;
               AddDecisionReason(decision,"EquityProtection");
              }
           }
        }
     }

   bool EntryAllowed(const datetime now=0)
     {
      SGHProtectionDecision decision;
      EvaluateProtectionDecision(now>0 ? now : TimeTradeServer(),decision);
      if(decision.blockEntries)
        {
         SetReason(decision.reason);
         return(false);
        }
      return(true);
     }

    int DeleteAllPendings()
     {
      if(!IsSymbolTradeSessionOpen(m_symbol))
         return(0);
      int deleted=0;
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         const ulong ticket=OrderGetTicket(i);
         if(ticket==0 || !IsOurOrderSelected())
            continue;
         if(!IsPendingType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
            continue;
         if(DeletePendingByTicket(ticket))
            deleted++;
        }
       return(deleted);
      }

    int DeleteExpiredPendings(const datetime now=0)
      {
       if(m_cfg.pendingExpirySeconds<=0)
          return(0);

       const datetime currentTime=(now>0 ? now : TimeTradeServer());
       int deleted=0;
       for(int i=OrdersTotal()-1;i>=0;i--)
         {
          const ulong ticket=OrderGetTicket(i);
          if(ticket==0 || !IsOurOrderSelected())
             continue;
          if(!IsPendingType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
             continue;

          const datetime setup=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
          // Exact oracle boundary: a 01:15:00 order is removed on the first
          // tick strictly after 13:15:00, producing "order canceled" rather
          // than broker-native "order expired".
          if(setup>0 && currentTime>setup+m_cfg.pendingExpirySeconds)
            {
             const string orderSymbol=OrderGetString(ORDER_SYMBOL);
             if(orderSymbol!="" && IsSymbolTradeSessionOpen(orderSymbol) &&
                DeletePendingByTicket(ticket))
                deleted++;
            }
         }
       return(deleted);
      }

   int CloseAllPositions()
     {
      int closed=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !IsOurPositionSelected())
            continue;
         if(ClosePositionByTicket(ticket))
            closed++;
        }
      return(closed);
     }

   void RunSafetyCycle(const datetime now=0)
     {
      SGHProtectionDecision decision;
      EvaluateProtectionDecision(now>0 ? now : TimeTradeServer(),decision);
      if(decision.deletePendings)
         DeleteAllPendings();
      if(decision.closePositions)
         CloseAllPositions();
     }

   bool PlacePendingStop(const ENUM_ORDER_TYPE pendingType,
                         const double requestedEntryPrice,
                         ulong &placedTicket)
     {
      placedTicket=0;
      m_lastReason="";
      if(pendingType!=ORDER_TYPE_BUY_STOP && pendingType!=ORDER_TYPE_SELL_STOP)
        {
         SetReason("Unsupported pending order type");
         return(false);
        }
      if(!TradeEnvironmentReady() || !EntryAllowed())
         return(false);

      const double entryPrice=NormalizePrice(requestedEntryPrice);
      if(m_cfg.oneShot && HasDirectionalExposure(pendingType))
        {
         SetReason("Same-direction position or pending already exists");
         return(false);
        }
      if(HasDuplicateExposurePrice(entryPrice))
        {
         SetReason("Duplicate live price");
         return(false);
        }

      double sl=0.0;
      double tp=0.0;
      if(!BuildProtectionPrices(pendingType,entryPrice,true,sl,tp) ||
         !ValidatePendingGeometry(pendingType,entryPrice,sl,tp))
         return(false);

      const double lots=ComputeLots(entryPrice,sl);
      if(lots<=0.0)
        {
         SetReason("Volume below minimum");
         return(false);
        }
      if(!CheckFreeMargin(pendingType,lots,entryPrice))
         return(false);

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action       = TRADE_ACTION_PENDING;
      request.magic        = (ulong)m_cfg.magic;
      request.symbol       = m_symbol;
      request.volume       = lots;
      request.price        = entryPrice;
      request.sl           = sl;
      request.tp           = tp;
      request.deviation    = Deviation();
      request.type         = pendingType;
      request.type_filling = ORDER_FILLING_RETURN;
      request.comment      = m_cfg.comment;

       // The original manages the profile lifetime itself.  Broker-native
       // ORDER_TIME_SPECIFIED expires on the exact boundary and is observably
       // one tick too early on the captured carrier.
       request.type_time=ORDER_TIME_GTC;

      ResetLastError();
      if(!OrderCheck(request,check))
        {
         SetReason(StringFormat("OrderCheck failed retcode=%u comment=%s error=%d",
                                check.retcode,check.comment,GetLastError()));
         return(false);
        }

      ResetLastError();
      if(!OrderSend(request,result) || !TradeResultSucceeded(result,true))
        {
         SetReason(StringFormat("Pending send failed retcode=%u comment=%s error=%d",
                                result.retcode,result.comment,GetLastError()));
         return(false);
        }

      placedTicket=(result.order>0 ? result.order : result.deal);
      Log(StringFormat("Pending placed ticket=%I64u type=%d lots=%.4f price=%s SL=%s TP=%s",
                       placedTicket,(int)pendingType,lots,
                       DoubleToString(entryPrice,m_digits),DoubleToString(sl,m_digits),
                       DoubleToString(tp,m_digits)));
      return(true);
     }

   void ManagePositions(const datetime now=0)
     {
      const datetime currentTime=(now>0 ? now : TimeTradeServer());
      PrunePropTickets();

      MqlTick tick;
      if(!SymbolInfoTick(m_symbol,tick))
         return;
      const double minDistance=BrokerMinimumDistancePrice();

      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         const ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !IsOurPositionSelected())
            continue;

         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const double openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
         double currentSL=PositionGetDouble(POSITION_SL);
         double currentTP=PositionGetDouble(POSITION_TP);

         if(m_cfg.propScalperMode && !PropTicketProcessed(ticket))
           {
            const datetime openedAt=(datetime)PositionGetInteger(POSITION_TIME);
            if(currentTime-openedAt<m_cfg.propHoldSeconds)
               continue; // No normal trailing during the observed hold.

            double normalSL=0.0;
            double normalTP=0.0;
            const ENUM_ORDER_TYPE side=(type==POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
            BuildProtectionPrices(side,openPrice,false,normalSL,normalTP);

            // Never regress a stop which was already made more protective
            // (for example after an EA restart with an existing position).
            if(type==POSITION_TYPE_BUY && currentSL>normalSL)
               normalSL=currentSL;
            if(type==POSITION_TYPE_SELL && currentSL>0.0 &&
               (normalSL<=0.0 || currentSL<normalSL))
               normalSL=currentSL;

            // Exact behavior when price has already crossed the target at
            // second 120 was not observed. Avoid sending an invalid SL/TP.
            bool geometryValid=true;
            if(type==POSITION_TYPE_BUY)
              {
               if(normalSL>0.0 && normalSL>=tick.bid-minDistance)
                  geometryValid=false;
               if(normalTP>0.0 && normalTP<=tick.ask+minDistance)
                  geometryValid=false;
              }
            else
              {
               if(normalSL>0.0 && normalSL<=tick.ask+minDistance)
                  geometryValid=false;
               if(normalTP>0.0 && normalTP>=tick.bid-minDistance)
                  geometryValid=false;
              }

            if(geometryValid && ModifyPosition(ticket,normalSL,normalTP))
              {
               MarkPropTicketProcessed(ticket);
               currentSL=normalSL;
               currentTP=normalTP;
              }
            else
               continue;
           }

         if(m_cfg.trailStartPoints<=0.0 || m_cfg.trailDistancePoints<=0.0)
            continue;

         double candidateSL=0.0;
         if(type==POSITION_TYPE_BUY)
           {
            if(tick.bid-openPrice<m_cfg.trailStartPoints*m_point)
               continue;
            candidateSL=NormalizePrice(tick.bid-m_cfg.trailDistancePoints*m_point);
            if(candidateSL>=tick.bid-minDistance)
               continue;
            if(currentSL>0.0 && candidateSL<=currentSL+m_point*0.1)
               continue;
           }
         else
           {
            if(openPrice-tick.ask<m_cfg.trailStartPoints*m_point)
               continue;
            candidateSL=NormalizePrice(tick.ask+m_cfg.trailDistancePoints*m_point);
            if(candidateSL<=tick.ask+minDistance)
               continue;
            if(currentSL>0.0 && candidateSL>=currentSL-m_point*0.1)
               continue;
           }

         ModifyPosition(ticket,candidateSL,currentTP);
        }
     }
  };

// -------------------------------------------------------------------
// Small integration API. The signal include may keep ownership of its
// SGHEffectiveProfile / SGHSignal structures and pass only the resulting
// side and entry price here, avoiding shared-structure redefinitions.
// -------------------------------------------------------------------
CSGHTradeEngine g_sghTradeEngine;

bool SGHTradeInit(const SGHTradeEngineConfig &cfg)
  {
   return(g_sghTradeEngine.Configure(cfg));
  }

void SGHTradeApplyProfile(const double stopLossPoints,
                          const double takeProfitPoints,
                          const double trailStartPoints,
                          const double trailDistancePoints,
                          const int pendingExpirySeconds,
                          const bool propScalperMode)
  {
   g_sghTradeEngine.ApplyProfileTradeParameters(stopLossPoints,
                                                takeProfitPoints,
                                                trailStartPoints,
                                                trailDistancePoints,
                                                pendingExpirySeconds,
                                                propScalperMode);
  }

bool SGHSafetyGate(const datetime now=0)
  {
   return(g_sghTradeEngine.EntryAllowed(now));
  }

void SGHSetNewsBlock(const bool stateKnown,const bool blocked)
  {
   g_sghTradeEngine.SetExternalNewsBlock(stateKnown,blocked);
  }

bool SGHSubmitSignal(const ENUM_ORDER_TYPE pendingType,
                     const double entryPrice,ulong &placedTicket)
  {
   return(g_sghTradeEngine.PlacePendingStop(pendingType,entryPrice,placedTicket));
  }

#ifdef SGH_SIGNAL_ENGINE_MQH
// Convenience overloads are available when SGH_SignalEngine.mqh is included
// first. The primitive overload above keeps this module independently usable.
void SGHTradeApplyProfile(const SGHEffectiveProfile &profile)
  {
   long expirySeconds=profile.pendingExpiryHours*3600;
   if(expirySeconds>2147483647)
      expirySeconds=2147483647;
   if(expirySeconds<0)
      expirySeconds=0;
   SGHTradeApplyProfile(profile.stopLossPoints,profile.takeProfitPoints,
                        profile.trailStartPoints,profile.trailDistancePoints,
                        (int)expirySeconds,profile.isPropScalper);
  }

bool SGHSubmitSignal(const SGHSignal &signal,ulong &placedTicket)
  {
   placedTicket=0;
   if(signal.status!=SGH_STATUS_READY)
      return(false);
   if(signal.orderType!=ORDER_TYPE_BUY_STOP &&
      signal.orderType!=ORDER_TYPE_SELL_STOP)
      return(false);
   return(SGHSubmitSignal(signal.orderType,signal.entryPrice,placedTicket));
  }
#endif

void SGHManage(const datetime now=0)
  {
   g_sghTradeEngine.RunSafetyCycle(now);
   g_sghTradeEngine.DeleteExpiredPendings(now);
   g_sghTradeEngine.ManagePositions(now);
  }

#endif // __SGH_TRADE_ENGINE_MQH__
