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

  // number of prefetch buffers
  size_t n_buffers = 10;

  // number of transpose threads
  size_t n_transpose_threads = 5;

  // maximum number of events per slice
  size_t offsets_size = 10001;

  // default of events per prefetch buffer
  size_t events_per_buffer = 1200;

  // number of loops over input data
  size_t n_loops = 0;

  bool split_by_run = false;
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
    MDFProviderConfig config = MDFProviderConfig {}) :
    InputProvider {n_slices, events_per_slice, bank_types, IInputProvider::Layout::Allen, n_events},
    m_buffer_status(config.n_buffers), m_slice_to_buffer(n_slices, {-1, 0}), m_slice_free(n_slices, true),
    m_mfp_count {0}, m_event_ids {n_slices}, m_connections {std::move(connections)}, m_config {config}
  {

    // Preallocate prefetch buffer memory
    m_buffers.resize(config.n_buffers);
    for (auto& [n_filled, event_offsets, buffer, transpose_start] : m_buffers) {
      auto epb = config.events_per_buffer;
      buffer.resize((epb < 100 ? 100 : epb) * average_event_size * bank_size_fudge_factor * kB);
      event_offsets.resize(config.offsets_size);
      event_offsets[0] = 0;
      n_filled = 0;
      transpose_start = 0;
    }

    // Initialize the current input filename
    m_current = m_connections.begin();

    // Allocate space to store event ids
    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(events_per_slice);
    }

    // Reserve 1MB for decompression
    m_compress_buffer.reserve(1u * MB);

    // Start prefetch thread and count bank types one a single buffer
    // is available
    {
      // aquire lock
      std::unique_lock<std::mutex> lock {m_prefetch_mut};

      m_masks.resize(n_slices);
      for (auto& mask : m_masks) {
        mask.resize(events_per_slice, 0);
      }

      // start prefetch thread
      m_prefetch_thread = std::make_unique<std::thread>([this] { prefetch(); });

      // Wait for first read buffer to be full
      m_prefetch_cond.wait(lock, [this] { return !m_prefetched.empty() || m_read_error; });
      if (!m_read_error) {
        // Count number of banks per flavour
        bool count_success = false;

        // Offsets are to the start of the event, which includes the header
        auto i_read = m_prefetched.front();
        auto& [n_filled, event_offsets, buffer, transpose_start] = m_buffers[i_read];
        gsl::span<char> const event_span = {buffer.data(), event_offsets[1]};

        // Check what type of file we have: old MC or (new MC or data)
        m_is_mc = check_sourceIDs(event_span);
        if (*m_is_mc) {
          m_sd_from_raw = sd_from_bank_type;
          m_bank_sorter = sort_by_bank_type;
        }
        else {
          m_sd_from_raw = sd_from_sourceID;
          m_bank_sorter = sort_by_sourceID;
        }
        std::tie(count_success, m_mfp_count) = fill_counts(event_span, m_sd_from_raw);

        for (auto allen_type : types()) {
          if (m_mfp_count[to_integral(allen_type)] == 0) {
            error_cout << "Banks for " << bank_name(allen_type) << " are not present in the file\n";
            m_read_error = true;
          }
        }

        if (!count_success) {
          error_cout << "Failed to determine bank counts\n";
          m_read_error = true;
        }
        else if (!m_read_error) {
          m_sizes_known = true;

          // Allocate slice memory that will contain transposed banks ready
          // for processing by the Allen kernels
          auto size_fun = [events_per_slice, this](BankTypes bank_type) -> std::tuple<size_t, size_t> {
            auto it = BankSizes.find(bank_type);
            auto ib = to_integral<BankTypes>(bank_type);
            if (it == end(BankSizes)) {
              throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
            }
            // Allocate a minimum size
            auto allocate_events = events_per_slice < 100 ? 100 : events_per_slice;

            // When events are transposed from the read buffer into
            // the per-rawbank-type slices, a check is made each time
            // to see if there is enough space available in a slice.
            // To avoid having to read every event twice to get the
            // size of all the banks, the size of the entire event is
            // used for the check - 65 kB on average. To avoid
            // problems for banks with very low average size like the
            // ODIN bank - 0.1 kB, a fixed amount is also added.
            auto n_bytes = std::lround(
              ((1 + m_mfp_count[ib]) * sizeof(uint32_t) + it->second * kB) * allocate_events * bank_size_fudge_factor +
              2 * MB);
            return {n_bytes, events_per_slice};
          };
          m_slices = allocate_slices(n_slices, types(), size_fun);
        }
      }
    }

    // Sanity check on the number of buffers and threads
    if (m_config.n_buffers <= 1) {
      warning_cout << "too few read buffers requested, setting it to 2\n";
      m_config.n_buffers = 2;
    }

    if (m_config.n_transpose_threads > m_config.n_buffers - 1) {
      warning_cout << "too many transpose threads requested with respect "
                      "to the number of read buffers; reducing the number of threads to "
                   << m_config.n_buffers - 1;
      m_config.n_transpose_threads = m_config.n_buffers - 1;
    }

    // Start the transpose threads
    if (m_transpose_threads.empty() && !m_read_error) {
      for (size_t i = 0; i < m_config.n_transpose_threads; ++i) {
        m_transpose_threads.emplace_back([this, i] { transpose(i); });
      }
    }
  }

  /// Destructor
  virtual ~MDFProvider()
  {

    // Set flag to indicate the prefetch thread should exit, wake it
    // up and join it
    m_done = true;
    m_transpose_done = true;
    m_prefetch_cond.notify_one();
    if (m_prefetch_thread) m_prefetch_thread->join();

    // Set a flat to indicate all transpose threads should exit, wake
    // them up and join the threads. Ensure any waiting calls to
    // get_slice also return.
    m_prefetch_cond.notify_all();
    m_transpose_cond.notify_all();
    m_slice_cond.notify_all();

    for (auto& thread : m_transpose_threads) {
      thread.join();
    }
  }

  /**
   * @brief      Obtain event IDs of events stored in a given slice
   *
   * @param      slice index
   *
   * @return     EventIDs of events in given slice
   */
  EventIDs event_ids(size_t slice_index, std::optional<size_t> first = {}, std::optional<size_t> last = {})
    const override
  {
    auto const& ids = m_event_ids[slice_index];
    return {ids.begin() + (first ? *first : 0), ids.begin() + (last ? *last : ids.size())};
  }

  /**
   * @brief      Obtain banks from a slice
   *
   * @param      BankType
   * @param      slice index
   *
   * @return     Banks and their offsets
   */
  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const override
  {
    auto ib = to_integral(bank_type);
    // FIXME structured binding version below triggers clang 11 bug
    //       revert after clang fix available
    // auto const& [banks, data_size, offsets, offsets_size] = m_slices[ib][slice_index];
    auto const& tup = m_slices[ib][slice_index];
    auto const& banks = std::get<0>(tup);
    auto const offsets = std::get<2>(tup);
    auto const offsets_size = std::get<3>(tup);

    gsl::span<char const> b {banks[0].data(), offsets[offsets_size - 1]};
    gsl::span<unsigned int const> o {offsets.data(), static_cast<::offsets_size>(offsets_size)};
    return BanksAndOffsets {{std::move(b)}, offsets[offsets_size - 1], std::move(o), m_banks_version[ib]};
  }

  /**
   * @brief      Get a slice that is ready for processing; thread-safe
   *
   * @param      optional timeout
   *
   * @return     (good slice, input done, timed out, slice index, number of events in slice)
   */
  std::tuple<bool, bool, bool, size_t, size_t, std::any> get_slice(std::optional<unsigned int> timeout = {}) override
  {
    bool timed_out = false, done = false;
    size_t slice_index = 0, n_filled = 0;
    std::any odin;
    std::unique_lock<std::mutex> lock {m_transpose_mut};
    if (!m_read_error) {
      // If no transposed slices are ready for processing, wait until
      // one is; use a timeout if requested
      if (m_transposed.empty()) {
        auto wakeup = [this] {
          auto n_writable = count_writable();
          return (!m_transposed.empty() || m_read_error || (m_transpose_done && n_writable == m_buffer_status.size()));
        };
        if (timeout) {
          timed_out = !m_transpose_cond.wait_for(lock, std::chrono::milliseconds {*timeout}, wakeup);
        }
        else {
          m_transpose_cond.wait(lock, wakeup);
        }
      }
      if (!m_read_error && !m_transposed.empty() && (!timeout || (timeout && !timed_out))) {
        std::tie(slice_index, n_filled) = m_transposed.front();
        m_transposed.pop_front();
        if (n_filled > 0) {
          auto bno = banks(BankTypes::ODIN, slice_index);
          gsl::span<unsigned const> odin_data {
            odin_data_t::data(std::get<0>(bno)[0].data(), std::get<2>(bno).data(), 0), 10};
          odin = odin_data;
        }
      }
    }

    // Check if I/O and transposition is done and return a slice index
    auto n_writable = count_writable();
    done = m_transpose_done && m_transposed.empty() && n_writable == m_buffer_status.size();
    return {!m_read_error, done, timed_out, slice_index, n_filled, odin};
  }

  /**
   * @brief      Declare a slice free for reuse; thread-safe
   *
   * @param      slice index
   *
   * @return     void
   */
  void slice_free(size_t slice_index) override
  {
    // Check if a slice was acually in use before and if it was, only
    // notify the transpose threads that a free slice is available
    bool freed = false, set_writable = false;
    int i_read = 0;
    {
      std::unique_lock<std::mutex> lock {m_slice_mut};
      if (!m_slice_free[slice_index]) {
        m_slice_free[slice_index] = true;
        freed = true;

        // Reset the slice
        auto& event_ids = m_event_ids[slice_index];
        reset_slice(m_slices, slice_index, types(), event_ids);

        // Clear relation between slice and buffer
        i_read = m_slice_to_buffer[slice_index].buffer_index;
        auto& status = m_buffer_status[i_read];
        m_slice_to_buffer[slice_index].buffer_index = -1;

        if (
          status.work_counter == 0 && std::get<0>(m_buffers[i_read]) == std::get<3>(m_buffers[i_read]) &&
          (std::find_if(m_slice_to_buffer.begin(), m_slice_to_buffer.end(), [i_read](auto const stb) {
             return stb.buffer_index == i_read;
           }) == m_slice_to_buffer.end())) {
          status.writable = true;
          set_writable = true;
          // "Reset" buffer; the 0th offset is always 0. Set transpose
          // start to 0.
          std::get<0>(m_buffers[i_read]) = 0;
          std::get<3>(m_buffers[i_read]) = 0;
          m_transpose_done = m_done && m_prefetched.empty();
        }
      }
    }
    if (freed) {
      this->debug_output("Freed slice " + std::to_string(slice_index));
      m_slice_cond.notify_one();
    }
    if (set_writable) {
      this->debug_output("Set buffer " + std::to_string(i_read) + " writable");
      m_prefetch_cond.notify_one();
    }
  }

  gsl::span<char const> raw_banks(Allen::ReadBuffer const& buffer, size_t const read_event_start, size_t const event)
    const
  {
    auto const event_index = event + read_event_start;

    // FIXME structured binding version below triggers clang 11 bug
    //       revert after clang fix available
    // auto const& [n_filled, event_offsets, event_buffer, transpose_start] = m_buffers[i_read];
    auto const& event_offsets = std::get<1>(buffer);
    auto const& event_buffer = std::get<2>(buffer);

    auto event_offset = event_offsets[event_index];

    // The first bank in the read buffer is the DAQ bank, which
    // contains the MDF header as bank payload; it does not belong to
    // the original event and should be skipped
    auto const* daq_bank = reinterpret_cast<LHCb::RawBank const*>(event_buffer.data() + event_offset);
    assert(daq_bank->type() == LHCb::RawBank::DAQ);
    auto const daq_bank_size = daq_bank->totalSize();

    auto const* banks_start = event_buffer.data() + event_offset + daq_bank_size;
    return {banks_start, event_offsets[event_index + 1] - event_offset - daq_bank_size};
  }

  void event_sizes(
    size_t const slice_index,
    gsl::span<unsigned int const> const selected_events,
    std::vector<size_t>& sizes) const override
  {
    auto const stb = m_slice_to_buffer[slice_index];
    auto const i_read = stb.buffer_index;
    auto const read_event_start = stb.buffer_event_start;
    auto const& buffer = m_buffers[i_read];

    for (size_t i = 0; i < static_cast<size_t>(selected_events.size()); ++i) {
      auto const event = selected_events[i];
      sizes[i] = raw_banks(buffer, read_event_start, event).size_bytes();
    }
  }

  void copy_banks(size_t const slice_index, unsigned int const event, gsl::span<char> output_buffer) const override
  {
    // The first bank in the read buffer is the DAQ bank, which
    // contains the MDF header as bank payload
    auto const stb = m_slice_to_buffer[slice_index];
    auto const i_read = stb.buffer_index;
    auto const read_event_start = stb.buffer_event_start;

    auto const& buffer = m_buffers[i_read];
    auto const banks = raw_banks(buffer, read_event_start, event);
    assert(banks.size_bytes() <= output_buffer.size());
    std::memcpy(output_buffer.data(), banks.data(), banks.size_bytes());
  }

