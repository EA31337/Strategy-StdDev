/**
 * @file
 * Implements StdDev strategy the Standard Deviation indicator.
 */

// User input params.
INPUT string __StdDev_Parameters__ = "-- StdDev strategy params --";  // >>> STDDEV <<<
INPUT float StdDev_LotSize = 0;                                       // Lot size
INPUT int StdDev_SignalOpenMethod = 2;                                // Signal open method (-127-127)
INPUT float StdDev_SignalOpenLevel = 0.0f;                            // Signal open level
INPUT int StdDev_SignalOpenFilterMethod = 32;                          // Signal open filter method
INPUT int StdDev_SignalOpenBoostMethod = 0;                           // Signal open boost method
INPUT int StdDev_SignalCloseMethod = 2;                               // Signal close method (-127-127)
INPUT float StdDev_SignalCloseLevel = 0.0f;                           // Signal close level
INPUT int StdDev_PriceStopMethod = 1;                                 // Price stop method
INPUT float StdDev_PriceStopLevel = 0;                                // Price stop level
INPUT int StdDev_TickFilterMethod = 1;                                // Tick filter method
INPUT float StdDev_MaxSpread = 4.0;                                   // Max spread to trade (pips)
INPUT short StdDev_Shift = 0;                                         // Shift
INPUT int StdDev_OrderCloseTime = -20;                                // Order close time in mins (>0) or bars (<0)
INPUT string __StdDev_Indi_StdDev_Parameters__ =
    "-- StdDev strategy: StdDev indicator params --";                     // >>> StdDev strategy: StdDev indicator <<<
INPUT int StdDev_Indi_StdDev_MA_Period = 10;                              // Period
INPUT int StdDev_Indi_StdDev_MA_Shift = 0;                                // MA Shift
INPUT ENUM_MA_METHOD StdDev_Indi_StdDev_MA_Method = (ENUM_MA_METHOD)1;    // MA Method
INPUT ENUM_APPLIED_PRICE StdDev_Indi_StdDev_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int StdDev_Indi_StdDev_Shift = 0;                                   // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_StdDev_Params_Defaults : StdDevParams {
  Indi_StdDev_Params_Defaults()
      : StdDevParams(::StdDev_Indi_StdDev_MA_Period, ::StdDev_Indi_StdDev_MA_Shift, ::StdDev_Indi_StdDev_MA_Method,
                     ::StdDev_Indi_StdDev_Applied_Price, ::StdDev_Indi_StdDev_Shift) {}
} indi_stddev_defaults;

// Defines struct with default user strategy values.
struct Stg_StdDev_Params_Defaults : StgParams {
  Stg_StdDev_Params_Defaults()
      : StgParams(::StdDev_SignalOpenMethod, ::StdDev_SignalOpenFilterMethod, ::StdDev_SignalOpenLevel,
                  ::StdDev_SignalOpenBoostMethod, ::StdDev_SignalCloseMethod, ::StdDev_SignalCloseLevel,
                  ::StdDev_PriceStopMethod, ::StdDev_PriceStopLevel, ::StdDev_TickFilterMethod, ::StdDev_MaxSpread,
                  ::StdDev_Shift, ::StdDev_OrderCloseTime) {}
} stg_stddev_defaults;

// Struct to define strategy parameters to override.
struct Stg_StdDev_Params : StgParams {
  StdDevParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_StdDev_Params(StdDevParams &_iparams, StgParams &_sparams)
      : iparams(indi_stddev_defaults, _iparams.tf.GetTf()), sparams(stg_stddev_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_StdDev : public Strategy {
 public:
  Stg_StdDev(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_StdDev *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StdDevParams _indi_params(indi_stddev_defaults, _tf);
    StgParams _stg_params(stg_stddev_defaults);
#ifdef __config__
    SetParamsByTf<StdDevParams>(_indi_params, _tf, indi_stddev_m1, indi_stddev_m5, indi_stddev_m15, indi_stddev_m30,
                                indi_stddev_h1, indi_stddev_h4, indi_stddev_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_stddev_m1, stg_stddev_m5, stg_stddev_m15, stg_stddev_m30,
                             stg_stddev_h1, stg_stddev_h4, stg_stddev_h8);
#endif
    // Initialize indicator.
    StdDevParams stddev_params(_indi_params);
    _stg_params.SetIndicator(new Indi_StdDev(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_StdDev(_stg_params, _tparams, _cparams, "StdDev");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_StdDev *_indi = GetIndicator();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      // Note: It doesn't give independent signals. Is used to define volatility (trend strength).
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result &= _indi.IsIncreasing(3);
          _result &= _indi.IsIncByPct(_level, 0, _shift, 3);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(2, 0, _shift + 3);
            if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(2, 0, _shift + 5);
          }
          break;
        case ORDER_TYPE_SELL:
          _result &= _indi.IsDecreasing(3);
          _result &= _indi.IsDecByPct(-_level, 0, _shift, 3);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(2, 0, _shift + 3);
            if (METHOD(_method, 1)) _result &= _indi.IsDecreasing(2, 0, _shift + 5);
          }
          break;
      }
    }
    return _result;
  }
};
