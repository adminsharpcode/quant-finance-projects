//+------------------------------------------------------------------+
//|   GOLDEN – NEUTRAL – DEEP LEVELS – FIXED COLORS                 |
//|   Desenvolvido por Trader Augusto                               |
//|   https://t.me/TraderAugusto1000                                |
//+------------------------------------------------------------------+
#property copyright   "Trader Augusto"
#property link        "https://t.me/TraderAugusto1000"
#property description "Indicador criado por Trader Augusto – Topo de Ouro, Resistências, Equilíbrio, Suportes e Fundo Extremo."

#property indicator_chart_window
#property strict

// ========================= SISTEMA DE LICENÇA =========================

// Ativar / desativar expiração
bool use_demo = true;

// Data final da licença
datetime expir_date = D'13.12.2025';

// Mensagem exibida quando expirar
string expir_msg = "Licença expirada. Entre em contato com Trader Augusto.";

// Ativar / desativar restrição por número de conta
bool use_acc_number = false;

// Lista de contas permitidas
int acc_number[] = { 1109442274, 78164683, 1119436 };

// ====================== INPUTS ============================
input double TopoDeOuro         = 0.90;
input double ResIntermediaria   = 0.66;
input double Equilibrio         = 0.50;
input double SupIntermediario   = 0.33;
input double FundoExtremo       = 0.10;

// Cores FIXAS
input color Color_TopoDeOuro       = clrGold;
input color Color_Resistencia      = clrRed;
input color Color_Equilibrio       = clrWhite;

// *** ALTERADO: SUPORTE INTERMEDIÁRIO = AZUL CLARO
input color Color_Suporte          = clrDeepSkyBlue;

// *** ALTERADO: FUNDO EXTREMO = AZUL ESCURO
input color Color_FundoExtremo     = clrNavy;

// Canais laterais
input color CanalSupColor = C'160,160,160';
input color CanalInfColor = C'160,160,160';

// Labels
input bool  ShowLabels      = true;
input int   LabelFontSize   = 13;
input int   LabelRightShift = 20;

// Linhas
input int LineWidth = 2;
input int LineStyle = STYLE_SOLID;

// ===================== RELÓGIO E CONTADOR ======================
input bool ShowClock       = true;
input bool ShowCandleTimer = true;

enum ClockPosition
{
   CP_LEFT  = 0,
   CP_CENTER = 1,
   CP_RIGHT = 2
};

input ClockPosition Clock_Pos = CP_CENTER;

input color ClockColor     = clrWhite;
input color TimerColor     = clrLime;
input int   ClockFontSize  = 16;
input int   TimerFontSize  = 14;

input int Clock_OffsetX = 0;
input int Clock_OffsetY = 15;

string CLOCK_NAME = "LVL_CLOCK";
string TIMER_NAME = "LVL_TIMER";

// =================== SISTEMA DE SAÚDE DO MERCADO ====================
input bool ShowMarketHealth = true;

string MH_NameStatus   = "MH_STATUS";
string MH_NameScore    = "MH_SCORE";

double MH_Score = 0;
string MH_Status = "";
color  MH_Color = clrBlue;

// ===================== FUNÇÃO DE VERIFICAÇÃO DE LICENÇA =====================
bool CheckLicense()
{
   // ===== CONTROLE DE DATA =====
   if(use_demo)
   {
      if(TimeCurrent() > expir_date)
      {
         Alert(expir_msg);
         return(false);
      }
   }

   // ===== CONTROLE DE CONTA =====
   if(use_acc_number)
   {
      bool autorizado = false;

      for(int i=0; i<ArraySize(acc_number); i++)
      {
         if(AccountNumber() == acc_number[i])
         {
            autorizado = true;
            break;
         }
      }

      if(!autorizado)
      {
         Alert("Conta não autorizada.");
         return(false);
      }
   }

   return(true);
}

