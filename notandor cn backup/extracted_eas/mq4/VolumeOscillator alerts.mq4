//+------------------------------------------------------------------+
//|                                             VolumeOscillator.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link ""
#property version "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots 1

// Plot oscillator
#property indicator_label1 "oscillator"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrRoyalBlue
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1

// Input parameters
input int       i_shortPeriod   = 20;             // Short period
input int       i_longPeriod    = 60;             // Long period
input bool      alertsOn        = false;           // Alerts on true/false?
input bool      alertsOnCurrent = false;          // Alerts on current (still opened) bar true/false?
input bool      alertsMessage   = true;           // Alerts pop-up message true/false?
input bool      alertsSound     = false;          // Alerts sound true/false?
input bool      alertsNotify    = false;          // Alerts push notification true/false?
input bool      alertsEmail     = false;          // Alerts send email true/false?
input string    soundfile       = "alert2.wav";   // Alert sound file to use.

// Indicator buffers
double oscillatorBuffer[];
double shortBuffer[];
double longBuffer[];
double volumeBuffer[];
double trend[];

// -------------------------------------------------------------------
// Custom indicator initialization function
// -------------------------------------------------------------------
int OnInit()
{
   string shortName = "Volume Oscillator (" + string(i_shortPeriod) + ", " + string(i_longPeriod) + ")";
   
   IndicatorShortName(shortName);
   IndicatorDigits(2);
   IndicatorBuffers(5);
   
   // Check input
   if (i_shortPeriod < 1)
   {
      Print("Incorrect value for input variable i_shortPeriod = " + string(i_shortPeriod));
      return INIT_FAILED;
   }
   
   if (i_longPeriod < 2)
   {
      Print("Incorrect value for input variable i_longPeriod = " + string(i_longPeriod));
      return INIT_FAILED;
   }
   
   // Indicator buffers mapping
   SetIndexBuffer(0, oscillatorBuffer);
   SetIndexStyle(0, indicator_type1, indicator_style1, indicator_width1, indicator_color1);
   SetIndexLabel(0, shortName);
   SetIndexDrawBegin(0, i_longPeriod);
   
   SetIndexBuffer(1, shortBuffer);
   SetIndexBuffer(2, longBuffer);
   SetIndexBuffer(3, volumeBuffer);
   SetIndexBuffer(4, trend);
   
   return INIT_SUCCEEDED;
}

// -------------------------------------------------------------------
// Custom indicator iteration function
// -------------------------------------------------------------------
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
   int countedBars = IndicatorCounted();
   int limit;
   
   // Check for bars count
   if (countedBars < 0 || rates_total < i_longPeriod)
      return -1;
   
   // Prepare buffers
   ArraySetAsSeries(shortBuffer, true);
   ArraySetAsSeries(longBuffer, true);
   ArraySetAsSeries(oscillatorBuffer, true);
   ArraySetAsSeries(volumeBuffer, true);
   ArraySetAsSeries(Volume, true);
   
   // Initialize buffers until first drawn bar
   if (countedBars < 1)
   {
      for (int i = 1; i <= i_longPeriod; i++)
      {
         shortBuffer[i] = 0.0;
         longBuffer[i] = 0.0;
         oscillatorBuffer[i] = 0.0;
         volumeBuffer[i] = 0.0;
      }
      
      //for (int i = 0; i <= rates_total; i++)
      //   volumeBuffer[i] = double(Volume[i]);
   }
   
   // Calculate region (from limit to rates_total).
   limit = Bars - i_longPeriod;
   
   calcVolumeEMA(shortBuffer, i_shortPeriod, rates_total, prev_calculated);
   calcVolumeEMA(longBuffer, i_longPeriod, rates_total, prev_calculated);
   
   for (int i = 0; i < limit && !IsStopped(); i++)
   {
      //shortBuffer[i] = iMAOnArray(volumeBuffer, 0, i_shortPeriod, 0, MODE_EMA, i);
      //longBuffer[i] = iMAOnArray(volumeBuffer, 0, i_longPeriod, 0, MODE_EMA, i);
      oscillatorBuffer[i] = 100 * (shortBuffer[i] - longBuffer[i]) / longBuffer[i];
      trend[i] = (i<rates_total-1) ? (oscillatorBuffer[i]>0) ? 1 : (oscillatorBuffer[i]<0) ? -1 : trend[i+1] : 0;  
   }
   if (alertsOn)
   {
      int whichBar = (alertsOnCurrent) ? 0 : 1;
      static datetime time1 = 0;
      static string   mess1 = "";
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] ==  1) doAlert(time1,mess1,whichBar,"crossed zero up");
         if (trend[whichBar] == -1) doAlert(time1,mess1,whichBar,"crossed zero down");
      }
   }
return rates_total;
}

// -------------------------------------------------------------------
// Calc volume EMA
// -------------------------------------------------------------------
void calcVolumeEMA(double& buffer[], int period, int rates_total, int prev_calculated)
{
   int limit;
   
   double firstValue;
   double smoothFactor = 2.0 / (period + 1.0);
   
   ArraySetAsSeries(buffer, false);
   ArraySetAsSeries(Volume, false);
   
   // First calculation or number of bars was changed
   if (prev_calculated <= 0)
   {
      limit = period;
      firstValue = double(Volume[0]);
      buffer[0] = 0.0;
      
      for (int i = 1; i <= limit; i++)
      {
         firstValue += double(Volume[i]);
         buffer[i] = 0.0;
      }
      
      firstValue /= period;
      buffer[limit] = firstValue;
   }
   else
      limit = prev_calculated - 1;
   
   // Main calculation
   for (int i = limit; i < rates_total && !IsStopped(); i++)
      buffer[i] = (Volume[i] - buffer[i - 1]) * smoothFactor + buffer[i - 1];
      
   ArraySetAsSeries(buffer, true);
   ArraySetAsSeries(Volume, true);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

void doAlert(datetime& previousTime, string& previousAlert, int forBar, string doWhat)
{
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message = timeFrameToString(_Period)+" - "+_Symbol+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" VolumeOscillator "+doWhat;
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," VolumeOscillator "),message);
          if (alertsSound)   PlaySound(soundfile);
   }
}

//
//
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



