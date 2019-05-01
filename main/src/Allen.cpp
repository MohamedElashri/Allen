/**
 *      CUDA HLT1
 *
 *      author  -  GPU working group
 *      e-mail  -  lhcb-rta-accelerators@cern.ch
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
#include "MuonRawToHitsDecoding.h"
#include "Consumers.h"
#include "Allen.h"

void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants) {
  tuple consumers{tuple{Allen::NonEventData::UTBoards{}, std::make_unique<Consumers::BasicGeometry>(constants.dev_ut_boards)},
                  tuple{Allen::NonEventData::UTLookupTables{}, std::make_unique<Consumers::UTLookupTables>(constants.dev_ut_magnet_tool)},
                  tuple{Allen::NonEventData::UTGeometry{}, std::make_unique<Consumers::UTGeometry>(constants)},
                  tuple{Allen::NonEventData::SciFiGeometry{}, std::make_unique<Consumers::SciFiGeometry>(constants.host_scifi_geometry, constants.dev_scifi_geometry)},
                  tuple{Allen::NonEventData::MagneticField{}, std::make_unique<Consumers::MagneticField>(constants.dev_magnet_polarity)},
                  tuple{Allen::NonEventData::Beamline{}, std::make_unique<Consumers::Beamline>(constants.dev_beamline)},
                  tuple{Allen::NonEventData::VeloGeometry{}, std::make_unique<Consumers::RawGeometry>(constants.dev_velo_geometry)}};

  for_each(consumers, [updater, &constants] (auto& c) {
                        using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
                        updater->registerConsumer<id_t>(std::move(std::get<1>(c)));
                      });
}

int allen(map<string, string> options, Allen::NonEventData::IUpdater* updater) {

  // Folder containing raw, MC and muon information
  std::string folder_data = "../input/minbias/";
  const std::string folder_rawdata = "banks/";
  // Folder containing detector configuration and catboost model
  std::string folder_detector_configuration = "../input/detector_configuration/down/";

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

  string flag, arg;
  for (auto const& entry : options) {
    std::tie(flag, arg) = entry;
    if (flag == "cuda_device") {
      cuda_device = atoi(arg.c_str());
    } else if (flag == "mdf") {
      use_mdf = atoi(arg.c_str());
    } else if (flag == "cpu-offload") {
      cpu_offload = atoi(arg.c_str());
    } else if (flag == "f") {
      folder_data = arg + "/";
    } else if (flag == "g") {
      folder_detector_configuration = arg + "/";
    } else if (flag == "i") {
      folder_name_imported_forward_tracks = arg;
    } else if (flag == "m") {
      reserve_mb = atoi(arg.c_str());
    } else if (flag == "n") {
      number_of_events_requested = atoi(arg.c_str());
    } else if (flag == "o") {
      start_event_offset = atoi(arg.c_str());
    } else if (flag == "t") {
      number_of_threads = atoi(arg.c_str());
    } else if (flag == "r") {
      number_of_repetitions = atoi(arg.c_str());
    } else if (flag == "c") {
      do_check = atoi(arg.c_str());
    } else if (flag == "v") {
      verbosity = atoi(arg.c_str());
    } else if (flag == "p") {
      print_memory_usage = atoi(arg.c_str());
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
    } else {
      debug_cout << " selected cuda device " << cuda_device << ": " << device_name << std::endl << std::endl;
    }
  } catch (const std::invalid_argument& e) {
    error_cout << e.what() << std::endl;
    error_cout << "Failed to select cuda device " << cuda_device << std::endl;
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
            << " offload part of the computation to CPU (--cpu-offload) " << cpu_offload << std::endl
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

  std::unique_ptr<EventReader> event_reader;
  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader;
  if (use_mdf) {
    event_reader = std::make_unique<MDFReader>(FolderMap {{{BankTypes::VP, folder_name_mdf},
                                                           {BankTypes::UT, folder_name_mdf},
                                                           {BankTypes::FT, folder_name_mdf},
                                                           {BankTypes::MUON, folder_name_Muon_raw}}});
  } else {
    event_reader = std::make_unique<EventReader>(FolderMap {{{BankTypes::VP, folder_name_velopix_raw},
                                                             {BankTypes::UT, folder_name_UT_raw},
                                                             {BankTypes::FT, folder_name_SciFi_raw},
                                                             {BankTypes::MUON, folder_name_Muon_raw}}});
  }

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
  constants.reserve_and_initialize(muon_field_of_interest_params, folder_detector_configuration + "params_kalman_FT6x2/");
  constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader->n_trees(),
    muon_catboost_model_reader->tree_depths(),
    muon_catboost_model_reader->tree_offsets(),
    muon_catboost_model_reader->leaf_values(),
    muon_catboost_model_reader->leaf_offsets(),
    muon_catboost_model_reader->split_border(),
    muon_catboost_model_reader->split_feature());

  // Register all consumers
  register_consumers(updater, constants);

  // Run all registered produces and consumers
  updater->update(0);

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
