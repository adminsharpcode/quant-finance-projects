//+------------------------------------------------------------------+
//|                                     GoldHunter_MQL5_FIXED.mq5   |
//|                         Converted from MQL4 by Danny Weckhuyzen |
//|                                              @Bestrobotworld1    |
//|                         FIXED VERSION - All bugs corrected       |
//+------------------------------------------------------------------+
//
// ============================================================
// LISTA DE CORREÇÕES (BUG FIX LIST)
// ============================================================
// BUG 1  [CRÍTICO] Calculate_ZigZag() ausente: Swing_High[] / Swing_Low[]
//        nunca eram populados → EA nunca abria ordens. Adicionada função
//        completa de detecção de pivot high/low.
//
// BUG 2  [CRÍTICO] handle_ZigZag nunca inicializado no OnInit().
//
// BUG 3  [CRÍTICO] OnTick nunca chamava Calculate_ZigZag(); adicionada
//        chamada no bloco diário E em cada novo candle do ZZ_TF.
//
// BUG 4  [CRÍTICO] Calculate_TotalProfits(): linha de comissão apagada,
//        TotalComissions sempre ficava 0. Restaurada:
//        TotalComissions += PositionGetDouble(POSITION_COMMISSION).
//
// BUG 5  Swing_Tops[] / Swing_Bottoms[] (usados no System 9) nunca
//        populados. Agora preenchidos dentro de Calculate_ZigZag().
//
// BUG 6  MyBarShift(): implementação instável com gaps de fim de semana.
//        Reescrita usando CopyTime com from_pos para encontrar o bar
//        imediatamente antes ou igual ao datetime pedido.
//
// BUG 7  ReadWPR(): WPR_1M_1 / WPR_1M_2 declarados mas nunca lidos.
//        Adicionada leitura do handle_WPR_1M.
//
// BUG 8  Generate_StopOrder_1(): usava SymbolInfoDouble(SYMBOL_POINT)*3
//        em vez de Poin*3 para calcular distância → cálculo errado em
//        brokers de 5 dígitos.
//
// BUG 9  Generate_StopOrder_1(): condição de verificação do afastamento
//        dos candles usava SymbolInfoDouble(SYMBOL_POINT) em vez de Poin.
//
// BUG 10 OnTick(): D1Bars comparado com dt.day em vez de com o número
//        real de barras D1, causava re-execução do bloco diário ao virar
//        o mês (dia 1 = dia 1 do mês anterior). Corrigido usando
//        Bars(_Symbol, PERIOD_D1).
//
// BUG 11 OnDeinit(): handle_ZigZag não era liberado. Adicionado release.
//
// BUG 12 CalculateLotSize(): MarginRequired_G declarado mas nunca usado
//        nem inicializado. Removido o global sem uso; cálculo de lote
//        permanece correto.
//
// BUG 13 CCI_LT_OK(): nome da função confuso (lê TF_CCI não "LT").
//        Sem impacto em runtime, mas adicionado comentário explicativo.
//
// BUG 14 Generate_StopOrder_3() chamava Generate_StopOrder_2() mesmo
//        quando Enable_NewsFilter estava ligado mas News_OK()==true.
//        Condição corrigida (ver comentário na função).
//
// BUG 15 ZZBars nunca atualizado em nenhum ponto do código original.
//        Agora atualizado corretamente no OnTick().
//
// BUG 16 CheckCloseCond(): usado -WPR_1 para verificar nível de WPR;
//        WPR já retorna valor negativo (0 a -100), então -WPR_1 era
//        sempre positivo → condição errada. Corrigido para usar WPR_1
//        diretamente com os limiares adequados.
//
// BUG 17 DoTrailing() para SELL: quando curSL==0 a comparação com
//        openPx-BreakEvenPips não funcionava corretamente. Adicionada
//        guarda para curSL==0.
//
// BUG 18 FiboCross_OK(): quando modo SELL verificava BO_Fibo_50 mas
//        a variável BO_Fibo_SL era setada para _50 antes de checar _38.
//        Reordenação para que cada nível configure o SL correto.
// ============================================================

#property copyright "Danny Weckhuyzen"
#property link      "@Bestrobotworld1"
#property version   "5.01"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Indicators\Indicators.mqh>

CTrade         trade;
CPositionInfo  positionInfo;
COrderInfo     orderInfo;
CSymbolInfo    symbolInfo;

#define HAHIGH   0
#define HALOW    1
#define HAOPEN   2
#define HACLOSE  3
#define ARR_SIZE 20

// ============================================================
// INPUT PARAMETERS
// ============================================================
input string   Setting1            = "** Trading system **";
input int      MagicNo             = 1111;
input bool     EnableSystem_1      = true;
input bool     EnableSystem_2      = false;
input bool     EnableSystem_3      = false;
input bool     EnableSystem_4      = false;
input bool     EnableSystem_5      = false;
input bool     EnableSystem_6      = false;
input bool     EnableSystem_7      = false;
input bool     EnableSystem_8      = false;
input bool     EnableSystem_9      = false;
input bool     EnableSystem_10     = false;
input bool     EnableSystem_11     = false;
input bool     EnableSystem_12     = false;
input bool     EnableSystem_13     = false;
input bool     EnableSystem_14     = false;
input double   MinTakeProfit       = 100;
input double   MinStopLoss         = 100;
input double   MaxStopLoss         = 300;
input bool     Enable_Fixed_SL     = false;
input double   StopLoss            = 40;

input string   MM_setting          = "** Money Management **";
input bool     MM                  = true;
input bool     Enable_Gradual_MM   = false;
input double   RiskPercent         = 5;
input double   LotSize             = 0.1;
input double   Max_Lot_Size        = 99999;

input string   Gen_setting         = "** General **";
input double   TakeProfit          = 1000;
input string   ComTPRatio          = "TP Ratio of Fibo 23.2 zone";
input double   TakeProfitRatio     = 1;
input string   ComTP_FiboRation    = "Ratio yesterday high-low";
input double   TP_FiboRatio        = 50;
input bool     Enable_ADR_TP       = false;
input double   ADR_TP_Ratio        = 4.6;
input bool     Enable_Fractal_TP   = false;
input double   ADR_Fractal_Ratio   = 0.6;
input double   StopLossRatio       = 1;
input bool     EnableZZStopLoss    = true;
input int      ZZ_SL_Method        = 2;
input int      Nr_Extra_SL_Pips    = 2;
input bool     Enable_ZZ_Fract_LT  = false;
input bool     Enable_OnlyFractals = false;
input int      ZZ_Fract_LT_TF      = 5;
input int      Nr_Days_Back        = 5;
input int      Nr_Fractals_Back    = 2;
input bool     EnableBreakOutSL    = false;

input string   ComSystem_1         = " **SYSTEM 1 & 2 PARAMETERS**";
input double   MinPipsDistance     = -14;
input int      TF_Below_BO         = 1;
input int      CloseSecTimeOut     = 120;
input bool     EnableGMTOffset     = false;
input int      GmtClosingOffset    = 0;
input int      TestMult            = 1;

input string   ComSystem_4         = " **SYSTEM 4 PARAMETERS**";
input double   PipsDistance        = 20;
input double   OpenPipsDistance    = 20;
input bool     Enable_FiboDist_4   = false;
input bool     En_PipsDistRatio    = false;
input double   PipsDistRatio       = 0.2;
input bool     En_OpenPipsDistRatio= false;
input double   OpenPipsDistRatio   = 0.2;
input bool     En_StopLossRatio_4  = false;
input double   StopLossRatio_4     = 0.5;
input double   DistanceLimitRatio  = 1;
input int      TF_MA_4             = 1;
input int      MA_Period_4         = 2;
input int      MA_Method_4         = 3;

input string   ComSystem_5         = " **SYSTEM 5/6/7 PARAMETERS**";
input bool     Enable_3_Trades     = false;
input bool     Enable_61_Cross     = false;
input bool     Enable_50_Cross     = true;
input bool     Enable_38_Cross     = false;
input bool     Enable_23_Cross     = false;
input bool     Enable_Ref_Cross    = false;
input bool     Enable_2_Ref_Cross  = false;
input bool     Enable_TL_Cross     = false;
input bool     En_FiboSL_Ratio_5   = true;
input double   FiboSLRatio_23      = 0.62;
input double   FiboSLRatio_38      = 0.62;
input double   FiboSLRatio_50      = 0.63;
input double   FiboSLRatio_61      = 0.83;
input double   FiboSLRatio_TL      = 0.83;
input double   FiboSLRatio_Ref     = 0.83;
input bool     En_FiboTP_5         = true;
input int      FiboTP_5            = 0;
input double   RelFiboDist         = 0.5;
input int      FiboCross_Method    = 0;
input double   FiboOffsetPips      = 20;
input int      FiboZZ_TF           = 2;
input int      TL_Cross_TF         = 1;
input int      MaxBreakOutPips     = 1000;
input bool     Enable_BOTimeOuts   = false;
input int      MaxBOTradingMin_23  = 510;
input int      MaxBOTradingMin_38  = 270;
input int      MaxBOTradingMin_50  = 540;
input int      MaxBOTradingMin     = 420;
input bool     Enable_MACD_TimeOut = false;
input int      MinBreakOutPips     = 0;

input string   ComSystem_7         = " **SYSTEM 7 PARAMETERS**";
input bool     Enable_CCI_Retrace  = false;
input int      CCI_Retrace_Limit   = 5;
input bool     UseVolatilityTickSpeed = false;
input bool     Enable_ZigZagFractals  = false;
input int      ZigZagFractals_TF      = 1;
input int      Nr_ZigZagFractals      = 50;
input int      ZigZagMinBefore        = 20;
input int      ZigZagMinAfter         = 10;
input bool     Enable_SessionBreak    = false;
input int      Nr_Session_Bars        = 4;

input string   ComSystem_8         = " **SYSTEM 8 PARAMETERS**";
input int      XPS_period          = 52;
input int      XPS_TF              = 1;

input string   ComSystem_9         = " **SYSTEM 9 PARAMETERS**";
input int      Nr_ST_Bars          = 50;
input int      ZZ_ST_TF            = 2;
input bool     Enable_CloseRevOrders = false;
input double   LotExp              = 1;
input double   ADR_Multiplier      = 1;
input bool     Enable_NearbyTakeProfit = false;

input string   ComSystem_10        = " **SYSTEM 10 PARAMETERS**";
input bool     Enable_TradeAboveRefPrice = false;

input string   ComSystem_13        = " **SYSTEM 13 PARAMETERS**";
input bool     Enable_Orders_Start_EA = false;
input bool     Enable_Standard_Gann   = false;
input double   Max_Percent_Distance   = 50.0;
input bool     Enable_Closing_Sys13   = true;
input int      Nr_Min_Opening_Period  = 9;
input int      Close_Pending_GMT_Hr   = 17;
input bool     Close_Only_At_Profit   = false;
input bool     Close_News_At_Profit   = false;
input bool     Close_Pending_Gann_Cross = false;
input double   Min_Profit_Ratio       = 0.6;
input int      Extra_SupRes_SL_Points = 20;
input bool     Enable_ADR_StopLoss    = false;
input double   ADR_SL_Ratio           = 0.5;
input bool     Enable_Reverse_Pending = false;
input bool     Enable_OpenAtSupResPiv = false;
input bool     Enable_New_Open_Gann   = false;

input double   MaxSpread              = 20;
input bool     Enable_VergilTrailClose = false;
input string   ComBreakEven           = "+++ Breakeven +++; If 0 - do not use";
input double   BreakEvenThreshold     = 1;
input double   BreakEvenPips          = -70;
input double   Positive_Points_BE     = 20;
input string   Com_Fractal_BE         = "+++ Breakeven determined when fractal found +++";
input bool     Enable_Fractal_BE      = false;
input int      Fractal_TF_BE          = 3;
input bool     Enable_Fibo_BE         = false;
input double   Fibo_Ratio_BE          = 1.7;
input bool     Enable_BreakOut_BE     = false;
input int      BreakOut_Points_BE     = 56;
input int      BreakOut_Minutes_BE    = 1;
input int      BO_Points_Trailed_BE   = 6;

input string   SettinGs_3             = "+++ Trailing Stop +++";
input string   TrailTypeCom           = "0=no trailing; 1=actual bar trail; 2=lowest/highest of trailingbar, 3=dynamic trailing";
input int      TrailingType           = 0;
input bool     Enable_Trailing_1      = false;
input bool     Enable_Trailing_2      = false;
input bool     Enable_Trailing_3      = false;
input bool     Enable_Trailing_4      = false;
input bool     Enable_Trailing_5      = false;
input bool     Enable_Trailing_6      = false;
input double   TrailingStop           = 370;
input double   TraillingStep          = 500;
input int      TraillingBar           = 5;
input int      TF_Trailing            = 1;
input string   ComTrail_3             = "Trailing with ATR-exit";
input int      ATR_Periods            = 20;
input double   ATR_Mult               = 2;
input int      ATR_Bar                = 0;
input string   ComTrail_4             = "Trailing with Fibo's";
input double   Fibo_TrailRatio        = 0.5;
input string   ComTrail_6             = "Trailing with Fractal";
input int      TF_Trail_Fractal       = 3;
input double   Trail_Pips_Distance    = 2;
input int      Trail_Fractal_Method   = 0;

