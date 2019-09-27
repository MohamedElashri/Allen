#include <map>
#include <string>
#include <iostream>
#include <vector>
#include <ProgramOptions.h>
#include <MPIConfig.h>
#include <Logger.h>
#include <InputTools.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <read_mep.hpp>

namespace MPI {
  int rank;

  std::string rank_str()
  {
    if (rank == sender) {
      return "MPI::Sender: ";
    }
    else {
      return "MPI::Receiver: ";
    }
  }
}

int send_meps_mpi(std::map<std::string, std::string> const& allen_options)
{

  std::string mep_input;
  size_t window_size;
  bool non_stop;
  bool with_mpi = false;
  bool number_of_events = 0;
  for (auto const& [flag, arg] : allen_options) {
    if (flag == "with-mpi") {
      with_mpi = atoi(arg.c_str());
    }
    else if (flag == "mep") {
      mep_input = arg;
    }
    else if (flag == "mpi-window-size") {
      window_size = atoi(arg.c_str());
    }
    else if (flag == "non-stop") {
      non_stop = atoi(arg.c_str());
    }
  }

  // The sender is in charge of reading all MDF files and passing
  // them to the receiver.

  if (mep_input.empty()) {
    error_cout << MPI::rank_str() << "Required argument --mdf not supplied. Exiting application.\n";
    return -1;
  }

  auto connections = split_input(mep_input);

  // Create requests of appropiate size
  std::vector<MPI_Request> requests(window_size);

  // Read all files in connections
  std::vector<gsl::span<char>> meps;

  info_cout << MPI::rank_str() << "Reading files\n" << MPI::rank_str();

  std::vector<char> data;
  gsl::span<char const> mep_span;
  size_t n_meps = 0;
  EB::Header mep_header;

  for (const auto& connection : connections) {
    bool eof = false, success = true;
    while (success && !eof) {
      info_cout << "." << std::flush;

      int input = ::open(connection.c_str(), O_RDONLY);
      std::tie(eof, success, mep_header, mep_span) = MEP::read_mep(input, data);

      if (!eof && success) {
        char* contents = nullptr;
        MPI_Alloc_mem(mep_span.size(), MPI_INFO_NULL, &contents);

        // Populate contents with stream buf
        std::copy_n(mep_span.data(), mep_span.size(), contents);
        ++n_meps;

        meps.emplace_back(contents, mep_span.size());
      }
      if (n_meps >= number_of_events && number_of_events != 0) {
        goto send;
      }
    }
  }

 send:

  info_cout << MPI::rank_str() << "EB header: "
            << mep_header.n_blocks << ", "
            << mep_header.packing_factor << ", "
            << mep_header.reserved << ", "
            << mep_header.mep_size << "\n";

  size_t packing_factor = mep_header.packing_factor;
  MPI_Send(&packing_factor, 1, MPI_SIZE_T, MPI::receiver, MPI::message::packing_factor, MPI_COMM_WORLD);

  size_t number_of_meps = meps.size();
  MPI_Send(&number_of_meps, 1, MPI_SIZE_T, MPI::receiver, MPI::message::number_of_meps, MPI_COMM_WORLD);

  // Test: Send all the files
  int current_mep = 0;
  while (non_stop || current_mep < meps.size()) {
    // info_cout << MPI::rank_str() << "round " << current_file << "\n";

    // Get event data
    const char* current_event_start = meps[current_mep].data();
    const size_t current_event_size = meps[current_mep].size();

    // Notify the event size
    MPI_Send(&current_event_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::event_size, MPI_COMM_WORLD);

    // Number of full-size (MPI::mdf_chunk_size) messages
    int n_messages = current_event_size / MPI::mdf_chunk_size;
    // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
    int rest = current_event_size - n_messages * MPI::mdf_chunk_size;
    // Number of parallel sends
    int n_sends = n_messages > window_size ? window_size : n_messages;

    // Initial parallel sends
    for (int k = 0; k < n_sends; k++) {
      const char* message = current_event_start + k * MPI::mdf_chunk_size;
      // info_cout << MPI::rank_str() << "Isend: Tag " << MPI::message::event_send_tag_start + k << "\n";
      MPI_Isend(
                message,
                MPI::mdf_chunk_size,
                MPI_BYTE,
                MPI::receiver,
                MPI::message::event_send_tag_start + k,
                MPI_COMM_WORLD,
                &requests[k]);
    }
    // Sliding window sends
    for (int k = n_sends; k < n_messages; k++) {
      int r;
      MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
      const char* message = current_event_start + k * MPI::mdf_chunk_size;
      MPI_Isend(
                message,
                MPI::mdf_chunk_size,
                MPI_BYTE,
                MPI::receiver,
                MPI::message::event_send_tag_start + k,
                MPI_COMM_WORLD,
                &requests[r]);
    }
    // Last send (if necessary)
    if (rest) {
      int r;
      MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
      const char* message = current_event_start + n_messages * MPI::mdf_chunk_size;
      MPI_Isend(
                message,
                rest,
                MPI_BYTE,
                MPI::receiver,
                MPI::message::event_send_tag_start + n_messages,
                MPI_COMM_WORLD,
                &requests[r]);
    }
    // Wait until all chunks have been sent
    MPI_Waitall(n_sends, requests.data(), MPI_STATUSES_IGNORE);

    if (non_stop) {
      current_mep = (current_mep + 1) % meps.size();
    }
    else {
      ++current_mep;
    }
  }

  MPI_Finalize();
  return 0;
}
