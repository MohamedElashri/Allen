/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Transpose.h>

std::vector<int> bank_ids()
{
  // Cache the mapping of LHCb::RawBank::BankType to Allen::BankType
  std::vector<int> ids;
  ids.resize(std::size(LHCb::RawBank::types()));
  for (auto bt : LHCb::RawBank::types()) {
    auto it = Allen::bank_types.find(bt);
    ids[bt] = (it != Allen::bank_types.end() ? to_integral(it->second) : -1);
  }
  return ids;
}

std::tuple<bool, bool, bool, size_t> read_events(
  Allen::IO& input,
  ReadBuffer& read_buffer,
  LHCb::MDFHeader& header,
  std::vector<char>& compress_buffer,
  size_t n_events,
  bool check_checksum)
{
  auto& [n_filled, event_offsets, buffer, transpose_start] = read_buffer;

  // Keep track of where to write and the end of the prefetch buffer
  auto* buffer_start = &buffer[0];
  size_t n_bytes = 0;
  bool eof = false, error = false, full = false;
  gsl::span<char> bank_span;

  // Loop until the requested number of events is prefetched, the
  // maximum number of events per prefetch buffer is hit, an error
  // occurs or eof is reached
  while (!eof && !error && n_filled < event_offsets.size() - 1 && n_filled < n_events) {
    // It is

    // Read the banks
    gsl::span<char> buffer_span {buffer_start + event_offsets[n_filled],
                                 static_cast<events_size>(buffer.size() - event_offsets[n_filled])};
    std::tie(eof, error, bank_span) =
      MDF::read_banks(input, header, std::move(buffer_span), compress_buffer, check_checksum);
    // Fill the start offset of the next event
    event_offsets[++n_filled] = bank_span.data() + bank_span.size() - buffer_start;
    n_bytes += bank_span.size();

    // read the next header
    ssize_t n_bytes = input.read(reinterpret_cast<char*>(&header), mdf_header_size);
    if (n_bytes != 0) {
      // Check if there is enough space to read this event
      int compress = header.compression() & 0xF;
      int expand = (header.compression() >> 4) + 1;
      int event_size =
        (header.recordSize() + mdf_header_size + 2 * (sizeof(LHCb::RawBank) + sizeof(int)) +
         (compress ? expand * (header.recordSize() - mdf_header_size) : 0));
      if (event_offsets[n_filled] + event_size > buffer.size()) {
        full = true;
        break;
      }
    }
    else if (n_bytes == 0) {
      info_cout << "Cannot read more data (Header). End-of-File reached.\n";
      eof = true;
    }
    else {
      error_cout << "Failed to read header " << strerror(errno) << "\n";
      error = true;
    }
  }
  return {eof, error, full, n_bytes};
}

std::tuple<bool, std::array<unsigned int, LHCb::NBankTypes>> fill_counts(gsl::span<char const> bank_data)
{

  std::array<unsigned int, LHCb::NBankTypes> count {0};

  auto const* bank = bank_data.data();

  // Loop over all the bank data
  while (bank < bank_data.data() + bank_data.size()) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "Magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, count};
    }

    // Check if Allen processes this bank type, count bank types that
    // are wanted
    if (b->type() < LHCb::RawBank::LastType) {
      ++count[b->type()];
    }

    // Increment overall bank pointer
    bank += b->totalSize();
  }

  return {true, count};
}

