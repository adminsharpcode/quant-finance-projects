#ifndef SGH_SIGNAL_ENGINE_MQH
#define SGH_SIGNAL_ENGINE_MQH

// Smart Gold Hunter v2.0 clean-room signal engine.
//
// Scope:
//   - recovered effective profile values;
//   - exactly 300 CopyRates bars;
//   - ZigZag-like Depth/Deviation/Backstep reconstruction;
//   - latest-two alternating-extrema scan (maximum 100 buffer slots);
//   - Buy Stop / Sell Stop choice and recovered entry-offset formulas.
//
// Deliberately outside this module: duplicate-price suppression, exposure and
// margin checks, StopsLevel/FreezeLevel enforcement, lot sizing, daily/news
// guards, pending-order submission and position management.

#define SGH_COPY_RATES_COUNT          300
#define SGH_EXTREMA_SCAN_LIMIT        100
#define SGH_ZIGZAG_DEVIATION_POINTS    10
// Native first-pass cleanup visits the preceding three map slots.  This is
// distinct from the two-slot constant used by the prior Stage8 candidate.
#define SGH_ZIGZAG_BACKSTEP             3
#define SGH_TRIGGER_DISTANCE_POINTS     10

enum ENUM_SGH_PROFILE_MODE
  {
   SGH_MODE_SCALPER     = 0,
   SGH_MODE_SWINGER     = 1,
   SGH_MODE_POSITIVE_RR = 2,
   SGH_MODE_PROP_SCALPER= 3,
   SGH_MODE_CUSTOM      = 4
  };

enum ENUM_SGH_EXTREMUM_TYPE
  {
   SGH_EXTREMUM_NONE = 0,
   SGH_EXTREMUM_HIGH = 1,
   SGH_EXTREMUM_LOW  =-1
  };

enum ENUM_SGH_PENDING_DIRECTION
  {
   SGH_DIRECTION_NONE      = 0,
   SGH_DIRECTION_BUY_STOP  = 1,
   SGH_DIRECTION_SELL_STOP =-1
  };

enum ENUM_SGH_SIGNAL_STATUS
  {
   SGH_STATUS_ERROR             =-1,
   SGH_STATUS_NO_SETUP          = 0,
   SGH_STATUS_READY             = 1,
   SGH_STATUS_NOT_ENOUGH_RATES  = 2,
   SGH_STATUS_NOT_ENOUGH_SWINGS = 3,
   SGH_STATUS_NO_TICK           = 4,
   SGH_STATUS_BAD_SYMBOL        = 5
  };

struct SGHCustomValues
  {
   double takeProfitPoints;
   double stopLossPoints;
   double trailStartPoints;
   double trailDistancePoints;
   double entryOffsetPoints;
   int    pauseSeconds;
  };

// All distances are raw broker points.  For the captured two-digit XAUUSD
// carrier, Point=0.01 and therefore 100 points=$1.00 of price.
struct SGHEffectiveProfile
  {
   int              requestedMode;
   ENUM_SGH_PROFILE_MODE effectiveMode;
   string           profileName;
   ENUM_TIMEFRAMES  signalTimeframe;
   int              swingDepth;
   int              zigzagDeviationPoints;
   int              zigzagBackstep;
   int              copyRatesCount;
   int              extremaScanLimit;
   long             pendingExpiryHours;
   double           takeProfitPoints;
   double           stopLossPoints;
   double           trailStartPoints;
   double           trailDistancePoints;
   double           entryOffsetPoints;
   int              pauseSeconds;
   bool             isCustom;
   bool             isPropScalper;
   int              propHoldSeconds;
   double           initialTakeProfitPoints;
   double           initialStopLossPoints;
  };

struct SGHExtremum
  {
   ENUM_SGH_EXTREMUM_TYPE type;
   double                 price;
   datetime               time;
   int                    shift;
  };

struct SGHSignal
  {
   ENUM_SGH_SIGNAL_STATUS      status;
   ENUM_SGH_PENDING_DIRECTION direction;
   ENUM_ORDER_TYPE             orderType;
   string                      symbol;
   ENUM_TIMEFRAMES             timeframe;
   double                      bid;
   double                      ask;
   double                      rawPoint;
   double                      normalizedPoint;
   double                      triggerDistance;
   double                      entryPrice;
   double                      stopLossPrice;
   double                      takeProfitPrice;
   datetime                    expiration;
   SGHExtremum                 latestExtremum;
   SGHExtremum                 previousExtremum;
   int                         copiedRates;
   int                         errorCode;
  };

