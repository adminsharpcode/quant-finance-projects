/*
https://www.mql5.com/en/forum/179876/page51
// https://forex-station.com/viewtopic.php?p=1295478806#p1295478806
// https://forex-station.com/viewtopic.php?p=1295478883#p1295478883
*/
//+------------------------------------------------------------------+
//|                                       Polychromatic momentum.mq4 |
//|                                                                  |
//| Polychromatic momentum originaly developed                       |
//| by Dennis Meyers                                                 |
//| forex-tsd elite section only                                     |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 0
#import "dynamicZone.dll"
   double dzBuyP(double& sourceArray[],double probabiltyValue, int lookBack, int bars, int i, double precision);
   double dzSellP(double& sourceArray[],double probabiltyValue, int lookBack, int bars, int i, double precision);
#import

//
//
//
//
//

extern string TimeFrame                 = "Current time frame";
extern int    MomentumLength            = 21;
extern ENUM_APPLIED_PRICE    Price      = PRICE_CLOSE;
extern double SmoothLength              = 5;
extern double SmoothPhase               = 0;
extern int    DzLookBackBars            = 35;
extern double DzStartBuyProbability     = 0.05;
extern double DzStartSellProbability    = 0.05;
extern color  ColorUp                   = clrLimeGreen;
extern color  ColorDown                 = clrOrangeRed;
extern string ColorUniqueID             = "DZPolychromaticColorBars";
extern int    ColorWidth                = 5;
extern int    ColorBars                 = 500;
extern int    widthWick                 = 0;
extern int    widthBody                 = 5;
extern bool   drawInBackgound           = false;
extern bool   alertsOn                  = false;                  // Turn alerts on?
extern bool   alertsOnobLineCross       = false;                  // Alert on ob line cross?
extern bool   alertsOnosLineCross       = false;                  // Alerts on os line cross?
extern bool   alertsOnmiLineCross       = false;                  // Alerts on middle line cross?
extern bool   alertsOnCurrent           = false;                  // Alerts on current (still opened) bar?
extern bool   alertsMessage             = false;                  // Alerts should display pop-up message?
extern bool   alertsSound               = false;                  // Alerts should play alert sound?
extern bool   alertsEmail               = false;                  // Alerts should send an email?
extern bool   alertsNotify              = false;                  // Alerts should send push notification?

//Forex-Station button template start41; copy and paste
extern string             button_note1_         = "------------------------------";
extern int                btn_Subwindow         = 0;                               // What window to put the button on.  If <0, the button will use the same sub-window as the indicator.
extern ENUM_BASE_CORNER   btn_corner            = CORNER_LEFT_UPPER;               // button corner on chart for anchoring
extern string             btn_text              = "MOMENTUM";                      // a button name
extern string             btn_Font              = "Arial";                         // button font name
extern int                btn_FontSize          = 9;                               // button font size               
extern color              btn_text_ON_color     = clrLime;                         // ON color when the button is turned on
extern color              btn_text_OFF_color    = clrRed;                          // OFF color when the button is turned off
extern color              btn_background_color  = clrDimGray;                      // background color of the button
extern color              btn_border_color      = clrBlack;                        // border color the button
extern int                button_x              = 100;                             // x coordinate of the button     
extern int                button_y              = 75;                              // y coordinate of the button     
extern int                btn_Width             = 80;                              // button width
extern int                btn_Height            = 20;                              // button height
extern string             button_note2          = "------------------------------";

bool show_data, recalc=false;
string IndicatorObjPrefix, buttonId;
//Forex-Station button template end41; copy and paste
//
//
//
//
//

double obLine[], osLine[], zeroLine[], buffer1[], buffer2[], ratios[], trends[][3];
#define _tob 0
#define _tos 1
#define _tmi 2

string indicatorFileName;
bool   returnBars, calculateValue;
int    timeFrame, window;

