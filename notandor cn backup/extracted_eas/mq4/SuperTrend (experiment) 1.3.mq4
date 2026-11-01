//------------------------------------------------------------------
#property copyright "Copyright 2016, mladen - MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1 clrSilver
#property indicator_color2 clrSilver
#property indicator_color3 clrLimeGreen
#property indicator_color4 clrOrange
#property indicator_color5 clrOrange
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 2
#property indicator_style1 STYLE_DOT
#property indicator_style2 STYLE_DOT
#property strict

enum enCalcType
{
   st_atr, // Use atr
   st_std, // Use standard deviation 
   st_ste, // Use standard error
   st_sam, // Custom strandard deviation - with sample correction
   st_nos  // Custom strandard deviation - without sample correction
   
};
extern ENUM_TIMEFRAMES TimeFrame  = PERIOD_CURRENT;  // Time frame to use
extern int        period          = 66;              // Super trend period
extern double     multiplier      = 2.236;           // Super trend multiplier
extern int        midPricePeriod  = 10;              // Mid price period (1 for original super trend)
extern enCalcType Type            = st_atr;          // Calculate using?
extern bool       alertsOn        = false;           // Turn alerts on?
extern bool       alertsOnCurrent = false;           // Alerts on still opened bar?
extern bool       alertsMessage   = false;            // Alerts should display message?
extern bool       alertsSound     = false;           // Alerts should play a sound?
extern bool       alertsNotify    = false;           // Alerts should send a notification?
extern bool       alertsEmail     = false;           // Alerts should send an email?
extern string     soundFile       = "alert2.wav";    // Sound file
extern bool       Interpolate     = false;            // Interpolate in multi time frame mode?

double Trend[],TrendDoA[],TrendDoB[],Direction[],Up[],Dn[];
string indicatorFileName;
bool   returnBars;

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   IndicatorBuffers(6);
      SetIndexBuffer(0, Up);
      SetIndexBuffer(1, Dn);
      SetIndexBuffer(2, Trend);
      SetIndexBuffer(3, TrendDoA);
      SetIndexBuffer(4, TrendDoB);
      SetIndexBuffer(5, Direction);
            indicatorFileName = WindowExpertName();
            returnBars        = TimeFrame==-99;
            TimeFrame         = MathMax(TimeFrame,_Period);
   IndicatorShortName("SuperTrend");
   return(0);
}
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   int counted_bars = prev_calculated;
      if(counted_bars < 0) return(-1);
      if(counted_bars > 0) counted_bars--;
         int limit=MathMin(rates_total-counted_bars,rates_total-1);
         if (TimeFrame != _Period) 
         {
            limit = (int)MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,-99,0,0)*TimeFrame/Period()));
            if (Direction[limit] <= 0) CleanPoint(limit,TrendDoA,TrendDoB);
            for(int i=limit; i>=0; i--)
            {
               int y = iBarShift(NULL,TimeFrame,Time[i]);
                  Up[i]        = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,period,multiplier,midPricePeriod,Type,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,0,y);
                  Dn[i]        = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,period,multiplier,midPricePeriod,Type,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,1,y);
                  Trend[i]     = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,period,multiplier,midPricePeriod,Type,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,2,y);
                  Direction[i] = iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,period,multiplier,midPricePeriod,Type,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,5,y);
                  TrendDoA[i]  = EMPTY_VALUE;
                  TrendDoB[i]  = EMPTY_VALUE;
            
                  //
                  //
                  //
                  //
                  //
      
                  if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                     int n,k; datetime ctime = iTime(NULL,TimeFrame,y);
                        for(n = 1; i+n < Bars && Time[i+n] >= ctime; n++) continue;	
                        for(k = 1; i+n < Bars && i+k < Bars && k<n; k++)
                        {
                           Up[i+k]    = Up[i]    + (Up[i+n]   -Up[i]   )*k/n;
                           Dn[i+k]    = Dn[i]    + (Dn[i+n]   -Dn[i]   )*k/n;
                           Trend[i+k] = Trend[i] + (Trend[i+n]-Trend[i])*k/n;
                        }               
               }
               for (int i=limit;i>=0;i--) if (Direction[i]<0) PlotPoint(i,TrendDoA,TrendDoB,Trend);
               return(0);
            }

   //
   //
   //
   //
   //

   if (Direction[limit] <= 0) CleanPoint(limit,TrendDoA,TrendDoB);
   for(int i=limit; i >= 0; i--)
   {
      double val=0;
         switch (Type)
         {
            case st_atr : val = iATR(NULL,0,period,i);                           break;
            case st_std : val = iStdDev(NULL,0,period,0,MODE_SMA,PRICE_CLOSE,i); break;
            case st_ste : val = iStdError(close[i],period,i);                    break;
            default :     val = iDeviation(close[i],period,Type==st_sam,i);
         }            
      double cprice =  close[i];
      double mprice = (high[ArrayMaximum(high,midPricePeriod,i)]+low[ArrayMinimum(low,midPricePeriod,i)])/2;
              Up[i] = mprice+multiplier*val;
              Dn[i] = mprice-multiplier*val;
         
         //
         //
         //
         //
         //
         
         Direction[i] = (i<rates_total-1) ? (cprice > Up[i+1]) ? 1 : (cprice < Dn[i+1]) ? -1 : Direction[i+1] : 0;
         TrendDoA[i]  = EMPTY_VALUE;
         TrendDoB[i]  = EMPTY_VALUE;
            if (Direction[i] ==  1) { Dn[i] = MathMax(Dn[i],Dn[i+1]); Up[i] = MathMax(Up[i],Up[i+1]); Trend[i] = Dn[i]; }
            if (Direction[i] == -1) { Up[i] = MathMin(Up[i],Up[i+1]); Dn[i] = MathMin(Dn[i],Dn[i+1]); Trend[i] = Up[i]; PlotPoint(i,TrendDoA,TrendDoB,Trend); }
   }
   //
   //
   //
   //
   //
      
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0; 
      if (Direction[whichBar] != Direction[whichBar+1])
      {
         if (Direction[whichBar] == 1) doAlert(" up");
         if (Direction[whichBar] ==-1) doAlert(" down");       
      }         
   }              
   return(rates_total);
}


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
// 
//
//
//
//

