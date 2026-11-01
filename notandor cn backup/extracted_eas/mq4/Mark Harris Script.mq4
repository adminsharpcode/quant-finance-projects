//+------------------------------------------------------------------+
//|                                           Mark Harris Script.mq4 |
//|                                 Copyright © 2011, MethodTraders. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, MethodTraders."
#property link      "http://www.metaquotes.net"
#property show_inputs

extern bool
   
   UseBuyStop     = true,
   UseSellStop    = true;
extern int
   Slippage       = 6,
   TakeProfit     = 0,
   StopLoss       = 0;
extern int
   Levels         = 4,
   Initial_Level_Distance = 5,
   Level_Distance_Increment = 5;
extern double
   Lots           = 0.01,
   AddLots        = 0.01;


datetime TT;
int MagicNumber;        
int MyDigits;
double MyPoint;   
string TicketComment = "Mark Harris Script";  
bool Ready_Trade;   //INPUT EA NAME HERE              
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   if(Digits==5)MyDigits=4;
   else if(Digits==3)MyDigits=2;
   else MyDigits = Digits; 
   if (Point == 0.00001) MyPoint = 0.0001; //6 digits
   else if (Point == 0.001) MyPoint = 0.01; //3 digits (for Yen based pairs)
   else MyPoint = Point; //Normal 
   TT=iTime(Symbol(),0,0);
   Comment("");
   Ready_Trade = true;
//----
   return(0);
  }
  int deinit()
  {
//----
   Comment("");
   //---
   return(0);
  }
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   int ticket = 0;
   while(!IsStopped())
   {  
      if(IsTradeAllowed()==false)
      {
         Alert("Allow Live Trading = false, script removed.");
         break;
      }
      RefreshRates();  
      if(IsExpertEnabled()==false)
      {
           Ready_Trade = true;
           if(subTotalTrade()<1)Comment("Script Stopped. Press Expert Advisor Button to Trade");
           if(subTotalTrade()>0)Comment("Closing Trades...");
           subCloseOrder();
           subDeleteAllPending();
           
      }
      if(IsExpertEnabled()==true)
      {
           Comment("Mark Harris Script running");
           if(Ready_Trade==true && subTotalTrade()<1)
           {
               Comment("Opening Trades...");
               if(UseSellStop==true)PlaceSellPendingOrders(Levels, Initial_Level_Distance, Level_Distance_Increment, Initial_Level_Distance,AddLots);
               if(UseBuyStop==true)PlaceBuyPendingOrders(Levels, Initial_Level_Distance, Level_Distance_Increment, Initial_Level_Distance,AddLots); 
               Ready_Trade = false;
           } 
      }
      Sleep(100);
   } 
     Comment("");
//----
   return(0);
  }
//+------------------------------------------------------------------+
int subTotalTrade()
{
   int
      cnt, 
      total = 0;

   for(cnt=0;cnt<OrdersTotal();cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber) total++;
   }
   return(total);
}

