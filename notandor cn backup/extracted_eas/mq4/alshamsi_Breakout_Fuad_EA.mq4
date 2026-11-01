//+------------------------------------------------------------------+
//|                                    alshamsi_Breakout_Fuad_EA.mq4 |
//|                                                         alshamsi |
//|                                            fx_mt4_ea@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "alshamsi"
#property link      "fx_mt4_ea@hotmail.com"

        
 extern string A=" Breakout Settings";
 extern int StartHour=1;
 extern int EndHour=9;   
 extern string  MM_Parameters = "Money Management";                                          
 extern bool  UseMoneyManagement = false;                                                
 extern int  RiskPercent = 10; 
 extern double Lots=1;
 extern int Lot_Digits=1;
 extern string B="Order Management";
 extern bool ECN_Broker=true;
 extern bool  UseSound = false;
 extern int AddPips=0;
 extern int  OrdersNumber = 1;
 extern int TakeProfit=20;
 extern int StopLoss=20;
 extern int TrailingStop=0;
 extern int TrailingStep=0;
 extern int BreakEven=0;
 extern int movestopto=1;
 extern int MagicNumber=55;                             
 double SL,TP,SLecn,TPecn,point;
 int Q,i,ticket ;
 datetime Time0;

 int digits;
  int init()
{
  if(MarketInfo(Symbol(),MODE_MINLOT)<0.1)Lot_Digits=2;
 else Lot_Digits=1;
   if(Digits==5||Digits==3)Q=10;
   else Q=1;
    if(Digits<4)
   {
      point=0.01;
      digits=2;
   }
   else
   {
      point=0.0001;
      digits=4;
   }
return(0);
}

 //+------------------------------------------------------------------+
 //| FUNCTION DEFINITIONS    deinitialization function                |
 //+------------------------------------------------------------------+

 void deinit()
  {
    Comment("");
  }


 int orderscnt(int type){
 int cnt=0;
   for(int i =0;i<OrdersTotal();i++){
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
       if(OrderSymbol()==Symbol()&&OrderType()==type && MagicNumber==OrderMagicNumber()){
         cnt++;
       }
     }
   }
    return(cnt);
  }
 //+------------------------------------------------------------------+
 //| FUNCTION DEFINITIONS   Start function                            |
 //+------------------------------------------------------------------+

 int start()
   {
    ObjectCreate("oop", OBJ_LABEL, 0, 0, 0);
    ObjectSetText("oop", "Programmed by alshamsi" + ", http://www.1234ex.com", 12, "Verdana", White);
    ObjectSet("oop", OBJPROP_CORNER, 3);
    ObjectSet("oop", OBJPROP_XDISTANCE, 5);
    ObjectSet("oop", OBJPROP_YDISTANCE, 5);   
    if(TrailingStop>0)MoveTrailingStop();
    if(BreakEven>0)MoveBreakEven(); 
    if(UseMoneyManagement)Lots=LotManage();
    if(StartHour>EndHour)
    {
    datetime TimeStart=StrToTime(TimeToStr(iTime(Symbol(),1440,1),TIME_DATE)+" "+StartHour);
    int BarStart=iBarShift(Symbol(),0,TimeStart,false);
    }
    else 
    {
    TimeStart=StrToTime(TimeToStr(TimeCurrent(),TIME_DATE)+" "+StartHour);
    BarStart=iBarShift(Symbol(),0,TimeStart,false);    
    } 
   datetime TimeEnd=StrToTime(TimeToStr(TimeCurrent(),TIME_DATE)+" "+EndHour);
   int BarEnd=iBarShift(Symbol(),0,TimeEnd,false);   
   double Buy=High[iHighest(Symbol(),0,MODE_HIGH,BarStart-BarEnd,BarEnd)];
   double Sell=Low[iLowest(Symbol(),0,MODE_LOW,BarStart-BarEnd,BarEnd)]; 
         
   if(Time0!=Time[0]&&Open[0]<Buy&&Close[0]>Buy+AddPips*point&&orderscnt(OP_BUY)<1){
   if(StopLoss==0){SL=0;}else{SL=Ask-StopLoss*point;}
   if(TakeProfit==0){TP=0;}else{TP=Ask+TakeProfit*point;}
   if(ECN_Broker){SLecn=SL;TPecn=TP;SL=0;TP=0;}
   for( i=1;i<=OrdersNumber ;i++){ 
   ticket= OrderSend(Symbol(),OP_BUY,Lots,NormalizeDouble(Bid,Digits),3*Q,SL,TP,"ALSHAMSI EA",MagicNumber,0,Blue);
   if(ECN_Broker&&SLecn!=0||TPecn!=0)OrderModify(ticket,OrderOpenPrice(),SLecn,TPecn,0);
   Time0=Time[0];        
   if (UseSound)PlaySound("Alert.wav");
   }
   }    
   if(Time0!=Time[0]&&Open[0]>Sell&&Close[0]<Sell-AddPips*point&&orderscnt(OP_SELL)<1){
   if(StopLoss==0){SL=0;}else{SL=Bid+StopLoss*point;}
   if(TakeProfit==0){TP=0;}else{TP=Bid-TakeProfit*point;}
   if(ECN_Broker){SLecn=SL;TPecn=TP;SL=0;TP=0;}
   for( i=1;i<=OrdersNumber ;i++){ 
   ticket=OrderSend(Symbol(),OP_SELL,Lots,NormalizeDouble(Ask,Digits),3*Q,SL,TP,"ALSHAMSI EA",MagicNumber,0,Red); 
   if(ECN_Broker&&SLecn!=0||TPecn!=0)OrderModify(ticket,OrderOpenPrice(),SLecn,TPecn,0);
   Time0=Time[0];
   if (UseSound)PlaySound("Alert.wav");
   }
   }
   }
 //+------------------------------------------------------------------+
 //| FUNCTION DEFINITIONS   TrailingStop                              |
 //+------------------------------------------------------------------+
    
    //|---------trailing stop

