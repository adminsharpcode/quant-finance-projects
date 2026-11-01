/*-------------------------------------------------------------------
   Name: BN Levels.mq4
   Copyright ©2010, Xaphod, http://forexwhiz.appspot.com
   
   Description: With this indicator one can set up to eight levels 
    between 00 and 99 pips to be marked with horizontal lines.     
    * Draws a specified number of horizontal lines on each side of 
      the bid.
    * Up to eight lines can be defined.
    * Each line has settings for line level, text (label and value), 
      line style and width.
    * Text/label color can be set individually or generally.
    * Line type, text size, text position and background property 
      are general for all the lines.
    * The indicator redraws the lines when the bid moves more than 
      10 pips or a new candle is drawn.
    * No lines are drawn for time-frames over 60min.
    * 3 types of lines are available. 
       1=Line on right side of the screen, 
       2=Trend line across screen, 
       3=Trend line across screen with level shown in the price axis.
	         
   Change log: 
       2010-04-06, Xaphod, v1.00 
          Initial Release
       2010-05-06, Xaphod, v1.01 Release
          Added MaxTimeFrame parameter to set the highest TF in 
           which the BN lines are drawn
       2010-05-06, Xaphod, v1.02 Release
          Added SIM mode
       
          
-----------------------------------------------------------------*/
// Indicator properties
#property copyright "Copyright © 2010, Xaphod, forexwhiz.appspot.com"
#property link      "http://forexwhiz.appspot.com"
#property indicator_chart_window

// Definitions
#define H_LINE_RAY 3
#define T_LINE_RAY 2
#define T_LINE_SHORT 1
#define INDI_OBJ_NAME "BNL_"

// Input parameters
extern string  GeneralSettingsInfo1="<< Settings affecting all lines >>";
extern int     LinesPerSide=5;
extern string  GeneralSettingsInfo2="<< 1: Right Side, 2=Trend Line, 3=Hline >>";
extern int     LineType=1;
extern bool    LineAsBackground=true; 
extern string  GeneralSettingsInfo3="<< Offset middle of long lines. Offset right of short lines >>";
extern int     LineTextPos=8;
extern int     LineTextSize=8;
extern string  GeneralSettingsInfo4="<< Highest TF to show lines in 1,5,15,30,60,240,1440 etc>>";
extern int     MaxTimeFrame=240;
extern string  GeneralSettingsInfo5="<< Label color & size >>";
extern bool    UseGeneralColor=false;
extern color   LineTextColor=Black;
extern bool    SimMode=False;

extern string  Line1SettingsInfo="<< Line1 Settings >>";
extern bool    Line1Enable=true;
extern int     Line1Level=0;
extern string  Line1Label="BN-00";
extern bool    Line1ShowLabel=false;
extern bool    Line1ShowValue=true;
extern int     Line1Style=0;
extern int     Line1Width=2;
extern color   Line1Color=Thistle;

extern string  Line2SettingsInfo="<< Line2 Settings >>";
extern bool    Line2Enable=true;
extern int     Line2Level=20;
extern string  Line2Label="BN-20";
extern bool    Line2ShowLabel=false;
extern bool    Line2ShowValue=true;
extern int     Line2Style=0;
extern int     Line2Width=1;
extern color   Line2Color=Thistle;

extern string  Line3SettingsInfo="<< Line3 Settings >>";
extern bool    Line3Enable=true;
extern int     Line3Level=50;
extern string  Line3Label="BN-50";
extern bool    Line3ShowLabel=false;
extern bool    Line3ShowValue=true;
extern int     Line3Style=0;
extern int     Line3Width=2;
extern color   Line3Color=Thistle;

extern string  Line4SettingsInfo="<< Line4 Settings >>";
extern bool    Line4Enable=true;
extern int     Line4Level=80;
extern string  Line4Label="BN-80";
extern bool    Line4ShowLabel=false;
extern bool    Line4ShowValue=true;
extern int     Line4Style=0;
extern int     Line4Width=1;
extern color   Line4Color=Thistle;

extern string  Line5SettingsInfo="<< Line5 Settings >>";
extern bool    Line5Enable=true;
extern int     Line5Level=10;
extern string  Line5Label="MRN-10";
extern bool    Line5ShowLabel=false;
extern bool    Line5ShowValue=true;
extern int     Line5Style=2;
extern int     Line5Width=1;
extern color   Line5Color=Gainsboro;

