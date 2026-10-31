//+------------------------------------------------------------------+
//|                                              Private_EA_v1.mq5   |
//|                                  Copyright 2026, LifeinDreamsWorld|
//+------------------------------------------------------------------+
#property copyright "Copyright © 2026, LifeInDreamsWorld"
#property link      "https://t.me/LifeInDreamsWorld"
#property version "2.0"

//--- === Lot Settings ===
input double   InpStartLot       = 0.01;      
input double   InpLotIncrement   = 0.01;      
input int      InpOrdersPerLevel = 4;         

//--- === Grid Settings ===
input double   InpGridSpacing    = 2.0;       
input int      InpMaxOrdersSide  = 40;        

//--- === Take Profit Settings ===
input double   InpTakeProfit     = 2.0;       

//--- === Risk Management ===
input double   InpMaxDDPercent   = 50.0;      
input double   InpMinEquityPct   = 50.0;      

//--- === Safety Settings ===
input int      InpSlippage       = 50;        
input double   InpMaxSpread      = 0.5;       
input int      InpOrderDelay     = 500;       

//--- Expiry Configuration
datetime ExpiryDate = D'2026.04.12 23:59'; // Expiry Date: 20 May 2026

//--- Colors & Magic
#define CLR_GOLD     C'255,185,0'
#define CLR_BG       C'10,12,25'
#define CLR_BORD     C'45,45,65'
#define CLR_SUPPORT  C'30,150,220'
#define MAGIC_BUY    1111
#define MAGIC_SELL   2222

datetime m_lastOrderTime = 0;
bool m_isExpired = false;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit() 
{ 
    if(TimeCurrent() >= ExpiryDate) 
    {
        m_isExpired = true;
        Alert("EA EXPIRED! Contact Owner: https://t.me/LifeInDreamsWorld");
    }
    return(INIT_SUCCEEDED); 
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "pnl_"); }

//+------------------------------------------------------------------+
//| Main Execution                                                   |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check Expiry First
    if(m_isExpired) 
    {
        DrawExactPanel();
        return;
    }

    if(!CheckProtection()) return;
    HandleGridSide(ORDER_TYPE_BUY, MAGIC_BUY);
    HandleGridSide(ORDER_TYPE_SELL, MAGIC_SELL);
    DrawExactPanel();
}

void HandleGridSide(ENUM_ORDER_TYPE type, int magic)
{
    double pnl = GetBasketProfit(magic);
    if(pnl >= InpTakeProfit) { CloseAllByMagic(magic); return; }

    int count = CountOrders(magic);
    if(count == 0 && AccountInfoDouble(ACCOUNT_EQUITY) >= (AccountInfoDouble(ACCOUNT_BALANCE) * (InpMinEquityPct/100))) {
        SendTrade(type, InpStartLot, magic);
    } 
    else if(count > 0 && count < InpMaxOrdersSide) {
        double lastP = GetLastOrderPrice(magic);
        double curP = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double gap = (type == ORDER_TYPE_BUY) ? (lastP - curP) : (curP - lastP);

        if(gap >= InpGridSpacing && (int)GetTickCount() - (int)m_lastOrderTime > InpOrderDelay) {
            double nextLot = InpStartLot + ((count / InpOrdersPerLevel) * InpLotIncrement);
            SendTrade(type, NormalizeDouble(nextLot, 2), magic);
        }
    }
}

