#property link          "https://www.earnforex.com/metatrader-expert-advisors/hidden-stop-loss-take-profit-ghost-sl-tp/"
#property version       "1.04"

#property copyright     "EarnForex.com - 2019-2025"
#property description   "This expert advisor will execute stop-loss and take-profit"
#property description   "without letting your broker know where they are."
#property description   ""
#property description   "WARNING: Use this software at your own risk."
#property description   "The creator of this expert advisor cannot be held responsible for any damage or loss."
#property description   ""
#property description   "Find More on EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"

#include <MQLTA ErrorHandling.mqh>
#include <MQLTA Utils.mqh>
#include <Trade/Trade.mqh>

enum ENUM_CONSIDER
{
    All = -1,                 // ALL ORDERS
    Buy = POSITION_TYPE_BUY,  // BUY ONLY
    Sell = POSITION_TYPE_SELL // SELL ONLY
};

enum ENUM_REFERENCE_PRICE
{
    PRICE_BID, // BID PRICE
    PRICE_ASK  // ASK PRICE
};

enum ENUM_LINE_TP_SL
{
    LINE_SL,
    LINE_TP
};

input string Comment_1 = "====================";     // Expert Advisor Settings
input ENUM_REFERENCE_PRICE BuyRefPrice = PRICE_BID;  // Reference Price for Buy Orders
input ENUM_REFERENCE_PRICE SellRefPrice = PRICE_ASK; // Reference Price for Sell Orders
input int SLDistance = 500;                          // Stop-Loss in Points
input int TPDistance = 500;                          // Take-Profit in Points
input int Slippage = 10;                             // Slippage in Points
input bool AsyncMode = false;                        // Async Mode
input string Comment_2 = "====================";     // Orders Filtering Options
input bool OnlyCurrentSymbol = true;                 // Apply to Current Symbol Only
input ENUM_CONSIDER OnlyType = All;                  // Apply to
input bool UseMagic = false;                         // Filter by Magic Number
input int MagicNumber = 0;                           // Magic Number (if above is true)
input bool UseComment = false;                       // Filter by Comment
input string CommentFilter = "";                     // Comment (if above is true)
input bool EnableMonitoringParam = false;            // Enable Monitoring
input string Comment_3 = "====================";     // Notification Options
input bool EnableNotify = false;                     // Enable Notifications Feature
input bool SendAlert = true;                         // Send Alert Notification
input bool SendApp = false;                          // Send Notification to Mobile
input bool SendEmail = false;                        // Send Notification via Email
input string Comment_3a = "====================";    // Graphical Window
input bool ShowPanel = true;                         // Show Graphical Panel
input string ExpertName = "MQLTA-GTPSL";             // Expert Name (to name the objects)
input int Xoff = 20;                                 // Horizontal spacing for the control panel
input int Yoff = 20;                                 // Vertical spacing for the control panel
input ENUM_BASE_CORNER ChartCorner = CORNER_LEFT_UPPER; // Chart Corner
input int FontSize = 10;                             // Font Size
input bool DisplayLines = true;                      // Display Lines
input color TPColor = clrGreen;                      // TP Line Color
input color SLColor = clrSalmon;                     // SL Line Color
input string LabelFont = "Tahoma";                   // Label Font
input int LabelSize = 8;                             // Label Size

// Global variables:
int OrderOpRetry = 5;
double DPIScale; // Scaling parameter for the panel based on the screen DPI.
int PanelMovY, PanelLabX, PanelLabY, PanelRecX;
bool EnableMonitoring;
CTrade Trade;

void OnInit()
{
    CleanPanel();

    EnableMonitoring = EnableMonitoringParam;
    if (EnableMonitoring) // If enabled via input parameters, trigger auto-trading checks:
    {
        EnableMonitoring = false;
        ChangeMonitoringEnabled();
    }

    DPIScale = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

    PanelMovY = (int)MathRound(20 * DPIScale);
    PanelLabX = (int)MathRound(150 * DPIScale);
    PanelLabY = PanelMovY;
    PanelRecX = PanelLabX + 4;
    
    Trade.SetDeviationInPoints(Slippage);
    Trade.SetAsyncMode(AsyncMode);

    if (ShowPanel) DrawPanel();

    EventSetTimer(1);
}

void OnDeinit(const int reason)
{
    CleanPanel();
    EventKillTimer();
}

void OnTick()
{
    if (EnableMonitoring) MonitoringTPSL();
    if (ShowPanel) DrawPanel();
    if (DisplayLines) CheckLines();
}

void OnTimer()
{
    if (EnableMonitoring) MonitoringTPSL();
    if (ShowPanel) DrawPanel();
    if (DisplayLines) CheckLines();
}