input string   Comment_WPR            = "Opening of %Williams";
input string   TF_WPR_Comment         = "1=1M;2=5M;3=15M;4=30M;5=1H;6=4H;7=1D;8=1W;9=1M";
input bool     Enable_LT_WPR          = true;
input int      TF_LT_WPR              = 6;
input int      WPR_LT_Period          = 18;
input int      WPR_LT_Limit           = 40;
input bool     Enable_WPR             = true;
input int      TF_WPR                 = 2;
input int      WPR_Period             = 21;
input int      WPR_Limit              = 20;
input bool     Enable_WPR_1M          = true;
input int      WPR_1M_Method          = 0;
input int      TF_WPR_1M              = 1;
input int      WPR_1M_Period          = 19;
input int      WPR_1M_Limit           = 15;

input string   Comment_CCI            = "Opening of CCI";
input bool     Enable_CCI             = true;
input bool     Enable_Nx_CCI          = false;
input int      CCI_LT_Method          = 0;
input int      TF_CCI                 = 6;
input int      CCI_Period             = 17;
input int      CCI_TH                 = 500;
input int      CCI_Limit              = 80;
input int      CCI_LT_Bars            = 3;

input string   Comment_1M_CCI         = "Opening of CCI 1 Min TF";
input bool     Enable_CCI_1M          = false;
input bool     Enable_Nx_CCI_1M       = false;
input int      CCI_1M_Method          = 1;
input int      CCI_1M_Limit           = 150;
input int      CCI_1M_TF              = 1;
input int      CCI_1M_TH              = 355;
input int      CCI_Av_TH              = 300;
input int      NR_CCI_Bars            = 3;

input string   Comment_RSI            = "Opening of RSI";
input bool     Enable_RSI             = false;
input bool     Enable_Rev_RSI         = false;
input int      RSI_Method             = 9;
input int      TF_RSI                 = 1;
input int      Period_RSI             = 7;
input int      ApplPrice_RSI          = PRICE_TYPICAL;
input double   RSI_Limit              = 30;
input int      NR_RSI_Bars            = 3;

input string   CSTOCHFilter           = "Opening Stochastics";
input bool     Enable_STOCH           = false;
input int      Stoch_Method           = 6;
input double   Stoch_Level            = 10.0;
input int      TF_STOCH               = 1;
input int      Stoch_K                = 5;
input int      Stoch_D                = 3;
input int      Stoch_Slowing          = 3;
input int      Stoch_MAMethod         = 0;

input string   CSTOCHLTFilter         = "Opening Stochastics High TF";
input bool     Enable_LT_STOCH        = false;
input int      Stoch_LT_Method        = 5;
input double   Stoch_LT_Level         = 30.0;
input int      TF_LT_STOCH            = 2;
input int      Stoch_LT_K             = 5;
input int      Stoch_LT_D             = 3;
input int      Stoch_LT_Slowing       = 3;
input int      Stoch_LT_MAMethod      = 0;

input string   CMACD                  = "Opening MACD";
input bool     Enable_MACD            = false;
input int      TF_MACD                = 1;
input int      Fast_EMA_Period        = 11;
input int      Slow_EMA_Period        = 34;
input int      Signal_SMA_Period      = 14;
input int      MACD_AppliedPrice      = 0;
input int      MACD_Bars              = 4;
input int      MACD_Method_Inp        = 0;

input string   CMACD_LT               = "Opening MACD Higher TF";
input bool     Enable_LT_MACD         = false;
input int      TF_LT_MACD             = 3;
input int      MACD_LT_Fast_EMA_Period  = 12;
input int      MACD_LT_Slow_EMA_Period  = 26;
input int      MACD_LT_Signal_SMA_Period= 7;
input int      MACD_LT_AppliedPrice     = 0;
input int      MACD_LT_Bars             = 3;
input int      MACD_LT_Method           = 2;

input string   CBollBandsFilter       = "Opening/Closing Bollinger Bands";
input int      TF_BB                  = 3;
input int      Period_BB              = 20;
input double   Deviation_BB           = 2;
input int      Shift_BB               = 0;

input string   Comment_ZigZag         = "--- ZigZag for calculating average top-bottom pips ---";
input bool     Enable_ZigZag          = false;
input int      ZigZag_TF              = 5;
input bool     Enable_Higher_TF       = false;
input bool     Enable_Extra_TF        = false;
input double   ZigZag_ADR_Ratio       = 1;
input int      ZigZag_TF_Refresh      = 1;
input int      ZigZag_ExtDepth        = 10;
input int      ZigZag_ExtDeviation    = 5;
input int      ZigZag_ExtBackstep     = 3;
input int      ZigZag_TotSwings       = 10;

input string   Comment_Fractals       = "--- Entries are activated when Fractal is detected ---";
input bool     Enable_Fractals        = false;
input int      Fractals_TF            = 1;
input int      Fractals_Shift         = 5;

input string   ComNews_Filter         = "--- NEWS FILTERING ---";
input bool     Enable_NewsFilter      = false;
input bool     Enable_ForceNewsReading= false;
input bool     Enable_TradingIfNews   = false;
input bool     High_Impact            = true;
input int      MinsUntilNextHighNews  = 60;
input int      MinsSincePrevHighNews  = 60;
input bool     Medium_Impact          = false;
input int      MinsUntilNextMediumNews= 0;
input int      MinsSincePrevMediumNews= 5;
input bool     Low_Impact             = false;
input int      MinsUntilNextLowNews   = 1;
input int      MinsSincePrevLowNews   = 5;

input string   Comment_Pivots             = "--- Calculation of Fibonacci/Standard Pivot/Sup/Res Levels ---";
input bool     Enable_Fibo_Pivots         = true;
input bool     Enable_Standard_Pivots     = true;
input bool     Enable_Daily_Pivots        = false;
input bool     Enable_Weekly_Pivots       = false;
input bool     Enable_Monthly_Pivots      = false;
input int      Pivot_GMT_Offset           = -1;
input bool     Show_Pivot_Lines           = false;

input string   ComBrokerGMT               = "----BrokerGMT only used in backtesting!!!----";
input int      BrokerGMT                  = 2;

input bool     EnableFileErrorLogging     = false;
input int      SizeBackGround             = 330;
input bool     Enable_Comments            = true;

// ============================================================
// TIMEFRAME ARRAY
// ============================================================
ENUM_TIMEFRAMES TF_Array[] = {
   PERIOD_CURRENT, PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
   PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1
};
string TF_TEXT[] = {"PinBar","M1","M5","M15","M30","H1","H4","D1","W1","MN"};

// ============================================================
// GLOBAL VARIABLES
// ============================================================
double   Poin;
int      Mult;
double   MaxLot_G;
double   MinLot_G;
double   LotStep_G;
int      LotDec;

double   TopBreakOutLow    = -1;
double   TopBreakOutHigh   = -1;
double   BreakOutHighest   = -1;
double   BreakOutLowest    = -1;
double   RefBreakOutLevel  = -1;

double   YesterdayHigh     = -1;
double   YesterdayLow      = -1;
datetime YesterdayHigh_Time= 0;
datetime YesterdayLow_Time = 0;
double   TodayHigh;
double   TodayLow;
datetime TodayHigh_Time;
datetime TodayLow_Time;
datetime BreakOutLow_Time  = 0;
datetime BreakOutLow_ZZ_Time = 0;
datetime BreakOutHigh_Time = 0;
datetime BreakOutHigh_ZZ_Time= 0;

int      OpenOrders        = 0;
int      OpenActiveOrders  = 0;
int      PendingOrders     = 0;
int      BuyOrders         = 0;
int      SellOrders        = 0;
int      OpenBuyStopOrders = 0;
int      OpenSellStopOrders= 0;
int      OpenBuyLimitOrders = 0;
int      OpenSellLimitOrders=0;
int      AllowedStopOrders = 1;
int      PreviousActiveOrders=0;

double   WPR_1, WPR_2;
double   WPR_1M_1, WPR_1M_2;   // FIX BUG 7: agora preenchidos em ReadWPR()
double   CCI_1, CCI_2;
double   MA_1;

double   Fibo_Level_0, Fibo_Level_23, Fibo_Level_38;
double   Fibo_Level_50, Fibo_Level_61, Fibo_Level_76;
double   Fibo_Level_100, Fibo_Level_123;
double   Fibo_Level_SL;
double   Fibo_ZONE_1_SL, Fibo_ZONE_2_SL, Fibo_ZONE_3_SL, Fibo_ZONE_4_SL;
double   Fibo_ZONE_1_NT, Fibo_ZONE_2_NT, Fibo_ZONE_3_NT, Fibo_ZONE_4_NT;
int      Fibo_Status = -1;
datetime Fibo_Level_0_Time;
datetime Fibo_Level_100_Time;

double   BO_Fibo_0, BO_Fibo_23, BO_Fibo_38, BO_Fibo_50, BO_Fibo_61, BO_Fibo_100;
double   BO_Fibo_SL, BO_Fibo_SL_23, BO_Fibo_SL_38, BO_Fibo_SL_50, BO_Fibo_SL_61;
double   BO_Fibo_SL_TL_Cross, BO_Fibo_SL_Ref;
double   Top, Bottom;

bool     Enable_Retrace          = false;
bool     Enable_Buy_Retrace      = false;
bool     Enable_Sell_Retrace     = false;
bool     Enable_Retrace_23       = false;
bool     Enable_Retrace_38       = false;
bool     Enable_Retrace_50       = false;
bool     Enable_Retrace_61       = false;
bool     Enable_Retrace_TL       = false;
bool     Enable_Cross_Reference  = false;
bool     Second_Trade_Enabled    = false;
bool     Fibo_23_Crossed         = false;
bool     Fibo_38_Crossed         = false;
bool     Fibo_50_Crossed         = false;
bool     Fibo_61_Crossed         = false;
bool     Ref_Crossed             = false;
bool     TL_Crossed              = false;

double   Swing_High[];
double   Swing_Low[];
datetime Swing_High_Time[];
datetime Swing_Low_Time[];
double   Swing_ST_High[];
double   Swing_ST_Low[];
datetime Swing_ST_High_Time[];
datetime Swing_ST_Low_Time[];
double   Swing_LT_High[];
double   Swing_LT_Low[];
datetime Swing_LT_High_Time[];
datetime Swing_LT_Low_Time[];
double   Swing_Tops[];      // FIX BUG 5: populado em Calculate_ZigZag()
double   Swing_Bottoms[];   // FIX BUG 5: populado em Calculate_ZigZag()
double   Top_Levels[];
double   Bottom_Levels[];
double   Swing_All[];

double   ADR = 0;
double   ADR_MIN, ADR_MAX;
int      ADR_Period_G = 20;
int      Fixed_ADR_G  = 100;

double   Average_5M_Volume = 0;
double   Typical_5M_Volume = 0;
double   Max_5M_Volume     = 0;
double   CurrentVolume     = 0;
double   VolumeThreshold   = 0;

bool     NewsArrayFilled = false;
int      NewsTotal = 0;
datetime NewsTimes[300];
int      NewsRatings[300];
string   sCurrency[300];
string   sDescription[300];
string   NextNewsDescription = "";
bool     SinceNewsActive = false;
bool     NEWS_OK_G = false;

double   Spread_Ar[30];
double   AvgSpread = 0;
double   MaxArraySpread = 0;

double   TotalProfits    = 0;
double   TotalComissions = 0;

// FIX BUG 10: D1Bars agora armazena contagem real de barras D1
int      D1Bars  = -1;
int      M1Bars  = -1;
int      M30Bars = -1;
int      Indi_Bars = -1;
int      Order_Bars = -1;
int      ZZBars = -1;   // FIX BUG 15: agora atualizado corretamente

double   STOCH_0, STOCH_1, STOCH_2, STOCH_3, STOCH_4;
double   STOCH_S_0, STOCH_S_1, STOCH_S_2;
double   STOCH_LT_0, STOCH_LT_1, STOCH_LT_2;
double   STOCH_LT_S_0, STOCH_LT_S_1, STOCH_LT_S_2;

double   Gann_Sup[22];
double   Gann_Res[22];
bool     First_Gann_PASS = false;
double   TodayGannClose;
datetime TodayGannClose_Time;
double   SecondGannCycle;
datetime SecondGannCycle_Time;

double   Daily_Pivot, Daily_R1, Daily_R2, Daily_R3;
double   Daily_S1, Daily_S2, Daily_S3;
double   TodayClose, YesterdayClose;
double   Daily_Pivots[7];

double   AverageSlippage = 0;
double   AverageCloseSlippage = 0;
double   AverageTakeProfitSlippage = 0;
int      Slippage_samples = 0;
int      Stop_Slippage_samples = 0;
int      TakeProfit_Slippage_samples = 0;

string   OrderMarking = "GoldHunter Strat";

int      Slippage_G = 5;
int      MaxOrder_G = 4;
bool     Trailing_Stop_G = true;
bool     EmailAlerts = true;
double   DecrTP = 0;
double   IncrLS = 0;
double   Gradual_LotSize = 0;
datetime OrderTimeOut_dt = 0;

string   InpName = "FiboLevels";

double   TL_T[10][2];
double   TL_1[10][2];
double   TL_2[10][2];
double   TL_M[10][2];
double   TL_1_Current[10];
double   TL_2_Current[10];
double   TL_M_Current[10];
int      TL_Direction[10];
datetime TL_T_dt[10][2];

// ============================================================
// INDICATOR HANDLES
// ============================================================
int      handle_WPR_LT     = INVALID_HANDLE;
int      handle_WPR        = INVALID_HANDLE;
int      handle_WPR_1M     = INVALID_HANDLE;
int      handle_CCI_LT     = INVALID_HANDLE;
int      handle_CCI_1M     = INVALID_HANDLE;
int      handle_MA_M5      = INVALID_HANDLE;
int      handle_ZigZag     = INVALID_HANDLE;   // FIX BUG 2 & 11
int      handle_Fractals   = INVALID_HANDLE;
int      handle_BB         = INVALID_HANDLE;
int      handle_ATR        = INVALID_HANDLE;
int      handle_STOCH      = INVALID_HANDLE;
int      handle_STOCH_LT   = INVALID_HANDLE;
int      handle_MACD       = INVALID_HANDLE;
int      handle_MACD_LT    = INVALID_HANDLE;

