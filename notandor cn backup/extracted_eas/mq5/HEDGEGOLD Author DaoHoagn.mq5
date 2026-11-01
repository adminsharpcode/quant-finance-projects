//+--------------------------------------------------------------------------+
//| MurreyMath.mq5                                                           |
//| Copyright 2018, getYourNet.ch                                            |
//| http://www.getyournet.ch                                                 |
//+--------------------------------------------------------------------------+
#property copyright "Copyright 2018, getYourNet.ch"
#property link      "http://www.getyournet.ch"
#property version   "2.02"
#property indicator_chart_window
#property indicator_plots 0

input string NameSpace = "Murrey Math 1"; // Application Namespace
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // Timeframe
input int ObserveCandles = 64; // Observe Candles
input int CandlesBack = 1; // Candles Back
input color ColorMinus28 = clrBlack; // Color -2/8
input color ColorMinus18 = clrBlack; // Color -1/8
input color Color08 = clrDeepSkyBlue; // Color 0/8
input color Color18 = clrOrange; // Color 1/8
input color Color28 = clrRed; // Color 2/8
input color Color38 = clrGreen; // Color 3/8
input color Color48 = clrBlue; // Color 4/8
input color Color58 = clrGreen; // Color 5/8
input color Color68 = clrRed; // Color 6/8
input color Color78 = clrOrange; // Color 7/8
input color Color88 = clrDeepSkyBlue; // Color 8/8
input color ColorPlus18 = clrBlack; // Color +1/8
input color ColorPlus28 = clrBlack; // Color +2/8
input int WidthMinus28 = 2; // Width -2/8
input int WidthMinus18 = 1; // Width -1/8
input int Width08 = 1; // Width 0/8
input int Width18 = 1; // Width 1/8
input int Width28 = 1; // Width 2/8
input int Width38 = 1; // Width 3/8
input int Width48 = 1; // Width 4/8
input int Width58 = 1; // Width 5/8
input int Width68 = 1; // Width 6/8
input int Width78 = 1; // Width 7/8
input int Width88 = 1; // Width 8/8
input int WidthPlus18 = 1; // Width +1/8
input int WidthPlus28 = 2; // Width +2/8
input int TextShift = 20; // Text Shift
input bool DisableText = false; // Disable Text
input bool DebugMode = false; // Debug Mode

bool newbar = false;
long firstbar = 0;
long lastfirstbar = -1;
bool istesting;

// Структура для хранения настроек и данных уровней Мюррея
struct TypeMurreyMath
{
   string appnamespace;
   ENUM_TIMEFRAMES timeframe;
   int candles;
   int startcandle;
   int textshift;
   bool debug;
   color Clolors[13]; // Цвета для уровней от -2/8 до +2/8
   int Widths[13]; // Толщины линий для уровней
   double Levels[13]; // Уровни Мюррея от -2/8 до +2/8

   void Calculate()
   {
      if (timeframe == PERIOD_CURRENT)
         timeframe = _Period;

      // Проверка доступности исторических данных
      if (!EnsureHistoryLoaded(_Symbol, timeframe))
      {
         Print("Failed to load history for ", EnumToString(timeframe));
         return;
      }

      // Получение данных для расчёта
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int copied = CopyRates(_Symbol, timeframe, startcandle, candles, rates);
      if (copied < candles)
      {
         Print("Failed to copy rates. Copied: ", copied, ", required: ", candles, ". Error code: ", GetLastError());
         return;
      }

      // Нахождение максимума и минимума за период
      double high = rates[0].high;
      double low = rates[0].low;
      for (int i = 1; i < copied; i++)
      {
         if (rates[i].high > high)
            high = rates[i].high;
         if (rates[i].low < low)
            low = rates[i].low;
      }

      // Расчёт уровней Мюррея
      double range = high - low;
      double logRange = MathLog(range) / MathLog(2);
      double scale = MathPow(2, MathFloor(logRange));
      double multiplier = range / scale;
      if (multiplier < 0.125)
         scale *= 0.5;
      else if (multiplier > 0.5)
         scale *= 2;

      double baseLevel = MathFloor(low / scale) * scale;
      double levelStep = scale / 8.0;

      Levels[0] = baseLevel - 2 * levelStep; // -2/8
      Levels[1] = baseLevel - levelStep;     // -1/8
      Levels[2] = baseLevel;                 // 0/8
      Levels[3] = baseLevel + levelStep;     // 1/8
      Levels[4] = baseLevel + 2 * levelStep; // 2/8
      Levels[5] = baseLevel + 3 * levelStep; // 3/8
      Levels[6] = baseLevel + 4 * levelStep; // 4/8
      Levels[7] = baseLevel + 5 * levelStep; // 5/8
      Levels[8] = baseLevel + 6 * levelStep; // 6/8
      Levels[9] = baseLevel + 7 * levelStep; // 7/8
      Levels[10] = baseLevel + 8 * levelStep; // 8/8
      Levels[11] = baseLevel + 9 * levelStep; // +1/8
      Levels[12] = baseLevel + 10 * levelStep; // +2/8

      if (debug)
      {
         Print("Murrey Math Levels: High=", high, ", Low=", low, ", Scale=", scale, ", BaseLevel=", baseLevel);
         for (int i = 0; i < 13; i++)
            Print("Level ", i - 2, "/8: ", Levels[i]);
      }
   }