void OnTrade()
{
    if (EnableMonitoring) MonitoringTPSL();
    if (ShowPanel) DrawPanel();
    if (DisplayLines) CheckLines();
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == PanelEnableDisable)
        {
            ChangeMonitoringEnabled();
        }
    }
    else if (id == CHARTEVENT_KEYDOWN)
    {
        if (lparam == 27)
        {
            if (MessageBox("Are you sure you want to close the EA?", "EXIT ?", MB_YESNO) == IDYES)
            {
                ExpertRemove();
            }
        }
    }
    else if (id == CHARTEVENT_CHART_CHANGE)
    {
        if (DisplayLines) RedrawLabels();
    }
}

void MonitoringTPSL()
{
    for (int i = PositionsTotal() - 1; i >= 0 ; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0)
        {
            int Error = GetLastError();
            string ErrorText = GetLastErrorText(Error);
            Print("ERROR - Unable to select the position - ", Error);
            Print("ERROR - ", ErrorText);
            break;
        }
        if (OnlyCurrentSymbol && PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        if (UseMagic && PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        if (UseComment && StringFind(PositionGetString(POSITION_COMMENT), CommentFilter) < 0) continue;
        if (OnlyType != All && PositionGetInteger(POSITION_TYPE) != OnlyType) continue;

        string Instrument = PositionGetString(POSITION_SYMBOL);
        double point = SymbolInfoDouble(Instrument, SYMBOL_POINT);
        double ReferencePrice = 0;
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            if (BuyRefPrice == PRICE_BID) ReferencePrice = SymbolInfoDouble(Instrument, SYMBOL_BID);
            else if (BuyRefPrice == PRICE_ASK) ReferencePrice = SymbolInfoDouble(Instrument, SYMBOL_ASK);
            if (TPDistance > 0)
            {
                if (PositionGetDouble(POSITION_PRICE_OPEN) + TPDistance * point < ReferencePrice) CloseOrder(ticket, PositionGetDouble(POSITION_VOLUME), ReferencePrice, Instrument);
                else if ((DisplayLines) && (Instrument == Symbol()))
                {
                    DrawLine(LINE_TP, ticket, PositionGetDouble(POSITION_PRICE_OPEN) + TPDistance * point);
                }
            }
            if (SLDistance > 0)
            {
                if (PositionGetDouble(POSITION_PRICE_OPEN) - SLDistance * point > ReferencePrice) CloseOrder(ticket, PositionGetDouble(POSITION_VOLUME), ReferencePrice, Instrument);
                else if ((DisplayLines) && (Instrument == Symbol()))
                {
                    DrawLine(LINE_SL, ticket, PositionGetDouble(POSITION_PRICE_OPEN) - SLDistance * point);
                }
            }
        }
        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            if (SellRefPrice == PRICE_ASK) ReferencePrice = SymbolInfoDouble(Instrument, SYMBOL_ASK);
            else if (SellRefPrice == PRICE_BID) ReferencePrice = SymbolInfoDouble(Instrument, SYMBOL_BID);

            if (TPDistance > 0)
            {
                if (PositionGetDouble(POSITION_PRICE_OPEN) - TPDistance * point > ReferencePrice) CloseOrder(ticket, PositionGetDouble(POSITION_VOLUME), ReferencePrice, Instrument);
                else if ((DisplayLines) && (Instrument == Symbol()))
                {
                    DrawLine(LINE_TP, ticket, PositionGetDouble(POSITION_PRICE_OPEN) - TPDistance * point);
                }
            }
            if (SLDistance > 0)
            {
                if (PositionGetDouble(POSITION_PRICE_OPEN) + SLDistance * point < ReferencePrice) CloseOrder(ticket, PositionGetDouble(POSITION_VOLUME), ReferencePrice, Instrument);
                else if ((DisplayLines) && (Instrument == Symbol()))
                {
                    DrawLine(LINE_SL, ticket, PositionGetDouble(POSITION_PRICE_OPEN) + SLDistance * point);
                }
            }
        }
    }
    ChartRedraw();
}

// Close a single order with error handling and multiple retries.
void CloseOrder(ulong Ticket, double Lots, double CurrentPrice, string Instrument)
{
    if (!AsyncMode)
    {
        // Try to close the order by its ticket number multiple times or until it works.
        for (int i = 1; i <= OrderOpRetry; i++)
        {
            // Send the close command.
            bool res = Trade.PositionClose(Ticket);
            // If successful, print the result and exit the function:
            if (res)
            {
                Print("TRADE CLOSE SUCCESS - Position ", Ticket, " closed at price ", CurrentPrice);
                NotifyStopLossUpdate(Ticket, Instrument);
                if ((DisplayLines) && (Instrument == Symbol())) RemoveLines(Ticket);
                break;
            }
            else // If not, print the error and continue:
            {
                int Error = GetLastError();
                string ErrorText = GetLastErrorText(Error);
                Print("ERROR - CLOSE FAILED - error closing position ", Ticket, " return error: ", Error, " - ", ErrorText);
            }
        }
    }
    else // Async mode.
    {
        Trade.PositionClose(Ticket);
        if ((DisplayLines) && (Instrument == Symbol())) RemoveLines(Ticket);
    }
}

