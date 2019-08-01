#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <numeric>
#include <map>

#include <raw_bank.hpp>
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

  size_t events_per_slice = 1000;
  double n_filled = 0.;
  size_t n_events = 10000;
  size_t offsets_size = 10001;

  size_t buffer_size = average_event_size * n_events * 1024 * bank_size_fudge_factor;

  vector<string> files(argc - 2);
  for (int i = 0; i < argc - 2; ++i) {
    files[i] = argv[i + 2];
  }

  std::array<BankTypes, NBankTypes> bank_types{BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON};

  vector<vector<char>> compress_buffers(n_slices, vector<char>(1024 * 1024));

  std::vector<ReadBuffer> read_buffers(n_slices);
  for (auto& [n_filled, event_offsets, bank_offsets, buffer] : read_buffers) {
    // FIXME: Make this configurable
    buffer.resize(n_events * average_event_size * bank_size_fudge_factor * 1024);
    event_offsets.resize(offsets_size);
    event_offsets[0] = 0;
    bank_offsets.resize(offsets_size * NBankTypes);
    n_filled = 0;
  }

  // Bank ID translation
  vector<int> bank_ids;
  bank_ids.resize(LHCb::RawBank::LastType);

  for (int bt = LHCb::RawBank::L0Calo; bt < LHCb::RawBank::LastType; ++bt) {
    auto it = Allen::bank_types.find(static_cast<LHCb::RawBank::BankType>(bt));
    if (it != Allen::bank_types.end()) {
      bank_ids[bt] = to_integral(it->second);
    } else {
      bank_ids[bt] = -1;
    }
  }

  // Transposed slices
  Slices slices;

  for (auto bank_type : bank_types) {
    auto ib = to_integral<BankTypes>(bank_type);
    // Fudge with extra 20% memory
    auto& banks_slices = slices[ib];
    banks_slices.reserve(n_slices);
    for (size_t i = 0; i < n_slices; ++i) {
      auto* events_mem = static_cast<char*>(malloc(buffer_size));
      auto* offsets_mem = static_cast<uint*>(malloc((n_events + 1) * sizeof(uint)));

      offsets_mem[0] = 0;
      banks_slices.emplace_back(gsl::span<char>{events_mem, buffer_size},
                                gsl::span<uint>{offsets_mem, n_events + 1},
                                1);
    }
  }

  Timer t;

  LHCb::MDFHeader header;

  unique_ptr<ifstream> input;
  size_t i_file = 0, n_bytes_read = 0;
  bool eof = false, error = false, read_full = false;
  string file;
  for (size_t i_buffer = 0; i_buffer < read_buffers.size(); ++i_buffer) {
    while (std::get<0>(read_buffers[i_buffer]) < n_events && i_file < files.size()) {
      if (!input || eof) {
        file = files[i_file++];
        input = make_unique<ifstream>(file, std::ios::binary);
        if (!input->is_open()) {
          cerr << "error opening " << file << "\n";
          return -1;
        }
        input->read(reinterpret_cast<char*>(&header), sizeof(header));
        if (input->good() && !input->eof()) {
          cerr << "error reading " << file << "\n";
          return -1;
        } else {
          cout << "opened " << file << "\n";
        }
      }
      std::tie(eof, error, read_full, n_bytes_read) = read_events(*input, read_buffers[i_buffer],
                                                                  header,
                                                                  compress_buffers[i_buffer],
                                                                  n_events, false);
      if (error) {
        cerr << "error reading " << file << "\n";
        return -1;
      } else if (eof && i_file == files.size()) {
        cerr << "insufficient events in files" << endl;
        return -1;
      }
    }
  }

  t.stop();
  auto n_read = std::accumulate(read_buffers.begin(), read_buffers.end(), 0.,
                                [](double s, ReadBuffer const& rb) {
                                  return s + std::get<0>(rb);
                                });
  cout << "read " << std::lround(n_read) << " events; " << n_read / t.get()  << " events/s\n";

  auto [count_success, banks_count] = fill_counts(read_buffers[0]);

  size_t n_reps = 50;

  std::vector<EventIDs> event_ids(n_slices);
  for (auto& ids : event_ids) {
    ids.reserve(n_events);
  }

  t.restart();

  std::vector<thread> threads;

  for (size_t i = 0; i < n_slices; ++i) {
    threads.emplace_back(thread{[i, n_reps, n_events, &read_buffers, &slices, &bank_ids, &banks_count, &event_ids] {
                                  auto& read_buffer = read_buffers[i];
                                  for (size_t rep = 0; rep < n_reps; ++rep) {
                                    auto [success, transpose_full, n_transposed] = transpose_events<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
                                      (read_buffer, slices, i,
                                       event_ids[i], bank_ids,
                                       banks_count, n_events);
                                    info_cout << "thread " << i << " " << success
                                              << " " << transpose_full << " " << n_transposed << endl;
                                  }}});
  }

  for (auto& thread : threads) {
    thread.join();
  }

  t.stop();
  cout << "transposed " << n_slices * n_events * n_reps / t.get()  << " events/s\n";
}
