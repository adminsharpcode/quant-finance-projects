//+------------------------------------------------------------------+
//|                                               Универсал_1.70.mq4 |
//|                                                            Drknn |
//|                   02.03.2007                       drknn@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Drknn"
#property link      "drknn@mail.ru"
#include <Errors.mqh>
#include <Bazovie.mqh>
// ================ Параметры, настраиваимые пользователем ===========================
// ----- Параметры, общие для всех ордеров --------------------------------------------
extern string   t1="------ У открытых вручную MAGIC = 0 ------";
extern int      MAGIC=0;//У ордеров открытых вручную MAGIC=0 
extern double   Lot=0.2;//Лот для установки ордера
// ----- Разрешение установить тот или иной ордер ------------------------------------- 
extern string   t2="--- Выключатели отложенных ---";
extern bool     WaitClose=true;//Если true, то отложенный встанет только тогда, когда закроется рыночный
                               //иначе новый будет выставлен как только отложенный сработает
extern bool     Ustan_BuyStop=true;   //можно ли ставиь Бай-Cтоп если в рынке такого у нас нет
extern bool     Ustan_SellLimit=false; //можно ли ставиь Cелл-Лимит если в рынке такого у нас нет
extern bool     Ustan_SellStop=true;  //можно ли ставиь Cелл-Cстоп если в рынке такого у нас нет
extern bool     Ustan_BuyLimit=false;  //можно ли ставиь Бай-Лимит если в рынке такого у нас нет
// ----- Параметры рыночных ордеров ---------------------------------------------
extern string   t3="--- Параметры рыночных ---";
extern int      ryn_MaxOrderov=2;//ограничение максимального числа рыночных ордеров одного типа
extern int      ryn_TakeProfit=200; //Тейк-Профит  рыночного ордера 
extern int      ryn_StopLoss=100; //Стоп-Лосс  рыночного ордера
extern int      ryn_TrStop=100; //Трейлинг-Стоп рыночного ордера. Если = 0 то тарла нет
extern int      ryn_TrStep=10; //Шаг трала рыночного ордера
extern bool     WaitProfit = true; // Если true, то ждать профит = значению TrailingStop и только потом начинать тралить
                                    //Иначе, трейлинговать не дожидаясь положительного профита
// ----- Параметры стоповых ордеров ---------------------------------------------
extern string   t4="--- Параметры стоповых ---";
extern int      st_Step=50;//Расстояние в пунктах от уровня текущей цены до уорвня установки стопового ордера
extern int      st_TakeProfit=200; //Тейк-Профит  стоповых ордеров
extern int      st_StopLoss=100; //Стоп-Лосс  стоповых ордеров
extern int      st_TrStop=0; //Трейлинг-Стоп стоповых ордеров. Если = 0 то тарла нет и st_TrStep не важен
extern int      st_TrStep=3; //Шаг трала стоповых ордеров

// ----- Параметры лимитных ордеров ---------------------------------------------
extern string   t5="--- Параметры лимитных ---";
extern int      lim_Step=50;//Расстояние в пунктах от уровня текущей цены до уорвня установки лимитного ордера
extern int      lim_TakeProfit=200; //Тейк-Профит лимитных ордеров 
extern int      lim_StopLoss=100; //Стоп-Лосс лимитных ордеров
extern int      lim_TrStop=0; //Трейлинг-Стоп лимитных ордеров. Если = 0 то тарла нет и lim_TrStep не важен
extern int      lim_TrStep=3; //Шаг трейлинга лимитных ордеров

//------ Открыть (устаовить) ордера в заданное время ----------------------------------------------------------
extern string   t6="--- Только для работы по времени ---";
extern bool     UseTime=true;//вкл/выкл привязку к указанноу времени. Если=false, то все таймовые параметры не важны, 
                             // а именно, параметры: Hhour, Mminute, Popravka_Hhour, TIME_Buy, TIME_Sell, TIME_BuyStop,
                             // TIME_SellLimit, TIME_SellStop, TIME_BuyLimit.
