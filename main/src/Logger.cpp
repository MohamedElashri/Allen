#include "Logger.h"
#include "boost/iostreams/stream.hpp"
#include "boost/iostreams/device/null.hpp"
#include <sstream>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>

namespace logger {
  static std::unique_ptr<Logger> ll;
}

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
  if (logger::ll->verbosityLevel >= requestedLogLevel) {
    return std::cout;
  }
  else {
    return boost::iostreams::stream<boost::iostreams::null_sink> nullOstream {boost::iostreams::null_sink()};
  }
}
