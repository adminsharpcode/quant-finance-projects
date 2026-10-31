//+------------------------------------------------------------------+
//|                                                  TopBottomEA.mq5  |
//|   Нативный MQL5 (переписан с декомпилированного MQL4-конвертера). |
//|   Логика 1:1: волатильностный mean-reversion по ширине полос      |
//|   Боллинджера + Williams %R на M1. Одна позиция за раз, всегда с  |
//|   жёстким стоп-лоссом.                                            |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.31"
#property description "TopBottomEA — volatility-adaptive mean reversion (Bollinger width + Williams %R, M1)."
#property description "One position at a time, each with a hard stop loss."

#include <Trade/Trade.mqh>

//====================== ВХОДНЫЕ ПАРАМЕТРЫ ==========================
input double InpLots        = 0.1;           // Lots
input bool   InpCompound    = false;         // Compound interest switch
input int    InpRisk        = 40;            // Risk (equity*Risk/1000000)
input bool   InpParamSwitch = false;         // Parameter switching (per-symbol presets)
input int    InpVolatility  = 110;           // Volatility (Williams %R period)
input int    InpStopLoss    = 800;           // Stop loss (points)
input int    InpProfit      = 300;           // Profit target (points)
input double InpSpreadLimit = 50.0;          // Max spread to trade (points)
input int    InpMagic       = 888999;        // Magic number
input string InpComment      = "TopBottomEA"; // Order comment

//====================== КОНСТАНТЫ СТРАТЕГИИ ========================
#define BAND_MAX_DEF   1000     // верхний лимит ширины полос (пункты)
#define BAND_MIN_DEF   150      // нижний лимит ширины полос (пункты)
#define WPR_ENTRY      5        // вход: buy при WPR < -95, sell при WPR > -5
#define WPR_EXIT       5        // выход по развороту WPR
#define SLIPPAGE       30       // проскальзывание (пункты)
#define BB_PERIOD      20       // период Боллинджера
#define BB_DEV         2.0      // отклонение Боллинджера
#define SEND_RETRIES   10       // попытки переотправки ордера

//====================== РАНТАЙМ ====================================
int      g_wprPeriod;
int      g_slPoints;
int      g_tpPoints;
int      g_bandMax;
int      g_bandMin;

int      g_hBands = INVALID_HANDLE;
int      g_hWPR   = INVALID_HANDLE;

int      g_buyCount, g_sellCount;
double   g_buyOpen,  g_sellOpen;

datetime g_lastBuyBar  = 0;
datetime g_lastSellBar = 0;

CTrade   g_trade;

