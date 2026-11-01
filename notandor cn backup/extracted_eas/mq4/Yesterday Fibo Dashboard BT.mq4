//+------------------------------------------------------------------------------------------------------------------+
//modified from mladen "Stochastic Heatmap.mq4"
// August 12th, 2020
#property copyright "mladen"
#property link      "www.forex-station.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property strict
extern string Symbols = "AUDCAD;AUDCHF;AUDJPY;AUDNZD;AUDUSD;CADCHF;CADJPY;CHFJPY;EURAUD;EURCAD;EURCHF;EURGBP;EURJPY;EURNZD;EURUSD;GBPAUD;GBPCAD;GBPCHF;GBPJPY;GBPNZD;GBPUSD;NZDCAD;NZDCHF;NZDJPY;NZDUSD;USDCAD;USDCHF;USDJPY;XAUUSD;BTCUSD;";  // Symbols to use (separated by ";" in the list)

extern color  AboveYesterHigh   = clrDarkGreen;                          // Color for breaking up yesterday high
extern color  Fibo76Color       = clrLimeGreen;                          // Color for above Fibo 76.4 %
extern color  Fibo61Color       = clrLime;                               // Color for above Fibo 61.8 %
extern color  Fibo50Color       = clrGray;                               // Color for above Fibo 50.0 %
extern color  Fibo38Color       = clrRed;                                // Color for above Fibo 38.2 %
extern color  Fibo23Color       = clrCrimson;                            // Color for above Fibo 23.6 %
extern color  FiboZeroColor     = clrFireBrick;                          // Color for above Fibo zero %
extern color  BelowYesterLow    = clrMaroon;                             // Color for breaking down yesterday low
extern color  Neutral           = clrLightGray;                          // Color for neutral
extern string             button_note1          = "------------------------------"; // ------------------------------
extern int    ButtonWidth       = 74;
extern color  TextColor         = clrBlack;                              // Color for button text
extern string TextFont          = "Arial";                               // Text font
extern int    TextSize          = 8;                                     // Text size
extern color  BorderColor       = clrBlack;                              // Color for button border
extern color  FillColor         = clrSilver;                             // Color for button background
extern int    Window            = 0;                                     // Window to use for display
extern ENUM_BASE_CORNER  Corner = CORNER_LEFT_LOWER;                     // Corner for display
extern int    XShift            = 0;                                     // Horizontal shift
extern int    YShift            = 0;                                     // Vertical shift
extern string UniqueID          = "SpudFiboDashboard1";                  // Indicator unique ID

//Forex-Station button template start41; copy and paste
extern string             button_note2          = "------------------------------";
extern int                btn_Subwindow         = 0;                               // What window to put the button on.  If <0, the button will use the same sub-window as the indicator.
extern ENUM_BASE_CORNER   btn_corner            = CORNER_LEFT_UPPER;               // button corner on chart for anchoring
extern string             btn_text              = "FIB BOARD";                     // a button name
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
extern string             UniqueButtonID        = "Yesterday";                     // Unique ID for each button        
extern string             button_note3          = "------------------------------";
bool show_data, recalc=false;
string IndicatorObjPrefix, buttonId;
//Forex-Station button template end41; copy and paste

