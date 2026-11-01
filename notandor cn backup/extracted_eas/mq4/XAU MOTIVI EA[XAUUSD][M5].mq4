//+------------------------------------------------------------------+
//|                                                XAU MOTIVI EA.mq4 |
//+------------------------------------------------------------------+
#property copyright "tg"
#property description "XAU MOTIVI EA m1/m5"
#property version   "1.30"
#property strict

//--- Input Parameters 
input int      TrailUse   = 25;     // TRAIL use (Points)
input double   LotUse     = 0.01;   // LOT use

//--- Strategy Parameters
input int      FastMAPeriod = 10;   // Fast MA Period
input int      SlowMAPeriod = 20;   // Slow MA Period
input int      MagicNumber  = 123456;// Magic Number for order identification
input int      Slippage     = 3;     // Allowed Slippage (Points)

//--- Global Variables
datetime lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   lastBarTime = 0;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Manage existing trades using the Trailing Stop logic
   ApplyTrailingStop();

   // 2. Check for a new bar to avoid multiple signals on a single bar
   if(lastBarTime == Time[0]) return;

   // Count open orders managed by this EA
   int totalBuyOrders = 0;
   int totalSellOrders = 0;
   CountOrders(totalBuyOrders, totalSellOrders);

   // 3. Evaluate Entry Signals
   // Fast MA (EMA 10) on previous closed bar
   double fastCurrent  = iMA(Symbol(), 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double fastPrevious = iMA(Symbol(), 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);

   // Slow MA (EMA 20) on previous closed bar
   double slowCurrent  = iMA(Symbol(), 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slowPrevious = iMA(Symbol(), 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);

   // Buy Signal: Fast MA crosses above Slow MA
   if(fastPrevious <= slowPrevious && fastCurrent > slowCurrent)
   {
      if(totalBuyOrders == 0)
      {
         // Close opposing Sell positions if any exist
         CloseSellPositions();
         
         // Open Buy Order
         int ticket = OrderSend(Symbol(), OP_BUY, LotUse, Ask, Slippage, 0, 0, "Motive Buy", MagicNumber, 0, clrGreen);
         if(ticket > 0)
         {
            lastBarTime = Time[0];
         }
      }
   }
   // Sell Signal: Fast MA crosses below Slow MA
   else if(fastPrevious >= slowPrevious && fastCurrent < slowCurrent)
   {
      if(totalSellOrders == 0)
      {
         // Close opposing Buy positions if any exist
         CloseBuyPositions();
         
         // Open Sell Order
         int ticket = OrderSend(Symbol(), OP_SELL, LotUse, Bid, Slippage, 0, 0, "Motive Sell", MagicNumber, 0, clrRed);
         if(ticket > 0)
         {
            lastBarTime = Time[0];
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing Stop Logic                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
   if(TrailUse <= 0) return;

   double minStop = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   double trailDist = TrailUse * Point;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY)
            {
               // Check if trade is in enough profit to start trailing
               if(Bid - OrderOpenPrice() > trailDist)
               {
                  double newSL = NormalizeDouble(Bid - trailDist, Digits);
                  
                  // Modify only if the new Stop Loss is higher than the current SL (or if no SL is set)
                  if(OrderStopLoss() < newSL - Point || OrderStopLoss() == 0)
                  {
                     // Ensure stop-level limits are respected
                     if(newSL > Bid - minStop) newSL = Bid - minStop;
                     
                     if(OrderStopLoss() < newSL)
                     {
                        bool res = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrGreen);
                     }
                  }
               }
            }
            else if(OrderType() == OP_SELL)
            {
               // Check if trade is in enough profit to start trailing
               if(OrderOpenPrice() - Ask > trailDist)
               {
                  double newSL = NormalizeDouble(Ask + trailDist, Digits);
                  
                  // Modify only if the new Stop Loss is lower than the current SL (or if no SL is set)
                  if(OrderStopLoss() > newSL + Point || OrderStopLoss() == 0)
                  {
                     // Ensure stop-level limits are respected
                     if(newSL < Ask + minStop) newSL = Ask + minStop;
                     
                     if(OrderStopLoss() > newSL || OrderStopLoss() == 0)
                     {
                        bool res = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed);
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Count current active trades managed by the EA                     |
//+------------------------------------------------------------------+
void CountOrders(int &buyCount, int &sellCount)
{
   buyCount = 0;
   sellCount = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY)  buyCount++;
            if(OrderType() == OP_SELL) sellCount++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close all active Buy positions                                   |
//+------------------------------------------------------------------+
void CloseBuyPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY)
         {
            bool res = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrOrange);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close all active Sell positions                                  |
//+------------------------------------------------------------------+
void CloseSellPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL)
         {
            bool res = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrOrange);
         }
      }
   }
}


