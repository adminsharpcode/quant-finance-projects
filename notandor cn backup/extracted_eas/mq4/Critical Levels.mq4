//+------------------------------------------------------------------+
//|                                              Critical Levels.mq4 |
//+------------------------------------------------------------------+
//#property copyright "Copyright © 2011, David Louisson"
//#property link      "http://www.forexfactory.com/hanover"

#property indicator_chart_window

#include <hanover --- function header.mqh>

/*
extern int        NumDailyHLs            = 10;
extern color      ColorDailyHLs          = Gray;
extern color      ColorWeeklyHLs         = Silver;
extern color      ColorMonthlyHLs        = White;
extern string     ColorDailyPivotStd     = "DeepSkyBlue";
extern string     ColorWeeklyPivotStd    = "DodgerBlue";
extern string     ColorMonthlyPivotStd   = "RoyalBlue";
extern string     ColorDailyPivotFibo    = "Lime";
extern string     ColorWeeklyPivotFibo   = "Green";
extern string     ColorMonthlyPivotFibo  = "DarkGreen";
extern string     ColorRoundNumbers      = "Red";
*/
extern int        NumDailyHLs            = 10;
extern color      ColorDailyHLs          = Gray;
extern color      ColorWeeklyHLs         = Silver;
extern color      ColorMonthlyHLs        = White;
extern string     ColorDailyPivotStd     = "";
extern string     ColorWeeklyPivotStd    = "";
extern string     ColorMonthlyPivotStd   = "";
extern string     ColorDailyPivotFibo    = "DodgerBlue";
extern string     ColorWeeklyPivotFibo   = "";
extern string     ColorMonthlyPivotFibo  = "";
extern string     ColorRoundNumbers      = "Red";

extern int        LineLength             = 5;
extern string     RefreshPeriod          = "H1";
extern string     Visibility             = "M1,M5,M15,M30,H1,H4,D1,W1,MN";

string   ccy, sym, IndiName;
int      dig, tf, tmf, obj, vis, RefreshEveryXMins;
double   spr, pnt, tickval, bidp, askp, minlot, lswap, sswap;
datetime prev_time;
bool     FirstTime;

//+------------------------------------------------------------------+
int init()  {
//+------------------------------------------------------------------+
  IndiName = "@CL-";
  IndicatorShortName(IndiName);

  sym     = Symbol();
  ccy     = Symbol();
  tmf     = Period();
  bidp    = MarketInfo(ccy,MODE_BID);
  askp    = MarketInfo(ccy,MODE_ASK);
  pnt     = MarketInfo(ccy,MODE_POINT);
  dig     = MarketInfo(ccy,MODE_DIGITS);
  spr     = MarketInfo(ccy,MODE_SPREAD);
  tickval = MarketInfo(ccy,MODE_TICKVALUE);
  minlot  = MarketInfo(ccy,MODE_MINLOT);
  lswap   = MarketInfo(ccy,MODE_SWAPLONG);
  sswap   = MarketInfo(ccy,MODE_SWAPSHORT);
  if (dig == 3 || dig == 5) {
    pnt     *= 10;
    spr     /= 10;
    tickval *= 10;
  }  
  RefreshEveryXMins = StrToTF(RefreshPeriod);
  prev_time = -9999;
  obj = 0;
  vis = GetVisibility(Visibility);
  del_obj();
  plot_obj();

  return(0);
}

//+------------------------------------------------------------------+
int deinit()  {
//+------------------------------------------------------------------+
  del_obj();
  return(0);
}

//+------------------------------------------------------------------+
int start()  {
//+------------------------------------------------------------------+
  if (RefreshEveryXMins < 0)  {
    if (FirstTime)  {
      del_obj();
      plot_obj();
    }
    FirstTime = false;      
    return(0);
  }  
  if (RefreshEveryXMins == 0) {
    del_obj();
    plot_obj();    
  } else {
    if (prev_time != iTime(sym,RefreshEveryXMins,0))  {
      del_obj();
      plot_obj();
      prev_time = iTime(sym,RefreshEveryXMins,0);
  } }      
  return(0);
}

//+------------------------------------------------------------------+
void del_obj()  {
//+------------------------------------------------------------------+
  int k=0;
  while (k<ObjectsTotal())   {
    string objname = ObjectName(k);
    if (StringSubstr(objname,0,StringLen(IndiName)) == IndiName)  
      ObjectDelete(objname);
    else
      k++;
  }    
  return(0);
}

