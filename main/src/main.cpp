/**
 *      CUDA HLT1
 *
 *      author  -  GPU working group
 *      e-mail  -  lhcb-parallelization@cern.ch
 *
 *      Started development on February, 2018
 *      CERN
 */
#include <getopt.h>
#include <cstring>
#include <map>
#include <string>
#include <iostream>
#include <vector>
#include <Allen.h>
#include <Updater.h>

/**
 * @brief Options accepted in the program.
 * @details Each argument is composed of the following:
 * 
 *          options: vector of strings with all names to arguments.
 *          description: description of arguments, shown in print_usage.
 *          default_value [optional]: default value the argument takes.
 */
struct ProgramOption {
  std::vector<std::string> options;
  std::string description;
  std::string default_value = "";

  ProgramOption() = default;
  ProgramOption(const std::vector<std::string>&& options, const std::string&& description)
    : options(options), description(description) {}
  ProgramOption(const std::vector<std::string>&& options,
    const std::string&& description, const std::string&& default_value)
    : options(options), description(description), default_value(default_value) {}
};

/**
 * @brief Prints usage of the application according to program options.
 */
void print_usage(char* argv[], const std::vector<ProgramOption>& program_options) {
  std::cerr << "Usage: " << argv[0] << std::endl;
  for (const auto& po : program_options) {
    std::cerr << " ";
    for (int i=0; i<po.options.size(); ++i) {
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
    }
    std::cerr << std::endl;
  }
  std::cerr << " -h {show this help}" << std::endl;
}

int main(int argc, char* argv[]) {
  // Vector of accepted options
  // Format: options {short / long, short / long, ...}, description, default value
  std::vector<ProgramOption> program_options {
    {{"f", "folder"}, "folder containing data directories", "\"../input/minbias/\""},
    {{"g", "geometry"}, "folder containing detector configuration", ""},
    {{"mdf"}, "use MDF files as input instead of binary files", ""},
    {{"n", "number-of-events"}, "number of events to process", "0 (all)"},
    // {{"o", "offset"}, "offset of events from which to start", "0 (beginning)"},
    {{"t", "threads"}, "number of threads / streams", "1"},
    {{"r", "repetitions"}, "number of repetitions per thread / stream", "1"},
    {{"c", "validate"}, "run validation / checkers", "1"},
    {{"m", "memory"}, "memory to reserve per thread / stream (megabytes)", "1024"},
    {{"v", "verbosity"}, "verbosity [0-5]", "3 (info)"},
    {{"p", "print-memory"}, "print memory usage", "0"},
    {{"i", "import-tracks"}, "import forward tracks dumped from Brunel", ""},
    {{"device"}, "select cuda device to use", "0"},
    {{"cpu-offload"}, "offload part of the computation to CPU", "0"}
  };

  // Options object that will be passed to Allen
  std::map<std::string, std::string> allen_options;

  // Create long_options from program_options
  std::vector<option> long_options;
  std::string accepted_single_letter_options = "h";
  for (const auto& po : program_options) {
    for (const auto& opt : po.options) {
      if (opt.length() > 1) {
        long_options.push_back(option{opt.c_str(), required_argument, nullptr, 0});
      } else {
        accepted_single_letter_options += opt + ":";
      }
    }
  }

  int option_index = 0;
  signed char c;
  while ((c = getopt_long(argc, argv, accepted_single_letter_options.c_str(), long_options.data(), &option_index)) != -1) {
    switch (c) {
    case 0:
      for (const auto& po : program_options) {
        for (const auto& opt : po.options) {
          if (std::string(long_options[option_index].name) == opt) {
            if (optarg) {
              allen_options[opt] = optarg;
            } else {
              allen_options[opt] = "1";
            }
          }
        }
      }
      break;
    default:
      bool found_opt = false;
      for (const auto& po : program_options) {
        for (const auto& opt : po.options) {
          if (std::string{c} == opt) {
            if (optarg) {
              allen_options[std::string{c}] = optarg;
            } else {
              allen_options[std::string{c}] = "1";
            }
            found_opt = true;
          }
        }
      }
      if (!found_opt) {
        // If we reach this point, it is not supported
        print_usage(argv, program_options);
        return -1;
      }
      break;
    }
  }

  Allen::NonEventData::Updater updater{allen_options};
  return allen(std::move(allen_options), &updater);
}
