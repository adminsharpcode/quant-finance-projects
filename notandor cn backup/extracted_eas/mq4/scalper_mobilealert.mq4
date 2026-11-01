/*
   This is a modified version of superscalper05.ex4 that
   includes Push Notifications to iOS or Android devices.
   The original version was uploaded by user "Emad" on
   http://forex-strategies-revealed.com/scalping/superscalper
   Modification Author: Henry Latourrette
   E-mail : henry.latourrette@gmail.com
   October 24th, 2012
*/

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Yellow

extern int SignalPeriod = 28;
int gi_80 = 0;
extern int NR_SLIPE = 3;
int g_applied_price_88 = PRICE_CLOSE;
extern double FilterNumber = 3.0;
bool gi_100 = TRUE;
int gi_104 = 0;
extern int lineWidth = 3;
extern int barsToDrawLine = 10000;
extern bool skipSingleBarSignal = FALSE;
extern int aTake_Profit = 150;
extern int aStop_Loss = 150;
extern bool aAlerts = TRUE;
extern bool EmailOn = TRUE;
extern bool PushNotification = TRUE;
datetime g_time_136;
string gs_148;
string gs_156 = "fx_NR_Scalping";
double g_ibuf_164[];
double g_ibuf_168[];
double g_ibuf_172[];
double g_ibuf_176[];
int gi_180;
string gs_184;
int gi_unused_192 = 0;

string GetTimeFrameStr() {
   string l_timeframe_4;
   switch (Period()) {
   case PERIOD_M1:
      l_timeframe_4 = "M1";
      break;
   case PERIOD_M5:
      l_timeframe_4 = "M5";
      break;
   case PERIOD_M15:
      l_timeframe_4 = "M15";
      break;
   case PERIOD_M30:
      l_timeframe_4 = "M30";
      break;
   case PERIOD_H1:
      l_timeframe_4 = "H1";
      break;
   case PERIOD_H4:
      l_timeframe_4 = "H4";
      break;
   case PERIOD_D1:
      l_timeframe_4 = "D1";
      break;
   case PERIOD_W1:
      l_timeframe_4 = "W1";
      break;
   case PERIOD_MN1:
      l_timeframe_4 = "MN1";
      break;
   default:
      l_timeframe_4 = Period();
   }
   return (l_timeframe_4);
}

void DisplayAlert(string as_0, double ad_8, double ad_16, double ad_24) {
   string ls_32;
   string ls_40;
   string ls_48;
   string ls_56;
   if (Time[0] != g_time_136) {
      g_time_136 = Time[0];
      if (gs_148 != as_0) {
         gs_148 = as_0;
         if (ad_8 != 0.0) ls_48 = " @ Price " + DoubleToStr(ad_8, 4);
         else ls_48 = "";
         if (ad_16 != 0.0) ls_40 = ", TakeProfit   " + DoubleToStr(ad_16, 4);
         else ls_40 = "";
         if (ad_24 != 0.0) ls_32 = ", StopLoss   " + DoubleToStr(ad_24, 4);
         else ls_32 = "";
         ls_56 = gs_184 + "Scalping " + aRperiodf() + " Alert " + as_0 
            + "\n" 
            + as_0 + ls_48 + ls_40 + ls_32 
         + "\nDate & Time = " + TimeToStr(TimeCurrent(), TIME_DATE) + " " + TimeHour(TimeCurrent()) + ":" + TimeMinute(TimeCurrent()) + " ";
         Alert(ls_56, Symbol(), ", ", Period(), " minutes chart");
         PlaySound("alert.wav");
         if (EmailOn) SendMail(gs_184, ls_56);
         if (PushNotification) SendNotification(ls_56);
      }
   }
}

