//------------------------------------------------------------------
// not for sale, rent, auction, nor lease
// January 31st, 2020
// Fibo # 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987,  ...
#property copyright "www.forex-station.com"
#property link      "www.forex-station.com"
#property description "not for sale, rent, auction, nor lease"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 8

#property indicator_color7  C'0,160,0'
#property indicator_color8 clrRed

#property indicator_color5  C'0,140,0'
#property indicator_color6 clrCrimson

#property indicator_color3  C'0,120,0'
#property indicator_color4 C'134,5,39'
#property indicator_color1  C'0,100,0' //clrDarkGreen
#property indicator_color2 C'124,5,39'

#property indicator_minimum 0
#property indicator_maximum 5

extern string TimeFrame1            = "Current time frame";
extern string note_a="input an integer for TimeFrame1 such as";
extern string note_b="1,5,15,30,60,240,1440,10080,43200, or leave as it is";
extern string note_c="-------------------------------------";
extern string UniqueID              = "4x Stochastic";
extern int    HowManyBarsToDisplay  = 300;
extern string note1="-------------------------------------";
extern int    StochasticK1          = 21;
extern int    StochasticD1          = 3;
extern int    StochasticSlowing1    = 3;
extern string note1a="Price field parameter. Can be 1 of these values: 0 - Low/High or 1 - Close/Close.";
extern int    StochasticPrice1      = 1;
extern ENUM_MA_METHOD    SignalLineMaMethod1    = MODE_EMA;
extern int    WingdingsFontSymbol1 = 110;
extern string note2="-------------------------------------";
extern int    StochasticK2          = 13;
extern int    StochasticD2          = 3;
extern int    StochasticSlowing2    = 3;
extern string note2a="0 - Low/High or 1 - Close/Close";
extern int    StochasticPrice2      = 1;
extern ENUM_MA_METHOD    SignalLineMaMethod2    = MODE_EMA;
extern int    WingdingsFontSymbol2 = 110;
extern string note3="-------------------------------------";
extern int    StochasticK3          = 8;
extern int    StochasticD3          = 3;
extern int    StochasticSlowing3    = 3;
extern string note3a="0 - Low/High or 1 - Close/Close";
extern int    StochasticPrice3      = 1;
extern ENUM_MA_METHOD    SignalLineMaMethod3    = MODE_EMA;
extern int    WingdingsFontSymbol3 = 108;
extern string note4="-------------------------------------";
extern int    StochasticK4          = 5;
extern int    StochasticD4          = 3;
extern int    StochasticSlowing4    = 3;
extern string note4a="0 - Low/High or 1 - Close/Close";
extern int    StochasticPrice4      = 1;
extern ENUM_MA_METHOD    SignalLineMaMethod4    = MODE_EMA;
extern int    WingdingsFontSymbol4 = 108;
extern string note5="-------------------------------------";
extern int    LinesWidth            = 0;
extern color  LabelsColor           = clrBrown;
extern int    LabelsHorizontalShift = 5;
extern double LabelsVerticalShift   = 1.5;
extern bool   alertsOn              = false;
extern int    alertsLevel           = 7;
extern bool   alertsMessage         = false;
extern bool   alertsSound           = false;
extern bool   alertsEmail           = false;
extern bool   alertsOnEachBar       = false;

double sto1u[], sto1d[], sto2u[], sto2d[], sto3u[], sto3d[], sto4u[], sto4d[];