void NotifyStopLossUpdate(ulong Ticket, string Instrument)
{
    if (!EnableNotify) return;
    if (!SendAlert && !SendApp && !SendEmail) return;
    string EmailSubject = ExpertName + " " + Instrument + " Notification";
    string EmailBody = "\r\n" + AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + "\r\n" + ExpertName + " Notification for " + Instrument + "\r\n";
    EmailBody += "Position " + string(Ticket) + " was closed.";
    string AlertText = "Position " + string(Ticket) + " was closed.";
    string AppText = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + " - " + ExpertName + " - " + Instrument + " - ";
    AppText += "Position " + string(Ticket) + " was closed.";
    if (SendAlert) Alert(AlertText);
    if (SendEmail)
    {
        if (!SendMail(EmailSubject, EmailBody)) Print("Error sending email " + IntegerToString(GetLastError()));
    }
    if (SendApp)
    {
        if (!SendNotification(AppText)) Print("Error sending notification " + IntegerToString(GetLastError()));
    }
}

string PanelBase = ExpertName + "-P-BAS";
string PanelLabel = ExpertName + "-P-LAB";
string PanelEnableDisable = ExpertName + "-P-ENADIS";
void DrawPanel()
{
    int SignX = 1;
    int YAdjustment = 0;
    if ((ChartCorner == CORNER_RIGHT_UPPER) || (ChartCorner == CORNER_RIGHT_LOWER))
    {
        SignX = -1; // Correction for right-side panel position.
    }
    if ((ChartCorner == CORNER_RIGHT_LOWER) || (ChartCorner == CORNER_LEFT_LOWER))
    {
        YAdjustment = (PanelMovY + 2) * 2 + 1 - PanelLabY; // Correction for upper side panel position.
    }
    
    string PanelText = "MQLTA GTPSL";
    string PanelToolTip = "Ghost Take-Profit and Stop-Loss";
    int Rows = 1;
    ObjectCreate(ChartID(), PanelBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_CORNER, ChartCorner);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_XDISTANCE, Xoff);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_YDISTANCE, Yoff + YAdjustment);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_COLOR, clrBlack);

    DrawEdit(PanelLabel,
             Xoff + 2 * SignX,
             Yoff + 2,
             PanelLabX,
             PanelLabY,
             true,
             FontSize,
             PanelToolTip,
             ALIGN_CENTER,
             "Consolas",
             PanelText,
             false,
             clrNavy,
             clrKhaki,
             clrBlack);
    ObjectSetInteger(ChartID(), PanelLabel, OBJPROP_CORNER, ChartCorner);

    string EnableDisabledText = "";
    color EnableDisabledColor = clrNavy;
    color EnableDisabledBack = clrKhaki;
    if (EnableMonitoring)
    {
        EnableDisabledText = "MONITORING ENABLED";
        EnableDisabledColor = clrWhite;
        EnableDisabledBack = clrDarkGreen;
    }
    else
    {
        EnableDisabledText = "MONITORING DISABLED";
        EnableDisabledColor = clrWhite;
        EnableDisabledBack = clrDarkRed;
    }

    DrawEdit(PanelEnableDisable,
             Xoff + 2 * SignX,
             Yoff + (PanelMovY + 1)*Rows + 2,
             PanelLabX,
             PanelLabY,
             true,
             FontSize,
             "Click to Enable or Disable the Monitoring Feature",
             ALIGN_CENTER,
             "Consolas",
             EnableDisabledText,
             false,
             EnableDisabledColor,
             EnableDisabledBack,
             clrBlack);
    ObjectSetInteger(ChartID(), PanelEnableDisable, OBJPROP_CORNER, ChartCorner);
    Rows++;

    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_XSIZE, PanelRecX);
    ObjectSetInteger(ChartID(), PanelBase, OBJPROP_YSIZE, (PanelMovY + 1) * Rows + 3);
    ChartRedraw();
}

void CleanPanel()
{
    ObjectsDeleteAll(0, ExpertName);
    ChartRedraw();
}

