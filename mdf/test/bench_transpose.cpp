#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>

#include <raw_bank.hpp>
#include <read_mdf.hpp>
#include <Timer.h>
#include <MDFProvider.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 1) {
    cout << "usage: bench_transpose <file.mdf> <file.mdf> <file.mdf> ..." << endl;
    return -1;
  }

  string filename = {argv[1]};
  size_t n_slices = 1;
  size_t events_per_slice = 1000;
  double n_filled = 0.;
  size_t n_events = 10000;
  size_t offsets_size = 10001;

  size_t buffer_size = average_event_size * n_events * 1024 * bank_size_fudge_factor;

  vector<string> files(argc - 1);
  for (int i = 0; i < argc - 1; ++i) {
    files[i] = argv[i + 1];
  }

  vector<char> compress_buffer(1024 * 1024);

  ReadBuffer read_buffer;
  {
    auto& [n_filled, event_offsets, bank_offsets, buffer] = read_buffer;
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

  for (int ib = 0; ib < NBankTypes; ++ib) {
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

  std::ifstream input{files[0], std::ios::binary};
  auto [eof, error, read_full, n_bytes_read] = read_events(input, read_buffer, compress_buffer, false);

  t.stop();
  cout << "read " << std::get<0>(read_buffer) << " events; " << std::get<0>(read_buffer) / t.get()  << " events/s\n";

  auto [count_success, banks_count] = fill_counts(read_buffer);

  size_t n_reps = 20;

  EventIDs event_ids;
  event_ids.reserve(n_events);

  t.restart();

  for (size_t rep = 0; rep < n_reps; ++rep) {
    auto [success, transpose_full, n_transposed] = transpose_events(read_buffer, slices, 0,
                                                                    event_ids, bank_ids,
                                                                    banks_count, n_events);
    info_cout << success << " " << transpose_full << " " << n_transposed << endl;
  }

  t.stop();
  cout << "transposed " << n_events * n_reps / t.get()  << " events/s\n";
}
