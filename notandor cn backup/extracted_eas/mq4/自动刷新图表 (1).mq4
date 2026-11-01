#property description "设定时间 强制刷新图表 会触发指标重算"
#property description "2026年1月20日 5995736"
#property strict                        // 使用严格编译规则，减少隐式类型转换等潜在问题
#property indicator_chart_window        // 指标运行在主图窗口（不是单独子窗口）

input int             TimerSeconds     = 60;         // 每隔多少秒刷新一次
input bool            UseSwitchPeriod  = true;       // 启用“切周期再切回”刷新方式
input ENUM_TIMEFRAMES SwitchTempPeriod = PERIOD_M1;  // “切周期”时使用的临时周期

int OnInit()
{
   int seconds = TimerSeconds;         // 读取用户设置的定时器秒数
   if(seconds < 1)                     // 定时器最小为 1 秒，避免无效参数
      seconds = 1;                     // 小于 1 秒则强制修正为 1 秒
   EventSetTimer(seconds);             // 设置定时器：每隔指定秒数触发一次 OnTimer()
   return(INIT_SUCCEEDED);            // 初始化成功
}

void OnDeinit(const int reason)
{
   EventKillTimer();                  // 释放定时器：避免卸载指标后定时器继续占用资源
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);               // 本指标不绘制缓冲区，仅用于定时刷新；直接返回即可
}

int GetDifferentPeriod(const int currentPeriod)
{
   if(currentPeriod != PERIOD_M1)     // 若当前不是 M1，则优先选 M1
      return(PERIOD_M1);              // 返回一个与当前周期不同的周期
   if(currentPeriod != PERIOD_M5)     // 若当前不是 M5，则选 M5
      return(PERIOD_M5);              // 返回一个与当前周期不同的周期
   if(currentPeriod != PERIOD_M15)    // 若当前不是 M15，则选 M15
      return(PERIOD_M15);             // 返回一个与当前周期不同的周期
   if(currentPeriod != PERIOD_H1)     // 若当前不是 H1，则选 H1
      return(PERIOD_H1);              // 返回一个与当前周期不同的周期
   return(PERIOD_D1);                 // 兜底：若前面都相同（理论上不太会），返回 D1
}

void RefreshBySwitchPeriod()
{
   const int currentPeriod = Period();                 // 读取当前图表周期（分钟/小时/日等）
   int tempPeriod          = (int)SwitchTempPeriod;    // 读取用户设置的临时周期

   if(tempPeriod == currentPeriod)                      // 若临时周期与当前周期相同
      tempPeriod = GetDifferentPeriod(currentPeriod);   // 自动换成另一个不同周期，确保“切周期”会发生

   if(!ChartSetSymbolPeriod(0, Symbol(), tempPeriod))   // 先把当前图表切到临时周期（0 表示当前图表）
      return;                                          // 若切换失败，直接退出（避免再切回导致额外操作）

   ChartSetSymbolPeriod(0, Symbol(), currentPeriod);    // 再把图表切回原周期，达到“强制重载/重算”的效果
}

void OnTimer()
{
   if(UseSwitchPeriod)                 // 若启用“切周期再切回”
      RefreshBySwitchPeriod();         // 执行一次周期切换式刷新
}