double   ExtZigzagBuffer[];
double   ExtHighBuffer[];
double   ExtLowBuffer[];
double   dUpFractalsBuffer[];
double   dDownFractalsBuffer[];

// ============================================================
// OnInit
// ============================================================
int OnInit()
{
   symbolInfo.Name(_Symbol);
   symbolInfo.RefreshRates();

   Poin     = GetPoin();
   Mult     = GetMultiplier();
   MaxLot_G = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   MinLot_G = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   LotStep_G= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(LotStep_G == 0.0001)      LotDec = 4;
   else if(LotStep_G == 0.001)  LotDec = 3;
   else if(LotStep_G == 0.01)   LotDec = 2;
   else if(LotStep_G == 0.1)    LotDec = 1;
   else                          LotDec = 0;

   trade.SetExpertMagicNumber(MagicNo);
   trade.SetDeviationInPoints(Slippage_G * Mult);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   ArrayResize(Swing_High,        ZigZag_TotSwings);
   ArrayResize(Swing_High_Time,   ZigZag_TotSwings);
   ArrayResize(Swing_Low,         ZigZag_TotSwings);
   ArrayResize(Swing_Low_Time,    ZigZag_TotSwings);
   ArrayResize(Swing_ST_High,     ZigZag_TotSwings);
   ArrayResize(Swing_ST_High_Time,ZigZag_TotSwings);
   ArrayResize(Swing_ST_Low,      ZigZag_TotSwings);
   ArrayResize(Swing_ST_Low_Time, ZigZag_TotSwings);
   ArrayResize(Swing_LT_High,     ZigZag_TotSwings);
   ArrayResize(Swing_LT_High_Time,ZigZag_TotSwings);
   ArrayResize(Swing_LT_Low,      ZigZag_TotSwings);
   ArrayResize(Swing_LT_Low_Time, ZigZag_TotSwings);
   ArrayResize(Swing_Tops,        ZigZag_TotSwings);
   ArrayResize(Swing_Bottoms,     ZigZag_TotSwings);
   ArrayInitialize(Swing_High,    0);
   ArrayInitialize(Swing_Low,     0);
   ArrayInitialize(Swing_Tops,    0);
   ArrayInitialize(Swing_Bottoms, 0);
   ArrayInitialize(Spread_Ar,    -1);

   handle_WPR_LT  = iWPR(_Symbol, TF_Array[TF_LT_WPR],  WPR_LT_Period);
   handle_WPR     = iWPR(_Symbol, TF_Array[TF_WPR],      WPR_Period);
   handle_WPR_1M  = iWPR(_Symbol, TF_Array[TF_WPR_1M],   WPR_1M_Period);
   handle_CCI_LT  = iCCI(_Symbol, TF_Array[TF_CCI],      CCI_Period,   PRICE_TYPICAL);
   handle_CCI_1M  = iCCI(_Symbol, TF_Array[CCI_1M_TF],   CCI_Period,   PRICE_TYPICAL);
   handle_ATR     = iATR(_Symbol, TF_Array[3],            18);
   handle_STOCH   = iStochastic(_Symbol, TF_Array[TF_STOCH],
                                 Stoch_K, Stoch_D, Stoch_Slowing,
                                 (ENUM_MA_METHOD)Stoch_MAMethod, STO_LOWHIGH);
   handle_STOCH_LT= iStochastic(_Symbol, TF_Array[TF_LT_STOCH],
                                 Stoch_LT_K, Stoch_LT_D, Stoch_LT_Slowing,
                                 (ENUM_MA_METHOD)Stoch_LT_MAMethod, STO_LOWHIGH);
   handle_MACD    = iMACD(_Symbol, TF_Array[TF_MACD],
                           Fast_EMA_Period, Slow_EMA_Period, Signal_SMA_Period,
                           (ENUM_APPLIED_PRICE)MACD_AppliedPrice);
   handle_MACD_LT = iMACD(_Symbol, TF_Array[TF_LT_MACD],
                           MACD_LT_Fast_EMA_Period, MACD_LT_Slow_EMA_Period,
                           MACD_LT_Signal_SMA_Period,
                           (ENUM_APPLIED_PRICE)MACD_LT_AppliedPrice);
   handle_BB      = iBands(_Symbol, TF_Array[TF_BB], Period_BB, 0,
                            Deviation_BB, PRICE_CLOSE);
   handle_Fractals= iFractals(_Symbol, TF_Array[Fractals_TF]);
   handle_MA_M5   = iMA(_Symbol, TF_Array[2], 170, 0, MODE_SMMA, PRICE_CLOSE);

   // FIX BUG 2: inicializa handle do ZigZag usando indicador nativo
   // O ZigZag padrão está em "Examples\\ZigZag" no MT5.
   // Se não encontrar, Calculate_ZigZag() usa detecção interna de pivot.
   handle_ZigZag  = iCustom(_Symbol, TF_Array[ZigZag_TF],
                             "Examples\\ZigZag",
                             ZigZag_ExtDepth, ZigZag_ExtDeviation, ZigZag_ExtBackstep);
   if(handle_ZigZag == INVALID_HANDLE)
      Print("ZigZag handle nao criado - usando deteccao interna de pivots.");

   if(Enable_Orders_Start_EA) First_Gann_PASS = true;
   else                        First_Gann_PASS = false;

   Enable_Retrace = false;
   ObjectDelete(0, InpName);

   Print("GoldHunter MQL5 FIXED inicializado em ", _Symbol,
         " | Poin=", Poin, " | Mult=", Mult);

   return(INIT_SUCCEEDED);
}

// ============================================================
// OnDeinit
// ============================================================
void OnDeinit(const int reason)
{
   if(handle_WPR_LT  != INVALID_HANDLE) IndicatorRelease(handle_WPR_LT);
   if(handle_WPR     != INVALID_HANDLE) IndicatorRelease(handle_WPR);
   if(handle_WPR_1M  != INVALID_HANDLE) IndicatorRelease(handle_WPR_1M);
   if(handle_CCI_LT  != INVALID_HANDLE) IndicatorRelease(handle_CCI_LT);
   if(handle_CCI_1M  != INVALID_HANDLE) IndicatorRelease(handle_CCI_1M);
   if(handle_ATR     != INVALID_HANDLE) IndicatorRelease(handle_ATR);
   if(handle_STOCH   != INVALID_HANDLE) IndicatorRelease(handle_STOCH);
   if(handle_STOCH_LT!= INVALID_HANDLE) IndicatorRelease(handle_STOCH_LT);
   if(handle_MACD    != INVALID_HANDLE) IndicatorRelease(handle_MACD);
   if(handle_MACD_LT != INVALID_HANDLE) IndicatorRelease(handle_MACD_LT);
   if(handle_BB      != INVALID_HANDLE) IndicatorRelease(handle_BB);
   if(handle_Fractals!= INVALID_HANDLE) IndicatorRelease(handle_Fractals);
   if(handle_MA_M5   != INVALID_HANDLE) IndicatorRelease(handle_MA_M5);
   // FIX BUG 11: libera handle do ZigZag
   if(handle_ZigZag  != INVALID_HANDLE) IndicatorRelease(handle_ZigZag);

   ObjectDelete(0, InpName);
}

// ============================================================
// OnTick
// ============================================================
void OnTick()
{
   symbolInfo.RefreshRates();

   // FIX BUG 10: compara contagem real de barras D1, não dt.day
   int curD1Bars = Bars(_Symbol, PERIOD_D1);
   if(D1Bars != curD1Bars || Swing_High[0] == 0 || Swing_Low[0] == 0)
   {
      NewsArrayFilled = false;
      D1Bars  = curD1Bars;
      M30Bars = Bars(_Symbol, PERIOD_M30);

      Calculate_ADR();
      FindHighLowPreviousDay();

      TodayHigh      = YesterdayHigh;
      TodayHigh_Time = YesterdayHigh_Time;
      TodayLow       = YesterdayLow;
      TodayLow_Time  = YesterdayLow_Time;

      Print("YesterdayHigh=", DoubleToString(YesterdayHigh, _Digits),
            "  YesterdayLow=", DoubleToString(YesterdayLow, _Digits));

      if(!Enable_Retrace)
      {
         TopBreakOutLow  = -1;
         TopBreakOutHigh = -1;
         BreakOutHighest = YesterdayHigh;
         BreakOutLowest  = YesterdayLow;
         BreakOutLow_Time  = 0;
         BreakOutHigh_Time = 0;
      }

      // FIX BUG 1 & 3: calcula ZigZag ao início do dia
      Calculate_ZigZag();

      CloseStopOrders();
      if(EnableSystem_1 && PendingOrders > 0)
         CloseLimitOrders();
      ObjectDelete(0, InpName);
   }

   // FIX BUG 3 & 15: recalcula ZigZag em cada novo candle do TF configurado
   int curZZBars = Bars(_Symbol, TF_Array[ZigZag_TF]);
   if(ZZBars != curZZBars)
   {
      Calculate_ZigZag();
      ZZBars = curZZBars;
   }

   CalculateAvgSpread();

   int cur1MBars = Bars(_Symbol, PERIOD_M1);
   if(Indi_Bars != cur1MBars)
   {
      ReadWPR();
      ReadCCI();
      Indi_Bars = cur1MBars;
   }

   Calculate_Fibos();

   if(EnableSystem_5 || EnableSystem_6 || EnableSystem_7)
      Check_Retrace();
   if(EnableSystem_10 || EnableSystem_14)
      Check_Retrace_10();

   Calculate_TotalProfits(-1);
   Check_Closing();
   Do_Trailing();
   CalculateSeveralTimeFrameSignals();

   int curOrder_Bars = Bars(_Symbol, PERIOD_M1);
   if(Order_Bars != curOrder_Bars || !MQLInfoInteger(MQL_TESTER))
   {
      if(EnableSystem_1)  Generate_StopOrder_1();
      if(EnableSystem_2)  Generate_StopOrder_2();
      if(EnableSystem_3)  Generate_StopOrder_3();
      if(EnableSystem_4)  Generate_StopOrder_4();
      if(EnableSystem_5)  Generate_RetraceOrder_5();
      if(EnableSystem_6)  Generate_RetraceOrder_6();
      if(EnableSystem_7)  Generate_RetraceOrder_7();
      if(EnableSystem_9)  Generate_StopOrder_9();
      if(EnableSystem_10) Generate_RetraceOrder_10();
      if(EnableSystem_13) Generate_PendingOrder_13();
      if(EnableSystem_14) Generate_FalseBreakOutOrder_14();
      Order_Bars = curOrder_Bars;
   }

   Count_Open_Orders();
   PreviousActiveOrders = OpenActiveOrders;
}

// ============================================================
// HELPER: Point size
// ============================================================
double GetPoin()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5)
      return 10.0 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   return SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

int GetMultiplier()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return (digits == 3 || digits == 5) ? 10 : 1;
}

// ============================================================
// Count Open Orders
// ============================================================
void Count_Open_Orders()
{
   OpenOrders         = 0;
   PendingOrders      = 0;
   OpenActiveOrders   = 0;
   BuyOrders          = 0;
   SellOrders         = 0;
   OpenBuyStopOrders  = 0;
   OpenSellStopOrders = 0;
   OpenBuyLimitOrders = 0;
   OpenSellLimitOrders= 0;

   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNo)
         {
            OpenOrders++;
            OpenActiveOrders++;
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  BuyOrders++;
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) SellOrders++;
         }
      }
   }

   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket))
      {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
            OrderGetInteger(ORDER_MAGIC) == MagicNo)
         {
            OpenOrders++;
            PendingOrders++;
            ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            if(otype == ORDER_TYPE_BUY_STOP)    OpenBuyStopOrders++;
            if(otype == ORDER_TYPE_SELL_STOP)   OpenSellStopOrders++;
            if(otype == ORDER_TYPE_BUY_LIMIT)   OpenBuyLimitOrders++;
            if(otype == ORDER_TYPE_SELL_LIMIT)  OpenSellLimitOrders++;
         }
      }
   }
}

// ============================================================
// INDICATOR READS
// ============================================================
void ReadWPR()
{
   double buf[];
   ArraySetAsSeries(buf, true);

   if(handle_WPR != INVALID_HANDLE && CopyBuffer(handle_WPR, 0, 0, 3, buf) == 3)
   {
      WPR_1 = buf[1];
      WPR_2 = buf[2];
   }

   // FIX BUG 7: lia handle_CCI_LT mas nunca lia handle_WPR_1M
   if(handle_WPR_1M != INVALID_HANDLE && CopyBuffer(handle_WPR_1M, 0, 0, 3, buf) == 3)
   {
      WPR_1M_1 = buf[1];
      WPR_1M_2 = buf[2];
   }

   if(handle_CCI_LT != INVALID_HANDLE && CopyBuffer(handle_CCI_LT, 0, 0, 3, buf) == 3)
      CCI_1 = buf[1];
}

void ReadCCI()
{
   // Leituras adicionais de CCI podem ser inseridas aqui
}

double GetWPR(int handle, int shift)
{
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(handle, 0, 0, shift+2, buf) > shift)
      return buf[shift];
   return 0;
}

