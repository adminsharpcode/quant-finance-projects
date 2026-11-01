/*
 ____        _ _                   
|  _ \  __ _(_) |_   _             
| | | |/ _` | | | | | |            
| |_| | (_| | | | |_| |            
|____/ \__,_|_|_|\__, |            
__        __     |___/    _ _      
\ \      / /__   ___   __| (_) ___ 
 \ \ /\ / / _ \ / _ \ / _` | |/ _ \
  \ V  V / (_) | (_) | (_| | |  __/
 __\_/\_/ \___/ \___/ \__,_|_|\___|
|  _ \(_)_   _____ | |_            
| |_) | \ \ / / _ \| __|           
|  __/| |\ V / (_) | |_            
|_|   |_| \_/ \___/ \__|           
*/
//+------------------------------------------------------------------+
//|                                             DailyWoodiePivot.mq4 |
//+------------------------------------------------------------------+
// https://forex-station.com/post1295563149.html#p1295563149 this indicator

#property copyright "c. 2011, Sheker"
#property link      "pippingshek.blogspot.com"
#property description "Here's a breakdown of the Woodie's pivot point formula: "
#property description "Pivot Point (PP): (High + Low + 2 * Close) / 4"
#property description "Resistance 1 (R1): (2 * PP) - Low"
#property description "Resistance 2 (R2): PP + (High - Low)"
#property description "Resistance 3 (R3): High + 2 * (PP - Low)"
#property description "Support 1 (S1): (2 * PP) - High"
#property description "Support 2 (S2): PP - (High - Low)"
#property description "Support 3 (S3): Low - 2 * (High - PP)"

#property indicator_chart_window
//#property indicator_separate_window
#property indicator_buffers 7
#property indicator_color1 clrGoldenrod
#property indicator_color2 clrDarkBlue
#property indicator_color3 clrBrown
#property indicator_color4 clrDarkBlue
#property indicator_color5 clrBrown
#property indicator_color6 clrGreen
#property indicator_color7 clrGreen

#property indicator_width1 3
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 2
#property indicator_width6 2
#property indicator_width7 2

//---- input parameters
extern int                FontSize              = 10;
extern string             FontName              = "Arial";
extern color              TextColor             = clrRed;

//Forex-Station button template start41; copy and paste
extern string             button_note1          = "(===||:::::::::::::::::::::::::::::::::>"; // (===||:::::::::::::::::::::::::>
extern int                btn_Subwindow         = 0;                               // What window to put the button on.  If <0, the button will use the same sub-window as the indicator.
extern ENUM_BASE_CORNER   btn_corner            = CORNER_LEFT_UPPER;               // button corner on chart for anchoring
extern string             btn_text              = "PIVOT";                         // a button name
extern string             btn_Font              = "Arial";                         // button font name
extern int                btn_FontSize          = 9;                               // button font size               
extern color              btn_text_ON_color     = clrLime;                         // ON color when the button is turned on
extern color              btn_text_OFF_color    = clrRed;                          // OFF color when the button is turned off
extern color              btn_background_color  = clrDimGray;                      // background color of the button
extern color              btn_border_color      = clrBlack;                        // border color the button
extern int                button_x              = 100;                             // x coordinate of the button     
extern int                button_y              = 115;                             // y coordinate of the button     
extern int                btn_Width             = 80;                              // button width
extern int                btn_Height            = 20;                              // button height
extern string             UniqueButtonID        = "PivotBT";                       // Unique ID for each button        
extern string             button_note2          = "(===||:::::::::::::::::::::::::::::::::>"; // (===||:::::::::::::::::::::::::>

bool show_data, recalc=false;
string IndicatorObjPrefix, buttonId;
//Forex-Station button template end41; copy and paste

//---- buffers
double PBuffer[], S1Buffer[], R1Buffer[], S2Buffer[], R2Buffer[], S3Buffer[], R3Buffer[], P,S1,R1,S2,R2,S3,R3,LastHigh,LastLow,x;
string Pivot="WPP",Sup1="S 1", Res1="R 1", Sup2="S 2", Res2="R 2", Sup3="S 3", Res3="R 3";
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

   init2();
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
         // Is it a problem to call 'start()' ??  Possibly it makes no difference, but now calling "mystart()" instead of "start()"; and "start()" simply runs "mystart()", so should be same as before.
         recalc=true;
         init2();
         mystart();
      }
      else
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
         for (int Forex=0; Forex<indicator_buffers; Forex++)
              SetIndexStyle(Forex,DRAW_NONE);
         deinit2();  
      }
   }
}
//Forex-Station button template end42; copy and paste
//+------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit2()
  {
//---- TODO: add your code here

   ObjectDelete("WPP");
   ObjectDelete("Sup1");
   ObjectDelete("Res1");
   ObjectDelete("Sup2");
   ObjectDelete("Res2");
   ObjectDelete("Sup3");
   ObjectDelete("Res3");   

//----
   return(0);
  }
