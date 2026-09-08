//+------------------------------------------------------------------+
//|                               EA7_Supertrend.mq5                  |
//| Supertrend Trend-Following Expert Advisor                        |
//| Referensi: René Balke - Fx Bot Trading                           |
//| Part 1: https://www.youtube.com/watch?v=acaqusyaeXc               |
//+------------------------------------------------------------------+
#property copyright "Project 1 - EA dengan AI"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//------------------------- INPUT ------------------------------------
input double          Lots             = 0.01;
input ENUM_TIMEFRAMES SignalTimeframe  = PERIOD_H1;
input int             ATRPeriod        = 10;
input double          Multiplier       = 3.0;
input int             StopLossPoints   = 500;
input int             TakeProfitPoints = 1000;
input int             MagicNumber      = 20260914;
input int             MaxDeviation     = 20;

//------------------------- STATE ------------------------------------
int      atrHandle   = INVALID_HANDLE;
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
   if(ATRPeriod < 2 || Multiplier <= 0)
     {
      Print("Parameter Supertrend tidak valid");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxDeviation);

   atrHandle = iATR(_Symbol, SignalTimeframe, ATRPeriod);

   if(atrHandle == INVALID_HANDLE)
     {
      Print("Gagal membuat indikator ATR");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
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
//| Menghitung arah Supertrend dua candle terakhir yang telah selesai|
//| Direction: 1 = bullish, -1 = bearish                             |
//+------------------------------------------------------------------+
bool GetSupertrendDirections(int &previousDirection,
                             int &currentDirection)
  {
   int calculationBars = MathMax(ATRPeriod + 100, 300);

   MqlRates rates[];
   double atrValues[];
   double finalUpper[];
   double finalLower[];
   int directions[];

   int copiedRates = CopyRates(_Symbol,
                               SignalTimeframe,
                               1,
                               calculationBars,
                               rates);

   int copiedATR = CopyBuffer(atrHandle,
                              0,
                              1,
                              calculationBars,
                              atrValues);

   if(copiedRates < ATRPeriod + 10 ||
      copiedATR != copiedRates)
     {
      Print("Data Supertrend belum mencukupi");
      return false;
     }

   ArrayResize(finalUpper, copiedRates);
   ArrayResize(finalLower, copiedRates);
   ArrayResize(directions, copiedRates);

   // Data hasil CopyRates tersusun dari candle lama menuju candle baru
   for(int i = 0; i < copiedRates; i++)
     {
      double middlePrice = (rates[i].high + rates[i].low) / 2.0;
      double basicUpper  = middlePrice + Multiplier * atrValues[i];
      double basicLower  = middlePrice - Multiplier * atrValues[i];

      if(i == 0)
        {
         finalUpper[i] = basicUpper;
         finalLower[i] = basicLower;
         directions[i] = rates[i].close >= middlePrice ? 1 : -1;
         continue;
        }

      if(basicUpper < finalUpper[i - 1] ||
         rates[i - 1].close > finalUpper[i - 1])
         finalUpper[i] = basicUpper;
      else
         finalUpper[i] = finalUpper[i - 1];

      if(basicLower > finalLower[i - 1] ||
         rates[i - 1].close < finalLower[i - 1])
         finalLower[i] = basicLower;
      else
         finalLower[i] = finalLower[i - 1];

      directions[i] = directions[i - 1];

      if(directions[i - 1] == -1 &&
         rates[i].close > finalUpper[i])
         directions[i] = 1;

      else if(directions[i - 1] == 1 &&
              rates[i].close < finalLower[i])
         directions[i] = -1;
     }

   previousDirection = directions[copiedRates - 2];
   currentDirection  = directions[copiedRates - 1];

   return true;
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
                 "EA7 Supertrend BUY"))
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
                  "EA7 Supertrend SELL"))
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

   if(BarsCalculated(atrHandle) < ATRPeriod + 100)
      return;

   int previousDirection;
   int currentDirection;

   if(!GetSupertrendDirections(previousDirection, currentDirection))
      return;

   bool bullishChange =
      previousDirection == -1 &&
      currentDirection == 1;

   bool bearishChange =
      previousDirection == 1 &&
      currentDirection == -1;

   ulong ticket = 0;
   ENUM_POSITION_TYPE positionType;
   bool hasPosition = GetEAPosition(ticket, positionType);

   if(bullishChange)
     {
      if(hasPosition && positionType == POSITION_TYPE_SELL)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("Supertrend berubah bullish -> buka BUY");
         OpenBuy();
        }
     }
   else if(bearishChange)
     {
      if(hasPosition && positionType == POSITION_TYPE_BUY)
        {
         if(!ClosePosition(ticket))
            return;

         hasPosition = false;
        }

      if(!hasPosition)
        {
         Print("Supertrend berubah bearish -> buka SELL");
         OpenSell();
        }
     }
  }
//+------------------------------------------------------------------+
