//+------------------------------------------------------------------+
//|                                                     BBMA ReEntry |
//|             https://www.forexfactory.com/showthread.php?t=930783 |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers   4



//---- input parameters
//
//
//
//
extern bool      AutoColoring = True;
extern string    note0001 = "----- REE Arrow Setings-----";
extern int       REEArrowSCode_Buy = 233;
extern int       REEArrowSCode_Sell = 234;
extern color     REEArrowSColor_Buy = Red;
extern color     REEArrowSColor_Sell = Blue;
extern int       REEArrowSSize_Buy = 2;
extern int       REEArrowSSize_Sell = 2;
extern double    REEArrowSGap_Buy = 0;
extern double    REEArrowSGap_Sell = 0;
extern string    note0002 = "----- RRE Arrow Setings-----";
extern int       RREArrowSCode_Buy = 225;
extern int       RREArrowSCode_Sell = 226;
extern color     RREArrowSColor_Buy = Red;
extern color     RREArrowSColor_Sell = Blue;
extern int       RREArrowSSize_Buy = 2;
extern int       RREArrowSSize_Sell = 2;
extern double    RREArrowSGap_Buy = 0;
extern double    RREArrowSGap_Sell = 0;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime dt = 0;

   if(Time[0] != dt)
     {
      dt = Time[0];
      return(true);
     }

   return(false);
  }

//---- buffers
//
//
//
//
//
color    Bull;
color    Bear;
double   REEArrowB[];
double   REEArrowS[];
double   RREArrowB[];
double   RREArrowS[];
int trend;

