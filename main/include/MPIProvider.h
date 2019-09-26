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

#include <CudaCommon.h>

#include <Logger.h>
#include <InputProvider.h>
#include <BankTypes.h>
#include <Timer.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <raw_bank.hpp>

#include "Transpose.h"
#include "TransposeMEP.h"
#include "MPIConfig.h"

namespace {
  using namespace Allen::Units;
} // namespace

// Read buffer containing the number of events, offsets to the start
// of the event and the event data
using ReadBuffer = std::tuple<size_t, std::vector<unsigned int>, std::vector<char>>;
using ReadBuffers = std::vector<ReadBuffer>;

// A slice contains transposed bank data, offsets to the start of each
// set of banks and the number of sets of banks
using Slice = std::tuple<gsl::span<char>, gsl::span<unsigned int>, size_t>;
using BankSlices = std::vector<Slice>;
using Slices = std::array<BankSlices, NBankTypes>;

/**
 * @brief      Configuration parameters for the MPIProvider
 */
struct MPIProviderConfig {
  // check the MDF checksum if it is available
  bool check_checksum = false;

  // number of prefetch buffers
  size_t n_buffers = 10;

  // number of transpose threads
  size_t n_transpose_threads = 5;

  // maximum number of events per slice
  size_t offsets_size = 10001;

  size_t window_size = 4;

  size_t transpose_chunk_size = 20;

  bool non_stop = true;
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
template <BankTypes... Banks>
class MPIProvider final : public InputProvider<MPIProvider<Banks...>> {
public:
  MPIProvider(size_t n_slices, size_t events_per_slice, std::optional<size_t> n_events,
              std::vector<std::string> connections,
              MPIProviderConfig config = MPIProviderConfig{}) :
    InputProvider<MPIProvider<Banks...>>{n_slices, events_per_slice, n_events},
    m_buffer_writable(config.n_buffers, true),
    m_slice_free(n_slices, true),
    m_banks_count{0},
    m_event_ids{n_slices},
    m_connections {std::move(connections)},
    m_config{config}
  {

    MPI_Recv(&m_packing_factor, 1, MPI_SIZE_T, MPI::sender, MPI::message::packing_factor, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    // Allocate as many net slices as configured, of expected size
    // Packing factor can be done dynamically if needed
    size_t n_bytes = std::lround(m_packing_factor * average_event_size * bank_size_fudge_factor * kB);
    for (int i=0; i < config.n_buffers; ++i) {
      char* contents;
      MPI_Alloc_mem(n_bytes, MPI_INFO_NULL, &contents);
      m_net_slices.emplace_back(gsl::span{contents, n_bytes}, n_bytes);
    }

    // Allocate queues for slice intervals
    m_slice_intervals.resize(config.n_buffers);

    // Reinitialize to take the possible minimum number of events per
    // slice into account
    events_per_slice = this->events_per_slice();

    // Allocate slice memory that will contain transposed banks ready
    // for processing by the Allen kernels
    auto size_fun = [events_per_slice](BankTypes bank_type) -> std::tuple<size_t, size_t> {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }
      return {std::lround(it->second * events_per_slice * bank_size_fudge_factor * kB), events_per_slice};
    };
    m_slices = allocate_slices<Banks...>(n_slices, size_fun);

    // Allocate storage for offsets and blocks used during MEP
    // transposition
    m_slice_offsets_blocks.resize(n_slices);

    // Initialize the current input filename
    m_current = m_connections.begin();

    // Allocate space to store event ids
    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(events_per_slice);
    }

    // Cached bank LHCb bank type to Allen bank type mapping
    m_bank_ids = bank_ids();

    // Reserve 1MB for decompression
    m_compress_buffer.reserve(1u * MB);

