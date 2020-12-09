/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <ProgramOptions.h>

const std::string build_directory = "../..";
const std::string source_directory = "../../..";
const std::string base_datadir = "/scratch/allen_data";

inline void append_default_allen_program_options(std::map<std::string, std::string>& allen_options)
{
  // Iterate all options with default values and put those in
  const auto program_options = allen_program_options();
  for (const auto& po : program_options) {
    bool initialized = false;
    for (const auto& opt : po.options) {
      const auto it = allen_options.find(opt);
      if (it != allen_options.end()) {
        initialized = true;
      }
    }
    if (!initialized && po.default_value != "") {
      allen_options[po.options[0]] = po.default_value;
    }
  }
}
