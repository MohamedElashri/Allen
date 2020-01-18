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
#include <cassert>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <Logger.h>
#include <InputProvider.h>
#include <BankTypes.h>
#include <Timer.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <read_mep.hpp>
#include <raw_bank.hpp>
#include <write_mdf.hpp>

#include "Transpose.h"
#include "TransposeMEP.h"

#ifndef CPU
#define CPU
#include <MEPTools.h>
#undef CPU
#else
#include <MEPTools.h>
#endif

#ifdef HAVE_MPI
#include "MPIConfig.h"
#endif

#ifndef NO_CUDA
#include <CudaCommon.h>
#endif

namespace {
  using namespace Allen::Units;
} // namespace

/**
 * @brief      Configuration parameters for the MEPProvider
 */
struct MEPProviderConfig {
  // check the MDF checksum if it is available
  bool check_checksum = false;

  // number of prefetch buffers
  size_t n_buffers = 10;

  // number of transpose threads
  size_t n_transpose_threads = 5;

  int window_size = 4;

  bool use_mpi = false;

  bool non_stop = true;

  bool transpose_mep = false;

  std::string output_file = "";
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
template<BankTypes... Banks>
class MEPProvider final : public InputProvider<MEPProvider<Banks...>> {
public:
  MEPProvider(
    size_t n_slices,
    size_t events_per_slice,
    std::optional<size_t> n_events,
    std::vector<std::string> connections,
    MEPProviderConfig config = MEPProviderConfig {}) noexcept(false) :
    InputProvider<MEPProvider<Banks...>> {n_slices, events_per_slice, n_events},
    m_buffer_status(config.n_buffers), m_slice_free(n_slices, true), m_banks_count {0},
    m_event_ids {n_slices}, m_connections {std::move(connections)}, m_config {config}
  {

    if (m_config.transpose_mep) {
      info_cout << "Providing events in Allen layout by transposing MEPs\n";
    } else {
      info_cout << "Providing events in MEP layout\n";
    }

    m_buffer_transpose = m_buffer_status.begin();
    m_buffer_reading = m_buffer_status.begin();

    if (m_config.use_mpi) {
#ifdef HAVE_MPI
      MPI_Recv(
        &m_packing_factor, 1, MPI_SIZE_T, MPI::sender, MPI::message::packing_factor, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

      // Allocate as many net slices as configured, of expected size
      // Packing factor can be done dynamically if needed
      size_t n_bytes = std::lround(m_packing_factor * average_event_size * bank_size_fudge_factor * kB);
      for (size_t i = 0; i < config.n_buffers; ++i) {
        char* contents = nullptr;
        MPI_Alloc_mem(n_bytes, MPI_INFO_NULL, &contents);
#if !defined(NO_CUDA) && !defined(CPU)
        cudaCheck(cudaHostRegister(contents, n_bytes, cudaHostRegisterDefault));
#endif
        m_net_slices.emplace_back(
          EB::Header {}, gsl::span<char const> {contents, n_bytes}, MEP::Blocks {}, MEP::SourceOffsets {}, n_bytes);
        m_mpi_buffers.emplace_back(contents);
      }
#else
      error_cout << "MPI requested, but Allen was not built with MPI support.\n";
      throw std::runtime_error {"No MPI supoprt"};
#endif
    }
    else {
      m_read_buffers.resize(m_config.n_buffers);
      m_net_slices.resize(m_config.n_buffers);
    }

    // Reinitialize to take the possible minimum number of events per
    // slice into account
    events_per_slice = this->events_per_slice();

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

    // start MPI receive or MEP reading thread
    if (m_config.use_mpi) {
#ifdef HAVE_MPI
      m_mpi_thread = std::thread {&MEPProvider::mpi_read, this};
#endif
    }
    else {
      m_mpi_thread = std::thread {&MEPProvider::mep_read, this};
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
  virtual ~MEPProvider() noexcept(false)
  {

    // Set flag to indicate the prefetch thread should exit, wake it
    // up and join it
    m_done = true;
    m_transpose_done = true;
    m_mpi_cond.notify_one();
    m_mpi_thread.join();

    // Set a flat to indicate all transpose threads should exit, wake
    // them up and join the threads. Ensure any waiting calls to
    // get_slice also return.
    m_mpi_cond.notify_all();
    m_transpose_cond.notify_all();
    m_slice_cond.notify_all();

    for (auto& thread : m_transpose_threads) {
      thread.join();
    }

#ifdef HAVE_MPI
    for (auto* buf : m_mpi_buffers) {
#if !defined(NO_CUDA) && !defined(CPU)
      cudaCheck(cudaHostUnregister(buf));
#endif
      MPI_Free_mem(buf);
    }
#endif
  }

  /**
   * @brief      Obtain event IDs of events stored in a given slice
   *
   * @param      slice index
   *
   * @return     EventIDs of events in given slice
   */
  EventIDs event_ids(size_t slice_index, std::optional<size_t> first = {}, std::optional<size_t> last = {}) const override
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
    auto ib = to_integral<BankTypes>(bank_type);
    auto const& [banks, data_size, offsets, offsets_size] = m_slices[ib][slice_index];

    BanksAndOffsets bno;
    auto& spans = std::get<0>(bno);
    spans.reserve(banks.size());
    for (auto s : banks) {
      spans.emplace_back(s);
    }
    std::get<1>(bno) = m_config.transpose_mep ? offsets[offsets_size - 1] : data_size;
    std::get<2>(bno) = offsets;
    return bno;
  }

  /**
   * @brief      Get a slice that is ready for processing; thread-safe
   *
   * @param      optional timeout
   *
   * @return     (good slice, timed out, slice index, number of events in slice)
   */
  std::tuple<bool, bool, bool, size_t, size_t> get_slice(
    std::optional<unsigned int> timeout = std::optional<unsigned int> {}) override
  {
    bool timed_out = false, done = false;
    size_t slice_index = 0, n_filled = 0;
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
      }
    }

    // Check if I/O and transposition is done and return a slice index
    auto n_writable = count_writable();
    done = m_transpose_done && m_transposed.empty() && n_writable == m_buffer_status.size();

    if (timed_out && logger::ll.verbosityLevel >= logger::verbose) {
      this->debug_output(
        "get_slice timed out; error " + std::to_string(m_read_error) + " done " + std::to_string(done) + " n_filled " +
        std::to_string(n_filled));
    }
    else if (!timed_out) {
      this->debug_output(
        "get_slice returning " + std::to_string(slice_index) + "; error " + std::to_string(m_read_error) + " done " +
        std::to_string(done) + " n_filled " + std::to_string(n_filled));
    }

    return {!m_read_error, done, timed_out, slice_index, m_read_error ? 0 : n_filled};
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
    int i_buffer = 0;
    {
      std::unique_lock<std::mutex> lock {m_slice_mut};
      if (!m_slice_free[slice_index]) {
        m_slice_free[slice_index] = true;
        freed = true;

        // Clear relation between slice and buffer
        i_buffer = std::get<0>(m_slice_to_buffer[slice_index]);
        auto& status = m_buffer_status[i_buffer];
        m_slice_to_buffer[slice_index] = {-1, 0, 0};

        // If MEPs are not transposed and the respective buffer is no
        // longer in use, set it to writable
        if (status.work_counter == 0 &&
            (std::find_if(m_slice_to_buffer.begin(), m_slice_to_buffer.end(),
                          [i_buffer] (const auto& entry) {
                            return std::get<0>(entry) == i_buffer;
                          }) == m_slice_to_buffer.end())) {
          status.writable = true;
          set_writable = true;
        }
      }
    }
    if (freed) {
      this->debug_output("Freed slice " + std::to_string(slice_index));
      m_slice_cond.notify_one();
    }
    if (set_writable) {
      this->debug_output("Set buffer " + std::to_string(i_buffer) + " writable");
      m_mpi_cond.notify_one();
    }
  }

