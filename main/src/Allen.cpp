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
#include <tuple>
#include <vector>
#include <algorithm>
#include <thread>
#include <bitset>
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>

#include <zmq.hpp>
#include <ZeroMQSvc.h>

#include "cuda_runtime.h"
#include "CudaCommon.h"
#include "RuntimeOptions.h"
#include "ProgramOptions.h"
#include "Logger.h"
#include "Tools.h"
#include "InputTools.h"
#include "InputReader.h"
#include "MDFReader.h"
#include "MDFProvider.h"
#include "Timer.h"
#include "StreamWrapper.cuh"
#include "Constants.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHitsDecoding.h"
#include "Consumers.h"
#include "Allen.h"

namespace {
  constexpr size_t n_io = 1;
  constexpr size_t max_input_slices = 512;
  constexpr size_t max_event_threads = 32;

  enum class SliceStatus {
                          Empty,
                          Filling,
                          Filled,
                          Processing
  };
}

void input_reader(const size_t io_id, IInputProvider* input_provider) {

  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);

  auto con = connection(io_id);
  try {
    control.connect(con.c_str());
  } catch (const zmq::error_t& e) {
    cout << "failed to connect connection " << con << endl;
    throw e;
  }

  zmq::pollitem_t items [] = {{control, 0, zmq::POLLIN, 0}};

  while (true) {

    // Indicate to the main thread that the reader is ready
    zmqSvc().send(control, "READY");

    // Wait to get assigned a slice index
    zmq::poll(&items[0], 1, -1);

    size_t idx = 0;
    size_t fill = 0;
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<string>(control);
      if (msg == "DONE") {
        break;
      } else {
        idx = zmqSvc().receive<size_t>(control);
        fill = zmqSvc().receive<size_t>(control);

        auto r = input_provider->fill(idx, fill);
        zmqSvc().send(control, "FILLED", zmq::SNDMORE);
        zmqSvc().send(control, idx, zmq::SNDMORE);
        zmqSvc().send(control, std::get<0>(r), zmq::SNDMORE);
        zmqSvc().send(control, std::get<2>(r));
      }
    }
  }
}

void event_processor(const size_t pid, int cuda_device, StreamWrapper& wrapper,
                     IInputProvider const* input_provider,
                     bool do_check, bool cpu_offload) {

  size_t n_devices = 0;
  std::string device_name;
  bool cuda_set = true;
  try {
    std::tie(n_devices, device_name) = set_device(cuda_device);
    if (n_devices == 0) {
      error_cout << "Failed to select device " << cuda_device << std::endl;
      return -1;
    }
    else {
      debug_cout << " selected cuda device " << cuda_device << ": " << device_name << std::endl << std::endl;
    }
  } catch (const std::invalid_argument& e) {
    error_cout << e.what() << std::endl;
    error_cout << "Failed to select cuda device " << cuda_device << std::endl;
    cuda_set = false;
  }

  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);
  std::this_thread::sleep_for(std::chrono::milliseconds{50});
  auto con = connection(pid);
  try {
    control.connect(con.c_str());
  } catch (const zmq::error_t& e) {
    cout << "failed to connect connection " << con << endl;
    throw e;
  }

  zmq::pollitem_t items [] = {
                              {control, 0, ZMQ_POLLIN, 0},
  };

  // Indicate to the main thread that we are ready to process
  std::optional<bool> good;
  do {
    try {
      good = zmqSvc().send(control, cuda_set);
    } catch (const zmq::error_t& err) {
      if (err.num() == EINTR) continue;
    }
  } while (!good);

  while (true) {

    // Wait until we need to process
    std::optional<int> n;
    do {
      try {
        n = zmq::poll(&items[0], 1, -1);
      } catch (const zmq::error_t& err) {
        warning_cout << "processor caught exception." << err.what() << std::endl;
        if (err.num() == EINTR) continue;
      }
    } while (!n);

    n.reset();

    string command;
    std::optional<size_t> idx;
    size_t n_events;
    if (items[0].revents & zmq::POLLIN) {
      command = zmqSvc().receive<string>(control);
      if (command == "DONE") {
        break;
      } else if (command != "PROCESS") {
        error_cout << "processor " << pid << " received bad command: " << command << endl;
      } else {
        idx = zmqSvc().receive<size_t>(control);
      }
    }

    if (idx) {
      // process a slice
      auto vp_banks = input_provider->banks(BankTypes::VP, *idx);
      // Not very clear, but the number of event offsets is the number of filled events.
      uint n_events = static_cast<uint>(std::get<1>(vp_banks).size());
      wrapper.run_stream(pid, {std::move(vp_banks),
                               input_provider->banks(BankTypes::UT, *idx),
                               input_provider->banks(BankTypes::FT, *idx),
                               input_provider->banks(BankTypes::MUON, *idx),
                               n_events,
                               1,
                               do_check,
                               cpu_offload});

      // signal that we're done
      zmqSvc().send(control, true);
    }
  }
}

