//+------------------------------------------------------------------+
//|                                                        Aroon.mq4 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "www.forex-tsd.com"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  LightSeaGreen
#property indicator_color2  Red
#property indicator_level1 70
#property indicator_level2 50
#property indicator_level3 30
#property indicator_levelcolor DimGray

extern int  AroonPeriod       = 14;
extern bool alertsOn          = false;
extern bool alertsOnCurrent   = false;
extern bool alertsMessage     = false;
extern bool alertsPushNotif   = false;
extern bool alertsSound       = false;
extern bool alertsEmail       = false;

//
//

double buffer1[];
double buffer2[];
double trend1[];
double trend2[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


int init()
{
   IndicatorBuffers(4);
   SetIndexBuffer(0,buffer1); SetIndexLabel(0,"Aroon Up");
   SetIndexBuffer(1,buffer2); SetIndexLabel(1,"Aroon Down");
   SetIndexBuffer(2,trend1);
   SetIndexBuffer(3,trend2);
   IndicatorShortName("Aroon ("+AroonPeriod+")");
   return(0);
}

//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;
   
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=Bars-counted_bars;
  
   for(i=limit; i>=0; i--)
   {
      buffer1[i] = 100.0*(AroonPeriod-iHighest(NULL,0,MODE_HIGH,AroonPeriod+1,i)+i)/AroonPeriod;
      buffer2[i] = 100.0*(AroonPeriod- iLowest(NULL,0,MODE_LOW ,AroonPeriod+1,i)+i)/AroonPeriod;
      trend1[i] = trend1[i+1];
      trend2[i] = trend2[i+1];
         if (buffer1[i]>50) trend1[i] =  1;
         if (buffer1[i]<50) trend1[i] = -1;
         if (buffer2[i]>50) trend2[i] =  1;
         if (buffer2[i]<50) trend2[i] = -1;
   }
   manageAlerts();
   return(0);
}

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1;
      
      //
      //
      //
      //
      //
      
      static string   alertType1 = "";
      static datetime alertTime1 = 0;
      if (trend1[whichBar] != trend1[whichBar+1])
      {
         if (trend1[whichBar] ==  1) doAlert(alertType1,alertTime1,"Aroon up crossed level 50 up");
         if (trend1[whichBar] == -1) doAlert(alertType1,alertTime1,"Aroon up crossed level 50 down");
      }
      static string   alertType2 = "";
      static datetime alertTime2 = 0;
      if (trend2[whichBar] != trend2[whichBar+1])
      {
         if (trend2[whichBar] ==  1) doAlert(alertType2,alertTime2,"Aroon down crossed level 50 up");
         if (trend2[whichBar] == -1) doAlert(alertType2,alertTime2,"Aroon down crossed level 50 down");
      }
   }
}

//
//
//
//
//

void doAlert(string& previousAlert, datetime& previousTime, string doWhat)
{
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[0]) {
       previousAlert  = doWhat;
       previousTime   = Time[0];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS),"  ",doWhat);
          if (alertsMessage)   Alert(message);
          if (alertsEmail)     SendMail(StringConcatenate(Symbol(),"Aroon"),message);
          if (alertsPushNotif) SendNotification(StringConcatenate(Symbol(),"Aroon "+message));
          if (alertsSound)     PlaySound("alert2.wav");
   }
}