/*bool __disabled; // whether or not the block is disabled

		string __block_user_number;
        int __block_number;
		int __block_waiting;
		int __parent_number;
		int __inbound_blocks[];
		int __outbound_blocks[];

		void __addInboundBlock(int id = 0) {
			int size = ArraySize(__inbound_blocks);
			for (int i = 0; i < size; i++) {
				if (__inbound_blocks[i] == id) {
					return;
				}
			}
			ArrayResize(__inbound_blocks, size + 1);
			__inbound_blocks[size] = id;
		}

		void BlockCalls() {
			__disabled          = false;
			__block_user_number = "";
			__block_number      = 0;
			__block_waiting     = 0;
			__parent_number     = 0;
		}

		/**
		   Announce this block to the list of inbound connections of all the blocks to which this block is connected to
		   
		void __announceThisBlock()
		{
		   // add the current block number to the list of inbound blocks
		   // for each outbound block that is provided
			for (int i = 0; i < ArraySize(__outbound_blocks); i++)
			{
				int block = __outbound_blocks[i]; // outbound block number
				int size  = ArraySize(_blocks_[block].__inbound_blocks); // the size of its inbound list

				// skip if the current block was already added
				for (int j = 0; j < size; j++) {
					if (_blocks_[block].__inbound_blocks[j] == __block_number)
					{
						return;
					}
				}

				// add the current block number to the list of inbound blocks of the other block
				ArrayResize(_blocks_[block].__inbound_blocks, size + 1);
				_blocks_[block].__inbound_blocks[size] = __block_number;
			}
		}

		// this is here, because it is used in the "run" function
		virtual void _execute_() = 0;

		/**
			In the derived class this method should be used to set dynamic parameters or other stuff before the main execute.
			This method is automatically called within the main "run" method below, before the execution of the main class.
			
		virtual void _beforeExecute_() {return;};
		bool _beforeExecuteEnabled; // for speed

		/**
			Same as _beforeExecute_, but to work after the execute method.
			
		virtual void _afterExecute_() {return;};
		bool _afterExecuteEnabled; // for speed

		/**
			This is the method that is used to run the block
			
		virtual void run(int _parent_=0) {
			__parent_number = _parent_;
			if (__disabled || FXD_BREAK) {return;}
			FXD_CURRENT_FUNCTION_ID = __block_number;

			if (_beforeExecuteEnabled) {_beforeExecute_();}
			_execute_();
			if (_afterExecuteEnabled) {_afterExecute_();}

			if (__block_waiting && FXD_CURRENT_FUNCTION_ID == __block_number) {fxdWait.Accumulate(FXD_CURRENT_FUNCTION_ID);}
		}

	T20 StopLossPips;
	T21 GridSizeSL;
	T22 dlStopLoss; virtual _T22_ _dlStopLoss_(){return(_T22_)0;}
	T23 dpStopLoss; virtual _T23_ _dpStopLoss_(){return(_T23_)0;}
	T24 ddStopLoss; virtual _T24_ _ddStopLoss_(){return(_T24_)0;}
	T25 gTPmode;
	T26 TakeProfitPips;
	T27 GridSizeTP;
	T28 dlTakeProfit; virtual _T28_ _dlTakeProfit_(){return(_T28_)0;}
	T29 dpTakeProfit; virtual _T29_ _dpTakeProfit_(){return(_T29_)0;}
	T30 ddTakeProfit; virtual _T30_ _ddTakeProfit_(){return(_T30_)0;}
	T31 GridLevelsGradation;
	T32 GridVolumesGradation;
	T33 GridSLgradation;
	T34 GridTPgradation;
	T35 ExpMode;
	T36 ExpDays;
	T37 ExpHours;
	T38 ExpMinutes;
	T39 dExp; virtual _T39_ _dExp_(){return(_T39_)0;}
	T40 Slippage;
	T41 MyComment;
	T42 ArrowColorSell;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_GridPendingSells2()
	{
		Group = (string)"";
		Symbol = (string)CurrentSymbol();
		GridOrdersCount = (int)3;
		GridStart = (string)"bid";
		GridStartOffset = (double)0.0;
		GridStartRoundNumberPips = (double)0.0;
		GridSize = (double)25.0;
		VolumeMode = (string)"fixed";
		VolumeSize = (double)0.1;
		VolumeSizeRisk = (double)50.0;
		VolumeRisk = (double)2.5;
		VolumePercent = (double)100.0;
		VolumeBlockPercent = (double)3.0;
		FixedRatioUnitSize = (double)0.01;
		FixedRatioDelta = (double)20.0;
		VolumeUpperLimit = (double)0.0;
		gSLmode = (string)"fixed";
		StopLossPips = (double)50.0;
		GridSizeSL = (double)100.0;
		gTPmode = (string)"fixed";
		TakeProfitPips = (double)50.0;
		GridSizeTP = (double)100.0;
		GridLevelsGradation = (double)100.0;
		GridVolumesGradation = (double)100.0;
		GridSLgradation = (double)100.0;
		GridTPgradation = (double)100.0;
		ExpMode = (string)"GTC";
		ExpDays = (int)0;
		ExpHours = (int)1;
		ExpMinutes = (int)0;
		Slippage = (ulong)4;
		MyComment = (string)"";
		ArrowColorSell = (color)clrRed;
	}

	public: /* The main method *
	virtual void _execute_()
	{
		//-- open price -------------------------------------------------------------
		double op=0;
		
		     if (GridStart == "ask")      {op = SymbolAsk(Symbol);}
		else if (GridStart == "bid")      {op = SymbolBid(Symbol);}
		else if (GridStart == "mid")      {op = (SymbolAsk(Symbol) + SymbolBid(Symbol)) / 2;}
		else if (GridStart == "function") {op = _fGridStart_();}
		
		op = op - toDigits(GridStartOffset, Symbol);
		
		//-- round number snap ------------------------------------------------------
		if (GridStartRoundNumberPips != 0)
		{
			double grid_start_round_number = toDigits(GridStartRoundNumberPips, Symbol);
			// when negative number is applied, the Math function knows to reverse itself: Ceil <-> Floor
			op = MathFloor(op / grid_start_round_number) * grid_start_round_number;
		}
		
		//-- stops ------------------------------------------------------------------
		double sll = 0, slp = 0, tpl = 0, tpp = 0;
		
		     if (gSLmode == "fixed")           {slp = StopLossPips;}
		else if (gSLmode == "gridsize")        {slp = GridSize * (GridSizeSL / 100);}
		else if (gSLmode == "dynamicPips")     {slp = _dpStopLoss_();}
		else if (gSLmode == "dynamicDigits")   {slp = toPips(_ddStopLoss_(), Symbol);}
		else if (gSLmode == "dynamicLevel")    {sll = _dlStopLoss_();}
		else if (gSLmode == "dynamicLevelAll") {sll = _dlStopLoss_();}
		
		     if (gTPmode == "fixed")           {tpp = TakeProfitPips;}
		else if (gTPmode == "gridsize")        {tpp = GridSize * (GridSizeTP / 100);}
		else if (gTPmode == "dynamicPips")     {tpp = _dpTakeProfit_();}
		else if (gTPmode == "dynamicDigits")   {tpp = toPips(_ddTakeProfit_(), Symbol);}
		else if (gTPmode == "dynamicLevel")    {tpl = _dlTakeProfit_();}
		else if (gTPmode == "dynamicLevelAll") {tpl = _dlTakeProfit_();}
		
		//-- lots -------------------------------------------------------------------
		double lots    = 0;
		double pre_sll = sll;
		
		if (pre_sll == 0) {pre_sll = op;}
		
		double pre_sl_pips = toPips((pre_sll + toDigits(slp, Symbol)) - op, Symbol);
		
		     if (VolumeMode == "fixed")            {lots = DynamicLots(Symbol, VolumeMode, VolumeSize);}
		else if (VolumeMode == "block-equity")     {lots = DynamicLots(Symbol, VolumeMode, VolumeBlockPercent);}
		else if (VolumeMode == "block-balance")    {lots = DynamicLots(Symbol, VolumeMode, VolumeBlockPercent);}
		else if (VolumeMode == "block-freemargin") {lots = DynamicLots(Symbol, VolumeMode, VolumeBlockPercent);}
		else if (VolumeMode == "equity")           {lots = DynamicLots(Symbol, VolumeMode, VolumePercent);}
		else if (VolumeMode == "balance")          {lots = DynamicLots(Symbol, VolumeMode, VolumePercent);}
		else if (VolumeMode == "freemargin")       {lots = DynamicLots(Symbol, VolumeMode, VolumePercent);}
		else if (VolumeMode == "equityRisk")       {lots = DynamicLots(Symbol, VolumeMode, VolumeRisk, pre_sl_pips);}
		else if (VolumeMode == "balanceRisk")      {lots = DynamicLots(Symbol, VolumeMode, VolumeRisk, pre_sl_pips);}
		else if (VolumeMode == "freemarginRisk")   {lots = DynamicLots(Symbol, VolumeMode, VolumeRisk, pre_sl_pips);}
		else if (VolumeMode == "fixedRisk")        {lots = DynamicLots(Symbol, VolumeMode, VolumeSizeRisk, pre_sl_pips);}
		else if (VolumeMode == "fixedRatio")       {lots = DynamicLots(Symbol, VolumeMode, FixedRatioUnitSize, FixedRatioDelta);}
		else if (VolumeMode == "dynamic")          {lots = _dVolumeSize_();}
		
		lots = AlignLots(Symbol, lots, 0, VolumeUpperLimit);
		
		//-- expiration -------------------------------------------------------------
		datetime exp = ExpirationTime(ExpMode, ExpDays, ExpHours, ExpMinutes, _dExp_());
		
		//-- send -------------------------------------------------------------------
		long ticket = 0;
		double gSize = GridSize;
		double gSL  = slp;
		double gTP  = tpp;
		
		if (sll > 0)
		{
			gSL = toPips(sll - op, Symbol);
		
			if (gSLmode == "dynamicLevelAll")
			{
				gSL = 0;
			}
			else if (gSLmode != "dynamicLevelAll")
			{
				sll = 0;
			}
		}
		
		if (tpl > 0)
		{
			gTP = toPips(op - tpl, Symbol);
		
			if (gTPmode == "dynamicLevelAll")
			{
				gTP = 0;
			}
			else if (gTPmode != "dynamicLevelAll")
			{
				tpl = 0;
			}
		}
		
		for (int cnt = 1; cnt <= GridOrdersCount; cnt++)
		{
			if (cnt == 1)
			{
				if (gSLmode == "gridsize") gSL = gSize * (GridSizeSL / 100);
				if (gTPmode == "gridsize") gTP = gSize * (GridSizeTP / 100);
			}
			else
			{
				if (GridLevelsGradation > 0) gSize = gSize * (GridLevelsGradation / 100);
		
				lots = lots * (GridVolumesGradation / 100);
		
				if (gSLmode == "gridsize") gSL = gSize * (GridSizeSL / 100);
				gSL = gSL * (GridSLgradation / 100);
		
				if (gTPmode == "gridsize") gTP = gSize * (GridSizeTP / 100);
				gTP = gTP * (GridTPgradation / 100);
			}
		
			op = op - toDigits(gSize, Symbol);
			double lotsAligned = AlignLots(Symbol, lots, 0, VolumeUpperLimit);
		
			ticket = SellLater(Symbol, lotsAligned, op, sll, tpl, gSL, gTP, Slippage, exp, (MagicStart + (int)Group), MyComment, ArrowColorSell);
		}
		
		if (ticket > 0) {_callback_(1);} else {_callback_(0);}
	}
};

// "Impulse Down" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6,typename T7>
class MDL_ImpulseDn: public BlockCalls
{
	public: /* Input Parameters 
	T1 SignalType;
	T2 QuietBarsCount;
	T3 QuietBarsMinRange;
	T4 ImpulseStrength;
	T5 ImpulseShift;
	T6 Symbol;
	T7 Period;
	/* Static Parameters 
	double QBrange;
	datetime BarTime;
	datetime BarTime2;
	double InpOpen;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_ImpulseDn()
	{
		SignalType = (string)"continuous";
		QuietBarsCount = (int)3;
		QuietBarsMinRange = (double)10.0;
		ImpulseStrength = (double)3.0;
		ImpulseShift = (int)0;
		Symbol = (string)CurrentSymbol();
		Period = (ENUM_TIMEFRAMES)CurrentTimeframe();
		/* Static Parameters (initial value) 
		QBrange = -1;
		BarTime =  0;
		BarTime2 =  0;
		InpOpen =  0;
	}

	public: /* The main method 
	virtual void _execute_()
	{
		int i            = 0;
		double MaxSize   = 0;
		bool NewBarComes = false;
		bool pass        = false;
		
		if (BarTime < iTime(Symbol,Period,1) || QBrange == -1)
		{
			BarTime = (int)iTime(Symbol,Period,1);
			QBrange = 0;
		
			for (i=0; i < QuietBarsCount; i++)
			{
				int shift = i + 1 + ImpulseShift;
				MaxSize   = iHigh(Symbol,Period,shift) - iLow(Symbol,Period,shift);
		
				if (MaxSize > QBrange)
				{
					QBrange = MaxSize;
				}
			}
		
			InpOpen     = iOpen(Symbol,Period,ImpulseShift);
			NewBarComes = true;
		}
		
		if (
			   (SignalType == "continuous" || BarTime2 < iTime(Symbol,Period,1))
			&& ((ImpulseShift == 0 && InpOpen > 0) || NewBarComes == true)
			&& QBrange > toDigits(QuietBarsMinRange, Symbol)
		)
		{
			double ImpSize = InpOpen - iClose(Symbol,Period,ImpulseShift);
		
			if (ImpSize >= QBrange * ImpulseStrength)
			{
				if (SignalType != "continuous")
				{
					BarTime2 = (int)iTime(Symbol,Period,1);
				}
		
				pass = true;
			}
		}
		
		if (pass == true) {_callback_(1);} else {_callback_(0);}
	}
};

// "Trailing stop (group of trades)" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6,typename T7,typename T8,typename _T8_,typename T9,typename T10,typename T11,typename T12,typename T13,typename T14,typename T15,typename T16,typename _T16_,typename T17,typename T18,typename T19,typename T20,typename T21,typename _T21_,typename T22>
class MDL_TrailingStopAvgPrice: public BlockCalls
{
	public: /* Input Parameters 
	T1 GroupMode;
	T2 Group;
	T3 Symbol;
	T4 BuysOrSells;
	T5 TrailWhat;
	T6 TrailingStopMode;
	T7 tStopPips;
	T8 ftStop; virtual _T8_ _ftStop_(){return(_T8_)0;}
	T9 tStopMoney;
	T10 TrailingStepMode;
	T11 tStepPips;
	T12 tStepPercentTS;
	T13 TrailingStartMode;
	T14 tStartPips;
	T15 tStartPercentTS;
	T16 ftStart; virtual _T16_ _ftStart_(){return(_T16_)0;}
	T17 resetOnTrade;
	T18 TrailingTPmode;
	T19 tTPpips;
	T20 tTPpercentTS;
	T21 ftTP; virtual _T21_ _ftTP_(){return(_T21_)0;}
	T22 LevelColor;
	/* Static Parameters 
	double avg_lots0;
	double group_stop;
	string change_detect0;
	virtual void _callback_(int r) {return;}

	public: /* Constructor 
	MDL_TrailingStopAvgPrice()
	{
		GroupMode = (string)"group";
		Group = (string)"";
		Symbol = (string)CurrentSymbol();
		BuysOrSells = (string)"both";
		TrailWhat = (int)1;
		TrailingStopMode = (string)"fixed";
		tStopPips = (double)40.0;
		tStopMoney = (double)10.0;
		TrailingStepMode = (string)"fixed";
		tStepPips = (double)1.0;
		tStepPercentTS = (double)10.0;
		TrailingStartMode = (string)"none";
		tStartPips = (double)10.0;
		tStartPercentTS = (double)100.0;
		resetOnTrade = (bool)true;
		TrailingTPmode = (string)"none";
		tTPpips = (double)20.0;
		tTPpercentTS = (double)200.0;
		LevelColor = (color)clrDeepPink;
		/* Static Parameters (initial value) 
		avg_lots0 =  0;
		group_stop =  0;
		change_detect0 =  "";
	}

	public: /* The main method *
	virtual void _execute_()
	{
		int index        = 0;
		double avg_price = 0;
		double avg_load  = 0;
		double avg_lots  = 0; // Average sum of lots - it can be negative
		double profit    = 0;
		double askbid    = 0;
		double bidask    = 0;
		int trades_count = 0; // Count of Trades to work with
		bool resetSL     = false;
		ulong tickets[]; ArrayResize(tickets, 0); // Array with tickets to modify
		
		string change_detect         = "";
		
		int total = TradesTotal();
		
		//-- collect group data from trades
		for (index = 0; index < total; index++)
		{
			if (!TradeSelectByIndex(index, GroupMode, Group, "symbol", Symbol, BuysOrSells)) {continue;}
			
			if (OrderType() == 0)
			{
				avg_load = avg_load + (OrderOpenPrice() * OrderLots());
				avg_lots = avg_lots + OrderLots();
			}
			else
			{
				avg_load = avg_load - (OrderOpenPrice() * OrderLots());
				avg_lots = avg_lots - OrderLots();
			}
			
			ArrayEnsureValue(tickets, (ulong)OrderTicket());
		
			profit        = profit + NormalizeDouble(OrderProfit() + OrderCommission() + OrderSwap(), 2);
			change_detect = (string)OrderTicket() + change_detect;
			trades_count++;
		}
		
		avg_price = 0;
		
		if (avg_lots != 0)
		{
			avg_price = avg_load / avg_lots;
		}
		
		//-- check and set flag for reset (when new trade or when trade is gone)
		if (change_detect0 != change_detect)
		{
			if (trades_count == 0)
			{
				avg_lots0  = 0;
				group_stop = 0;
			}
			else
			{
				group_stop = 0;
		
				if (resetOnTrade == true)
				{
					avg_lots0 = avg_lots;
					resetSL   = true;
				}
			}
		
			change_detect0 = change_detect;
		}
		
		//-- do trailing stop
		if (avg_lots != 0)
		{
			int polarity = 0;
		
			if (avg_lots > 0)
			{
				polarity = 1;
				askbid   = SymbolAsk(Symbol);
				bidask   = SymbolBid(Symbol);
			}
			else
			{
				polarity = -1;
				askbid   = SymbolBid(Symbol);
				bidask   = SymbolAsk(Symbol);
			}
		
			// Trailing Stop Size
			double t_stop = 0;
		
			     if (TrailingStopMode == "fixed")       {t_stop = tStopPips;}
			else if (TrailingStopMode == "dynamicSize") {t_stop = _ftStop_();}
			else if (TrailingStopMode == "function")
			{
				t_stop = _ftStop_();
				t_stop = toPips(MathAbs(askbid-t_stop), Symbol);
			}
			else if (TrailingStopMode == "money")
			{
				double tick_value = SymbolInfoDouble(Symbol, SYMBOL_TRADE_TICK_VALUE);
				double tick_size  = SymbolInfoDouble(Symbol, SYMBOL_TRADE_TICK_SIZE);
				double point      = SymbolInfoDouble(Symbol, SYMBOL_POINT);
		
				double tickvalue = ((tick_value / tick_size) * point);
		
				t_stop = tStopMoney;
				t_stop = t_stop /  ((MathAbs(avg_lots) * PipValue(Symbol)));
				t_stop = t_stop / tickvalue;
			}
		
			// Trailing Start Level
			double t_start = 0;
		
			     if (TrailingStartMode == "none")      {t_start = -EMPTY_VALUE;}
			else if (TrailingStartMode == "zero")      {t_start = 0;}
			else if (TrailingStartMode == "fixed")     {t_start = tStartPips;}
			else if (TrailingStartMode == "percentTS") {t_start = t_stop * (tStartPercentTS / 100);}
			else if (TrailingStartMode == "function")  {t_start = _ftStart_();}
		
			// Trailing Step Size
			double t_step = 0;
		
			     if (TrailingStepMode == "fixed")      {t_step = tStepPips;}
			else if (TrailingStepMode == "percentTS")  {t_step = t_stop * (tStepPercentTS / 100);}
		
			// Trailing Take Profit
			double t_opp = -1;
		
			     if (TrailingTPmode == "none")         {t_opp = -1;}
			else if (TrailingTPmode == "clear")        {t_opp = 0;}
			else if (TrailingTPmode == "fixed")        {t_opp = MathAbs(toPips(avg_price - group_stop, Symbol));}
			else if (TrailingTPmode == "percentTS")    {t_opp = MathAbs(toPips(avg_price - t_stop, Symbol)) * (tTPpercentTS/100);}
			else if (TrailingTPmode == "function")     {t_opp = _ftTP_();}
		
			bool go_modify = false;
		
			if (polarity == 1 && TrailWhat * (askbid - avg_price) > toDigits(t_start, Symbol))
			{
				if ((TrailWhat * (askbid - group_stop) >= toDigits(t_stop + t_step, Symbol)) || group_stop==0 || resetSL == true)
				{
					group_stop = (askbid - TrailWhat * toDigits(t_stop, Symbol));
					go_modify  = true;
				}
			}
			else if (polarity == -1 && TrailWhat * (avg_price - askbid) > toDigits(t_start, Symbol))
			{
				if ((TrailWhat * (group_stop - askbid) >= toDigits(t_stop + t_step, Symbol)) || group_stop == 0 || resetSL == true)
				{
					group_stop = (askbid + TrailWhat * toDigits(t_stop, Symbol));
					go_modify  = true;
				}
			}
		
			if (go_modify==true)
			{
				for (index = ArraySize(tickets) - 1; index >= 0; index--)
				{
					if (TradeSelectByTicket(tickets[index]))
					{
						bool success = true;
						
						// calculate the future stop and the limit
						double stopslevel = (double)SymbolInfoInteger(OrderSymbol(), SYMBOL_TRADE_STOPS_LEVEL);
						stopslevel        = toDigits(stopslevel / PipValue(OrderSymbol()), OrderSymbol());
						double fsl        = MathAbs(group_stop); // future SL
						double limit      = 0;
						
						if (OrderType() == 0)
						{
							limit = bidask - stopslevel * TrailWhat;
							if (fsl > limit) {fsl = limit;}
						}
						else
						{
							limit = bidask + stopslevel * TrailWhat;
							if (fsl < limit) {fsl = limit;}
						}
		
						// trail SL
						if (TrailWhat == 1)
						{
							if (t_opp < 0) {t_opp = attrTakeProfit();}
							
							// consider limits
							if (
								   attrStopLoss() == 0
								|| (OrderType() == 0 && (attrStopLoss() < fsl || resetSL == true))
								|| (OrderType() == 1 && (attrStopLoss() > fsl || resetSL == true))
							)
							{
								success = ModifyStops(OrderTicket(), group_stop, t_opp, LevelColor);
							}
						}
						// trail TP
						else
						{
							if (t_opp < 0) {t_opp = attrStopLoss();}
							
							// consider limits
							if (
								   attrTakeProfit() == 0
								|| (OrderType() == 0 && (attrTakeProfit() > fsl || resetSL == true))
								|| (OrderType() == 1 && (attrTakeProfit() < fsl || resetSL == true))
							)
							{
								success = ModifyStops(OrderTicket(), t_opp, group_stop, LevelColor);
							}
						}
					}
				}
			}
		}
		
		_callback_(1);
	}
};

// "Trailing stop" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6,typename T7,typename T8,typename T9,typename T10,typename T11,typename T12,typename T13,typename T14,typename _T14_,typename T15,typename _T15_,typename T16,typename T17,typename T18,typename T19,typename T20,typename T21,typename T22,typename T23,typename T24,typename _T24_,typename T25,typename _T25_,typename T26,typename T27,typename T28,typename T29,typename _T29_,typename T30>
class MDL_TrailingStop2: public BlockCalls
{
	public: /* Input Parameters *
	T1 GroupMode;
	T2 Group;
	T3 SymbolMode;
	T4 Symbol;
	T5 BuysOrSells;
	T6 TrailWhat;
	T7 TrailingReferencePrice;
	T8 TrailingStopMode;
	T9 tStopPips;
	T10 tStopMoney;
	T11 tStopMultiple;
	T12 tStopPercentTP;
	T13 tStopPercentProfit;
	T14 ftStop; virtual _T14_ _ftStop_(){return(_T14_)0;}
	T15 ftDigits; virtual _T15_ _ftDigits_(){return(_T15_)0;}
	T16 TrailingStepMode;
	T17 tStepPips;
	T18 tStepPercentTS;
	T19 TrailingStartMode;
	T20 tStartPips;
	T21 tStartPercentTS;
	T22 tStartPercentSL;
	T23 tStartPercentTP;
	T24 ftStart; virtual _T24_ _ftStart_(){return(_T24_)0;}
	T25 ftStartFraction; virtual _T25_ _ftStartFraction_(){return(_T25_)0;}
	T26 TrailingTPmode;
	T27 tTPpips;
	T28 tTPpercentTS;
	T29 ftTP; virtual _T29_ _ftTP_(){return(_T29_)0;}
	T30 LevelColor;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_TrailingStop2()
	{
		GroupMode = (string)"group";
		Group = (string)"";
		SymbolMode = (string)"symbol";
		Symbol = (string)CurrentSymbol();
		BuysOrSells = (string)"both";
		TrailWhat = (int)1;
		TrailingReferencePrice = (int)0;
		TrailingStopMode = (string)"fixed";
		tStopPips = (double)40.0;
		tStopMoney = (double)10.0;
		tStopMultiple = (string)"20/5, 30/10";
		tStopPercentTP = (double)100.0;
		tStopPercentProfit = (double)50.0;
		TrailingStepMode = (string)"fixed";
		tStepPips = (double)1.0;
		tStepPercentTS = (double)10.0;
		TrailingStartMode = (string)"none";
		tStartPips = (double)10.0;
		tStartPercentTS = (double)100.0;
		tStartPercentSL = (double)10.0;
		tStartPercentTP = (double)10.0;
		TrailingTPmode = (string)"none";
		tTPpips = (double)20.0;
		tTPpercentTS = (double)200.0;
		LevelColor = (color)clrDeepPink;
	}

	public: /* The main method *
	virtual void _execute_()
	{
		int total = TradesTotal();
		
		for (int index = 0; index < total; index++)
		{
			if (TradeSelectByIndex(index, GroupMode, Group, SymbolMode, Symbol, BuysOrSells))
			{
				string symbol     = OrderSymbol();
				double ask        = SymbolInfoDouble(symbol, SYMBOL_ASK);
				double bid        = SymbolInfoDouble(symbol, SYMBOL_BID);
				double stopslevel = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
				int digits        = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
				int polarity      = 1;   // 1 = buy, -1 = sell
				double askbid     = ask; // could be Ask or Bid
				double bidask     = bid; // the opposite of askbid
				double sltp       = 0;   // could be SL or TP
				double tpsl       = 0;   // the opposite of sltp
				double fsl        = 0;   // Freeze Level
				double limit      = 0;
				double t_stop     = 0;   // trailing STOP
				double t_start    = 0;   // trailing START
				double t_step     = 0;   // trailing STEP
				double t_opp      = 0;   // trailing Opposite (TP when trailing SL or SL when trailing TP)
		
				if (TrailWhat > 0) {
					sltp = attrStopLoss();
					tpsl = attrTakeProfit();
				}
				else {
					sltp = attrTakeProfit();
					tpsl = attrStopLoss();
				}
		
				if (OrderType() == 0) {
					polarity = 1;
		
					if (TrailingReferencePrice == 1)
					{
						askbid = bid;
						bidask = ask;
					}
				}
				else if (OrderType() == 1) {
					polarity = -1;
					askbid   = bid;
					bidask   = ask;
		
					if (TrailingReferencePrice == 1) {
						askbid = ask;
						bidask = bid;
					}
				}
		
				if (TrailingReferencePrice == 2) {
					askbid = (ask + bid) / 2;
					bidask = (ask + bid) / 2;
				}
		
				// Trailing Stop Size
				     if (TrailingStopMode == "fixed")         {t_stop = toDigits(tStopPips, symbol);} 
				else if (TrailingStopMode == "percentTP")     {t_stop = (MathAbs(OrderOpenPrice() - tpsl)) * (tStopPercentTP / 100);}
				else if (TrailingStopMode == "percentProfit") {t_stop = (MathAbs(askbid - OrderOpenPrice())) * (tStopPercentProfit / 100);}
				else if (TrailingStopMode == "dynamicSize")   {t_stop = toDigits(_ftStop_(), symbol);}
				else if (TrailingStopMode == "dynamicDigits") {t_stop = _ftDigits_();}
				else if (TrailingStopMode == "dynamic")
				{
					// TODO: ftStop is now used for both, dynamic and dynamicSize - separate it
					t_stop = _ftStop_();
					t_stop = (polarity == 1) ? ask - t_stop : t_stop - bid;
				}
				else if (TrailingStopMode == "money")
				{
					t_stop = tStopMoney;
		
					double lotsize   = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
					double tickvalue = (SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE)) * SymbolInfoDouble(symbol, SYMBOL_POINT);
					t_stop = t_stop /  (OrderLots() * PipValue(symbol));
					// TODO: remove this toDigits(), the calculation should be made directly into digits
					t_stop = toDigits(t_stop / tickvalue, symbol);
				}
		
				// Trailing Start Level
				     if (TrailingStartMode == "none")             {t_start = -EMPTY_VALUE;}
				else if (TrailingStartMode == "zero")             {t_start = 0;}
				else if (TrailingStartMode == "fixed")            {t_start = toDigits(tStartPips, symbol);}
				else if (TrailingStartMode == "percentTS")        {t_start = t_stop * (tStartPercentTS / 100);}
				else if (TrailingStartMode == "percentTP")        {t_start = (MathAbs(OrderOpenPrice() - tpsl)) * (tStartPercentTP / 100);}
				else if (TrailingStartMode == "percentSL")        {t_start = (MathAbs(OrderOpenPrice() - sltp)) * (tStartPercentSL / 100);}
				else if (TrailingStartMode == "function")         {t_start = toDigits(_ftStart_(), symbol);}
				else if (TrailingStartMode == "functionFraction") {t_start = _ftStartFraction_();}
		
				// Trailing Step Size
				     if (TrailingStepMode == "fixed")     {t_step = toDigits(tStepPips, symbol);}
				else if (TrailingStepMode == "percentTS") {t_step = t_stop * (tStepPercentTS / 100);}
		
				// Trailing Opposite Size
				     if (TrailingTPmode == "none")      {t_opp = tpsl;}
				else if (TrailingTPmode == "clear")     {t_opp = 0;}
				else if (TrailingTPmode == "fixed")     {t_opp = TrailWhat * (OrderOpenPrice() + (polarity * toDigits(tTPpips, symbol)));}
				else if (TrailingTPmode == "percentTS") {t_opp = TrailWhat * (OrderOpenPrice() + (polarity * toDigits(t_stop * (tTPpercentTS / 100), symbol)));}
				else if (TrailingTPmode == "function")  {t_opp = _ftTP_();}
		
				// this mode is located here because it overrides Start, Stop and Step
				// the idea here is to use Start as target profits
				if (TrailingStopMode == "multiple")
				{
					bool next = false;
					string tmp1[];
					string tmp2[];
		
					StringExplode(",", tStopMultiple, tmp1);
		
					for (int i = ArraySize(tmp1)-1; i >= 0; i--)
					{
						StringExplode("/", tmp1[i], tmp2);
		
						if (ArraySize(tmp2) != 2) {continue;}
		
						// trailing start will be used as the treshold level
						double new_start = toDigits(StringToDouble(StringTrim(tmp2[0])), symbol);
		
						// the regular trailing start is bigger than this level -> skip
						if (new_start < t_start) {continue;}
		
						// check whether the current price<->op distance is bigger than some of the desired levels
						double diff = NormalizeDouble(askbid - OrderOpenPrice(), digits);
		
						if (polarity * TrailWhat * diff >= new_start)
						{
							// and setup parameters so SL will be moved
							t_start = new_start;
							t_stop  = polarity * TrailWhat * diff - toDigits(StringToDouble(StringTrim(tmp2[1])), symbol);
		
							next = true;
							break;
						}
					}
		
					if (next == false) {continue;}
				}
		
				stopslevel   = stopslevel * SymbolInfoDouble(symbol, SYMBOL_POINT);
		
				if (t_stop <= 0) {continue;}
		
				if (OrderType() == 0 && TrailWhat * (askbid - OrderOpenPrice()) > t_start)
				{
					if ((TrailWhat * (askbid - sltp) >= t_stop + t_step) || sltp == 0)
					{
						// consider minimum stop
						fsl   = MathAbs(askbid - t_stop);
						limit = bidask - stopslevel * TrailWhat;
		
						if (fsl > limit) {fsl = limit;}
		
						if (TrailWhat == 1) // trail SL
						{
							if (sltp == 0 || sltp < fsl) {
								ModifyStops(OrderTicket(), askbid - t_stop, t_opp, LevelColor);
							}
						}
						else { // trail TP
							if (sltp == 0 || sltp > fsl) {
								ModifyStops(OrderTicket(), t_opp, askbid + t_stop, LevelColor);
							}
						}
					}
				}
				else if (OrderType() == 1 && TrailWhat * (OrderOpenPrice() - askbid) > t_start)
				{
					if ((TrailWhat * (sltp - askbid) >= t_stop + t_step) || sltp == 0)
					{
						// consider minimum stop
						fsl   = MathAbs(askbid + t_stop);
						limit = bidask + stopslevel * TrailWhat;
		
						if (fsl < limit) {fsl = limit;}
		
						if (TrailWhat == 1)
						{ // trail SL
							if (sltp == 0 || sltp > fsl)
							{
								ModifyStops(OrderTicket(), askbid + t_stop, t_opp, LevelColor);
							}
						}
						else
						{ // trail TP
							if (sltp == 0 || sltp < fsl)
							{
								ModifyStops(OrderTicket(), t_opp, askbid - t_stop, LevelColor);
							}
						}
					}
				}
			}
		}
		
		_callback_(1);
	}
};

// "Trailing pending orders" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6,typename T7,typename T8,typename T9,typename _T9_,typename T10,typename _T10_,typename T11,typename _T11_,typename T12>
class MDL_TrailingPendingOrders: public BlockCalls
{
	public: /* Input Parameters 
	T1 GroupMode;
	T2 Group;
	T3 SymbolMode;
	T4 Symbol;
	T5 BuysOrSells;
	T6 LimitsOrStops;
	T7 TrailingDistanceMode;
	T8 tDistancePips;
	T9 dtDistancePips; virtual _T9_ _dtDistancePips_(){return(_T9_)0;}
	T10 dtDistanceDigits; virtual _T10_ _dtDistanceDigits_(){return(_T10_)0;}
	T11 dtLevel; virtual _T11_ _dtLevel_(){return(_T11_)0;}
	T12 tStepPips;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_TrailingPendingOrders()
	{
		GroupMode = (string)"group";
		Group = (string)"";
		SymbolMode = (string)"symbol";
		Symbol = (string)CurrentSymbol();
		BuysOrSells = (string)"both";
		LimitsOrStops = (string)"both";
		TrailingDistanceMode = (string)"fixed";
		tDistancePips = (double)30.0;
		tStepPips = (double)1.0;
	}

	public: /* The main method *
	virtual void _execute_()
	{
		for (int index = OrdersTotal()-1; index >= 0; index--)
		{
			if (PendingOrderSelectByIndex(index, GroupMode, Group, SymbolMode, Symbol, BuysOrSells, LimitsOrStops))
			{
				string symbol   = OrderSymbol();
				double price    = (IsOrderTypeBuy()) ? SymbolAsk(symbol) : SymbolBid(symbol);
				double distance = 0;
				int digits      = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
		
				     if (TrailingDistanceMode == "fixed")         distance = toDigits(tDistancePips, symbol);
				else if (TrailingDistanceMode == "dynamic")       distance = price - _dtLevel_();
				else if (TrailingDistanceMode == "dynamicPips")   distance = toDigits(_dtDistancePips_(), symbol);
				else if (TrailingDistanceMode == "dynamicDigits") distance = _dtDistanceDigits_();
		
				distance = NormalizeDouble(MathAbs(distance), digits);
		
				double old_op = 0, old_sl = 0, old_tp = 0;
				double new_op = 0, new_sl = 0, new_tp = 0;
		
				if (MathAbs(price - OrderOpenPrice()) >= MathAbs(distance + toDigits(tStepPips, symbol)))         
				{
					old_sl = attrStopLoss();
					old_tp = attrTakeProfit();
					old_op = OrderOpenPrice();
		
					if (IsOrderTypeBuy() == true)
					{
						new_op = IsOrderTypeStop() ? price + distance : price - distance;
		
						if (old_sl > 0) new_sl = new_op - (old_op - old_sl);
						if (old_tp > 0) new_tp = new_op + (old_tp - old_op);
					}
					else
					{
						new_op = IsOrderTypeStop() ? price - distance : price + distance;
		
						if (old_sl > 0) new_sl = new_op + (old_sl - old_op);
						if (old_tp > 0) new_tp = new_op - (old_op - old_tp);
					}
		
					ModifyOrder(OrderTicket(), new_op, new_sl, new_tp, 0, 0, OrderExpiration(), clrBlack);
				}
			}
		}
		
		_callback_(1);
	}
};

// "No pending order" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6>
class MDL_NoPendingOrders: public BlockCalls
{
	public: /* Input Parameters *
	T1 GroupMode;
	T2 Group;
	T3 SymbolMode;
	T4 Symbol;
	T5 BuysOrSells;
	T6 LimitsOrStops;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_NoPendingOrders()
	{
		GroupMode = (string)"group";
		Group = (string)"";
		SymbolMode = (string)"symbol";
		Symbol = (string)CurrentSymbol();
		BuysOrSells = (string)"both";
		LimitsOrStops = (string)"both";
	}

	public: /* The main method *
	virtual void _execute_()
	{
		bool exist = false;
		
		for (int index = OrdersTotal()-1; index >= 0; index--)
		{
			if (PendingOrderSelectByIndex(index, GroupMode, Group, SymbolMode, Symbol, BuysOrSells, LimitsOrStops))
			{
				exist = true;
				break;
			}
		}
		
		if (exist == false) {_callback_(1);} else {_callback_(0);}
	}
};

// "Condition" model
template<typename T1,typename _T1_,typename T2,typename T3,typename _T3_,typename T4>
class MDL_Condition: public BlockCalls
{
	public: /* Input Parameters *
	T1 Lo; virtual _T1_ _Lo_(){return(_T1_)0;}
	T2 compare;
	T3 Ro; virtual _T3_ _Ro_(){return(_T3_)0;}
	T4 crosswidth;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_Condition()
	{
		compare = (string)">";
		crosswidth = (int)1;
	}

	public: /* The main method *
	virtual void _execute_()
	{
		bool output1 = false, output2 = false; // output 1 and output 2
		int crossover = 0;
		
		if (compare == "x>" || compare == "x<") {crossover = 1;}
		
		for (int i = 0; i <= crossover; i++)
		{
			// i=0 - normal pass, i=1 - crossover pass
		
			// Left operand of the condition
			FXD_MORE_SHIFT = i * crosswidth;
			_T1_ lo = _Lo_();
			if (MathAbs(lo) == EMPTY_VALUE) {return;}
		
			// Right operand of the condition
			FXD_MORE_SHIFT = i * crosswidth;
			_T3_ ro = _Ro_();
			if (MathAbs(ro) == EMPTY_VALUE) {return;}
		
			// Conditions
			if (CompareValues(compare, lo, ro))
			{
				if (i == 0)
				{
					output1 = true;
				}
			}
			else
			{
				if (i == 0)
				{
					output2 = true;
				}
				else
				{
					output2 = false;
				}
			}
		
			if (crossover == 1)
			{
				if (CompareValues(compare, ro, lo))
				{
					if (i == 0)
					{
						output2 = true;
					}
				}
				else
				{
					if (i == 1)
					{
						output1 = false;
					}
				}
			}
		}
		
		FXD_MORE_SHIFT = 0; // reset
		
			  if (output1 == true) {_callback_(1);}
		else if (output2 == true) {_callback_(0);}
	}
};

// "Pass" model
class MDL_Pass: public BlockCalls
{
	virtual void _callback_(int r) {return;}

	public: /* The main method *
	virtual void _execute_()
	{
		_callback_(1);
	}
};

// "Comment" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6,typename T7,typename T8,typename T9,typename T10,typename T11,typename T12,typename T13,typename T14,typename T15,typename T16,typename _T16_,typename T17,typename T18,typename T19,typename T20,typename _T20_,typename T21,typename T22,typename T23,typename T24,typename _T24_,typename T25,typename T26,typename T27,typename T28,typename _T28_,typename T29,typename T30,typename T31,typename T32,typename _T32_,typename T33,typename T34,typename T35,typename T36,typename _T36_,typename T37,typename T38,typename T39,typename T40,typename _T40_,typename T41,typename T42,typename T43,typename T44,typename _T44_,typename T45,typename T46>
class MDL_CommentEx: public BlockCalls
{
	public: /* Input Parameters *
	T1 Title;
	T2 ObjChartSubWindow;
	T3 ObjCorner;
	T4 ObjX;
	T5 ObjY;
	T6 ObjTitleFont;
	T7 ObjTitleFontColor;
	T8 ObjTitleFontSize;
	T9 ObjLabelsFont;
	T10 ObjLabelsFontColor;
	T11 ObjLabelsFontSize;
	T12 ObjFont;
	T13 ObjFontColor;
	T14 ObjFontSize;
	T15 Label1;
	T16 Value1; virtual _T16_ _Value1_(){return(_T16_)0;}
	T17 FormatNumber1;
	T18 FormatTime1;
	T19 Label2;
	T20 Value2; virtual _T20_ _Value2_(){return(_T20_)0;}
	T21 FormatNumber2;
	T22 FormatTime2;
	T23 Label3;
	T24 Value3; virtual _T24_ _Value3_(){return(_T24_)0;}
	T25 FormatNumber3;
	T26 FormatTime3;
	T27 Label4;
	T28 Value4; virtual _T28_ _Value4_(){return(_T28_)0;}
	T29 FormatNumber4;
	T30 FormatTime4;
	T31 Label5;
	T32 Value5; virtual _T32_ _Value5_(){return(_T32_)0;}
	T33 FormatNumber5;
	T34 FormatTime5;
	T35 Label6;
	T36 Value6; virtual _T36_ _Value6_(){return(_T36_)0;}
	T37 FormatNumber6;
	T38 FormatTime6;
	T39 Label7;
	T40 Value7; virtual _T40_ _Value7_(){return(_T40_)0;}
	T41 FormatNumber7;
	T42 FormatTime7;
	T43 Label8;
	T44 Value8; virtual _T44_ _Value8_(){return(_T44_)0;}
	T45 FormatNumber8;
	T46 FormatTime8;
	/* Static Parameters *
	bool initialized;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_CommentEx()
	{
		Title = (string)"Comment Message";
		ObjChartSubWindow = (string)"";
		ObjCorner = (int)CORNER_LEFT_UPPER;
		ObjX = (int)5;
		ObjY = (int)24;
		ObjTitleFont = (string)"Georgia";
		ObjTitleFontColor = (color)clrGold;
		ObjTitleFontSize = (int)13;
		ObjLabelsFont = (string)"Verdana";
		ObjLabelsFontColor = (color)clrDarkGray;
		ObjLabelsFontSize = (int)10;
		ObjFont = (string)"Verdana";
		ObjFontColor = (color)clrWhite;
		ObjFontSize = (int)10;
		Label1 = (string)"";
		FormatNumber1 = (int)EMPTY_VALUE;
		FormatTime1 = (int)EMPTY_VALUE;
		Label2 = (string)"";
		FormatNumber2 = (int)EMPTY_VALUE;
		FormatTime2 = (int)EMPTY_VALUE;
		Label3 = (string)"";
		FormatNumber3 = (int)EMPTY_VALUE;
		FormatTime3 = (int)EMPTY_VALUE;
		Label4 = (string)"";
		FormatNumber4 = (int)EMPTY_VALUE;
		FormatTime4 = (int)EMPTY_VALUE;
		Label5 = (string)"";
		FormatNumber5 = (int)EMPTY_VALUE;
		FormatTime5 = (int)EMPTY_VALUE;
		Label6 = (string)"";
		FormatNumber6 = (int)EMPTY_VALUE;
		FormatTime6 = (int)EMPTY_VALUE;
		Label7 = (string)"";
		FormatNumber7 = (int)EMPTY_VALUE;
		FormatTime7 = (int)EMPTY_VALUE;
		Label8 = (string)"";
		FormatNumber8 = (int)EMPTY_VALUE;
		FormatTime8 = (int)EMPTY_VALUE;
		/* Static Parameters (initial value) *
		initialized =  false;
	}

	public: /* The main method *
	virtual void _execute_()
	{
		if (!MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
		{
			
		
			long ObjChartID = 0;
			int ObjAnchor   = ANCHOR_LEFT;
		
			if (ObjCorner == CORNER_RIGHT_UPPER || ObjCorner == CORNER_RIGHT_LOWER)
			{
				ObjAnchor = ANCHOR_RIGHT;
			}
		
			string namebase = "fxd_cmnt_" + __block_user_number;
		
			int subwindow = WindowFindVisible(ObjChartID, ObjChartSubWindow);
		
			if (subwindow >= 0)
			{
				//-- draw comment title
				if ((string)Title != "")
				{
					string nametitle = namebase;
		
					if(ObjectFind(ObjChartID, nametitle) < 0)
					{
						if (!ObjectCreate(ObjChartID, nametitle, OBJ_LABEL, subwindow, 0, 0, 0, 0))
						{
							Print(__FUNCTION__, ": failed to create text object! Error code = ", GetLastError());
						}
						else
						{
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_FONTSIZE, (int)(ObjTitleFontSize));
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_COLOR, ObjTitleFontColor);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_BACK, 0);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_SELECTABLE, 1);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_SELECTED, 0);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_HIDDEN, 1);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_CORNER, ObjCorner);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_ANCHOR, ObjAnchor);
		
							ObjectSetString(ObjChartID, nametitle, OBJPROP_FONT, ObjTitleFont);
		
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_XDISTANCE, ObjX);
							ObjectSetInteger(ObjChartID, nametitle, OBJPROP_YDISTANCE, ObjY);
						}
					}
					else
					{
						ObjX = (int)ObjectGetInteger(ObjChartID, nametitle, OBJPROP_XDISTANCE);
						ObjY = (int)ObjectGetInteger(ObjChartID, nametitle, OBJPROP_YDISTANCE);
					}
		
					ObjectSetString(ObjChartID, nametitle, OBJPROP_TEXT, (string)Title);
		
					ObjY = (int)(ObjY + ObjTitleFontSize / 3);
				}
		
				//-- draw comment rows
				for (int i = 1; i <= 8; i++)
				{
					string text    = "";
					string textlbl = "";
		
					switch(i)
					{
						case 1:
						{
							if (Label1 != "")
							{
								textlbl = Label1;
								text    = FormatValueForPrinting(_Value1_(), FormatNumber1, FormatTime1);
							}
		
							break;
						}
						case 2:
						{
							if (Label2 != "")
							{
								textlbl = Label2;
								text    = FormatValueForPrinting(_Value2_(), FormatNumber2, FormatTime2);
							}
		
							break;
						}
						case 3:
						{
							if (Label3 != "")
							{
								textlbl = Label3;
								text    = FormatValueForPrinting(_Value3_(), FormatNumber3, FormatTime3);
							}
		
							break;
						}
						case 4:
						{
							if (Label4 != "")
							{
								textlbl = Label4;
								text    = FormatValueForPrinting(_Value4_(), FormatNumber4, FormatTime4);
							}
		
							break;
						}
						case 5:
						{
							if (Label5 != "")
							{
								textlbl = Label5;
								text    = FormatValueForPrinting(_Value5_(), FormatNumber5, FormatTime5);
							}
		
							break;
						}
						case 6:
						{
							if (Label6 != "")
							{
								textlbl = Label6;
								text    = FormatValueForPrinting(_Value6_(), FormatNumber6, FormatTime6);
							}
		
							break;
						}
						case 7:
						{
							if (Label7 != "")
							{
								textlbl = Label7;
								text    = FormatValueForPrinting(_Value7_(), FormatNumber7, FormatTime7);
							}
		
							break;
						}
						case 8:
						{
							if (Label8 != "")
							{
								textlbl = Label8;
								text    = FormatValueForPrinting(_Value8_(), FormatNumber8, FormatTime8);
							}
		
							break;
						}
				   }
		
					string name    = namebase + "_" + (string)i;
					string namelbl = name + "_l";
		
					if (textlbl == "")
					{
						if (!initialized)
						{
							//-- pre-delete
							ObjectDelete(ObjChartID, namelbl);
							ObjectDelete(ObjChartID, name);
						}
		
						continue;
					}
		
					//-- draw initial objects
					if (ObjectFind(ObjChartID, name) < 0)
					{
						if (textlbl == "")
						{
							continue;
						}
		
						if (ObjectCreate(ObjChartID, namelbl, OBJ_LABEL, subwindow, 0, 0, 0, 0))
						{
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_CORNER, ObjCorner);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_ANCHOR, ObjAnchor);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_BACK, 0);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_SELECTABLE, 0);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_SELECTED, 0);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_HIDDEN, 1);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_FONTSIZE, ObjLabelsFontSize);
							ObjectSetInteger(ObjChartID, namelbl, OBJPROP_COLOR, ObjLabelsFontColor);
							ObjectSetString(ObjChartID, namelbl, OBJPROP_FONT, ObjLabelsFont);
						}
						else
						{
							Print(__FUNCTION__, ": failed to create text object! Error code = ", GetLastError());
						}
		
						if (ObjectCreate(ObjChartID, name, OBJ_LABEL, subwindow, 0, 0, 0, 0))
						{
							ObjectSetInteger(ObjChartID, name, OBJPROP_CORNER, ObjCorner);
							ObjectSetInteger(ObjChartID, name, OBJPROP_ANCHOR, ObjAnchor);
							ObjectSetInteger(ObjChartID, name, OBJPROP_BACK, 0);
							ObjectSetInteger(ObjChartID, name, OBJPROP_SELECTABLE, 0);
							ObjectSetInteger(ObjChartID, name, OBJPROP_SELECTED, 0);
							ObjectSetInteger(ObjChartID, name, OBJPROP_HIDDEN, 1);
							ObjectSetInteger(ObjChartID, name, OBJPROP_FONTSIZE, ObjFontSize);
							ObjectSetInteger(ObjChartID, name, OBJPROP_COLOR, ObjFontColor);
							ObjectSetString(ObjChartID, name, OBJPROP_FONT, ObjFont);
						}
						else
						{
							Print(__FUNCTION__, ": failed to create text object! Error code = ", GetLastError());
						}
					}
					else
					{
						if (textlbl == "")
						{
							ObjectDelete(ObjChartID, namelbl);
							ObjectDelete(ObjChartID, name);
							continue;
						}
					}
		
					ObjY  = (int)(ObjY + ObjFontSize + ObjFontSize/2);
		
					//-- update label objects
					ObjectSetInteger(ObjChartID, namelbl, OBJPROP_XDISTANCE, ObjX);
					ObjectSetInteger(ObjChartID, namelbl, OBJPROP_YDISTANCE, ObjY);
					ObjectSetString(ObjChartID, namelbl, OBJPROP_TEXT, (string)textlbl);
		
					//-- update value objects
					int x        = 0;
					int xsizelbl = (int)ObjectGetInteger(ObjChartID, namelbl, OBJPROP_XSIZE);
		
					if (xsizelbl == 0) {
						//-- when the object is newly created, it returns 0 for XSIZE and YSIZE, so here we will trick it somehow
						xsizelbl = (int)(StringLen((string)textlbl) * ObjFontSize / 1.5 + ObjFontSize / 2);
					}
		
					x = ObjX + (xsizelbl + ObjFontSize/2);
		
					ObjectSetInteger(ObjChartID, name, OBJPROP_XDISTANCE, x);
					ObjectSetInteger(ObjChartID, name, OBJPROP_YDISTANCE, ObjY);
					ObjectSetString(ObjChartID, name, OBJPROP_TEXT, (string)text);
				}
				
				ChartRedraw();
			}
		
			initialized = true;
		}
		
		_callback_(1);
	}
};

// "Draw Button" model
template<typename T1,typename T2,typename T3,typename T4,typename T5,typename T6,typename _T6_,typename T7,typename T8,typename T9,typename T10,typename T11,typename T12,typename T13,typename T14,typename T15,typename T16,typename T17,typename T18,typename T19,typename T20,typename T21>
class MDL_ChartDrawButton: public BlockCalls
{
	public: /* Input Parameters *
	T1 ObjectPerBar;
	T2 ObjectUpdate;
	T3 ObjName;
	T4 ObjX;
	T5 ObjY;
	T6 ObjText; virtual _T6_ _ObjText_(){return(_T6_)0;}
	T7 ObjFont;
	T8 ObjFontSize;
	T9 ObjXsize;
	T10 ObjYsize;
	T11 ObjBgColor;
	T12 ObjBorderColor;
	T13 ObjCorner;
	T14 ObjState;
	T15 ObjColor;
	T16 ObjBack;
	T17 ObjSelectable;
	T18 ObjSelected;
	T19 ObjHidden;
	T20 ObjZorder;
	T21 ObjChartSubWindow;
	/* Static Parameters *
	int count;
	datetime time0;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDL_ChartDrawButton()
	{
		ObjectPerBar = (bool)false;
		ObjectUpdate = (bool)true;
		ObjName = (string)"";
		ObjX = (int)10;
		ObjY = (int)10;
		ObjFont = (string)"Arial";
		ObjFontSize = (int)10;
		ObjXsize = (int)100;
		ObjYsize = (int)20;
		ObjBgColor = (color)clrWhite;
		ObjBorderColor = (color)clrNONE;
		ObjCorner = (int)CORNER_LEFT_UPPER;
		ObjState = (bool)false;
		ObjColor = (color)clrDeepPink;
		ObjBack = (bool)false;
		ObjSelectable = (bool)false;
		ObjSelected = (bool)false;
		ObjHidden = (bool)false;
		ObjZorder = (int)0;
		ObjChartSubWindow = (string)"";
		/* Static Parameters (initial value) *
		count =  0;
		time0 =  0;
	}

	public: /* The main method *
	virtual void _execute_()
	{
		string ObjNamePrefix = "fxd_button_";
		long ObjChartID      = 0;
		int subwindow_id     = WindowFindVisible(ObjChartID, ObjChartSubWindow);
		
		if (subwindow_id >= 0)
		{
			string name       = "";
			string name_base  = "";
			bool get_new_name = false;
			bool do_update    = true;
		
			if (ObjectPerBar == true)
			{
				datetime time = iTime(Symbol(),0,1);
		
				if (time0 < time)
				{
					time0        = time;
					get_new_name = true;
				}
				else
				{
					if (ObjectUpdate == false) {do_update = false;}
				}
			}
			else
			{
				if (ObjectUpdate == false) {get_new_name = true;}
			}
		
			if (do_update)
			{
				if (ObjName != "") {name_base = ObjName;} else {name_base = ObjNamePrefix + __block_user_number + "_";}
		
				if (get_new_name == false)
				{
					name = name_base + IntegerToString(count);
				}
				else
				{
					while (true)
					{
						count++;
						name = name_base + IntegerToString(count);
		
						if (ObjectFind(ObjChartID,name) < 0) {break;}
					}
				}
		
				if (ObjName != "" && count == 0) {name = ObjName;}
		
				if (ObjectFind(ObjChartID,name) < 0 && !ObjectCreate(ObjChartID,name,OBJ_BUTTON,subwindow_id,0,0))
				{
					Print(__FUNCTION__,": failed to create button object! Error code = ",GetLastError());
				}
		
				ObjectSetInteger(ObjChartID,name,OBJPROP_XDISTANCE,ObjX);
				ObjectSetInteger(ObjChartID,name,OBJPROP_YDISTANCE,ObjY);
				ObjectSetInteger(ObjChartID,name,OBJPROP_XSIZE,ObjXsize);
				ObjectSetInteger(ObjChartID,name,OBJPROP_YSIZE,ObjYsize);
				ObjectSetInteger(ObjChartID,name,OBJPROP_BGCOLOR,ObjBgColor);
				ObjectSetInteger(ObjChartID,name,OBJPROP_BORDER_COLOR,ObjBorderColor);
				ObjectSetInteger(ObjChartID,name,OBJPROP_CORNER,ObjCorner);
				ObjectSetString(ObjChartID,name,OBJPROP_FONT,ObjFont);
				ObjectSetInteger(ObjChartID,name,OBJPROP_FONTSIZE,ObjFontSize);
				ObjectSetInteger(ObjChartID,name,OBJPROP_STATE,ObjState);
				ObjectSetString(ObjChartID,name,OBJPROP_TEXT,(string)_ObjText_());
		
				ObjectSetInteger(ObjChartID,name,OBJPROP_COLOR,ObjColor);
				ObjectSetInteger(ObjChartID,name,OBJPROP_BACK,ObjBack);
				ObjectSetInteger(ObjChartID,name,OBJPROP_SELECTABLE,ObjSelectable);
				ObjectSetInteger(ObjChartID,name,OBJPROP_SELECTED,ObjSelected);
				ObjectSetInteger(ObjChartID,name,OBJPROP_HIDDEN,ObjHidden);
				ObjectSetInteger(ObjChartID,name,OBJPROP_ZORDER,ObjZorder);
		
				ChartRedraw();
			}
		}
		
		_callback_(1);
	}
};


//------------------------------------------------------------------------------------------------------------------------

// "Candle" model
class MDLIC_candles_candles
{
	public: /* Input Parameters *
	string iOHLC;
	string ModeCandleFindBy;
	int CandleID;
	string TimeStamp;
	string Symbol;
	ENUM_TIMEFRAMES Period;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_candles_candles()
	{
		iOHLC = (string)"iClose";
		ModeCandleFindBy = (string)"id";
		CandleID = (int)0;
		TimeStamp = (string)"00:00";
		Symbol = (string)CurrentSymbol();
		Period = (ENUM_TIMEFRAMES)CurrentTimeframe();
	}

	public: /* The main method *
	double _execute_()
	{
		int digits = (int)SymbolInfoInteger(Symbol, SYMBOL_DIGITS);
		
		double O[];
		double H[];
		double L[];
		double C[]; 
		long cTickVolume[];
		long cRealVolume[];
		datetime T[];
		
		double retval = EMPTY_VALUE;
		
		// candle's id will change, so we don't want to mess with the variable CandleID;
		int cID = CandleID;
		
		if (ModeCandleFindBy == "time")
		{
			cID = iCandleID(Symbol, Period, StringToTimeEx(TimeStamp, "server"));
		}
		
		cID = cID + FXD_MORE_SHIFT;
		
		//-- the common levels ----------------------------------------------------
		if (iOHLC == "iOpen")
		{
			if (CopyOpen(Symbol,Period,cID,1,O) > -1) retval = O[0];
		}
		else if (iOHLC == "iHigh")
		{
			if (CopyHigh(Symbol,Period,cID,1,H) > -1) retval = H[0];
		}
		else if (iOHLC == "iLow")
		{
			if (CopyLow(Symbol,Period,cID,1,L) > -1) retval = L[0];
		}
		else if (iOHLC == "iClose")
		{
			if (CopyClose(Symbol,Period,cID,1,C) > -1) retval = C[0];
		}
		
		//-- non-price values  ----------------------------------------------------
		else if (iOHLC == "iVolume" || iOHLC == "iTickVolume")
		{
			if (CopyTickVolume(Symbol,Period,cID,1,cTickVolume) > -1) retval = (double)cTickVolume[0];
			
			return retval;
		}
		else if (iOHLC == "iRealVolume")
		{
			if (CopyRealVolume(Symbol,Period,cID,1,cRealVolume) > -1) retval = (double)cRealVolume[0];
			
			return retval;
		}
		else if (iOHLC == "iTime")
		{
			if (CopyTime(Symbol,Period,cID,1,T) > -1) retval = (double)T[0];
			
			return retval;
		}
		
		//-- simple calculations --------------------------------------------------
		else if (iOHLC == "iMedian")
		{
			if (
				   CopyLow(Symbol,Period,cID,1,L) > -1
				&& CopyHigh(Symbol,Period,cID,1,H) > -1
			)
			{
				retval = ((L[0]+H[0])/2);
			}
		}
		else if (iOHLC == "iTypical")
		{
			if (
				   CopyLow(Symbol,Period,cID,1,L) > -1
				&& CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
			)
			{
				retval = ((L[0]+H[0]+C[0])/3);
			}
		}
		else if (iOHLC == "iAverage")
		{
			if (
				   CopyLow(Symbol,Period,cID,1,L) > -1
				&& CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
			)
			{
				retval = ((L[0]+H[0]+C[0]+C[0])/4);
			}
		}
		
		//-- more complex levels --------------------------------------------------
		else if (iOHLC=="iTotal")
		{
			if (
				   CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyLow(Symbol,Period,cID,1,L) > -1
			)
			{
				retval = toPips(MathAbs(H[0]-L[0]),Symbol);
			}
		}
		else if (iOHLC == "iBody")
		{
			if (
				   CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
			)
			{
				retval = toPips(MathAbs(C[0]-O[0]),Symbol);
			}
		}
		else if (iOHLC == "iUpperWick")
		{
			if (
				   CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& CopyLow(Symbol,Period,cID,1,L) > -1
			)
			{
				retval = (C[0] > O[0]) ? toPips(MathAbs(H[0]-C[0]),Symbol) : toPips(MathAbs(H[0]-O[0]),Symbol);
			}
		}
		else if (iOHLC == "iBottomWick")
		{
			if (
				   CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& CopyLow(Symbol,Period,cID,1,L) > -1
			)
			{
				retval = (C[0] > O[0]) ? toPips(MathAbs(O[0]-L[0]),Symbol) : toPips(MathAbs(C[0]-L[0]),Symbol);
			}
		}
		else if (iOHLC == "iGap")
		{
			if (
				   CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID+1,1,C) > -1
			)
			{
				retval = toPips(MathAbs(O[0]-C[0]),Symbol);
			}
		}
		else if (iOHLC == "iBullTotal")
		{
			if (
				   CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyLow(Symbol,Period,cID,1,L) > -1
				&& C[0] > O[0]
			)
			{
				retval = toPips((H[0]-L[0]),Symbol);
			}
		}
		else if (iOHLC == "iBullBody")
		{
			if (
				   CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& C[0] > O[0]
			)
			{
				retval = toPips((C[0]-O[0]),Symbol);
			}
		}
		else if (iOHLC == "iBullUpperWick")
		{
			if (
				   CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& C[0] > O[0]
			)
			{
				retval = toPips((H[0]-C[0]),Symbol);
			}
		}
		else if (iOHLC == "iBullBottomWick")
		{
			if (
				   CopyLow(Symbol,Period,cID,1,L) > -1
				&& CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& C[0] > O[0]
			)
			{
				retval = toPips((O[0]-L[0]),Symbol);
			}
		}
		else if (iOHLC == "iBearTotal")
		{
			if (
				   CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyLow(Symbol,Period,cID,1,L) > -1
				&& C[0] < O[0]
			)
			{
				retval = toPips((H[0]-L[0]),Symbol);
			}
		}
		else if (iOHLC == "iBearBody")
		{
			if (
				   CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& C[0] < O[0]
			)
			{
				retval = toPips((O[0]-C[0]),Symbol);
			}
		}
		else if (iOHLC == "iBearUpperWick")
		{
			if (
				   CopyHigh(Symbol,Period,cID,1,H) > -1
				&& CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& C[0] < O[0]
			)
			{
				retval = toPips((H[0]-O[0]),Symbol);
			}
		}
		else if (iOHLC == "iBearBottomWick")
		{
			if (
				   CopyLow(Symbol,Period,cID,1,L) > -1
				&& CopyOpen(Symbol,Period,cID,1,O) > -1
				&& CopyClose(Symbol,Period,cID,1,C) > -1
				&& C[0] < O[0]
			)
			{
				retval = toPips((C[0]-L[0]),Symbol);
			}
		}
		
		return NormalizeDouble(retval, digits);
	}
};

// "Numeric" model
class MDLIC_value_value
{
	public: /* Input Parameters *
	double Value;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_value_value()
	{
		Value = (double)1.0;
	}

	public: /* The main method *
	double _execute_()
	{
		return Value;
	}
};

// "Time" model
class MDLIC_value_time
{
	public: /* Input Parameters *
	int ModeTime;
	int TimeSource;
	string TimeStamp;
	int TimeCandleID;
	string TimeMarket;
	ENUM_TIMEFRAMES TimeCandleTimeframe;
	int TimeComponentYear;
	int TimeComponentMonth;
	double TimeComponentDay;
	double TimeComponentHour;
	double TimeComponentMinute;
	int TimeComponentSecond;
	int ModeTimeShift;
	int TimeShiftYears;
	int TimeShiftMonths;
	int TimeShiftWeeks;
	double TimeShiftDays;
	double TimeShiftHours;
	double TimeShiftMinutes;
	int TimeShiftSeconds;
	bool TimeSkipWeekdays;
	/* Static Parameters *
	datetime retval;
	datetime retval0;
	int ModeTime0;
	int smodeshift;
	int years0;
	int months0;
	datetime Time[];
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_value_time()
	{
		ModeTime = (int)0;
		TimeSource = (int)0;
		TimeStamp = (string)"00:00";
		TimeCandleID = (int)1;
		TimeMarket = (string)"";
		TimeCandleTimeframe = (ENUM_TIMEFRAMES)0;
		TimeComponentYear = (int)0;
		TimeComponentMonth = (int)0;
		TimeComponentDay = (double)0.0;
		TimeComponentHour = (double)12.0;
		TimeComponentMinute = (double)0.0;
		TimeComponentSecond = (int)0;
		ModeTimeShift = (int)0;
		TimeShiftYears = (int)0;
		TimeShiftMonths = (int)0;
		TimeShiftWeeks = (int)0;
		TimeShiftDays = (double)0.0;
		TimeShiftHours = (double)0.0;
		TimeShiftMinutes = (double)0.0;
		TimeShiftSeconds = (int)0;
		TimeSkipWeekdays = (bool)false;
		/* Static Parameters (initial value) *
		retval =  0;
		retval0 =  0;
		ModeTime0 =  0;
		smodeshift =  0;
		years0 =  0;
		months0 =  0;
	}

	public: /* The main method *
	datetime _execute_()
	{
		// this is static for speed reasons
		
		if (TimeMarket == "") TimeMarket = Symbol();
		
		if (ModeTime == 0)
		{
			     if (TimeSource == 0) {retval = TimeCurrent();}
			else if (TimeSource == 1) {retval = TimeLocal() + (TimeCurrent() - TimeLocal());}
			else if (TimeSource == 2) {retval = TimeGMT() + (TimeCurrent() - TimeGMT());}
		}
		else if (ModeTime == 1)
		{
			retval  = StringToTime(TimeStamp);
			retval0 = retval;
		}
		else if (ModeTime==2)
		{
			retval = TimeFromComponents(TimeSource, TimeComponentYear, TimeComponentMonth, TimeComponentDay, TimeComponentHour, TimeComponentMinute, TimeComponentSecond);
		}
		else if (ModeTime == 3)
		{
			ArraySetAsSeries(Time,true);
			CopyTime(TimeMarket,TimeCandleTimeframe,TimeCandleID,1,Time);
			retval = Time[0];
		}
		
		if (ModeTimeShift > 0)
		{
			int sh = 1;
		
			if (ModeTimeShift == 1) {sh = -1;}
		
			if (
				   ModeTimeShift != smodeshift
				|| TimeShiftYears != years0
				|| TimeShiftMonths != months0
			)
			{
				years0  = TimeShiftYears;
				months0 = TimeShiftMonths;
		
				if (TimeShiftYears > 0 || TimeShiftMonths > 0)
				{
					int year = 0, month = 0, week = 0, day = 0, hour = 0, minute = 0, second = 0;
		
					if (ModeTime == 3)
					{
						year   = TimeComponentYear;
						month  = TimeComponentYear;
						day    = (int)MathFloor(TimeComponentDay);
						hour   = (int)(MathFloor(TimeComponentHour) + (24 * (TimeComponentDay - MathFloor(TimeComponentDay))));
						minute = (int)(MathFloor(TimeComponentMinute) + (60 * (TimeComponentHour - MathFloor(TimeComponentHour))));
						second = (int)(TimeComponentSecond + (60 * (TimeComponentMinute - MathFloor(TimeComponentMinute))));
					}
					else {
						year   = TimeYear(retval);
						month  = TimeMonth(retval);
						day    = TimeDay(retval);
						hour   = TimeHour(retval);
						minute = TimeMinute(retval);
						second = TimeSeconds(retval);
					}
		
					year  = year + TimeShiftYears * sh;
					month = month + TimeShiftMonths * sh;
		
					     if (month < 0) {month = 12 - month;}
					else if (month > 12) {month = month - 12;}
		
					retval = StringToTime(IntegerToString(year)+"."+IntegerToString(month)+"."+IntegerToString(day)+" "+IntegerToString(hour)+":"+IntegerToString(minute)+":"+IntegerToString(second));
				}
			}
		
			retval = retval + (sh * ((604800 * TimeShiftWeeks) + SecondsFromComponents(TimeShiftDays, TimeShiftHours, TimeShiftMinutes, TimeShiftSeconds)));
		
			if (TimeSkipWeekdays == true)
			{
				int weekday = TimeDayOfWeek(retval);
		
				if (sh > 0) { // forward
					     if (weekday == 0) {retval = retval + 86400;}
					else if (weekday == 6) {retval = retval + 172800;}
				}
				else if (sh < 0) { // back
					     if (weekday == 0) {retval = retval - 172800;}
					else if (weekday == 6) {retval = retval - 86400;}
				}
			}
		}
		
		smodeshift = ModeTimeShift;
		ModeTime0  = ModeTime;
		
		return (datetime)retval;
	}
};

// "Parabolic SAR" model
class MDLIC_indicators_iSAR
{
	public: /* Input Parameters *
	double Step;
	double Maximum;
	string Symbol;
	ENUM_TIMEFRAMES Period;
	int Shift;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_indicators_iSAR()
	{
		Step = (double)0.02;
		Maximum = (double)0.2;
		Symbol = (string)CurrentSymbol();
		Period = (ENUM_TIMEFRAMES)CurrentTimeframe();
		Shift = (int)0;
	}

	public: /* The main method *
	double _execute_()
	{
		return iSAR(Symbol, Period, Step, Maximum, Shift + FXD_MORE_SHIFT);
	}
};

// "Pips" model
class MDLIC_value_points
{
	public: /* Input Parameters *
	double Value;
	int ModeValue;
	string Symbol;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_value_points()
	{
		Value = (double)10.0;
		ModeValue = (int)1;
		Symbol = (string)CurrentSymbol();
	}

	public: /* The main method *
	double _execute_()
	{
		double retval = 0;
		
		     if (ModeValue == 0) {retval = Value;}
		else if (ModeValue == 1) {retval = Value*SymbolInfoDouble(Symbol,SYMBOL_POINT)*PipValue(Symbol);}
		
		return retval;
	}
};

// "Boolean" model
class MDLIC_boolean_boolean
{
	public: /* Input Parameters *
	bool Boolean;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_boolean_boolean()
	{
		Boolean = (bool)true;
	}

	public: /* The main method *
	bool _execute_()
	{
		return Boolean;
	}
};

// "Name: Broker" model
class MDLIC_account_AccountCompany
{
	public: /* Input Parameters *
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_account_AccountCompany()
	{
	}

	public: /* The main method *
	string _execute_()
	{
		return AccountInfoString(ACCOUNT_COMPANY);
	}
};

// "Name: Server" model
class MDLIC_account_AccountServer
{
	public: /* Input Parameters *
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_account_AccountServer()
	{
	}

	public: /* The main method *
	string _execute_()
	{
		return AccountInfoString(ACCOUNT_SERVER);
	}
};

// "Balance" model
class MDLIC_account_AccountBalance
{
	public: /* Input Parameters *
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_account_AccountBalance()
	{
	}

	public: /* The main method *
	double _execute_()
	{
		return NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 2);
	}
};

// "Profit (Equity - Balance)" model
class MDLIC_account_AccountProfit
{
	public: /* Input Parameters *
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_account_AccountProfit()
	{
	}

	public: /* The main method *
	double _execute_()
	{
		return NormalizeDouble(AccountInfoDouble(ACCOUNT_PROFIT), 2);
	}
};

// "Text" model
class MDLIC_text_text
{
	public: /* Input Parameters *
	string Text;
	virtual void _callback_(int r) {return;}

	public: /* Constructor *
	MDLIC_text_text()
	{
		Text = (string)"sample text";
	}

	public: /* The main method *
	string _execute_()
	{
		return Text;
	}
};


//------------------------------------------------------------------------------------------------------------------------

// Block 1 (Impulse Up)
class Block0: public MDL_ImpulseUp<string,int,double,double,int,string,ENUM_TIMEFRAMES>
{

	public: /* Constructor *
	Block0() {
		__block_number = 0;
		__block_user_number = "1";
		_beforeExecuteEnabled = true;

		// Fill the list of outbound blocks
		int ___outbound_blocks[2] = {2,4};
		ArrayCopy(__outbound_blocks, ___outbound_blocks);
		// Block input parameters
		SignalType = "once";
	}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
		if (value == 0) {
			_blocks_[4].run(0);
		}
		else if (value == 1) {
			_blocks_[2].run(0);
		}
	}

	virtual void _beforeExecute_()
	{

		QuietBarsCount = (int)c::Bar_Count;
		QuietBarsMinRange = (double)c::Bar_Size;
		ImpulseStrength = (double)c::STR;
		Symbol = (string)CurrentSymbol();
		Period = (ENUM_TIMEFRAMES)CurrentTimeframe();
	}
};

// Block 3 (Buy pending orders in grid)
class Block1: public MDL_GridPendingBuys2<string,string,int,string,MDLIC_candles_candles,double,double,double,double,string,double,double,double,double,double,MDLIC_value_value,double,double,double,double,string,double,double,MDLIC_value_value,double,MDLIC_value_value,double,MDLIC_value_value,double,string,double,double,MDLIC_value_value,double,MDLIC_value_value,double,MDLIC_value_value,double,double,double,double,double,string,int,int,int,MDLIC_value_time,datetime,ulong,string,color>
{

	public: /* Constructor *
	Block1() {
		__block_number = 1;
		__block_user_number = "3";
		_beforeExecuteEnabled = true;

		// IC input parameters
		fGridStart.iOHLC = "iOpen";
		fGridStart.TimeStamp = "";
		dVolumeSize.Value = 0.1;
		dpStopLoss.Value = 100.0;
		ddStopLoss.Value = 0.01;
		dpTakeProfit.Value = 100.0;
		ddTakeProfit.Value = 0.01;
		dExp.ModeTimeShift = 2;
		dExp.TimeShiftDays = 1.0;
		dExp.TimeSkipWeekdays = true;
		// Block input parameters
		Group = "1";
		GridOrdersCount = 1;
		GridStart = "mid";
		VolumeMode = "balance";
		MyComment = "HFT Scalper";
	}

	public: /* Custom methods *
	virtual double _fGridStart_() {
		fGridStart.Symbol = CurrentSymbol();
		fGridStart.Period = CurrentTimeframe();

		return fGridStart._execute_();
	}
	virtual double _dVolumeSize_() {return dVolumeSize._execute_();}
	virtual double _dlStopLoss_() {return dlStopLoss._execute_();}
	virtual double _dpStopLoss_() {return dpStopLoss._execute_();}
	virtual double _ddStopLoss_() {return ddStopLoss._execute_();}
	virtual double _dlTakeProfit_() {return dlTakeProfit._execute_();}
	virtual double _dpTakeProfit_() {return dpTakeProfit._execute_();}
	virtual double _ddTakeProfit_() {return ddTakeProfit._execute_();}
	virtual datetime _dExp_() {return dExp._execute_();}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
	}

	virtual void _beforeExecute_()
	{

		Symbol = (string)CurrentSymbol();
		GridSize = (double)c::Gridsize;
		VolumePercent = (double)c::Autolots;
		StopLossPips = (double)c::SL;
		TakeProfitPips = (double)c::TP;
		ArrowColorBuy = (color)clrBlue;
	}
};

// Block 4 (Sell pending orders in grid)
class Block2: public MDL_GridPendingSells2<string,string,int,string,MDLIC_candles_candles,double,double,double,double,string,double,double,double,double,double,MDLIC_value_value,double,double,double,double,string,double,double,MDLIC_value_value,double,MDLIC_value_value,double,MDLIC_value_value,double,string,double,double,MDLIC_value_value,double,MDLIC_value_value,double,MDLIC_value_value,double,double,double,double,double,string,int,int,int,MDLIC_value_time,datetime,ulong,string,color>
{

	public: /* Constructor *
	Block2() {
		__block_number = 2;
		__block_user_number = "4";
		_beforeExecuteEnabled = true;

		// IC input parameters
		fGridStart.iOHLC = "iOpen";
		fGridStart.TimeStamp = "";
		dVolumeSize.Value = 0.1;
		dpStopLoss.Value = 100.0;
		ddStopLoss.Value = 0.01;
		dpTakeProfit.Value = 100.0;
		ddTakeProfit.Value = 0.01;
		dExp.ModeTimeShift = 2;
		dExp.TimeShiftDays = 1.0;
		dExp.TimeSkipWeekdays = true;
		// Block input parameters
		Group = "1";
		GridOrdersCount = 1;
		GridStart = "mid";
		VolumeMode = "balance";
		MyComment = "HFT Scalper";
	}

	public: /* Custom methods *
	virtual double _fGridStart_() {
		fGridStart.Symbol = CurrentSymbol();
		fGridStart.Period = CurrentTimeframe();

		return fGridStart._execute_();
	}
	virtual double _dVolumeSize_() {return dVolumeSize._execute_();}
	virtual double _dlStopLoss_() {return dlStopLoss._execute_();}
	virtual double _dpStopLoss_() {return dpStopLoss._execute_();}
	virtual double _ddStopLoss_() {return ddStopLoss._execute_();}
	virtual double _dlTakeProfit_() {return dlTakeProfit._execute_();}
	virtual double _dpTakeProfit_() {return dpTakeProfit._execute_();}
	virtual double _ddTakeProfit_() {return ddTakeProfit._execute_();}
	virtual datetime _dExp_() {return dExp._execute_();}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
	}

	virtual void _beforeExecute_()
	{

		Symbol = (string)CurrentSymbol();
		GridSize = (double)c::Gridsize;
		VolumePercent = (double)c::Autolots;
		StopLossPips = (double)c::SL;
		TakeProfitPips = (double)c::TP;
		ArrowColorSell = (color)clrRed;
	}
};

// Block 5 (Impulse Down)
class Block3: public MDL_ImpulseDn<string,int,double,double,int,string,ENUM_TIMEFRAMES>
{

	public: /* Constructor *
	Block3() {
		__block_number = 3;
		__block_user_number = "5";
		_beforeExecuteEnabled = true;

		// Fill the list of outbound blocks
		int ___outbound_blocks[2] = {1,4};
		ArrayCopy(__outbound_blocks, ___outbound_blocks);
		// Block input parameters
		SignalType = "once";
	}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
		if (value == 0) {
			_blocks_[4].run(3);
		}
		else if (value == 1) {
			_blocks_[1].run(3);
		}
	}

	virtual void _beforeExecute_()
	{

		QuietBarsCount = (int)c::Bar_Count;
		QuietBarsMinRange = (double)c::Bar_Size;
		ImpulseStrength = (double)c::STR;
		Symbol = (string)CurrentSymbol();
		Period = (ENUM_TIMEFRAMES)CurrentTimeframe();
	}
};

// Block 6 (Trailing stop (group of trades))
class Block4: public MDL_TrailingStopAvgPrice<string,string,string,string,int,string,double,MDLIC_value_value,double,double,string,double,double,string,double,double,MDLIC_value_value,double,bool,string,double,double,MDLIC_value_value,double,color>
{

	public: /* Constructor *
	Block4() {
		__block_number = 4;
		__block_user_number = "6";
		_beforeExecuteEnabled = true;

		// IC input parameters
		ftStop.Value = 40.0;
		ftStart.Value = 0.0;
		ftTP.Value = 40.0;
		// Block input parameters
		Group = "1";
		TrailingStartMode = "fixed";
		resetOnTrade = false;
	}

	public: /* Custom methods *
	virtual double _ftStop_() {return ftStop._execute_();}
	virtual double _ftStart_() {return ftStart._execute_();}
	virtual double _ftTP_() {return ftTP._execute_();}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
	}

	virtual void _beforeExecute_()
	{

		Symbol = (string)CurrentSymbol();
		TrailWhat = (int)c::Use_Trailing_Stops;
		tStopPips = (double)c::Stops;
		tStepPips = (double)c::Steps;
		tStartPips = (double)c::Starts;
		LevelColor = (color)clrDeepPink;
	}
};

// Block 7 (Trailing stop (each trade))
class Block5: public MDL_TrailingStop2<string,string,string,string,string,int,int,string,double,double,string,double,double,MDLIC_indicators_iSAR,double,MDLIC_value_points,double,string,double,double,string,double,double,double,double,MDLIC_value_value,double,MDLIC_value_value,double,string,double,double,MDLIC_value_value,double,color>
{

	public: /* Constructor *
	Block5() {
		__block_number = 5;
		__block_user_number = "7";
		_beforeExecuteEnabled = true;

		// IC input parameters
		ftDigits.Value = 40.0;
		ftStart.Value = 0.0;
		ftStartFraction.Value = 0.001;
		ftTP.Value = 0.0;
		// Block input parameters
		Group = "1";
		TrailingReferencePrice = 1;
		TrailingStartMode = "fixed";
	}

	public: /* Custom methods *
	virtual double _ftStop_() {
		ftStop.Symbol = CurrentSymbol();
		ftStop.Period = CurrentTimeframe();

		return ftStop._execute_();
	}
	virtual double _ftDigits_() {
		ftDigits.Symbol = CurrentSymbol();

		return ftDigits._execute_();
	}
	virtual double _ftStart_() {return ftStart._execute_();}
	virtual double _ftStartFraction_() {return ftStartFraction._execute_();}
	virtual double _ftTP_() {return ftTP._execute_();}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
	}

	virtual void _beforeExecute_()
	{

		Symbol = (string)CurrentSymbol();
		TrailWhat = (int)c::Use_Trailing_Stops;
		tStopPips = (double)c::Stops;
		tStepPips = (double)c::Steps;
		tStartPips = (double)c::Starts;
		LevelColor = (color)clrDeepPink;
	}
};

// Block 8 (Trailing pending orders)
class Block6: public MDL_TrailingPendingOrders<string,string,string,string,string,string,string,double,MDLIC_value_value,double,MDLIC_value_value,double,MDLIC_value_value,double,double>
{

	public: /* Constructor *
	Block6() {
		__block_number = 6;
		__block_user_number = "8";
		_beforeExecuteEnabled = true;

		// IC input parameters
		dtDistancePips.Value = 30.0;
		dtDistanceDigits.Value = 0.0030;
		// Block input parameters
		Group = "1";
		tStepPips = 0.10;
	}

	public: /* Custom methods *
	virtual double _dtDistancePips_() {return dtDistancePips._execute_();}
	virtual double _dtDistanceDigits_() {return dtDistanceDigits._execute_();}
	virtual double _dtLevel_() {return dtLevel._execute_();}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
	}

	virtual void _beforeExecute_()
	{

		Symbol = (string)CurrentSymbol();
		tDistancePips = (double)c::Trail_Pen;
	}
};

// Block 9 (No pending order)
class Block7: public MDL_NoPendingOrders<string,string,string,string,string,string>
{

	public: /* Constructor *
	Block7() {
		__block_number = 7;
		__block_user_number = "9";
		_beforeExecuteEnabled = true;

		// Fill the list of outbound blocks
		int ___outbound_blocks[4] = {0,3,5,6};
		ArrayCopy(__outbound_blocks, ___outbound_blocks);
		// Block input parameters
		Group = "1";
	}

	public: /* Callback & Run *
	virtual void _callback_(int value) {
		if (value == 0) {
			_blocks_[5].run(7);
			_blocks_[6].run(7);
		}
		else if (value == 1) {
			_blocks_[0].run(7);
			_blocks_[3].run(7);
		}
	}

	virtual void _beforeExecute_()
	{

		Symbol = (string)CurrentSymbol();
	}
};

// Block 19 (Condition)
class Block8: public MDL_Condition<MDLIC_boolean_boolean,bool,string,MDLIC_boolean_boolean,bool,int>
{

	public: /* Constructor *
	Block8() {
		__block_number = 8;
		__block_user_number = "19";


		// Fill the list of outbound blocks
		int ___outbound_blocks[1] = {7};
		ArrayCopy(__outbound_blocks, ___outbound_blocks);
		// Block input parameters
		compare = "==";
	}

	public: /* Custom methods *
	virtual bool _Lo_() {return Lo._execute_();}
	virtual bool _Ro_() {
		Ro.Boolean = c::Limits_Only;

		return Ro._execute_();
	}

	public: /* Callback & Run */
	
//+------------------------------------------------------------------+