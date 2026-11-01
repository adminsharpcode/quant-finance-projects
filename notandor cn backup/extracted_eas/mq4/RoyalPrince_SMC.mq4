/*
── Project ─────────────────────────────────────────────────────────────────────

Name:        RoyalPrince_SMC
Version:     1.00
Date:        2025
Repository:  Available @ https://fxcodebase.com/code/viewtopic.php?f=38&t=76432&p=161150#p161150
License:     GNU

── Author ──────────────────────────────────────────────────────────────────────

Developed by: Mario Jemic
Email:        mario.jemic@gmail.com
Website:      https://mario-jemic.com

── Support & Donations ─────────────────────────────────────────────────────────

PayPal:      https://goo.gl/9Rj74e
Patreon:     https://tiny.cc/1ybwxz
BuyMeACoffee:https://tiny.cc/bj7vzj

Crypto:
 BTC : 16F5k43RXibTmna4np8bPVgmXM1CzjXFJJ
 SOL : 3nh5rpUKopcYLNU4zGCdUFAkM3iRQq8VVUmuzVG6VDf2
 ETH/BNB/USDT/XRP (ERC20/BEP20): 0xe53aab6bc468a963a02d1319660ee60cf80fc8e7

── Copyright ───────────────────────────────────────────────────────────────────

© 2025 Gehtsoft USA LLC — https://fxcodebase.com

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 <https://www.gnu.org/licenses/>.
*/
/*
in Forex and MetaTrader 4 (MT4), AMA stands for Adaptive Moving Average (also known as Kaufman’s Adaptive Moving Average, or KAMA). ✅

Here’s a breakdown:

 What is AMA / KAMA?

The Adaptive Moving Average (AMA) is a type of moving average that automatically adjusts its sensitivity (or “speed”) based on market volatility or price noise.

It was developed by Perry J. Kaufman in 1998 to make moving averages “smarter” — adapting to market conditions.

 How it works

In trending markets, AMA becomes faster, following price more closely (like an EMA).

In sideways/choppy markets, AMA becomes slower, filtering out noise (like an SMA).

This adaptability comes from a factor called the Efficiency Ratio (ER):

ER measures how “directional” price movement is.

AMA then adjusts its smoothing constant based on ER.

<code>
ER = |Price(t) - Price(t - N)| / Sum(|Price(i) - Price(i-1)|, i = t-N+1...t)

SC = [ER * (FastSC - SlowSC) + SlowSC]^2
AMA(t) = AMA(t-1) + SC * (Price(t) - AMA(t-1))
</code>
*/
#property copyright "Copyright © 2025, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com"
#property version   "1.00"
#property description "BOS = Break of Structure or BreakOut to the upside or downside"
#property description "CHoCH = Change of Character or Reverse Trend"
#property description "EQH = Double Top; when two or more swing highs form around the same level"
#property description "EQH = liquidity resting above equal highs → potential buy-side liquidity grab area."
#property description "EQL = Double Bottom; when two or more swing lows form around the same price level"
#property description "EQL = liquidity resting below equal lows → potential sell-side liquidity grab area."

#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "AMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

input string SMC1                  = "----------------------------"; //"----------------------------"
input int    RefreshEverySeconds   = 30;                             // Refresh Every 30 seconds?
input color  AMAColor              = clrDarkViolet;
input bool   ShowAMA               = true;
input string SMC2                  = "----------------------------"; //"----------------------------"
input string Mode                  = "Historical";                   // Mode: Historical/Present
input string Style                 = "Colored";                      // Style: Colored/Monochrome
input bool   ShowTrend             = false;                          // Color Candles
input bool   ShowInternals         = true;                           // Show Internal Structure
input string ShowIBull             = "All";                          // Bullish Structure: All/BOS/CHoCH
input color  SwingIBullColor       = clrGreen;                       // Internal Bullish Color
input string ShowIBear             = "All";                          // Bearish Structure: All/BOS/CHoCH
input color  SwingIBearColor       = clrRed;                         // Internal Bearish Color
input bool   IFilterConfluence     = false;                          // Confluence Filter
input string InternalStructureSize = "Tiny";                         // Internal Label Size
input bool   ShowStructure         = true;                           // Show Swing Structure
input string ShowBull              = "All";                          // Bullish Structure: All/BOS/CHoCH
input color  SwingBullColor        = clrGreen;                       // Swing Bullish Color
input string ShowBear              = "All";                          // Bearish Structure: All/BOS/CHoCH
input color  SwingBearColor        = clrRed;                         // Swing Bearish Color
input string SwingStructureSize    = "Small";                        // Swing Label Size
input bool   ShowSwings            = false;                          // Show Swing Points
input int    SwingLength           = 50;                             // Swing Length
input bool   ShowHLSwings          = true;                           // Show Strong/Weak High/Low
input bool   ShowIOB               = true;                           // Internal Order Blocks
input int    IOBShowLast           = 5;                              // Internal OB Count
input bool   ShowOB                = false;                          // Swing Order Blocks
input int    OBShowLast            = 5;                              // Swing OB Count
input string OBFilter              = "Atr";                          // Order Block Filter: Atr/Cumulative Mean Range
input color  IBullOBColor          = clrHoneydew;                    // Internal Bullish OB
input color  IBearOBColor          = clrLightPink;                   // Internal Bearish OB
input color  BullOBColor           = clrBlue;                        // Bullish OB
input color  BearOBColor           = clrDarkRed;                     // Bearish OB
input bool   ShowEQ                = true;                           // Equal High/Low
input int    EQLen                 = 3;                              // Bars Confirmation
input double EQThreshold           = 0.1;                            // Threshold
input string EQSize                = "Tiny";                         // Label Size
input bool   ShowFVG               = false;                          // Fair Value Gaps
input bool   FVGAuto               = true;                           // Auto Threshold
input string FVGTF                 = "";                             // Timeframe (empty = current)
input color  BullFVGColor          = clrLimeGreen;                   // Bullish FVG
input color  BearFVGColor          = clrRed;                         // Bearish FVG
input int    FVGExtend             = 1;                              // Extend FVG
input bool   ShowPDHL              = false;                          // Daily High/Low
input string PDHLStyle             = "Solid";                        // Daily Style
input color  PDHLColor             = clrBlue;                        // Daily Color
input bool   ShowPWHL              = false;                          // Weekly High/Low
input string PWHLStyle             = "Solid";                        // Weekly Style
input color  PWHLColor             = clrBlue;                        // Weekly Color
input bool   ShowPMHL              = false;                          // Monthly High/Low
input string PMHLStyle             = "Solid";                        // Monthly Style
input color  PMHLColor             = clrBlue;                        // Monthly Color
input bool   ShowSD                = false;                          // Premium/Discount Zones
input color  PremiumColor          = clrRed;                         // Premium Zone
input color  EQZoneColor           = clrGray;                        // Equilibrium Zone
input color  DiscountColor         = clrGreen;                       // Discount Zone
input double K_Slope               = 1.0;                            // Slope multiplier
input string SlopeMethod           = "Atr";                          // Slope Method: Atr/Stdev/Linreg
input bool   ShowOnlyConfirmed     = true;                           // Show Only Confirmed Breakouts
double AMABuffer[];
int trend = 0, itrend = 0;
double top_y = 0, btm_y = 0;
int top_x = 0, btm_x = 0;
double itop_y = 0, ibtm_y = 0;
int itop_x = 0, ibtm_x = 0;
double trail_up = 0, trail_dn = 0;
int trail_up_x = 0, trail_dn_x = 0;
bool top_cross = true, btm_cross = true;
bool itop_cross = true, ibtm_cross = true;
double ama = 0;
double slope_ph = 0, slope_pl = 0;
double upper = 0, lower = 0;
int single_upper = 0, single_lower = 0;
double atr_value = 0;
double cmean_range = 0;
double iob_top[], iob_btm[];
datetime iob_left[];
int iob_type[];
int iob_size = 0;
double ob_top[], ob_btm[];
datetime ob_left[];
int ob_type[];
int ob_size = 0;
double eq_prev_top = 0, eq_prev_btm = 0;
int eq_top_x = 0, eq_btm_x = 0;
string bullish_fvg_names[], bearish_fvg_names[];
int bull_fvg_count = 0, bear_fvg_count = 0;
string structure_line_names[];
double structure_line_prices[];
int structure_line_count = 0;
string prefix = "RoyalPrince_";
int object_counter = 0;

