//+------------------------------------------------------------------+
//|                                        XAUUSD_KeyLevels_EA.mq5   |
//|                                      Copyright 2026, Assistant   |
//|                                          Made By Mark_TH1911     |
//+------------------------------------------------------------------+
#property copyright "Made By Mark_TH1911"
#property link      "https://t.me/bKjQqhfsY"
#property version   "12.09"
#property strict

#include <Trade\Trade.mqh>
#include <Canvas\Canvas.mqh>

//--- Input parameters
input group "--- SNR Detection Inputs ---"
input int    InpPivotLeftWindow  = 20;         // Required Bars to Left (Pattern Strength)
input int    InpPivotRightWindow = 5;          // Bars to Wait for Confirmation
input int    InpMaxLookbackBars  = 1000;       // Max Lookback Range (Bars back to scan)
input double InpMinPushPrice     = 5.00;       // Minimum Displacement ($5.00)
input double InpZoneThreshold    = 0.75;       // Zone Buffer ($0.75 threshold to prevent overlapping)
input int    InpMaxLevels        = 5;          // Max Active Levels to display per side

input group "--- Visual Inputs ---"
input color  InpResColor         = clrRed;     // Active Resistance Color
input color  InpSupColor         = clrDeepSkyBlue;// Active Support Color
input color  InpBrokenColor      = clrGray;    // Historical Broken Zone Color
input int    InpLineWidth        = 2;          // Line Width

input group "--- Risk Management Inputs ---"
input bool   InpUseRiskPercent   = true;       // Enable Auto Risk % Compounding
input double InpRiskPercent      = 1.0;        // Risk % per Trade (e.g., 1.0 = 1% of Equity)
input double InpLotSize          = 0.01;       // Fallback Lot Size (if Risk % is false)

input group "--- EA Trading Inputs ---"
input ulong  InpMagicNumber      = 888123;     // Magic Number
input int    InpMaxSpreadPoints  = 30;         // Max Spread Filter (Points/Pips-equivalent)
input int    InpStopLossPoints   = 75;         // Fixed SL = 75 points (7.5 pips)
input int    InpTakeProfitPoints = 375;        // Fixed TP = 375 points (37.5 pips)
input int    InpTrailingStart    = 50;         // Trailing Start = 50 points (5.0 pips)
input int    InpTrailingStep     = 25;         // Trailing Step = 2.5 pips

//--- Global Objects
CTrade trade;
CCanvas hudCanvas;
bool isTesterMode = false;
bool isVisualMode = false;

//--- Virtual Trailing Tracker (Engine 2) ---
struct TVirtualTrail
{
   ulong  ticket;
   double virtualSL;
   long   type;
   bool   engine1Failed; 
};
TVirtualTrail virtualStops[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   
   isTesterMode = (bool)MQLInfoInteger(MQL_TESTER);
   isVisualMode = (bool)MQLInfoInteger(MQL_VISUAL_MODE);
   
   // OPTIMIZATION: Skip Canvas creation entirely in non-visual backtests for maximum speed
   if(!isTesterMode || isVisualMode)
     {
      if(!hudCanvas.CreateBitmapLabel(0, 0, "LuxuryHUD", 20, 30, 330, 250, COLOR_FORMAT_ARGB_NORMALIZE))
        {
         Print("Error creating Elite Luxury HUD canvas!");
         return(INIT_FAILED);
        }
      DrawLuxuryHUD(0, 0, 0, 0, 0, 0);
      
      // Only set fast timer if not in standard non-visual backtest
      EventSetMillisecondTimer(50); 
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(!isTesterMode || isVisualMode)
     {
      EventKillTimer();
      hudCanvas.Destroy();
     }
   ObjectsDeleteAll(0, "XAU_SoftSR_");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Manage Trailing Stops for Open Positions
   ManageTrailingStops();

   // 2. Refresh SNR detection on new bar close
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   if(currentBarTime != lastBarTime)
     {
      lastBarTime = currentBarTime;

      MqlRates rates[];
      ArraySetAsSeries(rates, false);
      int copied = CopyRates(_Symbol, _Period, 0, InpMaxLookbackBars + InpPivotLeftWindow + 10, rates);

      if(copied <= InpPivotLeftWindow + InpPivotRightWindow + 1)
         return;

      double activeRes[];
      double activeSup[];

      ScanAndDrawSNR(rates, copied, activeRes, activeSup);
      SyncPendingOrders(activeRes, activeSup);
     }
      
   if(!isTesterMode || isVisualMode)
      UpdateDashboardStats();
  }

//+------------------------------------------------------------------+
//| Timer function for live HUD rendering (Fires every 50ms)         |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!isTesterMode || isVisualMode)
      UpdateDashboardStats();
  }

