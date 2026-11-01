//+------------------------------------------------------------------+
//|                                       smTMMS Oscillator_vX
//+------------------------------------------------------------------+
#property copyright "Copyright 11.05.2020, SwingMan"
#property strict
#property indicator_separate_window

//31.05.2020   -  v7.3.1-  All Alerts at previous bar
//11.05.2020   -  v7.3  -  Alerts for: Stochastic Momentum Index Cross signals; for color change of Dots
//03.05.2020   -  v7.2  -  Number of vertical lines
//02.05.2020   -  v7.1  -  Bug - limit for SMI calculation; corrected
//29.04.2020   -  v7.0  -  Arrows, Vertical lines for crossing
//28.04.2020   -  v5.0-new  -  with Stochastic Momentum Index, arrows and vertical lines; It gives a version 5.0!?
//17.08.2019   -  v4.1  -  width 1 for histograms when Hashi or Hull are not identical with the oscillator trend
//16.08.2019   -  v4.0  -  with Alerts

#property indicator_buffers 13

#property indicator_color1 clrSienna      //lines
#property indicator_color2 clrLime
#property indicator_color3 clrDarkViolet //clrSlateGray
#property indicator_color4 clrGreen       //histograms
#property indicator_color5 clrRed
#property indicator_color6 clrWhite  //clrDarkGray
#property indicator_color7 clrDodgerBlue //clrLime        //arrows
#property indicator_color8 clrOrangeRed //clrOrange
#property indicator_color9 clrGreen       //histograms
#property indicator_color10 clrRed

#property indicator_width1 1              //lines
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 3              //histograms
#property indicator_width5 3
#property indicator_width6 3 //1
#property indicator_width7 1              //arrows
#property indicator_width8 1
#property indicator_width9 3 //1              //histograms
#property indicator_width10 3 //1

#property indicator_level1 20
#property indicator_level2 0
#property indicator_level3 -20
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
#property indicator_levelwidth 1

