#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <numeric>
#include <map>
#include <vector>
#include <cmath>

#include <gsl-lite.hpp>
#include <raw_bank.hpp>
#include <read_mdf.hpp>
#include <read_mep.hpp>
#include <eb_header.hpp>
#include <Timer.h>
#include <Transpose.h>
#include <TransposeMEP.h>

using namespace std;

int main(int argc, char* argv[])
{
  string usage = "usage: bench_transpose n_slices <file.mep> <file.mep> <file.mep> ...";
  if (argc <= 2) {
    cout << usage << endl;
    return -1;
  }

  size_t n_slices = atoi(argv[1]);
  if (n_slices == 0) {
    cout << usage << endl;
    return -1;
  }

  // Test parameters
  size_t n_meps = 10;
  size_t n_reps = 50;

  vector<string> files(argc - 2);
  for (int i = 0; i < argc - 2; ++i) {
    files[i] = argv[i + 2];
  }

  // Allocate read buffer space
  vector<tuple<vector<char>, EB::Header, gsl::span<char const>, MEP::Blocks, MEP::SourceOffsets>> mep_buffers {
    n_slices};

  // Bank ID translation
  auto ids = bank_ids();

  // Transposed slices
  Slices slices;

  Timer t;

  // Header for storage

  // Read events into buffers, open more files if needed
  optional<Allen::IO> input;
  size_t i_file = 0;
  bool eof = false, success = false;
  string file;
  for (size_t i_buffer = 0; i_buffer < mep_buffers.size(); ++i_buffer) {
    if (!input->good || eof) {
      file = files[i_file++];
      if (i_file == files.size()) {
        i_file = 0;
      }
      input = MDF::open(file.c_str(), O_RDONLY);
      if (!input->good) {
        cerr << "error opening " << file << " " << strerror(errno) << "\n";
        return -1;
      }
      else {
        cout << "opened " << file << "\n";
      }
    }

    auto& [buffer, mep_header, mep_span, blocks, source_offsets] = mep_buffers[i_buffer];
    std::tie(eof, success, mep_header, mep_span) = MEP::read_mep(*input, buffer);
    if (i_buffer == 0) {
      auto pf = mep_header.packing_factor;
      auto size_fun = [pf](BankTypes) -> std::tuple<size_t, size_t> {
        return {std::lround(average_event_size * pf * bank_size_fudge_factor * kB), pf};
      };
      slices = allocate_slices<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>(n_meps, size_fun);
      blocks.resize(mep_header.n_blocks);
    }

    // Fill blocks
    MEP::find_blocks(mep_header, mep_span, blocks);

    // Fill fragment offsets
    MEP::fragment_offsets(blocks, source_offsets);

    if (input->good && eof) {
      input->close();
    }
    else if (!success) {
      cerr << "error reading " << file << "\n";
      return -1;
    }
  }

  auto b_ids = bank_ids();

  // Measure and report read throughput
  t.stop();
  auto n_read = std::accumulate(mep_buffers.begin(), mep_buffers.end(), 0., [](double s, auto const& mb) {
    return s + std::get<1>(mb).packing_factor;
  });
  cout << "read " << std::lround(n_read) << " events; " << n_read / t.get() << " events/s\n";
  cout << std::get<1>(mep_buffers[0]).packing_factor << "\n";
  // Count the number of banks of each type
  auto& [buffer, mep_header, mep_span, blocks, source_offsets] = mep_buffers[0];
  bool count_success = false;
  std::array<unsigned int, LHCb::NBankTypes> banks_count {};
  std::tie(count_success, banks_count) = MEP::fill_counts(mep_header, mep_span);

  // Allocate space for event ids
  std::vector<EventIDs> event_ids(n_slices);
  for (auto& ids : event_ids) {
    ids.reserve(mep_header.packing_factor);
  }

  // reset timer for transpose throughput measurement
  t.restart();

  // storage for threads
  std::vector<thread> threads;

  // Start the transpose threads
  for (size_t i = 0; i < n_slices; ++i) {
    threads.emplace_back(thread {[i, n_reps, &event_ids, &mep_buffers, &slices, &b_ids, &banks_count] {
      auto& [buffer, mep_header, mep_span, blocks, source_offsets] = mep_buffers[i];
      for (size_t rep = 0; rep < n_reps; ++rep) {
        // Reset the slice
        reset_slice<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>(slices, i, event_ids[i]);
        auto [success, transpose_full, n_transposed] = MEP::transpose_events(
          slices,
          i,
          b_ids,
          banks_count,
          event_ids[i],
          mep_header,
          blocks,
          source_offsets,
          {0, mep_header.packing_factor});

        info_cout << "thread " << i << " " << success << " " << transpose_full << " " << n_transposed << endl;
      }
    }});
  }

  // Join transpose threads
  for (auto& thread : threads) {
    thread.join();
  }

  t.stop();

  cout << "transposed " << n_read * n_reps / t.get() << " events/s\n";
}
