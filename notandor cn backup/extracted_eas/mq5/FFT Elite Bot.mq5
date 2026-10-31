//+------------------------------------------------------------------+
//|                                                      Snipe FX.mq5
//| Exact rules: Buy/Sell Stop 2 pips away, 5s expire, trail 1 pip   |
//+------------------------------------------------------------------+
#property copyright "Free Forex Tools"
#property link      "https://t.me/free_fx_pro"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

CTrade trade;  // Use CTrade for easier operations

input double LotSize = 0.01;  // Lot size

ulong buy_stop_ticket  = 0;
ulong sell_stop_ticket = 0;
datetime last_place_time = 0;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Clean up expired pendings (rule 4)
   CheckAndDeleteExpiredPendings();

   // If no open position AND no pending orders left → place new ones (rule 5 + 1)
   if (PositionsTotal() == 0 && buy_stop_ticket == 0 && sell_stop_ticket == 0)
   {
      PlaceNewOrders();
   }

   // If we have an open position (rule 2 & 3)
   if (PositionsTotal() == 1)
   {
      // Delete opposite pending if still there (rule 2)
      DeleteOppositePending();

      // Trail SL if in profit >= 1 pip (rule 3)
      TrailSLBy1Pip();
   }
}

//+------------------------------------------------------------------+
//| Place new Buy Stop + Sell Stop (rule 1)                          |
//+------------------------------------------------------------------+
void PlaceNewOrders()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double pip_value = 0.10;           // 1 pip = 0.10 price
   double distance   = 2.0 * pip_value;   // 2 pips = 0.20
   double sl_tp_dist = 20.0 * pip_value;  // 20 pips = 2.00

   double buy_price  = NormalizeDouble(ask + distance, _Digits);
   double sell_price = NormalizeDouble(bid - distance, _Digits);

   double buy_sl  = NormalizeDouble(buy_price  - sl_tp_dist, _Digits);
   double buy_tp  = NormalizeDouble(buy_price  + sl_tp_dist, _Digits);
   double sell_sl = NormalizeDouble(sell_price + sl_tp_dist, _Digits);
   double sell_tp = NormalizeDouble(sell_price - sl_tp_dist, _Digits);

   // Use GTC (no broker expiration) - EA deletes after 5s
   datetime expire = 0;  // ignored for GTC

   // Buy Stop
   if (trade.BuyStop(LotSize, buy_price, _Symbol, buy_sl, buy_tp, ORDER_TIME_GTC, expire, "Buy Stop"))
   {
      buy_stop_ticket = trade.ResultOrder();
      last_place_time = TimeCurrent();
      PrintFormat("Buy Stop PLACED at %.3f | SL: %.3f | TP: %.3f", buy_price, buy_sl, buy_tp);
   }
   else
   {
      Print("BuyStop FAILED: ", trade.ResultRetcodeDescription(), " (code ", trade.ResultRetcode(), ")");
   }

   // Sell Stop
   if (trade.SellStop(LotSize, sell_price, _Symbol, sell_sl, sell_tp, ORDER_TIME_GTC, expire, "Sell Stop"))
   {
      sell_stop_ticket = trade.ResultOrder();
      last_place_time = TimeCurrent();
      PrintFormat("Sell Stop PLACED at %.3f | SL: %.3f | TP: %.3f", sell_price, sell_sl, sell_tp);
   }
   else
   {
      Print("SellStop FAILED: ", trade.ResultRetcodeDescription(), " (code ", trade.ResultRetcode(), ")");
   }
}

//+------------------------------------------------------------------+
//| Delete both pendings if expired (rule 4)                         |
//+------------------------------------------------------------------+
void CheckAndDeleteExpiredPendings()
{
   if ((buy_stop_ticket > 0 || sell_stop_ticket > 0) && TimeCurrent() - last_place_time >= 5)
   {
      if (buy_stop_ticket > 0)  trade.OrderDelete(buy_stop_ticket);
      if (sell_stop_ticket > 0) trade.OrderDelete(sell_stop_ticket);
      buy_stop_ticket = sell_stop_ticket = 0;
   }
}

//+------------------------------------------------------------------+
//| Delete opposite pending once position opens (rule 2)             |
//+------------------------------------------------------------------+
void DeleteOppositePending()
{
   if (buy_stop_ticket > 0 || sell_stop_ticket > 0)
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (ticket == 0) continue;
         if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

         ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         if (pos_type == POSITION_TYPE_BUY && sell_stop_ticket > 0)
         {
            trade.OrderDelete(sell_stop_ticket);
            sell_stop_ticket = 0;
         }
         else if (pos_type == POSITION_TYPE_SELL && buy_stop_ticket > 0)
         {
            trade.OrderDelete(buy_stop_ticket);
            buy_stop_ticket = 0;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trail SL by 1 pip as soon as +1 pip profit (rule 3)              |
//+------------------------------------------------------------------+
void TrailSLBy1Pip()
{
   double pip_value = 0.10;  // Your 1 pip = 0.10

   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_sl = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      double new_sl = 0;

      if (pos_type == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double profit = bid - open_price;

         if (profit >= pip_value)  // >= 1 pip in profit
         {
            new_sl = NormalizeDouble(bid - pip_value, _Digits);  // trail 1 pip behind
            if (new_sl > current_sl + _Point)  // only move if improvement
            {
               trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
            }
         }
      }
      else if (pos_type == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double profit = open_price - ask;

         if (profit >= pip_value)
         {
            new_sl = NormalizeDouble(ask + pip_value, _Digits);
            if (new_sl < current_sl - _Point || current_sl == 0)
            {
               trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
            }
         }
      }
   }
}