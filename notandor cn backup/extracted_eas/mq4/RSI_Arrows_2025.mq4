//+------------------------------------------------------------------+
//|                                              RSI_Arrows_2025.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Josmellon Trading."
#property link      "https://josmellontrading.com"
#property version   "2.00"
#property strict
#property indicator_chart_window    
#property indicator_buffers 2
#property indicator_plots   2

//--- Buy Arrows
#property indicator_label1  "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_width1  2

//--- Sell Arrows
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  2

//--- Input Parameters
input int    RSIPeriod = 14;            // RSI Period
input int    OverboughtLevel = 80;      // Overbought Level 
input int    OversoldLevel = 20;         // Oversold Level
input color  BuyArrowColor = clrBlue;   // Buy Arrow Color
input color  SellArrowColor = clrRed;   // Sell Arrow Color

//--- Indicator Buffers
double BuyArrowBuffer[];
double SellArrowBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, BuyArrowBuffer);
    SetIndexBuffer(1, SellArrowBuffer);

    //--- Set arrow codes and positions
    SetIndexArrow(0, 233); // Down arrow (sell)
    SetIndexArrow(1, 234); // Up arrow (buy)
    
    //--- Set arrow distances from price
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
    
    //--- Set colors
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, BuyArrowColor);
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, SellArrowColor);

    return(INIT_SUCCEEDED);
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
    int limit = rates_total - prev_calculated;
    if(prev_calculated > 0) limit++;

    for(int i=limit-1; i>=0; i--)
    {
        // Calculate RSI values
        double rsi = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE, i);
        double rsi_prev = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE, i+1);

        // Reset buffers
        BuyArrowBuffer[i] = EMPTY_VALUE;
        SellArrowBuffer[i] = EMPTY_VALUE;

        // Buy signal (cross up from oversold)
        if(rsi_prev < OversoldLevel && rsi >= OversoldLevel)
            BuyArrowBuffer[i] = Low[i] - 10 * Point;  // Arrow below price

        // Sell signal (cross down from overbought)
        if(rsi_prev > OverboughtLevel && rsi <= OverboughtLevel)
            SellArrowBuffer[i] = High[i] + 10 * Point; // Arrow above price
    }

    return(rates_total);
}
//+------------------------------------------------------------------+