void SGHSetCapturedCustomDefaults(SGHCustomValues &values)
  {
   // Defaults observed in the captured v2.0 SET files.  They only become
   // effective when the requested mode is Custom (4 or an unknown value).
   values.takeProfitPoints    =250.0;
   values.stopLossPoints      =1500.0;
   values.trailStartPoints    =100.0;
   values.trailDistancePoints =50.0;
   values.entryOffsetPoints   =0.0;
   values.pauseSeconds        =300;
  }

void SGHResetExtremum(SGHExtremum &extremum)
  {
   extremum.type =SGH_EXTREMUM_NONE;
   extremum.price=0.0;
   extremum.time =0;
   extremum.shift=-1;
  }

void SGHResetSignal(SGHSignal &signal,const string symbol,
                    const ENUM_TIMEFRAMES timeframe)
  {
   signal.status           =SGH_STATUS_NO_SETUP;
   signal.direction        =SGH_DIRECTION_NONE;
   signal.orderType        =ORDER_TYPE_BUY_STOP;
   signal.symbol           =symbol;
   signal.timeframe        =timeframe;
   signal.bid              =0.0;
   signal.ask              =0.0;
   signal.rawPoint         =0.0;
   signal.normalizedPoint  =0.0;
   signal.triggerDistance  =0.0;
   signal.entryPrice       =0.0;
   signal.stopLossPrice    =0.0;
   signal.takeProfitPrice  =0.0;
   signal.expiration       =0;
   signal.copiedRates      =0;
   signal.errorCode        =0;
   SGHResetExtremum(signal.latestExtremum);
   SGHResetExtremum(signal.previousExtremum);
  }

void SGHSetProfileCommon(const int requested_mode,
                         SGHEffectiveProfile &profile)
  {
   profile.requestedMode             =requested_mode;
   profile.effectiveMode             =SGH_MODE_CUSTOM;
   profile.profileName               ="Custom";
   profile.signalTimeframe           =PERIOD_CURRENT;
   profile.swingDepth                =12;
   profile.zigzagDeviationPoints     =SGH_ZIGZAG_DEVIATION_POINTS;
   profile.zigzagBackstep            =SGH_ZIGZAG_BACKSTEP;
   profile.copyRatesCount            =SGH_COPY_RATES_COUNT;
   profile.extremaScanLimit          =SGH_EXTREMA_SCAN_LIMIT;
   profile.pendingExpiryHours        =27000;
   profile.takeProfitPoints          =0.0;
   profile.stopLossPoints            =0.0;
   profile.trailStartPoints          =0.0;
   profile.trailDistancePoints       =0.0;
   profile.entryOffsetPoints         =0.0;
   profile.pauseSeconds              =0;
   profile.isCustom                  =true;
   profile.isPropScalper             =false;
   profile.propHoldSeconds           =0;
   profile.initialTakeProfitPoints   =0.0;
   profile.initialStopLossPoints     =0.0;
  }

