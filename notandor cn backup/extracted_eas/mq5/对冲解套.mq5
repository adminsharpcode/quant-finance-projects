//+------------------------------------------------------------------+
//|                                                   AutoHedgeEA.mq5 |
//|                                    Copyright 2023, Your Name     |
//|                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, AutoHedge"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| 输入参数 (基于用户图片参数表)                                    |
//+------------------------------------------------------------------+
input int      MagicNumber = 0;                     // 魔术号 (0=管理全部持仓，包括手动开仓)
input int      SameSideMinCount = 3;                // 同向持仓≥几张才启动对冲
input double   OneToOneMinDiff = 50.0;              // 1对1规则最小点差（美元差）
input double   ManyToOneMinDiff = 60.0;             // 多对1规则最小点差（美元差）
input double   MaxProfitHedgeMinDiff = 50.0;        // 最大浮盈对冲最小点差（美元差）
input double   TotalProfitHedgeMinDiff = 50.0;      // 总浮盈对冲最小点差（美元差）
input double   AmountHedgeMinProfit = 5.0;          // 金额对冲最小盈利金额（美元）
input bool     UseOneToOneRule = true;              // 1对1对冲平仓规则
input bool     UseManyToOneRule = true;             // 多对1对冲平仓规则
input bool     UseMaxProfitRule = true;             // 使用最大浮盈对冲规则
input bool     UseTotalProfitRule = true;           // 使用总浮盈对冲规则
input bool     UseAmountRule = true;                // 使用金额对冲规则
input double   LotFilter = 0.0;                     // 手数过滤（0=不过滤）
input double   DefaultLot = 0.01;                   // 默认开仓手数（本EA仅对冲，未使用开仓）
input bool     UseStopLossTakeProfit = false;       // 是否使用止损止盈（false=不使用）
input bool     ShowAvgPriceLine = true;             // 显示持仓均价线
input color    AvgBuyLineColor = Lime;              // 多单均价线颜色
input color    AvgSellLineColor = Red;              // 空单均价线颜色
input int      LineWidth = 2;                       // 线宽
input ENUM_LINE_STYLE LineStyle = STYLE_SOLID;      // 线型
input bool     ShowPanel = true;                    // 是否显示面板
input int      PanelCorner = 0;                     // 0左上1右上2左下3右下
input int      PanelX = 5;                          // 面板X坐标
input int      PanelY = 100;                        // 面板Y坐标
input int      PanelWidth = 380;                    // 面板宽度
input int      PanelHeight = 410;                   // 面板高度

//+------------------------------------------------------------------+
//| 自定义结构体：存储持仓信息                                       |
//+------------------------------------------------------------------+
struct PositionInfo
{
   ulong ticket;
   ENUM_POSITION_TYPE type;
   double volume;
   double profit;
   double openPrice;
   double currentPrice;
};

//+------------------------------------------------------------------+
//| 全局变量                                                        |
//+------------------------------------------------------------------+
datetime lastHedgeTime = 0;
const int hedgeInterval = 2; // 对冲检测间隔(秒)
CTrade trade;                 // 交易对象

//+------------------------------------------------------------------+
//| 函数声明                                                        |
//+------------------------------------------------------------------+
bool GetFilteredPositions(PositionInfo &result[]);
bool OneToOneHedge(PositionInfo &positions[]);
bool ManyToOneHedge(PositionInfo &positions[]);
bool MaxProfitHedge(PositionInfo &positions[]);
bool TotalProfitHedge(PositionInfo &positions[]);
bool AmountHedge(PositionInfo &positions[]);
bool ClosePositions(ulong ticket1, ulong ticket2);
bool ClosePositionsGroup(int &indices[], int singleIdx, PositionInfo &positions[]);
void DrawAvgPriceLines();
void CreateInfoPanel();
void CreateLabel(string name, string text, int x, int y, int fontsize, color clr, int corner);
void UpdateInfoPanel();

//+------------------------------------------------------------------+
//| 专家初始化函数                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   if(ShowPanel)
      CreateInfoPanel();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 专家反初始化函数                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "HedgePanel_");
   ObjectsDeleteAll(0, "AvgLine_");
}