//+------------------------------------------------------------------+
//| Gather stats & redraw Elite Luxury Dashboard (Optimized Cache)   |
//+------------------------------------------------------------------+
void UpdateDashboardStats()
  {
   static double todayWin = 0, todayLoss = 0, todayNet = 0, todayComm = 0, weekNet = 0;
   static int todayOrders = 0;
   static int lastTotalDeals = -1;
   
   // 1. Calculate time periods first
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime startOfDay = StructToTime(dt);
   datetime startOfWeek = now - (7 * 86400);

   // 2. CRITICAL FIX: Must select history pool BEFORE calling HistoryDealsTotal()
   HistorySelect(startOfWeek, now);
   
   // 3. Now we can accurately get the total deals
   int currentTotalDeals = HistoryDealsTotal();
   
   // 4. OPTIMIZATION: Only scan history loop if total deals have actually changed
   if(currentTotalDeals == lastTotalDeals && lastTotalDeals != -1)
     {
      // Redraw with cached static values (Needed for Jet Animation to stay smooth)
      if(!isTesterMode || isVisualMode)
         DrawLuxuryHUD(todayWin, todayLoss, todayOrders, todayNet, todayComm, weekNet);
      return;
     }
     
   lastTotalDeals = currentTotalDeals;

   // 5. Reset stats for recalculation
   todayWin = 0; todayLoss = 0; todayNet = 0; todayComm = 0; weekNet = 0;
   todayOrders = 0;

   // 6. Loop through the freshly selected history pool
   for(int i = 0; i < currentTotalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
        {
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber)
           {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
            double comm = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            double totalDealProfit = profit + swap + comm;
            long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);

            if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
              {
               if(dealTime >= startOfDay)
                 {
                  todayOrders++;
                  todayComm += comm;
                  todayNet += totalDealProfit;
                  if(profit >= 0) todayWin += profit;
                  else todayLoss += profit;
                 }
               if(dealTime >= startOfWeek)
                 {
                  weekNet += totalDealProfit;
                 }
              }
           }
        }
     }

   if(!isTesterMode || isVisualMode)
      DrawLuxuryHUD(todayWin, todayLoss, todayOrders, todayNet, todayComm, weekNet);
  }