  void event_sizes(size_t const slice_index, gsl::span<unsigned int const> const selected_events,
                   std::vector<size_t>& sizes) const override
  {
    int i_buffer = 0;
    size_t interval_start = 0, interval_end = 0;
    std::tie(i_buffer, interval_start, interval_end) = m_slice_to_buffer[slice_index];
    auto const& blocks = std::get<2>(m_net_slices[i_buffer]);
    for (unsigned int i = 0; i < selected_events.size(); ++i) {
      auto event = selected_events[i];
      sizes[i] += std::accumulate(blocks.begin(), blocks.end(), 0ul,
        [event, interval_start, this] (size_t s, const auto& entry) {
          auto const& block_header = std::get<0>(entry);
          return s + LHCb::RawBank::hdrSize() + block_header.sizes[interval_start + event];
        });
    }
  }

  void copy_banks(size_t const slice_index, unsigned int const event,
                  gsl::span<char> buffer) const override {
    auto [i_buffer, interval_start, interval_end] = m_slice_to_buffer[slice_index];
    const auto mep_event = interval_start + event;

    auto const& [mep_header, mpi_slice, blocks, fragment_offsets, slice_size] = m_net_slices[i_buffer];

    unsigned char prev_type = 0;
    auto block_index = 0;
    size_t offset = 0;

    for (size_t i_block = 0; i_block < blocks.size(); ++i_block) {
      auto const& [block_header, block_data] = blocks[i_block];
      auto lhcb_type = block_header.types[0];

      if (prev_type != lhcb_type) {
        block_index = 0;
        prev_type = lhcb_type;
      }

      // All banks are taken directly from the block data to be able
      // to treat banks needed by Allen and banks not needed by Allen
      // in the same way
      auto const fragment_offset = fragment_offsets[i_block][mep_event];
      auto fragment_size = block_header.sizes[mep_event];

      assert((offset + fragment_size) < buffer.size());
      offset += add_raw_bank(block_header.types[mep_event],
                             mep_header.versions[i_block], mep_header.source_ids[i_block],
                             {block_data.data() + fragment_offset, fragment_size},
                             buffer.data() + offset);
      ++block_index;
    }
  }

private:
  size_t count_writable() const
  {
    return std::accumulate(m_buffer_status.begin(), m_buffer_status.end(), 0ul, [](size_t s, BufferStatus const& stat) {
      return s + stat.writable;
    });
  }

