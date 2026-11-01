
//+------------------------------------------------------------------+
//|                     CuteDragon_ALGOX_M5.mq4 🐉                  |
//|  Supertrend (ATR) + Heikin Ashi RSI+EMA filters + Risk (0.30$)  |
//|  Features: ATR SL, TP1/TP2/TP3 (Fibo style), close if returns to TP1,
//|            daily close option, automatic lot sizing by $ risk   |
//+------------------------------------------------------------------+
#property strict

// ====== INPUTS ======
input int    ATR_Period            = 55;       // ATR period (for Supertrend & SL)
input double ATR_Multiplier        = 3.0;      // ATR multiplier for Supertrend bands (factor)
input int    RSI_Period            = 14;       // RSI period
input int    EMA_Period            = 21;       // EMA period (on Heikin Ashi close)
input double ATR_Risk              = 1.0;      // Stop distance in ATRs
input double TP1_Mult             = 1.0;       // TP1 = ATR * TP1_Mult
input double TP2_Mult             = 2.0;
input double TP3_Mult             = 3.0;
input double MaxLossUSD           = 0.30;     // Max loss per trade in USD
input bool   Allow_CarryForward   = false;    // if false, closes trades at end of day
input double Slippage             = 3;        // allowed slippage (points)
input bool   UseHeikenAshi        = true;     // use HA for EMA and RSI filtering
input int    MagicNumber          = 20231115; // EA magic number

// ====== GLOBALS ======
int    prevTrend = 0;       // -1 short, 1 long
bool   tp1_hit = false;     // shared flag (per symbol)
string gv_tp1_key;          // GlobalVariable key per symbol

// ====== UTIL FUNCTIONS ======

// Return Heikin Ashi close for a given shift on PERIOD_M5
double HA_Close(int shift) {
   double o = iOpen(Symbol(), PERIOD_M5, shift);
   double h = iHigh(Symbol(), PERIOD_M5, shift);
   double l = iLow(Symbol(), PERIOD_M5, shift);
   double c = iClose(Symbol(), PERIOD_M5, shift);
   return (o + h + l + c) / 4.0;
}

// Return Heikin Ashi open for a given shift (requires previous HA values)
double HA_Open(int shift) {
   // HA_open = (HA_open_prev + HA_close_prev) / 2
   double haClosePrev = HA_Close(shift+1);
   // To get haOpenPrev we approximate using real candle previous open/close
   double o1 = iOpen(Symbol(), PERIOD_M5, shift+1);
   double h1 = iHigh(Symbol(), PERIOD_M5, shift+1);
   double l1 = iLow(Symbol(), PERIOD_M5, shift+1);
   double c1 = iClose(Symbol(), PERIOD_M5, shift+1);
   double haClose1 = (o1 + h1 + l1 + c1) / 4.0;
   // approximate haOpenPrev as (realOpenPrev + realClosePrev)/2 if not available
   double haOpenPrev = (o1 + c1) / 2.0;
   return (haOpenPrev + haClose1) / 2.0;
}

// Get ATR on M5
double ATR_M5(int period, int shift) {
   return iATR(Symbol(), PERIOD_M5, period, shift);
}

// Compute pip/point USD value per 1 lot approx.
double PointValuePerLot() {
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE); // value of one tick for current lot?
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
   if(tickValue == 0 || tickSize == 0) {
      // fallback for symbols where broker provides point and tickvalue differently
      double p = MarketInfo(Symbol(), MODE_POINT);
      // approximate: for many brokers tickvalue is per 1 lot and ticksize equals point
      // if unavailable, return 0 to avoid division by zero later
      return 0.0;
   }
   return tickValue / tickSize; // USD per price unit per 1 lot (approx)
}

// Calculate lot based on MaxLossUSD and stop in points
double CalculateLotByRisk(double stopPoints) {
   double valuePerPoint = PointValuePerLot(); // USD per point for 1 lot
   if(valuePerPoint <= 0 || stopPoints <= 0) {
      return MarketInfo(Symbol(), MODE_MINLOT);
   }
   double lot = MaxLossUSD / (stopPoints * valuePerPoint);
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep <= 0) lotStep = 0.01;
   double steps = MathFloor(lot / lotStep);
   double adjLot = steps * lotStep;
   if(adjLot < minLot) adjLot = minLot;
   if(adjLot > maxLot) adjLot = maxLot;
   return NormalizeDouble(adjLot, 2);
}

