//+------------------------------------------------------------------+
//|                                                        Blank.mq4 |
//|                       Copyright 2016, INALGORITMA Software Corp. |
//|                                      https://www.inalgoritma.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, INALGORITMA Software Corp."
#property link      "https://www.inalgoritma.com"
#property version   "1.00"

#include      <stdlib.mqh>

extern int     StopLoss        = 50;
extern double  Lots            = 1.0;
extern int     MagicNumber     = 9723;
extern string  SettingIndi     = "=====";
extern int     MoveShift       = 12;
extern int     MAPeriod        = 9;
extern int     OsMA            = 3;
extern int     Dist2           = 20;
extern double  Std             = 0.4;
extern int     BPeriod         = 20;

       int     StartHour       = 0;
       int     EndHour         = 24;

bool           ShowInfo        = true;
int            Corner          = 1;              
int            PT              = 1,
               DIGIT,SlipPage;
double         POINT;  
int            TakeProfit      = 0;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   SlipPage = 4;
   AutoDigit(); 
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   DelObject();
   Comment(""); 
	return(0);
}
//+------------------------------------------------------------------+
//| Expert start function                                   |
//+------------------------------------------------------------------+
int start()
{
   if(IsTrade())
   {
      SetupTrade();
      DisplayShow();
	}
	
   return(0);
}
//========================================

void SetupTrade()
{
   int x = 2147483647;
   
   double value_2 = iCustom(Symbol(),Period(),"ma_bbands",MoveShift,MAPeriod,OsMA,Dist2,Std,BPeriod,2,1);
   double value_3 = iCustom(Symbol(),Period(),"ma_bbands",MoveShift,MAPeriod,OsMA,Dist2,Std,BPeriod,3,1);
   
   Comment(value_2,"==",value_3);
   
   bool buy1   = value_2 > 0;
   bool sell1  = value_3 > 0;
   
   bool closebuy  = sell1;
   bool closesell = buy1;
   
   datetime candleTime   = iTime(Symbol(),Period(),0); static datetime timeTrade;
   bool     trade        = Hour() >= StartHour && Hour() <= EndHour;
   
   if(closebuy)  CloseOrder(OP_BUY);
   if(closesell) CloseOrder(OP_SELL);
   
   if(trade && TotalOrder()==0)
   {  
      if(buy1 && IsOrder("buy#1") && timeTrade != candleTime)  
      {
         Order(OP_BUY,"buy#1");
         timeTrade = candleTime;
      }   
      if(sell1 && IsOrder("sell#1") && timeTrade != candleTime) 
      {
         Order(OP_SELL,"sell#1");
         timeTrade = candleTime;
      }
   }   
}

//=======================================

bool IsOrder(string comment)
{
   bool isOrder = true;
   
   if(OrderSelect(OrdersTotal()-1,SELECT_BY_POS,MODE_TRADES))
   {
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {  
         if(StringFind(OrderComment(),comment) != -1) isOrder = false;
         
         if(OrderType() == OP_BUY)
         {
            if(OrderStopLoss() > OrderOpenPrice()) isOrder = false;
         }

         if(OrderType() == OP_SELL)
         {
            if(OrderStopLoss() < OrderOpenPrice() && OrderStopLoss() > 0) isOrder = false;
         }
      }
   }
   
   return(isOrder);
}

double TotalPips()
{
   double totalPip = 0, pip = 0;
   string date     = TimeToString(TimeCurrent(),TIME_DATE);
   
   for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(StringFind(TimeToString(OrderCloseTime(),TIME_DATE),date) != -1)
            {
               if(OrderType() == OP_BUY)
               {
                  pip = (OrderClosePrice()-OrderOpenPrice())/POINT;
                  totalPip += pip;
               }

               if(OrderType() == OP_SELL)
               {
                  pip = (OrderOpenPrice()-OrderClosePrice())/POINT;
                  totalPip += pip;
               }
            }
         }
      }
   }
   
   return(totalPip);
}


int TotalOrder(int ordertype = -1)
{
   int Order = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(ordertype == -1) 
               Order++;
            else if(ordertype == OrderType()) 
               Order++;
         }
      }
   }
   
   return(Order);
}

