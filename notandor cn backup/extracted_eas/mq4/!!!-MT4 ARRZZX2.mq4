// THIS CODE IS POSTED SO THAT LIKE MINDED PAY IT FORWARD CODERS MAY
// IMPROVE ON IT AND REPOST IT ON THE FORUM FOR THEIR FELLOW TRADERS
//==================================================================
// [!!!-MT4 ARRZZX2]                 \¦/   
//                                  (ò ó)
//_____________________________o0o___(_)___o0o______________________ 
#property copyright "Welcome to the World of Forex"
#property indicator_chart_window
#property indicator_buffers 8
    extern int SR=3,SRZZ=12,MainRZZ=34,FP=21,SMF=3,PriceConst=0;
   extern bool DrawZZ=FALSE; 
        double Lmt[],LZZ[],SA[],SM[],Up[],Dn[],pUp[],pDn[];
           int LTF[6]={0,0,0,0,0,0},STF[5]={0,0,0,0,0}; 
           int MaxBar,nSBZZ,nLBZZ,SBZZ,LBZZ,prevBars=0;
          bool First=true;
   extern bool Indicator_On=true; bool Deinitialized; int ChartScale,Width;
//==========================================================================================================          
   int init(){Deinitialized=false; ChartScale=ChartScaleGet();                   
         if(ChartScale==0) {Width=1;}
   else {if(ChartScale==1) {Width=1;}      
   else {if(ChartScale==2) {Width=1;}
   else {if(ChartScale==3) {Width=3;}
   else {if(ChartScale==4) {Width=7;} else {Width=12;}}}}}
//==========================================================================================================
   int Buf=-1; IndicatorBuffers(8);
   Buf+=1; SetIndexBuffer(Buf,Lmt); SetIndexStyle(Buf,DRAW_ARROW,EMPTY,8,clrWhite); SetIndexArrow(Buf,SYMBOL_STOPSIGN);
   if(DrawZZ) {
   Buf+=1; SetIndexBuffer(Buf,LZZ); SetIndexStyle(Buf,DRAW_SECTION,EMPTY,2,clrRoyalBlue); SetIndexEmptyValue(Buf,0.0);}
   else 
   Buf+=1; SetIndexBuffer(Buf,LZZ); SetIndexStyle(Buf,DRAW_NONE);
   Buf+=1; SetIndexBuffer(Buf,SA);  SetIndexStyle(Buf,DRAW_NONE);
   Buf+=1; SetIndexBuffer(Buf,SM);  SetIndexStyle(Buf,DRAW_NONE);
   Buf+=1; SetIndexBuffer(Buf,Up);  SetIndexStyle(Buf,DRAW_ARROW,EMPTY,Width,clrAqua); SetIndexArrow(Buf,159);
   Buf+=1; SetIndexBuffer(Buf,Dn);  SetIndexStyle(Buf,DRAW_ARROW,EMPTY,Width,clrGold); SetIndexArrow(Buf,159);
   Buf+=1; SetIndexBuffer(Buf,pUp); SetIndexStyle(Buf,DRAW_ARROW,EMPTY,Width,clrAqua); SetIndexArrow(Buf,159);
   Buf+=1; SetIndexBuffer(Buf,pDn); SetIndexStyle(Buf,DRAW_ARROW,EMPTY,Width,clrGold); SetIndexArrow(Buf,159); return(0);}
//==========================================================================================================
   int deinit() {return(0);}
//==========================================================================================================
   int start() {if(!Indicator_On){if(!Deinitialized) {deinit(); Deinitialized=true;} return(0);}
   int counted_bars=IndicatorCounted(); int limit,i;
   if(counted_bars<0) return(-1); if(counted_bars>0) counted_bars--;
   if(First==true) { 
   if(SR<2) SR=2; if(Bars<=2*(MainRZZ+FP+SR+2)) return(-1); 
   if(SRZZ<=SR) SRZZ=SR+1; MaxBar=Bars-(MainRZZ+FP+SR+2);
   LBZZ=MaxBar; SBZZ=LBZZ; prevBars=Bars; First=false;}
   limit=Bars-counted_bars; for(i=limit;i>=0;i--) {MainCalculation(i);}
   if(prevBars!=Bars) {SBZZ=Bars-nSBZZ; LBZZ=Bars-nLBZZ; prevBars=Bars;} 
   SZZCalc(0); LZZCalc(0); ArrCalc(); return(0);}
//==========================================================================================================          
   void MainCalculation(int Pos) {
   if((Bars-Pos)>(SR+1)) SACalc(Pos); else SA[Pos]=0; 
   if((Bars-Pos)>(FP+SR+2)) SMCalc(Pos); else SM[Pos]=0; return;}
