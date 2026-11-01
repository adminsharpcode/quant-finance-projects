//+------------------------------------------------------------------+
//|                                                 ZeroLag MACD.mq4 |
//|                                                               RD |
//|                                                 marynarz15@wp.pl |
//+------------------------------------------------------------------+
// https://www.forexfactory.com/thread/295224-zerolag-macd

#property copyright "RD"
#property link      "marynarz15@wp.pl"

#property indicator_separate_window
#property  indicator_buffers   4
#property indicator_color1     clrDarkGreen
#property indicator_color2     clrMaroon
#property indicator_color3     clrNavy
#property indicator_color4     clrGoldenrod
#property indicator_width1     2
#property indicator_width2     2
#property indicator_width3     2
#property indicator_width4     2
#property indicator_level1     0 
#property indicator_levelcolor clrMediumOrchid
#property strict

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen,     // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2, // Heiken ashi trend biased (extreme) price
   pr_habclose,   // Heiken ashi (better formula) close
   pr_habopen,    // Heiken ashi (better formula) open
   pr_habhigh,    // Heiken ashi (better formula) high
   pr_hablow,     // Heiken ashi (better formula) low
   pr_habmedian,  // Heiken ashi (better formula) median
   pr_habtypical, // Heiken ashi (better formula) typical
   pr_habweighted,// Heiken ashi (better formula) weighted
   pr_habaverage, // Heiken ashi (better formula) average
   pr_habmedianb, // Heiken ashi (better formula) median body
   pr_habtbiased, // Heiken ashi (better formula) trend biased price
   pr_habtbiased2 // Heiken ashi (better formula) trend biased (extreme) price
};

enum enMaTypes
{
   ma_sma,     // Simple moving average
   ma_ema,     // Exponential moving average
   ma_smma,    // Smoothed MA
   ma_lwma,    // Linear weighted MA
   ma_slwma,   // Smoothed LWMA
   ma_dsema,   // Double Smoothed Exponential average
   ma_tema,    // Triple exponential moving average - TEMA
   ma_lsma,    // Linear regression value (lsma)
   ma_dema     // Double exponential moving average - DEMA
};

extern ENUM_TIMEFRAMES TimeFrame   = PERIOD_CURRENT;    // Time frame
extern int             FastMa      = 4;                 // Fast ma period
extern int             SlowMa      = 10;                // Slow ma period
extern int             SignalMa    = 5;                 // Signal ma period
extern enPrices        MaPrice     = pr_close;          // Moving average price to use 
extern enMaTypes       MaMode      = ma_ema;            // Moving average method  
//Forex-Station button template start41; copy and paste
extern string             button_note1          = "------------------------------"; // ------------------------------
extern int                btn_Subwindow         = 0;                                // What window to put the button on.  If <0, the button will use the same sub-window as the indicator.
extern ENUM_BASE_CORNER   btn_corner            = CORNER_LEFT_UPPER;                // button corner on chart for anchoring
extern string             btn_text              = "MACD FAST";                      // a button name
extern string             btn_Font              = "Arial";                          // button font name
extern int                btn_FontSize          = 9;                                // button font size               
extern color              btn_text_ON_color     = clrLime;                          // ON color when the button is turned on
extern color              btn_text_OFF_color    = clrRed;                           // OFF color when the button is turned off
extern color              btn_background_color  = clrDimGray;                       // background color of the button
extern color              btn_border_color      = clrBlack;                         // border color the button
extern int                button_x              = 20;                               // x coordinate of the button     
extern int                button_y              = 215;                              // y coordinate of the button     
extern int                btn_Width             = 80;                               // button width
extern int                btn_Height            = 20;                               // button height
extern string             UniqueButtonID        = "ZMACDfast";                      // Unique ID for each button        
extern string             button_note2          = "------------------------------"; // ------------------------------
extern bool               Interpolate           = true;                             // Interpolate in multi time frame mode?
bool show_data, recalc=false;
string IndicatorObjPrefix, buttonId;
//Forex-Station button template end41; copy and paste
//"",btn_Subwindow,btn_corner,btn_text,btn_Font,btn_FontSize,btn_text_ON_color,btn_text_OFF_color,btn_background_color,btn_border_color,button_x,button_y,btn_Width,btn_Height,UniqueButtonID,"",

