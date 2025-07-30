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
#include "BackendCommon.h"

thread_local GridDimensions gridDim;
thread_local BlockIndices blockIdx;

namespace Allen {
  std::tuple<bool, std::string, unsigned, unsigned> set_device(int id, size_t)
  {
#ifdef __linux__
    // Try to get the CPU type on a linux system
    FILE* cmd = popen("grep -m1 -hoE 'model name\\s+.*' /proc/cpuinfo | awk '{ print substr($0, index($0,$4)) }'", "r");
    if (cmd == NULL) return {true, "CPU", 0, 0};

    // Get a string that identifies the CPU
    const int fd = fileno(cmd);
    __gnu_cxx::stdio_filebuf<char> filebuf {fd, std::ios::in};
    std::istream cmd_ifstream {&filebuf};
    std::string processor_name {(std::istreambuf_iterator<char>(cmd_ifstream)), (std::istreambuf_iterator<char>())};
    pclose(cmd);

    // Clean the string
    const std::regex regex_to_remove {"(\\(R\\))|(CPU )|( @.*)|(\\(TM\\))|(\n)|( Processor)"};
    processor_name = std::regex_replace(processor_name, regex_to_remove, std::string {});

    return {true, processor_name, cpu_alignment, id};
#else
    return {true, "CPU", cpu_alignment, id};
#endif // linux-dependent CPU detection
  }
} // namespace Allen
