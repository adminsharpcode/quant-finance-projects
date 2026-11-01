//+------------------------------------------------------------------+
//|                            A! SupportResistanceDiagonal+Stoch.mq4|
//|                    Converted from TradingView Pine Script by AI  |
//|     Original Pine Script: https://www.tradingview.com/v/v2635O1L |
//+------------------------------------------------------------------+
#property copyright "Converter: AI. Original Author: Unknown (TradingView)"
#property link      "https://www.tradingview.com/script/v2635O1L-Support-Resistance-Diagonal/"
#property version   "2.00" // Added Stochastic Arrows
#property strict

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 0

//--- Description
#property description "Diagonal S/R lines with Stochastic crossover arrows."
#property description "Best for scalping with lower 'History Bars Back' settings (e.g., 50-120)."

//--- Input parameters for S/R Lines
extern int    HistoryBarsBack = 300;
extern int    Resolution      = 6;
extern color  SupColor        = C'23,255,39';   // #17ff27
extern color  ResColor        = C'255,119,173'; // #ff77ad
extern ENUM_LINE_STYLE LineStyle = STYLE_SOLID;
extern int    LineWidth       = 1;

//--- Input parameters for Stochastic Arrows
extern bool   EnableStochArrows = true;
extern int    Stoch_KPeriod     = 14;
extern int    Stoch_DPeriod     = 3;
extern int    Stoch_Slowing     = 3;
extern double Stoch_Overbought  = 80.0;
extern double Stoch_Oversold    = 20.0;
extern color  BuyArrowColor     = clrDodgerBlue;
extern color  SellArrowColor    = clrRed;

//--- Other Settings
extern bool   EnableAlerts    = true;

//--- Indicator buffers
double MinimumsBuffer[];
double MaximumsBuffer[];

//--- Global variables for object management
string obj_prefix;
int    obj_uid_counter = 0;

#define MAX_LINES 50
string g_support_lines[MAX_LINES];
string g_resistance_lines[MAX_LINES];
string g_labels[MAX_LINES * 2];
int    g_support_count = 0;
int    g_resistance_count = 0;
int    g_label_count = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    if(HistoryBarsBack > 4500) {
        Print("Warning: 'History Bars Back' is very high and may cause performance issues or errors.");
    }
    
    SetIndexBuffer(0, MinimumsBuffer);
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
    ArraySetAsSeries(MinimumsBuffer, true);

    SetIndexBuffer(1, MaximumsBuffer);
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
    ArraySetAsSeries(MaximumsBuffer, true);
    
    obj_prefix = "SRD_" + IntegerToString(ChartID()) + "_" + IntegerToString(Period()) + "_";
    IndicatorSetString(INDICATOR_SHORTNAME, "S/R Diagonal+Stoch (" + IntegerToString(HistoryBarsBack) + "," + IntegerToString(Resolution) + ")");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, obj_prefix);
}

//+------------------------------------------------------------------+
//| Helper to calculate price on a line from bar shifts              |
//+------------------------------------------------------------------+
double PriceAt(int t1_shift, double p1, int t2_shift, double p2, int t3_shift)
{
    if (t2_shift - t1_shift == 0) return (p1);
    return (p1 + (p2 - p1) * (double)(t3_shift - t1_shift) / (double)(t2_shift - t1_shift));
}

//+------------------------------------------------------------------+
//| Helper to round price up to the nearest tick size                |
//+------------------------------------------------------------------+
double RoundToTick(double price)
{
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if (tick_size <= 0) return(NormalizeDouble(price, _Digits));
    double mult = 1.0 / tick_size;
    return (MathCeil(price * mult) / mult);
}

//+------------------------------------------------------------------+
//| Deletes all objects created by this indicator                    |
//+------------------------------------------------------------------+
void DeleteAllMyObjects()
{
    ObjectsDeleteAll(0, obj_prefix);
    obj_uid_counter = 0;
}

//+------------------------------------------------------------------+
//| Converts timeframe integer to a user-friendly string (MQL4)      |
//+------------------------------------------------------------------+
string TimeframeToString(int period_mins)
{
   switch(period_mins)
   {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
      default:         return("Unknown TF " + IntegerToString(period_mins));
   }
}


