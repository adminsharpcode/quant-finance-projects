//+------------------------------------------------------------------+
//|                                     BB_ATR_Master_Final.mq5 |
//|                                       Copyright 2024, MetaQuotes Ltd. |
//|                                            https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      "https://www.mql5.com"
#property version   "8.0"
#property description "飞博双通道网格 - 完全修复版"
#property description "功能：中轨交易，双向持仓，ATR回撤加仓，多空各自整体止盈"

// 输入参数
input group "===== 基础设置 ====="
input int      MagicNumber = 202608;           // 魔术码
input double   BaseLot = 0.01;                 // 基础手数
input bool     AutoLotSize = true;             // 自动计算手数
input double   RiskPercent = 0.00001;              // 风险百分比
input int      MaxOrders = 1000;                  // 最大订单数
input int      Slippage = 10;                  // 滑点
input int      MaxSpread = 20;                 // 最大点差

input group "===== 布林通道设置 ====="
input int      BandsPeriod = 20;               // 布林通道周期
input double   BandsDeviation = 2.0;           // 布林通道标准差
input double   TouchDistance = 0.5;            // 中轨触及距离(点)
input bool     WaitForClose = true;            // 等待K线收盘

input group "===== ATR设置 ====="
input int      ATRPeriod = 14;                 // ATR周期
input double   ATRChannelMultiplier = 2.0;     // ATR通道倍数
input bool     ShowATRChannel = true;          // 显示ATR通道

input group "===== 加仓设置 ====="
input bool     EnableGrid = true;              // 启用网格加仓
input int      MaxGridLevels = 30;              // 最大网格层数
input double   GridStepATR = 1.5;              // 基础回撤加仓距离(ATR倍数)
input double   GridLotMultiplier = 1.3;        // 加仓手数倍数
input int      MinBarsBetweenAdd = 2;          // 加仓最小间隔K线数
input bool     EnableTrendAdd = false;         // 启用顺势加仓(默认关闭)

input group "===== 浮亏控制加仓间隔 ====="
input bool     EnableFloatLossControl = true;  // 启用浮亏控制
input double   FloatLossLevel1 = 1.5;          // 浮亏第1级(ATR倍数)
input double   GridStepMultiplier1 = 1.8;      // 第1级加仓间隔倍数
input double   FloatLossLevel2 = 2.5;          // 浮亏第2级(ATR倍数)
input double   GridStepMultiplier2 = 2.5;      // 第2级加仓间隔倍数
input double   FloatLossLevel3 = 3.5;          // 浮亏第3级(ATR倍数)
input double   GridStepMultiplier3 = 3.5;      // 第3级加仓间隔倍数
input bool     StopAddAtLevel3 = false;         // 第3级浮亏时停止加仓

input group "===== 整体移动止损和止盈 ====="
input bool     UseGlobalTrailing = true;       // 使用整体移动止损
input double   BreakEvenATR = 1.5;             // 整体保本触发(ATR倍数)
input double   TrailStartATR = 1.5;            // 启动移动止损(ATR倍数)
input double   TrailStepATR = 0.5;             // 移动步长(ATR倍数)
input double   BuyTakeProfit_ATR = 3.0;        // 多头整体止盈(ATR倍数)
input double   SellTakeProfit_ATR = 3.0;       // 空头整体止盈(ATR倍数)
input bool     SeparateClose = true;           // 分开平仓(多空各自独立)

// 全局变量
int bbHandle, atrHandle, maHandle;
datetime lastBarTime = 0;
double pointValue, minLot, maxLot, lotStep;
double dailyEquityStart = 0.0;
datetime lastDailyCheck = 0;
bool initialUpdate = true;

// 结构体存储持仓信息
struct PositionGroup {
   double totalVolume;      // 总手数
   double totalValue;       // 总价值
   double avgPrice;         // 加权平均入场价
   double totalProfit;      // 总利润(当前浮盈)
   double floatingLoss;     // 浮亏金额
   double highestPrice;     // 持仓期间最高价
   double lowestPrice;      // 持仓期间最低价
   bool breakEven;          // 是否已保本
   bool trailingStarted;    // 移动止损已启动
   int orderCount;          // 订单数量
   double currentGridStep;  // 当前加仓间隔倍数
   int floatLossLevel;      // 当前浮亏等级
   datetime lastAddTime;    // 最后加仓时间
   double highestEntry;     // 最高入场价
   double lowestEntry;      // 最低入场价
   int gridLevel;           // 当前网格层级
   double trailStop;        // 当前移动止损位
};
PositionGroup buyGroup, sellGroup;