// Resolves the recovered hidden/effective values.  Built-in modes ignore the
// custom arguments, matching the observed EA.  Every value in the four cases
// below is recovered JIT/runtime evidence, not a fitted parameter.
bool SGHResolveProfile(const int mode,const SGHCustomValues &custom_values,
                       SGHEffectiveProfile &profile)
  {
   SGHSetProfileCommon(mode,profile);

   switch(mode)
     {
      case SGH_MODE_SCALPER:
         profile.effectiveMode           =SGH_MODE_SCALPER;
         profile.profileName             ="Scalper";
         profile.signalTimeframe         =PERIOD_M15;
         profile.swingDepth              =18;
         profile.pendingExpiryHours      =12;
         profile.takeProfitPoints        =1500.0;
         profile.stopLossPoints          =300.0;
         profile.trailStartPoints        =140.0;
         profile.trailDistancePoints     =40.0;
         profile.entryOffsetPoints       =-160.0;
         profile.pauseSeconds            =60;
         profile.isCustom                =false;
         break;

      case SGH_MODE_SWINGER:
         profile.effectiveMode           =SGH_MODE_SWINGER;
         profile.profileName             ="Swinger";
         profile.signalTimeframe         =PERIOD_M15;
         profile.swingDepth              =12;
         profile.pendingExpiryHours      =27000;
         profile.takeProfitPoints        =4500.0;
         profile.stopLossPoints          =2500.0;
         profile.trailStartPoints        =1500.0;
         profile.trailDistancePoints     =500.0;
         profile.entryOffsetPoints       =-50.0;
         profile.pauseSeconds            =60;
         profile.isCustom                =false;
         break;

      case SGH_MODE_POSITIVE_RR:
         profile.effectiveMode           =SGH_MODE_POSITIVE_RR;
         profile.profileName             ="Positive RR";
         profile.signalTimeframe         =PERIOD_M30;
         profile.swingDepth              =18;
         profile.pendingExpiryHours      =12;
         profile.takeProfitPoints        =2250.0;
         profile.stopLossPoints          =325.0;
         profile.trailStartPoints        =575.0;
         profile.trailDistancePoints     =165.0;
         profile.entryOffsetPoints       =-175.0;
         profile.pauseSeconds            =60;
         profile.isCustom                =false;
         break;

      case SGH_MODE_PROP_SCALPER:
         profile.effectiveMode           =SGH_MODE_PROP_SCALPER;
         profile.profileName             ="Prop Scalper";
         profile.signalTimeframe         =PERIOD_M15;
         profile.swingDepth              =18;
         profile.pendingExpiryHours      =12;
         profile.takeProfitPoints        =2500.0;
         profile.stopLossPoints          =350.0;
         profile.trailStartPoints        =165.0;
         profile.trailDistancePoints     =40.0;
         profile.entryOffsetPoints       =-150.0;
         profile.pauseSeconds            =60;
         profile.isCustom                =false;
         profile.isPropScalper           =true;
         profile.propHoldSeconds         =120;
         profile.initialTakeProfitPoints =5000.0;
         profile.initialStopLossPoints   =700.0;
         break;

      default:
         // Recovered dispatch sends 4+ to Custom.  Negative values were not a
         // valid UI state; this clean-room implementation also treats them as
         // Custom so that it fails safely and deterministically.
         profile.effectiveMode        =SGH_MODE_CUSTOM;
         profile.profileName          ="Custom";
         profile.signalTimeframe      =PERIOD_CURRENT;
         profile.swingDepth           =12;
         profile.pendingExpiryHours   =27000;
         profile.takeProfitPoints     =custom_values.takeProfitPoints;
         profile.stopLossPoints       =custom_values.stopLossPoints;
         profile.trailStartPoints     =custom_values.trailStartPoints;
         profile.trailDistancePoints  =custom_values.trailDistancePoints;
         profile.entryOffsetPoints    =custom_values.entryOffsetPoints;
         profile.pauseSeconds         =custom_values.pauseSeconds;
         profile.isCustom             =true;
         break;
     }

   if(!profile.isPropScalper)
     {
      profile.initialTakeProfitPoints=profile.takeProfitPoints;
      profile.initialStopLossPoints  =profile.stopLossPoints;
     }

   return(true);
  }

// Convenience overload for integration with the original input names.
bool SGHResolveProfile(const int mode,
                       const double custom_take_profit_points,
                       const double custom_stop_loss_points,
                       const double custom_trail_start_points,
                       const double custom_trail_distance_points,
                       const int custom_pause_seconds,
                       const double custom_entry_offset_points,
                       SGHEffectiveProfile &profile)
  {
   SGHCustomValues values;
   values.takeProfitPoints    =custom_take_profit_points;
   values.stopLossPoints      =custom_stop_loss_points;
   values.trailStartPoints    =custom_trail_start_points;
   values.trailDistancePoints =custom_trail_distance_points;
   values.entryOffsetPoints   =custom_entry_offset_points;
   values.pauseSeconds        =custom_pause_seconds;
   return(SGHResolveProfile(mode,values,profile));
  }

// Convenience overload using the exact Custom defaults captured from SET.
bool SGHResolveProfile(const int mode,SGHEffectiveProfile &profile)
  {
   SGHCustomValues values;
   SGHSetCapturedCustomDefaults(values);
   return(SGHResolveProfile(mode,values,profile));
  }

double SGHRawPoint(const string symbol)
  {
   return(SymbolInfoDouble(symbol,SYMBOL_POINT));
  }