double huu[],hdd[],macd[],sign[],fast[],slow[],signMa[],trend[],count[];
string names[] = {"SMA","EMA","SMMA","LWMA","SLWMA,DSEMA","TEMA","LSMA","DEMA"};
string indicatorFileName;
#define _mtfCall(_buff,_y) iCustom(NULL,TimeFrame,indicatorFileName,PERIOD_CURRENT,FastMa,SlowMa,SignalMa,MaPrice,MaMode,"",btn_Subwindow,btn_corner,btn_text,btn_Font,btn_FontSize,btn_text_ON_color,btn_text_OFF_color,btn_background_color,btn_border_color,button_x,button_y,btn_Width,btn_Height,UniqueButtonID,"",_buff,_y)

//+------------------------------------------------------------------------------------------------------------------+
//Forex-Station button template start42; copy and paste
int OnInit()
{
   IndicatorDigits(Digits);
   IndicatorObjPrefix = "_" + btn_text + "_";
      
   // The leading "_" gives buttonId a *unique* prefix.  Furthermore, prepending the swin is usually unique unless >2+ of THIS indy are displayed in the SAME sub-window. (But, if >2 used, be sure to shift the buttonId position)
   buttonId = "_" + UniqueButtonID + IndicatorObjPrefix + "_BT_";
   if (ObjectFind(buttonId)<0) 
      createButton(buttonId, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize, btn_background_color, btn_border_color, btn_text_ON_color);
   ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);  

   init2();
   show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);
  
   if (show_data) ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color); 
   else ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------------------------------------------------------+
void createButton(string buttonID,string buttonText,int width2,int height,string font,int fontSize,color bgColor,color borderColor,color txtColor)
{
      ObjectDelete    (0,buttonID);
      ObjectCreate    (0,buttonID,OBJ_BUTTON,btn_Subwindow,0,0);
      ObjectSetInteger(0,buttonID,OBJPROP_COLOR,txtColor);
      ObjectSetInteger(0,buttonID,OBJPROP_BGCOLOR,bgColor);
      ObjectSetInteger(0,buttonID,OBJPROP_BORDER_COLOR,borderColor);
      ObjectSetInteger(0,buttonID,OBJPROP_BORDER_TYPE,BORDER_RAISED);
      ObjectSetInteger(0,buttonID,OBJPROP_XSIZE,width2);
      ObjectSetInteger(0,buttonID,OBJPROP_YSIZE,height);
      ObjectSetString (0,buttonID,OBJPROP_FONT,font);
      ObjectSetString (0,buttonID,OBJPROP_TEXT,buttonText);
      ObjectSetInteger(0,buttonID,OBJPROP_FONTSIZE,fontSize);
      ObjectSetInteger(0,buttonID,OBJPROP_SELECTABLE,0);
      ObjectSetInteger(0,buttonID,OBJPROP_CORNER,btn_corner);
      ObjectSetInteger(0,buttonID,OBJPROP_HIDDEN,1);
      ObjectSetInteger(0,buttonID,OBJPROP_XDISTANCE,9999);
      ObjectSetInteger(0,buttonID,OBJPROP_YDISTANCE,9999);
      // Upon creation, set the initial state to "true" which is "on", so one will see the indicator by default
      ObjectSetInteger(0, buttonId, OBJPROP_STATE, true);
}
//+------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
   // If just changing a TF', the button need not be deleted, therefore the 'OBJPROP_STATE' is also preserved.
   if(reason != REASON_CHARTCHANGE) ObjectDelete(buttonId);
}
//+------------------------------------------------------------------------------------------------------------------+
void OnChartEvent(const int id, //don't change anything here
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // If another indy on the same chart has enabled events for create/delete/mouse-move, just skip this events up front because they aren't
   //    needed, AND in the worst case, this indy might cause MT4 to hang!!  Skipping the events seems to help, along with other (major) changes to the code below.
   if(id==CHARTEVENT_OBJECT_CREATE || id==CHARTEVENT_OBJECT_DELETE) return; // This appears to make this indy compatible with other programs that enabled CHART_EVENT_OBJECT_CREATE and/or CHART_EVENT_OBJECT_DELETE
   if(id==CHARTEVENT_MOUSE_MOVE    || id==CHARTEVENT_MOUSE_WHEEL)   return; // If this, or another program, enabled mouse-events, these are not needed below, so skip it unless actually needed. 

   if (id==CHARTEVENT_OBJECT_CLICK && sparam == buttonId)
   {
      show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);
      
      if (show_data)
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color); 
         // Is it a problem to call 'start()' ??  Possibly it makes no difference, but now calling "mystart()" instead of "start()"; and "start()" simply runs "mystart()", so should be same as before.
         recalc=true;
         init2();
         mystart();
      }
      else
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
         for (int MACD_counter=0; MACD_counter<indicator_buffers; MACD_counter++)
              SetIndexStyle(MACD_counter,DRAW_NONE);
      }
   }
}
//Forex-Station button template end42; copy and paste
//+------------------------------------------------------------------------------------------------------------------+
int start() {return(mystart()); }
//+------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
//
//