//+------------------------------------------------------------------+
//| 专家初始化函数                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // 初始化交易品种信息
   pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   // 初始化指标句柄
   bbHandle = iBands(_Symbol, PERIOD_CURRENT, BandsPeriod, 0, BandsDeviation, PRICE_CLOSE);
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   maHandle = iMA(_Symbol, PERIOD_CURRENT, BandsPeriod, 0, MODE_SMA, PRICE_CLOSE);
   
   if(bbHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE || maHandle == INVALID_HANDLE) {
      Print("错误: 指标初始化失败");
      return INIT_FAILED;
   }
   
   // 初始化数据
   ResetPositionGroups();
   
   // 初始化每日数据
   MqlDateTime dt;
   TimeCurrent(dt);
   lastDailyCheck = StructToTime(dt);
   dailyEquityStart = AccountInfoDouble(ACCOUNT_EQUITY);
   
   Print("=== 布林通道+ATR交易系统初始化成功 ===");
   Print("交易品种: ", _Symbol, " 周期: ", Period());
   Print("基础手数: ", BaseLot, " 风险: ", RiskPercent, "%");
   Print("最大网格层级: ", MaxGridLevels, " 加仓间隔: ", GridStepATR, "ATR");
   Print("多空分向止盈: 多头", BuyTakeProfit_ATR, "ATR 空头", SellTakeProfit_ATR, "ATR");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| 专家去初始化函数                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(bbHandle != INVALID_HANDLE) IndicatorRelease(bbHandle);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
   
   // 清理图表对象
   ObjectDelete(0, "ATR_Upper");
   ObjectDelete(0, "ATR_Lower");
   ObjectDelete(0, "ATR_Middle");
   Comment("");
   
   Print("EA已卸载");
}

//+------------------------------------------------------------------+
//| 专家订单函数 - 主循环                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // 检查新K线
   if(!IsNewBar()) return;
   
   // 点差检查
   if(!CheckSpread()) return;
   
   // 每日检查
   CheckDaily();
   
   // 获取指标数据
   double bbMiddle[3], bbUpper[3], bbLower[3];
   double atrValue[1];
   double maValue[1];
   
   if(CopyBuffer(bbHandle, 0, 0, 3, bbMiddle) < 3) return;
   if(CopyBuffer(bbHandle, 1, 0, 3, bbUpper) < 3) return;
   if(CopyBuffer(bbHandle, 2, 0, 3, bbLower) < 3) return;
   if(CopyBuffer(atrHandle, 0, 0, 1, atrValue) < 1) return;
   if(CopyBuffer(maHandle, 0, 0, 1, maValue) < 1) return;
   
   double atr = atrValue[0];
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // 更新ATR通道显示
   if(ShowATRChannel) UpdateATRChannel(maValue[0], atr);
   
   // 步骤1: 更新持仓数据
   UpdatePositionGroups();
   
   // 步骤2: 计算浮亏控制
   if(EnableFloatLossControl) CalculateFloatLossControl(bid, ask, atr);
   
   // 步骤3: 检查入场信号
   if(GetTotalOrders() < MaxOrders) {
      CheckEntrySignal(bbMiddle, bbUpper, bbLower, bid, ask, atr);
   }
   
   // 步骤4: 检查加仓机会
   if(EnableGrid) {
      CheckGridEntry(bid, ask, atr);
   }
   
   // 步骤5: 管理整体移动止损
   if(UseGlobalTrailing) {
      ManageGlobalTrailing(bid, ask, atr);
   }
   
   // 步骤6: 检查整体止盈
   CheckGlobalTakeProfit(bid, ask, atr);
   
   // 步骤7: 显示信息
   DisplayInfo(atr);
}

//+------------------------------------------------------------------+
//| 重置持仓组数据                                                   |
//+------------------------------------------------------------------+
void ResetPositionGroups()
{
   // 重置多头组
   buyGroup.totalVolume = 0;
   buyGroup.totalValue = 0;
   buyGroup.avgPrice = 0;
   buyGroup.totalProfit = 0;
   buyGroup.floatingLoss = 0;
   buyGroup.highestPrice = 0;
   buyGroup.lowestPrice = 0;
   buyGroup.breakEven = false;
   buyGroup.trailingStarted = false;
   buyGroup.orderCount = 0;
   buyGroup.currentGridStep = GridStepATR;
   buyGroup.floatLossLevel = 0;
   buyGroup.lastAddTime = 0;
   buyGroup.highestEntry = 0;
   buyGroup.lowestEntry = 0;
   buyGroup.gridLevel = 0;
   buyGroup.trailStop = 0;
   
   // 重置空头组
   sellGroup.totalVolume = 0;
   sellGroup.totalValue = 0;
   sellGroup.avgPrice = 0;
   sellGroup.totalProfit = 0;
   sellGroup.floatingLoss = 0;
   sellGroup.highestPrice = 0;
   sellGroup.lowestPrice = 0;
   sellGroup.breakEven = false;
   sellGroup.trailingStarted = false;
   sellGroup.orderCount = 0;
   sellGroup.currentGridStep = GridStepATR;
   sellGroup.floatLossLevel = 0;
   sellGroup.lastAddTime = 0;
   sellGroup.highestEntry = 0;
   sellGroup.lowestEntry = 0;
   sellGroup.gridLevel = 0;
   sellGroup.trailStop = 0;
}