//+------------------------------------------------------------------+
//| Refresh every minute                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
   string test_obj = "AutoRefresh";

   // Update dynamic elements
   CleanCrossedStructureLines();
   UpdateStructureLines();
   if(ShowIOB) UpdateOrderBlocks(true);
   if(ShowOB) UpdateOrderBlocks(false);
   if(ShowSD) UpdatePremiumDiscountZones();
   if(ShowPDHL || ShowPWHL || ShowPMHL) UpdateMTFHighLow();
   if(ShowHLSwings) UpdateHLSwings();
   UpdateDynamicTrendlines();

/*
   // Simulate timeframe switch to force refresh
   int current_tf = Period();
   int temp_tf = 0;
   switch(current_tf)
   {
      case PERIOD_M1:  temp_tf = PERIOD_M5; break;
      case PERIOD_M5:  temp_tf = PERIOD_M1; break;
      case PERIOD_M15: temp_tf = PERIOD_M5; break;
      case PERIOD_M30: temp_tf = PERIOD_M15; break;
      case PERIOD_H1:  temp_tf = PERIOD_M30; break;
      case PERIOD_H4:  temp_tf = PERIOD_H1; break;
      case PERIOD_D1:  temp_tf = PERIOD_H4; break;
      case PERIOD_W1:  temp_tf = PERIOD_D1; break;
      case PERIOD_MN1: temp_tf = PERIOD_W1; break;
      default: temp_tf = PERIOD_M1; break;
   }
   ChartSetSymbolPeriod(0, _Symbol, temp_tf);
   ChartSetSymbolPeriod(0, _Symbol, current_tf);
*/
   // Force redraw of chart and window
   ChartRedraw();
   WindowRedraw();

   // Optional: debug print
   Print("SMC indicator auto-refreshed at ", TimeToString(TimeCurrent(), TIME_SECONDS));
}

//+------------------------------------------------------------------+
//| Update order blocks' right edge                                  |
//+------------------------------------------------------------------+
void UpdateOrderBlocks(bool is_internal)
{
   int count = is_internal ? MathMin(IOBShowLast, iob_size) : MathMin(OBShowLast, ob_size);
   string pfx = is_internal ? "IOB_" : "OB_";
   datetime right_time = TimeCurrent() + PeriodSeconds() * 1; // Extend slightly into the future
   for(int i = 0; i < count; i++)
   {
      string box_name = prefix + pfx + IntegerToString(i);
      if(ObjectFind(0, box_name) >= 0)
      {
         ObjectSet(box_name, OBJPROP_TIME2, right_time);
      }
   }
}

//+------------------------------------------------------------------+
//| Update premium/discount zones' right edge                        |
//+------------------------------------------------------------------+
void UpdatePremiumDiscountZones()
{
   datetime end_time = TimeCurrent() + PeriodSeconds() * 20;
   string names[3] = { "Premium", "Equilibrium", "Discount" };
   for(int i = 0; i < 3; i++)
   {
      string name = prefix + names[i];
      if(ObjectFind(0, name) >= 0)
      {
         ObjectSet(name, OBJPROP_TIME2, end_time);
      }
   }
}

//+------------------------------------------------------------------+
//| Update MTF high/low lines' right edge                            |
//+------------------------------------------------------------------+
void UpdateMTFHighLow()
{
   datetime extend_time = TimeCurrent() + PeriodSeconds() * 20;
   string lines[6] = { "PDH", "PDL", "PWH", "PWL", "PMH", "PML" };
   for(int i = 0; i < 6; i++)
   {
      string line_name = prefix + lines[i];
      if(ObjectFind(0, line_name) >= 0)
      {
         ObjectSet(line_name, OBJPROP_TIME2, extend_time);
      }
   }
}

//+------------------------------------------------------------------+
//| Update strong/weak high/low labels' position                     |
//+------------------------------------------------------------------+
void UpdateHLSwings()
{
   datetime now = TimeCurrent();
   string hl_name = prefix + "StrongHigh";
   if(ObjectFind(0, hl_name) >= 0)
   {
      ObjectSet(hl_name, OBJPROP_TIME, now);
   }
   string ll_name = prefix + "StrongLow";
   if(ObjectFind(0, ll_name) >= 0)
   {
      ObjectSet(ll_name, OBJPROP_TIME, now);
   }
}