void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants)
{
  tuple consumers {
    tuple {Allen::NonEventData::UTBoards {}, std::make_unique<Consumers::BasicGeometry>(constants.dev_ut_boards)},
    tuple {Allen::NonEventData::UTLookupTables {},
           std::make_unique<Consumers::UTLookupTables>(constants.dev_ut_magnet_tool)},
    tuple {Allen::NonEventData::UTGeometry {}, std::make_unique<Consumers::UTGeometry>(constants)},
    tuple {Allen::NonEventData::SciFiGeometry {},
           std::make_unique<Consumers::SciFiGeometry>(constants.host_scifi_geometry, constants.dev_scifi_geometry)},
    tuple {Allen::NonEventData::MagneticField {},
           std::make_unique<Consumers::MagneticField>(constants.dev_magnet_polarity)},
    tuple {Allen::NonEventData::Beamline {}, std::make_unique<Consumers::Beamline>(constants.dev_beamline)},
    tuple {Allen::NonEventData::VeloGeometry {}, std::make_unique<Consumers::VPGeometry>(constants)},
    tuple {Allen::NonEventData::MuonGeometry {},
           std::make_unique<Consumers::MuonGeometry>(
             constants.host_muon_geometry_raw, constants.dev_muon_geometry_raw, constants.dev_muon_geometry)},
    tuple {Allen::NonEventData::MuonLookupTables {},
           std::make_unique<Consumers::MuonLookupTables>(
             constants.host_muon_lookup_tables_raw, constants.dev_muon_lookup_tables_raw, constants.dev_muon_tables)}};

  for_each(consumers, [updater, &constants](auto& c) {
    using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
    updater->registerConsumer<id_t>(std::move(std::get<1>(c)));
  });

int allen(std::map<std::string, std::string> options, Allen::NonEventData::IUpdater* updater)
{
  // Folder containing raw, MC and muon information
  std::string folder_data = "../input/minbias/";
  const std::string folder_rawdata = "banks/";
  // Folder containing detector configuration and catboost model
  std::string folder_detector_configuration = "../input/detector_configuration/down/";

  std::string folder_name_imported_forward_tracks = "";
  uint number_of_slices = 1;
  long number_of_events_requested = 0;
  uint events_per_slice = 1000;
  uint start_event_offset = 0;
  uint number_of_threads = 1;
  uint number_of_repetitions = 1;
  uint verbosity = 3;
  bool print_memory_usage = false;
  // By default, do_check will be true when mc_check is enabled
  bool do_check = true;
  size_t reserve_mb = 1024;

  string mdf_input;
  int cuda_device = 0;
  int cpu_offload = 1;

  std::string flag, arg;
  const auto flag_in = [&flag](const std::vector<std::string>& option_flags) {
    if (std::find(std::begin(option_flags), std::end(option_flags), flag) != std::end(option_flags)) {
      return true;
    }
    return false;
  };

  // Use flags to populate variables in the program
  for (auto const& entry : options) {
    std::tie(flag, arg) = entry;
    if (flag_in({"f", "folder"})) {
      folder_data = arg + "/";
    }
    else if (flag_in({"g", "geometry"})) {
      folder_detector_configuration = arg + "/";
    } else if (flag_in({"mdf"})) {
      mdf_input = arg;
    } else if (flag_in({"n", "number-of-events"})) {
      number_of_events_requested = atol(arg.c_str());
    } else if (flag_in({"s", "number-of-slices"})) {
      number_of_slices = atoi(arg.c_str());
    } else if (flag_in({"t", "threads"})) {
      number_of_threads = atoi(arg.c_str());
    }
    else if (flag_in({"r", "repetitions"})) {
      number_of_repetitions = atoi(arg.c_str());
    }
    else if (flag_in({"c", "validate"})) {
      do_check = atoi(arg.c_str());
    }
    else if (flag_in({"m", "memory"})) {
      reserve_mb = atoi(arg.c_str());
    }
    else if (flag_in({"v", "verbosity"})) {
      verbosity = atoi(arg.c_str());
    }
    else if (flag_in({"p", "print-memory"})) {
      print_memory_usage = atoi(arg.c_str());
    }
    else if (flag_in({"i", "import-tracks"})) {
      folder_name_imported_forward_tracks = arg;
    }
    else if (flag_in({"cpu-offload"})) {
      cpu_offload = atoi(arg.c_str());
    }
    else if (flag_in({"device"})) {
      cuda_device = atoi(arg.c_str());
    }
  }

  if(number_of_slices < number_of_threads) {
    warning_cout << "Setting number of slices to " << number_of_threads + 1 << std::endl;
    number_of_slices = number_of_threads + 1;
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

  // Show call options
  print_call_options(options, device_name);

  bool check_imported_forward_tracks = !folder_name_imported_forward_tracks.empty();

  // Print configured sequence
  print_configured_sequence();

  // Read all inputs
  info_cout << "Reading input datatypes" << std::endl;

  std::string folder_name_velopix_raw = folder_data + folder_rawdata + "VP";
  number_of_events_requested = get_number_of_events_requested(number_of_events_requested, folder_name_velopix_raw);
  // FIXME, this should be separate
  events_per_slice = number_of_events_requested;
  const auto folder_name_UT_raw = folder_data + folder_rawdata + "UT";
  const auto folder_name_mdf = folder_data + folder_rawdata + "mdf";
  const auto folder_name_SciFi_raw = folder_data + folder_rawdata + "FTCluster";
  const auto folder_name_Muon_raw = folder_data + folder_rawdata + "Muon";

  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader;

  std::unique_ptr<EventReader> event_reader{};
  std::unique_ptr<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>> mdf_provider{};
  BanksAndOffsets velo_events{}, ut_events{}, scifi_events{}, muon_events{};
  if (!mdf_input.empty()) {
    vector<string> connections;
    size_t current = mdf_input.find(","), previous = 0;
    while (current != string::npos) {
      connections.emplace_back(mdf_input.substr(previous, current - previous));
      previous = current + 1;
      current = mdf_input.find(",", previous);
    }
    connections.emplace_back(mdf_input.substr(previous, current - previous));
    mdf_provider = std::make_unique<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>>(1, events_per_slice, std::move(connections));
  } else {
    event_reader = std::make_unique<EventReader>(FolderMap {{{BankTypes::VP, folder_name_velopix_raw},
                                                             {BankTypes::UT, folder_name_UT_raw},
                                                             {BankTypes::FT, folder_name_SciFi_raw},
                                                             {BankTypes::MUON, folder_name_Muon_raw}}});
    event_reader->read_events(number_of_events_requested, start_event_offset);
    velo_events = BanksAndOffsets{{event_reader->events(BankTypes::VP).begin(),
                                   event_reader->events(BankTypes::VP).size()},
                                  {event_reader->offsets(BankTypes::VP).begin(),
                                   event_reader->offsets(BankTypes::VP).size()}};
    ut_events = BanksAndOffsets{{event_reader->events(BankTypes::UT).begin(),
                                 event_reader->events(BankTypes::UT).size()},
                                {event_reader->offsets(BankTypes::UT).begin(),
                                 event_reader->offsets(BankTypes::UT).size()}};
    scifi_events = BanksAndOffsets{{event_reader->events(BankTypes::FT).begin(),
                                    event_reader->events(BankTypes::FT).size()},
                                   {event_reader->offsets(BankTypes::FT).begin(),
                                    event_reader->offsets(BankTypes::FT).size()}};
    muon_events = BanksAndOffsets{{event_reader->events(BankTypes::MUON).begin(),
                                   event_reader->events(BankTypes::MUON).size()},
                                  {event_reader->offsets(BankTypes::MUON).begin(),
                                   event_reader->offsets(BankTypes::MUON).size()}};

  }

  muon_catboost_model_reader =
    std::make_unique<CatboostModelReader>(folder_detector_configuration + "muon_catboost_model.json");
  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(
    muon_field_of_interest_params, folder_detector_configuration + "field_of_interest_params.bin");

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
  constants.reserve_and_initialize(
    muon_field_of_interest_params, folder_detector_configuration + "params_kalman_FT6x2/");
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
    number_of_threads,
    number_of_events_requested,
    print_memory_usage,
    start_event_offset,
    reserve_mb,
    constants,
    do_check);

  // Notify used memory if requested verbose mode
  if (logger::ll.verbosityLevel >= logger::verbose) {
    print_gpu_memory_consumption();
  }

  // Lambda with the execution of a thread / stream
  const auto event_thread = [&](uint i) {
                              event_processor(i, cuda_device, stream_wrapper,
                                              mdf_provider.get(), do_check, cpu_offload);
                            };

  const auto io_thread = [&](uint i) {
                           input_reader(i, mdf_provider.get());
                         };
  using start_thread = std::function<void(uint)>;

  // Vector of threads
  std::vector<zmq::pollitem_t> items; items.resize(number_of_threads + 1);

  using workers_t = std::vector<std::tuple<std::thread, zmq::socket_t>>;
  workers_t event_processors; event_processors.reserve(number_of_threads);
  workers_t io_workers; io_workers.reserve(1);

  Timer t;

  // Start all workers
  size_t conn_id = 0;
  for (auto& [workers, start, n, type] : {std::tuple{&io_workers, start_thread{io_thread}, 1u, "input"},
                                          std::tuple{&event_processors, start_thread{event_thread}, number_of_threads, "events"}}) {
    for (uint i = 0; i < n; ++i) {
      zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
      zmq::setsockopt(control, zmq::LINGER, 0);
      auto con = connection(conn_id);
      control.bind(con.c_str());
      // I don't know why, but this prevents problems. Probably
      // some race condition I haven't noticed.
      std::this_thread::sleep_for(std::chrono::milliseconds{50});
      workers->emplace_back(std::thread{ start, conn_id }, std::move(control));
      items[conn_id] = {std::get<1>(workers->back()), 0, zmq::POLLIN, 0};
      cout << "started " << type << " (" << i + 1 << "/" << n << ") "
           << conn_id << endl;
      ++conn_id;
    }
  }

  // keep track of what the status of slices is
  std::vector<SliceStatus> input_slice_status(number_of_slices, SliceStatus::Empty);
  // processing stream status
  std::bitset<max_event_threads> stream_ready(false);

  auto count_status = [&input_slice_status] (SliceStatus const status) {
                        return std::accumulate(input_slice_status.begin(), input_slice_status.end(), 0ul,
                                               [] (size_t s, auto const status) { return s + (status == SliceStatus::Filled); });
                      };

  // Circular index which slice to process next
  size_t prev_processor = 0;
  size_t prev_input_slice = 0;
  size_t n_events = 0;

  // Wait for at least one event to be ready
  zmq::poll(&items[0], n_io, -1);

  size_t error_count = 0;

  // Wait for all processors to be ready
  while ((stream_ready.count() + error_count) < number_of_threads) {
    std::optional<int> n;
    do {
      try {
        n = zmq::poll(&items[1], number_of_threads, -1);
      } catch (const zmq::error_t& err) {
        if (err.num() == EINTR) continue;
      }
    } while (!n);
    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[n_io + i].revents & ZMQ_POLLIN) {
        auto& socket = std::get<1>(event_processors[i]);
        auto success = zmqSvc().receive<bool>(socket);
        stream_ready[i] = success;
        cout << "event processor " << std::setw(2) << i
             << " (" << std::setw(2) << stream_ready.count()<< "/"
             << number_of_threads << ") " << n_io + i
             << " device " << cuda_device
             << (success ? " ready." : " failed.") << endl;
        error_count += !success;
      }
    }
  }

  bool io_done = false;
  while (error_count == 0) {

    // Wait for at least one event to be ready
    zmq::poll(&items[0], number_of_threads + n_io, -1);

    // Check if input_slices are ready
    for (size_t i = 0; i < n_io; ++i) {
      if (items[i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(io_workers[i]);
        auto msg = zmqSvc().receive<string>(socket);
        if (msg == "READY") {
          auto it = std::find(input_slice_status.begin(), input_slice_status.end(),
                              SliceStatus::Empty);
          *it = SliceStatus::Filling;
          size_t idx = std::distance(input_slice_status.begin(), it);
          size_t fill = number_of_events_requested == -1 ? events_per_slice : number_of_events_requested - n_events;
          zmqSvc().send(socket, "FILL", zmq::SNDMORE);
          zmqSvc().send(socket, idx, zmq::SNDMORE);
          zmqSvc().send(socket, fill);
        } else {
          assert(msg == "FILLED");
          auto slice_index = zmqSvc().receive<int>(socket);
          auto good = zmqSvc().receive<bool>(socket);
          auto n_filled = zmqSvc().receive<size_t>(socket);

          if (good) {
            input_slice_status[slice_index] = SliceStatus::Filled;
            n_events += n_filled;
          } else {
            error_cout << "IO provider failed to decode events into slice." << std::endl;
            goto loop_error;
          }

          if (n_events >= number_of_events_requested) {
            io_done = true;
            zmqSvc().send(socket, "DONE");
            info_cout << "IO complete." << std::endl;
          }
        }
      }
    }

    // Check if any processors are ready
    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[n_io + i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(event_processors[i]);
        auto r = zmqSvc().receive<bool>(socket);
        if (r) {
          stream_ready[i] = true;
        } else {
          error_cout << "event thread " << i << " sent message, but not ready." << endl;
        }
      }
    }

    // Find a processor that is ready to process
    std::optional<size_t> processor_index;
    if (!stream_ready.count()) {
      warning_cout << "No processor ready to accept slice" << endl;
    } else {
      for (size_t i = 0; i < number_of_threads; ++i) {
        size_t idx = (i + prev_processor + 1) % number_of_threads;
        if (stream_ready[idx]) {
          processor_index = idx;
          prev_processor = *processor_index;
          break;
        }
      }
    }

    // A processor is ready
    if (processor_index && !count_status(SliceStatus::Filled)) {
      debug_cout << "No slice ready to process." << endl;
    } else if (processor_index) {
      // Find an event slice
      size_t input_slice_idx = 0;
      for (size_t i = 0; i < number_of_slices; ++i) {
        input_slice_idx = (i + prev_input_slice + 1) % number_of_slices;
        if (input_slice_status[input_slice_idx] == SliceStatus::Filled) {
          prev_input_slice = input_slice_idx;

          // send message to processor to process the slice
          stream_ready[*processor_index] = false;
          auto& socket = std::get<1>(event_processors[*processor_index]);
          zmqSvc().send(socket, "PROCESS", zmq::SNDMORE);
          zmqSvc().send(socket, input_slice_idx);

          info_cout << "slice " << std::setw(6) << n_events
                    << " slice index  " << std::setw(2) << input_slice_idx
                    << " stream " << std::setw(2) << *processor_index << std::endl;
        }
      }
    }

    if (io_done && stream_ready.count() == number_of_threads) {
      info_cout << "Processing complete." << std::endl;
      break;
    }
  }

  loop_error:
  // Let processors that are still busy finish
  while((stream_ready.count() + error_count) < number_of_threads) {

    zmq::poll(&items[n_io], number_of_threads, -1);

    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[n_io + i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(event_processors[i]);
        auto r = zmqSvc().receive<bool>(socket);
        if (r) {
          stream_ready[i] = true;
        } else {
          error_cout << "event thread " << i << " sent message, but not ready." << std::endl;
          ++error_count;
        }
      }
    }
  }

  // Send stop signal to all threads and join them
  for (auto* workers : {&io_workers, &event_processors}) {
    for (auto& worker : *workers) {
      zmqSvc().send(std::get<1>(worker), "DONE");
      std::get<0>(worker).join();
    }
  }

  t.stop();

  // Do optional Monte Carlo truth test on stream 0
  if (do_check) {
    CheckerInvoker invoker{};
    auto mask = stream_wrapper.reconstructed_events(0);
    auto mc_events = invoker.load(folder_data + "MC_info/", input_events, mask);
    stream_wrapper.run_monte_carlo_test(0, invoker, mc_events, forward_tracks);
    invoker.report(number_of_events_requested);
  }

  std::cout << (number_of_events_requested * number_of_threads * number_of_repetitions / t.get()) << " events/s"
            << std::endl
            << "Ran test for " << t.get() << " seconds" << std::endl;

  // Reset device
  cudaCheck(cudaDeviceReset());

  return 0;
}
