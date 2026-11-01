//------------------------------------------------------------------
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
#property strict

//
//
//
//
//

input color  PositiveColor     = clrMediumSeaGreen;  // Color for positive values
input color  NegativeColor     = clrPaleVioletRed;   // Color for negative values
input int    CandleShift       = 1;                  // Candle shift
input string TimeFont          = "Arial";
input int    TimeFontSize      = 10;                 // Font size for timer
input bool   DisplayTimeFrame  = true;
input int    TimerShift        = 2;                  // Timer shift
input string clockName         = "CandleTimer";      // Unique ID for the timer

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit() { EventSetMillisecondTimer(250); return(0); }
void OnDeinit(const int reason) { ObjectDelete(clockName); EventKillTimer(); }
void OnTimer( ) {	ShowClock(); }
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void ShowClock()
{
   int periodMinutes = _Period;
   int shift         = periodMinutes*TimerShift*60;
   int currentTime   = (int)TimeCurrent();
   int localTime     = (int)TimeLocal();
   int barTime       = (int)iTime();
   int diff          = (int)MathMax(round((currentTime-localTime)/3600.0)*3600,-24*3600);

   //
   //
   //
   //
   //

      color  theColor;
      string time = "[" + timeFrameToString(_Period)+"] " + getTime(barTime+periodMinutes*60-localTime-diff,theColor);
             time = (TerminalInfoInteger(TERMINAL_CONNECTED)) ? time : time+" x";

      //
      //
      //
      //
      //
                          
      if(ObjectFind(0,clockName) < 0)
         ObjectCreate(0,clockName,OBJ_TEXT,0,barTime+shift,0);
         ObjectSetString(0,clockName,OBJPROP_TEXT,time);
         ObjectSetString(0,clockName,OBJPROP_FONT,TimeFont);
         ObjectSetInteger(0,clockName,OBJPROP_FONTSIZE,TimeFontSize);
         ObjectSetInteger(0,clockName,OBJPROP_COLOR,theColor);
         ObjectSetInteger(0,clockName,OBJPROP_HIDDEN,true);
         if (ChartGetInteger(0,CHART_SHIFT,0)==0 && (shift >=0))
               ObjectSetInteger(0,clockName,OBJPROP_TIME,barTime-shift*3);
         else  ObjectSetInteger(0,clockName,OBJPROP_TIME,barTime+shift+CandleShift*_Period*60);

      //
      //
      //
      //
      //

      double price  = (Bars>0) ? Close[0] : 0;
      double atr    = iATR(NULL,0,10,0);
             price += 3.0*atr/4.0;
             
      //
      //
      //
      //
      //

      bool visible = ((ChartGetInteger(0,CHART_VISIBLE_BARS,0)-ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR,0)) > 0);
      if ( visible && price>=ChartGetDouble(0,CHART_PRICE_MAX,0))
            ObjectSetDouble(0,clockName,OBJPROP_PRICE,price-1.5*atr);
      else  ObjectSetDouble(0,clockName,OBJPROP_PRICE,price);
}


string getTime(int times, color& theColor)
{
   string stime = "";
   int    seconds;
   int    minutes;
   int    hours;
   
   //
   //
   //
   //
   //
   
   if (times < 0) {
         theColor = NegativeColor; times = (int)fabs(times); }
   else  theColor = PositiveColor;
   seconds = (times%60);
   hours   = (times-times%3600)/3600;
   minutes = (times-seconds)/60-hours*60;

   //
   //
   //
   //
   //
   
   if (hours>0)
   if (minutes < 10)
         stime = stime+(string)hours+":0";
   else  stime = stime+(string)hours+":";
         stime = stime+(string)minutes;
   if (seconds < 10)
         stime = stime+":0"+(string)seconds;
   else  stime = stime+":" +(string)seconds;
   return(stime);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

datetime iTime(ENUM_TIMEFRAMES forPeriod=PERIOD_CURRENT)
{
   datetime times[]; if (CopyTime(Symbol(),forPeriod,0,1,times)<=0) return(TimeLocal());
   return(times[0]);
}
//+------------------------------------------------------------------------------------------------------------------+
string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
//+------------------------------------------------------------------------------------------------------------------+
