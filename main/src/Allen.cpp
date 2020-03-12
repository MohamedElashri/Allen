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

#include <zmq/zmq.hpp>
#include <ZeroMQ/IZeroMQSvc.h>
#include <zmq_compat.h>

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
#include "ZMQOutputSender.h"
#include "AllenThreads.h"
#include "Allen.h"
#include "RegisterConsumers.h"
#include "CpuID.h"
#include <tuple>

namespace {
  enum class SliceStatus { Empty, Filling, Filled, Processing, Processed, Writing, Written };
  using namespace zmq;
} // namespace

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
=======
 * @brief      Main entry point
 *
 * @param      {key : value} command-line arguments as std::strings
 * @param      IUpdater instance
 *
 * @return     int
 */
extern "C" int allen(
  std::map<std::string, std::string> options,
  Allen::NonEventData::IUpdater* updater,
  IZeroMQSvc* zmqSvc,
  std::string_view control_connection)
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
  std::map<std::string, int> receivers = {{"mem", 1}};
  int mpi_window_size = 4;
  // Input file options
  std::string mdf_input;
  std::string mep_input;
  bool mep_layout = true;
  std::string output_file;
  int device_id = 0;
  int cpu_offload = 1;
  std::string file_list;
  bool print_config = 0;
  bool print_status = 0;

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
      mep_layout = !atoi(arg.c_str());
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
      if (arg.find(":") != std::string::npos) {
        // Get by PCI bus ID
        bool s = false;
        std::tie(s, device_id) = get_device_id(arg);
        if (!s) exit(1);
      }
      else {
        device_id = atoi(arg.c_str());
      }
    }
    else if (flag_in({"with-mpi"})) {
      with_mpi = true;
      bool parsed = false;
      std::tie(parsed, receivers) = parse_receivers(arg);
      if (!parsed) {
        error_cout << "Failed to parse argument to with-mpi\n";
        exit(1);
      }
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
    else if (flag_in({"print-status"})) {
      print_status = atoi(arg.c_str());
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

  // Generate CPU ID object
  cpu_id::reset_cpuid();

  // Set verbosity level
  std::cout << std::fixed << std::setprecision(6);
  logger::setVerbosity(verbosity);

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
    debug_cout << "Disabling async I/O to measure throughput without it.\n";
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
  const auto folder_name_ODIN_raw = folder_data + folder_rawdata + "ODIN";
  const auto folder_name_mdf = folder_data + folder_rawdata + "mdf";

  std::unique_ptr<ConfigurationReader> configuration_reader;

  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader;

  std::unique_ptr<IInputProvider> input_provider {};

  // Number of requested events as an optional
  std::optional<size_t> n_events;
  if (number_of_events_requested != 0) {
    n_events = number_of_events_requested;
  }

  // items for 0MQ to poll
  std::vector<zmq::pollitem_t> items;
  items.resize(number_of_threads + n_io + n_mon + !control_connection.empty());

  std::optional<zmq::socket_t> allen_control;
  size_t control_index = 0;
  if (!control_connection.empty()) {
    allen_control = zmqSvc->socket(zmq::PAIR);
    zmq::setsockopt(*allen_control, zmq::LINGER, -1);
    allen_control->connect(control_connection.data());
    control_index = items.size() - 1;
    items[control_index] = {*allen_control, 0, zmq::POLLIN, 0};
  }

  // Create the InputProvider, either MDF or Binary
  // info_cout << with_mpi << ", " << mdf_input[0] << "\n";
  if (!mep_input.empty() || with_mpi) {
    MEPProviderConfig config {false,                // verify MEP checksums
                              10,                   // number of read buffers
                              mep_layout ? 1u : 4u, // number of transpose threads
                              mpi_window_size,      // MPI sliding window size
                              with_mpi,             // Receive from MPI or read files
                              non_stop,             // Run the application non-stop
                              !mep_layout,          // MEPs should be transposed to Allen layout
                              receivers};           // Map of receiver to MPI rank to receive from
    input_provider =
      std::make_unique<MEPProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
        number_of_slices, *events_per_slice, n_events, split_string(mep_input, ","), config);
  }
  else if (!mdf_input.empty()) {
    mep_layout = false;
    MDFProviderConfig config {false,                      // verify MDF checksums
                              10,                         // number of read buffers
                              4,                          // number of transpose threads
                              *events_per_slice * 10 + 1, // mximum number event of offsets in read buffer
                              *events_per_slice,          // number of events per read buffer
                              n_io_reps};                 // number of loops over the input files
    input_provider =
      std::make_unique<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
        number_of_slices, *events_per_slice, n_events, split_string(mdf_input, ","), config);
  }
  else {
    mep_layout = false;
    // The binary input provider expects the folders for the bank types as connections
    std::vector<std::string> connections = {
      folder_name_velopix_raw, folder_name_UT_raw, folder_name_SciFi_raw, folder_name_Muon_raw, folder_name_ODIN_raw};
    input_provider =
      std::make_unique<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
        number_of_slices, *events_per_slice, n_events, std::move(connections), n_io_reps, file_list);
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

  // Create streams
  StreamWrapper stream_wrapper;
  stream_wrapper.initialize_streams(
    number_of_threads, print_memory_usage, start_event_offset, reserve_mb, constants, configuration_reader->params());

  // create host buffers
  std::unique_ptr<HostBuffersManager> buffer_manager = std::make_unique<HostBuffersManager>(
    number_of_buffers,
    *events_per_slice,
    do_check,
    stream_wrapper.number_of_hlt1_lines,
    stream_wrapper.errorevent_line);

  stream_wrapper.initialize_streams_host_buffers_manager(buffer_manager.get());

  if (print_status) {
    buffer_manager->printStatus();
  }

  // create rate monitors
  std::unique_ptr<MonitorManager> monitor_manager =
    std::make_unique<MonitorManager>(n_mon, buffer_manager.get(), stream_wrapper.number_of_hlt1_lines, 30, time(0));

  std::unique_ptr<OutputHandler> output_handler;
  if (!output_file.empty()) {
    try {
      if (output_file.substr(0, 6) == "tcp://") {
        output_handler = std::make_unique<ZMQOutputSender>(
          input_provider.get(), output_file, *events_per_slice, zmqSvc, stream_wrapper.number_of_hlt1_lines);
      }
      else {
        output_handler = std::make_unique<FileWriter>(
          input_provider.get(), output_file, *events_per_slice, stream_wrapper.number_of_hlt1_lines);
      }
    } catch (std::runtime_error const& e) {
      error_cout << e.what() << "\n";
      exit(1);
    }
  }

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
  if (logger::verbosity() >= logger::verbose) {
    print_gpu_memory_consumption();
  }

  auto checker_invoker = std::make_unique<CheckerInvoker>();

  // Lambda with the execution of a thread-stream pair
  const auto stream_thread = [&](uint thread_id, uint stream_id) {
    std::optional<zmq::socket_t> check_control;
    if (do_check || !output_file.empty()) {
      check_control = zmqSvc->socket(zmq::PAIR);
      zmq::setsockopt(*check_control, zmq::LINGER, 0);
      auto con = connection(thread_id, "check");
      check_control->bind(con.c_str());
    }
    return std::make_tuple(
      std::thread {run_stream,
                   thread_id,
                   stream_id,
                   device_id,
                   &stream_wrapper,
                   input_provider.get(),
                   zmqSvc,
                   checker_invoker.get(),
                   number_of_repetitions,
                   do_check,
                   cpu_offload,
                   mep_layout,
                   folder_name_imported_forward_tracks},
      std::move(check_control));
  };

  // Lambda with the execution of the input thread that polls the
  // input provider for slices.
  const auto slice_thread = [&](uint thread_id, uint) {
    return std::make_tuple(
      std::thread {run_slices, thread_id, zmqSvc, input_provider.get()}, std::optional<zmq::socket_t> {});
  };

  // Lambda with the execution of the output thread
  const auto output_thread = [&](uint thread_id, uint) {
    return std::make_tuple(
      std::thread {
        run_output, thread_id, zmqSvc, output_handler ? output_handler.get() : nullptr, buffer_manager.get()},
      std::optional<zmq::socket_t> {});
  };

  // Lambda with the execution of the monitoring thread
  const auto mon_thread = [&](uint thread_id, uint mon_id) {
    return std::tuple {std::thread {run_monitoring, thread_id, zmqSvc, monitor_manager.get(), mon_id},
                       std::optional<zmq::socket_t> {}};
  };

  using start_thread = std::function<std::tuple<std::thread, std::optional<zmq::socket_t>>(uint, uint)>;

  // Vector of worker threads
  using workers_t = std::vector<std::tuple<std::thread, zmq::socket_t, std::optional<zmq::socket_t>>>;
  workers_t streams;
  streams.reserve(number_of_threads);
  workers_t io_workers;
  io_workers.reserve(n_io);
  workers_t mon_workers;
  mon_workers.reserve(n_mon);

  auto socket_ready = [zmqSvc](zmq::socket_t& socket) -> std::optional<size_t> {
    zmq::pollitem_t ready_items[] = {{socket, 0, zmq::POLLIN, 0}};
    int tries = 5;
    std::optional<size_t> thread_id;
    while (tries > 0) {
      zmqSvc->send(socket, "STATUS");
      zmqSvc->poll(&ready_items[0], 1, 200);
      if (ready_items[0].revents & zmq::POLLIN) {
        auto msg = zmqSvc->receive<std::string>(socket);
        assert(msg == "READY");
        thread_id = zmqSvc->receive<size_t>(socket);
        break;
      }
      --tries;
    }
    return thread_id;
  };

  auto thread_ready = [&socket_ready](workers_t::value_type& worker) {
    auto success = socket_ready(std::get<1>(worker));
    auto& extra_socket = std::get<2>(worker);
    if (success && extra_socket) {
      return socket_ready(*extra_socket);
    }
    return success;
  };

  // processing stream status
  std::bitset<max_stream_threads> stream_ready(false);
  size_t error_count = 0;

  auto handle_default_ready = [](size_t) {};
  auto handle_stream_ready = [&stream_ready](size_t i) { stream_ready[i] = true; };
  using handle_ready = std::function<void(size_t)>;

  // Start all workers and check if the threads are ready
  size_t thread_id = 0;
  for (auto& [workers, start, n, type, handle] : {std::tuple {&streams,
                                                              start_thread {stream_thread},
                                                              number_of_threads,
                                                              std::string("GPU"),
                                                              handle_ready {handle_stream_ready}},
                                                  std::tuple {&io_workers,
                                                              start_thread {slice_thread},
                                                              static_cast<uint>(n_input),
                                                              std::string("Slices"),
                                                              handle_ready {handle_default_ready}},
                                                  std::tuple {&io_workers,
                                                              start_thread {output_thread},
                                                              static_cast<uint>(n_write),
                                                              std::string("Output"),
                                                              handle_ready {handle_default_ready}},
                                                  std::tuple {&mon_workers,
                                                              start_thread {mon_thread},
                                                              static_cast<uint>(n_mon),
                                                              std::string("Mon"),
                                                              handle_ready {handle_default_ready}}}) {
    size_t n_ready = 0;
    for (uint i = 0; i < n; ++i) {
      zmq::socket_t control = zmqSvc->socket(zmq::PAIR);
      zmq::setsockopt(control, zmq::LINGER, 0);
      auto con = connection(thread_id);
      control.bind(con.c_str());
      // I don't know why, but this prevents problems. Probably
      // some race condition I haven't noticed.
      std::this_thread::sleep_for(std::chrono::milliseconds {50});

      auto [thread, check_control] = start(thread_id, i);
      workers->emplace_back(std::move(thread), std::move(control), std::move(check_control));
      items[thread_id] = {std::get<1>(workers->back()), 0, zmq::POLLIN, 0};

      // Check if thread is ready
      auto ready = thread_ready(workers->back());
      if (ready) handle(i);
      debug_cout << type << " thread " << std::setw(2) << std::setw(2) << i + 1 << "/" << std::setw(2) << n
                 << (ready ? " ready." : " failed to start.") << "\n";
      n_ready += ready.has_value();
      error_count += !ready;
      ++thread_id;
    }
    if (n_ready == n && print_status) {
      info_cout << "Started " << type << " threads\n";
    }
  }

  // keep track of what the status of slices is
  // allow slices to be sub-divided if necessary
  // key of map corresponds to the first entry in a sub-slice
  std::vector<std::map<size_t, SliceStatus>> input_slice_status(
    number_of_slices, std::map<size_t, SliceStatus> {{0, SliceStatus::Empty}});
  std::vector<std::map<size_t, size_t>> events_in_slice(number_of_slices, std::map<size_t, size_t> {{0, 0}});

  auto count_status = [&input_slice_status](SliceStatus const status) {
    return std::accumulate(
      input_slice_status.begin(), input_slice_status.end(), 0ul, [status](size_t s, auto const stat) {
        return s + (stat.at(0) == status);
      });
  };

  // counters for bookkeeping
  size_t prev_processor = 0;
  long n_events_read = 0;
  long n_events_processed = 0, n_events_measured = 0;
  size_t throughput_start = 0;
  std::optional<size_t> throughput_processed;
  size_t slices_processed = 0;
  std::optional<size_t> slice_index;
  std::optional<size_t> buffer_index;

  size_t n_events_output = 0, n_output_measured = 0;

  // Create optional timer
  std::optional<Timer> t;
  double previous_time_measurement = 0;

  std::optional<zmq::socket_t> throughput_socket;
  try {
    throughput_socket = zmqSvc->socket(zmq::PUB);
    zmq::setsockopt(*throughput_socket, zmq::LINGER, 0);
    std::string con = "ipc:///tmp/allen_throughput_" + std::to_string(device_id);
    throughput_socket->bind(con.c_str());
  } catch (zmq::error_t const& e) {
    debug_cout << "Failed to create or bind throughput socket " << e.what() << "\n";
  }

  // queues of slice/buffer pairs to write out
  // and sub-slices to be resubmitted
  std::queue<std::tuple<size_t, size_t, size_t>> write_queue;
  std::queue<std::tuple<size_t, size_t, size_t>> sub_slice_queue;

  // Lambda to check if any event processors are done processing
  auto check_processors = [&]() {
    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(streams[i]);
        auto msg = zmqSvc->receive<std::string>(socket);
        if (msg == "SPLIT") {
          // This slice required too much memory to process
          // return it to the I/O thread for splitting
          auto slice_index = zmqSvc->receive<size_t>(socket);
          auto first_event = zmqSvc->receive<size_t>(socket);
          auto last_event = zmqSvc->receive<size_t>(socket);
          auto buffer_index = zmqSvc->receive<size_t>(socket);
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
          auto slice_index = zmqSvc->receive<size_t>(socket);
          auto first_event = zmqSvc->receive<size_t>(socket);
          auto buffer_index = zmqSvc->receive<size_t>(socket);
          n_events_processed += events_in_slice[slice_index][first_event];
          n_events_measured += events_in_slice[slice_index][first_event];
          ++slices_processed;
          stream_ready[i] = true;

          if (throughput_socket && t) {
            double elapsed_time = t->get_elapsed_time();
            auto dt = elapsed_time - previous_time_measurement;
            if (dt > 5.) {
              if (print_status) {
                char buf[200];
                std::snprintf(
                  buf,
                  sizeof(buf),
                  "Processed %7li events at a rate of %8.2f events/s\n",
                  n_events_measured * number_of_repetitions,
                  n_events_measured * number_of_repetitions / dt);
                info_cout << buf;
                std::snprintf(
                  buf,
                  sizeof(buf),
                  "Output    %7lu events at a rate of %8.2f events/s\n",
                  n_output_measured,
                  n_output_measured / dt);
                info_cout << buf;
              }
              zmqSvc->send(*throughput_socket, std::to_string(n_events_measured * number_of_repetitions / dt));
              previous_time_measurement = elapsed_time;
              n_events_measured = 0;
              n_output_measured = 0;
            }
          }

          // Add the slice and buffer to the queue for output
          write_queue.push(std::make_tuple(slice_index, first_event, buffer_index));

          // Run the checker accumulation here in a blocking fashion;
          // the blocking is ensured by sending a message and
          // immediately waiting for a reply
          auto& check_control = std::get<2>(streams[i]);

          if (do_check && check_control) {
            zmqSvc->send(*check_control, folder_data + "/MC_info");
            auto success = zmqSvc->receive<bool>(*check_control);
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
      if (items[number_of_threads + n_io + i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(mon_workers[i]);
        auto msg = zmqSvc->receive<std::string>(socket);
        assert(msg == "MONITORED");
        auto buffer_index = zmqSvc->receive<size_t>(socket);
        auto monitor_index = zmqSvc->receive<uint>(socket);
        buffer_manager->returnBufferProcessed(buffer_index);
        monitor_manager->freeMonitor(monitor_index);
      }
    }
  };

  if (!allen_control && !error_count) {
    input_provider->start();
    for (size_t i = 0; i < n_io; ++i) {
      auto& socket = std::get<1>(io_workers[i]);
      zmqSvc->send(socket, "START");
    }
  }
  else if (allen_control) {
    zmqSvc->send(*allen_control, (error_count ? "ERROR" : "READY"));
  }

  bool io_done = false;
  // stop triggered, input done, output done
  auto stop = false, exit_loop = false;

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
    zmqSvc->poll(&items[0], items.size(), -1);

    // Check if input slices are ready or events have been written
    for (size_t i = 0; i < n_io; ++i) {
      if (items[number_of_threads + i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(io_workers[i]);
        auto msg = zmqSvc->receive<std::string>(socket);
        if (msg == "SLICE") {
          slice_index = zmqSvc->receive<size_t>(socket);
          auto n_filled = zmqSvc->receive<size_t>(socket);
          // FIXME: make the warmup time configurable
          if (!t && (number_of_repetitions == 1 || slices_processed >= 5 * number_of_threads || !enable_async_io)) {
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
          auto slc_idx = zmqSvc->receive<size_t>(socket);
          auto first_evt = zmqSvc->receive<size_t>(socket);
          auto buf_idx = zmqSvc->receive<size_t>(socket);
          auto success = zmqSvc->receive<bool>(socket);
          auto n_written = zmqSvc->receive<size_t>(socket);
          n_events_output += n_written;
          n_output_measured += n_written;
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
          if (((allen_control && stop) || !allen_control) && !io_done) {
            io_done = true;
            info_cout << "Input complete\n";
          }
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
        zmqSvc->send(socket, "PROCESS", send_flags::sndmore);
        zmqSvc->send(socket, *slice_index, send_flags::sndmore);
        zmqSvc->send(socket, size_t(0), send_flags::sndmore);
        zmqSvc->send(socket, events_in_slice[*slice_index][0], send_flags::sndmore);
        zmqSvc->send(socket, *buffer_index);
        stream_ready[processor_index] = false;

        if (logger::verbosity() >= logger::debug) {
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
      auto [slice_idx, first_evt, last_evt] = sub_slice_queue.front();
      sub_slice_queue.pop();

      size_t processor_index = prev_processor++;
      if (prev_processor == number_of_threads) {
        prev_processor = 0;
      }
      input_slice_status[slice_idx][first_evt] = SliceStatus::Processing;
      buffer_index = std::optional<size_t> {buffer_manager->assignBufferToFill()};
      auto& socket = std::get<1>(streams[processor_index]);
      zmqSvc->send(socket, "PROCESS", send_flags::sndmore);
      zmqSvc->send(socket, slice_idx, send_flags::sndmore);
      zmqSvc->send(socket, first_evt, send_flags::sndmore);
      zmqSvc->send(socket, last_evt, send_flags::sndmore);
      zmqSvc->send(socket, *buffer_index);
      stream_ready[processor_index] = false;

      if (logger::verbosity() >= logger::debug) {
        debug_cout << "Submitted " << std::setw(5) << last_evt - first_evt << " events in slice " << std::setw(2)
                   << slice_idx << " to stream " << std::setw(2) << processor_index << "\n";
      }
    }

    // Send slices and buffers back to I/O threads for writing
    while (write_queue.size()) {
      auto [slc_index, first_event, buf_index] = write_queue.front();
      write_queue.pop();

      input_slice_status[slc_index][first_event] = SliceStatus::Writing;

      auto& socket = std::get<1>(io_workers[n_input]);
      zmqSvc->send(socket, "WRITE", send_flags::sndmore);
      zmqSvc->send(socket, slc_index, send_flags::sndmore);
      zmqSvc->send(socket, first_event, send_flags::sndmore);
      zmqSvc->send(socket, buf_index);
    }

    // Send any available HostBuffers to montoring threads
    buffer_index = std::optional<size_t> {buffer_manager->assignBufferToProcess()};
    while ((*buffer_index) != SIZE_MAX) {
      // check if a monitor is available
      std::optional<size_t> monitor_index = monitor_manager->getFreeMonitor();
      if (monitor_index) {
        auto& socket = std::get<1>(mon_workers[*monitor_index]);
        zmqSvc->send(socket, "MONITOR", send_flags::sndmore);
        zmqSvc->send(socket, *buffer_index);
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

    if (allen_control && items[control_index].revents & zmq::POLLIN) {
      auto msg = zmqSvc->receive<std::string>(*allen_control);
      if (msg == "STOP") {
        stop = true;
        input_provider->stop();
      }
      else if (msg == "START") {
        // Start the input provider
        io_done = false;
        input_provider->start();

        // Send slice thread start to start asking for slices
        for (size_t i = 0; i < n_io; ++i) {
          auto& socket = std::get<1>(io_workers[i]);
          zmqSvc->send(socket, "START");
        }

        // Respond to steering
        zmqSvc->send(*allen_control, "RUNNING");
      }
      else if (msg == "RESET") {
        io_done = true;
        exit_loop = true;
      }
    }

    // Separate if statement to allow stop in different ways
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
      if (allen_control && stop) {
        stop = false;
        zmqSvc->send(*allen_control, "READY");
      }
      else if (!allen_control || (allen_control && exit_loop)) {
        break;
      }
    }
  }

loop_error:
  // Let processors that are still busy finish
  while ((stream_ready.count() + error_count) < number_of_threads) {

    // Wait for a message
    zmqSvc->poll(&items[0], number_of_threads, -1);

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
  for (auto workers : {std::ref(io_workers), std::ref(mon_workers), std::ref(streams)}) {
    for (auto& worker : workers.get()) {
      zmqSvc->send(std::get<1>(worker), "DONE");
      std::get<0>(worker).join();
    }
  }

  if (print_status) {
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
  else if (!t) {
    warning_cout << "Timer wasn't started."
                 << "\n";
  }
  else {
    warning_cout << "No event count."
                 << "\n";
  }

  if (!output_file.empty()) {
    info_cout << "Wrote " << n_events_output << "/" << n_events_processed << " events to " << output_file << "\n";
  }

  // Reset device
  cudaCheck(cudaDeviceReset());

  if (allen_control) {
    zmqSvc->send(*allen_control, "NOT_READY");
  }

  return 0;
}
