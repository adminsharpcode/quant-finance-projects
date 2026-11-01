#property copyright "Copyright trevone"
#property link "https://www.mql5.com/en/users/trevone" 
#property strict
#property version "1.05"

extern string LicenseKey = "9676DA2D3E8A737E7501A2FD1026E0E6D507509165ECD5A5";
extern string TradeComment = "MonkeyPips v1.05";
int MagicNumber = 33431; 
extern int MaxSpread = 9;
extern double FixedLot = 0;
extern int RiskPercent = 10;
extern int GMTOffset = 0; 
extern int StartHour = 23; 
extern int EndHour = 20; 
extern int TradeDeviation = 4;  
extern int TradeDelta = 7;   
extern int Trailing = 6; 
extern int TrailTime = 120; 
extern int VelocityTrigger = 40;

int VelocityTime = 15; 
int OrderExpiry = 15; 
int TickSample = 100;  
int r, gmt, brokerOffset, size, digits;

double marginRequirement, maxLot, minLot, lotSize, points, currentSpread, avgSpread, maxSpread, initialBalance, rateChange, rateTrigger;

double spreadSize[]; 
double tick[];
int tickTime[];   

string testerStartDate, testerEndDate;

bool timeToTrade;
bool licenseValid = false;
int yearExpiry, monthExpiry;

bool hasKey = false;

double limitedLots;
string licensetext;

int init() {  
   hasKey = false;
   authorise();
   marginRequirement = MarketInfo( Symbol(), MODE_MARGINREQUIRED ) * 0.01;
   maxLot = ( double ) MarketInfo( Symbol(), MODE_MAXLOT );  
   minLot = ( double ) MarketInfo( Symbol(), MODE_MINLOT );  
   currentSpread = NormalizeDouble( Ask - Bid, Digits ); 
   avgSpread = currentSpread; 
   size = TickSample;
   ArrayResize( spreadSize, size ); 
   ArrayFill( spreadSize, 0, size, avgSpread );
   maxSpread = NormalizeDouble( MaxSpread * Point, Digits );
   rateTrigger = NormalizeDouble( ( double ) VelocityTrigger * Point, Digits );
   testerStartDate = StringConcatenate( Year(), "-", Month(), "-", Day() );
   initialBalance = AccountBalance(); 
   return ( 0 );
} 
 
int start() {   
   int totalBuyStop = 0;
   int totalSellStop = 0;  
   int ticket; 
   prepareTimeToTrade();
   prepareSpread();
   manageTicks();  
   int orderExpiry = ( int ) TimeCurrent() + ( 60 * OrderExpiry ); 
   for( int pos = 0; pos < OrdersTotal(); pos++ ) {
      r = OrderSelect( pos, SELECT_BY_POS, MODE_TRADES );
      if( OrderSymbol() != Symbol() ) continue;   
      if( OrderMagicNumber() == MagicNumber ){ 
         switch ( OrderType() ) {
            case OP_BUYSTOP:
               if( avgSpread > maxSpread || MathAbs( rateChange ) < VelocityTrigger * Point ) r = OrderDelete( OrderTicket() );
               totalBuyStop++;
            break;
            case OP_SELLSTOP:
               if( avgSpread > maxSpread || MathAbs( rateChange ) < VelocityTrigger * Point ) r = OrderDelete( OrderTicket() );
               totalSellStop++;
            break;
            case OP_BUY:  
               if( ( int ) TimeCurrent() - ( int ) OrderOpenTime() < TrailTime ){
                  if( Bid - OrderOpenPrice() > Trailing * Point )
                     if( OrderStopLoss() == 0.0 || Bid - OrderStopLoss() > Trailing * Point )
                        r = OrderModify( OrderTicket(), OrderOpenPrice(), NormalizeDouble( Bid - ( Trailing * Point ), Digits ), OrderTakeProfit(), 0 ); 
               } else {
                  if( OrderStopLoss() == 0.0 || Bid - OrderStopLoss() > Trailing * Point )
                     r = OrderModify( OrderTicket(), OrderOpenPrice(), NormalizeDouble( Bid - ( Trailing * Point ), Digits ), OrderTakeProfit(), 0 ); 
               }
            break;
            case OP_SELL:  
               if( ( int ) TimeCurrent() - ( int ) OrderOpenTime() < TrailTime ){
                  if( OrderOpenPrice() - Ask > Trailing * Point )
                     if( OrderStopLoss() == 0.0 || OrderStopLoss() - Ask > Trailing * Point ) 
                        r = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble( Ask + ( Trailing * Point ), Digits ), OrderTakeProfit(), 0 );
               } else {
                  if( OrderStopLoss() == 0.0 || OrderStopLoss() - Ask > Trailing * Point ) 
                     r = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble( Ask + ( Trailing * Point ), Digits ), OrderTakeProfit(), 0 ); 
               }  
            break;
         } 
      }
   } 
   if( hasKey || IsTesting() ){ 
      if( timeToTrade ){
         if( rateChange > VelocityTrigger * Point && avgSpread <= maxSpread && totalBuyStop < TradeDeviation ) {
            ticket = OrderSend(Symbol(), OP_BUYSTOP, lotSize(), Ask + ( totalBuyStop + 1.0 ) * ( Point * TradeDelta ), 3, 0, 0, TradeComment, MagicNumber, orderExpiry );
         } 
         if( rateChange < -VelocityTrigger * Point && avgSpread <= maxSpread && totalSellStop < TradeDeviation ) {
            ticket = OrderSend(Symbol(), OP_SELLSTOP, lotSize(), Bid - ( totalSellStop + 1.0 ) * ( Point * TradeDelta ), 3, 0, 0, TradeComment, MagicNumber, orderExpiry );
         }   
      }   
   }
   display();
   return (0);
} 

