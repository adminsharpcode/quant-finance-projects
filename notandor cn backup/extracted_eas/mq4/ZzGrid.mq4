//+------------------------------------------------------------------+
//|                                                        ZzGrid.mq4 |
//|                                           Copyright 2020,Amin EA |
//|                                             https://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020,Amin EA"
#property link      "https://t.me/amin1softco"
#property version   "1.01"
#property strict
#property description   "This is a FREE Shareware Expert Advisor for MetaTrader 4."
#property description   "TF=5m or TF=15m backtest some pair need reverse =true"


extern double StopLoss    =0;
extern double Slippage  =3;
extern double idistancePoint  =300;
extern double zdiff  =20;
extern double ppLot  =0.5;
extern bool    reverse = true;
extern int magic =110;
extern string Cmt="zzGrid";
extern bool   CloseOnExpiration = false;
extern int    expirationDays = 4; 
extern string o0="========= ZZ =========";// wpr 
extern int Depth  =12;
extern int Deviation  =5;
extern int Backstep  =3;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  double lastpricebuy =(Ask+Bid)/2;
  double lastpricesell =(Ask+Bid)/2;
  int multbuy=1;
  int multsell=1;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     if(Bars<100)
     {
      Print("bars less than 100");
      return;
     }
//---
RefreshRates();
double distancePoint=idistancePoint;//+2*((Ask-Bid)/Point);
  int cntbuy =Count(OP_BUY);
  int cntsell=Count(OP_SELL);
  
Comment("buy:"+cntbuy+"\r\nsell:"+cntsell);

if( CloseOnExpiration == true)
    for (int i = OrdersTotal(); i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderSymbol() == Symbol()  && OrderMagicNumber() == magic && TimeCurrent()-OrderOpenTime() > expirationDays *24 *3600) {
      if (OrderType() == OP_BUY || OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5, CLR_NONE);
      if (OrderType() != OP_BUY && OrderType() != OP_SELL) OrderDelete(OrderTicket());
    
   }
   }
if(NewBar()){
if(signal()>0&&cntbuy==0&&cntsell==0){//buy
runbuy(Symbol(),0.01,"grid");
lastpricebuy =(Ask);
}
if(signal()<0&&cntsell==0&&cntbuy==0){//sell
runsell(Symbol(),0.01,"grid");
lastpricesell =(Bid);
}


 cntbuy =Count(OP_BUY);
 cntsell=Count(OP_SELL);

if(cntbuy!=0 && lastpricebuy-Ask>distancePoint*Point){
runbuy(Symbol(),getnextlot(cntbuy),"grid");
lastpricebuy =(Ask);
}
   
 if(cntsell!=0 && Bid-lastpricesell>distancePoint*Point) {
 runsell(Symbol(),getnextlot(cntsell),"grid");
lastpricesell =(Bid);
 } 
   
   }
   if(cntbuy!=0 && Ask-lastpricebuy>multbuy*distancePoint*Point){
   
   
   //if(cntbuy<14)
if (!(sumprofit(OP_BUY)>0) ){
multbuy++;
return;
}

multbuy=1;

    for (int i = OrdersTotal(); i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderSymbol() == Symbol()  && OrderMagicNumber() == magic ) 
      if (OrderType() == OP_BUY && StringFind( OrderComment(), "grid")!=-1) 
      OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5, CLR_NONE);
   }
}
   
   
 if(cntsell!=0 && lastpricesell-Bid>multsell*distancePoint*Point) {
 // if(cntsell<14)
 if (!(sumprofit(OP_SELL)>0)){
multsell++;
return;
}
multsell=1;
    for (int i = OrdersTotal(); i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderSymbol() == Symbol()  && OrderMagicNumber() == magic) 
      if (OrderType() == OP_SELL && StringFind( OrderComment(), "grid")!=-1) 
      OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5, CLR_NONE);
   }
 } 
  }
//+------------------------------------------------------------------+

double sumprofit(int op){
double sum =0;
   for (int i = OrdersTotal(); i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderSymbol() == Symbol()  && OrderMagicNumber() == magic && StringFind( OrderComment(), "grid")!=-1) 
      if (OrderType() == op ) sum+=OrderProfit()+OrderCommission()+OrderSwap();

   
   }

