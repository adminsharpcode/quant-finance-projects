<chart>
id=134343819107861214
symbol=GBPAUD
period=240
leftpos=6564
digits=5
scale=4
graph=1
fore=0
grid=0
volume=0
scroll=1
shift=1
ohlc=0
one_click=0
one_click_btn=1
askline=0
days=0
descriptions=0
shift_size=26
fixed_pos=0
window_left=694
window_top=0
window_right=1918
window_bottom=985
window_type=1
background_color=394244
foreground_color=10125950
barup_color=11493944
bardown_color=6960556
bullcandle_color=11493944
bearcandle_color=6960556
chartline_color=11493944
volumes_color=6200333
grid_color=4865081
askline_color=3286091
stops_color=5968066

<window>
height=312
fixed_height=0
<indicator>
name=main
<object>
type=24
object_name=DrW_XCP_GBPAUD134343819107861216_CANVAS
period_flags=0
create_time=1789974254
description=BitmapLabel
color=8421504
font=Arial
fontsize=10
angle=0
anchor_pos=0
background=0
corner=0
x_distance=1
y_distance=20
filling=0
selectable=0
hidden=1
zorder=0
size_x=0
size_y=0
offset_x=0
offset_y=0
state=0
bmpfile_on=C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\0E9DF41E457B90231E706129F0D6BB0C\MQL4\Experts\TraderAgent.ex4::DrW_XCP_GBPAUD134343819107861216_CANVAS401926037
</object>
<object>
type=24
object_name=DrW_XCP_GBPAUD134343819107861216_TITLECANVAS
period_flags=0
create_time=1789974254
description=BitmapLabel
color=8421504
font=Arial
fontsize=10
angle=0
anchor_pos=0
background=0
corner=0
x_distance=6
y_distance=22
filling=0
selectable=0
hidden=1
zorder=0
size_x=0
size_y=0
offset_x=0
offset_y=0
state=0
bmpfile_on=C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\0E9DF41E457B90231E706129F0D6BB0C\MQL4\Experts\TraderAgent.ex4::DrW_XCP_GBPAUD134343819107861216_TITLECANVAS401924887
</object>
<object>
type=28
object_name=[AP Panel] PVSRA 1
period_flags=0
create_time=1789974297
description=RectangleLabel
color=460037
font=Arial
fontsize=10
background=0
filling=0
selectable=0
hidden=1
zorder=0
corner=2
x_distance=-1
y_distance=19
size_x=206
size_y=20
bgcolor=460037
border_type=0
</object>
<object>
type=23
object_name=[AP Panel] PVSRA 2
period_flags=0
create_time=1789974297
description=PVSRA  v2.4  by  Traderathome,  et  al.
color=9230301
font=Tahoma
fontsize=8
angle=0
anchor_pos=2
background=0
filling=0
selectable=1
hidden=0
zorder=0
corner=2
x_distance=6
y_distance=4
</object>
<object>
type=2
object_name=[AP Ask] Ask Line
period_flags=0
create_time=1789974297
color=6579300
style=2
weight=1
background=1
filling=0
selectable=1
hidden=0
zorder=0
time_0=1790020800
value_0=1.876550
time_1=1789963200
value_1=1.876550
ray=1
</object>
<object>
type=2
object_name=[AP Bid] Bid Line
period_flags=0
create_time=1789974297
color=6579300
style=2
weight=1
background=1
filling=0
selectable=1
hidden=0
zorder=0
time_0=1790020800
value_0=1.876250
time_1=1789963200
value_1=1.876250
ray=1
</object>
</indicator>
<indicator>
name=Custom Indicator
<expert>
name=1) PVSRA v2.4 Trade Levels (Black)
flags=339
window_num=0
<inputs>
_=
Part_1_____________________________=Main Settings:
Indicator_On=true
Show_Micro_Mini_Full_123=1
Show_Open_Long_Trades=true
Show_Open_Short_Trades=true
Show_Closed_Long_Trades=true
Show_Closed_Short_Trades=true
Show_Pending_Orders=true
Note_1_1=Next 2 items affect chart display only.
Note_1_2=Do not control MT4 order processing!
__Per_FIFO_Regulation=false
__Per_NO_HEDGING_Regulation=false
Lookback_Multiple_Factor=1
Display_Max_TF=240
TF_Choices=1-5-15-30-60-240-1440-10080-43200
__=
Part_2_____________________________=PL Label Settings:
Currency_Symbol=$
Include_Commissions_Swaps=true
Note_2_1=For Open & Closed Trade Displays, if you
Note_2_2='Show_Units'  average pips for the units
Note_2_3=and the total pips are shown.  If you don't
Note_2_4='Show_Units'  only average pips will show
Note_2_5=indicating average pips distance between
Note_2_6=EPs & TPs. 'Show_Micro_Mini_Full_123'
Note_2_7=sets pip values, based on type unit input.
Open_Trade=
__Show_Units=true
__Show_Money=true
__Show_Percent=false
Closed_Trade=
___Show_Units=false
___Show_Money=true
___Show_Percent=false
___=
Part_3_____________________________=EP/AV/SL/TP Settings:
EP_Level_Line_Width=1
AV_SL_TP_Level_Line_Width=1
Show_EP_PO_Levels_and_Labels=false
Show_EP_Price_Dots=true
Show_EP_PL_Lines=false
__Subordinate_PL_Lines=false
Show_Full_EP_Level_lines=false
Show_Full_PO_Level_lines=false
Show_Full_AV_Level_lines=false
Show_Full_SL_TP_Level_lines=false
Note_3_1=You can apply  ' trial '  SL/TP  to chart.
Note_3_2=Real SL/TP order prices replace them.
Enter_Trial_SL_Long=0.0
Enter_Trial_TP_Long=0.0
Enter_Trial_SL_Short=0.0
Enter_Trial_TP_Short=0.0
____=
Part_4_____________________________=Closed Trade Display Settings:
Show_Price_Dots=true
Show_Price_Lines=true
__Subordinate_Lines=false
Lookback_Time_Span_Minutes=1
Lookback_Exact_Start_Time=yyyy.mm.dd hh:mm
Lookback_Exact_End_Time=yyyy.mm.dd hh:mm
__Reset_via_Copy_Paste=yyyy.mm.dd hh:mm
Show_Separate_Trade_Groups=true
__Min_Minutes_Btwn_Groups=60
__PL_Label_1_Adjust_Height=30
__PL_Label_2_Adjust_Height=30
__PL_Label_3_Adjust_Height=30
__PL_Label_4_Adjust_Height=30
__PL_Label_5_Adjust_Height=30
_____=
Part_5_____________________________=PL Labels Color Settings:
Open_PL_Panel=460037
Open_PL_Panel_Border=6908265
Open_PL_Text_Profit=3845169
Open_PL_Text_Loss=3746300
Closed_PL_Label_Panel_Profit=10081138
Closed_PL_Label_Panel_Loss=12757976
Closed_PL_Label_Text_Profit=1406720
Closed_PL_Label_Text_Loss=223
______=
Part_6_____________________________=Levels Color Settings:
EP_Level_Label=16619102
EP_Level_Line=13463627
AV_Level_Label=-1
AV_Level_Line=-1
SL_Level_Label=4666367
SL_Level_Line=3749322
TP_Level_Label=4694573
TP_Level_Line=3505451
_______=
Part_7=Dot Size Settings:
Note_7_1=For each Chart Scale 0-5 select the
Note_7_2=Dot Static Size 0-5 you want applied:
CS0_SS=0
CS1_SS=0
CS2_SS=0
CS3_SS=0
CS4_SS=0
CS5_SS=0
________=
Part_8_____________________________=Dot Related Color Settings:
Note_8_1=Colors for Size in EP Labels:
EP_Size_Label_Long=16765254
EP_Size_Label_Short=9934847
Note_8_2=Colors for Long Trade Dots:
EP_Dot_Ring_Open_Long=0
EP_Dot_Ring_Closed_Long=16777215
EP_Dot_Body_Long=16761357
EP_Dot_Center_Long=0
CP_Dot_Ring_Long=0
CP_Dot_Body_Long=65535
CP_Dot_Center_Long=16711680
Note_8_3=Colors for Short Trade Dots:
EP_Dot_Ring_Open_Short=0
EP_Dot_Ring_Closed_Short=16777215
EP_Dot_Body_Short=8421631
EP_Dot_Center_Short=0
CP_Dot_Ring_Short=0
CP_Dot_Body_Short=65535
CP_Dot_Center_Short=3937500
Note_8_4=Colors for PL Trade Lines:
PL_Line_Trade_Positive=16765254
PL_Line_Trade_Negative=8421631
</inputs>
</expert>
shift_0=0
draw_0=0
color_0=0
style_0=0
weight_0=0
period_flags=0
show_data=1
</indicator>
<indicator>
name=Custom Indicator
<expert>
name=2) PVSRA v2.4 Access Panel (Black)
flags=339
window_num=0
<inputs>
Indicator_On=true
Preface____________=Find & enter Clock Proxy Server Tz Location.
Clock_vs_Find_Server_on_Live_Feed=true
Clock_Proxy_Server_Tz_Location=Helsinki
Preface_____________=Read User Notes.  Contact your broker to confirm.
_=
Part_1_____________________________=Indicator Master Controls:
Access_Panel_On=false
__Clock_On_Full_Size_Charts=true
__Clock_On_Downsized_Charts=false
Ask_Line_On=true
__Ask_Max_TF=240
Bid_Line_On=true
Levels_On=false
__Show_Half_Levels=true
__Show_Quarter_Levels=true
__Levels_Whole_Max_TF=240
__Levels_Half_Max_TF=240
__Levels_Quarter_Max_TF=240
__Note_1_0=To Adjust Levels Spacing:
__Note_1_1=Some items may require a change to Levels spacing.
__Note_1_2=Automatically change Levels spacing using EXACT
__Note_1_3=Market Watch list name and this following method
__Note_1_4=using discrete numbers to change Levels spacing
__Note_1_5=by factors of 10  ( -1=/10, 1=10x,  2=100x,  etc.).
__Note_1_6=Enter:  name = +,-  number   Example:  BTCUSD=1
__Note_1_7=To do more than one item, separate with semicolon.
__Note_1_8=Example:  EURAUD=-1;US30Index=1;XAUUSDi=2
__Note_1_9=Enter EXACT names & Levels spacing settings here:
__EXACT_Name_Levels_Spacing=XAUUSD=2;BTCUSD=2;ETHUSD=2;LTCUSD=2
__Note_1_10=To +,- Levels spacing for just the chart item, input
__Note_1_11=the +,- number here,.....DO NOT use both methods!:
__Chart_Item_Levels_Spacing=1
Natural_Fibos=true
__Fibos_Max_TF=60
Pivots_On=false
__Use_Day_vs_Fibonacci_Formula=true
__Show_PVT=true
__Show_SR=true
__Show_Mid=false
__Show_Levels_4_Thru_6=true
__Use_PivotsTz=true
___Use_Preferred_Offset=true
___Alternative_GMT_Offset=0
__PVT_Max_TF=60
Range_Day_Off_Stat_Move_Both_0123=0
__Day_Max_TF=1440
Range_Week_Off_Stat_Move_Both_0123=0
__Week_Max_TF=10080
Separators_On=false
__Prior_Days_To_Show=0
__Separators_Max_TF=60
vLines_On=false
__Current_Session_Max_TF=60
__Prior_Sessions_Max_TF=60
__Prior_Sessions_To_Show=0
TF_Choices=1-5-15-30-60-240-1440-10080-43200
__=
Part_2_____________________________=Panel Settings:
Days_In_Range_Day_Avg=15
Weeks_In_Week_ATR=13
Panel_Color=1314832
Panel_Border_Color=6908265
Symbol_And_TF_Color=13684944
Mkt_Bid_UP_Color=5089792
Mkt_Bid_DN_Color=5046512
Mkt_Bid_Display_with_Bold_Font=true
Downsize_Fractional_Pip=true
__Shift_Fractional_Pip_LR=0
Candle_Time_Color=8506321
Range_Color=15779705
Swaps_Color=15779705
Spread_Color=15180777
Logo=14512224
___=
Part_3_____________________________=Ask-Bid Line Settings:
Ask_Ray_Color=6579300
Ask_Ray_LineStyle_01234=2
Ask_Ray_Thickness=1
Bid_Ray_Color=6579300
Bid_Ray_LineStyle_01234=2
Bid_Ray_Thickness=1
Subordinate_Ask_Bid_Lines=true
Ask_Dot_Color=14474460
Ask_Dot_Size=6
Ask_Dot_Cntr_Color=6579300
Ask_Dot_Cntr_Size=4
Bid_Dot_Up_Color=65280
Bid_Dot_Dn_Color=255
Bid_Dot_Mono_Color=16777215
Use_Bid_Dot_Mono_Color=false
Bid_Dot_Size=6
____=
Part_4_____________________________=Horizontal Lines Settings:
Labels_Color=11444898
Subordinate_Fibos=true
Subordinate_Pivots=true
Subordinate_Ranges=true
__Max_TF_to_Subordinate=60
_____=
Part_5_____________________________=Levels Settings:
Level_Whole_Color=6567708
Level_Whole_Style_01234=0
Level_Whole_Width_12345=2
Level_Half_Color=17920
Level_Half_Style_01234=0
Level_Half_Width_12345=2
Level_Quarter_Color=1847616
Level_Quarter_Style_01234=0
Level_Quarter_Width_12345=2
______=
Part_6_____________________________=Fibos Settings:
H_Fibo_Color=12544091
M_Fibo_Color=8220529
L_Fibo_Color=4607696
F_Style_01234=0
F_Width_12345=1
_______=
Part_7_____________________________=Pivots Settings:
PVT1_Back_Color=0
PVT1_Style_01234=0
PVT1_Width_12345=3
PVT2_Top_Color=13324497
PVT2_Style_01234=2
PVT2_Width_12345=1
R_Pivot_Color=729800
R_Style_01234=2
R_Width_12345=1
S_Pivot_Color=16473660
S_Style_01234=2
S_Width_12345=1
MidPivots_Color=3434343
mP_Style_01234=2
mP_Width_12345=1
________=
Part_8_____________________________=Range Day Settings:
RDH_Color=14445419
RDL_Color=4278486
RD_Style_01234=0
RD_Width_12345=1
_________=
Part_9_____________________________=Range Week Settings:
RWH_Color=14244699
RWL_Color=3620048
RW_Style_01234=0
RW_Width_12345=2
___________=
Part_10____________________________=vLines Settings:
vLines_Color=4868682
vLines_Style_01234=2
vLines_Width_12345=1
vLines_Thru_SubWindows=false
Sbow_vLabels=true
vLabels_Color=11444898
__________=
Part_11____________________________=Separators Settings:
Separators_Color=5592405
Separators_Style_01234=2
Separators_Width_12345=1
Separators_Thru_SubWindows=true
____________=
Part_12____________________________=Clock Settings:
Clock_MktClosed=9341056
Location_MktClosed=9341056
Clock_MktOpen=8165833
Location_MktOpen=5354548
Show_AMPM_Time=true
Note_1=Show 7 Maximum:
Note_2=0 = off
Note_3=1 = on
Broker=0
Local=0
Auckland=0
Sydney=1
Tokyo=1
HongKong=1
Jakarta=0
India=0
Dubai=0
Moscow=0
Israel=0
Helsinki=1
Frankfurt=1
London=1
GMT=0
Brazil=0
NewYork=1
Central=0
Mexico=0
Mountain=0
Pacific=0
</inputs>
</expert>
shift_0=0
draw_0=0
color_0=0
style_0=0
weight_0=0
period_flags=0
show_data=1
</indicator>
</window>