void MoveTrailingStop()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
      {
         if(OrderType()==OP_BUY)
         {
            if(TrailingStop>0&&NormalizeDouble(Ask-TrailingStep*point,digits)>NormalizeDouble(OrderOpenPrice()+TrailingStop*point,digits))  
            {                 
               if((NormalizeDouble(OrderStopLoss(),digits)<NormalizeDouble(Bid-TrailingStop*point,digits))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-TrailingStop*point,digits),OrderTakeProfit(),0,Blue);
               }
            }
         }
         else 
         {
            if(TrailingStop>0&&NormalizeDouble(Bid+TrailingStep*point,digits)<NormalizeDouble(OrderOpenPrice()-TrailingStop*point,digits))  
            {                 
               if((NormalizeDouble(OrderStopLoss(),digits)>(NormalizeDouble(Ask+TrailingStop*point,digits)))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+TrailingStop*point,digits),OrderTakeProfit(),0,Red);
               }
            }
         }
      }
   }
}




//|---------break even

void MoveBreakEven()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
      {
         if(OrderType()==OP_BUY)
         {
            if(BreakEven>0)
            {
               if(NormalizeDouble((Bid-OrderOpenPrice()),digits)>BreakEven*point)
               {
                  if(NormalizeDouble((OrderStopLoss()-OrderOpenPrice()),digits)<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()+movestopto*point,digits),OrderTakeProfit(),0,Blue);
                  }
               }
            }
         }
         else
         {
            if(BreakEven>0)
            {
               if(NormalizeDouble((OrderOpenPrice()-Ask),digits)>BreakEven*point)
               {
                  if(NormalizeDouble((OrderOpenPrice()-OrderStopLoss()),digits)<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()-movestopto*point,digits),OrderTakeProfit(),0,Red);
                  }
               }
            }
         }
      }
   }
}

 //+------------------------------------------------------------------+
 //| FUNCTION DEFINITIONS   Money Managment                           |
 //+------------------------------------------------------------------+ 

 double LotManage()
  {
       double lot = MathCeil(AccountBalance() *  RiskPercent / 1000) / 100; 
	  
	  if(lot<MarketInfo(Symbol(),MODE_MINLOT))lot=MarketInfo(Symbol(),MODE_MINLOT);
	  if(lot>MarketInfo(Symbol(),MODE_MAXLOT))lot=MarketInfo(Symbol(),MODE_MAXLOT);
	  
	   
	   return (NormalizeDouble(lot,Lot_Digits));
  }

 //+---------------------------------------------------------------------------------+
 
   