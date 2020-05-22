#pragma once

#define verbose_cout logger::logger(logger::verbose)
#define debug_cout logger::logger(logger::debug)
#define info_cout logger::logger(logger::info)
#define warning_cout logger::logger(logger::warning)
#define error_cout logger::logger(logger::error)

#include <iosfwd>
#include <ostream>
#include <streambuf>
#include <memory>
#include "LoggerCommon.h"
#include "boost/iostreams/stream.hpp"
#include "boost/iostreams/device/null.hpp"

namespace logger {
  class Logger {
  public:
    int verbosityLevel = 3;
    boost::iostreams::stream<boost::iostreams::null_sink> nullOstream = boost::iostreams::null_sink();
  };

  std::ostream& logger(int requestedLogLevel);

  int verbosity();

  void setVerbosity(int level);
} // namespace logger