//+------------------------------------------------------------------+
//| 专家报价函数                                                    |
//+------------------------------------------------------------------+
void OnTick()
{
   // 控制检测频率，避免每tick都执行
   if(TimeCurrent() - lastHedgeTime < hedgeInterval)
      return;
   lastHedgeTime = TimeCurrent();
   
   // 执行对冲逻辑
   ExecuteHedge();
   
   // 更新面板和均价线
   if(ShowPanel)
      UpdateInfoPanel();
   if(ShowAvgPriceLine)
      DrawAvgPriceLines();
   else
      ObjectsDeleteAll(0, "AvgLine_");
}

//+------------------------------------------------------------------+
//| 执行对冲解套主逻辑                                              |
//+------------------------------------------------------------------+
void ExecuteHedge()
{
   // 获取当前品种的所有持仓（根据魔术号过滤）
   PositionInfo positions[];
   if(!GetFilteredPositions(positions))
      return;
   
   int buyCount = 0, sellCount = 0;
   double buyTotalLot = 0, sellTotalLot = 0;
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].type == POSITION_TYPE_BUY)
      {
         buyCount++;
         buyTotalLot += positions[i].volume;
      }
      else
      {
         sellCount++;
         sellTotalLot += positions[i].volume;
      }
   }
   
   // 检查同向持仓数量是否达到启动对冲阈值
   if(buyCount < SameSideMinCount && sellCount < SameSideMinCount)
      return;
   
   // 按规则顺序执行对冲（每次只执行一种操作，然后重新检测）
   // 优先级：1对1 -> 多对1 -> 最大浮盈 -> 总浮盈 -> 金额对冲
   if(UseOneToOneRule && OneToOneHedge(positions))
      return;
   if(UseManyToOneRule && ManyToOneHedge(positions))
      return;
   if(UseMaxProfitRule && MaxProfitHedge(positions))
      return;
   if(UseTotalProfitRule && TotalProfitHedge(positions))
      return;
   if(UseAmountRule && AmountHedge(positions))
      return;
}