double lotSize(){ 
   if( FixedLot > 0 ){
      lotSize = NormalizeDouble( FixedLot, 2 );
   } else {
      if( marginRequirement > 0 ) 
         lotSize = MathMax( MathMin( NormalizeDouble( ( AccountBalance() * ( ( double ) RiskPercent / 1000 ) * 0.01 / marginRequirement ), 2 ), maxLot ), minLot );    
   } 
   return ( lotSize ); 
}  

void prepareSpread(){
   if( !IsTesting() ){  
      double spreadSize_temp[];
      ArrayResize( spreadSize_temp, size - 1 );
      ArrayCopy( spreadSize_temp, spreadSize, 0, 1, size - 1 );
      ArrayResize( spreadSize_temp, size ); 
      spreadSize_temp[size-1] = NormalizeDouble( Ask - Bid, Digits ); 
      ArrayCopy( spreadSize, spreadSize_temp, 0, 0 ); 
      avgSpread = iMAOnArray( spreadSize, size, size, 0, MODE_LWMA, 0 );  
   }
}   

bool prepareTimeToTrade(){  
   gmt = offlineGMT();
   if( ( ( StartHour < EndHour && gmt >= StartHour && gmt <= EndHour ) 
      || ( StartHour > EndHour && ( ( gmt <= EndHour && gmt >= 0 ) 
      || ( gmt <= 23 && gmt >= StartHour ) ) ) ) 
      ){ 
      timeToTrade = true;
      return ( true );
   } else {
      timeToTrade = false; 
      return ( false );
   }
}

string niceHour( int kgmt ){ 
   string m;
   if( kgmt > 12 ) {
      kgmt = kgmt - 12;
      m = "PM"; 
   } else {
      m = "AM";
      if( kgmt == 12 )
         m = "PM";
   }
   return ( StringConcatenate( kgmt, m ) );
}

void prepareGMT(){
   int gmtH = gmt;
   int bkrH = Hour();
   brokerOffset =  bkrH - gmtH; 
   if( brokerOffset < 0 ) brokerOffset += 24;
   else if( brokerOffset > 23 ) brokerOffset -= 24;
}

int offlineGMT(){
   int bkrH = Hour();
   int gOffset =  bkrH - GMTOffset; 
   if( gOffset < 0 ) gOffset += 24;
   else if( gOffset > 23 ) gOffset -= 24;
   return ( gOffset );
}

string ArrayToHex(uchar &arre[],int count=-1){
   string res="";
   if(count<0 || count>ArraySize(arre))
      count=ArraySize(arre);
   for(int i=0; i<count; i++)
      res+=StringFormat( "%.2X",arre[i] );
   return(res);
}

void authorise(){
   int valid = 0;  
   licenseValid = decodeKey();
   licensetext = "";
   if( licenseValid == 1 ){   
      hasKey = true;
      return;
   } else licensetext = "Error: Key is not valid.";    
}
 
int decodeKey(){
   int valid = 0;
   int acc = AccountNumber(); 
   string text = StringConcatenate( acc, "monkeypips.v116" ); 
   string keystr = "6r$gDj)0sK";
   uchar src[], dst[],key[]; 
   StringToCharArray( keystr, key ); 
   StringToCharArray( text, src );  
   int res = CryptEncode( CRYPT_DES, src, key, dst );  
   if( res > 0 ){     
      if( ArrayToHex( dst ) == LicenseKey ){ 
         valid = 1;
      }
   } else Print( "Error in CryptEncode. Error code=", GetLastError() );
   return ( valid );
} 

int gmtHour( int inH ){
   int outH;
   if( IsTesting() ) return ( inH );
   outH = inH - brokerOffset;
   if( outH < 0 ) outH += 24;
   else if( outH > 23 ) outH -= 24;
   return ( outH );
}

