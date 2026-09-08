//+------------------------------------------------------------------+
//|                                   TurnaroundTuesday_EA_v2.mq5     |
//|  Referensi strategi: Rene Balke (BM Trading)                      |
//|  https://www.youtube.com/watch?v=3DI7IOyCQLg                      |
//|                                                                    |
//|  Konsep: Buy di hari Senin saat harga menunjukkan "setback"        |
//|  (penurunan) dari penutupan minggu sebelumnya, lalu tutup posisi   |
//|  di hari Selasa untuk memanfaatkan momentum recovery.              |
//|  Versi ini menambahkan filter setback yang belum ada di versi v1.  |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------- INPUT (sama seperti versi awal) -------------------
input double Lots               = 1.0;   // Lot size
input int    OpenHour           = 20;     // Jam buka posisi (hari Senin)
input int    CloseHour          = 20;     // Jam tutup posisi (hari Selasa)
input int    StopLossPoints     = 0;      // Stop Loss (points), 0 = tanpa SL
input int    TakeProfitPoints   = 0;      // Take Profit (points), 0 = tanpa TP
input int    MagicNumber        = 20260908;
input int    MaxDeviation       = 20;

//------------------- INPUT BARU: FILTER SETBACK -------------------
input bool   UseSetbackFilter      = true;   // Aktifkan filter setback
input double SetbackThresholdPoints = 100;   // Minimal penurunan (points) dari Close Jumat agar dianggap "setback"
input int    LookbackFridayShift    = 1;     // Berapa hari kerja ke belakang untuk ambil Close "Jumat" (candle harian D1)

//------------------- STATE -------------------
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
//| Cek apakah candle H1 baru sudah terbentuk (supaya logic hanya    |
//| dieksekusi sekali per jam, bukan tiap tick)                      |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime currentBarTime = iTime(_Symbol, PERIOD_H1, 0);
   if(currentBarTime != lastBarTime)
     {
      lastBarTime = currentBarTime;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Ambil Close candle Jumat (D1) sebagai acuan "sebelum weekend"    |
//+------------------------------------------------------------------+
double GetFridayClose()
  {
   // shift=0 adalah candle D1 berjalan (hari ini / Senin belum close),
   // shift=1 biasanya candle Jumat karena pasar tutup Sabtu-Minggu
   return iClose(_Symbol, PERIOD_D1, LookbackFridayShift);
  }

//+------------------------------------------------------------------+
//| Cek apakah kondisi "setback" terpenuhi                           |
//| Setback = harga saat ini sudah turun minimal SetbackThresholdPoints|
//| dari Close Jumat minggu lalu                                     |
//+------------------------------------------------------------------+
bool IsSetbackDetected()
  {
   if(!UseSetbackFilter)
      return true; // filter dimatikan -> selalu izinkan (perilaku sama seperti versi awal)

   double fridayClose = GetFridayClose();
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double dropPoints = (fridayClose - currentPrice) / point;

   PrintFormat("Cek setback | FridayClose=%.5f CurrentPrice=%.5f DropPoints=%.1f Threshold=%.1f",
               fridayClose, currentPrice, dropPoints, SetbackThresholdPoints);

   return (dropPoints >= SetbackThresholdPoints);
  }

//+------------------------------------------------------------------+
//| Cek apakah sudah ada posisi terbuka dari EA ini                  |
//+------------------------------------------------------------------+
bool HasOpenPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Tutup semua posisi milik EA ini                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
         trade.PositionClose(ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//| Buka posisi BUY dengan SL/TP opsional                            |
//+------------------------------------------------------------------+
void OpenBuy()
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double sl = (StopLossPoints > 0)   ? ask - StopLossPoints   * point : 0;
   double tp = (TakeProfitPoints > 0) ? ask + TakeProfitPoints * point : 0;

   trade.Buy(Lots, _Symbol, ask, sl, tp, "Turnaround Tuesday v2");
  }

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int dow  = dt.day_of_week; // 0=Minggu, 1=Senin, 2=Selasa, ...
   int hour = dt.hour;

   // ---------- ENTRY: Senin jam OpenHour ----------
   if(dow == 1 && hour == OpenHour && !HasOpenPosition())
     {
      if(IsSetbackDetected())
        {
         Print("Setback terdeteksi -> buka posisi BUY (Turnaround Tuesday)");
         OpenBuy();
        }
      else
        {
         Print("Tidak ada setback signifikan hari ini -> skip entry Senin");
        }
     }

   // ---------- EXIT: Selasa jam CloseHour ----------
   if(dow == 2 && hour == CloseHour && HasOpenPosition())
     {
      Print("Waktunya tutup posisi Turnaround Tuesday (hari Selasa)");
      CloseAllPositions();
     }
  }
//+------------------------------------------------------------------+
