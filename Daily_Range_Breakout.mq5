//+------------------------------------------------------------------+
//|                                         Daily_Range_Breakout.mq5 |
//|                                           Copyright 2024, Ananta |
//|                                          https://www.ananta.dev/ |
//+------------------------------------------------------------------+
// Credit to ALLAN MUNENE MUTIIRIA. #@Forex Algo-Trader
// https://www.youtube.com/watch?v=sgcyC7TNWNw

#property copyright "Copyright 2024, Ananta"
#property link      "https://www.ananta.dev/"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input int i_tpInPoints        = 100; // Take Profit distance in points
input int i_slInPoints        = 50; // Stop Loss distance in points
input double i_volumeInLots   = 0.1; // Volume in lots

datetime maximum_time;
datetime minimum_time;

double maximum_price          = -DBL_MAX;
double minimum_price          = DBL_MAX;

bool isHaveDailyRange_Prices  = false;
bool isHaveRangeBreak         = false;

#define RECTANGLE_PREFIX "RANGE RECTANGLE "
#define UPPER_LINE_PREFIX "UPPER LINE "
#define LOWER_LINE_PREFIX "LOWER LINE "

//+------------------------------------------------------------------+
//| Expert initialization function |
//+------------------------------------------------------------------+
int OnInit(){
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
  Print("Expert Deinitialization. Reason = ",reason);
}

//+------------------------------------------------------------------+
//| Expert tick function |
//+------------------------------------------------------------------+
void OnTick() {
  static datetime midnight             = iTime(_Symbol,PERIOD_D1,0);
  static datetime sixAM                = midnight + 6 * 3600;
  static datetime scanBarTime          = sixAM + 1 * PeriodSeconds(_Period); // next bar
  static datetime validBreakTime_start = scanBarTime;
  static datetime validBreakTime_end   = midnight + (6+5) * 3600; // 11 am
  
  if (isNewDay()){
    midnight                = iTime(_Symbol,PERIOD_D1,0);
    sixAM                   = midnight + 6 * 3600;
    scanBarTime             = sixAM + 1 * PeriodSeconds(_Period); // next bar
    validBreakTime_start    = scanBarTime;
    validBreakTime_end      = midnight + (6+5) * 3600; // 11 am
    maximum_price           = -DBL_MAX;
    minimum_price           =  DBL_MAX;
    isHaveDailyRange_Prices = false;
    isHaveRangeBreak        = false;
  }
  
  if (isNewBar()) {
    //Print("Scan Bar Time = ",scanBarTime);
    datetime currentBarTime = iTime(_Symbol,_Period,0);
    //Print("Current Bar Time = ",currentBarTime);
    
    if (currentBarTime == scanBarTime && !isHaveDailyRange_Prices) {
      Print("WE HAVE ENOUGH BARS DATA FOR DOCUMENTATION. MAKE THE EXTRACTION");
      
      int total_bars = int((sixAM - midnight)/PeriodSeconds(_Period))+1;
      Print("Total Bars for scan = ", total_bars);
      
      int highest_price_bar_index = -1;
      int lowest_price_bar_index = -1;
      
      for (int i=1; i<=total_bars ; i++) {
        //Print(i,", Time = ",time(i));
        double open_i = open(i);
        double close_i = close(i);
        double highest_price_i = (open_i > close_i) ? open_i : close_i;
        double lowest_price_i = (open_i < close_i) ? open_i : close_i;
        
        if (highest_price_i > maximum_price){
          maximum_price = highest_price_i;
          highest_price_bar_index = i;
          maximum_time = time(i);
        }

        if (lowest_price_i < minimum_price){
          minimum_price = lowest_price_i;
          lowest_price_bar_index = i;
          minimum_time = time(i);
        }
      }
      
      Print("Maximum Price = ",maximum_price,", Bar index = ",highest_price_bar_index,", Time = ", maximum_time);
      Print("Minimum Price = ",minimum_price,", Bar index = ",lowest_price_bar_index,", Time = ", minimum_time);
      
      create_Rectangle(RECTANGLE_PREFIX+TimeToString(maximum_time),maximum_time,maximum_price, minimum_time,minimum_price,clrBlue);
      create_Line(UPPER_LINE_PREFIX+TimeToString(midnight),midnight,maximum_price,sixAM, maximum_price,3,clrBlack,DoubleToString(maximum_price,_Digits));
      create_Line(LOWER_LINE_PREFIX+TimeToString(midnight),midnight,minimum_price,sixAM, minimum_price,3,clrRed,DoubleToString(minimum_price,_Digits));
      isHaveDailyRange_Prices = true;
    }
  }
  
  //double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
  //double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
  
  double barClose = close(1);
  datetime barTime = time(1);

  if (barClose > maximum_price && isHaveDailyRange_Prices && !isHaveRangeBreak && barTime >= validBreakTime_start && barTime <= validBreakTime_end) {
    Print("CLOSE Price broke the HIGH range. ",barClose," > ",maximum_price);
    isHaveRangeBreak = true;
    drawBreakPoint(TimeToString(barTime),barTime,barClose,234,clrBlack,-1);
    
    trade.Buy(i_volumeInLots, _Symbol, barClose,
              barClose - i_slInPoints * _Point, 
              barClose + i_tpInPoints * _Point, 
              "Daily Range Breakout - Buy");
  }
  else if (barClose < minimum_price && isHaveDailyRange_Prices && !isHaveRangeBreak && barTime >= validBreakTime_start && barTime <= validBreakTime_end ){
    Print("CLOSE Price broke the LOW range. ",barClose," < ",minimum_price);
    isHaveRangeBreak = true;
    drawBreakPoint(TimeToString(barTime),barTime,barClose,233,clrBlue,1);
    
    trade.Sell(i_volumeInLots, _Symbol, barClose,
               barClose + i_slInPoints * _Point, 
               barClose - i_tpInPoints * _Point, 
               "Daily Range Breakout - Sell");
  }
}



