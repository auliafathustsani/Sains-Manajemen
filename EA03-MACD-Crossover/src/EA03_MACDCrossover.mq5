//+------------------------------------------------------------------+
//|                            EA3_MACD_Crossover.mq5                  |
//| MACD Crossover Expert Advisor                                    |
//| Referensi: https://youtu.be/tSCtmXv25nM                           |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots            = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe = PERIOD_H1;
input int             FastEMA         = 12;
input int             SlowEMA         = 26;
input int             SignalPeriod    = 9;
input int             StopLossPoints  = 500;
input int             TakeProfitPoints= 1000;
input int             MagicNumber     = 20260910;
input int             MaxDeviation    = 20;

//------------------------- STATE ------------------------------------
int      macdHandle  = INVALID_HANDLE;
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
   if(FastEMA <= 0 || SlowEMA <= 0 ||
      SignalPeriod <= 0 || FastEMA >= SlowEMA)
     {
      Print("Parameter MACD tidak valid: FastEMA harus lebih kecil dari SlowEMA");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   macdHandle = iMACD(_Symbol,
                      SignalTimeframe,
                      FastEMA,
                      SlowEMA,
                      SignalPeriod,
                      PRICE_CLOSE);

   if(macdHandle == INVALID_HANDLE)
     {
      Print("Gagal membuat indikator MACD");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(macdHandle != INVALID_HANDLE)
      IndicatorRelease(macdHandle);
  }

//+------------------------------------------------------------------+
//| Menjalankan logika satu kali setiap candle baru                  |
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

   if(!trade.Buy(volume, _Symbol, 0, sl, tp, "EA3 MACD BUY"))
      Print("BUY gagal: ", trade.ResultRetcodeDescription());
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

   if(!trade.Sell(volume, _Symbol, 0, sl, tp, "EA3 MACD SELL"))
      Print("SELL gagal: ", trade.ResultRetcodeDescription());
  }

//+------------------------------------------------------------------+
//| Logika utama                                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;

   if(BarsCalculated(macdHandle) < SlowEMA + SignalPeriod + 3)
      return;

   double mainLine[2];
   double signalLine[2];

   // Mengambil candle yang sudah selesai:
   // indeks 0 = candle terakhir, indeks 1 = candle sebelumnya
   if(CopyBuffer(macdHandle, 0, 1, 2, mainLine) != 2 ||
      CopyBuffer(macdHandle, 1, 1, 2, signalLine) != 2)
     {
      Print("Gagal mengambil data MACD");
      return;
     }
   
   double previousMain   = mainLine[0];
   double currentMain    = mainLine[1];
   double previousSignal = signalLine[0];
   double currentSignal  = signalLine[1];

   bool bullishCross =
      previousMain <= previousSignal &&
      currentMain > currentSignal;

   bool bearishCross =
      previousMain >= previousSignal &&
      currentMain < currentSignal;

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   if(bullishCross)
     {
      if(hasPosition && positionType == POSITION_TYPE_SELL)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("MACD bullish crossover -> buka BUY");
         OpenBuy();
        }
     }
   else if(bearishCross)
     {
      if(hasPosition && positionType == POSITION_TYPE_BUY)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("MACD bearish crossover -> buka SELL");
         OpenSell();
        }
     }
  }
//+------------------------------------------------------------------+
