#include <Mean reversion/XAUUSD_H1 ONNX include 0.mqh>
#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>

CTrade mytrade;
CPositionInfo myposition;

input group "Signals settings";
input bool Allow_Buy = true;           //@LifeInDreamsWorld
input bool Allow_Sell = true;          //Allow SELL signals
double main_threshold = 0.5;           //SIGNALS SENSITIVITY for buy and sell
double meta_threshold = 0.5;           //FILTER SENSITIVITY for positions timing
input bool close_orders_by_signals = true; // Close orders by signals (Only SL/TP if false)
input group "Positions settings"
double   MaximumRisk=0.00001;          //Progressive lot coefficient
sinput double   ManualLot=0.01;        //Fixed lot
sinput ulong    OrderMagic = 6374889475647; //Orders magic
input group "Money management settings"
input int max_orders = 3;              //Max positions number (Enable grid mode if >1)
input int orders_time_delay = 3;       //Time delay between positions (For grid mode)
input double orders_distance = 250;    //Distance between positions (For grid mode)
input int max_spread = 250;            //Max spread
input int stoploss = 5000;             //Stop loss
input int takeprofit = 5000;           //Take profit
input string bot_comment = "Alpha trader"; //Bot comment

static datetime last_time = 0;
#define Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)

#define model ExtModel_XAUUSD_H1_0
#define model_m ExtModel2_XAUUSD_H1_0
#define periods PeriodsXAUUSD_H1_0
#define periods_m Periods_mXAUUSD_H1_0
#define fill_arrays fill_araysXAUUSD_H1_0
#define fill_arrays_m fill_arays_mXAUUSD_H1_0

const ulong  ExtInputShape [] = {1, ArraySize(periods)};
const ulong  ExtInputShape2 [] = {1, ArraySize(periods_m)};
long     ExtHandle = INVALID_HANDLE, ExtHandle2 = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   mytrade.SetExpertMagicNumber(OrderMagic);

   ExtHandle = OnnxCreateFromBuffer(model, ONNX_USE_CPU_ONLY);
   ExtHandle2 = OnnxCreateFromBuffer(model_m, ONNX_USE_CPU_ONLY);

   if(ExtHandle == INVALID_HANDLE || ExtHandle2 == INVALID_HANDLE)
     {
      Print("OnnxCreateFromBuffer error ", GetLastError());
      return(INIT_FAILED);
     }

   if(!OnnxSetInputShape(ExtHandle, 0, ExtInputShape))
     {
      Print("OnnxSetInputShape 1 failed, error ", GetLastError());
      OnnxRelease(ExtHandle);
      return(-1);
     }

   if(!OnnxSetInputShape(ExtHandle2, 0, ExtInputShape2))
     {
      Print("OnnxSetInputShape 2 failed, error ", GetLastError());
      OnnxRelease(ExtHandle2);
      return(-1);
     }

   const ulong output_shape[] = {1};
   if(!OnnxSetOutputShape(ExtHandle, 0, output_shape))
     {
      Print("OnnxSetOutputShape 1 error ", GetLastError());
      return(INIT_FAILED);
     }
   if(!OnnxSetOutputShape(ExtHandle2, 0, output_shape))
     {
      Print("OnnxSetOutputShape 2 error ", GetLastError());
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   OnnxRelease(ExtHandle);
   OnnxRelease(ExtHandle2);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
   if(!isNewBar())
      return;
   
   double features[], features_m[];
   fill_arrays(features);
   fill_arrays_m(features_m);

   double f[ArraySize(periods)], f_m[ArraySize(periods_m)];

   for(int i = 0; i < ArraySize(periods); i++)
     {
      f[i] = features[i];
     }

   for(int i = 0; i < ArraySize(periods_m); i++)
     {
      f_m[i] = features_m[i];
     }

   static vector out(1), out_meta(1);

   struct output
     {
      long           label[];
      float          proba[];
     };

   output out2[], out2_meta[];
   
   OnnxRun(ExtHandle, ONNX_USE_CPU_ONLY, f, out, out2);
   OnnxRun(ExtHandle2, ONNX_USE_CPU_ONLY, f_m, out_meta, out2_meta);

   double sig = out2[0].proba[1];
   double meta_sig = out2_meta[0].proba[1];

// CLOSE ORDERS BY SIGNALS
   if(close_orders_by_signals && (Ask-Bid < max_spread*_Point))
      if(countOrders(OrderMagic) > 0)
         for(int b = PositionsTotal() - 1; b >= 0; b--)
            if(PositionGetSymbol(b)==_Symbol)
              {
               // CLOSE BUY POSITIONS
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY &&
                  PositionGetInteger(POSITION_MAGIC) == OrderMagic &&
                  sig > main_threshold)
                  if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) <
                     MathAbs(Bid - PositionGetDouble(POSITION_PRICE_OPEN)))
                    {
                     int res = -1;
                     do
                       {
                        res = mytrade.PositionClose(_Symbol);
                        Sleep(50);
                       }
                     while(res == -1);
                    }
               // CLOSE SELL POSITIONS
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL &&
                  PositionGetInteger(POSITION_MAGIC) == OrderMagic &&
                  sig < 1-main_threshold)
                  if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) <
                     MathAbs(Bid - PositionGetDouble(POSITION_PRICE_OPEN)))
                    {
                     int res = -1;
                     do
                       {
                        res = mytrade.PositionClose(_Symbol);
                        Sleep(50);
                       }
                     while(res == -1);
                    }
              }

