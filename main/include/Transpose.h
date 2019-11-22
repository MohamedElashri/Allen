#pragma once

#include <thread>
#include <vector>
#include <array>
#include <deque>
#include <mutex>
#include <atomic>
#include <chrono>
#include <algorithm>
#include <numeric>
#include <condition_variable>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <Logger.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <raw_bank.hpp>

#ifndef NO_CUDA
#include <CudaCommon.h>
#endif

namespace {
  constexpr auto header_size = sizeof(LHCb::MDFHeader);

  using namespace Allen::Units;
} // namespace

// Read buffer containing the number of events, offsets to the start
// of the event, the event data and event from which trasposition should start
using ReadBuffer = std::tuple<size_t, std::vector<unsigned int>, std::vector<char>, size_t>;
using ReadBuffers = std::vector<ReadBuffer>;

// A slice contains transposed bank data, offsets to the start of each
// set of banks and the number of sets of banks
using Slice = std::tuple<gsl::span<char>, gsl::span<unsigned int>, size_t>;
using BankSlices = std::vector<Slice>;
using Slices = std::array<BankSlices, NBankTypes>;

//
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
std::tuple<bool, bool, bool, size_t> read_events(
  Allen::IO& input,
  ReadBuffer& read_buffer,
  LHCb::MDFHeader& header,
  std::vector<char> compress_buffer,
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
    gsl::span<char> buffer_span {buffer_start + event_offsets[n_filled], buffer.size() - event_offsets[n_filled]};
    std::tie(eof, error, bank_span) =
      MDF::read_banks(input, header, std::move(buffer_span), compress_buffer, check_checksum);
    // Fill the start offset of the next event
    event_offsets[++n_filled] = bank_span.end() - buffer_start;
    n_bytes += bank_span.size();

    // read the next header
    ssize_t n_bytes = input.read(reinterpret_cast<char*>(&header), header_size);
    if (n_bytes != 0) {
      // Check if there is enough space to read this event
      int compress = header.compression() & 0xF;
      int expand = (header.compression() >> 4) + 1;
      int event_size =
        (header.recordSize() + header_size + 2 * (sizeof(LHCb::RawBank) + sizeof(int)) +
         (compress ? expand * (header.recordSize() - header_size) : 0));
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

/**
 * @brief      Fill the array the contains the number of banks per type
 *
 * @details    detailed description
 *
 * @param      prefetched buffer of events (a single event is needed)
 *
 * @return     (success, number of banks per bank type; 0 if the bank is not needed)
 */
std::tuple<bool, std::array<unsigned int, NBankTypes>> fill_counts(gsl::span<char const> bank_data)
{

  std::array<unsigned int, NBankTypes> count {0};

  auto const* bank = bank_data.data();

  // Loop over all the bank data
  while (bank < bank_data.end()) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "Magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, count};
    }

    // Check if Allen processes this bank type, count bank types that
    // are wanted
    auto bank_type_it = Allen::bank_types.find(b->type());
    if (bank_type_it != Allen::bank_types.end()) {
      auto bank_type_index = to_integral(bank_type_it->second);
      ++count[bank_type_index];
    }

    // Increment overall bank pointer
    bank += b->totalSize();
  }

  return {true, count};
}

/**
 * @brief      Transpose events to Allen layout
 *
 * @param      slices to fill with transposed banks, slices are addressed by bank type
 * @param      index of bank slices
 * @param      number of banks per event
 * @param      event ids of banks in this slice
 * @param      start of bank data for this event
 *
 * @return     tuple of: (success, slice is full)
 */
