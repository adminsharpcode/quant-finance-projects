//+------------------------------------------------------------------+
//|                                        Custom Moving Average.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Gray
//---- indicator parameters
extern string TimeFrame="";
extern int  ExtDepth=12;
extern int  ExtDeviation=5;
extern int  ExtBackstep=3;
extern bool ShowZigZag=False;

extern bool   alertsOn        = false;
extern bool   alertsOnCurrent = true;
extern bool   alertsMessage   = true;
extern bool   alertsSound     = false;
extern bool   alertsEmail     = false;
//---- indicator buffers
double ExtMapBuffer[];
double ExtMapBuffer2[];
double ExtMapBufferU[];
double ExtMapBufferD[];
double trend[];

int    timeFrame;
string indicatorFileName;
bool   calculateValue;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   IndicatorBuffers(5);
   SetIndexBuffer(0,ExtMapBufferU); SetIndexStyle(0,DRAW_ARROW); SetIndexArrow(0,159);
   SetIndexBuffer(1,ExtMapBufferD); SetIndexStyle(1,DRAW_ARROW); SetIndexArrow(1,159);
   SetIndexBuffer(2,ExtMapBuffer);
   if(ShowZigZag)
         SetIndexStyle(2,DRAW_SECTION);
   else  SetIndexStyle(2,DRAW_NONE);
   SetIndexBuffer(3,ExtMapBuffer2);
   SetIndexBuffer(4,trend);
   SetIndexEmptyValue(0,0.0);
   SetIndexEmptyValue(1,0.0);
   SetIndexEmptyValue(2,0.0);
      indicatorFileName = WindowExpertName();
      calculateValue    = (TimeFrame=="calculateValue"); if (calculateValue) return(0);
      timeFrame         = stringToTimeFrame(TimeFrame);
   
   IndicatorShortName("ZigZag("+ExtDepth+","+ExtDeviation+","+ExtBackstep+")");
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   int    shift, back,lasthighpos,lastlowpos;
   double val,res;
   double curlow,curhigh,lasthigh,lastlow;

   if (calculateValue || timeFrame==Period())
   {
   for(shift=Bars-ExtDepth; shift>=0; shift--)
     {
      ExtMapBufferU[shift]=0;
      ExtMapBufferD[shift]=0;
      val=Low[Lowest(NULL,0,MODE_LOW,ExtDepth,shift)];
      if(val==lastlow) val=0.0;
      else 
        { 
         lastlow=val; 
         if((Low[shift]-val)>(ExtDeviation*Point)) val=0.0;
         else
           {
            for(back=1; back<=ExtBackstep; back++)
              {
               res=ExtMapBuffer[shift+back];
               if((res!=0)&&(res>val)) ExtMapBuffer[shift+back]=0.0; 
              }
           }
        } 
      ExtMapBuffer[shift]=val;
      //--- high
      val=High[Highest(NULL,0,MODE_HIGH,ExtDepth,shift)];
      if(val==lasthigh) val=0.0;
      else 
        {
         lasthigh=val;
         if((val-High[shift])>(ExtDeviation*Point)) val=0.0;
         else
           {
            for(back=1; back<=ExtBackstep; back++)
              {
               res=ExtMapBuffer2[shift+back];
               if((res!=0)&&(res<val)) ExtMapBuffer2[shift+back]=0.0; 
              } 
           }
        }
      ExtMapBuffer2[shift]=val;
     }

   // final cutting 
   lasthigh=-1; lasthighpos=-1;
   lastlow=-1;  lastlowpos=-1;

   for(shift=Bars-ExtDepth; shift>=0; shift--)
     {
      curlow=ExtMapBuffer[shift];
      curhigh=ExtMapBuffer2[shift];
      if((curlow==0)&&(curhigh==0)) continue;
      //---
      if(curhigh!=0)
        {
         if(lasthigh>0) 
           {
            if(lasthigh<curhigh) ExtMapBuffer2[lasthighpos]=0;
            else ExtMapBuffer2[shift]=0;
           }
         //---
         if(lasthigh<curhigh || lasthigh<0)
           {
            lasthigh=curhigh;
            lasthighpos=shift;
           }
         lastlow=-1;
        }
      //----
      if(curlow!=0)
        {
         if(lastlow>0)
           {
            if(lastlow>curlow) ExtMapBuffer[lastlowpos]=0;
            else ExtMapBuffer[shift]=0;
           }
         //---
         if((curlow<lastlow)||(lastlow<0))
           {
            lastlow=curlow;
            lastlowpos=shift;
           } 
         lasthigh=-1;
        }
     }
  
   double prevPeak=0;
   for(shift=Bars-1; shift>=0; shift--)
   {
      if(shift>=Bars-ExtDepth)
      {
         ExtMapBuffer[shift] =0.0;
         ExtMapBufferU[shift]=0.0;
         ExtMapBufferD[shift]=0.0;
      }            
      else
      {
         res=ExtMapBuffer2[shift];
         if(res!=0.0) ExtMapBuffer[shift] =res;
      }
      res=ExtMapBuffer[shift];
      trend[shift] = 0;
      ExtMapBufferU[shift]=ExtMapBufferU[shift+1];
      ExtMapBufferD[shift]=ExtMapBufferD[shift+1];
      if(res!=0.0) 
      {
        if(res>prevPeak && prevPeak!=0) trend[shift] = 1; 
        if(res<prevPeak && prevPeak!=0) trend[shift] =-1; 
        if (trend[shift] == 1) ExtMapBufferU[shift]=res;
        if (trend[shift] ==-1) ExtMapBufferD[shift]=res; 
        prevPeak = res;
      }                   
  }
  manageAlerts();
  return(0);
  }

   //
   //
   //
   //
   //
   
   for(shift=Bars-1; shift>=0; shift--)
   {
      int y = iBarShift(NULL,timeFrame,Time[shift]);
      int x = iBarShift(NULL,timeFrame,Time[shift+1]);
         ExtMapBufferU[shift] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",ExtDepth,ExtDeviation,ExtBackstep,0,y);
         ExtMapBufferD[shift] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",ExtDepth,ExtDeviation,ExtBackstep,1,y);
         trend[shift]         = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",ExtDepth,ExtDeviation,ExtBackstep,4,y);
         ExtMapBuffer[shift]  = 0;
         if (x!=y) ExtMapBuffer[shift] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",ExtDepth,ExtDeviation,ExtBackstep,2,y);
   } 
   manageAlerts();  
   return(0);

}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string stringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int tchar = StringGetChar(s, length);
         if((tchar > 96 && tchar < 123) || (tchar > 223 && tchar < 256))
                     s = StringSetChar(s, length, tchar - 32);
         else if(tchar > -33 && tchar < 0)
                     s = StringSetChar(s, length, tchar + 224);
   }
   return(s);
}
               
//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] ==  1) doAlert(whichBar,"Resistance");
         if (trend[whichBar] == -1) doAlert(whichBar,"Support");
      }
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," - ",timeFrameToString(timeFrame)+" zigzagtriad changed to ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," zigzagtriad "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

