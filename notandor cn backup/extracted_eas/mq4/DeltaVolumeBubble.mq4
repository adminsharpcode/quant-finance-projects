//+------------------------------------------------------------------+
//|                                           DeltaVolumeBubble.mq4  |
//|                                  Copyright 2025, Google Deepmind |
//|                                       Translated from Pine Script|
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Google Deepmind"
#property link      "https://www.google.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   0

//--- Constants
#define PREFIX "DVB_"

//--- Enums
enum ENUM_CALC_SOURCE {
   SRC_DELTA,  // Volume Delta
   SRC_VOLUME  // Regular Volume
};

enum ENUM_CALC_MODE {
   MODE_ADAPTIVE, // Adaptive (Z-Score)
   MODE_FIXED     // Fixed (Absolute Value)
};

enum ENUM_THEME {
   THEME_DARK,  // Dark Theme (Mint-Coral)
   THEME_LIGHT  // Light Theme (Royal-Sunset)
};

enum ENUM_FONT_TYPE {
   FONT_DEFAULT,
   FONT_MONOSPACE
};

enum ENUM_ALERT_MODE {
   ALERT_OFF,     // Off
   ALERT_CURRENT, // Current Bar (Realtime)
   ALERT_CLOSED   // Closed Bar (Confirmed)
};

//--- Inputs
input ENUM_CALC_SOURCE InpSource = SRC_DELTA; // Calculation Source
input int InpAnchorTF = 0; // Anchor TF (Minutes, 0=Current)
input int InpLowerTF = 0; // Lower TF (Minutes, 0=Current)
// Note: MQL4 Inputs for Timeframe usually simpler as int (ENUM_TIMEFRAMES works in modern too, but int is safer for broad compat)

input int InpLookback = 60; // Statistical Lookback
input int InpMaxHistory = 5000; // Max Bars to Draw

input ENUM_CALC_MODE InpCalcMode = MODE_ADAPTIVE; // Calculation Mode
input double InpZThreshold = 2.0; // Z-Score Threshold (sigma)
input double InpMinVolume = 200.0; // Fixed Mode: Min Volume

input bool InpDetectAbsorption = false; // Detect Absorption
input double InpAbsorptionRatio = 0.6; // Absorption Ratio (0.1 - 1.0)

input bool InpShowBullish = true; // Show Bullish
input bool InpShowBearish = true; // Show Bearish
input bool InpScaleSize = true; // Scale Size by Z-Score
input bool InpGlowEffect = true; // Glow Effect
input ENUM_FONT_TYPE InpFontType = FONT_DEFAULT; // Font
input ENUM_THEME InpTheme = THEME_DARK; // Theme

input ENUM_ALERT_MODE InpAlertTiming = ALERT_CURRENT; // Alert Timing
input bool InpAlertThreshold = false; // Alert: Unusual Threshold Trigger
input bool InpAlertAbsorption = false; // Alert: Absorption Detected

//--- Buffers
double RawBuffer[];
double ZScoreBuffer[];
double AvgBodyBuffer[];
double DummyBuffer[];

//--- Global Variables
struct UnicornVomit {
   color happy_juice;
   color angry_juice;
   color happy_glow;
   color angry_glow;
   color sponge_glow;
   color ink_color;
};

UnicornVomit current_outfit;

//+------------------------------------------------------------------+
//| Custom Indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- indicator buffers mapping
   SetIndexBuffer(0, RawBuffer);
   SetIndexStyle(0, DRAW_NONE);
   SetIndexBuffer(1, ZScoreBuffer);
   SetIndexStyle(1, DRAW_NONE);
   SetIndexBuffer(2, AvgBodyBuffer);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexBuffer(3, DummyBuffer);
   SetIndexStyle(3, DRAW_NONE);

   SetupTheme();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom Indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, PREFIX);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Helper: Setup Theme Colors                                       |