template<BankTypes... Banks>
std::tuple<bool, bool> transpose_event(
  Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, NBankTypes> const& banks_count,
  EventIDs& event_ids,
  const gsl::span<char const> bank_data)
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
  unsigned int bank_type_index = 0;

  auto bank = bank_data.begin(), bank_end = bank_data.end();

  // L0Calo doesn't exist in the upgrade
  LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;

  // Loop over all bank data of this event
  while (bank < bank_end) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "Magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, false};
      // Decode the odin bank
    }

    // Check what to do with this bank
    auto bt = b->type();
    if (bt == LHCb::RawBank::ODIN) {
      // decode ODIN bank to obtain run and event numbers
      auto odin = MDF::decode_odin(b);
      event_ids.emplace_back(odin.run_number, odin.event_number);
      bank += b->totalSize();
      continue;
    }
    else if (bt >= LHCb::RawBank::LastType || bank_ids[bt] == -1) {
      // This bank is not required: skip it
      bank += b->totalSize();
      continue;
    }
    else if (bt != prev_type) {
      // Switch to new type of banks
      bank_type_index = bank_ids[b->type()];
      auto& slice = slices[bank_type_index][slice_index];
      prev_type = bt;

      bank_counter = 1;
      banks_offsets = std::get<1>(slice).data();
      n_banks_offsets = &std::get<2>(slice);

      // Calculate the size taken by storing the number of banks
      // and offsets to all banks within the event
      auto preamble_words = 2 + banks_count[bank_type_index];

      // Initialize offset to start of this set of banks from the
      // previous one and increment with the preamble size
      banks_offsets[*n_banks_offsets] = (banks_offsets[*n_banks_offsets - 1] + preamble_words * sizeof(uint32_t));

      // Three things to write for a new set of banks:
      // - number of banks/offsets
      // - offsets to individual banks
      // - bank data

      // Initialize point to write from offset of previous set
      banks_write = reinterpret_cast<uint32_t*>(std::get<0>(slice).data() + banks_offsets[*n_banks_offsets - 1]);

      // New offset to increment
      ++(*n_banks_offsets);

      // Write the number of banks
      banks_write[0] = banks_count[bank_type_index];

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

  // Check if any of the per-bank-type slices potentially has too
  // little space to fit the next event
  for (auto bank_type : {Banks...}) {
    auto ib = to_integral<BankTypes>(bank_type);
    const auto& [slice, slice_offsets, offsets_size] = slices[ib][slice_index];
    // Use the event size of the next event here instead of the
    // per bank size because that's not yet known for the next
    // event
    if ((slice_offsets[offsets_size - 1] + bank_data.size()) > slice.size()) {
      return {true, true};
    }
  }
  return {true, false};
}

/**
 * @brief      Reset a slice
 *
 * @param      slices
 * @param      slice_index
 * @param      event_ids
 */
template<BankTypes... Banks>
void reset_slice(Slices& slices, int const slice_index, EventIDs& event_ids)
{
  // "Reset" the slice
  for (auto bank_type : {Banks...}) {
    auto ib = to_integral<BankTypes>(bank_type);
    std::get<1>(slices[ib][slice_index])[0] = 0;
    std::get<2>(slices[ib][slice_index]) = 1;
  }
  event_ids.clear();
}

/**
 * @brief      Transpose events to Allen layout
 *
 * @param      ReadBuffer containing events to be transposed
 * @param      slices to fill with transposed banks, slices are addressed by bank type
 * @param      index of bank slices
 * @param      event ids of banks in this slice
 * @param      number of banks per event
 * @param      number of events to transpose
 *
 * @return     (success, slice full for one of the bank types, number of events transposed)
 */
template<BankTypes... Banks>
std::tuple<bool, bool, size_t> transpose_events(
  const ReadBuffer& read_buffer,
  Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::array<unsigned int, NBankTypes> const& banks_count,
  EventIDs& event_ids,
  size_t n_events)
{

  bool full = false, success = true;
  auto const& [n_filled, event_offsets, buffer, event_start] = read_buffer;

  // Loop over events in the prefetch buffer
  size_t i_event = event_start;
  for (; i_event < n_filled && i_event < n_events && success && !full; ++i_event) {
    // Offsets are to the start of the event, which includes the header
    auto const* bank = buffer.data() + event_offsets[i_event];
    auto const* bank_end = buffer.data() + event_offsets[i_event + 1];
    std::tie(success, full) =
      transpose_event<Banks...>(slices, slice_index, bank_ids, banks_count, event_ids, {bank, bank_end});
  }

  return {success, full, i_event};
}

template<BankTypes... Banks>
Slices allocate_slices(size_t n_slices, std::function<std::tuple<size_t, size_t>(BankTypes)> size_fun)
{
  Slices slices;
  for (auto bank_type : {Banks...}) {
    auto [n_bytes, n_offsets] = size_fun(bank_type);
    auto ib = to_integral<BankTypes>(bank_type);
    auto& bank_slices = slices[ib];
    bank_slices.reserve(n_slices);
    for (size_t i = 0; i < n_slices; ++i) {
      char* events_mem = nullptr;
      uint* offsets_mem = nullptr;

#ifndef NO_CUDA
      if (n_bytes) cudaCheck(cudaMallocHost((void**) &events_mem, n_bytes));
      if (n_offsets) cudaCheck(cudaMallocHost((void**) &offsets_mem, (n_offsets + 1) * sizeof(uint)));
#else
      if (n_bytes) events_mem = static_cast<char*>(malloc(n_bytes));
      if (n_offsets) offsets_mem = static_cast<uint*>(malloc((n_offsets + 1) * sizeof(uint)));
#endif
      for (size_t i = 0; i < n_offsets + 1; ++i) {
        offsets_mem[i] = 0;
      }
      bank_slices.emplace_back(gsl::span<char> {events_mem, n_bytes}, gsl::span<uint> {offsets_mem, n_offsets + 1}, 1);
    }
  }
  return slices;
}
