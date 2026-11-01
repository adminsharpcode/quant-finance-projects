//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright ""
#property link      ""

extern string xxx0 = "--- General:";
extern string SETname = "DEFAULT";
extern bool Flag_Stop = FALSE;
extern string xxx1 = "--- Logic:";
extern int Filter = 30;
extern int  Filter2=0;
extern double TPfact = 1.6;
extern double SLfact = 2.0;
extern int TakeProfit_Martin = 7;
extern int Indent = 0;
extern datetime IgnoreDDBeforeDate=315532800;
extern bool GapeProtect=true  ;
extern string xxx2 = "--- MM: ";
extern double LotSize = 0.1;
extern double MaxLotSize=0.0;
extern bool AutoMM = FALSE;
extern double AutoMMEquity = 10000.0;
extern string xxx3 = "--- Misc: ";
extern int Magic = 4376;
extern bool Verbose = TRUE;
extern color comment_color = White;
extern int  comment_fontsize=11;
extern int  comment_lineheight=18;
extern color box_color = DarkSlateGray;
extern bool DrawLines=true;
extern color ColorUp=16748574;
extern color ColorLo=7504122;





bool GAti_192 = TRUE;
int GAti_196 = 0;
int GAti_200 = 0;
bool GAti_156 = TRUE;
string GAts_76;
int GAti_84 = 3;
int GAti_120 = 15;
double GAtd_216;
double GAtd_224;
double GAtd_232;
double GAtd_240;
double GAtd_248;
double GAtd_256;
double GAtd_264;
double GAtd_272;
int GAti_280;
int GAti_284 = 1001;
double GAtd_288 = 0.0;
double GAtd_296 = 0.0;
int GAti_304 = 0;
int GAti_308 = 0;
int GAti_312 = 0;
int GAti_316 = 0;
double GAtd_320 = 0.0;
double GAtd_328 = 0.0;
double GAtd_336 = 0.0;
double GAtd_344 = 0.0;
double GAtd_352 = 0.0;
double GAtd_360 = 0.0;
double GAtd_368;
double GAtd_376;
int GAti_384 = 0;
int GAti_388 = 0;
int GAti_392 = 0;
int GAti_396 = 0;
int GAti_400;
int GAti_404;
int GAti_412 = 0;
double GAtd_416 = 0.0;
double GAtd_424 = 0.0;
int GAti_432;
double GAtda_436[1001];
double GAtda_440[1001];
double GAtda_444[1001];
double GAtda_448[1001];
int GAti_452 = 0;
double GAtd_456 = 0.0;
double GAtd_464 = 0.0;
int GAti_472;
double GAtda_476[1001];
double GAtda_480[1001];
double GAtda_484[1001];
double GAtda_488[1001];
double GAtd_492;
double GAtd_500;
double GAtd_508;
double GAtd_524;
double GAtd_532;
double GAtd_540;
double GAtd_548;
double GAtd_556;
double GAtd_572;
double GAtd_580;
string GAts_588 = "";
string GAts_596 = "comment_textbox";
int GAti_604 = 0;

string GAts_tahoma_612 = "Tahoma";
int GAti_620 = 12;
int GAti_624 = 40;

int GAti_632 = 500;
int GAti_636 = 4;
int GAti_640 = 10;
bool GAti_644 = FALSE;

// E37F0136AA3FFAF149B351F6A4C948E9
int init()
  {
   if(Digits < 4)
      GAtd_216 = 0.01;
   else
      GAtd_216 = 0.0001;
   if(StringSubstr(Symbol(), 0, 6) == "XAGUSD")
     {
      GAtd_216 = 0.01;
      Print("Metals: silver");
      Print("Point = ", f0_1(Point), "  Digits = ", Digits, "  point4 = ", f0_1(GAtd_216));
      Print("Tick value = ", MarketInfo(Symbol(), MODE_TICKVALUE));
      Print("Price of pip = ", MarketInfo(Symbol(), MODE_TICKVALUE) * GAtd_216 / Point);
     }
   else
     {
      if(StringSubstr(Symbol(), 0, 6) == "XAUUSD" || StringSubstr(Symbol(), 0, 4) == "GOLD" || StringSubstr(Symbol(), 0, 4) == "Gold")
        {
         GAtd_216 = 0.1;
         Print("Metals: gold");
         Print("Point = ", f0_1(Point), "  Digits = ", Digits, "  point4 = ", f0_1(GAtd_216));
         Print("Tick value = ", MarketInfo(Symbol(), MODE_TICKVALUE));
         Print("Price of pip = ", MarketInfo(Symbol(), MODE_TICKVALUE) * GAtd_216 / Point);
        }
     }
   GAts_76 = WindowExpertName();
   GAti_400 = TPfact * Filter;
   GAti_404 = SLfact * Filter;
   GAtd_240 = MarketInfo(Symbol(), MODE_MINLOT);
   GAtd_248 = MarketInfo(Symbol(), MODE_MAXLOT);
   GAtd_256 = MarketInfo(Symbol(), MODE_LOTSTEP);
   GAtd_264 = MarketInfo(Symbol(), MODE_TICKVALUE);
   GAtd_272 = MarketInfo(Symbol(), MODE_MARGINREQUIRED);
   if(GAtd_256 < 0.1)
      GAti_280 = 2;
   else
     {
      if(GAtd_256 < 1.0)
         GAti_280 = 1;
      else
         GAti_280 = 0;
     }
   GAtd_232 = MathMax(MarketInfo(Symbol(), MODE_STOPLEVEL) * Point, 2.0 * (Ask - Bid));
   if(GAti_196 == 0)
      GAtd_224 = MarketInfo(Symbol(), MODE_SPREAD) * Point;
   else
      GAtd_224 = GAti_196 * GAtd_216;
   Print("Ask-Bid = ", f0_1(Ask - Bid));
   Print("spread = ", f0_1(GAtd_224));
   Print("stop_level = ", f0_1(GAtd_232));
   Print("point4 = ", f0_1(GAtd_216));
   double LAtd_0 = 0;
   double LAtd_8 = 0;
   f0_19();
   for(int LAti_16 = 0; LAti_16 <= Bars - 4; LAti_16++)
     {
      f0_2(LAti_16);
      if(LAtd_0 == 0.0 && GAtd_424 > 0.0)
         LAtd_0 = GAtd_424;
      if(LAtd_8 == 0.0 && GAtd_416 > 0.0)
         LAtd_8 = GAtd_416;
      if(LAtd_8 > 0.0 && LAtd_0 > 0.0)
         break;
     }
   GAtd_424 = LAtd_0;
   GAtd_416 = LAtd_8;
   if(Verbose)
      Print("LastMax_1 = ", f0_1(GAtd_416));
   if(Verbose)
      Print("LastMin_1 = ", f0_1(GAtd_424));
   double LAtd_20 = 0;
   double LAtd_28 = 0;
   f0_4();
   for(LAti_16 = 0; LAti_16 <= Bars - 4; LAti_16++)
     {
      f0_0(LAti_16);
      if(LAtd_20 == 0.0 && GAtd_464 > 0.0)
         LAtd_20 = GAtd_464;
      if(LAtd_28 == 0.0 && GAtd_456 > 0.0)
         LAtd_28 = GAtd_456;
      if(LAtd_28 > 0.0 && LAtd_20 > 0.0)
         break;
     }
   GAtd_464 = LAtd_20;
   GAtd_456 = LAtd_28;
   if(Verbose)
      Print("LastMax_2 = ", f0_1(GAtd_456));
   if(Verbose)
      Print("LastMin_2 = ", f0_1(GAtd_464));
   return (0);
  }

