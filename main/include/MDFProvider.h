/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
#include <optional>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <Logger.h>
#include <InputProvider.h>
#include <mdf_header.hpp>
#include <sourceid.h>
#include <read_mdf.hpp>
#include <write_mdf.hpp>
#include <Event/RawBank.h>
#include "BankMapping.h"

#include <SliceUtils.h>
#include <Transpose.h>
#include <ODINBank.cuh>

#include <BackendCommon.h>

namespace {
  using namespace Allen::Units;

  using namespace std::string_literals;
} // namespace

/**
 * @brief      Configuration parameters for the MDFProvider
 *
 */
struct MDFProviderConfig {
  // check the MDF checksum if it is available
  bool check_checksum = false;

  // number of transpose threads
  size_t n_transpose_threads = 5;

  // maximum number of events per slice
  size_t offsets_size = 10001;

  // default of events per prefetch buffer
  size_t events_per_buffer = 1200;

  // number of loops over input data
  size_t n_loops = 0;

  bool split_by_run = false;

  std::unordered_set<LHCb::RawBank::BankType> skip_banks;
};

/**
 * @brief      Provide transposed events from MDF files
 *
 * @details    The provider has three main components
 *             - a prefetch thread to read from the current input
 *               file into prefetch buffers
 *             - N transpose threads that read from prefetch buffers
 *               and fill the per-bank-type slices with transposed sets
 *               of banks and the offsets to individual bank inside a
 *               given set
 *             - functions to obtain a transposed slice and declare it
 *               for refilling
 *
 *             Access to prefetch buffers and slices is synchronised
 *             using mutexes and condition variables.
 *
 * @param      Number of slices to fill
 * @param      Number of events per slice
 * @param      MDF filenames
 * @param      Configuration struct
 *
 */
// template<BankTypes... Banks>
// class MDFProvider final : public InputProvider<MDFProvider<Banks...>> {
class MDFProvider final : public InputProvider {
public:
  MDFProvider(
    size_t n_slices,
    size_t events_per_slice,
    std::optional<size_t> n_events,
    std::vector<std::string> connections,
    std::unordered_set<BankTypes> const& bank_types,
    MDFProviderConfig config);

  /// Destructor
  virtual ~MDFProvider();

  bool release_buffers() override;

  /**
   * @brief      Obtain event IDs of events stored in a given slice
   *
   * @param      slice index
   *
   * @return     EventIDs of events in given slice
   */
  EventIDs event_ids(size_t slice_index, std::optional<size_t> first = {}, std::optional<size_t> last = {})
    const override;

  /**
   * @brief      Obtain event mask in a given slice (ODIN error)
   *
   * @param      slice index
   *
   * @return     event mask in given slice
   */
  std::vector<char> event_mask(size_t slice_index) const override;

  /**
   * @brief      Obtain banks from a slice
   *
   * @param      BankType
   * @param      slice index
   *
   * @return     Banks and their offsets
   */
  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const override;

  /**
   * @brief      Get a slice that is ready for processing; thread-safe
   *
   * @param      optional timeout
   *
   * @return     (good slice, input done, timed out, slice index, number of events in slice)
   */
  std::tuple<bool, bool, bool, size_t, size_t, std::any> get_slice(std::optional<unsigned int> timeout = {}) override;

  /**
   * @brief      Declare a slice free for reuse; thread-safe
   *
   * @param      slice index
   *
   * @return     void
   */
  void slice_free(size_t slice_index) override;

  gsl::span<char const> raw_banks(Allen::ReadBuffer const& buffer, size_t const read_event_start, size_t const event)
    const;

  void event_sizes(
    size_t const slice_index,
    gsl::span<unsigned int const> const selected_events,
    std::vector<size_t>& sizes) const override;

  void copy_banks(size_t const slice_index, unsigned int const event, gsl::span<char> output_buffer) const override;

private:
  size_t count_writable() const;

  /**
   * @brief      Function to run in each thread transposing events
   *
   * @param      thread ID
   *
   * @return     void
   */
  void transpose(int thread_id);
  /**
   * @brief      Open an input file; called from the prefetch thread
   *
   * @return     (success, is_mc)
   */
  bool open_file() const;
  /**
   * @brief      Function to steer prefetching of events; run on separate
   *             thread
   *
   * @return     void
   */
  void prefetch();

  // Memory buffers to read binary data into from the file
  mutable Allen::ReadBuffers m_buffers;

  // data members for prefetch thread
  std::mutex m_prefetch_mut;
  std::condition_variable m_prefetch_cond;
  std::deque<size_t> m_prefetched;
  std::vector<BufferStatus> m_buffer_status;
  std::unique_ptr<std::thread> m_prefetch_thread;

  // Atomics to flag errors and completion
  std::atomic<bool> m_done = false;
  mutable std::atomic<bool> m_read_error = false;
  std::atomic<bool> m_transpose_done = false;

  // Buffer to store data read from file if banks are compressed. The
  // decompressed data will be written to the buffers
  mutable std::vector<char> m_compress_buffer;

  // Storage to read the header into for each event
  mutable LHCb::MDFHeader m_header;

  // Memory slices, N for each raw bank type
  Allen::Slices m_slices;
  std::vector<std::vector<char>> m_masks;
  std::vector<LHCb::ODIN> m_odins;

  struct SliceToBuffer {
    int buffer_index;
    size_t buffer_event_start;
  };
  std::vector<SliceToBuffer> m_slice_to_buffer;

  // Array to store the version of banks per bank type
  mutable std::vector<std::array<int, NBankTypes>> m_banks_version;

  // Mutex, condition varaible and queue for parallel transposition of slices
  std::mutex m_transpose_mut;
  std::condition_variable m_transpose_cond;
  std::deque<std::tuple<size_t, size_t>> m_transposed;

  // Keep track of what slices are free
  std::mutex m_slice_mut;
  std::condition_variable m_slice_cond;
  std::vector<bool> m_slice_free;

  // Threads transposing data
  std::vector<std::thread> m_transpose_threads;

  // Array to store the number of banks per subdetector
  mutable std::array<unsigned int, NBankTypes> m_mfp_count;
  mutable bool m_sizes_known = false;

  std::optional<bool> m_is_mc = std::nullopt;

  Allen::sd_from_raw_bank m_sd_from_raw;

  Allen::bank_sorter m_bank_sorter;

  // Run and event numbers present in each slice
  std::vector<EventIDs> m_event_ids;

  // File names to read
  std::vector<std::string> m_connections;

  // Storage for the currently open file
  mutable std::optional<Allen::IO> m_input = std::nullopt;

  // Iterator that points to the filename of the currently open file
  mutable std::vector<std::string>::const_iterator m_current;

  // Input data loop counter
  mutable size_t m_loop = 0;

  // Configuration struct
  MDFProviderConfig m_config;
};
