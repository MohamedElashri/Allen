#include <string>
#include <thread>

#include <zmq_compat.h>
#include <ZeroMQ/IZeroMQSvc.h>
#include <AllenThreads.h>

#include <OutputHandler.h>
#include <HostBuffersManager.cuh>
#include <MonitorManager.h>
#include <CheckerInvoker.h>
#include <InputProvider.h>
#include <StreamWrapper.cuh>
#include <Tools.h>

namespace {
  using namespace zmq;
  using namespace std::string_literals;
} // namespace

std::string connection(const size_t id, std::string suffix)
{
  auto con = std::string {"inproc://control_"} + std::to_string(id);
  if (!suffix.empty()) {
    con += "_" + suffix;
  }
  return con;
}

zmq::socket_t make_control(size_t thread_id, IZeroMQSvc* zmqSvc, std::string suffix = std::string {})
{

  auto make_socket = [thread_id, &suffix, zmqSvc] {
    zmq::socket_t control = zmqSvc->socket(zmq::PAIR);
    zmq::setsockopt(control, zmq::LINGER, 0);
    auto con = connection(thread_id, suffix);
    try {
      control.connect(con.c_str());
    } catch (const zmq::error_t& e) {
      error_cout << "failed to connect connection " << con << "\n";
      throw e;
    }
    return control;
  };

  auto control = make_socket();
  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};

  bool connected = false;
  unsigned int tries = 5;
  while (!connected && tries > 0) {
    zmqSvc->poll(&items[0], 1, 500);
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc->receive<std::string>(control);
      assert(msg == "STATUS");
      zmqSvc->send(control, "READY", send_flags::sndmore);
      zmqSvc->send(control, thread_id);
      connected = true;
    }
    else {
      control = make_socket();
      items[0] = {control, 0, zmq::POLLIN, 0};
      --tries;
    }
  }

  if (!connected) {
    auto msg = "Failed to connect control socket for thread "s + std::to_string(thread_id);
    throw std::runtime_error {msg};
  }

  return control;
}

void run_output(
  const size_t thread_id,
  IZeroMQSvc* zmqSvc,
  OutputHandler* output_handler,
  HostBuffersManager* buffer_manager)
{
  auto* client_socket = output_handler ? output_handler->client_socket() : nullptr;

  std::vector<zmq::pollitem_t> items(client_socket ? 2 : 1);
  if (client_socket) {
    items[1] = {*client_socket, 0, zmq::POLLIN, 0};
  }

  // Create a control socket and connect it.
  zmq::socket_t control = make_control(thread_id, zmqSvc);
  items[0] = {control, 0, zmq::POLLIN, 0};

  while (true) {

    // Check if there are messages
    zmqSvc->poll(&items[0], items.size(), -1);

    if (client_socket && (items[1].revents & zmq::POLLIN)) {
      output_handler->handle();
    }

    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc->receive<std::string>(control);
      if (msg == "DONE") {
        break;
      }
      else if (msg == "WRITE") {
        auto slc_idx = zmqSvc->receive<size_t>(control);
        auto first_evt = zmqSvc->receive<size_t>(control);
        auto buf_idx = zmqSvc->receive<size_t>(control);

        bool success = true;
        auto [passing_event_list, dec_reports, sel_reports, sel_report_offsets] =
          buffer_manager->getBufferOutputData(buf_idx);
        if (output_handler != nullptr) {
          success = output_handler->output_selected_events(
            slc_idx, first_evt, passing_event_list, dec_reports, sel_reports, sel_report_offsets);
        }

        zmqSvc->send(control, "WRITTEN", send_flags::sndmore);
        zmqSvc->send(control, slc_idx, send_flags::sndmore);
        zmqSvc->send(control, first_evt, send_flags::sndmore);
        zmqSvc->send(control, buf_idx, send_flags::sndmore);
        zmqSvc->send(control, success, send_flags::sndmore);
        zmqSvc->send(control, static_cast<size_t>(passing_event_list.size()));
      }
    }
  }
}

/**
 * @brief      Request slices from the input provider and report
 *             them to the main thread; run from a separate thread
 *
 * @param      thread ID of this I/O thread
 * @param      IInputProvider instance
 *
 * @return     void
 */