//+------------------------------------------------------------------+
//| Разрешение параметров по символу (аналог блока ParameterSwitching)|
//+------------------------------------------------------------------+
void ResolveParameters()
{
   string s = _Symbol;

   // значения по умолчанию (для XAUUSD и всех «неименованных» символов)
   g_wprPeriod = InpVolatility;
   g_slPoints  = InpStopLoss;
   g_tpPoints  = InpProfit;
   g_bandMax   = BAND_MAX_DEF;
   g_bandMin   = BAND_MIN_DEF;

   if(InpParamSwitch)
   {
      if(StringFind(s,"CHFSGD")<0 && StringFind(s,"GBPSGD")<0)
      {
         g_wprPeriod = InpVolatility;
         g_slPoints  = InpStopLoss;
         g_tpPoints  = InpProfit;
         g_bandMax   = BAND_MAX_DEF;
         g_bandMin   = BAND_MIN_DEF;
      }
      else
      {
         g_wprPeriod = 35;
         g_slPoints  = InpStopLoss;
         g_tpPoints  = InpProfit;
         g_bandMax   = BAND_MAX_DEF;
         g_bandMin   = 0;
      }
   }
   else
   {
      if(StringFind(s,"GBPCAD")>=0){ g_wprPeriod=110; g_slPoints=800; g_tpPoints=300; g_bandMax=BAND_MAX_DEF; g_bandMin=BAND_MIN_DEF; }
      if(StringFind(s,"EURSGD")>=0){ g_wprPeriod=140; g_slPoints=700; g_tpPoints=160; g_bandMax=BAND_MAX_DEF; g_bandMin=BAND_MIN_DEF; }
      if(StringFind(s,"GBPCHF")>=0){ g_wprPeriod=110; g_slPoints=600; g_tpPoints=200; g_bandMax=BAND_MAX_DEF; g_bandMin=BAND_MIN_DEF; }
      if(StringFind(s,"CHFSGD")>=0){ g_wprPeriod=60;  g_slPoints=700; g_tpPoints=160; g_bandMax=BAND_MAX_DEF; g_bandMin=0; }
      if(StringFind(s,"GBPSGD")>=0){ g_wprPeriod=35;  g_slPoints=700; g_tpPoints=160; g_bandMax=BAND_MAX_DEF; g_bandMin=0; }
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   ResolveParameters();

   // Индикаторы всегда на M1 (как в оригинале — timeframe жёстко = M1)
   g_hBands = iBands(_Symbol, PERIOD_M1, BB_PERIOD, 0, BB_DEV, PRICE_CLOSE);
   g_hWPR   = iWPR (_Symbol, PERIOD_M1, g_wprPeriod);

   if(g_hBands==INVALID_HANDLE || g_hWPR==INVALID_HANDLE)
   {
      Print("Indicator init failed: Bands=",g_hBands," WPR=",g_hWPR);
      return(INIT_FAILED);
   }

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(SLIPPAGE);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_hBands!=INVALID_HANDLE) IndicatorRelease(g_hBands);
   if(g_hWPR  !=INVALID_HANDLE) IndicatorRelease(g_hWPR);
}

//+------------------------------------------------------------------+
//| Чтение индикаторов (текущий формирующийся бар, shift 0)          |
//+------------------------------------------------------------------+
bool ReadBands(double &upper, double &lower)
{
   double up[1], lo[1];
   if(CopyBuffer(g_hBands, 1, 0, 1, up)!=1) return false; // UPPER_BAND
   if(CopyBuffer(g_hBands, 2, 0, 1, lo)!=1) return false; // LOWER_BAND
   upper = up[0];
   lower = lo[0];
   return true;
}

bool ReadWPR(double &wpr)
{
   double w[1];
   if(CopyBuffer(g_hWPR, 0, 0, 1, w)!=1) return false;
   wpr = w[0];
   return true;
}

//+------------------------------------------------------------------+
//| Время открытия предыдущего M1-бара (детектор нового бара)        |
//+------------------------------------------------------------------+
datetime PrevBarTimeM1()
{
   datetime t[1];
   if(CopyTime(_Symbol, PERIOD_M1, 1, 1, t)!=1) return 0;
   return t[0];
}

//+------------------------------------------------------------------+
//| Подсчёт своих позиций по символу+magic                          |
//+------------------------------------------------------------------+
void ScanPositions()
{
   g_buyCount=0; g_sellCount=0; g_buyOpen=0.0; g_sellOpen=0.0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=(long)InpMagic) continue;

      long   type = PositionGetInteger(POSITION_TYPE);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);

      if(type==POSITION_TYPE_BUY)  { g_buyCount++;  g_buyOpen  = open; }
      else                         { g_sellCount++; g_sellOpen = open; }
   }
}

//+------------------------------------------------------------------+
void CloseByType(const ENUM_POSITION_TYPE ptype)
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=(long)InpMagic) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=ptype) continue;
      g_trade.PositionClose(ticket, SLIPPAGE);
   }
}

//+------------------------------------------------------------------+
//| Расчёт и нормализация лота                                       |
//+------------------------------------------------------------------+
double GetLots()
{
   double lots = InpCompound
                 ? AccountInfoDouble(ACCOUNT_EQUITY) * InpRisk / 1000000.0
                 : InpLots;

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step<=0.0) step = 0.01;

   lots = MathFloor(lots/step)*step;
   if(lots<minLot) lots = minLot;
   if(lots>maxLot) lots = maxLot;
   return lots;
}

