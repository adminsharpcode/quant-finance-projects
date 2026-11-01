
#include <stdlib.mqh>

extern string P1 = " This EA Version is AUTHENTICATED ";
extern string P2 = " --- Trading Parameters --- ";
extern string P3 = "RISK LEVEL (1=LOW recommendet, 2=MODERATE, 3=HIGH)";
extern int iRiskLevel = 2;
extern string P4 = "Please use the ea only on this pairs:";
extern string P5 = "AUDCAD, AUDJPY, AUDNZD, AUDUSD,CADJPY, CHFJPY, EURAUD, EURCAD, EURCHF,";
extern string P6 = "EURGBP, EURJPY, EURUSD, GBPCHF, GBPJPY, GBPUSD, NZDJPY, NZDUSD, USDCAD, USDCHF, USDJPY";
bool gi_128 = FALSE;
double gd_132;
bool gi_140 = TRUE;
double gd_144;
int gi_152 = 30;
int gi_156 = 60;
string gs_unused_160 = "---------------- MACD SETTINGS----------------------";
int gi_168 = 30;
int gi_172 = 78;
int gi_176 = 1;
double gd_180;
double gd_188;
double gd_196;
int gi_204 = 1;
int gi_208 = 30;
int gi_212 = 60;
string gs_unused_216 = "------------SmaAngle Settings---------------";
bool gi_unused_224 = FALSE;
double gd_unused_228 = 50.0;
double gd_unused_236 = 0.25;
double gd_244 = 99.0;
double gd_252 = 100.0;
int gi_260 = 6;
bool gi_264 = TRUE;
bool gi_268 = TRUE;
extern bool HedgingAllowed = TRUE;
bool gi_276 = TRUE;
double gd_280 = 48.0;
bool gi_288 = FALSE;
string gs_unused_292 = "Martingale Settings";
int gi_300 = 20;
bool gi_304 = FALSE;
bool gi_308 = FALSE;
double g_period_312;
double g_period_320;
double g_period_328;
string gs_unused_336 = "StopLoss Settings";
bool gi_344 = FALSE;
int gi_348 = 20;
bool gi_352 = FALSE;
int gi_356 = 10;
string gs_unused_360 = "StopLossMa";
double g_period_368 = 33.0;
double g_ma_method_376 = 1.0;
string gs_unused_384 = "///////////////////////////////";
bool gi_392 = TRUE;
bool gi_396 = TRUE;
int gi_400 = 400;
string gs_unused_404 = "///////////////////////////////";
bool gi_412 = FALSE;
int gi_416 = 400;
int gi_420;
int gi_424;
int gi_428;
int gi_432;
bool gi_436;
double gda_440[25];
double gda_444[25];
double gd_448;
double gd_456;
double gd_unused_464;
double gd_unused_472;
double g_ord_open_price_480;
double g_ord_open_price_488;
double gd_496;
double gd_504;
int gi_512;
int gi_516;
int gi_unused_520 = 0;
int g_bars_524 = -1;
bool gi_528 = FALSE;
int gi_532 = 100;
string gs_536 = "";
int gi_unused_544 = 5;
int gi_548 = 0;
int gi_552;
int gi_556 = 9000;
int gi_unused_560;
double gd_564;
double gd_572;
double gd_580;
double gd_588;
double gd_596;
double gd_604;
bool gi_612;
bool gi_616;
int g_shift_620;
bool gi_624 = FALSE;
string gs_unused_628 = "SlowMa";
double g_ma_method_636 = 0.0;
double g_applied_price_644 = 0.0;
double gd_652 = 0.0;
double g_timeframe_660 = 0.0;
string gs_unused_668 = "///////////////////////////";
string gs_unused_676 = "MediumMa";
double g_ma_method_684 = 1.0;
double g_applied_price_692 = 0.0;
double gd_700 = 0.0;
double g_timeframe_708 = 0.0;
string gs_unused_716 = "///////////////////////////";
string gs_unused_724 = "FastMa";
double g_ma_method_732 = 1.0;
double g_applied_price_740 = 0.0;
double gd_748 = 0.0;
double g_timeframe_756 = 0.0;
string gs_unused_764 = "///////////////////////////";
double g_applied_price_772 = 0.0;
double gd_780 = 0.0;
double g_timeframe_788 = 0.0;
double g_iclose_796;
double gd_804;
double gd_812;
int gi_820 = 0;
bool gi_824 = FALSE;
int gi_unused_828 = 3;
string gs_unused_832 = "N/A";
string gs_unused_840 = "v.21";
string gs_unused_848 = "     ";
string gs_unused_856 = "          ";
string gs_unused_864 = "               ";
string gs_unused_872 = "                    ";
string gs_unused_880 = "                         ";
string gs_unused_888 = "                              ";
string gs_unused_896 = "                                   ";
string gs_unused_904 = "                                        ";
string gs_unused_912 = "                                             ";
string gs_unused_920 = "                                                  ";
bool gi_unused_928 = FALSE;
bool gi_unused_932 = FALSE;
int g_count_936;
int g_count_940;
double gda_unused_944[10];
double gda_unused_948[10];
double gda_952[10] = {4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0};
int gi_unused_956 = 100;
int gi_unused_960 = 0;
int gi_unused_964 = 5;
int gi_unused_968 = 120;
bool gi_unused_972 = FALSE;
int gi_unused_976 = 0;
int gi_unused_980 = 3;
double gd_unused_984 = 0.02;
double gd_unused_992 = 0.2;
int gi_unused_1000 = 0;
int gi_unused_1004 = 34;
int gi_unused_1008 = 0;
int gi_unused_1012 = 0;
int gi_unused_1016 = 0;
int gi_unused_1020 = 0;
int gi_unused_1024 = 9;
double gd_unused_1028 = 0.3;
int gi_unused_1036 = 0;
int gi_unused_1040 = 5;
int gi_unused_1044 = 1;
bool gi_unused_1048 = FALSE;
string gs_1052 = "v3.1";
string gs_1060 = "OrderReliable fname unset";
int gi_1068 = 10;
double gd_1072 = 8.0;
double gd_1080 = 25.0;
int gi_1088 = 3;
bool gi_1092 = FALSE;
bool gi_1096 = FALSE;

void f0_37(int ai_0) {
   gi_unused_828 = ai_0;
}

int f0_3(string as_0) {
   string ls_8 = StringSubstr(as_0, 0, 6);
   if (ls_8 == "AUDCAD") return (1);
   if (ls_8 == "AUDJPY") return (2);
   if (ls_8 == "AUDNZD") return (3);
   if (ls_8 == "AUDUSD") return (4);
   if (ls_8 == "CADJPY") return (5);
   if (ls_8 == "CHFJPY") return (6);
   if (ls_8 == "EURAUD") return (7);
   if (ls_8 == "EURCAD") return (8);
   if (ls_8 == "EURCHF") return (9);
   if (ls_8 == "EURGBP") return (10);
   if (ls_8 == "EURJPY") return (11);
   if (ls_8 == "EURUSD") return (12);
   if (ls_8 == "GBPCHF") return (13);
   if (ls_8 == "GBPJPY") return (14);
   if (ls_8 == "GBPUSD") return (15);
   if (ls_8 == "NZDJPY") return (16);
   if (ls_8 == "NZDUSD") return (17);
   if (ls_8 == "USDCAD") return (18);
   if (ls_8 == "USDCHF") return (19);
   if (ls_8 == "USDJPY") return (20);
   return (21);
}

int f0_36(int ai_0) {
   switch (ai_0) {
   case 1:
      return (1);
   case 5:
      return (2);
   case 15:
      return (3);
   case 30:
      return (4);
   case 60:
      return (5);
   case 240:
      return (6);
   case 1440:
      return (7);
   case 10080:
      return (8);
   case 43200:
      return (9);
   }
   return (0);
}

double f0_2() {
   double l_ticksize_0 = MarketInfo(Symbol(), MODE_TICKSIZE);
   return (f0_21(l_ticksize_0));
}

double f0_21(double ad_0) {
   if (ad_0 == 0.00001 || ad_0 == 0.001) ad_0 = 10.0 * ad_0;
   return (ad_0);
}

int f0_29(int ai_0, int ai_4) {
   gs_unused_832 = "NumOpenPositionsThisPair";
   f0_13(ai_0);
   if (ai_4 == -1) return (g_count_936 + g_count_940);
   if (ai_4 == 0) return (g_count_936);
   if (ai_4 == 1) return (g_count_940);
   return (0);
}

int f0_13(int a_magic_0) {
   gs_unused_832 = "CountOpenOrdersThisPair";
   g_count_936 = 0;
   g_count_940 = 0;
   for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--) {
      OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != a_magic_0 && a_magic_0 != 0) continue;
      if (OrderType() == OP_BUY) g_count_936++;
      else
         if (OrderType() == OP_SELL) g_count_940++;
   }
   if (g_count_936 == 0 && g_count_940 == 0) return (-1);
   if (g_count_936 > 0 && g_count_940 == 0) return (0);
   if (g_count_940 > 0 && g_count_936 == 0) return (1);
   return (g_count_936 + g_count_940);
}