//==========================================================================================================
   void SACalc(int Pos) { int sw,i,w,ww,Shift; double sum; 
   switch(PriceConst) {
   case 0: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_CLOSE,Pos);    break;
   case 1: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_OPEN,Pos);     break;
/* case 2: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_HIGH,Pos);     break;
   case 3: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_LOW,Pos);      break;*/
   case 4: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_MEDIAN,Pos);   break;
   case 5: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_TYPICAL,Pos);  break;
   case 6: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_WEIGHTED,Pos); break;
  default: SA[Pos]=iMA(NULL,0,SR+1,0,MODE_LWMA,PRICE_OPEN,Pos);     break;}
//====  
   for(Shift=Pos+SR+2;Shift>Pos;Shift--) {
   sum=0.0; sw=0; i=0; w=Shift+SR; ww=Shift-SR; if(ww<Pos) ww=Pos;
   while(w>=Shift) {i++; sum=sum+i*SnakePrice(w); sw=sw+i; w--;}
   while(w>=ww) {i--; sum=sum+i*SnakePrice(w); sw=sw+i; w--;}
   SA[Shift]=sum/sw;} return;}
//====
   double SnakePrice(int Shift) {
   switch(PriceConst) {
   case 0: return(Close[Shift]);
   case 1: return(Open[Shift]);
/* case 2: return(High[Shift]);
   case 3: return(Low[Shift]);*/
   case 4: return((High[Shift]+Low[Shift])/2);
   case 5: return((Close[Shift]+High[Shift]+Low[Shift])/3);
   case 6: return((2*Close[Shift]+High[Shift]+Low[Shift])/4);
  default: return(Open[Shift]);}}
//==========================================================================================================
   void SMCalc(int i) {double t,b; for(int Shift=i+SR+2;Shift>=i;Shift--) {
   t=SA[ArrayMaximum(SA,FP,Shift)]; b=SA[ArrayMinimum(SA,FP,Shift)];
   SM[Shift]=(2*(2+SMF)*SA[Shift]-(t+b))/2/(1+SMF);} return;}
//==========================================================================================================
   void LZZCalc(int Pos) {int i,RBar,LBar,ZZ,NZZ,NZig,NZag; 
   i=Pos-1; NZig=0; NZag=0;
   while(i<MaxBar && ZZ==0) {i++; LZZ[i]=0; RBar=i-MainRZZ; 
   if(RBar<Pos) RBar=Pos; LBar=i+MainRZZ;
   if(i==ArrayMinimum(SM,LBar-RBar+1,RBar)) {ZZ=-1; NZig=i;}
   if(i==ArrayMaximum(SM,LBar-RBar+1,RBar)) {ZZ=1;NZag=i;}}
   if(ZZ==0) return; NZZ=0;
   if(i>Pos) {if(SM[i]>SM[Pos]) {if(ZZ==1) {
   if(i>=Pos+MainRZZ && NZZ<5) {NZZ++; LTF[NZZ]=i;} NZag=i; 
   LZZ[i]=SM[i];}}
   else {if(ZZ==-1) {if(i>=Pos+MainRZZ && NZZ<5) {NZZ++; LTF[NZZ]=i;}
   NZig=i; LZZ[i]=SM[i];}}}
   while(i<LBZZ || NZZ<5) {LZZ[i]=0; RBar=i-MainRZZ; 
   if(RBar<Pos) RBar=Pos; LBar=i+MainRZZ;
   if(i==ArrayMinimum(SM,LBar-RBar+1,RBar)) {
   if(ZZ==-1 && SM[i]<SM[NZig]) { 
   if(i>=Pos+MainRZZ && NZZ<5) LTF[NZZ]=i; LZZ[NZig]=0; LZZ[i]=SM[i]; 
   NZig=i;}
   if(ZZ==1) {if(i>=Pos+MainRZZ && NZZ<5) {NZZ++; LTF[NZZ]=i;} 
   LZZ[i]=SM[i]; ZZ=-1; NZig=i;}}
   if(i==ArrayMaximum(SM,LBar-RBar+1,RBar)) {
   if(ZZ==1 && SM[i]>SM[NZag]) { 
   if(i>=Pos+MainRZZ && NZZ<5) LTF[NZZ]=i; LZZ[NZag]=0; LZZ[i]=SM[i]; 
   NZag=i;}
   if(ZZ==-1) {if(i>=Pos+MainRZZ && NZZ<5) {NZZ++; LTF[NZZ]=i;} 
   LZZ[i]=SM[i]; ZZ=1; NZag=i;}} i++; if(i>MaxBar) return;} 
   nLBZZ=Bars-LTF[5]; LZZ[Pos]=SM[Pos]; return;}
