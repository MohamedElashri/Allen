#include <cassert>
#include <cstring>
#include <TransposeMEP.h>

std::tuple<bool, std::array<unsigned int, LHCb::NBankTypes>> MEP::fill_counts(
  EB::Header const& header,
  gsl::span<char const> const& mep_span)
{
  // info_cout << "EB header: "
  //   << header.n_blocks << ", "
  //   << header.packing_factor << ", "
  //   << header.reserved << ", "
  //   << header.mep_size << "\n";

  auto header_size = +header.header_size(header.n_blocks);
  gsl::span<char const> block_span {mep_span.data() + header_size, mep_span.size() - header_size};
  std::array<unsigned int, LHCb::NBankTypes> count {0};
  for (size_t i = 0; i < header.n_blocks; ++i) {
    auto offset = header.offsets[i];
    EB::BlockHeader bh {block_span.data() + offset};

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

void MEP::find_blocks(EB::Header const& mep_header, gsl::span<char const> const& buffer_span, Blocks& blocks)
{

  // Fill blocks
  auto hdr_size = mep_header.header_size(mep_header.n_blocks);
  auto block_hdr_size = EB::BlockHeader::header_size(mep_header.packing_factor);
  gsl::span<char const> const mep_data {buffer_span.data() + hdr_size, buffer_span.size() - hdr_size};

  for (size_t i_block = 0; i_block < mep_header.n_blocks; ++i_block) {
    auto block_offset = mep_header.offsets[i_block];
    EB::BlockHeader block_header {mep_data.data() + block_offset};
    gsl::span<char const> block_data {mep_data.data() + block_offset + block_hdr_size, block_header.block_size};
    blocks[i_block] = std::tuple {std::move(block_header), std::move(block_data)};
  }
}

void MEP::fragment_offsets(MEP::Blocks const& blocks, MEP::SourceOffsets& offsets)
{

  // Reset input offsets
  for (auto& o : offsets) {
    std::fill(o.begin(), o.end(), 0);
  }

  // Loop over all bank sizes in all blocks
  for (size_t i_block = 0; i_block < blocks.size(); ++i_block) {
    auto const& [block_header, block_data] = blocks[i_block];
    auto& o = offsets[i_block];
    uint32_t fragment_offset = 0;

    for (size_t i = 0; i < block_header.n_frag; ++i) {
      o[i] = fragment_offset;
      fragment_offset += block_header.sizes[i];
    }
  }
}

size_t MEP::allen_offsets(
  ::Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EB::Header const& mep_header,
  MEP::Blocks const& blocks,
  MEP::SourceOffsets const& input_offsets,
  std::tuple<size_t, size_t> const& interval,
  bool split_by_run)
{

  auto [event_start, event_end] = interval;

  // First check for run changes in ODIN banks
  if (split_by_run) {
    for (size_t i_block = 0; i_block < blocks.size(); ++i_block) {
      auto const& [block_header, block_data] = blocks[i_block];
      auto lhcb_type = block_header.types[0];
      if (lhcb_type == LHCb::RawBank::ODIN) {
        auto& source_offsets = input_offsets[i_block];
        uint run_number = 0;
        for (size_t i = event_start; i < event_end; ++i) {
          // decode ODIN banks to check for run changes
          auto odin_version = mep_header.versions[i_block];
          auto odin_data = reinterpret_cast<unsigned int const*>(block_data.data() + source_offsets[i]);
          auto odin = MDF::decode_odin(odin_version, odin_data);
          // if splitting by run, check all events have same run number
          if (i == event_start) {
            run_number = odin.run_number;
          }
          else if (odin.run_number != run_number) {
            event_end = i;
          }
        }
      }
    }
  }

  // Loop over all bank sizes in all blocks
  for (size_t i_block = 0; i_block < blocks.size(); ++i_block) {
    auto const& [block_header, block_data] = blocks[i_block];
    auto lhcb_type = block_header.types[0];
    auto allen_type = bank_ids[lhcb_type];
    if (allen_type != -1) {
      for (size_t i = event_start; i < event_end; ++i) {
        // Anticipate offset structure already here, i.e. don't assign to the first one
        auto idx = i - event_start + 1;
        auto& event_offsets = std::get<2>(slices[allen_type][slice_index]);

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
      auto& [slice, slice_size, event_offsets, offsets_size] = slices[allen_type][slice_index];
      event_offsets[0] = 0;
      auto preamble_words = 2 + banks_count[lhcb_type];
      for (size_t i = 1; i <= (event_end - event_start) && i <= n_frag; ++i) {

        // Allen raw bank format has the number of banks and the bank
        // offsets in a preamble
        event_offsets[i] += preamble_words * sizeof(uint32_t) + event_offsets[i - 1];

        // Check for sufficient space
        if (event_offsets[i] > slice_size) {
          n_frag = i - 1;
          break;
        }
      }
    }
  }

  // Set offsets_size here to make sure it's consistent with the max
  for (size_t lhcb_type = 0; lhcb_type < bank_ids.size(); ++lhcb_type) {
    auto allen_type = bank_ids[lhcb_type];
    if (allen_type != -1) {
      auto& offsets_size = std::get<3>(slices[allen_type][slice_index]);
      offsets_size = n_frag + 1;
    }
  }
  return n_frag;
}

std::tuple<bool, bool, size_t> MEP::mep_offsets(
  ::Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  EB::Header const& mep_header,
  MEP::Blocks const& blocks,
  std::tuple<size_t, size_t> const& interval,
  bool split_by_run)
{

  auto [event_start, event_end] = interval;

  unsigned char prev_type = 0;
  size_t offset_index = 0;
  uint run_number = 0;
  for (size_t i_block = 0; i_block < blocks.size(); ++i_block) {
    auto const& [block_header, block_data] = blocks[i_block];
    auto lhcb_type = block_header.types[0];
    auto allen_type = bank_ids[lhcb_type];
    auto n_blocks = banks_count[lhcb_type];

    // Decode ODIN banks
    if (lhcb_type == LHCb::RawBank::ODIN) {
      // decode ODIN bank to obtain run and event numbers
      auto odin_version = mep_header.versions[i_block];
      uint fragment_offset = 0;
      for (uint i_event = 0; i_event < event_end; ++i_event) {
        if (i_event >= event_start) {
          auto odin_data = reinterpret_cast<unsigned int const*>(block_data.data() + fragment_offset);
          auto odin = MDF::decode_odin(odin_version, odin_data);
          // if splitting by run, check all events have same run number
          if (i_event == event_start) {
            run_number = odin.run_number;
          }
          else if (split_by_run && odin.run_number != run_number) {
            event_end = i_event;
            break;
          }
          event_ids.emplace_back(odin.run_number, odin.event_number);
        }
        fragment_offset += block_header.sizes[i_event];
      }
    }

    if (allen_type != -1) {
      auto& [spans, data_size, event_offsets, offsets_size] = slices[allen_type][slice_index];

      // Calculate block offset and size
      size_t interval_offset = 0, interval_size = 0;
      for (size_t i = 0; i < event_start; ++i) {
        interval_offset += block_header.sizes[i];
      }
      for (size_t i = event_start; i < event_end; ++i) {
        interval_size += block_header.sizes[i];
      }

      // Calculate offsets
      if (lhcb_type != prev_type) {
        event_offsets[0] = banks_count[lhcb_type];
        event_offsets[1] = event_end - event_start;
        event_offsets[2 + n_blocks] = 0;
        offset_index = 0;
        prev_type = lhcb_type;
      }

      // Store source ID
      event_offsets[2 + offset_index] = mep_header.source_ids[i_block];

      // Initialize the first offsets using the block sizes,
      if (offset_index < banks_count[lhcb_type] - 1) {
        event_offsets[2 + n_blocks + offset_index + 1] = event_offsets[2 + n_blocks + offset_index] + interval_size;
      }

      // Fill fragment offsets
      size_t oi = 0, idx = 0;
      for (size_t i = event_start; i < event_end; ++i) {
        idx = i - event_start + 1;
        oi = 2 + n_blocks * (1 + idx) + offset_index;
        event_offsets[oi] = event_offsets[oi - n_blocks] + block_header.sizes[i];
      }
      // Update offsets_size
      offsets_size = oi;

      // Store block span for this interval
      spans.emplace_back(const_cast<char*>(block_data.data()) + interval_offset, interval_size);
      data_size += interval_size;

      ++offset_index;
    }
  }
  return {true, false, event_end - event_start};
}

bool MEP::transpose_event(
  ::Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  EB::Header const& mep_header,
  MEP::Blocks const& blocks,
  MEP::SourceOffsets const& input_offsets,
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

    if (bank_type >= LHCb::RawBank::LastType || bank_ids[bank_type] == -1) {
      prev_type = bank_type;
    }
    else {
      if (bank_type != prev_type) {
        bank_index = 1;
        prev_type = bank_type;
      }

      auto allen_type = bank_ids[bank_type];
      auto& slice = std::get<0>(slices[allen_type][slice_index])[0];
      auto const& event_offsets = std::get<2>(slices[allen_type][slice_index]);

      for (size_t i_event = start_event; i_event < end_event && i_event < block_header.n_frag; ++i_event) {
        // Three things to write for a new set of banks:
        // - number of banks/offsets
        // - offsets to individual banks
        // - bank data

        auto preamble_words = 2 + banks_count[bank_type];

        // Initialize point to write from offset of previous set
        // All bank offsets are uit32_t so cast to that type
        auto* banks_write = reinterpret_cast<uint32_t*>(slice.data() + event_offsets[i_event - start_event]);

        // Where to write the offsets
        auto* banks_offsets_write = banks_write + 1;

        if (bank_index == 1) {
          // Write the number of banks
          banks_write[0] = banks_count[bank_type];
          banks_offsets_write[0] = 0;
        }

        // get offset for this bank and store offset for next bank
        auto offset = banks_offsets_write[bank_index - 1];
        auto frag_size = block_header.sizes[i_event];
        banks_offsets_write[bank_index] = offset + frag_size + sizeof(uint32_t);

        // Where to write the bank data itself
        banks_write += preamble_words;

        // Write sourceID; offset in 32bit words
        auto word_offset = offset / sizeof(uint32_t);
        banks_write[word_offset] = mep_header.source_ids[i_block];

        // Write bank data
        std::memcpy(banks_write + word_offset + 1, block_data.data() + source_offsets[i_event], frag_size);
      }

      ++bank_index;
    }
  }
  return true;
}

std::tuple<bool, bool, size_t> MEP::transpose_events(
  ::Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  EB::Header const& mep_header,
  MEP::Blocks const& blocks,
  MEP::SourceOffsets const& source_offsets,
  std::tuple<size_t, size_t> const& interval,
  bool split_by_run)
{
  auto [event_start, event_end] = interval;

  bool success = true;

  auto to_transpose = allen_offsets(
    slices, slice_index, bank_ids, banks_count, mep_header, blocks, source_offsets, interval, split_by_run);

  transpose_event(
    slices,
    slice_index,
    bank_ids,
    banks_count,
    event_ids,
    mep_header,
    blocks,
    source_offsets,
    {event_start, event_start + to_transpose});

  return {success, to_transpose != (event_end - event_start), to_transpose};
}

std::vector<int> bank_ids()
{
  // Cache the mapping of LHCb::RawBank::BankType to Allen::BankType
  std::vector<int> ids;
  ids.resize(LHCb::RawBank::LastType);
  for (int bt = LHCb::RawBank::L0Calo; bt < LHCb::RawBank::LastType; ++bt) {
    auto it = Allen::bank_types.find(static_cast<LHCb::RawBank::BankType>(bt));
    if (it != Allen::bank_types.end()) {
      ids[bt] = to_integral(it->second);
    }
    else {
      ids[bt] = -1;
    }
  }
  return ids;
}
