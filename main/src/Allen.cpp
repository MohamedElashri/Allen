/***************************************************************************** \
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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
#include <stdio.h>

#include <zmq/zmq.hpp>
#include <ZeroMQ/IZeroMQSvc.h>
#include <zmq_compat.h>

#include "BackendCommon.h"
#include "RuntimeOptions.h"
#include "ProgramOptions.h"
#include "Logger.h"
#include "Tools.h"
#include "InputTools.h"
#include "InputReader.h"
#include "Timer.h"
#include "Constants.cuh"
#include "MuonDefinitions.cuh"
#include "Consumers.h"
#include "CheckerInvoker.h"
#include "HostBuffersManager.cuh"
#include "MonitorManager.h"
#include "FileWriter.h"
#include "ZMQOutputSender.h"
#include "Stream.h"
#include "AllenThreads.h"
#include "Allen.h"
#include "RegisterConsumers.h"
#include "CPUID.h"
#include <tuple>
#include "Provider.h"
#include "ROOTService.h"

namespace {
  enum class SliceStatus { Empty, Filling, Filled, Processing, Processed, Writing, Written };
  using namespace zmq;
} // namespace

/**
=======
 * @brief      Main entry point
 *
 * @param      {key : value} command-line arguments as std::strings
 * @param      IUpdater instance
 * @param      IZeroMQSvc instance
 * @param      name of control connection
 *
 * @return     int
 */
