//+------------------------------------------------------------------+
//|     DELTA FLOW PREMIUM (MQL4)                          |
//| Painel: Delta, Delta Volume, Volume, MaxDelta, MinDelta, Ratio   |
//| POC + Sniper (setas no gráfico principal).                       |
//| *** Sem OBV, sem Cumulative, sem POCX, sem Price Action ***      |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_buffers 30
#property indicator_plots   0
#property indicator_minimum 0
#property indicator_maximum 100

#property version     ""
#property copyright   "Trader Augusto"
#property link        "https://t.me/TraderAugusto1000"
#property description "DELTA FLOW PREMIUM. O INDICADOR PRODUZIDO PELO TRADER AUGUSTO. SE VOCÊ ADQUIRIU ESSE INDICADOR, ENTÃO VOCÊ TEM TAMBÉM O INDICADOR AUXILIAR QUE REALIZA AS ANÁLISES DO PAINEL E EXIBE OPORTUNIDADE DE NEGOCIAR. SE CASO VOCÊ ADQUIRIU O INDICADOR ISOLADO, ENTRE EM CONTATO COM O TRADER AUGUSTO ATRAVÉS DO LINK ACIMA E FALA COM ELE DIRETAMENTE."

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


// ===================== BUFFERS PARA INTEGRAÇÃO EXTERNA =====================
double BufDelta[];      // buffer 0 — Delta bruto
double BufDVolPct[];    // buffer 1 — Delta Volume %
double BufVolume[];     // buffer 2 — Volume
double BufRatio[];      // buffer 3 — Ratio
double BufMaxDelta[];   // buffer 4 — Max Delta
double BufMinDelta[];   // buffer 5 — Min Delta

// ===================== BUFFERS PARA PADRÕES INSTITUCIONAIS =====================
// REMOVIDOS: Todos os buffers de padrões institucionais

// ===================== ENTRADAS DO PAINEL =====================
input bool   OnlyClosedBars      = false;
input bool   UpdateOnTick        = true;
input int    BarsToDrawMax       = 330;

input int    BandHeightPx        = 20;
input int    BandGapPx           = 3;
input int    TopPaddingPx        = 3;
input int    LeftPaddingPx       = 6;

input int    HeaderRightOffsetPx = 10;
input color  HeaderColor         = DarkGray;
input int    HeaderFontSize      = 10;

input string FontName            = "Arial";
input int    FontSize            = 9;
input int    MinTextWidthPx      = 24;
input color  NumColorDelta       = White;
input color  NumColorDVol        = White;
input color  NumColorVolume      = White;
input color  NumColorRatio       = White;

// Cores base
input color  CellBorderColor     = DarkSlateGray;
input color  DeltaPosBG          = C'0,159,0';
input color  DeltaNegBG          = C'210,0,0';
input color  DVolPosBG           = C'0,164,0';
input color  DVolNegBG           = C'196,0,0';

input color  VolumeBaseBG        = C'181,191,200';
input color  VolumeHeat1BG       = C'118,138,154';
input color  VolumeHeat2BG       = C'84,99,114';
input color  VolumeHeat3BG       = C'47,55,64';
input int    VolumeBoldSizeBump  = 0;

input int    VolumeMAPeriod      = 20;
input double VolumeAvgFactor     = 1.0;
input double VolumeHighFactor    = 1.5;
input double VolumeUltraFactor   = 2.0;

// RATIO (painel)
input color  RatioPosBGWeak      = C'0,140,0';
input color  RatioPosBGStrong    = C'0,200,0';
input color  RatioNegBGWeak      = C'202,0,0';
input color  RatioNegBGStrong    = C'255,40,40';
input color  RatioNeutralBG      = C'110,110,110';
input double RatioNeutralBand    = 0.05;
input double RatioStrongBand     = 0.30;

// ================= RATIO – ZONAS S/R NO GRÁFICO =================
input bool   RatioZones_Enable       = true;

// Zonas COMPRADORAS (Ratio > 1, lado BUY vencedor)

// Zona Amarela (ratio 20–45)
input double RatioYellowMin          = 20.0;
input double RatioYellowMax          = 45.0;
input color  RatioYellowHLColor      = Yellow;   // High/Low
input color  RatioYellowMidColor     = Yellow;   // 50%

// Zona Cinza (ratio 35–45 – institucional forte)
input double RatioGrayMin            = 35.0;
input double RatioGrayMax            = 45.0;
input color  RatioGrayHLColor        = Silver;   // High/Low
input color  RatioGrayMidColor       = Silver;   // 50%

// Zonas VENDEDORAS (Ratio < 1, lado SELL vencedor)
input double RatioSellLightMin       = 0.80;
input double RatioSellLightMax       = 0.95;
input double RatioSellDarkMin        = 0.60;
input double RatioSellDarkMax        = 0.80;

input color  RatioSellLightHLColor   = C'255,120,120';
input color  RatioSellLightMidColor  = C'255,120,120';
input color  RatioSellDarkHLColor    = C'200,0,0';
input color  RatioSellDarkMidColor   = C'200,0,0';

// Estilo das linhas
input int    RatioHLWidth            = 1;
input int    RatioHLStyle            = STYLE_SOLID;   // High/Low
input int    RatioMidWidth           = 1;
input int    RatioMidStyle           = STYLE_DASH;    // 50%

// Rompimento e limite
input int    RatioBreaksToDelete     = 2;      // nº de rompimentos CONTRÁRIOS para apagar
input double RatioBreakTolerancePts  = 0.0;    // tolerância em pontos (0 = sem folga)

// ================= RATIO AGRESSIVO (SINAIS PRINCIPAIS) =================
input double RatioAgg_BuyMin  = 8.0;   // Compra se ratio >= 8.0
input double RatioAgg_SellMax = 0.8;   // Venda se ratio <= 0.8

input color  RatioAggColorBuy  = Lime;    // Cor da seta de compra
input color  RatioAggColorSell = Red;     // Cor da seta de venda
input int    RatioAggArrowSize = 2;       // Tamanho da seta
input int    RatioAggArrowCodeBuy  = 233; // Código Wingdings compra
input int    RatioAggArrowCodeSell = 234; // Código Wingdings venda
input double RatioAggOffsetPts = 10.0;    // Distância da seta

// ===================== RATIO VENDA EXTREMA (3 NÍVEIS) =====================
input bool   UseRatioExtremeLevels   = true;

// Nível 1 – Venda Forte (≤ 0.80)
input double RatioSell_Level1        = 0.80;
input color  RatioSell_Color1        = C'255,120,120';  // vermelho claro
input int    RatioSell_Arrow1        = 234;
input int    RatioSell_Size1         = 1;

// Nível 2 – Venda Extrema Real (≤ 0.60)
input double RatioSell_Level2        = 0.60;
input color  RatioSell_Color2        = C'255,60,60';    // vermelho forte
input int    RatioSell_Arrow2        = 234;
input int    RatioSell_Size2         = 2;

// Nível 3 – Capitulação (≤ 0.40)
input double RatioSell_Level3        = 0.40;
input color  RatioSell_Color3        = C'255,0,0';      // vermelho máximo
input int    RatioSell_Arrow3        = 234;
input int    RatioSell_Size3         = 3;

// Distância das setas
input double RatioSellOffsetPts      = 10.0;

// ===================== RATIO COMPRA EXTREMA (3 NÍVEIS) =====================
input bool   UseRatioExtremeBuyLevels = true;

// Nível 1 – Compra Forte (≥ 1.20)  (equivalente ao inverso da venda forte)
input double RatioBuy_Level1          = 1.20;
input color  RatioBuy_Color1          = C'60,255,60';    // verde claro
input int    RatioBuy_Arrow1          = 233;
input int    RatioBuy_Size1           = 1;

// Nível 2 – Compra Extrema Real (≥ 1.60)
input double RatioBuy_Level2          = 1.60;
input color  RatioBuy_Color2          = C'0,200,0';      // verde forte
input int    RatioBuy_Arrow2          = 233;
input int    RatioBuy_Size2           = 2;

// Nível 3 – Capitulação de Compra (≥ 2.00)
input double RatioBuy_Level3          = 2.00;
input color  RatioBuy_Color3          = C'0,255,0';      // verde máximo
input int    RatioBuy_Arrow3          = 233;
input int    RatioBuy_Size3           = 3;