#property indicator_maximum 50
#property indicator_minimum -50
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_ARROW_TYPE
  {
   Circle,
   Rectangle
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_HISTOGRAM_LINE
  {
   Stochastic_2,
   Stochastic_1,
   RSI
  };
enum ENUM_VLINES_MODE
  {
   ALL,
   BUY,
   SELL
  };
//--- inputs
//+------------------------------------------------------------------+
input ENUM_HISTOGRAM_LINE Histogram_Line=Stochastic_2;
//input bool           Draw_Oscillator_Lines=false;
sinput string        sRSI     ="RSI"; //=================================
input int            RSI_Period=14;
input ENUM_APPLIED_PRICE      RSI_AppliedPrice=PRICE_CLOSE;
//
sinput string        sStochastic="STOCHASTIC"; //=================================
input int            Stochastic_1_Period_K  = 8;
input int            Stochastic_1_Period_D  = 3;
input int            Stochastic_1_Slowing   = 3;
input ENUM_STO_PRICE Stochastic_1_PriceField = STO_LOWHIGH;
input ENUM_MA_METHOD Stochastic_1_MAmethod   = MODE_SMMA;
input int            Stochastic_2_Period_K  = 14;
input int            Stochastic_2_Period_D  = 3;
input int            Stochastic_2_Slowing   = 3;
input ENUM_STO_PRICE Stochastic_2_PriceField = STO_LOWHIGH;
input ENUM_MA_METHOD Stochastic_2_MAmethod   = MODE_SMMA;
//
sinput string  sSMI_Blau="(SMI_Blau)_Stochastic_Momentum_Index"; //=================================
input int      Period_Q  = 9;
input int      Period_R  = 9;
input int      Period_S  = 9;
input color    SMI_Color=clrGold;
input int      SMI_Width=2;
input bool     Draw_Crossing_Arrows=true;
input int      SMI_ArrowWidth=2;
input color    SMI_ArrowUP=clrAqua;
input color    SMI_ArrowDN=clrMagenta;
sinput string        sVerticalLines="Vertical Lines"; //=================================
input bool             Draw_Vertical_Lines   =false;
input ENUM_VLINES_MODE Mode_Vertical_Lines   =ALL;
input int              NumberOf_VerticalLines=2;
//
sinput string             sHullAverage="HULL MovingAverage"; //=================================
input bool                Draw_HullTrend  =true;
input int                 Hull_Period     =12;
input double              Hull_Divisor    =3;
input ENUM_APPLIED_PRICE  Hull_AppliedPrice=PRICE_CLOSE;
input ENUM_ARROW_TYPE     Arrow_Type=Circle;
//
sinput string             sAlerts="Alerts_ThresholdLines"; //=================================
extern double Threshold_Line=20;
extern bool ThresholdLines_Alert =false;
extern bool ThresholdLines_Email =false;
extern bool ThresholdLines_Notification=false;
sinput string             sAlertsSMI="Alerts_StochasticMomentumIndex"; //=================================
extern bool StochasticMomentum_Alert=false;
extern bool StochasticMomentum_EMail=false;
extern bool StochasticMomentum_Notification=false;
sinput string             sAlertsDotsColor="Alerts_DotsColorChange"; //=================================
extern bool DotsColorChange_Alert=false;
extern bool DotsColorChange_EMail=false;
extern bool DotsColorChange_Notification=false;
//+------------------------------------------------------------------+

//---- buffers
double bufRSI[],bufStoch1[],bufStoch2[];
double bufHistUP[],bufHistDN[],bufHistNO[];
double bufHullUP[],bufHullDN[],bufHull[],buffHullAvg[],trend[];
double oscAlertThreshold[],oscSignalThreshold[];
double oscAlertStochastic[],oscSignalStochastic[];
double oscAlertDots[],oscSignalDots[];
double bufHistUPthin[],bufHistDNthin[];
double SMI_Buffer[];
double SM_Buffer[], EMA_SM[], EMA2_SM[], EMA_HQ[], EMA2_HQ[], HQ_Buffer[];
double crossUP[],crossDN[];
//--- variables
datetime thisTime,oldTime;
bool newBar;
string CR="\n";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ChartSetInteger(0,CHART_SHOW_GRID,false);

   int iArrow=108;
//--- indicator buffers mapping
   int iBuff=-1;
//--- lines
   iBuff++;
   SetIndexBuffer(iBuff,bufRSI);
   SetIndexStyle(iBuff,DRAW_LINE);
   SetIndexLabel(iBuff,"RSI");
   if(Histogram_Line==Stochastic_2 || Histogram_Line==Stochastic_1)
      SetIndexStyle(iBuff,DRAW_NONE);
//if(Draw_Oscillator_Lines==false) SetIndexStyle(iBuff,DRAW_NONE);
   iBuff++;
   SetIndexBuffer(iBuff,bufStoch1);
   SetIndexStyle(iBuff,DRAW_LINE);
   SetIndexLabel(iBuff,"Stochastic1 ("+(string)Stochastic_1_Period_K+")");
   if(Histogram_Line==Stochastic_2 || Histogram_Line==RSI)
      SetIndexStyle(iBuff,DRAW_NONE);
   iBuff++;
   SetIndexBuffer(iBuff,bufStoch2);
   SetIndexStyle(iBuff,DRAW_LINE);
   SetIndexLabel(iBuff,"Stochastic2 ("+(string)Stochastic_2_Period_K+")");
   if(Histogram_Line==Stochastic_1 || Histogram_Line==RSI)
      SetIndexStyle(iBuff,DRAW_NONE);
//--- histograms
   iBuff++;
   SetIndexBuffer(iBuff,bufHistUP);
   SetIndexStyle(iBuff,DRAW_HISTOGRAM);
   SetIndexLabel(iBuff,NULL);
   iBuff++;
   SetIndexBuffer(iBuff,bufHistDN);
   SetIndexStyle(iBuff,DRAW_HISTOGRAM);
   SetIndexLabel(iBuff,NULL);
   iBuff++;
   SetIndexBuffer(iBuff,bufHistNO);
   SetIndexStyle(iBuff,DRAW_HISTOGRAM);
   SetIndexLabel(iBuff,NULL);

//--- arrows - HULL moving average
   if(Arrow_Type==Circle)
      iArrow=108;
   else
      if(Arrow_Type==Rectangle)
         iArrow=110;
   iBuff++;
   SetIndexBuffer(iBuff,bufHullUP);
   SetIndexStyle(iBuff,DRAW_ARROW);
   SetIndexArrow(iBuff,iArrow);
   SetIndexLabel(iBuff,"HMA_Trend UP");
   if(Draw_HullTrend==false)
      SetIndexStyle(iBuff,DRAW_NONE);
   iBuff++;
   SetIndexBuffer(iBuff,bufHullDN);
   SetIndexStyle(iBuff,DRAW_ARROW);
   SetIndexArrow(iBuff,iArrow);
   SetIndexLabel(iBuff,"HMA_Trend DOWN");
   if(Draw_HullTrend==false)
      SetIndexStyle(iBuff,DRAW_NONE);
//--- thin histograms
   iBuff++;
   SetIndexBuffer(iBuff,bufHistUPthin);
   SetIndexStyle(iBuff,DRAW_HISTOGRAM);
   SetIndexLabel(iBuff,NULL);
   iBuff++;
   SetIndexBuffer(iBuff,bufHistDNthin);
   SetIndexStyle(iBuff,DRAW_HISTOGRAM);
   SetIndexLabel(iBuff,NULL);

//--- Stochastic Momentum Index
   iBuff++;
   SetIndexBuffer(iBuff,SMI_Buffer);
   SetIndexStyle(iBuff,DRAW_LINE,STYLE_SOLID,SMI_Width,SMI_Color);
   SetIndexLabel(iBuff,"SMI");
   int iArrowUP=233; //221;
   int iArrowDN=234; //222;
   iBuff++;
   SetIndexBuffer(iBuff,crossUP);
   SetIndexStyle(iBuff,DRAW_ARROW,STYLE_SOLID,SMI_ArrowWidth,SMI_ArrowUP);
   SetIndexArrow(iBuff,iArrowUP);
   SetIndexLabel(iBuff,"SMI-Cross UP");
   if(Draw_Crossing_Arrows==false)
      SetIndexStyle(iBuff,DRAW_NONE);
   iBuff++;
   SetIndexBuffer(iBuff,crossDN);
   SetIndexStyle(iBuff,DRAW_ARROW,STYLE_SOLID,SMI_ArrowWidth,SMI_ArrowDN);
   SetIndexArrow(iBuff,iArrowDN);
   SetIndexLabel(iBuff,"SMI-Cross DN");
   if(Draw_Crossing_Arrows==false)
      SetIndexStyle(iBuff,DRAW_NONE);

//--- more buffers
   IndicatorBuffers(28);

   iBuff++;
   SetIndexBuffer(iBuff,bufHull);
   iBuff++;
   SetIndexBuffer(iBuff,buffHullAvg);
   iBuff++;
   SetIndexBuffer(iBuff,trend);

//--- Alerts
   iBuff++;
   SetIndexBuffer(iBuff,oscAlertThreshold);
   SetIndexEmptyValue(iBuff,EMPTY_VALUE);
   iBuff++;
   SetIndexBuffer(iBuff,oscSignalThreshold);
   SetIndexEmptyValue(iBuff,EMPTY_VALUE);

   iBuff++;
   SetIndexBuffer(iBuff,oscAlertStochastic);
   SetIndexEmptyValue(iBuff,EMPTY_VALUE);
   iBuff++;
   SetIndexBuffer(iBuff,oscSignalStochastic);
   SetIndexEmptyValue(iBuff,EMPTY_VALUE);

   iBuff++;
   SetIndexBuffer(iBuff,oscAlertDots);
   SetIndexEmptyValue(iBuff,EMPTY_VALUE);
   iBuff++;
   SetIndexBuffer(iBuff,oscSignalDots);
   SetIndexEmptyValue(iBuff,EMPTY_VALUE);

//--- SMI help buffers
   iBuff++;
   SetIndexBuffer(iBuff,SM_Buffer);
   iBuff++;
   SetIndexBuffer(iBuff,HQ_Buffer);
   iBuff++;
   SetIndexBuffer(iBuff,EMA_SM);
   iBuff++;
   SetIndexBuffer(iBuff,EMA2_SM);
   iBuff++;
   SetIndexBuffer(iBuff,EMA_HQ);
   iBuff++;
   SetIndexBuffer(iBuff,EMA2_HQ);

//---
   IndicatorDigits(2);
   return(INIT_SUCCEEDED);
  }
