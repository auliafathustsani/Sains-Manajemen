//+------------------------------------------------------------------+
//|                              EA2_BollingerBands.mq5               |
//| Bollinger Bands Mean Reversion Expert Advisor                    |
//| Referensi: https://youtu.be/Z0rQqBUyusk                           |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots               = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe    = PERIOD_H1;
input int             BollingerPeriod    = 20;
input double          BollingerDeviation = 2.0;
input int             StopLossPoints     = 500;
input int             TakeProfitPoints   = 1000;
input int             MagicNumber        = 20260909;
input int             MaxDeviation       = 20;

//------------------------- STATE ------------------------------------
int      bandsHandle = INVALID_HANDLE;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Menyesuaikan lot dengan batas minimum broker                     |
//+------------------------------------------------------------------+
double NormalizeVolume(double requestedLots)
  {
   double minimum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maximum = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0)
      return requestedLots;

   double volume = MathMax(minimum, MathMin(maximum, requestedLots));
   volume = MathFloor(volume / step + 0.5) * step;

   return NormalizeDouble(volume, 2);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   bandsHandle = iBands(_Symbol,
                        SignalTimeframe,
                        BollingerPeriod,
                        0,
                        BollingerDeviation,
                        PRICE_CLOSE);

   if(bandsHandle == INVALID_HANDLE)
     {
      Print("Gagal membuat indikator Bollinger Bands");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(bandsHandle != INVALID_HANDLE)
      IndicatorRelease(bandsHandle);
  }

//+------------------------------------------------------------------+
//| Menjalankan logika sekali setiap candle baru                     |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime currentBar = iTime(_Symbol, SignalTimeframe, 0);

   if(currentBar == 0)
      return false;

   if(currentBar != lastBarTime)
     {
      lastBarTime = currentBar;
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Mencari posisi milik EA pada simbol yang sedang diuji            |
//+------------------------------------------------------------------+
bool GetEAPosition(ulong &ticket, ENUM_POSITION_TYPE &positionType)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong currentTicket = PositionGetTicket(i);

      if(currentTicket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         ticket       = currentTicket;
         positionType = (ENUM_POSITION_TYPE)
                        PositionGetInteger(POSITION_TYPE);
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
void OpenBuy()
  {
   double volume = NormalizeVolume(Lots);
   double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double sl = StopLossPoints > 0
               ? NormalizeDouble(ask - StopLossPoints * point, _Digits)
               : 0;

   double tp = TakeProfitPoints > 0
               ? NormalizeDouble(ask + TakeProfitPoints * point, _Digits)
               : 0;

   if(!trade.Buy(volume, _Symbol, 0, sl, tp,
                 "EA2 Bollinger BUY"))
     {
      Print("BUY gagal: ", trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
void OpenSell()
  {
   double volume = NormalizeVolume(Lots);
   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double sl = StopLossPoints > 0
               ? NormalizeDouble(bid + StopLossPoints * point, _Digits)
               : 0;

   double tp = TakeProfitPoints > 0
               ? NormalizeDouble(bid - TakeProfitPoints * point, _Digits)
               : 0;

   if(!trade.Sell(volume, _Symbol, 0, sl, tp,
                  "EA2 Bollinger SELL"))
     {
      Print("SELL gagal: ", trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| Logika utama                                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;

   if(BarsCalculated(bandsHandle) < BollingerPeriod + 2)
      return;

   double middleBand[1];
   double upperBand[1];
   double lowerBand[1];

   // Buffer Bollinger Bands:
   // 0 = Middle, 1 = Upper, 2 = Lower
   if(CopyBuffer(bandsHandle, 0, 1, 1, middleBand) != 1 ||
      CopyBuffer(bandsHandle, 1, 1, 1, upperBand)  != 1 ||
      CopyBuffer(bandsHandle, 2, 1, 1, lowerBand)  != 1)
     {
      Print("Gagal mengambil data Bollinger Bands");
      return;
     }

   // Menggunakan candle yang sudah selesai (shift 1)
   double candleClose = iClose(_Symbol, SignalTimeframe, 1);

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   // EXIT: harga kembali ke Middle Band
   if(hasPosition)
     {
      bool closeBuy =
         positionType == POSITION_TYPE_BUY &&
         candleClose >= middleBand[0];

      bool closeSell =
         positionType == POSITION_TYPE_SELL &&
         candleClose <= middleBand[0];

      if(closeBuy || closeSell)
        {
         if(!trade.PositionClose(ticket))
            Print("Gagal menutup posisi: ",
                  trade.ResultRetcodeDescription());
        }

      return;
     }

   // ENTRY mean reversion
   if(candleClose <= lowerBand[0])
     {
      Print("Harga di bawah Lower Band -> buka BUY");
      OpenBuy();
     }
   else if(candleClose >= upperBand[0])
     {
      Print("Harga di atas Upper Band -> buka SELL");
      OpenSell();
     }
  }
//+------------------------------------------------------------------+
