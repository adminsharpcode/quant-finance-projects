//+------------------------------------------------------------------+
//|                                          Quantum Valkyrie.mq5    |
//|                               Copyright 2026, Bogdan Ion Puscasu |
//|                        Precision XAUUSD Market Structure Scalper |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Bogdan Ion Puscasu"
#property version     "5.2"
#property strict
#property description "Quantum Valkyrie © 2026, Bogdan Ion Puscasu."
#property description "Expert Advisor for MetaTrader 5 © 2000-2026, MetaQuotes Ltd."

#include <Trade\Trade.mqh>
CTrade Trade;

//--- UI Colors
#define CLR_TITLE      C'0,162,232'
#define CLR_LABEL      clrWhite
#define CLR_BUY        clrLime
#define CLR_SELL       clrRed
#define CLR_VAL        clrWhite
#define CLR_RISK       C'230,230,230'

//--- Enumerations
enum ENUM_AUTO_LOT {
    RISK_VERY_LOW,   // Very low, 5000 USD, suitable for prop firms
    RISK_LOW,        // Low, 2500 USD, suitable for large accounts
    RISK_LOW_MED,    // Low-medium, 1500 USD
    RISK_MEDIUM,     // Medium, 1000 USD, recommended
    RISK_MED_HIGH,   // Medium-high, 800 USD
    RISK_HIGH,       // High, 600 USD
    RISK_VERY_HIGH,  // Very high, 500 USD, higher caution advised
    RISK_EXTREME     // Extreme, 300 USD, for testing purposes only
};

enum ENUM_SL_TYPE {
    SL_FIXED,        // Fixed points distance
    SL_ATR           // ATR-based distance
};

//--- INPUT PARAMETERS ---
input string Inp_0          = "Quantum Valkyrie Optimized XAUUSD [Gold] strategy for M15"; // >>> Overview

input group ">>> General"
input int    InpMagic       = 8242;             // EA magic number
input string InpComment     = "Quantum Valkyrie"; // Order comment

input group ">>> Risk"
input bool   InpAutoLot     = true;             // Enable automatic lot calculation
input ENUM_AUTO_LOT InpRisk = RISK_MEDIUM;      // Auto lot risk level
input double InpFixedLot    = 0.01;             // Fixed lot if auto lot is disabled
input double InpRecoveryMult= 2.0;              // Lot multiplier after a losing trade

input group ">>> Trade Parameters"
input int    InpTP          = 5000;             // Fixed Take Profit in points
input int    InpSL          = 1500;             // Initial Stop Loss in points
input ENUM_SL_TYPE InpSLMode= SL_ATR;           // Stop Loss calculation method
input int    InpBE          = 0;                // Break-even level in points (0 = disabled)

input group ">>> Execution"
input int    InpMaxSpread   = 30;               // Maximum allowed spread in points
input int    InpSlippage    = 100;              // Internal maximum slippage in points

input group ">>> Trading Days"
input bool   InpDaySun      = true;             // Allow trading on Sunday
input bool   InpDayMon      = true;             // Allow trading on Monday
input bool   InpDayTue      = true;             // Allow trading on Tuesday
input bool   InpDayWed      = true;             // Allow trading on Wednesday
input bool   InpDayThu      = true;             // Allow trading on Thursday
input bool   InpDayFri      = true;             // Allow trading on Friday
input bool   InpDaySat      = true;             // Allow trading on Saturday
input bool   InpNoNFP       = true;             // Disable trading on NFP Friday
input bool   InpNoHolidays  = true;             // Disable trading from Dec 15 to Jan 15

input group ">>> Panel"
input int    InpPanelSize   = 14;               // Panel size (0 = disabled)

//--- INTERNAL
const int    LOOKBACK_STRUCTURE = 24;
const int    ATR_PERIOD         = 28;
const int    EMA_TREND          = 34;
const int    MAX_TRADES_DAY     = 4;

int g_hATR, g_hEMA;
int g_lossStreak = 0;

//+------------------------------------------------------------------+
int OnInit() {
    Trade.SetExpertMagicNumber(InpMagic);
    g_hATR = iATR(_Symbol, PERIOD_CURRENT, ATR_PERIOD);
    g_hEMA = iMA(_Symbol, PERIOD_H1, EMA_TREND, 0, MODE_EMA, PRICE_CLOSE);
    CreateDashboard();
    EventSetTimer(1);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    IndicatorRelease(g_hATR);
    IndicatorRelease(g_hEMA);
    ObjectsDeleteAll(0, "QV_");
    EventKillTimer();
}