    // Start prefetch thread and count bank types once a single buffer
    // is available
    {
      // aquire lock
      std::unique_lock<std::mutex> lock{m_mpi_mutex};

      // start MPI thread
      m_mpi_thread = std::thread{&MPIProvider::mpi_read, this};

      // Wait for first read buffer to be full
      m_mpi_cond.wait(lock, [this] { return !m_mpi_produced.empty() || m_read_error; });
      if (!m_read_error) {
        // Count number of banks per flavour
        bool count_success = false;

        // Offsets are to the start of the event, which includes the header
        auto i_read = m_mpi_produced.front();
        auto& [mpi_slice, slice_size] = m_net_slices[i_read];
        EB::Header mep_header{mpi_slice.data()};
        // gsl::span<char const> block_span{mpi_slice.data() + mep_header.header_size(mep_header.n_blocks), mep_header.mep_size};
        assert(mep_header.packing_factor == m_packing_factor);
        std::tie(count_success, m_banks_count) = MEP::fill_counts(mep_header, mpi_slice);

        // The number of blocks in a MEP is know, use it to allocate
        // storage for temporary storage used during transposition
        for (auto& [input_offsets, blocks] : m_slice_offsets_blocks) {
          blocks.resize(mep_header.n_blocks);
          input_offsets.resize(mep_header.n_blocks);
          for (auto& offsets : input_offsets) {
            // info_cout << "Packing factor: " << mep_header.packing_factor << "\n";
            offsets.resize(m_packing_factor + 1);
          }
        }

        if (!count_success) {
          error_cout << "Failed to determine bank counts\n";
          m_read_error = true;
        } else {
          m_sizes_known = true;
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
        "to the number of read buffers; reducing the number of threads to " << m_config.n_buffers - 1;
      m_config.n_transpose_threads = m_config.n_buffers - 1;
    }

    // Start the transpose threads
    if (m_transpose_threads.empty() && !m_read_error) {
      for (size_t i = 0; i < m_config.n_transpose_threads; ++i) {
        m_transpose_threads.emplace_back([this, i] { transpose(i); });
      }
    }


  }

  static constexpr const char* name = "MDF";

  /// Destructor
  virtual ~MPIProvider() {

    // Set flag to indicate the prefetch thread should exit, wake it
    // up and join it
    m_done = true;
    m_mpi_cond.notify_one();
    m_mpi_thread.join();

    // Set a flat to indicate all transpose threads should exit, wake
    // them up and join the threads. Ensure any waiting calls to
    // get_slice also return.
    m_transpose_done = true;
    m_mpi_cond.notify_all();
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
  std::vector<std::tuple<unsigned int, unsigned long>> const& event_ids(size_t slice_index) const override
  {
    return m_event_ids[slice_index];
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
    auto ib = to_integral<BankTypes>(bank_type);
    auto const& [banks, offsets, offsets_size] = m_slices[ib][slice_index];
    span<char const> b {banks.data(), offsets[offsets_size - 1]};
    span<unsigned int const> o {offsets.data(), offsets_size};
    return BanksAndOffsets {std::move(b), std::move(o)};
  }

/**
 * @brief      Get a slice that is ready for processing; thread-safe
 *
 * @param      optional timeout
 *
 * @return     (good slice, timed out, slice index, number of events in slice)
 */
  std::tuple<bool, bool, size_t, size_t> get_slice(std::optional<unsigned int> timeout = std::optional<unsigned int>{}) override
  {
    bool timed_out = false, done = false;
    size_t slice_index = 0, n_filled = 0;
    std::unique_lock<std::mutex> lock{m_transpose_mut};
    if (!m_read_error) {
      // If no transposed slices are ready for processing, wait until
      // one is; use a timeout if requested
      if (m_transposed.empty()) {
        auto wakeup = [this, &done] {
                        auto n_writable = std::accumulate(m_buffer_writable.begin(), m_buffer_writable.end(), 0ul);
                        return (!m_transposed.empty() || m_read_error
                                || (m_transpose_done && n_writable == m_buffer_writable.size()));
                      };
        if (timeout) {
          timed_out = !m_transpose_cond.wait_for(lock, std::chrono::milliseconds{*timeout}, wakeup);
        } else {
          m_transpose_cond.wait(lock, wakeup);
        }
      }
      if (!m_read_error && !m_transposed.empty() && (!timeout || (timeout && !timed_out))) {
        std::tie(slice_index, n_filled) = m_transposed.front();
        m_transposed.pop_front();
      }
    }

    // Check if I/O and transposition is done and return a slice index
    auto n_writable = std::accumulate(m_buffer_writable.begin(), m_buffer_writable.end(), 0ul);
    done = m_transpose_done && m_transposed.empty() && n_writable == m_buffer_writable.size();
    return {!m_read_error && !done, timed_out, slice_index, m_read_error ? 0 : n_filled};
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
    bool freed = false;
    {
      std::unique_lock<std::mutex> lock{m_slice_mut};
      if (!m_slice_free[slice_index]) {
        m_slice_free[slice_index] = true;
        freed = true;
      }
    }
    if (freed) {
      this->debug_output("Freed slice " + std::to_string(slice_index));
      m_slice_cond.notify_one();
    }
  }

private:

  // MPI reader thread
  void mpi_read() {

    auto window_size = m_config.window_size;
    std::vector<MPI_Request> requests (window_size);

    // Iterate over the slices
    int current_slice = 0;
    int startup_iteration = 0;

    size_t reporting_period = 5;
    size_t bytes_received = 0;
    size_t meps_received = 0;
    size_t number_of_files = 0;
    Timer t;
    Timer t_origin;
    bool error = false;
    bool receive_done = false;

    MPI_Recv(&number_of_files, 1, MPI_SIZE_T, MPI::sender, MPI::message::number_of_files, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    int current_file=0;
    while (m_config.non_stop || current_file < number_of_files) {
      // info_cout << MPI::rank_str() << "round " << current_file << "\n";

      // Obtain a prefetch buffer to read into, if none is available,
      // wait until one of the transpose threads is done with its
      // prefetch buffer
      auto it = m_buffer_writable.end();
      {
        std::unique_lock<std::mutex> lock{m_mpi_mutex};
        it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
        if (it == m_buffer_writable.end()) {
          this->debug_output("Waiting for free buffer");
          m_mpi_cond.wait(lock, [this] {
                                  return std::find(m_buffer_writable.begin(), m_buffer_writable.end(), true)
                                    != m_buffer_writable.end() || m_done;
                                });
          if (m_done) {
            break;
          } else {
            it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
          }
        }
        // Flag the prefetch buffer as unavailable
        *it = false;
      }

      size_t i_slice = distance(m_buffer_writable.begin(), it);
      auto& [buffer_span, buffer_size] = m_net_slices[i_slice];
      char* contents = buffer_span.data();

      size_t mep_size = 0;
      MPI_Recv(&mep_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::event_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

      // info_cout << MPI::rank_str() << "event size: " << mep_size << "\n";

      // info_cout << MPI::rank_str() << "Max event size " << mep_size << "\n";

      // Reallocate if needed
      if (mep_size > buffer_size) {
        buffer_size = mep_size * bank_size_fudge_factor;
        MPI_Free_mem(contents);
        MPI_Alloc_mem(buffer_size, MPI_INFO_NULL, &contents);
        buffer_span = gsl::span{contents, buffer_size};
      }

      // Number of full-size (MPI::mdf_chunk_size) messages
      int n_messages = mep_size / MPI::mdf_chunk_size;
      // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
      int rest = mep_size - n_messages * MPI::mdf_chunk_size;
      // Number of parallel sends
      int n_sends = n_messages > window_size ? window_size : n_messages;

      // info_cout << MPI::rank_str() << "n_messages " << n_messages << ", rest " << rest << ", n_sends " << n_sends << "\n";

      // Initial parallel sends
      for (int k = 0; k < n_sends; k++) {
        char* message = contents + k * MPI::mdf_chunk_size;
        MPI_Irecv(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + k,
                  MPI_COMM_WORLD, &requests[k]);
      }
      // Sliding window sends
      for(int k = n_sends; k < n_messages; k++) {
        int r;
        MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
        char* message = contents + k * MPI::mdf_chunk_size;
        MPI_Irecv(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + k,
                  MPI_COMM_WORLD, &requests[r]);
      }
      // Last send (if necessary)
      if (rest) {
        int r;
        MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
        char* message = contents + n_messages * MPI::mdf_chunk_size;
        MPI_Irecv(message, rest, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + n_messages,
                  MPI_COMM_WORLD, &requests[r]);
      }
      // Wait until all chunks have been sent
      MPI_Waitall(n_sends, requests.data(), MPI_STATUSES_IGNORE);

      // info_cout << "All chunks received\n";

      buffer_span = gsl::span{contents, mep_size};

      bytes_received += mep_size;
      meps_received += 1;
      if (t.get_elapsed_time() >= reporting_period) {
        const auto seconds = t.get_elapsed_time();
        const double rate = (double) meps_received / seconds;
        double bandwidth = ((double) (bytes_received * 8)) / (1024 * 1024 * 1024 * seconds);

        printf("[%lf, %lf] Throughput: %lf MEP/s, %lf Gb/s\n",
               t_origin.get_elapsed_time(), seconds, rate, bandwidth);

        bytes_received = 0;
        meps_received = 0;

        t.restart();
      }

      // Notify a transpose thread that a new buffer of events is
      // ready. If prefetching is done, wake up all threads
      if (!error) {
        {
          std::unique_lock<std::mutex> lock{m_mpi_mutex};

          auto eps = this->events_per_slice();
          auto n_interval = m_packing_factor / eps;
          auto rest = m_packing_factor % eps;
          auto& intervals= m_slice_intervals[i_slice];
          size_t i = 0;
          for (; i < n_interval; ++i) {
            debug_cout << "Set interval: " << i * eps << "," << (i + 1) * eps << "\n";
            intervals.emplace_back(i * eps, (i + 1) * eps);
          }
          if (rest) {
            debug_cout << "Set interval (rest): " << i * eps << "," << i * eps + rest << "\n";
            intervals.emplace_back(i * eps, i * eps + rest);
          }
          m_mpi_produced.push_back(i_slice);
        }
        if (receive_done) {
          m_done = receive_done;
          this->debug_output("Prefetch notifying all");
          m_mpi_cond.notify_all();
        } else {
          this->debug_output("Prefetch notifying one");
          m_mpi_cond.notify_one();
        }
      }
      m_mpi_cond.notify_one();

      current_file++;
    }
  }

  /**
   * @brief      Function to run in each thread transposing events
   *
   * @param      thread ID
   *
   * @return     void
   */
  void transpose(int thread_id) {

    size_t i_read = 0;
    std::tuple<size_t, size_t> interval;
    std::optional<size_t> slice_index;

    bool good = false, transpose_full = false;
    size_t n_transposed = 0;

    while(!m_read_error && !m_transpose_done) {

      // Get a buffer to read from
      {
        std::unique_lock<std::mutex> lock{m_mpi_mutex};
        if (m_mpi_produced.empty() && !m_transpose_done) {
          m_mpi_cond.wait(lock, [this] { return !m_mpi_produced.empty() || m_transpose_done; });
        }
        if (m_mpi_produced.empty()) {
          this->debug_output("Transpose done: " + std::to_string(m_transpose_done) + " " + std::to_string(m_mpi_produced.empty()), thread_id);
          break;
        }

        i_read = m_mpi_produced.front();

        interval = m_slice_intervals[i_read].front();
        m_slice_intervals[i_read].pop_front();

        if (m_slice_intervals[i_read].empty()) {
          // Consume mpi_produced
          m_mpi_produced.pop_front();
        }

        this->debug_output("Got MEP slice index " + std::to_string(i_read)
                           + " interval [" + std::to_string(std::get<0>(interval)) + ","
                           + std::to_string(std::get<1>(interval)) + ")", thread_id);

        m_buffer_writable[i_read] = false;
      }

      // Get a slice to write to
      if (!slice_index) {
        this->debug_output("Getting slice index", thread_id);
        auto it = m_slice_free.end();
        {
          std::unique_lock<std::mutex> lock{m_slice_mut};
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

      // Reset the slice
      auto& event_ids = m_event_ids[*slice_index];
      reset_slice<Banks...>(m_slices, *slice_index, event_ids);

      // Transpose the events in the read buffer into the slice
      // FIXME replace by proper transposition including interval

      auto& [input_offsets, blocks] = m_slice_offsets_blocks[*slice_index];

      std::tie(good, transpose_full, n_transposed) = MEP::transpose_events(m_net_slices[i_read],
                                                                           input_offsets,
                                                                           blocks,
                                                                           m_slices,
                                                                           *slice_index,
                                                                           m_bank_ids,
                                                                           m_banks_count,
                                                                           event_ids,
                                                                           interval);
      this->debug_output("Transposed " + std::to_string(*slice_index) + " " + std::to_string(good)
                         + " " + std::to_string(transpose_full) + " " + std::to_string(n_transposed),
                         thread_id);

      if (m_read_error || !good) {
        m_read_error = true;
        m_transpose_cond.notify_one();
        break;
      }

      // Notify any threads waiting in get_slice that a slice is available
      {
        std::unique_lock<std::mutex> lock{m_transpose_mut};
        m_transposed.emplace_back(*slice_index, n_transposed);
      }
      m_transpose_cond.notify_one();
      slice_index.reset();

      // Check if the read buffer is now empty. If it is, it can be
      // reused, otherwise give it to another transpose thread once a
      // new target slice is available
      auto& intervals = m_slice_intervals[i_read];
      {
        std::unique_lock<std::mutex> lock{m_mpi_mutex};
        if (n_transposed == std::get<1>(interval) - std::get<0>(interval)) {
          if (intervals.empty()) {
            m_buffer_writable[i_read] = true;
          }
        } else {
          // Put this prefetched slice back on the prefetched queue so
          // somebody else can finish it
          std::unique_lock<std::mutex> lock{m_mpi_mutex};
          intervals.emplace_front(std::get<0>(interval) + n_transposed, std::get<1>(interval));
        }
        if (intervals.empty()) {
          // m_mpi_produced.pop_front();
          m_transpose_done = m_done && m_mpi_produced.empty();
        }
      }
      if (n_transposed == std::get<1>(interval) - std::get<0>(interval)) {
        m_mpi_cond.notify_one();
      }
    }
  }

  // Slices
  size_t m_packing_factor;
  MEP::Slices m_net_slices;

  // data members for mpi thread
  std::mutex m_mpi_mutex;
  std::condition_variable m_mpi_cond;
  std::deque<size_t> m_mpi_produced;
  std::vector<std::deque<std::tuple<size_t, size_t>>> m_slice_intervals;
  std::vector<bool> m_buffer_writable;
  std::thread m_mpi_thread;

  using InputOffsets = std::vector<std::vector<uint32_t>>;
  using Blocks = std::vector<std::tuple<EB::BlockHeader, gsl::span<char const>>>;
  // temporary storage
  std::vector<std::tuple<InputOffsets, Blocks>> m_slice_offsets_blocks;

  // Atomics to flag errors and completion
  std::atomic<bool> m_done = false;
  mutable std::atomic<bool> m_read_error = false;
  std::atomic<bool> m_transpose_done = false;

  // Buffer to store data read from file if banks are compressed. The
  // decompressed data will be written to the buffers
  mutable std::vector<char> m_compress_buffer;

  // Storage to read the header into for each event
  mutable LHCb::MDFHeader m_header;

  // Allen IDs of LHCb raw banks
  std::vector<int> m_bank_ids;

  // Memory slices, N for each raw bank type
  Slices m_slices;

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

  // Array to store the number of banks per bank type
  mutable std::array<unsigned int, LHCb::NBankTypes> m_banks_count;
  mutable bool m_sizes_known = false;

  // Run and event numbers present in each slice
  std::vector<EventIDs> m_event_ids;

  // File names to read
  std::vector<std::string> m_connections;

  // Storage for the currently open file
  mutable std::optional<int> m_input;

  // Iterator that points to the filename of the currently open file
  mutable std::vector<std::string>::const_iterator m_current;

  // Input data loop counter
  mutable size_t m_loop = 0;

  // Configuration struct
  MPIProviderConfig m_config;

  using base_class = InputProvider<MPIProvider<Banks...>>;

};
