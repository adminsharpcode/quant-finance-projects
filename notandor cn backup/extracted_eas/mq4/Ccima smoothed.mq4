//+------------------------------------------------------------------+
//|                                         CCIMA_smoothed_Chart.mq4 |
//|                                               Yuriy Tokman (YTG) |
//|                                               http://ytg.com.ua/ |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_color1 clrDarkViolet
#property indicator_color2 clrRed

input int                EMA_Period   = 12;
input ENUM_MA_METHOD     EMA_Method   = 0;
input ENUM_APPLIED_PRICE EMA_Price    = 0;
input int                CCI_Period   = 10;
input ENUM_APPLIED_PRICE CCI_Price    = 5;
input int                Period_Smoothed = 9;
input ENUM_MA_METHOD     MA_Method = 0;
//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
string name="";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   name = "CCIMA_smoothed_Chart";
   IndicatorShortName(name);
   IndicatorBuffers(3);
   
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexLabel(0,name);
   SetIndexDrawBegin(0,CCI_Period+Period_Smoothed+EMA_Period);
   
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,ExtMapBuffer2);
   SetIndexLabel(1,"MA");
   SetIndexDrawBegin(1,CCI_Period+Period_Smoothed+EMA_Period);
   
   SetIndexStyle(2,DRAW_NONE);
   SetIndexBuffer(2,ExtMapBuffer3);      
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
//---
   int limit=rates_total/* - MathMax(EMA_Period+Period_Smoothed,CCI_Period)*/ -prev_calculated;
   if(prev_calculated==0)limit--;
   else  limit++;  
   double ma=0, cci=0;
   
   for( int i=0; i<limit && !IsStopped(); i++)
     ExtMapBuffer3[i] = iCCI(NULL, 0, CCI_Period, CCI_Price,i)*Point;
   
   for( int i=0; i<limit && !IsStopped(); i++)
    {
     ma = iMA(NULL,0,EMA_Period,0,EMA_Method,EMA_Price,i);
     cci = iMAOnArray(ExtMapBuffer3,0,Period_Smoothed,0,MA_Method,i); 
     ExtMapBuffer1[i] = ma + cci;   
     ExtMapBuffer2[i] = ma;    
    }    
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