void OnTick() {
    UpdateTrailing(); // Always run management first, even during high spread
    ManageStaleOrders();
    CheckHistoryForStreak();
    AdjustPendingOrdersSL();

    static int lastDay = -1;
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    if(dt.day != lastDay) { lastDay = dt.day; }
    
    if(!IsTradingAllowed()) return;
    if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpread) return;
    
    static datetime lastBar;
    if(iTime(_Symbol, PERIOD_CURRENT, 0) != lastBar) {
        lastBar = iTime(_Symbol, PERIOD_CURRENT, 0);
        if(CountTradesToday() < MAX_TRADES_DAY) ScanMarketStructure();
    }
    UpdateDashboard();
}

void OnTimer() { 
    UpdateTrailing(); // Backup management
    UpdateDashboard(); 
}

//+------------------------------------------------------------------+
void ScanMarketStructure() {
    if(CountTotalPositions() > 0) return;
    int hi_idx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, LOOKBACK_STRUCTURE, 1);
    int lo_idx = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, LOOKBACK_STRUCTURE, 1);
    double atr[1]; CopyBuffer(g_hATR, 0, 0, 1, atr);
    double ema[1]; CopyBuffer(g_hEMA, 0, 0, 1, ema);
    if(!IsMarketExplosive(atr[0])) return;

    double targetUSD = 35.0, tpUSD = 100.0; 
    if(InpSLMode == SL_ATR) {
        if(g_lossStreak == 0)      targetUSD = 35.0;
        else if(g_lossStreak == 1) targetUSD = 42.0;
        else if(g_lossStreak == 2) targetUSD = 46.0;
        else                       targetUSD = 46.0 + (double)(g_lossStreak - 2) * 2.0;
        tpUSD = targetUSD + 50.0;
    } else {
        targetUSD = 15.0; tpUSD = 50.0;
    }

    double lot = GetSmartLot();
    double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double slPoints = (targetUSD * tickSize) / (lot * tickVal * _Point);
    double tpPoints = (tpUSD * tickSize) / (lot * tickVal * _Point);

    bool isBullish = iClose(_Symbol, PERIOD_H1, 0) > ema[0];
    double swingHigh = iHigh(_Symbol, PERIOD_CURRENT, hi_idx);
    double swingLow  = iLow(_Symbol, PERIOD_CURRENT, lo_idx);

    if(isBullish) {
        double entry = swingHigh + (30 * _Point);
        Trade.BuyStop(lot, entry, _Symbol, NormalizeDouble(entry - slPoints * _Point, _Digits), NormalizeDouble(entry + tpPoints * _Point, _Digits), ORDER_TIME_GTC, 0, InpComment);
    } else {
        double entry = swingLow - (30 * _Point);
        Trade.SellStop(lot, entry, _Symbol, NormalizeDouble(entry + slPoints * _Point, _Digits), NormalizeDouble(entry - tpPoints * _Point, _Digits), ORDER_TIME_GTC, 0, InpComment);
    }
}

void AdjustPendingOrdersSL() {
    double targetUSD = 35.0; 
    if(InpSLMode == SL_ATR) {
        if(g_lossStreak == 0)      targetUSD = 35.0;
        else if(g_lossStreak == 1) targetUSD = 42.0;
        else if(g_lossStreak == 2) targetUSD = 46.0;
        else                       targetUSD = 46.0 + (double)(g_lossStreak - 2) * 2.0;
    } else return; 

    for(int i=OrdersTotal()-1; i>=0; i--) {
        ulong t = OrderGetTicket(i);
        if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == InpMagic) {
            double lot = OrderGetDouble(ORDER_VOLUME_INITIAL);
            double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            double slPts = (targetUSD * tickSize) / (lot * tickVal * _Point);
            double op = OrderGetDouble(ORDER_PRICE_OPEN);
            double oldSL = OrderGetDouble(ORDER_SL);
            double newSL = (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) ? op - slPts * _Point : op + slPts * _Point;
            if(MathAbs(newSL - oldSL) > _Point) Trade.OrderModify(t, op, newSL, OrderGetDouble(ORDER_TP), ORDER_TIME_GTC, 0);
        }
    }
}

