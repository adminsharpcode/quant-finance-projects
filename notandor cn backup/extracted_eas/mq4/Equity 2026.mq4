#property version   "3.1"
#property strict

// Version History
// - 2.1: Initial release with Balance-TargetEquity closure, trailing stop, and info panel.
// - 2.2: Added strict descending order for buy/sell closures; changed Balance-TargetEquity to Balance-InitialEquity for losing position closure.
// - 2.3: Split Stop Loss/Trailing Stop and Take Profit ATR settings; adjusted info panel YDISTANCE and button size.
// - 2.4: Reverted to Balance-TargetEquity threshold for closing largest losing trades.
// - 2.5: Added TradeGap option to require profitable positions to outnumber losing positions by a specified amount before triggering closure.
// - 2.6: Added option to close largest winning and losing positions of the same direction if overrepresented by at least 1 and combined P/L meets MinimumValue.
// - 2.7: Reduced log verbosity to minimize output, retaining only essential closure and error logs.
// - 2.8: Modified MinimumValue to represent USD per trade, scaled by the number of open trades in the overrepresented direction.
// - 2.9: Fixed MinimumValue logic to correctly identify largest losing position by P/L.
// - 3.1: Removed symbol restriction – now manages ALL open trades (filtered only by MagicNumber, or all if MagicNumber=0).

enum ENUM_TRAILING_SIZE_MODE
{
   PercentOfProfit = 0, // % of profit
   ATRTrailMultiplier = 1    // ATR * multiplier (renamed from ATRMultiplier)
};

//--- Main Settings
input string Main_Settings;
input double TargetEquityGain = 10.0; // Base equity gain in currency units (multiplied by ATR if UseATR is true)
input string FileName = "EquityTracker.txt"; // File to store InitialEquity
input int ATRPeriod = 14; // ATR period for volatility calculation (Equity tracking)
input ENUM_TIMEFRAMES ATRTimeframe = PERIOD_CURRENT; // ATR timeframe (Equity tracking)
input double ATREquityMultiplier = 0.5; // Multiplier for ATR to scale equity gain target (Equity tracking, renamed from ATRMultiplier)
input bool UseATR = false; // Enable/disable ATR-based adjustment for TargetEquityGain
input int MagicNumber = 0; // Magic number to filter positions (set to 0 to disable filtering)

// Buy/Sell Closure Settings
input string Offset_Closure_Settings; // Section Header
input double ActivationLevel = 80.0; // Profit level to trigger closure of buy or sell positions
input double MinimumProfit = 5.0; // Minimum overall profit of closed positions
input double MaximumProfit = 20.0; // Maximum overall profit of closed positions
input double MinimumRemainingProfit = 30.0; // Minimum profit to remain in profitable positions after closure
input int TradeGap = 0; // Min difference between profitable and losing positions to trigger closure (0 = disabled)
input double MinimumValue = 0.0; // Min combined P/L (USD per trade) * number of trades to close largest winning and losing positions of same direction (0 = disabled)

// Balance vs Target Equity Closure
input string Balance_TargetEquity_Closure;
input double BalanceTargetEquityThreshold = 50.0; // Threshold for Balance - TargetEquity to trigger losing position closure

//--- Info Panel Settings
input string Info_Panel_Settings;
input ENUM_BASE_CORNER PanelCorner = CORNER_LEFT_UPPER; // Chart corner for info panel (0=Top-Left, 1=Top-Right, 2=Bottom-Left, 3=Bottom-Right)
input int PanelWidth = 270; // Panel width in pixels
input int PanelHeight = 135; // Panel height in pixels (adjusted to fit content after YDISTANCE change)
input int FontSize = 12; // Font size for text
input int LineSpacing = 4; // Additional spacing between lines (pixels)
input color TextColor = clrLime; // Text color (used for labels and profits)
input color LossColor = clrRed; // Color for losses
input color BackgroundColor = clrIndigo; // Background color
input int BackgroundOpacity = 255; // Background opacity (0-255, 0=transparent, 255=opaque) - used for reference, not applied in MQL4
input int ButtonYDistance = 145; // Y-distance for emergency button

//--- Profit/Loss Settings
input string Profit_Loss_Settings = "===== Profit/Loss Settings ====="; // Section Header
// Stop Loss Settings
input int StopLoss_ATRPeriod = 14;        // ATR period for Stop Loss and Trailing Stop
input ENUM_TIMEFRAMES StopLoss_ATRTimeframe = PERIOD_M15; // ATR timeframe for Stop Loss and Trailing Stop
input double StopLoss_ATRMultiplier = 2.5; // ATR multiplier for Stop Loss
// Take Profit Settings
input int TakeProfit_ATRPeriod = 14;      // ATR period for Take Profit
input ENUM_TIMEFRAMES TakeProfit_ATRTimeframe = PERIOD_M15; // ATR timeframe for Take Profit
input double TakeProfit_ATRMultiplier = 2.5; // ATR multiplier for Take Profit
// Other Settings
input bool OnlyNewPositions = true;      // Modify only positions without SL/TP when true
input bool EnableStopLoss = false;        // Enable stop-loss modification
input bool EnableTakeProfit = false;       // Enable take-profit modification
input double MaxFloatingLoss = 18.0;     // Max floating loss (0 = disabled, in account currency)
input double MaxFloatingProfit = 10.0;     // Max floating profit (0 = disabled, in account currency)
input double ThresholdFloatingLoss = 0; // Threshold to start monitoring for minimal loss closure (0 = disabled)
input double PercentageClosure = 40.0;     // % of highest loss to close positions (0 = disabled)
input bool EnableTrailingStop = false;    // Enable trailing stop
input double TrailingStopStart = 1.3;     // ATR multiplier to start trailing (e.g., 0.5 * ATR)
input double TrailingStopStep = 0.5;      // Step size in pips for trailing update
input ENUM_TRAILING_SIZE_MODE TrailingStopSizeMode = ATRTrailMultiplier; // Trailing stop size mode
input double TrailingStopSize = 50.0;     // Trailing stop size (% of profit)
input double TrailingStopATRMultiplier = 0.7; // Trailing stop size (ATR multiplier)

