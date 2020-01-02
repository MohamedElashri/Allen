/**
 *      Allen
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
#include <cstdio>
#include <ctime>
#include <unistd.h>
#include <getopt.h>
#include <memory>
#include <tuple>

#include <zmq.hpp>
#include <ZeroMQSvc.h>

#include "CudaCommon.h"
#include "RuntimeOptions.h"
#include "ProgramOptions.h"
#include "Logger.h"
#include "Tools.h"
#include "InputTools.h"
#include "InputReader.h"
#include "MDFProvider.h"
#include "BinaryProvider.h"
#include "MEPProvider.h"
#include "Timer.h"
#include "StreamWrapper.cuh"
#include "Constants.cuh"
#include "MuonDefinitions.cuh"
#include "Consumers.h"
#include "CheckerInvoker.h"
#include "HostBuffersManager.cuh"
#include "MonitorManager.h"
#include "FileWriter.h"
#include "Allen.h"

namespace {
  enum class SliceStatus { Empty, Filling, Filled, Processing, Processed, Writing, Written };
} // namespace

/**
 * @brief      Request slices from the input provider and report
 *             them to the main thread; run from a separate thread
 *
 * @param      thread ID of this I/O thread
 * @param      IInputProvider instance
 *
 * @return     void
 */
void run_io(
  const size_t io_id,
  IInputProvider* input_provider,
  OutputHandler* output_handler,
  HostBuffersManager* buffer_manager)
{

  // Create a control socket and connect it.
  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);

  auto con = ZMQ::connection(io_id);
  try {
    control.connect(con.c_str());
  } catch (const zmq::error_t& e) {
    error_cout << "failed to connect connection " << con << "\n";
    throw e;
  }

  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};

  bool input_done(false);

  while (true) {

    // Check if there are messages
    zmq::poll(&items[0], 1, 0);

    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(control);
      if (msg == "DONE") {
        break;
      }
      else if (msg == "WRITE") {
        auto slc_idx = zmqSvc().receive<size_t>(control);
        auto first_evt = zmqSvc().receive<size_t>(control);
        auto buf_idx = zmqSvc().receive<size_t>(control);

        auto [n_selected, passing_event_list, dec_reports] = buffer_manager->getBufferOutputData(buf_idx);
        // It's easier to shift indices for DecReports than for the input banks
        // so shift all event numbers by the offset of the first event
        if (first_evt != 0) {
          for (size_t i = 0; i < n_selected; ++i) {
            passing_event_list[i] += first_evt;
          }
        }
        bool success(true);

        if (output_handler != nullptr) {
          success =
            output_handler->output_selected_events(slc_idx, first_evt, {passing_event_list, n_selected}, dec_reports);
        }

        zmqSvc().send(control, "WRITTEN", zmq::SNDMORE);
        zmqSvc().send(control, slc_idx, zmq::SNDMORE);
        zmqSvc().send(control, first_evt, zmq::SNDMORE);
        zmqSvc().send(control, buf_idx, zmq::SNDMORE);
        zmqSvc().send(control, success, zmq::SNDMORE);
        zmqSvc().send(control, n_selected);
      }
    }

    if (!input_done) {
      // Get a slice and inform the main thread that it is available
      // NOTE: the argument specifies the timeout in ms, not the number of events.
      auto [good, done, timed_out, slice_index, n_filled] = input_provider->get_slice(1000);
      // Report errors or good slices that contain events
      if (!timed_out && good && n_filled != 0) {
        zmqSvc().send(control, "SLICE", zmq::SNDMORE);
        zmqSvc().send(control, slice_index, zmq::SNDMORE);
        zmqSvc().send(control, n_filled);
      }
      else if (!good) {
        zmqSvc().send(control, "ERROR");
        break;
      }
      if (done) {
        input_done = true;
        zmqSvc().send(control, "DONE");
      }
    }
  }
}

/**
 * @brief      Process events on GPU streams; run from a separate thread
 *
 * @param      thread ID
 * @param      GPU stream ID
 * @param      GPU device id
 * @param
 * @param      CUDA device
 *
 * @return     return type
 */
