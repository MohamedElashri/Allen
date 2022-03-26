/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <numeric>
#include <map>

#include <Event/RawBank.h>
#include <read_mdf.hpp>
#include <Timer.h>
#include <MDFProvider.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 2) {
    cout << "usage: bench_transpose n_slices <file.mdf> <file.mdf> <file.mdf> ..." << endl;
    return -1;
  }

  size_t n_slices = atoi(argv[1]);
  if (n_slices == 0) {
    cout << "usage: bench_transpose n_slices <file.mdf> <file.mdf> <file.mdf> ..." << endl;
    return -1;
  }

  // Test parameters
  size_t n_events = 10000;
  size_t offsets_size = 10001;
  size_t n_reps = 50;

  size_t buffer_size = average_event_size * n_events * 1024 * bank_size_fudge_factor;

  vector<string> files(argc - 2);
  for (int i = 0; i < argc - 2; ++i) {
    files[i] = argv[i + 2];
  }

  // temporary storage
  vector<vector<char>> compress_buffers(n_slices, vector<char>(1024 * 1024));

  // Allocate read buffer space
  std::vector<Allen::ReadBuffer> read_buffers(n_slices);
  for (auto& [n_filled, event_offsets, buffer, transpose_start] : read_buffers) {
    // FIXME: Make this configurable
    buffer.resize(n_events * average_event_size * bank_size_fudge_factor * 1024);
    event_offsets.resize(offsets_size);
    event_offsets[0] = 0;
    n_filled = 0;
    transpose_start = 0;
  }

  // Bank ID translation
  auto bank_ids = Allen::bank_ids();

  Timer t;

  // Header for storage
  LHCb::MDFHeader header;

  // Read events into buffers, open more files if needed
  optional<Allen::IO> input;
  size_t i_file = 0, n_bytes_read = 0;
  bool eof = false, error = false;
  string file;
  for (size_t i_buffer = 0; i_buffer < read_buffers.size(); ++i_buffer) {
    while (std::get<0>(read_buffers[i_buffer]) < n_events) {
      if (!input || eof) {
        file = files[i_file++];
        if (i_file == files.size()) {
          i_file = 0;
        }
        input = MDF::open(file.c_str(), O_RDONLY);
        if (!input->good) {
          cerr << "error opening " << file << " " << strerror(errno) << "\n";
          return -1;
        }
        ssize_t n_bytes = input->read(reinterpret_cast<char*>(&header), sizeof(header));
        if (n_bytes <= 0) {
          cerr << "error reading " << file << " " << strerror(errno) << "\n";
          return -1;
        }
        else {
          cout << "opened " << file << "\n";
        }
      }
      std::tie(eof, error, n_bytes_read) =
        read_events(*input, read_buffers[i_buffer], header, compress_buffers[i_buffer], n_events, false);
      if (input && eof) {
        input->close();
      }
      else if (error) {
        cerr << "error reading " << file << "\n";
        return -1;
      }
    }
  }

  // Measure and report read throughput
  t.stop();
  auto n_read =
    std::accumulate(read_buffers.begin(), read_buffers.end(), 0., [](double s, Allen::ReadBuffer const& rb) {
      return s + std::get<0>(rb);
    });
  cout << "read " << std::lround(n_read) << " events; " << n_read / t.get() << " events/s\n";

  // Count the number of banks of each type
  auto& [n_filled, event_offsets, read_buffer, transpose_start] = read_buffers[0];
  bool count_success = false;
  std::array<unsigned int, NBankTypes> banks_count {};

  auto sd_from_bank_type = [bank_ids](LHCb::RawBank const* raw_bank) {
    return static_cast<BankTypes>(bank_ids[raw_bank->type()]);
  };

  gsl::span<char const> bank_data {read_buffer.data(), event_offsets[1]};
  auto is_mc = check_sourceIDs(bank_data);
  Allen::sd_from_raw_bank sd_from_raw;
  Allen::bank_sorter bank_sorter;
  if (is_mc) {
    sd_from_raw = sd_from_bank_type;
    bank_sorter = sort_by_bank_type;
  }
  else {
    sd_from_raw = sd_from_sourceID;
    bank_sorter = sort_by_sourceID;
  }

  std::tie(count_success, banks_count) = fill_counts(bank_data, sd_from_raw, {});
  std::array<int, NBankTypes> banks_version {};

  // Transposed slices
  std::unordered_set<BankTypes> bank_types {
    BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN};
  auto size_fun = [buffer_size, n_events, banks_count](BankTypes bt) -> std::tuple<size_t, size_t, size_t> {
    auto const ib = to_integral(bt);
    return {buffer_size, n_events * (banks_count[ib] + 1), n_events};
  };
  Allen::Slices slices = allocate_slices(n_slices, bank_types, size_fun);

  // Allocate space for event ids
  std::vector<EventIDs> event_ids(n_slices);
  std::vector<vector<char>> event_masks(n_slices);
  for (auto& mask : event_masks) {
    mask.resize(n_events, 0);
  }

  for (auto& ids : event_ids) {
    ids.reserve(n_events);
  }

  // reset timer for transpose throughput measurement
  t.restart();

  // storage for threads
  std::vector<thread> threads;

  // Start the transpose threads
  for (size_t i = 0; i < n_slices; ++i) {
    threads.emplace_back(thread {[i,
                                  n_reps,
                                  n_events,
                                  &sd_from_raw,
                                  &bank_sorter,
                                  &read_buffers,
                                  &slices,
                                  &bank_types,
                                  &banks_count,
                                  &banks_version,
                                  &event_ids,
                                  &event_masks] {
      auto& read_buffer = read_buffers[i];
      for (size_t rep = 0; rep < n_reps; ++rep) {

        // Reset the slice
        reset_slice(slices, i, bank_types, event_ids[i]);

        // Transpose events
        auto [success, transpose_full, n_transposed] = transpose_events(
          read_buffer,
          slices,
          i,
          {BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN},
          sd_from_raw,
          bank_sorter,
          banks_count,
          {},
          banks_version,
          event_ids[i],
          event_masks[i],
          n_events);
        info_cout << "thread " << i << " " << success << " " << transpose_full << " " << n_transposed << endl;
      }
    }});
  }

  // Join transpose threads
  for (auto& thread : threads) {
    thread.join();
  }

  t.stop();
  cout << "transposed " << n_slices * n_events * n_reps / t.get() << " events/s\n";
}
