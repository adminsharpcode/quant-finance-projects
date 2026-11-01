//+------------------------------------------------------------------+
//|                     MAB_TD_D-WaveUp                              |
//|                        v1.0                                      |
//|                                                                  |
//|   This indicator is a D-Wave indicator as described in Perl's    |
//| book, "DeMark Indicators."  It is basically an objective Elliot  |
//| Wave.  This portion of the indicator is only the up wave.        |
//|                                                                  |         
//+------------------------------------------------------------------+
#property indicator_chart_window

//Wave formatting:
extern int  TrendSize=1;//width of line
extern int  LineType=0; //type of line
extern color Upclr=Blue; //color of up wave
extern color BrkLine=Green; //support and resistance lines
extern color ProjLine=Yellow; //projection lines
extern double ProjPrice1 = 1.618;
extern double ProjPrice2 = 2.618;
extern int  TrendCycle = 0; //0=down and up, 1=up, 2=down

//Text formatting:
extern int  NbrSize=8;  //size of wave marker
extern int Space=100;   //position of marker

//misc
extern int  showBars=700; // how far back do you want the wave to start...note:  the less bars the smaller the wave.

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   for(int cnt=showBars;cnt>=0;cnt--)   
      {
      ObjectsDeleteAll();
      }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {
  int wCounterUp;
  double val1, val2;
  int pos0up, pos1up, pos2up, pos3up, pos4up, pos5up, pos6up, pos7up, pos8up;
  int tfm=Space*Point;
  double WaveUp3Proj1, WaveUp3Proj2, WaveUp5Proj1, WaveUp5Proj2;
  
  if (showBars==0) showBars=Bars;
  for(int cnt=showBars;cnt>=0;cnt--) 
   {
//+------------------------------------------------------------------+
//| Up Wave Criteria                                                 |
//+------------------------------------------------------------------+  
   switch(wCounterUp)
      {
      case 0://Start of the Wave
         val1=Close[iLowest(NULL,0,MODE_CLOSE,21,cnt)];
         val2=Close[iHighest(NULL,0,MODE_CLOSE,13,cnt)];
         if(Close[cnt]==val1)
            {
            if(pos0up!=0 && Close[cnt]<Close[pos0up])pos0up=cnt;
            else if(pos0up==0)pos0up=cnt;
            }
         if(Close[cnt]==val2 && pos0up!=0)
            {
            ObjectCreate("WaveUp0_"+pos0up,OBJ_TEXT,0,Time[pos0up],Low[pos0up]-tfm);
            ObjectSetText("WaveUp0_"+pos0up,""+wCounterUp,NbrSize,"Arial",Upclr);
            wCounterUp++;
            }
         break;
      
      case 1://Wave 1 is created
         val1=Close[iHighest(NULL,0,MODE_CLOSE,13,cnt)];
         val2=Close[iLowest(NULL,0,MODE_CLOSE,7,cnt)];
         if(Close[cnt]==val1)
            {
            if(pos1up==0)
               {
               pos1up=cnt;
               ObjectCreate("WaveUp1_"+pos1up,OBJ_TEXT,0,Time[pos1up],High[pos1up]+tfm);
               ObjectSetText("WaveUp1_"+pos1up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp1_"+pos1up,OBJ_TREND,0,Time[pos1up],Close[pos1up],Time[pos0up],Close[pos0up]);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_RAY,false);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_STYLE,LineType);
               }
            else if(pos1up!=0 && Close[cnt]>Close[pos1up])
               {
               ObjectDelete("WaveUp1_"+pos1up);
               ObjectDelete("TrendUp1_"+pos1up);
            
               pos1up=cnt;
            
               ObjectCreate("WaveUp1_"+pos1up,OBJ_TEXT,0,Time[pos1up],High[pos1up]+tfm);
               ObjectSetText("WaveUp1_"+pos1up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp1_"+pos1up,OBJ_TREND,0,Time[pos1up],Close[pos1up],Time[pos0up],Close[pos0up]);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_RAY,false);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp1_"+pos1up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos1up!=0)
            {
            //Creating of the Projection lines
            ObjectCreate("WvUp1Brk"+pos1up,OBJ_TREND,0,Time[pos1up+1],Close[pos1up],Time[cnt],Close[pos1up]);
            ObjectSet("WvUp1Brk"+pos1up,OBJPROP_COLOR,BrkLine);
            ObjectSet("WvUp1Brk"+pos1up,OBJPROP_STYLE,STYLE_DASH);
            ObjectSet("WvUp1Brk"+pos1up,OBJPROP_RAY,true);
            
            WaveUp3Proj1=NormalizeDouble(Close[pos0up]+((Close[pos1up]-Close[pos0up])*ProjPrice1),Digits);
            WaveUp3Proj2=NormalizeDouble(Close[pos0up]+((Close[pos1up]-Close[pos0up])*ProjPrice2),Digits);
            
            ObjectCreate("WvUp3Proj1_"+pos1up,OBJ_TREND,0,Time[pos1up+1],WaveUp3Proj1,Time[cnt],WaveUp3Proj1);
            ObjectSet("WvUp3Proj1_"+pos1up,OBJPROP_COLOR,ProjLine);
            ObjectSet("WvUp3Proj1_"+pos1up,OBJPROP_STYLE,STYLE_DASH);
            ObjectSet("WvUp3Proj1_"+pos1up,OBJPROP_RAY,true);
            
            ObjectCreate("WvUp3Proj2_"+pos1up,OBJ_TREND,0,Time[pos1up+1],WaveUp3Proj2,Time[cnt],WaveUp3Proj2);
            ObjectSet("WvUp3Proj2_"+pos1up,OBJPROP_COLOR,ProjLine);
            ObjectSet("WvUp3Proj2_"+pos1up,OBJPROP_STYLE,STYLE_DASH);
            ObjectSet("WvUp3Proj2_"+pos1up,OBJPROP_RAY,true);
            wCounterUp++;
            }
         break;
      
      case 2://Wave 2 is created
         val1=Close[iLowest(NULL,0,MODE_CLOSE,9,cnt)];
         val2=Close[iHighest(NULL,0,MODE_CLOSE,21,cnt)];
         
         if(Close[cnt]>Close[pos1up])
            {
            ObjectDelete("WaveUp1_"+pos1up);
            ObjectDelete("TrendUp1_"+pos1up);
            ObjectDelete("WaveUp2_"+pos2up);
            ObjectDelete("TrendUp2_"+pos2up);
            ObjectDelete("WvUp1Brk"+pos1up);
            ObjectDelete("WvUp3Proj1_"+pos1up);
            ObjectDelete("WvUp3Proj2_"+pos1up);
            wCounterUp=1;
            pos1up=0;
            pos2up=0;
            }
         
         if(Close[cnt]==val1)
            {
            if(pos2up==0)
               {
               pos2up=cnt;
               
               ObjectCreate("WaveUp2_"+pos2up,OBJ_TEXT,0,Time[pos2up],Low[pos2up]-tfm);
               ObjectSetText("WaveUp2_"+pos2up,""+wCounterUp,NbrSize,"Arial",Upclr);
               
               ObjectCreate("TrendUp2_"+pos2up,OBJ_TREND,0,Time[pos2up],Close[pos2up],Time[pos1up],Close[pos1up]);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_RAY,false);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_STYLE,LineType);
               }
            else if(pos2up!=0 && Close[cnt]<Close[pos2up])
               {
               ObjectDelete("WaveUp2_"+pos2up);
               ObjectDelete("TrendUp2_"+pos2up);
               
               pos2up=cnt;
            
               ObjectCreate("WaveUp2_"+pos2up,OBJ_TEXT,0,Time[pos2up],Low[pos2up]-tfm);
               ObjectSetText("WaveUp2_"+pos2up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp2_"+pos2up,OBJ_TREND,0,Time[pos2up],Close[pos2up],Time[pos1up],Close[pos1up]);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_RAY,false);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp2_"+pos2up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos2up!=0)wCounterUp++;
         
         if(Close[cnt]<Close[pos0up])
            {
            ObjectDelete("WaveUp0_"+pos0up);
            ObjectDelete("WaveUp1_"+pos1up);
            ObjectDelete("WaveUp2_"+pos2up);
            ObjectDelete("TrendUp0_"+pos0up);
            ObjectDelete("TrendUp1_"+pos1up);
            ObjectDelete("TrendUp2_"+pos2up);
            ObjectDelete("WvUp1Brk"+pos1up);
            ObjectDelete("WvUp3Proj1_"+pos1up);
            ObjectDelete("WvUp3Proj2_"+pos1up);
            wCounterUp=0;
            pos0up=0;
            pos1up=0;
            pos2up=0;
            } 
         break;
      
      case 3://Wave 3 is created
         val1=Close[iHighest(NULL,0,MODE_CLOSE,21,cnt)];
         val2=Close[iLowest(NULL,0,MODE_CLOSE,13,cnt)];
         
         if(Close[cnt]<Close[pos2up])
            {
            ObjectDelete("WaveUp2_"+pos2up);
            ObjectDelete("WaveUp3_"+pos3up);
            ObjectDelete("TrendUp2_"+pos2up);
            ObjectDelete("TrendUp3_"+pos3up);
            wCounterUp=2;
            pos2up=0;
            pos3up=0;
            }
         if(Close[cnt]==val1)
            {
            if(pos3up==0)
               {
               pos3up=cnt;
            
               ObjectCreate("WaveUp3_"+pos3up,OBJ_TEXT,0,Time[pos3up],High[pos3up]+tfm);
               ObjectSetText("WaveUp3_"+pos3up,""+wCounterUp,NbrSize,"Arial",Upclr);
         
               ObjectCreate("TrendUp3_"+pos3up,OBJ_TREND,0,Time[pos2up],Close[pos2up],Time[pos3up],Close[pos3up]);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_RAY,false);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_STYLE,LineType);
               }
            else if(pos3up!=0 && Close[cnt]>Close[pos3up])
               {
               ObjectDelete("WaveUp3_"+pos3up);
               ObjectDelete("TrendUp3_"+pos3up);
            
               pos3up=cnt;
            
               ObjectCreate("WaveUp3_"+pos3up,OBJ_TEXT,0,Time[pos3up],High[pos3up]+tfm);
               ObjectSetText("WaveUp3_"+pos3up,""+wCounterUp,NbrSize,"Arial",Upclr);
         
               ObjectCreate("TrendUp3_"+pos3up,OBJ_TREND,0,Time[pos2up],Close[pos2up],Time[pos3up],Close[pos3up]);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_RAY,false);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp3_"+pos3up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos3up!=0 && Close[pos3up]>Close[pos1up])
            {
            ObjectSet("WvUp1Brk"+pos1up,OBJPROP_TIME2,Time[pos3up]);
            ObjectSet("WvUp1Brk"+pos1up,OBJPROP_RAY,false);
            
            ObjectSet("WvUp3Proj1_"+pos1up,OBJPROP_TIME2,Time[pos3up]);
            ObjectSet("WvUp3Proj1_"+pos1up,OBJPROP_RAY,false);
            
            ObjectSet("WvUp3Proj2_"+pos1up,OBJPROP_TIME2,Time[pos3up]);
            ObjectSet("WvUp3Proj2_"+pos1up,OBJPROP_RAY,false);
            
            //Projections for Wave 5
            ObjectCreate("WvUp3Brk"+pos3up,OBJ_TREND,0,Time[pos3up+1],Close[pos3up],Time[cnt],Close[pos3up]);
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_COLOR,BrkLine);
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_STYLE,STYLE_DASH);
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_RAY,true);
            
            WaveUp5Proj1=NormalizeDouble(Close[pos2up]+((Close[pos3up]-Close[pos2up])*1.618),Digits);
            WaveUp5Proj2=NormalizeDouble(Close[pos2up]+((Close[pos3up]-Close[pos2up])*2.618),Digits);
            
            ObjectCreate("WvUp5Proj1_"+pos3up,OBJ_TREND,0,Time[pos3up+1],WaveUp5Proj1,Time[cnt],WaveUp5Proj1);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_COLOR,ProjLine);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_STYLE,STYLE_DASH);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_RAY,true);
            
            ObjectCreate("WvUp5Proj2_"+pos3up,OBJ_TREND,0,Time[pos3up+1],WaveUp5Proj2,Time[cnt],WaveUp5Proj2);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_COLOR,ProjLine);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_STYLE,STYLE_DASH);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_RAY,true);
            wCounterUp++;
            }
         break;
      
      case 4://Wave 4 is created
         val1=Close[iLowest(NULL,0,MODE_CLOSE,13,cnt)];
         val2=Close[iHighest(NULL,0,MODE_CLOSE,33,cnt)];
         
         if(Close[cnt]<Close[pos2up])
            {
            ObjectDelete("WaveUp0_"+pos0up);
            ObjectDelete("WaveUp1_"+pos1up);
            ObjectDelete("WaveUp2_"+pos2up);
            ObjectDelete("WaveUp3_"+pos3up);
            ObjectDelete("WaveUp4_"+pos4up);
            ObjectDelete("TrendUp1_"+pos1up);
            ObjectDelete("TrendUp2_"+pos2up);
            ObjectDelete("TrendUp3_"+pos3up);
            ObjectDelete("TrendUp4_"+pos4up);
            ObjectDelete("WvUp1Brk"+pos1up);
            ObjectDelete("WvUp3Brk"+pos3up);
            ObjectDelete("WvUp3Proj1_"+pos1up);
            ObjectDelete("WvUp3Proj2_"+pos1up);
            ObjectDelete("WvUp5Proj1_"+pos3up);
            ObjectDelete("WvUp5Proj2_"+pos3up);
            
            cnt=pos1up;
            wCounterUp=0;
            
            pos0up=0;
            pos1up=0;
            pos2up=0;
            pos3up=0;
            pos4up=0;
            }
         if(Close[cnt]>Close[pos3up])
            {
            ObjectDelete("WaveUp3_"+pos3up);
            ObjectDelete("WaveUp4_"+pos4up);
            ObjectDelete("TrendUp3_"+pos3up);
            ObjectDelete("TrendUp4_"+pos4up);
            ObjectDelete("WvUp3Brk"+pos3up);
            ObjectDelete("WvUp5Proj1_"+pos3up);
            ObjectDelete("WvUp5Proj2_"+pos3up);
            
            ObjectSet("WvUp1Brk"+pos1up,OBJPROP_RAY,true);
            ObjectSet("WvUp3Proj1_"+pos1up,OBJPROP_RAY,true);
            ObjectSet("WvUp3Proj2_"+pos1up,OBJPROP_RAY,true);
            
            pos3up=0;
            pos4up=0;
            wCounterUp=3;
            }

         if(Close[cnt]==val1)
            {
            if(pos4up==0)
               {
               pos4up=cnt;
               
               ObjectCreate("WaveUp4_"+pos4up,OBJ_TEXT,0,Time[pos4up],Low[pos4up]-tfm);
               ObjectSetText("WaveUp4_"+pos4up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp4_"+pos4up,OBJ_TREND,0,Time[pos4up],Close[pos4up],Time[pos3up],Close[pos3up]);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_RAY,false);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_STYLE,LineType);
               }
            else if(pos4up!=0 && Close[cnt]<Close[pos4up])
               {
               ObjectDelete("WaveUp4_"+pos4up);
               ObjectDelete("TrendUp4_"+pos4up);
               
               pos4up=cnt;
               
               ObjectCreate("WaveUp4_"+pos4up,OBJ_TEXT,0,Time[pos4up],Low[pos4up]-tfm);
               ObjectSetText("WaveUp4_"+pos4up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp4_"+pos4up,OBJ_TREND,0,Time[pos4up],Close[pos4up],Time[pos3up],Close[pos3up]);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_RAY,false);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp4_"+pos4up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos4up!=0)wCounterUp++;
         break;
      
      case 5://Wave 5 is created
         val1=Close[iHighest(NULL,0,MODE_CLOSE,33,cnt)];
         val2=Close[iLowest(NULL,0,MODE_CLOSE,13,cnt)];
         
         if(Close[cnt]<Close[pos4up])
            {
            ObjectDelete("WaveUp4_"+pos4up);
            ObjectDelete("WaveUp5_"+pos5up);
            ObjectDelete("TrendUp4_"+pos4up);
            ObjectDelete("TrendUp5_"+pos5up);
            wCounterUp=4;
            pos4up=0;
            pos5up=0;
            }
         
         if(Close[cnt]==val1)
            {
            if(pos5up==0)
               {
               pos5up=cnt;
               ObjectCreate("WaveUp5_"+pos5up,OBJ_TEXT,0,Time[pos5up],High[pos5up]+tfm);
               ObjectSetText("WaveUp5_"+pos5up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp5_"+pos5up,OBJ_TREND,0,Time[pos5up],Close[pos5up],Time[pos4up],Close[pos4up]);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_RAY,false);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_STYLE,LineType);
               }
            else if(pos5up!=0 && Close[cnt]>Close[pos5up])
               {
               ObjectDelete("WaveUp5_"+pos5up);
               ObjectDelete("TrendUp5_"+pos5up);
               
               pos5up=cnt;
               
               ObjectCreate("WaveUp5_"+pos5up,OBJ_TEXT,0,Time[pos5up],High[pos5up]+tfm);
               ObjectSetText("WaveUp5_"+pos5up,""+wCounterUp,NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUp5_"+pos5up,OBJ_TREND,0,Time[pos5up],Close[pos5up],Time[pos4up],Close[pos4up]);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_RAY,false);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUp5_"+pos5up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos5up!=0 && Close[pos5up]>Close[pos3up])
            {
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_TIME2, Time[pos5up]);
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_RAY,false);
            
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_TIME2,Time[pos5up]);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_RAY,false);
            
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_TIME2,Time[pos5up]);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_RAY,false);
            wCounterUp++;
            }
         break;
      
      case 6://Wave A is created
         val1=Close[iLowest(NULL,0,MODE_CLOSE,13,cnt)];
         val2=Close[iHighest(NULL,0,MODE_CLOSE,8,cnt)];
         
         if(Close[cnt]>Close[pos5up])
            {
            ObjectDelete("WaveUp5_"+pos5up);
            ObjectDelete("WaveUpA_"+pos6up);
            ObjectDelete("TrendUp5_"+pos5up);
            ObjectDelete("TrendUpA_"+pos6up);

            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_RAY,true);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_RAY,true);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_RAY,true);
            
            wCounterUp=5;
            pos5up=0;
            pos6up=0;
            }  
         if(Close[cnt]<Close[pos4up])
            {
            ObjectDelete("WaveUp4_"+pos4up);
            ObjectDelete("WaveUp5_"+pos5up);
            ObjectDelete("WaveUpA_"+pos6up);
            ObjectDelete("TrendUp4_"+pos4up);
            ObjectDelete("TrendUp5_"+pos5up);
            ObjectDelete("TrendUpA_"+pos6up);
            
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_RAY,true);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_RAY,true);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_RAY,true);
            
            wCounterUp=4;
            pos4up=0;
            pos5up=0;
            pos6up=0;
            }
         
         if(Close[cnt]==val1)
            {
            if(pos6up==0)
               {
               pos6up=cnt;
               ObjectCreate("WaveUpA_"+pos6up,OBJ_TEXT,0,Time[pos6up],Low[pos6up]-tfm);
               ObjectSetText("WaveUpA_"+pos6up,"A",NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUpA_"+pos6up,OBJ_TREND,0,Time[pos6up],Close[pos6up],Time[pos5up],Close[pos5up]);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_RAY,false);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_STYLE,LineType);
               }
            else if(pos6up!=0 && Close[cnt]<Close[pos6up])
               {
               ObjectDelete("WaveUpA_"+pos6up);
               ObjectDelete("TrendUpA_"+pos6up);
               
               pos6up=cnt;
               ObjectCreate("WaveUpA_"+pos6up,OBJ_TEXT,0,Time[pos6up],Low[pos6up]-tfm);
               ObjectSetText("WaveUpA_"+pos6up,"A",NbrSize,"Arial",Upclr);
            
               ObjectCreate("TrendUpA_"+pos6up,OBJ_TREND,0,Time[pos6up],Close[pos6up],Time[pos5up],Close[pos5up]);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_RAY,false);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUpA_"+pos6up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos6up!=0)wCounterUp++;
         break;
      
      case 7://Wave B is created
         val1=Close[iHighest(NULL,0,MODE_CLOSE,8,cnt)];
         val2=Close[iLowest(NULL,0,MODE_CLOSE,21,cnt)];
         
         if(Close[cnt]>Close[pos5up])
            {
            ObjectDelete("WaveUp5_"+pos5up);
            ObjectDelete("WaveUpA_"+pos6up);
            ObjectDelete("WaveUpB_"+pos7up);
            ObjectDelete("TrendUp5_"+pos5up);
            ObjectDelete("TrendUpA_"+pos6up);
            ObjectDelete("TrendUpB_"+pos7up);
            
            ObjectSet("WvUp3Brk"+pos3up,OBJPROP_RAY,true);
            ObjectSet("WvUp5Proj1_"+pos3up,OBJPROP_RAY,true);
            ObjectSet("WvUp5Proj2_"+pos3up,OBJPROP_RAY,true);
            
            wCounterUp=5;
            pos5up=0;
            pos6up=0;
            pos7up=0;
            }
         if(Close[cnt]<Close[pos6up])
            {
            ObjectDelete("WaveUpA_"+pos6up);
            ObjectDelete("WaveUpB_"+pos7up);
            ObjectDelete("TrendUpA_"+pos6up);
            ObjectDelete("TrendUpB_"+pos7up);
            wCounterUp=6;
            pos6up=0;
            pos7up=0;
            }
         
         if(Close[cnt]==val1)
            {
            if(pos7up==0)
               {
               pos7up=cnt;
               ObjectCreate("WaveUpB_"+pos7up,OBJ_TEXT,0,Time[pos7up],High[pos7up]+tfm);
               ObjectSetText("WaveUpB_"+pos7up,"B",NbrSize,"Arial",Upclr);
           
               ObjectCreate("TrendUpB_"+pos7up,OBJ_TREND,0,Time[pos7up],Close[pos7up],Time[pos6up],Close[pos6up]);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_RAY,false);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_STYLE,LineType);
               }
            else if(pos7up!=0 && Close[cnt]>Close[pos7up])
               {
               ObjectDelete("WaveUpB_"+pos7up);
               ObjectDelete("TrendUpB_"+pos7up);
               
               pos7up=cnt;
               
               ObjectCreate("WaveUpB_"+pos7up,OBJ_TEXT,0,Time[pos7up],High[pos7up]+tfm);
               ObjectSetText("WaveUpB_"+pos7up,"B",NbrSize,"Arial",Upclr);
           
               ObjectCreate("TrendUpB_"+pos7up,OBJ_TREND,0,Time[pos7up],Close[pos7up],Time[pos6up],Close[pos6up]);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_RAY,false);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_COLOR,Upclr);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_WIDTH,TrendSize);
               ObjectSet("TrendUpB_"+pos7up,OBJPROP_STYLE,LineType);
               }
            }
         if(Close[cnt]==val2 && pos7up!=0)wCounterUp++;
         break;
      
      case 8://Wave C is created
         val1=Close[iLowest(NULL,0,MODE_CLOSE,21,cnt)];
         
         if(Close[cnt]==val1)
            {
            if(pos8up!=0 && Close[cnt]>Close[pos8up])pos8up=cnt;
            else if(pos8up==0)pos8up=cnt;
            }
         if(pos8up!=0 && Close[pos8up]<Close[pos6up])
            {
            ObjectCreate("WaveUpC_"+pos8up,OBJ_TEXT,0,Time[pos8up],Low[pos8up]-tfm);
            ObjectSetText("WaveUpC_"+pos8up,"C",NbrSize,"Arial",Upclr);
           
            ObjectCreate("TrendUpC_"+pos8up,OBJ_TREND,0,Time[pos8up],Close[pos8up],Time[pos7up],Close[pos7up]);
            ObjectSet("TrendUpC_"+pos8up,OBJPROP_RAY,false);
            ObjectSet("TrendUpC_"+pos8up,OBJPROP_COLOR,Upclr);
            ObjectSet("TrendUpC_"+pos8up,OBJPROP_WIDTH,TrendSize);
            ObjectSet("TrendUpC_"+pos8up,OBJPROP_STYLE,LineType);
           
            wCounterUp=0;
            pos0up=0;
            pos1up=0;
            pos2up=0;
            pos3up=0;
            pos4up=0;
            pos5up=0;
            pos6up=0;
            pos8up=0;
            }
         if(Close[cnt]>Close[pos7up])
            {
            ObjectDelete("WaveUpB_"+pos7up);
            ObjectDelete("TrendUpB_"+pos7up);
            wCounterUp=7;
            pos7up=0;
            pos8up=0;
            }
         break;      
      }
   }
   return(0);
  }
//+------------------------------------------------------------------+