//+------------------------------------------------------------------+
//|                                                       Pupupu.mq5 |
//|                                                           Binary |
//+------------------------------------------------------------------+
#property copyright "Binary"
#property version   "1.00"
#include <Trade\Trade.mqh>

CTrade trade;
bool positionOpen;
double  _HighsBuffer[],
        _LowsBuffer[],
        _OpensBuffer[],
        _ClosesBuffer[],
        _EMA[],
        _EMA_slow[];


int EMA_Handle;
int EMA_slow_Handle;
                                       // Recomended by backtest
input int EMA_PERIOD = 12;             // 9
input int Sup_Res_Period = 250;        // 350
input int Num_bars_Pivot = 4;          // 10
input double Risk_Reward_factor = 1.7; // 2.0
input double lots = 0.2;

input bool check_trend = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("EA Initialized.");
   
   EMA_Handle  = iMA(Symbol(),PERIOD_CURRENT, EMA_PERIOD,0,MODE_EMA,PRICE_CLOSE);
   EMA_slow_Handle = iMA(Symbol(),PERIOD_CURRENT, 100,0,MODE_EMA,PRICE_CLOSE);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (isNewBar(PERIOD_CURRENT)) OnNewBar();
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
   
  }
//+------------------------------------------------------------------+
//| isNewBar event function                                          |
//+------------------------------------------------------------------+

void OnNewBar() {
   
   if (PositionsTotal() > 0) return;
   
   ArraySetAsSeries(_HighsBuffer, true);
   ArraySetAsSeries(_LowsBuffer, true);
   ArraySetAsSeries(_OpensBuffer, true);
   ArraySetAsSeries(_ClosesBuffer, true);
   
   // Get errors 
   if (CopyBuffer(EMA_Handle,0,0,10,_EMA) < 0)  {Print("CopyBuffer EMA Error = ",GetLastError()); return;}
   if (CopyBuffer(EMA_slow_Handle,0,0,10,_EMA_slow) < 0)  {Print("CopyBuffer EMA Error = ",GetLastError()); return;}
   
   if (CopyHigh(Symbol(),PERIOD_CURRENT, 0,Sup_Res_Period, _HighsBuffer) < 0){Print("CopyHigh Historical Data Error = ",GetLastError()); return;}
   if (CopyLow(Symbol(), PERIOD_CURRENT, 0,Sup_Res_Period, _LowsBuffer) < 0) {Print("CopyLow Historical Data Error = ",GetLastError()); return;}
   if (CopyClose(Symbol(),PERIOD_CURRENT,0,10, _ClosesBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError()); return;}
   if (CopyOpen(Symbol(),PERIOD_CURRENT,0, 10, _OpensBuffer) < 0){Print("CopyClose Historical Data Error = ",GetLastError()); return;}
   
   // Set bands
   double resistence = _HighsBuffer[ArrayMaximum(_HighsBuffer, 0, Sup_Res_Period)];
   double support = _LowsBuffer[ArrayMinimum(_LowsBuffer, 0, Sup_Res_Period)];
   
   bool pivoted_support = false;
   bool pivoted_resistence = false;
   
   // Verify Support
   double near_lows[];
   ArraySetAsSeries(near_lows, true);
   CopyLow(Symbol(),PERIOD_CURRENT, 1, Num_bars_Pivot, near_lows);
   if (near_lows[ArrayMinimum(near_lows,0)] == support)
         pivoted_support = true;
         
   // Verify Resistence
   double near_highs[]; 
   ArraySetAsSeries(near_highs, true);
   CopyHigh(Symbol(),PERIOD_CURRENT, 1, Num_bars_Pivot, near_highs);
   if (near_highs[ArrayMaximum(near_highs,0)] == resistence)
         pivoted_resistence = true;
            
   // check Trend
   bool bullish_trend = _EMA_slow[1] > _EMA_slow[2] ;//&& _ClosesBuffer[1] > _EMA_slow[1];
   bool bearish_trend = _EMA_slow[1] < _EMA_slow[2] ;//&& _ClosesBuffer[1] < _EMA_slow[1];
            
   // Long condition
   if (pivoted_support && _ClosesBuffer[1] > _EMA[1] && _OpensBuffer[1] < _EMA[1] && (!check_trend || (check_trend && bullish_trend))) 
         SendBuyLimit(NormalizeDouble(_EMA[1],Digits()), lots, (_EMA[1]-support)*Risk_Reward_factor + _EMA[1], support);
      
   
   // Short condition
   if (pivoted_resistence && _ClosesBuffer[1] < _EMA[1] && _OpensBuffer[1] > _EMA[1] && (!check_trend || (check_trend && bearish_trend)))
      SendSellLimit(NormalizeDouble(_EMA[1],Digits()), lots, _EMA[1] - (resistence-_EMA[1])*Risk_Reward_factor, resistence);
}

//---

datetime Old_Time;
datetime New_Time;

bool isNewBar(ENUM_TIMEFRAMES pPeriod)
{
    New_Time = iTime(Symbol(), pPeriod, 0);

    if (New_Time != Old_Time)
    {
        Old_Time = New_Time;
        return true;
    }
    else return false;
}
//+------------------------------------------------------------------+
void SendBuyMarket(double price, double plots, double TP = 0, double SL = 0) {
    trade.Buy(plots, Symbol(), price, SL, TP, "");
}

void SendBuyLimit(double price, double plots, double TP = 0, double SL = 0) {
    datetime expirationTime = TimeCurrent() + 15 * 60;  // 15 min
    trade.BuyLimit(plots, price, Symbol(), SL, TP,ORDER_TIME_DAY, expirationTime);
}

void SendSellLimit(double price, double plots, double TP = 0, double SL = 0) {
    datetime expirationTime = TimeCurrent() + 15 * 60;  // 15 min
    trade.SellLimit(plots, price, Symbol(), SL, TP,ORDER_TIME_DAY, expirationTime);
}


void SendSellMarket(double price, double plots, double TP = 0, double SL = 0) {
    trade.Sell(plots, Symbol(), price, SL, TP, "");
}
