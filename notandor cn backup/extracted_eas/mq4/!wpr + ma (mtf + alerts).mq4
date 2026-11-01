
//+------------------------------------------------------------------
//| %r 
//+------------------------------------------------------------------
//
//

#property copyright "www,forex-station.com"
#property link      "www,forex-station.com"

#property indicator_separate_window
#property indicator_buffers    2
#property indicator_color1     clrCornflowerBlue
#property indicator_color2     clrRed
#property indicator_style2     STYLE_DOT
#property indicator_levelstyle STYLE_DOT
#property indicator_levelcolor clrGold
#property strict

//
//
//

extern ENUM_TIMEFRAMES TimeFrame       = PERIOD_CURRENT;    // Time frame to use
input int              WprPeriod       = 35;                // Wpr period
enum  enMaTypes
      {        
         ma_sma,                                            // Simple moving average
         ma_ema,                                            // Exponential moving average
         ma_smma,                                           // Smoothed MA
         ma_lwma,                                           // Linear weighted MA
      };
input enMaTypes        MaMethod        = ma_smma;           // Signal moving average type
input int              Signal          = 21;                // Wpr signal MA period
input int              levelOs         = -90;               // Oversold level
input int              levelOb         = -10;               // Overbought level
input int              LineWidth       = 3;                 // Main line width
input bool             alertsOn        = true;              // Alerts true/false?
input bool             alertsOnCurrent = false;             // Alerts open bar true/false?
input bool             alertsMessage   = true;              // Alerts message true/false?
input bool             alertsSound     = true;              // Alerts sound true/false?
input bool             alertsNotify    = false;             // Alerts push notification true/false?
input bool             alertsEmail     = false;             // Alerts email true/false?
input string           soundFile       = "alert2.wav";      // Sound file
input bool             Interpolate     = true;              // Interpolate in multi time frame mode

double wpr[],sig[],cross[],count[];
string indicatorFileName;
#define _mtfCall(_buff,_ind) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,WprPeriod,MaMethod,Signal,levelOs,levelOb,LineWidth,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,_buff,_ind)

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------

int OnInit()
{
    IndicatorBuffers(4);
    SetIndexBuffer(0, wpr,INDICATOR_DATA); SetIndexStyle(0,DRAW_LINE,EMPTY,LineWidth);
    SetIndexBuffer(1, sig,INDICATOR_DATA); SetIndexStyle(1,DRAW_LINE);
    SetIndexBuffer(2, cross);
    SetIndexBuffer(3, count);
    
    SetLevelValue(0,-50);
    SetLevelValue(1,levelOs);
    SetLevelValue(2,levelOb);
    
    indicatorFileName = WindowExpertName();
    TimeFrame         = fmax(TimeFrame,_Period);
    
    IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(TimeFrame)+" Wpr ("+(string)WprPeriod+")");
return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {   }

//
//
//
//
//

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
  
   int i=rates_total-prev_calculated+1; if (i>=rates_total) i=rates_total-1; count[0]=i;
      if (TimeFrame!=_Period)
      {
         i = (int)fmax(i,fmin(rates_total-1,_mtfCall(3,0)*TimeFrame/_Period));
         for (; i>=0 && !_StopFlag; i--)
         {
             int y = iBarShift(NULL,TimeFrame,time[i]);
                wpr[i] = _mtfCall(0,y);
                sig[i] = _mtfCall(1,y);
              
                //
                //
                //
                     
                if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,time[i-1]))) continue;
                  #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
                  int n,k; datetime btime = iTime(NULL,TimeFrame,y);
                     for(n = 1; (i+n)<rates_total && time[i+n] >= btime; n++) continue;	
                     for(k = 1; k<n && (i+n)<rates_total && (i+k)<rates_total; k++) 
                     {
                        _interpolate(wpr); 
                        _interpolate(sig);
                     }                                                                    
         }  
   return(rates_total);
   }
   
   //
   //
   //
   	
   for (; i>=0 && !_StopFlag; i--)
   {
       double hi = high[ArrayMaximum(high,WprPeriod,i)];
       double lo =  low[ArrayMinimum(low, WprPeriod,i)];
        wpr[i] = (hi!=lo) ? -100*(hi-close[i])/(hi-lo) : 0;
        sig[i] =  iCustomMa(MaMethod,wpr[i],Signal,i,rates_total); 
        cross[i] = (i<rates_total-1) ? (wpr[i]>sig[i])  ? 1 : (wpr[i]<sig[i])  ? -1 : cross[i+1] : 0;   
   }
   if (alertsOn)
   {
      int whichBar = (alertsOnCurrent) ? 0 : 1;
      if (cross[whichBar] != cross[whichBar+1])
      {
         if (cross[whichBar] == 1) doAlert(" crossed ma up");
         if (cross[whichBar] ==-1) doAlert(" crossed ma down");       
      }         
    }        
return(rates_total);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------

string getAverageName(int method)
{
      switch(method)
      {
         case ma_ema:    return("EMA");
         case ma_lwma:   return("LWMA");
         case ma_sma:    return("SMA");
         case ma_smma:   return("SMMA");
      }
return("");      
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------

#define _maInstances 1
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances
#define _maWorkBufferx3 3*_maInstances

double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   r = bars-r-1;
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)ceil(length),r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)ceil(length),r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)ceil(length),r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//

double workSma[][_maWorkBufferx1];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo+0] = price;
   double avg = price; int k=1;  for(; k<period && (r-k)>=0; k++) avg += workSma[r-k][instanceNo+0];  
   return(avg/(double)k);
}

//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo] = price;
   if (r>1 && period>1)
          workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
   workLwma[r][instanceNo] = price; if (period<=1) return(price);
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------

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

          message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" Wpr "+doWhat;
             if (alertsMessage) Alert(message);
             if (alertsNotify)  SendNotification(message);
             if (alertsEmail)   SendMail(_Symbol+" Wpr ",message);
             if (alertsSound)   PlaySound(soundFile);
      }
}




