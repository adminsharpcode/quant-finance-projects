//+------------------------------------------------------------------+
//|                                            mn RiskRewardLine.mq4 |
//+------------------------------------------------------------------+
#property copyright "Mn"
#property indicator_chart_window

extern color mCol = Red, mCol2 = Blue, mCol3 = LimeGreen;
extern int mWid = 2, mRiskPcnt = 50, mProfPcnt = 100;

//+------------------------------------------------------------------+
int init()
  {
      ObjectCreate("mMyRRLine", OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet("mMyRRLine", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("mMyRRLine", OBJPROP_PRICE1, Low[1]);
      ObjectSet("mMyRRLine", OBJPROP_PRICE2, High[10]);
      ObjectSet("mMyRRLine", OBJPROP_TIME1, Time[10]);
      ObjectSet("mMyRRLine", OBJPROP_TIME2, Time[0]);
      ObjectSet("mMyRRLine", OBJPROP_WIDTH, mWid);
      ObjectSet("mMyRRLine", OBJPROP_COLOR, mCol);
      ObjectSet("mMyRRLine", OBJPROP_RAY, false);

      ObjectCreate("mMyRisk", OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet("mMyRisk", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("mMyRisk", OBJPROP_PRICE1, Close[1]);
      ObjectSet("mMyRisk", OBJPROP_PRICE2, Close[10]);
      ObjectSet("mMyRisk", OBJPROP_TIME1, Time[30]);
      ObjectSet("mMyRisk", OBJPROP_TIME2, Time[20]);
      ObjectSet("mMyRisk", OBJPROP_WIDTH, mWid);
      ObjectSet("mMyRisk", OBJPROP_COLOR, mCol2);
      
      ObjectCreate("mMyProf", OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet("mMyProf", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("mMyProf", OBJPROP_PRICE1, Close[1]);
      ObjectSet("mMyProf", OBJPROP_PRICE2, Close[10]);
      ObjectSet("mMyProf", OBJPROP_TIME1, Time[30]);
      ObjectSet("mMyProf", OBJPROP_TIME2, Time[20]);
      ObjectSet("mMyProf", OBJPROP_WIDTH, mWid);
      ObjectSet("mMyProf", OBJPROP_COLOR, mCol3);
      
   return(0);
  }

//+------------------------------------------------------------------+
int deinit()
  {
   ObjectDelete("mMyRRLine");
   ObjectDelete("mMyRisk");
   ObjectDelete("mMyProf");
   
   return(0);
  }

//+------------------------------------------------------------------+
int start()
  {
   double mLaterTime, mEarlierTime, m1stPr, m2ndPr, mLaterTime2, mEarlierTime2, m1stPr2, m2ndPr2,
          mRange, mPrice, mPrice1, mPrice2, mPrice12;
   bool mUp;
   
   mLaterTime = ObjectGet("mMyRRLine", 2); mEarlierTime = ObjectGet("mMyRRLine", 0);
   m1stPr = ObjectGet("mMyRRLine", 1); m2ndPr = ObjectGet("mMyRRLine", 3);
   mRange = MathMax(m1stPr, m2ndPr) - MathMin(m1stPr, m2ndPr);
   if(mLaterTime > mEarlierTime)
     {
      mPrice = m2ndPr;
      if(m2ndPr > m1stPr)
        mUp = true;
      else
        mUp = false; 
     }
   else
     {
      mPrice = m1stPr;
      if(m2ndPr < m1stPr)
        mUp = true;
      else
        mUp = false; 
     }
     
      if(mUp)
       {
        ObjectSet("mMyRisk", OBJPROP_PRICE1, mPrice - mRange * mRiskPcnt /100);
        ObjectSet("mMyRisk", OBJPROP_PRICE2, mPrice - mRange * mRiskPcnt /100);
       }
      else
       {
        ObjectSet("mMyRisk", OBJPROP_PRICE1, mPrice + mRange * mRiskPcnt /100);
        ObjectSet("mMyRisk", OBJPROP_PRICE2, mPrice + mRange * mRiskPcnt /100);
       }
       
      ObjectSet("mMyRisk", OBJPROP_TIME1, MathMin(mLaterTime, mEarlierTime));
      ObjectSet("mMyRisk", OBJPROP_TIME2, Time[0]);

      if(mUp)
       {
        ObjectSet("mMyProf", OBJPROP_PRICE1, mPrice + mRange * mProfPcnt /100);
        ObjectSet("mMyProf", OBJPROP_PRICE2, mPrice + mRange * mProfPcnt /100);
       }
      else
       {
        ObjectSet("mMyProf", OBJPROP_PRICE1, mPrice - mRange * mProfPcnt /100);
        ObjectSet("mMyProf", OBJPROP_PRICE2, mPrice - mRange * mProfPcnt /100);
       }
      ObjectSet("mMyProf", OBJPROP_TIME1, MathMin(mLaterTime, mEarlierTime));
      ObjectSet("mMyProf", OBJPROP_TIME2, Time[0]);


   return(0);
  }
//+------------------------------------------------------------------+