//---
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,"VLine_");
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
//---
   int    i,pos;
   double threshold=50,limit=0;

//---
   if(rates_total<=10)
      return(0);

   thisTime=Time[0];
   if(thisTime!=oldTime)
     {
      oldTime=thisTime;
      newBar=true;
     }
   else
      newBar=false;

   pos=0;

//--- main loop of calculations
   for(i=pos; i<rates_total; i++)
     {
      //--- oscillators
      bufRSI[i]=iRSI(Symbol(),Period(),RSI_Period,RSI_AppliedPrice,i);
      bufStoch1[i]=iStochastic(Symbol(),Period(),
                               Stochastic_1_Period_K,Stochastic_1_Period_D,Stochastic_1_Slowing,
                               Stochastic_1_MAmethod,Stochastic_1_PriceField,MODE_MAIN,i);
      bufStoch2[i]=iStochastic(Symbol(),Period(),
                               Stochastic_2_Period_K,Stochastic_2_Period_D,Stochastic_2_Slowing,
                               Stochastic_2_MAmethod,Stochastic_2_PriceField,MODE_MAIN,i);
      bufRSI[i]=bufRSI[i]-threshold;
      bufStoch1[i]=bufStoch1[i]-threshold;
      bufStoch2[i]=bufStoch2[i]-threshold;

      //--- histograms; Alerts
      bufHistUP[i]=EMPTY_VALUE;
      bufHistDN[i]=EMPTY_VALUE;
      bufHistNO[i]=EMPTY_VALUE;
      oscAlertThreshold[i] =EMPTY_VALUE;

      double lineValue=-1;
      switch(Histogram_Line)
        {
         case Stochastic_2:
            lineValue=bufStoch2[i];
            break;
         case Stochastic_1:
            lineValue=bufStoch1[i];
            break;
         case RSI:
            lineValue=bufRSI[i];
            break;
        }

      if(bufRSI[i]>limit && bufStoch1[i]>limit && bufStoch2[i]>limit)
        {
         bufHistUP[i]=lineValue; //bufStoch2[i];
         if(bufHistUP[i]>Threshold_Line)
            oscAlertThreshold[i]=1;
        }
      else
         if(bufRSI[i]<limit && bufStoch1[i]<limit && bufStoch2[i]<limit)
           {
            bufHistDN[i]=lineValue; //bufStoch2[i];
            if(bufHistUP[i]<-Threshold_Line)
               oscAlertThreshold[i]=-1;
           }
         else
           {
            bufHistNO[i]=lineValue; //bufStoch2[i];
           }
     }

