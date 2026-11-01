//------------------------------------------------------------------
// not for sale, rent, auction, nor lease
// January 31st, 2020
// Fibo # 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987,  ...
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
#property description "not for sale, rent, auction, nor lease"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 12

#property indicator_color11  clrLime  //C'0,200,0'
#property indicator_color12 clrRed //C'164,5,39'

#property indicator_color9  clrLime //C'0,180,0'
#property indicator_color10 clrRed //C'154,5,39'

#property indicator_color7  clrLime //C'0,160,0'
#property indicator_color8  clrRed //C'144,5,39'

#property indicator_color5  clrDarkGreen //C'0,140,0'
#property indicator_color6  clrCrimson //C'134,5,39'

#property indicator_color3  clrDarkGreen //C'0,120,0'
#property indicator_color4  clrCrimson //C'124,5,39'

#property indicator_color1  clrDarkGreen //C'0,100,0' //clrDarkGreen
#property indicator_color2  clrCrimson // 

#property indicator_minimum 0
#property indicator_maximum 7

//template copy and paste start1
enum enTimeFrames
{
   tf_cu  = PERIOD_CURRENT, // Current time frame
   tf_m1  = PERIOD_M1,      // 1 minute
   tf_m5  = PERIOD_M5,      // 5 minutes
   tf_m15 = PERIOD_M15,     // 15 minutes
   tf_m30 = PERIOD_M30,     // 30 minutes
   tf_h1  = PERIOD_H1,      // 1 hour
   tf_h4  = PERIOD_H4,      // 4 hours
   tf_d1  = PERIOD_D1,      // Daily
   tf_w1  = PERIOD_W1,      // Weekly
   tf_mn1 = PERIOD_MN1,     // Monthly
   tf_n1  = -1,             // First higher time frame
   tf_n2  = -2,             // Second higher time frame
   tf_n3  = -3              // Third higher time frame
};
//template copy and paste end1

enum PriceMenu
{
   Low_High  = 0,      
   Close_Close = 1      
};
//template copy and paste start2
extern enTimeFrames       TimeFrame1               = tf_cu;   // Time frame
//template copy and paste end2
extern string             UniqueID                 = "ikokunomatome ahtf";
extern int                HowManyCandlesToDisplay  = 287;
extern string             noteStochastic           ="-----Stochastic----------------------";
extern int                StochasticK1             = 5;
extern int                StochasticD1             = 3;
extern int                StochasticSlowing1       = 3;
extern PriceMenu          StochasticPrice1         = Low_High;
extern ENUM_MA_METHOD     SignalLineMaMethod1      = MODE_EMA;
extern int                WingdingsFontSymbol1     = 110;
extern string             noteCCI                  ="-----CCI-----------------------------";
extern int                CCIperiod                = 3;
extern ENUM_APPLIED_PRICE CCIprice                 = PRICE_CLOSE;
extern int                WingdingsFontSymbol2     = 110;
extern string             noteRSI                  ="-----RSI-----------------------------";
extern int                RsiPeriod                = 3;
extern ENUM_APPLIED_PRICE RsiPrice                 = PRICE_CLOSE;
extern int                WingdingsFontSymbol3     = 110;
extern string             noteMomentum             ="-----Momentum------------------------";
extern int                MomentumPeriod           = 3;
extern ENUM_APPLIED_PRICE MomentumPrice            = PRICE_CLOSE;
extern int                WingdingsFontSymbol4     = 108;
extern string             noteMACD                 ="-----MACD----------------------------";
extern int                MACDfastEMA              = 4;
extern int                MACDslowEMA              = 10;
extern int                MACDsignalSMA            =  5;
extern ENUM_APPLIED_PRICE MACDprice                = PRICE_CLOSE;
extern int                WingdingsFontSymbol5     = 108;
extern string             noteDemark               ="-----DeMark--------------------------";
extern int                DemarkPeriod             = 3;
extern int                WingdingsFontSymbol6     = 108;
extern string             note7                    ="-------------------------------------";