double SetupLot()
{
   double lot    = 0, firstLot = 0,
          MinLot = MarketInfo(Symbol(),MODE_MINLOT),
          MaxLot = MarketInfo(Symbol(),MODE_MAXLOT); 
      
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            lot = MathMax(lot,OrderLots());
         }
      }
   }
   
   lot = Lots;

   if(MinLot == 0.01)
      firstLot = NormalizeDouble(firstLot,2);  
   else
      firstLot = NormalizeDouble(firstLot,1);
   
   if(lot == 0)
      lot = Lots;
      
   if(lot < MinLot) lot = MinLot;
   if(lot > MaxLot) lot = MaxLot;   
   
   if(MinLot == 0.01)
      lot = NormalizeDouble(lot,2);  
   else
      lot = NormalizeDouble(lot,1);
      
   return(lot);
}

double AskPrice(string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   return(MarketInfo(symbol,MODE_ASK));
}

double BidPrice(string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   return(MarketInfo(symbol,MODE_BID));
}

int StopLevel(string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   return(MarketInfo(symbol,MODE_STOPLEVEL));
}

string OrderCmd(int ordertype)
{
   string label;

   switch(ordertype)
   {
      case 0: label = "Buy";        break;
      case 1: label = "Sell";       break;
      case 2: label = "Buy Limit";  break;
      case 3: label = "Sell Limit"; break;
      case 4: label = "Buy Stop";   break;
      case 5: label = "Sell Stop";  break;
   }

   return(label);
}

int Order(int ordertype, string comment)
{
   int             ticket;
   double          lot         = SetupLot(),price, sl = 0, tp = 0;
   
   if(ordertype == OP_BUY)  
   {
      price = AskPrice(); 
      if(StopLoss > 0)   sl = NormalizeDouble(price-(StopLoss*POINT),DIGIT);
      if(TakeProfit > 0) tp = NormalizeDouble(price+(TakeProfit*POINT),DIGIT);      
   }
   
   if(ordertype == OP_SELL) 
   {
      price = BidPrice(); 
      if(StopLoss > 0)   sl = NormalizeDouble(price+(StopLoss*POINT),DIGIT);
      if(TakeProfit > 0) tp = NormalizeDouble(price-(TakeProfit*POINT),DIGIT);      
   }
              
   ticket = OrderSend(Symbol(),ordertype,lot,price,SlipPage,sl,tp,comment,MagicNumber,0);
   if(ticket == -1) ShowError("Order " + OrderCmd(ordertype));
   
   return(ticket);
}

void CloseOrder(int ordertype = -1)
{   
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(ordertype == -1)
            {
               if(OrderType() == OP_BUY) 
               {     
                  if(!OrderClose(OrderTicket(),OrderLots(),BidPrice(OrderSymbol()),SlipPage,Blue)) ShowError("Close " + OrderCmd(OrderType())); 
               }
               else if(OrderType() == OP_SELL)
               {      
                  if(!OrderClose(OrderTicket(),OrderLots(),AskPrice(OrderSymbol()),SlipPage,Red)) ShowError("Close " + OrderCmd(OrderType()));
               } 
               else
               {
                  if(!OrderDelete(OrderTicket())) ShowError("Delete Pending Order " + OrderCmd(OrderType()));
               }
            }
            else
            {
               if(OrderType() == ordertype)
               {
                  if(ordertype == OP_BUY)
                  {   
                     if(!OrderClose(OrderTicket(),OrderLots(),BidPrice(OrderSymbol()),SlipPage,Blue)) ShowError("Close " + OrderCmd(OrderType()));
                  } 
                  else if(ordertype == OP_SELL)   
                  {
                     if(!OrderClose(OrderTicket(),OrderLots(),AskPrice(OrderSymbol()),SlipPage,Red)) ShowError("Close " + OrderCmd(OrderType()));
                  } 
                  else
                  {
                     if(!OrderDelete(OrderTicket())) ShowError("Delete Pending Order " + OrderCmd(OrderType()));
                  }
               }
            }
         }
      }
   }
}

double TotalProfit()
{  
   if(TotalOrder() > 0)
   {
      double profit = 0;
    
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) profit += OrderProfit();
         }
      }
   }
   
   return(profit);
}