//+------------------------------------------------------------------+
void plot_line(double price, color clr, int width, int style, int start=0, bool label=false, string desc="")   {
//+------------------------------------------------------------------+
  obj++;
  string objname = IndiName + NumberToStr(obj,"Z4");
  ObjectCreate(objname,OBJ_TREND,0,Time[0]+start*60*Period(),price,Time[0]+(start+LineLength)*60*Period(),price);  
  ObjectSet(objname,OBJPROP_COLOR,clr);
  ObjectSet(objname,OBJPROP_WIDTH,width);
  ObjectSet(objname,OBJPROP_STYLE,style);
  ObjectSet(objname,OBJPROP_RAY,false);
  ObjectSet(objname,OBJPROP_TIMEFRAMES,vis);
  ObjectSetText(objname,desc,8,"Arial",Red);
  if (label)   {
    obj++;
    objname = IndiName + NumberToStr(obj,"Z4");
    ObjectCreate(objname,OBJ_ARROW,0,Time[0]+(start+LineLength+1)*60*Period(),price);  
    ObjectSet(objname,OBJPROP_COLOR,clr);
    ObjectSet(objname,OBJPROP_WIDTH,1);
    ObjectSet(objname,OBJPROP_ARROWCODE,SYMBOL_RIGHTPRICE);
    ObjectSet(objname,OBJPROP_TIMEFRAMES,vis);
  }  
  return(0);
}

