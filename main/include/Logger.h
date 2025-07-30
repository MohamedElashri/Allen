/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
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

namespace logger {
  class Logger {
  public:
    int verbosityLevel = 3;
  };

  std::ostream& logger(int requestedLogLevel);

  int verbosity();

  void setVerbosity(int level);
} // namespace logger