//+------------------------------------------------------------------+
double open(int index) {
  return iOpen(_Symbol,_Period,index);
}

double high(int index) {
  return iHigh(_Symbol,_Period,index);
}

double low(int index) {
  return iLow(_Symbol,_Period,index);
}

double close(int index) {
  return iClose(_Symbol,_Period,index);
}

datetime time(int index) {
  return iTime(_Symbol,_Period,index);
}




void create_Rectangle(string objName,datetime time1,double price1, datetime time2,double price2,color clr) {
  if (ObjectFind(0,objName) < 0) {
    ObjectCreate(0,objName,OBJ_RECTANGLE,0,time1,price1,time2,price2);
    ObjectSetInteger(0,objName,OBJPROP_TIME,0,time1);
    ObjectSetDouble(0,objName,OBJPROP_PRICE,0,price1);
    ObjectSetInteger(0,objName,OBJPROP_TIME,1,time2);

    ObjectSetDouble(0,objName,OBJPROP_PRICE,1,price2);
    ObjectSetInteger(0,objName,OBJPROP_FILL,true);
    ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
    ObjectSetInteger(0,objName,OBJPROP_BACK,false);
    ChartRedraw(0);
  }
}


void create_Line(string objName, datetime time1, double price1, datetime time2, double price2, int width, color clr, string text) {
  if (ObjectFind(0,objName) < 0) {
    ObjectCreate(0,objName,OBJ_TREND,0,time1,price1,time2,price2);
    ObjectSetInteger(0,objName,OBJPROP_TIME,0,time1);
    ObjectSetDouble(0,objName,OBJPROP_PRICE,0,price1);
    ObjectSetInteger(0,objName,OBJPROP_TIME,1,time2);
    ObjectSetDouble(0,objName,OBJPROP_PRICE,1,price2);
    ObjectSetInteger(0,objName,OBJPROP_WIDTH,width);
    ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
    ObjectSetInteger(0,objName,OBJPROP_BACK,false);
    
    long scale = 0;

    if(!ChartGetInteger(0,CHART_SCALE,0,scale)){
      Print("UNABLE TO GET THE CHART SCALE. DEFAULT OF ",scale," IS CONSIDERED");
    }
    
    //Print("CHART SCALE = ",scale);
    int fontsize = 11;
    // 0=minimized, 5=maximized
    if      (scale==0) { fontsize=5;  }
    else if (scale==1) { fontsize=6;  }
    else if (scale==2) { fontsize=7;  }
    else if (scale==3) { fontsize=9;  }
    else if (scale==4) { fontsize=11; }
    else if (scale==5) { fontsize=13; }
    
    string txt = " Right Price";
    string objNameDescr = objName + txt;
    
    ObjectCreate(0,objNameDescr,OBJ_TEXT,0,time2,price2);
    ObjectSetInteger(0,objNameDescr,OBJPROP_COLOR,clr);
    ObjectSetInteger(0,objNameDescr,OBJPROP_FONTSIZE,fontsize);
    ObjectSetInteger(0,objNameDescr,OBJPROP_ANCHOR,ANCHOR_LEFT);
    ObjectSetString(0,objNameDescr,OBJPROP_TEXT," "+text);
    ObjectSetString(0,objNameDescr,OBJPROP_FONT,"Calibri");
    
    ChartRedraw(0);
  }
}