//+------------------------------------------------------------------------------------------------------------------+
//Forex-Station button template start42; copy and paste
int OnInit()
{
   IndicatorDigits(Digits);
   IndicatorObjPrefix = "__" + btn_text + "__";
      
   // The leading "_" gives buttonId a *unique* prefix.  Furthermore, prepending the swin is usually unique unless >2+ of THIS indy are displayed in the SAME sub-window. (But, if >2 used, be sure to shift the buttonId position)
   buttonId = "_" + IndicatorObjPrefix + "_BT_";
   if (ObjectFind(buttonId)<0) 
      createButton(buttonId, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize, btn_background_color, btn_border_color, btn_text_ON_color);
   ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);

   OnInit2();

   show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);
   
   if (show_data) ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color); 
   else ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------------------------------------------------------+
void createButton(string buttonID,string buttonText,int width2,int height,string font,int fontSize,color bgColor,color borderColor,color txtColor)
{
      ObjectDelete    (0,buttonID);
      ObjectCreate    (0,buttonID,OBJ_BUTTON,btn_Subwindow,0,0);
      ObjectSetInteger(0,buttonID,OBJPROP_COLOR,txtColor);
      ObjectSetInteger(0,buttonID,OBJPROP_BGCOLOR,bgColor);
      ObjectSetInteger(0,buttonID,OBJPROP_BORDER_COLOR,borderColor);
      ObjectSetInteger(0,buttonID,OBJPROP_BORDER_TYPE,BORDER_RAISED);
      ObjectSetInteger(0,buttonID,OBJPROP_XSIZE,width2);
      ObjectSetInteger(0,buttonID,OBJPROP_YSIZE,height);
      ObjectSetString (0,buttonID,OBJPROP_FONT,font);
      ObjectSetString (0,buttonID,OBJPROP_TEXT,buttonText);
      ObjectSetInteger(0,buttonID,OBJPROP_FONTSIZE,fontSize);
      ObjectSetInteger(0,buttonID,OBJPROP_SELECTABLE,0);
      ObjectSetInteger(0,buttonID,OBJPROP_CORNER,btn_corner);
      ObjectSetInteger(0,buttonID,OBJPROP_HIDDEN,1);
      ObjectSetInteger(0,buttonID,OBJPROP_XDISTANCE,9999);
      ObjectSetInteger(0,buttonID,OBJPROP_YDISTANCE,9999);
      // Upon creation, set the initial state to "true" which is "on", so one will see the indicator by default
      ObjectSetInteger(0, buttonId, OBJPROP_STATE, true);
}
//+------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   // This 'ObjectsDeleteAll' is only needed when any objects *besides* the button are created, but this indicator does not, hence, not needed.
   //ObjectsDeleteAll(0, IndicatorObjPrefix);

   // If just changing a TF', the button need not be deleted, therefore the 'OBJPROP_STATE' is also preserved.
   if(reason != REASON_CHARTCHANGE) ObjectDelete(buttonId);
   deinit2();
}
//+------------------------------------------------------------------------------------------------------------------+
void OnChartEvent(const int id, //don't change anything here
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // If another indy on the same chart has enabled events for create/delete/mouse-move, just skip this events up front because they aren't
   //    needed, AND in the worst case, this indy might cause MT4 to hang!!  Skipping the events seems to help, along with other (major) changes to the code below.
   if(id==CHARTEVENT_OBJECT_CREATE || id==CHARTEVENT_OBJECT_DELETE) return; // This appears to make this indy compatible with other programs that enabled CHART_EVENT_OBJECT_CREATE and/or CHART_EVENT_OBJECT_DELETE
   if(id==CHARTEVENT_MOUSE_MOVE    || id==CHARTEVENT_MOUSE_WHEEL)   return; // If this, or another program, enabled mouse-events, these are not needed below, so skip it unless actually needed. 

   if (id==CHARTEVENT_OBJECT_CLICK && sparam == buttonId)
   {
      show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);
      
      if (show_data)
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color); 
         OnInit2();
         // Is it a problem to call 'start()' ??  Possibly it makes no difference, but now calling "mystart()" instead of "start()"; and "start()" simply runs "mystart()", so should be same as before.
         recalc=true;
         mystart();
      }
      else
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
         deinit2();
      }
   }
}
//Forex-Station button template end42; copy and paste
//+------------------------------------------------------------------------------------------------------------------+
int OnInit2()
{
   if (!IsDllsAllowed())
   {
      Alert("and then attach it to the chart again");
      Alert("Please enable DLL imports in the indicator properties");
      Alert("This indicator needs dlls to work");
      return(INIT_FAILED);
   }
   MomentumLength = MathMax(MomentumLength,1);
     IndicatorBuffers(5);
         SetIndexBuffer(0,obLine); SetIndexStyle(0,DRAW_NONE);
         SetIndexBuffer(1,osLine);
         SetIndexBuffer(2,buffer1);
         SetIndexBuffer(3,buffer2);
         SetIndexBuffer(4,ratios);
   
         //
         //
         //
         //
         //
      
            indicatorFileName = WindowExpertName();
            returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
            calculateValue    = (TimeFrame=="calculateValue"); if (calculateValue) return(0);
            timeFrame         = stringToTimeFrame(TimeFrame);
      
         //
         //
         //
         //
         //

      IndicatorShortName(timeFrameToString(timeFrame)+" ("+MomentumLength+","+DoubleToStr(SmoothLength,2)+")");
   return(0);
}

