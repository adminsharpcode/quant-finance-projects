/*
   G e n e r a t e d  by ex4-to-mq4 decompiler FREEWARE 4.0.509.5
   Website:  h TTp:/ / w Ww.Met a quot E s .n e T
   E-mail : S UP por t @me t a QU o te S.N e T
*/
#property copyright "arimint"
#property link      "arimint"

extern int MagicNumber = 0;
extern bool SignalMail = FALSE;
extern bool EachTickMode = TRUE;
extern double Lots = 0.01;
extern int Slippage = 5;
extern bool UseStopLoss = TRUE;
extern int StopLoss = 500;
extern bool UseTakeProfit = FALSE;
extern int TakeProfit = 100;
extern bool UseTrailingStop = FALSE;
extern int TrailingStop = 0;
int G_bars_124;
int Gi_128;
bool Gi_132 = FALSE;

// E37F0136AA3FFAF149B351F6A4C948E9
int init() {
   G_bars_124 = Bars;
   if (EachTickMode) Gi_128 = 0;
   else Gi_128 = 1;
   return (0);
}

// 52D46093050F38C27267BCE42543EF60
int deinit() {
   return (0);
}

// EA2B2676C28C0DB26D39331A336C6B92
int start() {
   int ticket_8;
   double price_12;
   double price_20;
   int Li_0 = 0;
   if (EachTickMode && Bars != G_bars_124) Gi_132 = FALSE;
   int order_total_4 = OrdersTotal();
   Li_0 = 0;
   double ima_28 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_36 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_44 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_52 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_60 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_68 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_76 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_84 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_92 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_100 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_108 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_116 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_124 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_132 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 1);
   double ima_140 = iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, Gi_128 + 0);
   double ima_148 = iMA(NULL, 0, 24, 0, MODE_SMA, PRICE_CLOSE, Gi_128 + 0);
   bool Li_156 = FALSE;
   for (int pos_160 = 0; pos_160 < order_total_4; pos_160++) {
      OrderSelect(pos_160, SELECT_BY_POS, MODE_TRADES);
      if (OrderType() <= OP_SELL && OrderSymbol() == Symbol()) {
         Li_156 = TRUE;
         if (OrderType() == OP_BUY) {
            if (ima_92 > ima_100 && ima_108 < ima_116) Li_0 = 3;
            if (Li_0 == 3 && (EachTickMode && (!Gi_132)) || ((!EachTickMode) && Bars != G_bars_124)) {
               OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               if (!EachTickMode) G_bars_124 = Bars;
               Li_156 = FALSE;
               continue;
            }
            if (!(UseTrailingStop && TrailingStop > 0)) continue;
            if (Bid - OrderOpenPrice() <= Point * TrailingStop) continue;
            if (OrderStopLoss() >= Bid - Point * TrailingStop) continue;
            OrderModify(OrderTicket(), OrderOpenPrice(), Bid - Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
            if (!(!EachTickMode)) continue;
            G_bars_124 = Bars;
            continue;
         }
         if (ima_124 < ima_132 && ima_140 > ima_148) Li_0 = 4;
         if (Li_0 == 4 && (EachTickMode && (!Gi_132)) || ((!EachTickMode) && Bars != G_bars_124)) {
            OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
            if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
            if (!EachTickMode) G_bars_124 = Bars;
            Li_156 = FALSE;
            continue;
         }
         if (UseTrailingStop && TrailingStop > 0) {
            if (OrderOpenPrice() - Ask > Point * TrailingStop) {
               if (OrderStopLoss() > Ask + Point * TrailingStop || OrderStopLoss() == 0.0) {
                  OrderModify(OrderTicket(), OrderOpenPrice(), Ask + Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
                  if (!EachTickMode) G_bars_124 = Bars;
               }
            }
         }
      }
   }
   if (ima_28 < ima_36 && ima_44 > ima_52) Li_0 = 1;
   if (ima_60 > ima_68 && ima_76 < ima_84) Li_0 = 2;
   if (Li_0 == 1 && (EachTickMode && (!Gi_132)) || ((!EachTickMode) && Bars != G_bars_124)) {
      if (!Li_156) {
         if (AccountFreeMargin() < 1000.0 * Lots) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return (0);
         }
         if (UseStopLoss) price_12 = Ask - StopLoss * Point;
         else price_12 = 0.0;
         if (UseTakeProfit) price_20 = Ask + TakeProfit * Point;
         else price_20 = 0.0;
         ticket_8 = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, price_12, price_20, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue);
         if (ticket_8 > 0) {
            if (OrderSelect(ticket_8, SELECT_BY_TICKET, MODE_TRADES)) {
               Print("BUY order opened : ", OrderOpenPrice());
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
            } else Print("Error opening BUY order : ", GetLastError());
         }
         if (EachTickMode) Gi_132 = TRUE;
         if (!(!EachTickMode)) return (0);
         G_bars_124 = Bars;
         return (0);
      }
   }
   if (Li_0 == 2 && (EachTickMode && (!Gi_132)) || ((!EachTickMode) && Bars != G_bars_124)) {
      if (!Li_156) {
         if (AccountFreeMargin() < 1000.0 * Lots) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return (0);
         }
         if (UseStopLoss) price_12 = Bid + StopLoss * Point;
         else price_12 = 0.0;
         if (UseTakeProfit) price_20 = Bid - TakeProfit * Point;
         else price_20 = 0.0;
         ticket_8 = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, price_12, price_20, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if (ticket_8 > 0) {
            if (OrderSelect(ticket_8, SELECT_BY_TICKET, MODE_TRADES)) {
               Print("SELL order opened : ", OrderOpenPrice());
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
            } else Print("Error opening SELL order : ", GetLastError());
         }
         if (EachTickMode) Gi_132 = TRUE;
         if (!(!EachTickMode)) return (0);
         G_bars_124 = Bars;
         return (0);
      }
   }
   if (!EachTickMode) G_bars_124 = Bars;
   return (0);
}