void run_stream(
  size_t const thread_id,
  size_t const stream_id,
  int device_id,
  StreamWrapper* wrapper,
  IInputProvider const* input_provider,
  OutputHandler* output_handler,
  CheckerInvoker* checker_invoker,
  uint n_reps,
  bool do_check,
  bool cpu_offload,
  bool allen_layout,
  std::string folder_name_imported_forward_tracks)
{
  auto make_control = [thread_id](std::string suffix = std::string {}) {
    zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
    zmq::setsockopt(control, zmq::LINGER, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds {50});
    auto con = ZMQ::connection(thread_id, suffix);
    try {
      control.connect(con.c_str());
    } catch (const zmq::error_t& e) {
      error_cout << "failed to connect connection " << con << "\n";
      throw e;
    }
    return control;
  };

  zmq::socket_t control = make_control();
  std::optional<zmq::socket_t> check_control;
  if (do_check || output_handler != nullptr) {
    check_control = make_control("check");
  }

  auto [device_set, device_name] = set_device(device_id, stream_id);

  zmq::pollitem_t items[] = {
    {control, 0, ZMQ_POLLIN, 0},
  };

  // Indicate to the main thread that we are ready to process
  std::optional<bool> good;
  do {
    try {
      zmqSvc().send(control, "READY", zmq::SNDMORE);
      good = zmqSvc().send(control, device_set);
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
        if (err.num() == EINTR) {
          continue;
        }
        else {
          warning_cout << "processor caught exception." << err.what() << "\n";
        }
      }
    } while (!n);

    n.reset();

    std::string command;
    std::optional<size_t> idx;
    std::optional<size_t> buf;
    std::optional<size_t> first;
    std::optional<size_t> last;
    if (items[0].revents & zmq::POLLIN) {
      command = zmqSvc().receive<std::string>(control);
      if (command == "DONE") {
        break;
      }
      else if (command != "PROCESS") {
        error_cout << "processor " << stream_id << " received bad command: " << command << "\n";
      }
      else {
        idx = zmqSvc().receive<size_t>(control);
        first = zmqSvc().receive<size_t>(control);
        last = zmqSvc().receive<size_t>(control);
        buf = zmqSvc().receive<size_t>(control);
      }
    }

    if (idx) {
      // Get list of events that are in the slice
      auto const& events = input_provider->event_ids(*idx);

      // Run the stream
      auto status = wrapper->run_stream(
        stream_id,
        *buf,
        {input_provider->banks(BankTypes::VP, *idx),
         input_provider->banks(BankTypes::UT, *idx),
         input_provider->banks(BankTypes::FT, *idx),
         input_provider->banks(BankTypes::MUON, *idx),
         static_cast<uint>(events.size()),
         n_reps,
         do_check,
         cpu_offload,
         !allen_layout});

      if (status == cudaErrorMemoryAllocation) {
        zmqSvc().send(control, "SPLIT", zmq::SNDMORE);
        zmqSvc().send(control, *idx, zmq::SNDMORE);
        zmqSvc().send(control, *first, zmq::SNDMORE);
        zmqSvc().send(control, *last, zmq::SNDMORE);
        zmqSvc().send(control, *buf);
      }
      else if (status == cudaSuccess) {
        // signal that we're done
        zmqSvc().send(control, "PROCESSED", zmq::SNDMORE);
        zmqSvc().send(control, *idx, zmq::SNDMORE);
        zmqSvc().send(control, *first, zmq::SNDMORE);
        zmqSvc().send(control, *buf);
        if (do_check && check_control) {
          // Get list of events that are in the slice to load the right
          // MC info
          auto const& events = input_provider->event_ids(*idx);
          EventIDs used_events;
          if (first != 0 || last != events.size()) {
            used_events = EventIDs(events.begin() + *first, events.begin() + *last);
          }
          else {
            used_events = events;
          }

          // synchronise to avoid threading issues with
          // CheckerInvoker. The main thread will send the folder to
          // only one stream at a time and will block until it receives
          // the message that informs it the checker is done.
          auto mc_folder = zmqSvc().receive<std::string>(*check_control);
          auto mask = wrapper->reconstructed_events(stream_id);
          auto mc_events = checker_invoker->load(mc_folder, used_events, mask);

          if (mc_events.empty()) {
            zmqSvc().send(*check_control, false);
          }
          else {
            // Run the checker
            std::vector<Checker::Tracks> forward_tracks;
            if (!folder_name_imported_forward_tracks.empty()) {
              std::vector<char> events_tracks;
              std::vector<uint> event_tracks_offsets;
              read_folder(
                folder_name_imported_forward_tracks, used_events, mask, events_tracks, event_tracks_offsets, true);
              forward_tracks =
                read_forward_tracks(events_tracks.data(), event_tracks_offsets.data(), used_events.size());
            }

            wrapper->run_monte_carlo_test(stream_id, *checker_invoker, mc_events, forward_tracks);
            zmqSvc().send(*check_control, true);
          }
        }
      }
    }
  }
}

/**
 * @brief      Receive filled HostBuffers from GPU
 *             threads and produce rate histograms
 *
 * @param      thread ID of this monitoring thread
 * @param      manager for the monitor objects
 * @param      index of the monitor objects to use for this thread
 *
 * @return     void
 */
void run_monitoring(const size_t mon_id, MonitorManager* monitor_manager, uint i_monitor)
{

  // Create a control socket and connect it.
  zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
  zmq::setsockopt(control, zmq::LINGER, 0);

  auto con = ZMQ::connection(mon_id);
  try {
    control.connect(con.c_str());
  } catch (const zmq::error_t& e) {
    error_cout << "failed to connect connection " << con << "\n";
    throw e;
  }

  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};

  while (true) {

    // Wait until we need to process
    std::optional<int> n;
    do {
      try {
        n = zmq::poll(&items[0], 1, -1);
      } catch (const zmq::error_t& err) {
        if (err.num() == EINTR) {
          continue;
        }
        else {
          warning_cout << "processor caught exception." << err.what() << "\n";
        }
      }
    } while (!n);

    n.reset();

    // Check if there are messages
    zmq::poll(&items[0], 1, 0);

    std::optional<size_t> buf_idx;
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc().receive<std::string>(control);
      if (msg == "DONE") {
        break;
      }
      else if (msg != "MONITOR") {
        error_cout << "monitor thread " << mon_id << " received bad command: " << msg << "\n";
      }
      else {
        buf_idx = zmqSvc().receive<size_t>(control);
      }
    }

    if (buf_idx) {
      monitor_manager->fill(i_monitor, *buf_idx);
      zmqSvc().send(control, "MONITORED", zmq::SNDMORE);
      zmqSvc().send(control, *buf_idx, zmq::SNDMORE);
      zmqSvc().send(control, i_monitor);
    }
  }
}

/**
 * @brief      Register all consumers of non-event data
 *
 * @param      IUpdater instance
 * @param      Constants
 *
 * @return     void
 */