int allen(
  std::map<std::string, std::string> options,
  Allen::NonEventData::IUpdater* updater,
  std::shared_ptr<IInputProvider> input_provider,
  OutputHandler* output_handler,
  IZeroMQSvc* zmqSvc,
  std::string_view control_connection)
{
  std::string folder_parameters = "";

  unsigned n_slices = 0;
  unsigned number_of_buffers = 0;
  unsigned number_of_threads = 1;
  unsigned n_repetitions = 1;
  unsigned verbosity = 3;
  bool print_memory_usage = false;
  bool write_config = false;
  size_t reserve_mb = 1000;
  size_t reserve_host_mb = 200;

  // Input file options
  int device_id = 0;
  int cpu_offload = 1;
  std::string file_list;
  bool print_config = 0;
  bool print_status = 0;
  uint inject_mem_fail = 0;
  uint mon_save_period = 0;
  std::string mon_filename;
  bool disable_run_changes = 0;

  std::string flag, arg;

  // Use flags to populate variables in the program
  for (auto const& entry : options) {
    std::tie(flag, arg) = entry;
    if (flag_in(flag, {"params"})) {
      folder_parameters = arg;
    }
    else if (flag_in(flag, {"write-configuration"})) {
      write_config = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"s", "number-of-slices"})) {
      n_slices = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"t", "threads"})) {
      number_of_threads = atoi(arg.c_str());
      if (number_of_threads > max_stream_threads) {
        error_cout << "Error: more than maximum number of threads (" << max_stream_threads << ") requested\n";
        return -1;
      }
    }
    else if (flag_in(flag, {"r", "repetitions"})) {
      n_repetitions = atoi(arg.c_str());
      if (n_repetitions == 0) {
        error_cout << "Error: number of repetitions must be at least 1\n";
        return -1;
      }
    }
    else if (flag_in(flag, {"m", "memory"})) {
      reserve_mb = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"host-memory"})) {
      reserve_host_mb = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"v", "verbosity"})) {
      verbosity = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"p", "print-memory"})) {
      print_memory_usage = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"cpu-offload"})) {
      cpu_offload = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"device"})) {
      if (arg.find(":") != std::string::npos) {
        // Get by PCI bus ID
        bool s = false;
        std::tie(s, device_id) = Allen::get_device_id(arg);
        if (!s) exit(1);
      }
      else {
        device_id = atoi(arg.c_str());
      }
    }
    else if (flag_in(flag, {"file-list"})) {
      file_list = arg;
    }
    else if (flag_in(flag, {"print-config"})) {
      print_config = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"print-status"})) {
      print_status = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"inject-mem-fail"})) {
      inject_mem_fail = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"monitoring-filename"})) {
      mon_filename = arg;
    }
    else if (flag_in(flag, {"monitoring-save-period"})) {
      mon_save_period = atoi(arg.c_str());
    }
    else if (flag_in(flag, {"disable-run-changes"})) {
      disable_run_changes = atoi(arg.c_str());
    }
  }

  // Set verbosity level
  std::cout << std::fixed << std::setprecision(6);
  logger::setVerbosity(verbosity);

  auto io_conf = Allen::io_configuration(n_slices, n_repetitions, number_of_threads);
  auto const [json_configuration_file, run_from_json] = Allen::sequence_conf(options);

  // Set device for main thread
  auto [device_set, device_name, device_memory_alignment] = Allen::set_device(device_id, 0);
  if (!device_set) {
    return -1;
  }

  // Show call options
  print_call_options(options, device_name);

  number_of_buffers = number_of_threads + n_mon + 1;

  std::unique_ptr<ConfigurationReader> configuration_reader;

  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader;
  std::unique_ptr<TwoTrackMVAModelReader> two_track_mva_model_reader;

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
  //
  // Load constant parameters from JSON
  configuration_reader = std::make_unique<ConfigurationReader>(json_configuration_file);

  // Get the path to the parameter folder: different for standalone and Gaudi build
  // Only in case of standalone gitlab CI pipepline the parameters folder path is passed as runtime argument
  if (folder_parameters == "") {
#ifdef ALLEN_STANDALONE
#define xstr(s) str(s)
#define str(s) #s
    folder_parameters = xstr(PARAMFILESROOTPATH);
    info_cout << "Local copy of param files is used: " << folder_parameters << std::endl;
#endif
  }
  if (folder_parameters == "") {
    error_cout << "Parameters file path is empty!" << std::endl;
  }
  folder_parameters += "/data/";

  // Read the Muon catboost model
  muon_catboost_model_reader =
    std::make_unique<CatboostModelReader>(folder_parameters + "allen_muon_catboost_model.json");
  // Two Track Model
  two_track_mva_model_reader =
    std::make_unique<TwoTrackMVAModelReader>(folder_parameters + "allen_two_track_mva_model.json");

  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(
    muon_field_of_interest_params, folder_parameters + "allen_muon_field_of_interest_params.bin");

  // Initialize detector constants on GPU
  Constants constants;

  constants.reserve_and_initialize(muon_field_of_interest_params, folder_parameters);
  constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader->n_trees(),
    muon_catboost_model_reader->tree_depths(),
    muon_catboost_model_reader->tree_offsets(),
    muon_catboost_model_reader->leaf_values(),
    muon_catboost_model_reader->leaf_offsets(),
    muon_catboost_model_reader->split_border(),
    muon_catboost_model_reader->split_feature());

  constants.initialize_two_track_mva_model_constants(
    two_track_mva_model_reader->weights(),
    two_track_mva_model_reader->biases(),
    two_track_mva_model_reader->layer_sizes(),
    two_track_mva_model_reader->n_layers(),
    two_track_mva_model_reader->monotone_constraints(),
    two_track_mva_model_reader->nominal_cut(),
    two_track_mva_model_reader->lambda());

  // Register all consumers
  register_consumers(updater, constants);

  auto const& configuration = configuration_reader->params();

  // Find the number of lines from gather_selections
  size_t n_lines = 0;
  unsigned error_line = 0;
  auto conf_it = configuration.find("gather_selections");
  if (conf_it != configuration.end()) {
    auto prop_it = conf_it->second.find("names_of_active_lines");
    if (prop_it != conf_it->second.end()) {
      auto line_names = split_string(prop_it->second, ",");
      n_lines = line_names.size();
      // find the name of the error event line
      auto it = std::find_if(line_names.begin(), line_names.end(), [](std::string_view line_name) {
        return line_name.find("ErrorEvent") != std::string::npos;
      });
      error_line = std::distance(line_names.begin(), it);
    }
  }

  // create host buffers
  std::unique_ptr<HostBuffersManager> buffers_manager =
    std::make_unique<HostBuffersManager>(number_of_buffers, input_provider->events_per_slice(), n_lines, error_line);

  if (print_status) {
    buffers_manager->printStatus();
  }

  auto root_service = std::make_unique<ROOTService>(mon_filename);

  // create rate monitors
  std::unique_ptr<MonitorManager> monitor_manager =
    std::make_unique<MonitorManager>(n_mon, buffers_manager.get(), root_service.get(), 30, time(0));

  // Notify used memory if requested verbose mode
  if (logger::verbosity() >= logger::verbose) {
    Allen::print_device_memory_consumption();
  }

  // Create all the streams
  std::vector<std::unique_ptr<Stream>> streams;
  for (unsigned t = 0; t < number_of_threads; ++t) {
    auto& sequence = streams.emplace_back(new Stream {configuration_reader->configured_sequence(),
                                                      print_memory_usage,
                                                      reserve_mb,
                                                      reserve_host_mb,
                                                      device_memory_alignment,
                                                      constants,
                                                      buffers_manager.get()});
    sequence->configure_algorithms(configuration);
  }

  if (run_from_json) {
    // Print configured sequence
    streams.front()->print_configured_sequence();
  }

  // Interrogate stream configured sequence for validation algorithms
  const auto sequence_contains_validation_algorithms = streams.front()->contains_validation_algorithms();

  // TODO: Test this
  if (print_config || write_config) {
    auto algorithm_configuration = streams.front()->get_algorithm_configuration();
    if (print_config) {
      info_cout << "Algorithm configuration\n";
      for (auto kv : algorithm_configuration) {
        for (auto kv2 : kv.second) {
          info_cout << " " << kv.first << ":" << kv2.first << " = " << kv2.second << "\n";
        }
      }
    }
    if (write_config) {
      info_cout << "Write full configuration\n";
      // Add sequence - this makes the generated json fully operational
      algorithm_configuration["sequence"] = configuration_reader->get_sequence();
      ConfigurationReader saveToJson(algorithm_configuration);
      saveToJson.save("config.json");
      return 0;
    }
  }

  auto checker_invoker = std::make_unique<CheckerInvoker>();

  // Lambda with the execution of a thread-stream pair
  const auto stream_thread = [&](unsigned thread_id, unsigned stream_id) {
    return std::thread {run_stream,
                        thread_id,
                        stream_id,
                        device_id,
                        streams[stream_id].get(),
                        input_provider,
                        zmqSvc,
                        checker_invoker.get(),
                        root_service.get(),
                        io_conf.number_of_repetitions,
                        cpu_offload,
                        input_provider->layout() == IInputProvider::Layout::MEP,
                        inject_mem_fail};
  };

  // Lambda with the execution of the input thread that polls the
  // input provider for slices.
  const auto slice_thread = [&](unsigned thread_id, unsigned) {
    return std::thread {run_slices, thread_id, zmqSvc, input_provider.get()};
  };

  // Lambda with the execution of the output thread
  const auto output_thread = [&](unsigned thread_id, unsigned) {
    return std::thread {run_output, thread_id, zmqSvc, output_handler, buffers_manager.get()};
  };

  // Lambda with the execution of the monitoring thread
  const auto mon_thread = [&](unsigned thread_id, unsigned mon_id) {
    return std::thread {run_monitoring, thread_id, zmqSvc, monitor_manager.get(), mon_id};
  };

  using start_thread = std::function<std::thread(unsigned, unsigned)>;

  // Vector of worker threads
  using workers_t = std::vector<std::tuple<std::thread, zmq::socket_t>>;
  workers_t stream_threads;
  stream_threads.reserve(number_of_threads);
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

  // processing stream status
  std::bitset<max_stream_threads> stream_ready(false);
  size_t error_count = 0;

  auto handle_default_ready = [](size_t) {};
  auto handle_stream_ready = [&stream_ready](size_t i) { stream_ready[i] = true; };
  using handle_ready = std::function<void(size_t)>;

  // Start all workers and check if the threads are ready
  size_t thread_id = 0;
  for (auto& [workers, start, n, type, handle] : {std::tuple {&stream_threads,
                                                              start_thread {stream_thread},
                                                              number_of_threads,
                                                              std::string("GPU"),
                                                              handle_ready {handle_stream_ready}},
                                                  std::tuple {&io_workers,
                                                              start_thread {slice_thread},
                                                              static_cast<unsigned>(n_input),
                                                              std::string("Slices"),
                                                              handle_ready {handle_default_ready}},
                                                  std::tuple {&io_workers,
                                                              start_thread {output_thread},
                                                              static_cast<unsigned>(n_write),
                                                              std::string("Output"),
                                                              handle_ready {handle_default_ready}},
                                                  std::tuple {&mon_workers,
                                                              start_thread {mon_thread},
                                                              static_cast<unsigned>(n_mon),
                                                              std::string("Mon"),
                                                              handle_ready {handle_default_ready}}}) {
    size_t n_ready = 0;
    for (unsigned i = 0; i < n; ++i) {
      zmq::socket_t control = zmqSvc->socket(zmq::PAIR);
      zmq::setsockopt(control, zmq::LINGER, 0);
      auto con = connection(thread_id);
      control.bind(con.c_str());
      // I don't know why, but this prevents problems. Probably
      // some race condition I haven't noticed.
      std::this_thread::sleep_for(std::chrono::milliseconds {50});

      workers->emplace_back(start(thread_id, i), std::move(control));
      items[thread_id] = {std::get<1>(workers->back()), 0, zmq::POLLIN, 0};

      // Check if thread is ready
      auto ready = socket_ready(std::get<1>(workers->back()));
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
    io_conf.number_of_slices, std::map<size_t, SliceStatus> {{0, SliceStatus::Empty}});
  std::vector<std::map<size_t, size_t>> events_in_slice(io_conf.number_of_slices, std::map<size_t, size_t> {{0, 0}});

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

  Timer t_mon;

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

  // track run changes
  std::optional<LHCb::ODIN> next_odin;
  bool run_change = false;
  uint current_run_number = 0;

  // Lambda to check if any event processors are done processing
  auto check_processors = [&]() {
    for (size_t i = 0; i < number_of_threads; ++i) {
      if (items[i].revents & zmq::POLLIN) {
        auto& socket = std::get<1>(stream_threads[i]);
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
            buffers_manager->writeSingleEventPassthrough(buffer_index);
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
            buffers_manager->returnBufferUnfilled(buffer_index);
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

          if (t) {
            double elapsed_time = t->get_elapsed_time();
            auto dt = elapsed_time - previous_time_measurement;
            if (dt > 5.) {
              if (print_status) {
                info_cout << "Processed " << n_events_processed << " events\n";
                char buf[200];
                std::snprintf(
                  buf,
                  sizeof(buf),
                  "Processed %7li events at a rate of %8.2f events/s\n",
                  n_events_measured * io_conf.number_of_repetitions,
                  n_events_measured * io_conf.number_of_repetitions / dt);
                info_cout << buf;
                std::snprintf(
                  buf,
                  sizeof(buf),
                  "Output    %7lu events at a rate of %8.2f events/s\n",
                  n_output_measured,
                  n_output_measured / dt);
                info_cout << buf;
              }

              if (throughput_socket) {
                zmqSvc->send(
                  *throughput_socket, std::to_string(n_events_measured * io_conf.number_of_repetitions / dt));
              }
              previous_time_measurement = elapsed_time;
              n_events_measured = 0;
              n_output_measured = 0;
            }
          }

          // Add the slice and buffer to the queue for output
          write_queue.push(std::make_tuple(slice_index, first_event, buffer_index));

          input_slice_status[slice_index][first_event] = SliceStatus::Processed;
          buffers_manager->returnBufferFilled(buffer_index);
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
        auto monitor_index = zmqSvc->receive<unsigned>(socket);
        buffers_manager->returnBufferProcessed(buffer_index);
        monitor_manager->freeMonitor(monitor_index);
      }
    }
  };

  if (!allen_control && !error_count) {
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
  bool stop = false, exit_loop = false;
  std::optional<Timer> t_stop;
  float stop_timeout = 5.f;

  // Main event loop
  // - Check if input slices are available from the input thread
  // - Distribute new input slices to stream_threads as soon as they arrive
  //   in a round-robin fashion
  // - If any slices failed to process then distribute the split sub-slices
  //   to stream_threads for processing
  // - Check if any stream_threads are done with a slice and mark it to be written out
  // - Send any processed slice+buffer pairs to I/O for writing
  // - Also send host buffers to monitoring thread
  // - Check if the loop should exit
  //
  // NOTE: special behaviour is implemented for testing without asynch
  // I/O and with repetitions. In this case, a single slice is
  // distributed to all stream_threads once.
  while (error_count == 0) {

    // Wait for messages to come in from the I/O, monitoring or stream threads
    zmqSvc->poll(&items[0], items.size(), stop ? 100 : -1);

    // If we have a pending run change we must do that before receiving further input from the I/O threads
    if (run_change) {
      if (next_odin) {
        // Only process the run change once all GPU stream_threads have finished
        if (stream_ready.count() == number_of_threads) {
          debug_cout << "Run number changing from " << current_run_number << " to " << next_odin->runNumber()
                     << std::endl;
          updater->update(next_odin->data);
          current_run_number = next_odin->runNumber();
          next_odin.reset();
          run_change = false;
        }
      }
      else {
        run_change = false;
      }
    }

    if (!run_change) {
      // Check if input slices are ready or events have been written
      for (size_t i = 0; i < n_io; ++i) {
        if (items[number_of_threads + i].revents & zmq::POLLIN) {
          auto& socket = std::get<1>(io_workers[i]);
          auto msg = zmqSvc->receive<std::string>(socket);
          if (msg == "SLICE") {
            slice_index = zmqSvc->receive<size_t>(socket);
            auto n_filled = zmqSvc->receive<size_t>(socket);

            // Check once that raw banks with MC information are available if MC check is requested
            if (n_events_read == 0 && sequence_contains_validation_algorithms) {
              auto bno_pvs = input_provider->banks(BankTypes::MCVertices, *slice_index);
              auto bno_tracks = input_provider->banks(BankTypes::MCTracks, *slice_index);
              if (bno_pvs.offsets.size() == 1 || bno_tracks.offsets.size() == 1) {
                error_cout << "No raw bank containing MC information found in input file" << std::endl;
                goto loop_error;
              }
            }

            // FIXME: make the warmup time configurable
            if (
              !t && (io_conf.number_of_repetitions == 1 || (slices_processed >= 5 * number_of_threads) ||
                     !io_conf.async_io)) {
              info_cout << "Starting timer for throughput measurement\n";
              throughput_start = n_events_processed * io_conf.number_of_repetitions;
              t = Timer {};
              previous_time_measurement = t->get_elapsed_time();
            }
            input_slice_status[*slice_index][0] = SliceStatus::Filled;
            events_in_slice[*slice_index][0] = n_filled;
            n_events_read += n_filled;
            // If we have a slice we must send it for processing before polling remaining I/O threads
            break;
          }
          else if (msg == "RUN") {
            run_change = true;
            auto odin_data = zmqSvc->receive<decltype(LHCb::ODIN::data)>(socket);
            next_odin = LHCb::ODIN {odin_data};
            debug_cout << "Requested run change from " << current_run_number << " to " << next_odin->runNumber()
                       << std::endl;
            // guard against double run changes if we have multiple input threads
            if ((disable_run_changes && current_run_number != 0) || next_odin->runNumber() == current_run_number)
              next_odin.reset();
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
            if (io_conf.async_io && slice_finished) {
              input_slice_status[slc_idx].clear();
              input_slice_status[slc_idx][0] = SliceStatus::Empty;
              input_provider->slice_free(slc_idx);
              events_in_slice[slc_idx].clear();
              events_in_slice[slc_idx][0] = 0;
            }

            buffers_manager->returnBufferWritten(buf_idx);
          }
          else if (msg == "DONE") {
            if (!io_done) {
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
    }

    // If there is a slice, send it to the next processor; when async
    // I/O is disabled send the slice(s) to all stream_threads
    if (slice_index) {
      bool first = true;
      while ((io_conf.async_io && first) || (!io_conf.async_io && stream_ready.count())) {
        first = false;
        size_t processor_index = prev_processor++;
        if (prev_processor == number_of_threads) {
          prev_processor = 0;
        }
        // send message to processor to process the slice
        if (io_conf.async_io) {
          input_slice_status[*slice_index][0] = SliceStatus::Processing;
        }
        buffer_index = std::optional<size_t> {buffers_manager->assignBufferToFill()};
        auto& socket = std::get<1>(stream_threads[processor_index]);
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
      buffer_index = std::optional<size_t> {buffers_manager->assignBufferToFill()};
      auto& socket = std::get<1>(stream_threads[processor_index]);
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
    buffer_index = std::optional<size_t> {buffers_manager->assignBufferToProcess()};
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
        buffers_manager->returnBufferProcessed(*buffer_index);
      }
      buffer_index = std::optional<size_t> {buffers_manager->assignBufferToProcess()};
    }
    buffer_index.reset();

    // Check for finished monitoring jobs
    check_monitors();

    // periodically save monitoring histograms
    if (mon_save_period > 0 && t_mon.get_elapsed_time() >= mon_save_period) {
      monitor_manager->saveHistograms();
      info_cout << "Saved monitoring histograms" << std::endl;
      t_mon.restart();
    }

    if (allen_control && items[control_index].revents & zmq::POLLIN) {
      bool more = false;
      auto msg = zmqSvc->receive<std::string>(*allen_control, &more);

      if (msg == "STOP") {
        stop = true;
        if (more) {
          stop_timeout = zmqSvc->receive<float>(*allen_control);
          t_stop = Timer {};
        }
      }
      else if (msg == "START") {
        // Start the input provider
        io_done = false;

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
    bool io_cond =
      ((!io_conf.async_io && stream_ready.count() == number_of_threads) || (io_conf.async_io && io_done)) &&
      !run_change;
    if (t && io_cond && io_conf.number_of_repetitions > 1) {
      if (!throughput_processed) {
        throughput_processed = n_events_processed * io_conf.number_of_repetitions - throughput_start;
      }
      t->stop();
    }

    // Check if we're done
    if (stream_ready.count() == number_of_threads && io_cond) {
      if (
        buffers_manager->buffersEmpty() &&
        (!io_conf.async_io || (io_conf.async_io && count_status(SliceStatus::Empty) == io_conf.number_of_slices))) {
        info_cout << "Processing complete\n";
        if (allen_control && stop) {
          stop = false;
          t_stop.reset();
          if (output_handler) output_handler->output_done();
          zmqSvc->send(*allen_control, "READY");
        }
        if (!allen_control || (allen_control && exit_loop)) {
          break;
        }
      }
    }
    else if (allen_control && stop && t_stop && static_cast<float>(t_stop->get()) > stop_timeout) {
      if (output_handler) output_handler->cancel();
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
      throughput_processed = n_events_processed * io_conf.number_of_repetitions - throughput_start;
    }
    t->stop();
  }

  // Send stop signal to all threads and join them
  for (auto workers : {std::ref(io_workers), std::ref(mon_workers), std::ref(stream_threads)}) {
    for (auto& worker : workers.get()) {
      zmqSvc->send(std::get<1>(worker), "DONE");
      std::get<0>(worker).join();
    }
  }

  if (print_status) {
    buffers_manager->printStatus();
  }
  if (!mon_filename.empty()) {
    monitor_manager->saveHistograms();
  }

  // Print checker reports
  checker_invoker->report(n_events_processed * io_conf.number_of_repetitions);
  checker_invoker.reset();

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

  if (output_handler != nullptr) {
    info_cout << "Wrote " << n_events_output << "/" << n_events_processed << " events to "
              << output_handler->connection() << "\n";
  }

  input_provider.reset();

  // Reset device
  Allen::device_reset();

  if (allen_control) {
    zmqSvc->send(*allen_control, "NOT_READY");
  }

  return 0;
}
