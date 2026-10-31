//+------------------------------------------------------------------+
//| FiboRSI8_SingleShot_MT4_v124.mq4                                 |
//| MT4 port: BLUE reaction zone = BUY; R1/R1Zone/R2 = SELL.         |
//| Includes fixed TP (R multiple), break-even and ATR trailing.      |
//| Rules-based reconstruction, not the original TradingView source. |
//+------------------------------------------------------------------+
#property strict
#property version "1.24"
#property description "FiboRSI8 MT4 v1.24: BLUE=BUY, R1/R2=SELL, TP + ATR trailing"

input int RSI_Period=8;
input ENUM_TIMEFRAMES RSI_Timeframe=PERIOD_M15;
input ENUM_TIMEFRAMES Fibo_Timeframe=PERIOD_H1;
input bool Use_H4_Filter=false;
input ENUM_TIMEFRAMES Filter_Timeframe=PERIOD_H4;
input double Sideways_Low=45.0;
input double Sideways_High=55.0;
input int Lookback_Fibo_Bars=80;
input int Min_Body_Points=10;
input double Min_Body_ATR=0.15;

input bool Single_Shot=true;
input bool One_Position_Per_Symbol=true;
input int Touch_Tolerance_Points=100;
input double Entry_Tolerance_ATR=0.20;
input double Blue_Zone_Padding_ATR=0.10;
input bool Use_R1=true;
input bool Use_R1_Zone=true;
input bool Use_R2=true;
input bool Use_Candle_Confirmation=false;

input double Buy_PR_Ratio=0.382;
input double Buy_FDR_Ratio=1.120;
input double Buy_PO_Ratio=1.382;
input double Buy_CL_Ratio=1.618;
input double Buy_R1_Ratio=-0.250;
input double Buy_R1Zone_Ratio=-0.441;
input double Buy_R2_Ratio=-0.850;
input double Sell_PR_Ratio=0.618;
input double Sell_FDR_Ratio=-0.120;
input double Sell_PO_Ratio=-0.382;
input double Sell_CL_Ratio=-0.618;
input double Sell_R1_Ratio=-0.250;
input double Sell_R1Zone_Ratio=-0.441;
input double Sell_R2_Ratio=-0.850;

input bool Use_Risk_Percent=true;
input double Risk_Percent=1.0;
input double Fixed_Lot=0.01;
input double Max_Lot=0.10; // hard cap; 0 = broker maximum
input double Min_SL_Distance_Points=300.0; // 300 points = 3.00 on 2-digit XAUUSD; 0 = disabled
input double Min_SL_Spread_Multiple=3.0; // SL distance >= spread x factor
input double SL_Buffer_ATR=0.20;
input double TakeProfit_RR=2.0; // fixed TP at 2R by default
input int Max_Spread_Points=0;
input int Slippage_Points=50;
input int Magic_Number=8050808;

input bool Use_BreakEven=true;
input double BreakEven_RR=1.0;
input int BreakEven_Plus_Points=2;
input bool Use_Trailing=true;
input double Trail_Start_RR=0.8;
input double Trail_ATR_Multiplier=1.20;
input double Trail_Step_ATR=0.15;
input bool Show_Panel=true;

#define MAP_NONE 0
#define MAP_BUY 1
#define MAP_SELL -1
struct FiboMap { bool valid; int direction; datetime candleTime; double low,high,range,LH0,LH1,PR,FDR,PO,CL,R1,R1Zone,R2; };
FiboMap g_map;
datetime g_lastFiboBar=0;
int g_lastRegime=0;
bool g_shotTaken=false;
string g_reason="Initializing";
string g_state="OFF";