//+------------------------------------------------------------------+
//| 1对1对冲规则：最大盈利单 vs 最大亏损单                           |
//+------------------------------------------------------------------+
bool OneToOneHedge(PositionInfo &positions[])
{
   int maxProfitIdx = -1, maxLossIdx = -1;
   double maxProfit = -DBL_MAX, maxLoss = DBL_MAX;
   
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].profit > maxProfit)
      {
         maxProfit = positions[i].profit;
         maxProfitIdx = i;
      }
      if(positions[i].profit < maxLoss)
      {
         maxLoss = positions[i].profit;
         maxLossIdx = i;
      }
   }
   
   if(maxProfitIdx == -1 || maxLossIdx == -1) return false;
   if(maxProfitIdx == maxLossIdx) return false;
   
   // 净盈利 = 盈利单盈利 + 亏损单盈利（负数）
   double netProfit = positions[maxProfitIdx].profit + positions[maxLossIdx].profit;
   if(netProfit >= OneToOneMinDiff)
   {
      // 执行对冲平仓
      if(ClosePositions(positions[maxProfitIdx].ticket, positions[maxLossIdx].ticket))
      {
         Print("1对1对冲成功: 盈利单 ", positions[maxProfitIdx].ticket, " 亏损单 ", positions[maxLossIdx].ticket, " 净利 ", netProfit);
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 多对1对冲规则：多个盈利单 vs 一个亏损单 或 多个亏损单 vs 一个盈利单|
//+------------------------------------------------------------------+
bool ManyToOneHedge(PositionInfo &positions[])
{
   // 情况1: 多个盈利单 vs 一个最大亏损单
   int maxLossIdx = -1;
   double maxLoss = DBL_MAX;
   double totalProfit = 0;
   int profitIndices[];
   
   // 找出最大亏损单
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].profit < maxLoss)
      {
         maxLoss = positions[i].profit;
         maxLossIdx = i;
      }
   }
   if(maxLossIdx == -1) return false;
   
   // 收集所有盈利单（盈利 > 0）
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(i != maxLossIdx && positions[i].profit > 0)
      {
         int size = ArraySize(profitIndices);
         ArrayResize(profitIndices, size+1);
         profitIndices[size] = i;
         totalProfit += positions[i].profit;
      }
   }
   
   if(ArraySize(profitIndices) >= 1)
   {
      double netProfit = totalProfit + positions[maxLossIdx].profit;
      if(netProfit >= ManyToOneMinDiff)
      {
         // 平掉所有盈利单和该亏损单
         if(ClosePositionsGroup(profitIndices, maxLossIdx, positions))
         {
            Print("多对1对冲成功(多盈对一亏): 净利 ", netProfit);
            return true;
         }
      }
   }
   
   // 情况2: 多个亏损单 vs 一个最大盈利单
   int maxProfitIdx = -1;
   double maxProfit = -DBL_MAX;
   double totalLoss = 0;
   int lossIndices[];
   
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].profit > maxProfit)
      {
         maxProfit = positions[i].profit;
         maxProfitIdx = i;
      }
   }
   if(maxProfitIdx == -1) return false;
   
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(i != maxProfitIdx && positions[i].profit < 0)
      {
         int size = ArraySize(lossIndices);
         ArrayResize(lossIndices, size+1);
         lossIndices[size] = i;
         totalLoss += positions[i].profit;
      }
   }
   
   if(ArraySize(lossIndices) >= 1)
   {
      double netProfit = positions[maxProfitIdx].profit + totalLoss;
      if(netProfit >= ManyToOneMinDiff)
      {
         if(ClosePositionsGroup(lossIndices, maxProfitIdx, positions))
         {
            Print("多对1对冲成功(多亏对一盈): 净利 ", netProfit);
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 最大浮盈对冲规则：最大浮盈单 vs 最大浮亏单（与1对1类似但独立参数）|
//+------------------------------------------------------------------+
bool MaxProfitHedge(PositionInfo &positions[])
{
   int maxProfitIdx = -1, maxLossIdx = -1;
   double maxProfit = -DBL_MAX, maxLoss = DBL_MAX;
   
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].profit > maxProfit)
      {
         maxProfit = positions[i].profit;
         maxProfitIdx = i;
      }
      if(positions[i].profit < maxLoss)
      {
         maxLoss = positions[i].profit;
         maxLossIdx = i;
      }
   }
   
   if(maxProfitIdx == -1 || maxLossIdx == -1 || maxProfitIdx == maxLossIdx) return false;
   
   double netProfit = positions[maxProfitIdx].profit + positions[maxLossIdx].profit;
   if(netProfit >= MaxProfitHedgeMinDiff)
   {
      if(ClosePositions(positions[maxProfitIdx].ticket, positions[maxLossIdx].ticket))
      {
         Print("最大浮盈对冲成功: 净利 ", netProfit);
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 总浮盈对冲规则：平掉所有持仓，如果总盈利达到阈值                  |
//+------------------------------------------------------------------+
bool TotalProfitHedge(PositionInfo &positions[])
{
   double totalProfit = 0;
   for(int i=0; i<ArraySize(positions); i++)
      totalProfit += positions[i].profit;
   
   if(totalProfit >= TotalProfitHedgeMinDiff)
   {
      // 平掉所有持仓
      for(int i=0; i<ArraySize(positions); i++)
      {
         if(!trade.PositionClose(positions[i].ticket))
         {
            Print("总浮盈对冲平仓失败，ticket: ", positions[i].ticket);
            return false;
         }
      }
      Print("总浮盈对冲成功: 总盈利 ", totalProfit);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| 金额对冲规则：单笔盈利达标，且与任意相反方向订单对冲             |
//+------------------------------------------------------------------+
bool AmountHedge(PositionInfo &positions[])
{
   // 寻找盈利 >= AmountHedgeMinProfit 的订单
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].profit >= AmountHedgeMinProfit)
      {
         // 寻找相反方向且亏损的订单
         for(int j=0; j<ArraySize(positions); j++)
         {
            if(i==j) continue;
            if(positions[i].type != positions[j].type && positions[j].profit < 0)
            {
               double netProfit = positions[i].profit + positions[j].profit;
               if(netProfit >= AmountHedgeMinProfit)
               {
                  if(ClosePositions(positions[i].ticket, positions[j].ticket))
                  {
                     Print("金额对冲成功: 盈利单 ", positions[i].ticket, " 亏损单 ", positions[j].ticket, " 净利 ", netProfit);
                     return true;
                  }
               }
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 平仓两个指定订单                                                |
//+------------------------------------------------------------------+
bool ClosePositions(ulong ticket1, ulong ticket2)
{
   if(!trade.PositionClose(ticket1))
      return false;
   if(!trade.PositionClose(ticket2))
      return false;
   return true;
}

//+------------------------------------------------------------------+
//| 平仓一组订单（多个索引）和一个单独订单                           |
//+------------------------------------------------------------------+
bool ClosePositionsGroup(int &indices[], int singleIdx, PositionInfo &positions[])
{
   // 平掉索引组中的订单
   for(int i=0; i<ArraySize(indices); i++)
   {
      if(!trade.PositionClose(positions[indices[i]].ticket))
         return false;
   }
   // 平掉单独订单
   if(!trade.PositionClose(positions[singleIdx].ticket))
      return false;
   return true;
}

//+------------------------------------------------------------------+
//| 获取过滤后的持仓信息（当前品种，魔术号，手数过滤）               |
//+------------------------------------------------------------------+
bool GetFilteredPositions(PositionInfo &result[])
{
   ArrayResize(result, 0);
   string symbol = Symbol();
   int total = PositionsTotal();
   
   for(int i=0; i<total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionSelectByTicket(ticket))
      {
         // 魔术号过滤
         long magic = PositionGetInteger(POSITION_MAGIC);
         if(MagicNumber != 0 && magic != MagicNumber) continue;
         // 品种过滤
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         
         double volume = PositionGetDouble(POSITION_VOLUME);
         if(LotFilter > 0 && volume < LotFilter) continue;
         
         PositionInfo info;
         info.ticket = ticket;
         info.type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         info.volume = volume;
         info.profit = PositionGetDouble(POSITION_PROFIT);
         info.openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         info.currentPrice = (info.type == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
         int size = ArraySize(result);
         ArrayResize(result, size+1);
         result[size] = info;
      }
   }
   return ArraySize(result) > 0;
}

//+------------------------------------------------------------------+
//| 绘制持仓均价线                                                  |
//+------------------------------------------------------------------+
void DrawAvgPriceLines()
{
   // 删除旧线
   ObjectsDeleteAll(0, "AvgLine_");
   
   PositionInfo positions[];
   if(!GetFilteredPositions(positions)) return;
   
   double totalBuyPrice = 0, totalBuyVol = 0;
   double totalSellPrice = 0, totalSellVol = 0;
   
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].type == POSITION_TYPE_BUY)
      {
         totalBuyPrice += positions[i].openPrice * positions[i].volume;
         totalBuyVol += positions[i].volume;
      }
      else
      {
         totalSellPrice += positions[i].openPrice * positions[i].volume;
         totalSellVol += positions[i].volume;
      }
   }
   
   datetime now = TimeCurrent();
   datetime startTime = now - PeriodSeconds(PERIOD_D1); // 显示1天范围
   
   if(totalBuyVol > 0)
   {
      double avgBuyPrice = totalBuyPrice / totalBuyVol;
      string lineName = "AvgLine_Buy";
      if(ObjectCreate(0, lineName, OBJ_TREND, 0, startTime, avgBuyPrice, now, avgBuyPrice))
      {
         ObjectSetInteger(0, lineName, OBJPROP_COLOR, AvgBuyLineColor);
         ObjectSetInteger(0, lineName, OBJPROP_WIDTH, LineWidth);
         ObjectSetInteger(0, lineName, OBJPROP_STYLE, LineStyle);
         ObjectSetInteger(0, lineName, OBJPROP_BACK, false);
         ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
      }
   }
   
   if(totalSellVol > 0)
   {
      double avgSellPrice = totalSellPrice / totalSellVol;
      string lineName = "AvgLine_Sell";
      if(ObjectCreate(0, lineName, OBJ_TREND, 0, startTime, avgSellPrice, now, avgSellPrice))
      {
         ObjectSetInteger(0, lineName, OBJPROP_COLOR, AvgSellLineColor);
         ObjectSetInteger(0, lineName, OBJPROP_WIDTH, LineWidth);
         ObjectSetInteger(0, lineName, OBJPROP_STYLE, LineStyle);
         ObjectSetInteger(0, lineName, OBJPROP_BACK, false);
         ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
      }
   }
}

//+------------------------------------------------------------------+
//| 创建信息面板                                                    |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
   // 面板背景
   string bgName = "HedgePanel_BG";
   ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, PanelX);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, PanelY);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, PanelWidth);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, PanelHeight);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, bgName, OBJPROP_BACK, true);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, bgName, OBJPROP_FILL, true);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, clrGray);
   
   // 标题
   CreateLabel("HedgePanel_Title", "自动对冲解套EA", PanelX+10, PanelY+20, 14, clrWhite, PanelCorner);
   CreateLabel("HedgePanel_Sep1", "------------------------", PanelX+10, PanelY+40, 10, clrGray, PanelCorner);
   
   // 动态内容将在UpdateInfoPanel中更新
   CreateLabel("HedgePanel_BuyCount", "买单数量: --", PanelX+10, PanelY+65, 10, clrLime, PanelCorner);
   CreateLabel("HedgePanel_SellCount", "卖单数量: --", PanelX+10, PanelY+85, 10, clrRed, PanelCorner);
   CreateLabel("HedgePanel_BuyLot", "买单总手数: --", PanelX+10, PanelY+105, 10, clrLime, PanelCorner);
   CreateLabel("HedgePanel_SellLot", "卖单总手数: --", PanelX+10, PanelY+125, 10, clrRed, PanelCorner);
   CreateLabel("HedgePanel_TotalProfit", "总浮动盈亏: --", PanelX+10, PanelY+145, 10, clrYellow, PanelCorner);
   CreateLabel("HedgePanel_Status", "对冲状态: 等待", PanelX+10, PanelY+170, 10, clrCyan, PanelCorner);
   CreateLabel("HedgePanel_Rules", "规则状态:", PanelX+10, PanelY+195, 10, clrWhite, PanelCorner);
   CreateLabel("HedgePanel_1to1", "1对1规则: --", PanelX+20, PanelY+215, 9, clrLightGray, PanelCorner);
   CreateLabel("HedgePanel_Many1", "多对1规则: --", PanelX+20, PanelY+235, 9, clrLightGray, PanelCorner);
   CreateLabel("HedgePanel_MaxProfit", "最大浮盈规则: --", PanelX+20, PanelY+255, 9, clrLightGray, PanelCorner);
   CreateLabel("HedgePanel_TotalProfitRule", "总浮盈规则: --", PanelX+20, PanelY+275, 9, clrLightGray, PanelCorner);
   CreateLabel("HedgePanel_Amount", "金额对冲规则: --", PanelX+20, PanelY+295, 9, clrLightGray, PanelCorner);
}