void run_slices(const size_t thread_id, IZeroMQSvc* zmqSvc, IInputProvider* input_provider)
{

  // Create a control socket and connect it.
  zmq::socket_t control = make_control(thread_id, zmqSvc);

  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};

  int timeout = -1;
  uint current_run_number = 0;
  while (true) {

    // Check if there are messages without blocking
    zmqSvc->poll(&items[0], 1, timeout);

    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc->receive<std::string>(control);
      if (msg == "DONE") {
        break;
      }
      else if (msg == "START") {
        timeout = 0;
      }
    }

    // Get a slice and inform the main thread that it is available
    // NOTE: the argument specifies the timeout in ms, not the number of events.
    auto [good, done, timed_out, slice_index, n_filled, run_number] = input_provider->get_slice(1000);
    // Report errors or good slices that contain events
    if (!timed_out && good && n_filled != 0) {
      // If run number has change then report this first
      if (run_number != current_run_number) {
        current_run_number = run_number;
        zmqSvc->send(control, "RUN", send_flags::sndmore);
        zmqSvc->send(control, current_run_number);
      }
      zmqSvc->send(control, "SLICE", send_flags::sndmore);
      zmqSvc->send(control, slice_index, send_flags::sndmore);
      zmqSvc->send(control, n_filled);
    }
    else if (!good) {
      zmqSvc->send(control, "ERROR");
      break;
    }
    if (done) {
      zmqSvc->send(control, "DONE");
      timeout = -1;
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
  IZeroMQSvc* zmqSvc,
  CheckerInvoker* checker_invoker,
  uint n_reps,
  bool do_check,
  bool cpu_offload,
  bool mep_layout,
  uint inject_mem_fail,
  std::string folder_name_imported_forward_tracks)
{

  auto [device_set, device_name] = set_device(device_id, stream_id);

  zmq::socket_t control = make_control(thread_id, zmqSvc);
  std::optional<zmq::socket_t> check_control;
  if (do_check) {
    check_control = make_control(thread_id, zmqSvc, "check");
  }

  zmq::pollitem_t items[] = {
    {control, 0, ZMQ_POLLIN, 0},
  };

  while (true) {

    zmqSvc->poll(&items[0], 1, -1);

    std::string command;
    std::optional<size_t> idx;
    size_t buf;
    size_t first;
    size_t last;
    if (items[0].revents & zmq::POLLIN) {
      command = zmqSvc->receive<std::string>(control);
      if (command == "DONE") {
        break;
      }
      else if (command != "PROCESS") {
        error_cout << "processor " << stream_id << " received bad command: " << command << "\n";
      }
      else {
        idx = zmqSvc->receive<size_t>(control);
        first = zmqSvc->receive<size_t>(control);
        last = zmqSvc->receive<size_t>(control);
        buf = zmqSvc->receive<size_t>(control);
      }
    }

    if (idx) {
      // Run the stream
      auto status = wrapper->run_stream(
        stream_id,
        buf,
        {input_provider->banks(BankTypes::VP, *idx),
         input_provider->banks(BankTypes::UT, *idx),
         input_provider->banks(BankTypes::FT, *idx),
         input_provider->banks(BankTypes::MUON, *idx),
         input_provider->banks(BankTypes::ODIN, *idx),
         {static_cast<uint>(first), static_cast<uint>(last)},
         n_reps,
         do_check,
         cpu_offload,
         mep_layout,
         inject_mem_fail});

      if (status == cudaErrorMemoryAllocation) {
        zmqSvc->send(control, "SPLIT", send_flags::sndmore);
        zmqSvc->send(control, *idx, send_flags::sndmore);
        zmqSvc->send(control, first, send_flags::sndmore);
        zmqSvc->send(control, last, send_flags::sndmore);
        zmqSvc->send(control, buf);
      }
      else if (status == cudaSuccess) {
        // signal that we're done
        zmqSvc->send(control, "PROCESSED", send_flags::sndmore);
        zmqSvc->send(control, *idx, send_flags::sndmore);
        zmqSvc->send(control, first, send_flags::sndmore);
        zmqSvc->send(control, buf);
        if (do_check && check_control) {
          // Get list of events that are in the slice
          auto const& events = input_provider->event_ids(*idx, first, last);

          // synchronise to avoid threading issues with
          // CheckerInvoker. The main thread will send the folder to
          // only one stream at a time and will block until it receives
          // the message that informs it the checker is done.
          auto mc_folder = zmqSvc->receive<std::string>(*check_control);
          auto mask = wrapper->reconstructed_events(stream_id);
          auto mc_events = checker_invoker->load(mc_folder, events, mask);

          if (mc_events.empty()) {
            zmqSvc->send(*check_control, false);
          }
          else {
            // Run the checker
            std::vector<Checker::Tracks> forward_tracks;
            if (!folder_name_imported_forward_tracks.empty()) {
              std::vector<char> events_tracks;
              std::vector<uint> event_tracks_offsets;
              read_folder(folder_name_imported_forward_tracks, events, mask, events_tracks, event_tracks_offsets, true);
              forward_tracks = read_forward_tracks(events_tracks.data(), event_tracks_offsets.data(), events.size());
            }

            wrapper->run_monte_carlo_test(stream_id, *checker_invoker, mc_events, forward_tracks);
            zmqSvc->send(*check_control, true);
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
void run_monitoring(const size_t mon_id, IZeroMQSvc* zmqSvc, MonitorManager* monitor_manager, uint i_monitor)
{
  zmq::socket_t control = make_control(mon_id, zmqSvc);
  zmq::pollitem_t items[] = {{control, 0, zmq::POLLIN, 0}};

  while (true) {
    // Check if there are messages
    zmqSvc->poll(&items[0], 1, -1);

    std::optional<size_t> buf_idx;
    if (items[0].revents & zmq::POLLIN) {
      auto msg = zmqSvc->receive<std::string>(control);
      if (msg == "DONE") {
        break;
      }
      else if (msg != "MONITOR") {
        error_cout << "monitor thread " << mon_id << " received bad command: " << msg << "\n";
      }
      else {
        buf_idx = zmqSvc->receive<size_t>(control);
      }
    }

    if (buf_idx) {
      monitor_manager->fill(i_monitor, *buf_idx);
      zmqSvc->send(control, "MONITORED", send_flags::sndmore);
      zmqSvc->send(control, *buf_idx, send_flags::sndmore);
      zmqSvc->send(control, i_monitor);
    }
  }
}
