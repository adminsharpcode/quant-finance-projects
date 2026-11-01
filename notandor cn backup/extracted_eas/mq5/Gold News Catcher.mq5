//+------------------------------------------------------------------+
//|                               GoldCatcher_TimeLimit.mq5          |
//|                                  Copyright 2024, Assistant AI    |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Assistant AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- INPUT PARAMETERS
input group             "--- MODE PILIHAN ---"
input bool   InpUseNewsFilter = true;       // TRUE = Pakai Batas Waktu News, FALSE = Unlimited (Non-Stop)

input group             "--- Settings Strategi ---"
input double InpLots          = 0.01;        // Lot Size
input int    InpGapPoints     = 150;        // Jarak Pending Order (300 = 30 pips)
input int    InpTakeProfit    = 50;        // Take Profit (Points)
input int    InpStopLoss      = 300;        // Stop Loss (Points)
input int    InpModifyStep    = 30;         // Min. Pergerakan Harga untuk Ubah Order

input group             "--- Settings Waktu News (Jika True) ---"
input int    InpMinutesBefore    = 10;      // Mulai Trade berapa menit SEBELUM News?
input int    InpMinutesAfterNews = 5;       // Berhenti Trade berapa menit SETELAH News? (Time Limit)
input bool   InpOnlyUSD          = true;    // Hanya News USD?

input group             "--- Lainnya ---"
input int    InpMagicNum      = 777888;     // Magic Number

//--- GLOBAL VARIABLES
const long USA_COUNTRY_ID = 840; 
CTrade trade;
datetime nextNewsTime = 0;
string nextNewsName = "";
int nextNewsImpact = 0; 
bool isNewsMode = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNum);
   trade.SetTypeFilling(ORDER_FILLING_IOC); 
   
   if(InpUseNewsFilter)
     {
      Print("EA Started: MODE NEWS FILTER. Mencari Jadwal...");
      FindNextNews();
     }
   else
     {
      Print("EA Started: MODE UNLIMITED (Tanpa News). Trap aktif selamanya.");
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // --- LOGIKA UTAMA: PILIHAN MODE ---
   
   if(InpUseNewsFilter == true)
     {
      // === MODE 1: NEWS FILTER (DENGAN BATAS WAKTU) ===
      RunNewsLogic();
     }
   else
     {
      // === MODE 2: TANPA NEWS (UNLIMITED) ===
      // Selalu jalankan trap 24 jam non-stop
      DoDynamicTrap();
      
      Comment("\n=== GOLD CATCHER (UNLIMITED MODE) ===\n",
              "STATUS: ALWAYS ACTIVE\n",
              "Time Limit: OFF (Non-stop)\n",
              "Warning: Pantau Spread!\n",
              "-------------------------");
     }
  }

//+------------------------------------------------------------------+
//| Logic: Pengaturan Waktu News                                     |
//+------------------------------------------------------------------+
void RunNewsLogic()
  {
   datetime currentTime = TimeCurrent();

   // 1. Cek apakah berita saat ini sudah selesai (melewati batas waktu after news)
   //    Jika ya, cari berita selanjutnya.
   long finishTime = nextNewsTime + (InpMinutesAfterNews * 60);
   
   if(nextNewsTime > 0 && currentTime > finishTime)
     {
      // Jika kita masih dalam mode aktif tapi waktu sudah habis
      if(isNewsMode)
        {
         Print("WAKTU HABIS! Berhenti trading untuk berita: ", nextNewsName);
         DeleteAllPendingOrders(); // HAPUS SEMUA ORDER
         isNewsMode = false;
        }
      // Cari berita baru
      FindNextNews();
     }

   // Jika belum ada jadwal berita, return
   if(nextNewsTime == 0) return;

   // 2. Hitung durasi (Countdown)
   long secondsToNews = nextNewsTime - currentTime;
   
   // Batas waktu berhenti (dalam detik negatif, karena sudah lewat)
   long stopThreshold = -(InpMinutesAfterNews * 60);

   // 3. LOGIKA AKTIVASI WINDOW
   // Aktif jika: (Waktu < Menit Sebelum) DAN (Waktu > Menit Sesudah [negatif])
   if(secondsToNews <= (InpMinutesBefore * 60) && secondsToNews > stopThreshold)
     {
      if(!isNewsMode)
        {
         Print("MODE AKTIF! Memulai Trap untuk: ", nextNewsName);
         isNewsMode = true;
        }
      
      DoDynamicTrap(); // Pasang/Update Pending Order
      
      string impactStr = (nextNewsImpact == CALENDAR_IMPORTANCE_HIGH) ? "HIGH" : "MEDIUM";
      string statusTime = (secondsToNews > 0) ? "Pre-News" : "Post-News";
      
      Comment("\n=== GOLD CATCHER (NEWS MODE) ===\n",
              "STATUS: TRAP ACTIVE (", statusTime, ")\n",
              "News: ", nextNewsName, " (", impactStr, ")\n",
              "Release Time: ", TimeToString(nextNewsTime), "\n",
              "Auto Stop In: ", (secondsToNews - stopThreshold), " seconds\n", // Hitung mundur ke stop
              "-------------------------");
     }
   else
     {
      // Di luar jendela waktu -> Standby
      if(isNewsMode)
        {
         DeleteAllPendingOrders();
         isNewsMode = false;
        }
        
      string impactStr = (nextNewsImpact == CALENDAR_IMPORTANCE_HIGH) ? "HIGH" : "MEDIUM";
      Comment("\n=== GOLD CATCHER (NEWS MODE) ===\n",
              "STATUS: STANDBY (Waiting)\n",
              "Next News: ", nextNewsName, " (", impactStr, ")\n",
              "Time: ", TimeToString(nextNewsTime), "\n",
              "Start In: ", (secondsToNews/60) - InpMinutesBefore, " minutes\n",
              "-------------------------");
     }
  }