//+------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init2()
  {
   string short_name;


//---- indicator line
   SetIndexStyle(0,DRAW_LINE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexStyle(4,DRAW_LINE);
   SetIndexStyle(5,DRAW_LINE);
   SetIndexStyle(6,DRAW_LINE);
   SetIndexBuffer(0,PBuffer);  SetIndexLabel (0, "Woodie Pivot");
   SetIndexBuffer(1,S1Buffer); SetIndexLabel (1, "Support 1");
   SetIndexBuffer(2,R1Buffer); SetIndexLabel (2, "Resistance 1");
   SetIndexBuffer(3,S2Buffer); SetIndexLabel (3, "Support 2");
   SetIndexBuffer(4,R2Buffer); SetIndexLabel (4, "Resistance 2");
   SetIndexBuffer(5,S3Buffer); SetIndexLabel (5, "Support 3");
   SetIndexBuffer(6,R3Buffer); SetIndexLabel (6, "Resistance 3");


//---- name for DataWindow and indicator subwindow label
   short_name="WPP";
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);

//----
   SetIndexDrawBegin(0,1);
//----
 

//----
   return(0);
  }
//+------------------------------------------------------------------------------------------------------------------+
int start() {return(mystart()); }
//+------------------------------------------------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int mystart()
  {
   int limit,i,counted_bars=IndicatorCounted();
   if (show_data)
      {
        if(recalc) 
        {
           // If a button goes from off-to-on, everything must be recalculated.  The 'recalc' variable is used as a trigger to do this.
           counted_bars = 0;
           recalc=false;
        }

//---- indicator calculation
if (counted_bars==0)
{
   x=Period();
   if (x>240) return(-1);
   ObjectCreate("WPP", OBJ_TEXT, 0, 0,0);
   ObjectSetText("WPP", "                 WPP",FontSize,FontName,TextColor);
   ObjectCreate("Sup1", OBJ_TEXT, 0, 0, 0);
   ObjectSetText("Sup1", "      S 1",FontSize,FontName,TextColor);
   ObjectCreate("Res1", OBJ_TEXT, 0, 0, 0);
   ObjectSetText("Res1", "      R 1",FontSize,FontName,TextColor);
   ObjectCreate("Sup2", OBJ_TEXT, 0, 0, 0);
   ObjectSetText("Sup2", "      S 2",FontSize,FontName,TextColor);
   ObjectCreate("Res2", OBJ_TEXT, 0, 0, 0);
   ObjectSetText("Res2", "      R 2",FontSize,FontName,TextColor);
   ObjectCreate("Sup3", OBJ_TEXT, 0, 0, 0);
   ObjectSetText("Sup3", "      S 3",FontSize,FontName,TextColor);
   ObjectCreate("Res3", OBJ_TEXT, 0, 0, 0);
   ObjectSetText("Res3", "      R 3",FontSize,FontName,TextColor);
}
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   limit=(Bars-counted_bars)-1;

for (i=limit; i>=0;i--) {
if (TimeDayOfWeek(Time[i+1])!=0){ // This if fix mondays.

if (High[i+1]>LastHigh) LastHigh=High[i+1];
if (Low[i+1]<LastLow) LastLow=Low[i+1];

if (TimeDay(Time[i])!= TimeDay(Time[i+1]))
   {

   P=(LastHigh+LastLow+2*Open[i])/4;
          R1=(2*P)-LastLow;
          S1=(2*P)-LastHigh;
          R2=P + R1 - S1;
          S2=P + S1 - R1;
          R3=R2 + (R1 - P);
          S3= S2 - (P - S1); 
   LastLow=Open[i]; LastHigh=Open[i];

   ObjectMove("WPP", 0, Time[i],P);
   ObjectMove("Sup1", 0, Time[i],S1);
   ObjectMove("Res1", 0, Time[i],R1);
   ObjectMove("Sup2", 0, Time[i],S2);
   ObjectMove("Res2", 0, Time[i],R2);
   ObjectMove("Sup3", 0, Time[i],S3);
   ObjectMove("Res3", 0, Time[i],R3);
   }
}   
    PBuffer[i]=P;
    S1Buffer[i]=S1;
    R1Buffer[i]=R1;
    S2Buffer[i]=S2;
    R2Buffer[i]=R2;
    S3Buffer[i]=S3;
    R3Buffer[i]=R3;

}

//----
      } //if (show_data)  
   return(0);
  }
//+------------------------------------------------------------------+