// Distância das setas
input double RatioBuyOffsetPts        = 10.0;

// TOGGLES
input bool   ShowDelta           = true;
input bool   ShowDeltaVolume     = true;
input bool   ShowVolume          = true;

// Ocultado do painel — funcionamento interno mantém ativo
bool ShowRatio = false;
bool Max_Delta = false;
bool Min_Delta = false;

input color  MaxDeltaFillBuy     = C'0,180,0';
input color  MaxDeltaFillSell    = C'200,0,0';
input color  MinDeltaFillBuy     = C'0,180,0';
input color  MinDeltaFillSell    = C'200,0,0';

// TIME AXIS
input bool   ShowTimeAxis        = true;
input int    TimeAxisFontSize    = 8;
input int    TimeAxisEveryN      = 4;

// CONTROLE
input bool   FreezeClosedBars    = true;

// NÚMEROS NAS VELAS (gráfico principal)
input bool   ShowAggOnChart      = false;
input int    AggOnChartMaxBars   = 150;
input int    AggOnChartFontSize  = 8;
input color  AggOnChartPosColor  = C'0,200,0';
input color  AggOnChartNegColor  = C'220,0,0';
input color  AggOnChartZeroColor = Silver;

// =================== POC (principal) ===================
input bool   POC_Show                = true;
input int    POC_Mode                = 4;   // 0=HL2 1=OC2 2=Typical 3=Close 4=DeltaSkew
input int    POC_Shape               = 2;   // 0=Dot 1=Rect 2=Line
input bool   POC_ColorByWinnerSide   = true;
input color  POC_ColorNeutral        = Silver;
input color  POC_ColorBuy            = C'0,200,0';
input color  POC_ColorSell           = C'220,0,0';
input int    POC_DotCode             = 159;
input int    POC_DotSize             = 2;
input double POC_RectHalfPts         = 6.0;
input int    POC_LineWidth           = 2;   // linha
// NOVOS – POC CONFIGURÁVEL
input int    POC_RectBorderWidth     = 2;             // borda do retângulo
input int    POC_RectStyle           = STYLE_SOLID;   // estilo da borda
input double POC_TimeWidthFactor     = 1.5;
input int    POC_MaxBars             = 300;
input bool   POC_OnlyClosedBars      = true;
input bool   POC_ExtendRight         = true; // linha se estende à direita

// =============== SNIPER DINAMICA GOLD (80/90) ===============
input bool   SniperEnable            = true;
input double SniperDominanceMin      = 0.80;   // mínimo 80%
input int    SniperMinDeltaAbs       = 120;
input double SniperMinDVolPct        = 30.0;   // DeltaVolume% min
input bool   SniperRequireDeltaSign  = true;
input bool   SniperUseRatio          = true;
input double SniperRatioEdge         = 0.10;   // 1.10 / 0.90

// Cores por nível
input color  SniperColor80Buy        = C'0,200,0';     // 80% BUY – verde
input color  SniperColor80Sell       = C'220,0,0';     // 80% SELL – vermelho
input color  SniperColor90           = C'255,215,0';   // 90% – OURO

// Tamanhos por nível
input int    SniperArrowSize80       = 1;  // 80%
input int    SniperArrowSize90       = 2;  // 90%

// Config geral das setas
input int    SniperArrowCodeBuy      = 233;  // Wingdings
input int    SniperArrowCodeSell     = 234;
input color  SniperColorTextBuy      = Lime;
input color  SniperColorTextSell     = Red;
input bool   SniperShowTextValues    = false;
input int    SniperProximityMode     = 0;   // 0=perto 1=longe
input double SniperOffsetNearPts     = 8.0;
input double SniperOffsetFarPts      = 20.0;
input double SniperHalfBarRatio      = 0.45; // pré-sinal ~45% da vela
input bool   SniperHalfBarEnable     = true;
input bool   SniperCancelOnOppVol    = true;
input double SniperCancelVolFactor   = 1.40;
input double SniperCancelOppDVolAbs  = 6.0;
input string SniperSoundFile         = "alert.wav";
input bool   SniperPlaySoundOnSignal = true;
input double SniperArrowOffsetPts    = 0.0;

// ==================== PADRÕES INSTITUCIONAIS ====================
// REMOVIDOS: Todos os inputs de ativação de padrões

// Configurações gerais
input int   ArrowCodeBuy   = 233;
input int   ArrowCodeSell  = 234;
input int   ArrowSize      = 2;
input int   ArrowDistance  = 10;

// =================== ESTADO ===================
int      gWin=0;
datetime gLastBarTime=0;
string   gShortName="DELTA FLOW 5.0 – SNIPER GOLD (Painel+POC+RatioSR)";

struct BarStats{ int delta; int volume; double dvol; bool frozen; };
BarStats gStats[];

int      AggDelta[];
int      gLiveDelta0_prev=0, gLiveDelta0_curr=0;

int      BarMaxDelta[];
int      BarMinDelta[];

datetime last_sniper_sound_time = 0;

// ------------------- HELPERS -------------------
string ID(const string b,int i){ return b+"_"+IntegerToString(i); }
string IDC(const string b,int i){ return b+"#"+IntegerToString(i); }
string IDT(const string b, datetime t){ return b+"@"+IntegerToString((long)t); }

string TFtoStr(int tf){
   switch(tf){
      case PERIOD_M1:  return "M1";  case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15"; case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";  case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";  case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
   }
   return IntegerToString(tf);
}
int PeriodSecondsEx(){
   switch(Period()){
      case PERIOD_M1:  return 60;
      case PERIOD_M5:  return 300;
      case PERIOD_M15: return 900;
      case PERIOD_M30: return 1800;
      case PERIOD_H1:  return 3600;
      case PERIOD_H4:  return 14400;
      case PERIOD_D1:  return 86400;
      case PERIOD_W1:  return 604800;
      case PERIOD_MN1: return 2592000;
   }
   return 3600;
}

double VolSMA(int sh){
   int n=0; double s=0.0;
   for(int k=0;k<VolumeMAPeriod;k++){
      int i=sh+k; if(i>=Bars) break;
      s+=(double)Volume[i]; n++;
   }
   return (n>0? s/(double)n : 0.0);
}
bool VolAbove(int sh,int v,double f){
   double a=VolSMA(sh);
   return (a>0 && (double)v>=a*f);
}

int EstimateDelta(int i){
   double r=High[i]-Low[i]; if(r<=Point*0.1) return 0;
   double frac=(Close[i]-Open[i])/r;
   return (int)MathRound((double)Volume[i]*frac);
}
int GetDeltaBar(int i){
   int reg=(i<ArraySize(AggDelta)?AggDelta[i]:INT_MIN);
   if(i==0) return EstimateDelta(0);
   if(reg!=INT_MIN) return reg;
   if(gStats[i].frozen) return gStats[i].delta;
   return EstimateDelta(i);
}

double RatioForBar(const int i) {
   int vVol   = (int)Volume[i];
   int vDelta = GetDeltaBar(i);
   double buy = MathMax(0.0, ((double)vVol + (double)vDelta)/2.0);
   double sel = MathMax(0.0, ((double)vVol - (double)vDelta)/2.0);
   return (sel>0.0 ? buy/sel : 0.0);
}
double AbsDVolPct(const int i) {
   int vVol   = (int)Volume[i];
   int vDelta = GetDeltaBar(i);
   if(vVol<=0) return 0.0;
   return 100.0 * MathAbs((double)vDelta) / (double)vVol;
}

int GetRatioSellLevel(double ratio)
{
   if(ratio <= RatioSell_Level3) return 3; // Capitulação
   if(ratio <= RatioSell_Level2) return 2; // Extrema Real
   if(ratio <= RatioSell_Level1) return 1; // Forte
   return 0; // Sem venda extrema
}

int GetRatioBuyLevel(double ratio)
{
   if(ratio >= RatioBuy_Level3) return 3; // Capitulação de compra
   if(ratio >= RatioBuy_Level2) return 2; // Compra extrema real
   if(ratio >= RatioBuy_Level1) return 1; // Compra forte
   return 0; // Nada
}

