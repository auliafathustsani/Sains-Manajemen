//+------------------------------------------------------------------+
//|                                 EA10_RSIGrid.mq5                  |
//| RSI Grid Trading Expert Advisor                                  |
//| Referensi: René Balke - Fx Bot Trading                           |
//| https://www.youtube.com/watch?v=M1t_gg-nO48                       |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots               = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe    = PERIOD_H1;
input int             RSIPeriod          = 14;
input double          OversoldLevel      = 30.0;
input double          OverboughtLevel    = 70.0;
input int             GridDistancePoints = 500;
input int             MaxGridPositions   = 5;
input double          BasketProfitMoney  = 10.0;
input double          BasketLossMoney    = 50.0;
input int             MagicNumber        = 20260917;
input int             MaxDeviation       = 20;

//------------------------- STATE ------------------------------------
int      rsiHandle   = INVALID_HANDLE;
datetime lastBarTime = 0;

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
int OnInit()
  {
   if(RSIPeriod < 2 ||
      OversoldLevel <= 0 ||
      OverboughtLevel >= 100 ||
      OversoldLevel >= OverboughtLevel ||
      GridDistancePoints <= 0 ||
      MaxGridPositions < 1 ||
      BasketProfitMoney <= 0 ||
      BasketLossMoney <= 0)
     {
      Print("Parameter RSI Grid tidak valid");
      return INIT_PARAMETERS_INCORRECT;
     }

   // EA grid ini dirancang untuk akun hedging
   ENUM_ACCOUNT_MARGIN_MODE marginMode =
      (ENUM_ACCOUNT_MARGIN_MODE)
      AccountInfoInteger(ACCOUNT_MARGIN_MODE);

   if(marginMode != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Print("EA10 RSI Grid membutuhkan akun bertipe Hedging");
      return INIT_FAILED;
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
//| Mengambil informasi seluruh posisi grid milik EA                 |
//+------------------------------------------------------------------+
int GetBasketInformation(ENUM_POSITION_TYPE &basketType,
                         double &basketProfit,
                         double &outerEntryPrice)
  {
   int positionCount = 0;
   basketProfit      = 0;
   outerEntryPrice   = 0;

   bool typeAssigned = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      ENUM_POSITION_TYPE currentType =
         (ENUM_POSITION_TYPE)
         PositionGetInteger(POSITION_TYPE);

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

      basketProfit += PositionGetDouble(POSITION_PROFIT);
      basketProfit += PositionGetDouble(POSITION_SWAP);

      if(!typeAssigned)
        {
         basketType     = currentType;
         outerEntryPrice = openPrice;
         typeAssigned   = true;
        }

      // Untuk BUY, posisi grid terakhir berada pada harga terendah
      if(currentType == POSITION_TYPE_BUY &&
         openPrice < outerEntryPrice)
         outerEntryPrice = openPrice;

      // Untuk SELL, posisi grid terakhir berada pada harga tertinggi
      if(currentType == POSITION_TYPE_SELL &&
         openPrice > outerEntryPrice)
         outerEntryPrice = openPrice;

      positionCount++;
     }

   return positionCount;
  }

//+------------------------------------------------------------------+
//| Menutup semua posisi grid milik EA                               |
//+------------------------------------------------------------------+
void CloseBasket()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         if(!trade.PositionClose(ticket))
           {
            Print("Gagal menutup posisi #",
                  ticket,
                  ": ",
                  trade.ResultRetcodeDescription());
           }
        }
     }
  }

//+------------------------------------------------------------------+
bool OpenBuy(string commentText)
  {
   double volume = NormalizeVolume(Lots);

   if(!trade.Buy(volume,
                 _Symbol,
                 0,
                 0,
                 0,
                 commentText))
     {
      Print("BUY gagal: ", trade.ResultRetcodeDescription());
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
bool OpenSell(string commentText)
  {
   double volume = NormalizeVolume(Lots);

   if(!trade.Sell(volume,
                  _Symbol,
                  0,
                  0,
                  0,
                  commentText))
     {
      Print("SELL gagal: ", trade.ResultRetcodeDescription());
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Memeriksa target profit/rugi dan menambah posisi grid            |
//+------------------------------------------------------------------+
void ManageExistingBasket(int positionCount,
                          ENUM_POSITION_TYPE basketType,
                          double basketProfit,
                          double outerEntryPrice)
  {
   // Tutup seluruh basket ketika target profit tercapai
   if(basketProfit >= BasketProfitMoney)
     {
      PrintFormat("Target basket tercapai: %.2f -> tutup semua posisi",
                  basketProfit);

      CloseBasket();
      return;
     }

   // Stop loss darurat untuk seluruh basket
   if(basketProfit <= -BasketLossMoney)
     {
      PrintFormat("Batas rugi basket tercapai: %.2f -> tutup semua posisi",
                  basketProfit);

      CloseBasket();
      return;
     }

   if(positionCount >= MaxGridPositions)
      return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(point <= 0)
      return;

   // Tambah BUY ketika harga turun sejauh GridDistance
   if(basketType == POSITION_TYPE_BUY)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double triggerPrice =
         outerEntryPrice - GridDistancePoints * point;

      if(bid <= triggerPrice)
        {
         PrintFormat("Tambah BUY grid ke-%d", positionCount + 1);
         OpenBuy("EA10 RSI Grid BUY");
        }
     }

   // Tambah SELL ketika harga naik sejauh GridDistance
   else if(basketType == POSITION_TYPE_SELL)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double triggerPrice =
         outerEntryPrice + GridDistancePoints * point;

      if(ask >= triggerPrice)
        {
         PrintFormat("Tambah SELL grid ke-%d", positionCount + 1);
         OpenSell("EA10 RSI Grid SELL");
        }
     }
  }

//+------------------------------------------------------------------+
//| Membuka posisi pertama berdasarkan RSI                           |
//+------------------------------------------------------------------+
void CheckInitialEntry()
  {
   if(!IsNewBar())
      return;

   if(BarsCalculated(rsiHandle) < RSIPeriod + 3)
      return;

   double rsiValue[1];

   // Menggunakan candle terakhir yang sudah selesai
   if(CopyBuffer(rsiHandle, 0, 1, 1, rsiValue) != 1)
     {
      Print("Gagal mengambil data RSI");
      return;
     }

   if(rsiValue[0] <= OversoldLevel)
     {
      PrintFormat("RSI %.2f oversold -> buka BUY pertama",
                  rsiValue[0]);

      OpenBuy("EA10 RSI Grid BUY awal");
     }
   else if(rsiValue[0] >= OverboughtLevel)
     {
      PrintFormat("RSI %.2f overbought -> buka SELL pertama",
                  rsiValue[0]);

      OpenSell("EA10 RSI Grid SELL awal");
     }
  }

//+------------------------------------------------------------------+
//| Logika utama                                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   ENUM_POSITION_TYPE basketType = POSITION_TYPE_BUY;
   double basketProfit   = 0;
   double outerEntryPrice = 0;

   int positionCount =
      GetBasketInformation(basketType,
                           basketProfit,
                           outerEntryPrice);

   if(positionCount > 0)
     {
      ManageExistingBasket(positionCount,
                           basketType,
                           basketProfit,
                           outerEntryPrice);

      return;
     }

   CheckInitialEntry();
  }
//+------------------------------------------------------------------+