int f0_18(string a_symbol_0, int a_cmd_8, double a_lots_12, double a_price_20, int a_slippage_28, double a_price_32, double a_price_40, string a_comment_48, int a_magic_56, int a_datetime_60 = 0, color a_color_64 = -1) {
   int l_digits_68;
   double ld_72;
   double ld_80;
   double ld_88;
   double l_ord_stoploss_96;
   double l_ord_takeprofit_104;
   int l_count_112;
   double ld_116;
   double l_price_124;
   int l_ticket_132 = -1;
   if (!gi_1096) {
      if (IsOptimization() || IsTesting()) {
         l_ticket_132 = OrderSend(a_symbol_0, a_cmd_8, a_lots_12, a_price_20, a_slippage_28, a_price_32, a_price_40, a_comment_48, a_magic_56, a_datetime_60, Black);
         return (l_ticket_132);
      }
   }
   gs_1060 = "OrderSendReliable";
   f0_8("");
   f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   f0_8("Attempted " + f0_40(a_cmd_8) + " " + a_lots_12 + " lots @" + a_price_20 + " sl:" + a_price_32 + " tp:" + a_price_40);
   double l_point_136 = MarketInfo(a_symbol_0, MODE_POINT);
   f0_10(0, a_symbol_0, a_cmd_8, l_digits_68, ld_72, l_ord_stoploss_96, l_ord_takeprofit_104, ld_80, ld_88, 0);
   a_price_20 = NormalizeDouble(a_price_20, l_digits_68);
   a_price_32 = NormalizeDouble(a_price_32, l_digits_68);
   a_price_40 = NormalizeDouble(a_price_40, l_digits_68);
   f0_44(a_symbol_0, a_cmd_8, a_price_20, a_price_32, a_price_40);
   int l_error_144 = GetLastError();
   l_error_144 = 0;
   bool li_148 = FALSE;
   bool li_152 = FALSE;
   bool li_156 = FALSE;
   if (a_cmd_8 == OP_BUYSTOP || a_cmd_8 == OP_SELLSTOP || a_cmd_8 == OP_BUYLIMIT || a_cmd_8 == OP_SELLLIMIT) {
      l_count_112 = 0;
      while (!li_148) {
         l_ticket_132 = OrderSend(a_symbol_0, a_cmd_8, a_lots_12, a_price_20, a_slippage_28, a_price_32, a_price_40, a_comment_48, a_magic_56, a_datetime_60, a_color_64);
         l_error_144 = GetLastError();
         switch (l_error_144) {
         case 0/* NO_ERROR */:
            li_148 = TRUE;
            break;
         case 4/* SERVER_BUSY */:
         case 6/* NO_CONNECTION */:
         case 136/* OFF_QUOTES */:
         case 137/* BROKER_BUSY */:
         case 146/* TRADE_CONTEXT_BUSY */:
         case 128/* TRADE_TIMEOUT */:
            l_count_112++;
            break;
         case 135/* PRICE_CHANGED */:
         case 138/* REQUOTE */:
            RefreshRates();
            continue;
            break;
         case 129/* INVALID_PRICE */:
         case 130/* INVALID_STOPS */:
            l_count_112++;
            ld_116 = MarketInfo(a_symbol_0, MODE_STOPLEVEL) * l_point_136;
            if (a_cmd_8 == OP_BUYSTOP || a_cmd_8 == OP_BUYLIMIT) {
               if (MathAbs(ld_88 - a_price_20) <= ld_116) {
                  if (gi_1092) {
                     li_152 = TRUE;
                     li_148 = TRUE;
                  } else {
                     if (li_156) {
                        if (a_cmd_8 == OP_BUYSTOP) {
                           a_price_20 += ld_72;
                           if (a_price_32 > 0.0) a_price_32 += ld_72;
                           if (a_price_40 > 0.0) a_price_40 += ld_72;
                           f0_8("Pending BuyStop Order still has ERR_INVALID_STOPS, adding 1 pip; new price = " + DoubleToStr(a_price_20, l_digits_68));
                           if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                        } else {
                           if (a_cmd_8 == OP_BUYLIMIT) {
                              a_price_20 -= ld_72;
                              if (a_price_32 > 0.0) a_price_32 -= ld_72;
                              if (a_price_40 > 0.0) a_price_40 -= ld_72;
                              f0_8("Pending BuyLimit Order still has ERR_INVALID_STOPS, subtracting 1 pip; new price = " + DoubleToStr(a_price_20, l_digits_68));
                              if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                           }
                        }
                     } else {
                        if (a_cmd_8 == OP_BUYLIMIT) {
                           l_price_124 = a_price_20;
                           a_price_20 = ld_88 - ld_116;
                           if (a_price_32 > 0.0) a_price_32 += a_price_20 - l_price_124;
                           if (a_price_40 > 0.0) a_price_40 += a_price_20 - l_price_124;
                           f0_8("Pending BuyLimit has ERR_INVALID_STOPS; new price = " + DoubleToStr(a_price_20, l_digits_68));
                           if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                        } else {
                           if (a_cmd_8 == OP_BUYSTOP) {
                              l_price_124 = a_price_20;
                              a_price_20 = ld_88 + ld_116;
                              if (a_price_32 > 0.0) a_price_32 += a_price_20 - l_price_124;
                              if (a_price_40 > 0.0) a_price_40 += a_price_20 - l_price_124;
                              f0_8("Pending BuyStop has ERR_INVALID_STOPS; new price = " + DoubleToStr(a_price_20, l_digits_68));
                              if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                           }
                        }
                        li_156 = TRUE;
                     }
                     f0_44(a_symbol_0, a_cmd_8, a_price_20, a_price_32, a_price_40);
                  }
               }
            } else {
               if ((a_cmd_8 == OP_SELLSTOP || a_cmd_8 == OP_SELLLIMIT)) {
                  if (MathAbs(ld_80 - a_price_20) <= ld_116) {
                     if (gi_1092) {
                        li_152 = TRUE;
                        li_148 = TRUE;
                     } else {
                        if (li_156) {
                           if (a_cmd_8 == OP_SELLSTOP) {
                              a_price_20 -= ld_72;
                              if (a_price_32 > 0.0) a_price_32 -= ld_72;
                              if (a_price_40 > 0.0) a_price_40 -= ld_72;
                              f0_8("Pending SellStop Order still has ERR_INVALID_STOPS, subtracting 1 pip; new price = " + DoubleToStr(a_price_20, l_digits_68));
                              if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                           } else {
                              if (a_cmd_8 == OP_SELLLIMIT) {
                                 a_price_20 += ld_72;
                                 if (a_price_32 > 0.0) a_price_32 += ld_72;
                                 if (a_price_40 > 0.0) a_price_40 += ld_72;
                                 f0_8("Pending SellLimit Order still has ERR_INVALID_STOPS, adding 1 pip; new price = " + DoubleToStr(a_price_20, l_digits_68));
                                 if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                              }
                           }
                        } else {
                           if (a_cmd_8 == OP_SELLSTOP) {
                              l_price_124 = a_price_20;
                              a_price_20 = ld_80 - ld_116;
                              if (a_price_32 > 0.0) a_price_32 -= l_price_124 - a_price_20;
                              if (a_price_40 > 0.0) a_price_40 -= l_price_124 - a_price_20;
                              f0_8("Pending SellStop has ERR_INVALID_STOPS; new price = " + DoubleToStr(a_price_20, l_digits_68));
                              if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                           } else {
                              if (a_cmd_8 == OP_SELLLIMIT) {
                                 l_price_124 = a_price_20;
                                 a_price_20 = ld_80 + ld_116;
                                 if (a_price_32 > 0.0) a_price_32 -= l_price_124 - a_price_20;
                                 if (a_price_40 > 0.0) a_price_40 -= l_price_124 - a_price_20;
                                 f0_8("Pending SellLimit has ERR_INVALID_STOPS; new price = " + DoubleToStr(a_price_20, l_digits_68));
                                 if (a_price_32 > 0.0 || a_price_40 > 0.0) f0_8("NOTE: SL (now " + DoubleToStr(a_price_32, l_digits_68) + ") & TP (now " + DoubleToStr(a_price_40, l_digits_68) + ") were adjusted proportionately");
                              }
                           }
                           li_156 = TRUE;
                        }
                        f0_44(a_symbol_0, a_cmd_8, a_price_20, a_price_32, a_price_40);
                     }
                  }
               }
            }
            break;
         case 3/* INVALID_TRADE_PARAMETERS */:
         default:
            li_148 = TRUE;
         }
         if (l_count_112 > gi_1068) li_148 = TRUE;
         if (li_148) {
            if (l_error_144 != 0/* NO_ERROR */ && l_error_144 != 1/* NO_RESULT */) f0_8("Non-retryable error: " + f0_12(l_error_144));
            if (l_count_112 > gi_1068) f0_8("Retry attempts maxed at " + gi_1068);
         } else {
            f0_8("Result of attempt " + l_count_112 + " of " + gi_1068 + ": Retryable error: " + f0_12(l_error_144));
            f0_8("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            f0_32(gd_1072, gd_1080);
            RefreshRates();
         }
      }
      if (l_error_144 == 0/* NO_ERROR */ || l_error_144 == 1/* NO_RESULT */) {
         f0_8("Ticket #" + l_ticket_132 + ": Successful " + f0_40(a_cmd_8) + " order placed, details follow.");
         OrderSelect(l_ticket_132, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         f0_8("");
         return (l_ticket_132);
      }
      if (!li_152) {
         f0_8("Failed to execute stop or limit order after " + gi_1068 + " retries");
         f0_8("Failed trade: " + f0_40(a_cmd_8) + " " + DoubleToStr(a_lots_12, 2) + " lots  " + a_symbol_0 + "@" + a_price_20 + " tp@" + a_price_40 + " sl@" + a_price_32);
         f0_8("Last error: " + f0_12(l_error_144));
         f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         f0_8("");
         return (-1);
      }
   }
   if (li_152) {
      f0_8("Going from stop/limit order to market order because market is too close.");
      if (a_cmd_8 == OP_BUYSTOP || a_cmd_8 == OP_BUYLIMIT) {
         a_cmd_8 = 0;
         a_price_20 = ld_88;
      } else {
         if (a_cmd_8 == OP_SELLSTOP || a_cmd_8 == OP_SELLLIMIT) {
            a_cmd_8 = 1;
            a_price_20 = ld_80;
         }
      }
   }
   l_error_144 = GetLastError();
   l_error_144 = 0;
   l_ticket_132 = -1;
   li_148 = FALSE;
   if (a_cmd_8 == OP_BUY || a_cmd_8 == OP_SELL) {
      l_count_112 = 0;
      while (!li_148) {
         l_ticket_132 = OrderSend(a_symbol_0, a_cmd_8, a_lots_12, a_price_20, a_slippage_28, a_price_32, a_price_40, a_comment_48, a_magic_56, a_datetime_60, a_color_64);
         l_error_144 = GetLastError();
         switch (l_error_144) {
         case 0/* NO_ERROR */:
            li_148 = TRUE;
            break;
         case 4/* SERVER_BUSY */:
         case 6/* NO_CONNECTION */:
         case 129/* INVALID_PRICE */:
         case 136/* OFF_QUOTES */:
         case 137/* BROKER_BUSY */:
         case 146/* TRADE_CONTEXT_BUSY */:
         case 128/* TRADE_TIMEOUT */:
            l_count_112++;
            break;
         case 135/* PRICE_CHANGED */:
         case 138/* REQUOTE */:
            RefreshRates();
            continue;
            break;
         default:
            li_148 = TRUE;
         }
         if (l_count_112 > gi_1068) li_148 = TRUE;
         if (!li_148) {
            f0_8("Result of attempt " + l_count_112 + " of " + gi_1068 + ": Retryable error: " + f0_12(l_error_144));
            f0_8("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            f0_32(gd_1072, gd_1080);
            RefreshRates();
         } else {
            if (l_error_144 != 0/* NO_ERROR */ && l_error_144 != 1/* NO_RESULT */) f0_8("Non-retryable error: " + f0_12(l_error_144));
            if (l_count_112 > gi_1068) f0_8("Retry attempts maxed at " + gi_1068);
         }
      }
      if (l_error_144 == 0/* NO_ERROR */ || l_error_144 == 1/* NO_RESULT */) {
         f0_8("Ticket #" + l_ticket_132 + ": Successful " + f0_40(a_cmd_8) + " order placed, details follow.");
         OrderSelect(l_ticket_132, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         f0_8("");
         return (l_ticket_132);
      }
      f0_8("Failed to execute OP_BUY/OP_SELL, after " + gi_1068 + " retries");
      f0_8("Failed trade: " + f0_40(a_cmd_8) + " " + DoubleToStr(a_lots_12, 2) + " lots  " + a_symbol_0 + "@" + a_price_20 + " tp@" + a_price_40 + " sl@" + a_price_32);
      f0_8("Last error: " + f0_12(l_error_144));
      f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
      f0_8("");
      return (-1);
   }
   return (0);
}

int f0_30(string a_symbol_0, int a_cmd_8, double a_lots_12, double a_price_20, int a_slippage_28, double a_price_32, double a_price_40, string a_comment_48, int a_magic_56, int a_datetime_60 = 0, color a_color_64 = -1) {
   int l_digits_68;
   double ld_72;
   double ld_80;
   double ld_88;
   double l_ord_stoploss_96;
   double l_ord_takeprofit_104;
   int l_count_112;
   double l_price_116;
   int l_slippage_124;
   int l_error_140;
   int l_ticket_128 = -1;
   if (IsOptimization() || IsTesting()) {
      l_ticket_128 = OrderSend(a_symbol_0, a_cmd_8, a_lots_12, a_price_20, a_slippage_28, a_price_32, a_price_40, a_comment_48, a_magic_56, a_datetime_60, Black);
      return (l_ticket_128);
   }
   if (a_cmd_8 > OP_SELL) {
      l_ticket_128 = f0_18(a_symbol_0, a_cmd_8, a_lots_12, a_price_20, a_slippage_28, 0, 0, a_comment_48, a_magic_56, a_datetime_60, a_color_64);
      return (l_ticket_128);
   }
   gs_1060 = "OrderSendReliableMKT";
   f0_8("");
   f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   f0_8("Attempted " + f0_40(a_cmd_8) + " " + a_lots_12 + " lots @" + a_price_20 + " sl:" + a_price_32 + " tp:" + a_price_40);
   f0_10(0, a_symbol_0, a_cmd_8, l_digits_68, ld_72, l_ord_stoploss_96, l_ord_takeprofit_104, ld_80, ld_88, 0);
   a_price_20 = NormalizeDouble(a_price_20, l_digits_68);
   a_price_32 = NormalizeDouble(a_price_32, l_digits_68);
   a_price_40 = NormalizeDouble(a_price_40, l_digits_68);
   f0_44(a_symbol_0, a_cmd_8, a_price_20, a_price_32, a_price_40);
   int l_error_132 = GetLastError();
   l_error_132 = 0;
   bool li_136 = FALSE;
   if (a_cmd_8 == OP_BUY || a_cmd_8 == OP_SELL) {
      l_count_112 = 0;
      while (!li_136) {
         l_price_116 = a_price_20;
         l_slippage_124 = a_slippage_28;
         if (a_cmd_8 == OP_BUY) {
            l_price_116 = NormalizeDouble(MarketInfo(a_symbol_0, MODE_ASK), MarketInfo(a_symbol_0, MODE_DIGITS));
            if (l_price_116 > a_price_20) l_slippage_124 = a_slippage_28 - (l_price_116 - a_price_20) / ld_72;
         } else {
            if (a_cmd_8 == OP_SELL) {
               l_price_116 = NormalizeDouble(MarketInfo(a_symbol_0, MODE_BID), MarketInfo(a_symbol_0, MODE_DIGITS));
               if (l_price_116 < a_price_20) l_slippage_124 = a_slippage_28 - (a_price_20 - l_price_116) / ld_72;
            }
         }
         if (l_slippage_124 > a_slippage_28) l_slippage_124 = a_slippage_28;
         if (l_slippage_124 >= 0) {
            l_ticket_128 = OrderSend(a_symbol_0, a_cmd_8, a_lots_12, l_price_116, l_slippage_124, a_price_32, a_price_40, a_comment_48, a_magic_56, a_datetime_60, a_color_64);
            l_error_132 = GetLastError();
         } else l_error_132 = 129;
         l_error_140 = l_error_132;
         if (l_error_140 == 135/* PRICE_CHANGED */) continue;
         if (l_error_140 == 138/* REQUOTE */) continue;
         switch (l_error_140) {
         case 0/* NO_ERROR */:
            li_136 = TRUE;
            break;
         case 4/* SERVER_BUSY */:
         case 6/* NO_CONNECTION */:
         case 129/* INVALID_PRICE */:
         case 136/* OFF_QUOTES */:
         case 137/* BROKER_BUSY */:
         case 146/* TRADE_CONTEXT_BUSY */:
         case 128/* TRADE_TIMEOUT */:
            l_count_112++;
            break;
         default:
            li_136 = TRUE;
         }
         if (l_count_112 > gi_1068) li_136 = TRUE;
         if (!li_136) {
            f0_8("Result of attempt " + l_count_112 + " of " + gi_1068 + ": Retryable error: " + f0_12(l_error_132));
            f0_8("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            f0_32(gd_1072, gd_1080);
         } else {
            if (l_error_132 != 0/* NO_ERROR */ && l_error_132 != 1/* NO_RESULT */) f0_8("Non-retryable error: " + f0_12(l_error_132));
            if (l_count_112 > gi_1068) f0_8("Retry attempts maxed at " + gi_1068);
         }
      }
      if (l_error_132 == 0/* NO_ERROR */ || l_error_132 == 1/* NO_RESULT */) {
         f0_8("Ticket #" + l_ticket_128 + ": Successful " + f0_40(a_cmd_8) + " order placed, details follow.");
         OrderSelect(l_ticket_128, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         f0_8("");
         return (l_ticket_128);
      }
      f0_8("Failed to execute OP_BUY/OP_SELL, after " + gi_1068 + " retries");
      f0_8("Failed trade: " + f0_40(a_cmd_8) + " " + DoubleToStr(a_lots_12, 2) + " lots  " + a_symbol_0 + "@" + a_price_20 + " tp@" + a_price_40 + " sl@" + a_price_32);
      f0_8("Last error: " + f0_12(l_error_132));
      f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
      f0_8("");
      return (-1);
   }
   return (0);
}

int f0_7(int a_ticket_0, double a_price_4, double a_price_12, double a_price_20, int a_datetime_28, color a_color_32 = -1) {
   int l_cmd_36;
   int l_digits_40;
   double ld_44;
   double ld_52;
   double ld_60;
   double l_ord_stoploss_68;
   double l_ord_takeprofit_76;
   bool l_bool_84 = FALSE;
   bool li_88 = FALSE;
   if (!gi_1096) {
      if (IsOptimization() || IsTesting()) {
         l_bool_84 = OrderModify(a_ticket_0, a_price_4, a_price_12, a_price_20, a_datetime_28, Black);
         return (l_bool_84);
      }
   }
   gs_1060 = "OrderModifyReliable";
   f0_8("");
   f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   f0_8("Attempted modify of #" + a_ticket_0 + " price:" + a_price_4 + " sl:" + a_price_12 + " tp:" + a_price_20);
   string l_symbol_92 = "ALLOCATE";
   f0_10(a_ticket_0, l_symbol_92, l_cmd_36, l_digits_40, ld_44, l_ord_stoploss_68, l_ord_takeprofit_76, ld_52, ld_60);
   double l_price_100 = a_price_4;
   if (l_cmd_36 == OP_BUY) l_price_100 = ld_52;
   else
      if (l_cmd_36 == OP_SELL) l_price_100 = ld_60;
   l_price_100 = NormalizeDouble(l_price_100, l_digits_40);
   a_price_4 = NormalizeDouble(a_price_4, l_digits_40);
   a_price_12 = NormalizeDouble(a_price_12, l_digits_40);
   a_price_20 = NormalizeDouble(a_price_20, l_digits_40);
   double ld_108 = a_price_12;
   double ld_116 = a_price_20;
   if (a_price_12 == l_ord_stoploss_68) ld_108 = 0;
   if (a_price_20 == l_ord_takeprofit_76) ld_116 = 0;
   f0_44(l_symbol_92, l_cmd_36, l_price_100, ld_108, ld_116, 0);
   if (a_price_12 != l_ord_stoploss_68) a_price_12 = ld_108;
   if (a_price_20 != l_ord_takeprofit_76) a_price_20 = ld_116;
   int l_count_124 = 0;
   int l_error_128 = GetLastError();
   l_error_128 = 0;
   bool li_132 = FALSE;
   while (!li_132) {
      l_bool_84 = OrderModify(a_ticket_0, a_price_4, a_price_12, a_price_20, a_datetime_28, a_color_32);
      l_error_128 = GetLastError();
      if (l_bool_84 == TRUE) li_132 = TRUE;
      else {
         switch (l_error_128) {
         case 0/* NO_ERROR */:
            li_132 = TRUE;
            f0_8("ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;
         case 1/* NO_RESULT */:
            li_132 = TRUE;
            break;
         case 130/* INVALID_STOPS */:
            f0_8("OrderModifyReliable, ERR_INVALID_STOPS, should not happen; stops already adjusted");
         case 2/* COMMON_ERROR */:
         case 4/* SERVER_BUSY */:
         case 6/* NO_CONNECTION */:
         case 8/* TOO_FREQUENT_REQUESTS */:
         case 128/* TRADE_TIMEOUT */:
         case 129/* INVALID_PRICE */:
         case 136/* OFF_QUOTES */:
         case 137/* BROKER_BUSY */:
         case 141/* TOO_MANY_REQUESTS */:
         case 146/* TRADE_CONTEXT_BUSY */:
            l_count_124++;
            break;
         case 145/* TRADE_MODIFY_DENIED */: break;
         case 135/* PRICE_CHANGED */:
         case 138/* REQUOTE */:
            RefreshRates();
            continue;
            break;
         default:
            li_132 = TRUE;
            li_88 = TRUE;
         }
      }
      if (l_count_124 > gi_1068) li_132 = TRUE;
      if (!li_132) {
         f0_8("Result of attempt " + l_count_124 + " of " + gi_1068 + ": Retryable error: " + f0_12(l_error_128));
         f0_8("~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         f0_32(gd_1072, gd_1080);
         RefreshRates();
      } else {
         if (l_count_124 > gi_1068) f0_8("Retry attempts maxed at " + gi_1068);
         else
            if (li_88) f0_8("Non-retryable error: " + f0_12(l_error_128));
      }
   }
   if (l_error_128 == 1/* NO_RESULT */) {
      f0_8("Server reported modify order did not actually change parameters.");
      f0_8("Redundant modification: " + a_ticket_0 + " " + l_symbol_92 + "@" + a_price_4 + " tp@" + a_price_20 + " sl@" + a_price_12);
      f0_8("Suggest modifying code logic to avoid.");
   }
   if (l_bool_84) {
      f0_8("Ticket #" + a_ticket_0 + ": Modification successful, updated trade details follow.");
      OrderSelect(a_ticket_0, SELECT_BY_TICKET, MODE_TRADES);
      OrderPrint();
   } else {
      f0_8("Failed to execute modify after " + gi_1068 + " retries");
      f0_8("Failed modification: " + a_ticket_0 + " " + l_symbol_92 + "@" + a_price_4 + " tp@" + a_price_20 + " sl@" + a_price_12);
      f0_8("Last error: " + f0_12(l_error_128));
   }
   f0_8("•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   f0_8("");
   return (l_bool_84);
}

string f0_12(int ai_0) {
   return (ai_0 + "  ::  " + ErrorDescription(ai_0));
}

void f0_8(string as_0) {
   if (gi_1088 >= 99 || !(IsTesting() || IsOptimization()))
      if (gi_1088 > 0) Print(gs_1060 + " " + gs_1052 + ":     " + as_0);
}

string f0_40(int ai_0) {
   if (ai_0 == 0) return ("BUY");
   if (ai_0 == 1) return ("SELL");
   if (ai_0 == 4) return ("BUY STOP");
   if (ai_0 == 5) return ("SELL STOP");
   if (ai_0 == 2) return ("BUY LIMIT");
   if (ai_0 == 3) return ("SELL LIMIT");
   return ("None (" + ai_0 + ")");
}

void f0_44(string a_symbol_0, int ai_8, double ad_12, double &ad_20, double &ad_28, bool ai_36 = TRUE) {
   double ld_40;
   double ld_48;
   string ls_56 = gs_1060;
   gs_1060 = "EnsureValidStops";
   double l_point_64 = MarketInfo(a_symbol_0, MODE_POINT);
   double ld_72 = ad_20;
   double ld_80 = ad_28;
   int l_stoplevel_88 = MarketInfo(a_symbol_0, MODE_STOPLEVEL);
   double ld_92 = l_stoplevel_88 * l_point_64;
   double ld_100 = MarketInfo(a_symbol_0, MODE_ASK) - MarketInfo(a_symbol_0, MODE_BID);
   if (ad_20 != 0.0) {
      if (ai_8 % 2 == 0) {
         ld_40 = ad_12 - ld_92;
         if (ai_8 == 0 && ai_36) ld_40 -= ld_100;
         ad_20 = MathMin(ad_20, ld_40);
      } else {
         ld_40 = ad_12 + ld_92;
         if (ai_8 == 1 && ai_36) ld_40 += ld_100;
         ad_20 = MathMax(ad_20, ld_40);
      }
      ad_20 = NormalizeDouble(ad_20, MarketInfo(a_symbol_0, MODE_DIGITS));
   }
   if (ad_28 != 0.0) {
      if (MathAbs(ad_12 - ad_28) <= ld_92) {
         if (ai_8 % 2 == 0) {
            ld_48 = ad_12 + ld_92;
            ad_28 = MathMax(ad_28, ld_48);
         } else {
            ld_48 = ad_12 - ld_92;
            ad_28 = MathMin(ad_28, ld_48);
         }
         ad_28 = NormalizeDouble(ad_28, MarketInfo(a_symbol_0, MODE_DIGITS));
      }
   }
   if (ad_20 != ld_72) f0_8("SL was too close to brokers min distance (" + l_stoplevel_88 + "); moved SL to: " + ad_20);
   if (ad_28 != ld_80) f0_8("TP was too close to brokers min distance (" + l_stoplevel_88 + "); moved TP to: " + ad_28);
   gs_1060 = ls_56;
}

void f0_32(double ad_0, double ad_8) {
   double ld_16;
   int li_24;
   double ld_28;
   if (IsTesting() == FALSE) {
      ld_16 = MathCeil(ad_0 / 0.1);
      if (ld_16 > 0.0) {
         li_24 = MathRound(ad_8 / 0.1);
         ld_28 = 1.0 - 1.0 / ld_16;
         Sleep(20);
         for (int l_count_36 = 0; l_count_36 < li_24; l_count_36++) {
            if (MathRand() > 32768.0 * ld_28) break;
            Sleep(20);
         }
      }
   }
}

int f0_10(int a_ticket_0, string &a_symbol_4, int &a_cmd_12, int &a_digits_16, double &ad_20, double &a_ord_stoploss_28, double &a_ord_takeprofit_36, double &ad_44, double &ad_52, bool ai_60 = TRUE) {
   int l_ticket_64;
   string ls_68;
   if (ai_60) {
      l_ticket_64 = OrderTicket();
      if (!OrderSelect(a_ticket_0, SELECT_BY_TICKET, MODE_TRADES)) {
         f0_8("OrderSelect() error: " + ErrorDescription(GetLastError()));
         return (0);
      }
      a_symbol_4 = OrderSymbol();
      a_cmd_12 = OrderType();
      a_ord_takeprofit_36 = OrderTakeProfit();
      a_ord_stoploss_28 = OrderStopLoss();
      if (l_ticket_64 >= 0) OrderSelect(l_ticket_64, SELECT_BY_TICKET, MODE_TRADES);
   }
   ad_44 = NormalizeDouble(MarketInfo(a_symbol_4, MODE_BID), MarketInfo(a_symbol_4, MODE_DIGITS));
   ad_52 = NormalizeDouble(MarketInfo(a_symbol_4, MODE_ASK), MarketInfo(a_symbol_4, MODE_DIGITS));
   ad_20 = MarketInfo(a_symbol_4, MODE_POINT);
   if (ad_20 == 0.001 || ad_20 == 0.00001) ad_20 = 10.0 * ad_20;
   a_digits_16 = MarketInfo(a_symbol_4, MODE_DIGITS);
   if (a_digits_16 == 0) {
      ls_68 = gs_1060;
      gs_1060 = "GetDigits";
      f0_8("error: MarketInfo(symbol, MODE_DIGITS) == 0");
      gs_1060 = ls_68;
      return (0);
   }
   if (ai_60) {
      a_ord_takeprofit_36 = NormalizeDouble(a_ord_takeprofit_36, a_digits_16);
      a_ord_stoploss_28 = NormalizeDouble(a_ord_stoploss_28, a_digits_16);
      ad_44 = NormalizeDouble(ad_44, a_digits_16);
      ad_52 = NormalizeDouble(ad_52, a_digits_16);
   }
   return (1);
}

int init() {
   Comment("  Please only set the ea to timeframe M1! Algobasket EA 1.93 waiting for Authentication...");
   gi_820 = 0;
   gi_824 = FALSE;
   if (IsDllsAllowed() == FALSE) {
      MessageBox("DLL calls are not enabled. Algobasket EA will not be running. Please enable DLL calls and rerun EA.", "Warning...");
      Print("DLL calls disabled. Algobasket EA suspended.");
      return (0);
   }
   if (Period() != PERIOD_M1) {
      MessageBox("Please put Algobasket EA to timeframe M1 only.", "Warning...");
      Print("Wrong Period loaded. Algobasket EA suspended.");
      return (0);
   }
   gd_144 = 20;
   if (iRiskLevel == 1) gd_144 = 10;
   if (iRiskLevel == 2) gd_144 = 20;
   if (iRiskLevel == 3) gd_144 = 30;
   if (iRiskLevel == 4) gd_144 = 40;
   if (iRiskLevel == 5) gd_144 = 50;
   if (iRiskLevel == 6) gd_144 = 60;
   if (iRiskLevel == 7) gd_144 = 70;
   if (iRiskLevel == 8) gd_144 = 80;
   if (iRiskLevel == 9) gd_144 = 90;
   if (iRiskLevel == 10) gd_144 =100;
   
   if (iRiskLevel < 1) gd_144 = 10;
   if (iRiskLevel > 10) gd_144 = 100;
   
   while (gi_820 == 1 || gi_820 == 0) {
      Print("waiting for init...");
      gi_820 = InitializeFunctionsExt();
      Sleep(5000);
   }
   if (gi_820 > 1000) gi_824 = TRUE;
   if (gi_824 == TRUE) Comment("  Algobasket EA 1.93 is Authenticated.");
   else Comment("  Algobasket 1.93 is Not Authenticated.");
   if (gi_824 == FALSE) return (0);
   gd_132 = GetParam(1);
   gd_180 = GetParam(3);
   gd_188 = GetParam(4);
   gd_196 = GetParam(5);
   g_period_312 = GetParam(6);
   g_period_320 = GetParam(7);
   g_period_328 = GetParam(8);
   if (Digits == 3) {
      gd_180 = 10.0 * gd_180;
      gd_188 = 10.0 * gd_188;
      gd_196 = 10.0 * gd_196;
   }
   gi_420 = gi_152;
   gi_424 = gi_156;
   gi_428 = gi_152;
   gi_432 = gi_156;
   if (gi_140) gd_132 = AccountEquity() * gd_144 / 10000000.0;
   double l_minlot_0 = MarketInfo(Symbol(), MODE_MINLOT);
   if (l_minlot_0 > 0.1) l_minlot_0 = 0.1;
   gd_564 = 2;
   if (l_minlot_0 >= 0.1) gd_564 = 1;
   if (l_minlot_0 < 0.1) gd_564 = 2;
   if (l_minlot_0 < 0.01) gd_564 = 3;
   if (gd_564 == 1.0) {
      gi_128 = TRUE;
      Print("Mini account detected.");
   }
   if (gi_128) gd_132 = 10.0 * gd_132;
   if (gd_132 < l_minlot_0) gd_132 = l_minlot_0;
   gd_804 = gd_132;
   gd_812 = gd_132;
   Print("Algobasket EA started.");
   PlaySound("Expert restart.wav");
   ObjectDelete("BuysBreakevenLine");
   ObjectDelete("SellsBreakevenLine");
   gi_552 = gi_556 + 100 * f0_3(Symbol()) + f0_36(Period());
   gi_unused_560 = 0;
   f0_37(gi_548);
   g_shift_620 = 1;
   if (gi_624) g_shift_620 = 0;
   GlobalVariableSet(Symbol() + "_" + Period() + "_" + "MacdFastEma", gi_168);
   GlobalVariableSet(Symbol() + "_" + Period() + "_" + "MacdSlowEma", gi_172);
   GlobalVariableSet(Symbol() + "_" + Period() + "_" + "MacdSignalSma", gi_176);
   GlobalVariableSet(Symbol() + "_" + Period() + "_" + "CounterTradingLevel", gd_196);
   GlobalVariableSet(Symbol() + "_" + Period() + "_" + "MinimumLevel", gd_180);
   GlobalVariableSet(Symbol() + "_" + Period() + "_" + "MaximumLevel", gd_188);
   return (0);
}

int deinit() {
   ObjectDelete("BuysBreakevenLine");
   ObjectDelete("SellsBreakevenLine");
   return (0);
}

int f0_6() {
   int l_ticket_0 = 0;
   for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--) {
      OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_BUY || !OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderTicket() > l_ticket_0) l_ticket_0 = OrderTicket();
   }
   return (l_ticket_0);
}

int f0_41() {
   int l_ticket_0 = 0;
   for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--) {
      OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_SELL || !OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderTicket() > l_ticket_0) l_ticket_0 = OrderTicket();
   }
   return (l_ticket_0);
}

double f0_35() {
   double ld_0;
   double ld_8;
   double l_ord_lots_16;
   double l_ord_open_price_24;
   double ld_32;
   int li_40 = f0_29(gi_552, 0);
   for (int l_pos_44 = 0; l_pos_44 <= OrdersTotal() - 1; l_pos_44++) {
      OrderSelect(l_pos_44, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_BUY || !OrderSelect(l_pos_44, SELECT_BY_POS, MODE_TRADES)) continue;
      l_ord_open_price_24 = OrderOpenPrice();
      l_ord_lots_16 = OrderLots();
      ld_32 = l_ord_open_price_24 * l_ord_lots_16;
      ld_0 += l_ord_lots_16;
      ld_8 += ld_32;
   }
   if (ld_0 == 0.0) ld_0 = 1;
   gd_unused_464 = ld_0;
   double ld_ret_48 = ld_8 / ld_0;
   return (ld_ret_48);
}

double f0_24() {
   double ld_0;
   double ld_8;
   double l_ord_lots_16;
   double l_ord_open_price_24;
   double ld_32;
   int li_40 = f0_29(gi_552, 1);
   for (int l_pos_44 = 0; l_pos_44 <= OrdersTotal() - 1; l_pos_44++) {
      OrderSelect(l_pos_44, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_SELL || !OrderSelect(l_pos_44, SELECT_BY_POS, MODE_TRADES)) continue;
      l_ord_open_price_24 = OrderOpenPrice();
      l_ord_lots_16 = OrderLots();
      ld_32 = l_ord_open_price_24 * l_ord_lots_16;
      ld_0 += l_ord_lots_16;
      ld_8 += ld_32;
   }
   if (ld_0 == 0.0) ld_0 = 1;
   gd_unused_472 = ld_0;
   double ld_ret_48 = ld_8 / ld_0;
   return (ld_ret_48);
}

void f0_14(string as_0) {
   if (IsTesting() == FALSE) {
      if (gi_528) Alert(as_0);
      if (gi_436) SendMail(gs_536, as_0);
   }
}

double f0_1() {
   double ld_0 = BuysPipTargetExt(gd_496, gi_512);
   return (ld_0);
}

double f0_23() {
   double ld_0 = BuysPipTargetExt(gd_504, gi_512);
   return (ld_0);
}

void f0_20() {
   int li_unused_0;
   double ld_4;
   int l_cmd_12;
   int l_ticket_16;
   double l_ord_open_price_20;
   double l_ord_stoploss_28;
   int l_magic_36;
   double l_ilow_40 = iLow(NULL, 0, 1);
   double l_ima_48 = iMA(NULL, g_timeframe_788, g_period_368, gd_780, g_ma_method_376, g_applied_price_772, 0);
   OrderSelect(f0_38(), SELECT_BY_TICKET, MODE_TRADES);
   if (gi_412) ld_4 = OrderOpenPrice() - gi_416 * f0_2();
   if (gi_352) ld_4 = l_ima_48 - gi_356 * f0_2();
   OrderSelect(f0_6(), SELECT_BY_TICKET, MODE_TRADES);
   if (gi_344 && Bid - OrderOpenPrice() > gi_348 * f0_2()) {
      ld_4 = OrderOpenPrice();
      li_unused_0 = 1;
   }
   for (int l_pos_56 = OrdersTotal() - 1; l_pos_56 >= 0; l_pos_56--) {
      OrderSelect(l_pos_56, SELECT_BY_POS, MODE_TRADES);
      l_cmd_12 = OrderType();
      l_ord_open_price_20 = OrderOpenPrice();
      l_ticket_16 = OrderTicket();
      l_ord_stoploss_28 = OrderStopLoss();
      l_magic_36 = OrderMagicNumber();
      ld_4 = 0;
      if (l_cmd_12 != OP_BUY || l_magic_36 != gi_552) continue;
      if (gi_616 && OrderComment() == "cyatrade") continue;
      if (NormalizeDouble(OrderTakeProfit(), Digits) == NormalizeDouble(gd_596, Digits) && NormalizeDouble(l_ord_stoploss_28, Digits) == NormalizeDouble(ld_4, Digits)) continue;
      f0_7(l_ticket_16, l_ord_open_price_20, ld_4, gd_596, 0, CLR_NONE);
   }
   if (gd_596 <= Bid) f0_4();
}

void f0_0() {
   int li_unused_0;
   double ld_4;
   int l_cmd_12;
   int l_ticket_16;
   double l_ord_open_price_20;
   double l_ord_stoploss_28;
   int l_magic_36;
   double l_ihigh_40 = iHigh(NULL, 0, 1);
   double l_ima_48 = iMA(NULL, g_timeframe_788, g_period_368, gd_780, g_ma_method_376, g_applied_price_772, 0);
   OrderSelect(f0_33(), SELECT_BY_TICKET, MODE_TRADES);
   if (gi_412) ld_4 = OrderOpenPrice() + gi_416 * f0_2();
   if (gi_352) ld_4 = l_ima_48 + gi_356 * f0_2();
   OrderSelect(f0_41(), SELECT_BY_TICKET, MODE_TRADES);
   if (gi_344 && OrderOpenPrice() - Ask > gi_348 * f0_2()) {
      ld_4 = OrderOpenPrice();
      li_unused_0 = 1;
   }
   for (int l_pos_56 = OrdersTotal() - 1; l_pos_56 >= 0; l_pos_56--) {
      OrderSelect(l_pos_56, SELECT_BY_POS, MODE_TRADES);
      l_cmd_12 = OrderType();
      l_ord_open_price_20 = OrderOpenPrice();
      l_ticket_16 = OrderTicket();
      l_ord_stoploss_28 = OrderStopLoss();
      l_magic_36 = OrderMagicNumber();
      ld_4 = 0;
      if (l_cmd_12 != OP_SELL || l_magic_36 != gi_552) continue;
      if (gi_612 && OrderComment() == "cyatrade") continue;
      if (NormalizeDouble(OrderTakeProfit(), Digits) == NormalizeDouble(gd_604, Digits) && NormalizeDouble(OrderStopLoss(), Digits) == NormalizeDouble(ld_4, Digits)) continue;
      f0_7(l_ticket_16, l_ord_open_price_20, ld_4, gd_604, 0, CLR_NONE);
   }
   if (gd_604 >= Ask) f0_17();
}

void f0_11() {
   int l_cmd_0;
   int l_ticket_4;
   double l_ord_open_price_8;
   double l_ord_stoploss_16;
   int l_magic_24;
   double l_ord_lots_28;
   double l_price_36;
   double l_bid_44;
   int l_ord_close_52;
   int l_error_56;
   int li_60;
   string l_symbol_64 = "";
   double ld_72 = 600;
   int l_slippage_80 = 100;
   for (int l_pos_84 = OrdersTotal() - 1; l_pos_84 >= 0; l_pos_84--) {
      OrderSelect(l_pos_84, SELECT_BY_POS, MODE_TRADES);
      l_cmd_0 = OrderType();
      l_ord_open_price_8 = OrderOpenPrice();
      l_ticket_4 = OrderTicket();
      l_ord_stoploss_16 = OrderStopLoss();
      l_magic_24 = OrderMagicNumber();
      l_symbol_64 = OrderSymbol();
      l_ord_lots_28 = OrderLots();
      if (l_magic_24 == gi_552) {
         if (l_symbol_64 == Symbol()) {
            RefreshRates();
            if (l_cmd_0 == OP_BUY) {
               l_price_36 = MarketInfo(l_symbol_64, MODE_BID);
               if (l_price_36 == 0.0) continue;
               if (l_price_36 > l_ord_open_price_8 - ld_72 * f0_2()) continue;
               while (true) {
                  l_bid_44 = MarketInfo(l_symbol_64, MODE_BID);
                  l_ord_close_52 = OrderClose(l_ticket_4, l_ord_lots_28, l_bid_44, l_slippage_80, Red);
                  if (l_ord_close_52 != 1) {
                     l_error_56 = GetLastError();
                     Print("LastError = ", l_error_56);
                  } else l_error_56 = 0;
                  if (l_error_56 == 135/* PRICE_CHANGED */) {
                     Sleep(1000);
                     RefreshRates();
                     li_60++;
                  }
                  if (l_error_56 == 136/* OFF_QUOTES */) {
                     Sleep(1000);
                     RefreshRates();
                     li_60++;
                  }
                  if (l_error_56 == 137/* BROKER_BUSY */) {
                     Sleep(1000);
                     RefreshRates();
                     li_60++;
                  }
                  if (l_error_56 == 138/* REQUOTE */) {
                     Sleep(1000);
                     RefreshRates();
                     li_60++;
                  }
                  if (l_error_56 != 142) break;
                  Sleep(1000);
                  RefreshRates();
                  li_60++;
               }
            }
            l_price_36 = MarketInfo(l_symbol_64, MODE_ASK);
            if (l_price_36 != 0.0) {
               if (l_price_36 >= l_ord_open_price_8 + ld_72 * f0_2()) {
                  while (true) {
                     l_bid_44 = MarketInfo(l_symbol_64, MODE_ASK);
                     l_ord_close_52 = OrderClose(l_ticket_4, l_ord_lots_28, l_bid_44, l_slippage_80, Red);
                     if (l_ord_close_52 != 1) {
                        l_error_56 = GetLastError();
                        Print("LastError = ", l_error_56);
                     } else l_error_56 = 0;
                     if (l_error_56 == 135/* PRICE_CHANGED */) {
                        Sleep(1000);
                        RefreshRates();
                        li_60++;
                     }
                     if (l_error_56 == 136/* OFF_QUOTES */) {
                        Sleep(1000);
                        RefreshRates();
                        li_60++;
                     }
                     if (l_error_56 == 137/* BROKER_BUSY */) {
                        Sleep(1000);
                        RefreshRates();
                        li_60++;
                     }
                     if (l_error_56 == 138/* REQUOTE */) {
                        Sleep(1000);
                        RefreshRates();
                        li_60++;
                     }
                     if (l_error_56 != 142) break;
                     Sleep(1000);
                     RefreshRates();
                     li_60++;
                  }
               }
            }
         }
      }
   }
}

int start() {
   bool li_0;
   bool li_4;
   int li_8;
   int li_12;
   if (gi_824 == FALSE) return (0);
   if (AccountMargin() == 0.0) gd_572 = 1;
   else gd_572 = AccountMargin();
   gd_572 = NormalizeDouble(100.0 * (AccountEquity() / gd_572), 0);
   double ld_16 = AccountEquity();
   double ld_24 = AccountBalance() - AccountBalance() * (gd_244 / 100.0);
   if (ld_16 <= ld_24) {
      f0_17();
      f0_4();
   }
   bool li_32 = f0_15();
   string ls_unused_36 = "start()";
   gi_512 = f0_29(gi_552, 0);
   gi_516 = f0_29(gi_552, 1);
   gi_616 = FALSE;
   gs_536 = "";
   if (gi_516 >= gi_300 && !gi_612) gi_616 = TRUE;
   gi_612 = FALSE;
   if (gi_512 >= gi_300 && !gi_616) gi_612 = TRUE;
   if (gi_512 <= 1) li_8 = gi_420;
   else li_8 = gi_424;
   if (gi_516 <= 1) li_12 = gi_428;
   else li_12 = gi_432;
   if (OrderSelect(f0_6(), SELECT_BY_TICKET, MODE_TRADES)) g_ord_open_price_480 = OrderOpenPrice();
   if (OrderSelect(f0_41(), SELECT_BY_TICKET, MODE_TRADES)) g_ord_open_price_488 = OrderOpenPrice();
   gd_448 = gd_804;
   gd_456 = gd_812;
   for (int li_44 = 1; li_44 < 21; li_44++) {
      gda_440[li_44] = BuySellLotsExt(gd_448, li_44);
      gda_444[li_44] = BuySellLotsExt(gd_456, li_44);
   }
   gd_496 = gd_804 * li_8;
   gd_504 = gd_812 * li_12;
   if (gi_512 == 0) gd_596 = 0;
   if (gi_516 == 0) gd_604 = 0;
   if (gi_512 > 0) gd_596 = f0_35() + f0_1() * f0_2() / f0_22();
   if (gi_516 > 0) gd_604 = f0_24() - f0_23() * f0_2() / f0_34();
   OrderSelect(f0_6(), SELECT_BY_TICKET, MODE_TRADES);
   if (gi_512 != gd_580) {
      gd_580 = gi_512;
      f0_20();
      if (gi_612) f0_27();
   }
   if (li_32 && gi_512 > 0 && OrderStopLoss() != OrderOpenPrice()) f0_20();
   if (gi_344 && Bid - OrderOpenPrice() > gi_348 * f0_2() && OrderStopLoss() != OrderOpenPrice()) f0_20();
   OrderSelect(f0_41(), SELECT_BY_TICKET, MODE_TRADES);
   if (gi_516 != gd_588) {
      gd_588 = gi_516;
      f0_0();
      if (gi_616) f0_26();
   }
   if (li_32 && gi_516 > 0 && OrderStopLoss() != OrderOpenPrice()) f0_0();
   if (gi_344 && OrderOpenPrice() - Ask > gi_348 * f0_2() && OrderStopLoss() != OrderOpenPrice()) f0_0();
   f0_11();
   if (li_32) {
      li_0 = f0_39();
      if (li_0) f0_26();
      li_4 = f0_19();
      if (li_4) f0_27();
   }
   g_iclose_796 = iClose(NULL, PERIOD_D1, 1);
   if (Hour() == 0) ObjectDelete("Yesterdays close");
   ObjectCreate("Yesterdays close", OBJ_HLINE, 0, TimeCurrent(), g_iclose_796);
   return (0);
}

int f0_26() {
   int li_ret_0 = f0_9();
   if (li_ret_0 >= 0) f0_14(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES) + ": " + f0_40(0) + " " + DoubleToStr(OrderLots(), 2) + " " + Symbol() + " @ " + DoubleToStr(Ask, Digits));
   return (li_ret_0);
}

int f0_27() {
   int li_ret_0 = f0_31();
   if (li_ret_0 >= 0) f0_14(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES) + ": " + f0_40(1) + " " + DoubleToStr(OrderLots(), 2) + " " + Symbol() + " @ " + DoubleToStr(Ask, Digits));
   return (li_ret_0);
}

double f0_5() {
   double l_ord_stoploss_0;
   double ld_ret_8 = 0;
   if (OrderSelect(f0_38(), SELECT_BY_TICKET, MODE_TRADES)) l_ord_stoploss_0 = OrderStopLoss();
   double l_ilow_16 = iLow(NULL, 0, 1);
   if (gi_392 && gi_396) ld_ret_8 = l_ilow_16 - gi_400 * f0_2();
   if (gi_392 && !gi_396 && gi_512 == 0) ld_ret_8 = l_ilow_16 - gi_400 * f0_2();
   if (gi_392 && !gi_396 && gi_512 > 0) ld_ret_8 = l_ord_stoploss_0;
   return (ld_ret_8);
}

double f0_43() {
   double l_ord_stoploss_0;
   double ld_ret_8 = 0;
   if (OrderSelect(f0_38(), SELECT_BY_TICKET, MODE_TRADES)) l_ord_stoploss_0 = OrderStopLoss();
   double l_ihigh_16 = iHigh(NULL, 0, 1);
   if (gi_392 && gi_396) ld_ret_8 = l_ihigh_16 + gi_400 * f0_2();
   if (gi_392 && !gi_396 && gi_516 == 0) ld_ret_8 = l_ihigh_16 + gi_400 * f0_2();
   if (gi_392 && !gi_396 && gi_516 > 0) ld_ret_8 = l_ord_stoploss_0;
   return (ld_ret_8);
}

int f0_9() {
   double l_ord_stoploss_0;
   string ls_8;
   if (gi_824 == FALSE) return (-1);
   if (OrderSelect(f0_38(), SELECT_BY_TICKET, MODE_TRADES)) l_ord_stoploss_0 = OrderStopLoss();
   double l_ilow_16 = iLow(NULL, 0, 1);
   if (gi_616) ls_8 = "cyatrade";
   if (!gi_616) ls_8 = "";
   double l_stoplevel_24 = 0;
   double ld_32 = 0;
   l_stoplevel_24 = f0_5();
   int li_40 = 32768;
   double l_ask_44 = Ask;
   double ld_52 = NormalizeDouble(f0_25(), gd_564);
   Print("Calculated lots " + f0_25() + " normalized to " + ld_52);
   if (ld_52 > 150.0 * gd_804) return (-1);
   ls_8 = "Algobasket 1.93";
   l_stoplevel_24 = NormalizeDouble(l_stoplevel_24, Digits);
   if (l_stoplevel_24 < MarketInfo(Symbol(), MODE_STOPLEVEL)) l_stoplevel_24 = MarketInfo(Symbol(), MODE_STOPLEVEL);
   l_stoplevel_24 = 0;
   int li_ret_60 = f0_30(Symbol(), OP_BUY, ld_52, l_ask_44, gi_532, l_stoplevel_24, ld_32, ls_8, gi_552, 0, li_40);
   if (li_ret_60 > 0) return (li_ret_60);
   return (0);
}

int f0_31() {
   double l_ord_stoploss_0;
   string ls_8;
   if (gi_824 == FALSE) return (-1);
   if (OrderSelect(f0_33(), SELECT_BY_TICKET, MODE_TRADES)) l_ord_stoploss_0 = OrderStopLoss();
   double l_ihigh_16 = iHigh(NULL, 0, 1);
   if (gi_612) ls_8 = "cyatrade";
   if (!gi_612) ls_8 = "";
   double ld_24 = 0;
   double ld_32 = 0;
   ld_24 = f0_43();
   int li_40 = 255;
   double l_bid_44 = Bid;
   double ld_52 = NormalizeDouble(f0_16(), gd_564);
   Print("Calculated lots " + f0_25() + " normalized to " + ld_52);
   if (ld_52 > 150.0 * gd_812) return (-1);
   ls_8 = "Algobasket 1.93";
   ld_24 = NormalizeDouble(ld_24, Digits);
   ld_24 = 0;
   int li_ret_60 = f0_30(Symbol(), OP_SELL, ld_52, l_bid_44, gi_532, ld_24, ld_32, ls_8, gi_552, 0, li_40);
   if (li_ret_60 > 0) return (li_ret_60);
   return (0);
}

double f0_25() {
   double ld_ret_0;
   if (!gi_616) {
      if (gi_512 == 0) ld_ret_0 = gda_440[1];
      if (gi_512 == 1) ld_ret_0 = gda_440[2];
      if (gi_512 == 2) ld_ret_0 = gda_440[3];
      if (gi_512 == 3) ld_ret_0 = gda_440[4];
      if (gi_512 == 4) ld_ret_0 = gda_440[5];
      if (gi_512 == 5) ld_ret_0 = gda_440[6];
      if (gi_512 == 6) ld_ret_0 = gda_440[7];
      if (gi_512 == 7) ld_ret_0 = gda_440[8];
      if (gi_512 == 8) ld_ret_0 = gda_440[9];
      if (gi_512 == 9) ld_ret_0 = gda_440[10];
      if (gi_512 == 10) ld_ret_0 = gda_440[11];
      if (gi_512 == 11) ld_ret_0 = gda_440[12];
      if (gi_512 == 12) ld_ret_0 = gda_440[13];
      if (gi_512 == 13) ld_ret_0 = gda_440[14];
      if (gi_512 == 14) ld_ret_0 = gda_440[15];
      if (gi_512 == 15) ld_ret_0 = gda_440[16];
      if (gi_512 == 16) ld_ret_0 = gda_440[17];
      if (gi_512 == 17) ld_ret_0 = gda_440[18];
      if (gi_512 == 18) ld_ret_0 = gda_440[19];
      if (gi_512 == 19) ld_ret_0 = gda_440[20];
   }
   if (gi_616) {
      if (gi_516 == 1) ld_ret_0 = gda_440[1];
      if (gi_516 == 2) ld_ret_0 = gda_440[2];
      if (gi_516 == 3) ld_ret_0 = gda_440[3];
      if (gi_516 == 4) ld_ret_0 = gda_440[4];
      if (gi_516 == 5) ld_ret_0 = gda_440[5];
      if (gi_516 == 6) ld_ret_0 = gda_440[6];
      if (gi_516 == 7) ld_ret_0 = gda_440[7];
      if (gi_516 == 8) ld_ret_0 = gda_440[8];
      if (gi_516 == 9) ld_ret_0 = gda_440[9];
      if (gi_516 == 10) ld_ret_0 = gda_440[10];
      if (gi_516 == 11) ld_ret_0 = gda_440[11];
      if (gi_516 == 12) ld_ret_0 = gda_440[12];
      if (gi_516 == 13) ld_ret_0 = gda_440[13];
      if (gi_516 == 14) ld_ret_0 = gda_440[14];
      if (gi_516 == 15) ld_ret_0 = gda_440[15];
      if (gi_516 == 16) ld_ret_0 = gda_440[16];
      if (gi_516 == 17) ld_ret_0 = gda_440[17];
      if (gi_516 == 18) ld_ret_0 = gda_440[18];
      if (gi_516 == 19) ld_ret_0 = gda_440[19];
      if (gi_516 == 20) ld_ret_0 = gda_440[20];
   }
   return (ld_ret_0);
}

double f0_16() {
   double ld_ret_0;
   if (!gi_612) {
      if (gi_516 == 0) ld_ret_0 = gda_444[1];
      if (gi_516 == 1) ld_ret_0 = gda_444[2];
      if (gi_516 == 2) ld_ret_0 = gda_444[3];
      if (gi_516 == 3) ld_ret_0 = gda_444[4];
      if (gi_516 == 4) ld_ret_0 = gda_444[5];
      if (gi_516 == 5) ld_ret_0 = gda_444[6];
      if (gi_516 == 6) ld_ret_0 = gda_444[7];
      if (gi_516 == 7) ld_ret_0 = gda_444[8];
      if (gi_516 == 8) ld_ret_0 = gda_444[9];
      if (gi_516 == 9) ld_ret_0 = gda_444[10];
      if (gi_516 == 10) ld_ret_0 = gda_444[11];
      if (gi_516 == 11) ld_ret_0 = gda_444[12];
      if (gi_516 == 12) ld_ret_0 = gda_444[13];
      if (gi_516 == 13) ld_ret_0 = gda_444[14];
      if (gi_516 == 14) ld_ret_0 = gda_444[15];
      if (gi_516 == 15) ld_ret_0 = gda_444[16];
      if (gi_516 == 16) ld_ret_0 = gda_444[17];
      if (gi_516 == 17) ld_ret_0 = gda_444[18];
      if (gi_516 == 18) ld_ret_0 = gda_444[19];
      if (gi_516 == 19) ld_ret_0 = gda_444[20];
   }
   if (gi_612) {
      if (gi_512 == 1) ld_ret_0 = gda_444[1];
      if (gi_512 == 2) ld_ret_0 = gda_444[2];
      if (gi_512 == 3) ld_ret_0 = gda_444[3];
      if (gi_512 == 4) ld_ret_0 = gda_444[4];
      if (gi_512 == 5) ld_ret_0 = gda_444[5];
      if (gi_512 == 6) ld_ret_0 = gda_444[6];
      if (gi_512 == 7) ld_ret_0 = gda_444[7];
      if (gi_512 == 8) ld_ret_0 = gda_444[8];
      if (gi_512 == 9) ld_ret_0 = gda_444[9];
      if (gi_512 == 10) ld_ret_0 = gda_444[10];
      if (gi_512 == 11) ld_ret_0 = gda_444[11];
      if (gi_512 == 12) ld_ret_0 = gda_444[12];
      if (gi_512 == 13) ld_ret_0 = gda_444[13];
      if (gi_512 == 14) ld_ret_0 = gda_444[14];
      if (gi_512 == 15) ld_ret_0 = gda_444[15];
      if (gi_512 == 16) ld_ret_0 = gda_444[16];
      if (gi_512 == 17) ld_ret_0 = gda_444[17];
      if (gi_512 == 18) ld_ret_0 = gda_444[18];
      if (gi_512 == 19) ld_ret_0 = gda_444[19];
      if (gi_512 == 20) ld_ret_0 = gda_444[20];
   }
   return (ld_ret_0);
}

double f0_22() {
   double ld_ret_0;
   for (int l_pos_8 = OrdersTotal() - 1; l_pos_8 >= 0; l_pos_8--) {
      if (!OrderSelect(l_pos_8, SELECT_BY_POS, MODE_TRADES) || OrderType() != OP_BUY || OrderMagicNumber() != gi_552) continue;
      ld_ret_0 += OrderLots();
   }
   if (ld_ret_0 == 0.0) ld_ret_0 = 1;
   return (ld_ret_0);
}

double f0_34() {
   double ld_ret_0;
   for (int l_pos_8 = OrdersTotal() - 1; l_pos_8 >= 0; l_pos_8--) {
      if (!OrderSelect(l_pos_8, SELECT_BY_POS, MODE_TRADES) || OrderType() != OP_SELL || OrderMagicNumber() != gi_552) continue;
      ld_ret_0 += OrderLots();
   }
   if (ld_ret_0 == 0.0) ld_ret_0 = 1;
   return (ld_ret_0);
}

void f0_4() {
   int l_cmd_0;
   int l_error_4;
   double l_bid_8;
   int l_ord_close_16;
   int l_slippage_20 = 100;
   int li_24 = OrdersTotal() - 1;
   for (int l_pos_28 = li_24; l_pos_28 >= 0; l_pos_28--) {
      if (OrderSelect(l_pos_28, SELECT_BY_POS, MODE_TRADES)) {
         l_cmd_0 = OrderType();
         if (!((l_cmd_0 == OP_BUY && OrderMagicNumber() == gi_552))) continue;
      } else Print("When selecting a trade, error ", GetLastError(), " occurred");
      l_bid_8 = MarketInfo(OrderSymbol(), MODE_BID);
      l_ord_close_16 = OrderClose(OrderTicket(), OrderLots(), l_bid_8, l_slippage_20, Red);
      if (l_ord_close_16 != 1) {
         l_error_4 = GetLastError();
         Print("LastError = ", l_error_4);
      } else l_error_4 = 0;
      if (l_error_4 == 135/* PRICE_CHANGED */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 136/* OFF_QUOTES */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 137/* BROKER_BUSY */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 138/* REQUOTE */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 142) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
   }
}

void f0_17() {
   int l_cmd_0;
   int l_error_4;
   double l_ask_8;
   int l_ord_close_16;
   int l_slippage_20 = 100;
   int li_24 = OrdersTotal() - 1;
   for (int l_pos_28 = li_24; l_pos_28 >= 0; l_pos_28--) {
      if (OrderSelect(l_pos_28, SELECT_BY_POS, MODE_TRADES)) {
         l_cmd_0 = OrderType();
         if (!((l_cmd_0 == OP_SELL && OrderMagicNumber() == gi_552))) continue;
      } else Print("When selecting a trade, error ", GetLastError(), " occurred");
      l_ask_8 = MarketInfo(OrderSymbol(), MODE_ASK);
      l_ord_close_16 = OrderClose(OrderTicket(), OrderLots(), l_ask_8, l_slippage_20, Red);
      if (l_ord_close_16 != 1) {
         l_error_4 = GetLastError();
         Print("LastError = ", l_error_4);
      } else l_error_4 = 0;
      if (l_error_4 == 135/* PRICE_CHANGED */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 136/* OFF_QUOTES */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 137/* BROKER_BUSY */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 138/* REQUOTE */) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
      if (l_error_4 == 142) {
         Sleep(1000);
         RefreshRates();
         l_pos_28++;
      }
   }
}

int f0_15() {
   if (Bars == g_bars_524) return (0);
   g_bars_524 = Bars;
   return (1);
}

int f0_39() {
   if (gi_824 == FALSE) return (0);
   double l_ihigh_0 = iHigh(NULL, 0, 1);
   double l_ilow_8 = iLow(NULL, 0, 1);
   double l_iclose_16 = iClose(NULL, 0, 1);
   double l_ihigh_24 = iHigh(NULL, 0, 2);
   double l_ilow_32 = iLow(NULL, 0, 2);
   double l_iclose_40 = iClose(NULL, 0, 2);
   double ld_48 = (iHigh(NULL, 0, 1) + iLow(NULL, 0, 1)) / 2.0;
   gi_512 = f0_29(gi_552, 0);
   gi_516 = f0_29(gi_552, 1);
   int l_timeframe_56 = gi_204;
   if (gi_512 > 2 && gi_512 < 5) l_timeframe_56 = gi_208;
   if (gi_512 > 4) l_timeframe_56 = gi_212;
   double l_imacd_60 = iMACD(NULL, l_timeframe_56, gi_168, gi_172, gi_176, PRICE_CLOSE, MODE_MAIN, g_shift_620);
   double l_imacd_68 = iMACD(NULL, l_timeframe_56, gi_168, gi_172, gi_176, PRICE_CLOSE, MODE_MAIN, g_shift_620 + 1);
   double l_imacd_76 = iMACD(NULL, l_timeframe_56, gi_168, gi_172, gi_176, PRICE_CLOSE, MODE_MAIN, g_shift_620 + 2);
   double l_ima_84 = iMA(NULL, g_timeframe_660, g_period_312, gd_652, g_ma_method_636, g_applied_price_644, 0);
   double l_ima_92 = iMA(NULL, g_timeframe_708, g_period_320, gd_700, g_ma_method_684, g_applied_price_692, 0);
   double l_ima_100 = iMA(NULL, g_timeframe_756, g_period_328, gd_748, g_ma_method_732, g_applied_price_740, 0);
   bool li_ret_108 = FALSE;
   if (DayOfWeek() < gi_260 && gd_572 > gd_252) {
      if (!gi_268) {
         if (gi_276)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 < (-gd_196) && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
         if (gi_276 && gi_512 > 0)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 > gd_180 && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
         if (!gi_276)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 < gd_188 && l_imacd_68 > gd_180 && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
         if (!gi_276 && gi_512 > 0)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 < (-gd_180) && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
      }
      if (gi_268) {
         if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 < (-gd_196) && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
         if (gi_512 > 0)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 > gd_180 && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
         if (gi_512 == 0)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 < gd_188 && l_imacd_68 > gd_180 && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
         if (gi_512 > 0)
            if (l_imacd_60 > l_imacd_68 && l_imacd_68 <= l_imacd_76 && l_imacd_68 < (-gd_180) && l_ihigh_0 > l_ihigh_24 && l_iclose_16 > ld_48) li_ret_108 = TRUE;
      }
   }
   if (li_ret_108 == TRUE) {
      if (gi_308 && gi_512 == 0) {
         if (l_ima_100 > l_ima_92 && l_ima_92 > l_ima_84) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
   }
   if (li_ret_108 == TRUE) {
      if (gi_304 && gi_512 == 0) {
         if (Bid > g_iclose_796) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
   }
   if (gi_512 > 0) {
      if (!gi_288) {
         if (li_ret_108 == TRUE && gd_280 * f0_2() < f0_28() - Ask) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
      if (gi_288) {
         if (li_ret_108 == TRUE && gd_280 * f0_2() < MathAbs(g_ord_open_price_480 - Ask)) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
   }
   if (!HedgingAllowed && gi_516 != 0) li_ret_108 = FALSE;
   if (gi_512 == 0 && !gi_264 && DayOfWeek() == 0) li_ret_108 = FALSE;
   return (li_ret_108);
}

int f0_19() {
   if (gi_824 == FALSE) return (0);
   double l_ihigh_0 = iHigh(NULL, 0, 1);
   double l_ilow_8 = iLow(NULL, 0, 1);
   double l_iclose_16 = iClose(NULL, 0, 1);
   double l_ihigh_24 = iHigh(NULL, 0, 2);
   double l_ilow_32 = iLow(NULL, 0, 2);
   double l_iclose_40 = iClose(NULL, 0, 2);
   double ld_48 = (iHigh(NULL, 0, 1) + iLow(NULL, 0, 1)) / 2.0;
   gi_512 = f0_29(gi_552, 0);
   gi_516 = f0_29(gi_552, 1);
   int l_timeframe_56 = gi_204;
   if (gi_516 > 2 && gi_516 < 5) l_timeframe_56 = gi_208;
   if (gi_516 > 4) l_timeframe_56 = gi_212;
   double l_imacd_60 = iMACD(NULL, l_timeframe_56, gi_168, gi_172, gi_176, PRICE_CLOSE, MODE_MAIN, g_shift_620);
   double l_imacd_68 = iMACD(NULL, l_timeframe_56, gi_168, gi_172, gi_176, PRICE_CLOSE, MODE_MAIN, g_shift_620 + 1);
   double l_imacd_76 = iMACD(NULL, l_timeframe_56, gi_168, gi_172, gi_176, PRICE_CLOSE, MODE_MAIN, g_shift_620 + 2);
   double l_ima_84 = iMA(NULL, g_timeframe_660, g_period_312, gd_652, g_ma_method_636, g_applied_price_644, 0);
   double l_ima_92 = iMA(NULL, g_timeframe_708, g_period_320, gd_700, g_ma_method_684, g_applied_price_692, 0);
   double l_ima_100 = iMA(NULL, g_timeframe_756, g_period_328, gd_748, g_ma_method_732, g_applied_price_740, 0);
   bool li_ret_108 = FALSE;
   if (DayOfWeek() < gi_260 && gd_572 > gd_252) {
      if (!gi_268) {
         if (gi_276)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > gd_196 && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
         if (gi_276 && gi_516 > 0)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > (-gd_188) && l_imacd_68 < (-gd_180) && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
         if (!gi_276)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > (-gd_188) && l_imacd_68 < (-gd_180) && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
         if (!gi_276 && gi_516 > 0)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > gd_180 && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
      }
      if (gi_268) {
         if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > gd_196 && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
         if (gi_516 > 0)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > (-gd_188) && l_imacd_68 < (-gd_180) && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
         if (gi_516 == 0)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > (-gd_188) && l_imacd_68 < (-gd_180) && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
         if (gi_516 > 0)
            if (l_imacd_60 < l_imacd_68 && l_imacd_68 >= l_imacd_76 && l_imacd_68 > gd_180 && l_ilow_8 < l_ilow_32 && l_iclose_16 < ld_48) li_ret_108 = TRUE;
      }
   }
   if (li_ret_108 == TRUE) {
      if (gi_308 && gi_516 == 0) {
         if (l_ima_100 < l_ima_92 && l_ima_92 < l_ima_84) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
   }
   if (li_ret_108 == TRUE) {
      if (gi_304 && gi_516 == 0) {
         if (Bid < g_iclose_796) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
   }
   if (gi_516 > 0) {
      if (!gi_288) {
         if (li_ret_108 == TRUE && gd_280 * f0_2() < Bid - f0_42()) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
      if (gi_288) {
         if (li_ret_108 == TRUE && gd_280 * f0_2() < MathAbs(g_ord_open_price_488 - Bid)) li_ret_108 = TRUE;
         else li_ret_108 = FALSE;
      }
   }
   if (!HedgingAllowed && gi_512 != 0) li_ret_108 = FALSE;
   if (gi_516 == 0 && !gi_264 && DayOfWeek() == 0) li_ret_108 = FALSE;
   return (li_ret_108);
}

int f0_38() {
   int l_ticket_0 = 0;
   for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--) {
      OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_BUY || !OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES)) continue;
      if (l_ticket_0 == 0) l_ticket_0 = OrderTicket();
      if (OrderTicket() < l_ticket_0) l_ticket_0 = OrderTicket();
   }
   return (l_ticket_0);
}

int f0_33() {
   int l_ticket_0 = 0;
   for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--) {
      OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_SELL || !OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES)) continue;
      if (l_ticket_0 == 0) l_ticket_0 = OrderTicket();
      if (OrderTicket() < l_ticket_0) l_ticket_0 = OrderTicket();
   }
   return (l_ticket_0);
}

double f0_28() {
   double l_ord_open_price_0 = 0.0;
   for (int l_pos_8 = OrdersTotal() - 1; l_pos_8 >= 0; l_pos_8--) {
      OrderSelect(l_pos_8, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_BUY || !OrderSelect(l_pos_8, SELECT_BY_POS, MODE_TRADES)) continue;
      if (l_ord_open_price_0 == 0.0) l_ord_open_price_0 = OrderOpenPrice();
      if (OrderOpenPrice() < l_ord_open_price_0) l_ord_open_price_0 = OrderOpenPrice();
   }
   return (l_ord_open_price_0);
}

double f0_42() {
   double l_ord_open_price_0 = 0.0;
   for (int l_pos_8 = OrdersTotal() - 1; l_pos_8 >= 0; l_pos_8--) {
      OrderSelect(l_pos_8, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() != gi_552 || OrderType() != OP_SELL || !OrderSelect(l_pos_8, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderOpenPrice() > l_ord_open_price_0) l_ord_open_price_0 = OrderOpenPrice();
   }
   return (l_ord_open_price_0);
}

double GetParam(int ai_0) {
   switch (ai_0) {
   case 0:
      return (0.0);
   case 1:
      return (0.01);
   case 2:
      return (20.0);
   case 3:
      return (0.0002);
   case 4:
      return (0.0025);
   case 5:
      return (0.004);
   case 6:
      return (89.0);
   case 7:
      return (21.0);
   case 8:
      return (8.0);
   }
   return (0);
}

int InitializeFunctionsExt() {
   return (1100);
}

double BuySellLotsExt(double ad_0, int ai_8) {
   switch (ai_8) {
   case 0:
      return (0);
   case 1:
      return (1.0 * ad_0);
   case 2:
      return (1.0 * ad_0);
   case 3:
      return (1.0 * ad_0);
   case 4:
      return (3.0 * ad_0);
   case 5:
      return (6.0 * ad_0);
   case 6:
      return (9.0 * ad_0);
   case 7:
      return (12.0 * ad_0);
   case 8:
      return (15.0 * ad_0);
   case 9:
      return (21.0 * ad_0);
   case 10:
      return (27.0 * ad_0);
   case 11:
      return (33.0 * ad_0);
   case 12:
      return (39.0 * ad_0);
   case 13:
      return (45.0 * ad_0);
   case 14:
      return (55.0 * ad_0);
   case 15:
      return (65.0 * ad_0);
   case 16:
      return (75.0 * ad_0);
   case 17:
      return (85.0 * ad_0);
   case 18:
      return (95.0 * ad_0);
   case 19:
      return (120.0 * ad_0);
   case 20:
      return (140.0 * ad_0);
   }
   return (0);
}

double BuysPipTargetExt(double ad_0, int ai_8) {
   switch (ai_8) {
   case 0:
      return (ad_0);
   case 1:
      return (ad_0);
   case 2:
      return (ad_0);
   case 3:
      return (2.0 * ad_0);
   case 4:
      return (2.0 * ad_0);
   case 5:
      return (3.0 * ad_0);
   case 6:
      return (4.0 * ad_0);
   case 7:
      return (4.0 * ad_0);
   case 8:
      return (5.0 * ad_0);
   case 9:
      return (5.0 * ad_0);
   case 10:
      return (5.0 * ad_0);
   case 11:
      return (5.0 * ad_0);
   case 12:
      return (5.0 * ad_0);
   case 13:
      return (5.0 * ad_0);
   case 14:
      return (5.0 * ad_0);
   case 15:
      return (5.0 * ad_0);
   case 16:
      return (5.0 * ad_0);
   case 17:
      return (5.0 * ad_0);
   case 18:
      return (5.0 * ad_0);
   case 19:
      return (5.0 * ad_0);
   case 20:
      return (5.0 * ad_0);
   }
   return (0);
}