int WinnerSideForBar(const int i)
{
   int d  = GetDeltaBar(i);
   int mx = (i<ArraySize(BarMaxDelta) && BarMaxDelta[i]!=INT_MIN) ? BarMaxDelta[i] : d;
   int mn = (i<ArraySize(BarMinDelta) && BarMinDelta[i]!=INT_MAX) ? BarMinDelta[i] : d;

   bool hasMx = (mx!=INT_MIN);
   bool hasMn = (mn!=INT_MAX);

   if(!hasMx && !hasMn){
      if(d>0) return +1;
      if(d<0) return -1;
      return 0;
   }
   if(hasMx && !hasMn) return +1;
   if(hasMn && !hasMx) return -1;

   if(MathAbs(mx) > MathAbs(mn)) return +1;
   if(MathAbs(mn) > MathAbs(mx)) return -1;

   if(d>0)  return +1;
   if(d<0)  return -1;
   return 0;
}

// --------- FUNÇÃO DE SEGURANÇA ---------
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
         Alert("Conta não autorizada para usar este indicador.");
         return(false);
      }
   }

   return(true);
}

// --------- Objetos (painel) ---------
void DrawRectPx(const string name,int x,int y,int w,int h,color fill,color border){
   if(ObjectFind(0,name)==-1)
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL, gWin, 0, 0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill);
   ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
void DrawTextPx(const string name,int x,int y,const string txt,int fsize,color c){
   if(ObjectFind(0,name)==-1)
      ObjectCreate(0,name,OBJ_LABEL, gWin, 0, 0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fsize);
   ObjectSetString (0,name,OBJPROP_FONT,FontName);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

// ======== Largura correta da coluna (inclui vela 0) ========
bool GetBarBoxPx(const int i,int &xLeft,int &w){
   if(i<0 || i>=Bars) return false;

   int xi,xip1,xim1,y;
   if(!ChartTimePriceToXY(0,gWin,Time[i],50.0,xi,y)) return false;

   bool has_ip1 = (i+1<Bars) && ChartTimePriceToXY(0,gWin,Time[i+1],50.0,xip1,y);
   bool has_im1 = (i-1>=0)   && ChartTimePriceToXY(0,gWin,Time[i-1],50.0,xim1,y);

   if(!has_ip1 && has_im1){
      int step = xi - xim1;
      xip1 = xi + step;
      has_ip1 = true;
   }
   if(!has_im1 && has_ip1){
      int step = xi - xip1;
      xim1 = xi + step;
      has_im1 = true;
   }

   if(!has_ip1 || !has_im1){
      int cw = 12;
      xLeft = xi - cw/2;
      w     = cw;
   } else {
      int left  = (xi + xip1)/2;
      int right = (xim1 + xi)/2;
      if(right < left){
         int t=left; left=right; right=t;
      }

      long chartW = 0;
      ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chartW);
      if(chartW > 0){
         left  = MathMax(0, left);
         right = MathMin((int)chartW - 1, right);
      }
      xLeft = left;
      w     = MathMax(2, right - left);
   }
   return true;
}

color VolHeatBG_ByValue(int idx,int vol){
   if(VolAbove(idx,vol,VolumeUltraFactor)) return VolumeHeat3BG;
   if(VolAbove(idx,vol,VolumeHighFactor))  return VolumeHeat2BG;
   if(VolAbove(idx,vol,VolumeAvgFactor))   return VolumeHeat1BG;
   return VolumeBaseBG;
}
void DeleteColumn(int idx){
   ObjectDelete(0,ID("D_BG",idx)); ObjectDelete(0,ID("D_TX",idx));
   ObjectDelete(0,ID("P_BG",idx)); ObjectDelete(0,ID("P_TX",idx));
   ObjectDelete(0,ID("V_BG",idx)); ObjectDelete(0,ID("V_TX",idx));
   ObjectDelete(0,ID("X_BG",idx)); ObjectDelete(0,ID("X_TX",idx));
   ObjectDelete(0,ID("N_BG",idx)); ObjectDelete(0,ID("N_TX",idx));
   ObjectDelete(0,"TM_"+IntegerToString(idx));
}

// --------- CONGELA DADOS DA BARRA (gStats) ----------
void FreezeBar(int i)
{
   if(i < 1 || i >= Bars) return;

   if(!FreezeClosedBars)
   {
      int v  = (int)Volume[i];
      int d  = EstimateDelta(i);

      gStats[i].delta  = d;
      gStats[i].volume = v;
      gStats[i].dvol   = (v > 0 ? 100.0 * (double)d / (double)v : 0.0);
      gStats[i].frozen = false;
   }
   else if(!gStats[i].frozen)
   {
      int v2 = (int)Volume[i];
      int d2 = EstimateDelta(i);

      gStats[i].delta  = d2;
      gStats[i].volume = v2;
      gStats[i].dvol   = (v2 > 0 ? 100.0 * (double)d2 / (double)v2 : 0.0);
      gStats[i].frozen = true;
   }
}

// --------- CARIMBO VENCEDOR ---------
void StampWinner(const int i){
   if(i<1 || i>=Bars) return;

   int mx = (i<ArraySize(BarMaxDelta) && BarMaxDelta[i]!=INT_MIN) ? BarMaxDelta[i] : INT_MIN;
   int mn = (i<ArraySize(BarMinDelta) && BarMinDelta[i]!=INT_MAX) ? BarMinDelta[i] : INT_MAX;
   int d  = (i<ArraySize(AggDelta)    && AggDelta[i]!=INT_MIN)    ? AggDelta[i]    : gStats[i].delta;

   if(d==0){
      if(mx==INT_MIN && mn==INT_MAX) return;
      if(mx!=INT_MIN && mn!=INT_MAX){ d = (MathAbs(mx) >= MathAbs(mn)) ? 1 : -1; }
      else if(mx!=INT_MIN) d = 1;
      else if(mn!=INT_MAX) d = -1;
   }

   datetime t = Time[i];
   ObjectDelete(0, IDT("WINB", t));
   ObjectDelete(0, IDT("WINS", t));

   if(d > 0){
      if(mx==INT_MIN) return;
      string id = IDT("WINB", t);
      double y  = Low[i] - 4*Point;
      if(ObjectFind(0,id)==-1) ObjectCreate(0,id,OBJ_TEXT,0,t,y);
      ObjectMove(0,id,0,t,y);
      ObjectSetText(id, IntegerToString(mx), 8, FontName, Lime);
      ObjectSet(id, OBJPROP_BACK, false);
      ObjectSet(id, OBJPROP_SELECTABLE, false);
   } else {
      if(mn==INT_MAX) return;
      string id = IDT("WINS", t);
      double y  = High[i] + 4*Point;
      if(ObjectFind(0,id)==-1) ObjectCreate(0,id,OBJ_TEXT,0,t,y);
      ObjectMove(0,id,0,t,y);
      ObjectSetText(id, IntegerToString(mn), 8, FontName, Red);
      ObjectSet(id, OBJPROP_BACK, false);
      ObjectSet(id, OBJPROP_SELECTABLE, false);
   }
}

// ------------------- RATIO (célula) -------------------
void DrawRatioCell(const int i,const int xLeft,const int y,const int w,const int h,
                   const double ratio,const color border,const color numColor,
                   const color posWeak,const color posStrong,
                   const color negWeak,const color negStrong,
                   const color neutralBG,const double neutralBand,const double strongBand,
                   const string fontName,const int fontSize)
{
   const string bg = "R_BG_" + IntegerToString(i);
   const string tx = "R_TX_" + IntegerToString(i);

   double loN = 1.0 - MathAbs(neutralBand);
   double hiN = 1.0 + MathAbs(neutralBand);
   double loS = 1.0 - MathAbs(strongBand);
   double hiS = 1.0 + MathAbs(strongBand);

   color fill;
   if(ratio>=loN && ratio<=hiN)      fill = neutralBG;
   else if(ratio>=hiS)               fill = posStrong;
   else if(ratio<=loS)               fill = negStrong;
   else if(ratio>1.0)                fill = posWeak;
   else                              fill = negWeak;

   if(ObjectFind(0, bg)==-1) ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,gWin,0,0);
   ObjectSetInteger(0,bg,OBJPROP_CORNER,0);
   ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,xLeft);
   ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,bg,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,bg,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,fill);
   ObjectSetInteger(0,bg,OBJPROP_COLOR,CellBorderColor);
   ObjectSetInteger(0,bg,OBJPROP_BACK,true);
   ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);

   if(ObjectFind(0, tx)==-1) ObjectCreate(0,tx,OBJ_LABEL,gWin,0,0);
   ObjectSetInteger(0,tx,OBJPROP_CORNER,0);
   ObjectSetInteger(0,tx,OBJPROP_XDISTANCE,xLeft+3);
   ObjectSetInteger(0,tx,OBJPROP_YDISTANCE,y+(h-fontSize)/2);
   ObjectSetString (0,tx,OBJPROP_TEXT, DoubleToString(ratio,1));
   ObjectSetInteger(0,tx,OBJPROP_COLOR,numColor);
   ObjectSetInteger(0,tx,OBJPROP_FONTSIZE,fontSize);
   ObjectSetString (0,tx,OBJPROP_FONT,fontName);
   ObjectSetInteger(0,tx,OBJPROP_BACK,false);
   ObjectSetInteger(0,tx,OBJPROP_SELECTABLE,false);
}