//
//
//
//
//
//+------------------------------------------------------------------------------------------------------------------+
int deinit2()
{
   int lookForLength = StringLen(ColorUniqueID);
      for (int i=ObjectsTotal()-1; i>=0; i--) 
      {
         string name = ObjectName(i);  if (StringSubstr(name,0,lookForLength) == ColorUniqueID) ObjectDelete(name);
      }
   return(0); 
}
//+------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------------------------------------------------------+
int start() {return(mystart()); }
//+------------------------------------------------------------------------------------------------------------------+
int mystart()
  {
   if (show_data)
      {
   int i,r,counted_bars = IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;

        if(recalc) 
        {
           // If a button goes from off-to-on, everything must be recalculated.  The 'recalc' variable is used as a trigger to do this.
           counted_bars = 0;
           recalc=false;
        }

           int limit=MathMin(Bars-counted_bars,Bars-1);
           if (returnBars) { obLine[0] = MathMin(limit+1,Bars-1); return(0); }

   //
   //
   //
   //
   //

   if (calculateValue || timeFrame == Period())
   {
      int cb = ColorBars; if (ColorBars==0) cb = Bars-1; cb = MathMin(Bars-1,cb);
      if (ArrayRange(trends,0)!=Bars) ArrayResize(trends,Bars); 
      for(i=limit, r=Bars-i-1; i>=0; i--,r++)
      {
         buffer2[i] = iMA(NULL,0,1,0,MODE_SMA,Price,i);
         double sumMom = 0;
         double sumWgh = 0;
         for (int k=0; (i+k)<Bars && k<MomentumLength; k++)
         {
            double weight = MathSqrt(k+1);
                  sumMom += (buffer2[i]-buffer2[i+k+1])/weight;
                  sumWgh += weight;
         }
         if (sumWgh != 0)         
               buffer1[i] = iSmooth(sumMom/sumWgh,SmoothLength,SmoothPhase,i,0);
         else  buffer1[i] = iSmooth(0            ,SmoothLength,SmoothPhase,i,0);
         obLine[i]    = dzBuyP (buffer1, DzStartBuyProbability,  DzLookBackBars, Bars, i, 0.00001);
         osLine[i]    = dzSellP(buffer1, DzStartSellProbability, DzLookBackBars, Bars, i, 0.00001);
         ratios[i]    = -1;
         setTrends(i,r);
            if (cb>=i)
            {
               double ratio = MathMin(buffer1[i],osLine[i]);
                      ratio = MathMax(ratio     ,obLine[i]);
                      if ((osLine[i]-obLine[i]) != 0)
                           ratio = (ratio-obLine[i])/(osLine[i]-obLine[i]);
                     else  ratio = 0; 
                     ratios[i] = ratio;
                        if (!calculateValue)
                        {
                           color barColor = gradientColor(100.0*ratios[i],101,ColorDown,ColorUp);
                              drawBar(Time[i],High[i],Low[i],Open[i],Close[i],barColor,barColor);
                        }
            }                     
      }
      return(0);
   }
   
   //
   //
   //
   //
   //

   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for(i=limit, r=Bars-i-1; i>=0; i--,r++)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         ratios[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",MomentumLength,Price,SmoothLength,SmoothPhase,DzLookBackBars,DzStartBuyProbability,DzStartSellProbability,ColorUp,ColorDown,ColorUniqueID,ColorWidth,ColorBars,widthWick,widthBody,drawInBackgound,alertsOn,alertsOnobLineCross,alertsOnosLineCross,alertsOnmiLineCross,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,4,y);
         barColor  = gradientColor(100.0*ratios[i],101,ColorDown,ColorUp);
            if (ratios[i] != -1) drawBar(Time[i],High[i],Low[i],Open[i],Close[i],barColor,barColor);
            setTrends(i,r);
   }
      } //if (show_data)  
   return(0);
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

double wrk[][10];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iSmooth(double price, double length, double phase, int i, int s=0)
{
   if (length <=1) return(price);
   if (ArrayRange(wrk,0) != Bars) ArrayResize(wrk,Bars);
   
   int r = Bars-i-1; 
      if (r==0) { for(int k=0; k<7; k++) wrk[r][k+s]=price; for(; k<10; k++) wrk[r][k+s]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax+s];
      double del2   = price - wrk[r-1][bsmin+s];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = MathMin(r,10);
	
         wrk[r][volty+s] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty+s] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty+s] = MathAbs(del2); 
         wrk[r][vsum+s] =	wrk[r-1][vsum+s] + (wrk[r][volty+s]-wrk[r-forBar][volty+s])*div;
         
         //
         //
         //
         //
         //
   
         wrk[r][avolty+s] = wrk[r-1][avolty+s]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum+s]-wrk[r-1][avolty+s]);
            if (wrk[r][avolty+s] > 0)
               double dVolty = wrk[r][volty+s]/wrk[r][avolty+s]; else dVolty = 0;   
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax+s] = price; else wrk[r][bsmax+s] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin+s] = price; else wrk[r][bsmin+s] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0+s] = price + alpha*(wrk[r-1][0+s]-price);
         wrk[r][1+s] = (price - wrk[r][0+s])*(1-beta) + beta*wrk[r-1][1+s];
         wrk[r][2+s] = (wrk[r][0+s] + R*wrk[r][1+s]);
         wrk[r][3+s] = (wrk[r][2+s] - wrk[r-1][4+s])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3+s];
         wrk[r][4+s] = (wrk[r-1][4+s] + wrk[r][3+s]); 

   //
   //
   //
   //
   //

   return(wrk[r][4+s]);
}