// Global variables
double InitialEquity = 0.0; // Stores equity when no positions are open
bool EquitySet = false;     // Flag to check if initial equity is set
double ChartATR = 0.0;      // Stores ATR value for Equity tracking
double BuyFloatingPL = 0.0; // Total floating profit/loss for buy positions
double SellFloatingPL = 0.0; // Total floating profit/loss for sell positions
int TotalBuyPositions = 0;  // Total number of open buy positions
int TotalSellPositions = 0; // Total number of open sell positions
datetime LastEquityUpdateTime = 0; // Timestamp of the last InitialEquity update

// Variables to track previous state for logging
int PrevTotalBuyPositions = 0;
int PrevTotalSellPositions = 0;
double PrevBuyFloatingPL = 0.0;
double PrevSellFloatingPL = 0.0;
double PrevInitialEquity = 0.0;
datetime LastPositionLogTime = 0; // Timestamp of the last position log
datetime LastEquityLogTime = 0;   // Timestamp of the last equity log

// Global variables
int PreviousTickets[];
int PreviousTicketCount = 0;

// Structure to track MaxProfitInPips per position (for TrailingStop)
struct PositionData
{
   int ticket;
   double maxProfitInPips;
};
PositionData positionData[];
int positionDataCount = 0;

// Variables for tracking highest floating loss
double highestFloatingLoss = 0.0;  // Peak floating loss after threshold
bool thresholdTriggered = false;   // Flag to indicate threshold monitoring

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   InitialEquity = 0.0;
   EquitySet = false;
   BuyFloatingPL = 0.0;
   SellFloatingPL = 0.0;
   TotalBuyPositions = 0;
   TotalSellPositions = 0;
   LastEquityUpdateTime = 0;
   
   PrevTotalBuyPositions = 0;
   PrevTotalSellPositions = 0;
   PrevBuyFloatingPL = 0.0;
   PrevSellFloatingPL = 0.0;
   PrevInitialEquity = 0.0;
   LastPositionLogTime = 0;
   LastEquityLogTime = 0;
   
   if(LoadInitialEquity())
   {
      EquitySet = true;
      PrevInitialEquity = InitialEquity;
      Print("Loaded InitialEquity from file: ", InitialEquity);
   }
   else
   {
      int filteredPositions = 0;
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
               filteredPositions++;
         }
      }
      
      if(filteredPositions == 0)
      {
         InitialEquity = AccountEquity();
         EquitySet = true;
         SaveInitialEquity();
         LastEquityUpdateTime = TimeCurrent();
         PrevInitialEquity = InitialEquity;
         Print("No open filtered positions. Initial equity set to: ", InitialEquity);
      }
      else
      {
         Print("Open filtered positions detected. Waiting for all filtered positions to close to set initial equity.");
      }
   }
   
   CreateInfoPanel();
   CreateEmergencyButton();
   
   ArrayResize(PreviousTickets, OrdersTotal());
   PreviousTicketCount = 0;
   ArrayResize(positionData, OrdersTotal());
   positionDataCount = 0;
   highestFloatingLoss = 0.0;
   thresholdTriggered = false;
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Get or create MaxProfitInPips for a ticket                        |
//+------------------------------------------------------------------+
int GetPositionDataIndex(int ticket)
{
   for(int i = 0; i < positionDataCount; i++)
   {
      if(positionData[i].ticket == ticket)
         return i;
   }
   ArrayResize(positionData, positionDataCount + 1);
   positionData[positionDataCount].ticket = ticket;
   positionData[positionDataCount].maxProfitInPips = 0.0;
   positionDataCount++;
   return positionDataCount - 1;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update ChartATR for equity tracking (still uses chart symbol)
   ChartATR = iATR(Symbol(), ATRTimeframe, ATRPeriod, 1);
   if(ChartATR <= 0.0)
   {
      Print("Error retrieving ATR for ", Symbol(), ": ", GetLastError());
      ChartATR = 1.0; // Fallback to avoid zero multiplication
   }

   // Handle MaxFloatingLoss/MaxFloatingProfit and ThresholdFloatingLoss logic
   double totalFloatingProfit = 0.0;
   int totalFilteredPositions = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            totalFloatingProfit += OrderProfit() + OrderSwap() + OrderCommission();
            totalFilteredPositions++;
         }
      }
   }
   double totalFloatingLoss = -totalFloatingProfit;

   // Reset variables if no positions are open
   if(totalFilteredPositions == 0)
   {
      highestFloatingLoss = 0.0;
      thresholdTriggered = false;
   }

   // Only proceed with MaxFloatingLoss logic if MaxFloatingLoss > 0
   if(MaxFloatingLoss > 0)
   {
      if(totalFloatingLoss > MaxFloatingLoss)
      {
         CloseAllPositions();
         highestFloatingLoss = 0.0;
         thresholdTriggered = false;
         return;
      }
   }
   
   if(MaxFloatingProfit > 0.0)
   {
      if(totalFloatingProfit > MaxFloatingProfit)
      {
         CloseAllPositions();
         Print("MaxFloatingProfit exceeded. All positions closed. Profit: ", DoubleToString(totalFloatingProfit, 2));
         return;
      }
   }

   if(ThresholdFloatingLoss > 0)
   {
      if(totalFloatingLoss > ThresholdFloatingLoss)
      {
         if(!thresholdTriggered)
         {
            thresholdTriggered = true;
            highestFloatingLoss = totalFloatingLoss;
         }
         else if(totalFloatingLoss > highestFloatingLoss)
         {
            highestFloatingLoss = totalFloatingLoss;
         }
      }

      if(thresholdTriggered)
      {
         double targetLoss = highestFloatingLoss * (PercentageClosure / 100.0);
         if(totalFloatingLoss <= targetLoss && totalFloatingLoss > 0)
         {
            CloseAllPositions();
            highestFloatingLoss = 0.0;
            thresholdTriggered = false;
            return;
         }
      }
   }

   // Calculate floating profit/loss and position counts (now across all symbols)
   BuyFloatingPL = 0.0;
   SellFloatingPL = 0.0;
   TotalBuyPositions = 0;
   TotalSellPositions = 0;
   int profitableBuys = 0;
   int losingBuys = 0;
   int profitableSells = 0;
   int losingSells = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            double pl = OrderProfit() + OrderSwap() + OrderCommission();
            if(OrderType() == OP_BUY)
            {
               BuyFloatingPL += pl;
               TotalBuyPositions++;
               if(pl >= 0) profitableBuys++;
               else losingBuys++;
            }
            else if(OrderType() == OP_SELL)
            {
               SellFloatingPL += pl;
               TotalSellPositions++;
               if(pl >= 0) profitableSells++;
               else losingSells++;
            }
         }
      }
   }

   // Handle equity updates when no filtered positions are open
   int totalFilteredPositionsCheck = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            totalFilteredPositionsCheck++;
         }
      }
   }
   if(totalFilteredPositionsCheck == 0 && EquitySet)
   {
      double currentEquity = AccountEquity();
      if(currentEquity != PrevInitialEquity && TimeCurrent() - LastEquityLogTime >= 60)
      {
         InitialEquity = currentEquity;
         SaveInitialEquity();
         LastEquityUpdateTime = TimeCurrent();
         Print("Initial equity updated to: ", InitialEquity);
         PrevInitialEquity = InitialEquity;
         LastEquityLogTime = TimeCurrent();
      }
   }

   // Handle TradeGap and position closure logic
   if(totalFilteredPositionsCheck > 0)
   {
      if(BuyFloatingPL >= ActivationLevel)
      {
         int tradeGapDiff = profitableBuys - losingSells;
         if(TradeGap == 0 || tradeGapDiff >= TradeGap)
         {
            CloseBuyAndSomeSellPositions();
         }
      }
      else if(SellFloatingPL >= ActivationLevel)
      {
         int tradeGapDiff = profitableSells - losingBuys;
         if(TradeGap == 0 || tradeGapDiff >= TradeGap)
         {
            CloseSellAndSomeBuyPositions();
         }
      }

      // Handle MinimumValue logic
      if(MinimumValue > 0.0)
      {
         struct PositionDataPL
         {
            int ticket;
            double pl;
            int type; // OP_BUY or OP_SELL
         };
         PositionDataPL positions[];
         int positionCount = 0;

         for(int i = 0; i < OrdersTotal(); i++)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
               if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
               {
                  ArrayResize(positions, positionCount + 1);
                  positions[positionCount].ticket = OrderTicket();
                  positions[positionCount].pl = OrderProfit() + OrderSwap() + OrderCommission();
                  positions[positionCount].type = OrderType();
                  positionCount++;
               }
            }
         }

         PositionDataPL buyPositions[];
         int buyCount = 0;
         PositionDataPL sellPositions[];
         int sellCount = 0;

         for(int i = 0; i < positionCount; i++)
         {
            if(positions[i].type == OP_BUY)
            {
               ArrayResize(buyPositions, buyCount + 1);
               buyPositions[buyCount] = positions[i];
               buyCount++;
            }
            else if(positions[i].type == OP_SELL)
            {
               ArrayResize(sellPositions, sellCount + 1);
               sellPositions[sellCount] = positions[i];
               sellCount++;
            }
         }

         // Handle buy positions
         if(TotalBuyPositions >= TotalSellPositions + 1 && buyCount >= 2 && profitableBuys > 0 && losingBuys > 0)
         {
            // Sort buy positions by P/L (descending)
            for(int i = 0; i < buyCount - 1; i++)
            {
               for(int j = i + 1; j < buyCount; j++)
               {
                  if(buyPositions[j].pl > buyPositions[i].pl)
                  {
                     PositionDataPL temp = buyPositions[i];
                     buyPositions[i] = buyPositions[j];
                     buyPositions[j] = temp;
                  }
               }
            }

            int largestWinnerIndex = -1;
            int largestLoserIndex = -1;
            double minPL = 0.0;

            for(int i = 0; i < buyCount; i++)
            {
               if(buyPositions[i].pl >= 0 && largestWinnerIndex == -1)
               {
                  largestWinnerIndex = i;
                  break;
               }
            }

            for(int i = 0; i < buyCount; i++)
            {
               if(buyPositions[i].pl < 0 && (largestLoserIndex == -1 || buyPositions[i].pl < minPL))
               {
                  largestLoserIndex = i;
                  minPL = buyPositions[i].pl;
               }
            }

            if(largestWinnerIndex != -1 && largestLoserIndex != -1)
            {
               double combinedPL = buyPositions[largestWinnerIndex].pl + buyPositions[largestLoserIndex].pl;
               double dynamicThreshold = MinimumValue * TotalBuyPositions;
               if(combinedPL >= dynamicThreshold)
               {
                  if(OrderSelect(buyPositions[largestWinnerIndex].ticket, SELECT_BY_TICKET, MODE_TRADES))
                  {
                     if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
                        Print("Closed largest winning buy position #", buyPositions[largestWinnerIndex].ticket, " with P/L: ", buyPositions[largestWinnerIndex].pl);
                     else
                        Print("Error closing largest winning buy order #", OrderTicket(), ": ", GetLastError());
                  }
                  if(OrderSelect(buyPositions[largestLoserIndex].ticket, SELECT_BY_TICKET, MODE_TRADES))
                  {
                     if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
                        Print("Closed largest losing buy position #", buyPositions[largestLoserIndex].ticket, " with P/L: ", buyPositions[largestLoserIndex].pl);
                     else
                        Print("Error closing largest losing buy order #", OrderTicket(), ": ", GetLastError());
                  }
               }
            }
         }
         // Handle sell positions
         else if(TotalSellPositions >= TotalBuyPositions + 1 && sellCount >= 2 && profitableSells > 0 && losingSells > 0)
         {
            for(int i = 0; i < sellCount - 1; i++)
            {
               for(int j = i + 1; j < sellCount; j++)
               {
                  if(sellPositions[j].pl > sellPositions[i].pl)
                  {
                     PositionDataPL temp = sellPositions[i];
                     sellPositions[i] = sellPositions[j];
                     sellPositions[j] = temp;
                  }
               }
            }

            int largestWinnerIndex = -1;
            int largestLoserIndex = -1;
            double minPL = 0.0;

            for(int i = 0; i < sellCount; i++)
            {
               if(sellPositions[i].pl >= 0 && largestWinnerIndex == -1)
               {
                  largestWinnerIndex = i;
                  break;
               }
            }

            for(int i = 0; i < sellCount; i++)
            {
               if(sellPositions[i].pl < 0 && (largestLoserIndex == -1 || sellPositions[i].pl < minPL))
               {
                  largestLoserIndex = i;
                  minPL = sellPositions[i].pl;
               }
            }

            if(largestWinnerIndex != -1 && largestLoserIndex != -1)
            {
               double combinedPL = sellPositions[largestWinnerIndex].pl + sellPositions[largestLoserIndex].pl;
               double dynamicThreshold = MinimumValue * TotalSellPositions;
               if(combinedPL >= dynamicThreshold)
               {
                  if(OrderSelect(sellPositions[largestWinnerIndex].ticket, SELECT_BY_TICKET, MODE_TRADES))
                  {
                     if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
                        Print("Closed largest winning sell position #", sellPositions[largestWinnerIndex].ticket, " with P/L: ", sellPositions[largestWinnerIndex].pl);
                     else
                        Print("Error closing largest winning sell order #", OrderTicket(), ": ", GetLastError());
                  }
                  if(OrderSelect(sellPositions[largestLoserIndex].ticket, SELECT_BY_TICKET, MODE_TRADES))
                  {
                     if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
                        Print("Closed largest losing sell position #", sellPositions[largestLoserIndex].ticket, " with P/L: ", sellPositions[largestLoserIndex].pl);
                     else
                        Print("Error closing largest losing sell order #", OrderTicket(), ": ", GetLastError());
                  }
               }
            }
         }
      }
   }

   // Handle equity-based closure
   if(EquitySet)
   {
      double currentEquity = AccountEquity();
      double dynamicTargetGain = UseATR ? (TargetEquityGain * ChartATR * ATREquityMultiplier) : TargetEquityGain;
      double targetEquity = InitialEquity + dynamicTargetGain;

      if(currentEquity >= targetEquity)
      {
         CloseAllPositions();
         if(UseATR)
            Print("Target equity gain reached. All positions closed. InitialEquity: ", InitialEquity, ", Current equity: ", currentEquity);
         else
            Print("Target equity gain reached. All positions closed. InitialEquity: ", InitialEquity, ", Current equity: ", currentEquity);
      }

      double currentBalance = AccountBalance();
      double balanceTargetEquityDiff = currentBalance - targetEquity;
      if(balanceTargetEquityDiff >= BalanceTargetEquityThreshold)
      {
         CloseSomeLosingPositions();
      }
   }

   // Handle position ticket tracking
   int currentTickets[];
   ArrayResize(currentTickets, OrdersTotal());
   int currentCount = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            currentTickets[currentCount] = OrderTicket();
            currentCount++;
         }
      }
   }

   for(int i = 0; i < PreviousTicketCount; i++)
   {
      bool found = false;
      for(int j = 0; j < currentCount; j++)
      {
         if(PreviousTickets[i] == currentTickets[j])
         {
            found = true;
            break;
         }
      }
      if(!found)
      {
         if(OrderSelect(PreviousTickets[i], SELECT_BY_TICKET, MODE_HISTORY))
         {
            if(OrderMagicNumber() == MagicNumber || MagicNumber == 0)
            {
               Print("Position #", PreviousTickets[i], " closed. Profit: ", OrderProfit());
            }
         }
      }
   }

   ArrayResize(PreviousTickets, currentCount);
   for(int i = 0; i < currentCount; i++)
      PreviousTickets[i] = currentTickets[i];
   PreviousTicketCount = currentCount;

   // Handle Stop Loss, Take Profit, and Trailing Stop
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            bool skip = OnlyNewPositions;
            if(EnableStopLoss && EnableTakeProfit)
               skip = skip && (OrderStopLoss() != 0 && OrderTakeProfit() != 0);
            else if(EnableStopLoss)
               skip = skip && (OrderStopLoss() != 0);
            else if(EnableTakeProfit)
               skip = skip && (OrderTakeProfit() != 0);

            string symbol = OrderSymbol();
            double StopLossAtrValue = iATR(symbol, StopLoss_ATRTimeframe, StopLoss_ATRPeriod, 1);
            double TakeProfitAtrValue = iATR(symbol, TakeProfit_ATRTimeframe, TakeProfit_ATRPeriod, 1);

            if(StopLossAtrValue <= 0)
            {
               Print("Error: Invalid Stop Loss ATR for ", symbol);
               continue;
            }
            if(TakeProfitAtrValue <= 0)
            {
               Print("Error: Invalid Take Profit ATR for ", symbol);
               continue;
            }

            double NewSL = OrderStopLoss();
            double NewTP = OrderTakeProfit();
            double PointValue = MarketInfo(symbol, MODE_POINT);
            double MinStop = MarketInfo(symbol, MODE_STOPLEVEL) * PointValue;
            int SymbolDigits = (int)MarketInfo(symbol, MODE_DIGITS);
            double Spread = MarketInfo(symbol, MODE_SPREAD) * PointValue;

            if(!skip || EnableTrailingStop)
            {
               if(OrderType() == OP_BUY)
               {
                  if(EnableStopLoss && !skip)
                  {
                     NewSL = OrderOpenPrice() - (StopLossAtrValue * StopLoss_ATRMultiplier);
                     if(OrderOpenPrice() - NewSL < MinStop)
                        NewSL = OrderOpenPrice() - MinStop;
                  }
                  if(EnableTakeProfit && !skip)
                  {
                     NewTP = OrderOpenPrice() + (TakeProfitAtrValue * TakeProfit_ATRMultiplier);
                     if(NewTP - OrderOpenPrice() < MinStop)
                        NewTP = OrderOpenPrice() + MinStop;
                     if(NewTP <= OrderOpenPrice())
                        NewTP = OrderOpenPrice() + MinStop;
                  }
               }
               else if(OrderType() == OP_SELL)
               {
                  if(EnableStopLoss && !skip)
                  {
                     NewSL = OrderOpenPrice() + (StopLossAtrValue * StopLoss_ATRMultiplier);
                     if(NewSL - OrderOpenPrice() < MinStop)
                        NewSL = OrderOpenPrice() + MinStop;
                  }
                  if(EnableTakeProfit && !skip)
                  {
                     NewTP = OrderOpenPrice() - (TakeProfitAtrValue * TakeProfit_ATRMultiplier);
                     if(OrderOpenPrice() - NewTP < MinStop)
                        NewTP = OrderOpenPrice() - MinStop;
                     if(NewTP >= OrderOpenPrice())
                        NewTP = OrderOpenPrice() - MinStop;
                  }
               }
            }

            if(EnableTrailingStop)
            {
               double CurrentPrice = (OrderType() == OP_BUY) ? MarketInfo(symbol, MODE_BID) : MarketInfo(symbol, MODE_ASK);
               double ProfitInPoints = (OrderType() == OP_BUY) ? (CurrentPrice - OrderOpenPrice()) : (OrderOpenPrice() - CurrentPrice);
               double PipFactor = (SymbolDigits == 5 || SymbolDigits == 3) ? 10 : 1;
               double PointsPerPip = PointValue * PipFactor;
               double ProfitInPips = ProfitInPoints / PointsPerPip;
               double TrailingStartPips = (StopLossAtrValue * TrailingStopStart) / PointsPerPip;

               int dataIndex = GetPositionDataIndex(OrderTicket());
               if(ProfitInPips > positionData[dataIndex].maxProfitInPips)
                  positionData[dataIndex].maxProfitInPips = ProfitInPips;
               else if(ProfitInPips < 0)
                  positionData[dataIndex].maxProfitInPips = 0;

               if(positionData[dataIndex].maxProfitInPips >= TrailingStartPips)
               {
                  double TrailingStepPoints = TrailingStopStep * PointsPerPip;
                  double TrailingSL = 0;
                  double TrailingDistance = 0;

                  if(TrailingStopSizeMode == PercentOfProfit)
                     TrailingDistance = positionData[dataIndex].maxProfitInPips * TrailingStopSize / 100 * PointsPerPip;
                  else if(TrailingStopSizeMode == ATRTrailMultiplier)
                     TrailingDistance = StopLossAtrValue * TrailingStopATRMultiplier;

                  if(OrderType() == OP_BUY)
                  {
                     TrailingDistance += Spread;
                     TrailingSL = CurrentPrice - TrailingDistance;
                     if(CurrentPrice - TrailingSL < MinStop)
                        TrailingSL = CurrentPrice - MinStop;
                     if(TrailingSL > OrderStopLoss() + TrailingStepPoints || OrderStopLoss() == 0)
                        NewSL = TrailingSL;
                  }
                  else if(OrderType() == OP_SELL)
                  {
                     TrailingDistance += Spread;
                     TrailingSL = CurrentPrice + TrailingDistance;
                     if(TrailingSL - CurrentPrice < MinStop)
                        TrailingSL = CurrentPrice + MinStop;
                     if(TrailingSL < OrderStopLoss() - TrailingStepPoints || OrderStopLoss() == 0)
                        NewSL = TrailingSL;
                  }
               }
            }

            NewSL = NormalizeDouble(NewSL, SymbolDigits);
            NewTP = NormalizeDouble(NewTP, SymbolDigits);

            if((OrderStopLoss() != NewSL) || (EnableTakeProfit && OrderTakeProfit() != NewTP))
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), NewSL, NewTP, 0, clrNONE))
                  Print("Error modifying order #", OrderTicket(), ": ", GetLastError());
            }
         }
      }
   }

   UpdateInfoPanel();
   UpdateEmergencyButton();
}