int init() {
   IndicatorBuffers(4);
   if (!SetIndexBuffer(0, g_ibuf_164) && !SetIndexBuffer(1, g_ibuf_168) && !SetIndexBuffer(2, g_ibuf_172) && !SetIndexBuffer(3, g_ibuf_176)) Print("cannot set indicator buffers!");
   if (gi_100) {
      SetIndexStyle(0, DRAW_ARROW, EMPTY, lineWidth - 3);
      SetIndexStyle(1, DRAW_ARROW, EMPTY, lineWidth - 3);
      SetIndexStyle(2, DRAW_ARROW, EMPTY, lineWidth - 3);
      SetIndexArrow(0, 159);
      SetIndexArrow(1, 159);
      SetIndexArrow(2, 159);
   } else {
      SetIndexStyle(0, DRAW_LINE);
      SetIndexStyle(1, DRAW_LINE);
      SetIndexStyle(2, DRAW_LINE);
   }
   gi_180 = SignalPeriod + MathFloor(MathSqrt(SignalPeriod));
   SetIndexDrawBegin(0, gi_180);
   SetIndexDrawBegin(1, gi_180);
   SetIndexDrawBegin(2, gi_180);
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS) + 1.0);
   IndicatorShortName("Scalping(" + SignalPeriod + ")");
   SetIndexLabel(0, "Scalping");
   gs_184 = Symbol() + " (" + GetTimeFrameStr() + "):  ";
   gs_148 = "";
   ArrayInitialize(g_ibuf_164, EMPTY_VALUE);
   ArrayInitialize(g_ibuf_172, EMPTY_VALUE);
   ArrayInitialize(g_ibuf_168, EMPTY_VALUE);
   return (0);
}

int deinit() {
   DelObj();
   return (0);
}

int start() {
   double l_ima_on_arr_20;
   int li_unused_28;
   int l_ind_counted_8 = IndicatorCounted();
   if (l_ind_counted_8 < 1) {
      for (int li_4 = 0; li_4 <= gi_180; li_4++) g_ibuf_176[Bars - li_4] = 0;
      for (li_4 = 0; li_4 <= SignalPeriod; li_4++) {
         g_ibuf_164[Bars - li_4] = EMPTY_VALUE;
         g_ibuf_168[Bars - li_4] = EMPTY_VALUE;
         g_ibuf_172[Bars - li_4] = EMPTY_VALUE;
      }
   }
   int li_0 = Bars - l_ind_counted_8;
   for (li_4 = 1; li_4 < li_0; li_4++) g_ibuf_176[li_4] = 2.0 * iMA(NULL, 0, MathFloor(SignalPeriod / FilterNumber), gi_80, NR_SLIPE, g_applied_price_88, li_4) - iMA(NULL, 0, SignalPeriod, gi_80, NR_SLIPE, g_applied_price_88, li_4);
   double l_ima_on_arr_12 = iMAOnArray(g_ibuf_176, 0, MathFloor(MathSqrt(SignalPeriod)), 0, NR_SLIPE, 1);
   for (li_4 = 2; li_4 < li_0 + 1; li_4++) {
      l_ima_on_arr_20 = iMAOnArray(g_ibuf_176, 0, MathFloor(MathSqrt(SignalPeriod)), 0, NR_SLIPE, li_4);
      li_unused_28 = 0;
      if (l_ima_on_arr_20 > l_ima_on_arr_12) {
         g_ibuf_172[li_4 - 1] = l_ima_on_arr_12 - gi_104 * Point;
         li_unused_28 = 1;
      } else {
         if (l_ima_on_arr_20 < l_ima_on_arr_12) {
            g_ibuf_164[li_4 - 1] = l_ima_on_arr_12 + gi_104 * Point;
            li_unused_28 = 2;
         } else {
            g_ibuf_164[li_4 - 1] = EMPTY_VALUE;
            g_ibuf_168[li_4 - 1] = l_ima_on_arr_12;
            g_ibuf_172[li_4 - 1] = EMPTY_VALUE;
            li_unused_28 = 3;
         }
      }
      if (l_ind_counted_8 > 0) {
      }
      l_ima_on_arr_12 = l_ima_on_arr_20;
   }
   if (li_0 > barsToDrawLine) li_0 = barsToDrawLine;
   for (li_4 = 2; li_4 <= li_0; li_4++) {
      if (g_ibuf_164[li_4 - 1] != EMPTY_VALUE) {
         if (g_ibuf_164[li_4] != EMPTY_VALUE) drawLineSegment(li_4 - 1, li_4, 1);
         else drawLineSegment(li_4 - 1, li_4, 10);
      }
      if (g_ibuf_172[li_4 - 1] != EMPTY_VALUE) {
         if (g_ibuf_172[li_4] != EMPTY_VALUE) drawLineSegment(li_4 - 1, li_4, -1);
         else drawLineSegment(li_4 - 1, li_4, -10);
      }
   }
   if (aAlerts) {
      if ((skipSingleBarSignal == FALSE && g_ibuf_172[1] != EMPTY_VALUE && g_ibuf_172[2] == EMPTY_VALUE) || (skipSingleBarSignal == TRUE && g_ibuf_172[1] != EMPTY_VALUE &&
         g_ibuf_172[2] != EMPTY_VALUE && g_ibuf_172[3] == EMPTY_VALUE)) DisplayAlert("Sell signal", Close[1], aGetTPs(), aGetSLs());
      if ((skipSingleBarSignal == FALSE && g_ibuf_164[1] != EMPTY_VALUE && g_ibuf_164[2] == EMPTY_VALUE) || (skipSingleBarSignal == TRUE && g_ibuf_164[1] != EMPTY_VALUE &&
         g_ibuf_164[2] != EMPTY_VALUE && g_ibuf_164[3] == EMPTY_VALUE)) DisplayAlert("Buy signal", Close[1], aGetTPl(), aGetSLl());
   }
   return (0);
}

