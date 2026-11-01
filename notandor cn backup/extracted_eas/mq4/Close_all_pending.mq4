#include <WinUser32.mqh>
void start()
{
   string title="Скрипт";
   string msg="Удалить все отложенные ордера?    ";
   if (MessageBox(msg,title,MB_YESNO|MB_ICONQUESTION)!=IDYES) return;
   int slippage=3;
   for (int i=OrdersTotal()-1; i>=0; i--)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
      if (OrderType()==OP_BUYSTOP  ) OrderDelete(OrderTicket());
      if (OrderType()==OP_SELLSTOP ) OrderDelete(OrderTicket());
      if (OrderType()==OP_BUYLIMIT ) OrderDelete(OrderTicket());
      if (OrderType()==OP_SELLLIMIT) OrderDelete(OrderTicket());
   }
}