//+------------------------------------------------------------------+
//| 创建标签辅助函数                                                |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, int fontsize, color clr, int corner)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| 更新信息面板                                                    |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
   if(!ShowPanel) return;
   
   PositionInfo positions[];
   GetFilteredPositions(positions);
   
   int buyCount=0, sellCount=0;
   double buyLot=0, sellLot=0, totalProfit=0;
   for(int i=0; i<ArraySize(positions); i++)
   {
      if(positions[i].type == POSITION_TYPE_BUY)
      { buyCount++; buyLot += positions[i].volume; }
      else
      { sellCount++; sellLot += positions[i].volume; }
      totalProfit += positions[i].profit;
   }
   
   ObjectSetString(0, "HedgePanel_BuyCount", OBJPROP_TEXT, StringFormat("买单数量: %d", buyCount));
   ObjectSetString(0, "HedgePanel_SellCount", OBJPROP_TEXT, StringFormat("卖单数量: %d", sellCount));
   ObjectSetString(0, "HedgePanel_BuyLot", OBJPROP_TEXT, StringFormat("买单总手数: %.2f", buyLot));
   ObjectSetString(0, "HedgePanel_SellLot", OBJPROP_TEXT, StringFormat("卖单总手数: %.2f", sellLot));
   ObjectSetString(0, "HedgePanel_TotalProfit", OBJPROP_TEXT, StringFormat("总浮动盈亏: %.2f USD", totalProfit));
   
   // 规则启用状态显示
   ObjectSetString(0, "HedgePanel_1to1", OBJPROP_TEXT, StringFormat("1对1规则: %s", UseOneToOneRule?"启用":"禁用"));
   ObjectSetString(0, "HedgePanel_Many1", OBJPROP_TEXT, StringFormat("多对1规则: %s", UseManyToOneRule?"启用":"禁用"));
   ObjectSetString(0, "HedgePanel_MaxProfit", OBJPROP_TEXT, StringFormat("最大浮盈规则: %s", UseMaxProfitRule?"启用":"禁用"));
   ObjectSetString(0, "HedgePanel_TotalProfitRule", OBJPROP_TEXT, StringFormat("总浮盈规则: %s", UseTotalProfitRule?"启用":"禁用"));
   ObjectSetString(0, "HedgePanel_Amount", OBJPROP_TEXT, StringFormat("金额对冲规则: %s", UseAmountRule?"启用":"禁用"));
   
   string status = "监控中";
   if(buyCount >= SameSideMinCount || sellCount >= SameSideMinCount)
      status = "满足对冲条件";
   ObjectSetString(0, "HedgePanel_Status", OBJPROP_TEXT, StringFormat("对冲状态: %s", status));
}
//+------------------------------------------------------------------+