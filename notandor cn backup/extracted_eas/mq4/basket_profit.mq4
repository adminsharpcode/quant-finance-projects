#property copyright "Copyright © 2010, 1000 pips club"
#property link      "Aiman CG"
#include <stdlib.mqh>
#define id "BP_"

//---- input parameters
extern double  Basket_Target      = 0; //<<------------ set your target here or 0 to disable 
extern double  Basket_StopLoss    = 0; //<<------------ set your stoploss here or 0 to disable

int slippage=5;

bool CloseAll;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() 
{
   deinit();   
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   for(int i=ObjectsTotal();i>=0;i--) 
   {
      if (StringSubstr(ObjectName(i),0,3)==id) 
      ObjectDelete(ObjectName(i));
   }
   return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
      RefreshRates();
      if(CloseAll)
      {
         TutupSemua();
         if(OrdersTotal()==0)
         {
            ObjectDelete(id+"Closing");
            CloseAll=false;
         }
      }
      
      //- Target
      if(Basket_Target>0 && TotalProfit()>=Basket_Target) CloseAll=true;

      //- StopLoss
      if(Basket_StopLoss>0 && TotalProfit()<(0-Basket_StopLoss)) CloseAll=true;

      displayStatus ();
      WindowRedraw();

      return(0);
  }
//+------------------------------------------------------------------+ 
double TotalProfit ()
{
   double totalProfit=0;
   for(int i=0;i<OrdersTotal();i++) 
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<2)
      totalProfit+=OrderProfit()+OrderSwap()+OrderCommission();
   }
   return (totalProfit);
}
//+------------------------------------------------------------------+ 
void TutupSemua ()
{
   while (OrdersTotal()>0)
   {
      int type=0, err=1;
      for(int i=0;i<OrdersTotal();i++)
      {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         type   = OrderType();
         drawLabel (id+"Closing", "Closing "+OrderSymbol()+"...", 20, "Monotype Corsiva", MediumVioletRed, 3, 10, 10);
         WindowRedraw();
         switch(type)
         {
            case OP_BUY       : OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),0,CLR_NONE);break;
            case OP_SELL      : OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),0,CLR_NONE);break;
            case OP_BUYLIMIT  :
            case OP_BUYSTOP   :
            case OP_SELLLIMIT :
            case OP_SELLSTOP  : OrderDelete(OrderTicket());break;
                      default : break;
         }
         err=GetLastError();
         Comment ("Closing / Deleting order = ", ErrorDescription(err));
         Sleep(50);
      }
   }
   Comment ("");
}

//+------------------------------------------------------------------+
void displayStatus ()
{
   string fontstyle="Tempus Sans ITC";
   string statustext;
   color textcolor;   
   int ydist=10;
   

   if (Basket_StopLoss>0)
   {

      statustext="Basket StopLoss: -"+DoubleToStr(Basket_StopLoss,2);
      drawLabel (id+"StopLosspips", statustext, 9, fontstyle, Yellow, 2, 10, ydist);
      ydist=ydist+14;
   }
   
   if (Basket_Target>0) 
   {
      statustext="Basket Target: "+DoubleToStr(Basket_Target,2);
      drawLabel (id+"Targetpips", statustext, 9, fontstyle, Yellow, 2, 10, ydist);
      ydist=ydist+14;
   }      

   drawLabel (id+"TotalProfit", "Profit: "+DoubleToStr(TotalProfit(),2), 15, fontstyle, Yellow, 2, 10, ydist);
}
//+------------------------------------------------------------------+
void drawLabel (string Ln, string Lt, int th, string ts, color Lc, int cr, int xp, int yp)
{
   ObjectCreate(Ln, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(Ln, Lt, th, ts, Lc);
   ObjectSet(Ln, OBJPROP_CORNER, cr);
   ObjectSet(Ln, OBJPROP_XDISTANCE, xp);
   ObjectSet(Ln, OBJPROP_YDISTANCE, yp);  
}