extern string  Line6SettingsInfo="<< Line6 Settings >>";
extern bool    Line6Enable=true;
extern int     Line6Level=35;
extern string  Line6Label="MRN-35";
extern bool    Line6ShowLabel=false;
extern bool    Line6ShowValue=true;
extern int     Line6Style=2;
extern int     Line6Width=1;
extern color   Line6Color=Gainsboro;

extern string  Line7SettingsInfo="<< Line7 Settings >>";
extern bool    Line7Enable=true;
extern int     Line7Level=65;
extern string  Line7Label="MRN-65";
extern bool    Line7ShowLabel=false;
extern bool    Line7ShowValue=true;
extern int     Line7Style=2;
extern int     Line7Width=1;
extern color   Line7Color=Gainsboro;

extern string  Line8SettingsInfo="<< Line8 Settings >>";
extern bool    Line8Enable=true;
extern int     Line8Level=90;
extern string  Line8Label="MRN-90";
extern bool    Line8ShowLabel=false;
extern bool    Line8ShowValue=true;
extern int     Line8Style=2;
extern int     Line8Width=1;
extern color   Line8Color=Gainsboro;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
  //---- indicators
  return(0);
}


//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit() {
  // Clear text objects
  for(int i=ObjectsTotal()-1; i>-1; i--)
   if (StringFind(ObjectName(i),INDI_OBJ_NAME)>=0)  ObjectDelete(ObjectName(i));
   return(0);
}

  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {
  static double dStartPrice=0;
  static datetime tStartTime=0;
  double dPip;
  int iNextLevel;
  int iStartLevel;
  int i;
  double dBid;

  // Exit if TF > 60 mins
  if (Period()>MaxTimeFrame) return(0);
  
  // Get bid value
  if (SimMode==true) 
    dBid=Close[0]; 
  else 
    dBid=Bid;
  
 
  // Check if Bid has changed by more than 10 pips or a new bar has been displayed and exit if it has not. 
  dPip=GetPointValue();   
  if (dStartPrice<(dBid-(dPip*10)) || dStartPrice>(dBid+(dPip*10)) || tStartTime!=Time[0]) {
    dStartPrice=dBid;
    tStartTime=Time[0];
    }
  else {
    return(0);
  } 

  iStartLevel= dBid/dPip; 
  // Draw lines above bid
  i=0;  
  iNextLevel=iStartLevel+1;
  while (i<LinesPerSide) {
     if (CheckAndSetLevel(iNextLevel,"+"+i)==true) i++;
     iNextLevel++;  
  }
  // Draw lines below bid
  i=0;
  iNextLevel=iStartLevel;
  while (i<LinesPerSide) {
     if (CheckAndSetLevel(iNextLevel,"-"+i)==true) i++;
     iNextLevel--;  
  }
  
  //Exit 
  return(0);
  }
//+------------------------------------------------------------------+
 

//-----------------------------------------------------------------------------
// function: GetPointValue()
// Description: Get pip value depending on number of digits.
//-----------------------------------------------------------------------------
double GetPointValue() {

  if (Digits==2 || Digits==3) 
    return(0.01); 
  else if (Digits==4 || Digits==5) 
    return(0.0001); 
  else
    return(Point);            
} // end funcion() 
 