//+------------------------------------------------------------------+
//| Logic: Mencari Berita (Calendar)                                 |
//+------------------------------------------------------------------+
void FindNextNews()
  {
   MqlCalendarValue values[];
   datetime start = TimeCurrent();
   datetime end = start + PeriodSeconds(PERIOD_D1) * 3; 
   
   nextNewsTime = 0; 
   
   if(CalendarValueHistory(values, start, end))
     {
      for(int i=0; i<ArraySize(values); i++)
        {
         MqlCalendarEvent event;
         if(CalendarEventById(values[i].event_id, event))
           {
            // Filter Impact
            if(event.importance != CALENDAR_IMPORTANCE_HIGH && 
               event.importance != CALENDAR_IMPORTANCE_MODERATE) continue;

            // Filter USD
            if(InpOnlyUSD && event.country_id != USA_COUNTRY_ID) continue;

            // PENTING: Cari berita yang waktunya > waktu sekarang
            if(values[i].time > TimeCurrent())
              {
               nextNewsTime = values[i].time;
               nextNewsName = event.name;
               nextNewsImpact = (int)event.importance; 
               return; 
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Logic: Dynamic Pending Orders (INTI STRATEGI)                    |
//+------------------------------------------------------------------+
void DoDynamicTrap()
  {
   // Jika sudah ada posisi terbuka, HAPUS pending order sisanya, biarkan posisi berjalan kena TP/SL
   if(PositionsTotal() > 0)
     {
      DeleteAllPendingOrders();
      return; 
     }

   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double Point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double targetBuyStop  = Ask + InpGapPoints * Point;
   double targetSellStop = Bid - InpGapPoints * Point;

   bool buyStopExists = false;
   bool sellStopExists = false;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(OrderGetInteger(ORDER_MAGIC) != InpMagicNum) continue;

      long type = OrderGetInteger(ORDER_TYPE);
      double currentPrice = OrderGetDouble(ORDER_PRICE_OPEN);

      // MODIFY BUY STOP
      if(type == ORDER_TYPE_BUY_STOP)
        {
         buyStopExists = true;
         if(MathAbs(currentPrice - targetBuyStop) > InpModifyStep * Point)
           {
            double sl = (InpStopLoss > 0) ? targetBuyStop - InpStopLoss * Point : 0;
            double tp = (InpTakeProfit > 0) ? targetBuyStop + InpTakeProfit * Point : 0;
            trade.OrderModify(ticket, targetBuyStop, sl, tp, ORDER_TIME_GTC, 0);
           }
        }

      // MODIFY SELL STOP
      if(type == ORDER_TYPE_SELL_STOP)
        {
         sellStopExists = true;
         if(MathAbs(currentPrice - targetSellStop) > InpModifyStep * Point)
           {
            double sl = (InpStopLoss > 0) ? targetSellStop + InpStopLoss * Point : 0;
            double tp = (InpTakeProfit > 0) ? targetSellStop - InpTakeProfit * Point : 0;
            trade.OrderModify(ticket, targetSellStop, sl, tp, ORDER_TIME_GTC, 0);
           }
        }
     }

   // PASANG ORDER BARU JIKA KOSONG
   if(!buyStopExists)
     {
      double sl = (InpStopLoss > 0) ? targetBuyStop - InpStopLoss * Point : 0;
      double tp = (InpTakeProfit > 0) ? targetBuyStop + InpTakeProfit * Point : 0;
      trade.BuyStop(InpLots, targetBuyStop, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "Trap Buy");
     }

   if(!sellStopExists)
     {
      double sl = (InpStopLoss > 0) ? targetSellStop + InpStopLoss * Point : 0;
      double tp = (InpTakeProfit > 0) ? targetSellStop - InpTakeProfit * Point : 0;
      trade.SellStop(InpLots, targetSellStop, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "Trap Sell");
     }
  }

//+------------------------------------------------------------------+
//| Fungsi Bantu: Hapus Semua Pending Order                          |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(OrderGetInteger(ORDER_MAGIC) == InpMagicNum) trade.OrderDelete(ticket);
     }
  }
//+------------------------------------------------------------------+