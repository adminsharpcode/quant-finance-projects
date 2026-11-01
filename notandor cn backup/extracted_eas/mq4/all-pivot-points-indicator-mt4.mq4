//+------------------------------------------------------------------+
//|                                             All Pivot Points.mq4 |
//|                                   Copyright 2016, Hossein Nouri. |
//|                           https://www.mql5.com/en/users/hsnnouri |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Hossein Nouri."
#property link      "https://www.mql5.com/en/users/hsnnouri"
#property version   "1.2"
#property description "All important Pivot Points including:" 
#property description "Classic, Camarilla, Woodie, Floor, Fibonacci, Fibonacci_Retracement"
#property strict
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   9
//--- plot Pivot
#property indicator_label1  "Pivot"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot S1
#property indicator_label2  "S1"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot S2
#property indicator_label3  "S2"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrCrimson
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot S3
#property indicator_label4  "S3"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrFireBrick
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot S4
#property indicator_label5  "S4"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrMaroon
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot R1
#property indicator_label6  "R1"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrLime
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- plot R2
#property indicator_label7  "R2"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrLimeGreen
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1
//--- plot R3
#property indicator_label8  "R3"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrMediumSeaGreen
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1
//--- plot R4
#property indicator_label9  "R4"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrSeaGreen
#property indicator_style9  STYLE_SOLID
#property indicator_width9  1
//--- indicator buffers
double         PivotBuffer[];
double         S1Buffer[];
double         S2Buffer[];
double         S3Buffer[];
double         S4Buffer[];
double         R1Buffer[];
double         R2Buffer[];
double         R3Buffer[];
double         R4Buffer[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum CalMode
  {
   Classic=0,
   Camarilla=1,
   Woodie=2,
   Fibonacci=3,
   Floor=4,
   Fibonacci_Retracement=5,
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ShMode
  {
   Today=0,
   Historical=1,
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum TF
  {
   M1=PERIOD_M1,
   M5=PERIOD_M5,
   M15=PERIOD_M15,
   M30=PERIOD_M30,
   H1=PERIOD_H1,
   H4=PERIOD_H4,
   D1=PERIOD_D1,
   W1=PERIOD_W1,
   MN=PERIOD_MN1,
  };
input TF TimeFrame=1440;
input CalMode CalculationMode=1;
input ShMode ShowMode=0;
input bool ShowLabels=true;
input bool ShowPivot=true;
input color PivotColor=clrLightGray;
input ENUM_LINE_STYLE PivotStyle=STYLE_SOLID;
input int PivotWidth=1;
input bool ShowS1=true;
input color S1Color=clrRed;
input ENUM_LINE_STYLE S1Style=STYLE_SOLID;
input int S1Width=1;

input bool ShowS2=true;
input color S2Color=clrCrimson;
input ENUM_LINE_STYLE S2Style=STYLE_SOLID;
input int S2Width=1;

input bool ShowS3=true;
input color S3Color=clrFireBrick;
input ENUM_LINE_STYLE S3Style=STYLE_SOLID;
input int S3Width=1;

input bool ShowS4=true;
input color S4Color=clrMaroon;
input ENUM_LINE_STYLE S4Style=STYLE_SOLID;
input int S4Width=1;

input bool ShowR1=true;
input color R1Color=clrLime;
input ENUM_LINE_STYLE R1Style=STYLE_SOLID;
input int R1Width=1;

input bool ShowR2=true;
input color R2Color=clrLimeGreen;
input ENUM_LINE_STYLE R2Style=STYLE_SOLID;
input int R2Width=1;

input bool ShowR3=true;
input color R3Color=clrMediumSeaGreen;
input ENUM_LINE_STYLE R3Style=STYLE_SOLID;
input int R3Width=1;

input bool ShowR4=true;
input color R4Color=clrSeaGreen;
input ENUM_LINE_STYLE R4Style=STYLE_SOLID;
input int R4Width=1;

datetime camTime,time1,time2;
string symbol;
int counter=0;
double R1,R2,R3,R4,S1,S2,S3,S4,PP;
string prefix;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,PivotBuffer);
   SetIndexBuffer(1,S1Buffer);
   SetIndexBuffer(2,S2Buffer);
   SetIndexBuffer(3,S3Buffer);
   SetIndexBuffer(4,S4Buffer);
   SetIndexBuffer(5,R1Buffer);
   SetIndexBuffer(6,R2Buffer);
   SetIndexBuffer(7,R3Buffer);
   SetIndexBuffer(8,R4Buffer);
   SetIndexStyle(0,DRAW_LINE,PivotStyle,PivotWidth,PivotColor);
   SetIndexStyle(1,DRAW_LINE,S1Style,S1Width,S1Color);
   SetIndexStyle(2,DRAW_LINE,S2Style,S2Width,S2Color);
   SetIndexStyle(3,DRAW_LINE,S3Style,S3Width,S3Color);
   SetIndexStyle(4,DRAW_LINE,S4Style,S4Width,S4Color);
   SetIndexStyle(5,DRAW_LINE,R1Style,R1Width,R1Color);
   SetIndexStyle(6,DRAW_LINE,R2Style,R2Width,R2Color);
   SetIndexStyle(7,DRAW_LINE,R3Style,R3Width,R3Color);
   SetIndexStyle(8,DRAW_LINE,R4Style,R4Width,R4Color);
   ArraySetAsSeries(S1Buffer,true);
   ArraySetAsSeries(S2Buffer,true);
   ArraySetAsSeries(S3Buffer,true);
   ArraySetAsSeries(S4Buffer,true);
   ArraySetAsSeries(R1Buffer,true);
   ArraySetAsSeries(R2Buffer,true);
   ArraySetAsSeries(R3Buffer,true);
   ArraySetAsSeries(R4Buffer,true);
   ArraySetAsSeries(PivotBuffer,true);
   prefix=EnumToString(CalculationMode)+EnumToString(TimeFrame);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,prefix);
   ObjectsDeleteAll(0,prefix);

  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total>prev_calculated)
     {
      if(Period()>TimeFrame)
        {
         Alert("TimeFrame value is less than current chart period.\nPlease enter value greater then or qual to the current chart.");
         return(rates_total);
        }

      if(ShowMode==1 && CalculationMode==1)
        {
         int j=0;
         for(int i=0;i<rates_total;i++)
           {
            if(time[i]>=iTime(Symbol(),TimeFrame,j))
              {
               calculateHistCamarilla(i,j+1);

                 }else{
               j++;
               calculateHistCamarilla(i,j+1);
              }

           }
         calculateTodayCamarilla();
        }
      if(ShowMode==1 && CalculationMode==0)
        {
         int j=0;
         for(int i=0;i<rates_total;i++)
           {
            if(time[i]>=iTime(Symbol(),TimeFrame,j))
              {
               calculateHistClassic(i,j+1);

                 }else{
               j++;
               calculateHistClassic(i,j+1);
              }

           }
         calculateTodayClassic();
        }
      if(ShowMode==1 && CalculationMode==2)
        {
         int j=0;
         for(int i=0;i<rates_total;i++)
           {
            if(time[i]>=iTime(Symbol(),TimeFrame,j))
              {
               calculateHistWoodie(i,j+1);

                 }else{
               j++;
               calculateHistWoodie(i,j+1);
              }

           }
         calculateTodayWoodie();
        }
      if(ShowMode==1 && CalculationMode==3)
        {
         int j=0;
         for(int i=0;i<rates_total;i++)
           {
            if(time[i]>=iTime(Symbol(),TimeFrame,j))
              {
               calculateHistFibonacci(i,j+1);

                 }else{
               j++;
               calculateHistFibonacci(i,j+1);
              }

           }
         calculateTodayFibonacci();
        }
      if(ShowMode==1 && CalculationMode==4)
        {
         int j=0;
         for(int i=0;i<rates_total;i++)
           {
            if(time[i]>=iTime(Symbol(),TimeFrame,j))
              {
               calculateHistFloor(i,j+1);

                 }else{
               j++;
               calculateHistFloor(i,j+1);
              }

           }
         calculateTodayFloor();
        }
      if(ShowMode==1 && CalculationMode==5)
        {
         int j=0;
         for(int i=0;i<rates_total;i++)
           {
            if(time[i]>=iTime(Symbol(),TimeFrame,j))
              {
               calculateHistFibonacciRet(i,j+1);

                 }else{
               j++;
               calculateHistFibonacciRet(i,j+1);
              }

           }
         calculateTodayFibonacciRet();
        }
      if(ShowMode==0)
        {
         if(CalculationMode==0) calculateTodayClassic();
         if(CalculationMode==1) calculateTodayCamarilla();
         if(CalculationMode==2) calculateTodayWoodie();
         if(CalculationMode==3) calculateTodayFibonacci();
         if(CalculationMode==4) calculateTodayFloor();
         if(CalculationMode==5) calculateTodayFibonacciRet();
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
void calculateHistFibonacciRet(int index,int barIndex)
  {
   double prevRange= iHigh(Symbol(),TimeFrame,barIndex)-iLow(Symbol(),TimeFrame,barIndex);
   double prevHigh = iHigh(Symbol(),TimeFrame,barIndex);
   double prevLow=iLow(Symbol(),TimeFrame,barIndex);
   double prevClose=iClose(Symbol(),TimeFrame,barIndex);
   PivotBuffer[index]=NormalizeDouble(prevLow+(0.50*prevRange),Digits);
   R1Buffer[index] = NormalizeDouble(prevLow +(0.618 * prevRange),Digits);
   R2Buffer[index] = NormalizeDouble(prevLow +(0.786 * prevRange),Digits);
   R3Buffer[index] = NormalizeDouble(prevHigh,Digits);
   R4Buffer[index] = NormalizeDouble(prevLow +(1.382 * prevRange),Digits);

   S1Buffer[index] = NormalizeDouble(prevLow +(0.382 * prevRange),Digits);
   S2Buffer[index] = NormalizeDouble(prevLow +(0.236 * prevRange),Digits);
   S3Buffer[index] = NormalizeDouble(prevLow,Digits);
   S4Buffer[index] = NormalizeDouble(prevLow -(0.382 * prevRange),Digits);
   checkVisiblity(index);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateTodayFibonacciRet()
  {
   double prevRange= iHigh(Symbol(),TimeFrame,1)-iLow(Symbol(),TimeFrame,1);
   double prevHigh = iHigh(Symbol(),TimeFrame,1);
   double prevLow=iLow(Symbol(),TimeFrame,1);
   double prevClose=iClose(Symbol(),TimeFrame,1);
   PP = NormalizeDouble(prevLow +(0.50 * prevRange),Digits);
   R1 = NormalizeDouble(prevLow +(0.618 * prevRange),Digits);
   R2 = NormalizeDouble(prevLow +(0.786 * prevRange),Digits);
   R3 = NormalizeDouble(prevHigh,Digits);
   R4 = NormalizeDouble(prevLow +(1.382 * prevRange),Digits);
   S1 = NormalizeDouble(prevLow +(0.382 * prevRange),Digits);
   S2 = NormalizeDouble(prevLow +(0.236 * prevRange),Digits);
   S3 = NormalizeDouble(prevLow,Digits);
   S4 = NormalizeDouble(prevLow -(0.382 * prevRange),Digits);
   time1 = iTime(Symbol(),TimeFrame,0);
   time2 = time1 + iTime(Symbol(),TimeFrame,0)-iTime(Symbol(),TimeFrame,1);

   DrawOnChart();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateHistFloor(int index,int barIndex)
  {
   double prevRange= iHigh(Symbol(),TimeFrame,barIndex)-iLow(Symbol(),TimeFrame,barIndex);
   double prevHigh = iHigh(Symbol(),TimeFrame,barIndex);
   double prevLow=iLow(Symbol(),TimeFrame,barIndex);
   double prevClose=iClose(Symbol(),TimeFrame,barIndex);
   PivotBuffer[index]=NormalizeDouble((prevHigh+prevLow+prevClose)/3,Digits);
   R1Buffer[index] = NormalizeDouble((PivotBuffer[index] * 2)-prevLow,Digits);
   S1Buffer[index] = NormalizeDouble((PivotBuffer[index] * 2)-prevHigh,Digits);
   R2Buffer[index] = NormalizeDouble(PivotBuffer[index] + prevHigh - prevLow,Digits);
   S2Buffer[index] = NormalizeDouble(PivotBuffer[index] - prevHigh + prevLow,Digits);
   R3Buffer[index] = NormalizeDouble(R1Buffer[index] + (prevHigh-prevLow),Digits);
   S3Buffer[index] = NormalizeDouble(prevLow - 2 * (prevHigh-PivotBuffer[index]),Digits);
   checkVisiblity(index);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateTodayFloor()
  {
   double prevRange= iHigh(Symbol(),TimeFrame,1)-iLow(Symbol(),TimeFrame,1);
   double prevHigh = iHigh(Symbol(),TimeFrame,1);
   double prevLow=iLow(Symbol(),TimeFrame,1);
   double prevClose=iClose(Symbol(),TimeFrame,1);
   PP = NormalizeDouble((prevHigh+prevLow+prevClose)/3,Digits);
   R1 = NormalizeDouble((PP * 2)-prevLow,Digits);
   S1 = NormalizeDouble((PP * 2)-prevHigh,Digits);
   R2 = NormalizeDouble(PP + prevHigh - prevLow,Digits);
   S2 = NormalizeDouble(PP - prevHigh + prevLow,Digits);
   R3 = NormalizeDouble(R1 + (prevHigh-prevLow),Digits);
   S3 = NormalizeDouble(prevLow - 2 * (prevHigh-PP),Digits);
   time1 = iTime(Symbol(),TimeFrame,0);
   time2 = time1 + iTime(Symbol(),TimeFrame,0)-iTime(Symbol(),TimeFrame,1);

   DrawOnChart();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateHistFibonacci(int index,int barIndex)
  {
   double prevRange= iHigh(Symbol(),TimeFrame,barIndex)-iLow(Symbol(),TimeFrame,barIndex);
   double prevHigh = iHigh(Symbol(),TimeFrame,barIndex);
   double prevLow=iLow(Symbol(),TimeFrame,barIndex);
   double prevClose=iClose(Symbol(),TimeFrame,barIndex);
   PivotBuffer[index]=NormalizeDouble((prevHigh+prevLow+prevClose)/3,Digits);
   R1Buffer[index] = NormalizeDouble(PivotBuffer[index] + (0.382 * (prevHigh - prevLow)),Digits);
   R2Buffer[index] = NormalizeDouble(PivotBuffer[index] + (0.618 * (prevHigh - prevLow)),Digits);
   R3Buffer[index] = NormalizeDouble(PivotBuffer[index] + (1 * (prevHigh - prevLow)),Digits);
   R4Buffer[index] = NormalizeDouble(PivotBuffer[index] + (1.618 * (prevHigh - prevLow)),Digits);
   S1Buffer[index] = NormalizeDouble(PivotBuffer[index] - (0.382 * (prevHigh - prevLow)),Digits);
   S2Buffer[index] = NormalizeDouble(PivotBuffer[index] - (0.618 * (prevHigh - prevLow)),Digits);
   S3Buffer[index] = NormalizeDouble(PivotBuffer[index] - (1 * (prevHigh - prevLow)),Digits);
   S4Buffer[index] = NormalizeDouble(PivotBuffer[index] - (1.618 * (prevHigh - prevLow)),Digits);
   checkVisiblity(index);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateTodayFibonacci()
  {
   double prevRange= iHigh(Symbol(),TimeFrame,1)-iLow(Symbol(),TimeFrame,1);
   double prevHigh = iHigh(Symbol(),TimeFrame,1);
   double prevLow=iLow(Symbol(),TimeFrame,1);
   double prevClose=iClose(Symbol(),TimeFrame,1);
   PP = NormalizeDouble((prevHigh+prevLow+prevClose)/3,Digits);
   R1 = NormalizeDouble(PP + (0.382 * (prevHigh - prevLow)),Digits);
   R2 = NormalizeDouble(PP + (0.618 * (prevHigh - prevLow)),Digits);
   R3 = NormalizeDouble(PP + (1 * (prevHigh - prevLow)),Digits);
   R4 = NormalizeDouble(PP + (1.618 * (prevHigh - prevLow)),Digits);
   S1 = NormalizeDouble(PP - (0.382 * (prevHigh - prevLow)),Digits);
   S2 = NormalizeDouble(PP - (0.618 * (prevHigh - prevLow)),Digits);
   S3 = NormalizeDouble(PP - (1 * (prevHigh - prevLow)),Digits);
   S4 = NormalizeDouble(PP - (1.618 * (prevHigh - prevLow)),Digits);
   time1 = iTime(Symbol(),TimeFrame,0);
   time2 = time1 + iTime(Symbol(),TimeFrame,0)-iTime(Symbol(),TimeFrame,1);

   DrawOnChart();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateHistCamarilla(int index,int barIndex)
  {
   double camRange = iHigh(Symbol(), TimeFrame,barIndex) - iLow(Symbol(), TimeFrame,barIndex);
   double prevHigh = iHigh(Symbol(), TimeFrame,barIndex);
   double prevLow=iLow(Symbol(),TimeFrame,barIndex);
   double prevClose= iClose(Symbol(),TimeFrame,barIndex);
   R1Buffer[index] = NormalizeDouble(((1.1 / 12) * camRange) + prevClose,Digits);
   R2Buffer[index] = NormalizeDouble(((1.1 / 6) * camRange) + prevClose,Digits);
   R3Buffer[index] = NormalizeDouble(((1.1 / 4) * camRange) + prevClose,Digits);
   R4Buffer[index] = NormalizeDouble(((1.1 / 2) * camRange) + prevClose,Digits);
   S1Buffer[index] = NormalizeDouble(prevClose - ((1.1 / 12) * camRange),Digits);
   S2Buffer[index] = NormalizeDouble(prevClose - ((1.1 / 6) * camRange),Digits);
   S3Buffer[index] = NormalizeDouble(prevClose - ((1.1 / 4) * camRange),Digits);
   S4Buffer[index] = NormalizeDouble(prevClose - ((1.1 / 2) * camRange),Digits);
   PivotBuffer[index]=NormalizeDouble((R1Buffer[index]+S1Buffer[index])/2,Digits);
   checkVisiblity(index);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateHistClassic(int index,int barIndex)
  {
   double prevRange= iHigh(Symbol(),TimeFrame,barIndex)-iLow(Symbol(),TimeFrame,barIndex);
   double prevHigh = iHigh(Symbol(),TimeFrame,barIndex);
   double prevLow=iLow(Symbol(),TimeFrame,barIndex);
   double prevClose=iClose(Symbol(),TimeFrame,barIndex);
   PivotBuffer[index]=NormalizeDouble((prevHigh+prevLow+prevClose)/3,Digits);
   R1Buffer[index] = NormalizeDouble((PivotBuffer[index] * 2)-prevLow,Digits);
   R2Buffer[index] = NormalizeDouble(PivotBuffer[index] + prevRange,Digits);
   R3Buffer[index] = NormalizeDouble(R2Buffer[index] + prevRange,Digits);
   R4Buffer[index] = NormalizeDouble(R3Buffer[index] + prevRange,Digits);
   S1Buffer[index] = NormalizeDouble((PivotBuffer[index] * 2)-prevHigh,Digits);
   S2Buffer[index] = NormalizeDouble(PivotBuffer[index] - prevRange,Digits);
   S3Buffer[index] = NormalizeDouble(S2Buffer[index] - prevRange,Digits);
   S4Buffer[index] = NormalizeDouble(S3Buffer[index] - prevRange,Digits);
   checkVisiblity(index);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateHistWoodie(int index,int barIndex)
  {
   double prevRange= iHigh(Symbol(),TimeFrame,barIndex)-iLow(Symbol(),TimeFrame,barIndex);
   double prevHigh = iHigh(Symbol(),TimeFrame,barIndex);
   double prevLow=iLow(Symbol(),TimeFrame,barIndex);
   double prevClose = iClose(Symbol(), TimeFrame,barIndex);
   double todayOpen = iOpen(Symbol(), TimeFrame,barIndex-1);
   PivotBuffer[index]=NormalizeDouble((prevHigh+prevLow+(todayOpen*2))/4,Digits);
   R1Buffer[index] = NormalizeDouble((PivotBuffer[index] * 2)-prevLow,Digits);
   R2Buffer[index] = NormalizeDouble(PivotBuffer[index] + prevRange,Digits);
   R3Buffer[index] = NormalizeDouble(prevHigh + 2*(PivotBuffer[index]-prevLow),Digits);
   R4Buffer[index] = NormalizeDouble(R3Buffer[index] + prevRange,Digits);
   S1Buffer[index] = NormalizeDouble((PivotBuffer[index] * 2)-prevHigh,Digits);
   S2Buffer[index] = NormalizeDouble(PivotBuffer[index] - prevRange,Digits);
   S3Buffer[index] = NormalizeDouble(prevLow - 2*(prevHigh - PivotBuffer[index]),Digits);
   S4Buffer[index] = NormalizeDouble(S3Buffer[index] - prevRange,Digits);
   checkVisiblity(index);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateTodayWoodie()
  {
   double prevRange= iHigh(Symbol(),TimeFrame,1)-iLow(Symbol(),TimeFrame,1);
   double prevHigh = iHigh(Symbol(),TimeFrame,1);
   double prevLow=iLow(Symbol(),TimeFrame,1);
   double prevClose = iClose(Symbol(), TimeFrame,1);
   double todayOpen = iOpen(Symbol(), TimeFrame,0);
   PP = NormalizeDouble((prevHigh+prevLow+(todayOpen*2))/4,Digits);
   R1 = NormalizeDouble((PP * 2)-prevLow,Digits);
   R2 = NormalizeDouble(PP + prevRange,Digits);
   R3 = NormalizeDouble(prevHigh + 2*(PP-prevLow),Digits);
   R4 = NormalizeDouble(R3 + prevRange,Digits);
   S1 = NormalizeDouble((PP * 2)-prevHigh,Digits);
   S2 = NormalizeDouble(PP - prevRange,Digits);
   S3 = NormalizeDouble(prevLow - 2*(prevHigh - PP),Digits);
   S4 = NormalizeDouble(S3 - prevRange,Digits);
   time1 = iTime(Symbol(),TimeFrame,0);
   time2 = time1 + iTime(Symbol(),TimeFrame,0)-iTime(Symbol(),TimeFrame,1);

   DrawOnChart();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateTodayClassic()
  {
   double prevRange= iHigh(Symbol(),TimeFrame,1)-iLow(Symbol(),TimeFrame,1);
   double prevHigh = iHigh(Symbol(),TimeFrame,1);
   double prevLow=iLow(Symbol(),TimeFrame,1);
   double prevClose=iClose(Symbol(),TimeFrame,1);
   PP = NormalizeDouble((prevHigh+prevLow+prevClose)/3,Digits);
   R1 = NormalizeDouble((PP * 2)-prevLow,Digits);
   R2 = NormalizeDouble(PP + prevRange,Digits);
   R3 = NormalizeDouble(R2 + prevRange,Digits);
   R4 = NormalizeDouble(R3 + prevRange,Digits);
   S1 = NormalizeDouble((PP * 2)-prevHigh,Digits);
   S2 = NormalizeDouble(PP - prevRange,Digits);
   S3 = NormalizeDouble(S2 - prevRange,Digits);
   S4 = NormalizeDouble(S3 - prevRange,Digits);
   time1 = iTime(Symbol(),TimeFrame,0);
   time2 = time1 + iTime(Symbol(),TimeFrame,0)-iTime(Symbol(),TimeFrame,1);

   DrawOnChart();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateTodayCamarilla()
  {
   double camRange = iHigh(Symbol(), TimeFrame,1) - iLow(Symbol(), TimeFrame,1);
   double prevHigh = iHigh(Symbol(), TimeFrame,1);
   double prevLow=iLow(Symbol(),TimeFrame,1);
   double prevClose=iClose(Symbol(),TimeFrame,1);
   R1 = NormalizeDouble(((1.1 / 12) * camRange) + prevClose,Digits);
   R2 = NormalizeDouble(((1.1 / 6) * camRange) + prevClose,Digits);
   R3 = NormalizeDouble(((1.1 / 4) * camRange) + prevClose,Digits);
   R4 = NormalizeDouble(((1.1 / 2) * camRange) + prevClose,Digits);
   S1 = NormalizeDouble(prevClose - ((1.1 / 12) * camRange),Digits);
   S2 = NormalizeDouble(prevClose - ((1.1 / 6) * camRange),Digits);
   S3 = NormalizeDouble(prevClose - ((1.1 / 4) * camRange),Digits);
   S4 = NormalizeDouble(prevClose - ((1.1 / 2) * camRange),Digits);
   PP = NormalizeDouble((R4+S4)/2,Digits);
   time1 = iTime(Symbol(),TimeFrame,0);
   time2 = time1 + (iTime(Symbol(),TimeFrame,0)-iTime(Symbol(),TimeFrame,1));


   DrawOnChart();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawOnChart()
  {
   if(ShowR1==true) CreateTrend(0,"R1",R1Color,R1Style,R1Width,time1,time2,R1,R1);
   if(ShowR2==true) CreateTrend(0,"R2",R2Color,R2Style,R2Width,time1,time2,R2,R2);
   if(ShowR3==true) CreateTrend(0,"R3",R3Color,R3Style,R3Width,time1,time2,R3,R3);
   if(ShowR4==true) CreateTrend(0,"R4",R4Color,R4Style,R4Width,time1,time2,R4,R4);
   if(ShowS1==true) CreateTrend(0,"S1",S1Color,S1Style,S1Width,time1,time2,S1,S1);
   if(ShowS2==true) CreateTrend(0,"S2",S2Color,S2Style,S2Width,time1,time2,S2,S2);
   if(ShowS3==true) CreateTrend(0,"S3",S3Color,S3Style,S3Width,time1,time2,S3,S3);
   if(ShowS4==true) CreateTrend(0,"S4",S4Color,S4Style,S4Width,time1,time2,S4,S4);
   if(ShowPivot==true) CreateTrend(0,"Pivot",PivotColor,PivotStyle,PivotWidth,time1,time2,PP,PP);
   if(ShowR1==true && ShowLabels==true) CreateLabel(0,"LR1","R1",clrGray,R1,time1);
   if(ShowR2==true && ShowLabels==true) CreateLabel(0,"LR2","R2",clrGray,R2,time1);
   if(ShowR3==true && ShowLabels==true) CreateLabel(0,"LR3","R3",clrGray,R3,time1);
   if(ShowR4==true && ShowLabels==true) CreateLabel(0,"LR4","R4",clrGray,R4,time1);
   if(ShowS1==true && ShowLabels==true) CreateLabel(0,"LS1","S1",clrGray,S1,time1);
   if(ShowS2==true && ShowLabels==true) CreateLabel(0,"LS2","S2",clrGray,S2,time1);
   if(ShowS3==true && ShowLabels==true) CreateLabel(0,"LS3","S3",clrGray,S3,time1);
   if(ShowS4==true && ShowLabels==true) CreateLabel(0,"LS4","S4",clrGray,S4,time1);
   if(ShowPivot==true && ShowLabels==true) CreateLabel(0,"LPivot","P",clrGray,PP,time1);
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkVisiblity(int index)
  {
   if(ShowR1==false) R1Buffer[index]=0;
   if(ShowR2==false) R2Buffer[index]=0;
   if(ShowR3==false) R3Buffer[index]=0;
   if(ShowR4==false) R4Buffer[index]=0;
   if(ShowS1==false) S1Buffer[index]=0;
   if(ShowS2==false) S2Buffer[index]=0;
   if(ShowS3==false) S3Buffer[index]=0;
   if(ShowS4==false) S4Buffer[index]=0;
   if(ShowPivot==false) PivotBuffer[index]=0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateTrend(long chart_ID,string name,color trendColor,ENUM_LINE_STYLE lineStyle,int lineWidth,datetime timeStart,datetime timeEnd,double price1,double price2)
  {
//ObjectDelete(chart_ID,name);
   name=prefix+name;
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(chart_ID,name,OBJ_TREND,0,timeStart,price1,timeEnd,price2);
        }else{
      ObjectSetDouble(chart_ID,name,OBJPROP_PRICE1,price1);
      ObjectSetDouble(chart_ID,name,OBJPROP_PRICE2,price2);
      ObjectSetInteger(chart_ID,name,OBJPROP_TIME1,timeStart);
      ObjectSetInteger(chart_ID,name,OBJPROP_TIME2,timeEnd);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,trendColor);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,lineStyle);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,lineWidth);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(long chart_ID,string name,string text,color labelColor,double price,datetime time)
  {
//ObjectDelete(chart_ID,name);
   name=prefix+name;
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(chart_ID,name,OBJ_TEXT,0,time,price);
        }else{
      ObjectSetDouble(chart_ID,name,OBJPROP_PRICE1,price);
      ObjectSetInteger(chart_ID,name,OBJPROP_TIME1,time);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,10);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,0.0);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,labelColor);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);

  }
//+------------------------------------------------------------------+
