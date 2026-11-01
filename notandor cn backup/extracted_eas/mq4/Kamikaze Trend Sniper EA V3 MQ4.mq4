//+------------------------------------------------------------------+
//|                    Kamikaze_Trend_Sniper_v3.mq4                 |
//|      Estrategia: EMA Cross + ADX + RSI + Filtro EMA200          |
//+------------------------------------------------------------------+
#property strict

input string L1 = "=== CAPITAL MANAGEMENT ===";
input double RiskPercent = 25.0;
input double MaxLot      = 10.0;

input string L2 = "=== TREND FILTER ===";
input bool   UseTrendFilter = true;
input int    TrendEMA       = 200;

input string L3 = "=== ENTRY SIGNALS ===";
input int    FastEMA     = 8;
input int    SlowEMA     = 21;
input int    ADXPeriod   = 14;
input int    MinADX      = 25;
input int    RSIPeriod   = 14;

input string L4 = "=== EXITS ===";
input int    TakeProfit  = 400;
input int    StopLoss    = 200;
input bool   UseBreakEven= true;
input int    BE_Trigger  = 100;
input int    BE_Offset   = 10;

input string L5 = "=== TIME FILTER ===";
input int    StartHour   = 9;
input int    EndHour     = 17;

input int    MagicNum    = 88888;

int PointFactor;

int OnInit()
{
   if(Digits==3 || Digits==5) PointFactor=10;
   else PointFactor=1;
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if((Ask-Bid) > 35*Point*PointFactor) return;

   if(UseBreakEven) MoveToBreakEven();
   if(!IsNewBar()) return;
   if(!IsTimeAllowed()) return;

   double maTrend = iMA(NULL, 0, TrendEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double closePrice = Close[1];

   double adx = iADX(NULL, 0, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 1);
   double maFast = iMA(NULL, 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double maSlow = iMA(NULL, 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double rsi = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, 1);

   bool IsUptrend = (closePrice > maTrend);
   bool IsDowntrend = (closePrice < maTrend);

   if(!UseTrendFilter){ IsUptrend = true; IsDowntrend = true; }

   bool BuySignal  = IsUptrend  && maFast > maSlow && adx > MinADX && rsi > 50 && rsi < 70;
   bool SellSignal = IsDowntrend && maFast < maSlow && adx > MinADX && rsi < 50 && rsi > 30;

   if(CountOrders() == 0)
   {
      if(BuySignal)  OpenOrder(OP_BUY);
      if(SellSignal) OpenOrder(OP_SELL);
   }
}

void MoveToBreakEven()
{
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNum)
         {
            double point = Point*PointFactor;

            if(OrderType()==OP_BUY)
            {
               if(Bid > OrderOpenPrice() + BE_Trigger*point)
               {
                  if(OrderStopLoss() < OrderOpenPrice() + BE_Offset*point)
                     OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice()+BE_Offset*point, OrderTakeProfit(), 0);
               }
            }

            if(OrderType()==OP_SELL)
            {
               if(Ask < OrderOpenPrice() - BE_Trigger*point)
               {
                  if(OrderStopLoss()==0 || OrderStopLoss() > OrderOpenPrice()-BE_Offset*point)
                     OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice()-BE_Offset*point, OrderTakeProfit(), 0);
               }
            }
         }
      }
   }
}

void OpenOrder(int type)
{
   double lot = GetAggressiveLot(StopLoss);
   if(lot <= 0) return;

   double point = Point*PointFactor;
   double sl, tp;

   if(type == OP_BUY)
   {
      sl = Ask - StopLoss*point;
      tp = Ask + TakeProfit*point;
      OrderSend(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "Buy", MagicNum, 0);
   }
   else
   {
      sl = Bid + StopLoss*point;
      tp = Bid - TakeProfit*point;
      OrderSend(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "Sell", MagicNum, 0);
   }
}

double GetAggressiveLot(int sl_pips)
{
   double equity = AccountEquity();
   double riskMoney = equity * (RiskPercent / 100.0);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   if(tickValue == 0) tickValue = 1;

   double riskPoints = sl_pips * PointFactor;
   double lot = riskMoney / (riskPoints * tickValue);

   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);

   lot = MathFloor(lot/step)*step;
   if(lot < minLot) lot = minLot;
   if(lot > MaxLot) lot = MaxLot;

   return lot;
}

int CountOrders()
{
   int c=0;
   for(int i=0;i<OrdersTotal();i++)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNum) 
         c++;
   return c;
}

bool IsNewBar()
{
   static datetime lastbar = 0;
   if(lastbar != Time[0]){ lastbar = Time[0]; return true; }
   return false;
}

bool IsTimeAllowed()
{
   int h = Hour();
   return (h >= StartHour && h < EndHour);
}
