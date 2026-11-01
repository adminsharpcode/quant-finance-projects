//+------------------------------------------------------------------+
//|                                                 ly Pivot.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   double high=iHigh(Symbol(),PERIOD_W1,1);
   double low=iLow(Symbol(),PERIOD_W1,1);
   double close=iClose(Symbol(),PERIOD_W1,1);
   double pp=(high+low+close)/3;
   double range=high-low;
   double s1=(2*pp)-high;
   double s2=pp-range;
   double s3=s2-range;
   double s4=s3-range;
   double r1=(2*pp)-low;
   double r2=pp+range;
   double r3=r2+range;
   double r4=r3+range;
   


   ObjectDelete("Pivot");
   ObjectCreate("Pivot", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), pp,TimeCurrent()+30*24*60*60,pp);
   ObjectSet("Pivot", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("Pivot", OBJPROP_RAY, false);
   ObjectSet("Pivot", OBJPROP_COLOR, Red);
   ObjectSet("Pivot", OBJPROP_WIDTH, 0);
   
   ObjectDelete("Pivottxt");
   ObjectCreate("Pivottxt", OBJ_TEXT , 0,Time[0]+7*24*60*60,pp);
   ObjectSetText("Pivottxt", "Wkly Pvt", 8, "Tahoma", Red);
   
   ObjectDelete("s1");
   ObjectCreate("s1", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), s1,TimeCurrent()+30*24*60*60,s1);
   ObjectSet("s1", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("s1", OBJPROP_RAY, false);
   ObjectSet("s1", OBJPROP_COLOR, Red);
   ObjectSet("s1", OBJPROP_WIDTH, 0);
   
   ObjectDelete("s1t");
   ObjectCreate("s1t", OBJ_TEXT , 0,Time[0]+7*24*60*60,s1);
   ObjectSetText("s1t", "S3", 8, "Tahoma", Red);
   
   ObjectDelete("s2");
   ObjectCreate("s2", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), s2,TimeCurrent()+30*24*60*60,s2);
   ObjectSet("s2", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("s2", OBJPROP_RAY, false);
   ObjectSet("s2", OBJPROP_COLOR, Red);
   ObjectSet("s2", OBJPROP_WIDTH, 0);
   
   ObjectDelete("s2t");
   ObjectCreate("s2t", OBJ_TEXT , 0,Time[0]+7*24*60*60,s2);
   ObjectSetText("s2t", "S2", 8, "Tahoma", Red);
   
   ObjectDelete("s3");
   ObjectCreate("s3", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), s3,TimeCurrent()+30*24*60*60,s3);
   ObjectSet("s3", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("s3", OBJPROP_RAY, false);
   ObjectSet("s3", OBJPROP_COLOR, Red);
   ObjectSet("s3", OBJPROP_WIDTH, 0);
   
   ObjectDelete("s3t");
   ObjectCreate("s3t", OBJ_TEXT , 0,Time[0]+7*24*60*60,s3);
   ObjectSetText("s3t", "S3", 8, "Tahoma", Red);

   ObjectDelete("s4");
   ObjectCreate("s4", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), s4,TimeCurrent()+30*24*60*60,s4);
   ObjectSet("s4", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("s4", OBJPROP_RAY, false);
   ObjectSet("s4", OBJPROP_COLOR, Red);
   ObjectSet("s4", OBJPROP_WIDTH, 0);
   
   ObjectDelete("s4t");
   ObjectCreate("s4t", OBJ_TEXT , 0,Time[0]+7*24*60*60,s4);
   ObjectSetText("s4t", "S4", 8, "Tahoma", Red);
   
   ObjectDelete("r1");
   ObjectCreate("r1", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), r1,TimeCurrent()+30*24*60*60,r1);
   ObjectSet("r1", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("r1", OBJPROP_RAY, false);
   ObjectSet("r1", OBJPROP_COLOR, Red);
   ObjectSet("r1", OBJPROP_WIDTH, 0);
   
   ObjectDelete("r1t");
   ObjectCreate("r1t", OBJ_TEXT , 0,Time[0]+7*24*60*60,r1);
   ObjectSetText("r1t", "R1", 8, "Tahoma", Red);
   
   ObjectDelete("r2");
   ObjectCreate("r2", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), r2,TimeCurrent()+30*24*60*60,r2);
   ObjectSet("r2", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("r2", OBJPROP_RAY, false);
   ObjectSet("r2", OBJPROP_COLOR, Red);
   ObjectSet("r2", OBJPROP_WIDTH, 0);
   
   ObjectDelete("r2t");
   ObjectCreate("r2t", OBJ_TEXT , 0,Time[0]+7*24*60*60,r2);
   ObjectSetText("r2t", "R2", 8, "Tahoma", Red);
   
   ObjectDelete("r3");
   ObjectCreate("r3", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), r3,TimeCurrent()+30*24*60*60,r3);
   ObjectSet("r3", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("r3", OBJPROP_RAY, false);
   ObjectSet("r3", OBJPROP_COLOR, Red);
   ObjectSet("r3", OBJPROP_WIDTH, 0);
   
   ObjectDelete("r3t");
   ObjectCreate("r3t", OBJ_TEXT , 0,Time[0]+7*24*60*60,r3);
   ObjectSetText("r3t", "R3", 8, "Tahoma", Red);

   ObjectDelete("r4");
   ObjectCreate("r4", OBJ_TREND , 0,iTime(Symbol(),PERIOD_W1,1), r4,TimeCurrent()+30*24*60*60,r4);
   ObjectSet("r4", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("r4", OBJPROP_RAY, false);
   ObjectSet("r4", OBJPROP_COLOR, Red);
   ObjectSet("r4", OBJPROP_WIDTH, 0);
   
   ObjectDelete("r4t");
   ObjectCreate("r4t", OBJ_TEXT , 0,Time[0]+7*24*60*60,r4);
   ObjectSetText("r4t", "R4", 8, "Tahoma", Red);
   
   
   
   ObjectDelete("Start");
   ObjectCreate("Start",OBJ_VLINE,0,iTime(Symbol(),PERIOD_W1,1),0);
   ObjectSet("Start", OBJPROP_STYLE, STYLE_DASH);
   ObjectSet("Start", OBJPROP_COLOR, Red);
   ObjectSet("Start", OBJPROP_WIDTH, 0);
   
//----
   return(0);
  }
//+------------------------------------------------------------------+