//+------------------------------------------------------------------+
//| 更新持仓组数据 - 修复版                                          |
//+------------------------------------------------------------------+
void UpdatePositionGroups()
{
   ResetPositionGroups();
   
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         long type = PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double price = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double profit = PositionGetDouble(POSITION_PROFIT);
         string comment = PositionGetString(POSITION_COMMENT);
         
         if(type == POSITION_TYPE_BUY) {
            buyGroup.totalVolume += volume;
            buyGroup.totalValue += price * volume;
            buyGroup.totalProfit += profit;
            
            // 记录浮亏
            if(profit < 0) {
               buyGroup.floatingLoss += MathAbs(profit);
            }
            
            // 更新最高价和最低价
            if(buyGroup.highestPrice == 0 || currentPrice > buyGroup.highestPrice) {
               buyGroup.highestPrice = currentPrice;
            }
            if(buyGroup.lowestPrice == 0 || currentPrice < buyGroup.lowestPrice) {
               buyGroup.lowestPrice = currentPrice;
            }
            
            // 更新最高和最低入场价
            if(buyGroup.highestEntry == 0 || price > buyGroup.highestEntry) {
               buyGroup.highestEntry = price;
            }
            if(buyGroup.lowestEntry == 0 || price < buyGroup.lowestEntry) {
               buyGroup.lowestEntry = price;
            }
            
            buyGroup.orderCount++;
            
            // 提取网格层级
            int pos = StringFind(comment, "Buy_L");
            if(pos >= 0) {
               string levelStr = StringSubstr(comment, pos + 5);
               int level = (int)StringToInteger(levelStr);
               if(level > buyGroup.gridLevel) {
                  buyGroup.gridLevel = level;
               }
            }
         } 
         else if(type == POSITION_TYPE_SELL) {
            sellGroup.totalVolume += volume;
            sellGroup.totalValue += price * volume;
            sellGroup.totalProfit += profit;
            
            // 记录浮亏
            if(profit < 0) {
               sellGroup.floatingLoss += MathAbs(profit);
            }
            
            // 更新最高价和最低价
            if(sellGroup.highestPrice == 0 || currentPrice > sellGroup.highestPrice) {
               sellGroup.highestPrice = currentPrice;
            }
            if(sellGroup.lowestPrice == 0 || currentPrice < sellGroup.lowestPrice) {
               sellGroup.lowestPrice = currentPrice;
            }
            
            // 更新最高和最低入场价
            if(sellGroup.highestEntry == 0 || price > sellGroup.highestEntry) {
               sellGroup.highestEntry = price;
            }
            if(sellGroup.lowestEntry == 0 || price < sellGroup.lowestEntry) {
               sellGroup.lowestEntry = price;
            }
            
            sellGroup.orderCount++;
            
            // 提取网格层级
            int pos = StringFind(comment, "Sell_L");
            if(pos >= 0) {
               string levelStr = StringSubstr(comment, pos + 6);
               int level = (int)StringToInteger(levelStr);
               if(level > sellGroup.gridLevel) {
                  sellGroup.gridLevel = level;
               }
            }
         }
      }
   }
   
   // 计算加权平均价格
   if(buyGroup.totalVolume > 0) {
      buyGroup.avgPrice = buyGroup.totalValue / buyGroup.totalVolume;
   }
   
   if(sellGroup.totalVolume > 0) {
      sellGroup.avgPrice = sellGroup.totalValue / sellGroup.totalVolume;
   }
}

