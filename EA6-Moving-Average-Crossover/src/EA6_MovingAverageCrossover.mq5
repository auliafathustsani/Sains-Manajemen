//+------------------------------------------------------------------+
//|                    EA6_MovingAverageCrossover.mq5                 |
//| Moving Average Crossover Expert Advisor                          |
//| Referensi: Antovis Analytics                                     |
//| https://www.youtube.com/watch?v=h8lZCEpiFOI                       |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots             = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe  = PERIOD_H1;
input int             FastMAPeriod     = 10;
input int             SlowMAPeriod     = 30;
input ENUM_MA_METHOD  MAMethod         = MODE_EMA;
input int             StopLossPoints   = 500;
input int             TakeProfitPoints = 1000;
input int             MagicNumber      = 20260913;
input int             MaxDeviation     = 20;

//------------------------- STATE ------------------------------------
int      fastMAHandle = INVALID_HANDLE;
int      slowMAHandle = INVALID_HANDLE;
datetime lastBarTime  = 0;

//+------------------------------------------------------------------+
//| Menyesuaikan lot dengan ketentuan broker                         |
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
//| Inisialisasi EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(FastMAPeriod < 2 ||
      SlowMAPeriod < 3 ||
      FastMAPeriod >= SlowMAPeriod)
     {
      Print("Parameter tidak valid: Fast MA harus lebih kecil dari Slow MA");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   fastMAHandle = iMA(_Symbol,
                      SignalTimeframe,
                      FastMAPeriod,
                      0,
                      MAMethod,
                      PRICE_CLOSE);

   slowMAHandle = iMA(_Symbol,
                      SignalTimeframe,
                      SlowMAPeriod,
                      0,
                      MAMethod,
                      PRICE_CLOSE);

   if(fastMAHandle == INVALID_HANDLE ||
      slowMAHandle == INVALID_HANDLE)
     {
      Print("Gagal membuat indikator Moving Average");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Membersihkan indikator ketika EA dihentikan                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(fastMAHandle != INVALID_HANDLE)
      IndicatorRelease(fastMAHandle);

   if(slowMAHandle != INVALID_HANDLE)
      IndicatorRelease(slowMAHandle);
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
//| Mencari posisi milik EA pada simbol yang sedang digunakan        |
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
//| Menutup posisi                                                   |
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
//| Membuka posisi BUY                                               |
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
                 "EA6 MA BUY"))
     {
      Print("BUY gagal: ", trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| Membuka posisi SELL                                              |
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
                  "EA6 MA SELL"))
     {
      Print("SELL gagal: ", trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| Logika utama EA                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;

   if(BarsCalculated(fastMAHandle) < SlowMAPeriod + 3 ||
      BarsCalculated(slowMAHandle) < SlowMAPeriod + 3)
      return;

   double fastMA[2];
   double slowMA[2];

   // CopyBuffer menyimpan candle lama pada indeks 0
   // dan candle terakhir yang selesai pada indeks 1
   if(CopyBuffer(fastMAHandle, 0, 1, 2, fastMA) != 2 ||
      CopyBuffer(slowMAHandle, 0, 1, 2, slowMA) != 2)
     {
      Print("Gagal mengambil data Moving Average");
      return;
     }

   double previousFast = fastMA[0];
   double currentFast  = fastMA[1];
   double previousSlow = slowMA[0];
   double currentSlow  = slowMA[1];

   bool bullishCross =
      previousFast <= previousSlow &&
      currentFast > currentSlow;

   bool bearishCross =
      previousFast >= previousSlow &&
      currentFast < currentSlow;

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   // Sinyal BUY
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
         Print("Fast MA memotong Slow MA ke atas -> buka BUY");
         OpenBuy();
        }
     }

   // Sinyal SELL
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
         Print("Fast MA memotong Slow MA ke bawah -> buka SELL");
         OpenSell();
        }
     }
  }
//+------------------------------------------------------------------+
