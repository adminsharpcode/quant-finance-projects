/*
 * Daily95pips strategy - IBFX Changes Made By PipHunter196
 * http://www.forexfactory.com/showthread.php?t=44246
 * Created by Pr1mer
 */

#property copyright "Wojciech Jarmulski"
#property link "http://www.forexfactory.com/showthread.php?t=44246"

#include <stdlib.mqh>
#include <stderror.mqh>

// Money management
extern double FixedLots = 0.0;   // if > 0.0 fixed lots used
extern double Risk = 0.01;       // per cent of free margin of a single offer

extern int Margin = 5;	// value to add/substract to previous day high/low
extern int StopLoss = 30;
extern int UpdateToBE = 15;	// if 0, no b/e update is made
extern int TakeProfit1 = 15;
extern int TakeProfit2 = 30;
extern int TakeProfit3 = 50;
extern bool UseTrailingStopOnLastOrder = false;
extern int TrailingStop = 20;

extern int DayStartHour = 21;	// 5pm EST in your time zone
extern int LookBackHours = 17;
extern int OrderExpirationHours = 18;
extern bool CloseOrdersNextDay = true;

extern int Slippage = 3;
extern int EAMagicNo = 156909;

bool extremsSet = false;
bool extremsSet2 = false;
double dayHigh = 0.0;
double dayLow = 0.0;
datetime lastOrderTime = 0;

void init()
{
}

int HandleLastError(bool printInfo = true)
{
	int error = GetLastError();
	
	if(error > 0 && printInfo)
		Print("Error #", error, ": ", ErrorDescription(error));
	
	return (error);
}

int OrderSendSafe(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment, int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
{
	int ticket;
	bool cont = true;
	
	int sleepMin = 2;
	int sleepMax = 10;
	MathSrand(TimeLocal());

	while(cont)
	{
		ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
		
		if(ticket < 0)
   		{
			if(HandleLastError() == ERR_TRADE_CONTEXT_BUSY)
			{
				Print("Retrying...");
				int randomSeconds = MathRand() % (sleepMax - sleepMin) + sleepMin;
				Sleep(randomSeconds * 1000);
			}
			else
				cont = false;
		}
		else
			cont = false;
	}
	
	return (ticket);
}

void OrderModifySafe(int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=CLR_NONE)
{
	bool cont = true;
	
	int sleepMin = 2;
	int sleepMax = 10;
	MathSrand(TimeLocal());

	while(cont)
	{	
		bool result = OrderModify(ticket, price, stoploss, takeprofit, expiration, arrow_color);
		
		if(!result)
		{
			if(HandleLastError() == ERR_TRADE_CONTEXT_BUSY)
			{
				Print("Retrying...");
				int randomSeconds = MathRand() % (sleepMax - sleepMin) + sleepMin;
				Sleep(randomSeconds * 1000);
			}
			else
				cont = false;
		}
		else
			cont = false;
	}
}

double CalculateLotSize()
{
	if(FixedLots > 0.0)
		return (FixedLots);

	double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE);
	double lots = AccountFreeMargin() * Risk / (StopLoss * pipValue);
	
	double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
	int digits = 0;
	if(lotStep <= 0.01)
		digits = 2;
	else if(lotStep <= 0.1)
		digits = 1;
	lots = NormalizeDouble(lots, digits);
  	
  	double minLots = MarketInfo(Symbol(), MODE_MINLOT);
  	if(lots < minLots)
  		lots = minLots;
  	
  	double maxLots = MarketInfo(Symbol(), MODE_MAXLOT);
  	if(lots > maxLots)
  		lots = maxLots;
  	
  	return (lots);
}

void CloseOpenPositions()
{
	for(int i = OrdersTotal() - 1; i >= 0; i--)
	{
  		if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
  		{
  			if(!IsThisChartOrder())
  				continue;
  			
 			if(OrderType() == OP_BUY || OrderType() == OP_SELL)
 			{
 				double price = Ask;
				if(OrderType() == OP_BUY)
					price = Bid;
            
				OrderClose(OrderTicket(), OrderLots(), price, Slippage);
 			}
 		}
  	}
}

void SetPositions()
{
	if(CloseOrdersNextDay)
		CloseOpenPositions();

	double lots = CalculateLotSize();
	lastOrderTime = TimeCurrent();

	double price = Ask;
	int operation = OP_BUY;
	if(Ask < dayHigh)
	{
  		operation = OP_BUYSTOP;
  		price = dayHigh + Margin * Point;
	}
	
	double tp3 = 0.0;
	if(!UseTrailingStopOnLastOrder)
		tp3 = price + TakeProfit3 * Point;

	OrderSendSafe(Symbol(), operation, lots, price, Slippage, price - StopLoss * Point, price + TakeProfit1 * Point, NULL, EAMagicNo, TimeCurrent() + D'1970.01.01 1' * OrderExpirationHours, Green);
	OrderSendSafe(Symbol(), operation, lots, price, Slippage, price - StopLoss * Point, price + TakeProfit2 * Point, NULL, EAMagicNo, TimeCurrent() + D'1970.01.01 1' * OrderExpirationHours, Green);
	OrderSendSafe(Symbol(), operation, lots, price, Slippage, price - StopLoss * Point, tp3, NULL, EAMagicNo, TimeCurrent() + D'1970.01.01 1' * OrderExpirationHours, Green);

	price = Bid;
	operation = OP_SELL;
	if(Bid > dayLow)
	{
  		operation = OP_SELLSTOP;
  		price = dayLow - Margin * Point;
	}
	
	tp3 = 0.0;
	if(!UseTrailingStopOnLastOrder)
		tp3 = price - TakeProfit3 * Point;

	OrderSendSafe(Symbol(), operation, lots, price, Slippage, price + StopLoss * Point, price - TakeProfit1 * Point, NULL, EAMagicNo, TimeCurrent() + D'1970.01.01 1' * OrderExpirationHours, Red);
	OrderSendSafe(Symbol(), operation, lots, price, Slippage, price + StopLoss * Point, price - TakeProfit2 * Point, NULL, EAMagicNo, TimeCurrent() + D'1970.01.01 1' * OrderExpirationHours, Red);
	OrderSendSafe(Symbol(), operation, lots, price, Slippage, price + StopLoss * Point, tp3, NULL, EAMagicNo, TimeCurrent() + D'1970.01.01 1' * OrderExpirationHours, Red);
}

