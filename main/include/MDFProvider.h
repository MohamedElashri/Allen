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

#include <InputProvider.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <raw_bank.hpp>

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

  // FIXME: Make this configurable
  constexpr size_t n_buffers = 10;
  constexpr size_t offsets_size = 10001;
  constexpr size_t buffer_size = 100 * 1024 * 1024;
} // namespace

// FIXME: add start offset
template <BankTypes... Banks>
class MDFProvider final : public InputProvider<MDFProvider<Banks...>> {
public:
  MDFProvider(size_t n_slices, size_t n_events, std::vector<std::string> connections, bool checkChecksum = false) :
    InputProvider<MDFProvider<Banks...>>{n_slices, n_events},
    m_event_ids(n_slices), m_banks_count{0}, m_connections {std::move(connections)}, m_checkChecksum {checkChecksum}
  {
    m_buffers.resize(n_buffers);
    for (auto& [n_filled, offsets, buffer] : m_buffers) {
      // FIXME: Make this configurable
      buffer.resize(buffer_size);
      offsets.resize(offsets_size);
      offsets[0] = 0;
      n_filled = 0;
    }

    for (auto bank_type : this->types()) {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }

      // Fudge with extra 20% memory
      size_t n_bytes = std::lround(it->second * n_events * 1024 * bank_size_fudge_factor);
      m_banks_data[ib].reserve(n_bytes / sizeof(uint32_t));
      m_banks_offsets[ib].reserve(n_events);
      auto& slices = m_slices[ib];
      slices.reserve(n_slices);
      for (size_t i = 0; i < n_slices; ++i) {
        char* events_mem = nullptr;
        uint* offsets_mem = nullptr;
        cudaCheck(cudaMallocHost((void**) &events_mem, n_bytes));
        cudaCheck(cudaMallocHost((void**) &offsets_mem, (n_events + 1) * sizeof(uint)));

        offsets_mem[0] = 0;
        slices.emplace_back(gsl::span<char>{events_mem, n_bytes},
                            gsl::span<uint>{offsets_mem, n_events + 1},
                            1);
      }
    }