  void allocate_storage(size_t i_read)
  {
    if (m_sizes_known) return;

    // Count number of banks per flavour
    bool count_success = false;

    // Offsets are to the start of the event, which includes the header
    auto& [mep_header, mpi_slice, blocks, input_offsets, slice_size] = m_net_slices[i_read];
    size_t n_blocks = mep_header.n_blocks;
    // gsl::span<char const> block_span{mpi_slice.data() + mep_header.header_size(mep_header.n_blocks),
    // mep_header.mep_size};
    if (m_packing_factor == 0) {
      m_packing_factor = mep_header.packing_factor;
    }
    else {
      assert(mep_header.packing_factor == m_packing_factor);
    }

    auto eps = this->events_per_slice();
    auto n_interval = m_packing_factor / eps;
    auto rest = m_packing_factor % eps;
    for (auto& s : m_buffer_status) {
      s.intervals.reserve(2 * (n_interval + rest));
    }

    for (auto& [mep_header, mpi_slice, blocks, input_offsets, slice_size] : m_net_slices) {
      // The number of blocks in a MEP is known, use it to allocate
      // temporary storage used during transposition
      blocks.resize(n_blocks);
      input_offsets.resize(n_blocks);
      for (auto& offsets : input_offsets) {
        // info_cout << "Packing factor: " << mep_header.packing_factor << "\n";
        offsets.resize(m_packing_factor + 1);
      }
    }

    std::tie(count_success, m_banks_count) = MEP::fill_counts(mep_header, mpi_slice);

    // Allocate slice memory that will contain transposed banks ready
    // for processing by the Allen kernels
    auto size_fun = [this, eps](BankTypes bank_type) -> std::tuple<size_t, size_t> {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }
      // In case of direct MEP output, no memory should be allocated.
      if (!m_config.transpose_mep) {
        auto it = std::find(m_bank_ids.begin(), m_bank_ids.end(), to_integral(bank_type));
        auto lhcb_type = std::distance(m_bank_ids.begin(), it);
        auto n_blocks = m_banks_count[lhcb_type];
        // 0 to not allocate fragment memory; -1 to correct for +1 in allocate_slices: re-evaluate
        return {0, 2 + n_blocks + (1 + eps) * (1 + n_blocks) - 2};
      }
      else {
        return {std::lround(it->second * eps * bank_size_fudge_factor * kB), eps};
      }
    };
    m_slices = allocate_slices<Banks...>(this->n_slices(), size_fun);
    m_slice_to_buffer = std::vector(this->n_slices(), std::tuple{-1, 0ul, 0ul});