// ------------------- DESENHO DE UMA COLUNA -------------------
void DrawColumn(const int i,const int panelY){
   // Forçar ocultação completa
   Max_Delta = false;
   Min_Delta = false;
   ShowRatio = false;
   
   if(i>=Bars) return;
   int xLeft,w; if(!GetBarBoxPx(i,xLeft,w)) return;
   int y = panelY;

   int vDelta = (i==0) ? EstimateDelta(0)
                       : ((i<ArraySize(AggDelta) && AggDelta[i]!=INT_MIN)? AggDelta[i] : EstimateDelta(i));
   int vVol = (int)Volume[i];
   double vPct = (vVol>0?100.0*(double)vDelta/(double)vVol:0.0);

   int fsz=FontSize; bool showTxt=(w-6>=MinTextWidthPx);
   if(!showTxt && w>=MinTextWidthPx){ showTxt=true; fsz=MathMax(8,FontSize-2); }

   if(ShowDelta){
      DrawRectPx(ID("D_BG",i), xLeft,y,w,BandHeightPx, (vDelta>=0?DeltaPosBG:DeltaNegBG), CellBorderColor);
      if(showTxt) DrawTextPx(ID("D_TX",i), xLeft+3, y+(BandHeightPx-FontSize)/2, IntegerToString(vDelta), fsz, NumColorDelta);
      else ObjectDelete(0,ID("D_TX",i));
      y += BandHeightPx + BandGapPx;
   } else {
      ObjectDelete(0,ID("D_BG",i)); ObjectDelete(0,ID("D_TX",i));
   }

   if(ShowDeltaVolume){
      DrawRectPx(ID("P_BG",i), xLeft,y,w,BandHeightPx, (vPct>=0.0?DVolPosBG:DVolNegBG), CellBorderColor);
      if(showTxt) DrawTextPx(ID("P_TX",i), xLeft+3, y+(BandHeightPx-FontSize)/2, DoubleToString(vPct,1), fsz, NumColorDVol);
      else ObjectDelete(0,ID("P_TX",i));
      y += BandHeightPx + BandGapPx;
   } else {
      ObjectDelete(0,ID("P_BG",i)); ObjectDelete(0,ID("P_TX",i));
   }

   if(ShowVolume){
      color vBG = VolHeatBG_ByValue(i,vVol); int fszV = fsz + VolumeBoldSizeBump;
      DrawRectPx(ID("V_BG",i), xLeft,y,w,BandHeightPx, vBG, CellBorderColor);
      if(showTxt) DrawTextPx(ID("V_TX",i), xLeft+3, y+(BandHeightPx-FontSize)/2, IntegerToString(vVol), fszV, NumColorVolume);
      else ObjectDelete(0,ID("V_TX",i));
      y += BandHeightPx + BandGapPx;
   } else {
      ObjectDelete(0,ID("V_BG",i)); ObjectDelete(0,ID("V_TX",i));
   }

   // Ocultar MaxDelta / MinDelta / Ratio no painel
   ObjectDelete(0,ID("X_BG",i)); ObjectDelete(0,ID("X_TX",i));
   ObjectDelete(0,ID("N_BG",i)); ObjectDelete(0,ID("N_TX",i));
   ObjectDelete(0,ID("R_BG",i)); ObjectDelete(0,ID("R_TX",i));

   // eixo de tempo
   string tmID="TM_"+IntegerToString(i);
   if(ShowTimeAxis && (i%TimeAxisEveryN==0))
      DrawTextPx(tmID, xLeft+2, y+2, TimeToString(Time[i],TIME_MINUTES), TimeAxisFontSize, HeaderColor);
   else ObjectDelete(0,tmID);
}

// ------------------- CABEÇALHOS -------------------
void DrawRightHeaders(){
   int x0,x1,xr,y;
   if(!ChartTimePriceToXY(0,gWin,Time[0],50.0,x0,y)) return;
   if(!ChartTimePriceToXY(0,gWin,Time[1],50.0,x1,y)) x1=x0-12;
   xr = x0 + (x0 - x1)/2;

   int x  = xr + HeaderRightOffsetPx;
   int y0 = TopPaddingPx;
   int row = 0, yoff;

   if(ShowDelta){
      yoff = y0 + (BandHeightPx+BandGapPx)*row + (BandHeightPx-HeaderFontSize)/2;
      DrawTextPx("H_DELTA", x, yoff, "DELTA", HeaderFontSize, HeaderColor); row++;
   } else ObjectDelete(0,"H_DELTA");

   if(ShowDeltaVolume){
      yoff = y0 + (BandHeightPx+BandGapPx)*row + (BandHeightPx-HeaderFontSize)/2;
      DrawTextPx("H_DVOL", x, yoff, "DELTA VOLUME", HeaderFontSize, HeaderColor); row++;
   } else ObjectDelete(0,"H_DVOL");

   if(ShowVolume){
      yoff = y0 + (BandHeightPx+BandGapPx)*row + (BandHeightPx-HeaderFontSize)/2;
      DrawTextPx("H_VOL", x, yoff, "VOLUME", HeaderFontSize, HeaderColor); row++;
   } else ObjectDelete(0,"H_VOL");

   ObjectDelete(0,"H_MAXD");
   ObjectDelete(0,"H_MIND");
   ObjectDelete(0,"H_RATIO");
}

// =================== POC (gráfico principal) ===================
string POC_ID(const string kind, datetime t){ return "POC_"+kind+"@"+IntegerToString((long)t); }

