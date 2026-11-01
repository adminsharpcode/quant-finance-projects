//+------------------------------------------------------------------+
//|                                                    M-Candles.mq4 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "c. 2025; Forex-Station"
#property link      "http://www.Forex-Station.com/"
#property strict

#property  indicator_chart_window
#property  indicator_buffers 2

//--- PROPERTY STYLES
#property  indicator_width1  2




//--- INPUT PARAMETERS
extern string              PARAMETERS             = "==== PARAMETERS ====";
extern int                 BarsToDraw             = 100;                   // History bars to draw
input ENUM_TIMEFRAMES      CandleTimeFrame        = 5;                     // Timeframe candles to display
extern bool                FillCandleWithColors   = true;                  // Fill candles?

extern string              STYLES                 = "==== STYLES SETTINGS ====";
extern int                 BodyCandlesWidth       = 2;                     // Candles width
extern int                 WickCandlesWidth       = 3;                     // Wicks width

extern string              COLORS                 = "==== COLORS SETTINGS ====";
extern color               ColorUp                = C'221,255,221';        // C'202,202,255';        // Candle up color
extern color               ColorDown              = clrMistyRose;          //C'255,196,196';        // Candle down color


extern string              BUTTON                 = "==== BUTTON ON/OFF ====";
extern ENUM_BASE_CORNER    Btn_Corner             = CORNER_LEFT_UPPER;     // Button corner
extern int                 Btn_Subwindow          = 0;                     // Button subwindow
extern string              Btn_Text               = "M5";                  // Button text
extern int                 Btn_FontSize           = 9;                     // Button font size
extern string              Btn_FontType           = "Arial";               // Button font type
extern color               Btn_Bg_Color           = clrDimGray;            // Button background color
extern color               Btn_BorderColor        = clrBlack;              // Button border color
extern color               Btn_TextColorPressed   = clrLime;               // Button pressed text color
extern color               Btn_TextColorUnpressed = clrRed;                // Button unpressed text color
extern int                 Btn_x                  = 100;                   // Button X coordinate
extern int                 Btn_y                  = 155;                   // Button Y coordinate
extern int                 Btn_Width              = 80;                    // Button width
extern int                 Btn_Height             = 20;                    // Button height
extern string              UniqueButtonID         = "M-CandlesM5";         // Unique ID for each button   


//--- INTERNAL VARIABLES DECLARATION
bool ButtonState = false;
bool Recalc = false;
string IndicatorObjPrefix, IndicatorName, ButtonId;





//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{

   IndicatorDigits(Digits);
   IndicatorObjPrefix = "__" + Btn_Text + "__";
   
   // The leading "_" gives buttonId a *unique* prefix.  Furthermore, prepending the swin is usually unique unless >2+ of THIS indy are displayed in the SAME sub-window. (But, if >2 used, be sure to shift the buttonId position)
   ButtonId = "_" + UniqueButtonID + IndicatorObjPrefix + "_BT_";
   if (ObjectFind(ButtonId)<0)
    
      CreateButton(ButtonId, Btn_Text, Btn_Width, Btn_Height, Btn_FontType, Btn_FontSize, Btn_Bg_Color, Btn_BorderColor, Btn_TextColorPressed);
      ObjectSetInteger(0, ButtonId, OBJPROP_YDISTANCE, Btn_y);
      ObjectSetInteger(0, ButtonId, OBJPROP_XDISTANCE, Btn_x);


   

   ButtonState = ObjectGetInteger(0, ButtonId, OBJPROP_STATE);
   
   
   if (ButtonState == true)
      { init2();        
         
      ObjectSetInteger(0, ButtonId, OBJPROP_COLOR, Btn_TextColorPressed); 
      }
      
   else 
      {
      ObjectSetInteger(0, ButtonId, OBJPROP_COLOR, Btn_TextColorUnpressed);
      
      }
      
      
   return(INIT_SUCCEEDED);
}



//+------------------------------------------------------------------------------------------------------------------+
void CreateButton(string buttonID, string buttonText, int width, int height, string font, int fontSize, color bgColor, color borderColor, color txtColor)
{
      ObjectDelete    (0, buttonID);
      ObjectCreate    (0, buttonID, OBJ_BUTTON, Btn_Subwindow, 0, 0);
      ObjectSetInteger(0, buttonID, OBJPROP_COLOR, Btn_TextColorPressed);
      ObjectSetInteger(0, buttonID, OBJPROP_BGCOLOR, Btn_Bg_Color);
      ObjectSetInteger(0, buttonID, OBJPROP_BORDER_COLOR, Btn_BorderColor);
      ObjectSetInteger(0, buttonID, OBJPROP_BORDER_TYPE,BORDER_RAISED);
      ObjectSetInteger(0, buttonID, OBJPROP_XSIZE, Btn_Width);
      ObjectSetInteger(0, buttonID, OBJPROP_YSIZE, Btn_Height);
      ObjectSetString (0, buttonID, OBJPROP_FONT, Btn_FontType);
      ObjectSetString (0, buttonID, OBJPROP_TEXT, Btn_Text);
      ObjectSetInteger(0, buttonID, OBJPROP_FONTSIZE, Btn_FontSize);
      ObjectSetInteger(0, buttonID, OBJPROP_SELECTABLE, 0);
      ObjectSetInteger(0, buttonID, OBJPROP_CORNER, Btn_Corner);
      ObjectSetInteger(0, buttonID, OBJPROP_HIDDEN, 1);
      ObjectSetInteger(0, buttonID, OBJPROP_XDISTANCE, 9999);
      ObjectSetInteger(0, buttonID, OBJPROP_YDISTANCE, 9999);
      ObjectSetInteger(0, buttonID, OBJPROP_STATE, true);
} 




