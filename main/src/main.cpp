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
#include <ProgramOptions.h>
#include <Logger.h>
#include <Timer.h>

#ifdef HAVE_MPI
#include <MPIConfig.h>
#include <MPISend.h>
#endif

int main(int argc, char* argv[])
{
  const auto program_options = allen_program_options();

  // Options object that will be passed to Allen
  std::map<std::string, std::string> allen_options;

  // Create long_options from program_options
  std::vector<option> long_options;
  std::string accepted_single_letter_options = "h";
  for (const auto& po : program_options) {
    for (const auto& opt : po.options) {
      if (opt.length() > 1) {
        long_options.push_back(option {opt.c_str(), required_argument, nullptr, 0});
      }
      else {
        accepted_single_letter_options += opt + ":";
      }
    }
  }

  int option_index = 0;
  signed char c;
  while ((c = getopt_long(argc, argv, accepted_single_letter_options.c_str(), long_options.data(), &option_index)) !=
         -1) {
    switch (c) {
    case 0:
      for (const auto& po : program_options) {
        for (const auto& opt : po.options) {
          if (std::string(long_options[option_index].name) == opt) {
            if (optarg) {
              allen_options[opt] = optarg;
            }
            else {
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
          if (std::string {(char) c} == opt) {
            if (optarg) {
              allen_options[std::string {(char) c}] = optarg;
            }
            else {
              allen_options[std::string {(char) c}] = "1";
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

  // Iterate all options with default values and put those in
  // if they were not specified
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

  if (allen_options.count("with-mpi") && std::atoi(allen_options["with-mpi"].c_str())) {
#ifdef HAVE_MPI
    // MPI initialization
    MPI_Init(&argc, &argv);

    // Communication size
    int comm_size;
    MPI_Comm_size(MPI_COMM_WORLD, &comm_size);
    if (comm_size != MPI::comm_size) {
      error_cout << "This program requires exactly " << MPI::comm_size << " processes.\n";
      return -1;
    }

    // MPI: Who am I?
    MPI_Comm_rank(MPI_COMM_WORLD, &MPI::rank);

    if (MPI::rank == MPI::sender) {
      return send_meps_mpi(allen_options);
    }
    else {
      Allen::NonEventData::Updater updater {allen_options};
      return allen(std::move(allen_options), &updater);
    }
#else
    error_cout << "MPI requested, but Allen was not built with MPI support.\n";
    return -1;
#endif
  }
  else {
    Allen::NonEventData::Updater updater {allen_options};
    return allen(std::move(allen_options), &updater);
  }

}
