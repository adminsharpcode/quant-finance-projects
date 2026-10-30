//+------------------------------------------------------------------+
//|                                   InstitutionalAlphaEngine.mq4   |
//|               Synthesized from Quantitative Audit of 1,297 EAs   |
//|           Multi-Regime Volatility Exhaustion & Asymmetric Payoff |
//+------------------------------------------------------------------+
#property copyright "Institutional Quantitative Engineering"
#property link      "https://github.com/adminsharpcode/quant-finance-projects"
#property version   "2.00"
#property strict

//--- INPUT PARAMETERS ---
input string   TradeSettings           = "=== SIGNAL & REGIME PARAMETERS ===";
input int      InpWindow               = 50;       // Microstructure Band Window (Ticks/Bars)
input double   InpBandDeviation        = 1.8;      // Volatility Exhaustion Band Deviation
input int      InpFastMA               = 20;       // Fast Regime MA Period
input int      InpSlowMA               = 80;       // Slow Regime MA Period
input double   InpTrendThreshold       = 1.2;      // Trend Strength Activation Ratio
input double   InpMaxSpreadPips        = 2.0;      // Hard Spread Gatekeeper (Max Spread in Pips)

input string   RiskSettings            = "=== ASYMMETRIC RISK MANAGEMENT ===";
input double   InpRiskPercent          = 1.5;      // Capital Risk per Trade (% Equity)
input double   InpStopLossPips         = 15.0;     // Stop Loss (Pips)
input double   InpTakeProfitPips       = 30.0;     // Take Profit (Pips, 2:1 Payoff Ratio)
input double   InpMaxLotSize           = 5.0;      // Maximum Allowable Lot Cap
input double   InpMinLotSize           = 0.01;     // Minimum Allowable Lot Floor

input string   SystemSettings          = "=== SYSTEM & EXECUTION ===";
input int      InpMagicNumber          = 889900;   // Expert Magic Identifier
input int      InpMaxSlippagePips      = 2;        // Maximum Tolerated Slippage (Pips)
input string   InpComment              = "AlphaEngine_v2";

//--- GLOBAL VARIABLES ---
int g_pipMultiplier = 1;
double g_pipSize = 0.0001;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Digits == 3 || Digits == 5)
   {
      g_pipMultiplier = 10;
      g_pipSize = Point * 10;
   }
   else
   {
      g_pipMultiplier = 1;
      g_pipSize = Point;
   }

   Print("InstitutionalAlphaEngine Initialized. Symbol: ", Symbol(), " PipSize: ", g_pipSize);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("InstitutionalAlphaEngine Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if already in trade
   if(CountActiveOrders() > 0)
      return;

   // 1. Spread Gatekeeper: Reject toxic execution during liquidity droughts
   double ask = MarketInfo(Symbol(), MODE_ASK);
   double bid = MarketInfo(Symbol(), MODE_BID);
   double currentSpreadPips = (ask - bid) / g_pipSize;

   if(currentSpreadPips > InpMaxSpreadPips)
      return;

   // 2. Compute Statistical Indicators
   double mid = (ask + bid) / 2.0;
   double mean = iMA(Symbol(), 0, InpWindow, 0, MODE_SMA, PRICE_MEDIAN, 0);
   double stdDev = iStdDev(Symbol(), 0, InpWindow, 0, MODE_SMA, PRICE_MEDIAN, 0);

   if(stdDev <= 0.000001)
      return;

   double upperBand = mean + (InpBandDeviation * stdDev);
   double lowerBand = mean - (InpBandDeviation * stdDev);

   // Regime Classification
   double fastMA = iMA(Symbol(), 0, InpFastMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowMA = iMA(Symbol(), 0, InpSlowMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double trendStrength = MathAbs(fastMA - slowMA) / stdDev;

   bool isTrendRegime = (trendStrength > InpTrendThreshold);

   // 3. Signal Generation
   if(isTrendRegime)
   {
      // Trend Breakout
      int highestBar = iHighest(Symbol(), 0, MODE_HIGH, InpWindow, 1);
      int lowestBar  = iLowest(Symbol(), 0, MODE_LOW, InpWindow, 1);
      double donchianHigh = High[highestBar];
      double donchianLow  = Low[lowestBar];

      if((fastMA > slowMA) && (mid > donchianHigh))
      {
         ExecuteOrder(OP_BUY, ask, InpStopLossPips, InpTakeProfitPips * 1.5);
      }
      else if((fastMA < slowMA) && (mid < donchianLow))
      {
         ExecuteOrder(OP_SELL, bid, InpStopLossPips, InpTakeProfitPips * 1.5);
      }
   }
   else
   {
      // Mean Reversion Exhaustion
      if(mid < lowerBand)
      {
         ExecuteOrder(OP_BUY, ask, InpStopLossPips, InpTakeProfitPips);
      }
      else if(mid > upperBand)
      {
         ExecuteOrder(OP_SELL, bid, InpStopLossPips, InpTakeProfitPips);
      }
   }
}

//+------------------------------------------------------------------+
//| Execute Order with Fixed Fractional Anti-Martingale Sizing       |
//+------------------------------------------------------------------+
void ExecuteOrder(int orderType, double price, double slPips, double tpPips)
{
   double slDist = slPips * g_pipSize;
   double tpDist = tpPips * g_pipSize;
   double slPrice = (orderType == OP_BUY) ? NormalizeDouble(price - slDist, Digits) : NormalizeDouble(price + slDist, Digits);
   double tpPrice = (orderType == OP_BUY) ? NormalizeDouble(price + tpDist, Digits) : NormalizeDouble(price - tpDist, Digits);

   double lots = CalculatePositionSize(slDist);
   color arrowColor = (orderType == OP_BUY) ? clrGreen : clrRed;

   int ticket = OrderSend(
      Symbol(),
      orderType,
      lots,
      price,
      InpMaxSlippagePips * g_pipMultiplier,
      slPrice,
      tpPrice,
      InpComment,
      InpMagicNumber,
      0,
      arrowColor
   );

   if(ticket < 0)
      Print("OrderSend failed with error: ", GetLastError());
   else
      Print("Order successfully opened. Ticket: ", ticket, " Lots: ", lots, " SL: ", slPrice, " TP: ", tpPrice);
}

//+------------------------------------------------------------------+
//| Calculate Position Size based on 1.5% Equity Risk                |
//+------------------------------------------------------------------+
double CalculatePositionSize(double slDistance)
{
   double equity = AccountEquity();
   double riskCapital = equity * (InpRiskPercent / 100.0);

   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);

   if(tickSize <= 0.0) tickSize = Point;
   if(tickValue <= 0.0) tickValue = 1.0;

   double lossPerLot = (slDistance / tickSize) * tickValue;
   if(lossPerLot <= 0.0) lossPerLot = 100.0;

   double lots = riskCapital / lossPerLot;
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep <= 0.0) lotStep = 0.01;

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(InpMinLotSize, MathMin(InpMaxLotSize, lots));
   return(NormalizeDouble(lots, 2));
}

//+------------------------------------------------------------------+
//| Count Active Orders with this EA's Magic Number                  |
//+------------------------------------------------------------------+
int CountActiveOrders()
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == InpMagicNumber)
            count++;
      }
   }
   return count;
}