//+------------------------------------------------------------------+
//| 计算浮亏控制                                                     |
//+------------------------------------------------------------------+
void CalculateFloatLossControl(double bid, double ask, double atr)
{
   // 多头浮亏控制
   if(buyGroup.orderCount > 0 && buyGroup.avgPrice > 0) {
      // 计算当前浮亏(ATR倍数)
      double floatLossATR = 0;
      if(bid < buyGroup.avgPrice) {
         floatLossATR = (buyGroup.avgPrice - bid) / atr;
      }
      
      // 根据浮亏等级调整加仓间隔倍数
      double gridStepMultiplier = 1.0;
      
      if(floatLossATR >= FloatLossLevel3) {
         gridStepMultiplier = GridStepMultiplier3;
         buyGroup.floatLossLevel = 3;
      } else if(floatLossATR >= FloatLossLevel2) {
         gridStepMultiplier = GridStepMultiplier2;
         buyGroup.floatLossLevel = 2;
      } else if(floatLossATR >= FloatLossLevel1) {
         gridStepMultiplier = GridStepMultiplier1;
         buyGroup.floatLossLevel = 1;
      } else {
         buyGroup.floatLossLevel = 0;
      }
      
      buyGroup.currentGridStep = GridStepATR * gridStepMultiplier;
   } else {
      buyGroup.currentGridStep = GridStepATR;
      buyGroup.floatLossLevel = 0;
   }
   
   // 空头浮亏控制
   if(sellGroup.orderCount > 0 && sellGroup.avgPrice > 0) {
      // 计算当前浮亏(ATR倍数)
      double floatLossATR = 0;
      if(ask > sellGroup.avgPrice) {
         floatLossATR = (ask - sellGroup.avgPrice) / atr;
      }
      
      // 根据浮亏等级调整加仓间隔倍数
      double gridStepMultiplier = 1.0;
      
      if(floatLossATR >= FloatLossLevel3) {
         gridStepMultiplier = GridStepMultiplier3;
         sellGroup.floatLossLevel = 3;
      } else if(floatLossATR >= FloatLossLevel2) {
         gridStepMultiplier = GridStepMultiplier2;
         sellGroup.floatLossLevel = 2;
      } else if(floatLossATR >= FloatLossLevel1) {
         gridStepMultiplier = GridStepMultiplier1;
         sellGroup.floatLossLevel = 1;
      } else {
         sellGroup.floatLossLevel = 0;
      }
      
      sellGroup.currentGridStep = GridStepATR * gridStepMultiplier;
   } else {
      sellGroup.currentGridStep = GridStepATR;
      sellGroup.floatLossLevel = 0;
   }
}