//+------------------------------------------------------------------+
//| Function to close some buy positions and some sell positions     |
//+------------------------------------------------------------------+
void CloseBuyAndSomeSellPositions()
{
   struct ClosurePositionData
   {
      int ticket;
      double pl;
      int type; // OP_BUY or OP_SELL
   };
   ClosurePositionData positions[];
   int positionCount = 0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            ArrayResize(positions, positionCount + 1);
            positions[positionCount].ticket = OrderTicket();
            positions[positionCount].pl = OrderProfit() + OrderSwap() + OrderCommission();
            positions[positionCount].type = OrderType();
            positionCount++;
         }
      }
   }
   
   ClosurePositionData buyPositions[];
   int buyCount = 0;
   ClosurePositionData sellPositions[];
   int sellCount = 0;
   
   for(int i = 0; i < positionCount; i++)
   {
      if(positions[i].type == OP_BUY)
      {
         ArrayResize(buyPositions, buyCount + 1);
         buyPositions[buyCount] = positions[i];
         buyCount++;
      }
      else if(positions[i].type == OP_SELL)
      {
         ArrayResize(sellPositions, sellCount + 1);
         sellPositions[sellCount] = positions[i];
         sellCount++;
      }
   }
   
   for(int i = 0; i < buyCount - 1; i++)
   {
      for(int j = i + 1; j < buyCount; j++)
      {
         if(buyPositions[j].pl > buyPositions[i].pl)
         {
            ClosurePositionData temp = buyPositions[i];
            buyPositions[i] = buyPositions[j];
            buyPositions[j] = temp;
         }
      }
   }
   
   double totalClosedProfit = 0.0;
   double remainingBuyProfit = BuyFloatingPL;
   int buyClosed = 0;
   
   for(int i = 0; i < buyCount; i++)
   {
      double pl = buyPositions[i].pl;
      double projectedRemainingProfit = remainingBuyProfit - pl;
      
      if(projectedRemainingProfit < MinimumRemainingProfit && i < buyCount - 1)
         break;
      
      if(OrderSelect(buyPositions[i].ticket, SELECT_BY_TICKET, MODE_TRADES))
      {
         if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
         {
            totalClosedProfit += pl;
            remainingBuyProfit -= pl;
            buyClosed++;
         }
         else
            Print("Error closing buy order #", OrderTicket(), ": ", GetLastError());
      }
   }
   
   for(int i = 0; i < sellCount - 1; i++)
   {
      for(int j = i + 1; j < sellCount; j++)
      {
         if(sellPositions[j].pl > sellPositions[i].pl)
         {
            ClosurePositionData temp = sellPositions[i];
            sellPositions[i] = sellPositions[j];
            sellPositions[j] = temp;
         }
      }
   }
   
   double remainingProfit = totalClosedProfit;
   int sellClosed = 0;
   
   for(int i = 0; i < sellCount; i++)
   {
      if(OrderSelect(sellPositions[i].ticket, SELECT_BY_TICKET, MODE_TRADES))
      {
         double pl = sellPositions[i].pl;
         double projectedProfit = remainingProfit + pl;
         
         if(projectedProfit > MaximumProfit && i < sellCount - 1)
            break;
         else if(projectedProfit >= MinimumProfit)
         {
            if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
            {
               remainingProfit += pl;
               sellClosed++;
            }
            else
               Print("Error closing sell order #", OrderTicket(), ": ", GetLastError());
         }
      }
   }
   
   if(buyClosed > 0 || sellClosed > 0)
      Print("Closed ", buyClosed, " buy and ", sellClosed, " sell positions. Total profit: ", remainingProfit);
}

