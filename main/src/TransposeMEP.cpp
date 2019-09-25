#include <cassert>

#include <TransposeMEP.h>

std::tuple<bool, std::array<unsigned int, LHCb::NBankTypes>>
MEP::fill_counts(EB::Header const& header, gsl::span<char const> const& mep_span)
{
  // info_cout << "EB header: "
  //   << header.n_blocks << ", "
  //   << header.packing_factor << ", "
  //   << header.reserved << ", "
  //   << header.mep_size << "\n";

  auto header_size = + header.header_size(header.n_blocks);
  gsl::span<char const> block_span{mep_span.data() + header_size,
                                   mep_span.size() - header_size};
  std::array<unsigned int, LHCb::NBankTypes> count {0};
  for (size_t i = 0; i < header.n_blocks; ++i) {
    auto offset = header.offsets[i];
    EB::BlockHeader bh{block_span.data() + offset};

    // info_cout << "EB BlockHeader: "
    //   << bh.event_id << ", " << bh.n_frag << ", " << bh.reserved << ", " << bh.block_size << "\n";

    assert(bh.n_frag != 0);
    auto type = bh.types[0];
    if (type < LHCb::RawBank::LastType) {
      ++count[type];
    }
  }

  return {true, count};
}

size_t MEP::fragment_offsets(std::vector<std::vector<uint32_t>>& input_offsets,
                             ::Slices& slices,
                             int const slice_index,
                             std::vector<int> const& bank_ids,
                             std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
                             EB::Header const& mep_header,
                             Blocks const& blocks,
                             std::tuple<size_t, size_t> const& interval) {

  auto [event_start, event_end] = interval;

  // Loop over all bank sizes in all blocks
  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto const& [block_header, block_data] = blocks[i_block];
    auto& o = input_offsets[i_block];
    uint32_t fragment_offset = 0;

    auto lhcb_type = block_header.types[0];
    auto allen_type = bank_ids[lhcb_type];
    for (size_t i = 0; i < event_end; ++i) {
      o[i] = fragment_offset;
      fragment_offset += block_header.sizes[i];
      // Fill the size per bank type per event
      if (allen_type != -1 && i >= event_start) {
        // Anticipate offset structure already here, i.e. don't assign to the first one
        auto idx = i - event_start + 1;
        auto& event_offsets = std::get<1>(slices[allen_type][slice_index]);

        // Allen raw bank format has the sourceID followed by the raw bank data
        event_offsets[idx] += sizeof(uint32_t) + block_header.sizes[i];
      }
    }
  }

  // Prefix sum over sizes per bank type per event to get the output
  // "Allen" offsets per bank type per event
  size_t n_frag = (event_end - event_start);
  for (size_t lhcb_type = 0; lhcb_type < bank_ids.size(); ++lhcb_type) {
    auto allen_type = bank_ids[lhcb_type];
    if (allen_type != -1) {
      auto& [slice, event_offsets, offsets_size] = slices[allen_type][slice_index];
      event_offsets[0] = 0;
      auto preamble_words = 2 + banks_count[lhcb_type];
      for (size_t i = 1; i <= (event_end - event_start) && i <= n_frag; ++i) {

        // Allen raw bank format has the number of banks and the bank
        // offsets in a preamble
        event_offsets[i] += preamble_words * sizeof(uint32_t) + event_offsets[i - 1];

        // Check for sufficient space
        if (event_offsets[i] > slice.size()) {
          n_frag = i;
          break;
        }
      }
    }
  }

  // Set offsets_size here to make sure it's consistent with the max
  for (size_t lhcb_type = 0; lhcb_type < bank_ids.size(); ++lhcb_type) {
    auto allen_type = bank_ids[lhcb_type];
    if (allen_type != -1) {
      auto& [slice, event_offsets, offsets_size] = slices[allen_type][slice_index];
      offsets_size = n_frag + 1;
    }
  }
  return n_frag;
}