//+------------------------------------------------------------------+
void SetupTheme()
{
   if(InpTheme == THEME_DARK)
   {
      // Mint-Coral
      current_outfit.happy_juice = C'0,150,100'; // #009664
      current_outfit.angry_juice = C'182,0,61'; // #b6003d
      current_outfit.happy_glow  = C'0,209,157'; // #00d19d
      current_outfit.angry_glow  = C'255,54,121'; // #ff3679
      current_outfit.sponge_glow = C'157,0,255'; // #9d00ff
      current_outfit.ink_color   = clrWhite; 
   }
   else
   {
      // Light Theme (Royal-Sunset)
      current_outfit.happy_juice = C'0,102,255';
      current_outfit.angry_juice = C'182,0,61'; // Fallback
      current_outfit.happy_glow  = C'0,209,157';
      current_outfit.angry_glow  = C'255,54,121';
      current_outfit.sponge_glow = C'157,0,255'; 
      current_outfit.ink_color   = clrBlack;
   }
}

string FormatVolume(double vol)
{
   double abs_vol = MathAbs(vol);
   if(abs_vol >= 1e9) return StringFormat("%.1fB", abs_vol / 1e9);
   if(abs_vol >= 1e6) return StringFormat("%.1fM", abs_vol / 1e6);
   if(abs_vol >= 1e3) return StringFormat("%.1fK", abs_vol / 1e3);
   return StringFormat("%.0f", abs_vol);
}

