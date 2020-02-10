#include <regex>

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
          {{"output-file"}, "Write selected event to output file", ""},
          {{"device"}, "select device to use", "0"},
          {{"non-stop"}, "Runs the program indefinitely", "0"},
          {{"with-mpi"}, "Read events with MPI"},
          {{"mpi-window-size"}, "Size of MPI sliding window", "4"},
          {{"mpi-number-of-slices"}, "Number of MPI network slices", "6"},
          {{"inject-mem-fail"}, "Whether to insert random memory failures (0: off 1-15: rate of 1 in 2^N)", "0"},
          {{"monitoring-save-period"}, "Number of seconds between writes of the monitoring histograms (0: off)", "0"},
          {{"disable-run-changes"}, "Ignore signals to update non-event data with each run change", "1"}};
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

std::vector<std::string> split_string(std::string const& input, std::string const& sep)
{
  std::vector<std::string> s;
  size_t current = input.find(","), previous = 0;
  while (current != std::string::npos) {
    s.emplace_back(input.substr(previous, current - previous));
    previous = current + sep.size();
    current = input.find(sep, previous);
  }
  s.emplace_back(input.substr(previous, current - previous));
  return s;
}

std::tuple<bool, std::map<std::string, int>> parse_receivers(const std::string& arg)
{
  std::map<std::string, int> result;
  const std::regex expr{"([a-z0-9_]+):([0-9]+)"};
  auto s = split_string(arg, ",");
  std::smatch match;
  for (auto const& r : s) {
    if (std::regex_match(r, match, expr)) {
      result.emplace(match[1].str(), atoi(match[2].str().c_str()));
    } else {
      result.clear();
      return {false, result};
    }
  }
  return {true, result};
}