   void Draw(bool disableText)
   {
      // Удаление старых объектов
      Cleanup();

      // Отрисовка уровней
      string levelNames[] = {"-2/8", "-1/8", "0/8", "1/8", "2/8", "3/8", "4/8", "5/8", "6/8", "7/8", "8/8", "+1/8", "+2/8"};
      for (int i = 0; i < 13; i++)
      {
         string objName = appnamespace + "_" + levelNames[i];
         ObjectCreate(0, objName, OBJ_HLINE, 0, 0, Levels[i]);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, Clolors[i]);
         ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, Widths[i]);
         ObjectSetInteger(0, objName, OBJPROP_BACK, false);

         if (!disableText)
         {
            string textName = objName + "_Text";
            ObjectCreate(0, textName, OBJ_TEXT, 0, iTime(_Symbol, _Period, 0) + textshift * PeriodSeconds(_Period), Levels[i]);
            ObjectSetString(0, textName, OBJPROP_TEXT, levelNames[i]);
            ObjectSetInteger(0, textName, OBJPROP_COLOR, Clolors[i]);
            ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
         }
      }
   }

   void Cleanup()
   {
      ObjectsDeleteAll(0, appnamespace);
   }

   bool EnsureHistoryLoaded(string symbol, ENUM_TIMEFRAMES tf)
   {
      int bars = Bars(symbol, tf);
      if (bars < candles)
      {
         Print("Not enough history for ", symbol, " on ", EnumToString(tf), ". Available bars: ", bars, ", required: ", candles);
         datetime times[1];
         if (CopyTime(symbol, tf, 0, 1, times) <= 0)
         {
            Print("Failed to initialize history for ", symbol, " on ", EnumToString(tf), ". Error code: ", GetLastError());
            return false;
         }
         Sleep(100);
         return Bars(symbol, tf) >= candles;
      }
      return true;
   }
};

TypeMurreyMath MM;

int OnInit()
{
   MM.appnamespace = NameSpace;
   MM.timeframe = TimeFrame;
   MM.candles = ObserveCandles;
   MM.startcandle = CandlesBack;
   MM.textshift = TextShift;
   MM.debug = DebugMode;

   MM.Clolors[0] = ColorMinus28;
   MM.Clolors[1] = ColorMinus18;
   MM.Clolors[2] = Color08;
   MM.Clolors[3] = Color18;
   MM.Clolors[4] = Color28;
   MM.Clolors[5] = Color38;
   MM.Clolors[6] = Color48;
   MM.Clolors[7] = Color58;
   MM.Clolors[8] = Color68;
   MM.Clolors[9] = Color78;
   MM.Clolors[10] = Color88;
   MM.Clolors[11] = ColorPlus18;
   MM.Clolors[12] = ColorPlus28;

   MM.Widths[0] = WidthMinus28;
   MM.Widths[1] = WidthMinus18;
   MM.Widths[2] = Width08;
   MM.Widths[3] = Width18;
   MM.Widths[4] = Width28;
   MM.Widths[5] = Width38;
   MM.Widths[6] = Width48;
   MM.Widths[7] = Width58;
   MM.Widths[8] = Width68;
   MM.Widths[9] = Width78;
   MM.Widths[10] = Width88;
   MM.Widths[11] = WidthPlus18;
   MM.Widths[12] = WidthPlus28;

   istesting = MQLInfoInteger(MQL_TESTER);
   firstbar = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR); // Инициализация firstbar
   EventSetTimer(1);

   // Попытка загрузки истории
   if (!MM.EnsureHistoryLoaded(_Symbol, MM.timeframe))
      Print("Initial history load failed for ", EnumToString(MM.timeframe));

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   MM.Cleanup();
}

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
   if (rates_total > prev_calculated)
   {
      newbar = true;
      if (istesting)
         OnTimer();
   }
   return rates_total;
}

void OnTimer()
{
   if (newbar || lastfirstbar != firstbar)
   {
      datetime arr1[1];
      if (CopyTime(_Symbol, _Period, (int)firstbar, 1, arr1) < 1)
      {
         Print("Failed to copy time. Error code: ", GetLastError());
         return;
      }

      int candlestart = CandlesBack;
      if (firstbar > 0)
      {
         datetime time_array[1];
         if (CopyTime(_Symbol, _Period, (int)firstbar, 1, time_array) < 1)
         {
            Print("Failed to get first bar time. Error code: ", GetLastError());
            return;
         }
         int indexbytime = Bars(_Symbol, MM.timeframe, time_array[0], arr1[0]) + 1;
         candlestart = MathMax(CandlesBack, indexbytime);
      }

      MM.startcandle = candlestart;
      MM.Calculate();
      MM.Draw(DisableText);

      lastfirstbar = firstbar;
      newbar = false;
   }
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if (id == CHARTEVENT_CHART_CHANGE)
   {
      long firstvisible = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
      long visiblebars = ChartGetInteger(0, CHART_VISIBLE_BARS);
      long widthinbars = ChartGetInteger(0, CHART_WIDTH_IN_BARS);
      if (firstvisible > (widthinbars - TextShift))
         firstbar = firstvisible - (widthinbars - TextShift);
      else
         firstbar = 0;
   }
}