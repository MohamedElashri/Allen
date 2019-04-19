/**
 *      CUDA HLT1
 *
 *      author  -  GPU working group
 *      e-mail  -  lhcb-parallelization@cern.ch
 *
 *      Started development on February, 2018
 *      CERN
 */
#include <string>
#include <map>
#include <iostream>
#include <string>
#include <cstring>
#include <exception>
#include <fstream>
#include <cstdlib>
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>

#include <Allen.h>

void printUsage(char* argv[])
{
  std::cerr << "Usage: " << argv[0] << std::endl
            << " -f {folder containing data directories}=\"../input/minbias/\"" << std::endl
            << " -g {folder containing detector configuration}" << std::endl
            << " --mdf {use MDF files as input instead of binary files}" << std::endl
            << " -n {number of events to process}=0 (all)" << std::endl
            << " -o {offset of events from which to start}=0 (beginning)" << std::endl
            << " -t {number of threads / streams}=1" << std::endl
            << " -r {number of repetitions per thread / stream}=1" << std::endl
            << " -c {run checkers}=0" << std::endl
            << " -m {reserve Megabytes}=1024" << std::endl
            << " -v {verbosity}=3 (info)" << std::endl
            << " -p {print memory usage}=0" << std::endl
            << " -i {Import forward tracks dumped from Brunel}" << std::endl
            << " --device {select cuda device to use}=0" << std::endl
            << " --cpu-offload {offload part of the computation to CPU}=0" << std::endl;
}

int main(int argc, char* argv[])
{
  int use_mdf = 0;
  int cuda_device = 0;
  int cpu_offload = 1;
  struct option long_options[] = {/* These options set a flag. */
                                  {"mdf", no_argument, &use_mdf, 1},
                                  {"device", required_argument, &cuda_device, 0},
                                  {"cpu-offload", required_argument, &cpu_offload, 1},
                                  /* These options don’t set a flag.
                                     We distinguish them by their indices. */
                                  {0, 0, 0, 0}};
  /* getopt_long stores the option index here. */
  int option_index = 0;

  // Options set to defaults
  std::map<std::string, std::string> options{{"f", "../input/minbias/"},
                                             {"g", "../input/detector_configuration/"},
                                             {"i", ""},
                                             {"n", "0"},
                                             {"o", "0"},
                                             {"t", "1"},
                                             {"mdf", "0"},
                                             {"cpu-offload", "1"},
                                             {"r", "1"},
                                             {"c", "1"},
                                             {"m", "1024"},
                                             {"v", "3"},
                                             {"p", "0"},
                                             {"device", "0"}};

  signed char c;
  while ((c = getopt_long(argc, argv, "f:i:n:o:t:r:phd:v:c:m:g:", long_options, &option_index)) != -1) {
    switch (c) {
    case 0:
      if (long_options[option_index].flag != 0) {
        if (strncmp(long_options[option_index].name, "device", 6) == 0 && optarg) {
          options["cuda_device"] = optarg;
        }
        else if (strncmp(long_options[option_index].name, "cpu-offload", 11) == 0 && optarg) {
          options["cpu-offload"] = optarg;
        }
        break;
      }
      /* If this option set a flag, do nothing else now. */
      break;
    case 'f':
    case 'g':
    case 'i':
    case 'm':
    case 'n':
    case 'o':
    case 't':
    case 'r':
    case 'c':
    case 'v':
    case 'p':
      options[std::string{c}] = optarg;
      break;
    case '?':
    case 'h':
    default:
      printUsage(argv);
      return -1;
    }
  }
  options["mdf"] = std::to_string(use_mdf);

  return allen(std::move(options));
}