//+------------------------------------------------------------------+
//| Function to close some sell positions and some buy positions     |
//+------------------------------------------------------------------+
void CloseSellAndSomeBuyPositions()
{
   struct ClosurePositionData
   {
      int ticket;
      double pl;
      int type; // OP_BUY or OP_SELL
   };
   ClosurePositionData positions[];
   int positionCount = 0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            ArrayResize(positions, positionCount + 1);
            positions[positionCount].ticket = OrderTicket();
            positions[positionCount].pl = OrderProfit() + OrderSwap() + OrderCommission();
            positions[positionCount].type = OrderType();
            positionCount++;
         }
      }
   }
   
   ClosurePositionData sellPositions[];
   int sellCount = 0;
   ClosurePositionData buyPositions[];
   int buyCount = 0;
   
   for(int i = 0; i < positionCount; i++)
   {
      if(positions[i].type == OP_SELL)
      {
         ArrayResize(sellPositions, sellCount + 1);
         sellPositions[sellCount] = positions[i];
         sellCount++;
      }
      else if(positions[i].type == OP_BUY)
      {
         ArrayResize(buyPositions, buyCount + 1);
         buyPositions[buyCount] = positions[i];
         buyCount++;
      }
   }
   
   for(int i = 0; i < sellCount - 1; i++)
   {
      for(int j = i + 1; j < sellCount; j++)
      {
         if(sellPositions[j].pl > sellPositions[i].pl)
         {
            ClosurePositionData temp = sellPositions[i];
            sellPositions[i] = sellPositions[j];
            sellPositions[j] = temp;
         }
      }
   }
   
   double totalClosedProfit = 0.0;
   double remainingSellProfit = SellFloatingPL;
   int sellClosed = 0;
   
   for(int i = 0; i < sellCount; i++)
   {
      double pl = sellPositions[i].pl;
      double projectedRemainingProfit = remainingSellProfit - pl;
      
      if(projectedRemainingProfit < MinimumRemainingProfit && i < sellCount - 1)
         break;
      
      if(OrderSelect(sellPositions[i].ticket, SELECT_BY_TICKET, MODE_TRADES))
      {
         if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
         {
            totalClosedProfit += pl;
            remainingSellProfit -= pl;
            sellClosed++;
         }
         else
            Print("Error closing sell order #", OrderTicket(), ": ", GetLastError());
      }
   }
   
   for(int i = 0; i < buyCount - 1; i++)
   {
      for(int j = i + 1; j < buyCount; j++)
      {
         if(buyPositions[j].pl > buyPositions[i].pl)
         {
            ClosurePositionData temp = buyPositions[i];
            buyPositions[i] = buyPositions[j];
            buyPositions[j] = temp;
         }
      }
   }
   
   double remainingProfit = totalClosedProfit;
   int buyClosed = 0;
   
   for(int i = 0; i < buyCount; i++)
   {
      if(OrderSelect(buyPositions[i].ticket, SELECT_BY_TICKET, MODE_TRADES))
      {
         double pl = buyPositions[i].pl;
         double projectedProfit = remainingProfit + pl;
         
         if(projectedProfit > MaximumProfit && i < buyCount - 1)
            break;
         else if(projectedProfit >= MinimumProfit)
         {
            if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
            {
               remainingProfit += pl;
               buyClosed++;
            }
            else
               Print("Error closing buy order #", OrderTicket(), ": ", GetLastError());
         }
      }
   }
   
   if(sellClosed > 0 || buyClosed > 0)
      Print("Closed ", sellClosed, " sell and ", buyClosed, " buy positions. Total profit: ", remainingProfit);
}