//===================================
//--- Stochastic Momentum Index
//===================================
   int Lookback=1000;
   int Signal=0;
   int maxPeriod=MathMax(Period_Q,Period_R);
   maxPeriod=MathMax(maxPeriod,Period_S)-1;
   int iLimit = MathMin(Bars-maxPeriod,Lookback);

   for(i=iLimit; i>=0; i--)
     {
      HQ_Buffer[i]=High[Highest(NULL,0,MODE_HIGH,Period_Q,i)]-Low[Lowest(NULL,0,MODE_LOW,Period_Q,i)];
      SM_Buffer[i]=Close[i]-(High[Highest(NULL,0,MODE_HIGH,Period_Q,i)]+Low[Lowest(NULL,0,MODE_LOW,Period_Q,i)])/2;
     }
   for(i=iLimit-Period_R; i>=0; i--)
     {
      EMA_SM[i]=iMAOnArray(SM_Buffer,0,Period_R,0,MODE_EMA,i);
      EMA_HQ[i]=iMAOnArray(HQ_Buffer,0,Period_R,0,MODE_EMA,i);
     }
   for(i=iLimit-Period_R-Period_S; i>=0; i--)
     {
      EMA2_SM[i]=iMAOnArray(EMA_SM,0,Period_S,0,MODE_EMA,i);
      EMA2_HQ[i]=iMAOnArray(EMA_HQ,0,Period_S,0,MODE_EMA,i);
     }
   for(i=iLimit-Period_R-Period_S-Signal; i>=0; i--)
     {
      SMI_Buffer[i]=100*EMA2_SM[i]/(1.0*EMA2_HQ[i]);
      //SMI_Buffer[i]=100*EMA2_SM[i]/0.5/EMA2_HQ[i];
     }