int    cpairsLen;
string cpairs[];
datetime StartTime;
//+------------------------------------------------------------------------------------------------------------------+
//Forex-Station button template start42
int OnInit()
{
   Symbols = StringTrimLeft(StringTrimRight(Symbols)); 
   if (StringSubstr(Symbols,StringLen(Symbols)-1,1) != ";")
                    Symbols = StringConcatenate(Symbols,";");

   int s = 0, i = StringFind(Symbols,";",s);
   while (i > 0)
   {
      string current = StringSubstr(Symbols,s,i-s);
      ArrayResize(cpairs,ArraySize(cpairs)+1);
      cpairs[ArraySize(cpairs)-1] = current;
      s = i + 1;
      i = StringFind(Symbols,";",s);
   }
   if (Corner==CORNER_LEFT_LOWER  || Corner==CORNER_RIGHT_LOWER) invertArray(cpairs);  
   cpairsLen = ArraySize(cpairs);

   IndicatorDigits(Digits);
   IndicatorObjPrefix = "_" + btn_text + "_";
      
   buttonId = "_" + UniqueButtonID + IndicatorObjPrefix + "_BT_";
   if (ObjectFind(buttonId)<0) 
      createButton(buttonId, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize, btn_background_color, btn_border_color, btn_text_ON_color);
   ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);  

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
      ObjectSetInteger(0, buttonId, OBJPROP_STATE, true);
}
//+------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   if(reason != REASON_CHARTCHANGE) ObjectDelete(buttonId);
   deinit2();
}
//+------------------------------------------------------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CREATE || id==CHARTEVENT_OBJECT_DELETE) return;
   if(id==CHARTEVENT_MOUSE_MOVE    || id==CHARTEVENT_MOUSE_WHEEL)   return;

   if (StringFind(sparam,UniqueID+"t",0)==0)          
      ChartSetSymbolPeriod(0,ObjectGetString(0,sparam,OBJPROP_TEXT),_Period);

   if (id==CHARTEVENT_OBJECT_CLICK && sparam == buttonId)
   {
      show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);
      
      if (show_data)
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color); 
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
//Forex-Station button template end42
//+------------------------------------------------------------------------------------------------------------------+
int start() {return(mystart()); }
//+------------------------------------------------------------------------------------------------------------------+
int mystart()
  {
   int counted_bars=IndicatorCounted();
   if (show_data)
      {
        if(recalc) 
        {
           counted_bars = 0;
           recalc=false;
        }
   double HiPrice, Fibo76Price, Fibo61Price, Fibo50Price, Fibo38Price, Fibo23Price, LoPrice, PriceBid;
   int xshift=0, nxshift=0; if (Corner==CORNER_RIGHT_LOWER || Corner==CORNER_RIGHT_UPPER) { xshift=ButtonWidth; nxshift=66; }
   for (int i = 0; i < cpairsLen; i++ ) ButtonCreate2(ChartID(),UniqueID+"t"+(string)i,Window,XShift+nxshift+2,YShift+30+i*15,66,14,Corner,cpairs[i],TextFont,TextSize,TextColor,BorderColor,FillColor);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)0,Window,XShift+xshift+0*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"above 100%",TextFont,TextSize,TextColor,BorderColor,FillColor);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)1,Window,XShift+xshift+1*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"100-76.4%",TextFont,TextSize,TextColor,BorderColor,FillColor);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)2,Window,XShift+xshift+2*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"76.4-61.8%",TextFont,TextSize,TextColor,BorderColor,FillColor);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)3,Window,XShift+xshift+3*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"61.8-50%",TextFont,TextSize,TextColor,BorderColor,clrGoldenrod);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)4,Window,XShift+xshift+4*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"50-38.2%",TextFont,TextSize,TextColor,BorderColor,clrGoldenrod);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)5,Window,XShift+xshift+5*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"38.2-23.6%",TextFont,TextSize,TextColor,BorderColor,FillColor);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)6,Window,XShift+xshift+6*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"23.6-zero%",TextFont,TextSize,TextColor,BorderColor,FillColor);
   ButtonCreate2(ChartID(),UniqueID+"h"+(string)7,Window,XShift+xshift+7*ButtonWidth+69,YShift+15,ButtonWidth,14,Corner,"Current",TextFont,TextSize,TextColor,BorderColor,FillColor);

   for (int i = 0; i < cpairsLen; i++)
      if (iClose(cpairs[i],0,0)!=0)
      {
	      int banzai	= iBarShift(cpairs[i],PERIOD_D1,Time[0]) + 1;
	      HiPrice		= iHigh(cpairs[i],PERIOD_D1,banzai);
	      LoPrice		= iLow (cpairs[i],PERIOD_D1,banzai);
	      StartTime	= iTime(cpairs[i],PERIOD_D1,banzai);
	      if(TimeDayOfWeek(StartTime)==0)
	      {
	   	   HiPrice = MathMax(HiPrice,iHigh(cpairs[i],PERIOD_D1,banzai+1));
	   	   LoPrice = MathMin(LoPrice,iLow(cpairs[i],PERIOD_D1,banzai+1));
	      }
         PriceBid = MarketInfo(cpairs[i],MODE_BID);
         Fibo76Price = ((HiPrice-LoPrice)*0.764)+LoPrice;
         Fibo61Price = ((HiPrice-LoPrice)*0.618)+LoPrice;
         Fibo50Price = ((HiPrice-LoPrice)/2)+LoPrice;
         Fibo38Price = ((HiPrice-LoPrice)*0.382)+LoPrice;
         Fibo23Price = ((HiPrice-LoPrice)*0.236)+LoPrice;
//------------------        
         if (PriceBid > HiPrice)
            ButtonCreate2(ChartID(),UniqueID+(string)0+(string)i,Window,XShift+xshift+0*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(HiPrice,5),TextFont,TextSize,TextColor,BorderColor,AboveYesterHigh);
         else                       
            ButtonCreate2(ChartID(),UniqueID+(string)0+(string)i,Window,XShift+xshift+0*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(HiPrice,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------
         if (PriceBid > Fibo76Price && PriceBid <HiPrice)
            ButtonCreate2(ChartID(),UniqueID+(string)1+(string)i,Window,XShift+xshift+1*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo76Price,5),TextFont,TextSize,TextColor,BorderColor,Fibo76Color);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)1+(string)i,Window,XShift+xshift+1*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo76Price,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------                     
         if (PriceBid > Fibo61Price && PriceBid <Fibo76Price)
            ButtonCreate2(ChartID(),UniqueID+(string)2+(string)i,Window,XShift+xshift+2*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo61Price,5),TextFont,TextSize,TextColor,BorderColor,Fibo61Color);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)2+(string)i,Window,XShift+xshift+2*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo61Price,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------
         if (PriceBid > Fibo50Price && PriceBid <Fibo61Price)
            ButtonCreate2(ChartID(),UniqueID+(string)3+(string)i,Window,XShift+xshift+3*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo50Price,5),TextFont,TextSize,TextColor,BorderColor,Fibo50Color);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)3+(string)i,Window,XShift+xshift+3*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo50Price,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------
         if (PriceBid > Fibo38Price && PriceBid <Fibo50Price)
            ButtonCreate2(ChartID(),UniqueID+(string)4+(string)i,Window,XShift+xshift+4*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo38Price,5),TextFont,TextSize,TextColor,BorderColor,Fibo38Color);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)4+(string)i,Window,XShift+xshift+4*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo38Price,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------
         if (PriceBid > Fibo23Price && PriceBid <Fibo38Price)
            ButtonCreate2(ChartID(),UniqueID+(string)5+(string)i,Window,XShift+xshift+5*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo23Price,5),TextFont,TextSize,TextColor,BorderColor,Fibo23Color);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)5+(string)i,Window,XShift+xshift+5*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(Fibo23Price,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------
         if (PriceBid > LoPrice && PriceBid <Fibo23Price)
            ButtonCreate2(ChartID(),UniqueID+(string)6+(string)i,Window,XShift+xshift+6*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(LoPrice,5),TextFont,TextSize,TextColor,BorderColor,FiboZeroColor);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)6+(string)i,Window,XShift+xshift+6*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(LoPrice,5),TextFont,TextSize,TextColor,BorderColor,Neutral);