extern int      Hhour=23;//терминальные часы совершения сделки
extern int      Mminute=59;//терминальные минуты совершения сделки
extern bool     TIME_Buy=false;//вкл/выкл открываться ли на покупку в заданное время
extern bool     TIME_Sell=false;//вкл/выкл открываться ли на продажу
extern bool     TIME_BuyStop=true;    //можно ли установить БайCтоп в заданное время
extern bool     TIME_SellLimit=false; //можно ли установить CеллЛимит в заданное время
extern bool     TIME_SellStop=true;   //можно ли установить CеллCстоп в заданное время
extern bool     TIME_BuyLimit=false;  //можно ли установить БайЛимит в заданное время

// ----- Параметры пипсовки ----------------------------------------------------
extern string   t7="--- Пипсовка ---";
extern int      PipsProfit=0; //прибыль при пипсовке можно ставить 1, 2, 3, ...
extern int      PipsLoss=0; //убыток при пипсовке можно ставить 1, 2, 3, ...
// -----------   Отлавливаем увеличение депозита --------------------------
extern string   t8="--- Глобальные уровни ---";
extern bool     UseGlobalLevels=true;//отловить увеличение и уменьшение депозита заданное число процентов
                             //если UseGlobalLevels=false, то значениt Global_TakeProfit и Global_StopLoss не важно.
extern double   Global_TakeProfit=2.0;//Глобальный Тейк-Профит (задаётся в процентах)
extern double   Global_StopLoss=2.0;//Глобальный Стоп-Лосс (задаётся в процентах)
extern bool     UseAlert=true;//использовать сообщение в окне алертов
extern bool     ryn_CloseAll_Profit=false;//вкл/выкл закрыть позиции по всем валютным парам по достижении глобального профита
extern bool     ryn_CloseAll_Loss=false;//вкл/выкл закрыть позиции по всем валютным парам по достижении глобального лосса
extern bool     DeleteOtlozh=false;//вкл/выкл удалить при этом и отложенные ордера


// ----- Прочие установки ------------------------------------------------------  
extern string   t9="--- Прочие параметры ---";
extern int      Proskalz = 3; //Проскальзывание в пунктах 
extern bool     UseOrderSound = true;  // Использовать звуковой сигнал для установки ордеров
extern bool     UseTrailingSound = true;  // Использовать звуковой сигнал для трейлинга
extern string   NameOrderSound  = "alert.wav";  // Наименование звукового файла для ордеров
extern string   NameTrallingSound  = "expert.wav";// Наименование звукового файла для трейлинга

// =======================================================================================

