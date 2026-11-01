/*------------------------------------------------------------------------------------
   Name: TDI-MTF.mq4
   
   Description: - MTF TDI Indicator
                - Requires 'TDI-RT-clone.mq4' is installed
	          
   Change log: 
       2014-06-06. Xaphod, v1.600 
          - Updated for build 600+
          - Changed to use TDI-RT-Clone for build 600+ compatitability
       2013-09-08. Xaphod, v1.03 
          - Changed to use TDI_RT instead of Traders_Dynamic_Index.mq4 which has a fault
          - Chnaged color of blue lines to CLR_NONE
       2010-11-10. Xaphod, v1.02 
          - Added Auto Higher TF
          - Added indicator level lines
       2010-11-10. Xaphod, v1.01 
          - Fixed time axis to correspond with the lower TF.
       2010-11-10. Xaphod, v1.00 
          - Initial Release 
         
-------------------------------------------------------------------------------------*/
// Indicator properties
#property copyright "xaphod.com"
#property link      "http://www.xaphod.com"
#property strict
#property version "1.600"
#property description "Multi-Timeframe version of the TDI based on the TDI-RT-Clone indicator"
#property description " "
#property description "The indicator will update/redraw all bars on the lower timeframe that represent the open"
#property description "higher time-frame bar until the higher time-frame bar closes.  This is how most MTF indicators"
#property description "work. It is simply showing you the current state of the higher timeframe indicator."
#property description " "
#property description "Requirements:"
#property description "  TDI-RT-clone.mq4"
#property description " "
#property description "Troubleshooting:"
#property description "  Check the 'Journal' and 'Expert' tabs in the terminal window for errors."



#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1  CLR_NONE
#property indicator_color2  Yellow
#property indicator_color3  CLR_NONE
#property indicator_color4  Red
#property indicator_color5  Green
#property indicator_width1  1
#property indicator_width2  2
#property indicator_width3  1
#property indicator_width4  2
#property indicator_width5  2
#property indicator_level1  32.0
#property indicator_level2  50.0
#property indicator_level3  68.0
#property indicator_levelcolor DimGray
#property indicator_levelstyle STYLE_DOT

// Constant definitions
#define TDI_INDI "TDI-RT-Clone"
#define INDICATOR_NAME "TDI-MTF"


// Indicator parameters
extern bool               TimeFrame_Auto=True;              /* TimeFrame: Auto Select Next TF. (M15 & M30 -> H1)*/  
extern ENUM_TIMEFRAMES    TimeFrame_Period=PERIOD_CURRENT;  /* TimeFrame: Period */  // Timeframe: 0,1,5,15,30,60,240,1440 etc. Current Timeframe=0. 
extern int                TDI_RSIPeriod = 13;               /* TDI: RSI Period */  
extern ENUM_APPLIED_PRICE TDI_RSIPrice = PRICE_CLOSE;       /* TDI: RSI Price Type */       
extern int                TDI_RSIPriceLine = 2;             /* TDI: RSI Price Line Period */ 
extern ENUM_MA_METHOD     TDI_RSIPriceType = MODE_SMA;      /* TDI: RSI Price Line MA Method */
extern int                TDI_TradeSignalLine = 7;          /* TDI: Trade Signal Line Period */ 
extern ENUM_MA_METHOD     TDI_TradeSignalType = MODE_SMA;   /* TDI: Trade Signal Line MA Method */ 
extern int                TDI_VolatilityBand = 34;          /* TDI: Volatility Band Period */

// Global module varables
double gdaVBHigh[];
double gdaMarketSig[];
double gdaVBLow[];
double gdaRSISig[];
double gdaTradeSig[];

int giRepaintBars;
int giTimeFrame;

//-----------------------------------------------------------------------------
// function: init()
// Description: Custom indicator initialization function.
//-----------------------------------------------------------------------------
int init() {
  // Init indicator buffers
  SetIndexStyle(0,DRAW_LINE);
  SetIndexBuffer(0,gdaVBHigh);
  SetIndexLabel(0,"VBHighLine");
  SetIndexStyle(1,DRAW_LINE);
  SetIndexBuffer(1,gdaMarketSig);
  SetIndexLabel(1,"MarketBaseLine");
  SetIndexStyle(2,DRAW_LINE);
  SetIndexBuffer(2,gdaVBLow);
  SetIndexLabel(2,"VBLowLine");
  SetIndexStyle(4,DRAW_LINE);
  SetIndexBuffer(4,gdaRSISig);
  SetIndexLabel(4,"RSIPriceLine");
  SetIndexStyle(3,DRAW_LINE);
  SetIndexBuffer(3,gdaTradeSig);
  SetIndexLabel(3,"TradeSignalLine");  
  
  // Set Timeframe
  switch(TimeFrame_Auto) {
    case 1: 
      giTimeFrame=NextHigherTF(TimeFrame_Period); 
      giRepaintBars=giTimeFrame/Period()+2;     
    break;
    case 2: 
      giTimeFrame=NextHigherTF(NextHigherTF(TimeFrame_Period));
      giRepaintBars=giTimeFrame/Period()+2;
    break;
    default: 
      if (TimeFrame_Period==0 || TimeFrame_Period==Period()) {
        giTimeFrame=Period();
        giRepaintBars=0;
      }
      else {
        giTimeFrame=TimeFrame_Period;
        giRepaintBars=giTimeFrame/Period()+2;
      }
    break;
  }

    
    
  // Other stuff  
  IndicatorShortName(INDICATOR_NAME+" ["+TF2Str(giTimeFrame)+"]");
  IndicatorDigits(4); 
    
  return(0);
}


