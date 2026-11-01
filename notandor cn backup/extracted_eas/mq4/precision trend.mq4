//+------------------------------------------------------------------+
//|                                              precision trend.mq4 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_chart_window
#property indicator_buffers  2
#property indicator_color1   Green
#property indicator_color2   Red
#property indicator_width1   1
#property indicator_width2   1
#property strict

//
//
//
//
//

extern int    avgPeriod   = 30; // Average period
extern double sensitivity = 3;  // Sensitivity

double upBuffer[],dnBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   SetIndexBuffer(0,upBuffer); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,dnBuffer); SetIndexStyle(1,DRAW_HISTOGRAM);
   return(0);
}
int deinit() { return(0); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double wrkBuffer[][7];
int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (ArrayRange(wrkBuffer,0) != Bars) ArrayResize(wrkBuffer,Bars);
         
   //
   //
   //
   //
   //
            
   for(int i=limit, r=Bars-i-1; i>=0; i--,r++)
   {
      upBuffer[i]     = EMPTY_VALUE;
      dnBuffer[i]     = EMPTY_VALUE;
      wrkBuffer[r][0] = High[i]-Low[i];
      wrkBuffer[r][2] = wrkBuffer[r][0];
      int k=1; for (; k<avgPeriod && (r-k)>=0; k++) wrkBuffer[r][2] += wrkBuffer[r-k][0];
                                                    wrkBuffer[r][2] /= k;
                                                    wrkBuffer[r][2] *= sensitivity;
   
         //
         //
         //
         //
         //
         
         if (i==(Bars-1))
         {
            wrkBuffer[r][1] = 0;
            wrkBuffer[r][3] = Close[i]-wrkBuffer[r][2];
            wrkBuffer[r][4] = Close[i]+wrkBuffer[r][2];
            wrkBuffer[r][5] = Close[i];
            wrkBuffer[r][6] = Close[i];
            continue;
         }
         else
         {
            wrkBuffer[r][1] = wrkBuffer[r-1][1];
            wrkBuffer[r][3] = wrkBuffer[r-1][3];
            wrkBuffer[r][4] = wrkBuffer[r-1][4];
            wrkBuffer[r][5] = wrkBuffer[r-1][5];
            wrkBuffer[r][6] = wrkBuffer[r-1][6];
         }
         
         //
         //
         //
         //
         //

         if (wrkBuffer[r][1] == 0)
         {
            if (Close[i] > wrkBuffer[r-1][4])
            {
               wrkBuffer[r][5] = Close[i];
               wrkBuffer[r][3] = Close[i]-wrkBuffer[r][2];
               wrkBuffer[r][1] =  1;
            }
            if (Close[i] < wrkBuffer[r-1][3])
            {
               wrkBuffer[r][6] = Close[i];
               wrkBuffer[r][4] = Close[i]+wrkBuffer[r][2];
               wrkBuffer[r][1] = -1;
            }
         }            

         if (wrkBuffer[r-1][1] == 1)
         {
            wrkBuffer[r][3] = wrkBuffer[r-1][5] - wrkBuffer[r][2];
               if (Close[i] > wrkBuffer[r-1][5])  wrkBuffer[r][5] = Close[i];
               if (Close[i] < wrkBuffer[r-1][3])
               {
                  wrkBuffer[r][6] = Close[i];
                  wrkBuffer[r][4] = Close[i]+wrkBuffer[r][2];
                  wrkBuffer[r][1] = -1;
            }
         }            

         if (wrkBuffer[r-1][1] == -1)
         {
            wrkBuffer[r][4] = wrkBuffer[r-1][6] + wrkBuffer[r][2];
               if (Close[i] < wrkBuffer[r-1][6])  wrkBuffer[r][6] = Close[i];
               if (Close[i] > wrkBuffer[r-1][4])
               {
                  wrkBuffer[r][5] = Close[i];
                  wrkBuffer[r][3] = Close[i]-wrkBuffer[r][2];
                  wrkBuffer[r][1] = 1;
               }
         }
         
         //
         //
         //
         //
         //
                     
         if (wrkBuffer[r][1] == 1)
         {
            upBuffer[i] = High[i]; dnBuffer[i] = Low[i];
         }
         if (wrkBuffer[r][1] == -1)
         {
            dnBuffer[i] = High[i]; upBuffer[i] = Low[i];
         }            
   }
   return(0);
}