bool isNewBar() {
  static int previousNumBars = 0;

  int currentNumBars = iBars(_Symbol,_Period);
  bool barIsNew = previousNumBars != currentNumBars;
  previousNumBars = currentNumBars;

  return barIsNew;
}

// Allan's version of isNewBar
// bool isNewBar() {
//   static int prevBars = 0;
//   int currBars = iBars(_Symbol,_Period);
  
//   if (prevBars==currBars) 
//     return (false);
  
//   prevBars = currBars;
//   return (true);
// }


bool isNewDay(){
  static int previousDay = 0;
  
  MqlDateTime now;
  TimeToStruct(TimeCurrent(), now);
  bool dayIsNew = previousDay != now.day;
  if (dayIsNew) Print("WE HAVE A NEW DAY WITH DATE ", now.day, ".", now.mon, ".", now.year);
  previousDay = now.day;

  return (dayIsNew);
}

// Allan's version of isNewDay
// bool isNewDay(){
//   bool newDay = false;
//   MqlDateTime Str_DateTime;
//   TimeToStruct(TimeCurrent(),Str_DateTime);
//   static int prevDay = 0;
//   int currDay = Str_DateTime.day;
//   //Print("CURRENT DAY DATE = ",currDay);
//   if (prevDay == currDay){//we are still in current day
//     newDay = false;
//   }
//   else if (prevDay != currDay){//WE HAVE A NEW DAY
//     Print("WE HAVE A NEW DAY WITH DATE ",currDay);
//     prevDay = currDay;
//     newDay = true;
//   }
//   return (newDay);
// }



void drawBreakPoint( string objName, datetime time, double price, int arrCode, color clr, int direction ){
  if (ObjectFind(0,objName) < 0){
    
    ObjectCreate(0,objName,OBJ_ARROW,0,time,price);
    ObjectSetInteger(0,objName,OBJPROP_ARROWCODE,arrCode);
    ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
    ObjectSetInteger(0,objName,OBJPROP_FONTSIZE,12);
    
    if (direction > 0) ObjectSetInteger(0,objName,OBJPROP_ANCHOR,ANCHOR_TOP);
    if (direction < 0) ObjectSetInteger(0,objName,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
    
    string txt = " Break";
    string objNameDescr = objName + txt;
    ObjectCreate(0,objNameDescr,OBJ_TEXT,0,time,price);
    ObjectSetInteger(0,objNameDescr,OBJPROP_COLOR,clr);
    ObjectSetInteger(0,objNameDescr,OBJPROP_FONTSIZE,12);
    
    if (direction > 0) {
      ObjectSetInteger(0,objNameDescr,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetString(0,objNameDescr,OBJPROP_TEXT, " " + txt);
    }
    if (direction < 0) {
      ObjectSetInteger(0,objNameDescr,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
      ObjectSetString(0,objNameDescr,OBJPROP_TEXT, " " + txt);
    }
  }

  ChartRedraw(0);
}
