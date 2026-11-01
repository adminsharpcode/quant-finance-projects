// https://forex-station.com/viewtopic.php?p=1295478806#p1295478806 //button code1
// https://forex-station.com/viewtopic.php?p=1295478883#p1295478883 //button code2
// https://forex-station.com/viewtopic.php?p=1295401742#p1295401742 //indicator
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"

#property indicator_separate_window
#property indicator_buffers    5
#property indicator_minimum    -100
#property indicator_maximum    0
#property indicator_color1     clrDarkGray // line color
#property indicator_color2     clrNONE // trend; don't need color
#property indicator_color3     clrGray // regular dots color
#property indicator_color4     clrDarkGreen  // overbought dots color
#property indicator_color5     clrRed // oversold dots color
#property indicator_width1     1
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DOT

enum enTimeFrames
{
   tf_cu  = PERIOD_CURRENT, // Current time frame
   tf_m1  = PERIOD_M1,      // 1 minute
   tf_m5  = PERIOD_M5,      // 5 minutes
   tf_m15 = PERIOD_M15,     // 15 minutes
   tf_m30 = PERIOD_M30,     // 30 minutes
   tf_h1  = PERIOD_H1,      // 1 hour
   tf_h4  = PERIOD_H4,      // 4 hours
   tf_d1  = PERIOD_D1,      // Daily
   tf_w1  = PERIOD_W1,      // Weekly
   tf_mn1 = PERIOD_MN1,     // Monthly
   tf_n1  = -1,             // First higher time frame
   tf_n2  = -2,             // Second higher time frame
   tf_n3  = -3,             // Third higher time frame
   tf_n4  = -4              // Fourth higher time frame
};

enTimeFrames    TimeFrame                  = tf_cu;            // Time frame to use
extern int             WPRPeriod                  = 20;
extern int             OversoldLevel              = -80;
extern int             OverboughtLevel            = -20;

extern bool            alertsOn                   = false;
extern bool            alertsOnCurrent            = false;
extern bool            alertsMessage              = false;
extern bool            alertsSound                = false;
extern bool            alertsNotify               = false;
extern bool            alertsEmail                = false;
extern string          soundFile                  = "alert2.wav"; 
extern bool            DrawDottedLine             = false;
extern int             RegularWingdingsDotCode    = 159;
extern int             OversoldWingdingsDotCode   = 164;
extern int             OverboughtWingdingsDotCode = 162;
//Forex-Station button template start41; copy and paste
extern string             button_note1_         = "------------------------------";
extern int                btn_Subwindow         = 1;                               // What window to put the button on.  If <0, the button will use the same sub-window as the indicator.
extern ENUM_BASE_CORNER   btn_corner            = CORNER_LEFT_LOWER;               // button corner on chart for anchoring
extern string             btn_text              = "WPR";                           // a button name
extern string             btn_Font              = "Arial";                         // button font name
extern int                btn_FontSize          = 9;                               // button font size               
extern color              btn_text_ON_color     = clrLime;                         // ON color when the button is turned on
extern color              btn_text_OFF_color    = clrRed;                          // OFF color when the button is turned off
extern color              btn_background_color  = clrDimGray;                      // background color of the button
extern color              btn_border_color      = clrBlack;                        // border color the button
extern int                button_x              = 20;                              // x coordinate of the button     
extern int                button_y              = 25;                              // y coordinate of the button     
extern int                btn_Width             = 80;                              // button width
extern int                btn_Height            = 20;                              // button height
extern string             UniqueButtonID        = "WPRobos";                       // Unique ID for each button        
extern string             button_note2          = "------------------------------";

bool show_data, recalc=false;
string IndicatorObjPrefix, buttonId;
//Forex-Station button template end41; copy and paste

//          WPR[i]   = iCustom(NULL,TimeFrame,indicatorFileName,"calculateValue",WPRPeriod,OversoldLevel,OverboughtLevel,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,DrawDottedLine,RegularWingdingsDotCode,OversoldWingdingsDotCode,OverboughtWingdingsDotCode,0,y);

