#property copyright "Scriptong"
#property link      "http://advancetools.net"
#property description "Отображение тиковых объемов по дням в виде гистограммы кластеров с шагом 1 пункт.\nОписание доступно на сайте AdvanceTools.net в разделе \"Тиковые объемы.\""
#property strict

#property indicator_chart_window
#property indicator_buffers 1

struct TickStruct                                                                                  // Структура для записи данных об одном тике
{
   datetime time;
   double   bid;
   double   ask;   
};

#define MAX_POINTS_DAY_HEIGHT             20000                                                    // Максимальная высота дня в пунктах - размер массива для хранения количества повторов уровней

// Настроечные параметры индикатора
input color    i_levelColor            = clrGray;                                                  // Цвет гистограммы объемов
input int      i_indBarsCount          = 10000;                                                    // Количество баров для отображения

// Прочие глобальные переменные индикатора
bool              g_activate;                                                                      // Признак успешной инициализации индикатора
     
int               g_levelRepeat[MAX_POINTS_DAY_HEIGHT],                                            // Массив для записи количества повторов уровня. Первый элемент - кол-во тиков на уровне g_minDayPrice,
                                                                                                   // ..второй - g_minDayPrice + point и т. д. до количества g_levelsCnt
                  g_levelsCnt,                                                                     // Текущее количество уровней в дне
                  g_curDayNumber;                                                                  // Номер в году для текущего обрабатываемого дня
                                                                                                   
double            g_minDayPrice,                                                                   // Минимальная цена текущего дня, на которую приходится первый элемент массива количества повторов уровня
                  g_point;
       
datetime          g_curDayStart;                                                                   // Время открытия дня, для которого собираются тиковые данные

TickStruct        g_ticks[];                                                                       // Массив для хранения тиков, поступивших после начала работы индикатора                    