//-----------------------------------------------------------------------------
// function: deinit()
// Description: Custom indicator deinitialization function.
//-----------------------------------------------------------------------------
int deinit() {
  return (0);
}


///-----------------------------------------------------------------------------
// function: start()
// Description: Custom indicator iteration function.
//-----------------------------------------------------------------------------
int start() {
  int iNewBars;
  int iCountedBars; 
  int i;
  
  // Get unprocessed ticks
  iCountedBars=IndicatorCounted();
  if(iCountedBars < 0) return (-1); 
  if(iCountedBars>0) iCountedBars--;
  // Set bars to redraw
  if (NewBars(giTimeFrame)>3)
    iNewBars=Bars-1-MathMax(TDI_RSIPeriod,TDI_VolatilityBand);
  else
    iNewBars=Bars-iCountedBars;
  if (iNewBars<giRepaintBars)
    iNewBars=giRepaintBars;

  
  for(i=iNewBars; i>=0; i--) {      
    // Get TDI Data
    gdaVBHigh[i]=iCustom(NULL,giTimeFrame,TDI_INDI,TDI_RSIPeriod,TDI_RSIPrice,TDI_VolatilityBand,TDI_RSIPriceLine,
                        TDI_RSIPriceType,TDI_TradeSignalLine,TDI_TradeSignalType,0,iBarShift(Symbol(), giTimeFrame, Time[i]));       // Upper Blue line
    gdaMarketSig[i]=iCustom(NULL,giTimeFrame,TDI_INDI,TDI_RSIPeriod,TDI_RSIPrice,TDI_VolatilityBand,TDI_RSIPriceLine,
                            TDI_RSIPriceType,TDI_TradeSignalLine,TDI_TradeSignalType,2,iBarShift(Symbol(), giTimeFrame, Time[i]));   // Yellow line
    gdaVBLow[i]=iCustom(NULL,giTimeFrame,TDI_INDI,TDI_RSIPeriod,TDI_RSIPrice,TDI_VolatilityBand,TDI_RSIPriceLine,
                       TDI_RSIPriceType,TDI_TradeSignalLine,TDI_TradeSignalType,1,iBarShift(Symbol(), giTimeFrame, Time[i]));        // Lower Blue line
    gdaRSISig[i]=iCustom(NULL,giTimeFrame,TDI_INDI,TDI_RSIPeriod,TDI_RSIPrice,TDI_VolatilityBand,TDI_RSIPriceLine,
                          TDI_RSIPriceType,TDI_TradeSignalLine,TDI_TradeSignalType,4,iBarShift(Symbol(), giTimeFrame, Time[i]));     // Green line
    gdaTradeSig[i]=iCustom(NULL,giTimeFrame,TDI_INDI,TDI_RSIPeriod,TDI_RSIPrice,TDI_VolatilityBand,TDI_RSIPriceLine,
                            TDI_RSIPriceType,TDI_TradeSignalLine,TDI_TradeSignalType,3,iBarShift(Symbol(), giTimeFrame, Time[i]));  // Red line
  }
  // Bye bye  
  return(0);
}
//+------------------------------------------------------------------+


//-----------------------------------------------------------------------------
// function: NewBars()
// Description: Return nr of new bars on a TF
//-----------------------------------------------------------------------------
int NewBars(int iPeriod) {
  static int iPrevSize;
  int iNewSize;
  int iNewBars;
  datetime tTimeArray[];
  
  ArrayCopySeries(tTimeArray,MODE_TIME,Symbol(),iPeriod);
  iNewSize=ArraySize(tTimeArray);
  iNewBars=iNewSize-iPrevSize;
  iPrevSize=iNewSize;
  return(iNewBars);
}


//-----------------------------------------------------------------------------
// function: TF2Str()
// Description: Convert time-frame to a string
//-----------------------------------------------------------------------------
string TF2Str(int iPeriod) {
  if (iPeriod==0) iPeriod=Period();
  switch(iPeriod) {
    case PERIOD_M1: return("M1");
    case PERIOD_M5: return("M5");
    case PERIOD_M15: return("M15");
    case PERIOD_M30: return("M30");
    case PERIOD_H1: return("H1");
    case PERIOD_H4: return("H4");
    case PERIOD_D1: return("D1");
    case PERIOD_W1: return("W1");
    case PERIOD_MN1: return("MN1");
    default: return("M"+(string)iPeriod);
  }
}

//-----------------------------------------------------------------------------
// function: NextHigherTF()
// Description: Select the next higher time-frame. 
//              Note: M15 and M30 both select H1 as next higher TF. 
//-----------------------------------------------------------------------------
int NextHigherTF(int iPeriod) {
  if (iPeriod==0) iPeriod=Period();
  switch(iPeriod) {
    case PERIOD_M1: return(PERIOD_M5);
    case PERIOD_M5: return(PERIOD_M15);
    case PERIOD_M15: return(PERIOD_H1);
    case PERIOD_M30: return(PERIOD_H1);
    case PERIOD_H1: return(PERIOD_H4);
    case PERIOD_H4: return(PERIOD_D1);
    case PERIOD_D1: return(PERIOD_W1);
    case PERIOD_W1: return(PERIOD_MN1);
    case PERIOD_MN1: return(PERIOD_MN1);
    default: return(Period());
  }
}


