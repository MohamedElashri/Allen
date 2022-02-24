/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Transpose.h>

std::array<int, LHCb::NBankTypes> Allen::bank_ids()
{
  // Cache the mapping of LHCb::RawBank::BankType to Allen::BankType
  std::array<int, LHCb::NBankTypes> ids;
  for (auto bt : LHCb::RawBank::types()) {
    auto it = Allen::bank_types.find(bt);
    ids[bt] = (it != Allen::bank_types.end() ? to_integral(it->second) : -1);
  }
  return ids;
}

/**
 * @brief      Check if any of the soruce IDs have a non-zero value
 *             in the 5 most-significant bits
 *
 * @param      span with banks in MDF layout
 *
 * @return     true if any of the sourceIDs has a non-zero value in
 *             its 5 most-significant bits
 */
bool check_sourceIDs(gsl::span<char const> bank_data)
{

  auto const* bank = bank_data.data();

  // Loop over all the banks and check if any of the sourceIDs has
  // the most-significant bits set. In MC data they are not set.
  bool is_mc = true;
  while (bank < bank_data.data() + bank_data.size()) {

    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->type() != LHCb::RawBank::DAQ) {
      is_mc &= (SourceId_sys(static_cast<short>(b->sourceID())) == 0);
    }

    // Increment overall bank pointer
    bank += b->totalSize();
  }
  return is_mc;
}

/**
 * @brief      Get the (Allen) subdetector from the bank type
 *
 * @param      raw bank
 *
 * @return     Allen subdetector
 */
BankTypes sd_from_bank_type(LHCb::RawBank const* raw_bank)
{
  static auto const bank_ids = Allen::bank_ids();
  auto const bt = bank_ids[raw_bank->type()];
  return bt == -1 ? BankTypes::Unknown : static_cast<BankTypes>(bt);
}

/**
 * @brief      Get the (Allen) subdetector from the 5
 *             most-significant bits of a source ID
 *
 * @param      raw bank
 *
 * @return     Allen subdetector
 */
BankTypes sd_from_sourceID(LHCb::RawBank const* raw_bank)
{
  auto sd = SourceId_sys(raw_bank->sourceID());
  auto it = Allen::subdetectors.find(static_cast<SourceIdSys>(sd));
  auto source_type = (it == Allen::subdetectors.end()) ? BankTypes::Unknown : it->second;
  if (source_type == BankTypes::ODIN && raw_bank->type() == LHCb::RawBank::DAQ) {
    return BankTypes::Unknown;
  }
  else {
    return source_type;
  }
}


/**
 * @brief      read events from input file into prefetch buffer
 *
 * @details    NOTE: It is assumed that the header has already been
 *             read, calling read_events will read the subsequent
 *             banks and then header of the next event.
 *
 * @param      input stream
 * @param      prefetch buffer to read into
 * @param      storage for the MDF header
 * @param      buffer for temporary storage of the compressed banks
 * @param      number of events to read
 * @param      check the MDF checksum if it is available
 *
 * @return     (eof, error, full, n_bytes)
 */
std::tuple<bool, bool, size_t> read_events(
  Allen::IO& input,
  Allen::ReadBuffer& read_buffer,
  LHCb::MDFHeader& header,
  std::vector<char>& compress_buffer,
  size_t n_events,
  bool check_checksum)
{
  auto& [n_filled, event_offsets, buffer, transpose_start] = read_buffer;

  // Keep track of where to write and the end of the prefetch buffer
  size_t n_bytes = 0;
  bool eof = false, error = false;
  gsl::span<char> bank_span;

  // Loop until the requested number of events is prefetched, the
  // maximum number of events per prefetch buffer is hit, an error
  // occurs or eof is reached
  while (!eof && !error && n_filled < event_offsets.size() - 1 && n_filled < n_events) {
    auto* buffer_start = &buffer[0];

    // Read the banks
    auto const buffer_offset = event_offsets[n_filled];
    assert(buffer_offset < buffer.size());
    gsl::span<char> buffer_span {buffer_start + buffer_offset, static_cast<events_size>(buffer.size() - buffer_offset)};
    std::tie(eof, error, bank_span) =
      MDF::read_banks(input, header, std::move(buffer_span), compress_buffer, check_checksum);
    // Fill the start offset of the next event

    if (eof || error) {
      error_cout << "Failed to read banks " << strerror(errno) << "\n";
      break;
    }
    else {
      event_offsets[n_filled + 1] = bank_span.data() + bank_span.size() - buffer_start;
      n_bytes += bank_span.size();
    }

    // read the next header
    ssize_t n_bytes = input.read(reinterpret_cast<char*>(&header), mdf_header_size);
    if (n_bytes != 0) {
      // Check if there is enough space to read this event
      int compress = header.compression() & 0xF;
      int expand = (header.compression() >> 4) + 1;
      int event_size =
        (header.recordSize() + mdf_header_size + 2 * (sizeof(LHCb::RawBank) + sizeof(int)) +
         (compress ? expand * (header.recordSize() - mdf_header_size) : 0));
      if (event_offsets[n_filled + 1] + event_size > buffer.size()) {
        buffer.resize(static_cast<size_t>(1.5 * buffer.size()));
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
    if (!eof && !error) {
      ++n_filled;
    }
  }
  return {eof, error, n_bytes};
}

/**
 * @brief      Fill the array the contains the number of banks per type
 *
 * @details    detailed description
 *
 * @param      prefetched buffer of events (a single event is needed)
 *
 * @return     (success, number of banks per bank type; 0 if the bank is not needed)
 */
std::tuple<bool, std::array<unsigned int, NBankTypes>> fill_counts(
  gsl::span<char const> bank_data,
  Allen::sd_from_raw_bank sd_from_raw_bank)
{

  std::array<unsigned int, NBankTypes> mfp_count {0};

  auto const* bank = bank_data.data();

  // Loop over all the bank data
  while (bank < bank_data.data() + bank_data.size()) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "Magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, mfp_count};
    }

    auto const sd_idx = to_integral(sd_from_raw_bank(b));
    ++mfp_count[sd_idx];

    // Increment overall bank pointer
    bank += b->totalSize();
  }

  return {true, mfp_count};
}

