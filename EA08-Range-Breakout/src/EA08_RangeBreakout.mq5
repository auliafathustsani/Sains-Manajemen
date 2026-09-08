//+------------------------------------------------------------------+
//|                            EA8_RangeBreakout.mq5                  |
//| Range Breakout Expert Advisor                                    |
//| Referensi: René Balke - Fx Bot Trading                           |
//| https://www.youtube.com/watch?v=1Y6j8_9Hzgk                       |
//| Optimasi: https://www.youtube.com/watch?v=qCdqheZrK7M             |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots             = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe  = PERIOD_H1;
input int             RangeStartHour   = 0;
input int             RangeEndHour     = 6;
input int             TradeEndHour     = 20;
input int             StopLossPoints   = 500;
input int             TakeProfitPoints = 1000;
input int             MagicNumber      = 20260915;
input int             MaxDeviation     = 20;

//------------------------- STATE ------------------------------------
datetime lastBarTime = 0;
int      lastTradeDay = 0;

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
//| Membuat identitas tanggal dalam format YYYYMMDD                  |
//+------------------------------------------------------------------+
int GetDayKey(datetime timeValue)
  {
   MqlDateTime dt;
   TimeToStruct(timeValue, dt);

   return dt.year * 10000 + dt.mon * 100 + dt.day;
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(RangeStartHour < 0 ||
      RangeStartHour > 23 ||
      RangeEndHour <= RangeStartHour ||
      RangeEndHour > 23 ||
      TradeEndHour <= RangeEndHour ||
      TradeEndHour > 23)
     {
      Print("Pengaturan jam tidak valid. Gunakan RangeStart < RangeEnd < TradeEnd");
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
//| Mengambil harga tertinggi dan terendah pada periode range        |
//+------------------------------------------------------------------+
bool GetTodayRange(double &rangeHigh, double &rangeLow)
  {
   datetime currentTime = TimeCurrent();
   int todayKey = GetDayKey(currentTime);

   rangeHigh = -DBL_MAX;
   rangeLow  = DBL_MAX;

   int foundBars = 0;

   // Memindai maksimal 72 candle ke belakang
   for(int shift = 1; shift <= 72; shift++)
     {
      datetime barTime = iTime(_Symbol, SignalTimeframe, shift);

      if(barTime == 0)
         break;

      int barDayKey = GetDayKey(barTime);

      if(barDayKey < todayKey)
         break;

      if(barDayKey != todayKey)
         continue;

      MqlDateTime barDate;
      TimeToStruct(barTime, barDate);

      if(barDate.hour >= RangeStartHour &&
         barDate.hour < RangeEndHour)
        {
         double barHigh = iHigh(_Symbol, SignalTimeframe, shift);
         double barLow  = iLow(_Symbol, SignalTimeframe, shift);

         if(barHigh > rangeHigh)
            rangeHigh = barHigh;

         if(barLow < rangeLow)
            rangeLow = barLow;

         foundBars++;
        }
     }

   return foundBars > 0 &&
          rangeHigh != -DBL_MAX &&
          rangeLow != DBL_MAX;
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

   if(trade.Buy(volume,
                _Symbol,
                0,
                sl,
                tp,
                "EA8 Range Breakout BUY"))
     {
      lastTradeDay = GetDayKey(TimeCurrent());
     }
   else
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

   if(trade.Sell(volume,
                 _Symbol,
                 0,
                 sl,
                 tp,
                 "EA8 Range Breakout SELL"))
     {
      lastTradeDay = GetDayKey(TimeCurrent());
     }
   else
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

   datetime currentTime = TimeCurrent();

   MqlDateTime currentDate;
   TimeToStruct(currentTime, currentDate);

   int currentHour = currentDate.hour;
   int todayKey    = GetDayKey(currentTime);

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   // Tutup posisi saat periode trading berakhir
   if(currentHour >= TradeEndHour)
     {
      if(hasPosition)
        {
         Print("TradeEndHour tercapai -> tutup posisi");
         ClosePosition(ticket);
        }

      return;
     }

   // Jangan entry sebelum periode range selesai
   if(currentHour < RangeEndHour)
      return;

   // Maksimal satu entry setiap hari
   if(lastTradeDay == todayKey || hasPosition)
      return;

   double rangeHigh;
   double rangeLow;

   if(!GetTodayRange(rangeHigh, rangeLow))
     {
      Print("Data range hari ini belum tersedia");
      return;
     }

   // Menggunakan harga penutupan candle yang sudah selesai
   double signalClose = iClose(_Symbol, SignalTimeframe, 1);

   if(signalClose > rangeHigh)
     {
      PrintFormat("Breakout atas | Close=%.5f RangeHigh=%.5f",
                  signalClose,
                  rangeHigh);

      OpenBuy();
     }
   else if(signalClose < rangeLow)
     {
      PrintFormat("Breakout bawah | Close=%.5f RangeLow=%.5f",
                  signalClose,
                  rangeLow);

      OpenSell();
     }
  }
//+------------------------------------------------------------------+