double aGetTPs() {
   return (Bid - aTake_Profit * Point);
}

double aGetTPl() {
   return (Ask + aTake_Profit * Point);
}

double aGetSLs() {
   return (Bid + aStop_Loss * Point);
}

double aGetSLl() {
   return (Ask - aStop_Loss * Point);
}

int aRperiodf() {
   return (10000.0 * (SignalPeriod * Point));
}

void DelObj() {
   string l_name_0;
   int l_str_len_12;
   for (int li_8 = ObjectsTotal() - 1; li_8 >= 0; li_8--) {
      l_name_0 = ObjectName(li_8);
      l_str_len_12 = StringLen(gs_156);
      if (StringSubstr(l_name_0, 0, l_str_len_12) == gs_156) ObjectDelete(l_name_0);
   }
}

void drawLineSegment(int ai_0, int ai_4, int ai_8) {
   double l_price_20;
   double l_price_28;
   color l_color_36;
   if (ai_8 > 0) {
      l_price_20 = g_ibuf_164[ai_0];
      if (ai_8 == 1) l_price_28 = g_ibuf_164[ai_4];
      else l_price_28 = g_ibuf_172[ai_4];
      l_color_36 = Blue;
   } else {
      l_price_20 = g_ibuf_172[ai_0];
      if (ai_8 == -1) l_price_28 = g_ibuf_172[ai_4];
      else l_price_28 = g_ibuf_164[ai_4];
      l_color_36 = Yellow;
   }
   int l_time_12 = Time[ai_0];
   int l_time_16 = Time[ai_4];
   if (l_price_20 == EMPTY_VALUE || l_price_28 == EMPTY_VALUE) {
      Print("Empty value for price line encountered!");
      return;
   }
   string l_name_40 = gs_156 + "_segment_" + l_color_36 + l_time_12 + "_" + l_time_16;
   ObjectDelete(l_name_40);
   ObjectCreate(l_name_40, OBJ_TREND, 0, l_time_12, l_price_20, l_time_16, l_price_28, 0, 0);
   ObjectSet(l_name_40, OBJPROP_WIDTH, lineWidth);
   ObjectSet(l_name_40, OBJPROP_COLOR, l_color_36);
   ObjectSet(l_name_40, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(l_name_40, OBJPROP_RAY, FALSE);
}