//+------------------------------------------------------------------+
//| 检查入场信号                                                     |
//+------------------------------------------------------------------+
void CheckEntrySignal(double &bbMiddle[], double &bbUpper[], double &bbLower[],
                     double bid, double ask, double atr)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 3, rates) < 3) return;
   
   double touchDist = TouchDistance * pointValue;
   double bbMid = bbMiddle[0];
   double bbUp = bbUpper[0];
   double bbLow = bbLower[0];
   
   // 检查多头入场（价格在中轨下方）
   if(buyGroup.orderCount == 0 && bid < bbMid - touchDist && bid <= bbLow + (bbMid - bbLow) * 0.3) {
      if(WaitForClose && rates[0].close > rates[0].open) return;
      
      if(EnableFloatLossControl && buyGroup.floatLossLevel >= 3 && StopAddAtLevel3) return;
      
      double lot = CalculateLotSize(atr, 0);
      if(lot > 0) {
         if(OpenBuyOrder(ask, atr, lot, 0)) {
            Print("多头入场: 价格=", ask, " 手数=", lot, " 中轨=", bbMid);
         }
      }
   }
   // 检查空头入场（价格在中轨上方）
   else if(sellGroup.orderCount == 0 && ask > bbMid + touchDist && ask >= bbUp - (bbUp - bbMid) * 0.3) {
      if(WaitForClose && rates[0].close < rates[0].open) return;
      
      if(EnableFloatLossControl && sellGroup.floatLossLevel >= 3 && StopAddAtLevel3) return;
      
      double lot = CalculateLotSize(atr, 0);
      if(lot > 0) {
         if(OpenSellOrder(bid, atr, lot, 0)) {
            Print("空头入场: 价格=", bid, " 手数=", lot, " 中轨=", bbMid);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 检查加仓机会                                                     |
//+------------------------------------------------------------------+
void CheckGridEntry(double bid, double ask, double atr)
{
   datetime now = TimeCurrent();
   
   // 检查多头回撤加仓
   if(buyGroup.orderCount > 0 && buyGroup.gridLevel < MaxGridLevels) {
      if(buyGroup.lastAddTime > 0 && (now - buyGroup.lastAddTime) < MinBarsBetweenAdd * PeriodSeconds(_Period)) {
         return; // 冷却中
      }
      
      if(buyGroup.lowestEntry > 0 && bid <= buyGroup.lowestEntry - (buyGroup.currentGridStep * atr)) {
         int nextLevel = buyGroup.gridLevel + 1;
         if(nextLevel <= MaxGridLevels) {
            double lot = CalculateGridLotSize(atr, nextLevel);
            if(lot > 0) {
               if(OpenBuyOrder(ask, atr, lot, nextLevel)) {
                  PrintFormat("多头回撤加仓, 层级:%d, 价格:%.5f, 间隔:%.5f, 浮亏等级:%d", 
                            nextLevel, ask, buyGroup.currentGridStep, buyGroup.floatLossLevel);
               }
            }
         }
      }
   }
   
   // 检查空头回撤加仓
   if(sellGroup.orderCount > 0 && sellGroup.gridLevel < MaxGridLevels) {
      if(sellGroup.lastAddTime > 0 && (now - sellGroup.lastAddTime) < MinBarsBetweenAdd * PeriodSeconds(_Period)) {
         return; // 冷却中
      }
      
      if(sellGroup.highestEntry > 0 && ask >= sellGroup.highestEntry + (sellGroup.currentGridStep * atr)) {
         int nextLevel = sellGroup.gridLevel + 1;
         if(nextLevel <= MaxGridLevels) {
            double lot = CalculateGridLotSize(atr, nextLevel);
            if(lot > 0) {
               if(OpenSellOrder(bid, atr, lot, nextLevel)) {
                  PrintFormat("空头回撤加仓, 层级:%d, 价格:%.5f, 间隔:%.5f, 浮亏等级:%d", 
                            nextLevel, bid, sellGroup.currentGridStep, sellGroup.floatLossLevel);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 管理整体移动止损                                                 |
//+------------------------------------------------------------------+
void ManageGlobalTrailing(double bid, double ask, double atr)
{
   // 多头整体移动止损
   if(buyGroup.orderCount > 0 && buyGroup.avgPrice > 0 && buyGroup.totalProfit > 0) {
      double breakEvenLevel = buyGroup.avgPrice;
      double trailStartLevel = buyGroup.avgPrice + (TrailStartATR * atr);
      
      if(bid >= trailStartLevel && !buyGroup.trailingStarted) {
         buyGroup.trailingStarted = true;
         Print("多头整体移动止损启动, 平均价:", buyGroup.avgPrice);
      }
      
      if(!buyGroup.breakEven && buyGroup.totalProfit >= (BreakEvenATR * atr * buyGroup.totalVolume)) {
         MoveAllBuyToBreakeven(breakEvenLevel);
         buyGroup.breakEven = true;
         Print("多头整体移动到保本位, 平均价:", breakEvenLevel);
      }
      
      if(buyGroup.trailingStarted) {
         double trailStop = buyGroup.highestPrice - (TrailStepATR * atr);
         if(trailStop > buyGroup.trailStop) {
            buyGroup.trailStop = trailStop;
            MoveAllBuyTrailingStop(trailStop, bid);
         }
      }
   }
   
   // 空头整体移动止损
   if(sellGroup.orderCount > 0 && sellGroup.avgPrice > 0 && sellGroup.totalProfit > 0) {
      double breakEvenLevel = sellGroup.avgPrice;
      double trailStartLevel = sellGroup.avgPrice - (TrailStartATR * atr);
      
      if(ask <= trailStartLevel && !sellGroup.trailingStarted) {
         sellGroup.trailingStarted = true;
         Print("空头整体移动止损启动, 平均价:", sellGroup.avgPrice);
      }
      
      if(!sellGroup.breakEven && sellGroup.totalProfit >= (BreakEvenATR * atr * sellGroup.totalVolume)) {
         MoveAllSellToBreakeven(breakEvenLevel);
         sellGroup.breakEven = true;
         Print("空头整体移动到保本位, 平均价:", breakEvenLevel);
      }
      
      if(sellGroup.trailingStarted) {
         double trailStop = sellGroup.lowestPrice + (TrailStepATR * atr);
         if(trailStop < sellGroup.trailStop || sellGroup.trailStop == 0) {
            sellGroup.trailStop = trailStop;
            MoveAllSellTrailingStop(trailStop, ask);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 检查整体止盈 - 修复版                                            |
//+------------------------------------------------------------------+
void CheckGlobalTakeProfit(double bid, double ask, double atr)
{
   if(atr <= 0) return;
   
   if(SeparateClose) {
      // 多头整体止盈
      if(buyGroup.orderCount > 0 && buyGroup.totalProfit > 0 && buyGroup.totalVolume > 0) {
         // 计算多头总ATR价值
         double atrValue = CalculateATRValue(atr, buyGroup.totalVolume);
         
         if(atrValue > 0) {
            // 计算盈利ATR倍数
            double profitATR = buyGroup.totalProfit / atrValue;
            
            // 检查是否达到止盈条件
            if(profitATR >= BuyTakeProfit_ATR) {
               CloseAllBuyOrders(StringFormat("多头整体止盈(盈利%.2fATR)", profitATR));
               return; // 平仓后直接返回，避免后续检查
            }
         }
      }
      
      // 空头整体止盈
      if(sellGroup.orderCount > 0 && sellGroup.totalProfit > 0 && sellGroup.totalVolume > 0) {
         // 计算空头总ATR价值
         double atrValue = CalculateATRValue(atr, sellGroup.totalVolume);
         
         if(atrValue > 0) {
            // 计算盈利ATR倍数
            double profitATR = sellGroup.totalProfit / atrValue;
            
            // 检查是否达到止盈条件
            if(profitATR >= SellTakeProfit_ATR) {
               CloseAllSellOrders(StringFormat("空头整体止盈(盈利%.2fATR)", profitATR));
               return; // 平仓后直接返回
            }
         }
      }
   } else {
      // 整体止盈（多空合并计算）
      double totalProfit = buyGroup.totalProfit + sellGroup.totalProfit;
      double totalVolume = buyGroup.totalVolume + sellGroup.totalVolume;
      
      if(totalProfit > 0 && totalVolume > 0) {
         double atrValue = CalculateATRValue(atr, totalVolume);
         
         if(atrValue > 0) {
            double profitATR = totalProfit / atrValue;
            
            if(profitATR >= BuyTakeProfit_ATR) { // 使用多头止盈参数
               CloseAllOrders(StringFormat("整体止盈(盈利%.2fATR)", profitATR));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 计算ATR价值（转换为货币单位）                                    |
//+------------------------------------------------------------------+
double CalculateATRValue(double atr, double volume)
{
   // 获取每点价值
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickValue <= 0) {
      // 如果获取失败，使用估计值
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSize > 0) {
         tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * tickSize;
      } else {
         tickValue = 0.01; // 默认值
      }
   }
   
   // 计算ATR价值 = ATR(点数) × 每点价值 × 手数
   double atrPoints = atr / pointValue;  // 将ATR转换为点数
   return atrPoints * tickValue * volume;
}

//+------------------------------------------------------------------+
//| 开单相关函数                                                     |
//+------------------------------------------------------------------+
bool OpenBuyOrder(double price, double atr, double lot, int gridLevel)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.type = ORDER_TYPE_BUY;
   request.price = price;
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = "Buy_L" + IntegerToString(gridLevel);
   
   if(OrderSend(request, result)) {
      Print("多单开仓成功: 价格=", price, " 手数=", lot, " 层级=", gridLevel);
      buyGroup.lastAddTime = TimeCurrent();
      if(gridLevel > 0) buyGroup.gridLevel = gridLevel;
      return true;
   }
   
   Print("多单开仓失败: ", GetLastError());
   return false;
}

bool OpenSellOrder(double price, double atr, double lot, int gridLevel)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.type = ORDER_TYPE_SELL;
   request.price = price;
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = "Sell_L" + IntegerToString(gridLevel);
   
   if(OrderSend(request, result)) {
      Print("空单开仓成功: 价格=", price, " 手数=", lot, " 层级=", gridLevel);
      sellGroup.lastAddTime = TimeCurrent();
      if(gridLevel > 0) sellGroup.gridLevel = gridLevel;
      return true;
   }
   
   Print("空单开仓失败: ", GetLastError());
   return false;
}

//+------------------------------------------------------------------+
//| 手数计算相关函数                                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double atr, int gridLevel = 0)
{
   if(!AutoLotSize) {
      double lot = BaseLot * MathPow(GridLotMultiplier, gridLevel);
      return NormalizeLot(lot);
   }
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickValue <= 0) return NormalizeLot(BaseLot);
   
   // 计算每点风险
   double atrPoints = atr / pointValue;
   double riskPerPoint = atrPoints * tickValue;
   if(riskPerPoint <= 0) return NormalizeLot(BaseLot);
   
   double lot = riskAmount / riskPerPoint;
   lot *= MathPow(GridLotMultiplier, gridLevel);
   
   return NormalizeLot(lot);
}

double CalculateGridLotSize(double atr, int gridLevel)
{
   return CalculateLotSize(atr, gridLevel);
}

double NormalizeLot(double lot)
{
   lot = MathRound(lot / lotStep) * lotStep;
   return MathMin(MathMax(lot, minLot), maxLot);
}

//+------------------------------------------------------------------+
//| 移动止损相关函数                                                 |
//+------------------------------------------------------------------+
void MoveAllBuyToBreakeven(double breakEvenLevel)
{
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double currentSL = PositionGetDouble(POSITION_SL);
         
         if(breakEvenLevel > currentSL) {
            ModifyPositionSL(ticket, breakEvenLevel);
         }
      }
   }
}

void MoveAllSellToBreakeven(double breakEvenLevel)
{
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double currentSL = PositionGetDouble(POSITION_SL);
         
         if(breakEvenLevel < currentSL) {
            ModifyPositionSL(ticket, breakEvenLevel);
         }
      }
   }
}

void MoveAllBuyTrailingStop(double trailStop, double currentPrice)
{
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double currentSL = PositionGetDouble(POSITION_SL);
         
         if(trailStop > currentSL && trailStop < currentPrice) {
            ModifyPositionSL(ticket, trailStop);
         }
      }
   }
}

void MoveAllSellTrailingStop(double trailStop, double currentPrice)
{
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double currentSL = PositionGetDouble(POSITION_SL);
         
         if(trailStop < currentSL && trailStop > currentPrice) {
            ModifyPositionSL(ticket, trailStop);
         }
      }
   }
}

void ModifyPositionSL(ulong ticket, double newSL)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = _Symbol;
   request.sl = newSL;
   request.magic = MagicNumber;
   
   if(OrderSend(request, result)) {
      // Print("修改止损成功: ", ticket, " 新止损=", newSL);
   } else {
      Print("修改止损失败: ", ticket, " 错误=", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 平仓相关函数 - 修复版                                            |
//+------------------------------------------------------------------+
void CloseAllBuyOrders(string reason)
{
   int closed = 0;
   int totalBuys = 0;
   
   // 先统计有多少多单
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         totalBuys++;
      }
   }
   
   // 逐个平仓
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         if(ClosePosition(ticket, reason)) {
            closed++;
         } else {
            Print("平仓失败: ", ticket);
         }
      }
   }
   
   if(closed > 0) {
      Print("已平仓", closed, "/", totalBuys, "个多单, 原因: ", reason);
   }
}

void CloseAllSellOrders(string reason)
{
   int closed = 0;
   int totalSells = 0;
   
   // 先统计有多少空单
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         totalSells++;
      }
   }
   
   // 逐个平仓
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         if(ClosePosition(ticket, reason)) {
            closed++;
         } else {
            Print("平仓失败: ", ticket);
         }
      }
   }
   
   if(closed > 0) {
      Print("已平仓", closed, "/", totalSells, "个空单, 原因: ", reason);
   }
}