//+------------------------------------------------------------------+
//| DASHBOARD RENDERING                                              |
//+------------------------------------------------------------------+
void DrawExactPanel()
{
    CreateBox("pnl_bg", 5, 5, 235, 510, CLR_BG, CLR_BORD);
    CreateText("pnl_title", 15, 15, "PRIVATE EA", 13, CLR_GOLD, "Arial Black");
    CreateText("pnl_ver", 125, 18, "v1.0", 7, clrGray);
    CreateBox("pnl_sym_bg", 165, 13, 65, 18, CLR_BG, clrGray);
    CreateText("pnl_sym", 170, 16, _Symbol + " " + string(Period()), 7, CLR_GOLD);

    int y = 50;
    
    if(m_isExpired)
    {
        CreateText("pnl_exp_h", 15, y, "STATUS: EXPIRED", 10, clrCrimson, "Arial Bold");
        y+=30;
        CreateText("pnl_exp_m", 15, y, "License ended on 20 May 2026", 8, clrWhite);
        y+=20;
        CreateText("pnl_exp_c", 15, y, "Contact owner to renew", 8, clrWhite);
    }
    else
    {
        CreateText("pnl_acc_h", 15, y, "ACCOUNT", 8, clrCornflowerBlue);
        y+=22; CreateRow("Bal", "Balance", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2)+" USD", y);
        y+=18; CreateRow("Eq", "Equity", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2)+" USD", y);
        double fl = AccountInfoDouble(ACCOUNT_EQUITY)-AccountInfoDouble(ACCOUNT_BALANCE);
        y+=18; CreateRow("Fl", "Floating P/L", (fl>=0?"+":"")+DoubleToString(fl, 2)+" USD", y, (fl>=0?clrLime:clrCrimson));
        double dd = (AccountInfoDouble(ACCOUNT_BALANCE)>0)?(MathAbs(fl)/AccountInfoDouble(ACCOUNT_BALANCE)*100):0;
        y+=18; CreateRow("Dd", "Drawdown", DoubleToString(dd, 2)+"%", y, clrLime);

        y+=30; CreateText("pnl_set_h", 15, y, "SETTINGS", 8, clrCornflowerBlue);
        y+=22; CreateRowSet("G", "Grid", "$"+DoubleToString(InpGridSpacing, 2), "L", "Lot", DoubleToString(InpStartLot, 2), y);
        y+=18; CreateRowSet("S", "Step", "+"+DoubleToString(InpLotIncrement, 2)+" x"+string(InpOrdersPerLevel), "T", "TP", DoubleToString(InpTakeProfit, 2), y);

        y+=35; CreateText("pnl_b_h", 15, y, "• BUY BASKET", 8, clrLime);
        UpdateBasketUI(MAGIC_BUY, "B", y+22);

        y+=100; CreateText("pnl_s_h", 15, y, "• SELL BASKET", 8, clrCrimson);
        UpdateBasketUI(MAGIC_SELL, "S", y+22);
    }

    y = 390; // Market Section fixed position
    CreateText("pnl_m_h", 15, y, "MARKET", 8, clrCornflowerBlue);
    y+=22; CreateRowSet("Sp", "Spread", "$"+DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK)-SymbolInfoDouble(_Symbol, SYMBOL_BID), 3), "St", "Status", (m_isExpired ? "Expired" : (CountOrders(MAGIC_BUY)+CountOrders(MAGIC_SELL)>0?"Trade":"Wait")), y);
    y+=18; CreateText("pnl_sv_l", 15, y, "Server", 8, clrGray); 
    CreateText("pnl_sv_v", 65, y, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), 8, clrWhite);

    y+=30;
    CreateBox("pnl_btn", 12, y, 220, 32, CLR_SUPPORT, CLR_NONE);
    CreateText("pnl_btn_t", 40, y+8, "Contact Owner t.me/LifeInDreamsWorld", 9, clrWhite, "Arial Bold");
    
    y+=42;
    CreateText("pnl_footer", 15, y, "t.me/LifeInDreamsWorld | Telegram", 7, clrDarkSlateGray);
    ChartRedraw();
}

void UpdateBasketUI(int m, string p, int y)
{
    int cnt = CountOrders(m);
    double pnl = GetBasketProfit(m);
    double tpPct = (pnl>0)?(pnl/InpTakeProfit)*100:0;
    
    CreateRowSet(p+"1", "Orders", string(cnt), p+"2", "Lots", DoubleToString(GetTotalLots(m), 2), y);
    y+=16; CreateRowSet(p+"3", "Level", string(cnt/InpOrdersPerLevel), p+"4", "Next", DoubleToString(InpStartLot+((cnt/InpOrdersPerLevel)*InpLotIncrement), 2), y);
    y+=16; CreateText("pnl_"+p+"_pl", 15, y, "Profit", 8, clrGray);
    CreateText("pnl_"+p+"_pv", 65, y, (pnl>=0?"+":"")+DoubleToString(pnl, 2), 8, (pnl>=0?clrLime:clrCrimson));
    
    y+=18; CreateText("pnl_"+p+"_tp", 15, y, "TP", 8, clrGray);
    CreateBox("pnl_"+p+"_bar_bg", 50, y+5, 100, 3, C'35,35,45', CLR_NONE);
    CreateBox("pnl_"+p+"_bar_fg", 50, y+5, (int)MathMin(tpPct, 100), 3, CLR_GOLD, CLR_NONE);
    CreateText("pnl_"+p+"_tpv", 160, y, IntegerToString((int)tpPct)+"%", 7, clrGray);
}