double SGHNormalizedPoint(const string symbol)
  {
   const double point=SGHRawPoint(symbol);
   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   if(digits==3 || digits==5)
      return(point*10.0);
   return(point);
  }

int SGHWindowLowest(const MqlRates &rates[],const int start,const int count)
  {
   const int bars=ArraySize(rates);
   if(start<0 || start>=bars || count<=0)
      return(-1);

   int end=start+count;
   if(end>bars)
      end=bars;

   int result=start;
   double value=rates[start].low;
   for(int i=start+1;i<end;i++)
     {
      if(rates[i].low<value)
        {
         value=rates[i].low;
         result=i;
        }
     }
   return(result);
  }

int SGHWindowHighest(const MqlRates &rates[],const int start,const int count)
  {
   const int bars=ArraySize(rates);
   if(start<0 || start>=bars || count<=0)
      return(-1);

   int end=start+count;
   if(end>bars)
      end=bars;

   int result=start;
   double value=rates[start].high;
   for(int i=start+1;i<end;i++)
     {
      if(rates[i].high>value)
        {
         value=rates[i].high;
         result=i;
        }
     }
   return(result);
  }

// Produces series-indexed buffers: index 0 is the newest (possibly forming)
// bar.  The first pass follows the conventional ZigZag extrema-map algorithm;
// the second pass forces alternating extrema and replaces a still-developing
// same-side extreme with the more extreme value.
bool SGHBuildZigZag(const MqlRates &rates[],const int depth,
                    const double deviation_price,const int backstep,
                    double &high_buffer[],double &low_buffer[],
                    double &zigzag_buffer[])
  {
   const int bars=ArraySize(rates);
   if(depth<2 || backstep<0 || bars<depth+2)
      return(false);

   ArrayResize(high_buffer,bars);
   ArrayResize(low_buffer,bars);
   ArrayResize(zigzag_buffer,bars);
   ArraySetAsSeries(high_buffer,true);
   ArraySetAsSeries(low_buffer,true);
   ArraySetAsSeries(zigzag_buffer,true);
   ArrayInitialize(high_buffer,0.0);
   ArrayInitialize(low_buffer,0.0);
   ArrayInitialize(zigzag_buffer,0.0);

   double last_low =0.0;
   double last_high=0.0;
   const int oldest_calculable=bars-depth;

   // Series index decreases as time advances, hence oldest -> newest is a
   // descending loop.
   for(int shift=oldest_calculable;shift>=0;shift--)
     {
      int index=SGHWindowLowest(rates,shift,depth);
      double value=(index>=0 ? rates[index].low : 0.0);

      if(value==last_low)
         value=0.0;
      else
        {
         last_low=value;
         if((rates[shift].low-value)>deviation_price)
            value=0.0;
         else
           {
            for(int back=1;back<=backstep;back++)
              {
               const int old_shift=shift+back;
               if(old_shift>=bars)
                  break;
               const double old_value=low_buffer[old_shift];
               if(old_value!=0.0 && old_value>value)
                  low_buffer[old_shift]=0.0;
              }
           }
        }
      if(value!=0.0 && rates[shift].low==value)
         low_buffer[shift]=value;

      index=SGHWindowHighest(rates,shift,depth);
      value=(index>=0 ? rates[index].high : 0.0);

      if(value==last_high)
         value=0.0;
      else
        {
         last_high=value;
         if((value-rates[shift].high)>deviation_price)
            value=0.0;
         else
           {
            for(int back=1;back<=backstep;back++)
              {
               const int old_shift=shift+back;
               if(old_shift>=bars)
                  break;
               const double old_value=high_buffer[old_shift];
               if(old_value!=0.0 && old_value<value)
                  high_buffer[old_shift]=0.0;
              }
           }
        }
      if(value!=0.0 && rates[shift].high==value)
         high_buffer[shift]=value;
     }

   int what_to_find=0; // 0=first point, 1=high next, -1=low next
   int last_low_position =-1;
   int last_high_position=-1;
   last_low =0.0;
   last_high=0.0;

   for(int shift=oldest_calculable;shift>=0;shift--)
     {
      const double high=high_buffer[shift];
      const double low =low_buffer[shift];

      if(what_to_find==0)
        {
         if(high!=0.0)
           {
            last_high=high;
            last_high_position=shift;
            zigzag_buffer[shift]=high;
            what_to_find=-1;
           }
         if(low!=0.0)
           {
            last_low=low;
            last_low_position=shift;
            zigzag_buffer[shift]=low;
            what_to_find=1;
           }
         continue;
        }

      if(what_to_find==1)
        {
         if(low!=0.0 && low<last_low && high==0.0)
           {
            if(last_low_position>=0)
               zigzag_buffer[last_low_position]=0.0;
            last_low=low;
            last_low_position=shift;
            zigzag_buffer[shift]=low;
           }
         if(high!=0.0 && low==0.0)
           {
            last_high=high;
            last_high_position=shift;
            zigzag_buffer[shift]=high;
            what_to_find=-1;
           }
         continue;
        }

      if(high!=0.0 && high>last_high && low==0.0)
        {
         if(last_high_position>=0)
            zigzag_buffer[last_high_position]=0.0;
         last_high=high;
         last_high_position=shift;
         zigzag_buffer[shift]=high;
        }
      if(low!=0.0 && high==0.0)
        {
         last_low=low;
         last_low_position=shift;
         zigzag_buffer[shift]=low;
         what_to_find=1;
        }
     }

   return(true);
  }