//-----------------------------------------------------------------------------
// function: CheckAndSetLevel()
// Description: heck all defined line levels and draw lines if indicated
//----------------------------------------------------------------------------- 
bool CheckAndSetLevel( int iNextLevel, string sLineId) {
  int iLastDigits;
  double dPip;
  //PrintD("Period: "+Period());
  // Get last 2 digits 
  iLastDigits=iNextLevel%100;
  dPip=GetPointValue();
  
  // Check all defined line levels and draw lines if indicated
  if (Line1Enable==true && iLastDigits==Line1Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line1Style, Line1Width, Line1Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line1ShowLabel, Line1Label, Line1ShowValue, Line1Color);
    return(true);
  }    
  else if (Line2Enable==true && iLastDigits==Line2Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line2Style, Line2Width, Line2Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line2ShowLabel, Line2Label, Line2ShowValue, Line2Color);
    return(true);
  }
  else if (Line3Enable==true && iLastDigits==Line3Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line3Style, Line3Width, Line3Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line3ShowLabel, Line3Label, Line3ShowValue, Line3Color);
    return(true);
  }
  else if (Line4Enable==true && iLastDigits==Line4Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line4Style, Line4Width, Line4Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line4ShowLabel, Line4Label, Line4ShowValue, Line4Color);
    return(true);
  } 
  else if (Line5Enable==true && iLastDigits==Line5Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line5Style, Line5Width, Line5Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line5ShowLabel, Line5Label, Line5ShowValue, Line5Color);
    return(true);
  } 
  else if (Line6Enable==true && iLastDigits==Line6Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line6Style, Line6Width, Line6Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line6ShowLabel, Line6Label, Line6ShowValue, Line6Color);
    return(true);
  } 
  else if (Line7Enable==true && iLastDigits==Line7Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line7Style, Line7Width, Line7Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line7ShowLabel, Line7Label, Line7ShowValue, Line7Color);
    return(true);
  } 
  else if (Line8Enable==true && iLastDigits==Line8Level) {
    DrawLine(iNextLevel*dPip, sLineId, Line8Style, Line8Width, Line8Color);
    DrawLabel(iNextLevel*dPip, sLineId, Line8ShowLabel, Line8Label, Line8ShowValue, Line8Color);
    return(true);
  } 
  return(false);
}
   
//-----------------------------------------------------------------------------
// function: DrawLine()
// Description: Draw a horizontal line at specific price
//----------------------------------------------------------------------------- 
int DrawLine(double dPrice, string sLineCnt, int iLineStyle, int iLineWidth, color cLineColor) {
  datetime tStartPos;
  datetime tEndPos;
  string sLineId;
  int iLineType;
  
  // Set Line object ID  
  sLineId=INDI_OBJ_NAME+"Line_"+"("+sLineCnt+")";
  
  // Set start & end position of line 
  if (LineType==T_LINE_RAY || LineType==H_LINE_RAY)  
    tStartPos = WindowFirstVisibleBar();  
  else
    tStartPos = Time[0]+Period()*60;
  tEndPos = tStartPos+Period()*60;
  
  // Set line type
  if (LineType==H_LINE_RAY) 
    iLineType=OBJ_HLINE;
  else
    iLineType=OBJ_TREND;  
  
  // Draw line
  if (ObjectFind(sLineId)>=0 ) ObjectDelete(sLineId);
  ObjectCreate(sLineId, iLineType, 0, tStartPos, dPrice, tEndPos, dPrice); 
  ObjectSet(sLineId, OBJPROP_STYLE, iLineStyle);     
  ObjectSet(sLineId, OBJPROP_WIDTH, iLineWidth);
  ObjectSet(sLineId, OBJPROP_BACK, LineAsBackground);
  ObjectSet(sLineId, OBJPROP_COLOR, cLineColor);    
  return(0);
}

//-----------------------------------------------------------------------------
// function: DrawLabel()
// Description: Draw a text label for a line
//-----------------------------------------------------------------------------
int DrawLabel(double dPrice, string sLineCnt, bool sShowLabel, string sLabel, bool sShowValue, color cLineColor) {
  datetime tTextPos=0;
  string sLineLabel="";
  string sLineId;
  color cTextColor;
  
  // Set text object id
  sLineId=INDI_OBJ_NAME+"Text_"+"("+sLineCnt+")";
  
  //Set position of text label
  if (LineType==T_LINE_RAY || LineType==H_LINE_RAY)  
    tTextPos=Time[WindowFirstVisibleBar()/2-LineTextPos];
  else
    tTextPos =  Time[0]+(Period()*60*LineTextPos);  
    
  // Set label text 
  if (sShowLabel==true) 
    sLineLabel= sLabel + "  ";
    
  if (sShowValue==true) 
    sLineLabel=sLineLabel+DoubleToStr(dPrice, Digits);
  
  // Set text color
  if (UseGeneralColor==true)  
    cTextColor=LineTextColor;
  else
    cTextColor=cLineColor;
    
  // Draw or text label  
  if (ObjectFind(sLineId)>=0 ) ObjectDelete(sLineId);      
  ObjectCreate(sLineId, OBJ_TEXT, 0, tTextPos, dPrice);    
  ObjectSet(sLineId, OBJPROP_BACK, LineAsBackground);
  ObjectSetText(sLineId, sLineLabel , 8, "Arial", cTextColor);
 
  return(0);
}

