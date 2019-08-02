#pragma once

#include <thread>
#include <vector>
#include <array>
#include <deque>
#include <mutex>
#include <atomic>
#include <chrono>
#include <algorithm>
#include <condition_variable>

#include <Logger.h>
#include <InputProvider.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <raw_bank.hpp>

#ifndef NO_CUDA
#include <CudaCommon.h>
#endif

namespace {
  // Copy data from the event-local buffer to the global
  // one, while keeping the global buffer's size consistent with its
  // content
  inline void copy_data(unsigned int& event_offset, char* buf, const void* source, size_t s)
  {
    ::memcpy(buf + event_offset, source, s);
    event_offset += s;
  }

  constexpr auto header_size = sizeof(LHCb::MDFHeader);

} // namespace

using ReadBuffer = std::tuple<size_t, std::vector<unsigned int>,
                              std::vector<unsigned int>, std::vector<char>>;
using ReadBuffers = std::vector<ReadBuffer>;

using Slice = std::tuple<gsl::span<char>, gsl::span<unsigned int>, size_t>;
using BankSlices = std::vector<Slice>;
using Slices = std::array<BankSlices, NBankTypes>;

struct MDFProviderConfig {
  bool check_checksum = false;
  size_t n_buffers = 10;
  size_t n_transpose_threads = 5;
  size_t offsets_size = 10001;
  size_t events_per_buffer = 1200;
  size_t n_loops = 0;
};

// success, number of banks per type
std::tuple<bool, std::array<unsigned int, NBankTypes>> fill_counts(ReadBuffer const& read_buffer)
{
  auto& [n_filled, event_offsets, bank_offsets, buffer] = read_buffer;

  std::array<unsigned int, NBankTypes> count{0};

  // Care only about the first event
  size_t i_event = 0;

  // Offsets are to the start of the event, which includes the header
  auto const* bank = buffer.data() + event_offsets[i_event];
  auto const* bank_end = buffer.data() + event_offsets[i_event + 1];

  while (bank < bank_end) {
    const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

    if (b->magic() != LHCb::RawBank::MagicPattern) {
      error_cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      return {false, count};
    }

    // Check if Allen processes this bank type
    auto bank_type_it = Allen::bank_types.find(b->type());
    if (bank_type_it == Allen::bank_types.end()) {
      bank += b->totalSize();
      continue;
    }

    auto bank_type_index = to_integral(bank_type_it->second);
    ++count[bank_type_index];

    // Increment overall bank pointer
    bank += b->totalSize();
  }

  return {true, count};
}

// eof, error, full, n_bytes
std::tuple<bool, bool, bool, size_t> read_events(std::ifstream& input, ReadBuffer& read_buffer,
                                                 LHCb::MDFHeader& header,
                                                 std::vector<char> compress_buffer,
                                                 size_t n_events, bool check_checksum)
{
  auto& [n_filled, event_offsets, bank_offsets, buffer] = read_buffer;

  auto* write = &buffer[0 + event_offsets[n_filled]];
  auto* buffer_start = &buffer[0];
  auto const* buffer_end = buffer.data() + buffer.size();
  size_t n_bytes = 0;
  bool eof = false, error = false, full = false;
  gsl::span<char> bank_span;

  while (!eof && !error && n_filled < event_offsets.size() - 1 && n_filled < n_events) {
    // Read the banks
    gsl::span<char> buffer_span{buffer_start + event_offsets[n_filled], buffer.size() - event_offsets[n_filled]};
    std::tie(eof, error, bank_span) = MDF::read_banks(input, header, std::move(buffer_span),
                                                      compress_buffer, check_checksum);
    event_offsets[++n_filled] = bank_span.end() - buffer_start;
    n_bytes += bank_span.size();

    // read the next header
    input.read(reinterpret_cast<char*>(&header), header_size);
    if (input.good()) {
      // Check if there is enough space to read this event
      int compress = header.compression() & 0xF;
      int expand = (header.compression() >> 4) + 1;
      int event_size = (header.recordSize() + header_size +
                        2 * (sizeof(LHCb::RawBank) + sizeof(int)) +
                        (compress ? expand * (header.recordSize() - header_size) : 0));
      if (event_offsets[n_filled] + event_size > buffer.size()) {
        full = true;
        break;
      }
    } else if (input.eof()) {
      info_cout << "cannot read more data (Header). End-of-File reached.\n";
      eof = true;
    } else {
      error_cout << "failed to read header\n";
      error = true;
    }
  }
  return {eof, error, full, n_bytes};
}