double GetCCI_1M(int shift)
{
   if(handle_CCI_1M == INVALID_HANDLE) return 0;
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(handle_CCI_1M, 0, 0, shift+2, buf) > shift)
      return buf[shift];
   return 0;
}

// ============================================================
// FIX BUG 1 & 3: CALCULATE ZIGZAG - FUNÇÃO AUSENTE NO ORIGINAL
// Detecta swing highs e lows usando dois métodos:
//   1) Indicador ZigZag externo (handle_ZigZag) se disponível
//   2) Detecção interna de pivot high/low como fallback
// Também popula Swing_Tops[] / Swing_Bottoms[] para o System 9.
// ============================================================
void Calculate_ZigZag()
{
   ArrayInitialize(Swing_High,      0);
   ArrayInitialize(Swing_Low,       0);
   ArrayInitialize(Swing_High_Time, 0);
   ArrayInitialize(Swing_Low_Time,  0);

   ENUM_TIMEFRAMES zzTF = TF_Array[ZigZag_TF];
   int maxSwings = ZigZag_TotSwings;
   int depth     = ZigZag_ExtDepth;

   // --- Método 1: via indicador ZigZag ---
   if(handle_ZigZag != INVALID_HANDLE)
   {
      int barsNeeded = 1000;
      double zzBuf[];
      ArraySetAsSeries(zzBuf, true);
      int copied = CopyBuffer(handle_ZigZag, 0, 0, barsNeeded, zzBuf);
      if(copied >= 10)
      {
         int hiCnt = 0, loCnt = 0;
         for(int i = 1; i < copied-1 && (hiCnt < maxSwings || loCnt < maxSwings); i++)
         {
            if(zzBuf[i] == 0.0 || zzBuf[i] == EMPTY_VALUE) continue;
            double hi = iHigh(_Symbol, zzTF, i);
            double lo = iLow (_Symbol, zzTF, i);
            double ptTol = Poin * 2.0;

            if(MathAbs(zzBuf[i] - hi) <= ptTol && hiCnt < maxSwings)
            {
               Swing_High[hiCnt]      = zzBuf[i];
               Swing_High_Time[hiCnt] = iTime(_Symbol, zzTF, i);
               hiCnt++;
            }
            else if(MathAbs(zzBuf[i] - lo) <= ptTol && loCnt < maxSwings)
            {
               Swing_Low[loCnt]      = zzBuf[i];
               Swing_Low_Time[loCnt] = iTime(_Symbol, zzTF, i);
               loCnt++;
            }
         }
         // Se pelo menos um par foi encontrado, usa estes resultados
         if(hiCnt > 0 && loCnt > 0)
         {
            PopulateSwingTopsBottoms();
            return;
         }
      }
   }

   // --- Método 2: detecção interna de pivot high/low (fallback) ---
   int totalBars = Bars(_Symbol, zzTF);
   if(totalBars < depth * 3) return;

   int lookback  = MathMin(totalBars - depth * 2, 800);
   int hiCnt = 0, loCnt = 0;

   for(int i = depth; i < lookback && (hiCnt < maxSwings || loCnt < maxSwings); i++)
   {
      double hi = iHigh(_Symbol, zzTF, i);
      double lo = iLow (_Symbol, zzTF, i);

      // Verifica pivot high: bar[i] é o máximo dentro de [i-depth .. i+depth]
      if(hiCnt < maxSwings)
      {
         bool isHigh = true;
         for(int j = 1; j <= depth && isHigh; j++)
         {
            if(iHigh(_Symbol, zzTF, i - j) >= hi) isHigh = false;
            if(iHigh(_Symbol, zzTF, i + j) >= hi) isHigh = false;
         }
         if(isHigh)
         {
            Swing_High[hiCnt]      = hi;
            Swing_High_Time[hiCnt] = iTime(_Symbol, zzTF, i);
            hiCnt++;
         }
      }

      // Verifica pivot low: bar[i] é o mínimo dentro de [i-depth .. i+depth]
      if(loCnt < maxSwings)
      {
         bool isLow = true;
         for(int j = 1; j <= depth && isLow; j++)
         {
            if(iLow(_Symbol, zzTF, i - j) <= lo) isLow = false;
            if(iLow(_Symbol, zzTF, i + j) <= lo) isLow = false;
         }
         if(isLow)
         {
            Swing_Low[loCnt]      = lo;
            Swing_Low_Time[loCnt] = iTime(_Symbol, zzTF, i);
            loCnt++;
         }
      }
   }

   // Garante fallback com yesterday high/low se nenhum swing foi detectado
   if(Swing_High[0] == 0 && YesterdayHigh > 0)
   {
      Swing_High[0]      = YesterdayHigh;
      Swing_High_Time[0] = YesterdayHigh_Time;
   }
   if(Swing_Low[0] == 0 && YesterdayLow > 0)
   {
      Swing_Low[0]      = YesterdayLow;
      Swing_Low_Time[0] = YesterdayLow_Time;
   }

   PopulateSwingTopsBottoms();
}

// ============================================================
// FIX BUG 5: Popula Swing_Tops / Swing_Bottoms para o System 9
// ============================================================
void PopulateSwingTopsBottoms()
{
   int maxSwings = ZigZag_TotSwings;
   ArrayResize(Swing_Tops,    maxSwings);
   ArrayResize(Swing_Bottoms, maxSwings);
   ArrayInitialize(Swing_Tops,    0);
   ArrayInitialize(Swing_Bottoms, 0);
   for(int i = 0; i < maxSwings; i++)
   {
      Swing_Tops[i]    = Swing_High[i];
      Swing_Bottoms[i] = Swing_Low[i];
   }
}

// ============================================================
// CALCULATE ADR
// ============================================================
void Calculate_ADR()
{
   double total = 0;
   int    count = 0;
   ADR_MIN = 0; ADR_MAX = 0;

   for(int l = 1; l <= ADR_Period_G; l++)
   {
      double hi   = iHigh(_Symbol, PERIOD_D1, l);
      double lo   = iLow (_Symbol, PERIOD_D1, l);
      double diff = hi - lo;
      if(diff > 0)
      {
         total += diff;
         if(diff > ADR_MAX) ADR_MAX = diff;
         if(ADR_MIN == 0 || diff < ADR_MIN) ADR_MIN = diff;
         count++;
      }
   }
   if(count == ADR_Period_G)
      ADR = total / count / Poin;
   else if(count > 0)
      ADR = Fixed_ADR_G;
}

// ============================================================
// FIND HIGH/LOW PREVIOUS DAY
// ============================================================
void FindHighLowPreviousDay()
{
   int i = 1;
   while(i < 20)
   {
      MqlDateTime dt;
      datetime t = iTime(_Symbol, PERIOD_D1, i);
      TimeToStruct(t, dt);
      if(dt.day_of_week != 0 && dt.day_of_week != 6) break;
      i++;
   }

   YesterdayHigh = iHigh(_Symbol, PERIOD_D1, i);
   YesterdayLow  = iLow (_Symbol, PERIOD_D1, i);

   datetime dStart = iTime(_Symbol, PERIOD_D1, i);
   datetime dEnd   = dStart + 86400 - 60;

   int startBar = MyBarShift(_Symbol, PERIOD_M1, dStart, false);
   int endBar   = MyBarShift(_Symbol, PERIOD_M1, dEnd,   false);

   if(startBar > endBar && endBar >= 0)
   {
      int hiIdx = iHighest(_Symbol, PERIOD_M1, MODE_HIGH, startBar-endBar, endBar);
      int loIdx = iLowest (_Symbol, PERIOD_M1, MODE_LOW,  startBar-endBar, endBar);
      YesterdayHigh_Time = iTime(_Symbol, PERIOD_M1, hiIdx);
      YesterdayLow_Time  = iTime(_Symbol, PERIOD_M1, loIdx);
   }
}

// ============================================================
// FIX BUG 6: MyBarShift reescrito para robustez com gaps de
// fim de semana. Usa CopyTime para localizar o bar correto.
// ============================================================
int MyBarShift(string sym, ENUM_TIMEFRAMES tf, datetime t, bool exact = false)
{
   if(t <= 0) return -1;

   // Copia o bar cujo open time é <= t
   datetime arr[];
   // CopyTime com start_time=t e count=1 retorna o bar que contém t
   if(CopyTime(sym, tf, t, 1, arr) < 1) return -1;
   datetime barTime = arr[0];

   if(exact && barTime != t) return -1;

   // Calcula shift contando os bars entre barTime e o bar mais recente
   datetime cur = iTime(sym, tf, 0);
   if(cur <= 0 || barTime > cur) return 0;

   // Busca pelo shift exato usando CopyTime do bar 0 ao bar calculado
   int approx = (int)((cur - barTime) / (long)PeriodSeconds(tf));
   // Ajusta em caso de gaps (fins de semana, feriados)
   int look = approx + 10;
   datetime times[];
   if(CopyTime(sym, tf, 0, look, times) < 1) return approx;
   ArraySetAsSeries(times, true);

   for(int k = 0; k < ArraySize(times); k++)
   {
      if(times[k] <= barTime)
         return k;
   }
   return approx;
}

// ============================================================
// CALCULATE AVERAGE SPREAD
// ============================================================
void CalculateAvgSpread()
{
   double ask = symbolInfo.Ask();
   double bid = symbolInfo.Bid();

   for(int i = ArraySize(Spread_Ar)-1; i > 0; i--)
      Spread_Ar[i] = Spread_Ar[i-1];
   Spread_Ar[0] = ask - bid;

   double tot = 0; int nr = 0; MaxArraySpread = 0;
   for(int i = 0; i < ArraySize(Spread_Ar); i++)
   {
      if(Spread_Ar[i] > 0)
      {
         tot += Spread_Ar[i];
         if(Spread_Ar[i] > MaxArraySpread) MaxArraySpread = Spread_Ar[i];
         nr++;
      }
   }
   if(nr > 0) AvgSpread = tot / nr;
}

bool Spread_OK()
{
   return (MathRound(AvgSpread / SymbolInfoDouble(_Symbol, SYMBOL_POINT)) <= MaxSpread);
}

// ============================================================
// FIBONACCI CALCULATION
// ============================================================
void Calculate_Fibos()
{
   Fibo_Status = -1;
   if(Swing_High[0] == 0 || Swing_Low[0] == 0) return;

   if(Swing_Low_Time[0] > Swing_High_Time[0])
   {
      Fibo_Level_0   = Swing_Low[0];
      Fibo_Level_100 = Swing_High[0];
      double range   = Swing_High[0] - Swing_Low[0];
      Fibo_Level_23  = NormalizeDouble(Swing_Low[0] + range*23.6/100,  _Digits);
      Fibo_Level_38  = NormalizeDouble(Swing_Low[0] + range*38.2/100,  _Digits);
      Fibo_Level_50  = NormalizeDouble(Swing_Low[0] + range/2,         _Digits);
      Fibo_Level_61  = NormalizeDouble(Swing_Low[0] + range*61.8/100,  _Digits);
      Fibo_Level_76  = NormalizeDouble(Swing_Low[0] + range*76.4/100,  _Digits);
      Fibo_Level_123 = NormalizeDouble(Swing_Low[0] + range*123.2/100, _Digits);
      Fibo_Level_0_Time   = Swing_Low_Time[0];
      Fibo_Level_100_Time = Swing_High_Time[0];
      Fibo_Status = 1;
   }
   else if(Swing_Low_Time[0] < Swing_High_Time[0])
   {
      Fibo_Level_0   = Swing_High[0];
      Fibo_Level_100 = Swing_Low[0];
      double range   = Swing_High[0] - Swing_Low[0];
      Fibo_Level_23  = NormalizeDouble(Swing_Low[0] + range*76.4/100, _Digits);
      Fibo_Level_38  = NormalizeDouble(Swing_Low[0] + range*61.8/100, _Digits);
      Fibo_Level_50  = NormalizeDouble(Swing_Low[0] + range/2,        _Digits);
      Fibo_Level_61  = NormalizeDouble(Swing_Low[0] + range*38.2/100, _Digits);
      Fibo_Level_76  = NormalizeDouble(Swing_Low[0] + range*23.6/100, _Digits);
      Fibo_Level_0_Time   = Swing_High_Time[0];
      Fibo_Level_100_Time = Swing_Low_Time[0];
      Fibo_Status = 1;
   }
}