    m_current = m_connections.begin();
    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(n_events);
    }

    // Reserve 1MB for decompression
    m_compress_buffer.reserve(1024 * 1024);

    // Start to prefetch
    m_prefetch_thread = std::make_unique<std::thread>([this] { prefetch(); });
  }

  static constexpr const char* name = "MDF";

  virtual ~MDFProvider() {
    m_done = true;
    if (m_prefetch_thread) m_prefetch_thread->join();
  }

  std::vector<std::tuple<unsigned int, unsigned long>> const& event_ids(size_t slice_index) const
  {
    return m_event_ids[slice_index];
  }

  std::tuple<bool, size_t> fill(size_t slice_index, size_t n) override
  {
    bool good = true, full = false;
    unsigned int run = 0;
    unsigned long event = 0;
    size_t n_filled = 0;
    auto& event_ids = m_event_ids[slice_index];
    event_ids.clear();

    // "Reset" the slice
    for (auto bank_type : this->types()) {
      auto ib = to_integral<BankTypes>(bank_type);
      std::get<2>(m_slices[ib][slice_index]) = 1;
    }

    // Fill the slices for all bank types
    for (; n_filled < n && !full; ++n_filled) {
      // Read next event into buffer memory
      // TODO: avoid extra copy of all bank data by:
      // - obtaining all offsets
      // - checkig if buffer is full
      // - copying if not full
      std::tie(good, run, event) = next();
      if (!good) break;

      // Check if we're full
      full = std::any_of(this->types().begin(), this->types().end(), [this, slice_index](auto bank_type) {
        auto ib = to_integral<BankTypes>(bank_type);
        const auto& [slice, offsets, offsets_size] = m_slices[ib][slice_index];
        // Make sure both the size of the bank offsets and the bank contests are counted
        return (offsets[offsets_size - 1]
                + (m_banks_offsets[ib].size() + 1) * sizeof(uint)
                + m_banks_offsets[ib].back()) > slice.size();
      });
      if (!full) {
        // Fill the output buffers from the event-local buffers in the right format:
        // - number of raw banks (uint32_t)
        // - raw bank offset within event as number of char (one more than number of banks)
        // - raw bank data as uint32_t
        for (auto bank_type : this->types()) {
          auto ib = to_integral(bank_type);

          auto& [buf, event_offsets, event_offsets_size] = m_slices[ib][slice_index];
          auto event_offset = event_offsets[event_offsets_size - 1];

          // Copy in number of banks
          const auto& offsets = m_banks_offsets[ib];
          uint32_t n_banks = offsets.size() - 1;
          copy_data(event_offset, buf.data(), &n_banks, sizeof(n_banks));

          // Copy in bank offsets
          copy_data(event_offset, buf.data(), offsets.data(), offsets.size() * sizeof(uint32_t));

          // Copy in bank data; cannot use bank size as data is directly copied in
          const auto& bank_data = m_banks_data[ib];
          copy_data(event_offset, buf.data(), bank_data.data(), offsets.back());

          event_offsets[event_offsets_size++] = event_offset;
        }
        event_ids.emplace_back(run, event);
      }
    }
    return {good, n_filled};
  }

  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const
  {
    auto ib = to_integral<BankTypes>(bank_type);
    auto const& [banks, offsets, offsets_size] = m_slices[ib][slice_index];
    span<char const> b {banks.data(), offsets[offsets_size - 1]};
    span<unsigned int const> o {offsets.data(), offsets_size};
    return BanksAndOffsets {std::move(b), std::move(o)};
  }

  std::tuple<bool, size_t> fill_parallel(size_t slice_index, size_t n)
  {

    size_t i_read = 0;
    bool good = false, transpose_full = false, transpose_done = false;
    size_t n_filled = 0, n_transposed = 0;
    while(n_filled < n && !m_read_error) {
      {
        std::unique_lock<std::mutex> lock{m_mut};
        if (m_prefetched.empty() && !m_done) {
          m_cond.wait(lock, [this] { return !m_prefetched.empty(); });
        } else if (m_prefetched.empty()) {
          break;
        }
        i_read = m_prefetched.front();
        m_buffer_writable[i_read] = false;
      }

      if (!m_sizes_known) {
        if (!fill_counts(i_read)) {
          error_cout << "Failed to determine bank counts\n";
          return {false, 0};
        } else {
          for (auto bank_type : this->types()) {
            debug_cout << std::setw(10) << bank_name(bank_type) << " banks:"
                       << std::setw(4) << m_banks_count[to_integral(bank_type)] << "\n";
            m_sizes_known = true;
          }
        }
      }

      std::tie(good, transpose_full, n_transposed) = transpose_events(i_read, slice_index, this->n_events() - n_filled);
      debug_cout << "Transposed " << n_transposed << "from " << i_read << " error " << !good << " full " << transpose_full <<  "\n";
      n_filled += n_transposed;
      if (!transpose_full) {
        {
          std::unique_lock<std::mutex> lock{m_mut};
          m_prefetched.pop_front();
          m_buffer_writable[i_read] = true;
          transpose_done = m_prefetched.empty();
        }
        m_cond.notify_one();
      }
    }
    return {good && !m_read_error && !transpose_done, m_read_error ? 0 : n_filled};
  }