void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants)
{
  std::tuple consumers = std::make_tuple(
    std::make_tuple(
      Allen::NonEventData::UTBoards {}, std::make_unique<Consumers::BasicGeometry>(constants.dev_ut_boards)),
    std::make_tuple(
      Allen::NonEventData::UTLookupTables {},
      std::make_unique<Consumers::UTLookupTables>(constants.dev_ut_magnet_tool)),
    std::make_tuple(Allen::NonEventData::UTGeometry {}, std::make_unique<Consumers::UTGeometry>(constants)),
    std::make_tuple(
      Allen::NonEventData::SciFiGeometry {},
      std::make_unique<Consumers::SciFiGeometry>(constants.host_scifi_geometry, constants.dev_scifi_geometry)),
    std::make_tuple(
      Allen::NonEventData::MagneticField {}, std::make_unique<Consumers::MagneticField>(constants.dev_magnet_polarity)),
    std::make_tuple(Allen::NonEventData::Beamline {}, std::make_unique<Consumers::Beamline>(constants.dev_beamline)),
    std::make_tuple(Allen::NonEventData::VeloGeometry {}, std::make_unique<Consumers::VPGeometry>(constants)),
    std::make_tuple(
      Allen::NonEventData::MuonGeometry {},
      std::make_unique<Consumers::MuonGeometry>(
        constants.host_muon_geometry_raw, constants.dev_muon_geometry_raw, constants.dev_muon_geometry)),
    std::make_tuple(
      Allen::NonEventData::MuonLookupTables {},
      std::make_unique<Consumers::MuonLookupTables>(
        constants.host_muon_lookup_tables_raw, constants.dev_muon_lookup_tables_raw, constants.dev_muon_tables)));

  for_each(consumers, [updater](auto& c) {
    using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
    updater->registerConsumer<id_t>(std::move(std::get<1>(c)));
  });
}

/**
 * @brief      Main entry point
 *
 * @param      {key : value} command-line arguments as std::strings
 * @param      IUpdater instance
 *
 * @return     int
 */