// Função para criar ou atualizar um texto na tela
void DrawInfo(string name, string txt, int x, int y, color c)
{
   if(ObjectFind(0,name) == -1)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

   ObjectSetInteger(0,name,OBJPROP_CORNER,0);  // canto superior esquerdo
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,12);
   ObjectSetString (0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

// ===========================================================
string ID(string s){ return("LVL_"+s); }

double PriceLevel(double pct)
{
   double h = WindowPriceMax();
   double l = WindowPriceMin();
   return l + (h - l) * pct;
}

// ----------------------- LINHA ------------------------
void DrawLine(string name, double price, color c)
{
   if(ObjectFind(0,name)==-1)
      ObjectCreate(0,name,OBJ_HLINE,0,0,price);

   ObjectSetDouble(0,name,OBJPROP_PRICE1,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,LineWidth);
   ObjectSetInteger(0,name,OBJPROP_STYLE,LineStyle);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

// ----------------------- LABEL ------------------------
void DrawLabel(string name, double price, string txt, color c)
{
   if(!ShowLabels){ ObjectDelete(0,name); return; }

   int chartW = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int x = chartW - LabelRightShift;
   int y;

   if(!ChartTimePriceToXY(0,0,Time[0],price,x,y)) return;

   if(ObjectFind(0,name)==-1)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

   ObjectSetInteger(0,name,OBJPROP_CORNER,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y - 8);

   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,LabelFontSize);
   ObjectSetString (0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

// ----------- Hora de São Paulo (GMT-3) -----------
datetime SaoPauloTime()
{
   return( TimeGMT() - 3*3600 );
}

// ----------- Desenha texto (relógio) -----------
void DrawClock(string name, string text, color c, int fontsize)
{
   if(ObjectFind(0,name) == -1)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

   int chartW = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int x = Clock_OffsetX;

   if(Clock_Pos == CP_LEFT)   x = 20 + Clock_OffsetX;
   if(Clock_Pos == CP_CENTER) x = chartW/2 + Clock_OffsetX;
   if(Clock_Pos == CP_RIGHT)  x = chartW - 120 + Clock_OffsetX;

   ObjectSetInteger(0,name,OBJPROP_CORNER,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,Clock_OffsetY);

   ObjectSetString (0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString (0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

// ----------- Desenha contador da vela -----------
void DrawTimer(string name, int seconds, color c, int fontsize)
{
   if(ObjectFind(0,name) == -1)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

   // texto
   string txt = IntegerToString(seconds) + "s";

   // pega coordenadas da vela atual
   int x,y;
   if(!ChartTimePriceToXY(0,0,Time[0],Close[0],x,y))
      return;

   // deslocamento para frente da vela
   x += 35;   // move para direita (ALINHADO À SUA SETA NA IMAGEM)
   y -= 10;   // leve ajuste vertical

   ObjectSetInteger(0,name,OBJPROP_CORNER,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString (0,name,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

// =================== FUNÇÃO DE CÁLCULO DA SAÚDE DO MERCADO ====================
void CalcMarketHealth(const double &high[], const double &low[], const double &close[])
{
   MH_Score = 0;

   double corpo = MathAbs(close[1] - close[2]);
   double range = high[1] - low[1];
   double wickUp   = high[1] - MathMax(close[1], close[2]);
   double wickDown = MathMin(close[1], close[2]) - low[1];

   // 1 — Pavios exagerados → manipulação
   if(wickUp > corpo*2 || wickDown > corpo*2)
      MH_Score -= 3;

   // 2 — Corpo pequeno demais → perigo/manipulação
   if(corpo < range * 0.15)
      MH_Score -= 2;

   // 3 — Velas diretas e limpas → estabilidade
   if(corpo > range * 0.50)
      MH_Score += 3;

   // 4 — Range muito grande → perigo
   if(range > (high[2] - low[2]) * 1.7)
      MH_Score -= 2;

   // 5 — Range moderado → estabilidade
   if(range < (high[2] - low[2]) * 1.2)
      MH_Score += 2;

   // Definição do status
   if(MH_Score >= 4)  { MH_Status = "ESTÁVEL";      MH_Color = clrDeepSkyBlue; }
   else if(MH_Score >= 0){ MH_Status = "PERIGOSO";  MH_Color = clrYellow; }
   else               { MH_Status = "MANIPULATIVO"; MH_Color = clrRed; }
}

// ===================== BLOQUEIO NO CARREGAMENTO =====================
int OnInit()
{
   if(!CheckLicense())
      return(INIT_FAILED);

   return(INIT_SUCCEEDED);
}

// ===========================================================
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   // ==== BLOQUEIO DE SEGURANÇA ====
   if(!CheckLicense())
      return(0);

   // Convertendo percentuais para preço
   double pTopo   = PriceLevel(TopoDeOuro);
   double pRes    = PriceLevel(ResIntermediaria);
   double pEq     = PriceLevel(Equilibrio);
   double pSup    = PriceLevel(SupIntermediario);
   double pFundo  = PriceLevel(FundoExtremo);

   double pCanalSup = PriceLevel(TopoDeOuro + 0.03);
   double pCanalInf = PriceLevel(FundoExtremo - 0.03);

   // ==================== LINHAS ====================
   DrawLine(ID("CanalSup"), pCanalSup, CanalSupColor);
   DrawLine(ID("CanalInf"), pCanalInf, CanalInfColor);

   DrawLine(ID("Topo"),   pTopo,  Color_TopoDeOuro);
   DrawLine(ID("Res"),    pRes,   Color_Resistencia);
   DrawLine(ID("Eq"),     pEq,    Color_Equilibrio);
   DrawLine(ID("Sup"),    pSup,   Color_Suporte);        // azul claro
   DrawLine(ID("Fundo"),  pFundo, Color_FundoExtremo);    // azul escuro

   // ==================== LABELS ====================
   DrawLabel(ID("TXT_Topo"),  pTopo,   "Topo de Ouro", Color_TopoDeOuro);
   DrawLabel(ID("TXT_Res"),   pRes,    "Resistência Intermediária", Color_Resistencia);
   DrawLabel(ID("TXT_Eq"),    pEq,     "Equilíbrio", Color_Equilibrio);
   DrawLabel(ID("TXT_Sup"),   pSup,    "Suporte Intermediário", Color_Suporte);
   DrawLabel(ID("TXT_Fundo"), pFundo,  "Fundo Extremo", Color_FundoExtremo);

   // ==================== SISTEMA DE SAÚDE DO MERCADO ====================
   if(ShowMarketHealth)
   {
      CalcMarketHealth(high, low, close);

      DrawInfo(MH_NameStatus, 
               "Mercado: " + MH_Status, 
               10, 20, MH_Color);

      DrawInfo(MH_NameScore, 
               "Score: " + DoubleToString(MH_Score,1) + " / 10", 
               10, 40, clrWhite);
   }
   else
   {
      ObjectDelete(0, MH_NameStatus);
      ObjectDelete(0, MH_NameScore);
   }

   // ===================== RELÓGIO =====================
   if(ShowClock)
   {
      datetime sp = SaoPauloTime();
      string horaTxt = TimeToString(sp, TIME_SECONDS);
      DrawClock(CLOCK_NAME, horaTxt, ClockColor, ClockFontSize);
   }
   else
   {
      ObjectDelete(0, CLOCK_NAME);
   }

   // ===================== CONTADOR DA VELA =====================
   if(ShowCandleTimer)
   {
      int periodSec = Period() * 60;
      int elapsed   = TimeCurrent() - Time[0];
      int remain    = periodSec - elapsed;

      if(remain < 0) remain = 0;

      DrawTimer(TIMER_NAME, remain, TimerColor, TimerFontSize);
   }
   else
   {
      ObjectDelete(0, TIMER_NAME);
   }

   return(rates_total);
}

// ===========================================================
void OnDeinit(const int reason)
{
   int total = ObjectsTotal(0,-1,-1);
   for(int i=total-1; i>=0; i--)
   {
      string n = ObjectName(0,i);
      if(StringFind(n,"LVL_") == 0)
         ObjectDelete(0,n);
   }
   
   ObjectDelete(0, MH_NameStatus);
   ObjectDelete(0, MH_NameScore);
   ObjectDelete(0, CLOCK_NAME);
   ObjectDelete(0, TIMER_NAME);
}