int TF(ENUM_TIMEFRAMES tf){ if(tf==PERIOD_CURRENT) return Period(); return (int)tf; }
double NP(double p){ return NormalizeDouble(p,Digits); }
double ATR(int shift=1){ return iATR(Symbol(),TF(Fibo_Timeframe),14,shift); }
double Tol(){ double a=ATR(1); return MathMax(Touch_Tolerance_Points*Point,(a>0?a*Entry_Tolerance_ATR:0)); }
bool SpreadOK(){ return (Max_Spread_Points<=0 || (Ask-Bid)/Point<=Max_Spread_Points); }
bool HasPosition(){ for(int i=OrdersTotal()-1;i>=0;i--){ if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))continue; if(OrderSymbol()==Symbol()&&OrderMagicNumber()==Magic_Number&&(OrderType()==OP_BUY||OrderType()==OP_SELL))return true;} return false; }
int Regime(double &rsi,double &h4){ rsi=iRSI(Symbol(),TF(RSI_Timeframe),RSI_Period,PRICE_CLOSE,1); h4=iRSI(Symbol(),TF(Filter_Timeframe),RSI_Period,PRICE_CLOSE,1); if(rsi>=Sideways_Low&&rsi<=Sideways_High)return MAP_NONE; if(rsi<Sideways_Low){if(Use_H4_Filter&&h4<Sideways_Low)return MAP_NONE;return MAP_BUY;} if(rsi>Sideways_High){if(Use_H4_Filter&&h4>Sideways_High)return MAP_NONE;return MAP_SELL;} return MAP_NONE; }
double Ratio(double low,double range,double r){return NP(low+range*r);}
bool BuildMap(int dir,FiboMap &m){ int lim=MathMax(20,Lookback_Fibo_Bars); for(int i=1;i<=lim;i++){ double o=iOpen(Symbol(),TF(Fibo_Timeframe),i),c=iClose(Symbol(),TF(Fibo_Timeframe),i),h=iHigh(Symbol(),TF(Fibo_Timeframe),i),l=iLow(Symbol(),TF(Fibo_Timeframe),i); double body=MathAbs(c-o),atr=ATR(1); if(h<=l||body<Min_Body_Points*Point||(atr>0&&body<atr*Min_Body_ATR))continue; if(dir==MAP_BUY&&c<=o)continue; if(dir==MAP_SELL&&c>=o)continue; m.valid=true;m.direction=dir;m.candleTime=iTime(Symbol(),TF(Fibo_Timeframe),i);m.low=l;m.high=h;m.range=h-l;m.LH0=NP(l);m.LH1=NP(h); if(dir==MAP_BUY){m.PR=Ratio(l,m.range,Buy_PR_Ratio);m.FDR=Ratio(l,m.range,Buy_FDR_Ratio);m.PO=Ratio(l,m.range,Buy_PO_Ratio);m.CL=Ratio(l,m.range,Buy_CL_Ratio);m.R1=Ratio(l,m.range,Buy_R1_Ratio);m.R1Zone=Ratio(l,m.range,Buy_R1Zone_Ratio);m.R2=Ratio(l,m.range,Buy_R2_Ratio);}else{m.PR=Ratio(l,m.range,Sell_PR_Ratio);m.FDR=Ratio(l,m.range,Sell_FDR_Ratio);m.PO=Ratio(l,m.range,Sell_PO_Ratio);m.CL=Ratio(l,m.range,Sell_CL_Ratio);m.R1=Ratio(l,m.range,Sell_R1_Ratio);m.R1Zone=Ratio(l,m.range,Sell_R1Zone_Ratio);m.R2=Ratio(l,m.range,Sell_R2_Ratio);} return true;} return false; }
bool RecentTouch(double level){ if(level<=0)return false; double tol=Tol(); double mid=(Ask+Bid)/2; if(MathAbs(mid-level)>tol*1.5)return false; for(int i=1;i<=2;i++)if(iLow(Symbol(),TF(RSI_Timeframe),i)<=level+tol&&iHigh(Symbol(),TF(RSI_Timeframe),i)>=level-tol)return true; return false; }
bool Touch(double p,double level){return level>0&&MathAbs(p-level)<=Tol();}
bool BlueZone(){ if(!g_map.valid)return false; double lo=MathMin(g_map.PR,MathMin(g_map.FDR,g_map.PO));double hi=MathMax(g_map.PR,MathMax(g_map.FDR,g_map.PO));double a=ATR(1);double pad=(a>0?a*Blue_Zone_Padding_ATR:Tol());double p=(Ask+Bid)/2;return p>=lo-pad&&p<=hi+pad; }
bool CandleOK(int dir){if(!Use_Candle_Confirmation)return true;double o=iOpen(Symbol(),TF(RSI_Timeframe),1),c=iClose(Symbol(),TF(RSI_Timeframe),1);return dir==MAP_BUY?c>o:c<o;}
double Lots(double entry,double sl){ double lots=Fixed_Lot;if(Use_Risk_Percent&&Risk_Percent>0){double risk=AccountEquity()*Risk_Percent/100.0;double tv=MarketInfo(Symbol(),MODE_TICKVALUE),ts=MarketInfo(Symbol(),MODE_TICKSIZE);double loss=(MathAbs(entry-sl)/MathMax(ts,Point))*tv;if(loss>0)lots=risk/loss;} double minLot=MarketInfo(Symbol(),MODE_MINLOT),maxLot=MarketInfo(Symbol(),MODE_MAXLOT),step=MarketInfo(Symbol(),MODE_LOTSTEP);if(Max_Lot>0)maxLot=MathMin(maxLot,Max_Lot);if(maxLot<minLot)return 0;lots=MathMax(minLot,MathMin(maxLot,lots));lots=MathFloor(lots/step+1e-8)*step;if(lots>maxLot)lots=MathFloor(maxLot/step+1e-8)*step;return NormalizeDouble(lots,2); }
void DrawLine(string name,double price,color clr,int style=STYLE_DASH){ if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_HLINE,0,0,price);ObjectSetDouble(0,name,OBJPROP_PRICE1,price);ObjectSetInteger(0,name,OBJPROP_COLOR,clr);ObjectSetInteger(0,name,OBJPROP_STYLE,style); }
void DrawMap(){ DrawLine("FR8_LH0",g_map.LH0,clrSilver);DrawLine("FR8_LH1",g_map.LH1,clrSilver);DrawLine("FR8_PR",g_map.PR,clrDodgerBlue,STYLE_SOLID);DrawLine("FR8_FDR",g_map.FDR,clrDodgerBlue);DrawLine("FR8_PO",g_map.PO,clrDodgerBlue);DrawLine("FR8_CL",g_map.CL,clrTomato);DrawLine("FR8_R1",g_map.R1,clrOrangeRed);DrawLine("FR8_R1Z",g_map.R1Zone,clrOrange);DrawLine("FR8_R2",g_map.R2,clrRed); }
void Panel(double rsi){if(!Show_Panel)return;string mapTxt=g_map.valid?(g_map.direction==MAP_BUY?"BUY":"SELL"):"INVALID";Comment("FiboRSI8 SingleShot MT4 v1.24\nEA: ",g_state," | RSI: ",DoubleToString(rsi,2),"\nFIBO MAP: ",mapTxt," | BLUE=BUY | R1/R2=SELL\n",g_reason,"\nTP RR: ",DoubleToString(TakeProfit_RR,1)," | ATR trailing: ",Use_Trailing?"ON":"OFF");}
bool OpenTrade(int dir){
 RefreshRates(); double atr=ATR(1);if(atr<=0)atr=MathMax(g_map.range*0.1,10*Point);
 double entry=dir==MAP_BUY?Ask:Bid,sl,tp;
 if(dir==MAP_BUY){double blueLo=MathMin(g_map.PR,MathMin(g_map.FDR,g_map.PO));sl=blueLo-atr*SL_Buffer_ATR;if(sl>=entry)sl=entry-atr*1.5;}
 else {sl=g_map.R1+atr*SL_Buffer_ATR;if(sl<=entry)sl=entry+atr*1.5;}
 double spreadPrice=Ask-Bid;double requiredDist=MathMax(Min_SL_Distance_Points*Point,MathMax(0.0,Min_SL_Spread_Multiple)*spreadPrice);
 requiredDist=MathMax(requiredDist,(MarketInfo(Symbol(),MODE_STOPLEVEL)+2)*Point);
 if(dir==MAP_BUY&&entry-sl<requiredDist)sl=entry-requiredDist;
 if(dir==MAP_SELL&&sl-entry<requiredDist)sl=entry+requiredDist;
 sl=NP(sl);double risk=MathAbs(entry-sl);if(risk<=0){g_reason="Trade skipped: invalid SL distance";return false;}
 double actualSpread=Ask-Bid;if(risk+Point<Min_SL_Distance_Points*Point|| (Min_SL_Spread_Multiple>0&&risk<actualSpread*Min_SL_Spread_Multiple)){g_reason="Trade skipped: SL too close to spread/minimum";Print(g_reason);return false;}
 tp=0;if(TakeProfit_RR>0)tp=NP(dir==MAP_BUY?entry+risk*TakeProfit_RR:entry-risk*TakeProfit_RR);
 double lot=Lots(entry,sl);if(lot<=0){g_reason="Trade skipped: Max_Lot below broker minimum";Print(g_reason);return false;}
 RefreshRates();entry=dir==MAP_BUY?Ask:Bid;
 // Re-check distance after refreshing the quote; widen SL if spread changed.
 requiredDist=MathMax(Min_SL_Distance_Points*Point,MathMax(0.0,Min_SL_Spread_Multiple)*(Ask-Bid));requiredDist=MathMax(requiredDist,(MarketInfo(Symbol(),MODE_STOPLEVEL)+2)*Point);
 if(dir==MAP_BUY&&entry-sl<requiredDist)sl=NP(entry-requiredDist);if(dir==MAP_SELL&&sl-entry<requiredDist)sl=NP(entry+requiredDist);
 risk=MathAbs(entry-sl);tp=0;if(TakeProfit_RR>0)tp=NP(dir==MAP_BUY?entry+risk*TakeProfit_RR:entry-risk*TakeProfit_RR);lot=Lots(entry,sl);if(lot<=0)return false;
 ResetLastError();int type=dir==MAP_BUY?OP_BUY:OP_SELL;int ticket=OrderSend(Symbol(),type,lot,entry,Slippage_Points,sl,tp,"FiboRSI8 SingleShot v1.24",Magic_Number,0,dir==MAP_BUY?clrDodgerBlue:clrTomato);
 if(ticket<0){int err=GetLastError();g_reason=StringConcatenate(dir==MAP_BUY?"BUY FAIL error=":"SELL FAIL error=",err);Print(g_reason);return false;}
 g_reason=StringConcatenate(dir==MAP_BUY?"BUY opened ticket ":"SELL opened ticket ",ticket);g_state=dir==MAP_BUY?"BUY OPEN":"SELL OPEN";Print(g_reason," lots=",lot," SL=",sl," TP=",tp," riskDistance=",risk," spread=",Ask-Bid);return true;
}
void ManageOrders(){double atr=ATR(1);if(atr<=0)return;for(int i=OrdersTotal()-1;i>=0;i--){if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))continue;if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=Magic_Number)continue;int type=OrderType();if(type!=OP_BUY&&type!=OP_SELL)continue;double open=OrderOpenPrice(),sl=OrderStopLoss(),tp=OrderTakeProfit();if(sl<=0)continue;double risk=MathAbs(open-sl);if(risk<=0)continue;double profit=type==OP_BUY?Bid-open:open-Ask;double rr=profit/risk;double newSL=sl;if(Use_BreakEven&&rr>=BreakEven_RR){double be=type==OP_BUY?NP(open+BreakEven_Plus_Points*Point):NP(open-BreakEven_Plus_Points*Point);if(type==OP_BUY&&be>newSL)newSL=be;if(type==OP_SELL&&be<newSL)newSL=be;}if(Use_Trailing&&rr>=Trail_Start_RR){double candidate=type==OP_BUY?NP(Bid-atr*Trail_ATR_Multiplier):NP(Ask+atr*Trail_ATR_Multiplier);double step=atr*Trail_Step_ATR;if(type==OP_BUY&&candidate>newSL+step)newSL=candidate;if(type==OP_SELL&&candidate<newSL-step)newSL=candidate;}double minDist=(MarketInfo(Symbol(),MODE_STOPLEVEL)+1)*Point;if(type==OP_BUY&&newSL>sl&&newSL<Bid-minDist){if(!OrderModify(OrderTicket(),open,newSL,tp,0,clrNONE))Print("Trailing BUY modify failed err=",GetLastError());}if(type==OP_SELL&&newSL<sl&&newSL>Ask+minDist){if(!OrderModify(OrderTicket(),open,newSL,tp,0,clrNONE))Print("Trailing SELL modify failed err=",GetLastError());}}}
int OnInit(){g_map.valid=false;g_lastFiboBar=iTime(Symbol(),TF(Fibo_Timeframe),0);return(INIT_SUCCEEDED);}
void OnDeinit(const int reason){Comment("");string names[]={"FR8_LH0","FR8_LH1","FR8_PR","FR8_FDR","FR8_PO","FR8_CL","FR8_R1","FR8_R1Z","FR8_R2"};for(int i=0;i<ArraySize(names);i++)ObjectDelete(0,names[i]);}
void OnTick(){ManageOrders();double rsi=50,h4=50;int regime=Regime(rsi,h4);datetime fb=iTime(Symbol(),TF(Fibo_Timeframe),0);if(fb!=g_lastFiboBar||regime!=g_lastRegime||!g_map.valid){g_lastFiboBar=fb;g_lastRegime=regime;if(regime==MAP_NONE){g_map.valid=false;g_state="WAIT";g_reason="RSI SIDEWAY / no direction";}else{int mapDir=-regime;FiboMap candidate;if(BuildMap(mapDir,candidate)){if(!g_map.valid||candidate.candleTime!=g_map.candleTime||candidate.direction!=g_map.direction){g_map=candidate;g_shotTaken=false;DrawMap();}g_state=regime==MAP_BUY?"WAIT FOR BUY":"WAIT FOR SELL";g_reason="Waiting for reaction zone";}else{g_map.valid=false;g_state="OFF";g_reason="No valid Fibo candle";}}}if(!g_map.valid){Panel(rsi);return;}if(!SpreadOK()){g_reason="Spread too high";Panel(rsi);return;}if(One_Position_Per_Symbol&&HasPosition()){g_reason="Position already open";Panel(rsi);return;}if(Single_Shot&&g_shotTaken){g_reason="Single Shot used for this map";Panel(rsi);return;}bool buy=(g_map.direction==MAP_SELL&&BlueZone()&&CandleOK(MAP_BUY));bool sell=(g_map.direction==MAP_BUY&&!BlueZone()&&( (Use_R1&&(Touch(Bid,g_map.R1)||RecentTouch(g_map.R1)))||(Use_R1_Zone&&(Touch(Bid,g_map.R1Zone)||RecentTouch(g_map.R1Zone)))||(Use_R2&&(Touch(Bid,g_map.R2)||RecentTouch(g_map.R2))) )&&CandleOK(MAP_SELL));if(buy){if(OpenTrade(MAP_BUY))g_shotTaken=true;}else if(sell){if(OpenTrade(MAP_SELL))g_shotTaken=true;}else g_reason="Waiting: BLUE=BUY or R1/R2=SELL";Panel(rsi);}
//+------------------------------------------------------------------+
