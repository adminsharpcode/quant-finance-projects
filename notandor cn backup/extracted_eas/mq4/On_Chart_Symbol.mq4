//+------------------------------------------------------------------+
//|                                              On_Chart_Symbol.mq4 |
//|                               Copyright 2013 cjatradingtools.com |
//|                                              cjatradingtools.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013 cjatradingtools.com"
#property link      "cjatradingtools.com"

#property indicator_chart_window

extern int     Font_size       = 12;
extern string  Font_type       = "Arial Bold";
extern color   Font_color      = Gold;

extern int     Shift_up_down   = 0;
extern int     Shift_sideways  = 0;
extern int     Display_corner  = 1;

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
  ObjectDelete("symbol"); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
 
//----
  Createtext("symbol",20,15); 
  ObjectSetText("symbol",Symbol(),Font_size,Font_type, Font_color);
  
//----
   return(0);
  }
  
  int Createtext( string a, int x, int y ) {
   ObjectCreate( a, OBJ_LABEL, 0, 0, 0 );
   ObjectSet( a, OBJPROP_CORNER, Display_corner );
   ObjectSet( a, OBJPROP_XDISTANCE,x+Shift_sideways);
   ObjectSet( a, OBJPROP_YDISTANCE,y+Shift_up_down);
   ObjectSet( a, OBJPROP_BACK, false );
   }
//+------------------------------------------------------------------+