#define PREFIX "CLSTRBXNDH_"                                                                       // Префикс имени графических объектов, отображаемых индикатором 
     
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                                                                                                                          |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
int OnInit()
{
   g_activate = false;                                                                             // Индикатор не инициализирован
   
   if (!IsTuningParametersCorrect())                                                               // Неверно указанные значения настроечных параметров - причина неудачной инициализации
      return INIT_FAILED;                                 
      
   if (!IsLoadTempTicks())                                                                         // Загрузка данных о тиках, сохраненных за предыдущий период работы индикатора   
      return INIT_FAILED;
      
   if (Period() >= PERIOD_D1)
      Print(WindowExpertName(), ": индикатор не отображает данные на таймфреймах D1 и старше. Также не производится накопление тиков.");
   else
      g_activate = true;                                                                           // Индикатор успешно инициализирован
   
   return INIT_SUCCEEDED;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Проверка корректности настроечных параметров                                                                                                                                                      |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsTuningParametersCorrect()
{
   string name = WindowExpertName();

   int period = Period();
   if (period == 0)
   {
      Alert(name, ": фатальная ошибка терминала - период 0 минут. Индикатор отключен.");
      return (false);
   }
   
   g_point = Point;
   if (g_point == 0)
   {
      Alert(name, ": фатальная ошибка терминала - величина пункта равна нулю. Индикатор отключен.");
      return (false);
   }
   
   g_curDayStart = 0;
   g_curDayNumber = -1;
   
   return (true);
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Чтение данных о тиках, накопленных в течение предыдущей рабочей сессии программы                                                                                                                  |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsLoadTempTicks()
{
   // Открытие файла тиковой истории
   int hTicksFile = FileOpen(Symbol() + "temp.tks", FILE_BIN | FILE_READ | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if (hTicksFile < 1)
      return true;
      
   // Распределение памяти для массива g_ticks
   int recSize = (int)(FileSize(hTicksFile) / sizeof(TickStruct));   
   if (ArrayResize(g_ticks, recSize, 1000) < 0)
   {
      Alert(WindowExpertName(), ": не удалось распределить память для подкачки данных из временного файла тиков. Индикатор отключен.");
      FileClose(hTicksFile);
      return false;
   }
   
   // Чтение файла
   int i = 0;
   while (i < recSize)
   {
      if (FileReadStruct(hTicksFile, g_ticks[i]) == 0)
      {
         Alert(WindowExpertName(), ": ошибка чтения данных из временного файла. Индикатор отключен.");
         return false;
      }
      
      i++;
   }

   FileClose(hTicksFile);
   return true;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                                                                                                                        |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if (!IsSavedFile())                                                                             // Если ни один из подключенных индикаторов не сохранил данные, то их сохранит текущий индикатор
      SaveTempTicks();                                                                             // Сохранение данных о тиках, накопленных за текущий период работы индикатора   
   DeleteAllObjects();
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Проверка наличия записанных данных другим индикатором                                                                                                                                             |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsSavedFile()
{
   // Получение времени поступления последнего записанного тика
   int lastTickIndex = ArraySize(g_ticks) - 1;
   if (lastTickIndex < 0)                                                                          // Ни один тик не был получен. Запись данных не требуется
      return true;

   // Открытие файла тиковой истории
   int hTicksFile = FileOpen(Symbol() + "temp.tks", FILE_BIN | FILE_READ | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if (hTicksFile < 1)
      return false;
   
   // Перемещение к последней записи в файле
   if (!FileSeek(hTicksFile, -sizeof(TickStruct), SEEK_END))
   {
      FileClose(hTicksFile);
      return false;
   }
   
   // Чтение последней записи и закрытие файла
   TickStruct tick;
   uint readBytes = FileReadStruct(hTicksFile, tick);
   FileClose(hTicksFile);
   if (readBytes == 0)
      return false;
      
   // Сравнение даты тика, записанного в файле, и даты последнего поступившего тика
   return tick.time >= g_ticks[lastTickIndex].time;                                                // Дата/время последнего записанного в файле тика больше или равна дате/времени..
                                                                                                   // ..зарегистрированного тика. Значит, файл уже записан, и повторная запись не требуется
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Сохранение данных о тиках, накопленных за текущую рабочую сессию программы                                                                                                                        |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void SaveTempTicks()
{
   // Создание файла тиковой истории
   int hTicksFile = FileOpen(Symbol() + "temp.tks", FILE_BIN | FILE_READ | FILE_WRITE | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if (hTicksFile < 1)
      return;
   
   // Запись файла
   int total = ArraySize(g_ticks), i = 0;
   while (i < total)
   {
      if (FileWriteStruct(hTicksFile, g_ticks[i]) == 0)
      {
         Print("Ошибка сохранения данных во временный файл...");
         return;
      }
      
      i++;
   }

   FileClose(hTicksFile);
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Удаление всех объектов, созданных программой                                                                                                                                                      |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void DeleteAllObjects()
{
   for (int i = ObjectsTotal() - 1; i >= 0; i--)     
      if (StringSubstr(ObjectName(i), 0, StringLen(PREFIX)) == PREFIX)
         ObjectDelete(ObjectName(i));
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Отображение трендовой линии                                                                                                                                                                       |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void ShowTrendLine(datetime time1, double price1, datetime time2, int index, string toolTip, color clr)
{
   string name = PREFIX + "LINE_" + IntegerToString(time1) + IntegerToString(index);
   
   if (ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price1);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_RAY, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, toolTip);
      return;
   }
   
   ObjectMove(0, name, 0, time1, price1);
   ObjectMove(0, name, 1, time2, price1);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, toolTip);
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Определение индекса бара, с которого необходимо производить перерасчет                                                                                                                            |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
int GetRecalcIndex(int& total, const int ratesTotal, const int prevCalculated)
{
   // Определение первого бара истории, на котором будут доступны адекватные значения индикатора
   total = ratesTotal - 1;                                                                         
                                                   
   // А может значения индикатора не нужно отображать на всей истории?
   if (i_indBarsCount > 0 && i_indBarsCount < total)
      total = MathMin(i_indBarsCount, total);                      
                                                   
   // Первое отображение индикатора или произошла подкачка данных, т. е. на предыдущем тике баров было не на один бар меньше, как при нормальном развитии истории, а на два или более баров меньше
   if (prevCalculated < ratesTotal - 1)                     
   {       
      DeleteAllObjects();
      return (total);
   }
   
   // Нормальное развитие истории. Количество баров текущего тика отличается от количества баров предыдущего тика не больше, чем на один бар
   return (MathMin(ratesTotal - prevCalculated, total));                            
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Равны ли числа?                                                                                                                                                                                   |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsValuesEquals(double first, double second)
{
   return (MathAbs(first - second) < g_point / 10);
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Запись данных о тике в массив g_ticks                                                                                                                                                             |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsUpdateTicksArray(TickStruct &tick)
{
   int total = ArraySize(g_ticks);
   if (ArrayResize(g_ticks, total + 1, 100) < 0)
   {
      Alert(WindowExpertName(), ": индикатору не хватает памяти для сохранения данных об очередном тике.");
      return false;
   }
   
   g_ticks[total] = tick;
   return true;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Проверка необходимости открытия нового дня                                                                                                                                                        |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsNewDayOpen(datetime time, double clusterPrice)
{
   int curTickDayNumber = TimeDayOfYear(time);
   if (g_curDayNumber == curTickDayNumber)                                                         // Новый тик принадлежит текущему дню
      return false;
      
   // Новый тик принадлежит другому дню
   ShowHistogramm();
   string dayOpen = TimeToString(time, TIME_DATE);
   g_curDayStart = StringToTime(dayOpen);
   g_curDayNumber = curTickDayNumber;

   // Обнуление текущей истории
   g_levelsCnt = 1;
   g_minDayPrice = clusterPrice;
   return true;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Запись данных о тике в массив g_levelRepeat                                                                                                                                                       |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsSaveTickData(TickStruct &curTick)
{
   // Проверка необходимости открытия нового дня
   if (IsNewDayOpen(curTick.time, curTick.bid))
      return true;

   // Определение индекса массива g_levelRepeat
   int index = (int)MathRound((curTick.bid - g_minDayPrice) / g_point);
   
   // Новый тик повторяет уже имеющуюся цену
   if (index >= 0 && index < g_levelsCnt)
   {
      g_levelRepeat[index]++;
      return true;
   }

   // Необходимо расширение границ массива g_levelRepeat   
   if (index >= MAX_POINTS_DAY_HEIGHT || g_levelsCnt - index + 1 >= MAX_POINTS_DAY_HEIGHT)
   {
      Alert(WindowExpertName(), ": индикатору не хватает памяти для корректной работы.");
      return false;
   }

   // Новый тик обновил максимум дня
   if (index >= g_levelsCnt)
   {
      for (int i = g_levelsCnt; i < index; i++)                                                    // Заполнение образовавшейся дыры (если index - g_levelsCnt > 0) нулями
         g_levelRepeat[i] = 0;
         
      g_levelRepeat[index] = 1;
      g_levelsCnt = index + 1;
      return true;
   }
   
   // Новый тик обновил минимум дня
   index = -index;
   g_levelsCnt += index;
   for (int i = g_levelsCnt - 1; i >= index; i--)                                                      // Перемещение содержимоо массива на index элементов вверх
      g_levelRepeat[i] = g_levelRepeat[i - index];
      
   for (int i = index - 1; i > 0; i--)                                                             // Заполнение образовавшейся дыры (если index > 1) нулями
      g_levelRepeat[i] = 0;
      
   g_levelRepeat[0] = 1;
   g_minDayPrice = curTick.bid;
   return true;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Чтение одного тика из файла                                                                                                                                                                       |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsReadTimeAndBidAskOfTick(int hTicksFile, TickStruct &tick)
{
   if (FileIsEnding(hTicksFile))
      return false;
   
   uint bytesCnt = FileReadStruct(hTicksFile, tick);
   return bytesCnt == sizeof(TickStruct);
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Считывание тиков из основного файла тиковой истории                                                                                                                                               |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool IsReadTicksFromFile(datetime &lastTime, int total)
{
   // Обнуление текущей истории
   g_curDayStart = 0;
   g_curDayNumber = -1;

   // Открытие файла тиковой истории
   int hTicksFile = FileOpen(Symbol() + ".tks", FILE_BIN | FILE_READ | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if (hTicksFile < 1)
      return true;
   
   // Чтение файла
   TickStruct tick = {0, 0, 0};
   bool result = true;
   datetime viewStartTime = Time[total];
   while (!IsStopped())
   {
      bool fileClose = !IsReadTimeAndBidAskOfTick(hTicksFile, tick);
      if (fileClose || tick.time == 0)
         break;

      if (tick.time < viewStartTime)
         continue;
         
      if (!IsSaveTickData(tick))
      {
         result = false;
         break;
      }
   }

   FileClose(hTicksFile);
   lastTime = tick.time;                                                                           // Указываем последнюю прочитанную дату, чтобы дополнить полученные данные из локального буфера..
                                                                                                   // ..при необходимости
   return result;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Чтение данных о тиках из локального буфера, чтобы не потерять тики, пришедшие после начала работы индикатора, но не попавшие в файл                                                               |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
bool ReadTicksFromBuffer(datetime lastTime, int total)
{
   // Возможно, данные из главного тикового файла заканчиваются до момента начала интервала отображения данных индикатора
   lastTime = (datetime)MathMax(lastTime, Time[total]);

   // Поиск индекса для g_ticks, с которого необходимо продолжить чтение данных
   int totalTicks = ArraySize(g_ticks);
   int i = 0;
   while (i < totalTicks && lastTime >= g_ticks[i].time)
      i++;
      
   // Осуществление дополнения
   datetime timeTotal = Time[0] + PeriodSeconds();
   while (i < totalTicks && g_ticks[i].time < timeTotal)
   {
      if (!IsSaveTickData(g_ticks[i]))
         return false;
      
      i++;
   }
   
   return true;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Отображение гистограммы                                                                                                                                                                           |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void ShowHistogramm()
{
   int maxVolume = ArrayMaximum(g_levelRepeat, g_levelsCnt);
   if (maxVolume < 0 || maxVolume >= g_levelsCnt)
      return;

   int curDayStartBarIndex = 0, dayDuration = 0;
   datetime curDayLastBarTime = GetCurDayLastBarTime(curDayStartBarIndex, dayDuration);
   for (int i = 0; i < g_levelsCnt; i++) 
   {
      double price = g_minDayPrice + i * g_point;
      string toolTip = "Кластер: " + DoubleToString(price, Digits) + ". Объем: " + IntegerToString(g_levelRepeat[i]);
      datetime histRightTime = GetHistRightTime(curDayLastBarTime, curDayStartBarIndex, dayDuration, g_levelRepeat[i], g_levelRepeat[maxVolume]);
      ShowTrendLine(g_curDayStart, price, histRightTime, i, toolTip, i_levelColor);
   }
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Определение времени открытия последнего бара текущего дня (исходя из значения g_curDayOpen), а также индексов начального и конечного баров дня                                                    |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
datetime GetCurDayLastBarTime(int &curDayStartBarIndex, int &dayDuration)
{
   // Индекс начального бара дня
   curDayStartBarIndex = iBarShift(NULL, 0, g_curDayStart);
   while (curDayStartBarIndex > 0 && Time[curDayStartBarIndex] < g_curDayStart)
      curDayStartBarIndex--;

   // Индекс конечного бара дня
   datetime absoluteDayEnd = g_curDayStart + PERIOD_D1 * 60 - 1;
   int curDayEndBarIndex = iBarShift(NULL, 0, absoluteDayEnd);
   while (curDayEndBarIndex < curDayStartBarIndex && Time[curDayEndBarIndex] > absoluteDayEnd)
      curDayEndBarIndex++;
    
   // Время окончания дня в соответствии с индексом конечного бара
   dayDuration = curDayStartBarIndex - curDayEndBarIndex;

   return Time[curDayEndBarIndex] + PeriodSeconds() - 1;
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Вычисление времени бара, на котором должна заканчиваться линия гистограммы с указанным тиковым объемом                                                                                            |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
datetime GetHistRightTime(datetime curDayLastBarTime, int curDayStartBarIndex, int dayDuration, int tickVolume, int maxVolume)
{
   int barsIndex = curDayStartBarIndex - (int)(dayDuration * tickVolume / 1.0 / maxVolume);
   if (barsIndex < 0 || barsIndex >= Bars)
      return curDayLastBarTime;

   return Time[barsIndex];
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Осуществление чтения данных из файла и полное отображение гистограммы                                                                                                                             |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void ShowNewData(int total)
{
   // Чтение данных из файла
   datetime lastTime = 0;
   if (!IsReadTicksFromFile(lastTime, total))
   {
      g_activate = false;
      return;
   }
   
   // Дополнение данных из локального буфера
   if (!ReadTicksFromBuffer(lastTime, total))
   {
      g_activate = false;
      return;
   }
   
   ShowHistogramm();
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Обновление данных по кластерам                                                                                                                                                                    |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void UpdateData()
{
   TickStruct tick;
   tick.time = TimeCurrent();
   tick.ask = Ask;
   tick.bid = Bid;

   // Добавление одного тика в массив хранения тиков   
   if (!IsUpdateTicksArray(tick))
   {
      g_activate = false;
      return;
   }
   
   // Добавление тика в массив кластеров
   if (!IsSaveTickData(tick))
   {
      g_activate = false;
      return;
   }
   
   ShowHistogramm();
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Отображение данных индикатора                                                                                                                                                                     |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
void ShowIndicatorData(int limit, int total)
{
   if (limit > 1)
   {
      ShowNewData(total);
      return;
   }
   
   UpdateData();
}
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                                                                                                                               |
//+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
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
   if (!g_activate)                                                                                // Если в процессе работы индикатора возникла ошибка, то работать программа не должна
      return rates_total;                                 
    
   int total;   
   int limit = GetRecalcIndex(total, rates_total, prev_calculated);                                // С какого бара начинать обновление?

   ShowIndicatorData(limit, total);                                                                // Отображение данных индикатора
   WindowRedraw();
   
   return rates_total;
}
