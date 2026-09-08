//+------------------------------------------------------------------+
//|                  TurnaroundTuesday_EA.mq5                         |
//|  Membuka posisi BUY pada Senin dan menutupnya pada Selasa         |
//+------------------------------------------------------------------+
#property copyright "Aulia Fathus Tsani"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

// Pengaturan EA
input double Lots            = 0.01;
input int    OpenHour        = 20;       // Jam buka pada hari Senin
input int    CloseHour       = 20;       // Jam tutup pada hari Selasa
input int    StopLossPoints  = 0;        // 0 = tanpa Stop Loss
input int    TakeProfitPoints= 0;        // 0 = tanpa Take Profit
input ulong  MagicNumber     = 100001;
input int    MaxDeviation    = 20;

int lastOpenWeek = -1;

//+------------------------------------------------------------------+
//| Inisialisasi EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   Print("Turnaround Tuesday EA berhasil dijalankan.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Mengecek posisi milik EA                                         |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);

      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Membuka posisi BUY                                               |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl  = 0.0;
   double tp  = 0.0;

   if(StopLossPoints > 0)
      sl = NormalizeDouble(ask - StopLossPoints * _Point, _Digits);

   if(TakeProfitPoints > 0)
      tp = NormalizeDouble(ask + TakeProfitPoints * _Point, _Digits);

   if(trade.Buy(Lots, _Symbol, 0.0, sl, tp, "Turnaround Tuesday"))
      Print("Posisi BUY berhasil dibuka.");
   else
      Print("Gagal membuka BUY. Error: ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//| Menutup seluruh posisi milik EA                                  |
//+------------------------------------------------------------------+
void ClosePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);

      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         if(trade.PositionClose(ticket))
            Print("Posisi berhasil ditutup pada hari Selasa.");
         else
            Print("Gagal menutup posisi. Error: ",
                  trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//| Program utama                                                    |
//+------------------------------------------------------------------+
void OnTick()
{
   MqlDateTime currentTime;
   TimeToStruct(TimeCurrent(), currentTime);

   // Membuat nomor minggu sederhana agar tidak membuka posisi berulang
   int currentWeek = currentTime.year * 100 +
                     currentTime.day_of_year / 7;

   // Senin = 1
   if(currentTime.day_of_week == 1 &&
      currentTime.hour >= OpenHour &&
      lastOpenWeek != currentWeek &&
      !HasOpenPosition())
   {
      OpenBuyPosition();
      lastOpenWeek = currentWeek;
   }

   // Selasa = 2
   if(currentTime.day_of_week == 2 &&
      currentTime.hour >= CloseHour &&
      HasOpenPosition())
   {
      ClosePositions();
   }
}
//+------------------------------------------------------------------+
