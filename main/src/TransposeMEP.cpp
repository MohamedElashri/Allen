#include <cassert>

#include <TransposeMEP.h>

std::tuple<bool, std::array<unsigned int, LHCb::NBankTypes>>
MEP::fill_counts(EB::Header const& header, gsl::span<char const> const& data)
{

  std::array<unsigned int, LHCb::NBankTypes> count {0};
  for (size_t i = 0; i < header.n_blocks; ++i) {
    auto offset = header.offsets[i];
    EB::BlockHeader bh{data.data() + offset};
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
        auto idx = i - event_start;
        auto& slice = slices[allen_type][slice_index];
        auto& output_offsets = std::get<1>(slice);
        output_offsets[idx] += block_header.sizes[i];
      }
    }
  }

  // Prefix sum over sizes per bank type per event to get the output
  // "Allen" offsets per bank type per event
  size_t n_frag = (event_end - event_start);
  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto const& [block_header, block_data] = blocks[i_block];
    auto lhcb_type = block_header.types[0];
    auto allen_type = bank_ids[lhcb_type];
    if (allen_type != -1) {
      auto& [slice, output_offsets, offsets_size] = slices[allen_type][slice_index];
      output_offsets[0] = 0;
      auto preamble_words = 2 + banks_count[lhcb_type];
      for (size_t i = 1; i < (event_end - event_start) && i < n_frag; ++i) {
        output_offsets[i] += preamble_words * sizeof(uint32_t) + output_offsets[i - 1];

        // Check for sufficient space
        if (output_offsets[i] > slice.size()) {
          n_frag = i;
          break;
        }
      }
    }
  }

  // Set offsets_size here to make sure it's consistent with the max
  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto lhcb_type = std::get<0>(blocks[i_block]).types[0];
    auto allen_type = bank_ids[lhcb_type];
    if (allen_type != -1) {
      std::get<2>(slices[allen_type][slice_index]) = n_frag;
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
  size_t start_event, size_t chunk_size)
{
  // Loop over all bank data of this event
  size_t bank_index = 1;
  // L0Calo doesn't exist in the upgrade
  LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;

  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto block_offset = mep_header.offsets[i_block];
    auto const& [block_header, block_data] = blocks[i_block];
    auto bank_type = static_cast<LHCb::RawBank::BankType>(block_header.types[0]);
    auto& bank_offsets = input_offsets[i_block];

    // Check what to do with this bank
    if (bank_type == LHCb::RawBank::ODIN) {
      // decode ODIN bank to obtain run and event numbers
      auto odin_version = mep_header.versions[i_block];
      for (uint16_t i_event = start_event; i_event < chunk_size; ++i_event) {
        auto odin_data = reinterpret_cast<unsigned int const*>(block_data.data() + bank_offsets[i_event]);
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

      auto bank_type_index = bank_ids[bank_type];
      auto& slice = slices[bank_type_index][slice_index];
      auto const& banks_offsets = std::get<1>(slice);
      auto const n_banks_offsets = std::get<2>(slice);

      for (size_t i_event = start_event; i_event < start_event + chunk_size && i_event < block_header.n_frag; ++i_event) {
        // Three things to write for a new set of banks:
        // - number of banks/offsets
        // - offsets to individual banks
        // - bank data

        auto preamble_words = 2 + banks_count[bank_type];

        // Initialize point to write from offset of previous set
        auto* banks_write = reinterpret_cast<uint32_t*>(std::get<0>(slice).data() + banks_offsets[i_event]);

        // Write the number of banks
        banks_write[0] = banks_count[bank_type];
        banks_write += preamble_words;

        // All bank offsets are uit32_t so cast to that type
        auto* banks_offsets_write = banks_write + 1;
        if (bank_index == 1) {
          banks_offsets_write[0] = 0;
        }

        auto bank_size = block_header.sizes[i_event];
        auto& offset = banks_offsets_write[bank_index];
        offset = banks_offsets_write[bank_index - 1] + bank_size;

        // Write sourceID
        banks_write[offset] = mep_header.source_ids[i_block];

        // Write bank data
        ::memcpy(banks_write + offset + 1, block_data.data() + bank_offsets[i_event], block_header.sizes[i_event]);
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
  std::tuple<size_t, size_t> const& interval,
  size_t chunk_size)
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

  auto to_transpose = fragment_offsets(input_offsets, slices, slice_index, bank_ids,
                                       banks_count, mep_header, blocks, interval);

  auto transpose = [&] (size_t i_event, size_t cs) {
    return transpose_event(slices, slice_index, bank_ids, banks_count, event_ids,
                           mep_header, blocks, input_offsets, i_event, cs);
  };

  size_t i_event = 0;
  size_t n_events = event_end - event_start;
  size_t rest = to_transpose % chunk_size;
  to_transpose -= rest;
  for (i_event = event_start; i_event < to_transpose; i_event += chunk_size) {
    transpose(i_event, chunk_size);
  }
  if (rest != 0) {
    transpose(i_event, rest);
    i_event += rest;
  }

  return {success, to_transpose != (event_end - event_start), i_event};
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
