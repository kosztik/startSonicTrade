//+------------------------------------------------------------------+
//|                                              startSonicTrade.mq4 |
//|                                                   Istvan Kosztik |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Istvan Kosztik"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters

extern double LOTs=0.01;

//--- init global variables
double dragonTop[100],dragonCenter[100],dragonBottom[100],dragonTopH1[100],dragonCenterH1[100],dragonBottomH1[100],trend[100],trendH1[100];;
bool dontesiMatrix[3];
int flipflop=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   dragonAndTrendHistory();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| A dragonnal és TL -el kapcsolatos töböket tölti fel              |
//+------------------------------------------------------------------+
void dragonAndTrendHistory()
  {
   int i;
   for(i=99; i>0; i--)
     {
      dragonTop[i]=NormalizeDouble(iMA(NULL,NULL,34,0,1,PRICE_HIGH,i),5);
      dragonBottom[i]=NormalizeDouble(iMA(NULL,NULL,34,0,1,PRICE_LOW,i), 5);
      dragonCenter[i]=NormalizeDouble(iMA(NULL,NULL,34,0,1,PRICE_CLOSE,i), 5);

      dragonTopH1[i]=NormalizeDouble(iMA(NULL,PERIOD_H1,34,0,1,PRICE_HIGH,i),5);
      dragonBottomH1[i]=NormalizeDouble(iMA(NULL,PERIOD_H1,34,0,1,PRICE_LOW,i), 5);
      dragonCenterH1[i]=NormalizeDouble(iMA(NULL,PERIOD_H1,34,0,1,PRICE_CLOSE,i), 5);

      trend[i]=NormalizeDouble(iMA(NULL,NULL,89,0,1,PRICE_CLOSE,i),5);

      trendH1[i]=NormalizeDouble(iMA(NULL,PERIOD_H1,89,0,1,PRICE_CLOSE,i),5);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double pips(bool irany) // true = fel, false = le
  {

   double pips;

   if(irany==True) //felfelé mérek
     {
      pips=(dragonCenter[1]-trend[1])*100000;

     }

   if(irany==False) //lefelé mérek
     {
      pips=(trend[1]-dragonCenter[1])*100000;

     }

   return NormalizeDouble(pips, 15);
  }
//+------------------------------------------------------------------+
//| Itt történik a vásárlás vagy az eladás                          |
//+------------------------------------------------------------------+
void piacraMegyek(string eztTeszem,string devizaPar)
  {
   int ticket,orderType;
   string orderSymbol;
// de elõtte egy teszt. Ha van már ilyen magic numberû kereskedés ezen a deviza páron, akkor nem csinálok semmit
   int Size=OrdersTotal();
   for(int cnt=0;cnt<Size;cnt++)
     {

      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      orderType=OrderType();
      orderSymbol=OrderSymbol();

      if(orderType==OP_BUY)
        {
         if(OrderMagicNumber() == 999 && orderSymbol == devizaPar) return;
        }
      if(orderType==OP_SELL)
        {
         if(OrderMagicNumber() == 999 && orderSymbol == devizaPar) return;
        }

     }

   if(eztTeszem=="buy")
     {
      int ticket=OrderSend(Symbol(),OP_BUY,LOTs,Ask,3,0,0,"My sonic order",999,0,clrGreen);

     }

   if(eztTeszem=="sell")
     {
      int ticket=OrderSend(Symbol(),OP_SELL,LOTs,Bid,3,0,0,"My sonic order",999,0,clrRed);

     }

   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError());
     }
   else
      Print("OrderSend placed successfully");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
/*
   használom:
   SonicR Filled Dragon-Trend 
   Heiken_Ashi_smoothed
   
   indikátorokat
   
*/
   double haOpenPrev=NormalizeDouble(iCustom(Symbol(),PERIOD_M15,"Heiken_Ashi_Smoothed",0,5,1),5);
   double haClosePrev=NormalizeDouble(iCustom(Symbol(),PERIOD_M15,"Heiken_Ashi_Smoothed",0,6,1),5);

   int min,sec;

   min = Time[0] + PERIOD_M15*60 - CurTime();
   sec = min%60;
   min=(min-min%60)/60; // idõszámítások, hogy pontosan tudjam mikor van 15. perc

   if(min!=14) flipflop=0;
   if(min==14 && flipflop==0)
     {
      flipflop=1;
      dragonAndTrendHistory();

      // hol van a trend a dragonhoz képest ?
      if(trend[1]> dragonCenter[1]) dontesiMatrix[0] = False; //sell - alatta van a dragon
      if(trend[1] < dragonCenter[1]) dontesiMatrix[0] = True; //buy - fölötte van a dragon
      
      // ue. H1-en
      if(trendH1[1]>dragonCenterH1[1]) dontesiMatrix[2]=False; //sell - alatta van a dragon
      if(trendH1[1]<dragonCenterH1[1]) dontesiMatrix[2]=True; //buy - fölötte van a dragon

      if(haOpenPrev>haClosePrev) dontesiMatrix[1] = True;  // Long
      if(haOpenPrev<haClosePrev) dontesiMatrix[1] = False; // Sell
                                                           // mit csinált a gyertya a dragonhoz képest ?
/*
      
      kilépett belõle ?
      
   */

      // lefelé
      if(dragonBottom[1]<Open[1] && dragonBottom[1]>Close[1] && dontesiMatrix[1]==False && dontesiMatrix[0]==False && dontesiMatrix[2]==False)
        { // most kilépett lefele!
         Print("kilépett lefelé!");
         piacraMegyek("sell",Symbol());
        }

      // felfelé
      if(dragonTop[1]>Open[1] && dragonTop[1]<Close[1] && dontesiMatrix[1]==True && dontesiMatrix[0]==True  && dontesiMatrix[2]==True)
        { // most kilépett lefele!
         Print("kilépett felfelé!");
         piacraMegyek("buy",Symbol());

        }

/*
   kiléphet úgy is, hogy a Dragon center line és a TL között nincs több mint 200pip. Ekkor is beszálhat a trade-be
   ilenkor az a kérdés, a dragonnál bottom vagy top lépett ki.
*/

      // tehát kilép lefelé, de vajon hány pipre van a TL-tõl?
      if(dragonBottom[1]<Open[1] && dragonBottom[1]>Close[1] && pips(True)<200.0 && dontesiMatrix[0]==True)
        {
         // a TL nem a dragon fölött van, de elég közel. (~200pip nél kevesebb). lefelé lépett ki
         Print("kilépett lefelé de a TL nem jó helyen van");
        }

      // tehát kilép felfelé
      if(dragonTop[1]>Open[1] && dragonTop[1]<Close[1] && pips(False)<200.0 && dontesiMatrix[0]==False)
        {
         // a TL nem a dragon alatt van, de elég közel. (~200pip nél kevesebb). felfelé lépett ki
         Print("Kilépett felfelé, de a TL nem jó helyen van");
        }

     }

  }

//+------------------------------------------------------------------+