// OPEN POSITIONS BY SIGNALS
   if((Ask-Bid < max_spread*_Point) && meta_sig > meta_threshold &&
      AllowTrade(OrderMagic))
      if(countOrders(OrderMagic) < max_orders &&
         CheckMoneyForTrade(_Symbol, LotsOptimized(), ORDER_TYPE_BUY))
        {
         double l = LotsOptimized();
         if(sig < 1-main_threshold && Allow_Buy && (getLastOpenedPrice(OrderMagic,POSITION_TYPE_BUY) == 0.0 ||
         Ask <= getLastOpenedPrice(OrderMagic,POSITION_TYPE_BUY) - orders_distance*Point()) )
           {
            int res = -1;
            do
              {
               double stop = Bid - stoploss * _Point;
               double take = Ask + takeprofit * _Point;
               res = mytrade.PositionOpen(_Symbol, ORDER_TYPE_BUY, l, Ask, stop, take, bot_comment);
               Sleep(50);
              }
            while(res == -1);
           }
         else
           {
 
            if(sig > main_threshold && Allow_Sell && (getLastOpenedPrice(OrderMagic,POSITION_TYPE_SELL) == 0.0 ||
            Ask >= getLastOpenedPrice(OrderMagic,POSITION_TYPE_SELL) + orders_distance*Point()) )
              {
               int res = -1;
               do
                 {
                  double stop = Ask + stoploss * _Point;
                  double take = Bid - takeprofit * _Point;
                  res = mytrade.PositionOpen(_Symbol, ORDER_TYPE_SELL, l, Bid, stop, take, bot_comment);
                  Sleep(50);
                 }
               while(res == -1);
              }
           }
        }

//---

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int countOrders(ulong magic) // Наличие текущих позиций в рынке
  {
   int count=0;
   for(int i= PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetSymbol(i)==_Symbol)
        {
         if(PositionGetInteger(POSITION_MAGIC)==magic)
           {
            count++;
           }
        }
     }
   return(count);
  }
 
