//+------------------------------------------------------------------+
//|                           EA4_DonchianChannel.mq5                  |
//| Donchian Channel Breakout Expert Advisor                         |
//| Referensi: René Balke - Fx Bot Trading                           |
//| https://www.youtube.com/watch?v=uz_BX5T1ER8                       |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots             = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe  = PERIOD_H1;
input int             DonchianPeriod   = 20;
input int             StopLossPoints   = 500;
input int             TakeProfitPoints = 1000;
input int             MagicNumber      = 20260911;
input int             MaxDeviation     = 20;

//------------------------- STATE ------------------------------------
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
   if(DonchianPeriod < 2)
     {
      Print("DonchianPeriod minimal 2");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
//| Mengambil batas atas Donchian dari candle sebelum candle sinyal  |
//+------------------------------------------------------------------+
double GetUpperChannel()
  {
   double highs[];

   if(CopyHigh(_Symbol,
               SignalTimeframe,
               2,
               DonchianPeriod,
               highs) != DonchianPeriod)
      return 0;

   int highestIndex = ArrayMaximum(highs);

   if(highestIndex < 0)
      return 0;

   return highs[highestIndex];
  }

//+------------------------------------------------------------------+
//| Mengambil batas bawah Donchian dari candle sebelum candle sinyal |
//+------------------------------------------------------------------+
double GetLowerChannel()
  {
   double lows[];

   if(CopyLow(_Symbol,
              SignalTimeframe,
              2,
              DonchianPeriod,
              lows) != DonchianPeriod)
      return 0;

   int lowestIndex = ArrayMinimum(lows);

   if(lowestIndex < 0)
      return 0;

   return lows[lowestIndex];
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
                 "EA4 Donchian BUY"))
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
                  "EA4 Donchian SELL"))
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

   if(Bars(_Symbol, SignalTimeframe) < DonchianPeriod + 3)
      return;

   double upperChannel = GetUpperChannel();
   double lowerChannel = GetLowerChannel();

   if(upperChannel == 0 || lowerChannel == 0)
      return;

   // Candle terakhir yang sudah selesai
   double signalClose = iClose(_Symbol, SignalTimeframe, 1);

   bool buySignal  = signalClose > upperChannel;
   bool sellSignal = signalClose < lowerChannel;

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   if(buySignal)
     {
      // Tutup SELL jika muncul breakout ke atas
      if(hasPosition && positionType == POSITION_TYPE_SELL)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("Breakout Upper Donchian -> buka BUY");
         OpenBuy();
        }
     }
   else if(sellSignal)
     {
      // Tutup BUY jika muncul breakout ke bawah
      if(hasPosition && positionType == POSITION_TYPE_BUY)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("Breakout Lower Donchian -> buka SELL");
         OpenSell();
        }
     }
  }
//+------------------------------------------------------------------+
