#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1  clrRed

//Input parameters
extern ENUM_TIMEFRAMES    TimeFrame   = PERIOD_CURRENT; // Time frame
extern int                Periods     = 20;
extern bool               Interpolate = true;           // Interpolate in multi time frame mode

//Indicator buffers
double CMF[],count[];
string indicatorFileName;
#define _mtfCall(_buff,_ind) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,Periods,_buff,_ind)

int init()
{
SetIndexStyle(0,DRAW_LINE);
SetIndexBuffer(0,CMF);
SetIndexBuffer(1,count);
SetIndexDrawBegin(0,Periods);

indicatorFileName = WindowExpertName();
TimeFrame         = fmax(TimeFrame,_Period); 

IndicatorShortName(timeFrameToString(TimeFrame)+" CMF("+Periods+")" );
return(0);
}

int deinit()
{
return(0);
}

int start()
{
    int i,counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = fmin(Bars-counted_bars,Bars-1); count[0]=limit;
            if (TimeFrame!=_Period)
            {
               limit = (int)fmax(limit,fmin(Bars-1,_mtfCall(1,0)*TimeFrame/_Period));
               for (i=limit;i>=0 && !_StopFlag; i--)
               {
                  int y = iBarShift(NULL,TimeFrame,Time[i]);
                     CMF[i] = _mtfCall(0,y);
                  
                     //
                     //
                     //
                     //
                     //
                     
                     if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                        #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
                        int n,k; datetime time = iTime(NULL,TimeFrame,y);
                           for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;	
                           for(k = 1; k<n && (i+n)<Bars && (i+k)<Bars; k++) _interpolate(CMF);
                                                   
               }
   return(0);
   }
   
   int shift;
   
   if(Bars<=Periods) return(0);
//---- initial zero
   if(counted_bars<1)
      for(i=1;i<=Periods;i++) CMF[Bars-i]=0.0;
//----
   if ( counted_bars > 0 )  limit=Bars-counted_bars;
   if ( counted_bars ==0 )  limit=Bars-Periods-1; 
   
   for(shift=limit;shift>=0;shift--)
   {	   
   double dN_Sum=0.0;
   double Volume_Sum=0.0;
      for(i=0;i<Periods-1;i++) 
      {	
      Volume_Sum+=Volume[shift+i];
      if((High[shift+i]-Low[shift+i])>0)
      dN_Sum += Volume[shift+i]*(Close[shift+i]-Open[shift+i])/(High[shift+i]-Low[shift+i]);
      }
   CMF[shift]=dN_Sum/Volume_Sum;
   }
return(0);
}

//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