//
//
//
//
//


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {

   SetIndexBuffer(0, REEArrowB);
   SetIndexStyle(0, DRAW_ARROW,EMPTY,REEArrowSSize_Buy,REEArrowSColor_Buy);
   SetIndexLabel(0,WindowExpertName() + " - Buy");
   SetIndexArrow(0,REEArrowSCode_Buy);
   SetIndexBuffer(1, REEArrowS);
   SetIndexStyle(1, DRAW_ARROW,EMPTY,REEArrowSSize_Sell,REEArrowSColor_Sell);
   SetIndexLabel(1,WindowExpertName() + " - Sell");
   SetIndexArrow(1,REEArrowSCode_Sell);
   SetIndexBuffer(2, RREArrowB);
   SetIndexStyle(2, DRAW_ARROW,EMPTY,RREArrowSSize_Buy,RREArrowSColor_Buy);
   SetIndexLabel(2,WindowExpertName() + " - Buy");
   SetIndexArrow(2,RREArrowSCode_Buy);
   SetIndexBuffer(3, RREArrowS);
   SetIndexStyle(3, DRAW_ARROW,EMPTY,RREArrowSSize_Sell,RREArrowSColor_Sell);
   SetIndexLabel(3,WindowExpertName() + " - Sell");
   SetIndexArrow(3,RREArrowSCode_Sell);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   return (0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   int counted_bars=IndicatorCounted();
   int limit = Bars-counted_bars-1;
   int i;
   Bull = ChartGetInteger(0, CHART_COLOR_CANDLE_BULL, 0);
   Bear = ChartGetInteger(0, CHART_COLOR_CANDLE_BEAR, 0);

   /*if(BarsShift == TRUE)
      SetIndexShift(0,100);*/

   if(AutoColoring == True)
     {
      SetIndexStyle(0, DRAW_ARROW,EMPTY,REEArrowSSize_Buy,Bull);
      SetIndexStyle(1, DRAW_ARROW,EMPTY,REEArrowSSize_Sell,Bear);
      SetIndexStyle(2, DRAW_ARROW,EMPTY,RREArrowSSize_Buy,Bull);
      SetIndexStyle(3, DRAW_ARROW,EMPTY,RREArrowSSize_Sell,Bear);
     }

   for(i=limit; i>=0; i--)
     {
      int SH4 = iBarShift(NULL, PERIOD_H4, Time[i]);
      int SH1 = iBarShift(NULL, PERIOD_H1, Time[i]);

      double SMAH4  = iMA(0, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE, SH4);
      double SMAH1  = iMA(0, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE, SH1);
      double SMA    = iMA(0, 0,         200, 0, MODE_SMA, PRICE_CLOSE, i);
      double EMAH4  = iMA(0, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE, SH4);
      double EMAH1  = iMA(0, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE, SH1);
      double EMA    = iMA(0, 0,         50, 0, MODE_EMA, PRICE_CLOSE, i);
      double WMAUH4 = iMA(0, PERIOD_H4, 5, 0, MODE_LWMA, PRICE_HIGH, SH4);
      double WMAUH1 = iMA(0, PERIOD_H1, 5, 0, MODE_LWMA, PRICE_HIGH, SH1);
      double WMAU   = iMA(0, 0,         5, 0, MODE_LWMA, PRICE_HIGH, i);
      double WMALH4 = iMA(0, PERIOD_H4, 5, 0, MODE_LWMA, PRICE_LOW, SH4);
      double WMALH1 = iMA(0, PERIOD_H1, 5, 0, MODE_LWMA, PRICE_LOW, SH1);
      double WMAL   = iMA(0, 0,         5, 0, MODE_LWMA, PRICE_LOW, i);
      double WMA10UH4 = iMA(0, PERIOD_H4, 10, 0, MODE_LWMA, PRICE_HIGH, SH4);
      double WMA10UH1 = iMA(0, PERIOD_H1, 10, 0, MODE_LWMA, PRICE_HIGH, SH1);
      double WMA10U   = iMA(0, 0,         10, 0, MODE_LWMA, PRICE_HIGH, i);
      double WMA10LH4 = iMA(0, PERIOD_H4, 10, 0, MODE_LWMA, PRICE_LOW, SH4);
      double WMA10LH1 = iMA(0, PERIOD_H1, 10, 0, MODE_LWMA, PRICE_LOW, SH1);
      double WMA10L   = iMA(0, 0,         10, 0, MODE_LWMA, PRICE_LOW, i);
      double BBUH4  = iBands(0, PERIOD_H4, 20, 2.0, 0, PRICE_CLOSE, MODE_UPPER, SH4);
      double BBUH1  = iBands(0, PERIOD_H1, 20, 2.0, 0, PRICE_CLOSE, MODE_UPPER, SH1);
      double BBU    = iBands(0, 0,         20, 2.0, 0, PRICE_CLOSE, MODE_UPPER, i);
      double BBLH4  = iBands(0, PERIOD_H4, 20, 2.0, 0, PRICE_CLOSE, MODE_LOWER, SH4);
      double BBLH1  = iBands(0, PERIOD_H1, 20, 2.0, 0, PRICE_CLOSE, MODE_LOWER, SH1);
      double BBL    = iBands(0, 0,         20, 2.0, 0, PRICE_CLOSE, MODE_LOWER, i);
      double BBMH4  = iBands(0, PERIOD_H4, 20, 2.0, 0, PRICE_CLOSE, MODE_MAIN,  SH4);
      double BBMH1  = iBands(0, PERIOD_H1, 20, 2.0, 0, PRICE_CLOSE, MODE_MAIN,  SH1);
      double BBM    = iBands(0, 0,         20, 2.0, 0, PRICE_CLOSE, MODE_MAIN,  i);

      if(BBM > EMA && EMA > SMA
         && BBMH1 > EMAH1 && EMAH1 > SMAH1
         && BBMH4 > EMAH4 && EMAH4 > SMAH4)
         trend = 1;
      else
         if(BBM < EMA && EMA < SMA
            && BBMH1 < EMAH1 && EMAH1 < SMAH1
            && BBMH4 < EMAH4 && EMAH4 < SMAH4)
            trend = -1;
         else
            trend = 0;

      //if(Low[i] <= WMA10LH4
      //   && BBMH4 < WMAUH4
      //   && WMAL < BBL
      //   && Close[i] < Open[i])
      //if(BBLH4 > WMALH4
      //&& BBL > Low[i]
      //&& WMAU > BBM
      //&& WMALH4 > Low[i]
      //&& WMALH1 > BBLH1
      //&& Low[i] > BBLH1
      //&& Close[i] < Open[i])

      //if(High[i] >= WMA10UH4
      //   && BBMH4 > WMALH4
      //   && WMAU > BBU
      //   && Close[i] > Open[i])
      //if(BBUH4 < WMAUH4
      //&& BBU < High[i]
      //&& WMAL < BBM
      //&& WMAUH4 < High[i]
      //&& WMAUH1 < BBUH1
      //&& High[i] < BBUH1
      //&& Close[i] > Open[i])

//+------------------------------------------------------------------+
//|                           R - E - E                              |
//+------------------------------------------------------------------+

      if(BBL > WMAL
      && BBLH1 > WMALH1
      && (WMALH4 > Close[i] || WMA10LH4 > Close[i] || BBMH4 > Close[i])
      && (WMA10LH4 > BBMH4 || BBLH4 > WMALH4)
      && BBL > Close[i]
      && WMAL > Close[i]
      && Open[i] > Close[i])
         REEArrowB[i] = Low[i] - (REEArrowSGap_Buy*Point()*10);
      else
         REEArrowB[i] = EMPTY_VALUE;

      if(BBU < WMAU
      && BBUH1 < WMAUH1
      && (WMAUH4 < Close[i] || WMA10UH4 < Close[i] || BBMH4 < Close[i])
      && (WMA10UH4 < BBMH4 || BBUH4 < WMAUH4)
      && BBU < Close[i]
      && WMAU < Close[i]
      && Open[i] < Close[i])
         REEArrowS[i] = High[i] + (REEArrowSGap_Buy*Point()*10);
      else
         REEArrowS[i] = EMPTY_VALUE;

//+------------------------------------------------------------------+
//|                           R - R - E                              |
//+------------------------------------------------------------------+

      if(BBL > WMAL
      && WMALH1 > BBLH1
      && BBUH1 >  WMAUH1
      && WMALH4 > BBLH4
      && BBUH4 >  WMAUH4
      && (WMALH1 > Close[i] || WMA10LH1 > Close[i] || BBMH1 > Close[i])
      && (WMALH4 > Close[i] || WMA10LH4 > Close[i] || BBMH4 > Close[i])
      && WMA10UH1 > BBMH1
      && WMA10UH4 > BBMH4
      && BBL > Close[i]
      && WMAL > Close[i]
      && Open[i] > Close[i])
         RREArrowB[i] = Low[i] - (RREArrowSGap_Buy*Point()*10);
      else
         RREArrowB[i] = EMPTY_VALUE;

      if(BBU < WMAU
      && WMAUH1 < BBUH1
      && BBLH1 < WMALH1
      && WMAUH4 < BBUH4
      && BBLH4 < WMALH4
      && (WMAUH1 < Close[i] || WMA10UH1 < Close[i] || BBMH1 < Close[i])
      && (WMAUH4 < Close[i] || WMA10UH4 < Close[i] || BBMH4 < Close[i])
      && WMA10LH1 < BBMH1
      && WMA10LH4 < BBMH4
      && BBU < Close[i]
      && WMAU < Close[i]
      && Open[i] < Close[i])
         RREArrowS[i] = High[i] + (RREArrowSGap_Buy*Point()*10);
      else
         RREArrowS[i] = EMPTY_VALUE;

     }

   Comment(trend);
   IndicatorShortName(WindowExpertName());
   return(0);
  }
//+------------------------------------------------------------------+
