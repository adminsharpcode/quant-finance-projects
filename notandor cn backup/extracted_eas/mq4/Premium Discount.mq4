//+------------------------------------------------------------------+
//|                               Fibonacci Killer Indicator (R).mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

#property indicator_chart_window
extern bool   soundAlerts = false;
extern bool   emailAlerts = false;

int init()
{
   return(0);
}

int deinit()
{
   return(0);
}

int start()
{
   if(Open[0] == Close[0] &&
      Open[0] == High[0] &&
      Open[0] == Low[0] &&
      GlobalVariableCheck("fiboalert"))
      GlobalVariableDel("fiboalert");
   
   //Find lowest low and highets High
   int il = iLowest(Symbol(), 0, MODE_LOW, 200, 0);
   int ih = iHighest(Symbol(), 0, MODE_HIGH, 200, 0);
   int later = MathMax(il, ih);
   double l = Low[il];
   double h = High[ih];
   
   //Plot 50.0
   double l500;
   if(il < ih)
      l500 = (h-l)*0.500 + l;
   else
      l500 = h-(h-l)*0.500;

   if(ObjectType("l5") != OBJ_TREND) ObjectDelete("l5");
   if(ObjectGet("l5", OBJPROP_PRICE1) != l500) ObjectDelete("l5");
   ObjectCreate("l5", OBJ_TREND, 0, Time[later], l500, Time[0], l500); 
   ObjectSet("l5", OBJPROP_STYLE, STYLE_DASH);

   
   //Alert if price is close
   double ATR = iATR(Symbol(), 0, 50, 1);
   if(MathAbs(Close[0] - l500) < ATR)
   {
      if(!GlobalVariableCheck("fiboalert"))
      {
         //Alert code here
         if(soundAlerts)
            Alert("Price is near Premium Discount at " + l500 + ", " + Symbol() + "! Premium Discount.");
      
         if(emailAlerts)
            SendMail("Price is near Premium Discount at " + l500, "Price is near Premium Discount at " + l500 + ", " + Symbol() + "! Premium Discount.");
         
         GlobalVariableSet("fiboalert", 1);
      }
   }
   
   return(0);
}