int init2()
{
   IndicatorBuffers(9);
   SetIndexBuffer(0,huu);   SetIndexStyle(0,DRAW_HISTOGRAM);  SetIndexLabel(0,"MACD UP");
   SetIndexBuffer(1,hdd);   SetIndexStyle(1,DRAW_HISTOGRAM);  SetIndexLabel(1,"MACD Down");
   SetIndexBuffer(2,sign);  SetIndexStyle(2,DRAW_LINE);       SetIndexLabel(2,"Signal");
   SetIndexBuffer(3,macd);  SetIndexStyle(3,DRAW_LINE);       SetIndexLabel(3,"Macd");
   SetIndexBuffer(4,fast);
   SetIndexBuffer(5,slow);
   SetIndexBuffer(6,signMa);
   SetIndexBuffer(7,trend);
   SetIndexBuffer(8,count);
   
   indicatorFileName = WindowExpertName();
   TimeFrame         = fmax(TimeFrame,_Period); 
   
   IndicatorShortName("[" + _Symbol + "] [" + timeFrameToString(TimeFrame)+"] ZeroLag MACD of " + names[MaMode] + " (" + (string)FastMa + "," +( string)SlowMa + "," + (string)SignalMa + ")");
return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int mystart()
  {
   int i,counted_bars=IndicatorCounted();
   if (show_data)
      {
        if(recalc) 
        {
           // If a button goes from off-to-on, everything must be recalculated.  The 'recalc' variable is used as a trigger to do this.
           counted_bars = 0;
           recalc=false;
        }
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
         int limit = fmin(Bars-counted_bars,Bars-1); count[0]=limit;
            if (TimeFrame!=_Period)
            {
               limit = (int)fmax(limit,fmin(Bars-1,_mtfCall(8,0)*TimeFrame/_Period));
               for (i=limit;i>=0 && !_StopFlag; i--)
               {
                  int y = iBarShift(NULL,TimeFrame,Time[i]);
                     sign[i]  = _mtfCall(2,y);
                     macd[i]  = _mtfCall(3,y);
                     trend[i] = _mtfCall(7,y);
                     
                     //
                     //
                     //
                     //
                     //
                     
                     if (!Interpolate || (i>0 && y==iBarShift(NULL,TimeFrame,Time[i-1]))) continue;
                        #define _interpolate(buff) buff[i+k] = buff[i]+(buff[i+n]-buff[i])*k/n
                        int n,k; datetime time = iTime(NULL,TimeFrame,y);
                           for(n = 1; (i+n)<Bars && Time[i+n] >= time; n++) continue;	
                           for(k = 1; k<n && (i+n)<Bars && (i+k)<Bars; k++)
                           {
                               _interpolate(sign);  
                               _interpolate(macd);   
                           }                                        
               }
               for(i=limit; i>=0; i--) 
               {
                  huu[i] = (trend[i] == 1) ? macd[i] : EMPTY_VALUE;
                  hdd[i] = (trend[i] ==-1) ? macd[i] : EMPTY_VALUE;    
               }
   return(0);
   }
   
   //
   //
   //
   //
   //
   
   for(i=limit; i>=0; i--)
   {
      double EMA,ZLEMAp,ZLEMAq;
      double price = getPrice(MaPrice,Open,Close,High,Low,i,Bars);
            fast[i]   = iCustomMa(MaMode,price,FastMa,i,Bars,0);
            slow[i]   = iCustomMa(MaMode,price,SlowMa,i,Bars,1);  
            EMA       = iCustomMa(MaMode,fast[i],FastMa,i,Bars,2);
            ZLEMAp    = fast[i]+fast[i]-EMA;
            EMA       = iCustomMa(MaMode,slow[i],SlowMa,i,Bars,3);
            ZLEMAq    = slow[i]+slow[i]-EMA;
            macd[i]   = ZLEMAp - ZLEMAq;
            signMa[i] = iCustomMa(MaMode,macd[i],SignalMa,i,Bars,4);
            EMA       = iCustomMa(MaMode,signMa[i],SignalMa,i,Bars,5);
            sign[i]   = signMa[i]+signMa[i]-EMA;
            trend[i] = (i<Bars-1) ? (macd[i]>0) ? 1 : (macd[i]<0) ? -1 : trend[i+1] : 0;
            huu[i] = (trend[i] == 1) ? macd[i] : EMPTY_VALUE;
            hdd[i] = (trend[i] ==-1) ? macd[i] : EMPTY_VALUE;        
    }
      } //if (show_data)  
return(0);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

#define _maInstances 6
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances
#define _maWorkBufferx3 3*_maInstances

double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   r = bars-r-1;
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)MathCeil(length),r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)MathCeil(length),r,bars,instanceNo));
      case ma_slwma : return(iSlwma(price,(int)MathCeil(length),r,bars,instanceNo));
      case ma_dsema : return(iDsema(price,length,r,bars,instanceNo));
      case ma_tema  : return(iTema(price,length,r,bars,instanceNo));
      case ma_lsma  : return(iLinr(price,(int)MathCeil(length),r,bars,instanceNo));
      case ma_dema  : return(iDema(price,length,r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//
//
//

double workSma[][_maWorkBufferx1];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo+0] = price;
   double avg = price; int k=1;  for(; k<period && (r-k)>=0; k++) avg += workSma[r-k][instanceNo+0];  
   return(avg/(double)k);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo] = price;
   if (r>1 && period>1)
          workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
   workLwma[r][instanceNo] = price; if (period<=1) return(price);
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}

//
//
//
//
//


double workSlwma[][_maWorkBufferx2];
double iSlwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSlwma,0)!= _bars) ArrayResize(workSlwma,_bars); 

   //
   //
   //
   //
   //

      int SqrtPeriod = (int)MathFloor(MathSqrt(period)); instanceNo *= 2;
         workSlwma[r][instanceNo] = price;

         //
         //
         //
         //
         //
               
         double sumw = period;
         double sum  = period*price;
   
         for(int k=1; k<period && (r-k)>=0; k++)
         {
            double weight = period-k;
                   sumw  += weight;
                   sum   += weight*workSlwma[r-k][instanceNo];  
         }             
         workSlwma[r][instanceNo+1] = (sum/sumw);

         //
         //
         //
         //
         //
         
         sumw = SqrtPeriod;
         sum  = SqrtPeriod*workSlwma[r][instanceNo+1];
            for(int k=1; k<SqrtPeriod && (r-k)>=0; k++)
            {
               double weight = SqrtPeriod-k;
                      sumw += weight;
                      sum  += weight*workSlwma[r-k][instanceNo+1];  
            }
   return(sum/sumw);
}

//
//
//
//
//

double workDsema[][_maWorkBufferx2];
#define _ema1 0
#define _ema2 1

double iDsema(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workDsema,0)!= _bars) ArrayResize(workDsema,_bars); instanceNo*=2;

   //
   //
   //
   //
   //
   
   workDsema[r][_ema1+instanceNo] = price;
   workDsema[r][_ema2+instanceNo] = price;
   if (r>0 && period>1)
   {
      double alpha = 2.0 /(1.0+MathSqrt(period));
          workDsema[r][_ema1+instanceNo] = workDsema[r-1][_ema1+instanceNo]+alpha*(price                         -workDsema[r-1][_ema1+instanceNo]);
          workDsema[r][_ema2+instanceNo] = workDsema[r-1][_ema2+instanceNo]+alpha*(workDsema[r][_ema1+instanceNo]-workDsema[r-1][_ema2+instanceNo]); }
   return(workDsema[r][_ema2+instanceNo]);
}

//
//
//
//
//

double workTema[][_maWorkBufferx3];
#define _tema1 0
#define _tema2 1
#define _tema3 2

