//| HMA.mq4 |
//| Copyright ?2004, MetaQuotes Software Corp. |
//| http://www.metaquotes.net/ |
//+------------------------------------------------------------------

#property copyright "Copyright ?2004, MetaQuotes Software Corp."
#property link "http://www.metaquotes.net/"

//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Yellow
#property indicator_color3 Red

//---- indicator parameters
extern int Take_Profit = 48;
extern int Stop_Loss = 38;
extern int HMA_Period= 8;
extern bool Alerts = true;
extern bool EmailOn = false;
bool aTurnedUp = false;
bool aTurnedDown = false;

//---- indicator buffers
double ind_buffer0[];
double ind_buffer1[];
double ind_buffer2[];
double buffer[];

int draw_begin0;

//+------------------------------------------------------------------

//| Custom indicator initialization function |
//+------------------------------------------------------------------

int init()
{
//---- indicator buffers mapping
IndicatorBuffers(4);
if(!SetIndexBuffer(0,ind_buffer0) && !SetIndexBuffer(1,ind_buffer1)
&& !SetIndexBuffer(2,ind_buffer2) && !SetIndexBuffer(3, buffer))
Print("cannot set indicator buffers!");
// ArraySetAsSeries(ind_buffer1,true);
//---- drawing settings
SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3);
SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,3);
SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,3);
draw_begin0=HMA_Period+MathFloor(MathSqrt(HMA_Period));
SetIndexDrawBegin(0,draw_begin0);
SetIndexDrawBegin(1,draw_begin0);
SetIndexDrawBegin(2,draw_begin0);
IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
//---- name for DataWindow and indicator subwindow label
IndicatorShortName("HMA("+HMA_Period+")");
SetIndexLabel(0,"Hull Moving Average");
//---- initialization done
return(0);
}
//+------------------------------------------------------------------

//| Moving Averages Convergence/Divergence |
//+------------------------------------------------------------------

int start()
{
int limit,i;
int counted_bars=IndicatorCounted();
double tmp, tmpPrevious;


//---- check for possible errors
if(counted_bars<1)
{
for(i=1;i<=draw_begin0;i++) buffer[Bars-i]=0;
for(i=1;i<=HMA_Period;i++)
{
ind_buffer0[Bars-i]=0;
ind_buffer1[Bars-i]=0;
ind_buffer2[Bars-i]=0;
}
}
//---- last counted bar will be recounted
if(counted_bars>0) counted_bars--;
limit=Bars-counted_bars;
//---- MA difference counted in the 1-st buffer
for(i=0; i<limit; i++)
{

buffer[i]=iMA(NULL,0,MathFloor
(HMA_Period/1.5),0,MODE_LWMA,PRICE_CLOSE,i)*2-        //change the HMA_Period/xx will change when the colors chang at given rate
iMA(NULL,0,HMA_Period,0,MODE_LWMA,PRICE_CLOSE,i);
}
//---- HMA counted in the 0-th buffer
tmp=iMAOnArray(buffer,0,MathFloor(MathSqrt
(HMA_Period)),0,MODE_LWMA,0);

for(i=1; i<limit; i++)
{

tmpPrevious=iMAOnArray(buffer,0,MathFloor(MathSqrt
(HMA_Period)),0,MODE_LWMA,i);
  
if (tmpPrevious > tmp)
{
ind_buffer0[i] = EMPTY_VALUE;
ind_buffer1[i] = EMPTY_VALUE;
ind_buffer2[i] = tmpPrevious;
ind_buffer2[i-1] = tmp; // !
}
else if (tmpPrevious < tmp)
{
ind_buffer0[i] = tmpPrevious;
ind_buffer0[i-1] = tmp; // !
ind_buffer1[i] = EMPTY_VALUE;
ind_buffer2[i] = EMPTY_VALUE;
}
  
else
{
ind_buffer0[i] = CLR_NONE;
ind_buffer1[i] = tmpPrevious;
ind_buffer2[i-1] = tmp; // !
ind_buffer2[i] = CLR_NONE;
}
if (Alerts)
 {
  if (tmpPrevious < tmp) //change the wt[?] number will change when the signal will trigger based on # of last bars
  {
   if (!aTurnedUp)
   {
    if (BarChanged())
    {
      Alert ("Buy Entry - " + Symbol() + " " + "EMA " + aRperiodf() + " - Price: " + DoubleToStr(Ask,4));
      PlaySound("alert.wav");
      if (EmailOn)
      {
      SendMail("Buy Entry - "+(Symbol())+" "+"EMA"+(aRperiodf()),(Symbol())+"  Price:  "+DoubleToStr(Ask,4)+"  Stop:  "+ DoubleToStr(aGetSLl(),4)
            +"  Limit:  "+DoubleToStr(aGetTPl(),4));  //send email with entry price
      }
    } 
    aTurnedUp = true;
    aTurnedDown = false;
   }
}
  if (tmpPrevious > tmp) //change the wt[?] number will change when the signal will trigger based on # of last bars
  {
   if (!aTurnedDown)
   {
    if (BarChanged())
    {
      Alert ("Sell Entry - "+(Symbol())+" "+"EMA "+(aRperiodf())," - Price: "+DoubleToStr(Bid,4));
      PlaySound("alert.wav");
      if (EmailOn)
      {
      SendMail("Sell Entry - "+(Symbol())+" "+"EMA"+(aRperiodf()),(Symbol())+"  Price:  "+DoubleToStr(Ask,4)+"  Stop:  "+ DoubleToStr(aGetSLs(),4)
            +"  Limit:  "+DoubleToStr(aGetTPs(),4));  //send email with entry price
      }
    }
    aTurnedDown = true;
    aTurnedUp = false;
   }
  }
}

tmp = tmpPrevious;
}


//---- done
return(0);
}

bool BarChanged()
{
 static datetime dt = 0;

  if (dt != Time[0])
  {
   dt = Time[0];
   return(true);
  }
   return(false);
}

//---- done
return(0);
 
  
  double aGetTPs() { return(Bid-Take_Profit*Point); }
  double aGetTPl() { return(Ask+Take_Profit*Point); }
  double aGetSLs() { return(Bid+Stop_Loss*Point); }
  double aGetSLl() { return(Ask-Stop_Loss*Point); }
  int aRperiodf() { return(HMA_Period*Point*10000); }