//+------------------------------------------------------------------+
//| Function to close the largest losing position                    |
//+------------------------------------------------------------------+
void CloseSomeLosingPositions()
{
   struct ClosurePositionData
   {
      int ticket;
      double pl;
      int type; // OP_BUY or OP_SELL
   };
   ClosurePositionData positions[];
   int positionCount = 0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            double pl = OrderProfit() + OrderSwap() + OrderCommission();
            if(pl < 0.0)
            {
               ArrayResize(positions, positionCount + 1);
               positions[positionCount].ticket = OrderTicket();
               positions[positionCount].pl = pl;
               positions[positionCount].type = OrderType();
               positionCount++;
            }
         }
      }
   }
   
   if(positionCount == 0)
      return;
   
   for(int i = 0; i < positionCount - 1; i++)
   {
      for(int j = i + 1; j < positionCount; j++)
      {
         if(positions[j].pl < positions[i].pl)
         {
            ClosurePositionData temp = positions[i];
            positions[i] = positions[j];
            positions[j] = temp;
         }
      }
   }
   
   double largestLoss = MathAbs(positions[0].pl);
   int largestLossTicket = positions[0].ticket;
   
   double currentBalance = AccountBalance();
   double dynamicTargetGain = UseATR ? (TargetEquityGain * ChartATR * ATREquityMultiplier) : TargetEquityGain;
   double targetEquity = InitialEquity + dynamicTargetGain;
   double balanceTargetEquityDiff = currentBalance - targetEquity;
   
   if(balanceTargetEquityDiff >= BalanceTargetEquityThreshold && balanceTargetEquityDiff > largestLoss)
   {
      if(OrderSelect(largestLossTicket, SELECT_BY_TICKET, MODE_TRADES))
      {
         if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
            Print("Closed largest losing position #", largestLossTicket, " with loss: ", largestLoss);
         else
            Print("Error closing largest losing position #", OrderTicket(), ": ", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| Function to close all open positions                             |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
               Print("Error closing order #", OrderTicket(), ": ", GetLastError());
         }
      }
   }
   
   InitialEquity = AccountEquity();
   EquitySet = true;
   SaveInitialEquity();
   LastEquityUpdateTime = TimeCurrent();
   PrevInitialEquity = InitialEquity;
   Print("All positions closed. Initial equity updated to: ", InitialEquity);
}