double POC_PriceForBar(const int i){
   if(i<0 || i>=Bars) return Close[i];
   double h=High[i], l=Low[i], o=Open[i], c=Close[i];
   switch(POC_Mode){
      case 0:  return (h+l)/2.0;                      // HL2
      case 1:  return (o+c)/2.0;                      // OC2
      case 2:  return (h+l+c)/3.0;                    // Typical
      case 3:  return c;                              // Close
      case 4:
      default:{
         double base = (h+l)/2.0;
         double rng  = MathMax(Point, h-l);
         int    v    = (int)Volume[i];
         int    d    = GetDeltaBar(i);
         double body = (c-o)/rng;
         double inten= (v>0? MathMin(1.0, MathAbs((double)d)/(double)v) : 0.0);
         double k    = 0.28 * inten;
         return base + body * k * rng;
      }
   }
}
color POC_ColorForBar(const int i){
   if(!POC_ColorByWinnerSide) return POC_ColorNeutral;
   int side = WinnerSideForBar(i);
   if(side>0)  return POC_ColorBuy;
   if(side<0)  return POC_ColorSell;
   return POC_ColorNeutral;
}
void POC_DrawLine(const int i, const double y)
{
   datetime tL, tR;
   if(i==0){ tL = Time[0]; tR = (Bars>1? Time[1] : (Time[0]+PeriodSecondsEx())); }
   else     { tL = Time[i]; tR = Time[i-1]; }

   string id = POC_ID("LINE", Time[i]);
   if(ObjectFind(0,id)==-1){
      ObjectCreate(0,id,OBJ_TREND,0,tL,y,tR,y);
      ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,id,OBJPROP_BACK,false);
   }

   ObjectSet(id,OBJPROP_TIME1,tL);
   ObjectSet(id,OBJPROP_TIME2,tR);
   ObjectSet(id,OBJPROP_PRICE1,y);
   ObjectSet(id,OBJPROP_PRICE2,y);
   ObjectSetInteger(0,id,OBJPROP_COLOR,POC_ColorForBar(i));
   ObjectSetInteger(0,id,OBJPROP_WIDTH,POC_LineWidth);
   ObjectSetInteger(0,id,OBJPROP_RAY_RIGHT, (POC_ExtendRight ? true : false));
   ObjectSetInteger(0,id,OBJPROP_RAY, false);
}
void POC_DrawRect(const int i, const double y){
   datetime tL, tR;
   if(i==0){ tL = Time[0]; tR = (Bars>1? Time[1] : (Time[0]+PeriodSecondsEx())); }
   else     { tL = Time[i]; tR = Time[i-1]; }
   double w = MathMax(0.2, POC_TimeWidthFactor);
   double midT = ( (double)tL + (double)tR )/2.0;
   double half = ( (double)tR - (double)tL ) * w / 2.0;
   datetime L  = (datetime)MathMax((double)tL, midT - half);
   datetime R  = (datetime)MathMin((double)tR, midT + half);

   double y1 = y + POC_RectHalfPts * Point;
   double y2 = y - POC_RectHalfPts * Point;

   string id = POC_ID("RECT", Time[i]);
   if(ObjectFind(0,id)==-1) ObjectCreate(0,id,OBJ_RECTANGLE,0,L,y1,R,y2);
   ObjectSet(id,OBJPROP_TIME1,L);  ObjectSet(id,OBJPROP_TIME2,R);
   ObjectSet(id,OBJPROP_PRICE1,y1);ObjectSet(id,OBJPROP_PRICE2,y2);
   ObjectSetInteger(0,id,OBJPROP_COLOR,POC_ColorForBar(i));
   ObjectSetInteger(0,id,OBJPROP_BACK,false);
   ObjectSetInteger(0,id,OBJPROP_WIDTH,POC_RectBorderWidth);
   ObjectSetInteger(0,id,OBJPROP_STYLE,POC_RectStyle);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
}
void POC_DrawDot(const int i, const double y){
   string id = POC_ID("DOT", Time[i]);
   if(ObjectFind(0,id)==-1) ObjectCreate(0,id,OBJ_ARROW,0,Time[i],y);
   ObjectSetInteger(0,id,OBJPROP_ARROWCODE,POC_DotCode);
   ObjectSetInteger(0,id,OBJPROP_COLOR,POC_ColorForBar(i));
   ObjectSetInteger(0,id,OBJPROP_WIDTH,POC_DotSize);
   ObjectSetInteger(0,id,OBJPROP_BACK,false);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
}
void POC_DeleteForBar(const int i){
   ObjectDelete(0, POC_ID("DOT",  Time[i]));
   ObjectDelete(0, POC_ID("RECT", Time[i]));
   ObjectDelete(0, POC_ID("LINE", Time[i]));
}

// --------- Atualização de POC ----------
void POC_Update(){
   if(!POC_Show){
      int limit=MathMin(POC_MaxBars, Bars-1);
      for(int i=1;i<=limit;i++) POC_DeleteForBar(i);
      if(Bars>0) POC_DeleteForBar(0);
      return;
   }
   int lim=MathMin(POC_MaxBars, Bars-1);
   for(int j=lim+1;j<lim+100 && j<Bars; j++) POC_DeleteForBar(j);

   if(!POC_OnlyClosedBars && Bars>0){
      double py0 = POC_PriceForBar(0);
      if(POC_Shape==0) POC_DrawDot(0,py0);
      else if(POC_Shape==1) POC_DrawRect(0,py0);
      else POC_DrawLine(0,py0);
   } else {
      if(Bars>0) POC_DeleteForBar(0);
   }

   for(int i=1;i<=lim;i++){
      double py = POC_PriceForBar(i);

      if(POC_Shape==0) POC_DrawDot(i,py);
      else if(POC_Shape==1) POC_DrawRect(i,py);
      else POC_DrawLine(i,py);
   }
}

// ================== RATIO ZONES – SUPORTE/RESISTÊNCIA ==================
// zone:
// 1 = Comprador – Amarelo (20–45)
// 2 = Comprador – Cinza   (35–45)
// 3 = Vendedor – Vermelho claro
// 4 = Vendedor – Vermelho escuro

string RZ_ID(const string kind, datetime t, int zone)
{
   return "RZ_"+IntegerToString(zone)+"_"+kind+"@"+IntegerToString((long)t);
}

void RatioZones_DeleteForBar(const int i)
{
   if(i<0 || i>=Bars) return;
   datetime t = Time[i];
   for(int z=1; z<=4; z++){
      ObjectDelete(0, RZ_ID("MID", t, z));
   }
}

// Limpa todas as zonas, usado em desativar / deinit
void RatioZones_DeleteAll()
{
   int total = ObjectsTotal(0,-1,-1);
   for(int k=total-1; k>=0; k--){
      string name = ObjectName(0,k);
      if(StringLen(name) >= 3 && StringSubstr(name,0,3) == "RZ_")
         ObjectDelete(0,name);
   }
}