void OCOAction()
{
	int openOrders = 0;

	for(int i = 0; i < OrdersTotal(); i++)
	{
  		if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
  		{
     		if( (OrderType() == OP_BUY || OrderType() == OP_SELL) && IsThisChartOrder() && IsLastOrder() )
     		{
        		openOrders++;
     		}
  		}
	}
	
	if(openOrders <= 0)
		return;
	
	for(i = OrdersTotal() - 1; i >= 0; i--)
	{
		if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
  		{
     		if( (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) && IsThisChartOrder() && IsLastOrder() )
     		{
        		OrderDelete(OrderTicket());
     		}
  		}
	}
}

void UpdateBE()
{
	if(UpdateToBE <= 0)
		return;

	for(int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
  		{
  			if(!IsThisChartOrder())
  				continue;
  		
  			if(OrderType() == OP_BUY && OrderOpenPrice() > OrderStopLoss() && Bid - OrderOpenPrice() >= UpdateToBE * Point)
  			{
  				OrderModifySafe(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
  			}
  			else if(OrderType() == OP_SELL && OrderOpenPrice() < OrderStopLoss() && OrderOpenPrice() - Ask >= UpdateToBE * Point)
  			{
  				OrderModifySafe(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
  			}
  		}
	}
}

void UpdateTS()
{
	if(!UseTrailingStopOnLastOrder)
		return;
	
	for(int i = OrdersTotal() - 1; i >= 0; i--)
	{
		if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
  		{
  			if(!IsThisChartOrder())
  				continue;
  		
  			if(OrderType() == OP_BUY && Bid - OrderOpenPrice() >= TakeProfit3 * Point
  				&& NormalizeDouble(Bid - OrderStopLoss(), Digits) > NormalizeDouble(TrailingStop * Point, Digits))
  			{
  				OrderModifySafe(OrderTicket(), OrderOpenPrice(), Bid - TrailingStop * Point, OrderTakeProfit(), 0);
  			}
  			else if(OrderType() == OP_SELL && OrderOpenPrice() - Ask >= TakeProfit3 * Point
  				&& NormalizeDouble(OrderStopLoss() - Ask, Digits) > NormalizeDouble(TrailingStop * Point, Digits))
  			{
  				OrderModifySafe(OrderTicket(), OrderOpenPrice(), Ask + TrailingStop * Point, OrderTakeProfit(), 0);
  			}
  		}
	}
}

bool IsThisChartOrder()
{
	return (OrderMagicNumber() == EAMagicNo && OrderSymbol() == Symbol());
}

bool IsLastOrder()
{
	return (OrderOpenTime() >= lastOrderTime);
}

void start()
{
	if(TakeProfit1 >= TakeProfit2 || TakeProfit2 >= TakeProfit3)
  		return;

	OCOAction();
	UpdateBE();
	UpdateTS();
	
//This Section Added By Me For IBFX -----------------------------------------------------------------------------

   if(DayOfWeek() == 0 && TimeHour(TimeCurrent()) == 22) //Added To Account For IBFX Sunday Open @ 18:00 (EST +4)
   {
    if(extremsSet2 == false)
       {
        dayHigh = High[iHighest(NULL, PERIOD_H1, MODE_HIGH, LookBackHours-1, 1)] + (Ask - Bid);
  		  dayLow = Low[iLowest(NULL, PERIOD_H1, MODE_LOW, LookBackHours-1, 1)];
 	 	  extremsSet2 = true;
  
        SetPositions();
	    }
   }
//--------------------------------------------------------------------------------------------------------------		

	if(TimeHour(TimeCurrent()) == DayStartHour && !extremsSet)
	{
  		dayHigh = High[iHighest(NULL, PERIOD_H1, MODE_HIGH, LookBackHours, 1)] + (Ask - Bid);
  		dayLow = Low[iLowest(NULL, PERIOD_H1, MODE_LOW, LookBackHours, 1)];
 	 	extremsSet = true;
 	 	extremsSet2 = false; // Added By Me
  
  		SetPositions();
	}
	else if(TimeHour(TimeCurrent()) != DayStartHour && extremsSet)
	  	extremsSet = false;
}