// 2F3FDDF1EA51500CBCDC792D9DB1D041
void f0_2(int AAti_0 = 0)
  {
   if(GAtda_436[AAti_0 + 1] > GAtda_448[AAti_0 + 1] && GAtda_436[AAti_0 + 2] < GAtda_448[AAti_0 + 2])
      GAtd_416 = f0_11(MathMax(GAtda_444[AAti_0 + 1], GAtda_444[AAti_0 + 2]));
   if(GAtda_436[AAti_0 + 1] < GAtda_448[AAti_0 + 1] && GAtda_436[AAti_0 + 2] > GAtda_448[AAti_0 + 2])
      GAtd_424 = f0_11(MathMin(GAtda_440[AAti_0 + 1], GAtda_440[AAti_0 + 2]));
  }

// 042F9499ECF2F032579D544D37E7B082
void f0_0(int AAti_0 = 0)
  {
   if(GAtda_476[AAti_0 + 1] > GAtda_488[AAti_0 + 1] && GAtda_476[AAti_0 + 2] < GAtda_488[AAti_0 + 2])
      GAtd_456 = f0_11(MathMax(GAtda_484[AAti_0 + 1], GAtda_484[AAti_0 + 2]));
   if(GAtda_476[AAti_0 + 1] < GAtda_488[AAti_0 + 1] && GAtda_476[AAti_0 + 2] > GAtda_488[AAti_0 + 2])
      GAtd_464 = f0_11(MathMin(GAtda_480[AAti_0 + 1], GAtda_480[AAti_0 + 2]));
  }