double WPR[], trend[], DottedLineWPR[], OverboughtWPR[], OversoldWPR[];
string indicatorFileName;
bool   returnBars, calculateValue;
int    timeFrame;
//+------------------------------------------------------------------------------------------------------------------+
//Forex-Station button template start42; copy and paste
int OnInit()
{
   IndicatorDigits(Digits);
   IndicatorObjPrefix = "__" + btn_text + "__";
      
   // The leading "_" gives buttonId a *unique* prefix.  Furthermore, prepending the swin is usually unique unless >2+ of THIS indy are displayed in the SAME sub-window. (But, if >2 used, be sure to shift the buttonId position)
   buttonId = "_" + UniqueButtonID + IndicatorObjPrefix + "_BT_";
   if (ObjectFind(buttonId)<0) 
      createButton(buttonId, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize, btn_background_color, btn_border_color, btn_text_ON_color);
   ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);

   OnInit2();

   show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);
   
   if (show_data) 
      {
        ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color); 
        SetLevelValue(0,OversoldLevel);
        SetLevelValue(1,OverboughtLevel);
      }
   else 
      { 
        ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
        SetLevelValue(0,EMPTY_VALUE);
        SetLevelValue(1,EMPTY_VALUE);
      }
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
   // If just changing a TF', the button need not be deleted, therefore the 'OBJPROP_STATE' is also preserved.
   if(reason != REASON_CHARTCHANGE) ObjectDelete(buttonId);
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
         SetLevelValue(0,OversoldLevel);
         SetLevelValue(1,OverboughtLevel);

         // Is it a problem to call 'start()' ??  Possibly it makes no difference, but now calling "mystart()" instead of "start()"; and "start()" simply runs "mystart()", so should be same as before.
         recalc=true;
         mystart();
      }
      else
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
         for (int ForexStation=0; ForexStation<indicator_buffers; ForexStation++)
              SetIndexStyle(ForexStation,DRAW_NONE);
         SetLevelValue(0,EMPTY_VALUE);
         SetLevelValue(1,EMPTY_VALUE);
      }
   }
}
//Forex-Station button template end42; copy and paste
//+------------------------------------------------------------------------------------------------------------------+
int OnInit2()
{
    IndicatorBuffers(5);
    SetIndexBuffer(0, WPR); 
    SetIndexStyle (0, DRAW_LINE);
    
    SetIndexBuffer(1, trend); 
    if (DrawDottedLine)
       {
        SetIndexBuffer(2, DottedLineWPR); 
        SetIndexStyle (2, DRAW_ARROW);
        SetIndexArrow (2, RegularWingdingsDotCode);

        SetIndexBuffer(3, OverboughtWPR); 
        SetIndexStyle (3, DRAW_ARROW);
        SetIndexArrow (3, OverboughtWingdingsDotCode);

        SetIndexBuffer(4, OversoldWPR); 
        SetIndexStyle (4, DRAW_ARROW);
        SetIndexArrow (4, OversoldWingdingsDotCode);

       }
   
      indicatorFileName = WindowExpertName();
      returnBars        = (TimeFrame == "returnBars");     if (returnBars)     return(0);
      calculateValue    = (TimeFrame == "calculateValue"); if (calculateValue) return(0);

//AHTF Timeframe template copy and paste start13
   TimeFrame         = (enTimeFrames)timeFrameValue(TimeFrame);
//AHTF Timeframe template copy and paste end13
    
   IndicatorShortName(timeFrameToString(TimeFrame)+" Williams %R (" +WPRPeriod+ ")");
 return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
//AHTF Timeframe template copy and paste start14
int timeFrameValue(int _tf)
{
   int add  = (_tf>=0) ? 0 : MathAbs(_tf);
   if (add != 0) _tf = _Period;
   int size = ArraySize(iTfTable); 
      int i =0; for (;i<size; i++) if (iTfTable[i]==_tf) break;
                                   if (i==size) return(_Period);
                                                return(iTfTable[(int)MathMin(i+add,size-1)]);
}
//AHTF Timeframe template copy and paste end14
//+------------------------------------------------------------------------------------------------------------------+
int start() {return(mystart()); }
//+------------------------------------------------------------------------------------------------------------------+
int mystart()
  {
   if (show_data)
      {
        int counted_bars=IndicatorCounted();

        if(recalc) 
        {
           // If a button goes from off-to-on, everything must be recalculated.  The 'recalc' variable is used as a trigger to do this.
           counted_bars = 0;
           recalc=false;
        }

      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { WPR[0] = limit+1; return(0); }
   
   if (calculateValue || TimeFrame == Period())
   {
      for(int i=limit; i>=0; i--)
      {
         double hi   = High[iHighest(NULL,0, MODE_HIGH,WPRPeriod,i)];
         double lo   =  Low[iLowest(NULL, 0,  MODE_LOW,WPRPeriod,i)];
         if (hi!=lo)      
              WPR[i] = -100*(hi-Close[i]) / (hi-lo);
         else WPR[i] = 0;  
         trend[i] = 0;
         OverboughtWPR[i] = EMPTY_VALUE;
         OversoldWPR[i]   = EMPTY_VALUE;
         
         if (DrawDottedLine) 
            {
              DottedLineWPR[i]= WPR[i];
              if (WPR[i]>OverboughtLevel) //-20; red arrows
                 {
                   trend[i] = 1;
                   if (DrawDottedLine) OverboughtWPR[i] = WPR[i];
                   else OverboughtWPR[i] = EMPTY_VALUE;
                 }
              if (WPR[i]<OversoldLevel) //-80; green arrows
                 {
                   trend[i] =-1;        
                   if (DrawDottedLine) OversoldWPR[i] = WPR[i];
                   else OversoldWPR[i] = EMPTY_VALUE;
                 }
            }
      }
      manageAlerts();
    return(0);
    }     
    
    limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,TimeFrame,indicatorFileName,"returnBars",0,0)*TimeFrame/Period()));
    for(i=limit; i>=0; i--)
    {
       int y = iBarShift(NULL,TimeFrame,Time[i]);
//          WPR[i]   = iCustom(NULL,TimeFrame,indicatorFileName,"calculateValue",WPRPeriod,OversoldLevel,OverboughtLevel,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,DrawDottedLine,RegularWingdingsDotCode,OversoldWingdingsDotCode,OverboughtWingdingsDotCode,0,y);
          WPR[i]   = iCustom(NULL,TimeFrame,indicatorFileName,"calculateValue",WPRPeriod,0,y);
//          trend[i] = iCustom(NULL,TimeFrame,indicatorFileName,"calculateValue",WPRPeriod,OversoldLevel,OverboughtLevel,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsNotify,alertsEmail,soundFile,DrawDottedLine,RegularWingdingsDotCode,OversoldWingdingsDotCode,OverboughtWingdingsDotCode,1,y);
          trend[i] = iCustom(NULL,TimeFrame,indicatorFileName,"calculateValue",WPRPeriod,1,y);

         OverboughtWPR[i] = EMPTY_VALUE;
         OversoldWPR[i]   = EMPTY_VALUE;
       if (DrawDottedLine) 
           {
             DottedLineWPR[i]= WPR[i];
             if (WPR[i]>OverboughtLevel) //-20; red arrows
                 OverboughtWPR[i] = WPR[i];
             else OverboughtWPR[i] = EMPTY_VALUE;
             if (WPR[i]<OversoldLevel) //-80; green arrows
                 OversoldWPR[i] = WPR[i];
             else OversoldWPR[i] = EMPTY_VALUE;
           }
   } 
   manageAlerts();  
      } //if (show_data)  
return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,TimeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar+1] ==  1 && trend[whichBar] != 1) doAlert(whichBar,"sell");
         if (trend[whichBar+1] == -1 && trend[whichBar] !=-1) doAlert(whichBar,"buy");
      }         
   }
}   
//+------------------------------------------------------------------------------------------------------------------+
void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       message =  StringConcatenate(Symbol()," ",timeFrameToString(TimeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," WPR ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsNotify)  SendNotification(StringConcatenate(Symbol(), Period() ," WPR " +" "+message));
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," WPR "),message);
          if (alertsSound)   PlaySound(soundFile);
   }
}
//+------------------------------------------------------------------------------------------------------------------+
string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//+------------------------------------------------------------------------------------------------------------------+
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
//+------------------------------------------------------------------------------------------------------------------+