// ================== Глобальные переменные ===============================================================  
string     Comm1,Comm2,Comm3,Comm4,Comm5,Comm6,Comm7,ED,SMB; 
double     PNT,NewPrice,SL,TP,Balans,Free;
int        MinLevel,i,SchBuyStop,SchSellStop,SchBuyLimit,SchSellLimit,SchSell,SchBuy,SBid,SAsk,BBid,BAsk,GTP,GSL,GLE,total;
bool       fm,Rezult,TrailBuyStop,TrailSellStop,TrailBuyLimit,TrailSellLimit,SigBuy,SigSell,NewOrder;
bool       SigTIME_Buy,SigTIME_Sell,SigTIME_BuyStop,SigTIME_SellLimit,SigTIME_SellStop,SigTIME_BuyLimit;
// ========================================================================================================

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   if (!IsTesting()) {
     if(!IsExpertEnabled()) {
       Alert("Ошибка! Не нажата кнопка *Советники*");
       Comment("Ошибка! Не нажата кнопка *Советники* над этой надписью.");
       return(0);
     }
     else {
       Comment("Инициализация прошла успешно. Ждём свежую котировку.");
       Print("Инициализация прошла успешно. Ждём свежую котировку.");
     }
   }
   SMB=Symbol();//Символ валютной пары
   PNT=MarketInfo(SMB,MODE_POINT);//Размер пункта в валюте котировки. Для текущего инструмента хранится в предопределенной переменной Point
   MinLevel=MarketInfo(SMB,MODE_STOPLEVEL);//Минимально допустимый уровень стоп-лосса/тейк-профита в пунктах
   Proverka();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   if (!IsTesting())
    {
     Comment("");
     Print("Советник деинициализирован (выключен совсем)");
    }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
  RefreshRates();
  //----Первичные проверки данных
  if(!IsTradeAllowed()) {
    Comment("Торговля запрещена в настройках терминала, либо торговый поток занят");
    return(0);
  }
  Proverka();
  //----Конец первичных проверок данных
 

  if(ryn_TrStop>0 && ryn_TrStop>=MinLevel) Comm1="Трал рыночных - Вкл."; else Comm1="Трал рыночных - Откл.";
  if (lim_TrStop>0 && lim_TrStop>=MinLevel) Comm2="Трал лимитных - Вкл."; else Comm2="Трал лимитных - Откл.";
  if (st_TrStop>0 && st_TrStop>=MinLevel) Comm3="Трал стоповых - Вкл."; else Comm3="Трал стоповых - Откл.";
  if (PipsProfit>0||PipsLoss>0) Comm4="Пипсовка - Вкл"; else Comm4="Пипсовка - Откл";
  double OtlTP=(Balans/100*Global_TakeProfit+Balans);
  double OtlSL=(Balans-Balans/100*Global_StopLoss);
  GTP=MathCeil(OtlTP);
  GSL=MathCeil(OtlSL);
  if (UseGlobalLevels) {
    Comm5="- - - - Глобальные уровни - - - -";
    Comm6="Глобальный Тейк-Профит = "+GTP+" $";
    Comm7="Глобальный Стоп-Лосс   = "+GSL+" $";
  }
  else {Comm5="Глобальные уровни - Откл"; Comm6=""; Comm7="";}
  SMB=Symbol();
  Comment("Ордеров сейчас для ",SMB," :","\n","Buy = ",SchBuy_b(MAGIC),"       Sell = ",SchSell_b(MAGIC),"\n","BuyStop = ",SchBuyStop_b(MAGIC),
        "   SellLimit = ",SchSellLimit_b(MAGIC),"\n","SellStop = ",SchSellStop_b(MAGIC),"    BuyLimit = ",SchBuyLimit_b(MAGIC),"\n",Comm1,
        "\n",Comm2,"\n",Comm3,"\n",Comm4,"\n",Comm5,"\n",Comm6,"\n",Comm7);

  // ========================== Установка отложенных ордеров ====================================
  if(Ustan_BuyLimit) {
    if((SchBuyLimit_b(MAGIC)==0 && (SchBuy_b(MAGIC)<ryn_MaxOrderov || !WaitClose))
        && (Ustan_BuyLimit && lim_Step>=MinLevel)) { 
      UstanBuyLimit_b(Lot,lim_Step,lim_TakeProfit,lim_StopLoss,Proskalz,MAGIC,UseOrderSound);
    }
  }
  if(Ustan_BuyStop) {
    if((SchBuyStop_b(MAGIC)==0 && (SchBuy_b(MAGIC)<ryn_MaxOrderov || !WaitClose)) && Ustan_BuyStop && st_Step>=MinLevel) {
      UstanBuyStop_b(Lot,st_Step,st_TakeProfit,st_StopLoss, Proskalz,MAGIC,UseOrderSound);
    }  
  }
  if(Ustan_SellStop) {
     if((SchSellStop_b(MAGIC)==0 && (SchSell_b(MAGIC)<ryn_MaxOrderov || !WaitClose))&&Ustan_SellStop && st_Step>=MinLevel) {
       UstanSellStop_b(Lot,st_Step,st_TakeProfit,st_StopLoss,Proskalz,MAGIC,UseOrderSound);
     }  
  }
  if(Ustan_SellLimit) {
    if((SchSellLimit_b(MAGIC)==0 && (SchSell_b(MAGIC)<ryn_MaxOrderov || !WaitClose)) && Ustan_SellLimit && lim_Step>=MinLevel) {
      UstanSellLimit_b(Lot,lim_Step,lim_TakeProfit,lim_StopLoss,Proskalz,MAGIC,UseOrderSound);
    }  
  }
  //=============================================================================================

  //==========================  Работа по заданному времени   =======================
  if(UseTime) {
     SigTIME_Buy=false;  SigTIME_BuyStop=false;   SigTIME_SellStop=false;
     SigTIME_Sell=false; SigTIME_SellLimit=false; SigTIME_BuyLimit=false;
     if(Hour()==Hhour && Minute()==Mminute) {//если текущие час и минута совпадают
        if(TIME_Buy) {
          SigTIME_Buy=true;
          if(UstanRynBuy_b(Lot,ryn_TakeProfit,ryn_StopLoss,Proskalz,MAGIC,UseOrderSound)==true)
          {SigTIME_Buy=false;}
        }
        if(TIME_Sell) {
          SigTIME_Sell=true;
          if(UstanRynSell_b(Lot,ryn_TakeProfit,ryn_StopLoss,Proskalz,MAGIC,UseOrderSound)==true)
            {SigTIME_Sell=false;}
        }
        if(TIME_BuyStop) {
          SigTIME_BuyStop=true;
          if((SchBuyStop_b(MAGIC)==0 && (SchBuy_b(MAGIC)<ryn_MaxOrderov || !WaitClose)) && SigTIME_BuyStop && st_Step>=MinLevel) {
            if(UstanBuyStop_b(Lot,st_Step,st_TakeProfit,st_StopLoss,Proskalz,MAGIC,UseOrderSound)==true) {
              SigTIME_BuyStop=false;
            }
          }  
        }
        if(TIME_SellLimit) {
           SigTIME_SellLimit=true;
           if((SchSellLimit_b(MAGIC)==0 && (SchSell_b(MAGIC)<ryn_MaxOrderov || !WaitClose))&& SigTIME_SellLimit && lim_Step>=MinLevel) {
             if(UstanSellLimit_b(Lot,lim_Step,lim_TakeProfit,lim_StopLoss,Proskalz,MAGIC,UseOrderSound)==true) {
               SigTIME_SellLimit=false;
             }
           }  
        }
        if(TIME_SellStop) {
           SigTIME_SellStop=true;
           if((SchSellStop_b(MAGIC)==0 && (SchSell_b(MAGIC)<ryn_MaxOrderov||!WaitClose)) && SigTIME_SellStop && st_Step>=MinLevel) {
             if(UstanSellStop_b(Lot,st_Step,st_TakeProfit,st_StopLoss,Proskalz,MAGIC,UseOrderSound)==true) {
               SigTIME_SellStop=false;
             }
           }  
        } 
        if(TIME_BuyLimit) {
          SigTIME_BuyLimit=true;
          if((SchBuyLimit_b(MAGIC)==0 && (SchBuy_b(MAGIC)<ryn_MaxOrderov || !WaitClose)) && SigTIME_BuyLimit && lim_Step>=MinLevel) {
            if(UstanBuyLimit_b(Lot,lim_Step,lim_TakeProfit,lim_StopLoss,Proskalz,MAGIC,UseOrderSound)==true) {
              SigTIME_BuyLimit=false;
            }
          }  
        }
     }
  }  
  //==================================================================================
  
  //============== Отлавливаем увеличение депозита на Pojmat процентов =========================  
  if(UseGlobalLevels) {//Если разрешено отловить процент увеличения/уменьшения депозита
    Balans=AccountBalance();//Баланс счёта
    Free=AccountEquity();//Текущее количество денег в статье "Средства"
    
    
    if ((Free-Balans)>=(Balans/100*Global_TakeProfit)) {
      
      if(DeleteOtlozh){DeleteAllOtlozh_b();}
      if (ryn_CloseAll_Profit){CloseAll_b(DeleteOtlozh,Proskalz);}
      if(UseAlert){
        Alert("Депозит увеличен на ",Global_TakeProfit," процентов. Суммарный профит = ",Free);
      }  
    }
    if ((Balans-Free)>=(Balans/100*Global_StopLoss)) {
      
      if(DeleteOtlozh){DeleteAllOtlozh_b();}
      if (ryn_CloseAll_Loss){CloseAll_b(DeleteOtlozh,Proskalz);}
      if(UseAlert){
        Alert("Депозит уменьшен на ",Global_StopLoss," процентов. Суммарный Стоп-Лосс = ",Free);
      }  
    }        
  }
  //============================================================================================
  
  //================= Взятие пипспрофита  и пипслосса =============
  Pipsovka_b(PipsProfit,Proskalz,MAGIC);
  PipsovkaLOSS_b(PipsLoss,Proskalz,MAGIC);
  //===============================================================
  
  // ========== Трейлинг рыночных ордеров ======================================
  TrailingRyn_b(ryn_TrStop,ryn_TrStep,Proskalz,MAGIC,WaitProfit,UseTrailingSound);                      
  // ===========================================================================
  
  //============ Трейлинг отложенных ордеров =============================================================
  RefreshRates(); SMB=Symbol();  
  if((st_TrStop>0 && SchBuyStop_b(MAGIC)+SchSellStop_b(MAGIC)>0) || (SchBuyLimit_b(MAGIC)+SchSellLimit_b(MAGIC)>0 && lim_TrStop>0)) {
    for (i=OrdersTotal()-1;i>=0;i--)
      {//Начало цикла
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {WriteError(i);}
        else{//начало работы с выбранным ордером
          if(OrderSymbol()!=SMB || OrderMagicNumber()!=MAGIC || OrderType()==OP_BUY || OrderType()==OP_SELL) continue;
          if(OrderType()==OP_BUYSTOP) { // Он наверху и едет вниз
            if(Ask<OrderOpenPrice()-(st_TrStop+st_TrStep)*Point)
              {TrailBuyStop_b(st_TakeProfit,st_StopLoss,st_TrStop,MAGIC,UseTrailingSound);}
          }
          if(OrderType()==OP_SELLLIMIT) {// Он наверху и едет вниз
            if(Bid<OrderOpenPrice()-(st_TrStop+st_TrStep)*Point)
            {TrailSellLimit_b(lim_TakeProfit,lim_StopLoss,lim_TrStop,MAGIC,UseTrailingSound);}
          }
          if(OrderType()==OP_SELLSTOP) { // Он внизу и едет вверх
            if(Bid>OrderOpenPrice()+(st_TrStop+st_TrStep)*Point)
            {TrailSellStop_b(st_TakeProfit,st_StopLoss,st_TrStop,MAGIC,UseTrailingSound);}
          }
          if(OrderType()==OP_BUYLIMIT) { // Он внизу и едет вверх
            if(Ask>OrderOpenPrice()+(st_TrStop+st_TrStep)*Point)
            {TrailBuyLimit_b(lim_TakeProfit,lim_StopLoss,lim_TrStop,MAGIC,UseTrailingSound);}
          }
        }//конец работы с выбранным ордером 
    }//Конец цикла
  }
  //====================================================================================================
  
  return(0);
}
//+ ========================== Конец работы советника ========================================================================== +