void CloseAllOrders(string reason)
{
   int closed = 0;
   int totalOrders = 0;
   
   // 先统计有多少订单
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         totalOrders++;
      }
   }
   
   // 逐个平仓
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         if(ClosePosition(ticket, reason)) {
            closed++;
         } else {
            Print("平仓失败: ", ticket);
         }
      }
   }
   
   if(closed > 0) {
      Print("已平仓", closed, "/", totalOrders, "个订单, 原因: ", reason);
   }
}

bool ClosePosition(ulong ticket, string reason)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   if(!PositionSelectByTicket(ticket)) {
      Print("无法选择仓位: ", ticket);
      return false;
   }
   
   long type = PositionGetInteger(POSITION_TYPE);
   double volume = PositionGetDouble(POSITION_VOLUME);
   
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = _Symbol;
   request.volume = volume;
   request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = reason;
   
   if(OrderSend(request, result)) {
      if(result.retcode == TRADE_RETCODE_DONE) {
         Print("平仓成功: ", ticket, " 手数=", volume, " 原因=", reason);
         return true;
      } else {
         Print("平仓失败: ", ticket, " 错误代码=", result.retcode);
         return false;
      }
   }
   Print("平仓失败: ", ticket, " 错误=", GetLastError());
   return false;
}

//+------------------------------------------------------------------+
//| 工具函数                                                         |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBar = iTime(_Symbol, _Period, 0);
   if(currentBar != lastBarTime) {
      lastBarTime = currentBar;
      return true;
   }
   return false;
}