//+------------------------------------------------------------------+
//| Check for alerts based on lines drawn on the previous tick       |
//+------------------------------------------------------------------+
void CheckAlerts(const double &low[], const double &high[], const double &close[])
{
    if (!EnableAlerts || IsTesting() || IsOptimization() || Bars < 2) return;

    bool fire_alert_sup = false;
    bool fire_alert_res = false;

    for (int i = 0; i < g_support_count; i++)
    {
        string name = g_support_lines[i];
        if (ObjectFind(0, name) < 0) continue;

        long t1_time = ObjectGetInteger(0, name, OBJPROP_TIME, 0);
        double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
        long t2_time = ObjectGetInteger(0, name, OBJPROP_TIME, 1);
        double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
        int t1_shift = iBarShift(_Symbol, _Period, (datetime)t1_time);
        int t2_shift = iBarShift(_Symbol, _Period, (datetime)t2_time);

        double line_price_at_1 = PriceAt(t1_shift, p1, t2_shift, p2, 1);
        double line_price_at_0 = PriceAt(t1_shift, p1, t2_shift, p2, 0);
        
        if (low[1] > line_price_at_1 && close[0] < line_price_at_0)
        {
            fire_alert_sup = true;
            break;
        }
    }

    for (int i = 0; i < g_resistance_count; i++)
    {
        string name = g_resistance_lines[i];
        if (ObjectFind(0, name) < 0) continue;

        long t1_time = ObjectGetInteger(0, name, OBJPROP_TIME, 0);
        double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
        long t2_time = ObjectGetInteger(0, name, OBJPROP_TIME, 1);
        double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
        int t1_shift = iBarShift(_Symbol, _Period, (datetime)t1_time);
        int t2_shift = iBarShift(_Symbol, _Period, (datetime)t2_time);
        
        double line_price_at_1 = PriceAt(t1_shift, p1, t2_shift, p2, 1);
        double line_price_at_0 = PriceAt(t1_shift, p1, t2_shift, p2, 0);

        if (high[1] < line_price_at_1 && close[0] > line_price_at_0)
        {
            fire_alert_res = true;
            break;
        }
    }

    static datetime last_sup_alert_time = 0;
    static datetime last_res_alert_time = 0;
    
    if (fire_alert_sup && TimeCurrent() > last_sup_alert_time + 1) { // Prevent alert spam
        Alert("Diagonal support crossed down on ", _Symbol, " ", TimeframeToString(_Period));
        last_sup_alert_time = TimeCurrent();
    }
    if (fire_alert_res && TimeCurrent() > last_res_alert_time + 1) { // Prevent alert spam
        Alert("Diagonal resistance crossed up on ", _Symbol, " ", TimeframeToString(_Period));
        last_res_alert_time = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Draws the S/R lines and labels                                   |
//+------------------------------------------------------------------+
void DrawLines(int rates_total, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[])
{
    //--- Draw Support Lines ---
    string last_sup_line_name = "";
    string last_sup_label_name = "";
    int    last_sup_pivot1_shift = -1;

    int minimum1 = 0;
    for (int k1 = 0; k1 < 50; k1++)
    {
        if (minimum1 >= rates_total - 1) break;
        int jump = (int)MinimumsBuffer[minimum1];
        if (jump <= 0) jump = 1;
        minimum1 += jump;

        if (minimum1 >= HistoryBarsBack || minimum1 >= rates_total - 1) break;

        int minimum2 = minimum1;
        for (int k2 = 0; k2 < 50; k2++)
        {
            if (minimum2 >= rates_total - 1) break;
            int jump2 = (int)MinimumsBuffer[minimum2];
            if (jump2 <= 0) jump2 = 1;
            minimum2 += jump2;

            if (minimum2 >= minimum1 * 8 || minimum2 >= HistoryBarsBack || minimum2 >= rates_total - 1) break;

            int bar1_shift = minimum1;
            int bar2_shift = minimum2;
            double price1 = low[bar1_shift];
            double price2 = low[bar2_shift];
            
            double current_price = PriceAt(bar2_shift, price2, bar1_shift, price1, 0);

            if (current_price < high[1])
            {
                bool crossed = false;
                int medium = 0;
                for (int k3 = 0; k3 < 50; k3++)
                {
                    if (medium >= rates_total - 1) break;
                    int jump3 = (int)MinimumsBuffer[medium];
                    if (jump3 <= 0) jump3 = 1;
                    medium += jump3;

                    if (medium >= minimum2) break;
                    
                    if (PriceAt(bar2_shift, price2, bar1_shift, price1, medium) > MathMin(open[medium], close[medium]))
                    {
                        crossed = true;
                        break;
                    }
                }

                if (!crossed)
                {
                    if (last_sup_line_name != "" && last_sup_pivot1_shift == bar1_shift)
                    {
                        double last_price = ObjectGetDouble(0, last_sup_label_name, OBJPROP_PRICE, 0);
                        if (current_price > last_price)
                        {
                            ObjectSetInteger(0, last_sup_line_name, OBJPROP_TIME, 0, time[bar2_shift]);
                            ObjectSetDouble(0, last_sup_line_name, OBJPROP_PRICE, 0, price2);
                            ObjectSetInteger(0, last_sup_line_name, OBJPROP_TIME, 1, time[bar1_shift]);
                            ObjectSetDouble(0, last_sup_line_name, OBJPROP_PRICE, 1, price1);
                            ObjectSetDouble(0, last_sup_label_name, OBJPROP_PRICE, 0, current_price);
                            ObjectSetString(0, last_sup_label_name, OBJPROP_TEXT, DoubleToString(RoundToTick(current_price), _Digits));
                        }
                    }
                    else if (g_support_count < MAX_LINES)
                    {
                        string name = obj_prefix + "sup_" + IntegerToString(obj_uid_counter++);
                        ObjectCreate(0, name, OBJ_TREND, 0, time[bar2_shift], price2, time[bar1_shift], price1);
                        ObjectSetInteger(0, name, OBJPROP_COLOR, SupColor);
                        ObjectSetInteger(0, name, OBJPROP_STYLE, LineStyle);
                        ObjectSetInteger(0, name, OBJPROP_WIDTH, LineWidth);
                        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
                        
                        last_sup_line_name = name;
                        last_sup_pivot1_shift = bar1_shift;
                        g_support_lines[g_support_count++] = name;
                        
                        string lname = obj_prefix + "suplbl_" + IntegerToString(obj_uid_counter++);
                        ObjectCreate(0, lname, OBJ_TEXT, 0, time[0], current_price);
                        ObjectSetString(0, lname, OBJPROP_TEXT, DoubleToString(RoundToTick(current_price), _Digits));
                        ObjectSetInteger(0, lname, OBJPROP_COLOR, SupColor);
                        ObjectSetInteger(0, lname, OBJPROP_FONTSIZE, 8);
                        ObjectSetInteger(0, lname, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
                        
                        last_sup_label_name = lname;
                        if(g_label_count < MAX_LINES*2) g_labels[g_label_count++] = lname;
                    }
                }
            }
        }
    }
    
    //--- Draw Resistance Lines ---
    string last_res_line_name = "";
    string last_res_label_name = "";
    int    last_res_pivot1_shift = -1;

    int maximum1 = 0;
    for (int k1 = 0; k1 < 100; k1++)
    {
        if (maximum1 >= rates_total - 1) break;
        int jump = (int)MaximumsBuffer[maximum1];
        if (jump <= 0) jump = 1;
        maximum1 += jump;

        if (maximum1 >= HistoryBarsBack || maximum1 >= rates_total - 1) break;

        int maximum2 = maximum1;
        for (int k2 = 0; k2 < 50; k2++)
        {
            if (maximum2 >= rates_total - 1) break;
            int jump2 = (int)MaximumsBuffer[maximum2];
            if (jump2 <= 0) jump2 = 1;
            maximum2 += jump2;

            if (maximum2 >= maximum1 * 8 || maximum2 >= HistoryBarsBack || maximum2 >= rates_total - 1) break;

            int bar1_shift = maximum1;
            int bar2_shift = maximum2;
            double price1 = high[bar1_shift];
            double price2 = high[bar2_shift];
            
            double current_price = PriceAt(bar2_shift, price2, bar1_shift, price1, 0);

            if (current_price > low[1])
            {
                bool crossed = false;
                int medium = 0;
                for (int k3 = 0; k3 < 100; k3++)
                {
                    if (medium >= rates_total - 1) break;
                    int jump3 = (int)MaximumsBuffer[medium];
                    if (jump3 <= 0) jump3 = 1;
                    medium += jump3;

                    if (medium >= maximum2) break;

                    if (PriceAt(bar2_shift, price2, bar1_shift, price1, medium) < MathMax(open[medium], close[medium]))
                    {
                        crossed = true;
                        break;
                    }
                }

                if (!crossed)
                {
                    if (last_res_line_name != "" && last_res_pivot1_shift == bar1_shift)
                    {
                        double last_price = ObjectGetDouble(0, last_res_label_name, OBJPROP_PRICE, 0);
                        if (current_price < last_price)
                        {
                            ObjectSetInteger(0, last_res_line_name, OBJPROP_TIME, 0, time[bar2_shift]);
                            ObjectSetDouble(0, last_res_line_name, OBJPROP_PRICE, 0, price2);
                            ObjectSetInteger(0, last_res_line_name, OBJPROP_TIME, 1, time[bar1_shift]);
                            ObjectSetDouble(0, last_res_line_name, OBJPROP_PRICE, 1, price1);
                            ObjectSetDouble(0, last_res_label_name, OBJPROP_PRICE, 0, current_price);
                            ObjectSetString(0, last_res_label_name, OBJPROP_TEXT, DoubleToString(RoundToTick(current_price), _Digits));
                        }
                    }
                    else if (g_resistance_count < MAX_LINES)
                    {
                        string name = obj_prefix + "res_" + IntegerToString(obj_uid_counter++);
                        ObjectCreate(0, name, OBJ_TREND, 0, time[bar2_shift], price2, time[bar1_shift], price1);
                        ObjectSetInteger(0, name, OBJPROP_COLOR, ResColor);
                        ObjectSetInteger(0, name, OBJPROP_STYLE, LineStyle);
                        ObjectSetInteger(0, name, OBJPROP_WIDTH, LineWidth);
                        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);

                        last_res_line_name = name;
                        last_res_pivot1_shift = bar1_shift;
                        g_resistance_lines[g_resistance_count++] = name;
                        
                        string lname = obj_prefix + "reslbl_" + IntegerToString(obj_uid_counter++);
                        ObjectCreate(0, lname, OBJ_TEXT, 0, time[0], current_price);
                        ObjectSetString(0, lname, OBJPROP_TEXT, DoubleToString(RoundToTick(current_price), _Digits));
                        ObjectSetInteger(0, lname, OBJPROP_COLOR, ResColor);
                        ObjectSetInteger(0, lname, OBJPROP_FONTSIZE, 8);
                        ObjectSetInteger(0, lname, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);

                        last_res_label_name = lname;
                        if(g_label_count < MAX_LINES*2) g_labels[g_label_count++] = lname;
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| *** NEW FUNCTION *** Draws Stochastic Crossover Arrows           |
//+------------------------------------------------------------------+
void DrawStochArrows(int bar, const datetime &time[], const double &high[], const double &low[])
{
   if(!EnableStochArrows) return;

   // Get Stochastic values for the signal bar (bar) and the one before it (bar+1)
   double main_curr = iStochastic(NULL, 0, Stoch_KPeriod, Stoch_DPeriod, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, bar);
   double sign_curr = iStochastic(NULL, 0, Stoch_KPeriod, Stoch_DPeriod, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, bar);
   
   double main_prev = iStochastic(NULL, 0, Stoch_KPeriod, Stoch_DPeriod, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, bar+1);
   double sign_prev = iStochastic(NULL, 0, Stoch_KPeriod, Stoch_DPeriod, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, bar+1);

   // Buy Signal: Main crosses above Signal in oversold zone
   if(main_prev < sign_prev && main_curr > sign_curr && main_prev < Stoch_Oversold)
   {
      string name = obj_prefix + "buy_arrow_" + IntegerToString(bar);
      ObjectCreate(0, name, OBJ_ARROW, 0, time[bar], low[bar] - _Point * 10);
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233); // Up arrow
      ObjectSetInteger(0, name, OBJPROP_COLOR, BuyArrowColor);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   }
   
   // Sell Signal: Main crosses below Signal in overbought zone
   if(main_prev > sign_prev && main_curr < sign_curr && main_prev > Stoch_Overbought)
   {
      string name = obj_prefix + "sell_arrow_" + IntegerToString(bar);
      ObjectCreate(0, name, OBJ_ARROW, 0, time[bar], high[bar] + _Point * 10);
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234); // Down arrow
      ObjectSetInteger(0, name, OBJPROP_COLOR, SellArrowColor);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   }
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
    int required_bars = MathMax(HistoryBarsBack, Stoch_KPeriod + Stoch_Slowing);
    if (rates_total < required_bars)
    {
        IndicatorSetString(INDICATOR_SHORTNAME, "Not enough bars");
        return(0);
    }
    
    CheckAlerts(low, high, close);
    DeleteAllMyObjects();
    g_support_count = g_resistance_count = g_label_count = 0;

    int start_bar = rates_total - 2;
    if (prev_calculated > 1)
        start_bar = rates_total - prev_calculated;
    if (start_bar >= rates_total - 1) start_bar = rates_total - 2;

    int res_half = Resolution / 2;
    if (res_half == 0) res_half = 1;

    for (int i = start_bar; i >= 0; i--)
    {
        if (i >= rates_total - Resolution)
        {
            if(i < rates_total -1) {
              MinimumsBuffer[i] = MinimumsBuffer[i + 1] + 1;
              MaximumsBuffer[i] = MaximumsBuffer[i + 1] + 1;
            }
            continue;
        }

        if (iLowest(NULL, 0, MODE_LOW, Resolution, i) == i + res_half)
            MinimumsBuffer[i] = res_half;
        else
            MinimumsBuffer[i] = MinimumsBuffer[i + 1] + 1;

        if (iHighest(NULL, 0, MODE_HIGH, Resolution, i) == i + res_half)
            MaximumsBuffer[i] = res_half;
        else
            MaximumsBuffer[i] = MaximumsBuffer[i + 1] + 1;
    }
    
    DrawLines(rates_total, time, open, high, low, close);
    
    // --- CALL TO DRAW STOCHASTIC ARROWS ---
    // We only need to check the last few bars for efficiency
    int limit = MathMin(rates_total - 2, 50); // check last 50 bars
    for(int i = 1; i < limit; i++)
    {
      DrawStochArrows(i, time, high, low);
    }

    ChartRedraw();
    return(rates_total);
}
//+------------------------------------------------------------------+