//+------------------------------------------------------------------+
void CreateDashboard() {
    int x=20, y=20, spaceY=25;
    CreateLabel("QV_Title", "Quantum Valkyrie", x, y, 22, CLR_TITLE); y += 45;
    CreateLabel("QV_Perf_Lab", "Performance", x, y, 12, CLR_LABEL);
    CreateLabel("QV_Perf_Val_USD", "0.00 USD", x+240, y, 12, CLR_VAL);
    CreateLabel("QV_Perf_Val_PCT", "0 % / 0", x+480, y, 12, CLR_VAL);
    y += spaceY;
    ObjectCreate(0, "QV_Line", OBJ_HLINE, 0, 0, 0);
    ObjectSetInteger(0, "QV_Line", OBJPROP_COLOR, clrRed); y += 5;
    CreateLabel("QV_Risk_Info1", " ", x, y, 8, CLR_RISK); y += 10;
    CreateLabel("QV_Risk_Info2", " ", x, y, 8, CLR_RISK); y += 10;
    CreateLabel("QV_H_Buys", "Buys", x+155, y, 11, CLR_BUY);
    CreateLabel("QV_H_Sells", "Sells", x+325, y, 11, CLR_SELL);
    y += spaceY;
    CreateLabel("QV_L_Curr", "Current", x, y, 11, CLR_LABEL);
    CreateLabel("QV_V_CurrB", "-", x+155, y, 11, CLR_BUY);
    CreateLabel("QV_V_CurrS", "-", x+325, y, 11, CLR_SELL);
    y += spaceY;
    CreateLabel("QV_L_Pos", "Position", x, y, 11, CLR_LABEL);
    CreateLabel("QV_V_PosB", "-", x+155, y, 11, CLR_BUY);
    CreateLabel("QV_V_PosS", "-", x+325, y, 11, CLR_SELL);
    y += spaceY;
    CreateLabel("QV_L_Pend", "Pending", x, y, 11, CLR_LABEL);
    CreateLabel("QV_V_PendB", "-", x+155, y, 11, CLR_BUY);
    CreateLabel("QV_V_PendS", "-", x+325, y, 11, CLR_SELL);
    y += spaceY;
    CreateLabel("QV_L_Open", "Open", x, y, 11, CLR_LABEL);
    CreateLabel("QV_V_OpenB", "0.01 Lots", x+155, y, 11, CLR_BUY);
    CreateLabel("QV_V_OpenS", "0.01 Lots", x+325, y, 11, CLR_SELL);
    y += spaceY;
    CreateLabel("QV_L_Heart", "Heartbeat", x, y, 11, C'255,128,0');
    CreateLabel("QV_V_Heart", "00:00:00 | 0", x+110, y, 11, C'255,128,0');
}