double getLastOpenedPrice(ulong magic, ENUM_POSITION_TYPE type) // Цена последней открытой позиции по типу
  {
   datetime lastTime = 0;
   double lastPrice = 0.0;
   
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         if(PositionGetInteger(POSITION_MAGIC) == magic && 
            PositionGetInteger(POSITION_TYPE) == type)
           {
            datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
            if(openTime > lastTime)
              {
               lastTime = openTime;
               lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
              }
           }
        }
     }
   
   return(lastPrice);
  }
 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AllowTrade(ulong magic)
  {
   if(countOrders(OrderMagic)==0)
      return true;
   datetime last_pos = 0;
   if(countOrders(OrderMagic)!=0)
     {
      for(int b = PositionsTotal() - 1; b >= 0; b--)
         if(PositionGetSymbol(b)==_Symbol)
            if(PositionGetInteger(POSITION_MAGIC)==magic)
               if(PositionGetInteger(POSITION_TIME) > last_pos)
                  last_pos = datetime(PositionGetInteger(POSITION_TIME));

      datetime time[];
      CopyTime(_Symbol,PERIOD_H1,0, 1, time);
      if(time[0] > last_pos + 3600 * orders_time_delay)
         return true;
     };

   return false;
  }
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot;

   if(MQLInfoInteger(MQL_OPTIMIZATION)==true)
     {
      lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
      return lot;
     }
   CAccountInfo myaccount;
   SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   lot=NormalizeDouble(myaccount.FreeMargin()*MaximumRisk/1000.0,2);
   if(ManualLot!=0.0)
      lot=ManualLot;

   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   int ratio=(int)MathRound(lot/volume_step);
   if(MathAbs(ratio*volume_step-lot)>0.0000001)
      lot=ratio*volume_step;

   if(lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
      lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
      lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   return(lot);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool isNewBar()
//  {
//   datetime lastbar_time = datetime(SeriesInfoInteger(_Symbol, PERIOD_H1, SERIES_LASTBAR_DATE));
//   if(last_time == 0)
//     {
//      last_time = lastbar_time;
//      return(false);
//     }
//   if(last_time != lastbar_time)
//     {
//      last_time = lastbar_time;
//      return(true);
//     }
//   return(false);
//  }
bool isNewBar()
  {
   // 1. Проверяем, наступил ли новый час
   datetime lastbar_time = (datetime)SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
   
   if(last_time == 0)
     {
      last_time = lastbar_time;
      return(false);
     }
   
   if(last_time == lastbar_time) 
      return(false); // Тот же самый бар, выходим

   // 2. Если час новый, проверяем: а открыт ли рынок?
   datetime session_start, session_end;
   datetime time_curr = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(time_curr, dt);

   // Проверяем торговую сессию для текущего дня недели
   if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, 0, session_start, session_end))
     {
      return(false); // Сессия не найдена (выходной)
     }

   // session_start и session_end возвращают время от 00:00 текущего дня в секундах.
   // Рассчитываем реальное время начала и конца
   datetime day_start = time_curr - (time_curr % 86400); 
   datetime real_start = day_start + session_start;
   datetime real_end   = day_start + session_end;

   // Если текущее время вне рамок сессии — возвращаем false
   if(time_curr < real_start || time_curr >= real_end)
     {
      return(false);
     }

   // Если всё ок: обновляем время последнего бара и разрешаем работу
   last_time = lastbar_time;
   return(true);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb, double lots, ENUM_ORDER_TYPE type)
  {
   MqlTick mqltick;
   SymbolInfoTick(symb, mqltick);
   double price = mqltick.ask;
   if(type == ORDER_TYPE_SELL)
      price = mqltick.bid;
   double margin, free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(!OrderCalcMargin(type, symb, lots, price, margin))
     {
      Print("Error in ", __FUNCTION__, " code=", GetLastError());
      return(false);
     }
   if(margin > free_margin)
     {
      Print("Not enough money for ", EnumToString(type), " ", lots, " ", symb, " Error code=", GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+

int getLastClosedPositionStatus(ulong magic)
  {
   // Загружаем всю доступную историю (или за большой период)
   HistorySelect(0, LONG_MAX);
   
   datetime lastTime = 0;
   double profit = 0.0;
   ENUM_DEAL_TYPE dealType = DEAL_TYPE_BUY;
   bool found = false;
   
   for(int i = HistoryDealsTotal()-1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(ticket, DEAL_MAGIC) == magic)
        {
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         
         // Проверяем только сделки закрытия позиций
         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
           {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            
            if(dealTime > lastTime)
              {
               lastTime = dealTime;
               profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
               found = true;
              }
           }
        }
     }
   
   if(!found)
      return(-1); // Нет закрытых позиций
   
   if(profit < 0) // Убыточная позиция
     {
      // Если сделка закрытия была SELL, значит закрывали BUY позицию
      if(dealType == DEAL_TYPE_SELL)
         return(0); // Убыточная позиция на покупку
      else
         return(1); // Убыточная позиция на продажу
     }
   else
     {
      return(2); // Прибыльная позиция
     }
  }