//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-station.com"
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 2
#property indicator_color1  clrNONE
#property indicator_color2  clrNONE
#property indicator_width1  2
#property indicator_style2  STYLE_DOT
#property strict

//
//
//

enum enTimeFrames
{
         tf_cu  = 0,                                                 // Current time frame
         tf_m1  = PERIOD_M1,                                         // 1 minute
         tf_m5  = PERIOD_M5,                                         // 5 minutes
         tf_m15 = PERIOD_M15,                                        // 15 minutes
         tf_m30 = PERIOD_M30,                                        // 30 minutes
         tf_h1  = PERIOD_H1,                                         // 1 hour
         tf_h4  = PERIOD_H4,                                         // 4 hours
         tf_d1  = PERIOD_D1,                                         // Daily
         tf_w1  = PERIOD_W1,                                         // Weekly
         tf_mn1 = PERIOD_MN1,                                        // Monthly
         tf_n1  = -1,                                                // First higher time frame
         tf_n2  = -2,                                                // Second higher time frame
         tf_n3  = -3,                                                // Third higher time frame
         tf_cus = 12345678                                           // Custom time frame
};
extern enTimeFrames  TimeFrame      = tf_cu;   
input int            KPeriod        = 5;
input int            DPeriod        = 3;
input int            Slowing        = 3;
input ENUM_MA_METHOD MAMode         = MODE_SMA;
enum  enStoPrice
{
   pr_close,    // Close/Close
   pr_open,     // Open/Open
   pr_high,     // High/High
   pr_low,      // Low/Low
   pr_median,   // Median/Median
   pr_typical,  // Typical/Typical
   pr_weighted, // Weighted/Weighted
   pr_hilo      // Low/High
};
input enStoPrice     Price          = pr_hilo;    
input double         Level1         = 75;
input double         Level2         = 25;
input bool           Interpolate    = true;                // Interpolate multi time frame data?

double sto[],sig[],HighesBuffer[],LowesBuffer[],HighesBuffera[],LowesBuffera[],cnt[];
string indicatorFileName;
#define _mtfCall(_buff,_ind) iCustom(NULL,TimeFrame,indicatorFileName,tf_cu,KPeriod,DPeriod,Slowing,MAMode,Price,Level1,Level2,_buff,_ind)

//------------------------------------------------------------------
//
//------------------------------------------------------------------

int OnInit()
{
   IndicatorBuffers(7);
   SetIndexBuffer(0,sto,INDICATOR_DATA); SetIndexStyle(0,DRAW_LINE); SetIndexLabel(0,"Stochastic");
   SetIndexBuffer(1,sig,INDICATOR_DATA); SetIndexStyle(0,DRAW_LINE); SetIndexLabel(1,"Signal");
   SetIndexBuffer(2,HighesBuffer);
   SetIndexBuffer(3,LowesBuffer);
   SetIndexBuffer(4,HighesBuffera);
   SetIndexBuffer(5,LowesBuffera);
   SetIndexBuffer(6,cnt);
   
   SetLevelValue(0,Level1);
   SetLevelValue(1,Level2);
   
   indicatorFileName = WindowExpertName();
   TimeFrame         = (enTimeFrames)timeFrameValue(TimeFrame);
      
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(TimeFrame)+" Stochastic ("+(string)KPeriod+","+(string)DPeriod+","+(string)Slowing+")");
return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
//
//------------------------------------------------------------------

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int i,limit = rates_total-(prev_calculated>0 ? prev_calculated : 1); cnt[0] = limit;
      if (TimeFrame != _Period)
      {
        limit = (int)fmax(limit,fmin(rates_total-1,_mtfCall(6,0)*TimeFrame/_Period));
        for (i=limit;i>=0 && !_StopFlag; i--)
        {
           int y = iBarShift(NULL,TimeFrame,time[i]);
              sto[i] = _mtfCall(0,y);
              sig[i] = _mtfCall(1,y);
   	        
              //
              //
              //
          
              if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,time[i-1]))) continue;
              #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
              int n,k; datetime itime = iTime(NULL,TimeFrame,y);
                 for(n = 1; (i+n)<rates_total && time[i+n] >= itime; n++) continue;	
                 for(k = 1; k<n && (i+n)<rates_total && (i+k)<rates_total; k++) 
                 {
                    _interpolate(sto);
                    _interpolate(sig);
                 } 
      }
   return(rates_total);
   }
   
   //
   //
   //
   
   for(i=limit; i>=0; i--)
   {
      if (Price==pr_hilo)
      {
         LowesBuffera[i]  = low[i];
         HighesBuffera[i] = high[i];
      }
      else         
      {
         LowesBuffera[i] = iMA(NULL,0,1,0,MODE_SMA,(int)Price,i);
         HighesBuffera[i]= iMA(NULL,0,1,0,MODE_SMA,(int)Price,i);
      }
      LowesBuffer[i] =  LowesBuffera[ArrayMinimum(LowesBuffera,KPeriod,i)];
      HighesBuffer[i]= HighesBuffera[ArrayMaximum(HighesBuffera,KPeriod,i)];
      
      //
      //
      //
      
      double sumlo  = 0.0,sumhi = 0.0;
      for(int k=0;k<Slowing && (i+k)<rates_total;k++)
      {
         if (Price==pr_hilo)
               sumlo += close[i+k]       -LowesBuffer[i+k];
         else  sumlo += LowesBuffera[i+k]-LowesBuffer[i+k];     
               sumhi += HighesBuffer[i+k]-LowesBuffer[i+k];
       }
       sto[i] = (sumhi==0.0) ? 100.0 : sumlo/sumhi*100.0;
   }      
   for(i=0; i<limit; i++) sig[i]=iMAOnArray(sto,0,DPeriod,0,MAMode,i);
return(rates_total);
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
int timeFrameValue(int _tf)
{
   int add  = (_tf>=0) ? 0 : fabs(_tf);
   if (add != 0) _tf = _Period;
   int size = ArraySize(iTfTable); 
      int i =0; for (;i<size; i++) if (iTfTable[i]==_tf) break;
                                   if (i==size) return(_Period);
                                                return(iTfTable[(int)fmin(i+add,size-1)]);
}