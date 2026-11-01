//+------------------------------------------------------------------+
//|                                                    Renko nmc.mq4 |
//+------------------------------------------------------------------+

#property indicator_chart_window
//#property strict 
#property indicator_buffers 2
#property indicator_color1 clrRoyalBlue
#property indicator_color2 clrMaroon
#property indicator_width1 0
#property indicator_width2 0

extern double BoxSize = 10.0;
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(4);
   SetIndexStyle(0, DRAW_HISTOGRAM);
   SetIndexBuffer(0, Buffer1);
   SetIndexStyle(1, DRAW_HISTOGRAM);
   SetIndexBuffer(1, Buffer2);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexBuffer(2, Buffer3);
   SetIndexStyle(3, DRAW_NONE);
   SetIndexBuffer(3, Buffer4);
   SetIndexLabel(0, "Up");
   SetIndexLabel(1, "Dn");
   IndicatorDigits(Digits);
  
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
  double Hi;
   double Lo;
   double result;
   double barsize;
   double digits;
   int  i;
   for(i = MathMax(rates_total-1-prev_calculated,2); i>=0; i--)
  
   Buffer1[Bars] = Close[Bars];
   Buffer2[Bars] = Close[Bars];
   Buffer3[Bars] = Close[Bars];
   Buffer4[Bars] = Close[Bars];
   if (Digits == 5 || Digits == 3) digits = NormalizeDouble(10.0 * BoxSize, Digits);
   else digits = NormalizeDouble(BoxSize, Digits);
   double box = NormalizeDouble(Point * digits, Digits);
   int bars = Bars - i;
   for (int k = bars; k >= 0; k--) {
      Hi = NormalizeDouble(High[k] - (Buffer3[k + 1]) - box, Digits);
      Lo = NormalizeDouble(Low[k] - (Buffer4[k + 1]) + box, Digits);
      if (Hi >= 0.0) {
         barsize = NormalizeDouble((High[k] - (Buffer3[k + 1])) / box, Digits);
         result = NormalizeDouble(MathFloor(barsize), Digits);
         Buffer3[k] = Buffer3[k + 1] + box * result;
         Buffer4[k] = Buffer3[k] - box * result;
         Buffer1[k] = Buffer3[k];
         Buffer2[k] = Buffer4[k];
         Buffer4[k] = Buffer3[k] - box;
      } else {
         if (Lo <= 0.0) {
            barsize = NormalizeDouble((Buffer4[k + 1] - Low[k]) / box, Digits);
            result = NormalizeDouble(MathFloor(barsize), Digits);
            Buffer4[k] = Buffer4[k + 1] - box * result;
            Buffer3[k] = Buffer4[k] + box * result;
            Buffer2[k] = Buffer3[k];
            Buffer1[k] = Buffer4[k];
            Buffer3[k] = Buffer4[k] + box;
         } else {
            Buffer3[k] = Buffer3[k + 1];
            Buffer4[k] = Buffer4[k + 1];
            if (Buffer1[k + 1] > Buffer2[k + 1]) {
               Buffer1[k] = Buffer1[k + 1];
               Buffer2[k] = Buffer1[k] - box;
            }
            if (Buffer2[k + 1] > Buffer1[k + 1]) {
               Buffer1[k] = Buffer1[k + 1];
               Buffer2[k] = Buffer1[k] + box;
            }
         }
      }
   }
   return(rates_total);
  }
//+------------------------------------------------------------------+