void manageTicks(){    
   double tick_temp[], tickTime_temp[];
   ArrayResize( tick_temp, size - 1 );
   ArrayResize( tickTime_temp, size - 1 );
   ArrayCopy( tick_temp, tick, 0, 1, size - 1 ); 
   ArrayCopy( tickTime_temp, tickTime, 0, 1, size - 1 ); 
   ArrayResize( tick_temp, size ); 
   ArrayResize( tickTime_temp, size );
   tick_temp[size-1] = Bid;
   tickTime_temp[size-1] = ( int ) TimeCurrent();
   ArrayCopy( tick, tick_temp, 0, 0 );    
   ArrayCopy( tickTime, tickTime_temp, 0, 0 ); 
   int timeNow = tickTime[size-1];
   double priceNow = tick[size-1];
   double priceThen = 0;   
   for( int i = size - 1; i >= 0; i-- ){ 
      if( timeNow - tickTime[i] > VelocityTime ){
         priceThen = tick[i]; 
         break;
      }  
   }     
   rateChange = ( priceNow - priceThen );
   if( rateChange / Point > 5000 ) rateChange = 0;  
} 

void display(){  
   //if( !IsTesting() ){ 
      string display = "  Monkey Pips v1.04\n";
      display = StringConcatenate( display, " ----------------------------------------\n" );
      display = StringConcatenate( display, "  GMT: ", niceHour( gmt ), "\n" );
      display = StringConcatenate( display, " ----------------------------------------\n" );
      display = StringConcatenate( display, "  Leverage: ", DoubleToStr( AccountLeverage(), 0 ), " Lots: ", DoubleToStr( lotSize, 2 ), ", \n" ); 
      display = StringConcatenate( display, "  Avg. Spread: ", DoubleToStr( avgSpread / Point, 0 ), " of ", MaxSpread, ", \n" ); 
      display = StringConcatenate( display, " ----------------------------------------\n" );
      display = StringConcatenate( display, "  Set: ", TradeComment, " \n" ); 
      display = StringConcatenate( display, " ----------------------------------------\n" ); 
      if( !hasKey ){
         display = StringConcatenate( display, "  ", licensetext, "\n" );
         display = StringConcatenate( display, "  Mail trevorschuil@yahoo.com\n" );
      }  
      Comment( display ); 
   //}
}
/*
double OnTester(){ 
   if( ( double ) TesterStatistics( STAT_EXPECTED_PAYOFF ) > 0 && ( double) TesterStatistics( STAT_PROFIT ) > 0 ){  
      testerEndDate = StringConcatenate( Year(), "-", Month(), "-", Day() );
      char post[],char_result[];
      string cookie = NULL, headers; 
      int res;     
      
      string params = StringConcatenate(   
         "TradeComment=", TradeComment, ";",  
         "MaxSpread=", DoubleToStr( MaxSpread, 0 ), ";",
         "RiskPercent=", DoubleToStr( RiskPercent, 0 ), ";",  
         "TradeDeviation=", DoubleToStr( TradeDeviation, 0 ), ";",
         "TradeDelta=", DoubleToStr( TradeDelta, 0 ), ";",  
         "Trailing=", DoubleToStr( Trailing, 0 ), ";",
         "TrailTime=", DoubleToStr( TrailTime, 0 ), ";",
         "VelocityTrigger=", DoubleToStr( VelocityTrigger, 0 ), ";"
      );           
      
      double profitTrades = TesterStatistics( STAT_PROFIT_TRADES );
      double losingTrades = TesterStatistics( STAT_LOSS_TRADES );
      double winRatio = NormalizeDouble( profitTrades / ( profitTrades + losingTrades ) * 100, 2 );
      
      string url = StringConcatenate( "http://my.domain.com/mt4/onTester.php?symbol=", 
         Symbol(), 
         "&balance=", initialBalance, 
         "&spread=", DoubleToStr( ( Ask - Bid ) / Point, 0 ), 
         "&start=", testerStartDate, 
         "&end=", testerEndDate, 
         "&leverage=", AccountLeverage(), 
         "&profit=", TesterStatistics( STAT_PROFIT ), 
         "&totalTrades=", TesterStatistics( STAT_TRADES ), 
         "&profitFactor=", TesterStatistics( STAT_PROFIT_FACTOR ), 
         "&expectedPayoff=", TesterStatistics( STAT_EXPECTED_PAYOFF ), 
         "&drawdownDollar=", TesterStatistics( STAT_EQUITY_DD_RELATIVE ), 
         "&drawdownPercent=", TesterStatistics( STAT_EQUITY_DDREL_PERCENT ), 
         "&winRatio=", winRatio,
         "&settings=", params ); 

      ResetLastError(); 
      int timeout = 5000; 
      res = WebRequest( "GET", url, cookie, NULL, timeout, post, 0, char_result, headers );
      return( ( double ) CharArrayToString( char_result, 0, WHOLE_ARRAY,CP_ACP ) ); 
   } else return ( 0 );
} 
*/