int    timeFrames[4];
bool   returnBars;
string indicatorFileName;
//------------------------------------------------------------------
int OnInit()
{
      SetIndexBuffer(0,sto1u);
      SetIndexBuffer(1,sto1d);
      SetIndexBuffer(2,sto2u);
      SetIndexBuffer(3,sto2d);
      SetIndexBuffer(4,sto3u);
      SetIndexBuffer(5,sto3d);
      SetIndexBuffer(6,sto4u);
      SetIndexBuffer(7,sto4d);

      indicatorFileName = WindowExpertName();
      returnBars        = (TimeFrame1=="returnBars"); if (returnBars) return(0);
      
      for (int i=0; i<8; i++) 
         SetIndexStyle(i,DRAW_ARROW,EMPTY,LinesWidth);  

      SetIndexArrow(0,WingdingsFontSymbol1);
      SetIndexArrow(1,WingdingsFontSymbol1);
      SetIndexArrow(2,WingdingsFontSymbol2);
      SetIndexArrow(3,WingdingsFontSymbol2);
      SetIndexArrow(4,WingdingsFontSymbol3);
      SetIndexArrow(5,WingdingsFontSymbol3);
      SetIndexArrow(6,WingdingsFontSymbol4);
      SetIndexArrow(7,WingdingsFontSymbol4);
      
      for (int babyYoda =0; babyYoda <4; babyYoda++)
      timeFrames[babyYoda] = stringToTimeFrame(TimeFrame1);

      alertsLevel = MathMin(MathMax(alertsLevel,3),4);
      IndicatorShortName(UniqueID);
   return(0);
}
//+-------------------------------------------------------------------
int deinit()
{
   for (int t=0; t<4; t++) ObjectDelete(UniqueID+t);
   return(0); 
}
//------------------------------------------------------------------
double trend[][2];
#define _up 0
#define _dn 1
int start()
{
         int i,r, counted_bars=IndicatorCounted();
   
         if(counted_bars < 0) return(-1);
         if(counted_bars>0) counted_bars--;
         int limit = MathMin(Bars-counted_bars,Bars-1);
         if (returnBars) { sto1u[0] = limit+1; return(0); }

         if (timeFrames[0] != Period()) limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrames[0],indicatorFileName,"returnBars",0,0)*timeFrames[0]/Period()));
         limit = HowManyBarsToDisplay;
         if (ArrayRange(trend,0)!=Bars) ArrayResize(trend,Bars);
        
         bool initialized = false;
         if (!initialized)
         {
               initialized = true;
               int window = WindowFind(UniqueID);

               string label1 = timeFrameToString (timeFrames[0]) + " (" + IntegerToString(StochasticK1)  +","+ IntegerToString(StochasticD1)+","+ IntegerToString(StochasticSlowing1) + ")";
               ObjectCreate (UniqueID+0,OBJ_TEXT,window,0,0);
               ObjectSet    (UniqueID+0,OBJPROP_COLOR,LabelsColor);
               ObjectSet    (UniqueID+0,OBJPROP_PRICE1,0+LabelsVerticalShift);
               ObjectSetText(UniqueID+0,label1,7,"Arial");
               ObjectSet    (UniqueID+0,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*60);

               string label2 = timeFrameToString (timeFrames[1]) + " (" + IntegerToString(StochasticK2)  +","+ IntegerToString(StochasticD2)+","+ IntegerToString(StochasticSlowing2) + ")";
               ObjectCreate(UniqueID+1,OBJ_TEXT,window,0,0);
               ObjectSet(UniqueID+1,OBJPROP_COLOR,LabelsColor);
               ObjectSet(UniqueID+1,OBJPROP_PRICE1,1+LabelsVerticalShift);
               ObjectSetText(UniqueID+1,label2,7,"Arial");
               ObjectSet(UniqueID+1,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*60);

               string label3 = timeFrameToString (timeFrames[2]) + " (" + IntegerToString(StochasticK3)  +","+ IntegerToString(StochasticD3)+","+ IntegerToString(StochasticSlowing3) + ")";
               ObjectCreate(UniqueID+2,OBJ_TEXT,window,0,0);
               ObjectSet(UniqueID+2,OBJPROP_COLOR,LabelsColor);
               ObjectSet(UniqueID+2,OBJPROP_PRICE1,2+LabelsVerticalShift);
               ObjectSetText(UniqueID+2,label3,7,"Arial");
               ObjectSet(UniqueID+2,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*60);

               string label4 = timeFrameToString (timeFrames[3]) + " (" + IntegerToString(StochasticK4)  +","+ IntegerToString(StochasticD4)+","+ IntegerToString(StochasticSlowing4) + ")";
               ObjectCreate(UniqueID+3,OBJ_TEXT,window,0,0);
               ObjectSet(UniqueID+3,OBJPROP_COLOR,LabelsColor);
               ObjectSet(UniqueID+3,OBJPROP_PRICE1,3+LabelsVerticalShift);
               ObjectSetText(UniqueID+3,label4,7,"Arial");
               ObjectSet(UniqueID+3,OBJPROP_TIME1,Time[0]+Period()*LabelsHorizontalShift*60);
         }
    
   for(i = limit, r=Bars-i-1; i >= 0; i--,r++)
   {
      trend[r][_up] = 0;
      trend[r][_dn] = 0;
      for (int k=0; k<4; k++)
      {
            int y = iBarShift(NULL,timeFrames[k],Time[i]);
            double stochm1 = iStochastic(NULL,timeFrames[k],StochasticK1,StochasticD1,StochasticSlowing1,SignalLineMaMethod1,StochasticPrice1,MODE_MAIN  ,y);
            double stochs1 = iStochastic(NULL,timeFrames[k],StochasticK1,StochasticD1,StochasticSlowing1,SignalLineMaMethod1,StochasticPrice1,MODE_SIGNAL,y);
            bool isUp1 = (stochm1>stochs1);
            double stochm2 = iStochastic(NULL,timeFrames[k],StochasticK2,StochasticD2,StochasticSlowing2,SignalLineMaMethod2,StochasticPrice2,MODE_MAIN  ,y);
            double stochs2 = iStochastic(NULL,timeFrames[k],StochasticK2,StochasticD2,StochasticSlowing2,SignalLineMaMethod2,StochasticPrice2,MODE_SIGNAL,y);
            bool isUp2 = (stochm2>stochs2);

            double stochm3 = iStochastic(NULL,timeFrames[k],StochasticK3,StochasticD3,StochasticSlowing3,SignalLineMaMethod3,StochasticPrice3,MODE_MAIN  ,y);
            double stochs3 = iStochastic(NULL,timeFrames[k],StochasticK3,StochasticD3,StochasticSlowing3,SignalLineMaMethod3,StochasticPrice3,MODE_SIGNAL,y);
            bool isUp3 = (stochm3>stochs3);

            double stochm4 = iStochastic(NULL,timeFrames[k],StochasticK4,StochasticD4,StochasticSlowing4,SignalLineMaMethod4,StochasticPrice4,MODE_MAIN  ,y);
            double stochs4 = iStochastic(NULL,timeFrames[k],StochasticK4,StochasticD4,StochasticSlowing4,SignalLineMaMethod4,StochasticPrice4,MODE_SIGNAL,y);
            bool isUp4 = (stochm4>stochs4);

            switch (k)
            {
               case 0 : if (isUp1) { sto1u[i] = k+1; sto1d[i] = EMPTY_VALUE;}  else { sto1d[i] = k+1; sto1u[i] = EMPTY_VALUE; } break;
               case 1 : if (isUp2) { sto2u[i] = k+1; sto2d[i] = EMPTY_VALUE;}  else { sto2d[i] = k+1; sto2u[i] = EMPTY_VALUE; } break;
               case 2 : if (isUp3) { sto3u[i] = k+1; sto3d[i] = EMPTY_VALUE;}  else { sto3d[i] = k+1; sto3u[i] = EMPTY_VALUE; } break;
               case 3 : if (isUp4) { sto4u[i] = k+1; sto4d[i] = EMPTY_VALUE;}  else { sto4d[i] = k+1; sto4u[i] = EMPTY_VALUE; } break;
            }
            if (isUp4)
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
