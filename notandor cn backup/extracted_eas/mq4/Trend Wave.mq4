#property indicator_separate_window
#property indicator_minimum -100.0
#property indicator_maximum 100.0
#property indicator_levelcolor SlateGray
#property indicator_levelstyle 1
#property indicator_buffers 8
#property indicator_color5 Aqua
#property indicator_color6 Yellow
#property indicator_color7 Lime
#property indicator_color8 Red
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width7 3
#property indicator_width8 3
#property indicator_level1 50.0
#property indicator_level2 -50.0
#property link "https://t.me/free_fx_pro"
//#property indicator_level3 -60.0
//#property indicator_level4 -75.0

extern string Notice = "Trading are risky! Trade only if you can loss your money";
extern string FreeFx__ = "free tools for forex! Join our channel for more free eas";
extern string The_our_telegram = "https://t.me/free_fx_pro";
extern int WavePeriod   =  10;
extern int AvgPeriod    =  21;
extern int _level1      =  20;
extern bool SoundAlert = TRUE;
extern bool EmailAlert = FALSE;
double ibuf_92[];
double ibuf_96[];
double ibuf_100[];
double ibuf_104[];
double ibuf_108[];
double ibuf_112[];
double ibuf_116[];
double ibuf_120[];

int init() {
   IndicatorShortName("TrendWave");
   SetIndexBuffer(0, ibuf_100);
   SetIndexLabel(0, "ESA");
   SetIndexStyle(0, DRAW_NONE);
   SetIndexDrawBegin(0, 0);
   SetIndexBuffer(1, ibuf_112);
   SetIndexLabel(1, "DD Values");
   SetIndexStyle(1, DRAW_NONE);
   SetIndexDrawBegin(1, 0);
   SetIndexBuffer(2, ibuf_104);
   SetIndexLabel(2, "DD");
   SetIndexStyle(2, DRAW_NONE);
   SetIndexDrawBegin(2, 0);
   SetIndexBuffer(3, ibuf_108);
   SetIndexLabel(3, "CI");
   SetIndexStyle(3, DRAW_NONE);
   SetIndexDrawBegin(3, 0);
   SetIndexBuffer(4, ibuf_92);
   SetIndexLabel(4, "Bull");
   SetIndexStyle(4, DRAW_LINE);
   SetIndexDrawBegin(4, 0);
   SetIndexBuffer(5, ibuf_96);
   SetIndexLabel(5, "Bear");
   SetIndexStyle(5, DRAW_LINE);
   SetIndexDrawBegin(5, 0);
   SetIndexBuffer(6, ibuf_116);
   SetIndexLabel(6, "Buy Dot");
   SetIndexStyle(6, DRAW_ARROW);
   SetIndexArrow(6, 233);
   SetIndexDrawBegin(6, 0);
   SetIndexBuffer(7, ibuf_120);
   SetIndexLabel(7, "Sell Dot");
   SetIndexStyle(7, DRAW_ARROW);
   SetIndexArrow(7, 234);
   SetIndexDrawBegin(7, 0);
   /*ArrayResize(ibuf_100, Bars);
   ArrayResize(ibuf_112, Bars);
   ArrayResize(ibuf_104, Bars);
   ArrayResize(ibuf_108, Bars);
   ArrayResize(ibuf_92, Bars);
   ArrayResize(ibuf_96, Bars);
   ArrayResize(ibuf_116, Bars);
   ArrayResize(ibuf_120, Bars);*/
   return (0);
}

int start() {
   double l_ima_on_arr_0;
   int li_12 = IndicatorCounted();
   if (li_12 < 0) return (-1);
   if (li_12 > 0) li_12--;
   int li_8 = Bars - li_12;
   for (int li_16 = li_8; li_16 > 0; li_16--) {
      ibuf_100[li_16] = iMA(NULL, 0, WavePeriod, 0, MODE_EMA, PRICE_TYPICAL, li_16);
      ArraySetAsSeries(ibuf_100, TRUE);
   }
   for (li_16 = li_8; li_16 > 0; li_16--) {
      ibuf_112[li_16] = MathAbs((iHigh(NULL, 0, li_16) + iClose(NULL, 0, li_16) + iLow(NULL, 0, li_16)) / 3.0 - ibuf_100[li_16]);
      ArraySetAsSeries(ibuf_112, TRUE);
   }
   for (li_16 = li_8; li_16 > 0; li_16--) {
      l_ima_on_arr_0 = iMAOnArray(ibuf_112, 0, WavePeriod, 0, MODE_EMA, li_16);
      ibuf_104[li_16] = l_ima_on_arr_0;
      ArraySetAsSeries(ibuf_104, TRUE);
   }
   for (li_16 = li_8; li_16 > 0; li_16--) {
      if (ibuf_104[li_16] > 0.0) ibuf_108[li_16] = ((iHigh(NULL, 0, li_16) + iClose(NULL, 0, li_16) + iLow(NULL, 0, li_16)) / 3.0 - ibuf_100[li_16]) / (0.015 * ibuf_104[li_16]);
      else ibuf_108[li_16] = 0;
      ArraySetAsSeries(ibuf_108, TRUE);
   }
   for (li_16 = li_8; li_16 > 0; li_16--) {
      l_ima_on_arr_0 = iMAOnArray(ibuf_108, 0, AvgPeriod, 0, MODE_EMA, li_16);
      ibuf_92[li_16] = l_ima_on_arr_0;
      ArraySetAsSeries(ibuf_92, TRUE);
   }
   for (li_16 = li_8; li_16 > 0; li_16--) {
      l_ima_on_arr_0 = iMAOnArray(ibuf_92, 0, 4, 0, MODE_SMA, li_16);
      ibuf_96[li_16] = l_ima_on_arr_0;
      ArraySetAsSeries(ibuf_96, TRUE);
   }
   for (li_16 = li_8; li_16 > 0; li_16--) {
      if (ibuf_92[li_16] >= ibuf_96[li_16] && ibuf_92[li_16 + 1] <= ibuf_96[li_16 + 1] && ibuf_92[li_16] < -_level1) {
         ibuf_116[li_16] = ibuf_92[li_16];
         //SendAlert("buy");
      } else ibuf_116[li_16] = -1000;
      if (ibuf_92[li_16] <= ibuf_96[li_16] && ibuf_92[li_16 + 1] >= ibuf_96[li_16 + 1] && ibuf_92[li_16] > _level1) {
         ibuf_120[li_16] = ibuf_96[li_16];
         //SendAlert("sell");
      } else ibuf_120[li_16] = -1000;
   }
   return (0);
}
/*
void SendAlert(string as_0) {
   if (Time[0] != i_132) {
      if (SoundAlert) {
         if (as_0 == "buy") Alert(Symbol() + " => " + TimeToStr(TimeCurrent()) + " buy");
         if (as_0 == "sell") Alert(Symbol() + " => " + TimeToStr(TimeCurrent()) + " sell");
      }
      if (EmailAlert) {
         if (as_0 == "buy") SendMail("TrendWave Alert", Symbol() + " => " + TimeToStr(TimeCurrent()) + " buy");
         if (as_0 == "sell") SendMail("TrendWave Alert", Symbol() + " => " + TimeToStr(TimeCurrent()) + " sell");
      }
      i_132 = Time[0];
   }
}*/