//+------------------------------------------------------------------+
//| Function to save InitialEquity to file                           |
//+------------------------------------------------------------------+
void SaveInitialEquity()
{
   int handle = FileOpen(FileName, FILE_WRITE | FILE_TXT);
   if(handle != INVALID_HANDLE)
   {
      FileWrite(handle, DoubleToString(InitialEquity, 2));
      FileClose(handle);
      Print("InitialEquity saved to file: ", InitialEquity);
   }
   else
      Print("Error saving InitialEquity to file: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Function to load InitialEquity from file                         |
//+------------------------------------------------------------------+
bool LoadInitialEquity()
{
   if(!FileIsExist(FileName)) return false;
   
   int handle = FileOpen(FileName, FILE_READ | FILE_TXT);
   if(handle != INVALID_HANDLE)
   {
      string data = FileReadString(handle);
      InitialEquity = StringToDouble(data);
      FileClose(handle);
      if(InitialEquity > 0.0)
         return true;
   }
   else
      Print("Error loading InitialEquity from file: ", GetLastError());
   return false;
}

//+------------------------------------------------------------------+
//| Function to create info panel on chart                           |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
   ObjectDelete(0, "EquityTracker_Background");
   ObjectDelete(0, "EquityTracker_InitialEquity");
   ObjectDelete(0, "EquityTracker_CurrentEquity");
   ObjectDelete(0, "EquityTracker_TargetEquity");
   ObjectDelete(0, "EquityTracker_BuyPL");
   ObjectDelete(0, "EquityTracker_SellPL");
   
   ObjectCreate(0, "EquityTracker_Background", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_YDISTANCE, 5);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_XSIZE, PanelWidth);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_YSIZE, PanelHeight);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_BGCOLOR, BackgroundColor);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_COLOR, BackgroundColor);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_FILL, true);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_BACK, false);
   ObjectSetInteger(0, "EquityTracker_Background", OBJPROP_ZORDER, 10);
   
   ObjectCreate(0, "EquityTracker_InitialEquity", OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0, "EquityTracker_CurrentEquity", OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0, "EquityTracker_TargetEquity", OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0, "EquityTracker_BuyPL", OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0, "EquityTracker_SellPL", OBJ_LABEL, 0, 0, 0);
   
   ObjectSetInteger(0, "EquityTracker_InitialEquity", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_InitialEquity", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_InitialEquity", OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_InitialEquity", OBJPROP_COLOR, TextColor);
   ObjectSetString(0, "EquityTracker_InitialEquity", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "EquityTracker_InitialEquity", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "EquityTracker_InitialEquity", OBJPROP_ZORDER, 20);
   
   ObjectSetInteger(0, "EquityTracker_CurrentEquity", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_CurrentEquity", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_CurrentEquity", OBJPROP_YDISTANCE, 10 + FontSize + 10 + LineSpacing);
   ObjectSetInteger(0, "EquityTracker_CurrentEquity", OBJPROP_COLOR, TextColor);
   ObjectSetString(0, "EquityTracker_CurrentEquity", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "EquityTracker_CurrentEquity", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "EquityTracker_CurrentEquity", OBJPROP_ZORDER, 20);
   
   ObjectSetInteger(0, "EquityTracker_TargetEquity", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_TargetEquity", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_TargetEquity", OBJPROP_YDISTANCE, 10 + (FontSize + 10 + LineSpacing) * 2);
   ObjectSetInteger(0, "EquityTracker_TargetEquity", OBJPROP_COLOR, TextColor);
   ObjectSetString(0, "EquityTracker_TargetEquity", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "EquityTracker_TargetEquity", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "EquityTracker_TargetEquity", OBJPROP_ZORDER, 20);
   
   ObjectSetInteger(0, "EquityTracker_BuyPL", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_BuyPL", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_BuyPL", OBJPROP_YDISTANCE, 10 + (FontSize + 10 + LineSpacing) * 3);
   ObjectSetString(0, "EquityTracker_BuyPL", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "EquityTracker_BuyPL", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "EquityTracker_BuyPL", OBJPROP_ZORDER, 20);
   
   ObjectSetInteger(0, "EquityTracker_SellPL", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_SellPL", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_SellPL", OBJPROP_YDISTANCE, 10 + (FontSize + 10 + LineSpacing) * 4);
   ObjectSetString(0, "EquityTracker_SellPL", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "EquityTracker_SellPL", OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "EquityTracker_SellPL", OBJPROP_ZORDER, 20);
   
   UpdateInfoPanel();
}