template <BankTypes... Banks>
std::tuple<bool, bool, size_t> transpose_events(const ReadBuffer& read_buffer,
                                                Slices& slices, int const slice_index,
                                                EventIDs& event_ids,
                                                std::vector<int> const& bank_ids,
                                                std::array<unsigned int, NBankTypes> const& banks_count,
                                                size_t n_events) {
  auto const& [n_filled, event_offsets, bank_offsets, buffer] = read_buffer;

  unsigned int* banks_offsets = nullptr;
  size_t* n_banks_offsets = nullptr;

  uint32_t* banks_write = nullptr;
  uint32_t* banks_offsets_write = nullptr;

  unsigned int bank_offset = 0;
  unsigned int bank_counter = 1;
  unsigned int bank_type_index = 0;

  bool full = false;

  // "Reset" the slice
  for (auto bank_type : {Banks...}) {
    auto ib = to_integral<BankTypes>(bank_type);
    std::get<1>(slices[ib][slice_index])[0] = 0;
    std::get<2>(slices[ib][slice_index]) = 1;
  }

  event_ids.clear();

  // L0Calo doesn't exist in the upgrade
  LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;
  size_t i_event = 0;
  for (; i_event < n_filled && i_event < n_events; ++i_event) {
    // Offsets are to the start of the event, which includes the header
    auto const* bank = buffer.data() + event_offsets[i_event];
    auto const* bank_end = buffer.data() + event_offsets[i_event + 1];

    while (bank < bank_end) {
      const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

      if (b->magic() != LHCb::RawBank::MagicPattern) {
        error_cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
        return {false, false, i_event};
        // Decode the odin bank
      }
      auto bt = b->type();
      if (bt == LHCb::RawBank::ODIN) {
        auto odin = MDF::decode_odin(b);
        event_ids.emplace_back(odin.run_number, odin.event_number);
        bank += b->totalSize();
        continue;
      } else if (bt >= LHCb::RawBank::LastType || bank_ids[bt] == -1) {
        bank += b->totalSize();
        continue;
      } else if (bt != prev_type) {
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
        banks_offsets[*n_banks_offsets] = (banks_offsets[*n_banks_offsets - 1]
                                           + preamble_words * sizeof(uint32_t));

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
      } else {
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

    for (auto bank_type : {Banks...}) {
      auto ib = to_integral<BankTypes>(bank_type);
      const auto& [slice, slice_offsets, offsets_size] = slices[ib][slice_index];
      // Use the event size of the next event here instead of the
      // per bank size because that's not yet known for the next
      // event
      auto const event_size = event_offsets[i_event + 1] - event_offsets[i_event];
      if ((slice_offsets[offsets_size - 1] + event_size) > slice.size()) {
        full = true;
        goto transpose_end;
      }
    }
  }
 transpose_end:
  return {true, full, i_event};
}

template <BankTypes... Banks>
class MDFProvider final : public InputProvider<MDFProvider<Banks...>> {
public:
  MDFProvider(size_t n_slices, size_t events_per_slice, std::optional<size_t> n_events,
              std::vector<std::string> connections, MDFProviderConfig config = MDFProviderConfig{}) :
    InputProvider<MDFProvider<Banks...>>{n_slices, events_per_slice, n_events},
    m_event_ids{n_slices}, m_banks_count{0},
    m_buffer_writable(config.n_buffers, true),
    m_slice_free(n_slices, true),
    m_connections {std::move(connections)},
    m_config{config}
  {
    m_buffers.resize(config.n_buffers);
    for (auto& [n_filled, event_offsets, bank_offsets, buffer] : m_buffers) {
      // FIXME: Make this configurable
      buffer.resize(config.events_per_buffer * average_event_size * 1024);
      event_offsets.resize(config.offsets_size);
      event_offsets[0] = 0;
      bank_offsets.resize(config.offsets_size * NBankTypes);
      n_filled = 0;
    }

    // Reinitialize to take the possible minimum into account
    events_per_slice = this->events_per_slice();

    for (auto bank_type : {Banks...}) {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }

      // Fudge with extra 20% memory
      size_t n_bytes = std::lround(it->second * events_per_slice * 1024 * bank_size_fudge_factor);
      m_banks_data[ib].reserve(n_bytes / sizeof(uint32_t));
      m_banks_offsets[ib].reserve(events_per_slice);
      auto& slices = m_slices[ib];
      slices.reserve(n_slices);
      for (size_t i = 0; i < n_slices; ++i) {
        char* events_mem = nullptr;
        uint* offsets_mem = nullptr;

#ifndef NO_CUDA
        cudaCheck(cudaMallocHost((void**) &events_mem, n_bytes));
        cudaCheck(cudaMallocHost((void**) &offsets_mem, (events_per_slice + 1) * sizeof(uint)));
#else
        events_mem = static_cast<char*>(malloc(n_bytes));
        offsets_mem = static_cast<uint*>(malloc((events_per_slice + 1) * sizeof(uint)));
#endif
        offsets_mem[0] = 0;
        slices.emplace_back(gsl::span<char>{events_mem, n_bytes},
                            gsl::span<uint>{offsets_mem, events_per_slice + 1},
                            1);
      }
    }

    m_current = m_connections.begin();
    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(events_per_slice);
    }

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
    m_compress_buffer.reserve(1024 * 1024);

    // Start prefetch thread and count bank types
    {
      // aquire lock
      std::unique_lock<std::mutex> lock{m_prefetch_mut};

      // start prefetch thread
      m_prefetch_thread = std::make_unique<std::thread>([this] { prefetch(); });

      // Wait for first read buffer to be full
      m_prefetch_cond.wait(lock, [this] { return !m_prefetched.empty() || m_read_error; });
      if (!m_read_error) {
        size_t i_read = m_prefetched.front();

        // Count number of banks per flavour
        bool count_success = false;
        std::tie(count_success, m_banks_count) = fill_counts(m_buffers[i_read]);
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

    if (m_config.n_buffers <= 1) {
      warning_cout << "too few read buffers requested, setting it to 2\n";
      m_config.n_buffers = 2;
    }

    if (m_config.n_transpose_threads > m_config.n_buffers - 1) {
      warning_cout << "too many transpose threads requested with respect "
        "to the number of read buffers; reducing the number of threads to " << m_config.n_buffers - 1;
      m_config.n_transpose_threads = m_config.n_buffers - 1;
    }

    // FIXME: not thread-safe -> move to constructor
    if (m_transpose_threads.empty() && !m_read_error) {
      for (size_t i = 0; i < m_config.n_transpose_threads; ++i) {
        m_transpose_threads.emplace_back([this, i] { transpose(i); });
      }
    }


  }

  static constexpr const char* name = "MDF";

  virtual ~MDFProvider() {
    m_done = true;
    m_prefetch_cond.notify_one();

    if (m_prefetch_thread) m_prefetch_thread->join();

    m_transpose_done = true;
    m_prefetch_cond.notify_all();
    m_transpose_cond.notify_all();

    for (auto& thread : m_transpose_threads) {
      thread.join();
    }
  }

  std::vector<std::tuple<unsigned int, unsigned long>> const& event_ids(size_t slice_index) const
  {
    return m_event_ids[slice_index];
  }

  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const
  {
    auto ib = to_integral<BankTypes>(bank_type);
    auto const& [banks, offsets, offsets_size] = m_slices[ib][slice_index];
    span<char const> b {banks.data(), offsets[offsets_size - 1]};
    span<unsigned int const> o {offsets.data(), offsets_size};
    return BanksAndOffsets {std::move(b), std::move(o)};
  }

  // success, timed_out, slice_index, n_filled
  std::tuple<bool, bool, size_t, size_t> get_slice(std::optional<unsigned int> timeout = std::optional<unsigned int>{})
  {
    bool timed_out = false;
    size_t slice_index = 0, n_filled = 0;
    std::unique_lock<std::mutex> lock{m_transpose_mut};
    if (!m_read_error && !m_transpose_done || !m_transposed.empty()) {
      if (m_transposed.empty()) {
        if (timeout) {
          timed_out = !m_transpose_cond.wait_for(lock, std::chrono::milliseconds{*timeout},
                                                 [this] { return !m_transposed.empty() && !m_read_error; });
        } else {
          m_transpose_cond.wait(lock, [this] { return !m_transposed.empty() && !m_read_error; });
        }
      }
      std::tie(slice_index, n_filled) = m_transposed.front();
      m_transposed.pop_front();
    }

    return {!m_read_error && !m_transpose_done, timed_out, slice_index, m_read_error ? 0 : n_filled};
  }

  void slice_free(size_t slice_index)
  {
    bool freed = false;
    {
      std::unique_lock<std::mutex> lock{m_transpose_mut};
      if (!m_slice_free[slice_index]) {
        m_slice_free[slice_index] = true;
        freed = true;
      }
    }
    if (freed) {
      debug_output("freed slice " + std::to_string(slice_index));
      m_transpose_cond.notify_one();
    }
  }

private:

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
        if (m_transpose_done || m_prefetched.empty()) {
          debug_output("transpose done: done  " + std::to_string(m_transpose_done) + " " + std::to_string(m_prefetched.empty()), thread_id);
          break;
        }
        i_read = m_prefetched.front();
        m_prefetched.pop_front();
        debug_output("got read buffer index " + std::to_string(i_read), thread_id);

        m_buffer_writable[i_read] = false;
      }

      // Get a slice to write to
      if (!slice_index) {
        debug_output("getting slice index", thread_id);
        auto it = m_slice_free.end();
        {
          std::unique_lock<std::mutex> lock{m_transpose_mut};
          it = find(m_slice_free.begin(), m_slice_free.end(), true);
          if (it == m_slice_free.end()) {
            debug_output("waiting for free slice", thread_id);
            m_transpose_cond.wait(lock, [this, &it] {
                                          it = std::find(m_slice_free.begin(), m_slice_free.end(), true);
                                          return it != m_slice_free.end() || m_transpose_done;
                                        });
            if (m_transpose_done && it == m_slice_free.end()) {
              break;
            }
          }
          *it = false;
        }
        if (it != m_slice_free.end()) {
          slice_index = distance(m_slice_free.begin(), it);
          debug_output("got slice index " + std::to_string(*slice_index), thread_id);
        }

        // Reset the slice
        for (auto bank_type : {Banks...}) {
          auto ib = to_integral<BankTypes>(bank_type);
          std::get<2>(m_slices[ib][*slice_index]) = 1;
        }
      }

      std::tie(good, transpose_full, n_transposed) = transpose_events<Banks...>(m_buffers[i_read],
                                                                                m_slices, *slice_index,
                                                                                m_event_ids[*slice_index],
                                                                                m_bank_ids,
                                                                                m_banks_count,
                                                                                this->events_per_slice());
      if (m_read_error || !good) {
        m_read_error = true;
        break;
      }

      debug_output("transposed " + std::to_string(*slice_index) + " " + std::to_string(good)
                   + " " + std::to_string(transpose_full) + " " + std::to_string(n_transposed),
                   thread_id);

      {
        std::unique_lock<std::mutex> lock{m_transpose_mut};
        m_transposed.emplace_back(*slice_index, n_transposed);
      }
      m_transpose_cond.notify_one();

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

  bool open_file() const {
    bool good = false;
    while (!good && m_current != m_connections.end()) {
      if (m_input) m_input->close();
      m_input = std::make_unique<std::ifstream>(*m_current, std::ios::binary);

      if (m_input->is_open()) {
        // read the first header
        m_input->read(reinterpret_cast<char*>(&m_header), header_size);
        good = !m_input->eof() && m_input->good();
      }

      if (good) {
        std::cout << "opened " << *m_current << std::endl;
      } else {
        std::cerr << "failed to open " << *m_current << std::endl;
      }
      ++m_current;

      if (m_current == m_connections.end() && m_loop++ < m_config.n_loops) {
        m_current = m_connections.begin();
      }
    }
    return good;
  }

  void prefetch() {

    if (!m_input && !open_file()) {
      m_read_error = true;
      return;
    }

    bool eof = false, error = false, buffer_full = false, prefetch_done = false;
    size_t bytes_read = 0;

    auto to_read = this->n_events();
    size_t eps = this->events_per_slice();

    while(!m_done && !m_read_error && (!to_read || *to_read > 0)) {
      auto it = m_buffer_writable.end();
      {
        std::unique_lock<std::mutex> lock{m_prefetch_mut};
        it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
        if (it == m_buffer_writable.end()) {
          debug_output("waiting for free buffer");
          m_prefetch_cond.wait(lock, [this] {
            return std::find(m_buffer_writable.begin(), m_buffer_writable.end(), true)
            != m_buffer_writable.end() || m_done;
          });
          if (m_done) {
            break;
          } else {
            it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
          }
        }
        *it = false;
      }
      size_t i_buffer = distance(m_buffer_writable.begin(), it);
      auto& read_buffer = m_buffers[i_buffer];

      while(true) {
        size_t read = std::get<0>(read_buffer);
        size_t to_prefetch = to_read ? std::min(eps, *to_read) : eps;
        std::tie(eof, error, buffer_full, bytes_read) = read_events(*m_input, read_buffer,
                                                                    m_header,
                                                                    m_compress_buffer,
                                                                    to_prefetch,
                                                                    m_config.check_checksum);
        size_t n_read = std::get<0>(read_buffer) - read;
        if (to_read) {
          *to_read -= n_read;
        }

        if (error) {
          m_read_error = true;
          break;
        } else if (std::get<0>(read_buffer) == eps || buffer_full) {
          break;
        } else if (to_read && *to_read == 0) {
          debug_output("prefetch done: n_events reached");
          prefetch_done = true;
          break;
        } else if (eof && !open_file()) {
          debug_output("prefetch done: eof and no more files");
          prefetch_done = true;
          break;
        }
      }

      // Read events; open next file if there are files left
      debug_output("read " + std::to_string(std::get<0>(read_buffer)) + " events into " + std::to_string(i_buffer));

      if (!error) {
        {
          std::unique_lock<std::mutex> lock{m_prefetch_mut};
          m_prefetched.push_back(i_buffer);
        }
        m_done = prefetch_done;
        debug_output("notifying one");
        m_prefetch_cond.notify_one();
      }
    }
  }

  template <typename MSG>
  void debug_output(const MSG& msg, std::optional<size_t> const thread_id = {}) {
    if (logger::ll.verbosityLevel >= logger::verbose) {
      std::unique_lock<std::mutex> lock{m_output_mut};
      verbose_cout << (thread_id ? std::to_string(*thread_id) + " " : std::string{}) << msg << "\n";
    }
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
  std::atomic<bool> m_read_error = false;
  std::atomic<bool> m_transpose_done = false;

  // Buffer to store data read from file if banks are compressed. The
  // decompressed data will be written to the buffers
  mutable std::vector<char> m_compress_buffer;

  // Storage to read the header into for each event
  mutable LHCb::MDFHeader m_header;

  // Allen IDs of LHCb raw banks
  std::vector<int> m_bank_ids;

  // Offsets to all the banks in the single event that was read from file
  mutable std::array<std::vector<uint32_t>, NBankTypes> m_banks_offsets;

  // Raw bank data by subdetector as read from file
  mutable std::array<std::vector<uint32_t>, NBankTypes> m_banks_data;

  // Memory slices, N for each raw bank type
  Slices m_slices;

  // Mutex, condition varaible and queue for parallel transposition of slices
  std::mutex m_transpose_mut;
  std::condition_variable m_transpose_cond;
  std::deque<std::tuple<size_t, size_t>> m_transposed;

  // Keep track of what slices are free
  std::vector<bool> m_slice_free;

  // Threads transposing data
  std::vector<std::thread> m_transpose_threads;

  // Mutex for ordered debug output
  std::mutex m_output_mut;

  // Array to store the number of banks per bank type
  mutable std::array<unsigned int, NBankTypes> m_banks_count;
  mutable bool m_sizes_known = false;

  // Run and event numbers present in each slice
  std::vector<EventIDs> m_event_ids;

  // File names to read
  std::vector<std::string> m_connections;

  // Storage for the currently open file
  mutable std::unique_ptr<std::ifstream> m_input;

  // Iterator that points to the filename of the currently open file
  mutable std::vector<std::string>::const_iterator m_current;

  // Input data loop counter
  mutable size_t m_loop = 0;

  MDFProviderConfig m_config;

  using base_class = InputProvider<MDFProvider<Banks...>>;

};