// --- Internal Helper Functions ---
void CreateRow(string n, string l, string v, int y, color c=clrWhite) {
    CreateText("pnl_l_"+n, 15, y, l, 8, clrSilver);
    CreateText("pnl_v_"+n, 140, y, v, 8, c);
}
void CreateRowSet(string n1, string l1, string v1, string n2, string l2, string v2, int y) {
    CreateText("pnl_l_"+n1, 15, y, l1, 8, clrGray); CreateText("pnl_v_"+n1, 60, y, v1, 8, CLR_GOLD);
    CreateText("pnl_l_"+n2, 135, y, l2, 8, clrGray); CreateText("pnl_v_"+n2, 185, y, v2, 8, CLR_GOLD);
}
void CreateText(string n, int x, int y, string t, int s, color c, string f="Arial") {
    if(ObjectFind(0, n)<0) ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); ObjectSetInteger(0, n, OBJPROP_COLOR, c);
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetString(0, n, OBJPROP_FONT, f);
}
void CreateBox(string n, int x, int y, int w, int h, color bg, color brd) {
    if(ObjectFind(0, n)<0) ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, n, OBJPROP_COLOR, brd);
}

double GetBasketProfit(int m) {
    double p = 0;
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong t = PositionGetTicket(i);
        if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == m)
            p += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    }
    return p;
}
int CountOrders(int m) {
    int c = 0;
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == m) c++;
    }
    return c;
}
double GetTotalLots(int m) {
    double l = 0;
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong t = PositionGetTicket(i);
        if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == m) l += PositionGetDouble(POSITION_VOLUME);
    }
    return l;
}
double GetLastOrderPrice(int m) {
    double p = 0; datetime t = 0;
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong tick = PositionGetTicket(i);
        if(PositionSelectByTicket(tick) && PositionGetInteger(POSITION_MAGIC) == m) {
            if(PositionGetInteger(POSITION_TIME) > t) { t = (datetime)PositionGetInteger(POSITION_TIME); p = PositionGetDouble(POSITION_PRICE_OPEN); }
        }
    }
    return p;
}
void SendTrade(ENUM_ORDER_TYPE type, double lot, int magic) {
    if(SymbolInfoDouble(_Symbol, SYMBOL_ASK)-SymbolInfoDouble(_Symbol, SYMBOL_BID) > InpMaxSpread) return;
    MqlTradeRequest req = {}; MqlTradeResult res = {};
    req.action = TRADE_ACTION_DEAL; req.symbol = _Symbol; req.volume = lot; req.type = type; req.magic = magic;
    req.price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    req.deviation = InpSlippage;
    bool sent = OrderSend(req, res);
    if(sent) m_lastOrderTime = GetTickCount();
}
bool CheckProtection() {
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    double eq = AccountInfoDouble(ACCOUNT_EQUITY);
    if(bal > 0 && ((bal - eq) / bal * 100.0) >= InpMaxDDPercent) { CloseAllByMagic(MAGIC_BUY); CloseAllByMagic(MAGIC_SELL); return false; }
    return true;
}
void CloseAllByMagic(int m) {
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == m) {
            MqlTradeRequest req = {}; MqlTradeResult res = {};
            req.action = TRADE_ACTION_DEAL; req.position = ticket; req.symbol = _Symbol; req.volume = PositionGetDouble(POSITION_VOLUME);
            req.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            req.price = (req.type == ORDER_TYPE_SELL) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            OrderSend(req, res);
        }
    }
}
