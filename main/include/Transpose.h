/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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

#include <BackendCommon.h>
#include <Common.h>
#include <Logger.h>
#include <SystemOfUnits.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <Event/RawBank.h>

#include "TransposeTypes.h"

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
  bool check_checksum);

/**
 * @brief      Fill the array the contains the number of banks per type
 *
 * @details    detailed description
 *
 * @param      prefetched buffer of events (a single event is needed)
 *
 * @return     (success, number of banks per bank type; 0 if the bank is not needed)
 */
std::tuple<bool, std::array<unsigned int, LHCb::NBankTypes>> fill_counts(gsl::span<char const> bank_data);

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
std::tuple<bool, bool, bool> transpose_event(
  Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::unordered_set<BankTypes> const& to_transpose,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  const gsl::span<char const> bank_data,
  bool split_by_run);

/**
 * @brief      Reset a slice
 *
 * @param      slices
 * @param      slice_index
 * @param      event_ids
 */
template<BankTypes... Banks>
void reset_slice(Slices& slices, int const slice_index, EventIDs& event_ids, bool mep = false)
{
  // "Reset" the slice
  for (auto bank_type : {Banks...}) {
    auto ib = to_integral<BankTypes>(bank_type);
    auto& [banks, data_size, offsets, offsets_size] = slices[ib][slice_index];
    std::fill(offsets.begin(), offsets.end(), 0);
    offsets_size = 1;
    if (mep) {
      banks.clear();
      data_size = 0;
    }
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
std::tuple<bool, bool, size_t> transpose_events(
  const ReadBuffer& read_buffer,
  Slices& slices,
  int const slice_index,
  std::vector<int> const& bank_ids,
  std::unordered_set<BankTypes> const& bank_types,
  std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
  EventIDs& event_ids,
  size_t n_events,
  bool split_by_run = false);

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
