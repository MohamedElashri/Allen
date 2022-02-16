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
#include <sourceid.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <Event/RawBank.h>
#include <BankTypes.h>

#include "TransposeTypes.h"

/**
 * @brief      Get the (Allen) subdetector from the bank type
 *
 * @param      raw bank
 *
 * @return     Allen subdetector
 */
BankTypes sd_from_bank_type(LHCb::RawBank const* raw_bank);

/**
 * @brief      Get the (Allen) subdetector from the 5
 *             most-significant bits of a source ID
 *
 * @param      raw bank
 *
 * @return     Allen subdetector
 */
BankTypes sd_from_sourceID(LHCb::RawBank const* raw_bank);

/**
 * @brief      Check if any of the soruce IDs have a non-zero value
 *             in the 5 most-significant bits
 *
 * @param      span with banks in MDF layout
 *
 * @return     true if any of the sourceIDs has a non-zero value in
 *             its 5 most-significant bits
 */
bool check_sourceIDs(gsl::span<char const> bank_data);

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
std::tuple<bool, std::array<unsigned int, NBankTypes>> fill_counts(
  gsl::span<char const> bank_data,
  Allen::sd_from_raw_bank sd_from_raw_bank);

/**
 * @brief      Transpose events to Allen layout
 *
 * @param      slices to fill with transposed banks, slices are addressed by bank type
 * @param      index of bank slices
 * @param      number of banks per event
 * @param      bank versions to fill
 * @param      event ids of banks in this slice
 * @param      start of bank data for this event
 *
 * @return     tuple of: (success, slice is full)
 */
std::tuple<bool, bool, bool> transpose_event(
  Allen::Slices& slices,
  int const slice_index,
  std::unordered_set<BankTypes> const& bank_types,
  Allen::sd_from_raw_bank sd_from_raw_bank,
  std::array<unsigned int, NBankTypes> const& mfp_count,
  std::array<int, NBankTypes>& banks_version,
  EventIDs& event_ids,
  std::vector<char>& event_mask,
  const gsl::span<char const> bank_data,
  bool split_by_run);

/**
 * @brief      Transpose events to Allen layout
 *
 * @param      ReadBuffer containing events to be transposed
 * @param      slices to fill with transposed banks, slices are addressed by bank type
 * @param      index of bank slices
 * @param      number of banks per event
 * @param      bank versions to fill
 * @param      event ids of banks in this slice
 * @param      number of banks per event
 * @param      number of events tor transpose
 *
 * @return     (success, slice full for one of the bank types, number of events transposed)
 */
std::tuple<bool, bool, size_t> transpose_events(
  const Allen::ReadBuffer& read_buffer,
  Allen::Slices& slices,
  int const slice_index,
  std::unordered_set<BankTypes> const& bank_types,
  Allen::sd_from_raw_bank sd_from_raw_bank,
  std::array<unsigned int, NBankTypes> const& mfp_count,
  std::array<int, NBankTypes>& banks_version,
  EventIDs& event_ids,
  std::vector<char>& event_mask,
  size_t n_events,
  bool split_by_run = false);
