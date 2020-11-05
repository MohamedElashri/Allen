/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#ifdef TARGET_DEVICE_CPU

#include "BackendCommon.h"
#include <cstring>
#include <cstdlib>
#include <fstream>
#include <regex>

thread_local GridDimensions gridDim;
thread_local BlockIndices blockIdx;

namespace Configuration {
  unsigned verbosity_level;
}

void print_gpu_memory_consumption() {}

#ifdef __linux__
#include <ext/stdio_filebuf.h>
std::tuple<bool, std::string> set_device(int, size_t)
{
  // Assume a linux system and try to get the CPU type
  FILE* cmd = popen("grep -m1 -hoE 'model name\\s+.*' /proc/cpuinfo | awk '{ print substr($0, index($0,$4)) }'", "r");
  if (cmd == NULL) return {true, "CPU"};

  // Get a string that identifies the CPU
  const int fd = fileno(cmd);
  __gnu_cxx::stdio_filebuf<char> filebuf {fd, std::ios::in};
  std::istream cmd_ifstream {&filebuf};
  std::string processor_name {(std::istreambuf_iterator<char>(cmd_ifstream)), (std::istreambuf_iterator<char>())};

  // Clean the string
  const std::regex regex_to_remove {"(\\(R\\))|(CPU )|( @.*)|(\\(TM\\))|(\n)|( Processor)"};
  processor_name = std::regex_replace(processor_name, regex_to_remove, std::string {});

  return {true, processor_name};
}
#else
std::tuple<bool, std::string> set_device(int, size_t) { return {true, "CPU"}; }
#endif // linux-dependent CPU detection

std::tuple<bool, int> get_device_id(std::string) { return {true, 0}; }

#endif
