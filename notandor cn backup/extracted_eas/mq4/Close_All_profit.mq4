extern int Profit=1;
void start()
{
   int slippage=3;
   int ask, bid, open;
   double point;
   for (int i=OrdersTotal()-1; i>=0; i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
      if (OrderType()==OP_BUY)
      {
         point=MarketInfo(OrderSymbol(),MODE_POINT);
         if (point==0) break;
         bid=MathRound(MarketInfo(OrderSymbol(),MODE_BID)/point);
         open=MathRound(OrderOpenPrice()/point);
         if (bid-open<Profit) continue;
         OrderClose(OrderTicket(),OrderLots(),bid*point,slippage);
      }
      if (OrderType()==OP_SELL)
      {
         point=MarketInfo(OrderSymbol(),MODE_POINT);
         if (point==0) break;
         ask=MathRound(MarketInfo(OrderSymbol(),MODE_ASK)/point);
         open=MathRound(OrderOpenPrice()/point);
         if (open-ask<Profit) continue;
         OrderClose (OrderTicket(),OrderLots(),ask*point,slippage);
      }
   }
}