//+------------------------------------------------------------------+
//| Draw Elite Luxury Theme HUD Panel                                |
//+------------------------------------------------------------------+
void DrawLuxuryHUD(double tWin, double tLoss, int tOrders, double tNet, double tComm, double wNet)
  {
   // Deep luxury obsidian black background with smooth transparency
   hudCanvas.Erase(ColorToARGB(C'12, 13, 18', 248));

   uint champagneGold = ColorToARGB(C'212, 175, 55', 255);
   uint softGold      = ColorToARGB(C'235, 205, 110', 200);
   uint platinumSilver= ColorToARGB(C'185, 195, 210', 255);
   uint textWhite     = ColorToARGB(clrWhite, 255);
   uint textGreen     = ColorToARGB(C'0, 230, 130', 255);
   uint textRed       = ColorToARGB(C'255, 95, 110', 255);

   // Outer Luxury Dual-Frame Border
   hudCanvas.Rectangle(0, 0, 329, 249, champagneGold);
   hudCanvas.Rectangle(2, 2, 327, 247, ColorToARGB(C'50, 55, 70', 255));

   // Corner Luxury Filigree Accents
   hudCanvas.Line(0, 0, 30, 0, champagneGold);
   hudCanvas.Line(0, 0, 0, 30, champagneGold);
   hudCanvas.Line(299, 249, 329, 249, champagneGold);
   hudCanvas.Line(329, 219, 329, 249, champagneGold);

   // Header Section Background
   hudCanvas.FillRectangle(3, 3, 326, 42, ColorToARGB(C'22, 24, 32', 255));
   
   hudCanvas.FontSet("Consolas", 18, FW_BOLD);
   hudCanvas.TextOut(15, 10, "Aspect Quant // XAUUSD", softGold);

   // Elegant Section Divider Line
   hudCanvas.Line(15, 50, 315, 50, ColorToARGB(C'60, 65, 85', 255));

   // Metrics Rows Configuration
   int y = 60;
   int rowHeight = 23;
   int labelX = 15;
   int valueX = 175;
   
   hudCanvas.FontSet("Consolas", 12, FW_BOLD);

   // 1. Today Total Win
   hudCanvas.TextOut(labelX, y, "TODAY TOTAL WIN:", platinumSilver);
   hudCanvas.TextOut(valueX, y, StringFormat("$%.2f", tWin), textGreen);
   y += rowHeight;

   // 2. Today Total Loss
   hudCanvas.TextOut(labelX, y, "TODAY TOTAL LOSS:", platinumSilver);
   hudCanvas.TextOut(valueX, y, StringFormat("$%.2f", tLoss), textRed);
   y += rowHeight;

   // 3. Today Total Orders
   hudCanvas.TextOut(labelX, y, "TODAY TOTAL ORDERS:", platinumSilver);
   hudCanvas.TextOut(valueX, y, IntegerToString(tOrders), textWhite);
   y += rowHeight;

   // 4. Today Net Profit
   hudCanvas.TextOut(labelX, y, "TODAY NET PROFIT:", platinumSilver);
   uint netColor = (tNet >= 0) ? textGreen : textRed;
   hudCanvas.TextOut(valueX, y, StringFormat("$%.2f", tNet), netColor);
   y += rowHeight;

   // 5. Today Commission
   hudCanvas.TextOut(labelX, y, "TODAY COMMISSION:", platinumSilver);
   hudCanvas.TextOut(valueX, y, StringFormat("$%.2f", tComm), textWhite);
   y += rowHeight;

   // 6. 1 Week Total Net
   hudCanvas.TextOut(labelX, y, "1-WEEK TOTAL NET:", platinumSilver);
   uint weekColor = (wNet >= 0) ? textGreen : textRed;
   hudCanvas.TextOut(valueX, y, StringFormat("$%.2f", wNet), weekColor);
   y += 20;

   // Footer Divider Line
   hudCanvas.Line(15, y, 315, y, ColorToARGB(C'60, 65, 85', 255));

   // Footer Branding
   hudCanvas.FontSet("Consolas", 11, FW_BOLD);
   hudCanvas.TextOut(labelX, y + 12, "Made By Mark_TH1911", champagneGold);

   // =========================================================================
   // ?? 2D PIXEL JET PLANE ANIMATION ENGINE (SUPERSONIC FLIGHT EFFECT)
   // =========================================================================
   uint t = GetTickCount();
   
   int planeX = 245;
   int planeY = 220;
   
   // Smooth aerodynamic floating bounce (sine wave)
   int bounce = (int)(MathSin(t / 90.0) * 2.0); 
   int py = planeY + bounce; 
   
   // Jet Colors
   uint jetBody      = ColorToARGB(C'200, 210, 225', 255); // Titanium Silver Body
   uint jetDark      = ColorToARGB(C'90, 100, 115', 255);   // Dark Metallic Details
   uint canopyColor  = ColorToARGB(C'50, 180, 255', 255);   // Glowing Cyan Canopy
   uint wingColor    = ColorToARGB(C'140, 155, 175', 255);  // Swept Wings
   
   // Blue-Purple Afterburner / Exhaust Colors
   uint coreFlame    = ColorToARGB(C'200, 230, 255', 255); // Bright white-blue core
   uint blueFlame    = ColorToARGB(C'0, 140, 255', 220);   // Electric Blue Flame
   uint purpleFlame  = ColorToARGB(C'140, 40, 255', 180);  // Deep Purple Outer Glow
   
   // 1. High-Altitude Wind / Speed Lines
   int windSpeed = (int)((t / 8) % 40);
   for(int i = 0; i < 5; i++) {
       int lineX = 210 + (i * 25) - windSpeed;
       if(lineX > 215 && lineX < 320) {
           int lineY = py - 20 + (i * 10);
           hudCanvas.FillRectangle(lineX, lineY, lineX + 8, lineY + 1, ColorToARGB(C'150, 180, 220', 100));
       }
   }
   
   // 2. Dynamic Blue-Purple Afterburner / Jet Exhaust
   int flicker = (int)((t / 25) % 3); 
   
   for(int p = 0; p < 4; p++) {
       int pxOffset = planeX - 12 - (p * 6) - (flicker * 2);
       if(pxOffset > 215) {
           uchar alpha = (uchar)(160 - (p * 40));
           uint particleClr = ColorToARGB(C'138, 43, 226', alpha); 
           hudCanvas.FillRectangle(pxOffset, py - 3 - (p/2), pxOffset + 4, py + 3 + (p/2), particleClr);
       }
   }
   
   hudCanvas.FillRectangle(planeX - 10 - flicker, py - 2, planeX, py + 2, blueFlame);
   hudCanvas.FillRectangle(planeX - 5, py - 1, planeX, py + 1, coreFlame);
   hudCanvas.FillRectangle(planeX - 16 - flicker, py - 4, planeX - 8, py + 4, purpleFlame);

   // 3. Draw Jet Fighter Silhouette (Facing Right)
   hudCanvas.FillRectangle(planeX, py - 4, planeX + 50, py + 4, jetBody);
   hudCanvas.FillRectangle(planeX + 50, py - 3, planeX + 58, py + 3, jetBody);
   hudCanvas.FillRectangle(planeX + 58, py - 1, planeX + 62, py + 1, jetDark);
   hudCanvas.FillRectangle(planeX + 25, py - 7, planeX + 38, py - 4, canopyColor);
   hudCanvas.FillRectangle(planeX + 15, py - 14, planeX + 32, py - 4, wingColor); 
   hudCanvas.FillRectangle(planeX + 15, py + 4, planeX + 32, py + 14, wingColor);  
   hudCanvas.FillRectangle(planeX + 2, py - 9, planeX + 10, py - 4, jetDark);  
   hudCanvas.FillRectangle(planeX, py - 2, planeX + 6, py + 2, jetDark);         
   // =========================================================================

   hudCanvas.Update();
  }

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size Based on Risk % and SL Distance       |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPoints)
  {
   if(!InpUseRiskPercent)
      return InpLotSize;

   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = accountEquity * (InpRiskPercent / 100.0);

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(tickSize <= 0 || tickValue <= 0 || slPoints <= 0)
      return InpLotSize;

   double slPriceDistance = slPoints * _Point;
   double lossPerOneLot = (slPriceDistance / tickSize) * tickValue;

   if(lossPerOneLot <= 0)
      return minLot;

   double calculatedLot = riskMoney / lossPerOneLot;
   calculatedLot = MathFloor(calculatedLot / lotStep) * lotStep;

   if(calculatedLot < minLot) calculatedLot = minLot;
   if(calculatedLot > maxLot) calculatedLot = maxLot;

   int digits = 2;
   if(lotStep == 0.1) digits = 1;
   else if(lotStep == 0.01) digits = 2;
   else if(lotStep == 0.001) digits = 3;
   else if(lotStep == 1.0) digits = 0;

   return NormalizeDouble(calculatedLot, digits);
  }