double iTema(double price, double period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workTema,0)!= bars) ArrayResize(workTema,bars); instanceNo*=3;

   //
   //
   //
   //
   //
      
   workTema[r][_tema1+instanceNo] = price;
   workTema[r][_tema2+instanceNo] = price;
   workTema[r][_tema3+instanceNo] = price;
   if (r>0 && period>1)
   {
      double alpha = 2.0 / (1.0+period);
          workTema[r][_tema1+instanceNo] = workTema[r-1][_tema1+instanceNo]+alpha*(price                         -workTema[r-1][_tema1+instanceNo]);
          workTema[r][_tema2+instanceNo] = workTema[r-1][_tema2+instanceNo]+alpha*(workTema[r][_tema1+instanceNo]-workTema[r-1][_tema2+instanceNo]);
          workTema[r][_tema3+instanceNo] = workTema[r-1][_tema3+instanceNo]+alpha*(workTema[r][_tema2+instanceNo]-workTema[r-1][_tema3+instanceNo]); }
   return(workTema[r][_tema3+instanceNo]+3.0*(workTema[r][_tema1+instanceNo]-workTema[r][_tema2+instanceNo]));
}

//
//
//
//
//

double workLinr[][_maWorkBufferx1];
double iLinr(double price, int period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workLinr,0)!= bars) ArrayResize(workLinr,bars);

   //
   //
   //
   //
   //
   
      period = MathMax(period,1);
      workLinr[r][instanceNo] = price;
      if (r<period) return(price);
         double lwmw = period; double lwma = lwmw*price;
         double sma  = price;
         for(int k=1; k<period && (r-k)>=0; k++)
         {
            double weight = period-k;
                   lwmw  += weight;
                   lwma  += weight*workLinr[r-k][instanceNo];  
                   sma   +=        workLinr[r-k][instanceNo];
         }             
   
   return(3.0*lwma/lwmw-2.0*sma/period);
}

//
//
//
//
//

double workDema[][_maWorkBufferx2];
#define _dema1 0
#define _dema2 1

double iDema(double price, double period, int r, int bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workDema,0)!= bars) ArrayResize(workDema,bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   workDema[r][_dema1+instanceNo] = price;
   workDema[r][_dema2+instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
   {
          workDema[r][_dema1+instanceNo] = workDema[r-1][_dema1+instanceNo]+alpha*(price                         -workDema[r-1][_dema1+instanceNo]);
          workDema[r][_dema2+instanceNo] = workDema[r-1][_dema2+instanceNo]+alpha*(workDema[r][_dema1+instanceNo]-workDema[r-1][_dema2+instanceNo]); }
   return(workDema[r][_dema1+instanceNo]*2.0-workDema[r][_dema2+instanceNo]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

#define _prHABF(_prtype) (_prtype>=pr_habclose && _prtype<=pr_habtbiased2)
#define _priceInstances     1
#define _priceInstancesSize 4
double workHa[][_priceInstances*_priceInstancesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= Bars) ArrayResize(workHa,Bars); instanceNo*=_priceInstancesSize; int r = bars-i-1;
         
         //
         //
         //
         //
         //
         
         double haOpen  = (r>0) ? (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0 : (open[i]+close[i])/2;;
         double haClose = (open[i]+high[i]+low[i]+close[i]) / 4.0;
         if (_prHABF(tprice))
               if (high[i]!=low[i])
                     haClose = (open[i]+close[i])/2.0+(((close[i]-open[i])/(high[i]-low[i]))*MathAbs((close[i]-open[i])/2.0));
               else  haClose = (open[i]+close[i])/2.0; 
         double haHigh  = fmax(high[i], fmax(haOpen,haClose));
         double haLow   = fmin(low[i] , fmin(haOpen,haClose));

         //
         //
         //
         //
         //
         
         if(haOpen<haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else               { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                              workHa[r][instanceNo+2] = haOpen;
                              workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:
            case pr_habclose:    return(haClose);
            case pr_haopen:   
            case pr_habopen:     return(haOpen);
            case pr_hahigh: 
            case pr_habhigh:     return(haHigh);
            case pr_halow:    
            case pr_hablow:      return(haLow);
            case pr_hamedian:
            case pr_habmedian:   return((haHigh+haLow)/2.0);
            case pr_hamedianb:
            case pr_habmedianb:  return((haOpen+haClose)/2.0);
            case pr_hatypical:
            case pr_habtypical:  return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:
            case pr_habweighted: return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:  
            case pr_habaverage:  return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
            case pr_habtbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
            case pr_habtbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
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