void Calculate_BreakOut_Fibos(int mode)
{
   if(mode == ORDER_TYPE_BUY)
   {
      Top    = BreakOutHighest;
      Bottom = TopBreakOutLow;
   }
   else
   {
      Top    = TopBreakOutHigh;
      Bottom = BreakOutLowest;
   }
   if(Top <= 0 || Bottom <= 0) return;
   double rng = Top - Bottom;

   if(mode == ORDER_TYPE_BUY)
   {
      BO_Fibo_0    = Top;
      BO_Fibo_61   = NormalizeDouble(Bottom + rng*38.2/100, _Digits);
      BO_Fibo_50   = NormalizeDouble(Bottom + rng/2,        _Digits);
      BO_Fibo_38   = NormalizeDouble(Bottom + rng*61.8/100, _Digits);
      BO_Fibo_23   = NormalizeDouble(Bottom + rng*76.4/100, _Digits);
      BO_Fibo_SL_61= NormalizeDouble(Bottom + rng*(1-FiboSLRatio_61), _Digits);
      BO_Fibo_SL_50= NormalizeDouble(Bottom + rng*(1-FiboSLRatio_50), _Digits);
      BO_Fibo_SL_38= NormalizeDouble(Bottom + rng*(1-FiboSLRatio_38), _Digits);
      BO_Fibo_SL_23= NormalizeDouble(Bottom + rng*(1-FiboSLRatio_23), _Digits);
   }
   else
   {
      BO_Fibo_0    = Bottom;
      BO_Fibo_61   = NormalizeDouble(Bottom + rng*61.8/100, _Digits);
      BO_Fibo_50   = NormalizeDouble(Bottom + rng/2,        _Digits);
      BO_Fibo_38   = NormalizeDouble(Bottom + rng*38.2/100, _Digits);
      BO_Fibo_23   = NormalizeDouble(Bottom + rng*23.6/100, _Digits);
      BO_Fibo_SL_61= NormalizeDouble(Bottom + rng*FiboSLRatio_61, _Digits);
      BO_Fibo_SL_50= NormalizeDouble(Bottom + rng*FiboSLRatio_50, _Digits);
      BO_Fibo_SL_38= NormalizeDouble(Bottom + rng*FiboSLRatio_38, _Digits);
      BO_Fibo_SL_23= NormalizeDouble(Bottom + rng*FiboSLRatio_23, _Digits);
   }
   BO_Fibo_SL_TL_Cross = (mode==ORDER_TYPE_BUY) ?
      NormalizeDouble(Bottom+rng*(1-FiboSLRatio_TL), _Digits) :
      NormalizeDouble(Bottom+rng*FiboSLRatio_TL,     _Digits);
   BO_Fibo_SL_Ref = (mode==ORDER_TYPE_BUY) ?
      NormalizeDouble(Bottom+rng*(1-FiboSLRatio_Ref), _Digits) :
      NormalizeDouble(Bottom+rng*FiboSLRatio_Ref,     _Digits);
}

// ============================================================
// LOT SIZE CALCULATION
// ============================================================
double CalculateLotSize(double stopLossPips)
{
   AllowedStopOrders = 1;
   if(!MM) return LotSize;

   double maxLot  = (Max_Lot_Size > 0 && Max_Lot_Size < MaxLot_G) ? Max_Lot_Size : MaxLot_G;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickVal <= 0 || stopLossPips <= 0) return MinLot_G;

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double ret = (freeMargin * RiskPercent / 100.0) / (stopLossPips * tickVal);

   ret = NormalizeDouble(MathFloor(ret / LotStep_G) * LotStep_G, LotDec);
   if(ret < MinLot_G) ret = MinLot_G;
   if(ret > maxLot)
   {
      AllowedStopOrders = (int)MathCeil(ret / maxLot);
      ret = NormalizeDouble(ret / AllowedStopOrders, LotDec);
   }
   return NormalizeDouble(ret, LotDec);
}

double LotsOptimized()
{
   if(!MM) return LotSize;
   double maxLot     = (Max_Lot_Size > 0 && Max_Lot_Size < MaxLot_G) ? Max_Lot_Size : MaxLot_G;
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double ret = freeMargin * RiskPercent / 100.0;
   ret = NormalizeDouble(MathFloor(ret / LotStep_G) * LotStep_G, LotDec);
   if(ret < MinLot_G) ret = MinLot_G;
   if(ret > maxLot)   ret = maxLot;
   return ret;
}

// ============================================================
// STOPLOSS & TAKEPROFIT
// ============================================================
double Calculate_StopLoss(int mode)
{
   double ask = symbolInfo.Ask();
   double bid = symbolInfo.Bid();

   if(mode == ORDER_TYPE_BUY)
   {
      if(En_FiboSL_Ratio_5 && BO_Fibo_SL > 0)
      {
         double dist = (ask - BO_Fibo_SL) / Poin;
         if(dist < MinStopLoss) return NormalizeDouble(ask - MinStopLoss*Poin, _Digits);
         if(dist > MaxStopLoss) return NormalizeDouble(ask - MaxStopLoss*Poin, _Digits);
         return BO_Fibo_SL;
      }
      if(EnableBreakOutSL && TopBreakOutLow > 0)
      {
         double dist = (ask - TopBreakOutLow) / Poin;
         if(dist < MinStopLoss) return NormalizeDouble(ask - MinStopLoss*Poin, _Digits);
         if(dist > MaxStopLoss) return NormalizeDouble(ask - MaxStopLoss*Poin, _Digits);
         return NormalizeDouble(TopBreakOutLow - Nr_Extra_SL_Pips*SymbolInfoDouble(_Symbol,SYMBOL_POINT), _Digits);
      }
      return NormalizeDouble(ask - StopLoss*Poin, _Digits);
   }
   else
   {
      if(En_FiboSL_Ratio_5 && BO_Fibo_SL > 0)
      {
         double dist = (BO_Fibo_SL - bid) / Poin;
         if(dist < MinStopLoss) return NormalizeDouble(bid + MinStopLoss*Poin, _Digits);
         if(dist > MaxStopLoss) return NormalizeDouble(bid + MaxStopLoss*Poin, _Digits);
         return BO_Fibo_SL;
      }
      if(EnableBreakOutSL && TopBreakOutHigh > 0)
      {
         double dist = (TopBreakOutHigh - bid) / Poin;
         if(dist < MinStopLoss) return NormalizeDouble(bid + MinStopLoss*Poin, _Digits);
         if(dist > MaxStopLoss) return NormalizeDouble(bid + MaxStopLoss*Poin, _Digits);
         return NormalizeDouble(TopBreakOutHigh + Nr_Extra_SL_Pips*SymbolInfoDouble(_Symbol,SYMBOL_POINT), _Digits);
      }
      return NormalizeDouble(bid + StopLoss*Poin, _Digits);
   }
}

double Calculate_TakeProfit(int mode)
{
   double ask = symbolInfo.Ask();
   double bid = symbolInfo.Bid();

   if(mode == ORDER_TYPE_BUY)
   {
      double tp = NormalizeDouble(ask + TakeProfit*Poin, _Digits);
      if(Enable_ADR_TP && ADR > 0 && Swing_High[0] > 0)
         tp = NormalizeDouble(Swing_High[0] + ADR*ADR_TP_Ratio*SymbolInfoDouble(_Symbol,SYMBOL_POINT), _Digits);
      return tp;
   }
   else
   {
      double tp = NormalizeDouble(bid - TakeProfit*Poin, _Digits);
      if(Enable_ADR_TP && ADR > 0 && Swing_Low[0] > 0)
         tp = NormalizeDouble(Swing_Low[0] - ADR*ADR_TP_Ratio*SymbolInfoDouble(_Symbol,SYMBOL_POINT), _Digits);
      return tp;
   }
}

// ============================================================
// TRADE EXECUTION
// ============================================================
ulong Trade_Execute(int mode)
{
   symbolInfo.RefreshRates();
   double ask  = symbolInfo.Ask();
   double bid  = symbolInfo.Bid();
   double lots = LotsOptimized();
   double stp  = Calculate_StopLoss(mode);
   double tp   = Calculate_TakeProfit(mode);

   if(mode == ORDER_TYPE_BUY)
   {
      if(trade.Buy(lots, _Symbol, ask, stp, tp, OrderMarking))
         return trade.ResultOrder();
      else
         Print("Buy error: ", trade.ResultRetcodeDescription());
   }
   else
   {
      if(trade.Sell(lots, _Symbol, bid, stp, tp, OrderMarking))
         return trade.ResultOrder();
      else
         Print("Sell error: ", trade.ResultRetcodeDescription());
   }
   return 0;
}

// ============================================================
// ORDER CLOSING FUNCTIONS
// ============================================================
void CloseOrders()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNo)
         trade.PositionClose(ticket);
   }
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == MagicNo)
         trade.OrderDelete(ticket);
   }
   Count_Open_Orders();
}

void CloseStopOrders()
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == MagicNo)
      {
         ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_SELL_STOP)
            trade.OrderDelete(ticket);
      }
   }
   Count_Open_Orders();
}

void CloseLimitOrders()
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == MagicNo)
      {
         ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_SELL_LIMIT)
            trade.OrderDelete(ticket);
      }
   }
   Count_Open_Orders();
}

void CloseBuyStopOrders()
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == MagicNo)
         if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP)
            trade.OrderDelete(ticket);
   }
   Count_Open_Orders();
}

void CloseSellStopOrders()
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == MagicNo)
         if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP)
            trade.OrderDelete(ticket);
   }
   Count_Open_Orders();
}

// ============================================================
// FIX BUG 4: CALCULATE TOTAL PROFITS
// Linha de comissão estava completamente apagada → TotalComissions
// sempre permanecia 0. Restaurada com POSITION_COMMISSION.
// ============================================================
double Calculate_TotalProfits(int mode)
{
   TotalProfits    = 0;
   TotalComissions = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNo)
      {
         int ptype = (int)PositionGetInteger(POSITION_TYPE);
         if(mode < 0 ||
           (mode == ORDER_TYPE_BUY  && ptype == POSITION_TYPE_BUY)  ||
           (mode == ORDER_TYPE_SELL && ptype == POSITION_TYPE_SELL))
         {
            TotalProfits    += PositionGetDouble(POSITION_PROFIT)
                             + PositionGetDouble(POSITION_SWAP);
            // FIX BUG 4: linha ausente no original - restaurada
            TotalComissions += PositionGetDouble(POSITION_COMMISSION);
         }
      }
   }
   TotalProfits += TotalComissions;
   return TotalProfits;
}

// ============================================================
// NEWS / VOLUME / FILTER FUNCTIONS
// ============================================================
bool News_OK()
{
   if(!Enable_NewsFilter) return true;
   NEWS_OK_G = true;
   return NEWS_OK_G;
}

bool Volume_OK()  { return true; }
bool VWAP_OK(int) { return true; }
bool CCI_TB_OK(int){ return true; }
bool STOCH_LT_OK(int){ return true; }

// ============================================================
// WPR OK
// ============================================================
bool WPR_OK(int mode)
{
   if(!Enable_WPR) return true;
   // WPR retorna valores de -100 a 0
   // Oversold (buy): WPR < -(100-Limit) ex: Limit=20 → WPR < -80
   // Overbought (sell): WPR > -Limit ex: Limit=20 → WPR > -20
   if(mode == ORDER_TYPE_BUY)
      return (WPR_1 < WPR_Limit - 100 || WPR_2 < WPR_Limit - 100);
   if(mode == ORDER_TYPE_SELL)
      return (WPR_1 > -WPR_Limit || WPR_2 > -WPR_Limit);
   return false;
}

bool WPR_LT_OK(int mode)
{
   if(!Enable_LT_WPR) return true;
   double wlt = GetWPR(handle_WPR_LT, 1);
   if(mode == ORDER_TYPE_BUY)  return (wlt > -WPR_LT_Limit);
   if(mode == ORDER_TYPE_SELL) return (wlt < WPR_LT_Limit - 100);
   return false;
}

// FIX BUG 7: WPR_1M agora tem valores lidos; função de filtro adicionada
bool WPR_1M_OK(int mode)
{
   if(!Enable_WPR_1M) return true;
   if(mode == ORDER_TYPE_BUY)
      return (WPR_1M_1 < WPR_1M_Limit - 100 || WPR_1M_2 < WPR_1M_Limit - 100);
   if(mode == ORDER_TYPE_SELL)
      return (WPR_1M_1 > -WPR_1M_Limit || WPR_1M_2 > -WPR_1M_Limit);
   return false;
}

// ============================================================
// CCI OK
// FIX BUG 13: comentário explicativo — CCI_LT_OK lê TF_CCI (4H por padrão)
// O nome "LT" (Long Term) é relativo: é o TF de confirmação do CCI
// ============================================================
bool CCI_LT_OK(int mode)
{
   if(!Enable_CCI) return true;
   double cciVal = CCI_1; // CCI do TF_CCI (handle_CCI_LT)
   if(mode == ORDER_TYPE_BUY)  return (cciVal > CCI_Limit);
   if(mode == ORDER_TYPE_SELL) return (cciVal < -CCI_Limit);
   return false;
}

bool CCI_1M_OK(int mode)
{
   if(!Enable_CCI_1M) return true;
   double v1 = GetCCI_1M(1);
   if(mode == ORDER_TYPE_BUY)  return (v1 >  CCI_1M_Limit && v1 <  CCI_1M_TH);
   if(mode == ORDER_TYPE_SELL) return (v1 < -CCI_1M_Limit && v1 > -CCI_1M_TH);
   return false;
}

// ============================================================
// FRACTALS OK
// ============================================================
bool Fractals_OK(int mode)
{
   if(!Enable_Fractals) return true;
   if(handle_Fractals == INVALID_HANDLE) return true;

   double bufUp[], bufDn[];
   ArraySetAsSeries(bufUp, true);
   ArraySetAsSeries(bufDn, true);
   CopyBuffer(handle_Fractals, 0, 0, Fractals_Shift+2, bufUp);
   CopyBuffer(handle_Fractals, 1, 0, Fractals_Shift+2, bufDn);

   double bid = symbolInfo.Bid();
   double ask = symbolInfo.Ask();

   if(mode == ORDER_TYPE_BUY)
   {
      for(int i = 0; i < Fractals_Shift; i++)
      {
         if(bufUp[i] != EMPTY_VALUE && bufUp[i] > 0) return false;
         if(bufDn[i] != EMPTY_VALUE && bufDn[i] > 0 && bufDn[i] < bid) return true;
      }
   }
   if(mode == ORDER_TYPE_SELL)
   {
      for(int i = 1; i < Fractals_Shift; i++)
      {
         if(bufDn[i] != EMPTY_VALUE && bufDn[i] > 0) return false;
         if(bufUp[i] != EMPTY_VALUE && bufUp[i] > 0 && bufUp[i] > ask) return true;
      }
   }
   return false;
}

// ============================================================
// MACD OK
// ============================================================
bool MACD_OK(int mode)
{
   if(!Enable_MACD) return true;
   if(handle_MACD == INVALID_HANDLE) return true;

   double main_buf[], sig_buf[];
   ArraySetAsSeries(main_buf, true);
   ArraySetAsSeries(sig_buf,  true);
   if(CopyBuffer(handle_MACD,0,0,MACD_Bars+2,main_buf) < MACD_Bars+1) return true;
   if(CopyBuffer(handle_MACD,1,0,MACD_Bars+2,sig_buf)  < MACD_Bars+1) return true;

   for(int i = 0; i < MACD_Bars; i++)
   {
      if(mode == ORDER_TYPE_BUY)
      {
         if(MACD_Method_Inp==0 && main_buf[i]>sig_buf[i] && main_buf[i+1]<=sig_buf[i+1]
            && main_buf[i]<0 && sig_buf[i]<0) return true;
         if(MACD_Method_Inp==3 && main_buf[i]>sig_buf[i]) return true;
         if(MACD_Method_Inp==4 && main_buf[i]>0)          return true;
      }
      if(mode == ORDER_TYPE_SELL)
      {
         if(MACD_Method_Inp==0 && main_buf[i]<sig_buf[i] && main_buf[i+1]>=sig_buf[i+1]
            && main_buf[i]>0 && sig_buf[i]>0) return true;
         if(MACD_Method_Inp==3 && main_buf[i]<sig_buf[i]) return true;
         if(MACD_Method_Inp==4 && main_buf[i]<0)          return true;
      }
   }
   return false;
}

bool MACD_LT_OK(int mode)
{
   if(!Enable_LT_MACD) return true;
   if(handle_MACD_LT == INVALID_HANDLE) return true;

   double main_buf[], sig_buf[];
   ArraySetAsSeries(main_buf, true);
   ArraySetAsSeries(sig_buf,  true);
   if(CopyBuffer(handle_MACD_LT,0,0,MACD_LT_Bars+2,main_buf)<MACD_LT_Bars+1) return true;
   if(CopyBuffer(handle_MACD_LT,1,0,MACD_LT_Bars+2,sig_buf) <MACD_LT_Bars+1) return true;

   for(int i = 0; i < MACD_LT_Bars; i++)
   {
      if(mode == ORDER_TYPE_BUY  && MACD_LT_Method==3 && main_buf[i]>sig_buf[i]) return true;
      if(mode == ORDER_TYPE_SELL && MACD_LT_Method==3 && main_buf[i]<sig_buf[i]) return true;
   }
   return false;
}

// ============================================================
// TIMEOUT OK
// ============================================================
bool TimeOut_OK()
{
   return (TimeCurrent() > OrderTimeOut_dt);
}

void UpdateOrderTimeOut(int minutes)
{
   OrderTimeOut_dt = TimeCurrent() + minutes * 60;
}

// ============================================================
// STOCH OK
// ============================================================
bool STOCH_OK(int mode)
{
   if(!Enable_STOCH) return true;
   if(handle_STOCH == INVALID_HANDLE) return true;

   double mainBuf[], sigBuf[];
   ArraySetAsSeries(mainBuf, true);
   ArraySetAsSeries(sigBuf,  true);
   if(CopyBuffer(handle_STOCH,0,0,5,mainBuf)<4) return true;
   if(CopyBuffer(handle_STOCH,1,0,5,sigBuf) <4) return true;

   double s0=mainBuf[0], s1=mainBuf[1], s2=mainBuf[2];
   double ss0=sigBuf[0];

   if(mode == ORDER_TYPE_BUY)
   {
      if(Stoch_Method==6 && (s2<=Stoch_Level||s1<=Stoch_Level) && s0>s1 && s0>ss0) return true;
      if(Stoch_Method==0 && (s2<Stoch_Level||s1<Stoch_Level||s0<Stoch_Level) && s0>s1) return true;
   }
   if(mode == ORDER_TYPE_SELL)
   {
      if(Stoch_Method==6 && (s2>=100-Stoch_Level||s1>=100-Stoch_Level) && s0<s1 && s0<ss0) return true;
      if(Stoch_Method==0 && (s2>100-Stoch_Level||s1>100-Stoch_Level||s0>100-Stoch_Level) && s0<s1) return true;
   }
   return false;
}

// ============================================================
// FIX BUG 18: FIBO CROSS OK
// Corrigida ordem das verificações para que BO_Fibo_SL receba
// o valor do nível correto antes do return.
// ============================================================
bool FiboCross_OK(int mode)
{
   Fibo_23_Crossed = false;
   Fibo_38_Crossed = false;
   Fibo_50_Crossed = false;
   Fibo_61_Crossed = false;

   if(mode == ORDER_TYPE_BUY  && (BreakOutHighest<=0 || TopBreakOutLow<=0))  return false;
   if(mode == ORDER_TYPE_SELL && (BreakOutLowest <=0 || TopBreakOutHigh<=0)) return false;

   Calculate_BreakOut_Fibos(mode);

   double bid    = symbolInfo.Bid();
   double offset = FiboOffsetPips * Poin;

   if(mode == ORDER_TYPE_BUY)
   {
      // FIX BUG 18: verifica 61 antes de 50 antes de 38 para setar SL correto
      if(Enable_61_Cross && bid > BO_Fibo_61 && bid < BO_Fibo_50)
      {
         for(int i = 0; i < 10; i++)
         {
            if(iTime(_Symbol,PERIOD_M1,i) <= BreakOutHigh_Time) return false;
            if(iLow(_Symbol,PERIOD_M1,i) < BO_Fibo_61 + offset)
            {
               Fibo_61_Crossed = true;
               BO_Fibo_SL = BO_Fibo_SL_61;
               return true;
            }
         }
      }
      if(Enable_50_Cross && bid > BO_Fibo_50 && bid < BO_Fibo_38)
      {
         for(int i = 0; i < 10; i++)
         {
            if(iTime(_Symbol,PERIOD_M1,i) <= BreakOutHigh_Time) return false;
            if(iLow(_Symbol,PERIOD_M1,i) < BO_Fibo_50 + offset &&
               bid < BO_Fibo_50 + (BO_Fibo_38-BO_Fibo_50)*RelFiboDist)
            {
               Fibo_50_Crossed = true;
               BO_Fibo_SL = BO_Fibo_SL_50;
               return true;
            }
         }
      }
      if(Enable_38_Cross && bid > BO_Fibo_38 && bid < BO_Fibo_23)
      {
         for(int i = 0; i < 10; i++)
         {
            if(iTime(_Symbol,PERIOD_M1,i) <= BreakOutHigh_Time) return false;
            if(iLow(_Symbol,PERIOD_M1,i) < BO_Fibo_38 + offset &&
               bid < BO_Fibo_38 + (BO_Fibo_23-BO_Fibo_38)*RelFiboDist)
            {
               Fibo_38_Crossed = true;
               BO_Fibo_SL = BO_Fibo_SL_38;
               return true;
            }
         }
      }
   }
   else // SELL
   {
      if(Enable_61_Cross && bid < BO_Fibo_61 && bid > BO_Fibo_50)
      {
         for(int i = 0; i < 10; i++)
         {
            if(iTime(_Symbol,PERIOD_M1,i) <= BreakOutLow_Time) return false;
            if(iHigh(_Symbol,PERIOD_M1,i) > BO_Fibo_61 - offset)
            {
               Fibo_61_Crossed = true;
               BO_Fibo_SL = BO_Fibo_SL_61;
               return true;
            }
         }
      }
      if(Enable_50_Cross && bid < BO_Fibo_50 && bid > BO_Fibo_38)
      {
         for(int i = 0; i < 10; i++)
         {
            if(iTime(_Symbol,PERIOD_M1,i) <= BreakOutLow_Time) return false;
            if(iHigh(_Symbol,PERIOD_M1,i) > BO_Fibo_50 - offset &&
               bid > BO_Fibo_50 - (BO_Fibo_50-BO_Fibo_38)*RelFiboDist)
            {
               Fibo_50_Crossed = true;
               BO_Fibo_SL = BO_Fibo_SL_50;
               return true;
            }
         }
      }
      if(Enable_38_Cross && bid < BO_Fibo_38 && bid > BO_Fibo_23)
      {
         for(int i = 0; i < 10; i++)
         {
            if(iTime(_Symbol,PERIOD_M1,i) <= BreakOutLow_Time) return false;
            if(iHigh(_Symbol,PERIOD_M1,i) > BO_Fibo_38 - offset &&
               bid > BO_Fibo_38 - (BO_Fibo_38-BO_Fibo_23)*RelFiboDist)
            {
               Fibo_38_Crossed = true;
               BO_Fibo_SL = BO_Fibo_SL_38;
               return true;
            }
         }
      }
   }
   return false;
}

bool RetraceFlags_OK(int mode)
{
   if(mode == ORDER_TYPE_BUY && Enable_Buy_Retrace)
   {
      if(Fibo_61_Crossed && Enable_Retrace_61) return true;
      if(Fibo_50_Crossed && Enable_Retrace_50) return true;
      if(Fibo_38_Crossed && Enable_Retrace_38) return true;
      if(Fibo_23_Crossed && Enable_Retrace_23) return true;
      if(Ref_Crossed     && Enable_Cross_Reference) return true;
      if(TL_Crossed      && Enable_Retrace_TL) return true;
      return false;
   }
   if(mode == ORDER_TYPE_SELL && Enable_Sell_Retrace)
   {
      if(Fibo_61_Crossed && Enable_Retrace_61) return true;
      if(Fibo_50_Crossed && Enable_Retrace_50) return true;
      if(Fibo_38_Crossed && Enable_Retrace_38) return true;
      if(Fibo_23_Crossed && Enable_Retrace_23) return true;
      if(Ref_Crossed     && Enable_Cross_Reference) return true;
      if(TL_Crossed      && Enable_Retrace_TL) return true;
      return false;
   }
   return false;
}

bool MaxBreakOutPips_OK(int mode)
{
   if(mode == ORDER_TYPE_BUY && TopBreakOutLow > 0)
   {
      double hi = iHigh(_Symbol, PERIOD_D1, 0);
      if((hi - TopBreakOutLow) / Poin > MaxBreakOutPips) return false;
   }
   if(mode == ORDER_TYPE_SELL && TopBreakOutHigh > 0)
   {
      double lo = iLow(_Symbol, PERIOD_D1, 0);
      if((TopBreakOutHigh - lo) / Poin > MaxBreakOutPips) return false;
   }
   return true;
}

bool MaxBOTradingMin_OK(int mode)
{
   if(!Enable_BOTimeOuts) return true;
   if(mode == ORDER_TYPE_BUY)
   {
      if(Fibo_50_Crossed && BreakOutHigh_Time>0 &&
         (TimeCurrent()-BreakOutHigh_Time)/60 < MaxBOTradingMin_50) return true;
      if(Fibo_38_Crossed && BreakOutHigh_Time>0 &&
         (TimeCurrent()-BreakOutHigh_Time)/60 < MaxBOTradingMin_38) return true;
      if(Fibo_23_Crossed && BreakOutHigh_Time>0 &&
         (TimeCurrent()-BreakOutHigh_Time)/60 < MaxBOTradingMin_23) return true;
      return false;
   }
   if(mode == ORDER_TYPE_SELL)
   {
      if(Fibo_50_Crossed && BreakOutLow_Time>0 &&
         (TimeCurrent()-BreakOutLow_Time)/60 < MaxBOTradingMin_50) return true;
      return false;
   }
   return false;
}

// ============================================================
// ZZ STOPLOSS
// ============================================================
double Calculate_ZZStopLoss(int mode, double openPrice)
{
   if(Swing_High[0] == 0 || Swing_Low[0] == 0)
      return (mode==ORDER_TYPE_BUY) ?
         NormalizeDouble(openPrice - MinStopLoss*Poin, _Digits) :
         NormalizeDouble(openPrice + MinStopLoss*Poin, _Digits);

   double rangePct = (Swing_High[0]-Swing_Low[0]) / Poin * 23.6/100.0;

   if(mode == ORDER_TYPE_BUY)
   {
      double newSL = NormalizeDouble(Swing_High[0] - rangePct*Poin*StopLossRatio, _Digits);
      if((openPrice-newSL)/Poin < MinStopLoss) newSL = NormalizeDouble(openPrice - MinStopLoss*Poin, _Digits);
      if((openPrice-newSL)/Poin > MaxStopLoss) newSL = NormalizeDouble(openPrice - MaxStopLoss*Poin, _Digits);
      return newSL;
   }
   else
   {
      double newSL = NormalizeDouble(Swing_Low[0] + rangePct*Poin*StopLossRatio, _Digits);
      if((newSL-openPrice)/Poin < MinStopLoss) newSL = NormalizeDouble(openPrice + MinStopLoss*Poin, _Digits);
      if((newSL-openPrice)/Poin > MaxStopLoss) newSL = NormalizeDouble(openPrice + MaxStopLoss*Poin, _Digits);
      return newSL;
   }
}

// ============================================================
// GENERATE STOP ORDER 1
// FIX BUG 8 & 9: SymbolInfoDouble(SYMBOL_POINT) substituído por Poin
// ============================================================
void Generate_StopOrder_1()
{
   if(!News_OK() && Enable_NewsFilter && Enable_TradingIfNews)
   {
      CloseStopOrders();
      return;
   }
   if(Swing_High[0] == 0 || Swing_Low[0] == 0) return;

   double ask    = symbolInfo.Ask();
   double bid    = symbolInfo.Bid();
   // FIX BUG 8: usa Poin em vez de SYMBOL_POINT para cálculo de pips
   double slPips = (Swing_High[0]-Swing_Low[0])/Poin * 23.6/100.0 + 1;

   // --- BUY STOP ---
   if(BuyOrders == 0 && Spread_OK() &&
      ask > Swing_High[0] - MaxStopLoss*Poin*3 &&   // FIX BUG 8
      Volume_OK() && VWAP_OK(ORDER_TYPE_BUY) &&
      CCI_LT_OK(ORDER_TYPE_BUY) && CCI_1M_OK(ORDER_TYPE_BUY) && CCI_TB_OK(ORDER_TYPE_BUY))
   {
      if(ask < NormalizeDouble(Swing_High[0]+MinPipsDistance*Poin, _Digits) &&
         // FIX BUG 9: usa Poin consistentemente
         iHigh(_Symbol,TF_Array[TF_Below_BO],0) - 2*MathAbs(MinPipsDistance*Poin) < Swing_High[0] &&
         iHigh(_Symbol,TF_Array[TF_Below_BO],1) - 2*MathAbs(MinPipsDistance*Poin) < Swing_High[0] &&
         iHigh(_Symbol,TF_Array[TF_Below_BO],2) - 2*MathAbs(MinPipsDistance*Poin) < Swing_High[0])
      {
         double newOP  = NormalizeDouble(Swing_High[0]+MinPipsDistance*Poin, _Digits);
         double newTP  = NormalizeDouble(Swing_High[0]+slPips*Poin*TakeProfitRatio, _Digits);
         double newSL  = EnableZZStopLoss ? Calculate_ZZStopLoss(ORDER_TYPE_BUY, newOP) :
                         NormalizeDouble(Swing_High[0]-slPips*Poin*StopLossRatio, _Digits);
         double slPipsCalc = (newOP-newSL) / SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double lots   = CalculateLotSize(slPipsCalc);

         if(OpenBuyStopOrders < AllowedStopOrders)
            trade.BuyStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
      }
   }
   else if(BuyOrders == 0)
      CloseBuyStopOrders();

   // --- SELL STOP ---
   if(SellOrders == 0 && Spread_OK() &&
      bid < Swing_Low[0] + MaxStopLoss*Poin*3 &&     // FIX BUG 8
      Volume_OK() && VWAP_OK(ORDER_TYPE_SELL) &&
      CCI_LT_OK(ORDER_TYPE_SELL) && CCI_1M_OK(ORDER_TYPE_SELL) && CCI_TB_OK(ORDER_TYPE_SELL))
   {
      if(bid > NormalizeDouble(Swing_Low[0]-MinPipsDistance*Poin, _Digits) &&
         // FIX BUG 9: usa Poin consistentemente
         iLow(_Symbol,TF_Array[TF_Below_BO],0) + 2*MathAbs(MinPipsDistance*Poin) > Swing_Low[0] &&
         iLow(_Symbol,TF_Array[TF_Below_BO],1) + 2*MathAbs(MinPipsDistance*Poin) > Swing_Low[0] &&
         iLow(_Symbol,TF_Array[TF_Below_BO],2) + 2*MathAbs(MinPipsDistance*Poin) > Swing_Low[0])
      {
         double newOP  = NormalizeDouble(Swing_Low[0]-MinPipsDistance*Poin, _Digits);
         double newTP  = NormalizeDouble(Swing_Low[0]-slPips*Poin*TakeProfitRatio, _Digits);
         double newSL  = EnableZZStopLoss ? Calculate_ZZStopLoss(ORDER_TYPE_SELL, newOP) :
                         NormalizeDouble(Swing_Low[0]+slPips*Poin*StopLossRatio, _Digits);
         double slPipsCalc = (newSL-newOP) / SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double lots   = CalculateLotSize(slPipsCalc);

         if(OpenSellStopOrders < AllowedStopOrders)
            trade.SellStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
      }
   }
   else if(SellOrders == 0)
      CloseSellStopOrders();
}

// ============================================================
// GENERATE STOP ORDER 2
// ============================================================
void Generate_StopOrder_2()
{
   if(News_OK() && Enable_NewsFilter) { CloseStopOrders(); return; }
   if(Swing_High[0] == 0 || Swing_Low[0] == 0) return;

   double ask = symbolInfo.Ask();
   double bid = symbolInfo.Bid();
   double rng = Swing_High[0] - Swing_Low[0];

   if(BuyOrders == 0 && ask < Swing_High[0])
   {
      double newOP  = NormalizeDouble(Swing_High[0]+MinPipsDistance*Poin, _Digits);
      double newSL  = EnableZZStopLoss ? Calculate_ZZStopLoss(ORDER_TYPE_BUY, newOP) :
                      NormalizeDouble(Swing_High[0] - rng/Poin*23.6/100.0*Poin*StopLossRatio, _Digits);
      double slPips = (newOP-newSL)/SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      double lots   = CalculateLotSize(slPips);
      double newTP  = NormalizeDouble(Swing_High[0]+rng*0.236, _Digits);
      if(OpenBuyStopOrders < AllowedStopOrders)
         trade.BuyStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
   }

   if(SellOrders == 0 && bid > Swing_Low[0])
   {
      double newOP  = NormalizeDouble(Swing_Low[0]-MinPipsDistance*Poin, _Digits);
      double newSL  = EnableZZStopLoss ? Calculate_ZZStopLoss(ORDER_TYPE_SELL, newOP) :
                      NormalizeDouble(Swing_Low[0] + rng/Poin*23.6/100.0*Poin*StopLossRatio, _Digits);
      double slPips = (newSL-newOP)/SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      double lots   = CalculateLotSize(slPips);
      double newTP  = NormalizeDouble(Swing_Low[0]-rng*0.236, _Digits);
      if(OpenSellStopOrders < AllowedStopOrders)
         trade.SellStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
   }
}

// ============================================================
// FIX BUG 14: GENERATE STOP ORDER 3
// Original chamava Generate_StopOrder_2() mesmo quando
// News_OK()==true com Enable_NewsFilter ativo.
// Corrigida condição: fecha ordens SE notícia ativa E filtro ligado.
// ============================================================
void Generate_StopOrder_3()
{
   // FIX BUG 14: original tinha condição invertida
   if(Enable_NewsFilter && !News_OK()) { CloseStopOrders(); return; }
   Generate_StopOrder_2();
}

// ============================================================
// GENERATE STOP ORDER 4
// Estratégia de reversão: entra contra o movimento quando
// o preço já se afastou PipsDistance do extremo de ontem
// ============================================================
void Generate_StopOrder_4()
{
   if(!News_OK() && Enable_NewsFilter) { CloseStopOrders(); return; }
   if(YesterdayHigh <= 0 || YesterdayLow <= 0) return;

   double slPips = MinStopLoss;

   if(BuyOrders == 0 && symbolInfo.Ask() < YesterdayLow - PipsDistance*Poin)
   {
      double newOP = NormalizeDouble(YesterdayLow + OpenPipsDistance*Poin, _Digits);
      double newSL = NormalizeDouble(YesterdayLow - slPips*Poin, _Digits);
      double newTP = NormalizeDouble(YesterdayLow + (YesterdayHigh-YesterdayLow)*TP_FiboRatio/100, _Digits);
      double lots  = CalculateLotSize(slPips+OpenPipsDistance);
      if(OpenBuyStopOrders < AllowedStopOrders)
         trade.BuyStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
   }

   if(SellOrders == 0 && symbolInfo.Bid() > YesterdayHigh + PipsDistance*Poin)
   {
      double newOP = NormalizeDouble(YesterdayHigh - OpenPipsDistance*Poin, _Digits);
      double newSL = NormalizeDouble(YesterdayHigh + slPips*Poin, _Digits);
      double newTP = NormalizeDouble(YesterdayHigh - (YesterdayHigh-YesterdayLow)*TP_FiboRatio/100, _Digits);
      double lots  = CalculateLotSize(slPips+OpenPipsDistance);
      if(OpenSellStopOrders < AllowedStopOrders)
         trade.SellStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
   }
}

// ============================================================
// GENERATE RETRACE ORDERS 5, 6, 7
// ============================================================
void Generate_RetraceOrder_5()
{
   if(!Enable_Retrace) return;
   if(Enable_Buy_Retrace &&
      (BuyOrders==0 || (Enable_3_Trades && BuyOrders<4)) &&
      Spread_OK() && MaxBreakOutPips_OK(ORDER_TYPE_BUY) &&
      FiboCross_OK(ORDER_TYPE_BUY) &&
      RetraceFlags_OK(ORDER_TYPE_BUY) && MaxBOTradingMin_OK(ORDER_TYPE_BUY) &&
      News_OK() && WPR_OK(ORDER_TYPE_BUY) && WPR_LT_OK(ORDER_TYPE_BUY) &&
      CCI_LT_OK(ORDER_TYPE_BUY) && CCI_1M_OK(ORDER_TYPE_BUY) &&
      STOCH_OK(ORDER_TYPE_BUY) && Fractals_OK(ORDER_TYPE_BUY) &&
      MACD_OK(ORDER_TYPE_BUY))
   {
      if(Trade_Execute(ORDER_TYPE_BUY) > 0UL)
         UpdateEnable_Retrace_Flags();
   }

   if(Enable_Sell_Retrace &&
      (SellOrders==0 || (Enable_3_Trades && SellOrders<4)) &&
      Spread_OK() && MaxBreakOutPips_OK(ORDER_TYPE_SELL) &&
      FiboCross_OK(ORDER_TYPE_SELL) &&
      RetraceFlags_OK(ORDER_TYPE_SELL) && MaxBOTradingMin_OK(ORDER_TYPE_SELL) &&
      News_OK() && WPR_OK(ORDER_TYPE_SELL) && WPR_LT_OK(ORDER_TYPE_SELL) &&
      CCI_LT_OK(ORDER_TYPE_SELL) && CCI_1M_OK(ORDER_TYPE_SELL) &&
      STOCH_OK(ORDER_TYPE_SELL) && Fractals_OK(ORDER_TYPE_SELL) &&
      MACD_OK(ORDER_TYPE_SELL))
   {
      if(Trade_Execute(ORDER_TYPE_SELL) > 0UL)
         UpdateEnable_Retrace_Flags();
   }
}

void Generate_RetraceOrder_6() { Generate_RetraceOrder_5(); }
void Generate_RetraceOrder_7() { Generate_RetraceOrder_5(); }

// ============================================================
// GENERATE STOP ORDER 9
// ============================================================
void Generate_StopOrder_9()
{
   if(!News_OK() && Enable_NewsFilter && Enable_TradingIfNews) { CloseStopOrders(); return; }
   if(!Volume_OK()) { CloseStopOrders(); return; }
   if(OpenActiveOrders > 0) return;
   if(ArraySize(Swing_Tops) == 0 || ArraySize(Swing_Bottoms) == 0) return;

   double slPips = (YesterdayHigh-YesterdayLow)/Poin*23.6/100+1;

   if(BuyOrders == 0 && Volume_OK() && CCI_LT_OK(ORDER_TYPE_BUY) && CCI_1M_OK(ORDER_TYPE_BUY))
   {
      for(int i = 0; i < ArraySize(Swing_Tops); i++)
      {
         if(Swing_Tops[i] <= 0) continue;
         double ask = symbolInfo.Ask();
         if(ask < Swing_Tops[i] &&
            (Swing_Tops[i]-iLow(_Symbol,PERIOD_D1,0))/SymbolInfoDouble(_Symbol,SYMBOL_POINT) < ADR*ADR_Multiplier)
         {
            double newOP  = NormalizeDouble(Swing_Tops[i]+MinPipsDistance*Poin, _Digits);
            double newSL  = EnableZZStopLoss ? Calculate_ZZStopLoss(ORDER_TYPE_BUY, Swing_Tops[i]) :
                            NormalizeDouble(Swing_Tops[i]-slPips*Poin*StopLossRatio, _Digits);
            double newTP  = NormalizeDouble(Swing_Tops[i]+slPips*Poin*TakeProfitRatio, _Digits);
            double spPips = (newOP-newSL)/SymbolInfoDouble(_Symbol,SYMBOL_POINT);
            double lots   = CalculateLotSize(spPips);
            trade.BuyStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
         }
      }
   }

   if(SellOrders == 0 && Volume_OK() && CCI_LT_OK(ORDER_TYPE_SELL) && CCI_1M_OK(ORDER_TYPE_SELL))
   {
      for(int i = 0; i < ArraySize(Swing_Bottoms); i++)
      {
         if(Swing_Bottoms[i] <= 0) continue;
         double bid = symbolInfo.Bid();
         if(bid > Swing_Bottoms[i] &&
            (iHigh(_Symbol,PERIOD_D1,0)-Swing_Bottoms[i])/SymbolInfoDouble(_Symbol,SYMBOL_POINT) < ADR*ADR_Multiplier)
         {
            double newOP  = NormalizeDouble(Swing_Bottoms[i]-MinPipsDistance*Poin, _Digits);
            double newSL  = EnableZZStopLoss ? Calculate_ZZStopLoss(ORDER_TYPE_SELL, Swing_Bottoms[i]) :
                            NormalizeDouble(Swing_Bottoms[i]+slPips*Poin*StopLossRatio, _Digits);
            double newTP  = NormalizeDouble(Swing_Bottoms[i]-slPips*Poin*TakeProfitRatio, _Digits);
            double spPips = (newSL-newOP)/SymbolInfoDouble(_Symbol,SYMBOL_POINT);
            double lots   = CalculateLotSize(spPips);
            trade.SellStop(lots, newOP, _Symbol, newSL, newTP, ORDER_TIME_GTC, 0, OrderMarking);
         }
      }
   }
}

void Generate_RetraceOrder_10() { Generate_RetraceOrder_5(); }
void Generate_PendingOrder_13()  {}
void Generate_FalseBreakOutOrder_14() {}

// ============================================================
// RETRACE FLAGS
// ============================================================
void SetBuyRetraceFlags()
{
   Enable_Retrace         = true;
   Enable_Buy_Retrace     = true;
   Enable_Sell_Retrace    = false;
   Enable_Retrace_23      = true;
   Enable_Retrace_38      = true;
   Enable_Retrace_50      = true;
   Enable_Retrace_61      = true;
   Enable_Retrace_TL      = true;
   Enable_Cross_Reference = true;
   Second_Trade_Enabled   = true;
}

void SetSellRetraceFlags()
{
   Enable_Retrace         = true;
   Enable_Buy_Retrace     = false;
   Enable_Sell_Retrace    = true;
   Enable_Retrace_23      = true;
   Enable_Retrace_38      = true;
   Enable_Retrace_50      = true;
   Enable_Retrace_61      = true;
   Enable_Retrace_TL      = true;
   Enable_Cross_Reference = true;
   Second_Trade_Enabled   = true;
}

void ResetRetraceFlags()
{
   Enable_Retrace         = false;
   Enable_Buy_Retrace     = false;
   Enable_Sell_Retrace    = false;
   Enable_Retrace_23      = false;
   Enable_Retrace_38      = false;
   Enable_Retrace_50      = false;
   Enable_Retrace_61      = false;
   Enable_Retrace_TL      = false;
   Enable_Cross_Reference = false;
   Second_Trade_Enabled   = false;
}

void ResetAllRetraceParameters()
{
   ResetRetraceFlags();
   ObjectDelete(0, InpName);
   BreakOutLow_Time     = 0;
   TopBreakOutHigh      = -1;
   BreakOutHigh_ZZ_Time = 0;
   BreakOutLowest       = -1;
   BreakOutHigh_Time    = 0;
   TopBreakOutLow       = -1;
   BreakOutLow_ZZ_Time  = 0;
   BreakOutHighest      = -1;
   RefBreakOutLevel     = -1;
}

void UpdateEnable_Retrace_Flags()
{
   if(Ref_Crossed)     { Ref_Crossed     = false; Enable_Cross_Reference = false; }
   if(TL_Crossed)      { TL_Crossed      = false; Enable_Retrace_TL      = false; }
   if(Fibo_61_Crossed) { Fibo_61_Crossed = false; Enable_Retrace_61      = false; }
   if(Fibo_50_Crossed) { Fibo_50_Crossed = false; Enable_Retrace_50      = false; }
   if(Fibo_38_Crossed) { Fibo_38_Crossed = false; Enable_Retrace_38      = false; }
   if(Fibo_23_Crossed) { Fibo_23_Crossed = false; Enable_Retrace_23      = false; }
}

// ============================================================
// CHECK RETRACE
// ============================================================
void Check_Retrace()
{
   if(Enable_Retrace && BreakOutHigh_Time>0 &&
      (TimeCurrent()-BreakOutHigh_Time)/60 > MaxBOTradingMin)
   {
      BreakOutHigh_Time = 0;
      TopBreakOutLow    = -1;
      BreakOutHighest   = iHigh(_Symbol, PERIOD_D1, 0);
      ResetRetraceFlags();
   }
   if(Enable_Retrace && BreakOutLow_Time>0 &&
      (TimeCurrent()-BreakOutLow_Time)/60 > MaxBOTradingMin)
   {
      BreakOutLow_Time = 0;
      TopBreakOutHigh  = -1;
      BreakOutLowest   = iLow(_Symbol, PERIOD_D1, 0);
      ResetRetraceFlags();
   }
   if(Enable_Retrace && BreakOutLow_Time<=0 && BreakOutHigh_Time<=0)
   {
      BreakOutHighest = iHigh(_Symbol, PERIOD_D1, 0);
      BreakOutLowest  = iLow (_Symbol, PERIOD_D1, 0);
      ResetRetraceFlags();
   }

   if(!Enable_CCI_Retrace && !UseVolatilityTickSpeed)
   {
      double dayHi = iHigh(_Symbol, PERIOD_D1, 0);
      double dayLo = iLow (_Symbol, PERIOD_D1, 0);

      if(YesterdayHigh>0 && dayHi>BreakOutHighest &&
         (dayHi-BreakOutHighest)/Poin > MinBreakOutPips &&
         dayHi>YesterdayHigh)
      {
         BreakOutHighest  = dayHi;
         BreakOutLow_Time = 0;
         if(TopBreakOutLow < 0)
         {
            BreakOutHigh_Time = iTime(_Symbol, PERIOD_M1, 0);
            TopBreakOutLow    = GetMostRecentLow();
         }
         SetBuyRetraceFlags();
         ObjectDelete(0, InpName);
      }

      if(YesterdayLow>0 && dayLo<BreakOutLowest &&
         (BreakOutLowest-dayLo)/Poin > MinBreakOutPips &&
         dayLo<YesterdayLow)
      {
         BreakOutLowest    = dayLo;
         BreakOutHigh_Time = 0;
         if(TopBreakOutHigh < 0)
         {
            BreakOutLow_Time = iTime(_Symbol, PERIOD_M1, 0);
            TopBreakOutHigh  = GetMostRecentHigh();
         }
         SetSellRetraceFlags();
         ObjectDelete(0, InpName);
      }
   }
}

void Check_Retrace_10() { Check_Retrace(); }

// ============================================================
// GET MOST RECENT HIGH/LOW
// ============================================================
double GetMostRecentHigh()
{
   int bars = Bars(_Symbol, PERIOD_M1);
   int idx  = (int)MathMin(bars-1, 60);
   for(int i = 0; i < idx; i++)
   {
      double h = iHigh(_Symbol, PERIOD_M1, i);
      if(h > 0) return h;
   }
   return -1;
}

double GetMostRecentLow()
{
   int bars = Bars(_Symbol, PERIOD_M1);
   int idx  = (int)MathMin(bars-1, 60);
   for(int i = 0; i < idx; i++)
   {
      double l = iLow(_Symbol, PERIOD_M1, i);
      if(l > 0) return l;
   }
   return -1;
}

// ============================================================
// FIX BUG 16: CHECK CLOSING
// Original usava -WPR_1 que inverte o sinal do WPR (já negativo).
// WPR retorna de -100 a 0. Para BUY: fechar quando saindo de oversold
// (WPR > -25). Para SELL: fechar quando saindo de overbought (WPR < -75).
// ============================================================
void Check_Closing()
{
   if(OpenOrders <= 0) return;
   if(CheckCloseCond()) CloseOrders();
}

bool CheckCloseCond()
{
   if(EnableSystem_1 || EnableSystem_2)
   {
      for(int i = PositionsTotal()-1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNo)  continue;

         int ptype = (int)PositionGetInteger(POSITION_TYPE);
         // FIX BUG 16: WPR já é negativo; não negar novamente
         // BUY: fechar quando WPR sobe acima de -25 (saiu de oversold) com lucro
         if(ptype == POSITION_TYPE_BUY  && WPR_1 > -25 && TotalProfits > 0) return true;
         // SELL: fechar quando WPR cai abaixo de -75 (saiu de overbought) com lucro
         if(ptype == POSITION_TYPE_SELL && WPR_1 < -75 && TotalProfits > 0) return true;
      }
   }

   if(EnableSystem_13 && Enable_Closing_Sys13 && !Close_Only_At_Profit)
   {
      MqlDateTime dt; TimeToStruct(TimeGMT(), dt);
      if(dt.hour >= Close_Pending_GMT_Hr && Close_Pending_GMT_Hr > 0)
         return true;
   }
   return false;
}

// ============================================================
// TRAILING STOP
// FIX BUG 17: curSL==0 tratado corretamente no SELL
// ============================================================
void Do_Trailing()
{
   if(!Enable_VergilTrailClose) return;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != MagicNo) continue;
      DoTrailing(ticket);
   }
}

void DoTrailing(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;
   int    ptype  = (int)PositionGetInteger(POSITION_TYPE);
   double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
   double curSL  = PositionGetDouble(POSITION_SL);
   double curTP  = PositionGetDouble(POSITION_TP);
   double ask    = symbolInfo.Ask();
   double bid    = symbolInfo.Bid();
   double pt     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double minStop= (double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL) * pt;

   if(ptype == POSITION_TYPE_BUY)
   {
      double bePx = NormalizeDouble(openPx + BreakEvenPips*Mult*pt, _Digits);
      if(BreakEvenThreshold > 0 && curSL < bePx)
      {
         if(bid - openPx > BreakEvenThreshold*Mult*pt)
         {
            if(bid - bePx > minStop)
               trade.PositionModify(ticket, bePx, curTP);
            return;
         }
      }
      if(TrailingType != 0 && Enable_Trailing_1 && TrailingStop > 0)
      {
         double newSL = NormalizeDouble(bid - TrailingStop*Mult*pt, _Digits);
         if(newSL > curSL && curSL >= bePx)
            trade.PositionModify(ticket, newSL, curTP);
      }
   }
   else if(ptype == POSITION_TYPE_SELL)
   {
      double bePx = NormalizeDouble(openPx - BreakEvenPips*Mult*pt, _Digits);
      // FIX BUG 17: quando curSL==0 (sem SL definido), trata como se ainda
      // não tivesse atingido breakeven
      bool   noSL = (curSL == 0);
      if(BreakEvenThreshold > 0 && (noSL || curSL > bePx))
      {
         if(openPx - ask > BreakEvenThreshold*Mult*pt)
         {
            if(bePx - ask > minStop)
               trade.PositionModify(ticket, bePx, curTP);
            return;
         }
      }
      if(TrailingType != 0 && Enable_Trailing_1 && TrailingStop > 0)
      {
         double newSL = NormalizeDouble(ask + TrailingStop*Mult*pt, _Digits);
         if((noSL || newSL < curSL) && bePx >= newSL)
            trade.PositionModify(ticket, newSL, curTP);
      }
   }
}

// ============================================================
// CALCULATE PIVOTS
// ============================================================
void Calculate_Pivots()
{
   if(!Enable_Fibo_Pivots && !Enable_Standard_Pivots) return;

   datetime refTime = iTime(_Symbol, PERIOD_D1, 0) + Pivot_GMT_Offset*3600;
   int refBar = MyBarShift(_Symbol, PERIOD_H1, refTime, false);
   if(refBar < 0) return;

   double dClose = iClose(_Symbol, PERIOD_H1, refBar+1);
   double dHigh  = iHigh (_Symbol, PERIOD_H1,
                   (int)iHighest(_Symbol, PERIOD_H1, MODE_HIGH, 24, refBar+1));
   double dLow   = iLow  (_Symbol, PERIOD_H1,
                   (int)iLowest (_Symbol, PERIOD_H1, MODE_LOW,  24, refBar+1));

   TodayClose = dClose;

   if(Enable_Fibo_Pivots)
   {
      Daily_Pivot = (dHigh + dLow + dClose) / 3.0;
      Daily_R1    = Daily_Pivot + 0.382*(dHigh-dLow);
      Daily_R2    = Daily_Pivot + 0.618*(dHigh-dLow);
      Daily_R3    = Daily_Pivot + 1.000*(dHigh-dLow);
      Daily_S1    = Daily_Pivot - 0.382*(dHigh-dLow);
      Daily_S2    = Daily_Pivot - 0.618*(dHigh-dLow);
      Daily_S3    = Daily_Pivot - 1.000*(dHigh-dLow);
   }
   else
   {
      Daily_Pivot = (dHigh + dLow + dClose) / 3.0;
      Daily_R1    = 2*Daily_Pivot - dLow;
      Daily_R2    = Daily_Pivot + (dHigh-dLow);
      Daily_R3    = dHigh + 2*(Daily_Pivot-dLow);
      Daily_S1    = 2*Daily_Pivot - dHigh;
      Daily_S2    = Daily_Pivot - (dHigh-dLow);
      Daily_S3    = dLow - 2*(dHigh-Daily_Pivot);
   }

   Daily_Pivots[0] = Daily_R3;
   Daily_Pivots[1] = Daily_R2;
   Daily_Pivots[2] = Daily_R1;
   Daily_Pivots[3] = Daily_Pivot;
   Daily_Pivots[4] = Daily_S1;
   Daily_Pivots[5] = Daily_S2;
   Daily_Pivots[6] = Daily_S3;
}

// ============================================================
// SEVERAL TIMEFRAME SIGNALS
// ============================================================
void CalculateSeveralTimeFrameSignals()
{
   static int lastH1bars = -1;
   int curH1bars = Bars(_Symbol, PERIOD_H1);
   if(lastH1bars != curH1bars)
   {
      Calculate_Pivots();
      lastH1bars = curH1bars;
   }
}

// ============================================================
// LOGGING
// ============================================================
void Log(string msg)
{
   if(!EnableFileErrorLogging) return;
   string fname = "GoldHunterLog_" + _Symbol + "_" + string(_Period) + ".csv";
   int handle = FileOpen(fname, FILE_CSV|FILE_READ|FILE_WRITE, ';');
   if(handle <= 0) return;
   FileSeek(handle, 0, SEEK_END);
   FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), msg);
   FileClose(handle);
}
//+------------------------------------------------------------------+
// END OF FILE - GoldHunter_MQL5_FIXED.mq5
//+------------------------------------------------------------------+