bool SGHFindLatestTwoExtrema(const MqlRates &rates[],
                             const double &high_buffer[],
                             const double &low_buffer[],
                             const double &zigzag_buffer[],
                             const int scan_limit,
                             SGHExtremum &latest,
                             SGHExtremum &previous)
  {
   SGHResetExtremum(latest);
   SGHResetExtremum(previous);

   int limit=scan_limit;
   if(limit>ArraySize(zigzag_buffer))
      limit=ArraySize(zigzag_buffer);
   if(limit>ArraySize(rates))
      limit=ArraySize(rates);

   // Native scan +0x4960..+0x5921 excludes shift 0 and examines shifts
   // 1..99.  It counts the first two non-zero values in the composite
   // ZigZag buffer exactly as stored; it does not skip equal/consecutive
   // candidate types.
   for(int shift=1;shift<limit;shift++)
     {
      const double value=zigzag_buffer[shift];
      if(value==0.0)
         continue;

      ENUM_SGH_EXTREMUM_TYPE type=SGH_EXTREMUM_NONE;
      if(high_buffer[shift]!=0.0 && value==high_buffer[shift])
         type=SGH_EXTREMUM_HIGH;
      else if(low_buffer[shift]!=0.0 && value==low_buffer[shift])
         type=SGH_EXTREMUM_LOW;

      if(latest.shift<0)
        {
         latest.type =type;
         latest.price=value;
         latest.time =rates[shift].time;
         latest.shift=shift;
         continue;
        }

      previous.type =type;
      previous.price=value;
      previous.time =rates[shift].time;
      previous.shift=shift;
      return(true);
     }

   return(false);
  }

double SGHNormalizePrice(const string symbol,const double price)
  {
   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   return(NormalizeDouble(price,digits));
  }

