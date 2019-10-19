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
          {{"mdf"}, "comma-separated list of MDF files to use as input"},
          {{"mep"}, "comma-separated list of MEP files to use as input"},
          {{"transpose-mep"}, "Transpose MEPs instead of decoding from MEP layout directly", "0", "don't transpose"},
          {{"n", "number-of-events"}, "number of events to process", "0", "all"},
          // {{"o", "offset"}, "offset of events from which to start", "0 (beginning)"},
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
          {{"non-stop"}, "Runs the program indefinitely", "0"},
          {{"with-mpi"}, "Read events with MPI", "0"},
          {{"mpi-window-size"}, "Size of MPI sliding window", "4"},
          {{"mpi-number-of-slices"}, "Number of MPI network slices", "6"}
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
