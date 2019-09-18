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
#include <list>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <Allen.h>
#include <Updater.h>
#include <ProgramOptions.h>
#include <MPIConfig.h>
#include <Logger.h>
#include <Timer.h>

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
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  const auto rank_str = [&rank] () -> std::string {
    if (rank == MPI::sender) {
      return "MPI::Sender: ";
    } else {
      return "MPI::Receiver: ";
    }
  };

  if (rank == MPI::sender) {
    // The sender is in charge of reading all MDF files and passing
    // them to the receiver.

    // Parse mdf option
    // TODO: Do not repeat this code here, refactor instead.
    std::string flag, arg;
    const auto flag_in = [&flag](const std::vector<std::string>& option_flags) {
      if (std::find(std::begin(option_flags), std::end(option_flags), flag) != std::end(option_flags)) {
        return true;
      }
      return false;
    };

    std::string mdf_input;
    size_t window_size;
    bool non_stop;
    for (auto const& entry : allen_options) {
      std::tie(flag, arg) = entry;
      if (flag_in({"mdf"})) {
        mdf_input = arg;
      } else if (flag_in({"window-size"})) {
        window_size = atoi(arg.c_str());
      } else if (flag_in({"non-stop"})) {
        non_stop = atoi(arg.c_str());
      }
    }

    if (!mdf_input.empty()) {
      std::vector<std::string> connections;
      size_t current = mdf_input.find(","), previous = 0;
      while (current != std::string::npos) {
        connections.emplace_back(mdf_input.substr(previous, current - previous));
        previous = current + 1;
        current = mdf_input.find(",", previous);
      }
      connections.emplace_back(mdf_input.substr(previous, current - previous));

      // Notify window size and create requests of appropiate size
      MPI_Send(&window_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::window_size, MPI_COMM_WORLD);
      std::vector<MPI_Request> requests (window_size);

      // Notify number of events
      const size_t number_of_files = connections.size();
      MPI_Send(&number_of_files, 1, MPI_SIZE_T, MPI::receiver, MPI::message::number_of_events, MPI_COMM_WORLD);

      // Read all files in connections
      std::vector<char*> file_contents;
      std::vector<size_t> file_sizes;

      info_cout << rank_str() << "Reading files\n" << rank_str();
      for (const auto& connection : connections) {
        info_cout << "." << std::flush;
        std::ifstream file_ifstream {connection, std::ios::binary | std::ios::ate};
        file_sizes.emplace_back(file_ifstream.tellg());
        
        char* contents;
        MPI_Alloc_mem(file_sizes.back(), MPI_INFO_NULL, &contents);

        // Populate contents with stream buf
        char* contents_it = contents;
        for (auto it = std::istreambuf_iterator<char>(file_ifstream); it != std::istreambuf_iterator<char>(); ++it) {
          *contents_it = *it;
          contents_it++;
        }

        // std::vector<uint8_t> fcontents {std::istreambuf_iterator<char>(file_ifstream), {}};
        file_contents.emplace_back(contents);
      }
      info_cout << "\n" << rank_str() << number_of_files << " files successfully read.\n";

      // Notify the max file size
      size_t max_file_size = 0;
      for (const auto size : file_sizes) {
        if (size > max_file_size) {
          max_file_size = size;
        }
      }
      MPI_Send(&max_file_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::max_file_size, MPI_COMM_WORLD);

      // Test: Send all the files
      int current_file=0;
      while (non_stop || current_file<number_of_files) {
        // Get event data
        const char* current_event_start = file_contents[current_file];
        const size_t current_event_size = file_sizes[current_file];

        // Notify the event size
        MPI_Send(&current_event_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::event_size, MPI_COMM_WORLD);

        // Number of full-size (MPI::mdf_chunk_size) messages
        int n_messages = current_event_size / MPI::mdf_chunk_size;
        // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
        int rest = current_event_size - n_messages * MPI::mdf_chunk_size;
        // Number of parallel sends
        int n_sends = n_messages > window_size ? window_size : n_messages;

        // info_cout << rank_str() << "n_messages " << n_messages << ", rest " << rest << ", n_sends " << n_sends << "\n";
        
        // Initial parallel sends
        for (int k = 0; k < n_sends; k++) {
            const char* message = current_event_start + k * MPI::mdf_chunk_size;
            // info_cout << rank_str() << "Isend: Tag " << MPI::message::event_send_tag_start + k << "\n";
            MPI_Isend(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::receiver, MPI::message::event_send_tag_start + k,
                      MPI_COMM_WORLD, &requests[k]);
        }
        // Sliding window sends
        for(int k = n_sends; k < n_messages; k++) {
            int r;
            MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
            const char* message = current_event_start + k * MPI::mdf_chunk_size;
            MPI_Isend(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::receiver, MPI::message::event_send_tag_start + k,
                      MPI_COMM_WORLD, &requests[r]);
        }
        // Last send (if necessary)
        if (rest) {
            int r;
            MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
            const char* message = current_event_start + n_messages * MPI::mdf_chunk_size;
            MPI_Isend(message, rest, MPI_BYTE, MPI::receiver, MPI::message::event_send_tag_start + n_messages,
                      MPI_COMM_WORLD, &requests[r]);
        }
        // Wait until all chunks have been sent
        MPI_Waitall(n_sends, requests.data(), MPI_STATUSES_IGNORE);

        if (non_stop) {
          current_file = (current_file + 1) % number_of_files;
        } else {
          ++current_file;
        }
      }
    } else {
      error_cout << rank_str() << "Required argument --mdf not supplied. Exiting application.\n";
      return -1;
    }
  } else if (rank == MPI::receiver) {
    size_t window_size;
    size_t number_of_events;
    size_t max_file_size;

    // Receive configuration of application
    MPI_Recv(&window_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::window_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(&number_of_events, 1, MPI_SIZE_T, MPI::sender, MPI::message::number_of_events, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(&max_file_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::max_file_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    info_cout << rank_str() << "Window size: " << window_size << "\n"
      << rank_str() << "Number of events: " << number_of_events << "\n"
      << rank_str() << "Maximum file size: " << max_file_size << "\n";

    // Allocate necessary memory
    // As a test, allocate just two slices
    constexpr int number_of_net_slices = 8;
    std::vector<size_t> net_slice_size;
    std::vector<char*> net_slice_contents;
    for (int i=0; i<number_of_net_slices; ++i) {
      char* contents;
      MPI_Alloc_mem(max_file_size, MPI_INFO_NULL, &contents);
      net_slice_contents.push_back(contents);
      net_slice_size.push_back(0);
    }

    std::array<std::mutex, number_of_net_slices> net_mutexes;
    std::array<std::condition_variable, number_of_net_slices> net_slice_produced_cv;
    std::array<std::condition_variable, number_of_net_slices> net_slice_consumed_cv;
    std::array<bool, number_of_net_slices> net_ready;
    std::array<bool, number_of_net_slices> net_consumed;

    for (int i=0; i<number_of_net_slices; ++i) {
      net_ready[i] = false;
      net_consumed[i] = false;
    }

    const auto worker_thread = [&] () {
      info_cout << rank_str() << "Started worker thread\n";
      // Iterate over the slices
      int current_slice = 0;

      while(true) {
        // Wait until the next net slice has been produced
        std::unique_lock<std::mutex> lk {net_mutexes[current_slice]};
        net_slice_produced_cv[current_slice].wait(lk, [&current_slice, &net_ready]{return net_ready[current_slice];});

        // Consume the net slice
        std::chrono::milliseconds duration(100);
        std::this_thread::sleep_for(duration);
        // info_cout << "Data is consumed " << current_slice << "\n";
        net_ready[current_slice] = false;
        net_consumed[current_slice] = true;

        // Notify a net slice has been consumed
        lk.unlock();
        net_slice_consumed_cv[current_slice].notify_one();

        current_slice = (current_slice + 1) % number_of_net_slices;
      }
    };

    std::thread worker(worker_thread);

    std::vector<MPI_Request> requests (window_size);

    // Iterate over the slices
    int current_slice = 0;
    int startup_iteration = 0;

    size_t reporting_period = 5;
    size_t bytes_received = 0;
    size_t meps_received = 0;
    Timer t;
    Timer t_origin;

    // for (int i=0; i<number_of_events; ++i) {
    while (true) {
      if (startup_iteration == number_of_net_slices) {
        // We need to wait for consumption
        std::unique_lock<std::mutex> lk {net_mutexes[current_slice]};
        net_slice_consumed_cv[current_slice].wait(lk, [&current_slice, &net_consumed]{return net_consumed[current_slice];});
      }

      size_t current_event_size;
      char* contents = net_slice_contents[current_slice];

      MPI_Recv(&current_event_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::event_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

      // info_cout << rank_str() << "Current event size: " << current_event_size << "\n";
      net_slice_size[current_slice] = current_event_size;

      // Number of full-size (MPI::mdf_chunk_size) messages
      int n_messages = current_event_size / MPI::mdf_chunk_size;
      // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
      int rest = current_event_size - n_messages * MPI::mdf_chunk_size;
      // Number of parallel sends
      int n_sends = n_messages > window_size ? window_size : n_messages;

      // info_cout << rank_str() << "n_messages " << n_messages << ", rest " << rest << ", n_sends " << n_sends << "\n";
      
      // Initial parallel sends
      for (int k = 0; k < n_sends; k++) {
          char* message = contents + k * MPI::mdf_chunk_size;
          MPI_Irecv(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + k,
                    MPI_COMM_WORLD, &requests[k]);
      }
      // Sliding window sends
      for(int k = n_sends; k < n_messages; k++) {
          int r;
          MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
          char* message = contents + k * MPI::mdf_chunk_size;
          MPI_Irecv(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + k,
                    MPI_COMM_WORLD, &requests[r]);
      }
      // Last send (if necessary)
      if (rest) {
          int r;
          MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
          char* message = contents + n_messages * MPI::mdf_chunk_size;
          MPI_Irecv(message, rest, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + n_messages,
                    MPI_COMM_WORLD, &requests[r]);
      }
      // Wait until all chunks have been sent
      MPI_Waitall(n_sends, requests.data(), MPI_STATUSES_IGNORE);

      // Notify data is ready to consumer thread
      {
        std::lock_guard<std::mutex> lk {net_mutexes[current_slice]};
        // info_cout << "Data is ready " << current_slice << "\n";
        net_ready[current_slice] = true;
        net_consumed[current_slice] = false;
      }
      net_slice_produced_cv[current_slice].notify_one();

      if (startup_iteration < number_of_net_slices) {
        ++startup_iteration;
      }

      current_slice = (current_slice + 1) % number_of_net_slices;

      bytes_received += current_event_size;
      meps_received += 1;
      if (t.get_elapsed_time() >= reporting_period) {
        const auto seconds = t.get_elapsed_time();
        const double rate = (double) meps_received / seconds;
        double bandwidth = ((double) (bytes_received * 8)) / (1024 * 1024 * 1024 * seconds);

        printf("[%lf, %lf] Throughput: %lf MEP/s, %lf Gb/s\n",
                t_origin.get_elapsed_time(), seconds, rate, bandwidth);

        bytes_received = 0;
        meps_received = 0;
        
        t.restart();
      }
    }

    Allen::NonEventData::Updater updater {allen_options};
    return allen(std::move(allen_options), &updater);
  }
}