std::tuple<bool, bool, bool> transpose_event(
  Allen::Slices& slices,
  int const slice_index,
  std::unordered_set<BankTypes> const& bank_types,
  Allen::sd_from_raw_bank sd_from_raw_bank,
  Allen::bank_sorter bank_sort,
  std::array<unsigned int, NBankTypes>& bank_count,
  std::array<int, NBankTypes>& banks_version,
  EventIDs& event_ids,
  std::vector<char>& event_mask,
  const gsl::span<char const> bank_data,
  std::vector<LHCb::RawBank const*>& sorted_banks,
  bool split_by_run)
{

  unsigned int* banks_offsets = nullptr;
  // Number of offsets
  size_t* n_banks_offsets = nullptr;

  // Where to write the transposed bank data
  uint32_t* banks_write = nullptr;

  // Where should offsets to individual banks be written
  uint32_t* banks_offsets_write = nullptr;

  // Memory where bank sizes are kept. The first N entries are offsets to the sizes per event
  uint16_t* fragment_sizes = nullptr;

  unsigned int bank_offset = 0;
  unsigned int bank_counter = 1;

  std::array<unsigned int, NBankTypes> size_per_type;
  size_per_type.fill(2 * sizeof(unsigned int));

  auto bank = bank_data.data(), bank_end = bank_data.data() + bank_data.size();

  while (bank < bank_end) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "Magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, false, false};
      // Decode the odin bank
    }

    // Allen bank type
    auto const allen_type = sd_from_raw_bank(b);

    if (bank_types.count(allen_type) || allen_type == BankTypes::ODIN) {
      sorted_banks.push_back(b);
      bank_count[to_integral(allen_type)] += 1;
      size_per_type[to_integral(allen_type)] += sizeof(unsigned int) + b->size();
    }
    bank += b->totalSize();
  }
  std::stable_sort(sorted_banks.begin(), sorted_banks.end(), bank_sort);

  // Check if any of the per-bank-type slices potentially has too
  // little space to fit this event
  for (auto allen_type : bank_types) {
    auto const ia = to_integral(allen_type);
    const auto& [slice, fragment_sizes, slice_size, slice_offsets, offsets_size] = slices[ia][slice_index];
    if ((slice_offsets[offsets_size - 1] + size_per_type[ia]) > slice_size) {
      return {true, true, false};
    }
  }

  BankTypes prev_type = BankTypes::Unknown;

  // Loop over all bank data of this event
  for (auto const* b : sorted_banks) {

    // Allen bank type
    auto const allen_type = sd_from_raw_bank(b);

    // Check what to do with this bank
    if (allen_type == BankTypes::ODIN) {
      auto const odin_error = b->type() >= LHCb::RawBank::DaqErrorFragmentThrottled;
      event_mask[event_ids.size()] = !odin_error;

      if (!odin_error) {
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
      else {
        event_ids.emplace_back(0, 0);
      }
    }

    if (!bank_types.count(allen_type)) {
      prev_type = allen_type;
      continue;
    }
    else if (allen_type != prev_type) {
      // Switch to new type of banks
      auto& slice = slices[to_integral(allen_type)][slice_index];
      prev_type = allen_type;

      // set bank version
      banks_version[to_integral(allen_type)] = b->version();

      // Reset bank count
      bank_counter = 1;
      banks_offsets = std::get<3>(slice).data();
      n_banks_offsets = &std::get<4>(slice);

      // Calculate the size taken by storing the number of banks
      // and offsets to all banks within the event
      auto preamble_words = 2 + bank_count[to_integral(allen_type)];

      // Initialize offset to start of this set of banks from the
      // previous one and increment with the preamble size
      banks_offsets[*n_banks_offsets] = (banks_offsets[*n_banks_offsets - 1] + preamble_words * sizeof(uint32_t));

      // Five things to write for a new set of banks:
      // - number of banks/offsets
      // - offsets to individual banks
      // - bank data
      // - offset to the start of the bank sizes
      // - the bank size

      // The offsets to the sizes for this batch of fragments is
      // copied from the current value
      fragment_sizes = std::get<1>(slice)[0].data();
      fragment_sizes_offset = fragment_sizes[*n_banks_offsets] + bank_counter - 1;
      fragment_sizes[*n_banks_offsets + 1] = fragment_sizes_offset;
      fragment_sizes += fragment_offset;

      // Size write pointer is initialiazed from the offset
      sizes_write = sizes_data + *n_sizes_write;

      // Initialize point to write from offset of previous set
      banks_write = reinterpret_cast<uint32_t*>(std::get<0>(slice)[0].data() + banks_offsets[*n_banks_offsets - 1]);

      // New offset to increment
      ++(*n_banks_offsets);

      // Write the number of banks
      banks_write[0] = bank_count[to_integral(allen_type)];

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
      assert(banks_version[to_integral(allen_type)] == b->version());
    }

    // Write sourceID
    banks_write[bank_offset] = b->sourceID();

    // Store bank size
    fragment_sizes[bank_counter - 1] = b->size();

    // Copy padded data
    auto const padded_size = b->totalSize() - b->hdrSize();
    // Write bank data
    ::memcpy(banks_write + bank_offset + 1, b->data(), padded_size);

    auto n_word = padded_size / sizeof(uint32_t);
    bank_offset += 1 + n_word;

    // Write next offset in bytes
    banks_offsets_write[bank_counter] = bank_offset * sizeof(uint32_t);

    // Update "event" offset (in bytes)
    banks_offsets[*n_banks_offsets - 1] += sizeof(uint32_t) * (1 + n_word);
  }

  return {true, false, false};
}