// Simple SuperTrend determination using current and previous bands on M5
int SupertrendSignal(int atrPeriod, double atrMultiplier) {
   double atr0 = ATR_M5(atrPeriod, 0);
   double atr1 = ATR_M5(atrPeriod, 1);
   double close0 = iClose(Symbol(), PERIOD_M5, 0);
   double close1 = iClose(Symbol(), PERIOD_M5, 1);
   double hl2_0 = (iHigh(Symbol(), PERIOD_M5, 0) + iLow(Symbol(), PERIOD_M5, 0)) / 2.0;
   double hl2_1 = (iHigh(Symbol(), PERIOD_M5, 1) + iLow(Symbol(), PERIOD_M5, 1)) / 2.0;

   double upper0 = hl2_0 + atrMultiplier * atr0;
   double lower0 = hl2_0 - atrMultiplier * atr0;
   double upper1 = hl2_1 + atrMultiplier * atr1;
   double lower1 = hl2_1 - atrMultiplier * atr1;

   int trend = prevTrend;
   // Detect flip
   if(close1 <= upper1 && close0 > upper0) trend = 1;    // flipped to up
   else if(close1 >= lower1 && close0 < lower0) trend = -1; // flipped to down
   else if(trend == 0) trend = (close0 >= hl2_0 ? 1 : -1); // initial guess
   prevTrend = trend;
   return trend;
}

// End of M5 day detection (server time). Close at server daily rollover (hour 23->0)
bool IsEndOfDay() {
   datetime t = TimeCurrent();
   int hour = TimeHour(t);
   int minute = TimeMinute(t);
   // trigger close near 23:58-23:59 server time once per day
   if(hour == 23 && minute >= 58) return true;
   return false;
}

// Count open orders for symbol by magic (we only manage EA orders)
int CountEAOrders() {
   int cnt=0;
   for(int i=0;i<OrdersTotal();i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber) cnt++;
      }
   }
   return cnt;
}

// Find and return open order ticket managed by EA (first one)
int FindEAOrderTicket() {
   for(int i=0;i<OrdersTotal();i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber) return OrderTicket();
      }
   }
   return -1;
}

// ====== ONINIT: setup global variable key ======
int OnInit() {
   gv_tp1_key = "CuteDragon_TP1_" + Symbol();
   // ensure GV exists
   if(!GlobalVariableCheck(gv_tp1_key)) GlobalVariableSet(gv_tp1_key, 0);
   return INIT_SUCCEEDED;
}