//===================================
//---Draw  Crossing Arrows
//===================================
   int shift=1;   
   int iShift;
   if(Draw_Crossing_Arrows==true && newBar==true)
     {
      double lineValue=-1,lineValue1=-1;
      for(i=iLimit-Period_R-Period_S-Signal; i>=0; i--)
        {
         iShift=i+shift;
         switch(Histogram_Line)
           {
            case Stochastic_2:
               lineValue=bufStoch2[iShift];
               lineValue1=bufStoch2[iShift+1];
               break;
            case Stochastic_1:
               lineValue=bufStoch1[iShift];
               lineValue1=bufStoch1[iShift+1];
               break;
            case RSI:
               lineValue=bufRSI[iShift];
               lineValue1=bufRSI[iShift+1];
               break;
           }

         //-- cross UP
         if(lineValue>SMI_Buffer[iShift] && lineValue1<SMI_Buffer[iShift+1])
           {
            crossUP[iShift]=SMI_Buffer[iShift];
            crossDN[iShift]=EMPTY_VALUE;
           }
         //-- cross DOWN
         if(lineValue<SMI_Buffer[iShift] && lineValue1>SMI_Buffer[iShift+1])
           {
            crossUP[iShift]=EMPTY_VALUE;
            crossDN[iShift]=SMI_Buffer[i];
           }
        }
     }

//===================================
//--- Draw Crossing vertical lines
//===================================
   int numberVLines=0;
   double lineValue=-1,lineValue1=-1;

//--- 1. delete old vertical lines
   if(Draw_Vertical_Lines==true && newBar==true)
     {
      for(i=0; i<iLimit-Period_R-Period_S-Signal; i++)
        {
         iShift=i+shift;
         switch(Histogram_Line)
           {
            case Stochastic_2:
               lineValue=bufStoch2[iShift];
               lineValue1=bufStoch2[iShift+1];
               break;
            case Stochastic_1:
               lineValue=bufStoch1[iShift];
               lineValue1=bufStoch1[iShift+1];
               break;
            case RSI:
               lineValue=bufRSI[iShift];
               lineValue1=bufRSI[iShift+1];
               break;
           }

         if(lineValue>SMI_Buffer[iShift] && lineValue1<SMI_Buffer[iShift+1])
           {
            ObjectsDeleteAll(0,"VLine_");
            break;
           }
         if(lineValue<SMI_Buffer[iShift] && lineValue1>SMI_Buffer[iShift+1])
           {
            ObjectsDeleteAll(0,"VLine_");
            break;
           }
        }

      //--- 2. draw new vertical lines
      lineValue=-1;
      lineValue1=-1;
      for(i=0; i<iLimit-Period_R-Period_S-Signal; i++)
        {
         iShift=i+shift;
         switch(Histogram_Line)
           {
            case Stochastic_2:
               lineValue=bufStoch2[iShift];
               lineValue1=bufStoch2[iShift+1];
               break;
            case Stochastic_1:
               lineValue=bufStoch1[iShift];
               lineValue1=bufStoch1[iShift+1];
               break;
            case RSI:
               lineValue=bufRSI[iShift];
               lineValue1=bufRSI[iShift+1];
               break;
           }
         //-- cross UP
         if(lineValue>SMI_Buffer[iShift] && lineValue1<SMI_Buffer[iShift+1])
           {
            if(Mode_Vertical_Lines==ALL || Mode_Vertical_Lines==BUY)
              {
               Draw_VerticalLine("buy",iShift);
               numberVLines++;
              }
           }
         //-- cross DOWN
         if(lineValue<SMI_Buffer[iShift] && lineValue1>SMI_Buffer[iShift+1])
           {
            if(Mode_Vertical_Lines==ALL || Mode_Vertical_Lines==SELL)
              {
               Draw_VerticalLine("sell",iShift);
               numberVLines++;
              }
           }

         if(numberVLines>=NumberOf_VerticalLines)
            break;
        }
     }

//=========================================================
//--- Last bar;  Alerts at previous bar
   i=0;
//--- 1. Threshold - Alert ----------------------
   if(newBar==true)
     {
      //--- LONG Alert
      if(oscAlertThreshold[i+2]==EMPTY_VALUE && oscAlertThreshold[i+1]==1 && oscSignalThreshold[i]==EMPTY_VALUE)
        {
         SendAlerts("Threshold",i,OP_BUY,Symbol(),Period());
         oscSignalThreshold[i]=1;
        }
      else
         //--- SHORT Alert
         if(oscAlertThreshold[i+2]==EMPTY_VALUE && oscAlertThreshold[i+1]==-1 && oscSignalThreshold[i]==EMPTY_VALUE)
           {
            SendAlerts("Threshold",i,OP_SELL,Symbol(),Period());
            oscSignalThreshold[i]=1;
           }
     }