void RatioZones_DrawForBar(const int i,int zone,double hi,double lo)
{
   if(i<0 || i>=Bars) return;
   datetime t0 = Time[i];
   datetime t1 = Time[0];

   color cMid;

   // Seleção da cor apenas da linha MID (50%)
   if(zone==2){ // comprador cinza
      cMid = RatioGrayMidColor;
   }
   else if(zone==1){ // comprador amarelo
      cMid = RatioYellowMidColor;
   }
   else if(zone==4){ // vendedor vermelho escuro
      cMid = RatioSellDarkMidColor;
   }
   else {            // zone==3 vendedor vermelho claro
      cMid = RatioSellLightMidColor;
   }

   double mid = (hi+lo)/2.0;

   // MID (50%) – única linha desenhada
   string idMid = RZ_ID("MID", t0, zone);

   if(ObjectFind(0,idMid)==-1)
      ObjectCreate(0,idMid,OBJ_TREND,0,t0,mid,t1,mid);

   ObjectSet(idMid,OBJPROP_TIME1,t0);
   ObjectSet(idMid,OBJPROP_TIME2,t1);
   ObjectSet(idMid,OBJPROP_PRICE1,mid);
   ObjectSet(idMid,OBJPROP_PRICE2,mid);
   ObjectSetInteger(0,idMid,OBJPROP_COLOR,cMid);
   ObjectSetInteger(0,idMid,OBJPROP_WIDTH,RatioMidWidth);
   ObjectSetInteger(0,idMid,OBJPROP_STYLE,RatioMidStyle);
   ObjectSetInteger(0,idMid,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(0,idMid,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,idMid,OBJPROP_BACK,false);
}

void RatioZones_Update()
{
   if(!RatioZones_Enable){
      RatioZones_DeleteAll();
      return;
   }

   int limit = MathMin(BarsToDrawMax, Bars-1);
   if(limit < 1) return;

   for(int i=1; i<=limit; i++)
   {
      double r = RatioForBar(i);
      int side = WinnerSideForBar(i); // +1 comprador, -1 vendedor
      int zone = 0;

      // ---------------- DEFINIÇÃO DA ZONA ----------------
      if(side > 0) // COMPRADOR
      {
         if(r >= RatioGrayMin && r <= RatioGrayMax)
            zone = 2;
         else if(r >= RatioYellowMin && r <= RatioYellowMax)
            zone = 1;
      }
      else if(side < 0) // VENDEDOR
      {
         if(r >= RatioSellDarkMin && r <= RatioSellDarkMax)
            zone = 4;
         else if(r >= RatioSellLightMin && r <= RatioSellLightMax)
            zone = 3;
      }

      if(zone == 0){
         RatioZones_DeleteForBar(i);
         continue;
      }

      double hi = High[i];
      double lo = Low[i];

      int breaks = 0;
      double tol = RatioBreakTolerancePts * Point;

      // ---------------- CONTAGEM DE ROMPIMENTO CONTRÁRIO ----------------
      // Zona de compra (side > 0):
      //   conta rompimento se FECHAMENTO abaixo da mínima
      // Zona de venda (side < 0):
      //   conta rompimento se FECHAMENTO acima da máxima
      for(int k=i-1; k>=0 && breaks<RatioBreaksToDelete; k--)
      {
         double cl = Close[k];

         if(side > 0)
         {
            if(cl < lo - tol) breaks++;  // rompimento contra comprador
         }
         else if(side < 0)
         {
            if(cl > hi + tol) breaks++;  // rompimento contra vendedor
         }
      }

      if(breaks >= RatioBreaksToDelete){
         RatioZones_DeleteForBar(i);
         continue;
      }

      // ainda válida: desenha/atualiza
      RatioZones_DrawForBar(i,zone,hi,lo);
   }
}

// =================== SNIPER – HELPERS ===================
double SNIP_GetOffsetPts(){
   return (SniperProximityMode==0? SniperOffsetNearPts : SniperOffsetFarPts) + SniperArrowOffsetPts;
}
void SNIP_GetVisuals(bool isBuy, double dominance, color &col, int &arrowSize)
{
   if(dominance >= 0.90){
      col       = SniperColor90;
      arrowSize = SniperArrowSize90;
   }
   else {
      col       = (isBuy ? SniperColor80Buy : SniperColor80Sell);
      arrowSize = SniperArrowSize80;
   }
}

string SNIP_ID(const string kind, datetime t){ return "SNIP_"+kind+"@"+IntegerToString((long)t); }
void SNIP_DeleteForBar(const int i){
   datetime t=Time[i];
   ObjectDelete(0, SNIP_ID("ARW",t));
   ObjectDelete(0, SNIP_ID("TXT",t));
}
void SNIP_DeleteLive(){
   ObjectDelete(0, "SNIP_LIVE_ARW");
   ObjectDelete(0, "SNIP_LIVE_TXT");
}

bool SNIP_ComputeDominance(const int i, bool &isBuy, double &dominance, int &mx, int &mn)
{
   dominance = 0.0; isBuy=false; mx=0; mn=0;

   int d = GetDeltaBar(i);
   int rawMx = (i<ArraySize(BarMaxDelta) && BarMaxDelta[i]!=INT_MIN) ? BarMaxDelta[i] : d;
   int rawMn = (i<ArraySize(BarMinDelta) && BarMinDelta[i]!=INT_MAX) ? BarMinDelta[i] : d;

   int aMx = MathAbs(rawMx);
   int aMn = MathAbs(rawMn);

   if(aMx==0 && aMn==0){
      if(d==0) return false;
      if(d>0){ aMx=MathAbs(d); aMn=0; }
      else   { aMn=MathAbs(d); aMx=0; }
   }

   if(aMx > aMn){ isBuy = true;  mx=aMx; mn=aMn; }
   else if(aMn > aMx){ isBuy = false; mx=aMx; mn=aMn; }
   else {
      if(d>0){ isBuy=true;  mx=aMx; mn=aMn; }
      else if(d<0){ isBuy=false; mx=aMx; mn=aMn; }
      else return false;
   }

   int strong = (isBuy ? mx : mn);
   int weak   = (isBuy ? mn : mx);
   if(strong <= 0) return false;

   double weakOverStrong = (weak>0 ? (double)weak/(double)strong : 0.0);
   dominance = 1.0 - weakOverStrong;

   if(strong < SniperMinDeltaAbs) return false;
   return true;
}
bool SNIP_CheckCancel(int barIndex, bool isBuy)
{
   if(!SniperCancelOnOppVol) return false;
   double ma = VolSMA(barIndex);
   int v = (int)Volume[barIndex];
   if(ma>0 && (double)v >= ma * SniperCancelVolFactor) return true;

   int d = GetDeltaBar(barIndex);
   if(isBuy && d < 0 && MathAbs((double)d) >= SniperCancelOppDVolAbs) return true;
   if(!isBuy && d > 0 && MathAbs((double)d) >= SniperCancelOppDVolAbs) return true;
   return false;
}

void SNIP_DrawFinalArrowAtBar(int barIndex, bool isBuy, double dominance, bool withText, string text)
{
   if(barIndex<0 || barIndex>=Bars) return;
   datetime t = Time[barIndex];

   color col; int arrowSize;
   SNIP_GetVisuals(isBuy, dominance, col, arrowSize);

   double y = isBuy ? (Low[barIndex] - SNIP_GetOffsetPts()*Point)
                    : (High[barIndex] + SNIP_GetOffsetPts()*Point);

   string idA = SNIP_ID("ARW", t);
   if(ObjectFind(0,idA)==-1) ObjectCreate(0,idA,OBJ_ARROW,0,t,y);
   ObjectSetInteger(0,idA,OBJPROP_ARROWCODE, (isBuy? SniperArrowCodeBuy : SniperArrowCodeSell));
   ObjectSetInteger(0,idA,OBJPROP_WIDTH, arrowSize);
   ObjectSetInteger(0,idA,OBJPROP_COLOR, col);
   ObjectSetInteger(0,idA,OBJPROP_BACK,false);
   ObjectSetInteger(0,idA,OBJPROP_SELECTABLE,false);
   ObjectMove(0,idA,0,t,y);

   string idT = SNIP_ID("TXT", t);
   if(withText){
      if(ObjectFind(0,idT)==-1)
         ObjectCreate(0,idT,OBJ_TEXT,0,t, y + (isBuy? -6*Point : +6*Point));
      ObjectSetText(idT, text, 10, FontName, (isBuy? SniperColorTextBuy:SniperColorTextSell));
      ObjectMove(0,idT,0,t, y + (isBuy? -6*Point : +6*Point));
      ObjectSetInteger(0,idT,OBJPROP_SELECTABLE,false);
   } else {
      ObjectDelete(0,idT);
   }
}
void SNIP_PlaySoundOnceForBar(datetime t)
{
   if(!SniperPlaySoundOnSignal || StringLen(SniperSoundFile)==0) return;
   if(last_sniper_sound_time == (long)t) return;
   last_sniper_sound_time = (long)t;
   PlaySound(SniperSoundFile);
}

// Preview meia-vela na barra 0
void SNIP_DrawLivePreviewIfNeeded()
{
   if(!SniperEnable || !SniperHalfBarEnable) { SNIP_DeleteLive(); return; }
   int perSec = PeriodSecondsEx();
   int elapsed = (int)(TimeCurrent() - Time[0]);
   if((double)elapsed < perSec * SniperHalfBarRatio){ SNIP_DeleteLive(); return; }

   bool isBuy=false; double dom=0.0; int mx=0, mn=0;
   if(!SNIP_ComputeDominance(0,isBuy,dom,mx,mn)) { SNIP_DeleteLive(); return; }
   if(dom < SniperDominanceMin) { SNIP_DeleteLive(); return; }
   if(AbsDVolPct(0) < SniperMinDVolPct) { SNIP_DeleteLive(); return; }
   if(SniperRequireDeltaSign){
      int d0=GetDeltaBar(0);
      if( (isBuy && d0<=0) || (!isBuy && d0>=0) ) { SNIP_DeleteLive(); return; }
   }
   if(SniperUseRatio){
      double r=RatioForBar(0);
      if(isBuy){
         if(r < 1.0 + SniperRatioEdge) { SNIP_DeleteLive(); return; }
      } else {
         if(r > 1.0 - SniperRatioEdge) { SNIP_DeleteLive(); return; }
      }
   }
   if(SNIP_CheckCancel(0,isBuy)) { SNIP_DeleteLive(); return; }

   color col; int arrowSize;
   SNIP_GetVisuals(isBuy, dom, col, arrowSize);

   string tx = "";
   if(SniperShowTextValues)
      tx = StringFormat("%s Dom:%d%% MX:%d MN:%d",
                        (isBuy?"BUY":"SELL"),
                        (int)MathRound(dom*100.0), mx, mn);

   datetime t = Time[0];
   double y = isBuy ? (Low[0] - SNIP_GetOffsetPts()*Point)
                    : (High[0] + SNIP_GetOffsetPts()*Point);

   if(ObjectFind(0,"SNIP_LIVE_ARW")==-1)
      ObjectCreate(0,"SNIP_LIVE_ARW",OBJ_ARROW,0,t,y);
   ObjectSetInteger(0,"SNIP_LIVE_ARW",OBJPROP_ARROWCODE,(isBuy? SniperArrowCodeBuy:SniperArrowCodeSell));
   ObjectSetInteger(0,"SNIP_LIVE_ARW",OBJPROP_WIDTH,arrowSize);
   ObjectSetInteger(0,"SNIP_LIVE_ARW",OBJPROP_COLOR,col);
   ObjectSetInteger(0,"SNIP_LIVE_ARW",OBJPROP_BACK,false);
   ObjectSetInteger(0,"SNIP_LIVE_ARW",OBJPROP_SELECTABLE,false);
   ObjectMove(0,"SNIP_LIVE_ARW",0,t,y);

   if(SniperShowTextValues && tx!=""){
      if(ObjectFind(0,"SNIP_LIVE_TXT")==-1)
         ObjectCreate(0,"SNIP_LIVE_TXT",OBJ_TEXT,0,t,y + (isBuy? -6*Point : +6*Point));
      ObjectSetText("SNIP_LIVE_TXT", tx, 10, FontName, (isBuy? SniperColorTextBuy:SniperColorTextSell));
      ObjectMove(0,"SNIP_LIVE_TXT",0,t,y + (isBuy? -6*Point : +6*Point));
   } else {
      ObjectDelete(0,"SNIP_LIVE_TXT");
   }
}

// =================== FUNÇÃO PARA DESENHAR SETAS DO RATIO AGRESSIVO ===================
void DrawRatioAggArrow(int i, bool isBuy)
{
    if(i < 0 || i >= Bars) return;

    datetime t = Time[i];
    string id  = isBuy ? 
                 ("RATIOAGG_BUY_"  + IntegerToString((long)t)) :
                 ("RATIOAGG_SELL_" + IntegerToString((long)t));

    double y = isBuy ?
               (Low[i]  - RatioAggOffsetPts * Point) :
               (High[i] + RatioAggOffsetPts * Point);

    if(ObjectFind(0, id) == -1)
        ObjectCreate(0, id, OBJ_ARROW, 0, t, y);

    ObjectSetInteger(0, id, OBJPROP_ARROWCODE, 
                     isBuy ? RatioAggArrowCodeBuy : RatioAggArrowCodeSell);

    ObjectSetInteger(0, id, OBJPROP_COLOR,
                     isBuy ? RatioAggColorBuy : RatioAggColorSell);

    ObjectSetInteger(0, id, OBJPROP_WIDTH, RatioAggArrowSize);
    ObjectSetInteger(0, id, OBJPROP_BACK, false);
    ObjectSetInteger(0, id, OBJPROP_SELECTABLE, false);

    ObjectMove(0, id, 0, t, y);
}

// =================== FUNÇÕES DE SETAS DE RATIO EXTREMO ===================
void DrawRatioSellLevelArrow(int i, int level)
{
   if(i < 0 || i >= Bars || level <= 0) return;

   datetime t = Time[i];
   string id = "RATIO_SELL_L" + IntegerToString(level) + "_" + IntegerToString((long)t);
   double y = High[i] + RatioSellOffsetPts * Point;

   int arrow  = RatioSell_Arrow1;
   int size   = RatioSell_Size1;
   color col  = RatioSell_Color1;

   if(level == 2){ arrow = RatioSell_Arrow2; size = RatioSell_Size2; col = RatioSell_Color2; }
   if(level == 3){ arrow = RatioSell_Arrow3; size = RatioSell_Size3; col = RatioSell_Color3; }

   if(ObjectFind(0, id) == -1)
      ObjectCreate(0, id, OBJ_ARROW, 0, t, y);

   ObjectSetInteger(0, id, OBJPROP_ARROWCODE, arrow);
   ObjectSetInteger(0, id, OBJPROP_COLOR, col);
   ObjectSetInteger(0, id, OBJPROP_WIDTH, size);
   ObjectSetInteger(0, id, OBJPROP_BACK, false);
   ObjectSetInteger(0, id, OBJPROP_SELECTABLE, false);

   ObjectMove(0, id, 0, t, y);
}

void DrawRatioBuyLevelArrow(int i, int level)
{
   if(i < 0 || i >= Bars || level <= 0) return;

   datetime t = Time[i];
   string id = "RATIO_BUY_L" + IntegerToString(level) + "_" + IntegerToString((long)t);
   double y = Low[i] - RatioBuyOffsetPts * Point;

   int arrow  = RatioBuy_Arrow1;
   int size   = RatioBuy_Size1;
   color col  = RatioBuy_Color1;

   if(level == 2){ arrow = RatioBuy_Arrow2; size = RatioBuy_Size2; col = RatioBuy_Color2; }
   if(level == 3){ arrow = RatioBuy_Arrow3; size = RatioBuy_Size3; col = RatioBuy_Color3; }

   if(ObjectFind(0, id) == -1)
      ObjectCreate(0, id, OBJ_ARROW, 0, t, y);

   ObjectSetInteger(0, id, OBJPROP_ARROWCODE, arrow);
   ObjectSetInteger(0, id, OBJPROP_COLOR, col);
   ObjectSetInteger(0, id, OBJPROP_WIDTH, size);
   ObjectSetInteger(0, id, OBJPROP_BACK, false);
   ObjectSetInteger(0, id, OBJPROP_SELECTABLE, false);

   ObjectMove(0, id, 0, t, y);
}

// =================== EVENTOS PADRÃO ===================
int OnInit(){
   // ===== BLOQUEIO DE LICENÇA =====
   if(!CheckLicense())
      return(INIT_FAILED);

   IndicatorShortName(gShortName);
   gWin=WindowFind(gShortName); if(gWin<0) gWin=0;

   // ===================== CONFIGURAÇÃO DOS BUFFERS EXTERNOS =====================
   ArraySetAsSeries(BufDelta,      true);
   ArraySetAsSeries(BufDVolPct,    true);
   ArraySetAsSeries(BufVolume,     true);
   ArraySetAsSeries(BufRatio,      true);
   ArraySetAsSeries(BufMaxDelta,   true);
   ArraySetAsSeries(BufMinDelta,   true);

   SetIndexBuffer(0, BufDelta);
   SetIndexBuffer(1, BufDVolPct);
   SetIndexBuffer(2, BufVolume);
   SetIndexBuffer(3, BufRatio);
   SetIndexBuffer(4, BufMaxDelta);
   SetIndexBuffer(5, BufMinDelta);

   // ===================== REMOVER LINHAS PRETAS DO PAINEL =====================
   for(int i = 0; i < 30; i++)  // Agora temos 30 buffers no total
   {
      SetIndexStyle(i, DRAW_NONE);
      SetIndexLabel(i, "");
   }

   ArrayResize(gStats,Bars+10);
   ArrayResize(AggDelta,Bars+10);
   for(int i=0;i<ArraySize(AggDelta);i++) AggDelta[i]=INT_MIN;
   ArrayResize(BarMaxDelta,Bars+10);
   ArrayResize(BarMinDelta,Bars+10);
   ArrayInitialize(BarMaxDelta,INT_MIN);
   ArrayInitialize(BarMinDelta,INT_MAX);

   if(Bars>0){
      gLastBarTime=Time[0];
      gLiveDelta0_curr=EstimateDelta(0);
      gLiveDelta0_prev=gLiveDelta0_curr;
      BarMaxDelta[0]=gLiveDelta0_curr;
      BarMinDelta[0]=gLiveDelta0_curr;
   }

   POC_Update();
   RatioZones_Update();

   // IMPORTANTE: não chamar StampWinner em histórico aqui
   // para não APAGAR carimbos antigos quando reanexar / mudar parâmetro.

   DrawRightHeaders();
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   // ===== BLOQUEIO EM TEMPO REAL =====
   if(!CheckLicense())
      return(0);

   bool newBar = (Bars>0 && Time[0] != gLastBarTime);

   if(ArraySize(AggDelta)     < Bars+10) ArrayResize(AggDelta,     Bars+10);
   if(ArraySize(BarMaxDelta)  < Bars+10) ArrayResize(BarMaxDelta,  Bars+10);
   if(ArraySize(BarMinDelta)  < Bars+10) ArrayResize(BarMinDelta,  Bars+10);
   if(ArraySize(gStats)       < Bars+10) ArrayResize(gStats,       Bars+10);

   if(newBar && Bars>1)
   {
      int lastMax0 = BarMaxDelta[0];
      int lastMin0 = BarMinDelta[0];

      int limit = MathMax(1, MathMin(BarsToDrawMax-1, Bars-1));

      for(int k=limit; k>=2; k--)
      {
         AggDelta[k]    = AggDelta[k-1];
         BarMaxDelta[k] = BarMaxDelta[k-1];
         BarMinDelta[k] = BarMinDelta[k-1];
      }

      AggDelta[1] = gLiveDelta0_prev;
      if(lastMax0!=INT_MIN) BarMaxDelta[1]=lastMax0;
      if(lastMin0!=INT_MAX) BarMinDelta[1]=lastMin0;

      // ---------- SNIPER na barra 1 (SÓ VELA 1) ----------
      if(SniperEnable)
      {
         bool  isBuy=false;
         double dominance=0.0;
         int   mx=0, mn=0;

         bool ok = SNIP_ComputeDominance(1, isBuy, dominance, mx, mn);

         if(ok && dominance < SniperDominanceMin) ok=false;
         if(ok){
            double dvolPct = AbsDVolPct(1);
            if(dvolPct < SniperMinDVolPct) ok=false;
         }
         if(ok && SniperRequireDeltaSign){
            int d1 = GetDeltaBar(1);
            if( (isBuy && d1<=0) || (!isBuy && d1>=0) ) ok=false;
         }
         if(ok && SniperUseRatio){
            double ratio = RatioForBar(1);
            if(isBuy){
               if(ratio < 1.0 + SniperRatioEdge) ok=false;
            } else {
               if(ratio > 1.0 - SniperRatioEdge) ok=false;
            }
         }
         if(ok && SNIP_CheckCancel(1,isBuy)) ok=false;

         if(ok){
            string tx = "";
            if(SniperShowTextValues)
               tx = StringFormat("%s Dom:%d%% MX:%d MN:%d",
                                 (isBuy?"BUY":"SELL"),
                                 (int)MathRound(dominance*100.0), mx, mn);

            SNIP_DeleteForBar(1);
            SNIP_DrawFinalArrowAtBar(1, isBuy, dominance, SniperShowTextValues, tx);
            SNIP_PlaySoundOnceForBar(Time[1]);
         } else {
           SNIP_DeleteForBar(1);
         }
      }
      // ---------- fim SNIPER ----------

      // carimbo APENAS da vela recém-fechada
      StampWinner(1);

      BarMaxDelta[0]=gLiveDelta0_prev;
      BarMinDelta[0]=gLiveDelta0_prev;

      if(FreezeClosedBars) FreezeBar(1);
      gLastBarTime=Time[0];

      POC_Update();
      RatioZones_Update();
   }

   // live updates barra 0
   if(Bars>0){
      gLiveDelta0_curr = EstimateDelta(0);
      if(BarMaxDelta[0]==INT_MIN) BarMaxDelta[0]=gLiveDelta0_curr;
      else if(gLiveDelta0_curr>BarMaxDelta[0]) BarMaxDelta[0]=gLiveDelta0_curr;

      if(BarMinDelta[0]==INT_MAX) BarMinDelta[0]=gLiveDelta0_curr;
      else if(gLiveDelta0_curr<BarMinDelta[0]) BarMinDelta[0]=gLiveDelta0_curr;

      gLiveDelta0_prev = gLiveDelta0_curr;
   }

   // ======================= SINAIS DE RATIO AGRESSIVO =======================
   int limitAgg = MathMin(Bars - 1, BarsToDrawMax);

   for (int i = 1; i <= limitAgg; i++)
   {
      double ratio = RatioForBar(i);

      // COMPRA: Ratio >= 8.0
      if (ratio >= RatioAgg_BuyMin)
      {
         DrawRatioAggArrow(i, true);
      }

      // VENDA: Ratio <= 0.8
      if (ratio <= RatioAgg_SellMax)
      {
         DrawRatioAggArrow(i, false);
      }
   }

   // ================= VENDA EXTREMA POR RATIO (3 NÍVEIS) =================
   if(UseRatioExtremeLevels)
   {
      int limitExt = MathMin(Bars - 1, BarsToDrawMax);

      for(int i = 1; i <= limitExt; i++)
      {
         double r = RatioForBar(i);
         int level = GetRatioSellLevel(r);

         if(level > 0)
            DrawRatioSellLevelArrow(i, level);
      }
   }

   // ================= COMPRA EXTREMA POR RATIO (3 NÍVEIS) =================
   if(UseRatioExtremeBuyLevels)
   {
      int limitBuy = MathMin(Bars - 1, BarsToDrawMax);

      for(int i = 1; i <= limitBuy; i++)
      {
         double r = RatioForBar(i);
         int level = GetRatioBuyLevel(r);

         if(level > 0)
            DrawRatioBuyLevelArrow(i, level);
      }
   }

   if(UpdateOnTick)
   {
      if(!POC_OnlyClosedBars) POC_Update();

      // se subjanela mudar, reobtém índice
      gWin=WindowFind(gShortName); if(gWin<0) gWin=0;

      int y=TopPaddingPx;
      DrawRightHeaders();
      int cols=MathMin(MathMin(WindowBarsPerChart(),Bars-1), BarsToDrawMax);
      if(cols<1) cols=1;

      // >>> CORREÇÃO DE DEFORMIDADE: limpa colunas além da área visível
      for(int c=cols; c<BarsToDrawMax; c++)
         DeleteColumn(c);

      for(int i=0;i<cols;i++) DrawColumn(i,y);

      // números nas velas, se desejado
      if(!ShowAggOnChart){
         int limit2 = MathMin(AggOnChartMaxBars, Bars-1);
         for(int ii=1;ii<=limit2;ii++) ObjectDelete(0, IDC("AGG", ii));
      } else {
         int limit3=MathMin(AggOnChartMaxBars, Bars-1);
         for(int i2=1;i2<=limit3;i2++){
            int reg=(i2<ArraySize(AggDelta)?AggDelta[i2]:INT_MIN);
            if(reg==INT_MIN){ ObjectDelete(0, IDC("AGG", i2)); continue; }
            double yy=(High[i2]+Low[i2])/2.0;
            string name=IDC("AGG",i2);
            color c=(reg>0?AggOnChartPosColor:(reg<0?AggOnChartNegColor:AggOnChartZeroColor));
            if(ObjectFind(0,name)==-1){
               ObjectCreate(0,name,OBJ_TEXT,0,Time[i2],yy);
               ObjectSetText(name,IntegerToString(reg),AggOnChartFontSize,FontName,c);
               ObjectSet(name,OBJPROP_BACK,false);
               ObjectSet(name,OBJPROP_SELECTABLE,false);
            } else {
               ObjectMove(0,name,0,Time[i2],yy);
               ObjectSetText(name,IntegerToString(reg),AggOnChartFontSize,FontName,c);
            }
         }
      }
   }

   // preview meia-vela
   SNIP_DrawLivePreviewIfNeeded();

   // =================== PREENCHER BUFFERS PARA iCustom ===================
   int bufferLimit = MathMin(Bars-1, BarsToDrawMax);

   for (int i = 0; i <= bufferLimit; i++)
   {
      BufDelta[i]    = GetDeltaBar(i);
      BufDVolPct[i]  = AbsDVolPct(i);
      BufVolume[i]   = Volume[i];
      BufRatio[i]    = RatioForBar(i);

      BufMaxDelta[i] = (BarMaxDelta[i] == INT_MIN ? GetDeltaBar(i) : BarMaxDelta[i]);
      BufMinDelta[i] = (BarMinDelta[i] == INT_MAX ? GetDeltaBar(i) : BarMinDelta[i]);
   }

   return(rates_total);
}

void OnDeinit(const int reason){
   int clear=MathMin(Bars-1, BarsToDrawMax-1);
   for(int i=0;i<=clear;i++) DeleteColumn(i);
   ObjectDelete(0,"H_DELTA"); ObjectDelete(0,"H_DVOL");
   ObjectDelete(0,"H_VOL");
   ObjectDelete(0,"H_MAXD");
   ObjectDelete(0,"H_MIND");
   ObjectDelete(0,"H_RATIO");

   int vis=MathMin(Bars-1, MathMin(WindowBarsPerChart(), BarsToDrawMax));
   for(int j=1;j<vis;j++){
      // NÃO APAGAR WINB/WINS quando apenas mudar parâmetros
      if(reason != REASON_PARAMETERS){
         ObjectDelete(0, IDT("WINB", Time[j]));
         ObjectDelete(0, IDT("WINS", Time[j]));
      }
      SNIP_DeleteForBar(j);
   }

   int lim=MathMin(POC_MaxBars, Bars-1);
   for(int i=0;i<=lim;i++) POC_DeleteForBar(i);

   RatioZones_DeleteAll();
   SNIP_DeleteLive();
}
//+------------------------------------------------------------------+