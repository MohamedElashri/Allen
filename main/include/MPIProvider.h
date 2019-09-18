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
#include <InputProvider.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <raw_bank.hpp>

#include "Transpose.h"
#include <CudaCommon.h>
#include <MPIConfig.h>
#include <Timer.h>

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
 *
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

  // default of events per prefetch buffer
  size_t events_per_buffer = 1200;

  // number of loops over input data
  size_t n_loops = 0;
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
  // Window transmission size
  size_t m_window_size;

  // Number of receiving slices
  size_t m_number_of_net_slices;

  // Maximum size of files to read
  size_t m_max_file_size;

public:
  MPIProvider(size_t n_slices, size_t events_per_slice, std::optional<size_t> n_events,
              std::vector<std::string> connections, size_t window_size, size_t number_of_net_slices,
              MPIProviderConfig config = MPIProviderConfig{}) :
    InputProvider<MPIProvider<Banks...>>{n_slices, events_per_slice, n_events},
    m_buffer_writable(config.n_buffers, true),
    m_slice_free(n_slices, true),
    m_banks_count{0},
    m_event_ids{n_slices},
    m_connections {std::move(connections)},
    m_window_size{window_size},
    m_number_of_net_slices{number_of_net_slices},
    m_config{config}
  {
    // Receive configuration of application
    MPI_Recv(&m_max_file_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::max_file_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    info_cout << MPI::rank_str() << "Maximum file size: " << m_max_file_size << " B\n";

    // Allocate as many net slices as configured, of maximum size
    std::vector<size_t> net_slice_size;
    std::vector<char*> net_slice_contents;
    for (int i=0; i<m_number_of_net_slices; ++i) {
      char* contents;
      MPI_Alloc_mem(m_max_file_size, MPI_INFO_NULL, &contents);
      net_slice_contents.push_back(contents);
      net_slice_size.push_back(0);
    }

    std::vector<std::mutex> net_mutexes (m_number_of_net_slices);
    std::vector<std::condition_variable> net_slice_produced_cv (m_number_of_net_slices);
    std::vector<std::condition_variable> net_slice_consumed_cv (m_number_of_net_slices);
    std::vector<bool> net_ready (m_number_of_net_slices);
    std::vector<bool> net_consumed (m_number_of_net_slices);

    for (int i=0; i<m_number_of_net_slices; ++i) {
      net_ready[i] = false;
      net_consumed[i] = false;
    }

    const auto worker_thread = [&] () {
      info_cout << MPI::rank_str() << "Started worker thread\n";
      // Iterate over the slices
      int current_slice = 0;

      while(true) {
        // Wait until the next net slice has been produced
        std::unique_lock<std::mutex> lk {net_mutexes[current_slice]};
        net_slice_produced_cv[current_slice].wait(lk, [&current_slice, &net_ready]{return net_ready[current_slice];});

        // Consume the net slice
        std::chrono::milliseconds duration(100);
        std::this_thread::sleep_for(duration);
        // info_cout << "Data is consumed " << current_slice << "\n";
        net_ready[current_slice] = false;
        net_consumed[current_slice] = true;

        // Notify a net slice has been consumed
        lk.unlock();
        net_slice_consumed_cv[current_slice].notify_one();

        current_slice = (current_slice + 1) % number_of_net_slices;
      }
    };

    std::thread worker(worker_thread);

    std::vector<MPI_Request> requests (m_window_size);

    // Iterate over the slices
    int current_slice = 0;
    int startup_iteration = 0;

    size_t reporting_period = 5;
    size_t bytes_received = 0;
    size_t meps_received = 0;
    Timer t;
    Timer t_origin;

    // for (int i=0; i<number_of_events; ++i) {
    while (true) {
      if (startup_iteration == number_of_net_slices) {
        // We need to wait for consumption
        std::unique_lock<std::mutex> lk {net_mutexes[current_slice]};
        net_slice_consumed_cv[current_slice].wait(lk, [&current_slice, &net_consumed]{return net_consumed[current_slice];});
      }

      size_t current_event_size;
      char* contents = net_slice_contents[current_slice];

      MPI_Recv(&current_event_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::event_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

      // info_cout << MPI::rank_str() << "Current event size: " << current_event_size << "\n";
      net_slice_size[current_slice] = current_event_size;

      // Number of full-size (MPI::mdf_chunk_size) messages
      int n_messages = current_event_size / MPI::mdf_chunk_size;
      // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
      int rest = current_event_size - n_messages * MPI::mdf_chunk_size;
      // Number of parallel sends
      int n_sends = n_messages > m_window_size ? m_window_size : n_messages;

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
          MPI_Waitany(m_window_size, requests.data(), &r, MPI_STATUS_IGNORE);
          char* message = contents + k * MPI::mdf_chunk_size;
          MPI_Irecv(message, MPI::mdf_chunk_size, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + k,
                    MPI_COMM_WORLD, &requests[r]);
      }
      // Last send (if necessary)
      if (rest) {
          int r;
          MPI_Waitany(m_window_size, requests.data(), &r, MPI_STATUS_IGNORE);
          char* message = contents + n_messages * MPI::mdf_chunk_size;
          MPI_Irecv(message, rest, MPI_BYTE, MPI::sender, MPI::message::event_send_tag_start + n_messages,
                    MPI_COMM_WORLD, &requests[r]);
      }
      // Wait until all chunks have been sent
      MPI_Waitall(n_sends, requests.data(), MPI_STATUSES_IGNORE);

      // Notify data is ready to consumer thread
      {
        std::lock_guard<std::mutex> lk {net_mutexes[current_slice]};
        // info_cout << "Data is ready " << current_slice << "\n";
        net_ready[current_slice] = true;
        net_consumed[current_slice] = false;
      }
      net_slice_produced_cv[current_slice].notify_one();

      if (startup_iteration < number_of_net_slices) {
        ++startup_iteration;
      }

      current_slice = (current_slice + 1) % number_of_net_slices;

      bytes_received += current_event_size;
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
    }

    // Preallocate prefetch buffer memory
    m_buffers.resize(config.n_buffers);
    for (auto& [n_filled, event_offsets, buffer] : m_buffers) {
      buffer.resize(config.events_per_buffer * average_event_size * bank_size_fudge_factor * kB);
      event_offsets.resize(config.offsets_size);
      event_offsets[0] = 0;
      n_filled = 0;
    }

    // Reinitialize to take the possible minimum number of events per
    // slice into account
    events_per_slice = this->events_per_slice();

    // Allocate slice memory that will contain transposed banks ready
    // for processing by the Allen kernels
    for (auto bank_type : {Banks...}) {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }

      // Fudge with extra 20% memory
      size_t n_bytes = std::lround(it->second * events_per_slice * bank_size_fudge_factor * kB);
      auto& slices = m_slices[ib];
      slices.reserve(n_slices);
      for (size_t i = 0; i < n_slices; ++i) {
        char* events_mem = nullptr;
        uint* offsets_mem = nullptr;

        cudaCheck(cudaMallocHost((void**) &events_mem, n_bytes));
        cudaCheck(cudaMallocHost((void**) &offsets_mem, (events_per_slice + 1) * sizeof(uint)));

        offsets_mem[0] = 0;
        slices.emplace_back(gsl::span<char>{events_mem, n_bytes},
                            gsl::span<uint>{offsets_mem, events_per_slice + 1},
                            1);
      }
    }

    // Initialize the current input filename
    m_current = m_connections.begin();

    // Allocate space to store event ids
    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(events_per_slice);
    }

    // Cache the mapping of LHCb::RawBank::BankType to Allen::BankType
    m_bank_ids.resize(LHCb::RawBank::LastType);
    for (int bt = LHCb::RawBank::L0Calo; bt < LHCb::RawBank::LastType; ++bt) {
      auto it = Allen::bank_types.find(static_cast<LHCb::RawBank::BankType>(bt));
      if (it != Allen::bank_types.end()) {
        m_bank_ids[bt] = to_integral(it->second);
      } else {
        m_bank_ids[bt] = -1;
      }
    }

    // Reserve 1MB for decompression
    m_compress_buffer.reserve(1u * MB);

    // Start prefetch thread and count bank types one a single buffer
    // is available
    {
      // aquire lock
      std::unique_lock<std::mutex> lock{m_prefetch_mut};

      // start prefetch thread
      m_prefetch_thread = std::make_unique<std::thread>([this] { prefetch(); });

      // Wait for first read buffer to be full
      m_prefetch_cond.wait(lock, [this] { return !m_prefetched.empty() || m_read_error; });
      if (!m_read_error) {
        // Count number of banks per flavour
        bool count_success = false;

        // Offsets are to the start of the event, which includes the header
        auto i_read = m_prefetched.front();
        auto& [n_filled, event_offsets, buffer] = m_buffers[i_read];
        std::tie(count_success, m_banks_count) = fill_counts({buffer.data(), event_offsets[1]});
        if (!count_success) {
          error_cout << "Failed to determine bank counts\n";
          m_read_error = true;
        } else {
          for (auto bank_type : this->types()) {
            debug_cout << std::setw(10) << bank_name(bank_type) << " banks:"
                       << std::setw(4) << m_banks_count[to_integral(bank_type)] << "\n";
            m_sizes_known = true;
          }
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
    m_prefetch_cond.notify_one();
    if (m_prefetch_thread) m_prefetch_thread->join();

    // Set a flat to indicate all transpose threads should exit, wake
    // them up and join the threads. Ensure any waiting calls to
    // get_slice also return.
    m_transpose_done = true;
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

  //

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

  /**
   * @brief      Function to run in each thread transposing events
   *
   * @param      thread ID
   *
   * @return     void
   */
  void transpose(int thread_id) {

    size_t i_read = 0;
    std::optional<size_t> slice_index;

    bool good = false, transpose_full = false;
    size_t n_transposed = 0;

    while(!m_read_error && !m_transpose_done) {

      // Get a buffer to read from
      {
        std::unique_lock<std::mutex> lock{m_prefetch_mut};
        if (m_prefetched.empty() && !m_transpose_done) {
          m_prefetch_cond.wait(lock, [this] { return !m_prefetched.empty() || m_transpose_done; });
        }
        if (m_prefetched.empty()) {
          this->debug_output("Transpose done: " + std::to_string(m_transpose_done) + " " + std::to_string(m_prefetched.empty()), thread_id);
          break;
        }
        i_read = m_prefetched.front();
        m_prefetched.pop_front();
        this->debug_output("Got read buffer index " + std::to_string(i_read), thread_id);

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
      std::tie(good, transpose_full, n_transposed) = transpose_events<Banks...>(m_buffers[i_read],
                                                                                m_slices,
                                                                                *slice_index,
                                                                                m_bank_ids,
                                                                                m_banks_count,
                                                                                event_ids,
                                                                                this->events_per_slice());
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

      // Check if the read buffer is now empty. If it is, it can be
      // reused, otherwise give it to another transpose thread once a
      // new target slice is available
      if (n_transposed == std::get<0>(m_buffers[i_read])) {
        slice_index.reset();
        {
          std::unique_lock<std::mutex> lock{m_prefetch_mut};
          m_buffer_writable[i_read] = true;
          // "Reset" buffer; the 0th offset is always 0.
          std::get<0>(m_buffers[i_read]) = 0;
          m_transpose_done = m_done && m_prefetched.empty();
        }
        m_prefetch_cond.notify_one();
      } else {
        // Put this prefetched slice back on the prefetched queue so
        // somebody else can finish it
        std::unique_lock<std::mutex> lock{m_prefetch_mut};
        m_prefetched.push_front(i_read);
      }
    }
  }

  /**
   * @brief      Open an input file; called from the prefetch thread
   *
   * @return     success
   */
  bool open_file() const {
    bool good = false;

    // Check if there are still files available
    while (!good) {
      // If looping on input is configured, do it
      if (m_current == m_connections.end()) {
        if (++m_loop < m_config.n_loops) {
          m_current = m_connections.begin();
        } else {
          break;
        }
      }

      if (m_input) ::close(*m_input);

      m_input = ::open(m_current->c_str(), O_RDONLY);
      if (*m_input != -1) {
        // read the first header, needed by subsequent calls to read_events
        ssize_t n_bytes = ::read(*m_input, reinterpret_cast<char*>(&m_header), header_size);
        good = (n_bytes > 0);
      }

      if (good) {
        info_cout << "Opened " << *m_current << "\n";
      } else {
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
  void prefetch() {



    // bool eof = false, error = false, buffer_full = false, prefetch_done = false;
    // size_t bytes_read = 0;

    // auto to_read = this->n_events();
    // size_t eps = this->events_per_slice();

    // // Loop while there are no errors and the flag to exit is not set
    // while(!m_done && !m_read_error && (!to_read || *to_read > 0)) {

    //   // open the first file
    //   if (!m_input && !open_file()) {
    //     m_read_error = true;
    //     m_prefetch_cond.notify_one();
    //     return;
    //   }

    //   // Obtain a prefetch buffer to read into, if none is available,
    //   // wait until one of the transpose threads is done with its
    //   // prefetch buffer
    //   auto it = m_buffer_writable.end();
    //   {
    //     std::unique_lock<std::mutex> lock{m_prefetch_mut};
    //     it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
    //     if (it == m_buffer_writable.end()) {
    //       this->debug_output("Waiting for free buffer");
    //       m_prefetch_cond.wait(lock, [this] {
    //         return std::find(m_buffer_writable.begin(), m_buffer_writable.end(), true)
    //         != m_buffer_writable.end() || m_done;
    //       });
    //       if (m_done) {
    //         break;
    //       } else {
    //         it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
    //       }
    //     }
    //     // Flag the prefetch buffer as unavailable
    //     *it = false;
    //   }
    //   size_t i_buffer = distance(m_buffer_writable.begin(), it);
    //   auto& read_buffer = m_buffers[i_buffer];

    //   // Read events into the prefetch buffer, open new files as
    //   // needed
    //   while(true) {
    //     size_t read = std::get<0>(read_buffer);
    //     size_t to_prefetch = to_read ? std::min(eps, *to_read) : eps;
    //     std::tie(eof, error, buffer_full, bytes_read) = read_events(*m_input, read_buffer,
    //                                                                 m_header,
    //                                                                 m_compress_buffer,
    //                                                                 to_prefetch,
    //                                                                 m_config.check_checksum);
    //     size_t n_read = std::get<0>(read_buffer) - read;
    //     if (to_read) {
    //       *to_read -= std::min(*to_read, n_read);
    //     }

    //     if (error) {
    //       // Error encountered
    //       m_read_error = true;
    //       break;
    //     } else if (to_read && *to_read == 0) {
    //       if (m_config.n_loops != 0 && m_loop < (m_config.n_loops - 1)) {
    //         // Set things such that the next call to open_file will
    //         // result in a loop
    //         this->debug_output("Loop " + std::to_string(m_loop + 1));
    //         to_read = this->n_events();
    //         m_current = m_connections.end();
    //         if (m_input) ::close(*m_input);
    //         m_input.reset();
    //       } else {
    //         // No events left to read
    //         this->debug_output("Prefetch done: n_events reached");
    //         prefetch_done = true;
    //       }
    //       break;
    //     } else if (std::get<0>(read_buffer) == eps || buffer_full) {
    //       // Number of events in a slice reached or buffer is full
    //       break;
    //     } else if (eof && !open_file()) {
    //       // Try to open the next file, if there is none, prefetching
    //       // is done.
    //       if (!m_read_error) {
    //         this->debug_output("Prefetch done: eof and no more files");
    //       }
    //       prefetch_done = true;
    //       break;
    //     }
    //   }

    //   this->debug_output("Read " + std::to_string(std::get<0>(read_buffer)) + " events into " + std::to_string(i_buffer));

    //   // Notify a transpose thread that a new buffer of events is
    //   // ready. If prefetching is done, wake up all threads
    //   if (!error) {
    //     {
    //       std::unique_lock<std::mutex> lock{m_prefetch_mut};
    //       m_prefetched.push_back(i_buffer);
    //     }
    //     if (prefetch_done) {
    //       m_done = prefetch_done;
    //       this->debug_output("Prefetch notifying all");
    //       m_prefetch_cond.notify_all();
    //     } else {
    //       this->debug_output("Prefetch notifying one");
    //       m_prefetch_cond.notify_one();
    //     }
    //   }
    // }
    // m_prefetch_cond.notify_one();
  }

  // Memory buffers to read binary data into from the file
  mutable ReadBuffers m_buffers;

  // data members for prefetch thread
  std::mutex m_prefetch_mut;
  std::condition_variable m_prefetch_cond;
  std::deque<size_t> m_prefetched;
  std::vector<bool> m_buffer_writable;
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
  mutable std::array<unsigned int, NBankTypes> m_banks_count;
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