void PlaceBuyPendingOrders(int levels, int level_distance,int increment, int price_distance,double addlots)
{
   double OP = Bid+(price_distance*MyPoint);
   int LV = price_distance;
   double AL = addlots;
   double Lotz = Lots;
   for(int cnt=1;cnt<=levels;cnt++)
   {
       int ticket = 0;
       LV = LV+increment;
       
       ticket = subOpenPendingOrder(OP_BUYSTOP, OP, Lotz, TakeProfit,StopLoss);
       Lotz = Lotz+AL;
       if(ticket<0)cnt=cnt-1;     
       if(ticket>0)OP = OP+(LV*MyPoint);
   }
}
void PlaceSellPendingOrders(int levels, int level_distance, int increment , int price_distance,double addlots)
{
   double OP = Bid-(price_distance*MyPoint);
   int LV = price_distance;
   double AL = addlots;
   double Lotz = Lots;
   for(int cnt=1;cnt<=levels;cnt++)
   {
       int ticket = 0;
       LV = LV+increment;
       
       ticket = subOpenPendingOrder(OP_SELLSTOP, OP, Lotz, TakeProfit , StopLoss);
       Lotz = Lotz+AL;
       if(ticket<0)cnt=cnt-1;     
       if(ticket>0)OP = OP-(LV*MyPoint);
   }
}
int subOpenPendingOrder(int type, double OpenPrice,double Lots ,double takeprofit,double stoploss)
{  
   int
         ticket      = 0,
         err         = 0,
         c           = 0;
         
    double         
         aStopLoss   = 0,
         aTakeProfit = 0,
         aOpenPrice  = 0,
         bStopLoss   = 0,
        // OpenPrice  = 0,
         bTakeProfit = 0;
   OpenPrice = NormalizeDouble(OpenPrice,Digits);
        
   if(takeprofit!=0)
   {
      aTakeProfit = NormalizeDouble(OpenPrice+takeprofit*MyPoint,Digits);
      bTakeProfit = NormalizeDouble(OpenPrice-takeprofit*MyPoint,Digits);
   }
   if(stoploss!=0)
   {
      aStopLoss   = NormalizeDouble(OpenPrice-stoploss*MyPoint,Digits);
      bStopLoss   = NormalizeDouble(OpenPrice+stoploss*MyPoint,Digits);
   }

   if(type==OP_BUYSTOP)
   {
      for(c=0;c<10;c++)
      {
         ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,OpenPrice,6,aStopLoss,aTakeProfit,TicketComment,MagicNumber,0,CLR_NONE);
         err=GetLastError();
         if(err==0)
         { 
            if(ticket>0) break;
         }
         else
         {
            Print("ERROR "+err+": "+error(err));
            if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
            {
               //Sleep(5000);
               continue;
            }
            else //normal error
            {
               if(ticket>0) break;
            }  
            
         }
         if(err==148)return(0);
      }   
   }
   if(type==OP_SELLSTOP)
   {   
      for(c=0;c<10;c++)
      {
         ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,OpenPrice,6,bStopLoss,bTakeProfit,TicketComment,MagicNumber,0,CLR_NONE);
         err=GetLastError();
         if(err==0)
         { 
            if(ticket>0) break;
         }
         else
         {
            Print("ERROR "+err+": "+error(err));
            if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
            {
               //Sleep(5000);
               continue;
            }
            else //normal error
            {
               if(ticket>0) break;
            }  
         }
         if(err==148)return(0);
      }   
   }
   if(type==OP_BUYLIMIT)
   {
      for(c=0;c<10;c++)
      {
         ticket=OrderSend(Symbol(),OP_BUYLIMIT,Lots,OpenPrice,6,aStopLoss,aTakeProfit,TicketComment,MagicNumber,0,Green);
         err=GetLastError();
         if(err==0)
         { 
            if(ticket>0) break;
         }
         else
         {
            Print("ERROR "+err+": "+error(err));
            if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
            {
               Sleep(5000);
               continue;
            }
            else //normal error
            {
               if(ticket>0) break;
            }  
         }
      }   
   }
   if(type==OP_SELLLIMIT)
   {   
      for(c=0;c<10;c++)
      {
         ticket=OrderSend(Symbol(),OP_SELLLIMIT,Lots,OpenPrice,6,bStopLoss,bTakeProfit,TicketComment,MagicNumber,0,Red);
         err=GetLastError();
         if(err==0)
         { 
            if(ticket>0) break;
         }
         else
         {
            Print("ERROR "+err+": "+error(err));
            if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
            {
               Sleep(5000);
               continue;
            }
            else //normal error
            {
               if(ticket>0) break;
            }  
         }
      }   
   }  
   return(ticket);  
}
string error(int ai_0) 
{
   switch (ai_0) {
   case 0:
      return ("No error returned.");
   case 1:
      return ("No error returned, but the result is unknown. ");
   case 2:
      return ("Common error. ");
   case 3:
      return ("Invalid trade parameters. ");
   case 4:
      return ("Trade server is busy. ");
   case 5:
      return ("Old version of the client terminal. ");
   case 6:
      return ("No connection with trade server. ");
   case 7:
      return ("Not enough rights. ");
   case 8:
      return ("Too frequent requests.");
   case 9:
      return ("Malfunctional trade operation. ");
   case 64:
      return ("Account disabled. ");
   case 65:
      return ("Invalid account. ");
   case 128:
      return ("Trade timeout. ");
   case 129:
      return ("Invalid price. ");
   case 130:
      return ("Invalid stops. ");
   case 131:
      return ("Invalid trade volume. ");
   case 132:
      return ("Market is closed. ");
   case 133:
      return ("Trade is disabled. ");
   case 134:
      return ("Not enough money. ");
   case 135:
      return ("Price changed. ");
   case 136:
      return ("Off quotes. ");
   case 137:
      return ("Broker is busy.");
   case 138:
      return ("Requote. ");
   case 139:
      return ("Order is locked. ");
   case 140:
      return ("Long positions only allowed. ");
   case 141:
      return ("Too many requests. ");
   case 145:
      return ("Modification denied because order too close to market. ");
   case 146:
      return ("Trade context is busy. ");
   case 147:
      return ("Expirations are denied by broker. ");
   case 148:
      return ("The amount of open and pending orders has reached the limit set by the broker. ");
   case 4000:
      return ("No error. ");
   case 4001:
      return ("Wrong function pointer. ");
   case 4002:
      return ("Array index is out of range. ");
   case 4003:
      return ("No memory for function call stack. ");
   case 4004:
      return ("Recursive stack overflow. ");
   case 4005:
      return ("Not enough stack for parameter. ");
   case 4006:
      return ("No memory for parameter string. ");
   case 4007:
      return ("No memory for temp string. ");
   case 4008:
      return ("Not initialized string. ");
   case 4009:
      return ("Not initialized string in array. ");
   case 4010:
      return ("No memory for array string. ");
   case 4011:
      return ("Too long string. ");
   case 4012:
      return ("Remainder from zero divide. ");
   case 4013:
      return ("Zero divide. ");
   case 4014:
      return ("Unknown command. ");
   case 4015:
      return ("Wrong jump (never generated error). ");
   case 4016:
      return ("Not initialized array. ");
   case 4017:
      return ("DLL calls are not allowed. ");
   case 4018:
      return ("Cannot load library. ");
   case 4019:
      return ("Cannot call function. ");
   case 4020:
      return ("Expert function calls are not allowed. ");
   case 4021:
      return ("Not enough memory for temp string returned from function. ");
   case 4022:
      return ("System is busy (never generated error). ");
   case 4050:
      return ("Invalid function parameters count. ");
   case 4051:
      return ("Invalid function parameter value. ");
   case 4052:
      return ("String function internal error. ");
   case 4053:
      return ("Some array error. ");
   case 4054:
      return ("Incorrect series array using. ");
   case 4055:
      return ("Custom indicator error. ");
   case 4056:
      return ("Arrays are incompatible. ");
   case 4057:
      return ("Global variables processing error. ");
   case 4058:
      return ("Global variable not found. ");
   case 4059:
      return ("Function is not allowed in testing mode. ");
   case 4060:
      return ("Function is not confirmed. ");
   case 4061:
      return ("Send mail error. ");
   case 4062:
      return ("String parameter expected. ");
   case 4063:
      return ("Integer parameter expected. ");
   case 4064:
      return ("Double parameter expected. ");
   case 4065:
      return ("Array as parameter expected. ");
   case 4066:
      return ("Requested history data in updating state. ");
   case 4067:
      return ("Some error in trading function. ");
   case 4099:
      return ("End of file. ");
   case 4100:
      return ("Some file error.");
   case 4101:
      return ("Wrong file name. ");
   case 4102:
      return ("Too many opened files. ");
   case 4103:
      return ("Cannot open file. ");
   case 4104:
      return ("Incompatible access to a file. ");
   case 4105:
      return ("No order selected. ");
   case 4106:
      return ("Unknown symbol. ");
   case 4107:
      return ("Invalid price. ");
   case 4108:
      return ("Invalid ticket. ");
   case 4109:
      return ("Trade is not allowed. ");
   case 4110:
      return ("Longs are not allowed. ");
   case 4111:
      return ("Shorts are not allowed. ");
   case 4200:
      return ("Object exists already. ");
   case 4201:
      return ("Unknown object property. ");
   case 4202:
      return ("Object does not exist. ");
   case 4203:
      return ("Unknown object type. ");
   case 4204:
      return ("No object name. ");
   case 4205:
      return ("Object coordinates error. ");
   case 4206:
      return ("No specified subwindow. ");
   case 4207:
      return ("Some error in object function. ");
   }
   return ("Unknown error:" + ai_0);
}
void subCloseOrder()//CLOSES ALL OPEN ORDERS
{
   int
         cnt, 
         total       = 0,
         ticket      = 0,
         err         = 0,
         c           = 0;

   int NumberOfTries = 10;
   total = OrdersTotal();
   for(cnt=total-1;cnt>=0;cnt--)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber)
      {
         switch(OrderType())
         {
            case OP_BUY      :
               for(c=0;c<NumberOfTries;c++)
               {
                  RefreshRates();
                  ticket=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Violet);
                  err=GetLastError();
                  if(err==0)
                  { 
                     if(ticket>0) break;
                  }
                  else
                  {
                     Print("CLOSE ERROR "+err+": "+error(err));
                     if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
                     {
                        Sleep(5000);
                        continue;
                     }
                     else //normal error
                     {
                        if(ticket>0) break;
                     }  
                  }
               }   
               continue;
               
            case OP_SELL     :
               for(c=0;c<NumberOfTries;c++)
               {
                  RefreshRates();
                  ticket=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Violet);
                  err=GetLastError();
                  if(err==0)
                  { 
                     if(ticket>0) break;
                  }
                  else
                  {
                     Print("CLOSE ERROR "+err+": "+error(err));
                     if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
                     {
                        Sleep(5000);
                        continue;
                     }
                     else //normal error
                     {
                        if(ticket>0) break;
                     }  
                  }
               }   
               continue;
         }
      }
   }      
}
void subDeleteAllPending()//DELETES ALL PENDING ORDERS
{  
   int
       
         cnt, 
         total       = 0,
         ticket      = 0,
         err         = 0,
         c           = 0;

   total = OrdersTotal();
   for(cnt=total-1;cnt>=0;cnt--)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()>OP_SELL && OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber)
      {
          OrderDelete(OrderTicket());
      }
   }      
}