//+------------------------------------------------------------------+
//| Detect SNR Zones & Draw Visual Chart Objects                     |
//+------------------------------------------------------------------+
void ScanAndDrawSNR(const MqlRates &rates[], int totalBars, double &activeRes[], double &activeSup[])
  {
   ObjectsDeleteAll(0, "XAU_SoftSR_");

   int resCount = 0;
   int supCount = 0;
   int brokenResCount = 0;
   int brokenSupCount = 0;

   int start_idx = totalBars - 1 - InpPivotRightWindow;
   int limit_idx = totalBars - InpMaxLookbackBars;
   if(limit_idx < InpPivotLeftWindow)
      limit_idx = InpPivotLeftWindow;

   for(int i = start_idx; i >= limit_idx; i--)
     {
      // 1. RESISTANCE (SWING HIGH PATTERN)
      bool isResPivotPattern = true;

      for(int j = 1; j <= InpPivotLeftWindow; j++)
        {
         if(rates[i].high < rates[i - j].high) { isResPivotPattern = false; break; }
        }
      for(int j = 1; j <= InpPivotRightWindow; j++)
        {
         if(rates[i].high < rates[i + j].high) { isResPivotPattern = false; break; }
        }

      if(isResPivotPattern)
        {
         bool isBroken = false;
         bool hasMinPush = false;
         int breakIndex = -1;

         for(int k = i + 1; k < totalBars; k++)
           {
            if(rates[k].high >= rates[i].high)
              {
               isBroken = true;
               breakIndex = k;
               break;
              }

            if((rates[i].high - rates[k].low) >= InpMinPushPrice)
              {
               hasMinPush = true;
              }
           }

         if(hasMinPush)
           {
            if(!isBroken && resCount < InpMaxLevels)
              {
               bool isTooClose = false;
               for(int r = 0; r < resCount; r++)
                 {
                  if(MathAbs(rates[i].high - activeRes[r]) < InpZoneThreshold)
                    {
                     isTooClose = true;
                     break;
                    }
                 }

               if(!isTooClose)
                 {
                  string name = "XAU_SoftSR_Res_" + IntegerToString(resCount);
                  DrawRay(name, rates[i].time, rates[i].high, InpResColor);

                  resCount++;
                  ArrayResize(activeRes, resCount);
                  activeRes[resCount - 1] = rates[i].high;
                 }
              }
            else if(isBroken && breakIndex != -1)
              {
               string name = "XAU_SoftSR_Res_Broken_" + IntegerToString(brokenResCount++);
               DrawSegment(name, rates[i].time, rates[i].high, rates[breakIndex].time, rates[i].high, InpBrokenColor);
              }
           }
        }

      // 2. SUPPORT (SWING LOW PATTERN)
      bool isSupPivotPattern = true;

      for(int j = 1; j <= InpPivotLeftWindow; j++)
        {
         if(rates[i].low > rates[i - j].low) { isSupPivotPattern = false; break; }
        }
      for(int j = 1; j <= InpPivotRightWindow; j++)
        {
         if(rates[i].low > rates[i + j].low) { isSupPivotPattern = false; break; }
        }

      if(isSupPivotPattern)
        {
         bool isBroken = false;
         bool hasMinPush = false;
         int breakIndex = -1;

         for(int k = i + 1; k < totalBars; k++)
           {
            if(rates[k].low <= rates[i].low)
              {
               isBroken = true;
               breakIndex = k;
               break;
              }

            if((rates[k].high - rates[i].low) >= InpMinPushPrice)
              {
               hasMinPush = true;
              }
           }

         if(hasMinPush)
           {
            if(!isBroken && supCount < InpMaxLevels)
              {
               bool isTooClose = false;
               for(int s = 0; s < supCount; s++)
                 {
                  if(MathAbs(rates[i].low - activeSup[s]) < InpZoneThreshold)
                    {
                     isTooClose = true;
                     break;
                    }
                 }

               if(!isTooClose)
                 {
                  string name = "XAU_SoftSR_Sup_" + IntegerToString(supCount);
                  DrawRay(name, rates[i].time, rates[i].low, InpSupColor);

                  supCount++;
                  ArrayResize(activeSup, supCount);
                  activeSup[supCount - 1] = rates[i].low;
                 }
              }
            else if(isBroken && breakIndex != -1)
              {
               string name = "XAU_SoftSR_Sup_Broken_" + IntegerToString(brokenSupCount++);
               DrawSegment(name, rates[i].time, rates[i].low, rates[breakIndex].time, rates[i].low, InpBrokenColor);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Synchronize Pending Stop Orders with Active SNR Levels           |
//+------------------------------------------------------------------+
void SyncPendingOrders(const double &activeRes[], const double &activeSup[])
  {
   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(currentSpread >= InpMaxSpreadPoints)
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dynamicLot = CalculateLotSize(InpStopLossPoints);

   // Buy Stop at Active Resistance
   for(int i = 0; i < ArraySize(activeRes); i++)
     {
      double targetPrice = NormalizeDouble(activeRes[i], _Digits);
      if(targetPrice > ask)
        {
         if(!HasPendingOrderAtPrice(ORDER_TYPE_BUY_STOP, targetPrice))
           {
            double sl = NormalizeDouble(targetPrice - (InpStopLossPoints * _Point), _Digits);
            double tp = NormalizeDouble(targetPrice + (InpTakeProfitPoints * _Point), _Digits);
            trade.BuyStop(dynamicLot, targetPrice, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "SNR Resistance Breakout");
           }
        }
     }

   // Sell Stop at Active Support
   for(int i = 0; i < ArraySize(activeSup); i++)
     {
      double targetPrice = NormalizeDouble(activeSup[i], _Digits);
      if(targetPrice < bid)
        {
         if(!HasPendingOrderAtPrice(ORDER_TYPE_SELL_STOP, targetPrice))
           {
            double sl = NormalizeDouble(targetPrice + (InpStopLossPoints * _Point), _Digits);
            double tp = NormalizeDouble(targetPrice - (InpTakeProfitPoints * _Point), _Digits);
            trade.SellStop(dynamicLot, targetPrice, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "SNR Support Breakout");
           }
        }
     }

   CleanStaleOrders(activeRes, activeSup);
  }

//+------------------------------------------------------------------+
//| Check if a Pending Order already exists near a price level       |
//+------------------------------------------------------------------+
bool HasPendingOrderAtPrice(ENUM_ORDER_TYPE orderType, double price)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
           {
            if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) == orderType)
              {
               if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - price) < _Point)
                  return true;
              }
           }
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Cancel Pending Orders for invalidated/removed SNR levels         |
//+------------------------------------------------------------------+
void CleanStaleOrders(const double &activeRes[], const double &activeSup[])
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
           {
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);

            if(type == ORDER_TYPE_BUY_STOP)
              {
               bool isValid = false;
               for(int r = 0; r < ArraySize(activeRes); r++)
                 {
                  if(MathAbs(openPrice - activeRes[r]) < _Point) { isValid = true; break; }
                 }
               if(!isValid) trade.OrderDelete(ticket);
              }
            else if(type == ORDER_TYPE_SELL_STOP)
              {
               bool isValid = false;
               for(int s = 0; s < ArraySize(activeSup); s++)
                 {
                  if(MathAbs(openPrice - activeSup[s]) < _Point) { isValid = true; break; }
                 }
               if(!isValid) trade.OrderDelete(ticket);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Trailing Stop Engine - TRUE STEP + ENGINE 2 FALLBACK             |
//+------------------------------------------------------------------+
void ManageTrailingStops()
  {
   double startDist = InpTrailingStart * _Point;  
   double stepDist  = InpTrailingStep  * _Point;  

   if(startDist <= 0 || stepDist <= 0) return;

   // 1. Array Garbage Collection: Remove closed positions from memory
   for(int i = ArraySize(virtualStops) - 1; i >= 0; i--)
     {
      if(!PositionSelectByTicket(virtualStops[i].ticket))
         ArrayRemove(virtualStops, i, 1);
     }

   // 2. Loop all actively open positions for trailing/cutting
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;

      string sym   = PositionGetString(POSITION_SYMBOL);
      long   magic = PositionGetInteger(POSITION_MAGIC);
      long   type  = PositionGetInteger(POSITION_TYPE);
      double open  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);

      if(sym != _Symbol || magic != (long)InpMagicNumber) continue;

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(bid <= 0 || ask <= 0) continue;

      // 3. Find or register ticket in memory
      int vIdx = -1;
      for(int v = 0; v < ArraySize(virtualStops); v++)
        {
         if(virtualStops[v].ticket == ticket)
           {
            vIdx = v; break;
           }
        }
      
      if(vIdx == -1)
        {
         int newSize = ArraySize(virtualStops) + 1;
         ArrayResize(virtualStops, newSize);
         vIdx = newSize - 1;
         virtualStops[vIdx].ticket = ticket;
         virtualStops[vIdx].type = type;
         virtualStops[vIdx].virtualSL = 0.0;
         virtualStops[vIdx].engine1Failed = false;
        }

      // =====================================================================
      // STAGE A: ENGINE 2 FALLBACK (NANOSECOND CUT)
      // =====================================================================
      if(virtualStops[vIdx].virtualSL != 0.0)
        {
         if(type == POSITION_TYPE_BUY && bid <= virtualStops[vIdx].virtualSL)
           {
            PrintFormat("[ENGINE 2] BUY #%I64u MANUAL CLOSE at VirtualSL %.5f", ticket, virtualStops[vIdx].virtualSL);
            trade.PositionClose(ticket);
            continue; 
           }
         else if(type == POSITION_TYPE_SELL && ask >= virtualStops[vIdx].virtualSL)
           {
            PrintFormat("[ENGINE 2] SELL #%I64u MANUAL CLOSE at VirtualSL %.5f", ticket, virtualStops[vIdx].virtualSL);
            trade.PositionClose(ticket);
            continue; 
           }
        }

      // =====================================================================
      // STAGE B: TRUE STEP TRAILING CALCULATION
      // =====================================================================
      if(type == POSITION_TYPE_BUY)
        {
         double profit = bid - open;
         if(profit >= startDist)
           {
            int steps = (int)MathFloor((profit - startDist) / stepDist);
            double calculatedSL = open + (steps * stepDist);
            double newSL = NormalizeDouble(calculatedSL, _Digits);
            
            // Only act if this is a NEW step (avoiding spam)
            if(virtualStops[vIdx].virtualSL == 0.0 || newSL > virtualStops[vIdx].virtualSL + (_Point * 0.1))
              {
               virtualStops[vIdx].virtualSL = newSL; // Lock into Engine 2 memory

               if(!virtualStops[vIdx].engine1Failed)
                 {
                  PositionSelectByTicket(ticket);
                  if(trade.PositionModify(ticket, newSL, tp))
                    {
                     PrintFormat("[STEP TRAIL OK] BUY #%I64u Step %d: SL moved to %.5f", ticket, steps, newSL);
                    }
                  else
                    {
                     virtualStops[vIdx].engine1Failed = true;
                     PrintFormat("[ENGINE 1 FAIL] Broker rejected BUY SL %.5f. Engine 2 is active.", newSL);
                    }
                 }
              }
           }
        }
      else if(type == POSITION_TYPE_SELL)
        {
         double profit = open - ask;
         if(profit >= startDist)
           {
            int steps = (int)MathFloor((profit - startDist) / stepDist);
            double calculatedSL = open - (steps * stepDist);
            double newSL = NormalizeDouble(calculatedSL, _Digits);
            
            // Only act if this is a NEW step (avoiding spam)
            if(virtualStops[vIdx].virtualSL == 0.0 || newSL < virtualStops[vIdx].virtualSL - (_Point * 0.1))
              {
               virtualStops[vIdx].virtualSL = newSL; // Lock into Engine 2 memory

               if(!virtualStops[vIdx].engine1Failed)
                 {
                  PositionSelectByTicket(ticket);
                  if(trade.PositionModify(ticket, newSL, tp))
                    {
                     PrintFormat("[STEP TRAIL OK] SELL #%I64u Step %d: SL moved to %.5f", ticket, steps, newSL);
                    }
                  else
                    {
                     virtualStops[vIdx].engine1Failed = true;
                     PrintFormat("[ENGINE 1 FAIL] Broker rejected SELL SL %.5f. Engine 2 is active.", newSL);
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Visual Drawing Helpers                                           |
//+------------------------------------------------------------------+
void DrawRay(string name, datetime time, double price, color clr)
  {
   ObjectCreate(0, name, OBJ_TREND, 0, time, price, time + PeriodSeconds(), price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLineWidth);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

void DrawSegment(string name, datetime startTime, double price, datetime endTime, double endPrice, color clr)
  {
   ObjectCreate(0, name, OBJ_TREND, 0, startTime, price, endTime, endPrice);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }
