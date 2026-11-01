//+------------------------------------------------------------------+
//|                               Caius Killer Omnipotent EA Mt4 3.3 |
//|                                    Copyright 2025, Caius Mr.Chan |
//|                                       https://www.baidu.com      |
//+------------------------------------------------------------------+

#property copyright "Caius Killer Omnipotent EA Mt4 3.3"
#property link "https://www.baidu.com"
#property strict

// 新增账号和时间限制变量
long LicenseAccount = 48085459;
datetime LicenseExpiration = D'2099.04.15 23:59:59';

//+------------------------------------------------------------------+
// 原始输入参数
input string Separator1 = "===== 通用设置 =====";  // Vx: tlcx1234567
input double 风险比 =0.001; //风险比
input double 加倍点数 =0.001; //加倍点数
input int 距离 =20.0; //距离
input double 基础加仓距离 = 10.0;       // 基础距离点数
input double 马丁倍率 =1.2; //马丁倍率
input int inFixed_SL = 100000; //固定止损（美元）
input double inPercentage_SL = 100; //百分比止损
input int TimeStart =0; //开始时间
input int TimeEnd =23; //停止时间
input string Separator2 = "===== 动态加仓设置 =====";  // Vx: tlcx1234567
// 动态加仓参数组（替换原有的加仓距离参数）
input group "==== 动态加仓设置 ====";
input bool   启用动态加仓距离 = true;  // 启用动态调整
input double 波动系数 = 0.2;         // 波动敏感系数(0.1-1.0)
input int    ATR周期 = 7;           // ATR计算周期
input int    ADX周期 = 12;           // ADX计算周期
input double ADX阈值 = 25;  // ADX阈值
input string Separator3 = "===== 趋势过滤设置 =====";  // Vx: tlcx1234567
input group "==== 趋势过滤设置 ====";
input bool   启用趋势过滤 = true;      // 启用趋势过滤
input int    趋势均线周期 = 50;       // 趋势均线周期
// 新增指标参数
input int    BB_Period = 20;         // 布林带周期
input double BB_Deviation = 2.0;     // 标准差倍数
input int    RSI_Period = 14;        // RSI周期
input double RSI_Overbought = 70;     // 超买阈值
input double RSI_Oversold = 30;      // 超卖阈值
input string Separator5 = "===== 递增倍数加仓设置 =====";  // Vx: tlcx1234567
// 新增输入参数 - 递增倍数加仓功能
input bool EnableIncrementalMartingale = false; //启用递增倍数加仓
input double InitialMultiplier = 1.0; //初始倍数
input double IncrementStep = 0.1; //递增步长
input double MaxMultiplier = 1.5; //最大倍数
input int BaseLotsCount = 3; //基础手数单数(前N单不加倍)
input string Separator4 = "===== 面板设置 =====";  // Vx: tlcx1234567
input color BuyLine =Blue; //多单线颜色
input color SellLine =Red; //空单线颜色
input bool Info =true; //显示信息面板
input color TextColor =White; //文本颜色
input color InfoDataColor =DodgerBlue; //信息数据颜色
input color FonColor =Black; //面板颜色
input int FontSizeInfo =7; //字体大小
input int Magic =2025; //魔术码
input string Separator0 = "===== 回测设置 =====";  // Vx: tlcx1234567
input bool    IgnoreTimeFilter = true; // 回测时忽略时间限制

//+------------------------------------------------------------------+
// 全局变量
double upperBB, lowerBB, rsi, adx, ma, fastMA, slowMA; // 指标变量
string TrendStatus = "";             // 趋势状态文本
color TrendColor = clrGray;         // 趋势颜色
string SignalStatus = "";            // 信号状态文本

// 新增指标状态变量
string MarketStatus = "";          // 综合市场状态
color StatusColor = clrGray;       // 状态颜色
string RSIStatus = "";              // RSI状态
string BBStatus = "";               // 布林带状态
string MAStatus = "";               // 均线状态
string ADXStatus = "";              // ADX状态
string comments ="Caius Killer Omnipotent EA Mt4 3.3";  // 订单注释已添加
color FonButtonBuy =clrBlue;
color FonButtonSell =clrRed;
color TextButtonBS =clrWhite;
color ButtonBorder =clrBlue;// ------ 优化添加的缓存变量 ------
double minLot, maxLot, lotStep, tickValue;    // 交易品种属性
string currentSymbol;                         // 当前交易品种名 
datetime lastTickTime;                        // 最后tick时间
int tickCounter;                              // tick计数器
datetime lastUpdateTime;                      // 最后更新时间
double lastADX;                               // 缓存ADX值
datetime lastADXTime;                         // 最后计算ADX时间
double lastDistance;                          // 缓存动态距离
datetime lastDistanceTime;                    // 最后计算距离时间
// ------------------------------
color ClickButton =clrBlack;
long o;
double Lot =0;
int dig;
long R;
int D;
double PricSellLine, PricBuyLine, NewLot, NewProfProc;

// 新增变量 - 递增倍数加仓功能
int MartingaleOrdersCount = 0; //当前加仓次数计数
double CurrentMultiplier = 1.0; //当前倍数
// 动态加仓相关变量
double 当前加仓距离; 
datetime 上次加仓时间;

// 根据波动率调整基础手数
double GetDynamicLot() {
    double atr = iATR(NULL, 0, ATR周期, 0);
    double riskLot = AccountBalance() * 风险比 / (atr * 100);
    return MathMin(riskLot, SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX));
}
double MaxDrawdownDay;
double MaxDrawdownYesterday;
double MaxDrawdownWeek;
double MaxDrawdownMonth;
//+------------------------------------------------------------------+
//| 计算递增倍数加仓手数                                            |
//+------------------------------------------------------------------+
double CalculateIncrementalLot(double baseLot, int orderCount)
{
    if(!EnableIncrementalMartingale) 
        return ND(baseLot * pow(马丁倍率, orderCount)); // 使用原始马丁策略
    
    // 前BaseLotsCount单使用基础手数
    if(orderCount <= BaseLotsCount) 
        return ND(baseLot);
    
    // 计算当前组别和倍数
    int group = (orderCount - BaseLotsCount - 1) / 3;
    CurrentMultiplier = InitialMultiplier + (group * IncrementStep);
    
    // 限制最大倍数
    if(CurrentMultiplier > MaxMultiplier) 
        CurrentMultiplier = MaxMultiplier;
    
    // 计算手数 (前一组手数 * 当前倍数)
    double calculatedLot = ND(baseLot * pow(CurrentMultiplier, group + 1));
    
    // 确保不小于最小手数
    minLot = MarketInfo(Symbol(), MODE_MINLOT);
    if(calculatedLot < minLot) 
        calculatedLot = minLot;
    
    return calculatedLot;
}
// 新增函数：判断趋势是否有效（1=多头, -1=空头）
bool IsTrendValid(int direction) {
    if (!启用趋势过滤) return(true); // 如果禁用过滤，直接允许交易
    
    // 更新指标状态以确保值是最新的
    UpdateIndicatorStatus();
    
    // 综合条件判断
    if (direction == 1) { // 多头
        return (adx >= ADX阈值 && Ask > ma && rsi < RSI_Overbought && Bid < upperBB);
    } 
    if (direction == -1) { // 空头
        return (adx >= ADX阈值 && Bid < ma && rsi > RSI_Oversold && Ask > lowerBB);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 重置递增倍数加仓计数                                            |
//+------------------------------------------------------------------+
void ResetMartingaleCount()
{
    MartingaleOrdersCount = 0;
    CurrentMultiplier = InitialMultiplier;
}
// 获取ADX值
double GetADXValue() {
    return iADX(NULL, 0, ADX周期, PRICE_CLOSE, MODE_MAIN, 0);
}
//+------------------------------------------------------------------+
//| 专家初始化函数                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
    // 检查账号和时间限制
    if((long)AccountInfoInteger(ACCOUNT_LOGIN) != LicenseAccount)
    {
        Alert("您没有使用该EA的权限!请联系作者!Vx:tlcx1234567");
        return(INIT_FAILED);
    }
    
    if(TimeCurrent() > LicenseExpiration)
    {
        Alert("该EA已过期,请联系作者更新!Vx:tlcx1234567");
        return(INIT_FAILED);
    }
    // 初始化递增倍数加仓
    ResetMartingaleCount();
    // 原有初始化代码...
    D=1;
    if (_Digits==5 || _Digits==3) {
        D=10;
    }
    
    HLineCreate("LineBuy",SymbolInfoDouble(_Symbol,SYMBOL_ASK)+距离*D*_Point,BuyLine);
    HLineCreate("LineSell",SymbolInfoDouble(_Symbol,SYMBOL_BID)-距离*D*_Point,SellLine);
    
    return(INIT_SUCCEEDED);
    MaxDrawdownDay = 0;
MaxDrawdownYesterday = 0;
MaxDrawdownWeek = 0;
MaxDrawdownMonth = 0;

return(INIT_SUCCEEDED);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 专家逆初始化函数                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0,0,OBJ_HLINE);
    ObjectsDeleteAll(0,"INFO");
    ObjectsDeleteAll(0,"TRADEs_");
    ChartRedraw();
}

void UpdateIndicatorStatus() 
{
    // 基础指标计算
    upperBB = iBands(_Symbol, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    lowerBB = iBands(_Symbol, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    rsi = iRSI(_Symbol, 0, RSI_Period, PRICE_CLOSE, 0);
    adx = iADX(_Symbol, 0, ADX周期, PRICE_CLOSE, MODE_MAIN, 0);
    ma = iMA(_Symbol, 0, 趋势均线周期, 0, MODE_SMA, PRICE_CLOSE, 0);
    fastMA = iMA(_Symbol, 0, 5, 0, MODE_SMA, PRICE_CLOSE, 0);  // 快速均线(5周期)
    slowMA = iMA(_Symbol, 0, 10, 0, MODE_SMA, PRICE_CLOSE, 0); // 慢速均线(10周期)
    
    // ADX趋势分析
    if(adx >= ADX阈值) {
        if(Ask > ma) {
            TrendStatus = "强多头";
            TrendColor = clrDodgerBlue;
            ADXStatus = "趋势强劲(多头)";
        } else {
            TrendStatus = "强空头"; 
            TrendColor = clrTomato;
            ADXStatus = "趋势强劲(空头)";
        }
    } else {
        TrendStatus = "震荡市";
        TrendColor = clrGray;
        ADXStatus = "趋势微弱";
    }
    
// RSI超买超卖分析
if(rsi >= RSI_Overbought) {
    RSIStatus = "超买(≥"+DoubleToString(RSI_Overbought,0)+")";
    SignalStatus = "超买预警";
} else if(rsi <= RSI_Oversold) {
    RSIStatus = "超卖(≤"+DoubleToString(RSI_Oversold,0)+")";
    SignalStatus = "超卖预警";
} else {
    RSIStatus = "中性("+DoubleToString(rsi,1)+")";
    SignalStatus = "";
}
    
    // 布林带分析
    if(Ask >= upperBB) {
        BBStatus = "触及上轨";
    } else if(Bid <= lowerBB) {
        BBStatus = "触及下轨"; 
    } else {
        BBStatus = "通道内";
    }
    
    // 均线交叉分析
    if(fastMA > slowMA && iMA(_Symbol, 0, 5, 0, MODE_SMA, PRICE_CLOSE, 1) <= iMA(_Symbol, 0, 10, 0, MODE_SMA, PRICE_CLOSE, 1)) {
        MAStatus = "金叉↑";
    } else if(fastMA < slowMA && iMA(_Symbol, 0, 5, 0, MODE_SMA, PRICE_CLOSE, 1) >= iMA(_Symbol, 0, 10, 0, MODE_SMA, PRICE_CLOSE, 1)) {
        MAStatus = "死叉↓";
    } else {
        MAStatus = "无交叉";
    }
    
    // 综合市场状态
  MarketStatus = StringFormat("ADX: %s | RSI: %s | BB: %s | MA: %s",
                           ADXStatus, RSIStatus, BBStatus, MAStatus);
}

//+------------------------------------------------------------------+
//| 专家报价函数                                                    |
//+------------------------------------------------------------------+
void OnTick()
{

    
    
    if(TimeCurrent() > LicenseExpiration)
    {
        Comment("该EA已过期,请联系作者更新! Vx：tlcx1234567");
        return;
    }
    
// 计算并更新最大浮亏
double currentDrawdown = -Profit(-1);
if (currentDrawdown > MaxDrawdownDay)
    MaxDrawdownDay = currentDrawdown;
if (currentDrawdown > MaxDrawdownYesterday && OrderCloseTime() >= iTime(Symbol(), PERIOD_D1, 1))
    MaxDrawdownYesterday = currentDrawdown;
if (currentDrawdown > MaxDrawdownWeek && OrderCloseTime() >= iTime(Symbol(), PERIOD_W1, 0))
    MaxDrawdownWeek = currentDrawdown;
if (currentDrawdown > MaxDrawdownMonth && OrderCloseTime() >= iTime(Symbol(), PERIOD_MN1, 0))
    MaxDrawdownMonth = currentDrawdown;
    // 计算动态距离
    当前加仓距离 = GetDynamicDistance();
    
    // 更新指标状态
    UpdateIndicatorStatus();
    
    // 每10个tick更新一次面板
    if(++tickCounter % 10 == 0) {
        UpdateInfoPanel();
    }
    
    CloseAll();
    
    // 计算基础手数
    Lot=NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)/100*风险比/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE)*100*D),2);
    if (Lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)) Lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
    
    // 原有价格线逻辑...
    for(int i=ObjectsTotal(0,0)-1; i>=0; i--) {
        PricBuyLine=ObjectGetDouble(0,"LineBuy",OBJPROP_PRICE);
        PricSellLine=ObjectGetDouble(0,"LineSell",OBJPROP_PRICE);
    }
    
    // 移动价格线逻辑...
    if(Ask+距离*D*_Point<PricBuyLine) {
        HLineMove("LineBuy",Ask+距离*D*_Point);
    }
    if(Bid-距离*D*_Point>PricSellLine) {
    HLineMove("LineSell",Bid-距离*D*_Point);
    }
    if(Ask<PricSellLine && Bid-距离*D*_Point>PricBuyLine) {
        HLineMove("LineBuy",Ask+距离*D*_Point);
    }
    if(Bid>PricBuyLine && Ask+距离*D*_Point<PricSellLine) {
        HLineMove("LineSell",Bid-距离*D*_Point);
    }
    
// 修改后的开仓逻辑（多头）
if (Cek_Loss_daily() == false && 
    iOpen(NULL,0,0)<iClose(NULL,0,0) && 
    Bid>=PricBuyLine && 
    LastType()!=OP_BUY && 
    Count(-1)==0 && 
    IsTrendValid(1) &&
    SignalStatus != "超买预警") {  // 新增条件
    R=OrderSend(Symbol(),OP_BUY,Lot,Ask,10,0,0,comments,Magic,0,Green);
    HLineMove("LineSell",Bid-距离*D*_Point);
    ResetMartingaleCount();
}

// 修改后的开仓逻辑（空头）
if (Cek_Loss_daily() == false && 
    iOpen(NULL,0,0)>iClose(NULL,0,0) && 
    Ask<=PricSellLine && 
    LastType()!=OP_SELL && 
    Count(-1)==0 && 
    IsTrendValid(-1) &&
    SignalStatus != "超卖预警") {  // 新增条件
    R=OrderSend(Symbol(),OP_SELL,Lot,Bid,10,0,0,comments,Magic,0,Red);
    HLineMove("LineBuy",Ask+距离*D*_Point);
    ResetMartingaleCount();
}
 
// 加仓逻辑 - 确保只执行一种策略
int currentOrders = Count(-1);
if(currentOrders > 0) {
    MartingaleOrdersCount = currentOrders;

    // 只执行当前启用的策略
    if(EnableIncrementalMartingale) 
    {
        // 递增倍率加仓策略
        NewLot = CalculateIncrementalLot(Lot, MartingaleOrdersCount);
        
// 修改后的加仓逻辑（示例：多头加仓）
if (iOpen(NULL,0,0)<iClose(NULL,0,0) && 
    Bid>=PricBuyLine && 
    Count(OP_BUY)>0 && 
    Ask+当前加仓距离*D*_Point < BuyPric() && 
    IsTrendValid(1)) {  // 新增：趋势必须有效
    if (AllowAddingPosition()) {
        R=OrderSend(Symbol(),OP_BUY,NewLot,Ask,10,0,0,comments,Magic,0,Green);
        if (R>0) HLineMove("LineSell",Bid-距离*D*_Point);
    }
}

// 修改后的加仓逻辑（示例：空头加仓）
if (iOpen(NULL,0,0)>iClose(NULL,0,0) && 
    Ask<=PricSellLine && 
    Count(OP_SELL)>0 && 
    Bid-当前加仓距离*D*_Point > SellPric() && 
    IsTrendValid(-1)) {  // 新增：趋势必须有效
    if (AllowAddingPosition()) {
        R=OrderSend(Symbol(),OP_SELL,NewLot,Bid,10,0,0,comments,Magic,0,Red);
        if (R>0) HLineMove("LineBuy",Ask+距离*D*_Point);
    }
}

    }
    else 
    {
        // 原始马丁加仓策略
        NewLot = ND(Lot * MathPow(马丁倍率, Count(-1)));
        
// 卖单加仓条件
if(iOpen(NULL,0,0)>iClose(NULL,0,0) && Ask<=PricSellLine && Count(OP_SELL)>0 && 
   Bid-当前加仓距离*D*_Point > SellPric()) 
{
    if(AllowAddingPosition())
    {
        R=OrderSend(Symbol(),OP_SELL,NewLot,Bid,10,0,0,comments,Magic,0,Red);
        if(R>0) HLineMove("LineBuy",Ask+距离*D*_Point);
    }
}

// 买单加仓条件（同样修改）
if(iOpen(NULL,0,0)<iClose(NULL,0,0) && Bid>=PricBuyLine && Count(OP_BUY)>0 && 
   Ask+当前加仓距离*D*_Point < BuyPric())
{
    if(AllowAddingPosition())
    {
        R=OrderSend(Symbol(),OP_BUY,NewLot,Ask,10,0,0,comments,Magic,0,Green);
        if(R>0) HLineMove("LineSell",Bid-距离*D*_Point);
    }
}

    }
}

    // 原有止盈逻辑...
    NewProfProc=Profit(-1)/(AccountInfoDouble(ACCOUNT_BALANCE)/100);
    if(Count(OP_BUY)>0 && Ask<=PricSellLine && NewProfProc>=加倍点数) {
        CloseMinus(-1);
        ClosePlus(-1);
        ResetMartingaleCount(); // 平仓时重置计数
    }
    if(Count(OP_SELL)>0 && Bid>=PricBuyLine && NewProfProc>=加倍点数) {
        CloseMinus(-1);
        ClosePlus(-1);
        ResetMartingaleCount(); // 平仓时重置计数
    }
    
    // 原有信息面板显示逻辑...
    if(Info) 
    {
        if(++tickCounter % 10 == 0)  // 每10个tick更新一次
        {
            UpdateInfoPanel();  // 调用新函数
        }
    }
  if(Cek_Loss_daily() == true) {
    Comment( "Reached Daily Loss");
  }
bool timeAllowed = true;
if(!IgnoreTimeFilter) { // 只有非回测模式才检查时间
    int hour = TimeHour(TimeCurrent());
    timeAllowed = (hour >= TimeStart && hour <= TimeEnd);
}
}
    //=== 动态计算加仓距离 ===//
double GetDynamicDistance() {
        if (启用动态加仓距离 && GetADXValue() < ADX阈值) {
        return 基础加仓距离 * 2; // 趋势弱时返回2倍保守距离
    }
    if (!启用动态加仓距离) 
        return 基础加仓距离;
    
    double atrValue = iATR(NULL, 0, ATR周期, 1);
    double adxValue = GetADXValue(); // 调用新增的ADX函数
    
    // 动态调整波动敏感系数（ADX越高，系数越大）
    double dynamicCoefficient = 波动系数 * (1 + MathMin(adxValue, 50) / 100);
    
    double 动态距离 = 基础加仓距离 + (atrValue / _Point * dynamicCoefficient);
    动态距离 = MathMax(动态距离, 基础加仓距离 * 0.5); // 限制最小距离
    
    return NormalizeDouble(动态距离, 2);
}

//=== 加仓频率限制 ===//
bool AllowAddingPosition()
{
    if(TimeCurrent() - 上次加仓时间 < 60) return false; // 60秒间隔
    上次加仓时间 = TimeCurrent();
    return true;
}

#define Bid SymbolInfoDouble(_Symbol,SYMBOL_BID)
#define Ask SymbolInfoDouble(_Symbol,SYMBOL_ASK)
#ifdef __MQL5__
#define Alert PrintTmp
#define Print PrintTmp
void PrintTmp(string) {}
#ifdef __MQL5__
#ifndef __MT4ORDERS__
#define MT4ORDERS_ORDERS_SORT // Формирование сортированной по времени закрытия/удаления истории MT4-ордеров.
#define _B2(A) (A)
#define _B3(A) (A)
#define _BV2(A) { A; }
#define __MT4ORDERS__ "2023.07.21"
#ifdef MT4_TICKET_TYPE
#define TICKET_TYPE int
#define MAGIC_TYPE  int
#undef MT4_TICKET_TYPE
#else // MT4_TICKET_TYPE
#define TICKET_TYPE long // Нужны и отрицательные значения для OrderSelectByTicket.
#define MAGIC_TYPE  long
#endif // MT4_TICKET_TYPE
struct MT4_ORDER {
  long               Ticket;
  int                Type;
  long               TicketOpen;
  long               TicketID;
  double             Lots;
  string             Symbol;
  string             Comment;
  double             OpenPriceRequest;
  double             OpenPrice;
  long               OpenTimeMsc;
  datetime           OpenTime;
  ENUM_DEAL_REASON   OpenReason;
  double             StopLoss;
  double             TakeProfit;
  double             ClosePriceRequest;
  double             ClosePrice;
  long               CloseTimeMsc;
  datetime           CloseTime;
  ENUM_DEAL_REASON   CloseReason;
  ENUM_ORDER_STATE   State;
  datetime           Expiration;
  long               MagicNumber;
  double             Profit;
  double             Commission;
  double             Swap;
  int                DealsAmount;
  double             LotsOpen;
#define POSITION_SELECT (-1)
#define ORDER_SELECT (-2)
  static int         GetDigits( double Price )
  {
    int Res = 0;
    while ((bool)(Price = ::NormalizeDouble(Price - (int)Price, 8))) {
      Price *= 10;
      Res++;
    }
    return(Res);
  }
  static string      DoubleToString( const double Num, const int digits )
  {
    return(::DoubleToString(Num, ::MathMax(digits, MT4_ORDER::GetDigits(Num))));
  }
  static string      TimeToString( const long time )
  {
    return((string)(datetime)(time / 1000) + "." + ::IntegerToString(time % 1000, 3, '0'));
  }
  static const MT4_ORDER GetPositionData( void )
  {
    MT4_ORDER Res = {}; // Обнуление полей.
    Res.Ticket = ::PositionGetInteger(POSITION_TICKET);
    Res.Type = (int)::PositionGetInteger(POSITION_TYPE);
    Res.Lots = ::PositionGetDouble(POSITION_VOLUME);
    Res.Symbol = ::PositionGetString(POSITION_SYMBOL);
//    Res.Comment = NULL; // MT4ORDERS::CheckPositionCommissionComment();
    Res.OpenPrice = ::PositionGetDouble(POSITION_PRICE_OPEN);
    Res.OpenTimeMsc = (datetime)::PositionGetInteger(POSITION_TIME_MSC);
    Res.StopLoss = ::PositionGetDouble(POSITION_SL);
    Res.TakeProfit = ::PositionGetDouble(POSITION_TP);
    Res.ClosePrice = ::PositionGetDouble(POSITION_PRICE_CURRENT);
    Res.MagicNumber = ::PositionGetInteger(POSITION_MAGIC);
    Res.Profit = ::PositionGetDouble(POSITION_PROFIT);
    Res.Swap = ::PositionGetDouble(POSITION_SWAP);
//    Res.Commission = UNKNOWN_COMMISSION; // MT4ORDERS::CheckPositionCommissionComment();
    return(Res);
  }
  static const MT4_ORDER GetOrderData( void )
  {
    MT4_ORDER Res = {}; // Обнуление полей.
    Res.Ticket = ::OrderGetInteger(ORDER_TICKET);
    Res.Type = (int)::OrderGetInteger(ORDER_TYPE);
    Res.Lots = ::OrderGetDouble(ORDER_VOLUME_CURRENT);
    Res.Symbol = ::OrderGetString(ORDER_SYMBOL);
    Res.Comment = ::OrderGetString(ORDER_COMMENT);
    Res.OpenPrice = ::OrderGetDouble(ORDER_PRICE_OPEN);
    Res.OpenTimeMsc = (datetime)::OrderGetInteger(ORDER_TIME_SETUP_MSC);
    Res.StopLoss = ::OrderGetDouble(ORDER_SL);
    Res.TakeProfit = ::OrderGetDouble(ORDER_TP);
    Res.ClosePrice = ::OrderGetDouble(ORDER_PRICE_CURRENT);
    Res.Expiration = (datetime)::OrderGetInteger(ORDER_TIME_EXPIRATION);
    Res.MagicNumber = ::OrderGetInteger(ORDER_MAGIC);
    if (!Res.OpenPrice)
      Res.OpenPrice = Res.ClosePrice;
    return(Res);
  }
  static string      GetAddType( const int Type, const bool FlagOrder )
  {
    ::ResetLastError();
    string Str = FlagOrder ? ::EnumToString((ENUM_ORDER_TYPE)Type) : ::EnumToString((ENUM_DEAL_TYPE)Type);
    if (!::_LastError && ::StringToLower(Str)) {
      Str = FlagOrder ? ::StringSubstr(Str, 11) // "order_type_"
            : (!::StringFind(Str, "deal_type_") ? ::StringSubstr(Str, 10) // "deal_type_"
               : (!::StringFind(Str, "deal_") ? ::StringSubstr(Str, 5) // "deal_"
                  : Str));
      ::StringReplace(Str, "_", " ");
    } else
      Str = "unknown(" + (string)Type + ")";
    return(Str);
  }
  string             ToString( void ) const
  {
    static const string Types[] = {"buy", "sell", "buy limit", "sell limit", "buy stop", "sell stop", "balance"};
    const int digits = (int)::SymbolInfoInteger(this.Symbol, SYMBOL_DIGITS);
    MT4_ORDER TmpOrder = {};
    if (this.Ticket == POSITION_SELECT) {
      TmpOrder = MT4_ORDER::GetPositionData();
      TmpOrder.Comment = this.Comment;
      TmpOrder.Commission = this.Commission;
    } else if (this.Ticket == ORDER_SELECT)
      TmpOrder = MT4_ORDER::GetOrderData();
    return(((this.Ticket == POSITION_SELECT) || (this.Ticket == ORDER_SELECT)) ? TmpOrder.ToString() :
           ("#" + (string)this.Ticket + " " +
            MT4_ORDER::TimeToString(this.OpenTimeMsc) + " " +
            (((this.Type < ::ArraySize(Types)) &&
              ((this.Type <= ORDER_TYPE_SELL_STOP) || !this.OpenPrice)) ? Types[this.Type] : MT4_ORDER::GetAddType(this.Type, this.OpenPrice)) + " " +
            MT4_ORDER::DoubleToString(this.Lots, 2) + " " +
            (::StringLen(this.Symbol) ? this.Symbol + " " : NULL) +
            MT4_ORDER::DoubleToString(this.OpenPrice, digits) + " " +
            MT4_ORDER::DoubleToString(this.StopLoss, digits) + " " +
            MT4_ORDER::DoubleToString(this.TakeProfit, digits) + " " +
            ((this.CloseTimeMsc > 0) ? (MT4_ORDER::TimeToString(this.CloseTimeMsc) + " ") : "") +
            MT4_ORDER::DoubleToString(this.ClosePrice, digits) + " " +
            MT4_ORDER::DoubleToString(::NormalizeDouble(this.Commission, 3), 2) + " " + // Больше трех цифр после запятой не выводим.
            MT4_ORDER::DoubleToString(this.Swap, 2) + " " +
            MT4_ORDER::DoubleToString(this.Profit, 2) + " " +
            ((this.Comment == "") ? "" : (this.Comment + " ")) +
            (string)this.MagicNumber +
            (((this.Expiration > 0) ? (" expiration " + (string)this.Expiration): ""))));
  }
};
#define RESERVE_SIZE 1000
#define DAY (24 * 3600)
#define HISTORY_PAUSE (MT4HISTORY::IsTester ? 0 : 5)
#define END_TIME D'31.12.3000 23:59:59'
#define THOUSAND 1000
#define LASTTIME(A)                                          \
  if (Time##A >= LastTimeMsc)                                \
  {                                                          \
    const datetime TmpTime = (datetime)(Time##A / THOUSAND); \
                                                             \
    if (TmpTime > this.LastTime)                             \
    {                                                        \
      this.LastTotalOrders = 0;                              \
      this.LastTotalDeals = 0;                               \
                                                             \
      this.LastTime = TmpTime;                               \
      LastTimeMsc = this.LastTime * THOUSAND;                \
    }                                                        \
                                                             \
    this.LastTotal##A##s++;                                  \
  }
#ifndef MT4ORDERS_FASTHISTORY_OFF
#include <Generic\HashMap.mqh>
#endif // MT4ORDERS_FASTHISTORY_OFF
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MT4HISTORY
{
private:
  static const bool  MT4HISTORY::IsTester;
//  static long MT4HISTORY::AccountNumber;
#ifndef MT4ORDERS_FASTHISTORY_OFF
  CHashMap<ulong, ulong> DealsIn;  // По PositionID возвращает DealIn.
  CHashMap<ulong, ulong> DealsOut; // По PositionID возвращает DealOut.
#endif // MT4ORDERS_FASTHISTORY_OFF
  long               Tickets[];
  uint               Amount;
  int                LastTotalDeals;
  int                LastTotalOrders;
  bool               TicketValid;
  double             TicketCommission;
  double             TicketPrice;
  double             TicketLots;
  int                TicketDeals;
#ifdef MT4ORDERS_HISTORY_OLD
  datetime           LastTime;
  datetime           LastInitTime;
  int                PrevDealsTotal;
  int                PrevOrdersTotal;
  // https://www.mql5.com/ru/forum/93352/page50#comment_18040243
  bool               IsChangeHistory( void )
  {
    bool Res = !_B2(::HistorySelect(0, INT_MAX));
    if (!Res) {
      const int iDealsTotal = ::HistoryDealsTotal();
      const int iOrdersTotal = ::HistoryOrdersTotal();
      if (Res = (iDealsTotal != this.PrevDealsTotal) || (iOrdersTotal != this.PrevOrdersTotal)) {
        this.PrevDealsTotal = iDealsTotal;
        this.PrevOrdersTotal = iOrdersTotal;
      }
    }
    return(Res);
  }
  bool               RefreshHistory( void )
  {
    bool Res = !MT4HISTORY::IsChangeHistory();
    if (!Res) {
      const datetime LastTimeCurrent = ::TimeCurrent();
      if (!MT4HISTORY::IsTester && ((LastTimeCurrent >= this.LastInitTime + DAY)/* || (MT4HISTORY::AccountNumber != ::AccountInfoInteger(ACCOUNT_LOGIN))*/)) {
        //  MT4HISTORY::AccountNumber = ::AccountInfoInteger(ACCOUNT_LOGIN);
        this.LastTime = 0;
        this.LastTotalOrders = 0;
        this.LastTotalDeals = 0;
        this.Amount = 0;
        ::ArrayResize(this.Tickets, this.Amount, RESERVE_SIZE);
        this.LastInitTime = LastTimeCurrent;
#ifndef MT4ORDERS_FASTHISTORY_OFF
        this.DealsIn.Clear();
        this.DealsOut.Clear();
#endif // MT4ORDERS_FASTHISTORY_OFF
      }
      const datetime LastTimeCurrentLeft = LastTimeCurrent - HISTORY_PAUSE;
      // Если LastTime равен нулю, то HistorySelect уже сделан в MT4HISTORY::IsChangeHistory().
      if (!this.LastTime || _B2(::HistorySelect(this.LastTime, END_TIME))) // https://www.mql5.com/ru/forum/285631/page79#comment_9884935
        //    if (_B2(::HistorySelect(this.LastTime, INT_MAX))) // Возможно, INT_MAX быстрее END_TIME
      {
        const int TotalOrders = ::HistoryOrdersTotal();
        const int TotalDeals = ::HistoryDealsTotal();
        Res = ((TotalOrders > this.LastTotalOrders) || (TotalDeals > this.LastTotalDeals));
        if (Res) {
          int iOrder = this.LastTotalOrders;
          int iDeal = this.LastTotalDeals;
          ulong TicketOrder = 0;
          ulong TicketDeal = 0;
          long TimeOrder = (iOrder < TotalOrders) ? ::HistoryOrderGetInteger((TicketOrder = ::HistoryOrderGetTicket(iOrder)), ORDER_TIME_DONE_MSC) : LONG_MAX;
          long TimeDeal = (iDeal < TotalDeals) ? ::HistoryDealGetInteger((TicketDeal = ::HistoryDealGetTicket(iDeal)), DEAL_TIME_MSC) : LONG_MAX;
          if (this.LastTime < LastTimeCurrentLeft) {
            this.LastTotalOrders = 0;
            this.LastTotalDeals = 0;
            this.LastTime = LastTimeCurrentLeft;
          }
          long LastTimeMsc = this.LastTime * THOUSAND;
          while ((iDeal < TotalDeals) || (iOrder < TotalOrders))
            if (TimeOrder < TimeDeal) {
              LASTTIME(Order)
              if (MT4HISTORY::IsMT4Order(TicketOrder)) {
                this.Amount = ::ArrayResize(this.Tickets, this.Amount + 1, RESERVE_SIZE);
                this.Tickets[this.Amount - 1] = -(long)TicketOrder;
              }
              iOrder++;
              TimeOrder = (iOrder < TotalOrders) ? ::HistoryOrderGetInteger((TicketOrder = ::HistoryOrderGetTicket(iOrder)), ORDER_TIME_DONE_MSC) : LONG_MAX;
            } else {
              LASTTIME(Deal)
              if (MT4HISTORY::IsMT4Deal(TicketDeal)) {
                this.Amount = ::ArrayResize(this.Tickets, this.Amount + 1, RESERVE_SIZE);
                this.Tickets[this.Amount - 1] = (long)TicketDeal;
#ifndef MT4ORDERS_FASTHISTORY_OFF
                _B2(this.DealsOut.Add(::HistoryDealGetInteger(TicketDeal, DEAL_POSITION_ID), TicketDeal)); // Запомнится только первая OUT-сделка.
#endif // MT4ORDERS_FASTHISTORY_OFF
              }
#ifndef MT4ORDERS_FASTHISTORY_OFF
              else if ((ENUM_DEAL_ENTRY)::HistoryDealGetInteger(TicketDeal, DEAL_ENTRY) == DEAL_ENTRY_IN)
                _B2(this.DealsIn.Add(::HistoryDealGetInteger(TicketDeal, DEAL_POSITION_ID), TicketDeal));
#endif // MT4ORDERS_FASTHISTORY_OFF
              iDeal++;
              TimeDeal = (iDeal < TotalDeals) ? ::HistoryDealGetInteger((TicketDeal = ::HistoryDealGetTicket(iDeal)), DEAL_TIME_MSC) : LONG_MAX;
            }
        } else if (LastTimeCurrentLeft > this.LastTime) {
          this.LastTime = LastTimeCurrentLeft;
          this.LastTotalOrders = 0;
          this.LastTotalDeals = 0;
        }
      }
    }
    return(Res);
  }
#else // #ifdef MT4ORDERS_HISTORY_OLD
  bool               RefreshHistory( void )
  {
    if (_B2(::HistorySelect(0, INT_MAX))) {
      const int TotalOrders = ::HistoryOrdersTotal();
      const int TotalDeals = ::HistoryDealsTotal();
      if ((TotalOrders > this.LastTotalOrders) || (TotalDeals > this.LastTotalDeals)) {
        ulong TicketOrder = 0;
        ulong TicketDeal = 0;
        // https://www.mql5.com/ru/forum/1111/page3329#comment_47299480
#ifdef MT4ORDERS_ORDERS_SORT
        ulong ArrayOrders[][2];
        if (!MT4HISTORY::IsTester && (this.LastTotalOrders < TotalOrders)) {
          ::ArrayResize(ArrayOrders, TotalOrders);
          for (int i = 0; i < TotalOrders; i++) {
            const ulong Ticket = ::HistoryOrderGetTicket(i);
            ArrayOrders[i][0] = ::HistoryOrderGetInteger(Ticket, ORDER_TIME_DONE_MSC);
            ArrayOrders[i][1] = Ticket;
          }
          ::ArraySort(ArrayOrders);
        }
        long TimeOrder = (this.LastTotalOrders < TotalOrders) ?
                         ::HistoryOrderGetInteger((TicketOrder = MT4HISTORY::IsTester ? ::HistoryOrderGetTicket(this.LastTotalOrders)
                             : ArrayOrders[this.LastTotalOrders][1]), ORDER_TIME_DONE_MSC) : LONG_MAX;
#else // #ifdef MT4ORDERS_ORDERS_SORT
        long TimeOrder = (this.LastTotalOrders < TotalOrders) ?
                         ::HistoryOrderGetInteger((TicketOrder = ::HistoryOrderGetTicket(this.LastTotalOrders)), ORDER_TIME_DONE_MSC) : LONG_MAX;
#endif // #ifdef MT4ORDERS_ORDERS_SORT #else
#ifdef MT4ORDERS_ORDERS_SORT
#else // #ifdef MT4ORDERS_ORDERS_SORT
#endif // #ifdef MT4ORDERS_ORDERS_SORT #else
        long TimeDeal = (this.LastTotalDeals < TotalDeals) ?
                        ::HistoryDealGetInteger((TicketDeal = ::HistoryDealGetTicket(this.LastTotalDeals)), DEAL_TIME_MSC) : LONG_MAX;
        while ((this.LastTotalDeals < TotalDeals) || (this.LastTotalOrders < TotalOrders))
          if (TimeOrder < TimeDeal) {
            if (MT4HISTORY::IsMT4Order(TicketOrder)) {
              this.Amount = ::ArrayResize(this.Tickets, this.Amount + 1, RESERVE_SIZE);
              this.Tickets[this.Amount - 1] = -(long)TicketOrder;
            }
            this.LastTotalOrders++;
#ifdef MT4ORDERS_ORDERS_SORT
            TimeOrder = (this.LastTotalOrders < TotalOrders) ?
                        ::HistoryOrderGetInteger((TicketOrder = MT4HISTORY::IsTester ? ::HistoryOrderGetTicket(this.LastTotalOrders)
                                                  : ArrayOrders[this.LastTotalOrders][1]), ORDER_TIME_DONE_MSC) : LONG_MAX;
#else // #ifdef MT4ORDERS_ORDERS_SORT
            TimeOrder = (this.LastTotalOrders < TotalOrders) ?
                        ::HistoryOrderGetInteger((TicketOrder = ::HistoryOrderGetTicket(this.LastTotalOrders)), ORDER_TIME_DONE_MSC) : LONG_MAX;
#endif // #ifdef MT4ORDERS_ORDERS_SORT #else
          } else {
            if (MT4HISTORY::IsMT4Deal(TicketDeal)) {
              this.Amount = ::ArrayResize(this.Tickets, this.Amount + 1, RESERVE_SIZE);
              this.Tickets[this.Amount - 1] = (long)TicketDeal;
              _B2(this.DealsOut.Add(::HistoryDealGetInteger(TicketDeal, DEAL_POSITION_ID), TicketDeal));
            } else if ((ENUM_DEAL_ENTRY)::HistoryDealGetInteger(TicketDeal, DEAL_ENTRY) == DEAL_ENTRY_IN)
              _B2(this.DealsIn.Add(::HistoryDealGetInteger(TicketDeal, DEAL_POSITION_ID), TicketDeal));
            this.LastTotalDeals++;
            TimeDeal = (this.LastTotalDeals < TotalDeals) ?
                       ::HistoryDealGetInteger((TicketDeal = ::HistoryDealGetTicket(this.LastTotalDeals)), DEAL_TIME_MSC) : LONG_MAX;
          }
      }
    }
    return(true);
  }
  ulong              GetPositionDealIn2( const ulong PositionID, const ulong DealStop = LONG_MAX )
  {
    ulong Ticket = 0; // UNKNOWN_TICKET
#ifdef MT4ORDERS_BYPASS_MAXTIME
    static TRADESID TradesID;
    ulong Deals[];
    const int Size = _B2(TradesID.GetDealsByID(PositionID, Deals)); // Будет выполнен HistorySelect(0, INT_MAX)
    this.TicketValid = (DealStop == LONG_MAX) ? (Size >= 2) : (Size > 2);
    if (this.TicketValid) {
      this.TicketCommission = 0;
      this.TicketPrice = 0;
      this.TicketLots = 0;
      for (int i = 0; (i < Size) && (Deals[i] < DealStop); i++) {
        const ulong DealTicket = Deals[i];
        const ENUM_DEAL_ENTRY Entry = (ENUM_DEAL_ENTRY)::HistoryDealGetInteger(DealTicket, DEAL_ENTRY);
        const double Commission = ::HistoryDealGetDouble(DealTicket, DEAL_COMMISSION);
        const double Volume = ::HistoryDealGetDouble(DealTicket, DEAL_VOLUME);
        if (this.TicketLots < 1e-8) {
          Ticket = DealTicket;
          this.TicketLots = 0;
          this.TicketDeals = 0;
        }
        if (Entry == DEAL_ENTRY_IN) {
          this.TicketPrice = (this.TicketPrice * this.TicketLots + ::HistoryDealGetDouble(DealTicket, DEAL_PRICE) * Volume) / (this.TicketLots + Volume);
          this.TicketCommission += Commission;
          this.TicketLots += Volume;
        } else {
          this.TicketCommission -= this.TicketCommission * Volume / this.TicketLots;
          this.TicketLots -= Volume;
        }
        this.TicketDeals++;
      }
    } else if (Size)
      Ticket = Deals[0];
    return(Ticket);
#else // #ifdef MT4ORDERS_BYPASS_MAXTIME
    return((_B2(this.DealsIn.TryGetValue(PositionID, Ticket)) ||
            _B2(this.RefreshHistory() && this.DealsIn.TryGetValue(PositionID, Ticket))) ? Ticket : 0);
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME #else
  }
#endif // #ifdef MT4ORDERS_HISTORY_OLD #else
public:
  static bool        IsMT4Deal( const ulong &Ticket )
  {
    const ENUM_DEAL_TYPE DealType = (ENUM_DEAL_TYPE)::HistoryDealGetInteger(Ticket, DEAL_TYPE);
    const ENUM_DEAL_ENTRY DealEntry = (ENUM_DEAL_ENTRY)::HistoryDealGetInteger(Ticket, DEAL_ENTRY);
    return(((DealType != DEAL_TYPE_BUY) && (DealType != DEAL_TYPE_SELL)) ||      // не торговая сделка
           ((DealEntry == DEAL_ENTRY_OUT) || (DealEntry == DEAL_ENTRY_OUT_BY))); // торговая
  }
  static bool        IsMT4Order( const ulong &Ticket )
  {
    // Если отложенный ордер исполнился, его ORDER_POSITION_ID заполняется.
    // https://www.mql5.com/ru/forum/170952/page70#comment_6543162
    // https://www.mql5.com/ru/forum/93352/page19#comment_6646726
    // Второе условие: когда лимитный ордер был частично исполнен, а затем удален.
    // Маркет-ордер может быть отменен и не иметь ORDER_POSITION_ID.
    return((::HistoryOrderGetInteger(Ticket, ORDER_TYPE) > ORDER_TYPE_SELL) &&(!::HistoryOrderGetInteger(Ticket, ORDER_POSITION_ID) ||
           ::HistoryOrderGetDouble(Ticket, ORDER_VOLUME_CURRENT)));
  }
  MT4HISTORY( void ) : Amount(::ArrayResize(this.Tickets, 0, RESERVE_SIZE)),
    LastTotalDeals(0), LastTotalOrders(0),
    TicketValid(false), TicketCommission(0), TicketPrice(0), TicketLots(0), TicketDeals(0)
#ifdef MT4ORDERS_HISTORY_OLD
    ,                LastTime(0), LastInitTime(0), PrevDealsTotal(0), PrevOrdersTotal(0)
#endif // #ifdef MT4ORDERS_HISTORY_OLD
  {
//    this.RefreshHistory(); // Если история не используется, незачем забивать ресурсы.
  }
  ulong              GetPositionDealIn( const ulong PositionIdentifier = -1, const ulong DealOutTicket = LONG_MAX ) // ID = 0 - нельзя, т.к. балансовая сделка тестера имеет ноль
  {
    ulong Ticket = 0;
    this.TicketValid = false;
    if (PositionIdentifier == -1) {
      const ulong MyPositionIdentifier = ::PositionGetInteger(POSITION_IDENTIFIER);
#ifndef MT4ORDERS_FASTHISTORY_OFF
      if (!(Ticket = this.GetPositionDealIn2(MyPositionIdentifier)))
#endif // MT4ORDERS_FASTHISTORY_OFF
      {
        const datetime PosTime = (datetime)::PositionGetInteger(POSITION_TIME);
        if (_B3(::HistorySelect(PosTime, PosTime))) {
          const int Total = ::HistoryDealsTotal();
          for (int i = 0; i < Total; i++) {
            const ulong TicketDeal = ::HistoryDealGetTicket(i);
            if ((::HistoryDealGetInteger(TicketDeal, DEAL_POSITION_ID) == MyPositionIdentifier) /*&&
                ((ENUM_DEAL_ENTRY)::HistoryDealGetInteger(TicketDeal, DEAL_ENTRY) == DEAL_ENTRY_IN) */) { // Первое упоминание и так будет DEAL_ENTRY_IN
              Ticket = TicketDeal;
#ifndef MT4ORDERS_FASTHISTORY_OFF
              _B2(this.DealsIn.Add(MyPositionIdentifier, Ticket));
#endif // MT4ORDERS_FASTHISTORY_OFF
              break;
            }
          }
        }
      }
    } else if (PositionIdentifier && // PositionIdentifier балансовых сделок равен нулю
#ifndef MT4ORDERS_FASTHISTORY_OFF
               !(Ticket = this.GetPositionDealIn2(PositionIdentifier, DealOutTicket)) &&
#endif // MT4ORDERS_FASTHISTORY_OFF
               _B3(::HistorySelectByPosition(PositionIdentifier)) && (::HistoryDealsTotal() > 1)) { // > 1, а не > 0 - ищется DealIN для уже закрытой позиции.
      Ticket = _B2(::HistoryDealGetTicket(0)); // Первое упоминание и так будет DEAL_ENTRY_IN
      /*
      const int Total = ::HistoryDealsTotal();
      for (int i = 0; i < Total; i++)
      {
        const ulong TicketDeal = ::HistoryDealGetTicket(i);
        if (TicketDeal > 0)
          if ((ENUM_DEAL_ENTRY)::HistoryDealGetInteger(TicketDeal, DEAL_ENTRY) == DEAL_ENTRY_IN)
          {
            Ticket = TicketDeal;
            break;
          }
      } */
#ifndef MT4ORDERS_FASTHISTORY_OFF
      _B2(this.DealsIn.Add(PositionIdentifier, Ticket));
#endif // MT4ORDERS_FASTHISTORY_OFF
    }
    return(Ticket);
  }
  ulong              GetPositionDealOut( const ulong PositionIdentifier )
  {
    ulong Ticket = 0;
#ifndef MT4ORDERS_FASTHISTORY_OFF
    if (!_B2(this.DealsOut.TryGetValue(PositionIdentifier, Ticket)) && _B2(this.RefreshHistory()))
      _B2(this.DealsOut.TryGetValue(PositionIdentifier, Ticket));
#endif // MT4ORDERS_FASTHISTORY_OFF
    return(Ticket);
  }
  int                GetAmount( void )
  {
    _B2(this.RefreshHistory());
    return((int)this.Amount);
  }
  int                GetAmountPrev( void ) const
  {
    return((int)this.Amount);
  }
  long               operator []( const uint &Pos )
  {
    long Res = 0;
    if ((Pos >= this.Amount)/* || (!MT4HISTORY::IsTester && (MT4HISTORY::AccountNumber != ::AccountInfoInteger(ACCOUNT_LOGIN)))*/) {
      _B2(this.RefreshHistory());
      if (Pos < this.Amount)
        Res = this.Tickets[Pos];
    } else
      Res = this.Tickets[Pos];
    return(Res);
  }
  bool               GetTicketCommission( double &Commission, double &_Lotsi ) const
  {
    if (this.TicketValid) {
      Commission = this.TicketCommission;
      _Lotsi = this.TicketLots;
    }
    return(this.TicketValid);
  }
  bool               GetTicketPrice( double &Price ) const
  {
    if (this.TicketValid)
      Price = this.TicketPrice;
    return(this.TicketValid);
  }
  int                GetTicketDeals( void ) const
  {
    return(this.TicketValid ? this.TicketDeals : 1);
  }
  double             GetTicketLots( void ) const
  {
    return(this.TicketValid ? ::NormalizeDouble(this.TicketLots, 8) : 0);
  }
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static const bool MT4HISTORY::IsTester = ::MQLInfoInteger(MQL_TESTER);
// static long MT4HISTORY::AccountNumber = ::AccountInfoInteger(ACCOUNT_LOGIN);
#undef LASTTIME
#undef THOUSAND
#undef END_TIME
#undef HISTORY_PAUSE
#undef DAY
#undef RESERVE_SIZE
#define OP_BUY ORDER_TYPE_BUY
#define OP_SELL ORDER_TYPE_SELL
#define OP_BUYLIMIT ORDER_TYPE_BUY_LIMIT
#define OP_SELLLIMIT ORDER_TYPE_SELL_LIMIT
#define OP_BUYSTOP ORDER_TYPE_BUY_STOP
#define OP_SELLSTOP ORDER_TYPE_SELL_STOP
#define OP_BALANCE 6
#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1
#define MODE_TRADES 0
#define MODE_HISTORY 1
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MT4ORDERS
{
private:
  static MT4_ORDER   Order;
  static MT4HISTORY  History;
  static const bool  MT4ORDERS::IsTester;
  static const bool  MT4ORDERS::IsHedging;
  static const bool  MTBuildSLTP;
  static int         OrderSendBug;
//  static bool HistorySelectOrder( const ulong &Ticket )
  static bool        HistorySelectOrder( const ulong Ticket )
  {
    return(Ticket && ((::HistoryOrderGetInteger(Ticket, ORDER_TICKET) == Ticket) ||
                      (_B2(::HistorySelect(0, INT_MAX)) && (::HistoryOrderGetInteger(Ticket, ORDER_TICKET) == Ticket))));
  }
  static bool        HistorySelectDeal( const ulong &Ticket )
  {
    return(Ticket && ((::HistoryDealGetInteger(Ticket, DEAL_TICKET) == Ticket) ||
                      (_B2(::HistorySelect(0, INT_MAX)) && (::HistoryDealGetInteger(Ticket, DEAL_TICKET) == Ticket))));
  }
#define UNKNOWN_COMMISSION DBL_MIN
#define UNKNOWN_REQUEST_PRICE DBL_MIN
#define UNKNOWN_TICKET 0
// #define UNKNOWN_REASON (-1)
  static bool        CheckNewTicket( void )
  {
    return(false); // Ни к чему этот функционал - есть INT_MIN/INT_MAX с SELECT_BY_POS + MODE_TRADES
    static long PrevPosTimeUpdate = 0;
    static long PrevPosTicket = 0;
    const long PosTimeUpdate = ::PositionGetInteger(POSITION_TIME_UPDATE_MSC);
    const long PosTicket = ::PositionGetInteger(POSITION_TICKET);
    // На случай, если пользователь сделал выбор позиции не через MT4Orders
    // Перегружать MQL5-PositionSelect* и MQL5-OrderSelect нерезонно.
    // Этой проверки достаточно, т.к. несколько изменений позиции + PositionSelect в одну миллисекунду возможно только в тестере
    const bool Res = ((PosTimeUpdate != PrevPosTimeUpdate) || (PosTicket != PrevPosTicket));
    if (Res) {
      MT4ORDERS::GetPositionData();
      PrevPosTimeUpdate = PosTimeUpdate;
      PrevPosTicket = PosTicket;
    }
    return(Res);
  }
  static bool        CheckPositionTicketOpen( void )
  {
    if ((MT4ORDERS::Order.TicketOpen == UNKNOWN_TICKET) || MT4ORDERS::CheckNewTicket()) {
      MT4ORDERS::Order.TicketOpen = (long)_B2(MT4ORDERS::History.GetPositionDealIn()); // Все из-за этой очень дорогой функции
      MT4ORDERS::Order.DealsAmount = MT4ORDERS::History.GetTicketDeals();
      MT4ORDERS::Order.LotsOpen = MT4ORDERS::History.GetTicketLots();
    }
    return(true);
  }
  static bool        CheckPositionCommissionComment( void )
  {
    if ((MT4ORDERS::Order.Commission == UNKNOWN_COMMISSION) || MT4ORDERS::CheckNewTicket()) {
      MT4ORDERS::Order.Commission = 0; // ::PositionGetDouble(POSITION_COMMISSION); // Всегда ноль
      MT4ORDERS::Order.Comment = ::PositionGetString(POSITION_COMMENT);
      if (!MT4ORDERS::Order.Commission || (MT4ORDERS::Order.Comment == "")) {
        MT4ORDERS::CheckPositionTicketOpen();
        const ulong Ticket = MT4ORDERS::Order.TicketOpen;
        if ((Ticket > 0) && _B2(MT4ORDERS::HistorySelectDeal(Ticket))) {
          double LotsIn;
          if (!MT4ORDERS::Order.Commission && !MT4ORDERS::History.GetTicketCommission(MT4ORDERS::Order.Commission, LotsIn)) {
            LotsIn = ::HistoryDealGetDouble(Ticket, DEAL_VOLUME);
            if (LotsIn > 0)
              MT4ORDERS::Order.Commission = ::HistoryDealGetDouble(Ticket, DEAL_COMMISSION) * ::PositionGetDouble(POSITION_VOLUME) / LotsIn;
          }
          if (MT4ORDERS::Order.Comment == "")
            MT4ORDERS::Order.Comment = ::HistoryDealGetString(Ticket, DEAL_COMMENT);
        }
      }
    }
    return(true);
  }
  /*
    static bool CheckPositionOpenReason( void )
    {
      if ((MT4ORDERS::Order.OpenReason == UNKNOWN_REASON) || MT4ORDERS::CheckNewTicket())
      {
        MT4ORDERS::CheckPositionTicketOpen();
        const ulong Ticket = MT4ORDERS::Order.TicketOpen;
        if ((Ticket > 0) && (MT4ORDERS::IsTester || MT4ORDERS::HistorySelectDeal(Ticket)))
          MT4ORDERS::Order.OpenReason = (ENUM_DEAL_REASON)::HistoryDealGetInteger(Ticket, DEAL_REASON);
      }
      return(true);
    }
  */
  static bool        CheckPositionOpenPriceRequest( void )
  {
    const long PosTicket = ::PositionGetInteger(POSITION_TICKET);
    if (((MT4ORDERS::Order.OpenPriceRequest == UNKNOWN_REQUEST_PRICE) || MT4ORDERS::CheckNewTicket()) &&
        !(MT4ORDERS::Order.OpenPriceRequest = (_B2(MT4ORDERS::HistorySelectOrder(PosTicket)) &&
            (MT4ORDERS::IsTester || (::PositionGetInteger(POSITION_TIME_MSC) ==
                                     ::HistoryOrderGetInteger(PosTicket, ORDER_TIME_DONE_MSC)))) // А нужна ли эта проверка?
            ? ::HistoryOrderGetDouble(PosTicket, ORDER_PRICE_OPEN)
            : ::PositionGetDouble(POSITION_PRICE_OPEN)))
      MT4ORDERS::Order.OpenPriceRequest = ::PositionGetDouble(POSITION_PRICE_OPEN); // На случай, если цена ордера нулевая
    return(true);
  }
  static void        GetPositionData( void )
  {
    MT4ORDERS::Order.Ticket = POSITION_SELECT;
    MT4ORDERS::Order.Commission = UNKNOWN_COMMISSION; // MT4ORDERS::CheckPositionCommissionComment();
    MT4ORDERS::Order.OpenPriceRequest = UNKNOWN_REQUEST_PRICE; // MT4ORDERS::CheckPositionOpenPriceRequest()
    MT4ORDERS::Order.TicketOpen = UNKNOWN_TICKET;
//    MT4ORDERS::Order.OpenReason = UNKNOWN_REASON;
//    const bool AntoWarning = ::OrderSelect(0); // Обнуляет данные выбранной позиции - может быть нужно для OrderModify
    return;
  }
// #undef UNKNOWN_REASON
#undef UNKNOWN_TICKET
#undef UNKNOWN_REQUEST_PRICE
#undef UNKNOWN_COMMISSION
  static void        GetOrderData( void )
  {
    MT4ORDERS::Order.Ticket = ORDER_SELECT;
//    ::PositionSelectByTicket(0); // Обнуляет данные выбранной позиции - может быть нужно для OrderModify
    return;
  }
  static void        GetHistoryOrderData( const ulong Ticket )
  {
    MT4ORDERS::Order.Ticket = ::HistoryOrderGetInteger(Ticket, ORDER_TICKET);
    MT4ORDERS::Order.Type = (int)::HistoryOrderGetInteger(Ticket, ORDER_TYPE);
    MT4ORDERS::Order.TicketOpen = MT4ORDERS::Order.Ticket;
    MT4ORDERS::Order.TicketID = MT4ORDERS::Order.Ticket; // Удаленная отложка может иметь ненулевой POSITION_ID.
    MT4ORDERS::Order.Lots = ::HistoryOrderGetDouble(Ticket, ORDER_VOLUME_CURRENT);
    if (!MT4ORDERS::Order.Lots)
      MT4ORDERS::Order.Lots = ::HistoryOrderGetDouble(Ticket, ORDER_VOLUME_INITIAL);
    MT4ORDERS::Order.Symbol = ::HistoryOrderGetString(Ticket, ORDER_SYMBOL);
    MT4ORDERS::Order.Comment = ::HistoryOrderGetString(Ticket, ORDER_COMMENT);
    MT4ORDERS::Order.OpenTimeMsc = ::HistoryOrderGetInteger(Ticket, ORDER_TIME_SETUP_MSC);
    MT4ORDERS::Order.OpenTime = (datetime)(MT4ORDERS::Order.OpenTimeMsc / 1000);
    MT4ORDERS::Order.OpenPrice = ::HistoryOrderGetDouble(Ticket, ORDER_PRICE_OPEN);
    MT4ORDERS::Order.OpenPriceRequest = MT4ORDERS::Order.OpenPrice;
    MT4ORDERS::Order.OpenReason = (ENUM_DEAL_REASON)::HistoryOrderGetInteger(Ticket, ORDER_REASON);
    MT4ORDERS::Order.StopLoss = ::HistoryOrderGetDouble(Ticket, ORDER_SL);
    MT4ORDERS::Order.TakeProfit = ::HistoryOrderGetDouble(Ticket, ORDER_TP);
    MT4ORDERS::Order.CloseTimeMsc = ::HistoryOrderGetInteger(Ticket, ORDER_TIME_DONE_MSC);
    MT4ORDERS::Order.CloseTime = (datetime)(MT4ORDERS::Order.CloseTimeMsc / 1000);
    MT4ORDERS::Order.ClosePrice = ::HistoryOrderGetDouble(Ticket, ORDER_PRICE_CURRENT);
    MT4ORDERS::Order.ClosePriceRequest = MT4ORDERS::Order.ClosePrice;
    MT4ORDERS::Order.CloseReason = MT4ORDERS::Order.OpenReason;
    MT4ORDERS::Order.State = (ENUM_ORDER_STATE)::HistoryOrderGetInteger(Ticket, ORDER_STATE);
    MT4ORDERS::Order.Expiration = (datetime)::HistoryOrderGetInteger(Ticket, ORDER_TIME_EXPIRATION);
    MT4ORDERS::Order.MagicNumber = ::HistoryOrderGetInteger(Ticket, ORDER_MAGIC);
    MT4ORDERS::Order.Profit = 0;
    MT4ORDERS::Order.Commission = 0;
    MT4ORDERS::Order.Swap = 0;
    MT4ORDERS::Order.LotsOpen = ::HistoryOrderGetDouble(Ticket, ORDER_VOLUME_INITIAL);
    return;
  }
  static string      GetTickFlag( uint tickflag )
  {
    string flag = " " + (string)tickflag;
#define TICKFLAG_MACRO(A) flag += ((bool)(tickflag & TICK_FLAG_##A)) ? " TICK_FLAG_" + #A : ""; \
                            tickflag -= tickflag & TICK_FLAG_##A;
    TICKFLAG_MACRO(BID)
    TICKFLAG_MACRO(ASK)
    TICKFLAG_MACRO(LAST)
    TICKFLAG_MACRO(VOLUME)
    TICKFLAG_MACRO(BUY)
    TICKFLAG_MACRO(SELL)
#undef TICKFLAG_MACRO
    if (tickflag)
      flag += " FLAG_UNKNOWN (" + (string)tickflag + ")";
    return(flag);
  }
#define TOSTR(A) " " + #A + " = " + (string)Tick.A
#define TOSTR2(A) " " + #A + " = " + ::DoubleToString(Tick.A, digits)
#define TOSTR3(A) " " + #A + " = " + (string)(A)
  static string      TickToString( const string &Symb, const MqlTick &Tick )
  {
    const int digits = (int)::SymbolInfoInteger(Symb, SYMBOL_DIGITS);
    return(TOSTR3(Symb) + TOSTR(time) + "." + ::IntegerToString(Tick.time_msc % 1000, 3, '0') +
           TOSTR2(bid) + TOSTR2(ask) + TOSTR2(last)+ TOSTR(volume) + MT4ORDERS::GetTickFlag(Tick.flags));
  }
  static string      TickToString( const string &Symb )
  {
    MqlTick Tick = {};
    return(TOSTR3(::SymbolInfoTick(Symb, Tick)) + MT4ORDERS::TickToString(Symb, Tick));
  }
#undef TOSTR3
#undef TOSTR2
#undef TOSTR
  static void        AlertLog( void )
  {
    ::Alert("Please send the logs to the coauthor");
    string Str = ::TimeToString(::TimeLocal(), TIME_DATE);
    ::StringReplace(Str, ".", NULL);
    ::Alert(::TerminalInfoString(TERMINAL_PATH) + "\\MQL5\\Logs\\" + Str + ".log");
    return;
  }
  static long        GetTimeCurrent( void )
  {
    long Res = 0;
    MqlTick Tick = {};
    for (int i = ::SymbolsTotal(true) - 1; i >= 0; i--) {
      const string SymbName = ::SymbolName(i, true);
      if (!::SymbolInfoInteger(SymbName, SYMBOL_CUSTOM) && ::SymbolInfoTick(SymbName, Tick) && (Tick.time_msc > Res))
        Res = Tick.time_msc;
    }
    return(Res);
  }
  static string      TimeToString( const long time )
  {
    return((string)(datetime)(time / 1000) + "." + ::IntegerToString(time % 1000, 3, '0'));
  }
#define WHILE(A) while ((!(Res = (A))) && MT4ORDERS::Waiting())
#define TOSTR(A)  #A + " = " + (string)(A) + "\n"
#define TOSTR2(A) #A + " = " + ::EnumToString(A) + " (" + (string)(A) + ")\n"
  static ulong       GetFirstOrderTicket( void )
  {
    static ulong FirstOrderTicket = ULONG_MAX;
    static uint PrevTime = 0;
    const uint NewTime = ::GetTickCount();
    if (NewTime - PrevTime > 1000) {
      if ((FirstOrderTicket != ::HistoryOrderGetTicket(0)) && ::HistorySelect(0, INT_MAX))
        FirstOrderTicket = ::HistoryOrdersTotal() ? ::HistoryOrderGetTicket(0) : ULONG_MAX;
      PrevTime = NewTime;
    }
    return(FirstOrderTicket);
  }
  static bool        IsHistoryFull( const ulong &OrderTicket )
  {
    return(MT4ORDERS::IsTester || (OrderTicket >= MT4ORDERS::GetFirstOrderTicket())); // Если был живой ордер во время удаления истории брокером - плохо.
  }
  static void        GetHistoryPositionData( const ulong Ticket )
  {
    MT4ORDERS::Order.Ticket = (long)Ticket;
    MT4ORDERS::Order.TicketID = ::HistoryDealGetInteger(MT4ORDERS::Order.Ticket, DEAL_POSITION_ID);
    MT4ORDERS::Order.Type = (int)::HistoryDealGetInteger(Ticket, DEAL_TYPE);
    if ((MT4ORDERS::Order.Type > OP_SELL))
      MT4ORDERS::Order.Type += (OP_BALANCE - OP_SELL - 1);
    else
      MT4ORDERS::Order.Type = 1 - MT4ORDERS::Order.Type;
    MT4ORDERS::Order.Lots = ::HistoryDealGetDouble(Ticket, DEAL_VOLUME);
    MT4ORDERS::Order.Symbol = ::HistoryDealGetString(Ticket, DEAL_SYMBOL);
    MT4ORDERS::Order.Comment = ::HistoryDealGetString(Ticket, DEAL_COMMENT);
    MT4ORDERS::Order.CloseTimeMsc = ::HistoryDealGetInteger(Ticket, DEAL_TIME_MSC);
    MT4ORDERS::Order.CloseTime = (datetime)(MT4ORDERS::Order.CloseTimeMsc / 1000); // (datetime)::HistoryDealGetInteger(Ticket, DEAL_TIME);
    MT4ORDERS::Order.ClosePrice = ::HistoryDealGetDouble(Ticket, DEAL_PRICE);
    MT4ORDERS::Order.CloseReason = (ENUM_DEAL_REASON)::HistoryDealGetInteger(Ticket, DEAL_REASON);
    MT4ORDERS::Order.Expiration = 0;
    MT4ORDERS::Order.MagicNumber = ::HistoryDealGetInteger(Ticket, DEAL_MAGIC);
    MT4ORDERS::Order.Profit = ::HistoryDealGetDouble(Ticket, DEAL_PROFIT);
    MT4ORDERS::Order.Commission = ::HistoryDealGetDouble(Ticket, DEAL_COMMISSION);
    MT4ORDERS::Order.Swap = ::HistoryDealGetDouble(Ticket, DEAL_SWAP);
    MT4ORDERS::Order.StopLoss = MT4ORDERS::MTBuildSLTP ? ::HistoryDealGetDouble(Ticket, DEAL_SL) : 0;
    MT4ORDERS::Order.TakeProfit = MT4ORDERS::MTBuildSLTP ? ::HistoryDealGetDouble(Ticket, DEAL_TP) : 0;
    MT4ORDERS::Order.DealsAmount = 0;
    MT4ORDERS::Order.LotsOpen = MT4ORDERS::Order.Lots;
    const ulong OrderTicket = (MT4ORDERS::Order.Type < OP_BALANCE) ? ::HistoryDealGetInteger(Ticket, DEAL_ORDER) : 0; // Торговый DEAL_ORDER может быть нулевым.
    const ulong PosTicket = MT4ORDERS::Order.TicketID;
    const ulong OpenTicket = ((OrderTicket > 0) || (MT4ORDERS::Order.Type < OP_BALANCE)) ? _B2(MT4ORDERS::History.GetPositionDealIn(PosTicket, Ticket)) : 0;
    const bool IsOrderTicket = MT4ORDERS::IsHistoryFull(OrderTicket); // Не обрезана ли брокером история до этого тикета?
    if (OpenTicket > 0) {
      MT4ORDERS::Order.DealsAmount = MT4ORDERS::History.GetTicketDeals();
      MT4ORDERS::Order.LotsOpen = MT4ORDERS::History.GetTicketLots();
      const ENUM_DEAL_REASON Reason = MT4ORDERS::Order.CloseReason;
      const ENUM_DEAL_ENTRY DealEntry = (ENUM_DEAL_ENTRY)::HistoryDealGetInteger(Ticket, DEAL_ENTRY);
      // История (OpenTicket и OrderTicket) подгружена, благодаря GetPositionDealIn, - HistorySelectByPosition
#ifdef MT4ORDERS_FASTHISTORY_OFF
      const bool Res = true;
#else // MT4ORDERS_FASTHISTORY_OFF
      // Частичное исполнение породит нужный ордер - https://www.mql5.com/ru/forum/227423/page2#comment_6543129
      bool Res = MT4ORDERS::IsTester ? MT4ORDERS::HistorySelectOrder(OrderTicket) : (!IsOrderTicket || MT4ORDERS::Waiting(true));
      // Можно долго ждать в этой ситуации: https://www.mql5.com/ru/forum/170952/page184#comment_17913645
      if (!Res)
        WHILE(_B2(MT4ORDERS::HistorySelectOrder(OrderTicket))) // https://www.mql5.com/ru/forum/304239#comment_10710403
        ;
      if (_B2(MT4ORDERS::HistorySelectDeal(OpenTicket))) // Обязательно сработает, т.к. OpenTicket гарантированно в истории.
#endif // MT4ORDERS_FASTHISTORY_OFF
      {
        MT4ORDERS::Order.TicketOpen = (long)OpenTicket;
        MT4ORDERS::Order.OpenReason = (ENUM_DEAL_REASON)HistoryDealGetInteger(OpenTicket, DEAL_REASON);
        if (!MT4ORDERS::History.GetTicketPrice(MT4ORDERS::Order.OpenPrice))
          MT4ORDERS::Order.OpenPrice = ::HistoryDealGetDouble(OpenTicket, DEAL_PRICE);
        MT4ORDERS::Order.OpenTimeMsc = ::HistoryDealGetInteger(OpenTicket, DEAL_TIME_MSC);
        MT4ORDERS::Order.OpenTime = (datetime)(MT4ORDERS::Order.OpenTimeMsc / 1000);
        double OpenLots;
        double Commission;
        if (!MT4ORDERS::History.GetTicketCommission(Commission, OpenLots)) {
          Commission = ::HistoryDealGetDouble(OpenTicket, DEAL_COMMISSION);
          OpenLots = ::HistoryDealGetDouble(OpenTicket, DEAL_VOLUME);
          MT4ORDERS::Order.LotsOpen = OpenLots;
        }
        if (OpenLots > 0)
          MT4ORDERS::Order.Commission += Commission * MT4ORDERS::Order.Lots / OpenLots;
//        if (!MT4ORDERS::Order.MagicNumber) // Мэджик закрытой позиции всегда должен быть равен мэджику открывающей сделки.
        const long _Magik = ::HistoryDealGetInteger(OpenTicket, DEAL_MAGIC);
        if (_Magik)
          MT4ORDERS::Order.MagicNumber = _Magik;
//        if (MT4ORDERS::Order.Comment == "") // Комментарий закрытой позиции всегда должен быть равен комментарию открывающей сделки.
        const string StrComment = ::HistoryDealGetString(OpenTicket, DEAL_COMMENT);
        if (Res && (IsOrderTicket || !OrderTicket)) { // OrderTicket может не быть в истории, но может оказаться среди еще живых. Возможно, резонно оттуда выудить нужную инфу.
          double OrderPriceOpen = OrderTicket ? ::HistoryOrderGetDouble(OrderTicket, ORDER_PRICE_OPEN) : 0;
          if (!MT4ORDERS::MTBuildSLTP) {
            if (Reason == DEAL_REASON_TP) {
              if (!OrderPriceOpen)
                // https://www.mql5.com/ru/forum/1111/page2820#comment_17749873
                OrderPriceOpen = (double)::StringSubstr(MT4ORDERS::Order.Comment, MT4ORDERS::IsTester ? 3 : (::StringFind(MT4ORDERS::Order.Comment, "tp ") + 3));
              MT4ORDERS::Order.TakeProfit = OrderPriceOpen;
              MT4ORDERS::Order.StopLoss = ::HistoryOrderGetDouble(OrderTicket, ORDER_TP);
            } else if (Reason == DEAL_REASON_SL) {
              if (!OrderPriceOpen)
                // https://www.mql5.com/ru/forum/1111/page2820#comment_17749873
                OrderPriceOpen = (double)::StringSubstr(MT4ORDERS::Order.Comment, MT4ORDERS::IsTester ? 3 : (::StringFind(MT4ORDERS::Order.Comment, "sl ") + 3));
              MT4ORDERS::Order.StopLoss = OrderPriceOpen;
              MT4ORDERS::Order.TakeProfit = ::HistoryOrderGetDouble(OrderTicket, ORDER_SL);
            } else if (!MT4ORDERS::IsTester &&::StringLen(MT4ORDERS::Order.Comment) > 3) {
              const string PartComment = ::StringSubstr(MT4ORDERS::Order.Comment, 0, 3);
              if (PartComment == "[tp") {
                MT4ORDERS::Order.CloseReason = DEAL_REASON_TP;
                if (!OrderPriceOpen)
                  // https://www.mql5.com/ru/forum/1111/page2820#comment_17749873
                  OrderPriceOpen = (double)::StringSubstr(MT4ORDERS::Order.Comment, MT4ORDERS::IsTester ? 3 : (::StringFind(MT4ORDERS::Order.Comment, "tp ") + 3));
                MT4ORDERS::Order.TakeProfit = OrderPriceOpen;
                MT4ORDERS::Order.StopLoss = ::HistoryOrderGetDouble(OrderTicket, ORDER_TP);
              } else if (PartComment == "[sl") {
                MT4ORDERS::Order.CloseReason = DEAL_REASON_SL;
                if (!OrderPriceOpen)
                  // https://www.mql5.com/ru/forum/1111/page2820#comment_17749873
                  OrderPriceOpen = (double)::StringSubstr(MT4ORDERS::Order.Comment, MT4ORDERS::IsTester ? 3 : (::StringFind(MT4ORDERS::Order.Comment, "sl ") + 3));
                MT4ORDERS::Order.StopLoss = OrderPriceOpen;
                MT4ORDERS::Order.TakeProfit = ::HistoryOrderGetDouble(OrderTicket, ORDER_SL);
              } else {
                // Перевернуто - не ошибка: см. OrderClose.
                MT4ORDERS::Order.StopLoss = ::HistoryOrderGetDouble(OrderTicket, ORDER_TP);
                MT4ORDERS::Order.TakeProfit = ::HistoryOrderGetDouble(OrderTicket, ORDER_SL);
              }
            } else {
              // Перевернуто - не ошибка: см. OrderClose.
              MT4ORDERS::Order.StopLoss = ::HistoryOrderGetDouble(OrderTicket, ORDER_TP);
              MT4ORDERS::Order.TakeProfit = ::HistoryOrderGetDouble(OrderTicket, ORDER_SL);
            }
          } else if (!OrderPriceOpen) {
            if (Reason == DEAL_REASON_TP)
              OrderPriceOpen = MT4ORDERS::Order.TakeProfit;
            else if (Reason == DEAL_REASON_SL)
              OrderPriceOpen = MT4ORDERS::Order.StopLoss;
            else if (MT4ORDERS::Order.Comment[0] == '[') {
              if ((MT4ORDERS::Order.Comment[1] == 't') && (MT4ORDERS::Order.Comment[2] == 'p')) {
                OrderPriceOpen = MT4ORDERS::Order.TakeProfit;
                MT4ORDERS::Order.CloseReason = DEAL_REASON_TP;
              } else if ((MT4ORDERS::Order.Comment[1] == 's') && (MT4ORDERS::Order.Comment[2] == 'l')) {
                OrderPriceOpen = MT4ORDERS::Order.StopLoss;
                MT4ORDERS::Order.CloseReason = DEAL_REASON_SL;
              }
            }
          }
          MT4ORDERS::Order.State = OrderTicket ? (ENUM_ORDER_STATE)::HistoryOrderGetInteger(OrderTicket, ORDER_STATE) : ORDER_STATE_FILLED;
          if (!(MT4ORDERS::Order.ClosePriceRequest = (DealEntry == DEAL_ENTRY_OUT_BY) ? MT4ORDERS::Order.ClosePrice : OrderPriceOpen))
            MT4ORDERS::Order.ClosePriceRequest = MT4ORDERS::Order.ClosePrice;
          if (!(MT4ORDERS::Order.OpenPriceRequest = _B2(MT4ORDERS::HistorySelectOrder(PosTicket) &&
                // При частичном исполнении только последняя сделка полностью исполненного ордера имеет это условие для взятия цены запроса.
                (MT4ORDERS::IsTester || (::HistoryDealGetInteger(OpenTicket, DEAL_TIME_MSC) == ::HistoryOrderGetInteger(PosTicket, ORDER_TIME_DONE_MSC)))) ?
                ::HistoryOrderGetDouble(PosTicket, ORDER_PRICE_OPEN) : MT4ORDERS::Order.OpenPrice))
            MT4ORDERS::Order.OpenPriceRequest = MT4ORDERS::Order.OpenPrice;
        } else {
          MT4ORDERS::Order.State = ORDER_STATE_FILLED;
          MT4ORDERS::Order.ClosePriceRequest = MT4ORDERS::Order.ClosePrice;
          MT4ORDERS::Order.OpenPriceRequest = MT4ORDERS::Order.OpenPrice;
        }
        // Выше комментарий используется для нахождения SL/TP.
        if (StrComment != "")
          MT4ORDERS::Order.Comment = StrComment;
      }
      if (!Res) {
        ::Alert("HistoryOrderSelect(" + (string)OrderTicket + ") - BUG! MT4ORDERS - not Sync with History!");
        MT4ORDERS::AlertLog();
        ::Print(__FILE__ + "\nVersion = " + __MT4ORDERS__ + "\nCompiler = " + (string)__MQLBUILD__ + "\n" + TOSTR(__DATE__) +
                TOSTR(::AccountInfoString(ACCOUNT_SERVER)) + TOSTR2((ENUM_ACCOUNT_TRADE_MODE)::AccountInfoInteger(ACCOUNT_TRADE_MODE)) +
                TOSTR((bool)::TerminalInfoInteger(TERMINAL_CONNECTED)) +
                TOSTR(::TerminalInfoInteger(TERMINAL_PING_LAST)) + TOSTR(::TerminalInfoDouble(TERMINAL_RETRANSMISSION)) +
                TOSTR(::TerminalInfoInteger(TERMINAL_BUILD)) + TOSTR((bool)::TerminalInfoInteger(TERMINAL_X64)) +
                TOSTR((bool)::TerminalInfoInteger(TERMINAL_VPS)) + TOSTR2((ENUM_PROGRAM_TYPE)::MQLInfoInteger(MQL_PROGRAM_TYPE)) +
                TOSTR(::TimeCurrent()) + TOSTR(::TimeTradeServer()) + TOSTR(MT4ORDERS::TimeToString(MT4ORDERS::GetTimeCurrent())) +
                TOSTR(::SymbolInfoString(MT4ORDERS::Order.Symbol, SYMBOL_PATH)) + TOSTR(::SymbolInfoString(MT4ORDERS::Order.Symbol, SYMBOL_DESCRIPTION)) +
                "CurrentTick =" + MT4ORDERS::TickToString(MT4ORDERS::Order.Symbol) + "\n" +
                TOSTR(MT4ORDERS::HistorySelectOrder(OrderTicket)) + TOSTR(::OrderSelect(OrderTicket)) + // Влияют ли на результат вызовы функций ниже.
                TOSTR(::PositionsTotal()) + TOSTR(::OrdersTotal()) +
                TOSTR(::HistorySelect(0, INT_MAX)) + TOSTR(::HistoryDealsTotal()) + TOSTR(::HistoryOrdersTotal()) +
                TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE)) + TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL)) +
                TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_TOTAL)) + TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_USED)) +
                TOSTR(::MQLInfoInteger(MQL_MEMORY_LIMIT)) + TOSTR(::MQLInfoInteger(MQL_MEMORY_USED)) + TOSTR(::MQLInfoInteger(MQL_HANDLES_USED)) +
                TOSTR(Ticket) + TOSTR(OrderTicket) + TOSTR(OpenTicket) + TOSTR(PosTicket) +
                TOSTR(MT4ORDERS::TimeToString(MT4ORDERS::Order.CloseTimeMsc)) +
                TOSTR(MT4ORDERS::HistorySelectOrder(OrderTicket)) + TOSTR(::OrderSelect(OrderTicket)) + // Влияют ли на результат вызовы функций выше.
                TOSTR(MT4ORDERS::GetFirstOrderTicket()) +
                (::OrderSelect(OrderTicket) ? TOSTR2((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE)) : NULL) +
                (::HistoryDealsTotal() ? TOSTR(::HistoryDealGetTicket(::HistoryDealsTotal() - 1)) +
                 "DEAL_ORDER = " + (string)::HistoryDealGetInteger(::HistoryDealGetTicket(::HistoryDealsTotal() - 1), DEAL_ORDER) + "\n"
                 "DEAL_TIME_MSC = " + MT4ORDERS::TimeToString(::HistoryDealGetInteger(::HistoryDealGetTicket(::HistoryDealsTotal() - 1), DEAL_TIME_MSC)) + "\n"
                 : NULL) +
                (::HistoryOrdersTotal() ? TOSTR(::HistoryOrderGetTicket(::HistoryOrdersTotal() - 1)) +
                 "ORDER_TIME_DONE_MSC = " + MT4ORDERS::TimeToString(::HistoryOrderGetInteger(::HistoryOrderGetTicket(::HistoryOrdersTotal() - 1), ORDER_TIME_DONE_MSC)) + "\n"
                 : NULL) +
#ifdef MT4ORDERS_BYPASS_MAXTIME
                "MT4ORDERS::ByPass: " + MT4ORDERS::ByPass.ToString() + "\n" +
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
                TOSTR(MT4ORDERS::OrderSend_MaxPause) + TOSTR(MT4ORDERS::OrderSendBug));
      }
    } else {
      MT4ORDERS::Order.TicketOpen = MT4ORDERS::Order.Ticket;
      if (!MT4ORDERS::Order.TicketID && (MT4ORDERS::Order.Type <= OP_SELL)) // ID балансовых сделок должен оставаться нулевым.
        MT4ORDERS::Order.TicketID = MT4ORDERS::Order.Ticket;
      MT4ORDERS::Order.OpenPrice = MT4ORDERS::Order.ClosePrice; // ::HistoryDealGetDouble(Ticket, DEAL_PRICE);
      MT4ORDERS::Order.OpenTimeMsc = MT4ORDERS::Order.CloseTimeMsc;
      MT4ORDERS::Order.OpenTime = MT4ORDERS::Order.CloseTime;   // (datetime)::HistoryDealGetInteger(Ticket, DEAL_TIME);
      MT4ORDERS::Order.OpenReason = MT4ORDERS::Order.CloseReason;
      MT4ORDERS::Order.State = ORDER_STATE_FILLED;
      MT4ORDERS::Order.ClosePriceRequest = MT4ORDERS::Order.ClosePrice;
      MT4ORDERS::Order.OpenPriceRequest = MT4ORDERS::Order.OpenPrice;
    }
    if (OrderTicket && IsOrderTicket) {
      bool Res = MT4ORDERS::IsTester ? MT4ORDERS::HistorySelectOrder(OrderTicket) : MT4ORDERS::Waiting(true);
      if (!Res)
        WHILE(_B2(MT4ORDERS::HistorySelectOrder(OrderTicket))) // https://www.mql5.com/ru/forum/304239#comment_10710403
        ;
      if ((ENUM_ORDER_TYPE)::HistoryOrderGetInteger(OrderTicket, ORDER_TYPE) == ORDER_TYPE_CLOSE_BY) {
        const ulong PosTicketBy = ::HistoryOrderGetInteger(OrderTicket, ORDER_POSITION_BY_ID);
        if (PosTicketBy == PosTicket) { // CloseBy-Slave не должен влиять на торговый оборот. Master_DealTicket < Slave_DealTicket
          MT4ORDERS::Order.Lots = 0;
          MT4ORDERS::Order.Commission = 0;
          MT4ORDERS::Order.ClosePrice = MT4ORDERS::Order.OpenPrice;
          MT4ORDERS::Order.ClosePriceRequest = MT4ORDERS::Order.ClosePrice;
        } else { // CloseBy-Master должен получить комиссию (но не свопы!) от CloseBy-Slave.
          // Может быть несколько позиций с ID от CloseBy-Slave, поэтому во входных присутствует Master_DealTicket.
          const ulong OpenTicketBy = (OrderTicket > 0) ? _B2(MT4ORDERS::History.GetPositionDealIn(PosTicketBy, Ticket)) : 0;
          if ((OpenTicketBy > 0) && _B2(MT4ORDERS::HistorySelectDeal(OpenTicketBy))) {
            double OpenLots;
            double Commission;
            if (!MT4ORDERS::History.GetTicketCommission(Commission, OpenLots)) {
              Commission= ::HistoryDealGetDouble(OpenTicketBy, DEAL_COMMISSION) ;
              OpenLots = ::HistoryDealGetDouble(OpenTicketBy, DEAL_VOLUME);
            }
            if (OpenLots > 0)
              MT4ORDERS::Order.Commission += Commission * MT4ORDERS::Order.Lots / OpenLots;
          }
        }
      }
    }
    return;
  }
  static bool        Waiting( const bool FlagInit = false )
  {
    static ulong StartTime = 0;
    const bool Res = FlagInit ? false : (::GetMicrosecondCount() - StartTime < MT4ORDERS::OrderSend_MaxPause);
    if (FlagInit) {
      StartTime = ::GetMicrosecondCount();
      MT4ORDERS::OrderSendBug = 0;
    } else if (Res) {
//      ::Sleep(0); // https://www.mql5.com/ru/forum/170952/page100#comment_8750511
      MT4ORDERS::OrderSendBug++;
    }
    return(Res);
  }
  static bool        EqualPrices( const double Price1, const double &Price2, const int &digits)
  {
    return(!::NormalizeDouble(Price1 - Price2, digits));
  }
  static bool        HistoryDealSelect2( MqlTradeResult &Result ) // В конце названия цифра для большей совместимости с макросами.
  {
#ifdef MT4ORDERS_HISTORY_OLD
    // Заменить HistorySelectByPosition на HistorySelect(PosTime, PosTime)
    if (!Result.deal && Result.order && _B3(::HistorySelectByPosition(::HistoryOrderGetInteger(Result.order, ORDER_POSITION_ID)))) {
#else // #ifdef MT4ORDERS_HISTORY_OLD
    if (!Result.deal && Result.order && _B2(MT4ORDERS::HistorySelectOrder(Result.order))) {
      const long OrderTimeFill = ::HistoryOrderGetInteger(Result.order, ORDER_TIME_DONE_MSC);
#endif // #ifdef MT4ORDERS_HISTORY_OLD #else
      if (::HistorySelect(0, INT_MAX)) // Без этого сделку можно не обнаружить.
        for (int i = ::HistoryDealsTotal() - 1; i >= 0; i--) {
          const ulong DealTicket = ::HistoryDealGetTicket(i);
          if (Result.order == ::HistoryDealGetInteger(DealTicket, DEAL_ORDER)) {
            Result.deal = DealTicket;
            Result.price = ::HistoryDealGetDouble(DealTicket, DEAL_PRICE);
            break;
          }
#ifndef MT4ORDERS_HISTORY_OLD
          else if (::HistoryDealGetInteger(DealTicket, DEAL_TIME_MSC) < OrderTimeFill)
            break;
#endif // #ifndef MT4ORDERS_HISTORY_OLD
        }
    }
    return(_B2(MT4ORDERS::HistorySelectDeal(Result.deal)));
  }
  /*
  #define MT4ORDERS_BENCHMARK Alert(MT4ORDERS::LastTradeRequest.symbol + " " +       \
                                    (string)MT4ORDERS::LastTradeResult.order + " " + \
                                    MT4ORDERS::LastTradeResult.comment);             \
                              Print(ToString(MT4ORDERS::LastTradeRequest) +          \
                                    ToString(MT4ORDERS::LastTradeResult));
  */
#define TMP_MT4ORDERS_BENCHMARK(A) \
  static ulong Max##A = 0;         \
                                   \
  if (Interval##A > Max##A)        \
  {                                \
    MT4ORDERS_BENCHMARK            \
                                   \
    Max##A = Interval##A;          \
  }
  static void        OrderSend_Benchmark( const ulong &Interval1, const ulong &Interval2 )
  {
#ifdef MT4ORDERS_BENCHMARK
    TMP_MT4ORDERS_BENCHMARK(1)
    TMP_MT4ORDERS_BENCHMARK(2)
#endif // MT4ORDERS_BENCHMARK
    return;
  }
#undef TMP_MT4ORDERS_BENCHMARK
  static string      ToString( const MqlTradeRequest &Request )
  {
    return(TOSTR2(Request.action) + TOSTR(Request.magic) + TOSTR(Request.order) +
           TOSTR(Request.symbol) + TOSTR(Request.volume) + TOSTR(Request.price) +
           TOSTR(Request.stoplimit) + TOSTR(Request.sl) +  TOSTR(Request.tp) +
           TOSTR(Request.deviation) + TOSTR2(Request.type) + TOSTR2(Request.type_filling) +
           TOSTR2(Request.type_time) + TOSTR(Request.expiration) + TOSTR(Request.comment) +
           TOSTR(Request.position) + TOSTR(Request.position_by));
  }
  static string      ToString( const MqlTradeResult &Result )
  {
    return(TOSTR(Result.retcode) + TOSTR(Result.deal) + TOSTR(Result.order) +
           TOSTR(Result.volume) + TOSTR(Result.price) + TOSTR(Result.bid) +
           TOSTR(Result.ask) + TOSTR(Result.comment) + TOSTR(Result.request_id) +
           TOSTR(Result.retcode_external));
  }
  static bool        OrderSend( const MqlTradeRequest &Request, MqlTradeResult &Result )
  {
    const bool FlagCalc = !MT4ORDERS::IsTester && MT4ORDERS::OrderSend_MaxPause;
    MqlTick PrevTick = {};
    if (FlagCalc)
      ::SymbolInfoTick(Request.symbol, PrevTick); // Может тормозить.
    const long PrevTimeCurrent = FlagCalc ? _B2(MT4ORDERS::GetTimeCurrent()) : 0;
    const ulong StartTime1 = FlagCalc ? ::GetMicrosecondCount() : 0;
    bool Res = ::OrderSend(Request, Result);
    const ulong StartTime2 = FlagCalc ? ::GetMicrosecondCount() : 0;
    const ulong Interval1 = StartTime2 - StartTime1;
    if (FlagCalc && Res && (Result.retcode < TRADE_RETCODE_ERROR)) {
      Res = (Result.retcode == TRADE_RETCODE_DONE);
      MT4ORDERS::Waiting(true);
      // TRADE_ACTION_CLOSE_BY отсутствует в перечне проверок
      if (Request.action == TRADE_ACTION_DEAL) {
        if (!Result.deal) {
          WHILE(_B2(::OrderSelect(Result.order)) || _B2(MT4ORDERS::HistorySelectOrder(Result.order)))
          ;
          if (!Res)
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(::OrderSelect(Result.order)) + TOSTR(MT4ORDERS::HistorySelectOrder(Result.order)));
          else if (::OrderSelect(Result.order) && !(Res = ((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED) ||
                   ((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE) == ORDER_STATE_PARTIAL)))
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(::OrderSelect(Result.order)) + TOSTR2((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE)));
        }
        // Если после частичного исполнения оставшаяся часть осталась висеть - false.
        if (Res) {
          const bool ResultDeal = (!Result.deal) && (!MT4ORDERS::OrderSendBug);
          if (MT4ORDERS::OrderSendBug && (!Result.deal))
            ::Print("Line = " + (string)__LINE__ + "\n" + "Before ::HistoryOrderSelect(Result.order):\n" + TOSTR(MT4ORDERS::OrderSendBug) + TOSTR(Result.deal));
          WHILE(_B2(MT4ORDERS::HistorySelectOrder(Result.order)))
          ;
          // Если ранее не было OrderSend-бага и был Result.deal == 0
          if (ResultDeal)
            MT4ORDERS::OrderSendBug = 0;
          if (!Res)
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(MT4ORDERS::HistorySelectOrder(Result.order)) +
                    TOSTR(MT4ORDERS::HistorySelectDeal(Result.deal)) + TOSTR(::OrderSelect(Result.order)) + TOSTR(Result.deal));
          // Если исторический ордер не исполнился (отклонили) - false
          else if (!(Res = ((ENUM_ORDER_STATE)::HistoryOrderGetInteger(Result.order, ORDER_STATE) == ORDER_STATE_FILLED) ||
                           ((ENUM_ORDER_STATE)::HistoryOrderGetInteger(Result.order, ORDER_STATE) == ORDER_STATE_PARTIAL)))
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR2((ENUM_ORDER_STATE)::HistoryOrderGetInteger(Result.order, ORDER_STATE)));
        }
        if (Res) {
          const bool ResultDeal = (!Result.deal) && (!MT4ORDERS::OrderSendBug);
          if (MT4ORDERS::OrderSendBug && (!Result.deal))
            ::Print("Line = " + (string)__LINE__ + "\n" + "Before MT4ORDERS::HistoryDealSelect(Result):\n" + TOSTR(MT4ORDERS::OrderSendBug) + TOSTR(Result.deal));
          WHILE(MT4ORDERS::HistoryDealSelect2(Result))
          ;
          // Если ранее не было OrderSend-бага и был Result.deal == 0
          if (ResultDeal)
            MT4ORDERS::OrderSendBug = 0;
          if (!Res)
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(MT4ORDERS::HistoryDealSelect2(Result)));
        }
      } else if (Request.action == TRADE_ACTION_PENDING) {
        if (Res) {
          WHILE(_B2(::OrderSelect(Result.order)) || _B2(MT4ORDERS::HistorySelectOrder(Result.order))) // History - может исполниться.
          ;
          if (!Res) {
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(::OrderSelect(Result.order)));
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(MT4ORDERS::HistorySelectOrder(Result.order)));
          } else if (::OrderSelect(Result.order) &&
                     (!(Res = ((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED) ||
                              ((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE) == ORDER_STATE_PARTIAL))))
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR2((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE)));
        } else {
          WHILE(_B2(MT4ORDERS::HistorySelectOrder(Result.order)))
          ;
          ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(MT4ORDERS::HistorySelectOrder(Result.order)));
          Res = false;
        }
      } else if (Request.action == TRADE_ACTION_SLTP) {
        if (Res) {
          const int digits = (int)::SymbolInfoInteger(Request.symbol, SYMBOL_DIGITS);
          bool EqualSL = false;
          bool EqualTP = false;
          do
            if (Request.position ? _B2(::PositionSelectByTicket(Request.position)) : _B2(::PositionSelect(Request.symbol))) {
              EqualSL = MT4ORDERS::EqualPrices(::PositionGetDouble(POSITION_SL), Request.sl, digits);
              EqualTP = MT4ORDERS::EqualPrices(::PositionGetDouble(POSITION_TP), Request.tp, digits);
            }
          WHILE(EqualSL && EqualTP);
          if (!Res)
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(::PositionGetDouble(POSITION_SL)) + TOSTR(::PositionGetDouble(POSITION_TP)) +
                    TOSTR(EqualSL) + TOSTR(EqualTP) +
                    TOSTR(Request.position ? ::PositionSelectByTicket(Request.position) : ::PositionSelect(Request.symbol)));
        }
      } else if (Request.action == TRADE_ACTION_MODIFY) {
        if (Res) {
          const int digits = (int)::SymbolInfoInteger(Request.symbol, SYMBOL_DIGITS);
          bool EqualSL = false;
          bool EqualTP = false;
          bool EqualPrice = false;
          do
            if (_B2(::OrderSelect(Result.order))) {
              // https://www.mql5.com/ru/forum/170952/page184#comment_17913645
              if (((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE) != ORDER_STATE_REQUEST_MODIFY)) {
                EqualSL = MT4ORDERS::EqualPrices(::OrderGetDouble(ORDER_SL), Request.sl, digits);
                EqualTP = MT4ORDERS::EqualPrices(::OrderGetDouble(ORDER_TP), Request.tp, digits);
                EqualPrice = MT4ORDERS::EqualPrices(::OrderGetDouble(ORDER_PRICE_OPEN), Request.price, digits);
              }
            } else if (_B2(MT4ORDERS::HistorySelectOrder(Result.order))) { // History - может исполниться.
              EqualSL = true;
              EqualTP = true;
              EqualPrice = true;
            }
          WHILE((EqualSL && EqualTP && EqualPrice));
          if (!Res) {
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(::OrderSelect(Result.order)));
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(MT4ORDERS::HistorySelectOrder(Result.order)));
            ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(::OrderGetDouble(ORDER_SL)) + TOSTR(Request.sl)+
                    TOSTR(::OrderGetDouble(ORDER_TP)) + TOSTR(Request.tp) +
                    TOSTR(::OrderGetDouble(ORDER_PRICE_OPEN)) + TOSTR(Request.price) +
                    TOSTR(EqualSL) + TOSTR(EqualTP) + TOSTR(EqualPrice) +
                    TOSTR(::OrderSelect(Result.order)) +
                    TOSTR2((ENUM_ORDER_STATE)::OrderGetInteger(ORDER_STATE)));
          }
        }
      } else if (Request.action == TRADE_ACTION_REMOVE) {
        if (Res)
          WHILE(_B2(MT4ORDERS::HistorySelectOrder(Result.order)))
          ;
        if (!Res)
          ::Print("Line = " + (string)__LINE__ + "\n" + TOSTR(MT4ORDERS::HistorySelectOrder(Result.order)));
      }
      const ulong Interval2 = ::GetMicrosecondCount() - StartTime2;
      Result.comment += " " + ::DoubleToString(Interval1 / 1000.0, 3) + " + " +
                        ::DoubleToString(Interval2 / 1000.0, 3) + " (" + (string)MT4ORDERS::OrderSendBug + ") ms.";
      if (!Res || MT4ORDERS::OrderSendBug) {
        ::Alert(Res ? "OrderSend(" + (string)Result.order + ") - BUG!" : "MT4ORDERS - not Sync with History!");
        MT4ORDERS::AlertLog();
        ::Print(__FILE__ + "\nVersion = " + __MT4ORDERS__ + "\nCompiler = " + (string)__MQLBUILD__ + "\n" + TOSTR(__DATE__) +
                TOSTR(::AccountInfoString(ACCOUNT_SERVER)) + TOSTR2((ENUM_ACCOUNT_TRADE_MODE)::AccountInfoInteger(ACCOUNT_TRADE_MODE)) +
                TOSTR((bool)::TerminalInfoInteger(TERMINAL_CONNECTED)) +
                TOSTR(::TerminalInfoInteger(TERMINAL_PING_LAST)) + TOSTR(::TerminalInfoDouble(TERMINAL_RETRANSMISSION)) +
                TOSTR(::TerminalInfoInteger(TERMINAL_BUILD)) + TOSTR((bool)::TerminalInfoInteger(TERMINAL_X64)) +
                TOSTR((bool)::TerminalInfoInteger(TERMINAL_VPS)) + TOSTR2((ENUM_PROGRAM_TYPE)::MQLInfoInteger(MQL_PROGRAM_TYPE)) +
                TOSTR(::TimeCurrent()) + TOSTR(::TimeTradeServer()) +
                TOSTR(MT4ORDERS::TimeToString(MT4ORDERS::GetTimeCurrent())) + TOSTR(MT4ORDERS::TimeToString(PrevTimeCurrent)) +
                "PrevTick =" + MT4ORDERS::TickToString(Request.symbol, PrevTick) + "\n" +
                "CurrentTick =" + MT4ORDERS::TickToString(Request.symbol) + "\n" +
                TOSTR(::SymbolInfoString(Request.symbol, SYMBOL_PATH)) + TOSTR(::SymbolInfoString(Request.symbol, SYMBOL_DESCRIPTION)) +
                TOSTR(::PositionsTotal()) + TOSTR(::OrdersTotal()) +
                TOSTR(::HistorySelect(0, INT_MAX)) + TOSTR(::HistoryDealsTotal()) + TOSTR(::HistoryOrdersTotal()) +
                (::HistoryDealsTotal() ? TOSTR(::HistoryDealGetTicket(::HistoryDealsTotal() - 1)) +
                 "DEAL_ORDER = " + (string)::HistoryDealGetInteger(::HistoryDealGetTicket(::HistoryDealsTotal() - 1), DEAL_ORDER) + "\n"
                 "DEAL_TIME_MSC = " + MT4ORDERS::TimeToString(::HistoryDealGetInteger(::HistoryDealGetTicket(::HistoryDealsTotal() - 1), DEAL_TIME_MSC)) + "\n"
                 : NULL) +
                (::HistoryOrdersTotal() ? TOSTR(::HistoryOrderGetTicket(::HistoryOrdersTotal() - 1)) +
                 "ORDER_TIME_DONE_MSC = " + MT4ORDERS::TimeToString(::HistoryOrderGetInteger(::HistoryOrderGetTicket(::HistoryOrdersTotal() - 1), ORDER_TIME_DONE_MSC)) + "\n"
                 : NULL) +
                TOSTR(MT4ORDERS::GetFirstOrderTicket()) +
                TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE)) + TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL)) +
                TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_TOTAL)) + TOSTR(::TerminalInfoInteger(TERMINAL_MEMORY_USED)) + TOSTR(::MQLInfoInteger(MQL_HANDLES_USED)) +
                TOSTR(::MQLInfoInteger(MQL_MEMORY_LIMIT)) + TOSTR(::MQLInfoInteger(MQL_MEMORY_USED)) +
                TOSTR(MT4ORDERS::IsHedging) + TOSTR(Res) + TOSTR(MT4ORDERS::OrderSendBug) +
                MT4ORDERS::ToString(Request) + MT4ORDERS::ToString(Result) +
#ifdef MT4ORDERS_BYPASS_MAXTIME
                "MT4ORDERS::ByPass: " + MT4ORDERS::ByPass.ToString() + "\n" +
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
                TOSTR(MT4ORDERS::OrderSend_MaxPause));
      } else
        MT4ORDERS::OrderSend_Benchmark(Interval1, Interval2);
    } else if (FlagCalc) {
      Result.comment += " " + ::DoubleToString(Interval1 / 1000.0, 3) + " ms";
      ::Print(TOSTR(::TimeCurrent()) + TOSTR(::TimeTradeServer()) + TOSTR(MT4ORDERS::TimeToString(PrevTimeCurrent)) +
              MT4ORDERS::TickToString(Request.symbol, PrevTick) + "\n" + MT4ORDERS::TickToString(Request.symbol) + "\n" +
              MT4ORDERS::ToString(Request) + MT4ORDERS::ToString(Result));
//      ExpertRemove();
    }
    return(Res);
  }
#undef TOSTR2
#undef TOSTR
#undef WHILE
  static ENUM_DAY_OF_WEEK GetDayOfWeek( const datetime &time )
  {
    return((ENUM_DAY_OF_WEEK)((time / (24 * 3600) + THURSDAY) % 7));
  }
  static bool        SessionTrade( const string &Symb )
  {
    datetime TimeNow = ::TimeCurrent();
    const ENUM_DAY_OF_WEEK DayOfWeek = MT4ORDERS::GetDayOfWeek(TimeNow);
    TimeNow %= 24 * 60 * 60;
    bool Res = false;
    datetime From, To;
    for (int i = 0; (!Res) && ::SymbolInfoSessionTrade(Symb, DayOfWeek, i, From, To); i++)
      Res = ((From <= TimeNow) && (TimeNow < To));
    return(Res);
  }
  static bool        SymbolTrade( const string &Symb )
  {
    MqlTick Tick;
    return(::SymbolInfoTick(Symb, Tick) ? (Tick.bid && Tick.ask && MT4ORDERS::SessionTrade(Symb) /* &&
           ((ENUM_SYMBOL_TRADE_MODE)::SymbolInfoInteger(Symb, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL) */) : false);
  }
  static bool        CorrectResult( void )
  {
    ::ZeroMemory(MT4ORDERS::LastTradeResult);
    MT4ORDERS::LastTradeResult.retcode = MT4ORDERS::LastTradeCheckResult.retcode;
    MT4ORDERS::LastTradeResult.comment = MT4ORDERS::LastTradeCheckResult.comment;
    return(false);
  }
  static bool        NewOrderCheck( void )
  {
    return((::OrderCheck(MT4ORDERS::LastTradeRequest, MT4ORDERS::LastTradeCheckResult) &&
            (MT4ORDERS::IsTester || MT4ORDERS::SymbolTrade(MT4ORDERS::LastTradeRequest.symbol))) ||
           (!MT4ORDERS::IsTester && MT4ORDERS::CorrectResult()));
  }
  static bool        NewOrderSend( const int &Check )
  {
    return((Check == INT_MAX) ? MT4ORDERS::NewOrderCheck() :
           ((
#ifndef MT4ORDERS_AUTO_VALIDATION
              (Check != INT_MIN) ||
#endif // #ifndef MT4ORDERS_AUTO_VALIDATION
              MT4ORDERS::NewOrderCheck()) && MT4ORDERS::OrderSend(MT4ORDERS::LastTradeRequest, MT4ORDERS::LastTradeResult)
            ? (MT4ORDERS::LastTradeResult.retcode < TRADE_RETCODE_ERROR)
#ifdef MT4ORDERS_BYPASS_MAXTIME
            && _B2(MT4ORDERS::ByPass += MT4ORDERS::LastTradeResult.order)
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
            : false));
  }
  static bool        ModifyPosition( const long &Ticket, MqlTradeRequest &Request )
  {
    const bool Res = _B2(::PositionSelectByTicket(Ticket));
    if (Res) {
      Request.action = TRADE_ACTION_SLTP;
      Request.position = Ticket;
      Request.symbol = ::PositionGetString(POSITION_SYMBOL); // указания одного тикета не достаточно!
    }
    return(Res);
  }
  static ENUM_ORDER_TYPE_FILLING GetFilling( const string &Symb, const uint Type = ORDER_FILLING_FOK )
  {
    static ENUM_ORDER_TYPE_FILLING Res = ORDER_FILLING_FOK;
    static string LastSymb = NULL;
    static uint LastType = ORDER_FILLING_FOK;
    const bool SymbFlag = (LastSymb != Symb);
    if (SymbFlag || (LastType != Type)) { // Можно немного ускорить, поменяв очередность проверки условия.
      LastType = Type;
      if (SymbFlag)
        LastSymb = Symb;
      const ENUM_SYMBOL_TRADE_EXECUTION ExeMode = (ENUM_SYMBOL_TRADE_EXECUTION)::SymbolInfoInteger(Symb, SYMBOL_TRADE_EXEMODE);
      const int FillingMode = (int)::SymbolInfoInteger(Symb, SYMBOL_FILLING_MODE);
      Res = (!FillingMode || (Type >= ORDER_FILLING_RETURN) || ((FillingMode & (Type + 1)) != Type + 1)) ?
            (((ExeMode == SYMBOL_TRADE_EXECUTION_EXCHANGE) || (ExeMode == SYMBOL_TRADE_EXECUTION_INSTANT)) ?
             ORDER_FILLING_RETURN : ((FillingMode == SYMBOL_FILLING_IOC) ? ORDER_FILLING_IOC : ORDER_FILLING_FOK)) :
            (ENUM_ORDER_TYPE_FILLING)Type;
    }
    return(Res);
  }
  static ENUM_ORDER_TYPE_TIME GetExpirationType( const string &Symb, uint Expiration = ORDER_TIME_GTC )
  {
    static ENUM_ORDER_TYPE_TIME Res = ORDER_TIME_GTC;
    static string LastSymb = NULL;
    static uint LastExpiration = ORDER_TIME_GTC;
    const bool SymbFlag = (LastSymb != Symb);
    if ((LastExpiration != Expiration) || SymbFlag) {
      LastExpiration = Expiration;
      if (SymbFlag)
        LastSymb = Symb;
      const int ExpirationMode = (int)::SymbolInfoInteger(Symb, SYMBOL_EXPIRATION_MODE);
      if ((Expiration > ORDER_TIME_SPECIFIED_DAY) || (!((ExpirationMode >> Expiration) & 1))) {
        if ((Expiration < ORDER_TIME_SPECIFIED) || (ExpirationMode < SYMBOL_EXPIRATION_SPECIFIED))
          Expiration = ORDER_TIME_GTC;
        else if (Expiration > ORDER_TIME_DAY)
          Expiration = ORDER_TIME_SPECIFIED;
        uint i = 1 << Expiration;
        while ((Expiration <= ORDER_TIME_SPECIFIED_DAY) && ((ExpirationMode & i) != i)) {
          i <<= 1;
          Expiration++;
        }
      }
      Res = (ENUM_ORDER_TYPE_TIME)Expiration;
    }
    return(Res);
  }
  static bool        ModifyOrder( const long Ticket, const double &Price, const datetime &Expiration, MqlTradeRequest &Request )
  {
    const bool Res = _B2(::OrderSelect(Ticket));
    if (Res) {
      Request.action = TRADE_ACTION_MODIFY;
      Request.order = Ticket;
      Request.price = Price;
      Request.symbol = ::OrderGetString(ORDER_SYMBOL);
      // https://www.mql5.com/ru/forum/1111/page1817#comment_4087275
//      Request.type_filling = (ENUM_ORDER_TYPE_FILLING)::OrderGetInteger(ORDER_TYPE_FILLING);
      Request.type_filling = _B2(MT4ORDERS::GetFilling(Request.symbol));
      Request.type_time = _B2(MT4ORDERS::GetExpirationType(Request.symbol, (uint)Expiration));
      if (Expiration > ORDER_TIME_DAY)
        Request.expiration = Expiration;
    }
    return(Res);
  }
  static bool        SelectByPosHistory( const int Index )
  {
    const long Ticket = MT4ORDERS::History[Index];
    const bool Res = (Ticket > 0) ? _B2(MT4ORDERS::HistorySelectDeal(Ticket)) : ((Ticket < 0) && _B2(MT4ORDERS::HistorySelectOrder(-Ticket)));
    if (Res) {
      if (Ticket > 0)
        _BV2(MT4ORDERS::GetHistoryPositionData(Ticket))
        else
          _BV2(MT4ORDERS::GetHistoryOrderData(-Ticket))
        }
    return(Res);
  }
  // https://www.mql5.com/ru/forum/227960#comment_6603506
  static bool        OrderVisible( void )
  {
    // Если позиция закрылась при живой частично исполненной отложке, что ее породила.
    // А после оставшаяся часть отложки полностью исполнилась, но не успела исчезнуть.
    // То будет видна и новая позиция (правильно) и не исчезнувшая отложка (неправильно).
    const ulong PositionID = ::OrderGetInteger(ORDER_POSITION_ID);
    const ENUM_ORDER_TYPE Type = (ENUM_ORDER_TYPE)::OrderGetInteger(ORDER_TYPE);
    ulong Ticket = 0;
    return(!((Type == ORDER_TYPE_CLOSE_BY) ||
             (PositionID && // Partial-отложенник имеет ненулевой PositionID.
              (Type <= ORDER_TYPE_SELL) && // Закрывающие маркет-ордера игнорируем
              ((Ticket = ::OrderGetInteger(ORDER_TICKET)) != PositionID))) && // Открывающие частично исполненные маркет-ордера не игнорируем.
           // Открывающий/доливающий позицию ордер может не успеть исчезнуть.
           (!::PositionsTotal() || !(::PositionSelectByTicket(Ticket ? Ticket : ::OrderGetInteger(ORDER_TICKET)) &&
//                                     (::PositionGetInteger(POSITION_TYPE) == (::OrderGetInteger(ORDER_TYPE) & 1)) &&
//                                     (::PositionGetInteger(POSITION_TIME_MSC) >= ::OrderGetInteger(ORDER_TIME_SETUP_MSC)) &&
                                     (::PositionGetDouble(POSITION_VOLUME) == ::OrderGetDouble(ORDER_VOLUME_INITIAL)))));
  }
  static ulong       OrderGetTicket( const int Index )
  {
    ulong Res;
    int PrevTotal;
    const long PrevTicket = ::OrderGetInteger(ORDER_TICKET);
    const long PositionTicket = ::PositionGetInteger(POSITION_TICKET);
    do {
      Res = 0;
      PrevTotal = ::OrdersTotal();
      if ((Index >= 0) && (Index < PrevTotal)) {
        int Count = 0;
        for (int i = 0; i < PrevTotal; i++) {
          const int Total = ::OrdersTotal();
          // Во время перебора может измениться количество ордеров
          if (Total != PrevTotal) {
            PrevTotal = -1;
            break;
          } else {
            const ulong Ticket = ::OrderGetTicket(i);
            if (Ticket && MT4ORDERS::OrderVisible()) {
              if (Count == Index) {
                Res = Ticket;
                break;
              }
              Count++;
            }
          }
        }
#ifdef MT4ORDERS_BYPASS_MAXTIME
        _B2(MT4ORDERS::ByPass.Waiting()); // Изменяет ORDER_TICKET.
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
      }
    } while (PrevTotal != ::OrdersTotal()); // Во время перебора может измениться количество ордеров
    if (!Res) {
      // При неудаче выбираем тот ордер, что был выбран ранее.
      if (PrevTicket && (::OrderGetInteger(ORDER_TICKET) != PrevTicket))
        const bool AntiWarning = _B2(::OrderSelect(PrevTicket));
    }
#ifdef MT4ORDERS_BYPASS_MAXTIME
    else if (::OrderGetInteger(ORDER_TICKET) != Res)
      const bool AntiWarning = _B2(::OrderSelect(Res)); // MT4ORDERS::ByPass.Waiting() изменяет ORDER_TICKET.
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
    // MT4ORDERS::OrderVisible() меняет выбор позиции.
    if (PositionTicket && (::PositionGetInteger(POSITION_TICKET) != PositionTicket))
      ::PositionSelectByTicket(PositionTicket);
    return(Res);
  }
  // С одним и тем же тикетом приоритет выбора позиции выше ордера
  static bool        SelectByPos( const int Index )
  {
    bool Flag = (Index == INT_MAX);
    bool Res = Flag || (Index == INT_MIN);
    if (!Res) {
      if (MT4ORDERS::IsTester) {
        const int Total = ::PositionsTotal();
        Flag = (Index < Total);
        Res = Flag ? ::PositionGetTicket(Index) : ::OrderGetTicket(Index - Total);
      } else {
        int Total;
        do {
          Total = ::PositionsTotal();
          Flag = (Index < Total);
          if (Flag)
            Res = _B2(::PositionGetTicket(Index));
          else {
            const int Index2 = Index - Total;
            const int Total2 = ::OrdersTotal();
            if ((Index2 >= 0) && (Index2 < Total2)) {
#ifdef MT4ORDERS_SELECTFILTER_OFF
              Res = ::OrderGetTicket(Index2);
#else // MT4ORDERS_SELECTFILTER_OFF
              Res = _B2(MT4ORDERS::OrderGetTicket(Index2));
#endif //MT4ORDERS_SELECTFILTER_OFF
            } else
              Res = 0;
          }
        } while (Total != ::PositionsTotal()); // Во время перебора может измениться количество позиций.
      }
    }
    if (Res) {
      if (Flag)
        MT4ORDERS::GetPositionData(); // (Index == INT_MAX) - переход на MT5-позицию без проверки существования и обновления.
      else
        MT4ORDERS::GetOrderData();    // (Index == INT_MIN) - переход на живой MT5-ордер без проверки существования и обновления.
    }
    return(Res);
  }
  static bool        SelectByHistoryTicket( const long &Ticket )
  {
    bool Res = false;
    if (!Ticket) { // Выбор по OrderTicketID (по нулевому значению - балансовые операции).
      const ulong TicketDealOut = MT4ORDERS::History.GetPositionDealOut(Ticket);
      if (Res = _B2(MT4ORDERS::HistorySelectDeal(TicketDealOut)))
        _BV2(MT4ORDERS::GetHistoryPositionData(TicketDealOut));
    } else if (_B2(MT4ORDERS::HistorySelectDeal(Ticket))) {
#ifdef MT4ORDERS_TESTER_SELECT_BY_TICKET
      // В Тестере при поиске закрытой позиции нужно искать сначала по PositionID из-за близкой нумерации тикетов MT5-сделок/ордеров.
      if (MT4ORDERS::IsTester) {
        const ulong TicketDealOut = MT4ORDERS::History.GetPositionDealOut(HistoryOrderGetInteger(Ticket, ORDER_POSITION_ID));
        if (Res = _B2(MT4ORDERS::HistorySelectDeal(TicketDealOut)))
          _BV2(MT4ORDERS::GetHistoryPositionData(TicketDealOut));
      }
      if (!Res)
#endif // #ifdef MT4ORDERS_TESTER_SELECT_BY_TICKET
      {
        if (Res = MT4HISTORY::IsMT4Deal(Ticket))
          _BV2(MT4ORDERS::GetHistoryPositionData(Ticket))
          else { // DealIn
            const ulong TicketDealOut = MT4ORDERS::History.GetPositionDealOut(HistoryDealGetInteger(Ticket, DEAL_POSITION_ID)); // Выбор по DealIn
            if (Res = _B2(MT4ORDERS::HistorySelectDeal(TicketDealOut)))
              _BV2(MT4ORDERS::GetHistoryPositionData(TicketDealOut))
            }
      }
    } else if (_B2(MT4ORDERS::HistorySelectOrder(Ticket))) {
      if (Res = MT4HISTORY::IsMT4Order(Ticket))
        _BV2(MT4ORDERS::GetHistoryOrderData(Ticket))
        else {
          const ulong TicketDealOut = MT4ORDERS::History.GetPositionDealOut(HistoryOrderGetInteger(Ticket, ORDER_POSITION_ID));
          if (Res = _B2(MT4ORDERS::HistorySelectDeal(TicketDealOut)))
            _BV2(MT4ORDERS::GetHistoryPositionData(TicketDealOut));
        }
    } else {
      // Выбор по OrderTicketID или тикету исполненной отложки - актуально для Неттинга.
      const ulong TicketDealOut = MT4ORDERS::History.GetPositionDealOut(Ticket);
      if (Res = _B2(MT4ORDERS::HistorySelectDeal(TicketDealOut)))
        _BV2(MT4ORDERS::GetHistoryPositionData(TicketDealOut));
    }
    return(Res);
  }
  static bool        SelectByExistingTicket( const long &Ticket )
  {
    bool Res = true;
    if (Ticket < 0) {
      if (_B2(::OrderSelect(-Ticket)))
        MT4ORDERS::GetOrderData();
      else if (_B2(::PositionSelectByTicket(-Ticket)))
        MT4ORDERS::GetPositionData();
      else
        Res = false;
    } else if (_B2(::PositionSelectByTicket(Ticket)))
      MT4ORDERS::GetPositionData();
    else if (_B2(::OrderSelect(Ticket)))
      MT4ORDERS::GetOrderData();
    else if (_B2(MT4ORDERS::HistorySelectDeal(Ticket))) {
#ifdef MT4ORDERS_TESTER_SELECT_BY_TICKET
      // В Тестере при поиске закрытой позиции нужно искать сначала по PositionID из-за близкой нумерации тикетов MT5-сделок/ордеров.
      if (Res = !MT4ORDERS::IsTester)
#endif // #ifdef MT4ORDERS_TESTER_SELECT_BY_TICKET
      {
        if (MT4HISTORY::IsMT4Deal(Ticket)) // Если сделан выбор по DealOut.
          _BV2(MT4ORDERS::GetHistoryPositionData(Ticket))
          else if (_B2(::PositionSelectByTicket(::HistoryDealGetInteger(Ticket, DEAL_POSITION_ID)))) // Выбор по DealIn
            MT4ORDERS::GetPositionData();
          else
            Res = false;
      }
    } else if (_B2(MT4ORDERS::HistorySelectOrder(Ticket)) && _B2(::PositionSelectByTicket(::HistoryOrderGetInteger(Ticket, ORDER_POSITION_ID)))) // Выбор по тикету MT5-ордера
      MT4ORDERS::GetPositionData();
    else
      Res = false;
    return(Res);
  }
  // С одним и тем же тикетом приоритеты выбора:
  // MODE_TRADES:  существующая позиция > существующий ордер > сделка > отмененный ордер
  // MODE_HISTORY: сделка > отмененный ордер > существующая позиция > существующий ордер
  static bool        SelectByTicket( const long &Ticket, const int &Pool )
  {
    return((Pool == MODE_TRADES) || (Ticket < 0) ?
           (_B2(MT4ORDERS::SelectByExistingTicket(Ticket)) || ((Ticket > 0) && _B2(MT4ORDERS::SelectByHistoryTicket(Ticket)))) :
           (_B2(MT4ORDERS::SelectByHistoryTicket(Ticket)) || _B2(MT4ORDERS::SelectByExistingTicket(Ticket))));
  }
  static void        CheckPrices( double &MinPrice, double &MaxPrice, const double Min, const double Max )
  {
    if (MinPrice && (MinPrice >= Min))
      MinPrice = 0;
    if (MaxPrice && (MaxPrice <= Max))
      MaxPrice = 0;
    return;
  }
  static int         OrdersTotal( void )
  {
    int Res = 0;
    int PrevTotal = ::OrdersTotal();
    if (PrevTotal) {
      const long PrevTicket = ::OrderGetInteger(ORDER_TICKET);
      const long PositionTicket = ::PositionGetInteger(POSITION_TICKET);
      do {
        PrevTotal = ::OrdersTotal();
        for (int i = PrevTotal - 1; i >= 0; i--) {
          // Во время перебора может измениться количество ордеров
          if (PrevTotal != ::OrdersTotal()) {
            PrevTotal = -1;
            Res = 0;
            break;
          } else if (::OrderGetTicket(i) && MT4ORDERS::OrderVisible())
            Res++;
        }
#ifdef MT4ORDERS_BYPASS_MAXTIME
        if (PrevTotal)
          _B2(MT4ORDERS::ByPass.Waiting());
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
      } while (PrevTotal && (PrevTotal != ::OrdersTotal())); // Во время перебора может измениться количество ордеров
      if (PrevTicket && (::OrderGetInteger(ORDER_TICKET) != PrevTicket))
        const bool AntiWarning = _B2(::OrderSelect(PrevTicket));
      // MT4ORDERS::OrderVisible() меняет выбор позиции.
      if (PositionTicket && (::PositionGetInteger(POSITION_TICKET) != PositionTicket))
        ::PositionSelectByTicket(PositionTicket);
    }
    return(Res);
  }
public:
  static uint        OrderSend_MaxPause; // максимальное время на синхронизацию в мкс.
#ifdef MT4ORDERS_BYPASS_MAXTIME
  static BYPASS      ByPass;
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
  static MqlTradeResult LastTradeResult;
  static MqlTradeRequest LastTradeRequest;
  static MqlTradeCheckResult LastTradeCheckResult;
  static bool        MT4OrderSelect( const long &Index, const int &Select, const int &Pool )
  {
    return(
#ifdef MT4ORDERS_BYPASS_MAXTIME
            (MT4ORDERS::IsTester || ((Select == SELECT_BY_POS) && ((Index == INT_MIN) || (Index == INT_MAX) ||
                                     ((Pool != MODE_TRADES) && (Index < MT4ORDERS::History.GetAmountPrev())))) ||
             _B2(MT4ORDERS::ByPass.Waiting())) &&
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
            ((Select == SELECT_BY_POS) ?
             ((Pool == MODE_TRADES) ? _B2(MT4ORDERS::SelectByPos((int)Index)) : _B2(MT4ORDERS::SelectByPosHistory((int)Index))) :
             _B2(MT4ORDERS::SelectByTicket(Index, Pool))));
  }
  static int         MT4OrdersTotal( void )
  {
#ifdef MT4ORDERS_SELECTFILTER_OFF
    return(::OrdersTotal() + ::PositionsTotal());
#else // MT4ORDERS_SELECTFILTER_OFF
    int Res;
    if (MT4ORDERS::IsTester)
      return(::OrdersTotal() + ::PositionsTotal());
    else {
      int PrevTotal;
#ifdef MT4ORDERS_BYPASS_MAXTIME
      _B2(MT4ORDERS::ByPass.Waiting());
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
      do {
        const int Total = ::OrdersTotal();
        PrevTotal = ::PositionsTotal();
        Res = Total ? _B2(MT4ORDERS::OrdersTotal()) + PrevTotal : PrevTotal;
      } while (PrevTotal != ::PositionsTotal()); // Отслеживаем только изменение позиций, т.к. ордера отслеживаются в MT4ORDERS::OrdersTotal()
    }
    return(Res); // https://www.mql5.com/ru/forum/290673#comment_9493241
#endif //MT4ORDERS_SELECTFILTER_OFF
  }
  // Такая "перегрузка" позволяет использоваться совместно и MT5-вариант OrdersTotal
  static int         MT4OrdersTotal( const bool )
  {
    return(::OrdersTotal());
  }
  static int         MT4OrdersHistoryTotal( void )
  {
#ifdef MT4ORDERS_BYPASS_MAXTIME
    _B2(MT4ORDERS::ByPass.Waiting());
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
    return(MT4ORDERS::History.GetAmount());
  }
  static long        MT4OrderSend( const string &Symb, const int &Type, const double &dVolume, const double &Price, const int &SlipPage, const double &SL, const double &TP,
                                   const string &comment, const MAGIC_TYPE &magic, const datetime &dExpiration, const color &arrow_color )
  {
    ::ZeroMemory(MT4ORDERS::LastTradeRequest);
    MT4ORDERS::LastTradeRequest.action = (((Type == OP_BUY) || (Type == OP_SELL)) ? TRADE_ACTION_DEAL : TRADE_ACTION_PENDING);
    MT4ORDERS::LastTradeRequest.magic = magic;
    MT4ORDERS::LastTradeRequest.symbol = ((Symb == NULL) ? ::Symbol() : Symb);
    MT4ORDERS::LastTradeRequest.volume = dVolume;
    MT4ORDERS::LastTradeRequest.price = Price;
    MT4ORDERS::LastTradeRequest.tp = TP;
    MT4ORDERS::LastTradeRequest.sl = SL;
    MT4ORDERS::LastTradeRequest.deviation = SlipPage;
    MT4ORDERS::LastTradeRequest.type = (ENUM_ORDER_TYPE)Type;
    MT4ORDERS::LastTradeRequest.type_filling = _B2(MT4ORDERS::GetFilling(MT4ORDERS::LastTradeRequest.symbol, (uint)MT4ORDERS::LastTradeRequest.deviation));
    if (MT4ORDERS::LastTradeRequest.action == TRADE_ACTION_PENDING) {
      MT4ORDERS::LastTradeRequest.type_time = _B2(MT4ORDERS::GetExpirationType(MT4ORDERS::LastTradeRequest.symbol, (uint)dExpiration));
      if (dExpiration > ORDER_TIME_DAY)
        MT4ORDERS::LastTradeRequest.expiration = dExpiration;
    }
    if (comment != NULL)
      MT4ORDERS::LastTradeRequest.comment = comment;
    return((arrow_color == INT_MAX) ? (MT4ORDERS::NewOrderCheck() ? 0 : -1) :
           ((
#ifndef MT4ORDERS_AUTO_VALIDATION
              ((int)arrow_color != INT_MIN) ||
#endif // #ifndef MT4ORDERS_AUTO_VALIDATION
              MT4ORDERS::NewOrderCheck()) &&
            MT4ORDERS::OrderSend(MT4ORDERS::LastTradeRequest, MT4ORDERS::LastTradeResult)
#ifdef MT4ORDERS_BYPASS_MAXTIME
            && (!MT4ORDERS::IsHedging || _B2(MT4ORDERS::ByPass += MT4ORDERS::LastTradeResult.order))
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
            ?
            (MT4ORDERS::IsHedging ? (long)MT4ORDERS::LastTradeResult.order : // PositionID == Result.order - особенность MT5-Hedge
             ((MT4ORDERS::LastTradeRequest.action == TRADE_ACTION_DEAL) ?
              (MT4ORDERS::IsTester ? (_B2(::PositionSelect(MT4ORDERS::LastTradeRequest.symbol)) ? ::PositionGetInteger(POSITION_TICKET) : 0) :
               // HistoryDealSelect в MT4ORDERS::OrderSend
               ::HistoryDealGetInteger(MT4ORDERS::LastTradeResult.deal, DEAL_POSITION_ID)) :
              (long)MT4ORDERS::LastTradeResult.order)) : -1));
  }
  static bool        MT4OrderModify( const long &Ticket, const double &Price, const double &SL, const double &TP, const datetime &Expiration, const color &Arrow_Color )
  {
    ::ZeroMemory(MT4ORDERS::LastTradeRequest);
    // Учитывается случай, когда присутствуют ордер и позиция с одним и тем же тикетом
    bool Res = (Ticket < 0) ? MT4ORDERS::ModifyOrder(-Ticket, Price, Expiration, MT4ORDERS::LastTradeRequest) :
               ((MT4ORDERS::Order.Ticket != ORDER_SELECT)
                // Спорное решение. Проблема, когда нужно модифицировать позицию, а получается модификация ордера с тем же тикетом.
//                || (((::PositionGetInteger(POSITION_TICKET) == Ticket) && (::OrderGetInteger(ORDER_TICKET) != Ticket))
                ?
                (MT4ORDERS::ModifyPosition(Ticket, MT4ORDERS::LastTradeRequest) || MT4ORDERS::ModifyOrder(Ticket, Price, Expiration, MT4ORDERS::LastTradeRequest)) :
                (MT4ORDERS::ModifyOrder(Ticket, Price, Expiration, MT4ORDERS::LastTradeRequest) || MT4ORDERS::ModifyPosition(Ticket, MT4ORDERS::LastTradeRequest)));
//    if (Res) // Игнорируем проверку - есть OrderCheck
    {
      MT4ORDERS::LastTradeRequest.tp = TP;
      MT4ORDERS::LastTradeRequest.sl = SL;
      Res = MT4ORDERS::NewOrderSend(Arrow_Color);
    }
    return(Res);
  }
  // Невозможно закрыть на весь объем определенную MT4-позицию - открывающий позицию MT5-маркет ордер: отсутствует вариант с вызовом OrderDelete.
  // Искусственно воспроизвести такую ситуацию не получилось.
  static bool        MT4OrderClose( const long &Ticket, const double &dLots, const double &Price, const int &SlipPage, const color &Arrow_Color, const string &comment )
  {
    // Есть MT4ORDERS::LastTradeRequest и MT4ORDERS::LastTradeResult, поэтому на результат не влияет, но нужно для PositionGetString ниже
    _B2(::PositionSelectByTicket(Ticket));
    ::ZeroMemory(MT4ORDERS::LastTradeRequest);
    MT4ORDERS::LastTradeRequest.action = TRADE_ACTION_DEAL;
    MT4ORDERS::LastTradeRequest.position = Ticket;
    MT4ORDERS::LastTradeRequest.symbol = ::PositionGetString(POSITION_SYMBOL);
    // Сохраняем комментарий при частичном закрытии позиции
//    if (dLots < ::PositionGetDouble(POSITION_VOLUME))
    MT4ORDERS::LastTradeRequest.comment = (comment == NULL) ? ::PositionGetString(POSITION_COMMENT) : comment;
    // Правильно ли не задавать мэджик при закрытии? -Правильно!
    MT4ORDERS::LastTradeRequest.volume = dLots;
    MT4ORDERS::LastTradeRequest.price = Price;
    if (!MT4ORDERS::MTBuildSLTP) {
      // Нужно для определения SL/TP-уровней у закрытой позиции. Перевернуто - не ошибка
      // SYMBOL_SESSION_PRICE_LIMIT_MIN и SYMBOL_SESSION_PRICE_LIMIT_MAX проверять не требуется, т.к. исходные SL/TP уже установлены
      MT4ORDERS::LastTradeRequest.tp = ::PositionGetDouble(POSITION_SL);
      MT4ORDERS::LastTradeRequest.sl = ::PositionGetDouble(POSITION_TP);
      if (MT4ORDERS::LastTradeRequest.tp || MT4ORDERS::LastTradeRequest.sl) {
        const double StopLevel = ::SymbolInfoInteger(MT4ORDERS::LastTradeRequest.symbol, SYMBOL_TRADE_STOPS_LEVEL) *
                                 ::SymbolInfoDouble(MT4ORDERS::LastTradeRequest.symbol, SYMBOL_POINT);
        const bool FlagBuy = (::PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
        const double CurrentPrice = SymbolInfoDouble(MT4ORDERS::LastTradeRequest.symbol, FlagBuy ? SYMBOL_ASK : SYMBOL_BID);
        if (CurrentPrice) {
          if (FlagBuy)
            MT4ORDERS::CheckPrices(MT4ORDERS::LastTradeRequest.tp, MT4ORDERS::LastTradeRequest.sl, CurrentPrice - StopLevel, CurrentPrice + StopLevel);
          else
            MT4ORDERS::CheckPrices(MT4ORDERS::LastTradeRequest.sl, MT4ORDERS::LastTradeRequest.tp, CurrentPrice - StopLevel, CurrentPrice + StopLevel);
        } else {
          MT4ORDERS::LastTradeRequest.tp = 0;
          MT4ORDERS::LastTradeRequest.sl = 0;
        }
      }
    }
    MT4ORDERS::LastTradeRequest.deviation = SlipPage;
    MT4ORDERS::LastTradeRequest.type = (ENUM_ORDER_TYPE)(1 - ::PositionGetInteger(POSITION_TYPE));
    MT4ORDERS::LastTradeRequest.type_filling = _B2(MT4ORDERS::GetFilling(MT4ORDERS::LastTradeRequest.symbol, (uint)MT4ORDERS::LastTradeRequest.deviation));
    return(MT4ORDERS::NewOrderSend(Arrow_Color));
  }
  static bool        MT4OrderCloseBy( const long &Ticket, const long &Opposite, const color &Arrow_Color )
  {
    ::ZeroMemory(MT4ORDERS::LastTradeRequest);
    MT4ORDERS::LastTradeRequest.action = TRADE_ACTION_CLOSE_BY;
    MT4ORDERS::LastTradeRequest.position = Ticket;
    MT4ORDERS::LastTradeRequest.position_by = Opposite;
    if ((!MT4ORDERS::IsTester) && _B2(::PositionSelectByTicket(Ticket))) // нужен для MT4ORDERS::SymbolTrade()
      MT4ORDERS::LastTradeRequest.symbol = ::PositionGetString(POSITION_SYMBOL);
    return(MT4ORDERS::NewOrderSend(Arrow_Color));
  }
  static bool        MT4OrderDelete( const long &Ticket, const color &Arrow_Color )
  {
//    bool Res = ::OrderSelect(Ticket); // Надо ли это, когда нужны MT4ORDERS::LastTradeRequest и MT4ORDERS::LastTradeResult ?
    ::ZeroMemory(MT4ORDERS::LastTradeRequest);
    MT4ORDERS::LastTradeRequest.action = TRADE_ACTION_REMOVE;
    MT4ORDERS::LastTradeRequest.order = Ticket;
    if ((!MT4ORDERS::IsTester) && _B2(::OrderSelect(Ticket))) // нужен для MT4ORDERS::SymbolTrade()
      MT4ORDERS::LastTradeRequest.symbol = ::OrderGetString(ORDER_SYMBOL);
    return(MT4ORDERS::NewOrderSend(Arrow_Color));
  }
#define MT4_ORDERFUNCTION(NAME,T,A,B,C)                               \
  static T MT4Order##NAME( void )                                     \
  {                                                                   \
    return(POSITION_ORDER((T)(A), (T)(B), MT4ORDERS::Order.NAME, C)); \
  }
#define POSITION_ORDER(A,B,C,D) (((MT4ORDERS::Order.Ticket == POSITION_SELECT) && (D)) ? (A) : ((MT4ORDERS::Order.Ticket == ORDER_SELECT) ? (B) : (C)))
  MT4_ORDERFUNCTION(Ticket, long, ::PositionGetInteger(POSITION_TICKET), ::OrderGetInteger(ORDER_TICKET), true)
  MT4_ORDERFUNCTION(Type, int, ::PositionGetInteger(POSITION_TYPE), ::OrderGetInteger(ORDER_TYPE), true)
  MT4_ORDERFUNCTION(Lots, double, ::PositionGetDouble(POSITION_VOLUME), ::OrderGetDouble(ORDER_VOLUME_CURRENT), true)
  MT4_ORDERFUNCTION(OpenPrice, double, ::PositionGetDouble(POSITION_PRICE_OPEN), (::OrderGetDouble(ORDER_PRICE_OPEN) ? ::OrderGetDouble(ORDER_PRICE_OPEN) : ::OrderGetDouble(ORDER_PRICE_CURRENT)), true)
  MT4_ORDERFUNCTION(OpenTimeMsc, long, ::PositionGetInteger(POSITION_TIME_MSC), ::OrderGetInteger(ORDER_TIME_SETUP_MSC), true)
  MT4_ORDERFUNCTION(OpenTime, datetime, ::PositionGetInteger(POSITION_TIME), ::OrderGetInteger(ORDER_TIME_SETUP), true)
  MT4_ORDERFUNCTION(StopLoss, double, ::PositionGetDouble(POSITION_SL), ::OrderGetDouble(ORDER_SL), true)
  MT4_ORDERFUNCTION(TakeProfit, double, ::PositionGetDouble(POSITION_TP), ::OrderGetDouble(ORDER_TP), true)
  MT4_ORDERFUNCTION(ClosePrice, double, ::PositionGetDouble(POSITION_PRICE_CURRENT), ::OrderGetDouble(ORDER_PRICE_CURRENT), true)
  MT4_ORDERFUNCTION(CloseTimeMsc, long, 0, 0, true)
  MT4_ORDERFUNCTION(CloseTime, datetime, 0, 0, true)
  MT4_ORDERFUNCTION(Expiration, datetime, 0, ::OrderGetInteger(ORDER_TIME_EXPIRATION), true)
  MT4_ORDERFUNCTION(MagicNumber, long, ::PositionGetInteger(POSITION_MAGIC), ::OrderGetInteger(ORDER_MAGIC), true)
  MT4_ORDERFUNCTION(Profit, double, ::PositionGetDouble(POSITION_PROFIT), 0, true)
  MT4_ORDERFUNCTION(Swap, double, ::PositionGetDouble(POSITION_SWAP), 0, true)
  MT4_ORDERFUNCTION(Symbol, string, ::PositionGetString(POSITION_SYMBOL), ::OrderGetString(ORDER_SYMBOL), true)
  MT4_ORDERFUNCTION(Comment, string, MT4ORDERS::Order.Comment, ::OrderGetString(ORDER_COMMENT), MT4ORDERS::CheckPositionCommissionComment())
  MT4_ORDERFUNCTION(Commission, double, MT4ORDERS::Order.Commission, 0, MT4ORDERS::CheckPositionCommissionComment())
  MT4_ORDERFUNCTION(OpenPriceRequest, double, MT4ORDERS::Order.OpenPriceRequest, ::OrderGetDouble(ORDER_PRICE_OPEN), MT4ORDERS::CheckPositionOpenPriceRequest())
  MT4_ORDERFUNCTION(ClosePriceRequest, double, ::PositionGetDouble(POSITION_PRICE_CURRENT), ::OrderGetDouble(ORDER_PRICE_CURRENT), true)
  MT4_ORDERFUNCTION(TicketOpen, long, MT4ORDERS::Order.TicketOpen, ::OrderGetInteger(ORDER_TICKET), MT4ORDERS::CheckPositionTicketOpen())
//  MT4_ORDERFUNCTION(OpenReason, ENUM_DEAL_REASON, MT4ORDERS::Order.OpenReason, ::OrderGetInteger(ORDER_REASON), MT4ORDERS::CheckPositionOpenReason())
  MT4_ORDERFUNCTION(OpenReason, ENUM_DEAL_REASON, ::PositionGetInteger(POSITION_REASON), ::OrderGetInteger(ORDER_REASON), true)
  MT4_ORDERFUNCTION(CloseReason, ENUM_DEAL_REASON, 0, ::OrderGetInteger(ORDER_REASON), true)
  MT4_ORDERFUNCTION(TicketID, long, ::PositionGetInteger(POSITION_IDENTIFIER), ::OrderGetInteger(ORDER_TICKET), true)
  MT4_ORDERFUNCTION(DealsAmount, int, MT4ORDERS::Order.DealsAmount, 0, MT4ORDERS::CheckPositionTicketOpen())
  MT4_ORDERFUNCTION(LotsOpen, double, ::PositionGetDouble(POSITION_VOLUME), ::OrderGetDouble(ORDER_VOLUME_INITIAL), true)
#undef POSITION_ORDER
#undef MT4_ORDERFUNCTION
  static void        MT4OrderPrint( void )
  {
    if (MT4ORDERS::Order.Ticket == POSITION_SELECT)
      MT4ORDERS::CheckPositionCommissionComment();
    ::Print(MT4ORDERS::Order.ToString());
    return;
  }
  static double      MT4OrderLots( const bool& )
  {
    // На случай, если будет решение в пользу целесообразности проверок (OrderLots() != OrderLots(true)).
    // Такой вариант позволяет не порождать ошибки в OrderClose, но неоднозначен в удобстве во всех сценариях.
    double Res = /*((MT4ORDERS::Order.Ticket == ORDER_SELECT) && (::OrderGetInteger(ORDER_TYPE) <= OP_SELL)) ? 0 :*/ MT4ORDERS::MT4OrderLots();
    if (Res && (MT4ORDERS::Order.Ticket == POSITION_SELECT)) {
      const ulong PositionID = ::PositionGetInteger(POSITION_IDENTIFIER);
      if (::PositionSelectByTicket(PositionID)) {
        const int Type = 1 - (int)::PositionGetInteger(POSITION_TYPE);
        double PrevVolume = Res;
        double NewVolume = 0;
        while (Res && (NewVolume != PrevVolume)) {
#ifdef MT4ORDERS_BYPASS_MAXTIME
          _B2(MT4ORDERS::ByPass.Waiting());
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
          if (::PositionSelectByTicket(PositionID)) {
            Res = ::PositionGetDouble(POSITION_VOLUME);
            PrevVolume = Res;
            for (int i = ::OrdersTotal() - 1; i >= 0; i--)
              if (!::OrderGetTicket(i)) { // Случается при i == ::OrdersTotal() - 1.
                PrevVolume = -1;
                break;
              } else if ((::OrderGetInteger(ORDER_POSITION_ID) == PositionID) &&
                         (::OrderGetInteger(ORDER_TYPE) == Type))
                Res -= ::OrderGetDouble(ORDER_VOLUME_CURRENT);
            /*
                      #ifdef MT4ORDERS_BYPASS_MAXTIME
                        _B2(MT4ORDERS::ByPass.Waiting());
                      #endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
            */
            if (::PositionSelectByTicket(PositionID))
              NewVolume = ::PositionGetDouble(POSITION_VOLUME);
            else
              Res = 0;
          } else
            Res = 0;
        }
      } else
        Res = 0;
    }
    return(Res);
  }
#undef ORDER_SELECT
#undef POSITION_SELECT
};
// #define OrderToString MT4ORDERS::MT4OrderToString
static MT4_ORDER MT4ORDERS::Order = {};
static MT4HISTORY MT4ORDERS::History;
static const bool MT4ORDERS::IsTester = ::MQLInfoInteger(MQL_TESTER);
// Если переключить счет, это значение у советников все равно пересчитается
// https://www.mql5.com/ru/forum/170952/page61#comment_6132824
static const bool MT4ORDERS::IsHedging = ((ENUM_ACCOUNT_MARGIN_MODE)::AccountInfoInteger(ACCOUNT_MARGIN_MODE) ==
    ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
static const bool MT4ORDERS::MTBuildSLTP = (::TerminalInfoInteger(TERMINAL_BUILD) >= 3081); // https://www.mql5.com/ru/forum/378360
static int MT4ORDERS::OrderSendBug = 0;
static uint MT4ORDERS::OrderSend_MaxPause = 1000000; // максимальное время на синхронизацию в мкс.
#ifdef MT4ORDERS_BYPASS_MAXTIME
static BYPASS MT4ORDERS::ByPass(MT4ORDERS_BYPASS_MAXTIME);
#endif // #ifdef MT4ORDERS_BYPASS_MAXTIME
static MqlTradeResult MT4ORDERS::LastTradeResult = {};
static MqlTradeRequest MT4ORDERS::LastTradeRequest = {};
static MqlTradeCheckResult MT4ORDERS::LastTradeCheckResult = {};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderClose( const long Ticket, const double dLots, const double Price, const int SlipPage, const color Arrow_Color = clrNONE, const string comment = NULL )
{
  return(MT4ORDERS::MT4OrderClose(Ticket, dLots, Price, SlipPage, Arrow_Color, comment));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderModify( const long Ticket, const double Price, const double SL, const double TP, const datetime Expiration, const color Arrow_Color = clrNONE )
{
  return(MT4ORDERS::MT4OrderModify(Ticket, Price, SL, TP, Expiration, Arrow_Color));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderCloseBy( const long Ticket, const long Opposite, const color Arrow_Color = clrNONE )
{
  return(MT4ORDERS::MT4OrderCloseBy(Ticket, Opposite, Arrow_Color));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderDelete( const long Ticket, const color Arrow_Color = clrNONE )
{
  return(MT4ORDERS::MT4OrderDelete(Ticket, Arrow_Color));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderPrint( void )
{
  MT4ORDERS::MT4OrderPrint();
  return;
}
#define MT4_ORDERGLOBALFUNCTION(NAME,T)     \
  T Order##NAME( void )                     \
  {                                         \
    return((T)MT4ORDERS::MT4Order##NAME()); \
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MT4_ORDERGLOBALFUNCTION(sHistoryTotal, int)
MT4_ORDERGLOBALFUNCTION(Ticket, TICKET_TYPE)
MT4_ORDERGLOBALFUNCTION(Type, int)
MT4_ORDERGLOBALFUNCTION(Lots, double)
MT4_ORDERGLOBALFUNCTION(OpenPrice, double)
MT4_ORDERGLOBALFUNCTION(OpenTimeMsc, long)
MT4_ORDERGLOBALFUNCTION(OpenTime, datetime)
MT4_ORDERGLOBALFUNCTION(StopLoss, double)
MT4_ORDERGLOBALFUNCTION(TakeProfit, double)
MT4_ORDERGLOBALFUNCTION(ClosePrice, double)
MT4_ORDERGLOBALFUNCTION(CloseTimeMsc, long)
MT4_ORDERGLOBALFUNCTION(CloseTime, datetime)
MT4_ORDERGLOBALFUNCTION(Expiration, datetime)
MT4_ORDERGLOBALFUNCTION(MagicNumber, MAGIC_TYPE)
MT4_ORDERGLOBALFUNCTION(Profit, double)
MT4_ORDERGLOBALFUNCTION(Commission, double)
MT4_ORDERGLOBALFUNCTION(Swap, double)
MT4_ORDERGLOBALFUNCTION(Symbol, string)
MT4_ORDERGLOBALFUNCTION(Comment, string)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MT4_ORDERGLOBALFUNCTION(OpenPriceRequest, double)
MT4_ORDERGLOBALFUNCTION(ClosePriceRequest, double)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MT4_ORDERGLOBALFUNCTION(TicketOpen, TICKET_TYPE)
MT4_ORDERGLOBALFUNCTION(OpenReason, ENUM_DEAL_REASON)
MT4_ORDERGLOBALFUNCTION(CloseReason, ENUM_DEAL_REASON)
MT4_ORDERGLOBALFUNCTION(TicketID, TICKET_TYPE)
MT4_ORDERGLOBALFUNCTION(DealsAmount, int)
MT4_ORDERGLOBALFUNCTION(LotsOpen, double)
#undef MT4_ORDERGLOBALFUNCTION
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OrderLots( const bool Value )
{
  return(MT4ORDERS::MT4OrderLots(Value));
}
// Перегруженные стандартные функции
#define OrdersTotal MT4ORDERS::MT4OrdersTotal // ПОСЛЕ Expert/Expert.mqh - идет вызов MT5-OrdersTotal()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderSelect( const long Index, const int Select, const int Pool = MODE_TRADES )
{
  return(_B2(MT4ORDERS::MT4OrderSelect(Index, Select, Pool)));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TICKET_TYPE OrderSend( const string Symb, const int Type, const double dVolume, const double Price, const int SlipPage, const double SL, const double TP,
                       const string comment = NULL, const MAGIC_TYPE magic = 0, const datetime dExpiration = 0, color arrow_color = clrNONE )
{
  return((TICKET_TYPE)MT4ORDERS::MT4OrderSend(Symb, Type, dVolume, Price, SlipPage, SL, TP, comment, magic, dExpiration, arrow_color));
}
#define RETURN_ASYNC(A) return((A) && ::OrderSendAsync(MT4ORDERS::LastTradeRequest, MT4ORDERS::LastTradeResult) &&                        \
                               (MT4ORDERS::LastTradeResult.retcode == TRADE_RETCODE_PLACED) ? MT4ORDERS::LastTradeResult.request_id : 0);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint OrderCloseAsync( const long Ticket, const double dLots, const double Price, const int SlipPage, const color Arrow_Color = clrNONE )
{
  RETURN_ASYNC(OrderClose(Ticket, dLots, Price, SlipPage, INT_MAX))
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint OrderModifyAsync( const long Ticket, const double Price, const double SL, const double TP, const datetime Expiration, const color Arrow_Color = clrNONE )
{
  RETURN_ASYNC(OrderModify(Ticket, Price, SL, TP, Expiration, INT_MAX))
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint OrderDeleteAsync( const long Ticket, const color Arrow_Color = clrNONE )
{
  RETURN_ASYNC(OrderDelete(Ticket, INT_MAX))
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint OrderSendAsync( const string Symb, const int Type, const double dVolume, const double Price, const int SlipPage, const double SL, const double TP,
                     const string comment = NULL, const MAGIC_TYPE magic = 0, const datetime dExpiration = 0, color arrow_color = clrNONE )
{
  RETURN_ASYNC(!OrderSend(Symb, Type, dVolume, Price, SlipPage, SL, TP, comment, magic, dExpiration, INT_MAX))
}
#undef RETURN_ASYNC
#undef _BV2
#undef _B3
#undef _B2
#ifdef MT4ORDERS_BENCHMARK_MINTIME
#undef MT4ORDERS_BENCHMARK_MINTIME
#endif // MT4ORDERS_BENCHMARK_MINTIME
// #undef TICKET_TYPE
#endif // __MT4ORDERS__
#else  // __MQL5__
#define TICKET_TYPE int
#define MAGIC_TYPE  int
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TICKET_TYPE OrderTicketID( void )
{
  return(::OrderTicket());
}
#endif // __MQL5__
//+------------------------------------------------------------------+
//#include <MT5.mqh>
#undef Print
#undef Alert
#endif
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ND(double thelot)
{
  double tLot=0;
  double MinLot = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
  double MaxLot = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
  lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
  tLot=NormalizeDouble(thelot/lotStep,0)*lotStep;
  if(tLot<MinLot) {
    tLot=MinLot;
  }
  if(tLot>MaxLot) {
    tLot=MaxLot;
  }
  return(tLot);
}
//+------------------------------------------------------------------+
//| Кнопки |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
//+------------------------------------------------------------------+
// Изменяем цвет кнопок при нажатии
//+------------------------------------------------------------------+
  if(ObjectGetInteger(0,"TRADEs_B",OBJPROP_STATE)) {
    ObjectSetInteger(0,"TRADEs_B",OBJPROP_BGCOLOR,ClickButton);
  } else {
    ObjectSetInteger(0,"TRADEs_B",OBJPROP_BGCOLOR,FonButtonBuy);
  }
//------------------
  if(ObjectGetInteger(0,"TRADEs_S",OBJPROP_STATE)) {
    ObjectSetInteger(0,"TRADEs_S",OBJPROP_BGCOLOR,ClickButton);
  } else {
    ObjectSetInteger(0,"TRADEs_S",OBJPROP_BGCOLOR,FonButtonSell);
  }
//------------------
//+------------------------------------------------------------------+
// Проверим событие на нажатие кнопки мышки
//+------------------------------------------------------------------+
  if(id==CHARTEVENT_OBJECT_CLICK) {
    string clickedChartObject=sparam;
    if(clickedChartObject=="TRADEs_B") {
      o=OrderSend(Symbol(),OP_BUY,Lot,Ask,10,0,0,comments,Magic,0,Green);
      ObjectSetInteger(0,"TRADEs_B",OBJPROP_STATE,false);
      ChartRedraw();
    }
    if(clickedChartObject=="TRADEs_S") {
      o=OrderSend(Symbol(),OP_SELL,Lot,Bid,10,0,0,comments,Magic,0,Red);
      ObjectSetInteger(0,"TRADEs_S",OBJPROP_STATE,false);
      ChartRedraw();
    }
//--- Принудительно перерисуем все объекты на графике
    ChartRedraw();
  }
}

//+------------------------------------------------------------------+
//| Функция закрытия ордеров |
//+------------------------------------------------------------------+
void ClosePlus(int ot)
{
  bool cl;
  for(int i=OrdersTotal()-1; i>=0; i--) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderProfit()+OrderSwap()+OrderCommission()>0) {
        if(OrderType()==0 && (ot==0 || ot==-1)) {
          cl=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,_Digits),10,White);
        }
        if(OrderType()==1 && (ot==1 || ot==-1)) {
          cl=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,_Digits),10,White);
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseMinus(int ot)
{
  bool cl;
  for(int i=OrdersTotal()-1; i>=0; i--) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderProfit()+OrderSwap()+OrderCommission()<0) {
        if(OrderType()==0 && (ot==0 || ot==-1)) {
          cl=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,_Digits),10,White);
        }
        if(OrderType()==1 && (ot==1 || ot==-1)) {
          cl=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,_Digits),10,White);
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
//| Создает горизонтальную линию |
//+------------------------------------------------------------------+
bool HLineCreate(string name,double price,color clr)
{
  //--- если цена не задана, то установим ее на уровне текущей цены Bid
  if(!price)
    price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- сбросим значение ошибки
  ResetLastError();
//--- создадим горизонтальную линию
  if(!ObjectCreate(0,name,OBJ_HLINE,0,0,price)) {
    Print(__FUNCTION__,": не удалось создать горизонтальную линию! Код ошибки = ",GetLastError());
    return(false);
  }
//--- установим цвет линии
  ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
//--- установим стиль отображения линии
  ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
//--- установим толщину линии
  ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
//--- включим (true) или отключим (false) режим перемещения линии мышью
  ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
  ObjectSetInteger(0,name,OBJPROP_SELECTED,true);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- установим приоритет на получение события нажатия мыши на графике
  ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
//--- успешное выполнение
  return(true);
}
//+------------------------------------------------------------------+
//| Перемещение горизонтальной линии |
//+------------------------------------------------------------------+
bool HLineMove(string name,double price)
{
  if(!price)
    price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- сбросим значение ошибки
  ResetLastError();
//--- переместим горизонтальную линию
  if(!ObjectMove(0,name,0,0,price)) {
    Print(__FUNCTION__,": не удалось переместить горизонтальную линию! Код ошибки = ",GetLastError());
    return(false);
  }
//--- успешное выполнение
  return(true);
}
//+------------------------------------------------------------------+
//| Определяем тип последнего ордера |
//+------------------------------------------------------------------+
int LastType()
{
  int type=-1;
  datetime dt=0;
  for(int i=OrdersHistoryTotal()-1; i>=0; i--)
    if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) {
      if(Symbol()==OrderSymbol() && OrderMagicNumber()==Magic) {
        if(OrderOpenTime()>dt) {
          dt=OrderOpenTime();
          type=OrderType();
        }
      }
    }
  return(type);
}
//+------------------------------------------------------------------+
//| Определяем цену последнего ордера бай |
//+------------------------------------------------------------------+
double BuyPric()
{
  double oldorderopenprice=0;
  datetime LastBuyTime = 0;
  for (int cnt = OrdersTotal() - 1; cnt >= 0; cnt--) {
    bool clos=OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_BUY) {
      if(LastBuyTime<OrderOpenTime()) {
        LastBuyTime=OrderOpenTime();
        oldorderopenprice=OrderOpenPrice();
      }
    }
  }
  return (oldorderopenprice);
}
//+------------------------------------------------------------------+
//| Определяем цену последнего ордера селл |
//+------------------------------------------------------------------+
double SellPric()
{
  double oldorderopenprice=0;
  datetime LastSellTime = 0;
  for (int cnt = OrdersTotal() - 1; cnt >= 0; cnt--) {
    bool clos=OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_SELL) {
      if(LastSellTime<OrderOpenTime()) {
        LastSellTime=OrderOpenTime();
        oldorderopenprice=OrderOpenPrice();
      }
    }
  }
  return (oldorderopenprice);
}
//+------------------------------------------------------------------+
//| Считаем количество ордеров по типу |
//+------------------------------------------------------------------+
int Count(int type)
{
  int count=0;
  for(int i=OrdersTotal()-1; i>=0; i--)
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
      if(Symbol()==OrderSymbol() && Magic==OrderMagicNumber() && (type==-1 || OrderType()==type)) count++;
    }
  return(count);
}
//======= Счетчик текущего профита по паре
double Profit(int type)
{
  double Profit = 0;
  for (int cnt = OrdersTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)) {
      if (Symbol()==OrderSymbol() && OrderMagicNumber()==Magic && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}
//======= Счетчик текущего профита по счету
double ProfitAll(int type)
{
  double Profit = 0;
  for (int cnt = OrdersTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderMagicNumber()==Magic && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}

//======= Счетчик зафиксированой прибыли за сегодня
double ProfitDey(int type)
{
  double Profit = 0;
  for (int cnt = OrdersHistoryTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY)) {
      if (OrderMagicNumber()==Magic && OrderCloseTime()>=iTime(Symbol(),PERIOD_D1,0) && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}

//======= Счетчик зафиксированой прибыли за вчера
double ProfitTuDey(int type)
{
  double Profit = 0;
  for (int cnt = OrdersHistoryTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY)) {
      if (OrderMagicNumber()==Magic && OrderCloseTime()>=iTime(Symbol(),PERIOD_D1,1) && OrderCloseTime()<iTime(Symbol(),PERIOD_D1,0) && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}

//======= Счетчик зафиксированой прибыли за позавчера
double ProfitEsTuDey(int type)
{
  double Profit = 0;
  for (int cnt = OrdersHistoryTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY)) {
      if (OrderMagicNumber()==Magic && OrderCloseTime()>=iTime(Symbol(),PERIOD_D1,2) && OrderCloseTime()<iTime(Symbol(),PERIOD_D1,1) && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}

//======= Счетчик зафиксированой прибыли за неделю
double ProfitWeek(int type)
{
  double Profit = 0;
  for (int cnt = OrdersHistoryTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY)) {
      if (OrderMagicNumber()==Magic && OrderCloseTime()>=iTime(Symbol(),PERIOD_W1,0) && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}

//======= Счетчик зафиксированой прибыли за месяц
double ProfitMontag(int type)
{
  double Profit = 0;
  for (int cnt = OrdersHistoryTotal() - 1; cnt >= 0; cnt--) {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY)) {
      if (OrderMagicNumber()==Magic && OrderCloseTime()>=iTime(Symbol(),PERIOD_MN1,0) && (OrderType() == type || type==-1)) Profit += OrderProfit()+OrderSwap()+OrderCommission();
    }
  }
  return (Profit);
}

//======= Создаем текстовую метку
void PutLabel(string name,int x,int y,string text)
{
  ObjectCreate(0,name,OBJ_LABEL,0,0,0);
//--- установим координаты метки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
//--- установим текст
  ObjectSetString(0,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
  ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
  ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
//--- установим цвет
  ObjectSetInteger(0,name,OBJPROP_COLOR,TextColor);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

//======= Создаем вторую текстовую метку
void PutLabel_(string name,int x,int y,string text)
{
  ObjectCreate(0,name,OBJ_LABEL,0,0,0);
//--- установим координаты метки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
//--- установим текст
  ObjectSetString(0,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
  ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
  ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
//--- установим цвет
  ObjectSetInteger(0,name,OBJPROP_COLOR,InfoDataColor);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

//======= Создаем прямоугольник
bool RectLabelCreate3(string name, int x,int y, int width, int height, color back_clr)
{
  ResetLastError();
//--- создадим прямоугольную метку
  if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0)) {
    return(false);
  }
//--- установим координаты метки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим размеры метки
  ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
  ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
//--- установим цвет фона
  ObjectSetInteger(0,name,OBJPROP_BGCOLOR,back_clr);
//--- установим тип границы
  ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_SUNKEN);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
//--- установим цвет плоской рамки (в режиме Flat)
  ObjectSetInteger(0,name,OBJPROP_COLOR,Blue);
//--- установим толщину плоской границы
  ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- успешное выполнение
  return(true);
}
//--- Кнопки торговой панели (Бай/Селл)
void PutButtonBS(string name,int x,int y,string text,int BWidth2,int BHeigh2,color FonButtonBS,color TXTButtonBS)
{
  ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
//--- установим координаты кнопки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим размер кнопки
  ObjectSetInteger(0,name,OBJPROP_XSIZE,BWidth2);
  ObjectSetInteger(0,name,OBJPROP_YSIZE,BHeigh2);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
//--- установим текст
  ObjectSetString(0,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
  ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
  ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
//--- установим цвет текста
  ObjectSetInteger(0,name,OBJPROP_COLOR,TXTButtonBS);
//--- установим цвет фона
  ObjectSetInteger(0,name,OBJPROP_BGCOLOR,FonButtonBS);
//--- установим цвет границы
  ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,ButtonBorder);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PutLabelT(string name,int x,int y,string text, int space)
{
  ObjectCreate(0,name,OBJ_LABEL,0,0,0);
//--- установим координаты метки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER, space);
//--- установим текст
  ObjectSetString(0,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
  ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
  ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
//--- установим цвет
  ObjectSetInteger(0,name,OBJPROP_COLOR,TextColor);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
}


//--- Цвет текста данных
void PutLabelD(string name,int x,int y,string data,int space)
{
  ObjectCreate(0,name,OBJ_LABEL,0,0,0);
//--- установим координаты метки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER,space);
//--- установим текст
  ObjectSetString(0,name,OBJPROP_TEXT,data);
//--- установим шрифт текста
  ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
  ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
//--- установим цвет
  ObjectSetInteger(0,name,OBJPROP_COLOR,InfoDataColor);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
}
//--- Создаем прямоугольную метку (фон)
bool RectLabelCreate(string name, int x,int y, int width, int height, color back_clr, int space)
{
  ResetLastError();
//--- создадим прямоугольную метку
  if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0)) {
    return(false);
  }
//--- установим координаты метки
  ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим размеры метки
  ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
  ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
//--- установим цвет фона
  ObjectSetInteger(0,name,OBJPROP_BGCOLOR,back_clr);
//--- установим тип границы
  ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_SUNKEN);
//--- установим угол графика, относительно которого будут определяться координаты точки
  ObjectSetInteger(0,name,OBJPROP_CORNER,space);
//--- установим цвет плоской рамки (в режиме Flat)
  ObjectSetInteger(0,name,OBJPROP_COLOR,Blue);
//--- установим толщину плоской границы
  ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
//--- отобразим на переднем (false) или заднем (true) плане
  ObjectSetInteger(0,name,OBJPROP_BACK,false);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
  ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
//--- успешное выполнение
  return(true);
}

//混淆加密主体
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\ListView.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\SpinEdit.mqh>
#include <Controls\RadioGroup.mqh>
#include <Controls\CheckGroup.mqh>
//+------------------------------------------------------------------+
//| defines |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT (11) // indent from left (with allowance for border width)
#define INDENT_TOP (11) // indent from top (with allowance for border width)
#define INDENT_RIGHT (11) // indent from right (with allowance for border width)
#define INDENT_BOTTOM (11) // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X (-10010) // gap by X coordinate
#define CONTROLS_GAP_Y (10) // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH (100) // size by X coordinate
#define BUTTON_HEIGHT (20) // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT (20) // size by Y coordinate
//+------------------------------------------------------------------+
//| Class CPanelDialog |
//| Usage: main dialog of the SimplePanel application |
//+------------------------------------------------------------------+
class CPanelDialog : public CAppDialog
{
private:
  CEdit m_edit; // the display field object
  CButton m_button1; // the button object
  CButton m_button2; // the button object
  CButton m_button3; // the fixed button object
  CListView m_list_view; // the list object
  CRadioGroup m_radio_group; // the radio buttons group object
  CCheckGroup m_check_group; // the check box group object
public:
  CPanelDialog(void);
  ~CPanelDialog(void);
//--- create
  virtual bool Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
//--- chart event handler
  virtual bool OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
protected:
//--- create dependent controls
  bool CreateEdit(void);
  bool CreateButton1(void);
  bool CreateButton2(void);
  bool CreateButton3(void);
  bool CreateRadioGroup(void);
  bool CreateCheckGroup(void);
  bool CreateListView(void);
//--- internal event handlers
  virtual bool OnResize(void);
//--- handlers of the dependent controls events
  void OnClickButton1(void);
  void OnClickButton2(void);
  void OnClickButton3(void);
  void OnChangeRadioGroup(void);
  void OnChangeCheckGroup(void);
  void OnChangeListView(void);
  bool OnDefault(const int id,const long &lparam,const double &dparam,const string &sparam);
};
//+------------------------------------------------------------------+
//| Event Handling |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CPanelDialog)
ON_EVENT(ON_CLICK,m_button1,OnClickButton1)
ON_EVENT(ON_CLICK,m_button2,OnClickButton2)
ON_EVENT(ON_CLICK,m_button3,OnClickButton3)
ON_EVENT(ON_CHANGE,m_radio_group,OnChangeRadioGroup)
ON_EVENT(ON_CHANGE,m_check_group,OnChangeCheckGroup)
ON_EVENT(ON_CHANGE,m_list_view,OnChangeListView)
ON_OTHER_EVENTS(OnDefault)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor |
//+------------------------------------------------------------------+
CPanelDialog::CPanelDialog(void)
{
}
//+------------------------------------------------------------------+
//| Destructor |
//+------------------------------------------------------------------+
CPanelDialog::~CPanelDialog(void)
{
}
//+------------------------------------------------------------------+
//| Create |
//+------------------------------------------------------------------+
bool CPanelDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
{
// if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
// return(false);
//--- create dependent controls
  if(!CreateEdit())
    return(false);
  if(!CreateButton1())
    return(false);
  if(!CreateButton2())
    return(false);
  if(!CreateButton3())
    return(false);
  if(!CreateRadioGroup())
    return(false);
  if(!CreateCheckGroup())
    return(false);
  if(!CreateListView())
    return(false);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the display field |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateEdit(void)
{
//--- coordinates
  int x1=INDENT_LEFT;
  int y1=INDENT_TOP;
  int x2=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
  int y2=y1+EDIT_HEIGHT;
//--- create
  if(!m_edit.Create(m_chart_id,m_name+"Edit",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!m_edit.ReadOnly(true))
    return(false);
  if(!Add(m_edit))
    return(false);
  m_edit.Alignment(WND_ALIGN_WIDTH,INDENT_LEFT,0,INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X,0);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the "Button1" button |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton1(void)
{
//--- coordinates
  int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
  int y1=INDENT_TOP;
  int x2=x1+BUTTON_WIDTH;
  int y2=y1+BUTTON_HEIGHT;
//--- create
  if(!m_button1.Create(m_chart_id,m_name+"Button1",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!m_button1.Text("Button1"))
    return(false);
  if(!Add(m_button1))
    return(false);
  m_button1.Alignment(WND_ALIGN_RIGHT,0,0,INDENT_RIGHT,0);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the "Button2" button |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton2(void)
{
//--- coordinates
  int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
  int y1=INDENT_TOP+BUTTON_HEIGHT+CONTROLS_GAP_Y;
  int x2=x1+BUTTON_WIDTH;
  int y2=y1+BUTTON_HEIGHT;
//--- create
  if(!m_button2.Create(m_chart_id,m_name+"Button2",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!m_button2.Text("Button2"))
    return(false);
  if(!Add(m_button2))
    return(false);
  m_button2.Alignment(WND_ALIGN_RIGHT,0,0,INDENT_RIGHT,0);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the "Button3" fixed button |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton3(void)
{
//--- coordinates
  int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
  int y1=ClientAreaHeight()-(INDENT_BOTTOM+BUTTON_HEIGHT);
  int x2=x1+BUTTON_WIDTH;
  int y2=y1+BUTTON_HEIGHT;
//--- create
  if(!m_button3.Create(m_chart_id,m_name+"Button3",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!m_button3.Text("Locked"))
    return(false);
  if(!Add(m_button3))
    return(false);
  m_button3.Locking(true);
  m_button3.Alignment(WND_ALIGN_RIGHT|WND_ALIGN_BOTTOM,0,0,INDENT_RIGHT,INDENT_BOTTOM);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the "RadioGroup" element |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateRadioGroup(void)
{
  int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
  int x1=INDENT_LEFT;
  int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
  int x2=x1+sx;
  int y2=ClientAreaHeight()-INDENT_BOTTOM;
//--- create
  if(!m_radio_group.Create(m_chart_id,m_name+"RadioGroup",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!Add(m_radio_group))
    return(false);
  m_radio_group.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
  for(int i=0; i<4; i++)
    if(!m_radio_group.AddItem("Item "+IntegerToString(i),1<<i))
      return(false);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the "CheckGroup" element |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateCheckGroup(void)
{
  int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
  int x1=INDENT_LEFT+sx+CONTROLS_GAP_X;
  int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
  int x2=x1+sx;
  int y2=ClientAreaHeight()-INDENT_BOTTOM;
//--- create
  if(!m_check_group.Create(m_chart_id,m_name+"CheckGroup",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!Add(m_check_group))
    return(false);
  m_check_group.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
  for(int i=0; i<4; i++)
    if(!m_check_group.AddItem("Item "+IntegerToString(i),1<<i))
      return(false);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Create the "ListView" element |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateListView(void)
{
  int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
  int x1=ClientAreaWidth()-(sx+INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
  int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
  int x2=x1+sx;
  int y2=ClientAreaHeight()-INDENT_BOTTOM;
//--- create
  if(!m_list_view.Create(m_chart_id,m_name+"ListView",m_subwin,x1,y1,x2,y2))
    return(false);
  if(!Add(m_list_view))
    return(false);
  m_list_view.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
  for(int i=0; i<16; i++)
    if(!m_list_view.ItemAdd("Item "+IntegerToString(i)))
      return(false);
//--- succeed
  return(true);
}
//+------------------------------------------------------------------+
//| Handler of resizing |
//+------------------------------------------------------------------+
bool CPanelDialog::OnResize(void)
{
//--- call method of parent class
  if(!CAppDialog::OnResize()) return(false);
//--- coordinates
  int x=ClientAreaLeft()+INDENT_LEFT;
  int y=m_radio_group.Top();
  int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- move and resize the "RadioGroup" element
  m_radio_group.Move(x,y);
  m_radio_group.Width(sx);
//--- move and resize the "CheckGroup" element
  x=ClientAreaLeft()+INDENT_LEFT+sx+CONTROLS_GAP_X;
  m_check_group.Move(x,y);
  m_check_group.Width(sx);
//--- move and resize the "ListView" element
  x=ClientAreaLeft()+ClientAreaWidth()-(sx+INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
  m_list_view.Move(x,y);
  m_list_view.Width(sx);
//--- succeed
  return(true);
}

//--- 创建带文本的标签
void PutLabelT2(string name,int x,int y,string text, int space)
{
    ObjectCreate(0,name,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
    ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
    ObjectSetInteger(0,name,OBJPROP_CORNER,space);
    ObjectSetString(0,name,OBJPROP_TEXT,text);
    ObjectSetString(0,name,OBJPROP_FONT,"Arial");
    ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
    ObjectSetInteger(0,name,OBJPROP_COLOR,TextColor);
    ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
    ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

//--- 创建数据标签
void PutLabelD2(string name,int x,int y,string data,int space)
{
    ObjectCreate(0,name,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
    ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
    ObjectSetInteger(0,name,OBJPROP_CORNER,space);
    ObjectSetString(0,name,OBJPROP_TEXT,data);
    ObjectSetString(0,name,OBJPROP_FONT,"Arial");
    ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSizeInfo);
    ObjectSetInteger(0,name,OBJPROP_COLOR,InfoDataColor);
    ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
    ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

//+------------------------------------------------------------------+
//| Event handler |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton1(void)
{
  m_edit.Text(__FUNCTION__);
}
//+------------------------------------------------------------------+
//| Event handler |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton2(void)
{
  m_edit.Text(__FUNCTION__);
}
//+------------------------------------------------------------------+
//| Event handler |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton3(void)
{
  if(m_button3.Pressed())
    m_edit.Text(__FUNCTION__+"On");
  else
    m_edit.Text(__FUNCTION__+"Off");
}
//+------------------------------------------------------------------+
//| Event handler |
//+------------------------------------------------------------------+
void CPanelDialog::OnChangeListView(void)
{
  m_edit.Text(__FUNCTION__+" \""+m_list_view.Select()+"\"");
}
//+------------------------------------------------------------------+
//| Event handler |
//+------------------------------------------------------------------+
void CPanelDialog::OnChangeRadioGroup(void)
{
  m_edit.Text(__FUNCTION__+" : Value="+IntegerToString(m_radio_group.Value()));
}
//+------------------------------------------------------------------+
//| Event handler |
//+------------------------------------------------------------------+
void CPanelDialog::OnChangeCheckGroup(void)
{
  m_edit.Text(__FUNCTION__+" : Value="+IntegerToString(m_check_group.Value()));
}
//+------------------------------------------------------------------+
//| Rest events handler |
//+------------------------------------------------------------------+
bool CPanelDialog::OnDefault(const int id,const long &lparam,const double &dparam,const string &sparam)
{
//--- restore buttons' states after mouse move'n'click
  //if(id==CHARTEVENT_CLICK)
  //  m_radio_group.RedrawButtonStates();
//--- let's handle event by parent
  return(false);
}
//+------------------------------------------------------------------+
//| |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
CPanelDialog ExtDialog;
//+------------------------------------------------------------------+
//| |
//+------------------------------------------------------------------+
void intX()
{
  (ExtDialog.Create(0,"Simple Panel",0,50,50,390,200));
  (ExtDialog.Run());
}

//+------------------------------------------------------------------+
void CloseAll()
{
  double Equity  = AccountInfoDouble(ACCOUNT_EQUITY);
  double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
  double Calculate = NormalizeDouble( Equity - Balance, 2);
  double Percentage = NormalizeDouble((inPercentage_SL/100) * Balance,2);
  int tOrders = OrdersTotal();
  for(int i = tOrders - 1 ; i >= 0; i--) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
        if( OrderType() == OP_BUY || OrderType() == OP_SELL  ) {
          if( Calculate <= -inFixed_SL || Calculate <= -Percentage) {
            int cl = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, clrNONE);
            Print("Close Reached Loss Amount ");
          }
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Cek_Loss_daily()
{
  bool cekDAY = false;
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  double Loss_perct = inPercentage_SL/100*balance;
  double profit  = 0;
  for(int i = 0; i <  OrdersHistoryTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
      if(OrderSymbol() == Symbol()  && OrderMagicNumber() == Magic) {
        if(OrderType() == OP_BUY || OrderType() == OP_SELL  ) {
          string now  = TimeToString(TimeCurrent(), TIME_DATE);
          string OCT  = TimeToString(OrderCloseTime(), TIME_DATE);
          if( OCT == now) {
            profit += OrderProfit()+OrderSwap()+OrderCommission();
            if(profit <= -inFixed_SL || profit <= -Loss_perct ) {
              cekDAY = true;
            }
          }
        }
      }
    }
  }
  return(cekDAY);
}
//+------------------------------------------------------------------+
#ifdef __MQL5__
int TimeHour(datetime date)
{
  MqlDateTime tm;
  TimeToStruct(date,tm);
  return(tm.hour);
}
#endif
//+------------------------------------------------------------------+
// 这是全新的函数，添加到所有现有函数之后
void UpdateInfoPanel() 
{
    // 1. 创建面板背景
    if(!ObjectFind(0, "INFO_fon")) {
        RectLabelCreate3("INFO_fon",220,20,200,225,FonColor);
    }
    
    // 2. 标题部分
    PutLabel("INFO_LOGO",165,29,"Caius Killer 3.3");
    
    // 3. 账户信息区块
    PutLabel_("INFO_txt1",215,45,"账户信息");
    
    // 4. 具体数据行
    PutLabel("INFO_txt2",215,70,"最小停止:");
    PutLabel_("INFO_txt13",85,70,IntegerToString((int)SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)));
    
    PutLabel("INFO_txt3",215,95,"本期利润百分比:");
    PutLabel_("INFO_txt14",85,95,StringFormat("%.2f",NewProfProc));
    
    PutLabel("INFO_txt4",215,115,"余额:");
    PutLabel_("INFO_txt15",85,115,StringFormat("%.2f",AccountInfoDouble(ACCOUNT_BALANCE)));
    
    PutLabel("INFO_txt5",215,135,"账户净值:");
    PutLabel_("INFO_txt16",85,135,StringFormat("%.2f",AccountInfoDouble(ACCOUNT_EQUITY)));
    
    // 5. 仓位情况区块
    PutLabel_("INFO_txt6",215,160,"仓位情况");
    
    PutLabel("INFO_txt7",215,180,"仓位盈亏:");
    PutLabel_("INFO_txt17",85,180,StringFormat("%.2f",Profit(-1)));
    
    PutLabel("INFO_txt8",215,200,"利润总额:");
    PutLabel_("INFO_txt18",85,200,StringFormat("%.2f",ProfitAll(-1)));
    
    PutLabel("INFO_txt9",215,220,"今天利润:");
    PutLabel_("INFO_txt19",85,220,StringFormat("%.2f",ProfitDey(-1)));
    
    PutLabel("INFO_txt10",215,240,"昨天利润:");
    PutLabel_("INFO_txt20",85,240,StringFormat("%.2f",ProfitTuDey(-1)));
    
    PutLabel("INFO_txt11",215,260,"周利润:");
    PutLabel_("INFO_txt21",85,260,StringFormat("%.2f",ProfitWeek(-1)));
    
    PutLabel("INFO_txt12",215,280,"月利润:");
    PutLabel_("INFO_txt22",85,280,StringFormat("%.2f",ProfitMontag(-1)));
    // 最大浮亏区块
PutLabel_("INFO_txt23",215,300,"今日最大浮亏:");
PutLabel_("INFO_txt24",85,300,StringFormat("%.2f",MaxDrawdownDay));

PutLabel_("INFO_txt25",215,320,"昨日最大浮亏:");
PutLabel_("INFO_txt26",85,320,StringFormat("%.2f",MaxDrawdownYesterday));

PutLabel_("INFO_txt27",215,340,"本周最大浮亏:");
PutLabel_("INFO_txt28",85,340,StringFormat("%.2f",MaxDrawdownWeek));

PutLabel_("INFO_txt29",215,360,"本月最大浮亏:");
PutLabel_("INFO_txt30",85,360,StringFormat("%.2f",MaxDrawdownMonth));
    
    // 市场状态标题
    PutLabelT("Indicator_Title", 20, 25, "=== 市场动态指标 ===", CORNER_LEFT_UPPER);
    
    // 趋势状态
    PutLabelT("Trend_Label", 10, 45, "趋势方向:", CORNER_LEFT_UPPER);
    PutLabelD("Trend_Value", 80, 45, TrendStatus, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "Trend_Value", OBJPROP_COLOR, TrendColor);
    
    // ADX状态
    PutLabelT("ADX_Label", 10, 65, "ADX强度:", CORNER_LEFT_UPPER);
    PutLabelD("ADX_Value", 80, 65, ADXStatus, CORNER_LEFT_UPPER);
    
    // RSI状态
    PutLabelT("RSI_Label", 10, 85, "RSI状态:", CORNER_LEFT_UPPER);
    PutLabelD("RSI_Value", 80, 85, RSIStatus, CORNER_LEFT_UPPER);
    
    // 布林带状态
    PutLabelT("BB_Label", 10, 105, "布林带:", CORNER_LEFT_UPPER);
    PutLabelD("BB_Value", 80, 105, BBStatus, CORNER_LEFT_UPPER);
    
    // 均线状态
    PutLabelT("MA_Label", 10, 125, "均线交叉:", CORNER_LEFT_UPPER);
    PutLabelD("MA_Value", 80, 125, MAStatus, CORNER_LEFT_UPPER);
    
    // 综合状态
    PutLabelT("Market_Status", 10, 145, MarketStatus, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "Market_Status", OBJPROP_COLOR, clrGold);
    
    // 7. 交易按钮 ========================================
    string buttonText = "BUY " + DoubleToString(Lot, 2);
    if(!ObjectFind(0, "TRADEs_B")) {
        PutButtonBS("TRADEs_B",220,245,buttonText,100,22,FonButtonBuy,TextButtonBS);
    } else {
        ObjectSetString(0, "TRADEs_B", OBJPROP_TEXT, buttonText);
    }
    
    buttonText = "SELL " + DoubleToString(Lot, 2);
    if(!ObjectFind(0, "TRADEs_S")) {
        PutButtonBS("TRADEs_S",118,245,buttonText,100,22,FonButtonSell,TextButtonBS);
    } else {
        ObjectSetString(0, "TRADEs_S", OBJPROP_TEXT, buttonText);
    }
}