private:
  size_t count_writable() const
  {
    return std::accumulate(m_buffer_status.begin(), m_buffer_status.end(), 0ul, [](size_t s, BufferStatus const& stat) {
      return s + stat.writable;
    });
  }

  /**
   * @brief      Function to run in each thread transposing events
   *
   * @param      thread ID
   *
   * @return     void
   */
  void transpose(int thread_id)
  {

    size_t i_read = 0;
    std::optional<size_t> slice_index {};

    bool good = false, transpose_full = false;
    size_t n_transposed = 0;

    while (!m_read_error && !m_transpose_done) {

      // Get a buffer to read from
      {
        std::unique_lock<std::mutex> lock {m_prefetch_mut};
        if (m_prefetched.empty() && !m_transpose_done) {
          m_prefetch_cond.wait(lock, [this] { return !m_prefetched.empty() || m_transpose_done; });
        }
        if (m_prefetched.empty() || m_transpose_done) {
          this->debug_output(
            "Transpose done: " + std::to_string(m_transpose_done) + " " + std::to_string(m_prefetched.empty()),
            thread_id);
          break;
        }
        i_read = m_prefetched.front();
        m_prefetched.pop_front();
        this->debug_output("Got read buffer index " + std::to_string(i_read), thread_id);
        auto& status = m_buffer_status[i_read];
        status.writable = false;
        ++status.work_counter;
      }

      // Get a slice to write to
      if (!slice_index) {
        this->debug_output("Getting slice index", thread_id);
        auto it = m_slice_free.end();
        {
          std::unique_lock<std::mutex> lock {m_slice_mut};
          it = find(m_slice_free.begin(), m_slice_free.end(), true);
          if (it == m_slice_free.end()) {
            this->debug_output("Waiting for free slice", thread_id);
            m_slice_cond.wait(lock, [this, &it] {
              it = std::find(m_slice_free.begin(), m_slice_free.end(), true);
              return it != m_slice_free.end() || m_transpose_done;
            });
            // If transpose is done and there is no slice, we were
            // woken up be the desctructor before a slice was declared
            // free. In that case, exit without transposing
            if (m_transpose_done && it == m_slice_free.end()) {
              break;
            }
          }
          *it = false;
        }
        if (it != m_slice_free.end()) {
          slice_index = distance(m_slice_free.begin(), it);
          this->debug_output("Got slice index " + std::to_string(*slice_index), thread_id);
        }
      }

      // Transpose the events in the read buffer into the slice
      std::tie(good, transpose_full, n_transposed) = transpose_events(
        m_buffers[i_read],
        m_slices,
        *slice_index,
        this->types(),
        m_sd_from_raw,
        m_bank_sorter,
        m_mfp_count,
        m_banks_version,
        m_event_ids[*slice_index],
        m_masks[*slice_index],
        this->events_per_slice(),
        m_config.split_by_run);

      if (m_read_error || !good) {
        m_read_error = true;
        auto& status = m_buffer_status[i_read];
        --status.work_counter;
        m_transpose_cond.notify_one();
        break;
      }
      else {
        m_slice_to_buffer[*slice_index] = {static_cast<int>(i_read), std::get<3>(m_buffers[i_read])};
      }

      // Increment the transpose_start with the number of transposed events
      std::get<3>(m_buffers[i_read]) += n_transposed;
      auto events_left = std::get<0>(m_buffers[i_read]) - std::get<3>(m_buffers[i_read]);
      this->debug_output(
        "Transposed: slice_index " + std::to_string(*slice_index) + "; full " + std::to_string(transpose_full) +
          "; n_transposed " + std::to_string(n_transposed) + "; n_left " + std::to_string(events_left),
        thread_id);

      // Notify any threads waiting in get_slice that a slice is available
      {
        std::unique_lock<std::mutex> lock {m_transpose_mut};
        m_transposed.emplace_back(*slice_index, n_transposed);
      }
      m_transpose_cond.notify_one();

      slice_index.reset();

      // Check if the read buffer is now empty. If it is, it can be
      // reused, otherwise give it to another transpose thread once a
      // new target slice is available
      {
        std::unique_lock<std::mutex> lock {m_prefetch_mut};
        if (events_left > 0) {
          // Put this prefetched slice back on the prefetched queue so
          // somebody else can finish it
          m_prefetched.push_front(i_read);
        }

        // Decrement the work counter of this buffer
        auto& status = m_buffer_status[i_read];
        --status.work_counter;
      }
    }
  }

  /**
   * @brief      Open an input file; called from the prefetch thread
   *
   * @return     (success, is_mc)
   */
  bool open_file() const
  {
    bool good = false;

    // Check if there are still files available
    while (!good) {
      // If looping on input is configured, do it
      if (m_current == m_connections.end()) {
        if (++m_loop < m_config.n_loops) {
          m_current = m_connections.begin();
        }
        else {
          break;
        }
      }

      if (m_input && m_input->good) m_input->close();

      m_input = MDF::open(m_current->c_str(), O_RDONLY);
      if (m_input->good) {
        // read the first header, needed by subsequent calls to read_events
        ssize_t n_bytes = m_input->read(reinterpret_cast<char*>(&m_header), mdf_header_size);
        good = (n_bytes > 0);
      }

      if (good) {
        info_cout << "Opened " << *m_current << "\n";
      }
      else {
        error_cout << "Failed to open " << *m_current << " " << strerror(errno) << "\n";
        m_read_error = true;
        return false;
      }
      ++m_current;
    }
    return good;
  }

  /**
   * @brief      Function to steer prefetching of events; run on separate
   *             thread
   *
   * @return     void
   */
  void prefetch()
  {

    bool eof = false, error = false, prefetch_done = false;
    size_t bytes_read = 0;

    auto to_read = this->n_events();
    size_t eps = this->events_per_slice();

    // Loop while there are no errors and the flag to exit is not set
    while (!m_done && !m_read_error && (!to_read || *to_read > 0)) {

      // open the first file
      if (!m_input && !open_file()) {
        m_read_error = true;
        m_prefetch_cond.notify_one();
        return;
      }

      // Obtain a prefetch buffer to read into, if none is available,
      // wait until one of the transpose threads is done with its
      // prefetch buffer
      auto it = m_buffer_status.end();
      {
        auto find_writable = [this] {
          return std::find_if(
            m_buffer_status.begin(), m_buffer_status.end(), [](const auto& stat) { return stat.writable; });
        };

        std::unique_lock<std::mutex> lock {m_prefetch_mut};
        it = find_writable();
        if (it == m_buffer_status.end()) {
          this->debug_output("Waiting for free buffer");
          m_prefetch_cond.wait(
            lock, [this, &find_writable] { return (find_writable() != m_buffer_status.end()) || m_done; });
          if (m_done) {
            break;
          }
          else {
            it = find_writable();
          }
        }
        // Flag the prefetch buffer as unavailable
        it->writable = false;
      }
      size_t i_buffer = distance(m_buffer_status.begin(), it);
      auto& read_buffer = m_buffers[i_buffer];

      // Read events into the prefetch buffer, open new files as
      // needed
      while (true) {
        size_t read = std::get<0>(read_buffer);
        size_t to_prefetch = to_read ? std::min(eps, *to_read + read) : eps;
        std::tie(eof, error, bytes_read) =
          read_events(*m_input, read_buffer, m_header, m_compress_buffer, to_prefetch, m_config.check_checksum);

        auto const is_mc = check_sourceIDs({std::get<2>(read_buffer).data(), std::get<1>(read_buffer)[1]});
        if (m_is_mc && *m_is_mc != is_mc) {
          throw std::out_of_range {"The next batch of events is different from the previous events"s +
                                   (*m_is_mc ? "some banks now"s : "none of the banks"s) + "have the top 5 bits set"s};
        }

        size_t n_read = std::get<0>(read_buffer) - read;
        if (to_read) {
          *to_read -= std::min(*to_read, n_read);
        }

        if (error) {
          // Error encountered
          m_read_error = true;
          break;
        }
        else if (to_read && *to_read == 0) {
          if (m_config.n_loops != 0 && m_loop < (m_config.n_loops - 1)) {
            // Set things such that the next call to open_file will
            // result in a loop
            this->debug_output("Loop " + std::to_string(m_loop + 1));
            to_read = this->n_events();
            m_current = m_connections.end();
            if (m_input && m_input->good) m_input->close();
            m_input.reset();
          }
          else {
            // No events left to read
            this->debug_output("Prefetch done: n_events reached");
            prefetch_done = true;
          }
          break;
        }
        else if (std::get<0>(read_buffer) == eps) {
          // Number of events in a slice reached
          break;
        }
        else if (eof && !open_file()) {
          // Try to open the next file, if there is none, prefetching
          // is done.
          if (!m_read_error) {
            this->debug_output("Prefetch done: eof and no more files");
          }
          prefetch_done = true;
          break;
        }
      }

      this->debug_output(
        "Read " + std::to_string(std::get<0>(read_buffer)) + " events into " + std::to_string(i_buffer));

      // Notify a transpose thread that a new buffer of events is
      // ready. If prefetching is done, wake up all threads
      if (!error) {
        {
          std::unique_lock<std::mutex> lock {m_prefetch_mut};
          m_prefetched.push_back(i_buffer);
        }
        if (prefetch_done) {
          m_done = prefetch_done;
          this->debug_output("Prefetch notifying all");
          m_prefetch_cond.notify_all();
        }
        else {
          this->debug_output("Prefetch notifying one");
          m_prefetch_cond.notify_one();
        }
      }
    }
    m_prefetch_cond.notify_one();
  }

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

  struct SliceToBuffer {
    int buffer_index;
    size_t buffer_event_start;
  };
  std::vector<SliceToBuffer> m_slice_to_buffer;

  // Array to store the version of banks per bank type
  mutable std::array<int, NBankTypes> m_banks_version;

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
  mutable std::optional<Allen::IO> m_input;

  // Iterator that points to the filename of the currently open file
  mutable std::vector<std::string>::const_iterator m_current;

  // Input data loop counter
  mutable size_t m_loop = 0;

  // Configuration struct
  MDFProviderConfig m_config;
};