extern int    LinesWidth            = 0;
extern color  LabelsColor           = clrBrown;
extern int    LabelsHorizontalShift = 5;
extern double LabelsVerticalShift   = 1.5;

 bool   alertsOn              = false;
 int    alertsLevel           = 7;
 bool   alertsMessage         = false;
 bool   alertsSound           = false;
 bool   alertsEmail           = false;
 bool   alertsOnEachBar       = false;

double buffer1up[], buffer1down[], buffer2up[], buffer2down[], buffer3up[], buffer3down[], buffer4up[], buffer4down[], buffer5up[], buffer5down[], buffer6up[], buffer6down[];

int    timeFrames[6];
bool   returnBars;
string indicatorFileName;
//------------------------------------------------------------------
int OnInit()
{
      SetIndexBuffer(0,buffer1up);
      SetIndexBuffer(1,buffer1down);
      SetIndexBuffer(2,buffer2up);
      SetIndexBuffer(3,buffer2down);
      SetIndexBuffer(4,buffer3up);
      SetIndexBuffer(5,buffer3down);
      SetIndexBuffer(6,buffer4up);
      SetIndexBuffer(7,buffer4down);
      SetIndexBuffer(8,buffer5up);
      SetIndexBuffer(9,buffer5down);
      SetIndexBuffer(10,buffer6up);
      SetIndexBuffer(11,buffer6down);

      indicatorFileName = WindowExpertName();
      returnBars        = (TimeFrame1=="returnBars"); if (returnBars) return(0);
      
      for (int i=0; i<indicator_buffers; i++) 
         SetIndexStyle(i,DRAW_ARROW,EMPTY,LinesWidth);  

      SetIndexArrow(0,WingdingsFontSymbol1);
      SetIndexArrow(1,WingdingsFontSymbol1);
      SetIndexArrow(2,WingdingsFontSymbol2);
      SetIndexArrow(3,WingdingsFontSymbol2);
      SetIndexArrow(4,WingdingsFontSymbol3);
      SetIndexArrow(5,WingdingsFontSymbol3);
      SetIndexArrow(6,WingdingsFontSymbol4);
      SetIndexArrow(7,WingdingsFontSymbol4);
      SetIndexArrow(8,WingdingsFontSymbol5);
      SetIndexArrow(9,WingdingsFontSymbol5);
      SetIndexArrow(10,WingdingsFontSymbol6);
      SetIndexArrow(11,WingdingsFontSymbol6);
      
      for (int babyYoda =0; babyYoda <indicator_buffers/2; babyYoda++)
//      timeFrames[babyYoda] = stringToTimeFrame(TimeFrame1);

//template copy and paste start3
      timeFrames[babyYoda]         = (enTimeFrames)timeFrameValue(TimeFrame1);
//template copy and paste end3


      alertsLevel = MathMin(MathMax(alertsLevel,4),indicator_buffers/2);
      IndicatorShortName(UniqueID);
   return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
//template copy and paste start4
int timeFrameValue(int _tf)
{
   int add  = (_tf>=0) ? 0 : MathAbs(_tf);
   if (add != 0) _tf = _Period;
   int size = ArraySize(iTfTable); 
      int i =0; for (;i<size; i++) if (iTfTable[i]==_tf) break;
                                   if (i==size) return(_Period);
                                                return(iTfTable[(int)MathMin(i+add,size-1)]);
}
//template copy and paste end4
//+------------------------------------------------------------------------------------------------------------------+
int deinit()
{
   for (int t=0; t<indicator_buffers/2; t++) ObjectDelete(UniqueID+t);
   return(0); 
}
//------------------------------------------------------------------
double trend[][2];
#define _up 0
#define _dn 1
int start()
{
         int i,r, counted_bars=IndicatorCounted(), myPriceField1;
         
         myPriceField1 = StochasticPrice1;
   
         if(counted_bars < 0) return(-1);
         if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { buffer1up[0] = limit+1; return(0); }

         if (timeFrames[0] != Period()) limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrames[0],indicatorFileName,"returnBars",0,0)*timeFrames[0]/Period()));
         limit = HowManyCandlesToDisplay;
         if (ArrayRange(trend,0)!=Bars) ArrayResize(trend,Bars);
        
         bool initialized = false;
         if (!initialized)
         {
               initialized = true;
               int window = WindowFind(UniqueID);

               string label1 = timeFrameToString (timeFrames[0]) + " MACD (" + IntegerToString(MACDfastEMA)  +","+ IntegerToString(MACDslowEMA)+","+ IntegerToString(MACDsignalSMA) + ")";
               ObjectCreate (UniqueID+0,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+0,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+0,OBJPROP_PRICE1,0+LabelsVerticalShift);
               ObjectSetText(UniqueID+0,label1,7,"Arial");
               ObjectSet    (UniqueID+0,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*80);

               string label2 = timeFrameToString (timeFrames[1]) + " Stoch (" + IntegerToString(StochasticK1)  +","+ IntegerToString(StochasticD1)+","+ IntegerToString(StochasticSlowing1) + ")";
               ObjectCreate (UniqueID+1,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+1,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+1,OBJPROP_PRICE1,1+LabelsVerticalShift);
               ObjectSetText(UniqueID+1,label2,7,"Arial");
               ObjectSet    (UniqueID+1,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*70);

               string label3 = timeFrameToString (timeFrames[2]) + " RSI (" + IntegerToString(RsiPeriod) + ")";
               ObjectCreate (UniqueID+2,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+2,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+2,OBJPROP_PRICE1,2+LabelsVerticalShift);
               ObjectSetText(UniqueID+2,label3,7,"Arial");
               ObjectSet    (UniqueID+2,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*50);

               string label4 = timeFrameToString (timeFrames[3]) + " CCI (" + IntegerToString(CCIperiod) + ")";
               ObjectCreate (UniqueID+3,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+3,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+3,OBJPROP_PRICE1,3+LabelsVerticalShift);
               ObjectSetText(UniqueID+3,label4,7,"Arial");
               ObjectSet    (UniqueID+3,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*50);


               string label5 = timeFrameToString (timeFrames[4]) + " Momentum (" + IntegerToString(MomentumPeriod) + ")";
               ObjectCreate (UniqueID+4,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+4,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+4,OBJPROP_PRICE1,4+LabelsVerticalShift);
               ObjectSetText(UniqueID+4,label5,7,"Arial");
               ObjectSet    (UniqueID+4,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*80);


               string label6 = timeFrameToString (timeFrames[5]) + " DeMark (" + IntegerToString(DemarkPeriod) + ")";
               ObjectCreate (UniqueID+5,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+5,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+5,OBJPROP_PRICE1,5+LabelsVerticalShift);
               ObjectSetText(UniqueID+5,label6,7,"Arial");
               ObjectSet    (UniqueID+5,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*70);
               
               

         }
    
   for(i = limit, r=Bars-i-1; i >= 0; i--,r++)
   {
      trend[r][_up] = 0;
      trend[r][_dn] = 0;
      for (int k=0; k<indicator_buffers/2; k++)
      {
            int y = iBarShift(NULL,timeFrames[k],Time[i]);
            double stochm1 = iStochastic(NULL,timeFrames[k],StochasticK1,StochasticD1,StochasticSlowing1,SignalLineMaMethod1,myPriceField1,MODE_MAIN  ,y);
            double stochs1 = iStochastic(NULL,timeFrames[k],StochasticK1,StochasticD1,StochasticSlowing1,SignalLineMaMethod1,myPriceField1,MODE_SIGNAL,y);
            bool isStochUp = (stochm1>=50); 

            double myRSI = iRSI(NULL,timeFrames[k],RsiPeriod,RsiPrice,y);
            bool isRSIup  = (myRSI>=50);

            double macd = iMACD(NULL,timeFrames[k],MACDfastEMA,MACDslowEMA,MACDsignalSMA,MACDprice,MODE_MAIN,y);
            bool isMACDup = (macd>=0);             

            double myDeMark = iDeMarker(NULL,timeFrames[k],DemarkPeriod,y);
            bool isDeMarkUp = (myDeMark>=0.5);

            double myCCI = iCCI(NULL, timeFrames[k],CCIperiod,CCIprice, y);
            bool isCCIup = (myCCI >=0);
            
            bool isMomentumUp = ((iMA(NULL,timeFrames[k],1,0,0,MomentumPrice,y)-iMA(NULL,timeFrames[k],1,MomentumPeriod,0,MomentumPrice,y)>=0));

            switch (k)
            {
               case 0 : if (isStochUp)    { buffer1up[i] = k+1; buffer1down[i] = EMPTY_VALUE;}  else { buffer1down[i] = k+1; buffer1up[i] = EMPTY_VALUE; } break;
               case 1 : if (isCCIup)      { buffer2up[i] = k+1; buffer2down[i] = EMPTY_VALUE;}  else { buffer2down[i] = k+1; buffer2up[i] = EMPTY_VALUE; } break;
               case 2 : if (isRSIup)      { buffer3up[i] = k+1; buffer3down[i] = EMPTY_VALUE;}  else { buffer3down[i] = k+1; buffer3up[i] = EMPTY_VALUE; } break;
               case 3 : if (isMomentumUp) { buffer4up[i] = k+1; buffer4down[i] = EMPTY_VALUE;}  else { buffer4down[i] = k+1; buffer4up[i] = EMPTY_VALUE; } break;
               case 4 : if (isMACDup)     { buffer5up[i] = k+1; buffer5down[i] = EMPTY_VALUE;}  else { buffer5down[i] = k+1; buffer5up[i] = EMPTY_VALUE; } break;
               case 5 : if (isDeMarkUp)   { buffer6up[i] = k+1; buffer6down[i] = EMPTY_VALUE;}  else { buffer6down[i] = k+1; buffer6up[i] = EMPTY_VALUE; } break;

            }
            if (isStochUp)
                  trend[r][_up] += 1;
            else  trend[r][_dn] += 1;
      }
   }
   manageAlerts();
   return(0);
}
//+-------------------------------------------------------------------
void manageAlerts()
{
   if (alertsOn)
   {
      int whichBar = Bars-1;
      if (trend[whichBar][_up] >= alertsLevel || trend[whichBar][_dn] >= alertsLevel)
      {
         if (trend[whichBar][_up] >= alertsLevel) doAlert("up"  ,trend[whichBar][_up]);
         if (trend[whichBar][_dn] >= alertsLevel) doAlert("down",trend[whichBar][_dn]);
      }
   }
}
//+-------------------------------------------------------------------
void doAlert(string doWhat, int howMany)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || (alertsOnEachBar && previousTime != Time[0])) {
       previousAlert  = doWhat;
       previousTime   = Time[0];

       message =  Symbol()+" at "+TimeToStr(TimeLocal(),TIME_SECONDS)+" "+howMany+" time frames of stochastic are aligned "+doWhat;
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(Symbol()+" 4x Stochastic",message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}
//-------------------------------------------------------------------
string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

int toInt(double value) { return(value); }
int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   int max = ArraySize(iTfTable)-1, add=0;
   int nxt = (StringFind(tfs,"NEXT1")>-1); if (nxt>0) { tfs = ""+Period(); add=1; }
       nxt = (StringFind(tfs,"NEXT2")>-1); if (nxt>0) { tfs = ""+Period(); add=2; }
       nxt = (StringFind(tfs,"NEXT3")>-1); if (nxt>0) { tfs = ""+Period(); add=3; }
       nxt = (StringFind(tfs,"NEXT4")>-1); if (nxt>0) { tfs = ""+Period(); add=4; }
         
      for (int i=max; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[toInt(MathMin(max,i+add))],Period()));
                                                      return(Period());
}
//+-------------------------------------------------------------------
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}
//+-------------------------------------------------------------------
string stringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int xchar = StringGetChar(s, length);
         if((xchar > 96 && xchar < 123) || (xchar > 223 && xchar < 256))
                     s = StringSetChar(s, length, xchar - 32);
         else if(xchar > -33 && xchar < 0)
                     s = StringSetChar(s, length, xchar + 224);
   }
   return(s);
}
//+-------------------------------------------------------------------