// Returns true only when an actionable pending-order candidate is present.
// Inspect out.status to distinguish ordinary "no setup" from data/tick errors.
bool SGHGenerateSignal(const string symbol,const SGHEffectiveProfile &profile,
                       SGHSignal &out)
  {
   SGHResetSignal(out,symbol,profile.signalTimeframe);

   const double point=SGHRawPoint(symbol);
   const double normalized_point=SGHNormalizedPoint(symbol);
   if(point<=0.0 || normalized_point<=0.0)
     {
      out.status=SGH_STATUS_BAD_SYMBOL;
      out.errorCode=GetLastError();
      return(false);
     }

   out.rawPoint=point;
   out.normalizedPoint=normalized_point;

   MqlRates rates[];
   ArrayResize(rates,profile.copyRatesCount);
   ArraySetAsSeries(rates,true);
   ResetLastError();
   const int copied=CopyRates(symbol,profile.signalTimeframe,0,
                              profile.copyRatesCount,rates);
   out.copiedRates=copied;
   if(copied!=profile.copyRatesCount)
     {
      out.status=SGH_STATUS_NOT_ENOUGH_RATES;
      out.errorCode=GetLastError();
      return(false);
     }

   double high_buffer[];
   double low_buffer[];
   double zigzag_buffer[];

   // Recovered code applies normal 3/5-digit scaling to the 10-point ZigZag
   // deviation.  Entry/SL/TP formulas below intentionally use raw Point.
   const double deviation_price=
      profile.zigzagDeviationPoints*normalized_point;

   if(!SGHBuildZigZag(rates,profile.swingDepth,deviation_price,
                      profile.zigzagBackstep,high_buffer,low_buffer,
                      zigzag_buffer))
     {
      out.status=SGH_STATUS_ERROR;
      return(false);
     }

   SGHExtremum latest;
   SGHExtremum previous;
   if(!SGHFindLatestTwoExtrema(rates,high_buffer,low_buffer,zigzag_buffer,
                               profile.extremaScanLimit,latest,previous))
     {
      out.status=SGH_STATUS_NOT_ENOUGH_SWINGS;
      return(false);
     }
   out.latestExtremum=latest;
   out.previousExtremum=previous;

   MqlTick tick;
   ResetLastError();
   if(!SymbolInfoTick(symbol,tick))
     {
      out.status=SGH_STATUS_NO_TICK;
      out.errorCode=GetLastError();
      return(false);
     }

   out.bid=tick.bid;
   out.ask=tick.ask;

   // UNCERTAIN EDGE: JIT evidence proves a 10-point trigger and proves normal
   // 3/5-digit scaling in this swing path, but it does not isolate whether the
   // multiplier is applied before or after this exact comparison.  Using the
   // normalized point is exact on the captured two-digit XAUUSD and is the
   // conventional cross-digit interpretation.
   out.triggerDistance=SGH_TRIGGER_DISTANCE_POINTS*normalized_point;

   // JIT names: latest=x11 (newer), previous=x8 (older/actionable).  Direction
   // is selected by their prices, not by a reconstructed enum/type test:
   // older>newer -> BUY from the older high; newer>older -> SELL from the
   // older low.  This also preserves the native edge semantics if two stored
   // composite points receive the same provisional type classification.
   const SGHExtremum actionable=previous;

   if(previous.price>latest.price)
     {
      out.direction=SGH_DIRECTION_BUY_STOP;
      out.orderType=ORDER_TYPE_BUY_STOP;

      // Direction exists before actionability in the native flow.  The main
      // EA uses this raw branch to reset the opposite sticky exposure latch
      // even when the 10-point distance gate is not yet satisfied.
      if((actionable.price-tick.ask)<=out.triggerDistance)
        {
         out.status=SGH_STATUS_NO_SETUP;
         return(false);
        }

      // Recovered exact formula:
      //   buyEntry = swingHigh + offsetPoints * Point
      out.entryPrice=SGHNormalizePrice(symbol,
         actionable.price+profile.entryOffsetPoints*point);
      out.stopLossPrice=SGHNormalizePrice(symbol,
         out.entryPrice-profile.initialStopLossPoints*point);
      out.takeProfitPrice=SGHNormalizePrice(symbol,
         out.entryPrice+profile.initialTakeProfitPoints*point);
     }
   else if(latest.price>previous.price)
     {
      out.direction=SGH_DIRECTION_SELL_STOP;
      out.orderType=ORDER_TYPE_SELL_STOP;

      if((tick.bid-actionable.price)<=out.triggerDistance)
        {
         out.status=SGH_STATUS_NO_SETUP;
         return(false);
        }

      // Recovered exact formula:
      //   sellEntry = swingLow - offsetPoints * Point
      out.entryPrice=SGHNormalizePrice(symbol,
         actionable.price-profile.entryOffsetPoints*point);
      out.stopLossPrice=SGHNormalizePrice(symbol,
         out.entryPrice+profile.initialStopLossPoints*point);
      out.takeProfitPrice=SGHNormalizePrice(symbol,
         out.entryPrice-profile.initialTakeProfitPoints*point);
     }
   else
     {
      out.status=SGH_STATUS_NO_SETUP;
      return(false);
     }

   out.expiration=(datetime)(TimeCurrent()+profile.pendingExpiryHours*3600);
   out.status=SGH_STATUS_READY;
   return(true);
  }

// Recovered simultaneous-candidate edge: low wins the initial state tie;
// otherwise the opposite-buffer-zero predicates defer a bar carrying both a
// high and a low candidate.  The three-slot first-pass cleanup above decides
// which older provisional endpoint remains visible around such outside bars.
// Broker StopsLevel/FreezeLevel can still invalidate a candidate after a
// negative built-in offset places it too near price.  That is an order-
// validation concern and is deliberately not converted into a signal filter.

#endif // SGH_SIGNAL_ENGINE_MQH