<expert>
name=TraderAgent
flags=343
window_num=0
<inputs>
_____Product_name_______= ..:: TraderAgent ::..
CC1______________________========== License settings =========
PassKey=
CC2______________________========== Common settings =========
MagicNumber=-1
CommentForOrder=TraderAgent
OrderSlippage=1
CC3______________________========== Money management =========
RiskPercent=1.0
LOT=0.0
CC4______________________========== SL / TP settings =========
StopLoss=0.0
TakeProfit=0.0
AutoTurnOffPreDefined=true
CC4_1========== Trailing stop settings =========
TrailingType=0
TrailingParam1=0.0
TrailingParam2=0.0
TrailingAlways=false
TrailingCandleOffset=1
TrailingDistanceOffset=0.0
TrailingStopTimeFrame=
CC4_2= TrailingStopAt: 0 - after BreakEventAt; x - after x pips
TrailingStopAt=0.0
CC4_3========== Custom indicator for Trailing stop =========
CustomIndicatorName=
CustomIndicatorParameters=
CustomIndicatorBufferBuy=0
CustomIndicatorBufferSell=0
CC5______________________========== Break Even settings =========
BreakEvenAt=0.0
BreakEvenPips=0.0
CC6______________________========== Partial Close settings =========
QuickPartialClose=50.0
PartialClosePos1=100.0
PartialClosePercent1=50.0
PartialClosePos2=75.0
PartialClosePercent2=50.0
PartialClosePos3=50.0
PartialClosePercent3=50.0
CC21______________________========== Reverse settings =========
ReverseLinePips=0.0
ReverseLotMultiplier=1.0
CC13_____________________========== Trendline handling =========
DisableTrendLinesFunction=false
TrueTLSupport=false
CC14_____________________========== Extra features =========
StealthMode=false
StealthModeHardSLTPDistance=50
AntiSpikeMode=false
DontAllowOrderOpenMaxSpread=5.0
ShowPivotPoints=false
PivotCalculateGMTTime=false
ShowNextCandleTime=false
NextCandleTimeTextColor=16777215
NextCandleTimeReverse=false
ShowSentinelAlerts=false
ConfirmActions=false
RemoveMT4ObjectAfterClose=false
CC19_____________________========== Pending line handling =========
UsePendingLines=false
PendingLineColor=16436871
QuickPendingDistance=20.0
UsePredefinedLineForPending=false
DeletePendingOrderIfNoLine=false
CC20_____________________========== Auto Close-All settings =======
AutoCloseAllProfitMoney=0.0
AutoCloseAllProfitPercent=0.0
AutoCloseAllLossMoney=0.0
AutoCloseAllLossPercent=0.0
CC15_____________________========== Grid feature settings =========
GridStep=0.0
GridMaxOrderCount=0
CC15_1=GridLotMode: 0 - Classic multiplier, 1 - Increment, 2 - Fibo increment
GridLotMode=1
GridLotMultiplier=1.5
GridReCalculateSLTP=false
AutoGridMode=false
CC18_____________________========== Audio settings =========
PlaySoundFileAfterOpen=
PlaySoundFileAfterClose=
CC7______________________========== Visual settings =========
DrawPriceLabel=false
PriceLabelInPips=false
DrawOrderLines=false
UIScalePercent=100.0
HideCopyRight=true
CC7_1____________________========== Control line settings =========
ShowControlLineLabels=false
ControlLineOffset=-80
ControlLineWidth=1
ControlLineLabelColor=-1
AlternativeLineLabels=false
ControlLineLabelFontSize=8
StopLossColor=255
TakeProfitColor=3329330
PartialCloseColor=42495
BreakEvenColor=16436871
ReverseColor=15624315
PreDefinedSLLineColor=16711935
PreDefinedTPLineColor=7451452
PreDefinedPendingLineColor=2139610
ShowAveragePriceLine=false
AveragePriceLineColor=9470064
ShowNextAveragePriceLine=false
NextAveragePriceLineColor=8519755
CC22______________________========== Toolbar settings =========
ShowToolbar=false
ToolbarX=0
ToolbarY=20
CC8______________________========== Account Panel settings =========
ShowAccountPanel=false
AccountPanelX=25
AccountPanelY=25
CC9______________________========== Control Panel settings =========
ShowControlPanel=true
ControlPanelX=1
ControlPanelY=20
CC10_____________________========== Order list settings =========
ShowOrderListPanel=true
OrderListPanelX=25
OrderListPanelY=220
PropertiesPanelPos=1
CC11_____________________========== Profit Panel settings =========
ShowProfitPanel=false
ProfitPanelX=200
ProfitPanelY=25
ProfitOnThisSymbolOnly=false
CC16_____________________========== Dashboard Panel settings =========
ShowDashboard=false
DashboardX=-220
DashboardY=200
DashboardSpreadRedValue=3.0
Dashboard_ShowPriceMeter=true
Dashboard_ShowSemaphore=false
Dashboard_SemaphoreCurrentTF=false
Dashboard_MAPeriod=200
Dashboard_MAMode=1
Dashboard_MAPrice=0
Dashboard_MAShift=0
Dashboard_CCIPeriod=14
Dashboard_CCIPrice=5
Dashboard_RSIPeriod=14
Dashboard_RSIPrice=5
Dashboard_StochKPeriod=14
Dashboard_StockDPeriod=3
Dashboard_StochSlowing=3
Dashboard_StochMode=1
Dashboard_StochPrice=0
CC12_____________________========== Notifications =========
ShowNotifications=false
CC22_____________________========== Advanced settings =========
PipMultiplierOverride=0
CC21_____________________========== Screenshots =========
ScreenShotFolder=TraderAgent ScreenShots
CC17_____________________======== Backtest settings =========
BackTestTime=50
ScreenShotInBacktest=false
PauseBTEveryCandles=0
PauseBTFromDate=0
SupportNewsInfoInBacktest=false
NewsInfoGMTOffset=0.0
</inputs>
</expert>
</chart>

