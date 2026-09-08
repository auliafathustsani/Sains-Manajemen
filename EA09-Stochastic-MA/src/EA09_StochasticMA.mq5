//+------------------------------------------------------------------+
//|                              EA9_StochasticMA.mq5                 |
//| Stochastic Moving Average Expert Advisor                         |
//| Referensi: René Balke - Fx Bot Trading                           |
//| https://www.youtube.com/watch?v=YrzfNo8iKlw                       |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots             = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe  = PERIOD_H1;
input int             KPeriod          = 5;
input int             DPeriod          = 3;
input int             Slowing          = 3;
input double          OversoldLevel    = 20.0;
input double          OverboughtLevel  = 80.0;
input int             MAPeriod         = 50;
input int             StopLossPoints   = 500;
input int             TakeProfitPoints = 1000;
input int             MagicNumber      = 20260916;
input int             MaxDeviation     = 20;

//------------------------- STATE ------------------------------------
int      stochasticHandle = INVALID_HANDLE;
int      maHandle         = INVALID_HANDLE;
datetime lastBarTime      = 0;

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
   if(KPeriod < 2 ||
      DPeriod < 1 ||
      Slowing < 1 ||
      MAPeriod < 2 ||
      OversoldLevel <= 0 ||
      OverboughtLevel >= 100 ||
      OversoldLevel >= OverboughtLevel)
     {
      Print("Parameter Stochastic atau Moving Average tidak valid");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   stochasticHandle = iStochastic(_Symbol,
                                  SignalTimeframe,
                                  KPeriod,
                                  DPeriod,
                                  Slowing,
                                  MODE_SMA,
                                  STO_LOWHIGH);

   maHandle = iMA(_Symbol,
                  SignalTimeframe,
                  MAPeriod,
                  0,
                  MODE_EMA,
                  PRICE_CLOSE);

   if(stochasticHandle == INVALID_HANDLE ||
      maHandle == INVALID_HANDLE)
     {
      Print("Gagal membuat indikator Stochastic atau Moving Average");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(stochasticHandle != INVALID_HANDLE)
      IndicatorRelease(stochasticHandle);

   if(maHandle != INVALID_HANDLE)
      IndicatorRelease(maHandle);
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
                 "EA9 Stochastic MA BUY"))
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
                  "EA9 Stochastic MA SELL"))
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

   if(BarsCalculated(stochasticHandle) < MAPeriod + 10 ||
      BarsCalculated(maHandle) < MAPeriod + 10)
      return;

   double mainLine[2];
   double signalLine[2];
   double movingAverage[1];

   // Buffer 0 Stochastic = Main line
   // Buffer 1 Stochastic = Signal line
   if(CopyBuffer(stochasticHandle, 0, 1, 2, mainLine) != 2 ||
      CopyBuffer(stochasticHandle, 1, 1, 2, signalLine) != 2 ||
      CopyBuffer(maHandle, 0, 1, 1, movingAverage) != 1)
     {
      Print("Gagal mengambil data indikator");
      return;
     }

   // CopyBuffer menempatkan candle lama pada indeks 0
   // dan candle terakhir selesai pada indeks 1
   double previousMain   = mainLine[0];
   double currentMain    = mainLine[1];
   double previousSignal = signalLine[0];
   double currentSignal  = signalLine[1];

   double currentMA    = movingAverage[0];
   double currentClose = iClose(_Symbol, SignalTimeframe, 1);

   // Crossover bullish dari area oversold dan harga di atas MA
   bool buySignal =
      previousMain <= previousSignal &&
      currentMain > currentSignal &&
      previousMain <= OversoldLevel &&
      currentClose > currentMA;

   // Crossover bearish dari area overbought dan harga di bawah MA
   bool sellSignal =
      previousMain >= previousSignal &&
      currentMain < currentSignal &&
      previousMain >= OverboughtLevel &&
      currentClose < currentMA;

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
         Print("Stochastic bullish + harga di atas MA -> buka BUY");
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
         Print("Stochastic bearish + harga di bawah MA -> buka SELL");
         OpenSell();
        }
     }
  }
//+------------------------------------------------------------------+