// 52D46093050F38C27267BCE42543EF60
void deinit()
  {
   f0_5();
   f0_10();
   ObjectDelete("Q_S_1");
   ObjectDelete("Q_S_2");
   string LAts_0 = "a" + GAts_76 + "Box";
   ObjectDelete(LAts_0);
   LAts_0 = "a" + GAts_76 + "Box2";
   ObjectDelete(LAts_0);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {


   start0();
  }

// EA2B2676C28C0DB26D39331A336C6B92
int start0()
  {
   f0_13();
   int LAti_0;
   double LAtd_4;
   double LAtd_12;
   double LAtd_20;
   int LAti_36;
   bool LAti_52;
   double LAtd_56;
   double LAtd_112;
   double LAtd_120;
   double LAtd_128;
   int LAti_136;
   int LAti_172;
   double LAtd_176;
   GAti_400 = TPfact * Filter;
   GAti_404 = SLfact * Filter;
   double LAtd_64 = GAtd_416;
   double LAtd_72 = GAtd_424;
   if(GAtd_416 <= 0.0)
      GAtd_416 = MathMax(iHigh(NULL, PERIOD_D1, 1), Ask + Filter * GAtd_216);
   if(GAtd_424 <= 0.0)
      GAtd_424 = MathMin(iLow(NULL, PERIOD_D1, 1), Bid - Filter * GAtd_216);
   if(GAtd_416 <= 0.0 || GAtd_424 <= 0.0)
     {
      Comment("Not enough quotes");
      Print("Not enough quotes");
      return (0);
     }
   double LAtd_80 = GAtd_456;
   double LAtd_88 = GAtd_464;
   if(GAtd_456 <= 0.0)
      GAtd_456 = MathMax(iHigh(NULL, PERIOD_D1, 1), Ask + GAti_120 * GAtd_216);
   if(GAtd_464 <= 0.0)
      GAtd_464 = MathMin(iLow(NULL, PERIOD_D1, 1), Bid - GAti_120 * GAtd_216);
   if(GAtd_456 <= 0.0 || GAtd_464 <= 0.0)
     {
      Comment("Not enough quotes");
      Print("Not enough quotes");
      return (0);
     }
   LAtd_64 = GAtd_416;
   LAtd_72 = GAtd_424;
   f0_19();
   f0_2();
   if(GAti_412 <= 0 && Bid > GAtd_416)
      GAti_412 = 2;
   if(GAti_412 > 0 && Bid > GAtd_424 && Bid < GAtd_416)
      GAti_412 = 1;
   if(GAti_412 >= 0 && Bid < GAtd_424)
      GAti_412 = -2;
   if(GAti_412 < 0 && Bid > GAtd_424 && Bid < GAtd_416)
      GAti_412 = -1;
   LAtd_80 = GAtd_456;
   LAtd_88 = GAtd_464;
   f0_4();
   f0_0();
   if(GAti_452 <= 0 && Bid > GAtd_456)
      GAti_452 = 2;
   if(GAti_452 > 0 && Bid > GAtd_464 && Bid < GAtd_456)
      GAti_452 = 1;
   if(GAti_452 >= 0 && Bid < GAtd_464)
      GAti_452 = -2;
   if(GAti_452 < 0 && Bid > GAtd_464 && Bid < GAtd_456)
      GAti_452 = -1;
   double LAtd_96 = GAtd_288;
   double LAtd_104 = GAtd_296;
   GAtd_288 = GAtd_416;
   GAtd_296 = GAtd_424;
   if(GAtd_288 != LAtd_96)
     {
      LAti_52 = FALSE;
      for(int LAti_44 = OrdersTotal() - 1; LAti_44 >= 0; LAti_44--)
        {
         if(OrderSelect(LAti_44, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
              {
               LAtd_4 = OrderOpenPrice();
               if(OrderType() == OP_SELL)
                 {
                  LAtd_20 = f0_11(MathMin(GAtd_288 + Indent * GAtd_216 + GAtd_224, LAtd_4 + GAti_404 * GAtd_216));
                  if(LAtd_20 <= OrderStopLoss() - Point)
                    {
                     f0_15(OrderTicket(), OrderOpenPrice(), LAtd_20, OrderTakeProfit(), 0, Red);
                     LAti_52 = TRUE;
                    }
                 }
              }
           }
        }
      if(LAti_52 && GAti_156)
         f0_9(1);
     }
   if(GAtd_296 != LAtd_104)
     {
      LAti_52 = FALSE;
      for(LAti_44 = OrdersTotal() - 1; LAti_44 >= 0; LAti_44--)
        {
         if(OrderSelect(LAti_44, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
              {
               LAtd_4 = OrderOpenPrice();
               if(OrderType() == OP_BUY)
                 {
                  LAtd_20 = f0_11(MathMax(GAtd_296 - Indent * GAtd_216, LAtd_4 - GAti_404 * GAtd_216));
                  if(LAtd_20 >= OrderStopLoss() + Point)
                    {
                     f0_15(OrderTicket(), OrderOpenPrice(), LAtd_20, OrderTakeProfit(), 0, Blue);
                     LAti_52 = TRUE;
                    }
                 }
              }
           }
        }
      if(LAti_52 && GAti_156)
         f0_9(-1);
     }
   if(GAtd_288 != LAtd_96 || GAtd_296 != LAtd_104)
     {
      for(LAti_44 = OrdersTotal() - 1; LAti_44 >= 0; LAti_44--)
        {
         if(OrderSelect(LAti_44, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() > OP_SELL)
              {
               LAtd_4 = OrderOpenPrice();
               LAtd_20 = OrderStopLoss();
               LAtd_12 = OrderTakeProfit();
               if(OrderType() == OP_BUYSTOP)
                 {
                  LAtd_112 = f0_11(GAtd_288 + Indent * GAtd_216 + GAtd_224);
                  LAtd_120 = f0_11(MathMax(GAtd_296 - Indent * GAtd_216, LAtd_112 - GAti_404 * GAtd_216));
                  LAtd_128 = f0_11(LAtd_112 + MathAbs(LAtd_4 - LAtd_12));
                  if((MathAbs(LAtd_112 - LAtd_4) >= Point || MathAbs(LAtd_120 - LAtd_20) >= Point)&& LAtd_112 > Ask + GAtd_232)
                     f0_15(OrderTicket(), LAtd_112, LAtd_120, LAtd_128, 0, Blue);
                 }
               if(OrderType() == OP_SELLSTOP)
                 {
                  LAtd_112 = f0_11(GAtd_296 - Indent * GAtd_216);
                  LAtd_120 = f0_11(MathMin(GAtd_288 + Indent * GAtd_216 + GAtd_224, LAtd_112 + GAti_404 * GAtd_216));
                  LAtd_128 = f0_11(LAtd_112 - MathAbs(LAtd_4 - LAtd_12));
                  if((MathAbs(LAtd_112 - LAtd_4) >= Point || MathAbs(LAtd_120 - LAtd_20) >= Point)&& LAtd_112 < Bid - GAtd_232)
                     f0_15(OrderTicket(), LAtd_112, LAtd_120, LAtd_128, 0, Red);
                 }
              }
           }
        }
     }
   if(GAti_156)
     {
      if(GAti_308 != OrdersHistoryTotal())
        {
         LAti_136 = GAti_312;
         GAti_308 = OrdersHistoryTotal();
         GAtd_320 = 0;
         GAti_312 = 0;
         for(LAti_44 = GAti_308 - 1; LAti_44 >= 0; LAti_44--)
           {
            if(OrderSelect(LAti_44, SELECT_BY_POS, MODE_HISTORY))
              {
               if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() <= OP_SELL)
                 {
                  if(OrderProfit() > 0.0)
                     break;
                  GAtd_320 += OrderProfit() + OrderCommission() + OrderSwap();
                  GAti_312++;
                 }
              }
           }
         if(GAti_312 > GAti_316)
            GAti_316 = GAti_312;
         if(GAtd_320 < GAtd_328)
            GAtd_328 = GAtd_320;
         if(GAtd_320 > 0.0)
            GAtd_320 = 0;
        }
     }
   GAti_384 = 0;
   GAti_388 = 0;
   GAti_392 = 0;
   GAti_396 = 0;
   GAtd_336 = 0;
   GAtd_344 = 0;
   GAtd_352 = 0;
   GAtd_360 = 0;
   double LAtd_140 = 0;
   double LAtd_148 = 0;
   double LAtd_156 = 0;
   double LAtd_164 = 0;
   for(LAti_44 = OrdersTotal() - 1; LAti_44 >= 0; LAti_44--)
     {
      if(OrderSelect(LAti_44, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
           {
            LAti_172 = OrderType();
            if(LAti_172 == OP_BUY)
              {
               GAti_384++;
               LAtd_140 += OrderLots();
              }
            else
              {
               if(LAti_172 == OP_SELL)
                 {
                  GAti_388++;
                  LAtd_148 += OrderLots();
                 }
               else
                 {
                  if(LAti_172 == OP_BUYSTOP || LAti_172 == OP_BUYLIMIT)
                    {
                     GAti_392++;
                     LAtd_156 += OrderLots();
                     GAtd_352 += MathAbs(OrderOpenPrice() - OrderTakeProfit()) * OrderLots() / Point * GAtd_264;
                    }
                  else
                    {
                     if(LAti_172 == OP_SELLSTOP || LAti_172 == OP_SELLLIMIT)
                       {
                        GAti_396++;
                        LAtd_164 += OrderLots();
                        GAtd_360 += MathAbs(OrderOpenPrice() - OrderTakeProfit()) * OrderLots() / Point * GAtd_264;
                       }
                    }
                 }
              }
            if(LAti_172 <= OP_SELL)
              {
               GAtd_336 -= MathAbs(OrderOpenPrice() - OrderStopLoss()) * OrderLots() / Point * GAtd_264;
               GAtd_344 += MathAbs(OrderOpenPrice() - OrderTakeProfit()) * OrderLots() / Point * GAtd_264;
              }
           }
        }
     }
   if(GAti_156)
     {
      LAtd_176 = f0_3();
      if(GAti_312 == 0 && GAti_384 == 0 && GAti_388 == 0)
        {
         GAtd_368 = LAtd_176;
         LAti_0 = GAti_400;
        }
      else
        {
         LAti_0 = GAti_400;
         GAtd_376 = (-GAtd_320) - GAtd_336 + (GAti_312 + 2) * f0_3() * GAtd_264 * TakeProfit_Martin * GAtd_216 / Point;
         GAtd_368 = f0_16(GAtd_376 / (LAti_0 * GAtd_216 / Point * GAtd_264));
         if(GAtd_368 < LAtd_176)
            GAtd_368 = LAtd_176;
        }
     }
   else
     {
      GAtd_368 = f0_3();
      LAti_0 = GAti_400;
     }
   if(LAtd_156 > 0.0)
     {
      if(LAtd_156 >= GAtd_368 + GAtd_240 - 0.0001)
        {
         f0_9(1);
         GAti_392 = 0;
         LAtd_156 = 0;
        }
      else
        {
         if(LAtd_156 <= GAtd_368 - GAtd_240 + 0.0001)
           {
            f0_9(1);
            GAti_392 = 0;
            LAtd_156 = 0;
           }
        }
     }
   if(LAtd_164 > 0.0)
     {
      if(LAtd_164 >= GAtd_368 + GAtd_240 - 0.0001)
        {
         f0_9(-1);
         GAti_396 = 0;
         LAtd_164 = 0;
        }
      else
        {
         if(LAtd_164 <= GAtd_368 - GAtd_240 + 0.0001)
           {
            f0_9(-1);
            GAti_396 = 0;
            LAtd_164 = 0;
           }
        }
     }
   if(GAti_384 == 0 && GAti_392 == 0 && Ask < GAtd_288 - 5.0 * GAtd_232 && (!Flag_Stop))
     {
      for(int LAti_40 = 0; GAtd_368 > GAtd_240 - 0.0001 && LAti_40 < 50; LAti_40++)
        {
         LAtd_56 = MathMin(GAtd_368, GAtd_248);
         RefreshRates();
         LAti_36 = f0_7(1, LAtd_56, LAti_0);
         if(LAti_36 > 0)
            GAtd_368 -= LAtd_56;
        }
     }
   if(GAti_388 == 0 && GAti_396 == 0 && Bid > GAtd_296 + 5.0 * GAtd_232 && (!Flag_Stop))
     {
      for(LAti_40 = 0; GAtd_368 > GAtd_240 - 0.0001 && LAti_40 < 50; LAti_40++)
        {
         LAtd_56 = MathMin(GAtd_368, GAtd_248);
         RefreshRates();
         LAti_36 = f0_7(-1, LAtd_56, LAti_0);
         if(LAti_36 > 0)
            GAtd_368 -= LAtd_56;
        }
     }
   if((!IsTesting()) || IsVisualMode())
      f0_13();
   return (0);
  }

// 883C65C67FF63C7C6C4782272239D9B1
int f0_7(int AAti_0, double AAtd_4, int AAti_12)
  {
   double LAtd_16;
   double LAtd_24;
   double LAtd_32;
   int LAti_40;
   int LAti_44;
   int LAti_48 = -1;



   if(AAti_0 > 0)
     {
      LAtd_16 = GAtd_288 + Indent * GAtd_216 + GAtd_224;
      LAtd_32 = LAtd_16 + AAti_12 * GAtd_216;
      LAtd_24 = MathMax(GAtd_296 - Indent * GAtd_216, LAtd_16 - GAti_404 * GAtd_216);
      LAti_44 = AAti_12;
      LAti_40 = MathRound(MathAbs(LAtd_16 - LAtd_24) / GAtd_216);

      FUN_06("Q_S_1", f0_11(LAtd_16),  ColorUp,1,2);
      if(Verbose)
         Print(Magic + " Setting the BUYSTOP order with Lot ", DoubleToStr(AAtd_4, GAti_280), ", TP = ", LAti_44, ", SL = ", LAti_40);
      if(GAti_192)
         LAti_48 = OrderSend(Symbol(), OP_BUYSTOP, AAtd_4, f0_11(LAtd_16), GAti_84, 0, 0, GAts_76, Magic, 0, Blue);
      else
         LAti_48 = OrderSend(Symbol(), OP_BUYSTOP, AAtd_4, f0_11(LAtd_16), GAti_84, f0_11(LAtd_24), f0_11(LAtd_32), GAts_76, Magic, 0, Blue);
      if(LAti_48 < 0)
        {
         f0_18();
         Print("Ask = ", f0_1(Ask), " OP = ", f0_1(LAtd_16), " OSL = ", f0_1(LAtd_24), " OTP = ", f0_1(LAtd_32));
        }
      if(LAti_48 > 0 && GAti_192)
         f0_12(LAti_48, LAti_40, LAti_44);
     }
   else
     {
      if(AAti_0 < 0)
        {
         LAtd_16 = GAtd_296 - Indent * GAtd_216;
         LAtd_32 = LAtd_16 - AAti_12 * GAtd_216;
         LAtd_24 = MathMin(GAtd_288 + Indent * GAtd_216 + GAtd_224, LAtd_16 + GAti_404 * GAtd_216);
         LAti_44 = AAti_12;
         LAti_40 = MathRound(MathAbs(LAtd_16 - LAtd_24) / GAtd_216);

         FUN_06("Q_S_2", f0_11(LAtd_16),  ColorLo,1,2);
         if(Verbose)
            Print(Magic + " Setting the SELLSTOP order with Lot ", DoubleToStr(AAtd_4, GAti_280), ", TP = ", LAti_44, ", SL = ", LAti_40);
         if(GAti_192)
            LAti_48 = OrderSend(Symbol(), OP_SELLSTOP, AAtd_4, f0_11(LAtd_16), GAti_84, 0, 0, GAts_76, Magic, 0, Red);
         else
            LAti_48 = OrderSend(Symbol(), OP_SELLSTOP, AAtd_4, f0_11(LAtd_16), GAti_84, f0_11(LAtd_24), f0_11(LAtd_32), GAts_76, Magic, 0, Red);
         if(LAti_48 < 0)
           {
            f0_18();
            Print("Bid = ", f0_1(Bid), " OP = ", f0_1(LAtd_16), " OSL = ", f0_1(LAtd_24), " OTP = ", f0_1(LAtd_32));
           }
         if(LAti_48 > 0 && GAti_192)
            f0_12(LAti_48, LAti_40, LAti_44);
        }
     }
   return (LAti_48);
  }

// 3EF451BB4852740EF08D77193A641370
double f0_3()
  {
   double LAtd_0;
   double LAtd_8;
   double LAtd_16;
   double LAtd_24;
   if(AutoMM && AutoMMEquity > 0.0)
     {
      LAtd_8 = AccountBalance();
      LAtd_16 = 10.0;
      LAtd_24 = MathFloor(LAtd_8 / (AutoMMEquity / LAtd_16)) * (AutoMMEquity / LAtd_16);
      LAtd_0 = MathRound(LotSize * LAtd_24 / AutoMMEquity / GAtd_256) * GAtd_256;
     }
   else
      LAtd_0 = LotSize;
   if(LAtd_0 < GAtd_240)
      LAtd_0 = GAtd_240;
   if(LAtd_0 > GAtd_248)
      LAtd_0 = GAtd_248;
   return (LAtd_0);
  }

// 9904FBA585854575D495DA0BA2924125
void f0_9(int AAti_0)
  {
   bool LAti_16;
   int LAti_4 = 0;
   bool LAti_8 = TRUE;
   while(LAti_8 && LAti_4 < 30)
     {
      LAti_4++;
      LAti_8 = FALSE;
      RefreshRates();
      for(int LAti_12 = OrdersTotal() - 1; LAti_12 >= 0; LAti_12--)
        {
         if(OrderSelect(LAti_12, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderMagicNumber() == Magic)
              {
               if((AAti_0 > 0 &&(OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT))|| (AAti_0 < 0 &&(OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)))
                 {
                  LAti_16 = OrderDelete(OrderTicket());
                  if(!LAti_16)
                    {
                     f0_18();
                     LAti_8 = TRUE;
                    }
                 }
              }
           }
        }
     }
   if(LAti_8)
      Print(Magic + " DeleteAllPendingOrders: failed");
  }

// AF8F6FC6FA3DE1C2797A0BED6CFEACE8
void f0_12(int AAti_0, int AAti_4, int AAti_8)
  {
   double LAtd_12;
   double LAtd_20;
   double LAtd_28;
   int LAti_36;
   if(AAti_8 == 0 && AAti_4 == 0)
      return;
   if(OrderSelect(AAti_0, SELECT_BY_TICKET))
     {
      LAtd_12 = OrderOpenPrice();
      LAti_36 = OrderType();
      if(LAti_36 == OP_BUY || LAti_36 == OP_BUYSTOP || LAti_36 == OP_BUYLIMIT)
        {
         if(AAti_8 > 0)
            LAtd_20 = f0_11(LAtd_12 + MathMax(AAti_8 * GAtd_216, GAtd_232));
         else
            LAtd_20 = OrderTakeProfit();
         if(AAti_4 > 0)
            LAtd_28 = f0_11(LAtd_12 - MathMax(AAti_4 * GAtd_216, GAtd_232));
         else
            LAtd_28 = OrderStopLoss();
         if(!(f0_11(LAtd_20) != f0_11(OrderTakeProfit()) || f0_11(LAtd_28) != f0_11(OrderStopLoss())))
            return;
         f0_15(AAti_0, LAtd_12, LAtd_28, LAtd_20, 0, Blue);
         return;
        }
      if(!(LAti_36 == OP_SELL || LAti_36 == OP_SELLSTOP || LAti_36 == OP_SELLLIMIT))
         return;
      if(AAti_8 > 0)
         LAtd_20 = f0_11(LAtd_12 - MathMax(AAti_8 * GAtd_216, GAtd_232));
      else
         LAtd_20 = OrderTakeProfit();
      if(AAti_4 > 0)
         LAtd_28 = f0_11(LAtd_12 + MathMax(AAti_4 * GAtd_216, GAtd_232));
      else
         LAtd_28 = OrderStopLoss();
      if(!(f0_11(LAtd_20) != f0_11(OrderTakeProfit()) || f0_11(LAtd_28) != f0_11(OrderStopLoss())))
         return;
      f0_15(AAti_0, LAtd_12, LAtd_28, LAtd_20, 0, Red);
      return;
     }
   Print("Error selecting order #", AAti_0);
  }

// D532DC49F12A0F8C022511BF7A5C979C
void f0_15(int AAti_0, double AAtd_4, double AAtd_12, double AAtd_20, int AAti_28, color AAti_32)
  {
   bool LAti_40;
   for(int LAti_36 = 0; LAti_36 < 10; LAti_36++)
     {
      while(!IsTradeAllowed())
         Sleep(1000);
      RefreshRates();
      LAti_40 = OrderModify(AAti_0, AAtd_4, AAtd_12, AAtd_20, AAti_28, AAti_32);
      if(LAti_40)
         break;
      f0_18();
      Print(Magic, "ticket = ", AAti_0, " price = ", f0_1(AAtd_4), " sl = ", f0_1(AAtd_12), " tp = ", f0_1(AAtd_20), " stop_level =", f0_1(GAtd_232));
      Print(Magic, "OrderOpenPrice = ", f0_1(OrderOpenPrice()), " OrderStopLoss = ", f0_1(OrderStopLoss()), " OrderTakeProfit = ", f0_1(OrderTakeProfit()));
     }
  }

// DB235EC41F2A7E866C4D86277EB6EDDC
double f0_16(double AAtd_0)
  {
   double LAtd_8 = NormalizeDouble(MathRound(AAtd_0 / GAtd_256) * GAtd_256, GAti_280);
   if(LAtd_8 < GAtd_240)
      LAtd_8 = GAtd_240;
   return (LAtd_8);
  }

// 12D87B8E013C154B16D7C73EF010FC87
string f0_1(double AAtd_0)
  {
   return (DoubleToStr(AAtd_0, Digits));
  }

// E648787A02E7F9599A8E07ADBFC13C9D
string f0_17(double AAtd_0)
  {
   return (DoubleToStr(AAtd_0, 2));
  }

// F10AA9FA6F6B89E4ECE657C536CE7E19
void f0_19()
  {
   int LAti_8;
   int LAti_12;
   double LAtd_16;
   int LAti_32;
   int LAti_36;
   double LAtd_24 = f0_11(Filter * GAtd_216);
   if(GAti_432 == 0)
     {
      LAti_32 = 10;
      if(iBars(NULL, PERIOD_M1) > 0)
         LAti_36 = 1;
      else
        {
         if(iBars(NULL, Period()) > 0)
            LAti_36 = Period();
         else
            LAti_36 = 0;
        }
      if(LAti_36 > 0)
        {
         for(int LAti_4 = 2; LAti_4 < MathMin(10000, iBars(NULL, LAti_36)); LAti_4++)
           {
            LAti_8 = LAti_4;
            if(MathAbs(iClose(NULL, LAti_36, LAti_4) - iClose(NULL, LAti_36, 1)) > LAti_32 * LAtd_24)
               break;
           }
         LAtd_16 = GAti_200 * GAtd_216;
         GAtd_508 = LAtd_16 + MathFloor((iClose(NULL, LAti_36, LAti_8) - LAtd_16) / LAtd_24) * LAtd_24;
        }
      else
        {
         LAti_8 = 0;
         LAtd_16 = GAti_200 * GAtd_216;
         GAtd_508 = LAtd_16 + MathFloor((Close[0] - LAtd_16) / LAtd_24) * LAtd_24;
        }
      GAtd_492 = GAtd_508;
      GAtd_500 = GAtd_508 - LAtd_24;
      GAtd_524 = GAtd_492;
      GAtd_532 = GAtd_500;
      GAti_432 = 1;
      for(LAti_4 = LAti_8 - 1; LAti_4 >= 1; LAti_4--)
        {
         LAti_12 = iHigh(NULL, LAti_36, LAti_4) + iLow(NULL, LAti_36, LAti_4) > iHigh(NULL, LAti_36, LAti_4 + 1) + iLow(NULL, LAti_36, LAti_4 + 1);
         GAtd_524 = MathMax(GAtd_524, iHigh(NULL, LAti_36, LAti_4));
         for(GAtd_532 = MathMin(GAtd_532, iLow(NULL, LAti_36, LAti_4)); LAti_12 && iLow(NULL, LAti_36, LAti_4) <= GAtd_500 - LAtd_24; GAtd_532 = EMPTY_VALUE)
           {
            GAtd_492 -= LAtd_24;
            GAtd_500 -= LAtd_24;
            GAtd_508 = GAtd_500;
            if(GAti_432 > 0)
               GAti_432 = -1;
            else
               GAti_432--;
            f0_20(GAtd_492, GAtd_500, MathMax(GAtd_524, GAtd_492), GAtd_500);
            GAtd_524 = 0;
           }
         while(iHigh(NULL, LAti_36, LAti_4) >= GAtd_492 + LAtd_24)
           {
            GAtd_492 += LAtd_24;
            GAtd_500 += LAtd_24;
            GAtd_508 = GAtd_492;
            if(GAti_432 < 0)
               GAti_432 = 1;
            else
               GAti_432++;
            f0_20(GAtd_500, MathMin(GAtd_532, GAtd_500), GAtd_492, GAtd_492);
            GAtd_524 = 0;
            GAtd_532 = EMPTY_VALUE;
           }
         while(!LAti_12 && iLow(NULL, LAti_36, LAti_4) < GAtd_500 - LAtd_24)
           {
            GAtd_492 -= LAtd_24;
            GAtd_500 -= LAtd_24;
            GAtd_508 = GAtd_500;
            if(GAti_432 > 0)
               GAti_432 = -1;
            else
               GAti_432--;
            f0_20(GAtd_492, GAtd_500, MathMax(GAtd_524, GAtd_492), GAtd_500);
            GAtd_524 = 0;
            GAtd_532 = EMPTY_VALUE;
           }
        }
     }
   if(GAti_432 != 0)
     {
      GAtd_524 = MathMax(GAtd_524, Bid);
      if(Bid > 0.0)
         GAtd_532 = MathMin(GAtd_532, Bid);
      if(Bid >= GAtd_492 + LAtd_24)
        {
         GAtd_492 += LAtd_24;
         GAtd_500 += LAtd_24;
         GAtd_508 = GAtd_492;
         if(GAti_432 < 0)
            GAti_432 = 1;
         else
            GAti_432++;
         f0_20(GAtd_500, MathMin(GAtd_532, GAtd_500), MathMax(GAtd_524, GAtd_492), GAtd_492);
         GAtd_524 = 0;
         GAtd_532 = EMPTY_VALUE;
        }
      if(Bid <= GAtd_500 - LAtd_24)
        {
         GAtd_492 -= LAtd_24;
         GAtd_500 -= LAtd_24;
         GAtd_508 = GAtd_500;
         if(GAti_432 > 0)
            GAti_432 = -1;
         else
            GAti_432--;
         f0_20(GAtd_492, MathMin(GAtd_532, GAtd_500), MathMax(GAtd_524, GAtd_492), GAtd_500);
         GAtd_524 = 0;
         GAtd_532 = EMPTY_VALUE;
        }
     }
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FUN_03(int Ai_0)
  {
   double Ld_4 = 0;
   if(OrdersTotal() > 0)
     {
      for(int Li_12 = OrdersTotal() - 1; Li_12 >= 0; Li_12--)
        {
         if(OrderSelect(Li_12, SELECT_BY_POS, MODE_TRADES) == TRUE)
           {
            if(OrderSymbol() == Symbol())
              {
               if(OrderMagicNumber() == Magic)
                 {
                  if(OrderType() == Ai_0)
                    {
                     Ld_4 = OrderOpenPrice() - OrderTakeProfit();
                     break;
                    }
                 }
              }
           }
        }
     }
   return (MathAbs(Ld_4) / Point);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FUN_02(int Ai_0)
  {
   double Ld_4 = 0;
   if(OrdersTotal() > 0)
     {
      for(int Li_12 = OrdersTotal() - 1; Li_12 >= 0; Li_12--)
        {
         if(OrderSelect(Li_12, SELECT_BY_POS, MODE_TRADES) == TRUE)
           {
            if(OrderSymbol() == Symbol())
              {
               if(OrderMagicNumber() == Magic)
                 {
                  if(OrderType() == Ai_0)
                    {
                     Ld_4 = OrderLots() ;
                     break;
                    }
                 }
              }
           }
        }
     }
   return (Ld_4) ;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FUN_01(int Ai_0)
  {
   double Ld_4 = 0;
   if(OrdersTotal() > 0)
     {
      for(int Li_12 = OrdersTotal() - 1; Li_12 >= 0; Li_12--)
        {
         if(OrderSelect(Li_12, SELECT_BY_POS, MODE_TRADES) == TRUE)
           {
            if(OrderSymbol() == Symbol())
              {
               if(OrderMagicNumber() == Magic)
                 {
                  if(OrderType() == Ai_0)
                    {
                     Ld_4 = OrderOpenPrice() - OrderStopLoss();
                     break;
                    }
                 }
              }
           }
        }
     }
   return (MathAbs(Ld_4) / Point);
  }
double Gd_128;
double Gd_136;
double Gd_144;
double Gd_152;
void FUN_057()
  {
   double Ld_0 = MarketInfo(Symbol(), MODE_TICKVALUE);
   Gd_152 = FUN_03(OP_SELLSTOP) * Ld_0 *FUN_02(OP_SELLSTOP);
   Gd_144 = FUN_03(OP_BUYSTOP) * Ld_0  *FUN_02(OP_SELLSTOP);



   double Ld_8 = FUN_03(OP_BUY) *FUN_02(0);
   double Ld_16 = FUN_03(OP_SELL) *FUN_02(1);
   Gd_128 = 0;
   if(Ld_8 > 0.0)
      Gd_128 = Ld_8;
   if(Ld_16 > 0.0)
      Gd_128 = Ld_16;
   Gd_136 = 0;
   double Ld_24 = FUN_01(OP_BUY) *FUN_02(0);
   double Ld_32 = FUN_01(OP_SELL) *FUN_02(1);
   if(Ld_24 > 0.0)
      Gd_136 = Ld_24;
   if(Ld_32 > 0.0)
      Gd_136 = Ld_32;

  }


// F9E83B3083AF1D7937605C28B81BDBD8
void f0_20(double AAtd_0, double AAtd_8, double AAtd_16, double AAtd_24)
  {
   for(int LAti_32 = GAti_284; LAti_32 > 1; LAti_32--)
     {
      GAtda_436[LAti_32] = GAtda_436[LAti_32 - 1];
      GAtda_440[LAti_32] = GAtda_440[LAti_32 - 1];
      GAtda_444[LAti_32] = GAtda_444[LAti_32 - 1];
      GAtda_448[LAti_32] = GAtda_448[LAti_32 - 1];
     }
   GAtda_436[1] = AAtd_0;
   GAtda_440[1] = AAtd_8;
   GAtda_444[1] = AAtd_16;
   GAtda_448[1] = AAtd_24;
  }

// 504C5A3EFB0D378E8B3D02932D57309D
void f0_4()
  {
   int LAti_8;
   int LAti_12;
   double LAtd_16;
   int LAti_32;
   int LAti_36;
   double LAtd_24 = f0_11(GAti_120 * GAtd_216);
   if(GAti_472 == 0)
     {
      LAti_32 = 10;
      if(iBars(NULL, PERIOD_M1) > 0)
         LAti_36 = 1;
      else
        {
         if(iBars(NULL, Period()) > 0)
            LAti_36 = Period();
         else
            LAti_36 = 0;
        }
      if(LAti_36 > 0)
        {
         for(int LAti_4 = 2; LAti_4 < MathMin(10000, iBars(NULL, LAti_36)); LAti_4++)
           {
            LAti_8 = LAti_4;
            if(MathAbs(iClose(NULL, LAti_36, LAti_4) - iClose(NULL, LAti_36, 1)) > LAti_32 * LAtd_24)
               break;
           }
         LAtd_16 = GAti_200 * GAtd_216;
         GAtd_556 = LAtd_16 + MathFloor((iClose(NULL, LAti_36, LAti_8) - LAtd_16) / LAtd_24) * LAtd_24;
        }
      else
        {
         LAti_8 = 0;
         LAtd_16 = GAti_200 * GAtd_216;
         GAtd_556 = LAtd_16 + MathFloor((Close[0] - LAtd_16) / LAtd_24) * LAtd_24;
        }
      GAtd_540 = GAtd_556;
      GAtd_548 = GAtd_556 - LAtd_24;
      GAtd_572 = GAtd_540;
      GAtd_580 = GAtd_548;
      GAti_472 = 1;
      for(LAti_4 = LAti_8 - 1; LAti_4 >= 1; LAti_4--)
        {
         LAti_12 = iHigh(NULL, LAti_36, LAti_4) + iLow(NULL, LAti_36, LAti_4) > iHigh(NULL, LAti_36, LAti_4 + 1) + iLow(NULL, LAti_36, LAti_4 + 1);
         GAtd_572 = MathMax(GAtd_572, iHigh(NULL, LAti_36, LAti_4));
         for(GAtd_580 = MathMin(GAtd_580, iLow(NULL, LAti_36, LAti_4)); LAti_12 && iLow(NULL, LAti_36, LAti_4) <= GAtd_548 - LAtd_24; GAtd_580 = EMPTY_VALUE)
           {
            GAtd_540 -= LAtd_24;
            GAtd_548 -= LAtd_24;
            GAtd_556 = GAtd_548;
            if(GAti_472 > 0)
               GAti_472 = -1;
            else
               GAti_472--;
            f0_6(GAtd_540, GAtd_548, MathMax(GAtd_572, GAtd_540), GAtd_548);
            GAtd_572 = 0;
           }
         while(iHigh(NULL, LAti_36, LAti_4) >= GAtd_540 + LAtd_24)
           {
            GAtd_540 += LAtd_24;
            GAtd_548 += LAtd_24;
            GAtd_556 = GAtd_540;
            if(GAti_472 < 0)
               GAti_472 = 1;
            else
               GAti_472++;
            f0_6(GAtd_548, MathMin(GAtd_580, GAtd_548), GAtd_540, GAtd_540);
            GAtd_572 = 0;
            GAtd_580 = EMPTY_VALUE;
           }
         while(!LAti_12 && iLow(NULL, LAti_36, LAti_4) < GAtd_548 - LAtd_24)
           {
            GAtd_540 -= LAtd_24;
            GAtd_548 -= LAtd_24;
            GAtd_556 = GAtd_548;
            if(GAti_472 > 0)
               GAti_472 = -1;
            else
               GAti_472--;
            f0_6(GAtd_540, GAtd_548, MathMax(GAtd_572, GAtd_540), GAtd_548);
            GAtd_572 = 0;
            GAtd_580 = EMPTY_VALUE;
           }
        }
     }
   if(GAti_472 != 0)
     {
      GAtd_572 = MathMax(GAtd_572, Bid);
      if(Bid > 0.0)
         GAtd_580 = MathMin(GAtd_580, Bid);
      if(Bid >= GAtd_540 + LAtd_24)
        {
         GAtd_540 += LAtd_24;
         GAtd_548 += LAtd_24;
         GAtd_556 = GAtd_540;
         if(GAti_472 < 0)
            GAti_472 = 1;
         else
            GAti_472++;
         f0_6(GAtd_548, MathMin(GAtd_580, GAtd_548), MathMax(GAtd_572, GAtd_540), GAtd_540);
         GAtd_572 = 0;
         GAtd_580 = EMPTY_VALUE;
        }
      if(Bid <= GAtd_548 - LAtd_24)
        {
         GAtd_540 -= LAtd_24;
         GAtd_548 -= LAtd_24;
         GAtd_556 = GAtd_548;
         if(GAti_472 > 0)
            GAti_472 = -1;
         else
            GAti_472--;
         f0_6(GAtd_540, MathMin(GAtd_580, GAtd_548), MathMax(GAtd_572, GAtd_540), GAtd_548);
         GAtd_572 = 0;
         GAtd_580 = EMPTY_VALUE;
        }
     }
  }

// 85EE0C3510848C3246359607036DD72B
void f0_6(double AAtd_0, double AAtd_8, double AAtd_16, double AAtd_24)
  {
   for(int LAti_32 = GAti_284; LAti_32 > 1; LAti_32--)
     {
      GAtda_476[LAti_32] = GAtda_476[LAti_32 - 1];
      GAtda_480[LAti_32] = GAtda_480[LAti_32 - 1];
      GAtda_484[LAti_32] = GAtda_484[LAti_32 - 1];
      GAtda_488[LAti_32] = GAtda_488[LAti_32 - 1];
     }
   GAtda_476[1] = AAtd_0;
   GAtda_480[1] = AAtd_8;
   GAtda_484[1] = AAtd_16;
   GAtda_488[1] = AAtd_24;
  }

// 9A116C50D133C8648404081885194300
double f0_11(double AAtd_0)
  {
   return (NormalizeDouble(AAtd_0, Digits));
  }

// EEDBD2A99CB21CBC10CEFA7B83FC612E
int f0_18()
  {
   int LAti_0 = GetLastError();
   Print("ERROR (" + LAti_0 + ") : " + f0_14(LAti_0));
   if(LAti_0 == 130/* INVALID_STOPS */ || LAti_0 == 129/* INVALID_PRICE */ || LAti_0 == 138/* REQUOTE */ || LAti_0 == 135/* PRICE_CHANGED */ || LAti_0 == 136/* OFF_QUOTES */)
     {
      RefreshRates();
      return (1);
     }
   if(LAti_0 == 146/* TRADE_CONTEXT_BUSY */ || LAti_0 == 133/* TRADE_DISABLED */ || LAti_0 == 128/* TRADE_TIMEOUT */ || LAti_0 == 139/* ORDER_LOCKED */)
     {
      Sleep(500);
      RefreshRates();
      return (1);
     }
   if(LAti_0 == 4/* SERVER_BUSY */ || LAti_0 == 137/* BROKER_BUSY */ || LAti_0 == 4022/* SYSTEM_BUSY */ || LAti_0 == 6/* NO_CONNECTION */ || LAti_0 == 141/* TOO_MANY_REQUESTS */ ||
      LAti_0 == 8/* TOO_FREQUENT_REQUESTS */)
     {
      Sleep(1500);
      RefreshRates();
      return (1);
     }
   if(LAti_0 == 147/* TRADE_EXPIRATION_DENIED */)
     {
      RefreshRates();
      return (1);
     }
   if(LAti_0 != 0/* NO_ERROR */)
     {
      Sleep(500);
      RefreshRates();
      return (0);
     }
   return (0);
  }

// CB5E100E5A9A3E7F6D1FD97512215282
string f0_14(int AAti_0)
  {
   string LAts_4="";

   return (LAts_4);
  }

// 963BAFD8C4CF009592882A613846771D
int f0_8(string AAts_0)
  {
   GAts_588 = GAts_588 + AAts_0;
   return (0);
  }

// 99B383A8F835928E50FC37F724D5B33C
int f0_10()
  {
   int LAti_0;
   string LAts_24;
   int LAti_32;
   if(GAti_644)
      LAti_0 = WindowFind("Empty");
   else
      LAti_0 = 0;
   if(LAti_0 < 0)
      return (0);
   int LAti_4 = 0;
   int LAti_8 = 0;
   int LAti_12 = 0;
   string LAts_16 = "";
   while(LAti_8 < StringLen(GAts_588))
     {
      LAti_12 = StringFind(GAts_588,
                           "\n", LAti_8);
      if(LAti_12 < 0)
         LAti_12 = StringLen(GAts_588);
      LAts_16 = StringSubstr(GAts_588, LAti_8, LAti_12 - LAti_8);
      LAti_8 = LAti_12 + 1;
      LAts_24 = GAts_596 + DoubleToStr(LAti_4, 0);
      LAti_32 = GAti_624 + comment_lineheight * LAti_4;
      ObjectCreate(LAts_24, OBJ_LABEL, LAti_0, 0, 0, 0, 0);
      ObjectSet(LAts_24, OBJPROP_CORNER, GAti_604);
      if(LAti_4 < GAti_636 + GAti_640 || (!GAti_644))
        {
         ObjectSet(LAts_24, OBJPROP_XDISTANCE, GAti_620);
         ObjectSet(LAts_24, OBJPROP_YDISTANCE, LAti_32);
        }
      else
        {
         ObjectSet(LAts_24, OBJPROP_XDISTANCE, GAti_620 + GAti_632);
         ObjectSet(LAts_24, OBJPROP_YDISTANCE, LAti_32 - GAti_640 * comment_lineheight);
        }
      ObjectSetText(LAts_24, LAts_16, comment_fontsize, GAts_tahoma_612, comment_color);
      LAti_4++;
     }
   for(LAts_24 = GAts_596 + DoubleToStr(LAti_4, 0); ObjectFind(LAts_24) >= 0; LAts_24 = GAts_596 + DoubleToStr(LAti_4, 0))
     {
      ObjectDelete(LAts_24);
      LAti_4++;
     }
   Comment("");
   return (0);
  }

// 8436DB92B06E487F61E5CCFC62B4CCAB
int f0_5()
  {
   GAts_588 = "";
   return (0);
  }


//+------------------------------------------------------------------+
void FUN_06(string Name,double price,color Colour,int Width,int Style)
  {

   if(DrawLines==0)
     {
      ObjectDelete("Q_S_1");
      ObjectDelete("Q_S_2");
      return;
     }
   ObjectCreate(0,Name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,Name,OBJPROP_COLOR,Colour);
   ObjectSetInteger(0,Name,OBJPROP_WIDTH,Width);
   ObjectSetInteger(0,Name,OBJPROP_STYLE,Style);
   if(price>0)
      ObjectMove(0,Name,0,0,price);
  }

//+------------------------------------------------------------------+
double FUN_04()
  {
   double Mq4_LastOpenPrice=0;
   if(OrdersTotal()>0)
      for(int ix=OrdersTotal()-1; ix>=0; ix--)
         if(OrderSelect(ix,SELECT_BY_POS,MODE_TRADES)==true)
            if(OrderSymbol()==Symbol())
               if(OrderMagicNumber()==Magic)

                  if(OrderType()==0||OrderType()==OP_BUYSTOP)
                    {
                     Mq4_LastOpenPrice=OrderOpenPrice();
                     break;
                    }

   return(Mq4_LastOpenPrice);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FUN_05()
  {
   double Mq4_LastOpenPrice=0;
   if(OrdersTotal()>0)
      for(int ix=OrdersTotal()-1; ix>=0; ix--)
         if(OrderSelect(ix,SELECT_BY_POS,MODE_TRADES)==true)
            if(OrderSymbol()==Symbol())
               if(OrderMagicNumber()==Magic)

                  if(OrderType()==1||OrderType()==OP_SELLSTOP)
                    {
                     Mq4_LastOpenPrice=OrderOpenPrice();
                     break;
                    }

   return(Mq4_LastOpenPrice);
  }

// BE416A2A6351C5184C700F7A59248C17
void f0_13()
  {

   FUN_06("Q_S_1", FUN_04(),  ColorUp,1,2);
   FUN_06("Q_S_2", FUN_05(),  ColorLo,1,2);

   string LAts_0 = "a" + GAts_76 + "Box";
   if(ObjectFind(LAts_0) < 0)
     {
      ObjectCreate(LAts_0, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(LAts_0, "g", 185, "Webdings", box_color);
      ObjectSet(LAts_0, OBJPROP_XDISTANCE, 5);
      ObjectSet(LAts_0, OBJPROP_YDISTANCE, 25);
      ObjectSet(LAts_0, OBJPROP_CORNER, GAti_604);
     }
   LAts_0 = "a" + GAts_76 + "Box2";
   if(ObjectFind(LAts_0) < 0)
     {
      ObjectCreate(LAts_0, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(LAts_0, "g", 185, "Webdings", box_color);
      ObjectSet(LAts_0, OBJPROP_XDISTANCE, 5);
      ObjectSet(LAts_0, OBJPROP_YDISTANCE, 205);
      ObjectSet(LAts_0, OBJPROP_CORNER, GAti_604);
     }
   f0_5();
   f0_8(GAts_76
        + "\n");
   f0_8("Freeware ?ARGOLab \n");
   f0_8("Set: " + SETname
        + "\n");
   f0_8(" \n");
   if(Flag_Stop)
     {
      f0_8("Flag_Stop is set \n");
      f0_8(" \n");
     }
   f0_8("LastMax: " + f0_1(GAtd_288)
        + "\n");
   f0_8("LastMin: " + f0_1(GAtd_296)
        + "\n");
   f0_8(" \n");
   f0_8("Next lot " + f0_17(GAtd_368)
        + "\n");
   f0_8(" \n");
   if(GAti_392>0)
      f0_8("Orders pending buy =  " + GAti_392
           + "\n");
   if(GAti_396>0)
      f0_8("Orders pending sell = " + GAti_396
           + "\n");
   f0_8(" \n");
   if(GAti_156)
     {
      f0_8("Orders DD = " + GAti_312
           + "\n");
      f0_8("Closed DD = " + f0_17(GAtd_320)
           + "\n");
     }


   FUN_057();
   f0_8(" \n");
   f0_8("Potential PR(market) = "+DoubleToStr(Gd_128,2)+"\n");

   f0_8("Potential DD(market) = "+DoubleToStr(Gd_136,2)+"\n");

   f0_8("Potential PR(buy,pe) = "+DoubleToStr(Gd_144,2)+"\n");

   f0_8("Potential PR(sell,pe)= "+DoubleToStr(Gd_152,2)+"\n");

   f0_10();
  }
//+------------------------------------------------------------------+
