//+------------------------------------------------------------------+
//|Индикатор показывает максимум и минимум за последние N свечей     |
//|                               Copyright © 2012, Хлыстов Владимир |
//|                                                cmillion@narod.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, http://cmillion.narod.ru"
#property link      "cmillion@narod.ru"
#property indicator_chart_window
//--------------------------------------------------------------------
extern int    N = 45;        //кол-во контрольных свечей
//--------------------------------------------------------------------
int deinit()
{
   ObjectDelete("Max");
   ObjectDelete("Min");
   ObjectDelete("Max1");
   ObjectDelete("Min1");
}
//--------------------------------------------------------------------
int start()
{
   double Max = iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,N,0)); 
   double Min = iLow(NULL,0,iLowest(NULL,0,MODE_LOW,N,0)); 
   ARROW("Max",Time[0],Max,Blue,6);                     
   ARROW("Min",Time[0],Min,Red,6);                     
   TREND("Max1",Time[N],Max,Time[0],Max,Blue,0,1);                     
   TREND("Min1",Time[N],Min,Time[0],Min,Red,0,1);                     
   return(0);
}
//--------------------------------------------------------------------
void ARROW(string name, datetime T1, double P1, color C, int ARROWCODE)
{
   ObjectDelete(name);                     
   ObjectCreate(name,OBJ_ARROW,0,T1,P1,0,0,0,0);                     
   ObjectSet   (name,OBJPROP_ARROWCODE,ARROWCODE);
   ObjectSet   (name,OBJPROP_COLOR, C);
}
//--------------------------------------------------------------------+
void TREND(string name, datetime T1, double P1, datetime T2, double P2, color C, int STYLE, int WIDTH)
{
   ObjectDelete(name);                     
   ObjectCreate(name, OBJ_TREND,0,T1,P1,T2,P2);                     
   ObjectSet   (name, OBJPROP_COLOR, C);   
   ObjectSet   (name, OBJPROP_STYLE, STYLE);
   ObjectSet   (name, OBJPROP_WIDTH, WIDTH);
   ObjectSet   (name, OBJPROP_BACK,  true);
   ObjectSet   (name, OBJPROP_RAY,   false); 
}
//--------------------------------------------------------------------+


