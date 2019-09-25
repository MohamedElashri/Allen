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
#include <Allen.h>
#include <Updater.h>
#include <ProgramOptions.h>
#include <MPIConfig.h>
#include <Logger.h>
#include <Timer.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <read_mep.hpp>

namespace MPI {
  int rank;
}

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
  bool with_mpi = false;
  for (auto const& entry : allen_options) {
    std::tie(flag, arg) = entry;
    if (flag_in({"with-mpi"})) {
      with_mpi = atoi(arg.c_str());
    }
    else if (flag_in({"mdf"})) {
      mdf_input = arg;
    }
    else if (flag_in({"mpi-window-size"})) {
      window_size = atoi(arg.c_str());
    }
    else if (flag_in({"non-stop"})) {
      non_stop = atoi(arg.c_str());
    }
  }

  if (with_mpi) {
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
    MPI_Comm_rank(MPI_COMM_WORLD, &MPI::rank);

    if (MPI::rank == MPI::sender) {
      // The sender is in charge of reading all MDF files and passing
      // them to the receiver.

      if (!mdf_input.empty()) {
        std::vector<std::string> connections;
        size_t current = mdf_input.find(","), previous = 0;
        while (current != std::string::npos) {
          connections.emplace_back(mdf_input.substr(previous, current - previous));
          previous = current + 1;
          current = mdf_input.find(",", previous);
        }
        connections.emplace_back(mdf_input.substr(previous, current - previous));

        // Create requests of appropiate size
        std::vector<MPI_Request> requests(window_size);

        // Number of files to read
        // const size_t number_of_files = connections.size();

        // Read all files in connections
        std::vector<char*> file_contents;
        std::vector<size_t> file_sizes;

        info_cout << MPI::rank_str() << "Reading files\n" << MPI::rank_str();
        for (const auto& connection : connections) {
          info_cout << "." << std::flush;

          std::vector<char> data;
          int input = ::open(connection.c_str(), O_RDONLY);
          auto [eof, success, mep_header, mep_span] = MEP::read_mep(input, data);

          char* contents;
          MPI_Alloc_mem(mep_span.size(), MPI_INFO_NULL, &contents);

          // Populate contents with stream buf
          std::copy_n(mep_span.data(), mep_span.size(), contents);

          file_contents.emplace_back(contents);
          file_sizes.emplace_back(mep_span.size());
        }

        // // Read file_contents 0:
        // LHCb::MDFHeader* mdf_header = reinterpret_cast<LHCb::MDFHeader*>(file_contents[0]);
        // auto mdf_size = mdf_header->size();

        // info_cout << "MDF size: " << mdf_size << "\n";

        // const uint header_version = mdf_header->headerVersion();
        // auto hdr_size = LHCb::MDFHeader::sizeOf(header_version);
        // char* mep_buffer = file_contents[0] + hdr_size;
        EB::Header* mep_header = reinterpret_cast<EB::Header*>(file_contents[0]);

        info_cout << MPI::rank_str() << "EB header: "
          << mep_header->n_blocks << ", "
          << mep_header->packing_factor << ", "
          << mep_header->reserved << ", "
          << mep_header->mep_size << "\n";

        // gsl::span<char const> span {mep_header.data() + hdr_size, EB::Header::header_size(mep_header->n_blocks) + data_size};

        // auto header_size = + header.header_size(header.n_blocks);
        // gsl::span<char const> block_span{mep_span.data() + header_size,
        //                                  mep_span.size() - header_size};
        // std::array<unsigned int, LHCb::NBankTypes> count {0};
        // for (size_t i = 0; i < header.n_blocks; ++i) {
        //   auto offset = header.offsets[i];
        //   EB::BlockHeader bh{block_span.data() + offset};

        //   info_cout << "EB BlockHeader: "
        //     << bh.event_id << ", " << bh.n_frag << ", " << bh.reserved << ", " << bh.block_size << "\n";

        //   assert(bh.n_frag != 0);
        //   auto type = bh.types[0];
        //   if (type < LHCb::RawBank::LastType) {
        //     ++count[type];
        //   }
        // }


        // info_cout << "\n" << MPI::rank_str() << number_of_files << " files successfully read.\n";

        size_t number_of_files = file_contents.size();
        MPI_Send(&number_of_files, 1, MPI_SIZE_T, MPI::receiver, MPI::message::number_of_events, MPI_COMM_WORLD);

        // // Notify the max file size
        // size_t max_file_size = 0;
        // for (const auto size : file_sizes) {
        //   if (size > max_file_size) {
        //     max_file_size = size;
        //   }
        // }
        // MPI_Send(&max_file_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::max_file_size, MPI_COMM_WORLD);

        // Test: Send all the files
        int current_file = 0;
        while (non_stop || current_file < number_of_files) {
          // info_cout << MPI::rank_str() << "round " << current_file << "\n";

          // Get event data
          const char* current_event_start = file_contents[current_file];
          const size_t current_event_size = file_sizes[current_file];

          // Notify the event size
          MPI_Send(&current_event_size, 1, MPI_SIZE_T, MPI::receiver, MPI::message::event_size, MPI_COMM_WORLD);

          // info_cout << MPI::rank_str() << "event size: " << current_event_size << "\n";

          // Number of full-size (MPI::mdf_chunk_size) messages
          int n_messages = current_event_size / MPI::mdf_chunk_size;
          // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
          int rest = current_event_size - n_messages * MPI::mdf_chunk_size;
          // Number of parallel sends
          int n_sends = n_messages > window_size ? window_size : n_messages;

          // info_cout << MPI::rank_str() << "n_messages " << n_messages << ", rest " << rest << ", n_sends " << n_sends
          //           << "\n";

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

          // info_cout << "All chunks sent\n";

          if (non_stop) {
            current_file = (current_file + 1) % number_of_files;
          }
          else {
            ++current_file;
          }
        }
      }
      else {
        error_cout << MPI::rank_str() << "Required argument --mdf not supplied. Exiting application.\n";
        return -1;
      }
    }
    else {
      Allen::NonEventData::Updater updater {allen_options};
      return allen(std::move(allen_options), &updater);
    }
  }
  else {
    Allen::NonEventData::Updater updater {allen_options};
    return allen(std::move(allen_options), &updater);
  }

  if (with_mpi) {
    MPI_Finalize();
  }
}