int allen(std::map<std::string, std::string> options, Allen::NonEventData::IUpdater* updater)
{
  // Folder containing raw, MC and muon information
  std::string folder_data = "../input/minbias/";
  const std::string folder_rawdata = "banks/";
  // Folder containing detector configuration and catboost model
  std::string folder_detector_configuration = "../input/detector_configuration/down/";
  std::string json_constants_configuration_file = "../configuration/constants/default.json";

  std::string folder_name_imported_forward_tracks = "";
  uint number_of_slices = 0;
  uint number_of_buffers = 0;
  long number_of_events_requested = 0;
  std::optional<uint> events_per_slice;
  uint start_event_offset = 0;
  uint number_of_threads = 1;
  uint number_of_repetitions = 1;
  uint verbosity = 3;
  bool print_memory_usage = false;
  bool non_stop = false;
  bool write_config = false;
  // By default, do_check will be true when mc_check is enabled
  bool do_check = true;
  size_t reserve_mb = 1024;
  // MPI options
  bool with_mpi = false;
  int mpi_window_size = 4;
  // Input file options
  std::string mdf_input;
  std::string mep_input;
  bool allen_layout = false;
  std::string output_file;
  int device_id = 0;
  int cpu_offload = 1;
  std::string file_list;
  bool print_config = 0;
  bool print_buffer_status = 0;

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
    }
    else if (flag_in({"mdf"})) {
      mdf_input = arg;
    }
    else if (flag_in({"mep"})) {
      mep_input = arg;
    }
    else if (flag_in({"configuration"})) {
      json_constants_configuration_file = arg;
    }
    else if (flag_in({"transpose-mep"})) {
      allen_layout = atoi(arg.c_str());
    }
    else if (flag_in({"write-configuration"})) {
      write_config = atoi(arg.c_str());
    }
    else if (flag_in({"n", "number-of-events"})) {
      number_of_events_requested = atol(arg.c_str());
    }
    else if (flag_in({"s", "number-of-slices"})) {
      number_of_slices = atoi(arg.c_str());
    }
    else if (flag_in({"events-per-slice"})) {
      events_per_slice = atoi(arg.c_str());
    }
    else if (flag_in({"t", "threads"})) {
      number_of_threads = atoi(arg.c_str());
      if (number_of_threads > max_stream_threads) {
        error_cout << "Error: more than maximum number of threads (" << max_stream_threads << ") requested\n";
        return -1;
      }
    }
    else if (flag_in({"r", "repetitions"})) {
      number_of_repetitions = atoi(arg.c_str());
      if (number_of_repetitions == 0) {
        error_cout << "Error: number of repetitions must be at least 1\n";
        return -1;
      }
    }
    else if (flag_in({"c", "validate"})) {
      do_check = atoi(arg.c_str());
    }
    else if (flag_in({"m", "memory"})) {
      reserve_mb = atoi(arg.c_str());
    }
    else if (flag_in({"v", "verbosity"})) {
      verbosity = atoi(arg.c_str());
      cudaMemcpyToSymbol(&Configuration::verbosity_level, &verbosity, sizeof(uint));
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
    else if (flag_in({"output-file"})) {
      output_file = arg;
    }
    else if (flag_in({"device"})) {
      device_id = atoi(arg.c_str());
    }
    else if (flag_in({"with-mpi"})) {
      with_mpi = atoi(arg.c_str());
    }
    else if (flag_in({"file-list"})) {
      file_list = arg;
    }
    else if (flag_in({"mpi-window-size"})) {
      mpi_window_size = atoi(arg.c_str());
    }
    else if (flag_in({"print-config"})) {
      print_config = atoi(arg.c_str());
    }
    else if (flag_in({"non-stop"})) {
      non_stop = atoi(arg.c_str());
    }
    else if (flag_in({"print-buffer-status"})) {
      print_buffer_status = atoi(arg.c_str());
    }
  }

  // Options sanity check
  if (folder_data.empty() || folder_detector_configuration.empty()) {
    std::string missing_folder = "";

    if (folder_data.empty())
      missing_folder = "data folder";
    else if (folder_detector_configuration.empty() && do_check)
      missing_folder = "detector configuration";

    error_cout << "No folder for " << missing_folder << " specified\n";
    return -1;
  }

  // Set verbosity level
  std::cout << std::fixed << std::setprecision(6);
  logger::ll.verbosityLevel = verbosity;

  // Set device for main thread
  auto [device_set, device_name] = set_device(device_id, 0);
  if (!device_set) {
    return -1;
  }

  // Show call options
  print_call_options(options, device_name);

  // Determine wether to run with async I/O.
  bool enable_async_io = true;
  size_t n_io_reps = number_of_repetitions;
  if ((number_of_slices == 0 || number_of_slices == 1) && number_of_repetitions > 1) {
    // NOTE: Special case to be able to compare throughput with and
    // without async I/O; if repetitions are requested and the number
    // of slices is default (0) or 1, never free the initially filled
    // slice.
    enable_async_io = false;
    number_of_slices = 1;
    n_io_reps = 1;
    warning_cout << "Disabling async I/O to measure throughput without it.\n";
  }
  else if (number_of_slices <= number_of_threads) {
    warning_cout << "Setting number of slices to " << number_of_threads + 1 << "\n";
    number_of_slices = number_of_threads + 1;
    number_of_repetitions = 1;
  }
  else {
    info_cout << "Using " << number_of_slices << " input slices."
              << "\n";
    number_of_repetitions = 1;
  }

  number_of_buffers = number_of_threads + n_mon + 1;

  // Print configured sequence
  print_configured_sequence();

  // Set a sane default for the number of events per input slice
  if (!events_per_slice && number_of_events_requested != 0) {
    events_per_slice = number_of_events_requested;
  }
  else if (!events_per_slice) {
    events_per_slice = 1000;
  }

  // Raw data input folders
  const auto folder_name_velopix_raw = folder_data + folder_rawdata + "VP";
  const auto folder_name_UT_raw = folder_data + folder_rawdata + "UT";
  const auto folder_name_SciFi_raw = folder_data + folder_rawdata + "FTCluster";
  const auto folder_name_Muon_raw = folder_data + folder_rawdata + "Muon";
  const auto folder_name_mdf = folder_data + folder_rawdata + "mdf";

  std::unique_ptr<ConfigurationReader> configuration_reader;

  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader;

  std::unique_ptr<IInputProvider> input_provider {};

  // Number of requested events as an optional
  std::optional<size_t> n_events;
  if (number_of_events_requested != 0) {
    n_events = number_of_events_requested;
  }

  // Create the InputProvider, either MDF or Binary
  // info_cout << with_mpi << ", " << mdf_input[0] << "\n";
  if (!mep_input.empty()) {
    MEPProviderConfig config {false,           // verify MEP checksums
                              10,              // number of read buffers
                              1,               // number of transpose threads
                              mpi_window_size, // MPI sliding window size
                              with_mpi,        // Receive from MPI or read files
                              non_stop,        // Run the application non-stop
                              allen_layout,    // MEPs should be transposed to Allen layout
                              ""};             // Output file
    input_provider = std::make_unique<MEPProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>>(
      number_of_slices, *events_per_slice, n_events, split_input(mep_input), config);
  }
  else if (!mdf_input.empty()) {
    allen_layout = true;
    MDFProviderConfig config {false,                      // verify MDF checksums
                              10,                         // number of read buffers
                              4,                          // number of transpose threads
                              *events_per_slice * 10 + 1, // mximum number event of offsets in read buffer
                              *events_per_slice,          // number of events per read buffer
                              n_io_reps};                 // number of loops over the input files
    input_provider = std::make_unique<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>>(
      number_of_slices, *events_per_slice, n_events, split_input(mdf_input), config);
  }
  else {
    allen_layout = true;
    // The binary input provider expects the folders for the bank types as connections
    std::vector<std::string> connections = {
      folder_name_velopix_raw, folder_name_UT_raw, folder_name_SciFi_raw, folder_name_Muon_raw};
    input_provider = std::make_unique<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>>(
      number_of_slices, *events_per_slice, n_events, std::move(connections), n_io_reps, file_list);
  }

  std::unique_ptr<OutputHandler> output_handler;
  if (!output_file.empty()) {
    try {
      output_handler = std::make_unique<FileWriter>(input_provider.get(), *events_per_slice, output_file);
    } catch (std::runtime_error const& e) {
      error_cout << e.what() << "\n";
      exit(1);
    }
  }

  // Load constant parameters from JSON
  configuration_reader = std::make_unique<ConfigurationReader>(json_constants_configuration_file);

  // Read the Muon catboost model
  muon_catboost_model_reader =
    std::make_unique<CatboostModelReader>(folder_detector_configuration + "muon_catboost_model.json");
  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(
    muon_field_of_interest_params, folder_detector_configuration + "field_of_interest_params.bin");

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

  // create host buffers
  std::unique_ptr<HostBuffersManager> buffer_manager =
    std::make_unique<HostBuffersManager>(number_of_buffers, *events_per_slice, do_check);

  if (print_buffer_status) {
    buffer_manager->printStatus();
  }

  // create rate monitors
  std::unique_ptr<MonitorManager> monitor_manager =
    std::make_unique<MonitorManager>(n_mon, buffer_manager.get(), 30, time(0));

  // Create streams
  StreamWrapper stream_wrapper;
  stream_wrapper.initialize_streams(
    number_of_threads,
    print_memory_usage,
    start_event_offset,
    reserve_mb,
    constants,
    buffer_manager.get(),
    configuration_reader->params());

  auto algo_config = stream_wrapper.get_algorithm_configuration();
  if (print_config) {
    info_cout << "Algorithm configuration\n";
    for (auto kv : algo_config) {
      for (auto kv2 : kv.second) {
        info_cout << " " << kv.first << ":" << kv2.first << " = " << kv2.second << "\n";
      }
    }
  }
  if (write_config) {
    info_cout << "Write full configuration\n";
    ConfigurationReader saveToJson(algo_config);
    saveToJson.save("config.json");
    return 0;
  }

  // Notify used memory if requested verbose mode
  if (logger::ll.verbosityLevel >= logger::verbose) {
    print_gpu_memory_consumption();
  }

  auto checker_invoker = std::make_unique<CheckerInvoker>();

  // Lambda with the execution of a thread-stream pair
  const auto stream_thread = [&](uint thread_id, uint stream_id) {
    std::optional<zmq::socket_t> check_control;
    if (do_check || !output_file.empty()) {
      check_control = zmqSvc().socket(zmq::PAIR);
      zmq::setsockopt(*check_control, zmq::LINGER, 0);
      auto con = ZMQ::connection(thread_id, "check");
      check_control->bind(con.c_str());
    }
    return std::make_tuple(
      std::thread {run_stream,
                   thread_id,
                   stream_id,
                   device_id,
                   &stream_wrapper,
                   input_provider.get(),
                   output_handler ? output_handler.get() : nullptr,
                   checker_invoker.get(),
                   number_of_repetitions,
                   do_check,
                   cpu_offload,
                   allen_layout,
                   folder_name_imported_forward_tracks},
      std::move(check_control));
  };

  // Lambda with the execution of the I/O thread
  const auto io_thread = [&](uint thread_id, uint) {
    return std::make_tuple(
      std::thread {
        run_io, thread_id, input_provider.get(), output_handler ? output_handler.get() : nullptr, buffer_manager.get()},
      std::optional<zmq::socket_t> {});
  };

  // Lambda with the execution of the monitoring thread
  const auto mon_thread = [&](uint thread_id, uint) {
    return std::tuple {std::thread {run_monitoring, thread_id, monitor_manager.get(), thread_id - n_io},
                       std::optional<zmq::socket_t> {}};
  };

  using start_thread = std::function<std::tuple<std::thread, std::optional<zmq::socket_t>>(uint, uint)>;

  // items for 0MQ to poll
  std::vector<zmq::pollitem_t> items;
  items.resize(number_of_threads + n_io + n_mon);

  // Vector of worker threads
  using workers_t = std::vector<std::tuple<std::thread, zmq::socket_t, std::optional<zmq::socket_t>>>;
  workers_t streams;
  streams.reserve(number_of_threads);
  workers_t io_workers;
  io_workers.reserve(n_io);
  workers_t mon_workers;
  mon_workers.reserve(n_mon);

  // Start all workers
  size_t thread_id = 0;
  for (auto& [workers, start, n, type] :
       {std::tuple {&io_workers, start_thread {io_thread}, static_cast<uint>(n_io), std::string("I/O")},
        std::tuple {&mon_workers, start_thread {mon_thread}, static_cast<uint>(n_mon), std::string("Mon")},
        std::tuple {&streams, start_thread {stream_thread}, number_of_threads, std::string("GPU")}}) {
    for (uint i = 0; i < n; ++i) {
      zmq::socket_t control = zmqSvc().socket(zmq::PAIR);
      zmq::setsockopt(control, zmq::LINGER, 0);
      auto con = ZMQ::connection(thread_id);
      control.bind(con.c_str());

      // I don't know why, but this prevents problems. Probably
      // some race condition I haven't noticed.
      std::this_thread::sleep_for(std::chrono::milliseconds {50});

      auto [thread, check_control] = start(thread_id, i);
      workers->emplace_back(std::move(thread), std::move(control), std::move(check_control));
      items[thread_id] = {std::get<1>(workers->back()), 0, zmq::POLLIN, 0};
      debug_cout << "Started " << type << " thread " << std::setw(2) << i + 1 << "/" << std::setw(2) << n << "\n";
      ++thread_id;
    }
  }

  // keep track of what the status of slices is
  // allow slices to be sub-divided if necessary
  // key of map corresponds to the first entry in a sub-slice
  std::vector<std::map<size_t, SliceStatus>> input_slice_status(
    number_of_slices, std::map<size_t, SliceStatus> {{0, SliceStatus::Empty}});
  std::vector<std::map<size_t, size_t>> events_in_slice(number_of_slices, std::map<size_t, size_t> {{0, 0}});
  // processing stream status
  std::bitset<max_stream_threads> stream_ready(false);

  auto count_status = [&input_slice_status](SliceStatus const status) {
    return std::accumulate(
      input_slice_status.begin(), input_slice_status.end(), 0ul, [status](size_t s, auto const stat) {
        return s + (stat.at(0) == status);
      });
  };

  // counters for bookkeeping
  size_t prev_processor = 0;
  long n_events_read = 0;
  long n_events_processed = 0;
  size_t throughput_start = 0;
  std::optional<size_t> throughput_processed;
  size_t slices_processed = 0;
  std::optional<size_t> slice_index;
  std::optional<size_t> buffer_index;
  size_t prev_io = 0;

  size_t n_events_output = 0;
  size_t error_count = 0;

  std::optional<Timer> t;
  double previous_time_measurement = 0;

  zmq::socket_t throughput_socket = zmqSvc().socket(zmq::PUB);
  zmq::setsockopt(throughput_socket, zmq::LINGER, 0);
  std::string con = "ipc:///tmp/allen_throughput_" + std::to_string(device_id);
  throughput_socket.bind(con.c_str());

  // queues of slice/buffer pairs to write out
  // and sub-slices to be resubmitted
  std::queue<std::tuple<size_t, size_t, size_t>> write_queue;
  std::queue<std::tuple<size_t, size_t, size_t>> sub_slice_queue;

  // Lambda to check if any event processors are done processing
  auto check_processors = [&]() {
    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[n_io + n_mon + i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(streams[i]);
        auto msg = zmqSvc().receive<std::string>(socket);
        if (msg == "SPLIT") {
          // This slice required too much memory to process
          // return it to the I/O thread for splitting
          auto slice_index = zmqSvc().receive<size_t>(socket);
          auto first_event = zmqSvc().receive<size_t>(socket);
          auto last_event = zmqSvc().receive<size_t>(socket);
          auto buffer_index = zmqSvc().receive<size_t>(socket);
          stream_ready[i] = true;

          // if we failed to process a single event then pass through
          if (last_event - first_event == 1) {
            // for bookkeeping purposes we'll call this a single event and slice processed
            ++n_events_processed;
            ++slices_processed;
            write_queue.push(std::make_tuple(slice_index, first_event, buffer_index));
            input_slice_status[slice_index][first_event] = SliceStatus::Processed;
            // this also marks the buffer as filled
            buffer_manager->writeSingleEventPassthrough(buffer_index);
          }
          else {
            // Split slice and add sub-slices to the queue for processing
            size_t mid_event = (first_event + last_event) / 2;
            input_slice_status[slice_index][first_event] = SliceStatus::Filled;
            input_slice_status[slice_index][mid_event] = SliceStatus::Filled;
            events_in_slice[slice_index][first_event] = mid_event - first_event;
            events_in_slice[slice_index][mid_event] = last_event - mid_event;
            sub_slice_queue.push({slice_index, first_event, mid_event});
            sub_slice_queue.push({slice_index, mid_event, last_event});

            // Record the split in the monitoring output
            monitor_manager->fillSplit();

            // Release the buffer to be used again
            buffer_manager->returnBufferUnfilled(buffer_index);
          }
        }
        else {
          assert(msg == "PROCESSED");
          auto slice_index = zmqSvc().receive<size_t>(socket);
          auto first_event = zmqSvc().receive<size_t>(socket);
          auto buffer_index = zmqSvc().receive<size_t>(socket);
          n_events_processed += events_in_slice[slice_index][first_event];
          ++slices_processed;
          stream_ready[i] = true;

          if (logger::ll.verbosityLevel >= logger::debug && t) {
            double elapsed_time = t->get_elapsed_time();
            if (elapsed_time - previous_time_measurement > 5) {
              info_cout << "Processed " << std::setw(6) << n_events_processed * number_of_repetitions
                        << " events at a rate of " << n_events_processed * number_of_repetitions / elapsed_time
                        << " events / s\n";
              zmqSvc().send(
                throughput_socket, std::to_string(n_events_processed * number_of_repetitions / elapsed_time));
              previous_time_measurement = elapsed_time;
            }
          }

          // Add the slice and buffer to the queue for output
          write_queue.push(std::make_tuple(slice_index, first_event, buffer_index));

          // Run the checker accumulation here in a blocking fashion;
          // the blocking is ensured by sending a message and
          // immediately waiting for a reply
          auto& check_control = std::get<2>(streams[i]);

          if (do_check && check_control) {
            zmqSvc().send(*check_control, folder_data + "/MC_info");
            auto success = zmqSvc().receive<bool>(*check_control);
            if (!success) {
              warning_cout << "Failed to load MC events.\n";
            }
            else {
              info_cout << "Checked " << n_events_processed << " events\n";
            }
          }
          input_slice_status[slice_index][first_event] = SliceStatus::Processed;
          buffer_manager->returnBufferFilled(buffer_index);
        }
      }
    }
  };

  auto check_monitors = [&] {
    for (size_t i = 0; i < n_mon; ++i) {
      if (items[n_io + i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(mon_workers[i]);
        auto msg = zmqSvc().receive<std::string>(socket);
        assert(msg == "MONITORED");
        auto buffer_index = zmqSvc().receive<size_t>(socket);
        auto monitor_index = zmqSvc().receive<uint>(socket);
        buffer_manager->returnBufferProcessed(buffer_index);
        monitor_manager->freeMonitor(monitor_index);
      }
    }
  };

  // Wait for all processors to be ready
  while ((stream_ready.count() + error_count) < number_of_threads) {
    std::optional<int> n;
    do {
      try {
        n = zmq::poll(&items[n_io + n_mon], number_of_threads, -1);
      } catch (const zmq::error_t& err) {
        if (err.num() == EINTR) continue;
      }
    } while (!n);
    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[n_io + n_mon + i].revents & ZMQ_POLLIN) {
        auto& socket = std::get<1>(streams[i]);
        auto msg = zmqSvc().receive<std::string>(socket);
        assert(msg == "READY");
        auto success = zmqSvc().receive<bool>(socket);
        stream_ready[i] = success;
        debug_cout << "Stream " << std::setw(2) << i << " on device " << device_id
                   << (success ? " ready." : " failed to start.") << "\n";
        error_count += !success;
      }
    }
  }
  if (error_count == 0) {
    info_cout << "Streams ready\n";
  }

  bool io_done = false;

  // Main event loop
  // - Check if input slices are available from the input thread
  // - Distribute new input slices to streams as soon as they arrive
  //   in a round-robin fashion
  // - If any slices failed to process then distribute the split sub-slices
  //   to streams for processing
  // - Check if any streams are done with a slice and mark it to be written out
  // - Send any processed slice+buffer pairs to I/O for writing
  // - Also send host buffers to monitoring thread
  // - Check if the loop should exit
  //
  // NOTE: special behaviour is implemented for testing without asynch
  // I/O and with repetitions. In this case, a single slice is
  // distributed to all streams once.
  while (error_count == 0) {

    // Wait for messages to come in from the I/O, monitoring or stream threads
    std::optional<int> n;
    do {
      try {
        n = zmq::poll(&items[0], number_of_threads + n_io + n_mon, -1);
      } catch (const zmq::error_t& err) {
        if (err.num() == EINTR) continue;
      }
    } while (!n);

    // Check if input_slices are ready
    for (size_t i = 0; i < n_io; ++i) {
      if (items[i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(io_workers[i]);
        auto msg = zmqSvc().receive<std::string>(socket);
        if (msg == "SLICE") {
          slice_index = zmqSvc().receive<size_t>(socket);
          auto n_filled = zmqSvc().receive<size_t>(socket);

          // FIXME: make the warmup time configurable
          if (!t && (number_of_repetitions == 1 || (slices_processed >= 5 * number_of_threads) || !enable_async_io)) {
            info_cout << "Starting timer for throughput measurement\n";
            throughput_start = n_events_processed * number_of_repetitions;
            t = Timer {};
            previous_time_measurement = t->get_elapsed_time();
          }
          input_slice_status[*slice_index][0] = SliceStatus::Filled;
          events_in_slice[*slice_index][0] = n_filled;
          n_events_read += n_filled;
          // If we have a slice we must send it for processing before polling remaining I/O threads
          break;
        }
        else if (msg == "WRITTEN") {
          auto slc_idx = zmqSvc().receive<size_t>(socket);
          auto first_evt = zmqSvc().receive<size_t>(socket);
          auto buf_idx = zmqSvc().receive<size_t>(socket);
          auto success = zmqSvc().receive<bool>(socket);
          n_events_output += zmqSvc().receive<uint>(socket);
          if (!success) {
            error_cout << "Failed to write output events.\n";
          }
          input_slice_status[slc_idx][first_evt] = SliceStatus::Written;

          // check to see if any parts of this slice still need to be written
          bool slice_finished(true);
          for (auto const& [k, v] : input_slice_status[slc_idx]) {
            if (v != SliceStatus::Written) {
              slice_finished = false;
              break;
            }
          }
          if (enable_async_io && slice_finished) {
            input_slice_status[slc_idx].clear();
            input_slice_status[slc_idx][0] = SliceStatus::Empty;
            input_provider->slice_free(slc_idx);
            events_in_slice[slc_idx].clear();
            events_in_slice[slc_idx][0] = 0;
          }

          buffer_manager->returnBufferWritten(buf_idx);
        }
        else if (msg == "DONE") {
          io_done = true;
          info_cout << "Input complete\n";
        }
        else {
          assert(msg == "ERROR");
          error_cout << "I/O provider failed to decode events into slice.\n";
          io_done = true;
          goto loop_error;
        }
      }
    }

    // If there is a slice, send it to the next processor; when async
    // I/O is disabled send the slice(s) to all streams
    if (slice_index) {
      bool first = true;
      while ((enable_async_io && first) || (!enable_async_io && stream_ready.count())) {
        first = false;
        size_t processor_index = prev_processor++;
        if (prev_processor == number_of_threads) {
          prev_processor = 0;
        }
        // send message to processor to process the slice
        if (enable_async_io) {
          input_slice_status[*slice_index][0] = SliceStatus::Processing;
        }
        buffer_index = std::optional<size_t> {buffer_manager->assignBufferToFill()};
        auto& socket = std::get<1>(streams[processor_index]);
        zmqSvc().send(socket, "PROCESS", zmq::SNDMORE);
        zmqSvc().send(socket, *slice_index, zmq::SNDMORE);
        zmqSvc().send(socket, size_t(0), zmq::SNDMORE);
        zmqSvc().send(socket, events_in_slice[*slice_index][0], zmq::SNDMORE);
        zmqSvc().send(socket, *buffer_index);
        stream_ready[processor_index] = false;

        if (logger::ll.verbosityLevel >= logger::debug) {
          debug_cout << "Submitted " << std::setw(5) << events_in_slice[*slice_index][0] << " events in slice "
                     << std::setw(2) << *slice_index << " to stream " << std::setw(2) << processor_index << "\n";
        }
      }
      slice_index.reset();
    }

    // Check if any processors are ready
    check_processors();

    // Check if any sub-slices have been queued for processing
    while (!sub_slice_queue.empty()) {
      auto slice_idx = std::get<0>(sub_slice_queue.front());
      auto first_evt = std::get<1>(sub_slice_queue.front());
      auto last_evt = std::get<2>(sub_slice_queue.front());
      sub_slice_queue.pop();

      size_t processor_index = prev_processor++;
      if (prev_processor == number_of_threads) {
        prev_processor = 0;
      }
      input_slice_status[slice_idx][first_evt] = SliceStatus::Processing;
      buffer_index = std::optional<size_t> {buffer_manager->assignBufferToFill()};
      auto& socket = std::get<1>(streams[processor_index]);
      zmqSvc().send(socket, "PROCESS", zmq::SNDMORE);
      zmqSvc().send(socket, slice_idx, zmq::SNDMORE);
      zmqSvc().send(socket, first_evt, zmq::SNDMORE);
      zmqSvc().send(socket, last_evt, zmq::SNDMORE);
      zmqSvc().send(socket, *buffer_index);
      stream_ready[processor_index] = false;

      if (logger::ll.verbosityLevel >= logger::debug) {
        debug_cout << "Submitted " << std::setw(5) << last_evt - first_evt << " events in slice " << std::setw(2)
                   << slice_idx << " to stream " << std::setw(2) << processor_index << "\n";
      }
    }

    // Send slices and buffers back to I/O threads for writing
    while (write_queue.size()) {
      size_t slc_index = std::get<0>(write_queue.front());
      size_t first_event = std::get<1>(write_queue.front());
      size_t buf_index = std::get<2>(write_queue.front());
      write_queue.pop();

      size_t io_index = prev_io++;
      if (prev_io == n_io) {
        prev_io = 0;
      }

      input_slice_status[slc_index][first_event] = SliceStatus::Writing;

      auto& socket = std::get<1>(io_workers[io_index]);
      zmqSvc().send(socket, "WRITE", zmq::SNDMORE);
      zmqSvc().send(socket, slc_index, zmq::SNDMORE);
      zmqSvc().send(socket, first_event, zmq::SNDMORE);
      zmqSvc().send(socket, buf_index);
    }

    // Send any available HostBuffers to montoring threads
    buffer_index = std::optional<size_t> {buffer_manager->assignBufferToProcess()};
    while ((*buffer_index) != SIZE_MAX) {
      // check if a monitor is available
      std::optional<size_t> monitor_index = monitor_manager->getFreeMonitor();
      if (monitor_index) {
        auto& socket = std::get<1>(mon_workers[*monitor_index]);
        zmqSvc().send(socket, "MONITOR", zmq::SNDMORE);
        zmqSvc().send(socket, *buffer_index);
      }
      else {
        // if no free monitors then mark the buffer as processed
        buffer_manager->returnBufferProcessed(*buffer_index);
      }
      buffer_index = std::optional<size_t> {buffer_manager->assignBufferToProcess()};
    }
    buffer_index.reset();

    // Check for finished monitoring jobs
    check_monitors();

    // Separate if statement to allow stopping in different ways
    // depending on whether async I/O or repetitions are enabled.
    // NOTE: This may be called several times when slices are ready
    bool io_cond = ((!enable_async_io && stream_ready.count() == number_of_threads) || (enable_async_io && io_done));
    if (t && io_cond && number_of_repetitions > 1) {
      if (!throughput_processed) {
        throughput_processed = n_events_processed * number_of_repetitions - throughput_start;
      }
      t->stop();
    }

    // Check if we're done
    if (
      stream_ready.count() == number_of_threads && buffer_manager->buffersEmpty() && io_cond &&
      (!enable_async_io || (enable_async_io && count_status(SliceStatus::Empty) == number_of_slices))) {
      info_cout << "Processing complete\n";
      break;
    }
  }

loop_error:
  // Let processors that are still busy finish
  while ((stream_ready.count() + error_count) < number_of_threads) {

    // Wait for a message
    std::optional<int> n;
    do {
      try {
        n = zmq::poll(&items[n_io + n_mon], number_of_threads, -1);
      } catch (const zmq::error_t& err) {
        if (err.num() == EINTR) continue;
      }
    } while (!n);

    // Check if any processors are ready
    check_processors();
  }

  // Set the number of processed events if it wasn't set before and
  // make sure the timer has stopped
  if (t) {
    if (!throughput_processed) {
      throughput_processed = n_events_processed * number_of_repetitions - throughput_start;
    }
    t->stop();
  }

  // Send stop signal to all threads and join them if they haven't
  // exited yet (as indicated by pred)
  // this now needs to be done for all workers as I/O workers never finish early - could remove pred
  for (auto [workers, pred] : {std::tuple {std::ref(io_workers), true},
                               std::tuple {std::ref(mon_workers), true},
                               std::tuple {std::ref(streams), true}}) {
    for (auto& worker : workers.get()) {
      if (pred) {
        zmqSvc().send(std::get<1>(worker), "DONE");
      }
      std::get<0>(worker).join();
    }
  }

  if (print_buffer_status) {
    buffer_manager->printStatus();
  }
  monitor_manager->saveHistograms("monitoringHists.root");

  // Print checker reports
  if (do_check) {
    checker_invoker->report(n_events_processed);
    checker_invoker.reset();
  }

  // Print throughput measurement result
  if (t && throughput_processed) {
    info_cout << (*throughput_processed / t->get()) << " events/s\n"
              << "Ran test for " << t->get() << " seconds\n";
  }
  else {
    warning_cout << "Timer wasn't started."
                 << "\n";
  }

  if (!output_file.empty()) {
    info_cout << "Wrote " << n_events_output << "/" << n_events_processed << " events to " << output_file << "\n";
  }

  // Reset device
  cudaCheck(cudaDeviceReset());

  return 0;
}