void CheckDaily()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   
   int currentDay = dt.day_of_year;
   MqlDateTime lastDT;
   TimeToStruct(lastDailyCheck, lastDT);
   int lastDay = lastDT.day_of_year;
   
   if(currentDay != lastDay) {
      if(lastDailyCheck != 0) {
         dailyEquityStart = AccountInfoDouble(ACCOUNT_EQUITY);
         Print("每日重置: 已更新起始净值");
      }
      lastDailyCheck = StructToTime(dt);
   }
}

bool CheckSpread()
{
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return spread <= MaxSpread;
}

int GetTotalOrders()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         count++;
      }
   }
   return count;
}

void UpdateATRChannel(double maValue, double atr)
{
   static datetime lastUpdate = 0;
   if(TimeCurrent() - lastUpdate < 1) return;
   lastUpdate = TimeCurrent();
   
   double upper = maValue + (ATRChannelMultiplier * atr);
   double lower = maValue - (ATRChannelMultiplier * atr);
   
   // 更新上轨
   if(ObjectFind(0, "ATR_Upper") < 0) {
      ObjectCreate(0, "ATR_Upper", OBJ_HLINE, 0, 0, upper);
      ObjectSetInteger(0, "ATR_Upper", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "ATR_Upper", OBJPROP_STYLE, STYLE_DASH);
   } else {
      ObjectSetDouble(0, "ATR_Upper", OBJPROP_PRICE, upper);
   }
   
   // 更新下轨
   if(ObjectFind(0, "ATR_Lower") < 0) {
      ObjectCreate(0, "ATR_Lower", OBJ_HLINE, 0, 0, lower);
      ObjectSetInteger(0, "ATR_Lower", OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, "ATR_Lower", OBJPROP_STYLE, STYLE_DASH);
   } else {
      ObjectSetDouble(0, "ATR_Lower", OBJPROP_PRICE, lower);
   }
   
   // 更新中轨
   if(ObjectFind(0, "ATR_Middle") < 0) {
      ObjectCreate(0, "ATR_Middle", OBJ_HLINE, 0, 0, maValue);
      ObjectSetInteger(0, "ATR_Middle", OBJPROP_COLOR, clrYellow);
   } else {
      ObjectSetDouble(0, "ATR_Middle", OBJPROP_PRICE, maValue);
   }
}