//==========================================================================================================
   void SZZCalc(int Pos) {int i,RBar,LBar,ZZ,NZZ,NZig,NZag; i=Pos-1; NZig=0; NZag=0;
   while(i<=LBZZ && ZZ==0) {i++; pDn[i]=0; pUp[i]=0; Dn[i]=0; Up[i]=0; 
   Lmt[i]=0; RBar=i-SRZZ; if(RBar<Pos) RBar=Pos; LBar=i+SRZZ;
   if(i==ArrayMinimum(SM,LBar-RBar+1,RBar)) {ZZ=-1; NZig=i;}
   if(i==ArrayMaximum(SM,LBar-RBar+1,RBar)) {ZZ= 1; NZag=i;}}
   if(ZZ==0) return; NZZ=0;
   if(i>Pos) {if(SM[i]>SM[Pos]) {if(ZZ==1) {
   if(i>=Pos+SRZZ && NZZ<4) {NZZ++; STF[NZZ]=i;} NZag=i; 
   Dn[i-1]=Open[i-1];}}
   else {if(ZZ==-1) {if(i>=Pos+SRZZ && NZZ<4) {NZZ++; STF[NZZ]=i;}
   NZig=i; Up[i-1]=Open[i-1];}}}
   while(i<=LBZZ || NZZ<4) {pDn[i]=0; pUp[i]=0; Dn[i]=0; Up[i]=0; 
   Lmt[i]=0; RBar=i-SRZZ; if(RBar<Pos) RBar=Pos; LBar=i+SRZZ;
   if(i==ArrayMinimum(SM,LBar-RBar+1,RBar)) {
   if(ZZ==-1 && SM[i]<SM[NZig]) { 
   if(i>=Pos+SRZZ && NZZ<4) STF[NZZ]=i; Up[NZig-1]=0; Up[i-1]=Open[i-1]; 
   NZig=i;} if(ZZ==1) {if(i>=Pos+SRZZ && NZZ<4) {NZZ++; STF[NZZ]=i;} 
   Up[i-1]=Open[i-1]; ZZ=-1; NZig=i;}}
   if(i==ArrayMaximum(SM,LBar-RBar+1,RBar)) {
   if(ZZ==1 && SM[i]>SM[NZag]) { 
   if(i>=Pos+SRZZ && NZZ<4) STF[NZZ]=i; Dn[NZag-1]=0; Dn[i-1]=Open[i-1]; 
   NZag=i;} if(ZZ==-1) {if(i>=Pos+SRZZ && NZZ<4) {NZZ++; STF[NZZ]=i;} 
   Dn[i-1]=Open[i-1]; ZZ=1; NZag=i;}} i++; if(i>LBZZ) return;} 
   nSBZZ=Bars-STF[4]; return;}
//==========================================================================================================
   void ArrCalc() {int i,j,k,n,z=0; double p;
   i=LBZZ; while(LZZ[i]==0) i--; j=i; p=LZZ[i]; i--; while(LZZ[i]==0) i--; 
   if(LZZ[i]>p) z=1; if(LZZ[i]>0 && LZZ[i]<p) z=-1; p=LZZ[j]; i=j-1;  
   while(i>0) {if(LZZ[i]>p) {z=-1; p=LZZ[i];}
   if(LZZ[i]>0 && LZZ[i]<p) {z=1;  p=LZZ[i];}
   if(z>0 && Dn[i]>0) {Lmt[i]=Open[i]; Dn[i]=0;}
   if(z<0 && Up[i]>0) {Lmt[i]=Open[i]; Up[i]=0;}
   if(z>0 && Up[i]>0) {if(i>1) {j=i-1; k=j-SRZZ+1; if(k<0) k=0; 
   n=j; while(n>=k && Dn[n]==0) {pUp[n]=Up[i]; pDn[n]=0; n--;}} 
   if(i==1) pUp[0]=Up[i];} 
   if(z<0 && Dn[i]>0) {if(i>1) {j=i-1; k=j-SRZZ+1; if(k<0) k=0; 
   n=j; while(n>=k && Up[n]==0) {pDn[n]=Dn[i]; pUp[n]=0; n--;}} 
   if(i==1) pDn[0]=Dn[i];} i--;} return;}
//==========================================================================================================
   void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){ChartScale=ChartScaleGet(); 
   init();} int ChartScaleGet(){long result=-1; ChartGetInteger(0,CHART_SCALE,0,result); return((int)result);}           
//==========================================================================================================   