bool MEP::transpose_event(
  ::Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  EB::Header const& mep_header,
  std::vector<std::tuple<EB::BlockHeader, gsl::span<char const>>>& blocks,
  std::vector<std::vector<uint32_t>> const& input_offsets,
  std::tuple<size_t, size_t> const& interval)
{
  auto [start_event, end_event] = interval;

  // Loop over all bank data of this event
  size_t bank_index = 1;
  // L0Calo doesn't exist in the upgrade
  LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;

  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto const& [block_header, block_data] = blocks[i_block];
    auto bank_type = static_cast<LHCb::RawBank::BankType>(block_header.types[0]);
    auto& source_offsets = input_offsets[i_block];

    // Check what to do with this bank
    if (bank_type == LHCb::RawBank::ODIN) {
      // decode ODIN bank to obtain run and event numbers
      auto odin_version = mep_header.versions[i_block];
      for (uint16_t i_event = start_event; i_event < end_event; ++i_event) {
        auto odin_data = reinterpret_cast<unsigned int const*>(block_data.data() + source_offsets[i_event]);
        auto odin = MDF::decode_odin(odin_version, odin_data);
        event_ids.emplace_back(odin.run_number, odin.event_number);
      }
    }
    else if (bank_type >= LHCb::RawBank::LastType || bank_ids[bank_type] == -1) {
      prev_type = bank_type;
    }
    else {
      if (bank_type != prev_type) {
        bank_index = 1;
        prev_type = bank_type;
      }

      auto allen_type = bank_ids[bank_type];
      auto& slice = slices[allen_type][slice_index];
      auto const& event_offsets = std::get<1>(slice);
      auto const n_banks_offsets = std::get<2>(slice);

      for (size_t i_event = start_event; i_event < end_event && i_event < block_header.n_frag; ++i_event) {
        // Three things to write for a new set of banks:
        // - number of banks/offsets
        // - offsets to individual banks
        // - bank data

        auto preamble_words = 2 + banks_count[bank_type];

        // Initialize point to write from offset of previous set
        // All bank offsets are uit32_t so cast to that type
        auto* banks_write = reinterpret_cast<uint32_t*>(std::get<0>(slice).data() + event_offsets[i_event - start_event]);

        // Where to write the offsets
        auto* banks_offsets_write = banks_write + 1;

        if (bank_index == 1) {
          // Write the number of banks
          banks_write[0] = banks_count[bank_type];
          banks_offsets_write[0] = 0;
        }

        // get offset for this bank and store offset for next bank
        auto offset = banks_offsets_write[bank_index - 1];
        banks_offsets_write[bank_index] = offset + block_header.sizes[i_event] + sizeof(uint32_t);

        // Where to write the bank data itself
        banks_write += preamble_words;

        // Write sourceID; offset in 32bit words
        auto word_offset = offset / sizeof(uint32_t);
        banks_write[word_offset] = mep_header.source_ids[i_block];

        // Write bank data
        ::memcpy(banks_write + word_offset + 1,
                 block_data.data() + source_offsets[i_event],
                 block_header.sizes[i_event]);
      }

      ++bank_index;
    }
  }
  return true;
}

std::tuple<bool, bool, size_t> MEP::transpose_events(
  MEP::Slice const& mep_slice,
  std::vector<std::vector<uint32_t>>& input_offsets,
  std::vector<std::tuple<EB::BlockHeader, gsl::span<char const>>>& blocks,
  ::Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  std::tuple<size_t, size_t> const& interval)
{
  auto [event_start, event_end] = interval;

  bool success = true;
  auto const& [data, mep_size] = mep_slice;
  EB::Header mep_header(data.data());
  auto hdr_size = mep_header.header_size(mep_header.n_blocks);
  gsl::span<char const> const mep_data{data.data() + hdr_size, data.size() - hdr_size};

  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto block_offset = mep_header.offsets[i_block];
    EB::BlockHeader block_header{mep_data.data() + block_offset};
    gsl::span<char const> block_data{mep_data.data() + block_offset + block_header.header_size(block_header.n_frag),
                                     block_header.block_size};
    blocks[i_block] = std::tuple{std::move(block_header), std::move(block_data)};
  }

  // Reset input offsets
  for (auto& offsets : input_offsets) {
    std::fill(offsets.begin(), offsets.end(), 0);
  }

  auto to_transpose = fragment_offsets(input_offsets, slices, slice_index, bank_ids,
                                       banks_count, mep_header, blocks, interval);

  transpose_event(slices, slice_index, bank_ids, banks_count, event_ids,
                  mep_header, blocks, input_offsets, {event_start, event_start + to_transpose});

  return {success, to_transpose != (event_end - event_start), to_transpose};
}

std::vector<int> bank_ids() {
  // Cache the mapping of LHCb::RawBank::BankType to Allen::BankType
  std::vector<int> ids;
  ids.resize(LHCb::RawBank::LastType);
  for (int bt = LHCb::RawBank::L0Calo; bt < LHCb::RawBank::LastType; ++bt) {
    auto it = Allen::bank_types.find(static_cast<LHCb::RawBank::BankType>(bt));
    if (it != Allen::bank_types.end()) {
      ids[bt] = to_integral(it->second);
    } else {
      ids[bt] = -1;
    }
  }
  return ids;
}
