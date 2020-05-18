#include "Logger.h"
#include <sstream>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>

FileStdLogger::FileStdLogger() : std::ostream() {}

MessageLogger::MessageLogger(std::ofstream* file_io, FileStdLogger* file_std_io) :
  _buf(""), _file_io(file_io), _file_std_io(file_std_io)
{
  // Override the previous read buffer
  _old = _file_std_io->rdbuf(this);
}

MessageLogger::~MessageLogger()
{
  if (_file_std_io && _old) _file_std_io->rdbuf(_old);
}

int MessageLogger::overflow(int c)
{
  if (c == '\n') {
    std::cout << _buf << std::endl;
    (*_file_io) << _buf << std::endl;
    _buf = "";
  }
  else
    _buf += c;

  return c;
}

VoidLogger::VoidLogger(std::ostream* void_stream) : _void_stream(void_stream) { _old = _void_stream->rdbuf(this); }

VoidLogger::~VoidLogger()
{
  if ((_void_stream != nullptr) && (_old != nullptr)) _void_stream->rdbuf(_old);
}

int VoidLogger::overflow(int c)
{
  // Just don't do anything
  return c;
}

namespace logger {
  static std::unique_ptr<Logger> ll;
}

logger::Logger::Logger() { discardLogger.reset(new VoidLogger(&discardStream)); }

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
    return logger::ll->discardStream;
  }
}
