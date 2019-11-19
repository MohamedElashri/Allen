#include "ProgramOptions.h"

void print_usage(char* argv[], const std::vector<ProgramOption>& program_options)
{
  std::cerr << "Usage: " << argv[0] << std::endl;
  for (const auto& po : program_options) {
    std::cerr << " ";
    for (size_t i = 0; i < po.options.size(); ++i) {
      if (po.options[i].length() > 1) {
        std::cerr << "-";
      }
      std::cerr << "-" << po.options[i];
      if (i != po.options.size() - 1) {
        std::cerr << ", ";
      }
    }
    std::cerr << " {" << po.description << "}";
    if (po.default_value != "") {
      std::cerr << "=" << po.default_value;
      if (po.description_default_value != "") {
        std::cerr << " (" << po.description_default_value << ")";
      }
    }
    std::cerr << std::endl;
  }
  std::cerr << " -h {show this help}" << std::endl;
}

std::vector<ProgramOption> allen_program_options()
{
  // Vector of accepted options
  // Format: options {short / long, short / long, ...}, description,
  //         [optional default value], [optional description default value]
  return {{{"f", "folder"}, "folder containing data directories", "../input/minbias/"},
          {{"g", "geometry"}, "folder containing detector configuration", "../input/detector_configuration/down/"},
          {{"mdf"}, "comma-separated list of MDF files to use as input instead of binary files"},
          {{"configuration"},
           "path to json file containing values of configurable algorithm constants",
           "../configuration/constants/default.json"},
          {{"print-buffer-status"}, "show buffer status", "0"},
          {{"print-config"}, "show current algorithm configuration", "0"},
          {{"write-configuration"}, "write current algorithm configuration to file", "0"},
          {{"n", "number-of-events"}, "number of events to process", "0", "all"},
          {{"s", "number-of-slices"}, "number of input slices to allocate", "0", "one more than the number of threads"},
          {{"events-per-slice"}, "number of events per slice", "1000"},
          {{"t", "threads"}, "number of threads / streams", "1"},
          {{"r", "repetitions"}, "number of repetitions per thread / stream", "1"},
          {{"c", "validate"}, "run validation / checkers", "1"},
          {{"m", "memory"}, "memory to reserve per thread / stream (megabytes)", "1024"},
          {{"v", "verbosity"}, "verbosity [0-5]", "3", "info"},
          {{"p", "print-memory"}, "print memory usage", "0"},
          {{"i", "import-tracks"}, "import forward tracks dumped from Brunel"},
          {{"cpu-offload"}, "offload part of the computation to CPU", "1"},
          {{"device"}, "select device to use", "0"},
          {{"file-list"}, "list of files to process", ""}
        };
}

void print_call_options(const std::map<std::string, std::string>& options, const std::string& device_name)
{
  const auto program_options = allen_program_options();
  std::cout << "Requested options:" << std::endl;
  for (const auto& po : program_options) {
    std::cout << " " << po.description << " (";
    for (size_t i = 0; i < po.options.size(); ++i) {
      if (po.options[i].length() > 1) {
        std::cout << "-";
      }
      std::cout << "-" << po.options[i];
      if (i != po.options.size() - 1) {
        std::cout << ", ";
      }
    }
    std::cout << "): ";
    bool option_specified = false;
    for (const auto opt : po.options) {
      const auto it = options.find(opt);
      if (it != options.end()) {
        option_specified = true;
        std::cout << options.at(opt);
      }
    }
    if (!option_specified) {
      std::cout << po.default_value;
    }
    // Special case: -d should say the device
    if (po.options[0] == "device") {
      std::cout << ", " << device_name << std::endl;
    }
    std::cout << std::endl;
  }
}