#define _devInstances 1
double workDev[][_devInstances];
double iDeviation(double value, int length, bool isSample, int i, int instanceNo=0)
{
   if (ArrayRange(workDev,0)!=Bars) ArrayResize(workDev,Bars); i=Bars-i-1; workDev[i][instanceNo] = value;
                 
   //
   //
   //
   //
   //
   
      double oldMean   = value;
      double newMean   = value;
      double squares   = 0; int k;
      for (k=1; k<length && (i-k)>=0; k++)
      {
         newMean  = (workDev[i-k][instanceNo]-oldMean)/(k+1)+oldMean;
         squares += (workDev[i-k][instanceNo]-oldMean)*(workDev[i-k][instanceNo]-newMean);
         oldMean  = newMean;
      }
      return(MathSqrt(squares/MathMax(k-isSample,1)));
}

//
//
//
//
//

double workErr[][_devInstances];
double iStdError(double value, int length,int i, int instanceNo=0)
{
   if (ArrayRange(workErr,0)!=Bars) ArrayResize(workErr,Bars); i = Bars-i-1; workErr[i][instanceNo] = value;
                        
      //
      //
      //
      //
      //
                              
      double avgY     = workErr[i][instanceNo]; int j; for (j=1; j<length && (i-j)>=0; j++) avgY += workErr[i-j][instanceNo]; avgY /= j;
      double avgX     = length * (length-1) * 0.5 / length;
      double sumDxSqr = 0.00;
      double sumDySqr = 0.00;
      double sumDxDy  = 0.00;
   
      for (int k=0; k<length && (i-k)>=0; k++)
      {
         double dx = k-avgX;
         double dy = workErr[i-k][instanceNo]-avgY;
            sumDxSqr += (dx*dx);
            sumDySqr += (dy*dy);
            sumDxDy  += (dx*dy);
      }
      double err2 = (sumDySqr-(sumDxDy*sumDxDy)/sumDxSqr)/(length-2); 
      
   //
   //
   //
   //
   //
         
   if (err2 > 0)
         return(MathSqrt(err2));
   else  return(0.00);       
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void doAlert(string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
      if (previousAlert != doWhat || previousTime != Time[0]) {
          previousAlert  = doWhat;
          previousTime   = Time[0];

          //
          //
          //
          //
          //

          message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" super trend state changed to "+doWhat;
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(_Symbol+" super trend ",message);
             if (alertsSound)   PlaySound(soundFile);
      }
}

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if (i>Bars-2) return;
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (i>Bars-3) return;
   if (first[i+1] == EMPTY_VALUE)
         if (first[i+2] == EMPTY_VALUE) 
               { first[i]  = from[i]; first[i+1]  = from[i+1]; second[i] = EMPTY_VALUE; }
         else  { second[i] = from[i]; second[i+1] = from[i+1]; first[i]  = EMPTY_VALUE; }
   else        { first[i]  = from[i];                          second[i] = EMPTY_VALUE; }
}