//------------------
         if (PriceBid < LoPrice)
            ButtonCreate2(ChartID(),UniqueID+(string)7+(string)i,Window,XShift+xshift+7*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(PriceBid,5),TextFont,TextSize,TextColor,BorderColor,BelowYesterLow);
         else
            ButtonCreate2(ChartID(),UniqueID+(string)7+(string)i,Window,XShift+xshift+7*ButtonWidth+69,YShift+30+i*15,ButtonWidth,14,Corner,DoubleToStr(PriceBid,5),TextFont,TextSize,TextColor,BorderColor,Neutral);   
//------------------
      }
   if (Corner==CORNER_RIGHT_UPPER || Corner==CORNER_RIGHT_LOWER)
         ButtonCreate2(ChartID(),UniqueID+"title",Window,XShift+xshift+8*ButtonWidth,YShift+30+cpairsLen*15,8*(ButtonWidth)-1,14,Corner,"Yesterday Fibo Dashboard",TextFont,TextSize,TextColor,BorderColor,FillColor);
   else  ButtonCreate2(ChartID(),UniqueID+"title",Window,XShift+xshift+69,YShift+30+cpairsLen*15,8*(ButtonWidth)-1,14,Corner,"Yesterday Fibo Dashboard",TextFont,TextSize,TextColor,BorderColor,FillColor);

      if (!show_data)
       {
       ObjectSetInteger(ChartID(),buttonId,OBJPROP_COLOR,btn_text_OFF_color);
       int idLength = StringLen(UniqueID);
       for (int i = ObjectsTotal(); i>=0; i--)
         { string name = ObjectName(i); if (StringSubstr(name,0,idLength) == UniqueID) ObjectDelete(name); }         
       }
      else       ObjectSetInteger(ChartID(),buttonId,OBJPROP_COLOR,btn_text_ON_color);
      }
   return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
int deinit2()
{
   int idLength = StringLen(UniqueID);
   for (int i = ObjectsTotal(); i>=0; i--)
         { string name = ObjectName(i); if (StringSubstr(name,0,idLength) == UniqueID) ObjectDelete(name); }         

	return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
bool ButtonCreate2(const long              chart_ID=0,
                  const string            name="Button",
                  const int               sub_window=0,
                  const int               x=0,
                  const int               y=0,
                  const int               width=65,
                  const int               height=14,
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER,
                  const string            text="Button",
                  const string            font="Arial",
                  const int               font_size=8,
                  const color             clr=clrBlack,
                  const color             clrBorder=clrBlack,
                  const color             back_clr=clrGray,
                  const bool              state=true,
                  const bool              back=false,
                  const bool              selection=false,
                  const bool              hidden=true,
                  const long              z_order=0)
{ 
   ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,clrBorder); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,BORDER_FLAT); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
         ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
         ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
      return(true); 
} 
//+------------------------------------------------------------------------------------------------------------------+
void invertArray(string& array[])
{
   string temp[]; ArrayCopy(temp,array); for (int i=0, s=ArraySize(array); i<s; i++) array[i] = temp[s-i-1];
}
//+------------------------------------------------------------------------------------------------------------------+
