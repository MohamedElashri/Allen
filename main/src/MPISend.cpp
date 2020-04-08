#include <map>
#include <string>
#include <iostream>
#include <vector>
#include <ProgramOptions.h>
#include <MPIConfig.h>
#include <Logger.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <read_mdf.hpp>
#include <read_mep.hpp>

namespace MPI {
  int rank;

  std::string rank_str()
  {
    if (rank == receiver) {
      return "MPI::Receiver: ";
    }
    else {
      return "MPI::Sender: ";
    }
  }
} // namespace MPI

int send_meps_mpi(std::map<std::string, std::string> const& allen_options)
{

  std::string flag, arg;
  const auto flag_in = [&flag](const std::vector<std::string>& option_flags) {
    if (std::find(std::begin(option_flags), std::end(option_flags), flag) != std::end(option_flags)) {
      return true;
    }
    return false;
  };

  std::string mep_input;
  size_t window_size;
  bool non_stop = true;
  size_t number_of_events = 0;
  for (auto const& entry : allen_options) {
    std::tie(flag, arg) = entry;

    if (flag_in({"mep"})) {
      mep_input = arg;
    }
    else if (flag_in({"mpi-window-size"})) {
      window_size = atoi(arg.c_str());
    }
    else if (flag_in({"non-stop"})) {
      non_stop = atoi(arg.c_str());
    }
    else if (flag_in({"n", "number-of-events"})) {
      number_of_events = atol(arg.c_str());
    }
  }

  // The sender is in charge of reading all MDF files and passing
  // them to the receiver.

  if (mep_input.empty()) {
    error_cout << MPI::rank_str() << "Required argument --mep not supplied. Exiting application.\n";
    return -1;
  }

  auto connections = split_string(mep_input, ",");

  // Create requests of appropiate size
  std::vector<MPI_Request> requests(window_size);

  // Read all files in connections
  std::vector<std::tuple<EB::Header, gsl::span<char>>> meps;

  info_cout << MPI::rank_str() << "Reading "
            << (number_of_events != 0 ? std::to_string(number_of_events) : std::string {"all"}) << " meps from files\n";

  std::vector<char> data;
  gsl::span<char const> mep_span;
  size_t n_meps = 0;

  for (const auto& connection : connections) {
    bool eof = false, success = true;
    EB::Header mep_header;
    auto input = MDF::open(connection, O_RDONLY);

    while (success && !eof) {
      info_cout << "." << std::flush;

      std::tie(eof, success, mep_header, mep_span) = MEP::read_mep(input, data);

      if (!eof && success) {
        char* contents = nullptr;
        MPI_Alloc_mem(mep_span.size(), MPI_INFO_NULL, &contents);

        // Populate contents with stream buf
        std::copy_n(mep_span.data(), mep_span.size(), contents);
        ++n_meps;

        meps.emplace_back(std::move(mep_header), gsl::span<char> {contents, mep_span.size()});
      }
      if (n_meps >= number_of_events && number_of_events != 0) {
        input.close();
        goto send;
      }
    }
    input.close();
  }

send:

  if (meps.empty()) {
    info_cout << "Failed to read MEPs from file\n";
    exit(1);
  }

  auto const& first_header = std::get<0>(*meps.begin());

  info_cout << "\n"
            << MPI::rank_str() << "EB header: " << first_header.n_blocks << ", " << first_header.packing_factor << ", "
            << first_header.reserved << ", " << first_header.mep_size << "\n";

  size_t packing_factor = first_header.packing_factor;
  MPI_Send(&packing_factor, 1, MPI_SIZE_T, MPI::receiver, MPI::message::packing_factor, MPI_COMM_WORLD);

  size_t number_of_meps = meps.size();
  MPI_Send(&number_of_meps, 1, MPI_SIZE_T, MPI::receiver, MPI::message::number_of_meps, MPI_COMM_WORLD);

  // Test: Send all the files
  size_t current_mep = 0;
  while (non_stop || current_mep < meps.size()) {

    // Get event data
    auto const& [mep_header, mep_span] = meps[current_mep];
    const char* current_event_start = mep_span.data();
    const size_t current_event_size = mep_span.size();

    // Notify the event size
    MPI_Send(&current_event_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::event_size, MPI_COMM_WORLD);

    // Number of full-size (MPI::mdf_chunk_size) messages
    size_t n_messages = current_event_size / MPI::mdf_chunk_size;
    // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
    size_t rest = current_event_size - n_messages * MPI::mdf_chunk_size;
    // Number of parallel sends
    size_t n_sends = n_messages > window_size ? window_size : n_messages;

    // Initial parallel sends
    for (size_t k = 0; k < n_sends; k++) {
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
    for (size_t k = n_sends; k < n_messages; k++) {
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
