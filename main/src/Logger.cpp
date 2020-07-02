#include "Logger.h"

#if defined(__clang__) && __clang_major__ >= 10
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-copy"
#endif

#include "boost/iostreams/stream.hpp"

#if defined(__clang__) && __clang_major__ >= 10
#pragma clang diagnostic pop
#endif

#include "boost/iostreams/device/null.hpp"
#include <sstream>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>

namespace logger {
  static std::unique_ptr<Logger> ll;
  static std::unique_ptr<boost::iostreams::stream<boost::iostreams::null_sink>> nullOstream;
} // namespace logger

void logger::setVerbosity(int level)
{
  if (!logger::ll) {
    logger::ll.reset(new logger::Logger {});
  }
  logger::ll->verbosityLevel = level;
}

int logger::verbosity()
{
  if (!logger::ll) {
    logger::ll.reset(new logger::Logger {});
  }
  return logger::ll->verbosityLevel;
}

std::ostream& logger::logger(int requestedLogLevel)
{
  if (!logger::ll) {
    logger::ll.reset(new logger::Logger {});
  }
  if (!logger::nullOstream) {
    logger::nullOstream.reset(
      new boost::iostreams::stream<boost::iostreams::null_sink> {boost::iostreams::null_sink()});
  }
  if (logger::ll->verbosityLevel >= requestedLogLevel) {
    return std::cout;
  }
  else {
    return *logger::nullOstream;
  }
}