//+------------------------------------------------------------------+
//| Update dynamic trendlines' right edge                            |
//+------------------------------------------------------------------+
void UpdateDynamicTrendlines()
{
   datetime now = TimeCurrent();
   string upper_line = prefix + "UpperTrend";
   if(ObjectFind(0, upper_line) >= 0)
   {
      ObjectSet(upper_line, OBJPROP_TIME2, now);
   }
   string lower_line = prefix + "LowerTrend";
   if(ObjectFind(0, lower_line) >= 0)
   {
      ObjectSet(lower_line, OBJPROP_TIME2, now);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(RefreshEverySeconds); // Refresh every 60 seconds
   if (ShowAMA)
       {
         SetIndexBuffer(0, AMABuffer);
         SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, indicator_width1, AMAColor);
         SetIndexLabel(0, "AMA");
       }
   ArrayResize(iob_top, 100);
   ArrayResize(iob_btm, 100);
   ArrayResize(iob_left, 100);
   ArrayResize(iob_type, 100);
   ArrayResize(ob_top, 100);
   ArrayResize(ob_btm, 100);
   ArrayResize(ob_left, 100);
   ArrayResize(ob_type, 100);
   ArrayResize(bullish_fvg_names, 50);
   ArrayResize(bearish_fvg_names, 50);
   ArrayResize(structure_line_names, 100);
   ArrayResize(structure_line_prices, 100);
   IndicatorShortName("RoyalPrince SMC");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();   // Clean up timer when removed
   DeleteAllObjects();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteAllObjects()
  {
   int total = ObjectsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(i);
      if(StringFind(name, prefix) == 0)
        {
         ObjectDelete(name);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   if (ShowAMA) ArraySetAsSeries(AMABuffer, true);
   int limit;
   if(prev_calculated == 0)
     {
      limit = rates_total - 1;
      if(rates_total > 0)
        {
         trail_up = high[0];
         trail_dn = low[0];
         ama = close[0];
        }
     }
   else
     {
      limit = rates_total - prev_calculated;
     }
   if(rates_total > 200)
     {
      atr_value = iATR(NULL, 0, 200, 0);
     }
   double sum_range = 0;
   int count_bars = MathMin(rates_total, 500);
   for(int i = 0; i < count_bars; i++)
     {
      sum_range += high[i] - low[i];
     }
   if(count_bars > 0)
      cmean_range = sum_range / count_bars;
   for(int i = limit; i >= 0; i--)
     {
         if (ShowAMA) CalculateAMA(i, rates_total, high, low, close);
      DetectSwingPoints(i, rates_total, high, low);
      DetectStructureBreaks(i, open, close, high, low, time);
      UpdateTrailing(i, high, low);
      if(ShowFVG && i >= 2)
        {
         DetectFairValueGaps(i, high, low, close, time);
        }
     }
   static datetime last_bar_time = 0;
   bool is_new_bar = (Time[0] != last_bar_time);
   if(is_new_bar)
      last_bar_time = Time[0];
   if(is_new_bar)
      CleanFilledFVGs(high, low);
   CleanCrossedStructureLines();
   UpdateStructureLines();
   if(is_new_bar && rates_total > 0)
     {
      DrawGraphicalElements(rates_total, time, high, low, close);
      if(ShowEQ)
         DetectEqualHighsLows(rates_total, high, low, time);
      if(ShowPDHL || ShowPWHL || ShowPMHL)
         DrawMTFHighLow();
     }
   else
      if(rates_total > 0)
        {
         UpdateDynamicTrendlines(rates_total, time, high, low, close);
        }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateAMA(int shift, int rates_total, const double &high[], const double &low[], const double &close[])
  {
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   if(shift >= rates_total - SwingLength - 1)
     {
      AMABuffer[shift] = close[shift];
      return;
     }
   double highest_now = high[shift];
   double lowest_now = low[shift];
   double highest_prev = high[shift + 1];
   double lowest_prev = low[shift + 1];
   for(int j = 0; j <= SwingLength && shift + j < rates_total; j++)
     {
      if(high[shift + j] > highest_now)
         highest_now = high[shift + j];
      if(low[shift + j] < lowest_now)
         lowest_now = low[shift + j];
     }
   for(int j = 0; j <= SwingLength && shift + j + 1 < rates_total; j++)
     {
      if(high[shift + j + 1] > highest_prev)
         highest_prev = high[shift + j + 1];
      if(low[shift + j + 1] < lowest_prev)
         lowest_prev = low[shift + j + 1];
     }
   int hh = (highest_now > highest_prev) ? 1 : 0;
   int ll = (lowest_now < lowest_prev) ? 1 : 0;
   double tc_input = (hh > 0 || ll > 0) ? 1.0 : 0.0;
   static double tc_buffer[];
   static int tc_size = 0;
   if(tc_size == 0)
     {
      ArrayResize(tc_buffer, rates_total);
      tc_size = rates_total;
     }
   tc_buffer[shift] = tc_input;
   double tc_sum = 0;
   int count = 0;
   for(int j = 0; j < SwingLength && shift + j < rates_total; j++)
     {
      tc_sum += tc_buffer[shift + j];
      count++;
     }
   double tc_sma = (count > 0) ? (tc_sum / count) : 0;
   double tc = tc_sma * tc_sma;
   if (ShowAMA)
       {
         if(shift == rates_total - 1)
            AMABuffer[shift] = close[shift];
         else
            AMABuffer[shift] = AMABuffer[shift + 1] + tc * (close[shift] - AMABuffer[shift + 1]);
       }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DetectSwingPoints(int shift, int rates_total, const double &high[], const double &low[])
  {
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   if(shift >= SwingLength && shift < rates_total - SwingLength)
     {
      bool is_pivot_high = true;
      double center = high[shift];
      for(int j = 1; j <= SwingLength; j++)
        {
         if(high[shift - j] >= center || high[shift + j] >= center)
           {
            is_pivot_high = false;
            break;
           }
        }
      if(is_pivot_high)
        {
         top_cross = true;
         top_y = center;
         top_x = shift;
         trail_up = center;
         trail_up_x = shift;
         if(ShowSwings)
           {
            string label_text = (center > btm_y || btm_y == 0) ? "HH" : "LH";
            DrawSwingLabel(shift, center, label_text, false);
           }
        }
     }
   if(shift >= SwingLength && shift < rates_total - SwingLength)
     {
      bool is_pivot_low = true;
      double center = low[shift];
      for(int j = 1; j <= SwingLength; j++)
        {
         if(low[shift - j] <= center || low[shift + j] <= center)
           {
            is_pivot_low = false;
            break;
           }
        }
      if(is_pivot_low)
        {
         btm_cross = true;
         btm_y = center;
         btm_x = shift;
         trail_dn = center;
         trail_dn_x = shift;
         if(ShowSwings)
           {
            string label_text = (center < top_y || top_y == 0) ? "LL" : "HL";
            DrawSwingLabel(shift, center, label_text, true);
           }
        }
     }
   if(shift >= 5 && shift < rates_total - 5)
     {
      bool is_itop = true;
      double icenter = high[shift];
      for(int j = 1; j <= 5; j++)
        {
         if(high[shift - j] >= icenter || high[shift + j] >= icenter)
           {
            is_itop = false;
            break;
           }
        }
      if(is_itop)
        {
         itop_cross = true;
         itop_y = icenter;
         itop_x = shift;
        }
      bool is_ibtm = true;
      double ibcenter = low[shift];
      for(int j = 1; j <= 5; j++)
        {
         if(low[shift - j] <= ibcenter || low[shift + j] <= ibcenter)
           {
            is_ibtm = false;
            break;
           }
        }
      if(is_ibtm)
        {
         ibtm_cross = true;
         ibtm_y = ibcenter;
         ibtm_x = shift;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DetectStructureBreaks(int shift, const double &open[], const double &close[], const double &high[], const double &low[], const datetime &time[])
  {
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   int array_size = ArraySize(close);
   if(shift < 1 || shift + 1 >= array_size)
      return;
   if(close[shift] > itop_y && close[shift + 1] <= itop_y && itop_cross && top_y != itop_y)
     {
      bool bull_concordant = true;
      if(IFilterConfluence)
        {
         double close_curr = close[shift];
         double open_curr = open[shift];
         double body_top = MathMax(close_curr, open_curr);
         double body_btm = MathMin(close_curr, open_curr);
         bull_concordant = (high[shift] - body_top) > (body_btm - low[shift]);
        }
      if(bull_concordant)
        {
         bool is_choch = (itrend < 0);
         string label = is_choch ? "CHoCH" : "BOS";
         if(ShowInternals && ShouldShowInternalBull(is_choch))
           {
            DrawStructureLabel(itop_x, itop_y, label, SwingIBullColor, true, false, true);
           }
         itop_cross = false;
         itrend = 1;
         if(ShowIOB)
           {
            AddOrderBlock(true, false, itop_x, shift);
           }
        }
     }
   if(close[shift] > top_y && close[shift + 1] <= top_y && top_cross)
     {
      bool is_choch = (trend < 0);
      string label = is_choch ? "CHoCH" : "BOS";
      if(ShowStructure && ShouldShowSwingBull(is_choch))
        {
         DrawStructureLabel(top_x, top_y, label, SwingBullColor, false, false, false);
        }
      top_cross = false;
      trend = 1;
      if(ShowOB)
        {
         AddOrderBlock(false, false, top_x, shift);
        }
     }
   if(close[shift] < ibtm_y && close[shift + 1] >= ibtm_y && ibtm_cross && btm_y != ibtm_y)
     {
      bool bear_concordant = true;
      if(IFilterConfluence)
        {
         double close_curr = close[shift];
         double open_curr = open[shift];
         double body_top = MathMax(close_curr, open_curr);
         double body_btm = MathMin(close_curr, open_curr);
         bear_concordant = (high[shift] - body_top) < (body_btm - low[shift]);
        }
      if(bear_concordant)
        {
         bool is_choch = (itrend > 0);
         string label = is_choch ? "CHoCH" : "BOS";
         if(ShowInternals && ShouldShowInternalBear(is_choch))
           {
            DrawStructureLabel(ibtm_x, ibtm_y, label, SwingIBearColor, true, true, true);
           }
         ibtm_cross = false;
         itrend = -1;
         if(ShowIOB)
           {
            AddOrderBlock(true, true, ibtm_x, shift);
           }
        }
     }
   if(close[shift] < btm_y && close[shift + 1] >= btm_y && btm_cross)
     {
      bool is_choch = (trend > 0);
      string label = is_choch ? "CHoCH" : "BOS";
      if(ShowStructure && ShouldShowSwingBear(is_choch))
        {
         DrawStructureLabel(btm_x, btm_y, label, SwingBearColor, false, true, false);
        }
      btm_cross = false;
      trend = -1;
      if(ShowOB)
        {
         AddOrderBlock(false, true, btm_x, shift);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateTrailing(int shift, const double &high[], const double &low[])
  {
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   if(high[shift] > trail_up)
     {
      trail_up = high[shift];
      trail_up_x = shift;
     }
   if(low[shift] < trail_dn)
     {
      trail_dn = low[shift];
      trail_dn_x = shift;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShouldShowInternalBull(bool is_choch)
  {
   if(ShowIBull == "All")
      return true;
   if(ShowIBull == "BOS" && !is_choch)
      return true;
   if(ShowIBull == "CHoCH" && is_choch)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShouldShowInternalBear(bool is_choch)
  {
   if(ShowIBear == "All")
      return true;
   if(ShowIBear == "BOS" && !is_choch)
      return true;
   if(ShowIBear == "CHoCH" && is_choch)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShouldShowSwingBull(bool is_choch)
  {
   if(ShowBull == "All")
      return true;
   if(ShowBull == "BOS" && !is_choch)
      return true;
   if(ShowBull == "CHoCH" && is_choch)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShouldShowSwingBear(bool is_choch)
  {
   if(ShowBear == "All")
      return true;
   if(ShowBear == "BOS" && !is_choch)
      return true;
   if(ShowBear == "CHoCH" && is_choch)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawSwingLabel(int bar_shift, double price, string text, bool is_low)
  {
   string name = prefix + "Swing_" + IntegerToString(object_counter++);
   if(ObjectFind(name) >= 0)
      ObjectDelete(name);
   ObjectCreate(name, OBJ_TEXT, 0, Time[bar_shift], price);
   ObjectSetText(name, text, 8, "Arial", is_low ? SwingBullColor : SwingBearColor);
   ObjectSet(name, OBJPROP_BACK, false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawStructureLabel(int bar_shift, double price, string text, color clr, bool is_internal, bool is_down, bool use_internal_size)
  {
   datetime bar_time = Time[bar_shift];
   string unique_id = TimeToString(bar_time) + "_" + DoubleToString(price, Digits);
   string name = prefix + "Struct_" + unique_id;
   string line_name = prefix + "Line_" + unique_id;
   if(ObjectFind(line_name) >= 0)
      return;
   datetime end_time = Time[0];
   bool found_cross = false;
   for(int scan = bar_shift - 1; scan >= 0; scan--)
     {
      if(scan >= Bars - 1)
         continue;
      double close_prev = Close[scan + 1];
      double close_curr = Close[scan];
      if((close_prev < price && close_curr >= price) ||
         (close_prev > price && close_curr <= price))
        {
         end_time = Time[scan];
         found_cross = true;
         break;
        }
     }
   ObjectCreate(line_name, OBJ_TREND, 0, bar_time, price, end_time, price);
   ObjectSet(line_name, OBJPROP_COLOR, clr);
   ObjectSet(line_name, OBJPROP_STYLE, is_internal ? STYLE_DASH : STYLE_SOLID);
   ObjectSet(line_name, OBJPROP_WIDTH, 1);
   ObjectSet(line_name, OBJPROP_RAY, false);
   ObjectSet(line_name, OBJPROP_BACK, true);
   if(!found_cross && bar_shift < 50 && structure_line_count < ArraySize(structure_line_names))
     {
      structure_line_names[structure_line_count] = line_name;
      structure_line_prices[structure_line_count] = price;
      structure_line_count++;
     }
   ObjectCreate(name, OBJ_TEXT, 0, bar_time, price);
   ObjectSetText(name, text, use_internal_size ? 7 : 8, "Arial", clr);
   ObjectSet(name, OBJPROP_BACK, false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddOrderBlock(bool is_internal, bool is_bearish, int pivot_shift, int current_shift)
  {
   int ob_sz;
   if(is_internal)
      ob_sz = iob_size;
   else
      ob_sz = ob_size;
   double ob_top_val = 0, ob_btm_val = 99999999;
   datetime ob_time = 0;
   double threshold = (OBFilter == "Atr") ? atr_value : cmean_range;
   for(int i = pivot_shift; i >= current_shift; i--)
     {
      double candle_range = High[i] - Low[i];
      if(candle_range < threshold * 2)
        {
         if(is_bearish)
           {
            if(High[i] > ob_top_val || ob_top_val == 0)
              {
               ob_top_val = High[i];
               ob_btm_val = Low[i];
               ob_time = Time[i];
              }
           }
         else
           {
            if(Low[i] < ob_btm_val)
              {
               ob_btm_val = Low[i];
               ob_top_val = High[i];
               ob_time = Time[i];
              }
           }
        }
     }
   if(ob_time > 0 && ob_top_val > 0)
     {
      ob_sz++;
      if(is_internal)
        {
         if(ob_sz > ArraySize(iob_top))
           {
            ArrayResize(iob_top, ob_sz + 10);
            ArrayResize(iob_btm, ob_sz + 10);
            ArrayResize(iob_left, ob_sz + 10);
            ArrayResize(iob_type, ob_sz + 10);
           }
         for(int j = ob_sz - 1; j > 0; j--)
           {
            iob_top[j] = iob_top[j - 1];
            iob_btm[j] = iob_btm[j - 1];
            iob_left[j] = iob_left[j - 1];
            iob_type[j] = iob_type[j - 1];
           }
         iob_top[0] = ob_top_val;
         iob_btm[0] = ob_btm_val;
         iob_left[0] = ob_time;
         iob_type[0] = is_bearish ? -1 : 1;
         iob_size = ob_sz;
        }
      else
        {
         if(ob_sz > ArraySize(ob_top))
           {
            ArrayResize(ob_top, ob_sz + 10);
            ArrayResize(ob_btm, ob_sz + 10);
            ArrayResize(ob_left, ob_sz + 10);
            ArrayResize(ob_type, ob_sz + 10);
           }
         for(int j = ob_sz - 1; j > 0; j--)
           {
            ob_top[j] = ob_top[j - 1];
            ob_btm[j] = ob_btm[j - 1];
            ob_left[j] = ob_left[j - 1];
            ob_type[j] = ob_type[j - 1];
           }
         ob_top[0] = ob_top_val;
         ob_btm[0] = ob_btm_val;
         ob_left[0] = ob_time;
         ob_type[0] = is_bearish ? -1 : 1;
         ob_size = ob_sz;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawGraphicalElements(int rates_total, const datetime &time[], const double &high[], const double &low[], const double &close[])
  {
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   CleanOldOrderBlocks();
   if(ShowIOB)
      DrawOrderBlocks(true, rates_total, time);
   if(ShowOB)
      DrawOrderBlocks(false, rates_total, time);
   if(ShowHLSwings)
     {
      string hl_name = prefix + "StrongHigh";
      if(ObjectFind(hl_name) >= 0)
         ObjectDelete(hl_name);
      ObjectCreate(hl_name, OBJ_TEXT, 0, time[0], trail_up);
      ObjectSetText(hl_name, (trend < 0 ? "Strong High" : "Weak High"), 8, "Arial", SwingBearColor);
      string ll_name = prefix + "StrongLow";
      if(ObjectFind(ll_name) >= 0)
         ObjectDelete(ll_name);
      ObjectCreate(ll_name, OBJ_TEXT, 0, time[0], trail_dn);
      ObjectSetText(ll_name, (trend > 0 ? "Strong Low" : "Weak Low"), 8, "Arial", SwingBullColor);
     }
   if(ShowSD)
     {
      DrawPremiumDiscountZones(time, rates_total);
     }
   UpdateDynamicTrendlines(rates_total, time, high, low, close);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanOldOrderBlocks()
  {
   for(int i = iob_size - 1; i >= 0; i--)
     {
      bool should_delete = false;
      if(iob_type[i] == 1)
        {
         if(Close[0] < iob_btm[i])
            should_delete = true;
        }
      else
        {
         if(Close[0] > iob_top[i])
            should_delete = true;
        }
      if(should_delete)
        {
         for(int j = i; j < iob_size - 1; j++)
           {
            iob_top[j] = iob_top[j + 1];
            iob_btm[j] = iob_btm[j + 1];
            iob_left[j] = iob_left[j + 1];
            iob_type[j] = iob_type[j + 1];
           }
         iob_size--;
        }
     }
   for(int i = ob_size - 1; i >= 0; i--)
     {
      bool should_delete = false;
      if(ob_type[i] == 1)
        {
         if(Close[0] < ob_btm[i])
            should_delete = true;
        }
      else
        {
         if(Close[0] > ob_top[i])
            should_delete = true;
        }
      if(should_delete)
        {
         for(int j = i; j < ob_size - 1; j++)
           {
            ob_top[j] = ob_top[j + 1];
            ob_btm[j] = ob_btm[j + 1];
            ob_left[j] = ob_left[j + 1];
            ob_type[j] = ob_type[j + 1];
           }
         ob_size--;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawOrderBlocks(bool is_internal, int rates_total, const datetime &time[])
  {
   int ob_sz;
   int show_last;
   string prefix_name;
   if(is_internal)
     {
      ob_sz = iob_size;
      show_last = IOBShowLast;
      prefix_name = "IOB_";
     }
   else
     {
      ob_sz = ob_size;
      show_last = OBShowLast;
      prefix_name = "OB_";
     }
   int count = MathMin(show_last, ob_sz);
   datetime right_time = Time[0] + PeriodSeconds() * 1; // Initial extend
   for(int i = 0; i < count; i++)
     {
      string box_name = prefix + prefix_name + IntegerToString(i);
      if(ObjectFind(box_name) >= 0)
         ObjectDelete(box_name);
      color box_color;
      double top_val, btm_val;
      datetime left_val;
      int type_val;
      if(is_internal)
        {
         top_val = iob_top[i];
         btm_val = iob_btm[i];
         left_val = iob_left[i];
         type_val = iob_type[i];
         box_color = (type_val == 1) ? IBullOBColor : IBearOBColor;
        }
      else
        {
         top_val = ob_top[i];
         btm_val = ob_btm[i];
         left_val = ob_left[i];
         type_val = ob_type[i];
         box_color = (type_val == 1) ? BullOBColor : BearOBColor;
        }
      ObjectCreate(box_name, OBJ_RECTANGLE, 0, left_val, top_val, right_time, btm_val);
      ObjectSet(box_name, OBJPROP_COLOR, box_color);
      ObjectSet(box_name, OBJPROP_BACK, true);
      ObjectSet(box_name, OBJPROP_FILL, true);
      ObjectSet(box_name, OBJPROP_WIDTH, 1);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawPremiumDiscountZones(const datetime &time[], int rates_total)
  {
   double avg = (trail_up + trail_dn) / 2;
   datetime start_time = time[MathMax(top_x, btm_x)];
   datetime end_time = time[0] + PeriodSeconds() * 20;
   string premium_name = prefix + "Premium";
   if(ObjectFind(premium_name) >= 0)
      ObjectDelete(premium_name);
   ObjectCreate(premium_name, OBJ_RECTANGLE, 0, start_time, trail_up, end_time, 0.95 * trail_up + 0.05 * trail_dn);
   ObjectSet(premium_name, OBJPROP_COLOR, PremiumColor);
   ObjectSet(premium_name, OBJPROP_BACK, true);
   ObjectSet(premium_name, OBJPROP_FILL, true);
   string eq_name = prefix + "Equilibrium";
   if(ObjectFind(eq_name) >= 0)
      ObjectDelete(eq_name);
   ObjectCreate(eq_name, OBJ_RECTANGLE, 0, start_time, 0.525 * trail_up + 0.475 * trail_dn, end_time, 0.525 * trail_dn + 0.475 * trail_up);
   ObjectSet(eq_name, OBJPROP_COLOR, EQZoneColor);
   ObjectSet(eq_name, OBJPROP_BACK, true);
   ObjectSet(eq_name, OBJPROP_FILL, true);
   string discount_name = prefix + "Discount";
   if(ObjectFind(discount_name) >= 0)
      ObjectDelete(discount_name);
   ObjectCreate(discount_name, OBJ_RECTANGLE, 0, start_time, 0.95 * trail_dn + 0.05 * trail_up, end_time, trail_dn);
   ObjectSet(discount_name, OBJPROP_COLOR, DiscountColor);
   ObjectSet(discount_name, OBJPROP_BACK, true);
   ObjectSet(discount_name, OBJPROP_FILL, true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateDynamicTrendlines(int rates_total, const datetime &time[], const double &high[], const double &low[], const double &close[])
  {
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   double slope = 0;
   if(SlopeMethod == "Atr")
      slope = atr_value / SwingLength * K_Slope;
   else
      if(SlopeMethod == "Stdev")
        {
         double sum = 0;
         for(int i = 0; i < SwingLength && i < ArraySize(close); i++)
            sum += close[i];
         double mean = sum / SwingLength;
         double sum_sq = 0;
         for(int i = 0; i < SwingLength && i < ArraySize(close); i++)
            sum_sq += MathPow(close[i] - mean, 2);
         double stdev = MathSqrt(sum_sq / SwingLength);
         slope = stdev / SwingLength * K_Slope;
        }
   string upper_line = prefix + "UpperTrend";
   string lower_line = prefix + "LowerTrend";
   if(top_y > 0 && top_x < rates_total)
     {
      double bars_diff = top_x - 0;
      upper = top_y - slope * bars_diff;
      if(ObjectFind(upper_line) >= 0)
        {
         ObjectMove(upper_line, 0, time[top_x], top_y);
         ObjectMove(upper_line, 1, time[0], upper);
        }
      else
        {
         ObjectCreate(upper_line, OBJ_TREND, 0, time[top_x], top_y, time[0], upper);
         ObjectSet(upper_line, OBJPROP_COLOR, clrGreen);
         ObjectSet(upper_line, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(upper_line, OBJPROP_RAY, true);
         ObjectSet(upper_line, OBJPROP_WIDTH, 1);
        }
      if(close[0] > upper && close[1] <= upper)
        {
         string breakout_label = prefix + "UpperBreak_" + TimeToString(time[0]);
         if(ObjectFind(breakout_label) < 0)
           {
            ObjectCreate(breakout_label, OBJ_TEXT, 0, time[0], low[0]);
            ObjectSetText(breakout_label, "B", 8, "Arial", clrGreen);
           }
        }
     }
   if(btm_y > 0 && btm_x < rates_total)
     {
      double bars_diff = btm_x - 0;
      lower = btm_y + slope * bars_diff;
      if(ObjectFind(lower_line) >= 0)
        {
         ObjectMove(lower_line, 0, time[btm_x], btm_y);
         ObjectMove(lower_line, 1, time[0], lower);
        }
      else
        {
         ObjectCreate(lower_line, OBJ_TREND, 0, time[btm_x], btm_y, time[0], lower);
         ObjectSet(lower_line, OBJPROP_COLOR, clrRed);
         ObjectSet(lower_line, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(lower_line, OBJPROP_RAY, true);
         ObjectSet(lower_line, OBJPROP_WIDTH, 1);
        }
      if(close[0] < lower && close[1] >= lower)
        {
         string breakout_label = prefix + "LowerBreak_" + TimeToString(time[0]);
         if(ObjectFind(breakout_label) < 0)
           {
            ObjectCreate(breakout_label, OBJ_TEXT, 0, time[0], high[0]);
            ObjectSetText(breakout_label, "B", 8, "Arial", clrRed);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DetectEqualHighsLows(int rates_total, const double &high[], const double &low[], const datetime &time[])
  {
   if(!ShowEQ)
      return;
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   for(int i = EQLen; i < rates_total - EQLen; i++)
     {
      bool is_pivot = true;
      for(int j = 1; j <= EQLen; j++)
        {
         if(high[i - j] >= high[i] || high[i + j] >= high[i])
           {
            is_pivot = false;
            break;
           }
        }
      if(is_pivot && eq_prev_top > 0)
        {
         double max_val = MathMax(high[i], eq_prev_top);
         double min_val = MathMin(high[i], eq_prev_top);
         if(max_val < min_val + atr_value * EQThreshold)
           {
            string eqh_line = prefix + "EQH_" + IntegerToString(object_counter++);
            ObjectCreate(eqh_line, OBJ_TREND, 0, time[eq_top_x], eq_prev_top, time[i], high[i]);
            ObjectSet(eqh_line, OBJPROP_COLOR, SwingBearColor);
            ObjectSet(eqh_line, OBJPROP_STYLE, STYLE_DOT);
            ObjectSet(eqh_line, OBJPROP_RAY, false);
            ObjectSet(eqh_line, OBJPROP_BACK, true);
            string eqh_label = prefix + "EQH_Lbl_" + IntegerToString(object_counter++);
            int mid_x = (eq_top_x + i) / 2;
            ObjectCreate(eqh_label, OBJ_TEXT, 0, time[mid_x], high[i]);
            ObjectSetText(eqh_label, "EQH", 7, "Arial", SwingBearColor);
           }
        }
      if(is_pivot)
        {
         eq_prev_top = high[i];
         eq_top_x = i;
        }
     }
   for(int i = EQLen; i < rates_total - EQLen; i++)
     {
      bool is_pivot = true;
      for(int j = 1; j <= EQLen; j++)
        {
         if(low[i - j] <= low[i] || low[i + j] <= low[i])
           {
            is_pivot = false;
            break;
           }
        }
      if(is_pivot && eq_prev_btm > 0)
        {
         double max_val = MathMax(low[i], eq_prev_btm);
         double min_val = MathMin(low[i], eq_prev_btm);
         if(min_val > max_val - atr_value * EQThreshold)
           {
            string eql_line = prefix + "EQL_" + IntegerToString(object_counter++);
            ObjectCreate(eql_line, OBJ_TREND, 0, time[eq_btm_x], eq_prev_btm, time[i], low[i]);
            ObjectSet(eql_line, OBJPROP_COLOR, SwingBullColor);
            ObjectSet(eql_line, OBJPROP_STYLE, STYLE_DOT);
            ObjectSet(eql_line, OBJPROP_RAY, false);
            ObjectSet(eql_line, OBJPROP_BACK, true);
            string eql_label = prefix + "EQL_Lbl_" + IntegerToString(object_counter++);
            int mid_x = (eq_btm_x + i) / 2;
            ObjectCreate(eql_label, OBJ_TEXT, 0, time[mid_x], low[i]);
            ObjectSetText(eql_label, "EQL", 7, "Arial", SwingBullColor);
           }
        }
      if(is_pivot)
        {
         eq_prev_btm = low[i];
         eq_btm_x = i;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DetectFairValueGaps(int shift, const double &high[], const double &low[], const double &close[], const datetime &time[])
  {
   if(!ShowFVG)
      return;
   if(shift < 2)
      return;
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   double threshold = 0;
   if(FVGAuto)
     {
      double sum_delta = 0;
      int count = 0;
      for(int i = 1; i < MathMin(500, Bars); i++)
        {
         double delta_per = MathAbs((Close[i] - Open[i]) / Open[i] * 100);
         sum_delta += delta_per;
         count++;
        }
      if(count > 0)
         threshold = (sum_delta / count) * 2;
     }
   if(low[shift] > high[shift + 2] && close[shift + 1] > high[shift + 2])
     {
      double delta_per = (close[shift + 1] - Open[shift + 1]) / Open[shift + 1] * 100;
      if(!FVGAuto || delta_per > threshold)
        {
         string fvg_name = prefix + "BFVG_" + IntegerToString(object_counter++);
         datetime end_time = time[shift] + PeriodSeconds() * FVGExtend;
         double gap_mid = (low[shift] + high[shift + 2]) / 2;
         ObjectCreate(fvg_name + "_up", OBJ_RECTANGLE, 0, time[shift + 1], low[shift], end_time, gap_mid);
         ObjectSet(fvg_name + "_up", OBJPROP_COLOR, BullFVGColor);
         ObjectSet(fvg_name + "_up", OBJPROP_BACK, true);
         ObjectSet(fvg_name + "_up", OBJPROP_FILL, true);
         ObjectCreate(fvg_name + "_dn", OBJ_RECTANGLE, 0, time[shift + 1], gap_mid, end_time, high[shift + 2]);
         ObjectSet(fvg_name + "_dn", OBJPROP_COLOR, BullFVGColor);
         ObjectSet(fvg_name + "_dn", OBJPROP_BACK, true);
         ObjectSet(fvg_name + "_dn", OBJPROP_FILL, true);
         if(bull_fvg_count < ArraySize(bullish_fvg_names))
           {
            bullish_fvg_names[bull_fvg_count] = fvg_name;
            bull_fvg_count++;
           }
        }
     }
   if(high[shift] < low[shift + 2] && close[shift + 1] < low[shift + 2])
     {
      double delta_per = MathAbs((close[shift + 1] - Open[shift + 1]) / Open[shift + 1] * 100);
      if(!FVGAuto || delta_per > threshold)
        {
         string fvg_name = prefix + "SFVG_" + IntegerToString(object_counter++);
         datetime end_time = time[shift] + PeriodSeconds() * FVGExtend;
         double gap_mid = (high[shift] + low[shift + 2]) / 2;
         ObjectCreate(fvg_name + "_up", OBJ_RECTANGLE, 0, time[shift + 1], low[shift + 2], end_time, gap_mid);
         ObjectSet(fvg_name + "_up", OBJPROP_COLOR, BearFVGColor);
         ObjectSet(fvg_name + "_up", OBJPROP_BACK, true);
         ObjectSet(fvg_name + "_up", OBJPROP_FILL, true);
         ObjectCreate(fvg_name + "_dn", OBJ_RECTANGLE, 0, time[shift + 1], gap_mid, end_time, high[shift]);
         ObjectSet(fvg_name + "_dn", OBJPROP_COLOR, BearFVGColor);
         ObjectSet(fvg_name + "_dn", OBJPROP_BACK, true);
         ObjectSet(fvg_name + "_dn", OBJPROP_FILL, true);
         if(bear_fvg_count < ArraySize(bearish_fvg_names))
           {
            bearish_fvg_names[bear_fvg_count] = fvg_name;
            bear_fvg_count++;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanFilledFVGs(const double &high[], const double &low[])
  {
   if(!ShowFVG)
      return;
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   for(int i = bull_fvg_count - 1; i >= 0; i--)
     {
      string fvg_up = bullish_fvg_names[i] + "_up";
      string fvg_dn = bullish_fvg_names[i] + "_dn";
      if(ObjectFind(fvg_dn) >= 0)
        {
         double bottom = ObjectGet(fvg_dn, OBJPROP_PRICE2);
         if(low[0] < bottom)
           {
            ObjectDelete(fvg_up);
            ObjectDelete(fvg_dn);
            for(int j = i; j < bull_fvg_count - 1; j++)
              {
               bullish_fvg_names[j] = bullish_fvg_names[j + 1];
              }
            bull_fvg_count--;
           }
        }
     }
   for(int i = bear_fvg_count - 1; i >= 0; i--)
     {
      string fvg_up = bearish_fvg_names[i] + "_up";
      string fvg_dn = bearish_fvg_names[i] + "_dn";
      if(ObjectFind(fvg_up) >= 0)
        {
         double top = ObjectGet(fvg_up, OBJPROP_PRICE1);
         if(high[0] > top)
           {
            ObjectDelete(fvg_up);
            ObjectDelete(fvg_dn);
            for(int j = i; j < bear_fvg_count - 1; j++)
              {
               bearish_fvg_names[j] = bearish_fvg_names[j + 1];
              }
            bear_fvg_count--;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawMTFHighLow()
  {
   datetime current_time = Time[0];
   datetime extend_time = current_time + PeriodSeconds() * 20;
   if(ShowPDHL)
     {
      double pdh = iHigh(NULL, PERIOD_D1, 1);
      double pdl = iLow(NULL, PERIOD_D1, 1);
      datetime pdh_time = iTime(NULL, PERIOD_D1, 1);
      string pdh_line = prefix + "PDH";
      if(ObjectFind(pdh_line) >= 0)
         ObjectDelete(pdh_line);
      ObjectCreate(pdh_line, OBJ_TREND, 0, pdh_time, pdh, extend_time, pdh);
      ObjectSet(pdh_line, OBJPROP_COLOR, PDHLColor);
      ObjectSet(pdh_line, OBJPROP_STYLE, GetLineStyle(PDHLStyle));
      ObjectSet(pdh_line, OBJPROP_RAY, false);
      ObjectSet(pdh_line, OBJPROP_BACK, true);
      string pdh_label = prefix + "PDH_Lbl";
      if(ObjectFind(pdh_label) >= 0)
         ObjectDelete(pdh_label);
      ObjectCreate(pdh_label, OBJ_TEXT, 0, extend_time, pdh);
      ObjectSetText(pdh_label, "PDH", 8, "Arial", PDHLColor);
      string pdl_line = prefix + "PDL";
      if(ObjectFind(pdl_line) >= 0)
         ObjectDelete(pdl_line);
      ObjectCreate(pdl_line, OBJ_TREND, 0, pdh_time, pdl, extend_time, pdl);
      ObjectSet(pdl_line, OBJPROP_COLOR, PDHLColor);
      ObjectSet(pdl_line, OBJPROP_STYLE, GetLineStyle(PDHLStyle));
      ObjectSet(pdl_line, OBJPROP_RAY, false);
      ObjectSet(pdl_line, OBJPROP_BACK, true);
      string pdl_label = prefix + "PDL_Lbl";
      if(ObjectFind(pdl_label) >= 0)
         ObjectDelete(pdl_label);
      ObjectCreate(pdl_label, OBJ_TEXT, 0, extend_time, pdl);
      ObjectSetText(pdl_label, "PDL", 8, "Arial", PDHLColor);
     }
   if(ShowPWHL)
     {
      double pwh = iHigh(NULL, PERIOD_W1, 1);
      double pwl = iLow(NULL, PERIOD_W1, 1);
      datetime pwh_time = iTime(NULL, PERIOD_W1, 1);
      string pwh_line = prefix + "PWH";
      if(ObjectFind(pwh_line) >= 0)
         ObjectDelete(pwh_line);
      ObjectCreate(pwh_line, OBJ_TREND, 0, pwh_time, pwh, extend_time, pwh);
      ObjectSet(pwh_line, OBJPROP_COLOR, PWHLColor);
      ObjectSet(pwh_line, OBJPROP_STYLE, GetLineStyle(PWHLStyle));
      ObjectSet(pwh_line, OBJPROP_RAY, false);
      ObjectSet(pwh_line, OBJPROP_BACK, true);
      string pwh_label = prefix + "PWH_Lbl";
      if(ObjectFind(pwh_label) >= 0)
         ObjectDelete(pwh_label);
      ObjectCreate(pwh_label, OBJ_TEXT, 0, extend_time, pwh);
      ObjectSetText(pwh_label, "PWH", 8, "Arial", PWHLColor);
      string pwl_line = prefix + "PWL";
      if(ObjectFind(pwl_line) >= 0)
         ObjectDelete(pwl_line);
      ObjectCreate(pwl_line, OBJ_TREND, 0, pwh_time, pwl, extend_time, pwl);
      ObjectSet(pwl_line, OBJPROP_COLOR, PWHLColor);
      ObjectSet(pwl_line, OBJPROP_STYLE, GetLineStyle(PWHLStyle));
      ObjectSet(pwl_line, OBJPROP_RAY, false);
      ObjectSet(pwl_line, OBJPROP_BACK, true);
      string pwl_label = prefix + "PWL_Lbl";
      if(ObjectFind(pwl_label) >= 0)
         ObjectDelete(pwl_label);
      ObjectCreate(pwl_label, OBJ_TEXT, 0, extend_time, pwl);
      ObjectSetText(pwl_label, "PWL", 8, "Arial", PWHLColor);
     }
   if(ShowPMHL)
     {
      double pmh = iHigh(NULL, PERIOD_MN1, 1);
      double pml = iLow(NULL, PERIOD_MN1, 1);
      datetime pmh_time = iTime(NULL, PERIOD_MN1, 1);
      string pmh_line = prefix + "PMH";
      if(ObjectFind(pmh_line) >= 0)
         ObjectDelete(pmh_line);
      ObjectCreate(pmh_line, OBJ_TREND, 0, pmh_time, pmh, extend_time, pmh);
      ObjectSet(pmh_line, OBJPROP_COLOR, PMHLColor);
      ObjectSet(pmh_line, OBJPROP_STYLE, GetLineStyle(PMHLStyle));
      ObjectSet(pmh_line, OBJPROP_RAY, false);
      ObjectSet(pmh_line, OBJPROP_BACK, true);
      string pmh_label = prefix + "PMH_Lbl";
      if(ObjectFind(pmh_label) >= 0)
         ObjectDelete(pmh_label);
      ObjectCreate(pmh_label, OBJ_TEXT, 0, extend_time, pmh);
      ObjectSetText(pmh_label, "PMH", 8, "Arial", PMHLColor);
      string pml_line = prefix + "PML";
      if(ObjectFind(pml_line) >= 0)
         ObjectDelete(pml_line);
      ObjectCreate(pml_line, OBJ_TREND, 0, pmh_time, pml, extend_time, pml);
      ObjectSet(pml_line, OBJPROP_COLOR, PMHLColor);
      ObjectSet(pml_line, OBJPROP_STYLE, GetLineStyle(PMHLStyle));
      ObjectSet(pml_line, OBJPROP_RAY, false);
      ObjectSet(pml_line, OBJPROP_BACK, true);
      string pml_label = prefix + "PML_Lbl";
      if(ObjectFind(pml_label) >= 0)
         ObjectDelete(pml_label);
      ObjectCreate(pml_label, OBJ_TEXT, 0, extend_time, pml);
      ObjectSetText(pml_label, "PML", 8, "Arial", PMHLColor);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLineStyle(string style)
  {
   if(style == "Solid")
      return STYLE_SOLID;
   if(style == "Dash")
      return STYLE_DASH;
   if(style == "Dot")
      return STYLE_DOT;
   return STYLE_SOLID;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateStructureLines()
  {
   datetime current_time = TimeCurrent();
   for(int i = 0; i < structure_line_count; i++)
     {
      string line_name = structure_line_names[i];
      double line_price = structure_line_prices[i];
      if(ObjectFind(0, line_name) >= 0)
        {
         ObjectSetInteger(0, line_name, OBJPROP_TIME2, current_time);
         ObjectSetDouble(0, line_name, OBJPROP_PRICE2, line_price);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanCrossedStructureLines()
  {
   if(structure_line_count == 0)
      return;
   if(Bars < 2)
      return;
   for(int i = structure_line_count - 1; i >= 0; i--)
     {
      string line_name = structure_line_names[i];
      double line_price = structure_line_prices[i];
      if(ObjectFind(line_name) < 0)
        {
         RemoveStructureLineFromArray(i);
         continue;
        }
      double close_prev = Close[1];
      double close_curr = Close[0];
      bool crossed = false;
      if(close_prev < line_price && close_curr >= line_price)
         crossed = true;
      if(close_prev > line_price && close_curr <= line_price)
         crossed = true;
      if(crossed)
        {
         ObjectSet(line_name, OBJPROP_TIME2, Time[0]);
         ObjectSet(line_name, OBJPROP_PRICE2, line_price);
         RemoveStructureLineFromArray(i);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RemoveStructureLineFromArray(int index)
  {
   for(int j = index; j < structure_line_count - 1; j++)
     {
      structure_line_names[j] = structure_line_names[j + 1];
      structure_line_prices[j] = structure_line_prices[j + 1];
     }
   structure_line_count--;
  }

/*
── Project ─────────────────────────────────────────────────────────────────────

Name:        RoyalPrince_SMC
Version:     1.00
Date:        2025
Repository:  Available @ https://fxcodebase.com/code/viewtopic.php?f=38&t=76432&p=161150#p161150
License:     GNU

── Author ──────────────────────────────────────────────────────────────────────

Developed by: Mario Jemic
Email:        mario.jemic@gmail.com
Website:      https://mario-jemic.com

── Support & Donations ─────────────────────────────────────────────────────────

PayPal:      https://goo.gl/9Rj74e
Patreon:     https://tiny.cc/1ybwxz
BuyMeACoffee:https://tiny.cc/bj7vzj

Crypto:
 BTC : 16F5k43RXibTmna4np8bPVgmXM1CzjXFJJ
 SOL : 3nh5rpUKopcYLNU4zGCdUFAkM3iRQq8VVUmuzVG6VDf2
 ETH/BNB/USDT/XRP (ERC20/BEP20): 0xe53aab6bc468a963a02d1319660ee60cf80fc8e7

── Copyright ───────────────────────────────────────────────────────────────────

© 2025 Gehtsoft USA LLC — https://fxcodebase.com

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 <https://www.gnu.org/licenses/>.
*/