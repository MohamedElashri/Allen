#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>
#include <cassert>
#include <cmath>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <Logger.h>

#include <Event/RawBank.h>
#include <read_mdf.hpp>
#include <eb_header.hpp>
#include <read_mdf.hpp>
#include <read_mep.hpp>
#include <Transpose.h>
#include <TransposeMEP.h>

#include <HostGlobalEventCut.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc != 3) {
    cout << "usage: read_mep file.mep n_mep" << endl;
    return -1;
  }

  string filename = {argv[1]};
  size_t n_meps = atol(argv[2]);

  // Some storage for reading the events into
  bool eof = false, success = false;
  EB::Header mep_header;
  gsl::span<char const> mep_span;

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  if (input.good) {
    info_cout << "Opened " << filename << "\n";
  }
  else {
    cerr << "Failed to open file " << filename << " " << strerror(errno) << "\n";
    return -1;
  }

  vector<char> data;

  auto bank_ids = ::bank_ids();
  MEP::Blocks blocks;

  vector<uint> scifi_block_ids, ut_block_ids;

  bool count_success = false;
  std::array<unsigned int, LHCb::NBankTypes> banks_count;

  Slices slices;
  EventIDs events;

  size_t interval = 1000;

  size_t i_mep = 0;
  while (!eof && i_mep++ < n_meps) {

    // Read MEP
    std::tie(eof, success, mep_header, mep_span) = MEP::read_mep(input, data);

    //
    if (!count_success) {
      // Count banks per type
      std::tie(count_success, banks_count) = MEP::fill_counts(mep_header, mep_span);

      // Allocate slices
      auto size_fun = [&banks_count, &bank_ids, interval](BankTypes bank_type) -> std::tuple<size_t, size_t> {
        auto it = std::find(bank_ids.begin(), bank_ids.end(), to_integral(bank_type));
        auto lhcb_type = std::distance(bank_ids.begin(), it);
        auto n_blocks = banks_count[lhcb_type];
        // 0 to not allocate data memory; -1 to correct for +1 in allocate_slices: re-evaluate
        return {0, 2 + n_blocks + (1 + interval) * (1 + n_blocks) - 2};
      };
      slices = allocate_slices<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>(n_meps, size_fun);
      blocks.resize(mep_header.n_blocks);
    }

    // Fill blocks
    MEP::find_blocks(mep_header, mep_span, blocks);

    size_t i_block = 0;
    for (auto const& [block_header, block_span] : blocks) {
      auto const lhcb_type = int {block_header.types[0]};
      auto const allen_type = bank_ids[lhcb_type];

      // Copy blocks and calculate block offsets
      for (auto& [ids, at] : {std::tuple {std::ref(scifi_block_ids), BankTypes::FT},
                              std::tuple {std::ref(ut_block_ids), BankTypes::UT}}) {
        if (allen_type == to_integral(at)) {
          auto& [spans, offset, offsets, offsets_size] = slices[allen_type][0];
          ids.get().emplace_back(i_block);
          spans.emplace_back(const_cast<char*>(block_span.data()), block_span.size());
          // auto* data_start = spans[0].begin();
          // std::memcpy(data_start + offset, block_span.data(), block_span.size());
          // offset += block_header.block_size;
        }
      }
      ++i_block;
    }

    MEP::mep_offsets(slices, 0, bank_ids, banks_count, events, mep_header, blocks, {0, interval});
    auto scifi_allen_type = to_integral(BankTypes::FT);

    auto const& [scifi_data, scifi_data_size, scifi_offsets, scifi_offsets_size] = slices[scifi_allen_type][0];

    auto n_scifi_fragments = scifi_block_ids.size();

    for (size_t i_block = 0; i_block < scifi_block_ids.size(); ++i_block) {
      for (size_t event = 0; event < interval; ++event) {
        auto const& sizes = std::get<0>(blocks[scifi_block_ids[i_block]]).sizes;
        [[maybe_unused]] auto fragment_size = sizes[event];

        uint const offset_index = 2 + n_scifi_fragments * (1 + event);
        [[maybe_unused]] uint bank_size =
          scifi_offsets[offset_index + i_block + n_scifi_fragments] - scifi_offsets[offset_index + i_block];
        assert(bank_size == fragment_size);
      }
    }

    auto slice_to_banks = [&slices](int slice_index, BankTypes bank_type) {
      auto bt = to_integral(bank_type);
      auto const& [data, data_size, offsets, offsets_size] = slices[bt][slice_index];
      BanksAndOffsets bno;
      auto& spans = std::get<0>(bno);
      spans.reserve(data.size());
      for (auto s : data) {
        spans.emplace_back(s);
      }
      std::get<1>(bno) = data_size;
      std::get<2>(bno) = offsets;
      return bno;
    };

    auto vp_banks = slice_to_banks(0, BankTypes::VP);
    auto ut_banks = slice_to_banks(0, BankTypes::UT);
    auto scifi_banks = slice_to_banks(0, BankTypes::FT);

    vector<uint> event_list(interval, 0);
    uint number_of_selected_events = 0;

    host_global_event_cut::host_global_event_cut_mep(
      ut_banks,
      scifi_banks,
      interval,
      host_global_event_cut::Parameters {&number_of_selected_events, event_list.data()});
    cout << "selected " << number_of_selected_events << " events" << endl;
  }

  return 0;
}