//+------------------------------------------------------------------+
//| Function to create emergency button                              |
//+------------------------------------------------------------------+
void CreateEmergencyButton()
{
   ObjectDelete(0, "EquityTracker_EmergencyButton");
   
   ObjectCreate(0, "EquityTracker_EmergencyButton", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_YDISTANCE, ButtonYDistance);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_XSIZE, 80);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_YSIZE, 20);
   ObjectSetString(0, "EquityTracker_EmergencyButton", OBJPROP_TEXT, "Close All");
   ObjectSetString(0, "EquityTracker_EmergencyButton", OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_BGCOLOR, clrRed);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_BORDER_COLOR, clrBlack);
   ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_ZORDER, 30);
   
   UpdateEmergencyButton();
}

//+------------------------------------------------------------------+
//| Function to update emergency button state                        |
//+------------------------------------------------------------------+
void UpdateEmergencyButton()
{
   int totalFilteredPositions = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() <= OP_SELL && (OrderMagicNumber() == MagicNumber || MagicNumber == 0))
         {
            totalFilteredPositions++;
         }
      }
   }
   if(totalFilteredPositions > 0)
   {
      ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_STATE, false);
      ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_BGCOLOR, clrRed);
   }
   else
   {
      ObjectSetInteger(0, "EquityTracker_EmergencyButton", OBJPROP_BGCOLOR, clrGray);
   }
}