// ====== ONTICK ======
void OnTick() {
   // Use M5 data for everything
   double haClose0 = UseHeikenAshi ? HA_Close(0) : iClose(Symbol(), PERIOD_M5, 0);
   double haClose1 = UseHeikenAshi ? HA_Close(1) : iClose(Symbol(), PERIOD_M5, 1);
   double ema = iMA(Symbol(), PERIOD_M5, EMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0); // EMA on price; using HA close would require custom MA; keep classic for stability
   double rsi = iRSI(Symbol(), PERIOD_M5, RSI_Period, PRICE_CLOSE, 0);

   int trend = SupertrendSignal(ATR_Period, ATR_Multiplier);

   // Signals: require trend flip and filters similar to ALGOX
   // We'll treat buySignal when trend==1 and haClose crosses above EMA and rsi >50
   bool buySignal = (trend == 1 && haClose0 > ema && rsi > 50 && haClose1 <= ema);
   bool sellSignal = (trend == -1 && haClose0 < ema && rsi < 50 && haClose1 >= ema);

   // Calculate ATR-based distances (price units)
   double atr = ATR_M5(ATR_Period, 0);
   double SL_distance_price = atr * ATR_Risk; // price difference
   double point = MarketInfo(Symbol(), MODE_POINT);
   double stopPoints = (SL_distance_price / point); // in points

   // Open trades only if EA has no active trades (single trade at a time)
   if(CountEAOrders()==0) {
      if(buySignal) {
         double entry = MarketInfo(Symbol(), MODE_ASK);
         double sl = entry - SL_distance_price;
         double tp1 = entry + atr * TP1_Mult;
         double tp2 = entry + atr * TP2_Mult;
         double tp3 = entry + atr * TP3_Mult;
         double lot = CalculateLotByRisk(stopPoints);
         int ticket = OrderSend(Symbol(), OP_BUY, lot, entry, (int)Slippage, sl, tp3, "CuteDragon_ALGOX_M5 BUY", 0, 0, clrGreen);
         if(ticket>0) {
            Print("Opened BUY Ticket:", ticket, " Lot=", DoubleToStr(lot,2), " SL=", DoubleToStr(sl,Digits), " TP3=", DoubleToStr(tp3,Digits));
            GlobalVariableSet(gv_tp1_key, 0);
         } else Print("OrderSend BUY failed: ", GetLastError());
      }
      if(sellSignal) {
         double entry = MarketInfo(Symbol(), MODE_BID);
         double sl = entry + SL_distance_price;
         double tp1 = entry - atr * TP1_Mult;
         double tp2 = entry - atr * TP2_Mult;
         double tp3 = entry - atr * TP3_Mult;
         double lot = CalculateLotByRisk(stopPoints);
         int ticket = OrderSend(Symbol(), OP_SELL, lot, entry, (int)Slippage, sl, tp3, "CuteDragon_ALGOX_M5 SELL", 0, 0, clrRed);
         if(ticket>0) {
            Print("Opened SELL Ticket:", ticket, " Lot=", DoubleToStr(lot,2), " SL=", DoubleToStr(sl,Digits), " TP3=", DoubleToStr(tp3,Digits));
            GlobalVariableSet(gv_tp1_key, 0);
         } else Print("OrderSend SELL failed: ", GetLastError());
      }
   }

   // Manage open orders
   for(int i=OrdersTotal()-1;i>=0;i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;

      int type = OrderType();
      double openPrice = OrderOpenPrice();
      double lots = OrderLots();
      double currentPrice = (type==OP_BUY) ? MarketInfo(Symbol(), MODE_BID) : MarketInfo(Symbol(), MODE_ASK);
      double atrNow = ATR_M5(ATR_Period, 0);
      double tp1_price = (type==OP_BUY) ? openPrice + atrNow * TP1_Mult : openPrice - atrNow * TP1_Mult;
      double tp2_price = (type==OP_BUY) ? openPrice + atrNow * TP2_Mult : openPrice - atrNow * TP2_Mult;
      double tp3_price = (type==OP_BUY) ? openPrice + atrNow * TP3_Mult : openPrice - atrNow * TP3_Mult;

      // Check TP1 hit flag using GlobalVariable so state persists across ticks
      double gv_tp1 = GlobalVariableGet(gv_tp1_key);

      // Mark TP1 hit
      if(type==OP_BUY && MarketInfo(Symbol(), MODE_BID) >= tp1_price) {
         if(gv_tp1==0) {
            GlobalVariableSet(gv_tp1_key,1);
            Print("TP1 reached for BUY (ticket ", OrderTicket(), ")");
         }
      }
      if(type==OP_SELL && MarketInfo(Symbol(), MODE_ASK) <= tp1_price) {
         if(gv_tp1==0) {
            GlobalVariableSet(gv_tp1_key,1);
            Print("TP1 reached for SELL (ticket ", OrderTicket(), ")");
         }
      }

      gv_tp1 = GlobalVariableGet(gv_tp1_key);

      // If TP1 was reached and price returns to TP1 -> close
      if(gv_tp1==1) {
         if(type==OP_BUY && MarketInfo(Symbol(), MODE_BID) <= tp1_price) {
            Print("Price returned to TP1 -> closing BUY ticket ", OrderTicket());
            bool closed = OrderClose(OrderTicket(), lots, MarketInfo(Symbol(), MODE_BID), (int)Slippage, clrOrange);
            if(closed) GlobalVariableSet(gv_tp1_key,0);
            continue;
         }
         if(type==OP_SELL && MarketInfo(Symbol(), MODE_ASK) >= tp1_price) {
            Print("Price returned to TP1 -> closing SELL ticket ", OrderTicket());
            bool closed = OrderClose(OrderTicket(), lots, MarketInfo(Symbol(), MODE_ASK), (int)Slippage, clrOrange);
            if(closed) GlobalVariableSet(gv_tp1_key,0);
            continue;
         }
      }

      // Enforce max loss in USD
      double profitUSD = OrderProfit() + OrderSwap() + OrderCommission();
      if(profitUSD <= -MaxLossUSD) {
         Print("Max loss exceeded -> closing ticket ", OrderTicket(), " profitUSD=", DoubleToStr(profitUSD,2));
         double closePrice = (type==OP_BUY) ? MarketInfo(Symbol(), MODE_BID) : MarketInfo(Symbol(), MODE_ASK);
         OrderClose(OrderTicket(), lots, closePrice, (int)Slippage, clrYellow);
         GlobalVariableSet(gv_tp1_key,0);
         continue;
      }

      // End of day closure
      if(!Allow_CarryForward && IsEndOfDay()) {
         Print("End of day -> closing ticket ", OrderTicket());
         double closePrice = (type==OP_BUY) ? MarketInfo(Symbol(), MODE_BID) : MarketInfo(Symbol(), MODE_ASK);
         OrderClose(OrderTicket(), lots, closePrice, (int)Slippage, clrPink);
         GlobalVariableSet(gv_tp1_key,0);
         continue;
      }

   } // orders loop

} // OnTick

// EOF