private:

  bool fill_counts(int i_buffer)
  {
    auto& [n_filled, offsets, buffer] = m_buffers[i_buffer];

    // Care only about the first event
    size_t i_event = 0;

    // Offsets are to the start of the event, which includes the header
    auto const* bank = buffer.data() + offsets[i_event];
    auto const* bank_end = buffer.data() + offsets[i_event + 1];

    while (bank < bank_end) {
      const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

      if (b->magic() != LHCb::RawBank::MagicPattern) {
        error_cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
        return false;
      }

      // Check if Allen processes this bank type
      auto bank_type_it = Allen::bank_types.find(b->type());
      if (bank_type_it == Allen::bank_types.end()
          || !this->types().count(bank_type_it->second)) {
        bank += b->totalSize();
        continue;
      }

      auto bank_type_index = to_integral(bank_type_it->second);
      ++m_banks_count[bank_type_index];

      // Increment overall bank pointer
      bank += b->totalSize();
    }

    return true;
  }

  // eof, error, n_bytes
  std::tuple<bool, bool, size_t> read_events(std::ifstream& input, int i_buffer)
  {
    auto& [n_filled, offsets, buffer] = m_buffers[i_buffer];

    auto* write = &buffer[0 + offsets[n_filled]];
    auto* buffer_start = &buffer[0];
    auto const* buffer_end = buffer.data() + buffer.size();
    size_t n_bytes = 0;
    LHCb::MDFHeader header;
    bool eof = false, error = false;
    gsl::span<char> bank_span;

    while (!eof && !error && n_filled < offsets.size() - 1) {
      input.read(reinterpret_cast<char*>(&header), header_size);
      if (input.good()) {
        // Check if there is enough space to read this event
        if (offsets[n_filled] + header.recordSize() - header_size > buffer.size()) {
          // move back by the size of the header to be able to read it again
          input.seekg(input.tellg() - header_size);
          break;
        }

        // Read the banks
        gsl::span<char> buffer_span{buffer_start + offsets[n_filled], buffer.size() - offsets[n_filled]};
        std::tie(eof, error, bank_span) = MDF::read_banks(input, header, std::move(buffer_span),
                                                          m_compress_buffer, m_checkChecksum);
      } else if (input.eof()) {
        info_cout << "Cannot read more data (Header). End-of-File reached.\n";
        eof = true;
      } else {
        error_cout << "Failed to read header\n";
        error = true;
      }

      offsets[++n_filled] = bank_span.end() - buffer_start;
      n_bytes += bank_span.size();
    }

    return {input.eof(), error, n_bytes};
  }

  std::tuple<bool, bool, size_t> transpose_events(int const i_buffer, int const slice_index, size_t n_events) {
    auto& [n_filled, offsets, buffer] = m_buffers[i_buffer];

    gsl::span<char>* banks_data = nullptr;
    gsl::span<unsigned int>* banks_offsets = nullptr;
    size_t* n_banks_offsets = nullptr;

    uint32_t* banks_write = nullptr;
    uint32_t* banks_offsets_write = nullptr;

    unsigned int bank_offset = 0;
    unsigned int bank_counter = 1;
    unsigned int bank_type_index = 0;

    bool full = false;

    // "Reset" the slice
    for (auto bank_type : this->types()) {
      auto ib = to_integral<BankTypes>(bank_type);
      std::get<1>(m_slices[ib][slice_index])[0] = 0;
      std::get<2>(m_slices[ib][slice_index]) = 1;
    }

    auto& event_ids = m_event_ids[slice_index];
    event_ids.clear();

    // L0Calo doesn't exist in the upgrade
    LHCb::RawBank::BankType prev_type = LHCb::RawBank::L0Calo;
    size_t i_event = 0;
    for (; i_event < n_filled && i_event < n_events; ++i_event) {
      // Offsets are to the start of the event, which includes the header
      auto const* bank = buffer.data() + offsets[i_event];
      auto const* bank_end = buffer.data() + offsets[i_event + 1];

      while (bank < bank_end) {
        const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);

        if (b->magic() != LHCb::RawBank::MagicPattern) {
          error_cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
          return {false, false, i_event};
        }

        // Decode the odin bank
        if (b->type() == LHCb::RawBank::ODIN) {
          auto odin = MDF::decode_odin(b);
          event_ids.emplace_back(odin.run_number, odin.event_number);
        }

        // Check if Allen processes this bank type
        auto bank_type_it = Allen::bank_types.find(b->type());
        if (bank_type_it == Allen::bank_types.end()
            || !this->types().count(bank_type_it->second)) {
          bank += b->totalSize();
          continue;
        }

        if (b->type() != prev_type) {
          // Switch to new type of banks
          bank_type_index = to_integral(bank_type_it->second);
          auto& slice = m_slices[bank_type_index][slice_index];
          prev_type = b->type();

          bank_counter = 1;
          banks_data = &std::get<0>(slice);
          banks_offsets = &std::get<1>(slice);
          n_banks_offsets = &std::get<2>(slice);

          // Calculate the size taken by storing the number of banks
          // and offsets to all banks within the event
          auto preamble_words = 2 + m_banks_count[bank_type_index];

          // Initialize offset to start of this set of banks from the
          // previous one and increment with the preamble size
          (*banks_offsets)[*n_banks_offsets] = ((*banks_offsets)[*n_banks_offsets - 1]
                                                + preamble_words * sizeof(uint32_t));

          // Three things to write for a new set of banks:
          // - number of banks/offsets
          // - offsets to individual banks
          // - bank data

          // Initialize point to write from offset of previous set
          banks_write = reinterpret_cast<uint32_t*>(banks_data->data() + (*banks_offsets)[*n_banks_offsets - 1]);

          // New offset to increment
          ++(*n_banks_offsets);

          // Write the number of banks
          banks_write[0] = m_banks_count[bank_type_index];

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
        auto b_start = b->begin<uint32_t>();
        auto b_end = b->end<uint32_t>();
        auto n_word = b_end - b_start;
        std::copy_n(b_start, n_word, banks_write + bank_offset + 1);

        bank_offset += 1 + n_word;

        // Write next offset in bytes
        banks_offsets_write[bank_counter] = bank_offset * sizeof(uint32_t);

        // Update "event" offset (in bytes)
        (*banks_offsets)[*n_banks_offsets - 1] += sizeof(uint32_t) * (1 + n_word);

        // Increment overall bank pointer
        bank += b->totalSize();
      }

      full = std::any_of(this->types().begin(), this->types().end(),
                         [this, slice_index, i_event, &offsets](auto bank_type) {
        auto ib = to_integral<BankTypes>(bank_type);
        const auto& [slice, slice_offsets, offsets_size] = m_slices[ib][slice_index];
        // Use the event size of the next event here instead of the
        // per bank size because that's not yet known for the next
        // event
        auto const event_size = offsets[i_event + 1] - offsets[i_event];
        return (slice_offsets[offsets_size - 1] + event_size) > slice.size();
      });
      if (full) {
        break;
      }
    }
    return {true, full, i_event};
  }

  std::tuple<bool, unsigned int, unsigned long> next() const
  {

    bool eof = false, error = false;
    gsl::span<const char> bank_span;
    unsigned int run = 0;
    unsigned long event = 0;

    if (!m_input && !open_file()) {
      return {false, 0, 0};
    }

    gsl::span<char> buffer_span{std::get<2>(m_buffers[0]).data(), std::get<2>(m_buffers[0]).capacity()};
    std::tie(eof, error, bank_span) = MDF::read_event(*m_input, m_header, buffer_span,
                                                      m_compress_buffer, m_checkChecksum);
    if (error) {
      return {false, 0, 0};
    }
    else if (eof) {
      if (open_file())
        return next();
      else {
        return {false, 0, 0};
      }
    }

    // Clear bank offsets
    for (auto& bo : m_banks_offsets) {
      bo.clear();
      bo.push_back(0);
    }

    // Clear bank data
    for (auto& bd : m_banks_data) {
      bd.clear();
    }

    // Put the banks in the event-local buffers
    const auto* bank = bank_span.begin();
    const auto* end = bank_span.end();
    while (bank < end) {
      const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
      if (b->magic() != LHCb::RawBank::MagicPattern) {
        std::cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
      }

      // Decode the odin bank
      if (b->type() == LHCb::RawBank::ODIN) {
        auto odin = MDF::decode_odin(b);
        run = odin.run_number;
        event = odin.event_number;
      }

      // Check if Allen processes this bank type
      auto bank_type_it = Allen::bank_types.find(b->type());
      if (bank_type_it == Allen::bank_types.end()
          || !this->types().count(bank_type_it->second)) {
        bank += b->totalSize();
        continue;
      }

      auto index = to_integral(bank_type_it->second);
      auto& bank_data = m_banks_data[index];
      auto& offsets = m_banks_offsets[index];
      auto offset = offsets.back() / sizeof(uint32_t);

      // Store this bank in the event-local buffers
      bank_data[offset] = b->sourceID();
      offset++;

      auto b_start = b->begin<uint32_t>();
      auto b_end = b->end<uint32_t>();
      auto n_word = b_end - b_start;
      if ((offset + n_word) > bank_data.capacity()) {
        bank_data.reserve(2 * bank_data.capacity());
      }
      std::copy_n(b_start, n_word, bank_data.data() + offset);
      offsets.push_back((offset + n_word) * sizeof(uint32_t));

      // Move to next raw bank
      bank += b->totalSize();
    }

    return {!eof, run, event};
  }

  bool open_file() const {
    bool good = false;
    while (!good && m_current != m_connections.end()) {
      if (m_input) m_input->close();
      m_input = std::make_unique<std::ifstream>(*m_current, std::ios::binary);
      if ((good = m_input->is_open())) {
        std::cout << "opened " << *m_current << std::endl;
      }
      else {
        std::cerr << "failed to open " << *m_current << std::endl;
      }
      ++m_current;
    }
    return good;
  }

  void prefetch() {

    if (!m_input && !open_file()) {
      m_read_error = true;
      return;
    }

    bool eof = false, error = false;
    size_t bytes_read = 0;

    while(!m_done && !m_read_error) {
      int i_buffer = 0;
      auto it = m_buffer_writable.end();
      {
        std::unique_lock<std::mutex> lock{m_mut};
        it = find(m_buffer_writable.begin(), m_buffer_writable.end(), true);
        if (it == m_buffer_writable.end()) {
          m_cond.wait(lock, [this] {
            return std::find(m_buffer_writable.begin(), m_buffer_writable.end(), true)
            != m_buffer_writable.end();
          });
          if (m_done) break;
        }
        *it = false;
      }
      i_buffer = distance(m_buffer_writable.begin(), it);
      info_cout << "prefetching " << i_buffer << "\n";

      // Read events; open next file if there are files left
      size_t to_read = this->n_events() - std::get<0>(m_buffers[i_buffer]);
      while(true) {
        std::tie(eof, error, bytes_read) = read_events(*m_input, i_buffer);
        m_bytes_read += bytes_read;
        if (error) {
          m_read_error = true;
          break;
        } else if (!eof) {
          break;
        } else if (!open_file()) {
          m_done = true;
          info_cout << "prefetch done\n";
          break;
        }
      }
      if (!error) {
        {
          std::unique_lock<std::mutex> lock{m_mut};
          m_prefetched.push_back(i_buffer);
        }
        m_cond.notify_one();
      }
    }
  }

  // Memory buffers to read binary data into from the file
  mutable std::vector<std::tuple<size_t, std::vector<unsigned int>, std::vector<char>>> m_buffers;

  // data members for prefetch thread
  std::mutex m_mut;
  std::condition_variable m_cond;
  std::deque<size_t> m_prefetched;
  std::vector<bool> m_buffer_writable;
  std::atomic<bool> m_done = false;
  std::atomic<bool> m_read_error = false;
  size_t m_bytes_read = 0;
  std::unique_ptr<std::thread> m_prefetch_thread;

  // Buffer to store data read from file if banks are compressed. The
  // decompressed data will be written to the buffers
  mutable std::vector<char> m_compress_buffer;

  // Storage to read the header into for each event
  mutable LHCb::MDFHeader m_header;

  // Offsets to all the banks in the single event that was read from file
  mutable std::array<std::vector<uint32_t>, NBankTypes> m_banks_offsets;

  // Raw bank data by subdetector as read from file
  mutable std::array<std::vector<uint32_t>, NBankTypes> m_banks_data;

  // Memory slices, N for each raw bank type
  std::array<std::vector<std::tuple<gsl::span<char>, gsl::span<unsigned int>, size_t>>, NBankTypes> m_slices;

  mutable std::array<unsigned int, NBankTypes> m_banks_count;
  mutable bool m_sizes_known = false;

  // Run and event numbers present in each slice
  std::vector<std::vector<std::tuple<unsigned int, unsigned long>>> m_event_ids;

  // File names to read
  std::vector<std::string> m_connections;

  // Check the checksum in the input events
  bool m_checkChecksum = false;

  // Storage for the currently open file
  mutable std::unique_ptr<std::ifstream> m_input;

  // Iterator that points to the filename of the currently open file
  mutable std::vector<std::string>::const_iterator m_current;

  using base_class = InputProvider<MDFProvider<Banks...>>;

};