//+------------------------------------------------------------------+
//| Function to update info panel on chart                           |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
   string initialEquityText = EquitySet ? DoubleToString(InitialEquity, 2) : "Waiting for no positions";
   string currentEquityText = DoubleToString(AccountEquity(), 2);
   double targetEquityValue = EquitySet ? (InitialEquity + (UseATR ? (TargetEquityGain * ChartATR * ATREquityMultiplier) : TargetEquityGain)) : 0.0;
   string targetEquityText = EquitySet ? DoubleToString(targetEquityValue, 2) : "N/A";
   string buyPLText = DoubleToString(BuyFloatingPL, 2) + " (" + IntegerToString(TotalBuyPositions) + ")";
   string sellPLText = DoubleToString(SellFloatingPL, 2) + " (" + IntegerToString(TotalSellPositions) + ")";
   
   ObjectSetString(0, "EquityTracker_InitialEquity", OBJPROP_TEXT, "Initial Equity: " + initialEquityText);
   ObjectSetString(0, "EquityTracker_CurrentEquity", OBJPROP_TEXT, "Current Equity: " + currentEquityText);
   ObjectSetString(0, "EquityTracker_TargetEquity", OBJPROP_TEXT, "Target Equity: " + targetEquityText);
   ObjectSetString(0, "EquityTracker_BuyPL", OBJPROP_TEXT, "Buy P/L: " + buyPLText);
   ObjectSetString(0, "EquityTracker_SellPL", OBJPROP_TEXT, "Sell P/L: " + sellPLText);
   
   ObjectSetInteger(0, "EquityTracker_BuyPL", OBJPROP_COLOR, BuyFloatingPL >= 0 ? TextColor : LossColor);
   ObjectSetInteger(0, "EquityTracker_SellPL", OBJPROP_COLOR, SellFloatingPL >= 0 ? TextColor : LossColor);
}

//+------------------------------------------------------------------+
//| Expert chart event function (for button clicks)                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == "EquityTracker_EmergencyButton")
   {
      CloseAllPositions();
      Print("Emergency button clicked. All positions closed and initial equity updated.");
      UpdateInfoPanel();
      UpdateEmergencyButton();
   }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(0, "EquityTracker_Background");
   ObjectDelete(0, "EquityTracker_InitialEquity");
   ObjectDelete(0, "EquityTracker_CurrentEquity");
   ObjectDelete(0, "EquityTracker_TargetEquity");
   ObjectDelete(0, "EquityTracker_BuyPL");
   ObjectDelete(0, "EquityTracker_SellPL");
   ObjectDelete(0, "EquityTracker_EmergencyButton");
   
   ArrayFree(positionData);
   positionDataCount = 0;
   highestFloatingLoss = 0.0;
   thresholdTriggered = false;
   
   Print("EA stopped. Reason: ", reason);
}