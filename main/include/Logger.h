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

// Dumb type, just making constructor public
class FileStdLogger : public std::ostream {
public:
  FileStdLogger();
};

// This is relatively simple
class MessageLogger : public std::streambuf {
public:
  std::string _buf;
  std::ofstream* _file_io = nullptr;
  FileStdLogger* _file_std_io = nullptr;
  std::streambuf* _old = nullptr;

  MessageLogger(std::ofstream* file_io, FileStdLogger* file_std_io);

  ~MessageLogger();

  int overflow(int c) override;
};

class VoidLogger : public std::streambuf {
public:
  std::ostream* _void_stream = nullptr;
  std::streambuf* _old = nullptr;

  VoidLogger(std::ostream* void_stream);

  ~VoidLogger();

  int overflow(int c) override;
};

namespace logger {
  class Logger {
  public:
    int verbosityLevel = 3;
    FileStdLogger discardStream;
    std::unique_ptr<VoidLogger> discardLogger;
    Logger();
  };

  std::ostream& logger(int requestedLogLevel);

  int verbosity();

  void setVerbosity(int level);
} // namespace logger