    if (!count_success) {
      error_cout << "Failed to determine bank counts\n";
      m_read_error = true;
    }
    else {
      m_sizes_known = true;
    }
  }

  /**
   * @brief      Open an input file; called from the prefetch thread
   *
   * @return     success
   */
  bool open_file() const
  {
    bool good = false;

    // Check if there are still files available
    while (!good) {
      // If looping on input is configured, do it
      if (m_current == m_connections.end()) {
        if (m_config.non_stop) {
          m_current = m_connections.begin();
        }
        else {
          break;
        }
      }

      if (m_input) m_input->close();

      m_input = MDF::open(*m_current, O_RDONLY);
      if (m_input->good) {
        info_cout << "Opened " << *m_current << "\n";
        good = true;
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

  std::tuple<std::vector<BufferStatus>::iterator, size_t> get_mep_buffer(
    std::function<bool(BufferStatus const&)> pred,
    std::vector<BufferStatus>::iterator start,
    std::unique_lock<std::mutex>& lock)
  {
    // Obtain a prefetch buffer to read into, if none is available,
    // wait until one of the transpose threads is done with its
    // prefetch buffer
    auto find_buffer = [this, start, &pred] {
      auto it = std::find_if(start, m_buffer_status.end(), pred);
      if (it == m_buffer_status.end()) {
        it = std::find_if(m_buffer_status.begin(), start, pred);
        if (it == start) it = m_buffer_status.end();
      }
      return it;
    };

    auto it = find_buffer();
    if (it == m_buffer_status.end() && !m_transpose_done) {
      m_mpi_cond.wait(lock, [this, &it, &find_buffer] {
        it = find_buffer();
        return it != m_buffer_status.end() || m_transpose_done;
      });
    }
    return {it, distance(m_buffer_status.begin(), it)};
  }

  void set_intervals(std::vector<std::tuple<size_t, size_t>>& intervals, size_t n_events)
  {
    if (n_events == 0) return;
    const auto eps = this->events_per_slice();
    auto n_interval = n_events / eps;
    auto rest = n_events % eps;
    if (rest) {
      debug_cout << "Set interval (rest): " << n_interval * eps << "," << n_interval * eps + rest << "\n";
      intervals.emplace_back(n_interval * eps, n_interval * eps + rest);
    }
    for (size_t i = n_interval; i != 0; --i) {
      debug_cout << "Set interval: " << (i - 1) * eps << "," << i * eps << "\n";
      intervals.emplace_back((i - 1) * eps, i * eps);
    }
  }

  // mep reader thread
  void mep_read()
  {
    bool receive_done = false;
    EB::Header mep_header;

    auto to_read = this->n_events();
    if (to_read) debug_cout << "Reading " << *to_read << " events\n";
    auto to_publish = 0;

    while (!receive_done) {
      // info_cout << MPI::rank_str() << "round " << current_file << "\n";

      // open the first file
      if (!m_input && !open_file()) {
        m_read_error = true;
        m_mpi_cond.notify_one();
        return;
      }
      size_t i_buffer;
      {
        std::unique_lock<std::mutex> lock {m_mpi_mutex};
        std::tie(m_buffer_reading, i_buffer) =
          get_mep_buffer([](BufferStatus const& s) { return s.writable; }, m_buffer_reading, lock);
        m_buffer_reading->writable = false;
      }
      if (m_done) {
        receive_done = true;
        break;
      }

      this->debug_output("Writing to MEP slice index " + std::to_string(i_buffer));

      auto& read_buffer = m_read_buffers[i_buffer];
      auto& [mep_header, buffer_span, blocks, input_offsets, buffer_size] = m_net_slices[i_buffer];

      bool success = false, eof = false;

      while (!success || eof) {
        std::tie(eof, success, mep_header, buffer_span) = MEP::read_mep(*m_input, read_buffer);

        if (!eof) {
          debug_cout << "Read mep with packing factor " << mep_header.packing_factor << "\n";
          if (to_read && success) {
            to_publish = std::min(*to_read, size_t{mep_header.packing_factor});
            *to_read -= to_publish;
          }
          else {
            to_publish = mep_header.packing_factor;
          }
        }

        if (!success) {
          // Error encountered
          m_read_error = true;
          break;
        }
        else if ((to_read && *to_read == 0) || (eof && !open_file())) {
          // Try to open the next file, if there is none, prefetching
          // is done.
          if (!m_read_error) {
            this->debug_output("Prefetch done: eof and no more files");
          }
          receive_done = true;
          break;
        }
      }

      if (!m_sizes_known) {
        allocate_storage(i_buffer);
      }

      // Notify a transpose thread that a new buffer of events is
      // ready. If prefetching is done, wake up all threads
      if (success) {
        {
          std::unique_lock<std::mutex> lock {m_mpi_mutex};

          auto& status = m_buffer_status[i_buffer];
          assert(status.work_counter == 0);

          if (!eof && to_publish != 0) {
            set_intervals(status.intervals, to_read ? to_publish : size_t{mep_header.packing_factor});
          }
          else {
            // We didn't read anything, so free the buffer we got again
            status.writable = true;
          }
        }
        if (receive_done) {
          m_done = receive_done;
          this->debug_output("Prefetch notifying all");
          m_mpi_cond.notify_all();
        }
        else if (!eof) {
          this->debug_output("Prefetch notifying one");
          m_mpi_cond.notify_one();
        }
      }
      m_mpi_cond.notify_one();
    }
  }

#ifdef HAVE_MPI
  // MPI reader thread
  void mpi_read()
  {

    int window_size = m_config.window_size;
    std::vector<MPI_Request> requests(window_size);

    // Iterate over the slices
    size_t reporting_period = 5;
    size_t bytes_received = 0;
    size_t meps_received = 0;
    size_t number_of_meps = 0;
    Timer t;
    Timer t_origin;
    bool error = false;
    bool receive_done = false;

    MPI_Recv(
      &number_of_meps, 1, MPI_SIZE_T, MPI::sender, MPI::message::number_of_meps, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    size_t current_mep = 0;
    while (m_config.non_stop || current_mep < number_of_meps) {
      // info_cout << MPI::rank_str() << "round " << current_file << "\n";

      // Obtain a prefetch buffer to read into, if none is available,
      // wait until one of the transpose threads is done with its
      // prefetch buffer
      size_t i_buffer;
      {
        std::unique_lock<std::mutex> lock {m_mpi_mutex};
        std::tie(m_buffer_reading, i_buffer) =
          get_mep_buffer([](BufferStatus const& s) { return s.writable; }, m_buffer_reading, lock);
        m_buffer_reading->writable = false;
        assert(m_buffer_reading->work_counter == 0);
      }

      auto& [mep_header, buffer_span, blocks, input_offsets, buffer_size] = m_net_slices[i_buffer];
      char*& contents = m_mpi_buffers[i_buffer];

      size_t mep_size = 0;
      MPI_Recv(&mep_size, 1, MPI_SIZE_T, MPI::sender, MPI::message::event_size, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

      // Reallocate if needed
      if (mep_size > buffer_size) {
        buffer_size = mep_size * bank_size_fudge_factor;
#if !defined(NO_CUDA) && !defined(CPU)
        cudaCheck(cudaHostUnregister(contents));
#endif
        MPI_Free_mem(contents);
        MPI_Alloc_mem(buffer_size, MPI_INFO_NULL, &contents);
#if !defined(NO_CUDA) && !defined(CPU)
        try {
          cudaCheck(cudaHostRegister(contents, buffer_size, cudaHostRegisterDefault));
        } catch (std::invalid_argument const&) {
          m_read_error = true;
          break;
        }
#endif
        buffer_span = gsl::span {contents, buffer_size};
      }

      // Number of full-size (MPI::mdf_chunk_size) messages
      int n_messages = mep_size / MPI::mdf_chunk_size;
      // Size of the last message (if the MFP size is not a multiple of MPI::mdf_chunk_size)
      int rest = mep_size - n_messages * MPI::mdf_chunk_size;
      // Number of parallel sends
      int n_sends = n_messages > window_size ? window_size : n_messages;

      // info_cout << MPI::rank_str() << "n_messages " << n_messages << ", rest " << rest << ", n_sends " << n_sends <<
      // "\n";

      // Initial parallel sends
      for (int k = 0; k < n_sends; k++) {
        char* message = contents + k * MPI::mdf_chunk_size;
        MPI_Irecv(
          message,
          MPI::mdf_chunk_size,
          MPI_BYTE,
          MPI::sender,
          MPI::message::event_send_tag_start + k,
          MPI_COMM_WORLD,
          &requests[k]);
      }
      // Sliding window sends
      for (int k = n_sends; k < n_messages; k++) {
        int r;
        MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
        char* message = contents + k * MPI::mdf_chunk_size;
        MPI_Irecv(
          message,
          MPI::mdf_chunk_size,
          MPI_BYTE,
          MPI::sender,
          MPI::message::event_send_tag_start + k,
          MPI_COMM_WORLD,
          &requests[r]);
      }
      // Last send (if necessary)
      if (rest) {
        int r;
        MPI_Waitany(window_size, requests.data(), &r, MPI_STATUS_IGNORE);
        char* message = contents + n_messages * MPI::mdf_chunk_size;
        MPI_Irecv(
          message,
          rest,
          MPI_BYTE,
          MPI::sender,
          MPI::message::event_send_tag_start + n_messages,
          MPI_COMM_WORLD,
          &requests[r]);
      }
      // Wait until all chunks have been sent
      MPI_Waitall(n_sends, requests.data(), MPI_STATUSES_IGNORE);

      mep_header = EB::Header {contents};
      buffer_span = gsl::span {contents, mep_size};

      if (!m_sizes_known) {
        allocate_storage(i_buffer);
      }

      bytes_received += mep_size;
      meps_received += 1;
      if (t.get_elapsed_time() >= reporting_period) {
        const auto seconds = t.get_elapsed_time();
        const double rate = (double) meps_received / seconds;
        double bandwidth = ((double) (bytes_received * 8)) / (1024 * 1024 * 1024 * seconds);

        printf("[%lf, %lf] Throughput: %lf MEP/s, %lf Gb/s\n", t_origin.get_elapsed_time(), seconds, rate, bandwidth);

        bytes_received = 0;
        meps_received = 0;

        t.restart();
      }

      // Notify a transpose thread that a new buffer of events is
      // ready. If prefetching is done, wake up all threads
      if (!error) {
        {
          std::unique_lock<std::mutex> lock {m_mpi_mutex};
          set_intervals(m_buffer_status[i_buffer].intervals, size_t{mep_header.packing_factor});
          assert(m_buffer_status[i_buffer].work_counter == 0);
        }
        if (receive_done) {
          m_done = receive_done;
          this->debug_output("Prefetch notifying all");
          m_mpi_cond.notify_all();
        }
        else {
          this->debug_output("Prefetch notifying one");
          m_mpi_cond.notify_one();
        }
      }
      m_mpi_cond.notify_one();

      current_mep++;
    }
  }
#endif

  /**
   * @brief      Function to run in each thread transposing events
   *
   * @param      thread ID
   *
   * @return     void
   */
  void transpose(int thread_id)
  {

    size_t i_buffer = 0;
    std::tuple<size_t, size_t> interval;
    std::optional<size_t> slice_index;

    bool good = false, transpose_full = false;
    size_t n_transposed = 0;

    auto has_intervals = [](BufferStatus const& s) { return !s.intervals.empty(); };

    while (!m_read_error && !m_transpose_done) {
      // Get a buffer to read from
      {
        std::unique_lock<std::mutex> lock {m_mpi_mutex};
        std::tie(m_buffer_transpose, i_buffer) = get_mep_buffer(has_intervals, m_buffer_transpose, lock);
        if (m_transpose_done) {
          break;
        }
        auto& status = *m_buffer_transpose;
        assert(!status.intervals.empty());

        interval = status.intervals.back();
        status.intervals.pop_back();

        ++(status.work_counter);
        status.writable = false;

        this->debug_output(
          "Got MEP slice index " + std::to_string(i_buffer) + " interval [" + std::to_string(std::get<0>(interval)) +
            "," + std::to_string(std::get<1>(interval)) + ")",
          thread_id);
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
          slice_index = distance(m_slice_free.begin(), it);
          this->debug_output("Got slice index " + std::to_string(*slice_index), thread_id);

          // Keep track of what buffer this slice belonged to
          m_slice_to_buffer[*slice_index] = {i_buffer, std::get<0>(interval), std::get<1>(interval)};
        }
      }

      // Reset the slice
      auto& event_ids = m_event_ids[*slice_index];
      reset_slice<Banks...>(m_slices, *slice_index, event_ids, !m_config.transpose_mep);

      // MEP data
      auto& [mep_header, mep_data, blocks, source_offsets, slice_size] = m_net_slices[i_buffer];

      // Fill blocks
      MEP::find_blocks(mep_header, mep_data, blocks);

      // Fill fragment offsets
      MEP::fragment_offsets(blocks, source_offsets);

      // Transpose or calculate offsets
      if (m_config.transpose_mep) {
        // Transpose the events into the slice
        std::tie(good, transpose_full, n_transposed) = MEP::transpose_events(
          m_slices, *slice_index, m_bank_ids, m_banks_count, event_ids, mep_header, blocks, source_offsets, interval);
        this->debug_output(
          "Transposed slice " + std::to_string(*slice_index) + "; good: " + std::to_string(good) +
            ";full: " + std::to_string(transpose_full) + "; n_transposed:  " + std::to_string(n_transposed),
          thread_id);
      }
      else {
        // Calculate fragment offsets in MEP per sub-detector
        std::tie(good, transpose_full, n_transposed) =
          MEP::mep_offsets(m_slices, *slice_index, m_bank_ids, m_banks_count, event_ids, mep_header, blocks, interval);
        this->debug_output("Calculated MEP offsets for slice " + std::to_string(*slice_index), thread_id);
      }

      if (m_read_error || !good) {
        std::unique_lock<std::mutex> lock {m_mpi_mutex};
        auto& status = m_buffer_status[i_buffer];
        --status.work_counter;
        m_read_error = true;
        m_transpose_cond.notify_one();
        break;
      }

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
        std::unique_lock<std::mutex> lock {m_mpi_mutex};

        auto& status = m_buffer_status[i_buffer];
        --status.work_counter;

        if (n_transposed != std::get<1>(interval) - std::get<0>(interval)) {
          status.intervals.emplace_back(std::get<0>(interval) + n_transposed, std::get<1>(interval));
        }
        else if (status.work_counter == 0) {
          m_transpose_done =
            m_done && std::all_of(m_buffer_status.begin(), m_buffer_status.end(), [](BufferStatus const& stat) {
              return stat.intervals.empty() && stat.work_counter == 0;
            });
        }
      }
    }
  }

  // Slices
  size_t m_packing_factor = 0;
  std::vector<std::vector<char>> m_read_buffers;
  std::vector<char*> m_mpi_buffers;
  MEP::Slices m_net_slices;

  // data members for mpi thread
  std::mutex m_mpi_mutex;
  std::condition_variable m_mpi_cond;

  std::vector<BufferStatus> m_buffer_status;
  std::vector<BufferStatus>::iterator m_buffer_transpose;
  std::vector<BufferStatus>::iterator m_buffer_reading;
  std::thread m_mpi_thread;

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
  std::vector<std::tuple<int, size_t, size_t>> m_slice_to_buffer;

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

  // Storage for the currently open input file
  mutable std::optional<Allen::IO> m_input;

  // Iterator that points to the filename of the currently open file
  mutable std::vector<std::string>::const_iterator m_current;

  // Input data loop counter
  mutable size_t m_loop = 0;

  // Configuration struct
  MEPProviderConfig m_config;

  using base_class = InputProvider<MEPProvider<Banks...>>;
};
