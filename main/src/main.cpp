/**
 *      CUDA HLT1
 *
 *      author  -  GPU working group
 *      e-mail  -  lhcb-parallelization@cern.ch
 *
 *      Started development on February, 2018
 *      CERN
 */
#include <iostream>
#include <string>
#include <cstring>
#include <exception>
#include <fstream>
#include <cstdlib>
#include <vector>
#include <algorithm>
#include <thread>
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>

#include "cuda_runtime.h"
#include "CudaCommon.h"
#include "RuntimeOptions.h"
#include "Logger.h"
#include "Tools.h"
#include "InputTools.h"
#include "InputReader.h"
#include "MDFReader.h"
#include "Timer.h"
#include "StreamWrapper.cuh"
#include "Constants.cuh"
#include "MuonDefinitions.cuh"

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
            << " -a {run only data preparation algorithms: decoding, clustering, sorting}=0" << std::endl
            << " -i {import forward tracks dumped from Brunel}" << std::endl
            << " --cpu-offload {offload part of the computation to CPU}=0" << std::endl;
}

int main(int argc, char* argv[])
{
  // Folder containing raw, MC and muon information
  std::string folder_data = "../input/minbias/";
  const std::string folder_rawdata = "banks/";
  // Folder containing detector configuration and catboost model
  std::string folder_detector_configuration = "../input/detector_configuration/";

  std::string folder_name_imported_forward_tracks = "";
  uint number_of_events_requested = 0;
  uint start_event_offset = 0;
  uint number_of_threads = 1;
  uint number_of_repetitions = 1;
  uint verbosity = 3;
  bool print_memory_usage = false;
  // By default, do_check will be true when mc_check is enabled
  bool do_check = true;
  size_t reserve_mb = 1024;

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

  signed char c;
  while ((c = getopt_long(argc, argv, "f:i:n:o:t:r:phd:v:c:m:g:", long_options, &option_index)) != -1) {
    switch (c) {
    case 0:
      if (long_options[option_index].flag != 0) {
        if (strncmp(long_options[option_index].name, "device", 6) == 0 && optarg) {
          cuda_device = atoi(optarg);
        }
        else if (strncmp(long_options[option_index].name, "cpu-offload", 11) == 0 && optarg) {
          cpu_offload = atoi(optarg);
        }
        break;
      }
      /* If this option set a flag, do nothing else now. */
      break;
    case 'f': folder_data = std::string(optarg) + "/"; break;
    case 'g': folder_detector_configuration = std::string(optarg) + "/"; break;
    case 'i': folder_name_imported_forward_tracks = std::string(optarg); break;
    case 'm': reserve_mb = atoi(optarg); break;
    case 'n': number_of_events_requested = atoi(optarg); break;
    case 'o': start_event_offset = atoi(optarg); break;
    case 't': number_of_threads = atoi(optarg); break;
    case 'r': number_of_repetitions = atoi(optarg); break;
    case 'c': do_check = atoi(optarg); break;
    case 'v': verbosity = atoi(optarg); break;
    case 'p': print_memory_usage = true; break;
    case '?':
    case 'h':
    default: printUsage(argv); return -1;
    }
  }

  // Options sanity check
  if (folder_data.empty() || folder_detector_configuration.empty()) {
    std::string missing_folder = "";

    if (folder_data.empty())
      missing_folder = "data folder";
    else if (folder_detector_configuration.empty() && do_check)
      missing_folder = "detector configuration";

    error_cout << "No folder for " << missing_folder << " specified" << std::endl;
    printUsage(argv);
    return -1;
  }

  // Set verbosity level
  std::cout << std::fixed << std::setprecision(6);
  logger::ll.verbosityLevel = verbosity;

  // Set device
  size_t n_devices = 0;
  std::string device_name;
  try {
    std::tie(n_devices, device_name) = set_device(cuda_device);
    if (n_devices == 0) {
      error_cout << "Failed to select device " << cuda_device << std::endl;
      return -1;
    }
  } catch (const std::invalid_argument& e) {
    error_cout << e.what() << std::endl;
    error_cout << "Failed to select device " << cuda_device << std::endl;
    return -1;
  }

  // Show call options
  std::cout << "Requested options:" << std::endl
            << " data folder (-f): " << folder_data << " (eg. \"../input/minbias/\")" << std::endl
            << " using " << (use_mdf ? "MDF" : "binary") << " input" << (use_mdf ? " (--mdf)" : "") << std::endl
            << " folder with detector configuration (-g): " << folder_detector_configuration << std::endl
            << " folder with imported forward tracks (-i): " << folder_name_imported_forward_tracks << std::endl
            << " run checkers (-c): " << do_check << std::endl
            << " number of files (-n): " << number_of_events_requested << std::endl
            << " start event offset (-o): " << start_event_offset << std::endl
            << " threads / streams (-t): " << number_of_threads << std::endl
            << " number of repetitions (-r): " << number_of_repetitions << std::endl
            << " reserve MB (-m): " << reserve_mb << std::endl
            << " print memory usage (-p): " << print_memory_usage << std::endl
            << " verbosity (-v): " << verbosity << std::endl
            << " device (--device) " << cuda_device << ": " << device_name << std::endl
            << std::endl;

  bool check_imported_forward_tracks = !folder_name_imported_forward_tracks.empty();

  // Print configured sequence
  print_configured_sequence();

  // Read all inputs
  info_cout << "Reading input datatypes" << std::endl;

  std::string folder_name_velopix_raw = folder_data + folder_rawdata + "VP";
  number_of_events_requested = get_number_of_events_requested(number_of_events_requested, folder_name_velopix_raw);

  const auto folder_name_UT_raw = folder_data + folder_rawdata + "UT";
  const auto folder_name_mdf = folder_data + folder_rawdata + "mdf";
  const auto folder_name_SciFi_raw = folder_data + folder_rawdata + "FTCluster";
  const auto folder_name_Muon_raw = folder_data + folder_rawdata + "Muon";
  const auto geometry_reader = GeometryReader(folder_detector_configuration);
  const auto ut_magnet_tool_reader = UTMagnetToolReader(folder_detector_configuration);

  std::unique_ptr<EventReader> event_reader;
  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader;
  if (use_mdf) {
    event_reader = std::make_unique<MDFReader>(FolderMap {{{BankTypes::VP, folder_name_mdf},
                                                           {BankTypes::UT, folder_name_mdf},
                                                           {BankTypes::FT, folder_name_mdf},
                                                           {BankTypes::MUON, folder_name_mdf}}});
  }
  else {
    event_reader = std::make_unique<EventReader>(FolderMap {{{BankTypes::VP, folder_name_velopix_raw},
                                                             {BankTypes::UT, folder_name_UT_raw},
                                                             {BankTypes::FT, folder_name_SciFi_raw},
                                                             {BankTypes::MUON, folder_name_Muon_raw}}});
  }

  const auto velo_geometry = geometry_reader.read_geometry("velo_geometry.bin");
  const auto ut_boards = geometry_reader.read_geometry("ut_boards.bin");
  const auto ut_geometry = geometry_reader.read_geometry("ut_geometry.bin");
  const auto ut_magnet_tool = ut_magnet_tool_reader.read_UT_magnet_tool();
  const auto scifi_geometry = geometry_reader.read_geometry("scifi_geometry.bin");
  event_reader->read_events(number_of_events_requested, start_event_offset);

  muon_catboost_model_reader = std::make_unique<CatboostModelReader>(folder_detector_configuration + "muon_catboost_model.json");
  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(muon_field_of_interest_params, folder_detector_configuration + "field_of_interest_params.bin");

  std::vector<Checker::Tracks> forward_tracks;
  if (check_imported_forward_tracks) {
    std::vector<char> events_tracks;
    std::vector<uint> event_tracks_offsets;
    read_folder(
      folder_name_imported_forward_tracks,
      number_of_events_requested,
      events_tracks,
      event_tracks_offsets,
      start_event_offset);
    forward_tracks = read_forward_tracks(events_tracks.data(), event_tracks_offsets.data(), number_of_events_requested);
  }
  info_cout << std::endl << "All input datatypes successfully read" << std::endl << std::endl;

  // Initialize detector constants on GPU
  Constants constants;
  constants.reserve_and_initialize(muon_field_of_interest_params, folder_detector_configuration + "params_kalman/FT6x2/");
  constants.initialize_ut_decoding_constants(ut_geometry);
  constants.initialize_geometry_constants(velo_geometry, ut_boards, ut_geometry, ut_magnet_tool, scifi_geometry);
  constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader->n_trees(),
    muon_catboost_model_reader->tree_depths(),
    muon_catboost_model_reader->tree_offsets(),
    muon_catboost_model_reader->leaf_values(),
    muon_catboost_model_reader->leaf_offsets(),
    muon_catboost_model_reader->split_border(),
    muon_catboost_model_reader->split_feature());

  // Create streams
  StreamWrapper stream_wrapper;
  stream_wrapper.initialize_streams(
    number_of_threads, number_of_events_requested, print_memory_usage, start_event_offset, reserve_mb, constants, do_check);

  // Notify used memory if requested verbose mode
  if (logger::ll.verbosityLevel >= logger::verbose) {
    print_gpu_memory_consumption();
  }

  // Lambda with the execution of a thread / stream
  const auto thread_execution = [&](uint i) {
    auto runtime_options = RuntimeOptions {event_reader->events(BankTypes::VP).begin(),
                                           event_reader->offsets(BankTypes::VP).begin(),
                                           event_reader->events(BankTypes::VP).size(),
                                           event_reader->offsets(BankTypes::VP).size(),
                                           event_reader->events(BankTypes::UT).begin(),
                                           event_reader->offsets(BankTypes::UT).begin(),
                                           event_reader->events(BankTypes::UT).size(),
                                           event_reader->offsets(BankTypes::UT).size(),
                                           event_reader->events(BankTypes::FT).begin(),
                                           event_reader->offsets(BankTypes::FT).begin(),
                                           event_reader->events(BankTypes::FT).size(),
                                           event_reader->offsets(BankTypes::FT).size(),
                                           event_reader->events(BankTypes::MUON).begin(),
                                           event_reader->offsets(BankTypes::MUON).begin(),
                                           event_reader->events(BankTypes::MUON).size(),
                                           event_reader->offsets(BankTypes::MUON).size(),
                                           number_of_events_requested,
                                           number_of_repetitions,
                                           do_check,
                                           cpu_offload};

    stream_wrapper.run_stream(i, runtime_options);
  };

  // Vector of threads
  std::vector<std::thread> threads;

  Timer t;
  // Create and invoke all threads
  for (uint i = 0; i < number_of_threads; ++i) {
    threads.emplace_back(thread_execution, i);
  }

  // Join all threads
  for (auto& thread : threads) {
    thread.join();
  }
  t.stop();

  // Do optional Monte Carlo truth test on stream 0
  if (do_check) {
    stream_wrapper.run_monte_carlo_test(0, folder_data + "MC_info/", number_of_events_requested, forward_tracks);
  }

  std::cout << (number_of_events_requested * number_of_threads * number_of_repetitions / t.get()) << " events/s"
            << std::endl
            << "Ran test for " << t.get() << " seconds" << std::endl;

  // Reset device
  cudaCheck(cudaDeviceReset());

  return 0;
}