void ShowError(string label)
{
	string Error;
	int    error = GetLastError();
	
	Error        = StringConcatenate("Terminal: ",TerminalName(),"\n",
	                                  label," error ",error,"\n",
	                                  ErrorDescription(error));
	if(error > 2) 
	{
	  if(IsTesting())
	     Comment(Error);
	  else   
	     Alert(Error);
   }
}
        
void AutoDigit()
{
   POINT = MarketInfo(Symbol(),MODE_POINT);
   DIGIT = MarketInfo(Symbol(),MODE_DIGITS);
   
   if (DIGIT == 3 || DIGIT == 5)
   {
      PT              = 10;
      StopLoss       *= 10;
      TakeProfit     *= 10;
      SlipPage       *= 10;
   }
}

bool IsTrade()
{
   bool trade = true;
   
   if(!IsTesting())
   {
      if(!IsTradeAllowed()) 
      {
         Alert("Allow live trading is disable, press F7, \nselect Common tab, check Allow live trading");
         trade = false;
      }
   
      if(!IsExpertEnabled()) 
      {
         Alert("Expert Advisor is disable, click AutoTrading button to activate it ");
         trade = false;
      }   
   }
   
   return(trade);
}

void DelObject(string objectName = "")
{
   for(int i = ObjectsTotal()-1; i >= 0; i--)
	{
	   if(StringFind(ObjectName(i),WindowExpertName()) != -1)
	   {
	   	if(objectName == "")
	  			ObjectDelete(ObjectName(i));
	   	else
	   		if(StringFind(ObjectName(i),objectName) != -1) ObjectDelete(ObjectName(i));
		}
	}
}

void DisplayShow()
{
   if(ShowInfo)
   {
      DelObject();     
      DisplayInfo("Balance",StringConcatenate("",DoubleToString(AccountBalance(),2)));
      if(AccountMargin() != 0) DisplayInfo("Equity",StringConcatenate("",DoubleToString(AccountEquity(),2)));
      DisplayInfo("Spread",StringConcatenate("",MarketInfo(Symbol(),MODE_SPREAD)/PT));
      if(AccountMargin() != 0)
      {
         DisplayInfo ("Margin",StringConcatenate(DoubleToString((AccountEquity()/AccountMargin())*100,2),"%"));
		   DisplayInfo("Profit",StringConcatenate("",DoubleToString(TotalProfit(),2)));
      }
      
      DisplayInfo("TotalPips",StringConcatenate("",DoubleToString(TotalPips()/PT,1)));
   }
}  

void DisplayInfo(string name, string value)
{
   color      LabelColor      = White,
              BackgroundColor = DarkGreen;
   string     Font            = "Arial", name1,name2,name3;
   int        FontSize        = 9,
              Space           = 15, 
              X1,X2,X3;
   static int Y;
           
   if(name == "Balance") Y = 30;
   else                  Y += Space;
   if(Corner % 2 == 0) {X1 = 10; X2 = 70; X3 = 80;}
   else                {X1 = 90; X2 = 80; X3 = 10;}
             
   if(name != "")
   {        
      name1 = StringConcatenate(WindowExpertName(),name);
      name2 = StringConcatenate(WindowExpertName(),name,":");
      name3 = StringConcatenate(WindowExpertName(),name,"Value");
      
      ObjectDelete(name3);

      ObjectCreate(name1,OBJ_LABEL,0,0,0);           
      ObjectCreate(name2,OBJ_LABEL,0,0,0);      
      ObjectCreate(name3,OBJ_LABEL,0,0,0);
            
      ObjectSetText(name1,name,FontSize,Font, LabelColor); 
      ObjectSetText(name2,":",FontSize,Font,LabelColor); 
      ObjectSetText(name3,value,FontSize,Font,LabelColor);
            
      ObjectSet(name1,OBJPROP_CORNER,Corner);      
      ObjectSet(name2,OBJPROP_CORNER,Corner); 
      ObjectSet(name3,OBJPROP_CORNER,Corner);
            
      ObjectSet(name1,OBJPROP_XDISTANCE, X1);       
      ObjectSet(name2,OBJPROP_XDISTANCE, X2);  
      ObjectSet(name3,OBJPROP_XDISTANCE, X3);
            
      ObjectSet(name1,OBJPROP_YDISTANCE,Y);        
      ObjectSet(name2,OBJPROP_YDISTANCE,Y);   
      ObjectSet(name3,OBJPROP_YDISTANCE,Y);
   }
}