//+------------------------------------------------------------------+
bool MarginOK(const ENUM_ORDER_TYPE otype, const double lots, const double price)
{
   double margin = 0.0;
   if(!OrderCalcMargin(otype, _Symbol, lots, price, margin)) return false;
   return (AccountInfoDouble(ACCOUNT_MARGIN_FREE) - margin) > 0.0;
}

//+------------------------------------------------------------------+
//| Торговое окно (в тестере — серверное время, в реале — GMT)       |
//+------------------------------------------------------------------+
bool InTradeWindow()
{
   MqlDateTime tm;
   if(MQLInfoInteger(MQL_TESTER))
   {
      TimeCurrent(tm);
      int h = tm.hour;                       // окно: 20..23 и 0..3
      return ((h>=20 && h<=23) || (h>=0 && h<=3));
   }
   TimeGMT(tm);
   int h = tm.hour;                          // окно: 18..23 и 0..1
   return (h>=18 || h<=1);
}

//+------------------------------------------------------------------+
bool SendMarket(const ENUM_ORDER_TYPE otype, const double lots,
                const double sl, const double tp)
{
   for(int attempt=0; attempt<SEND_RETRIES; attempt++)
   {
      bool ok = (otype==ORDER_TYPE_BUY)
                ? g_trade.Buy (lots, _Symbol, 0.0, sl, tp, InpComment)
                : g_trade.Sell(lots, _Symbol, 0.0, sl, tp, InpComment);

      uint rc = g_trade.ResultRetcode();
      if(ok && (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_PLACED || rc==TRADE_RETCODE_DONE_PARTIAL))
         return true;

      Sleep(100);
   }
   return false;
}

//+------------------------------------------------------------------+
//| Основной обработчик                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // --- фильтр спреда ---
   long spread   = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   bool spreadOK = ((double)spread <= InpSpreadLimit);

   // --- индикаторы ---
   double upper, lower, wpr;
   if(!ReadBands(upper, lower)) return;
   if(!ReadWPR(wpr))            return;

   double pt        = _Point;
   double bandWidth = upper - lower;

   // --- состояние позиций (фиксируется один раз за тик, как в оригинале) ---
   ScanPositions();

   double   lots    = GetLots();
   datetime prevBar = PrevBarTimeM1();
   double   ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double   bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //=================== ВХОДЫ (только в окне + внутри полосы) =======
   if(InTradeWindow() && bandWidth < g_bandMax*pt && bandWidth > g_bandMin*pt)
   {
      bool noPos = (g_buyCount + g_sellCount < 1);

      // BUY — глубокая перепроданность WPR
      if(noPos && spreadOK && wpr < (WPR_ENTRY - 100) && prevBar != g_lastBuyBar)
      {
         g_lastBuyBar = prevBar;
         double sl = NormalizeDouble(ask - g_slPoints*pt, _Digits);
         if(MarginOK(ORDER_TYPE_BUY, lots, ask))
            SendMarket(ORDER_TYPE_BUY, lots, sl, 0.0);
      }

      // SELL — глубокая перекупленность WPR
      if(noPos && spreadOK && wpr > -WPR_ENTRY && prevBar != g_lastSellBar)
      {
         g_lastSellBar = prevBar;
         double sl = NormalizeDouble(bid + g_slPoints*pt, _Digits);
         if(MarginOK(ORDER_TYPE_SELL, lots, bid))
            SendMarket(ORDER_TYPE_SELL, lots, sl, 0.0);
      }
   }

   //=================== ВЫХОДЫ (каждый тик, с фильтром спреда) ======
   // разворот WPR
   if(g_buyCount  > 0 && spreadOK && wpr > -WPR_EXIT)          CloseByType(POSITION_TYPE_BUY);
   if(g_sellCount > 0 && spreadOK && wpr < (WPR_EXIT - 100))   CloseByType(POSITION_TYPE_SELL);

   // достижение цели по профиту
   if(g_buyCount  > 0 && spreadOK && (bid - g_buyOpen)  > g_tpPoints*pt) CloseByType(POSITION_TYPE_BUY);
   if(g_sellCount > 0 && spreadOK && (g_sellOpen - ask) > g_tpPoints*pt) CloseByType(POSITION_TYPE_SELL);
}
//+------------------------------------------------------------------+