void ChangeMonitoringEnabled()
{
    if (EnableMonitoring == false)
    {
        if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
            MessageBox("Algorithmic trading is disabled in the platform's options! Please enable it via Tools->Options->Expert Advisors.", "WARNING", MB_OK);
            return;
        }
        if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
            MessageBox("Algo Trading is disabled in the Position Sizer's settings! Please tick the Allow Algo Trading checkbox on the Common tab.", "WARNING", MB_OK);
            return;
        }
        EnableMonitoring = true;
    }
    else EnableMonitoring = false;
    DrawPanel();
}

void DrawLine(ENUM_LINE_TP_SL type, ulong ticket, double price)
{
    color col;
    string text;
    string obj_name = ExpertName + IntegerToString(ticket);
    if (type == LINE_SL)
    {
        obj_name += "SL";
        col = SLColor;
        text = "Ghost SL for #";
    }
    else
    {
        obj_name += "TP";
        col = TPColor;
        text = "Ghost TP for #";
    }
    if (ObjectFind(ChartID(), obj_name) < 0)
    {
        ObjectCreate(ChartID(), obj_name, OBJ_HLINE, 0, TimeCurrent(), price);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, col);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_BACK, true);
        ObjectSetString(ChartID(), obj_name, OBJPROP_TOOLTIP, DoubleToString(price, _Digits)); // Store BE price in the tooltip.
    }
    else ObjectSetDouble(ChartID(), obj_name, OBJPROP_PRICE, price);

    obj_name += "L"; // Label
    if (ObjectFind(ChartID(), obj_name) < 0)
    {
        ObjectCreate(ChartID(), obj_name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_COLOR, col);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_BACK, false);
        ObjectSetString(ChartID(), obj_name, OBJPROP_TOOLTIP, "");
        ObjectSetString(ChartID(), obj_name, OBJPROP_FONT, LabelFont);
        ObjectSetInteger(ChartID(), obj_name, OBJPROP_FONTSIZE, LabelSize);
        text += IntegerToString(ticket);
        ObjectSetString(ChartID(), obj_name, OBJPROP_TEXT, text);
    }    
    DrawLineLabel(obj_name, text, price);
}

// Draws a line label with a given text.                     |
void DrawLineLabel(const string label, const string text, const double price)
{
    // Data not loaded yet.
    if (Bars(Symbol(), Period()) <= 0) return;

    int x, y;
    //long real_x;
    uint w, h;

    // Needed only for y.
    ChartTimePriceToXY(0, 0, iTime(Symbol(), Period(), 0), price, x, y);
    // Get the width of the text based on font and its size. Negative because OS-dependent, *10 because set in 1/10 of pt.
    ObjectSetInteger(0, label, OBJPROP_XDISTANCE, 2); // 2px from the chart's left side.
    // Get the height of the text based on font and its size. Negative because OS-dependent, *10 because set in 1/10 of pt.
    TextSetFont(LabelFont, LabelSize * -10);
    TextGetSize(text, w, h);
    y -= int(h + 1);
    ObjectSetInteger(0, label, OBJPROP_YDISTANCE, y);
}

// Repositions all labels when chart is scrolled/rescaled.
void RedrawLabels()
{
    int total = ObjectsTotal(ChartID(), -1, OBJ_HLINE);
    // Process all bars on the current screen.
    for (int i = 0; i < total; i++)
    {
        string obj_name = ObjectName(ChartID(), i, -1, OBJ_HLINE);
        if (StringFind(obj_name, ExpertName) < 0) continue;
        double price = ObjectGetDouble(ChartID(), obj_name, OBJPROP_PRICE);
        obj_name += "L";
        string text = ObjectGetString(ChartID(), obj_name, OBJPROP_TEXT);
        DrawLineLabel(obj_name, text, price);
    }
}

void RemoveLines(ulong ticket)
{
    ObjectsDeleteAll(ChartID(), ExpertName + IntegerToString(ticket));
    ChartRedraw();
}

// Check if any line should be deleted (if a position was closed not via this EA).
void CheckLines()
{
    // Process all bars on the current screen.
    for (int i = ObjectsTotal(ChartID(), -1, OBJ_HLINE) - 1; i >= 0; i--)
    {
        string obj_name = ObjectName(ChartID(), i, -1, OBJ_HLINE);
        if (StringFind(obj_name, ExpertName) < 0) continue;
        string text = StringSubstr(obj_name, StringLen(ExpertName));
        int pos = StringFind(text, "SL");
        if (pos < 0) pos = StringFind(text, "TP");
        if (pos < 0) continue; // A weirdly named object?
        text = StringSubstr(text, 0, pos);
        ulong ticket = (ulong)StringToInteger(text);
        bool result = PositionSelectByTicket(ticket);
        if (!result) RemoveLines(ticket); // No position.
    }
    ChartRedraw();
}
//+------------------------------------------------------------------+