//+------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   deinit2();
   // If just changing a TF', the button need not be deleted, therefore the 'OBJPROP_STATE' is also preserved.
   if(reason != REASON_CHARTCHANGE) ObjectDelete(ButtonId);
}



//+------------------------------------------------------------------------------------------------------------------+
void OnChartEvent(const int id, 
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_DELETE) return;
   if(id == CHARTEVENT_MOUSE_MOVE    || id == CHARTEVENT_MOUSE_WHEEL)   return;


   if (id == CHARTEVENT_OBJECT_CLICK && sparam == ButtonId) 
   {
      ButtonState = ObjectGetInteger(0, ButtonId, OBJPROP_STATE);
      
      if (ButtonState == true)
      {
         ObjectSetInteger(0, ButtonId, OBJPROP_COLOR, Btn_TextColorPressed);
         init2();
         Recalc = true;
         mystart();
      }
      else
      {
         ObjectSetInteger(0, ButtonId, OBJPROP_COLOR, Btn_TextColorUnpressed);
         for (int ForexStation = 0; ForexStation < indicator_buffers; ForexStation++)
              SetIndexStyle(ForexStation, DRAW_NONE);
         deinit2();
      }
   }
   
}



//+------------------------------------------------------------------------------------------------------------------+
int init2()
{

  int i;

  for (i=0; i<BarsToDraw; i++)
    {
    ObjectDelete("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i));
    ObjectDelete("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i));
    ObjectDelete("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i));
    }
  
  for (i=0; i<BarsToDraw; i++)
    {
    ObjectCreate("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i), OBJ_RECTANGLE, 0, 0, 0, 0, 0);
    ObjectCreate("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i), OBJ_TREND, 0, 0, 0, 0, 0);
    ObjectCreate("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i), OBJ_TREND, 0, 0, 0, 0, 0);
    }
  

   return 0;
}



//+------------------------------------------------------------------------------------------------------------------+
  int deinit2()

{
   ObjectsDeleteAll(ChartID(), IndicatorObjPrefix);

//put deinit() here

  for (int i=0; i<BarsToDraw; i++) {
      ObjectDelete("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i));
      ObjectDelete("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i));
      ObjectDelete("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(i));

  }
  

   return 0;
}



//+------------------------------------------------------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{

return(mystart()); }




//+------------------------------------------------------------------+
int mystart() {

  // Controlla se il timeframe attuale è uguale al timeframe specificato
  if (Period() == CandleTimeFrame) {
    // Se il timeframe è uguale, non disegnare nulla
    return 0; 
  }


  int shb=0, sh1=1;
  double   po, pc;       // Öåíû îòêðûòèÿ è çàêðûòèÿ ñòàðøèõ ñâå÷åê
  double   ph=0, pl=500; // Öåíû õàé è ëîó ñòàðøèõ ñâå÷åê
  datetime to, tc, ts;   // Âðåìÿ îòêðûòèÿ, çàêðûòèÿ è òåíåé ñòàðøèõ ñâå÷åê

  
  bool OK_Period=false;   
  switch (CandleTimeFrame)
  {    
    case 1:OK_Period=true;break;
    case 5:OK_Period=true;break;
    case 15:OK_Period=true;break;
    case 30:OK_Period=true;break;
    case 60:OK_Period=true;break;
    case 240:OK_Period=true;break;
    case 1440:OK_Period=true;break;
    case 10080:OK_Period=true;break;
    case 43200:OK_Period=true;break;
  
    return(0);
  }
    
    shb=0;
      
    while (shb<BarsToDraw) 
    {
      to = iTime(Symbol(), CandleTimeFrame, shb);
      tc = iTime(Symbol(), CandleTimeFrame, shb) + CandleTimeFrame*60;
      po = iOpen(Symbol(), CandleTimeFrame, shb);
      pc = iClose(Symbol(), CandleTimeFrame, shb);
      ph = iHigh(Symbol(), CandleTimeFrame, shb); 
      pl = iLow(Symbol(), CandleTimeFrame, shb); 
      
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_TIME1, to);
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_PRICE1, po);
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_TIME2, tc);
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_PRICE2, pc);
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_WIDTH, BodyCandlesWidth);
      ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_BACK, FillCandleWithColors);

      
      ts = to + (int)MathRound((CandleTimeFrame * 60) / 2);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_TIME1, ts);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_PRICE1, ph);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_TIME2, ts);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_PRICE2, MathMax(po, pc));
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_WIDTH, WickCandlesWidth);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_BACK, FillCandleWithColors);
      ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_RAY, False);
      
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_TIME1, ts);
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_PRICE1, MathMin(po, pc));
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_TIME2, ts);
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_PRICE2, pl);
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_WIDTH, WickCandlesWidth);
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_BACK, FillCandleWithColors);
      ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_RAY, False);
           
 
 
 
      
      if (po<pc) {
          ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_COLOR, ColorUp);
          ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_COLOR, ColorUp);
          ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_COLOR, ColorUp);

 
        } else {
          ObjectSet("BodyTF" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_COLOR, ColorDown);
          ObjectSet("ShadowTFh" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_COLOR, ColorDown);
          ObjectSet("ShadowTFl" + IntegerToString(CandleTimeFrame) + "Bar" + IntegerToString(shb), OBJPROP_COLOR, ColorDown);


        }
      shb++;
     }       
  return(0);
}
//+------------------------------------------------------------------+