/**
 * @brief      Reset a slice
 *
 * @param      slices
 * @param      slice_index
 * @param      event_ids
 */

void reset_slice(
  Allen::Slices& slices,
  int const slice_index,
  std::unordered_set<BankTypes> const& bank_types,
  EventIDs& event_ids,
  bool mep);

std::tuple<bool, bool, size_t> transpose_events(
  const Allen::ReadBuffer& read_buffer,
  Allen::Slices& slices,
  int const slice_index,
  std::unordered_set<BankTypes> const& bank_types,
  Allen::sd_from_raw_bank sd_from_raw_bank,
  Allen::bank_sorter bank_sort,
  std::array<unsigned int, NBankTypes> const& mfp_count,
  std::array<int, NBankTypes>& banks_version,
  EventIDs& event_ids,
  std::vector<char>& event_mask,
  size_t n_events,
  bool split_by_run)
{
  bool full = false, success = true, run_change = false;
  auto const& [n_filled, event_offsets, buffer, event_start] = read_buffer;
  size_t event_end = event_start + n_events;
  if (n_filled < event_end) event_end = n_filled;

  std::vector<LHCb::RawBank const*> sorted_banks;
  auto n_banks = std::accumulate(mfp_count.begin(), mfp_count.end(), 0u);
  sorted_banks.reserve(n_banks);

  std::array<unsigned int, NBankTypes> bank_count;
  bank_count.fill(0);

  // Loop over events in the prefetch buffer
  size_t i_event = event_start;
  for (; i_event < event_end && success; ++i_event) {
    // Offsets are to the start of the event, which includes the header
    auto const* bank = buffer.data() + event_offsets[i_event];
    auto const* bank_end = buffer.data() + event_offsets[i_event + 1];
    std::tie(success, full, run_change) = transpose_event(
      slices,
      slice_index,
      bank_types,
      sd_from_raw_bank,
      bank_sort,
      bank_count,
      banks_version,
      event_ids,
      event_mask,
      {bank, bank_end},
      sorted_banks,
      split_by_run);

    sorted_banks.clear();
    bank_count.fill(0);

    // break the loop if we detect a run change or the slice is full to avoid incrementing i_event
    if (run_change || full) break;
  }

  return {success, full, i_event - event_start};
}

Allen::Slices allocate_slices(
  size_t n_slices,
  std::function<std::tuple<size_t, size_t>(BankTypes)> size_fun,
  std::unordered_set<BankTypes> const& bank_types)
{
  Allen::Slices slices;
  for (auto bank_type : bank_types) {
    auto [n_bytes, n_offsets] = size_fun(bank_type);

    auto ib = to_integral<BankTypes>(bank_type);
    auto& bank_slices = slices[ib];
    bank_slices.reserve(n_slices);
    for (size_t i = 0; i < n_slices; ++i) {
      char* events_mem = nullptr;
      unsigned* offsets_mem = nullptr;

      if (n_bytes) Allen::malloc_host((void**) &events_mem, n_bytes);
      if (n_offsets) Allen::malloc_host((void**) &offsets_mem, (n_offsets + 1) * sizeof(unsigned));

      for (size_t i = 0; i < n_offsets + 1; ++i) {
        offsets_mem[i] = 0;
      }
      std::vector<gsl::span<char>> spans {};
      if (n_bytes) {
        spans.emplace_back(events_mem, n_bytes);
      }
      bank_slices.emplace_back(
        std::move(spans), n_bytes, offsets_span {offsets_mem, static_cast<offsets_size>(n_offsets + 1)}, 1);
    }
  }
  return slices;
}