//+------------------------------------------------------------------+
void plot_obj()   {
//+------------------------------------------------------------------+
  // Daily, weekly, monthly highs/lows.......
  double close;
  for (int i=1; i<=NumDailyHLs; i++)   {
    double high = iHigh(ccy,StrToTF("D1"),i);
    color col = ColorDailyHLs;
    string descr = "Daily high";
    int   bar = BarConvert(i,"D1","W1");
    if (high == iHigh(ccy,StrToTF("W1"),bar))  {
      col   = ColorWeeklyHLs;
      descr = "Weekly high";
    }  
    bar = BarConvert(i,"D1","MN");
    if (high == iHigh(ccy,StrToTF("MN"),bar))  {
      col   = ColorMonthlyHLs;
      descr = "Weekly high";
    }  
    plot_line(high,col,1,STYLE_SOLID,0,false,descr);

    double low  = iLow(ccy,StrToTF("D1"),i);
    col = ColorDailyHLs;
    descr = "Daily low";
    bar = BarConvert(i,"D1","W1");
    if (low == iLow(ccy,StrToTF("W1"),bar))  {
      col   = ColorWeeklyHLs;
      descr = "Weekly low";
    }
    bar = BarConvert(i,"D1","MN");
    if (low == iLow(ccy,StrToTF("MN"),bar))  {
      col = ColorMonthlyHLs;
      descr = "Monthly low";
    }  
    plot_line(low,col,1,STYLE_SOLID,0,false,descr);
  }  
  
  // Daily pivot: standard.......
  if (ColorDailyPivotStd > "")   {
    col   = StrToColor(ColorDailyPivotStd);
    high  = iHigh(ccy,StrToTF("D1"),1);  
    low   = iLow(ccy,StrToTF("D1"),1);  
    close = iClose(ccy,StrToTF("D1"),1); 
    double PP = (high+low+close)/3;
    double S1 = 2*PP-high;
    double S2 = PP-(high-low);
    double S3 = 2*PP-(2*high-low);
    double R1 = 2*PP-low;
    double R2 = PP+(high-low);
    double R3 = 2*PP+(high-2*low);
    plot_line(PP,col,2,STYLE_SOLID,0,false,"Daily Pivot (std)");
    plot_line(S1,col,1,STYLE_DOT,0,false,"Daily S1 (std)");
    plot_line(S2,col,1,STYLE_DOT,0,false,"Daily S2 (std)");
    plot_line(S3,col,1,STYLE_DOT,0,false,"Daily S3 (std)");
    plot_line(R1,col,1,STYLE_DOT,0,false,"Daily R1 (std)");
    plot_line(R2,col,1,STYLE_DOT,0,false,"Daily R2 (std)");
    plot_line(R3,col,1,STYLE_DOT,0,false,"Daily R3 (std)");
  }
  // Weekly pivot: standard.......
  if (ColorWeeklyPivotStd > "")   {
    col   = StrToColor(ColorWeeklyPivotStd);
    high  = iHigh(ccy,StrToTF("W1"),1);  
    low   = iLow(ccy,StrToTF("W1"),1);  
    close = iClose(ccy,StrToTF("W1"),1); 
    PP    = (high+low+close)/3;
    S1    = 2*PP-high;
    S2    = PP-(high-low);
    S3    = 2*PP-(2*high-low);
    R1    = 2*PP-low;
    R2    = PP+(high-low);
    R3    = 2*PP+(high-2*low);
    plot_line(PP,col,1,STYLE_SOLID,2,false,"Weekly Pivot (std)");
    plot_line(S1,col,1,STYLE_DOT,2,false,"Weekly S1 (std)");
    plot_line(S2,col,1,STYLE_DOT,2,false,"Weekly S2 (std)");
    plot_line(S3,col,1,STYLE_DOT,2,false,"Weekly S3 (std)");
    plot_line(R1,col,1,STYLE_DOT,2,false,"Weekly R1 (std)");
    plot_line(R2,col,1,STYLE_DOT,2,false,"Weekly R2 (std)");
    plot_line(R3,col,1,STYLE_DOT,2,false,"Weekly R3 (std)");
  }
  // Monthly pivot: standard.......
  if (ColorMonthlyPivotStd > "")   {
    col   = StrToColor(ColorMonthlyPivotStd);
    high  = iHigh(ccy,StrToTF("MN"),1);  
    low   = iLow(ccy,StrToTF("MN"),1);  
    close = iClose(ccy,StrToTF("MN"),1); 
    PP    = (high+low+close)/3;
    S1    = 2*PP-high;
    S2    = PP-(high-low);
    S3    = 2*PP-(2*high-low);
    R1    = 2*PP-low;
    R2    = PP+(high-low);
    R3    = 2*PP+(high-2*low);
    plot_line(PP,col,1,STYLE_SOLID,4,false,"Monthly Pivot (std)");
    plot_line(S1,col,1,STYLE_DOT,4,false,"Monthly S1 (std)");
    plot_line(S2,col,1,STYLE_DOT,4,false,"Monthly S2 (std)");
    plot_line(S3,col,1,STYLE_DOT,4,false,"Monthly S3 (std)");
    plot_line(R1,col,1,STYLE_DOT,4,false,"Monthly R1 (std)");
    plot_line(R2,col,1,STYLE_DOT,4,false,"Monthly R2 (std)");
    plot_line(R3,col,1,STYLE_DOT,4,false,"Monthly R3 (std)");
  }
  // Daily pivot: Fibo.......
  if (ColorDailyPivotFibo > "")   {
    col   = StrToColor(ColorDailyPivotFibo);
    high  = iHigh(ccy,StrToTF("D1"),1);  
    low   = iLow(ccy,StrToTF("D1"),1);  
    close = iClose(ccy,StrToTF("D1"),1); 
    PP    = (high+low+close)/3;
    S1    = PP-(high-low)*0.382;
    S2    = PP-(high-low)*0.618;
    S3    = PP-(high-low);
    R1    = PP+(high-low)*0.382;
    R2    = PP+(high-low)*0.618;
    R3    = PP+(high-low);
    plot_line(PP,col,2,STYLE_SOLID,0,false,"Daily Pivot (fibo)");
    plot_line(S1,col,1,STYLE_DOT,0,false,"Daily S1 (fibo)");
    plot_line(S2,col,1,STYLE_DOT,0,false,"Daily S2 (fibo)");
    plot_line(S3,col,1,STYLE_DOT,0,false,"Daily S3 (fibo)");
    plot_line(R1,col,1,STYLE_DOT,0,false,"Daily R1 (fibo)");
    plot_line(R2,col,1,STYLE_DOT,0,false,"Daily R2 (fibo)");
    plot_line(R3,col,1,STYLE_DOT,0,false,"Daily R3 (fibo)");
  }
  // Weekly pivot: Fibo.......
  if (ColorWeeklyPivotFibo > "")   {
    col   = StrToColor(ColorWeeklyPivotFibo);
    high  = iHigh(ccy,StrToTF("W1"),1);  
    low   = iLow(ccy,StrToTF("W1"),1);  
    close = iClose(ccy,StrToTF("W1"),1); 
    PP    = (high+low+close)/3;
    S1    = PP-(high-low)*0.382;
    S2    = PP-(high-low)*0.618;
    S3    = PP-(high-low);
    R1    = PP+(high-low)*0.382;
    R2    = PP+(high-low)*0.618;
    R3    = PP+(high-low);
    plot_line(PP,col,1,STYLE_SOLID,2,false,"Weekly Pivot (fibo)");
    plot_line(S1,col,1,STYLE_DOT,2,false,"Weekly S1 (fibo)");
    plot_line(S2,col,1,STYLE_DOT,2,false,"Weekly S2 (fibo)");
    plot_line(S3,col,1,STYLE_DOT,2,false,"Weekly S3 (fibo)");
    plot_line(R1,col,1,STYLE_DOT,2,false,"Weekly R1 (fibo)");
    plot_line(R2,col,1,STYLE_DOT,2,false,"Weekly R2 (fibo)");
    plot_line(R3,col,1,STYLE_DOT,2,false,"Weekly R3 (fibo)");
  }
  // Monthly pivot: Fibo.......
  if (ColorMonthlyPivotFibo > "")   {
    col   = StrToColor(ColorMonthlyPivotFibo);
    high  = iHigh(ccy,StrToTF("MN"),1);  
    low   = iLow(ccy,StrToTF("MN"),1);  
    close = iClose(ccy,StrToTF("MN"),1); 
    PP    = (high+low+close)/3;
    S1    = PP-(high-low)*0.382;
    S2    = PP-(high-low)*0.618;
    S3    = PP-(high-low);
    R1    = PP+(high-low)*0.382;
    R2    = PP+(high-low)*0.618;
    R3    = PP+(high-low);
    plot_line(PP,col,1,STYLE_SOLID,4,false,"Monthly Pivot (fibo)");
    plot_line(S1,col,1,STYLE_DOT,4,false,"Monthly S1 (fibo)");
    plot_line(S2,col,1,STYLE_DOT,4,false,"Monthly S2 (fibo)");
    plot_line(S3,col,1,STYLE_DOT,4,false,"Monthly S3 (fibo)");
    plot_line(R1,col,1,STYLE_DOT,4,false,"Monthly R1 (fibo)");
    plot_line(R2,col,1,STYLE_DOT,4,false,"Monthly R2 (fibo)");
    plot_line(R3,col,1,STYLE_DOT,4,false,"Monthly R3 (fibo)");
  }
  // Round numbers........
  string mask = "'Price = 'T3.5";
  if (StringFind(Symbol(),"JPY") > 0)    mask = "'Price = 'T4.3";
  if (ColorRoundNumbers > "")   {
    col   = StrToColor(ColorRoundNumbers);
    bool   flag  = false;
//    double start = (WindowPriceMax()+WindowPriceMin())/2;
    double start = Bid;
    double incr  = 50*pnt;
    start = incr*MathInt(start/incr+0.5); 
//    log("---",start,incr);
    for (i=0; flag==false; i++)   {
      high = start+i*incr;
      PP   = (2*incr)*MathInt(high/(2*incr));
//      log("H",i,high,PP);
      if (MathAbs(high-PP)<0.00001) 
        plot_line(high,col,1,STYLE_SOLID,0,true,NumberToStr(high,mask));
      else
        plot_line(high,col,1,STYLE_DOT,0,false,NumberToStr(high,mask));
      if (i==0)   continue;  
      low  = start-i*incr;
      PP   = (2*incr)*MathInt(low/(2*incr));
//      log("L",i,low,PP);
      if (MathAbs(low-PP)<0.00001) 
        plot_line(low,col,1,STYLE_SOLID,0,true,NumberToStr(low,mask));
      else
        plot_line(low,col,1,STYLE_DOT,0,false,NumberToStr(low,mask));
//      if (high>WindowPriceMax() && low<WindowPriceMin())   flag=true;
      if (high>Bid+500*pnt && low<Bid-500*pnt)   flag=true;
  } }
  return(0);
}

#include <hanover --- extensible functions.mqh>

