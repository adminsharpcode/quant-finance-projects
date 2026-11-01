//+------------------------------------------------------------------+
//|      indic  to see if RSI is above or under 2 valors   |
//|                      Copyright © 2008, Pharmacien@dejante.com    |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
// you are asking if RSI is above/under 45/55 ?

#property  copyright "Copyright © 2008, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 1

#property  indicator_buffers 3
#property  indicator_color1  DarkGreen
#property  indicator_color2  Crimson
#property  indicator_color3  Yellow
//---- indicator parameters      
extern int RSI=8;
extern int valeur1=55;
extern int valeur2=45;

//---- indicator buffers
double   ExtBuffer1[];
double   ExtBuffer2[];
double   ExtBuffer3[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- drawing settings
   SetIndexStyle (0,DRAW_HISTOGRAM, EMPTY,4,DarkGreen);
   SetIndexBuffer(0,ExtBuffer1);
   SetIndexStyle (1,DRAW_HISTOGRAM, EMPTY,4,Crimson);
   SetIndexBuffer(1,ExtBuffer2);
   SetIndexStyle (2,DRAW_HISTOGRAM, EMPTY,4,Yellow);
   SetIndexBuffer(2,ExtBuffer3);
//---- names
   IndicatorShortName("RSI above/under 45/55");
   SetIndexLabel(0,"RSI"+RSI +" is above 55");
   SetIndexLabel(1,"RSI"+RSI +" is under 45");
   SetIndexLabel(2,"RSI is in the mid zone ");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Averages                                                  |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- macd counted in the 1st buffer
   for(int i=0; i<limit; i++)
       if (iRSI(NULL,0,RSI,PRICE_CLOSE,i)<=valeur2) 
        {
        ExtBuffer2[i]=1;
        }
       else
       if (iRSI(NULL,0,RSI,PRICE_CLOSE,i)>=valeur1)
        {
        ExtBuffer1[i]=1;
        }
       else 
        ExtBuffer3[i]=1;
   
   return(0);
  }
  
//+------------------------------------------------------------------+