//+------------------------------------------------------------------+
//| 显示信息                                                         |
//+------------------------------------------------------------------+
void DisplayInfo(double atr)
{
   static datetime lastUpdate = 0;
   if(TimeCurrent() - lastUpdate < 1) return;
   lastUpdate = TimeCurrent();
   
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyProfit = equity - dailyEquityStart;
   
   // 计算ATR价值和盈利ATR倍数
   double buyATRValue = CalculateATRValue(atr, buyGroup.totalVolume);
   double sellATRValue = CalculateATRValue(atr, sellGroup.totalVolume);
   double buyProfitATR = 0, sellProfitATR = 0;
   
   if(buyATRValue > 0) buyProfitATR = buyGroup.totalProfit / buyATRValue;
   if(sellATRValue > 0) sellProfitATR = sellGroup.totalProfit / sellATRValue;
   
   string info = "\n═══════════════════════════════════════\n";
   info += "       布林通道+ATR交易系统\n";
   info += "═══════════════════════════════════════\n";
   info += StringFormat("时间: %s | ATR: %.5f\n", TimeToString(TimeCurrent()), atr);
   info += StringFormat("余额: $%.2f | 净值: $%.2f | 当日: $%.2f\n", balance, equity, dailyProfit);
   info += StringFormat("持仓: %d/%d | 点差: %d\n", GetTotalOrders(), MaxSpread, SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
   info += "───────────────────────────────────────\n";
   info += StringFormat("多单: %d单(L%d) | 利润: $%.2f\n", 
           buyGroup.orderCount, buyGroup.gridLevel, buyGroup.totalProfit);
   info += StringFormat("盈利: %.2f/%.2fATR | 平均价: %.5f\n", 
           buyProfitATR, BuyTakeProfit_ATR, buyGroup.avgPrice);
   info += StringFormat("浮亏等级: %d | 加仓间隔: %.1fATR\n", 
           buyGroup.floatLossLevel, buyGroup.currentGridStep);
   info += "───────────────────────────────────────\n";
   info += StringFormat("空单: %d单(L%d) | 利润: $%.2f\n", 
           sellGroup.orderCount, sellGroup.gridLevel, sellGroup.totalProfit);
   info += StringFormat("盈利: %.2f/%.2fATR | 平均价: %.5f\n", 
           sellProfitATR, SellTakeProfit_ATR, sellGroup.avgPrice);
   info += StringFormat("浮亏等级: %d | 加仓间隔: %.1fATR\n", 
           sellGroup.floatLossLevel, sellGroup.currentGridStep);
   info += "═══════════════════════════════════════\n";
   
   Comment(info);
}