std::tuple<bool, bool, bool> transpose_event(
  Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::unordered_set<BankTypes> const& bank_types,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  std::array<int, NBankTypes>& banks_version,
  EventIDs& event_ids,
  const gsl::span<char const> bank_data,
  bool split_by_run)
{

  unsigned int* banks_offsets = nullptr;
  // Number of offsets
  size_t* n_banks_offsets = nullptr;

  // Where to write the transposed bank data
  uint32_t* banks_write = nullptr;

  // Where should offsets to individual banks be written
  uint32_t* banks_offsets_write = nullptr;

  unsigned int bank_offset = 0;
  unsigned int bank_counter = 1;

  auto bank = bank_data.data(), bank_end = bank_data.data() + bank_data.size();

  // Check if any of the per-bank-type slices potentially has too
  // little space to fit this event
  for (unsigned lhcb_type = 0; lhcb_type < bank_ids.size(); ++lhcb_type) {
    auto allen_type = bank_ids[lhcb_type];
    if (!bank_types.count(BankTypes {allen_type})) continue;

    const auto& [slice, slice_size, slice_offsets, offsets_size] = slices[allen_type][slice_index];
    // Use the event size of the next event here instead of the
    // per bank size because that's not yet known for the next
    // event
    if (
      (slice_offsets[offsets_size - 1] + (1 + banks_count[lhcb_type]) * sizeof(uint32_t) +
       static_cast<size_t>(bank_data.size())) > slice_size) {
      return {true, true, false};
    }
  }

  // L0Calo doesn't exist in the upgrade
  LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;

  // Loop over all bank data of this event
  while (bank < bank_end) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "Magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, false, false};
      // Decode the odin bank
    }

    // LHCb bank type
    auto bt = b->type();

    // Check what to do with this bank
    if (bt == LHCb::RawBank::ODIN) {
      // decode ODIN bank to obtain run and event numbers
      auto odin = MDF::decode_odin(b->version(), b->data());
      // if splitting by run, check for a run change since the last event
      if (split_by_run) {
        if (!event_ids.empty() && odin.runNumber() != std::get<0>(event_ids.front())) {
          return {true, false, true};
        }
      }
      event_ids.emplace_back(odin.runNumber(), odin.eventNumber());
    }

    auto const allen_type = bank_ids[bt];
    if (bt >= LHCb::RawBank::LastType || allen_type == -1 || !bank_types.count(BankTypes {allen_type})) {
      prev_type = bt;
      bank += b->totalSize();
      continue;
    }
    else if (bt != prev_type) {
      // Switch to new type of banks
      auto& slice = slices[allen_type][slice_index];
      prev_type = bt;

      // set bank version
      banks_version[allen_type] = b->version();

      bank_counter = 1;
      banks_offsets = std::get<2>(slice).data();
      n_banks_offsets = &std::get<3>(slice);

      // Calculate the size taken by storing the number of banks
      // and offsets to all banks within the event
      auto preamble_words = 2 + banks_count[bt];

      // Initialize offset to start of this set of banks from the
      // previous one and increment with the preamble size
      banks_offsets[*n_banks_offsets] = (banks_offsets[*n_banks_offsets - 1] + preamble_words * sizeof(uint32_t));

      // Three things to write for a new set of banks:
      // - number of banks/offsets
      // - offsets to individual banks
      // - bank data

      // Initialize point to write from offset of previous set
      banks_write = reinterpret_cast<uint32_t*>(std::get<0>(slice)[0].data() + banks_offsets[*n_banks_offsets - 1]);

      // New offset to increment
      ++(*n_banks_offsets);

      // Write the number of banks
      banks_write[0] = banks_count[bt];

      // All bank offsets are uit32_t so cast to that type
      banks_offsets_write = banks_write + 1;
      banks_offsets_write[0] = 0;

      // Offset in number of uint32_t
      bank_offset = 0;

      // Start writing bank data after the preamble
      banks_write += preamble_words;
    }
    else {
      ++bank_counter;
      assert(banks_version[allen_type] == b->version());
    }

    // Write sourceID
    banks_write[bank_offset] = b->sourceID();

    // Write bank data
    ::memcpy(banks_write + bank_offset + 1, b->data(), b->size());

    auto n_word = b->size() / sizeof(uint32_t);
    bank_offset += 1 + n_word;

    // Write next offset in bytes
    banks_offsets_write[bank_counter] = bank_offset * sizeof(uint32_t);

    // Update "event" offset (in bytes)
    banks_offsets[*n_banks_offsets - 1] += sizeof(uint32_t) * (1 + n_word);

    // Increment overall bank pointer
    bank += b->totalSize();
  }

  return {true, false, false};
}

std::tuple<bool, bool, size_t> transpose_events(
  const ReadBuffer& read_buffer,
  Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::unordered_set<BankTypes> const& bank_types,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  std::array<int, NBankTypes>& banks_version,
  EventIDs& event_ids,
  size_t n_events,
  bool split_by_run)
{

  bool full = false, success = true, run_change = false;
  auto const& [n_filled, event_offsets, buffer, event_start] = read_buffer;
  size_t event_end = event_start + n_events;
  if (n_filled < event_end) event_end = n_filled;

  // Loop over events in the prefetch buffer
  size_t i_event = event_start;
  for (; i_event < event_end && success; ++i_event) {
    // Offsets are to the start of the event, which includes the header
    auto const* bank = buffer.data() + event_offsets[i_event];
    auto const* bank_end = buffer.data() + event_offsets[i_event + 1];
    std::tie(success, full, run_change) = transpose_event(
      slices, slice_index, bank_ids, bank_types, banks_count, banks_version, event_ids, {bank, bank_end}, split_by_run);
    // break the loop if we detect a run change or the slice is full to avoid incrementing i_event
    if (run_change || full) break;
  }

  return {success, full, i_event - event_start};
}