void UpdateDashboard() {
    double profit=0; int totalTrades=0, wins=0;
    if(HistorySelect(0, TimeCurrent())) {
        for(int i=0; i<HistoryDealsTotal(); i++) {
            ulong t = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(t, DEAL_MAGIC) == InpMagic && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
                double p=HistoryDealGetDouble(t, DEAL_PROFIT); profit += p; totalTrades++; if(p >= 0) wins++;
            }
        }
    }
    double winPct=(totalTrades>0)?(double)wins/totalTrades*100:0;
    UpdateLabel("QV_Perf_Val_USD", DoubleToString(profit, 2) + " USD");
    UpdateLabel("QV_Perf_Val_PCT", IntegerToString((int)winPct) + " % / " + IntegerToString(totalTrades));
    
    int curB=0, curS=0, penB=0, penS=0;
    double lotB=0, lotS=0, lotPB=0, lotPS=0, slB=0, slS=0, slPB=0, slPS=0;
    for(int i=0; i<PositionsTotal(); i++) {
        if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic) {
            double v=PositionGetDouble(POSITION_VOLUME), sl=PositionGetDouble(POSITION_SL), op=PositionGetDouble(POSITION_PRICE_OPEN);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { curB++; lotB += v; if(sl > 0) slB = MathAbs(op - sl); }
            else { curS++; lotS += v; if(sl > 0) slS = MathAbs(op - sl); }
        }
    }
    for(int i=0; i<OrdersTotal(); i++) {
        ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==InpMagic) {
            double v=OrderGetDouble(ORDER_VOLUME_INITIAL), sl=OrderGetDouble(ORDER_SL), op=OrderGetDouble(ORDER_PRICE_OPEN);
            if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP) { penB++; lotPB += v; if(sl>0) slPB=MathAbs(op-sl); }
            else if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP) { penS++; lotPS += v; if(sl>0) slPS=MathAbs(op-sl); }
        }
    }
    double bal = AccountInfoDouble(ACCOUNT_BALANCE), tickM = (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)/SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)*_Point);
    string r1=" ", r2=" ";
    if(lotB+lotS > 0) { double lp=(lotB>0)?lotB:lotS; double sp=(lotB>0)?slB:slS; r1="SL for -"+IntegerToString((int)(sp/_Point))+", -"+DoubleToString(((sp/_Point)*lp*tickM/bal)*100, 2)+"%"; }
    if(lotPB+lotPS > 0) { double lp=(lotPB>0)?lotPB:lotPS; double sp=(lotPB>0)?slPB:slPS; r2="SL for -"+IntegerToString((int)(sp/_Point))+", -"+DoubleToString(((sp/_Point)*lp*tickM/bal)*100, 2)+"%"; }
    UpdateLabel("QV_Risk_Info1", r1); UpdateLabel("QV_Risk_Info2", (r1==r2)?" ":r2);
    UpdateLabel("QV_V_CurrB", (curB>0)?"Active":"-"); UpdateLabel("QV_V_CurrS", (curS>0)?"Active":"-");
    UpdateLabel("QV_V_PosB", (curB>0)?(DoubleToString(lotB,2)+" Lots / "+IntegerToString(curB)):"-"); UpdateLabel("QV_V_PosS", (curS>0)?(DoubleToString(lotS,2)+" Lots / "+IntegerToString(curS)):"-");
    UpdateLabel("QV_V_PendB", (penB>0)?(DoubleToString(lotPB,2)+" Lots / "+IntegerToString(penB)):"-"); UpdateLabel("QV_V_PendS", (penS>0)?(DoubleToString(lotPS,2)+" Lots / "+IntegerToString(penS)):"-");
    UpdateLabel("QV_V_OpenB", DoubleToString(GetSmartLot(), 2) + " Lots"); UpdateLabel("QV_V_OpenS", DoubleToString(GetSmartLot(), 2) + " Lots");
    UpdateLabel("QV_V_Heart", TimeToString(TimeCurrent(), TIME_SECONDS) + " | " + IntegerToString((int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)));
}

void CreateLabel(string n, string t, int x, int y, int s, color c) { ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); ObjectSetInteger(0, n, OBJPROP_COLOR, c); ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetString(0, n, OBJPROP_FONT, "Lucida Console"); }
void UpdateLabel(string n, string t) { if(ObjectFind(0, n)>=0) ObjectSetString(0, n, OBJPROP_TEXT, t); }

//--- Logic
bool IsMarketExplosive(double curATR) {
    double buf[]; ArraySetAsSeries(buf, true); if(CopyBuffer(g_hATR, 0, 1, 28, buf)<=0) return true;
    double avg=0; for(int i=0; i<28; i++) avg += buf[i]; return (curATR > (avg/28.0) * 1.18);
}

double GetSmartLot() {
    double lot=InpFixedLot; if(InpAutoLot) { double r[]={5000, 2500, 1500, 1000, 800, 600, 500, 300}; lot=(AccountInfoDouble(ACCOUNT_BALANCE)/r[InpRisk])*0.01; }
    
    int consecutiveLosses = 0;
    if(HistorySelect(0, TimeCurrent())) {
        int total = HistoryDealsTotal();
        for(int i=total-1; i>=0; i--) {
            ulong t = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(t, DEAL_MAGIC) == InpMagic && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
                double p = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
                if(p < -0.01) consecutiveLosses++; else break;
            }
        }
    }
    
    if(consecutiveLosses > 0 && consecutiveLosses <= 5) lot *= InpRecoveryMult; 
    return NormalizeDouble(MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), lot), 2);
}