return sum;
}

double sumprofitbalancer(int op){
double sum =0;
   for (int i = OrdersTotal(); i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))continue;
      if (OrderSymbol() == Symbol()  && OrderMagicNumber() == magic && StringFind( OrderComment(), "grid")==-1 ) 
      if (OrderType() == op ) sum+=OrderProfit()+OrderCommission()+OrderSwap();

   
   }

return sum;
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar()
{
        static datetime OldTime = 0;

        if(OldTime < Time[0])
        {
                OldTime = Time[0];
                return(true);
        }
        else
        {
                return(false);
        }
}
int signal(){
int s=1;
if (reverse) s=-1;
 int ZigZagFoundCount = 0;
 int ZigZagFoundCountH = 0;
 int ZigZagFoundCountL = 0;
int ZigZagShift = 0;
double ZigZagH[5];
double ZigZagL[5];
string ord="";
while(ZigZagFoundCount < 4)
   {
   double zz= iCustom(NULL, 0, "ZigZag",Depth,Deviation,Backstep, 0, ZigZagShift);
   if(zz == High[ZigZagShift])
      {
      ZigZagH[ZigZagFoundCountH++] =zz ;
      ZigZagFoundCount++;
      ord+="H";
      }
  
  if(zz == Low[ZigZagShift])
      {
      ZigZagL[ZigZagFoundCountL++] =zz ;
      ZigZagFoundCount++;
      ord+="L";
      }
   ZigZagShift++;

   }
      if ((inRange(ZigZagL[0],zdiff)||inRange(ZigZagL[1],zdiff) )&&  ZigZagL[0]<ZigZagL[1]&& (ord=="HLHL"||ord=="HLH")) return -s;
      else
      if ((inRange(ZigZagH[0],zdiff)||inRange(ZigZagH[1],zdiff) )&&ZigZagH[0]>ZigZagH[1]&&(ord=="LHLH" || ord=="LHL"))  return +s;
 //HideTestIndicators(false);
return 0;
}
bool inRange(double p,double diff){
RefreshRates();
if(Bid<p+diff*Point && Bid>p-diff*Point) return true;
return false;

}

      
double getnextlot(int step){
double vol=0.01;
if(step<2)return vol;
   for(int i =2;i<=step;i++){
 vol=MathRound(MathPow((1+ppLot),i-2))/100;
   }
   return vol;
}




int Count(int type)
  {
   int counter =0;
   for(int order = 0; order < OrdersTotal(); order++)
     {
      if(!OrderSelect(order,SELECT_BY_POS,MODE_TRADES))continue;
      if(OrderMagicNumber() == magic && OrderType()==type && StringFind( OrderComment(), "grid")!=-1)
         counter++;
     }
   return counter;
  }
  
  

  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void runbuy(string sym, double lot,string cmt)
  {
   RefreshRates();
   for(int i=0 ; i<3; i++)
     {
     
     double sl=0;
        if (StopLoss>0) sl=NormalizeDouble(MarketInfo(sym,MODE_ASK)- (StopLoss*Point),Digits );
      int ticket=OrderSend(sym,OP_BUY,lot,MarketInfo(sym,MODE_ASK),Slippage,sl,0,cmt,magic,0,Blue);
      if(ticket>0)
        {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
            Print("BUY order opened : ",OrderOpenPrice());
         break;
        }
      else
        {
         Print("Error opening BUY order : ",GetLastError());
        }
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void runsell(string sym, double lot,string cmt)
  {
   RefreshRates();
   for(int i=0 ; i<3; i++)
     {
     double sl=0;
       
        if (StopLoss>0) sl=NormalizeDouble(MarketInfo(sym,MODE_BID)+ (StopLoss*Point),Digits );
      int ticket=OrderSend(sym,OP_SELL,lot,MarketInfo(sym,MODE_BID),Slippage,sl,0,cmt,magic,0,Red);
      if(ticket>0)
        {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
            Print("SELL order opened : ",OrderOpenPrice());
         break;
        }
      else
        {
         Print("Error opening SELL order : ",GetLastError());
        }
     }

  }
//+------------------------------------------------------------------+