//+------------------------------------------------------------------+
//|                              EA5_RSIReversal.mq5                  |
//| RSI Oversold-Overbought Reversal Expert Advisor                  |
//| Referensi: Antovis Analytics                                     |
//| https://www.youtube.com/watch?v=jjI8_omc8Gc                       |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots             = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe  = PERIOD_H1;
input int             RSIPeriod        = 14;
input double          OversoldLevel    = 30.0;
input double          OverboughtLevel  = 70.0;
input int             StopLossPoints   = 500;
input int             TakeProfitPoints = 1000;
input int             MagicNumber      = 20260912;
input int             MaxDeviation     = 20;

//------------------------- STATE ------------------------------------
int      rsiHandle   = INVALID_HANDLE;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Menyesuaikan volume dengan ketentuan broker                      |
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

   int volumeDigits = 0;

   if(step < 1.0)
      volumeDigits = (int)MathCeil(-MathLog10(step));

   return NormalizeDouble(volume, volumeDigits);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(RSIPeriod < 2 ||
      OversoldLevel <= 0 ||
      OverboughtLevel >= 100 ||
      OversoldLevel >= OverboughtLevel)
     {
      Print("Parameter RSI tidak valid");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   rsiHandle = iRSI(_Symbol,
                    SignalTimeframe,
                    RSIPeriod,
                    PRICE_CLOSE);

   if(rsiHandle == INVALID_HANDLE)
     {
      Print("Gagal membuat indikator RSI");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(rsiHandle != INVALID_HANDLE)
      IndicatorRelease(rsiHandle);
  }

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
//| Mencari posisi milik EA                                          |
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
bool ClosePosition(ulong ticket)
  {
   if(!trade.PositionClose(ticket))
     {
      Print("Gagal menutup posisi: ",
            trade.ResultRetcodeDescription());

      return false;
     }

   return true;
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

   if(!trade.Buy(volume,
                 _Symbol,
                 0,
                 sl,
                 tp,
                 "EA5 RSI BUY"))
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

   if(!trade.Sell(volume,
                  _Symbol,
                  0,
                  sl,
                  tp,
                  "EA5 RSI SELL"))
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

   if(BarsCalculated(rsiHandle) < RSIPeriod + 3)
      return;

   double rsiValues[2];

   // CopyBuffer menyimpan candle lama di indeks 0 dan terbaru di indeks 1
   if(CopyBuffer(rsiHandle, 0, 1, 2, rsiValues) != 2)
     {
      Print("Gagal mengambil data RSI");
      return;
     }

   double previousRSI = rsiValues[0];
   double currentRSI  = rsiValues[1];

   // BUY ketika RSI keluar dari area oversold
   bool buySignal =
      previousRSI <= OversoldLevel &&
      currentRSI > OversoldLevel;

   // SELL ketika RSI keluar dari area overbought
   bool sellSignal =
      previousRSI >= OverboughtLevel &&
      currentRSI < OverboughtLevel;

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   if(buySignal)
     {
      if(hasPosition && positionType == POSITION_TYPE_SELL)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("RSI keluar dari oversold -> buka BUY");
         OpenBuy();
        }
     }
   else if(sellSignal)
     {
      if(hasPosition && positionType == POSITION_TYPE_BUY)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("RSI keluar dari overbought -> buka SELL");
         OpenSell();
        }
     }
  }
//+------------------------------------------------------------------+