//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
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

//------------------------------------------------------------------
//
//------------------------------------------------------------------

color gradientColor(int step, int totalSteps, color from, color to)
{
   step = MathMax(MathMin(step,totalSteps-1),0);
      color newBlue  = getColor(step,totalSteps,(from & 0XFF0000)>>16,(to & 0XFF0000)>>16)<<16;
      color newGreen = getColor(step,totalSteps,(from & 0X00FF00)>> 8,(to & 0X00FF00)>> 8) <<8;
      color newRed   = getColor(step,totalSteps,(from & 0X0000FF)    ,(to & 0X0000FF)    )    ;
      return(newBlue+newGreen+newRed);
}
color getColor(int stepNo, int totalSteps, color from, color to)
{
   double step = (from-to)/(totalSteps-1.0);
   return(MathRound(from-step*stepNo));
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------

void drawBar(int bTime, double prHigh, double prLow, double prOpen, double prClose, color barColor, color wickColor)
{
   string oName;
          oName = ColorUniqueID+TimeToStr(bTime)+"w";
            if (ObjectFind(oName) < 0) ObjectCreate(oName,OBJ_TREND,window,bTime,0,bTime,0);
                 ObjectSet(oName, OBJPROP_PRICE1, prHigh);
                 ObjectSet(oName, OBJPROP_PRICE2, prLow);
                 ObjectSet(oName, OBJPROP_COLOR, wickColor);
                 ObjectSet(oName, OBJPROP_WIDTH, widthWick);
                 ObjectSet(oName, OBJPROP_RAY, false);
                 ObjectSet(oName, OBJPROP_BACK, drawInBackgound);
           
         oName = ColorUniqueID+TimeToStr(bTime)+"b";
            if (ObjectFind(oName) < 0)ObjectCreate(oName,OBJ_TREND,window,bTime,0,bTime,0);
                 ObjectSet(oName, OBJPROP_PRICE1, prOpen);
                 ObjectSet(oName, OBJPROP_PRICE2, prClose);
                 ObjectSet(oName, OBJPROP_COLOR, barColor);
                 ObjectSet(oName, OBJPROP_WIDTH, widthBody);
                 ObjectSet(oName, OBJPROP_RAY, false);
                 ObjectSet(oName, OBJPROP_BACK, drawInBackgound);
}

//
//
//

void setTrends(int i, int r)
{
   if (r>0)
   {
      trends[r][_tob] = trends[r-1][_tob];
      trends[r][_tos] = trends[r-1][_tos];
      trends[r][_tmi] = trends[r-1][_tmi];
   
      if (buffer1[i] > obLine[i])   trends[r][_tob] =  1;
      if (buffer1[i] < obLine[i])   trends[r][_tob] = -1;
      if (buffer1[i] > osLine[i])   trends[r][_tos] =  1;
      if (buffer1[i] < osLine[i])   trends[r][_tos] = -1;     
      if (buffer1[i] > zeroLine[i]) trends[r][_tmi] =  1;
      if (buffer1[i] < zeroLine[i]) trends[r][_tmi] = -1;     
   }
}

//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      int whichBar = 1; if (alertsOnCurrent) whichBar = 0; whichBar = Bars-whichBar-1;

      static datetime time1 = 0;
      static string   mess1 = "";
      if (alertsOnobLineCross && trends[whichBar][_tob] != trends[whichBar-1][_tob])
      {
         if (trends[whichBar][_tob] ==  1) doAlert(time1,mess1,whichBar,"Crossing oversold line up");
         if (trends[whichBar][_tob] == -1) doAlert(time1,mess1,whichBar,"Crossing oversold line down");
      }
      
      static datetime time2 = 0;
      static string   mess2 = "";
      if (alertsOnosLineCross && trends[whichBar][_tos] != trends[whichBar-1][_tos])
      {
         if (trends[whichBar][_tos] ==  1) doAlert(time2,mess2,whichBar,"Crossing overbought up");
         if (trends[whichBar][_tos] == -1) doAlert(time2,mess2,whichBar,"Crossing overbought down");
      }   

      static datetime time3 = 0;
      static string   mess3 = "";
      if (alertsOnmiLineCross && trends[whichBar][_tmi] != trends[whichBar-1][_tmi])
      {
         if (trends[whichBar][_tmi] ==  1) doAlert(time3,mess3,whichBar,"Crossing zero line up");
         if (trends[whichBar][_tmi] == -1) doAlert(time3,mess3,whichBar,"Crossing zero line down");
      }   
   }
}

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
       
        message = _Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" "+timeFrameToString(_Period)+" DZ Polychromatic momentum "+doWhat;
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(_Symbol+" DZ Polychromatic momentum ",message);
          if (alertsNotify)  SendNotification(message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

      