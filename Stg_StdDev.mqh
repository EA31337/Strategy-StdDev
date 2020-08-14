/**
 * @file
 * Implements StdDev strategy the Standard Deviation indicator.
 */

// User input params.
INPUT unsigned int StdDev_MA_Period = 10;                     // Period
INPUT int StdDev_MA_Shift = 0;                                // Shift
INPUT ENUM_MA_METHOD StdDev_MA_Method = 1;                    // MA Method
INPUT ENUM_APPLIED_PRICE StdDev_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int StdDev_Shift = 0;                                   // Shift
INPUT int StdDev_SignalOpenMethod = 0;                        // Signal open method (0-
INPUT float StdDev_SignalOpenLevel = 0.00000000;              // Signal open level
INPUT int StdDev_SignalOpenFilterMethod = 0.00000000;         // Signal open filter method
INPUT int StdDev_SignalOpenBoostMethod = 0.00000000;          // Signal open boost method
INPUT int StdDev_SignalCloseMethod = 0;                       // Signal close method (0-
INPUT float StdDev_SignalCloseLevel = 0.00000000;             // Signal close level
INPUT int StdDev_PriceLimitMethod = 0;                        // Price limit method
INPUT float StdDev_PriceLimitLevel = 0;                       // Price limit level
INPUT float StdDev_MaxSpread = 6.0;                           // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_StdDev.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_StdDev_Params : StgParams {
  unsigned int StdDev_MA_Period;
  int StdDev_MA_Shift;
  ENUM_MA_METHOD StdDev_MA_Method;
  ENUM_APPLIED_PRICE StdDev_Applied_Price;
  int StdDev_Shift;
  int StdDev_SignalOpenMethod;
  float StdDev_SignalOpenLevel;
  int StdDev_SignalOpenFilterMethod;
  int StdDev_SignalOpenBoostMethod;
  int StdDev_SignalCloseMethod;
  float StdDev_SignalCloseLevel;
  int StdDev_PriceLimitMethod;
  float StdDev_PriceLimitLevel;
  float StdDev_MaxSpread;

  // Constructor: Set default param values.
  Stg_StdDev_Params()
      : StdDev_MA_Period(::StdDev_MA_Period),
        StdDev_MA_Shift(::StdDev_MA_Shift),
        StdDev_MA_Method(::StdDev_MA_Method),
        StdDev_Applied_Price(::StdDev_Applied_Price),
        StdDev_Shift(::StdDev_Shift),
        StdDev_SignalOpenMethod(::StdDev_SignalOpenMethod),
        StdDev_SignalOpenLevel(::StdDev_SignalOpenLevel),
        StdDev_SignalOpenFilterMethod(::StdDev_SignalOpenFilterMethod),
        StdDev_SignalOpenBoostMethod(::StdDev_SignalOpenBoostMethod),
        StdDev_SignalCloseMethod(::StdDev_SignalCloseMethod),
        StdDev_SignalCloseLevel(::StdDev_SignalCloseLevel),
        StdDev_PriceLimitMethod(::StdDev_PriceLimitMethod),
        StdDev_PriceLimitLevel(::StdDev_PriceLimitLevel),
        StdDev_MaxSpread(::StdDev_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_StdDev : public Strategy {
 public:
  Stg_StdDev(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_StdDev *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_StdDev_Params _params;
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_StdDev_Params>(_params, _tf, stg_stddev_m1, stg_stddev_m5, stg_stddev_m15, stg_stddev_m30,
                                       stg_stddev_h1, stg_stddev_h4, stg_stddev_h4);
    }
    // Initialize strategy parameters.
    StdDevParams stddev_params(_params.StdDev_MA_Period, _params.StdDev_MA_Shift, _params.StdDev_MA_Method,
                               _params.StdDev_Applied_Price);
    stddev_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_StdDev(stddev_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.StdDev_SignalOpenMethod, _params.StdDev_SignalOpenMethod,
                       _params.StdDev_SignalOpenFilterMethod, _params.StdDev_SignalOpenBoostMethod,
                       _params.StdDev_SignalCloseMethod, _params.StdDev_SignalCloseMethod);
    sparams.SetPriceLimits(_params.StdDev_PriceLimitMethod, _params.StdDev_PriceLimitLevel);
    sparams.SetMaxSpread(_params.StdDev_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_StdDev(sparams, "StdDev");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_StdDev *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      // Note: It doesn't give independent signals. Is used to define volatility (trend strength).
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = _indi[CURR].value[0] > _indi[PREV].value[0] + _level;
          if (METHOD(_method, 0)) _result &= Chart().GetClose() > Chart().GetOpen();
          if (METHOD(_method, 1)) _result &= Chart().GetOpen(CURR) > Chart().GetOpen(PREV);
          break;
        case ORDER_TYPE_SELL:
          _result = _indi[CURR].value[0] > _indi[PREV].value[0] + _level;
          if (METHOD(_method, 0)) _result &= Chart().GetClose() < Chart().GetOpen();
          if (METHOD(_method, 1)) _result &= Chart().GetOpen(CURR) < Chart().GetOpen(PREV);
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_StdDev *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0: {
          int _bar_count = (int)_level * (int)_indi.GetMAPeriod();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 1: {
          int _bar_count = (int)_level * (int)_indi.GetMAPeriod() * 2;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 2: {
          int _bar_count = (int)_level * (int)_indi.GetMAPeriod();
          _result = _direction > 0 ? _indi.GetPrice(_indi.GetAppliedPrice(), _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(_indi.GetAppliedPrice(), _indi.GetLowest(_bar_count));
          break;
        }
        case 3: {
          int _bar_count = (int)_level * (int)_indi.GetMAPeriod() * 2;
          _result = _direction > 0 ? _indi.GetPrice(_indi.GetAppliedPrice(), _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(_indi.GetAppliedPrice(), _indi.GetLowest(_bar_count));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
