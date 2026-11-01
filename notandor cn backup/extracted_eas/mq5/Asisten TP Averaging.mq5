//+------------------------------------------------------------------+
//|                                      Asisten TP-SL Averaging.mq5 |
//|                                       Copyright 2021, PrdnNvnRnt |
//|                                                  t.me/PrdnNvnRnt |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, PrdnNvnRnt"
#property link      "t.me/PrdnNvnRnt"
#property version   "1.00"

MqlTradeRequest   m_request;              // request data
MqlTradeResult    m_result;               // result data
MqlTradeCheckResult m_check_result;       // result check data

input double      TakeProfit        = 100;//Take Profit in Point
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
   EventSetTimer(5);

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();

}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   double tPriceBuy = 0,
          tPriceSell = 0,
          tLotsBuy = 0,
          tLotsSell = 0,
          BEPBuy = 0,
          BEPSell = 0;

   positionInformation(tPriceBuy, tPriceSell, tLotsBuy, tLotsSell, BEPBuy, BEPSell);

   if(BEPBuy != 0) {
      modifyPosition(POSITION_TYPE_BUY, BEPBuy + TakeProfit * Point());
   }

   if(BEPSell != 0) {
      modifyPosition(POSITION_TYPE_SELL, BEPSell - TakeProfit * Point());
   }

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              clearStructures() {
   ZeroMemory(m_request);
   ZeroMemory(m_result);
   ZeroMemory(m_check_result);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              modifyPosition(ENUM_POSITION_TYPE Type, double TP) {
   int digit = Digits();

   for(int i = 0; i < PositionsTotal(); i++) {
      if(!PositionGetTicket(i)) continue;
      if(PositionGetSymbol(i) == Symbol())
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == Type)
            if(NormalizeDouble(PositionGetDouble(POSITION_TP), digit) != NormalizeDouble(TP, digit) || NormalizeDouble(PositionGetDouble(POSITION_TP), digit) == 0) {
               clearStructures();
               m_request.action  = TRADE_ACTION_SLTP;
               m_request.position = PositionGetInteger(POSITION_TICKET);
               m_request.symbol  = PositionGetString(POSITION_SYMBOL);
               m_request.tp      = TP;
               if(!OrderSend(m_request, m_result))
                  Print("Modify Error");
            }

   }
}

//+------------------------------------------------------------------+
void              positionInformation(
   double &tPriceBuy,
   double &tPriceSell,
   double &tLotsBuy,
   double &tLotsSell,
   double &BEPBuy,
   double &BEPSell) {

   int digit = Digits();

   for(int i = 0; i < PositionsTotal(); i++) {
      if(!PositionGetTicket(i)) continue;
      if(PositionGetSymbol(i) == Symbol()) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            tPriceBuy += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
            tLotsBuy += PositionGetDouble(POSITION_VOLUME);
         }
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            tPriceSell += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
            tLotsSell += PositionGetDouble(POSITION_VOLUME);
         }
      }
   }

   if(tLotsBuy > 0 && tPriceBuy > 0) {
      BEPBuy = NormalizeDouble(tPriceBuy / tLotsBuy, digit);
   }
   if(tLotsSell > 0 && tPriceSell > 0) {
      BEPSell = NormalizeDouble(tPriceSell / tLotsSell, digit);
   }
}
//+------------------------------------------------------------------+
