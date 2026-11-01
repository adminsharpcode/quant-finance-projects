//+------------------------------------------------------------------+
//|                                                Master_Candle.mq4 |
//|                                                         Zen_Leow |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Zen_Leow"
#property link      ""

#property indicator_chart_window

extern int MinEngulfCandles = 4;
extern color TopLineColor = Lime ;
extern color BottomLineColor = Magenta;
extern int LineWidth = 2;
extern bool WaitForCandleClose = true;
extern bool IgnoreWick = false;
extern bool SoundAlert = true;

int IndexOffset = 0;
datetime LastAlertTime;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   if (WaitForCandleClose)
   {
      IndexOffset = 0;
   }
   else
   {
      IndexOffset = 1;
   }
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
//----
   int    obj_total=ObjectsTotal();
   string name, topLine, bottomLine;
   topLine = Symbol()+"_"+Period()+"_MasterTop_";
   bottomLine = Symbol()+"_"+Period()+"_MasterBottom_";
   for(int i=obj_total-1; i>=0; i--)
   {
      name=ObjectName(i);
      if (StringFind(name,topLine,0) != -1 || StringFind(name,bottomLine,0) != -1)
      {
         ObjectDelete(name);
      }
   }
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int i;                           // Bar index       
   int Counted_bars;                // Number of counted bars
   //--------------------------------------------------------------------   
   Counted_bars=IndicatorCounted(); // Number of counted bars   
   i=Bars-Counted_bars-1;           // Index of the first uncounted   
   
   // always recount the latest possible location for a master candle to be formed
   if (i == 0)
   {
      i = MinEngulfCandles+1; 
   }
   while(i>MinEngulfCandles-IndexOffset)                      // Loop for uncounted bars     
   {      
      if (isMasterCandle(i))
      {
         DrawLines(i);
         if (i == MinEngulfCandles-IndexOffset+1)
         {
            if (SoundAlert && LastAlertTime < Time[0])
            {
               Alert("Master Candle detected on "+Symbol()+" at candle: "+TimeToStr(Time[i],TIME_DATE|TIME_MINUTES));
               LastAlertTime = Time[0];
            }
         }
      }
      else
      {
         DeleteLines(i);
      }
      i--;
   }
//----
   return(0);
}

bool isMasterCandle(int index)
{
   double CandleTop = High[index];
   double CandleBottom = Low[index];
   
   for (int h = index-1; h >= index - MinEngulfCandles; h--)
   {
      if (IgnoreWick)
      {
         if (Close[h] >= Open[h]) // bull or doji candle
         {
            if (Close[h] > CandleTop || Open[h] < CandleBottom)
            {
               return (false);
            }
         }
         if (Close[h] <= Open[h]) // bear or doji candle
         {
            if (Open[h] > CandleTop || Close[h] < CandleBottom)
            {
               return (false);
            }
         }
      }
      else
      {
         if (High[h] > CandleTop || Low[h] < CandleBottom)
         {
            return (false);
         }
      }
   }
   
   return (true);
}

void DrawLines(int index)
{
   string TopName = Symbol()+"_"+Period()+"_MasterTop_" + Time[index];
   ObjectCreate(TopName, OBJ_TREND, 0, Time[index], High[index], Time[index - MinEngulfCandles], High[index]);
   ObjectSet(TopName, OBJPROP_RAY, false);
   ObjectSet(TopName, OBJPROP_WIDTH, LineWidth);
   ObjectSet(TopName, OBJPROP_COLOR, TopLineColor);
   
   string BottomName = Symbol()+"_"+Period()+"_MasterBottom_" + Time[index];
   ObjectCreate(BottomName, OBJ_TREND, 0, Time[index], Low[index], Time[index - MinEngulfCandles], Low[index]);
   ObjectSet(BottomName, OBJPROP_RAY, false);
   ObjectSet(BottomName, OBJPROP_WIDTH, LineWidth);
   ObjectSet(BottomName, OBJPROP_COLOR, BottomLineColor);
}

void DeleteLines(int index)
{
   string TopName = Symbol()+"_"+Period()+"_MasterTop_" + Time[index];
   string BottomName = Symbol()+"_"+Period()+"_MasterBottom_" + Time[index];
   if (ObjectFind(TopName) == 0 || ObjectFind(BottomName) == 0) // found in main chart window
   {
      ObjectDelete(TopName);
      ObjectDelete(BottomName);
      if (SoundAlert)
      {
         Alert("Master Candle REMOVED on "+Symbol()+" at candle: "+TimeToStr(Time[index],TIME_DATE|TIME_MINUTES));
      }
   }
}
//+------------------------------------------------------------------+