//--- 2. Stochastic Momentum Index - Alert ------
   if(newBar==true)
     {
      //--- LONG Alert
      if(crossUP[i+1]!=EMPTY_VALUE && oscSignalStochastic[i]==EMPTY_VALUE)
        {
         SendAlerts("Stochastic",i,OP_BUY,Symbol(),Period());
         oscSignalStochastic[i]=1;
        }
      else
         //--- SHORT Alert
         if(crossDN[i+1]!=EMPTY_VALUE && oscSignalStochastic[i]==EMPTY_VALUE)
           {
            SendAlerts("Stochastic",i,OP_SELL,Symbol(),Period());
            oscSignalStochastic[i]=1;
           }
     }
//--- 3. Dots Color - Alert ---------------------
   if(newBar==true)
     {
      //--- LONG Alert
      if(bufHullUP[i+2]==EMPTY_VALUE && bufHullUP[i+1]==0)
        {
         SendAlerts("Dots",i,OP_BUY,Symbol(),Period());
         oscSignalDots[i]=1;
        }
      else
         //--- SHORT Alert
         if(bufHullDN[i+2]==EMPTY_VALUE && bufHullDN[i+1]==0)
           {
            SendAlerts("Dots",i,OP_SELL,Symbol(),Period());
            oscSignalDots[i]=1;
           }
     }