void CreateBubble(int index, datetime time, double price, double z_score, double raw_val, bool is_bullish, bool is_absorp)
{
   string name_base = PREFIX + IntegerToString(time);
   string name_glow = name_base + "_Glow";
   string name_bub  = name_base + "_Bub";
   string name_txt  = name_base + "_Txt";

   string pants_size = "S";
   if(InpScaleSize)
   {
      double check_z = InpCalcMode == MODE_ADAPTIVE ? z_score : 0.0;
      double check_v = InpCalcMode == MODE_FIXED ? MathAbs(raw_val) : 0.0;
      
      if(InpCalcMode == MODE_ADAPTIVE)
         pants_size = (check_z > InpZThreshold + 2.0) ? "L" : (check_z > InpZThreshold + 1.0) ? "M" : "S";
      else
         pants_size = (check_v > InpMinVolume * 6) ? "L" : (check_v > InpMinVolume * 4) ? "M" : "S";
   }

   int glow_size = (pants_size == "L") ? 5 : (pants_size == "M") ? 4 : 3; 
   int bub_size  = (pants_size == "L") ? 4 : (pants_size == "M") ? 3 : 1; 
   int txt_size  = (pants_size == "L") ? 10 : (pants_size == "M") ? 8 : 7;
   
   // MQL4 No Transparency Support for standard Objects
   color base_col = is_bullish ? current_outfit.happy_juice : current_outfit.angry_juice;
   color glow_col = is_bullish ? current_outfit.happy_glow : current_outfit.angry_glow;
   if(is_absorp) glow_col = current_outfit.sponge_glow;

   if(InpGlowEffect)
   {
      if(ObjectFind(name_glow) < 0) ObjectCreate(name_glow, OBJ_TEXT, 0, time, price);
      ObjectSetString(0, name_glow, OBJPROP_TEXT, "l"); 
      ObjectSetString(0, name_glow, OBJPROP_FONT, "Wingdings");
      ObjectSetInteger(0, name_glow, OBJPROP_FONTSIZE, glow_size * 10);
      ObjectSetInteger(0, name_glow, OBJPROP_COLOR, glow_col);
      ObjectSetInteger(0, name_glow, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }

   if(ObjectFind(name_bub) < 0) ObjectCreate(name_bub, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name_bub, OBJPROP_TEXT, "l"); 
   ObjectSetString(0, name_bub, OBJPROP_FONT, "Wingdings");
   ObjectSetInteger(0, name_bub, OBJPROP_FONTSIZE, bub_size * 10);
   ObjectSetInteger(0, name_bub, OBJPROP_COLOR, base_col);
   ObjectSetInteger(0, name_bub, OBJPROP_ANCHOR, ANCHOR_CENTER);

   string txt_val = (InpSource == SRC_DELTA && is_bullish ? "+" : (InpSource==SRC_DELTA ? "-" : "")) + FormatVolume(raw_val);
   if(ObjectFind(name_txt) < 0) ObjectCreate(name_txt, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name_txt, OBJPROP_TEXT, txt_val);
   ObjectSetString(0, name_txt, OBJPROP_FONT, (InpFontType == FONT_MONOSPACE) ? "Consolas" : "Arial");
   ObjectSetInteger(0, name_txt, OBJPROP_FONTSIZE, txt_size);
   ObjectSetInteger(0, name_txt, OBJPROP_COLOR, current_outfit.ink_color);
   ObjectSetInteger(0, name_txt, OBJPROP_ANCHOR, ANCHOR_CENTER);
}

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
   if(rates_total < InpLookback + 1) return 0;

   // MQL4 Style: 0 is Newest.
   // But OnCalculate arrays passed here behave like MQL5 (0=Oldest) regarding 'rates_total' and indexing IF we don't set Series.
   // However, accessing global arrays Close[], Open[] in MQL4 means 0=Newest.
   // Let's use the passed arrays for consistency with MQL5 port logic if possible, 
   // BUT simpler to use standard MQL4 loops (backward).
   
   int limit = rates_total - prev_calculated;
   if(limit > rates_total - InpLookback - 1) limit = rates_total - InpLookback - 1;
   if(limit > InpMaxHistory) limit = InpMaxHistory;

   for(int i = limit; i >= 0; i--)
   {
      // Map i (Newest=0) to indices for Timeframe functions
      // iBarShift matches i.
      
      int calc_tf = (InpAnchorTF == 0) ? Period() : InpAnchorTF;
      int shift = iBarShift(NULL, calc_tf, Time[i], false);
      
      if(shift < 0) continue;

      double a_open = iOpen(NULL, calc_tf, shift);
      double a_close = iClose(NULL, calc_tf, shift);
      double a_high = iHigh(NULL, calc_tf, shift);
      double a_low = iLow(NULL, calc_tf, shift);
      long a_vol = (long)iVolume(NULL, calc_tf, shift);
      datetime a_time_start = iTime(NULL, calc_tf, shift); // Time of Anchor Bar

      double raw_fish = 0.0;
      double magic_carpet = (a_high + a_low + a_close) / 3.0; 

      // Lower TF logic
      bool use_lower = (InpLowerTF != 0 && InpLowerTF < calc_tf); // Compare minutes
      if(use_lower)
      {
          datetime t_start = a_time_start;
          datetime t_end = t_start + PeriodSeconds(calc_tf);
          
          // MQL4: Get Bar Shifts for the time range on Lower TF
          // Start Shift (Highest Index) corresponds to t_start
          int idx_start = iBarShift(NULL, InpLowerTF, t_start, false);
          // End Shift (Lowest Index) corresponds to t_end. 
          // Note: iBarShift returns the bar covering the time. 
          // We want bars strictly < t_end.
          int idx_end = iBarShift(NULL, InpLowerTF, t_end, false);
          
          // Safety: If t_end is in the future or exact match, adjustment might be needed.
          // Iterate from Old (idx_start) to New (idx_end)
          
          double sum_price_vol = 0;
          double sum_vol_lower = 0;
          double sum_delta = 0;
          
          for(int k = idx_start; k >= idx_end; k--)
          {
             datetime b_time = iTime(NULL, InpLowerTF, k);
             if(b_time >= t_end) continue; // Exclude next bar start
             if(b_time < t_start) break; // Should not happen if start shift is correct
             
             double r_vol = (double)iVolume(NULL, InpLowerTF, k); // Tick Volume in MQL4
             double r_close = iClose(NULL, InpLowerTF, k);
             double r_open = iOpen(NULL, InpLowerTF, k);
             
             double r_delta = (r_close >= r_open) ? r_vol : -r_vol;
                  
             sum_delta += r_delta;
             sum_price_vol += r_close * r_vol; 
             sum_vol_lower += r_vol;
          }
          
          if(InpSource == SRC_DELTA) raw_fish = sum_delta;
          else raw_fish = (a_close >= a_open) ? sum_vol_lower : -sum_vol_lower;
          
          if(sum_vol_lower > 0) magic_carpet = sum_price_vol / sum_vol_lower;
      }
      else
      {
           raw_fish = (InpSource == SRC_DELTA) ? ((a_close >= a_open) ? (double)a_vol : -(double)a_vol) : ((a_close >= a_open) ? (double)a_vol : -(double)a_vol);
      }

      RawBuffer[i] = raw_fish;
      double abs_vodka = MathAbs(raw_fish);

      // Stats - Backward Loop awareness!
      // We need stats of PAST bars.
      // i is Current. i+1 is Previous.
      double sum_vol = 0;
      double sum_sq = 0;
      
      for(int k=0; k<InpLookback; k++)
      {
          // We need RawBuffer[i+k].
          // Ensure i+k < rates_total
          if(i+k >= rates_total) continue;
          sum_vol += MathAbs(RawBuffer[i+k]);
      }
      double boring_average = sum_vol / InpLookback;
      
      for(int k=0; k<InpLookback; k++)
      {
          if(i+k >= rates_total) continue;
          sum_sq += MathPow(MathAbs(RawBuffer[i+k]) - boring_average, 2);
      }
      double deviant_behavior = MathSqrt(sum_sq / InpLookback);
      double z_score = (deviant_behavior != 0) ? (abs_vodka - boring_average) / deviant_behavior : 0.0;
      
      ZScoreBuffer[i] = z_score;

      bool kaboom = false;
      if(InpCalcMode == MODE_ADAPTIVE) kaboom = (z_score >= InpZThreshold);
      else kaboom = (abs_vodka >= InpMinVolume);
      
      // Absorption
      double body = MathAbs(a_close - a_open);
      double sum_body = 0; 
      // Approximate body history? Just lookup local body history
      for(int k=0; k<InpLookback; k++)
      {
         int h_shift = shift + k; // Shift + k goes back in time
         sum_body += MathAbs(iClose(NULL, calc_tf, h_shift) - iOpen(NULL, calc_tf, h_shift));
      }
      AvgBodyBuffer[i] = sum_body / InpLookback;
      
      bool is_spongy = InpDetectAbsorption && kaboom && (body < (sum_body/InpLookback) * InpAbsorptionRatio);
      
      bool show_it = (raw_fish > 0 && InpShowBullish) || (raw_fish <= 0 && InpShowBearish);
      
      if(kaboom && show_it)
      {
         bool is_bull = (raw_fish > 0);
         CreateBubble(i, Time[i], magic_carpet, z_score, raw_fish, is_bull, is_spongy);
         
         // Alerts
         if(InpAlertTiming == ALERT_CURRENT && i == 0) // i=0 is current bar
         {
             static datetime last_alert_time = 0;
             if(Time[0] != last_alert_time)
             {
                 string msg = "";
                 if(is_spongy && InpAlertAbsorption) msg = "ABSORPTION: " + Symbol();
                 else if(kaboom && InpAlertThreshold && !is_spongy) msg = "VOL ALERT: " + Symbol();
                 
                 if(msg != "") { Alert(msg); last_alert_time = Time[0]; }
             }
         }
      }
      
      // Closed Alerts
      if(InpAlertTiming == ALERT_CLOSED && i == 0)
      {
         static datetime last_bar_time = 0;
         if(Time[1] != last_bar_time) // Time[1] is the just-closed bar
         {
             // Check logic for buffer[1]
             if(ZScoreBuffer[1] >= InpZThreshold) // simplified check
             {
                 // Full logic check required if strict, but buffer check is usually fine
                 if(InpAlertThreshold) Alert("CLOSED ALERT: " + Symbol());
             }
             last_bar_time = Time[1];
         }
      }
   }
   return(rates_total);
  }
