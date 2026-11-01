//+------------------------------------------------------------------+
//|                                               Display Spread.mq4 |
//+------------------------------------------------------------------+
#property indicator_chart_window

extern color      TextColor              = clrGray;
extern string     TextFont               = "Arial Bold";
extern int        TextSize               = 22;
extern int        DecimalPoints          = 1;
extern int        DisplayCorner          = 1;
extern int        HorizPos               = 5;
extern int        VertPos                = 30;

//+------------------------------------------------------------------+
int init()   {
//+------------------------------------------------------------------+
  ObjectCreate("box-1",OBJ_LABEL,0,0,0);
  ObjectSet("box-1",OBJPROP_CORNER,DisplayCorner);
  ObjectSet("box-1",OBJPROP_XDISTANCE,HorizPos);
  ObjectSet("box-1",OBJPROP_YDISTANCE,VertPos);
  return(0);
}

//+------------------------------------------------------------------+
int deinit()  {
//+------------------------------------------------------------------+
  ObjectDelete("box-1");
  return(0);
}

//+------------------------------------------------------------------+
int start()  {
//+------------------------------------------------------------------+
//  Comment("Buyers = ",Buyers,"\n","Sellers = ",Sellers);   
  if (Digits==3 || Digits==5)  int fac=10;  else  fac=1;
  ObjectSetText("box-1", "" + DoubleToStr((Ask-Bid)/Point/fac, DecimalPoints), TextSize, TextFont, TextColor); 
  return(0);
}