void UpdateTrailing() {
    // Determine Trailing State: Recovery vs Normal
    int consecutiveLosses = 0;
    if(HistorySelect(0, TimeCurrent())) {
        int total = HistoryDealsTotal();
        for(int i = total - 1; i >= 0; i--) {
            ulong t = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(t, DEAL_MAGIC) == InpMagic && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
                double p = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
                if(p < -0.01) consecutiveLosses++; else break;
            }
        }
    }

    double triggerUSD = (consecutiveLosses > 0) ? 4.0 : 8.0;
    double trailGapUSD = (consecutiveLosses > 0) ? 1.0 : 2.0;

    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong t = PositionGetTicket(i);
        if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == InpMagic) {
            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION);
            if(profit < 1.0) continue; // Safety minimum

            double lot = PositionGetDouble(POSITION_VOLUME);
            double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            if(tickVal <= 0) continue;

            double priceRel = (trailGapUSD * tickSize) / (lot * tickVal);
            double stopLev = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
            double minGap = MathMax(priceRel, stopLev + 10 * _Point);
            
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);
            double op = PositionGetDouble(POSITION_PRICE_OPEN);

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                if(profit >= triggerUSD && sl < op + _Point) {
                    double secureSL = NormalizeDouble(bid - minGap, _Digits);
                    Trade.PositionModify(t, secureSL, tp);
                }
                else if(profit >= triggerUSD) {
                    double newSL = NormalizeDouble(bid - minGap, _Digits);
                    if(newSL > sl + 10 * _Point) Trade.PositionModify(t, newSL, tp);
                }
            } else {
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                if(profit >= triggerUSD && (sl == 0 || sl > op - _Point)) {
                    double secureSL = NormalizeDouble(ask + minGap, _Digits);
                    Trade.PositionModify(t, secureSL, tp);
                }
                else if(profit >= triggerUSD) {
                    double newSL = NormalizeDouble(ask + minGap, _Digits);
                    if(sl == 0 || newSL < sl - 10 * _Point) Trade.PositionModify(t, newSL, tp);
                }
            }
        }
    }
}

void ManageStaleOrders() {
    for(int i=OrdersTotal()-1; i>=0; i--) {
        ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==InpMagic) {
            if(TimeCurrent()-OrderGetInteger(ORDER_TIME_SETUP) > 10800) Trade.OrderDelete(t);
        }
    }
}

void CheckHistoryForStreak() {
    g_lossStreak = 0;
    if(HistorySelect(0, TimeCurrent())) {
        double maxBal = 0, curBal = 0;
        int lossesSincePeak = 0;
        int total = HistoryDealsTotal();
        for(int i = 0; i < total; i++) {
            ulong t = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(t, DEAL_MAGIC) == InpMagic) {
                double p = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
                curBal += p;
                if(curBal >= maxBal) {
                    maxBal = curBal;
                    lossesSincePeak = 0;
                } else {
                    if(HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT && p < -0.01)
                        lossesSincePeak++;
                }
            }
        }
        g_lossStreak = lossesSincePeak;
    }
}

int CountTotalPositions() {
    int c=0;
    for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==InpMagic) c++;
    for(int i=PositionsTotal()-1; i>=0; i--) if(PositionGetInteger(POSITION_MAGIC)==InpMagic) c++;
    return c;
}

int CountTradesToday() {
    int c=0; if(HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent())) {
        for(int i=0; i<HistoryDealsTotal(); i++) {
            ulong t=HistoryDealGetTicket(i); if(HistoryDealGetInteger(t, DEAL_MAGIC)==InpMagic && HistoryDealGetInteger(t, DEAL_ENTRY)==DEAL_ENTRY_OUT) c++;
        }
    }
    return c;
}

bool IsTradingAllowed() {
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    if(InpNoHolidays && ((dt.mon==12 && dt.day>=15) || (dt.mon==1 && dt.day<=15))) return false;
    if(!InpDaySun && dt.day_of_week==0) return false;
    if(!InpDayMon && dt.day_of_week==1) return false;
    if(!InpDayTue && dt.day_of_week==2) return false;
    if(!InpDayWed && dt.day_of_week==3) return false;
    if(!InpDayThu && dt.day_of_week==4) return false;
    if(!InpDayFri && dt.day_of_week==5) return false;
    if(!InpDaySat && dt.day_of_week==6) return false;
    return true;
}