// ___________________________________________________________________________________________
//|                                                                                           |
//|                                                                                           |
//|                       Далее идут подпрограммы (функции),                                  |
//|                  которые в случае надобности вызываются из тела советника                 |
//|                                                                                           |
//|___________________________________________________________________________________________|


// ======================= Проверка корректности пользовательских установок =============================================
void Proverka()
{
if(ryn_TrStop<MinLevel && ryn_TrStop!=0) {Comment("Ошибка! ТрейлингСтоп рыночных ордеров не может быть менее ",MinLevel);
                                          Print("Ошибка! ТрейлингСтоп рыночных ордеров не может быть менее ",MinLevel);
                                          Alert("Ошибка! ТрейлингСтоп рыночных ордеров не может быть менее ",MinLevel);
                                          return(0);}                                       
   if(ryn_TrStop>=MinLevel && ryn_TrStep==0) {Comment("Ошибка! Шаг трейлинга рыночных ордеров не может быть менее 1");
                                          Print("Ошибка! Шаг трейлинга рыночных ордеров не может быть менее 1");
                                          Alert("Ошибка! Шаг трейлинга рыночных ордеров не может быть менее 1");
                                          return(0);}                                       
   if(ryn_TakeProfit<MinLevel && ryn_TakeProfit!=0) {Comment("Ошибка! ryn_TakeProfit не может быть менее ",MinLevel);
                                          Print("Ошибка! ryn_TakeProfit не может быть менее ",MinLevel);
                                          Alert("Ошибка! ryn_TakeProfit не может быть менее ",MinLevel);
                                          return(0);}
   if(ryn_StopLoss<MinLevel && ryn_StopLoss!=0) {Comment("Ошибка! ryn_StopLoss не может быть менее ",MinLevel);
                                          Print("Ошибка! ryn_StopLoss не может быть менее ",MinLevel);
                                          Alert("Ошибка! ryn_StopLoss не может быть менее ",MinLevel);
                                          return(0);}
   
   if(st_TakeProfit<MinLevel && st_TakeProfit!=0) {Comment("Ошибка! st_TakeProfit не может быть менее ",MinLevel);
                                          Print("Ошибка! st_TakeProfit не может быть менее ",MinLevel);
                                          Alert("Ошибка! st_TakeProfit не может быть менее ",MinLevel);
                                          return(0);}
   if(st_StopLoss<MinLevel && st_StopLoss!=0) {Comment("Ошибка! st_StopLoss не может быть менее ",MinLevel);
                                          Print("Ошибка! st_StopLoss не может быть менее ",MinLevel);
                                          Alert("Ошибка! st_StopLoss не может быть менее ",MinLevel);
                                          return(0);}
   if(st_TrStop<MinLevel && st_TrStop!=0) {Comment("Ошибка! ТрейлингСтоп стоповых ордеров не может быть менее ",MinLevel);
                                          Print("Ошибка! ТрейлингСтоп стоповых ордеров не может быть менее ",MinLevel);
                                          Alert("Ошибка! ТрейлингСтоп стоповых ордеров не может быть менее ",MinLevel);
                                          return(0);}
   if(st_TrStop>=MinLevel && st_TrStep==0) {Comment("Ошибка! шаг тарала стоповых ордеров не может быть менее 1");
                                          Print("Ошибка! ТрейлингСтоп стоповых ордеров не может быть менее 1");
                                          Alert("Ошибка! ТрейлингСтоп стоповых ордеров не может быть менее 1");
                                          return(0);}
   if(st_Step<MinLevel)                   {Comment("Ошибка! переменная st_Step не может быть менее ",MinLevel);
                                          Print("Ошибка! переменная st_Step не может быть менее ",MinLevel);
                                          Alert("Ошибка! переменная st_Step не может быть менее ",MinLevel);
                                          return(0);}
   
   if(lim_TakeProfit<MinLevel && lim_TakeProfit!=0) {Comment("Ошибка! lim_TakeProfit не может быть менее ",MinLevel);
                                          Print("Ошибка! lim_TakeProfit не может быть менее ",MinLevel);
                                          Alert("Ошибка! lim_TakeProfit не может быть менее ",MinLevel);
                                          return(0);}
   if(lim_StopLoss<MinLevel && lim_StopLoss!=0) {Comment("Ошибка! lim_StopLoss не может быть менее ",MinLevel);
                                          Print("Ошибка! lim_StopLoss не может быть менее ",MinLevel);
                                          Alert("Ошибка! lim_StopLoss не может быть менее ",MinLevel);
                                          return(0);}
   if(lim_TrStop<MinLevel && lim_TrStop!=0) {Comment("Ошибка! ТрейлингСтоп лимитных ордеров не может быть менее ",MinLevel);
                                          Print("Ошибка! ТрейлингСтоп лимитных ордеров не может быть менее ",MinLevel);
                                          Alert("Ошибка! ТрейлингСтоп лимитных ордеров не может быть менее ",MinLevel);
                                          return(0);}
   if(lim_TrStop>=MinLevel && lim_TrStep==0) {Comment("Ошибка! Шаг тарала лимитных ордеров не может быть менее 1");
                                          Print("Ошибка! Шаг тарала лимитных ордеров не может быть менее 1");
                                          Alert("Ошибка! Шаг тарала лимитных ордеров не может быть менее 1");
                                          return(0);}
   if(lim_Step<MinLevel)                  {Comment("Ошибка! переменная lim_Step не может быть менее ",MinLevel);
                                          Print("Ошибка! переменная lim_Step не может быть менее ",MinLevel);
                                          Alert("Ошибка! переменная lim_Step не может быть менее ",MinLevel);
                                          return(0);}                                                                                 
}
// ============================================================================================================================