//===============================================
//--- Hull Moving Average -----------------------
   Get_HullMovingAverage(rates_total,bufHullUP,bufHullDN);

   Draw_ThinHistograms(rates_total);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_VerticalLine(string code,int iBar)
  {
   bool bHiddenObjects=true;

   int iWidth=1;
   int iStyle=STYLE_DOT;

   color dColor=0;
   if(code=="buy")
      dColor=clrAqua;
   else
      if(code=="sell")
         dColor=clrMagenta;

   string objName="VLine_"+TimeToString(Time[iBar]);
   if(ObjectFind(objName)>0)
      ObjectDelete(objName);

//int moreDays=0;
//int thisDay=TimeDayOfWeek(Time[iBar]);
//if(thisDay==FRIDAY)
//   moreDays=2;
//else
//   if(thisDay==THURSDAY)
//      moreDays=2;

   datetime time1=Time[iBar];
//datetime time2=time1+(Line_Length+moreDays)*Period()*60;

   ObjectCreate(0,objName,OBJ_VLINE,0,time1,0);
   ObjectSetInteger(0,objName,OBJPROP_COLOR,dColor);
   ObjectSetInteger(0,objName,OBJPROP_WIDTH,iWidth);
   ObjectSetInteger(0,objName,OBJPROP_STYLE,iStyle);
   ObjectSetInteger(0,objName,OBJPROP_RAY,true);
   ObjectSetInteger(0,objName,OBJPROP_BACK,true);
   ObjectSetInteger(0,objName,OBJPROP_HIDDEN,bHiddenObjects);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_ThinHistograms(int limitX)
  {
   for(int i=0; i<limitX; i++)
     {
      if(bufHullUP[i]==EMPTY_VALUE && bufHistUP[i]!=EMPTY_VALUE)
        {
         bufHistUPthin[i]=bufHistUP[i];
         bufHistUP[i]=EMPTY_VALUE;
        }
      else
         if(bufHullDN[i]==EMPTY_VALUE && bufHistDN[i]!=EMPTY_VALUE)
           {
            bufHistDNthin[i]=bufHistDN[i];
            bufHistDN[i]=EMPTY_VALUE;
           }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Get_HullMovingAverage(int limitX,double &hullUP[],double &hullDN[])
  {
   double zero=0;
//-- Hull moving average current TF -------------
   int MA_period1=(int)(Hull_Period/Hull_Divisor);
   int pPeriod=(int)MathSqrt(Hull_Period);

   for(int i=0; i<limitX; i++)
      bufHull[i]=2*iMA(Symbol(),Period(),MA_period1,0,MODE_LWMA,Hull_AppliedPrice,i)-
                 iMA(Symbol(),Period(),Hull_Period,0,MODE_LWMA,Hull_AppliedPrice,i);

   for(int i=0; i<limitX-Hull_Period; i++)
      buffHullAvg[i]=iMAOnArray(bufHull,0,pPeriod,0,MODE_LWMA,i);

//-- Arrows Hull moving average trend -----------
   for(int i=limitX-Hull_Period-1; i>=0; i--)
     {
      //trend[i]=trend[i+1];
      if(buffHullAvg[i]>=buffHullAvg[i+1])
         trend[i]=1;
      else
         trend[i]=-1;

      if(trend[i]>0)
        {
         hullUP[i]=zero;
         hullDN[i]=EMPTY_VALUE;
        }
      else
         if(trend[i]<0)
           {
            hullUP[i]=EMPTY_VALUE;
            hullDN[i]=zero;
           }
     }
  }
//                            *****************************
//                            **       ALERTS            **
//                            *****************************
//+------------------------------------------------------------------+
//    Send Alerts
//+------------------------------------------------------------------+
void SendAlerts(string code,int iBar,int iSignalDirection,string sSymbol,int iPeriod)
  {
//if(ThresholdLines_Alert == false && ThresholdLines_Email == false)
//   return;
//---
   string subjectEmailAlert="TMMS Oscillator";

   string   sPeriod     = " ("+Get_PeriodString(iPeriod)+") ";
   double   dEntryPrice = iOpen(sSymbol,iPeriod,iBar);
   string   sEntryPrice = " "+DoubleToString(dEntryPrice,Digits);
   string   sTime       = "  [" + TimeToStr(TimeCurrent(),TIME_MINUTES|TIME_SECONDS) + "] ";
   string   sBarTime    = "  Bar: " + TimeToStr(Time[iBar],TIME_MINUTES|TIME_SECONDS) + "  ";

   string sText,sTextAlert;

//--- LONG Entry Signal ------------------------------------------
   if(iSignalDirection==OP_BUY)
     {
      sText=" LONG entry:";
     }
   else

      //--- SHORT Entry Signal -----------------------------------------
      if(iSignalDirection==OP_SELL)
        {
         sText=" SHORT entry:";
        }

//======================================================================
//--- 1. Send alerts Threshold lines -----------------------------------
   if(code=="Threshold")
     {
      sTextAlert=sSymbol+sPeriod+sText+sEntryPrice+sTime+"TMMS Threshold";

      if(ThresholdLines_Alert==true)
         Alert(sTextAlert);
      if(ThresholdLines_Email==true)
         SendMail(subjectEmailAlert,sTextAlert);
      if(ThresholdLines_Notification==true)
         SendNotification(sTextAlert);
     }

//--- 2. Send alerts Stochastic Momentum Index -------------------------
   if(code=="Stochastic")
     {
      sTextAlert=sSymbol+sPeriod+sText+sEntryPrice+sTime+"TMMS Stoch.Momentum";

      if(StochasticMomentum_Alert==true)
         Alert(sTextAlert);
      if(StochasticMomentum_EMail==true)
         SendMail(subjectEmailAlert,sTextAlert);
      if(StochasticMomentum_Notification==true)
         SendNotification(sTextAlert);
     }

//--- 3. Send alerts Dots Color Change = Hull slope -------------------------
   if(code=="Dots")
     {
      sTextAlert=sSymbol+sPeriod+sText+sEntryPrice+sTime+"TMMS Dots Color";

      if(DotsColorChange_Alert==true)
         Alert(sTextAlert);
      if(DotsColorChange_EMail==true)
         SendMail(subjectEmailAlert,sTextAlert);
      if(DotsColorChange_Notification==true)
         SendNotification(sTextAlert);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Get_PeriodString(int iPeriod)
  {
   string sPeriod;
   switch(iPeriod)
     {
      case PERIOD_M1:
         sPeriod="M1";
         break;
      case PERIOD_M5:
         sPeriod="M5";
         break;
      case PERIOD_M15:
         sPeriod="M15";
         break;
      case PERIOD_M30:
         sPeriod="M30";
         break;
      case PERIOD_H1:
         sPeriod="H1";
         break;
      case PERIOD_H4:
         sPeriod="H4";
         break;
      case PERIOD_D1:
         sPeriod="D1";
         break;
      case PERIOD_W1:
         sPeriod="W1";
         break;
      case PERIOD_MN1:
         sPeriod="MN1";
         break;
     }
   return(sPeriod);
  }
//+------------------------------------------------------------------+
