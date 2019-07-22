#pragma once

#include <InputProvider.h>
#include "mdf_header.hpp"
#include "read_mdf.hpp"
#include "raw_bank.hpp"

namespace {
  // Copy data from the event-local buffer to the global
  // one, while keeping the global buffer's size consistent with its
  // content
  inline void copy_data(unsigned int& event_offset, char* buf, const void* source, size_t s)
  {
    ::memcpy(buf + event_offset, source, s);
    event_offset += s;
  }

  constexpr auto headerSize = sizeof(LHCb::MDFHeader);

} // namespace

// FIXME: add start offset
template <BankTypes... Banks>
class MDFProvider final : public InputProvider<MDFProvider<Banks...>> {
public:
  MDFProvider(size_t n_slices, size_t n_events, std::vector<std::string> connections, bool checkChecksum = false) :
    InputProvider<MDFProvider<Banks...>>{n_slices, n_events},
    m_event_ids(n_slices), m_banks_count{0}, m_connections {std::move(connections)}, m_checkChecksum {checkChecksum}
  {
    for (auto& [n_filled, offsets, buffer] : m_buffers) {
      // FIXME: Make this configurable
      buffer.resize(100 * 1024 * 1024);
      offsets.resize(10001);
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
  }

  static constexpr const char* name = "MDF";


  void close() {
    if (m_input) m_input->close();
  }

  std::vector<std::tuple<unsigned int, unsigned long>> const& event_ids(size_t slice_index) const
  {
    return m_event_ids[slice_index];
  }

  std::tuple<bool, bool, size_t> fill(size_t slice_index, size_t n)
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
    return {good, full, n_filled};
  }

  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const
  {
    auto ib = to_integral<BankTypes>(bank_type);
    auto const& [banks, offsets, offsets_size] = m_slices[ib][slice_index];
    span<char const> b {banks.data(), offsets[offsets_size - 1]};
    span<unsigned int const> o {offsets.data(), offsets_size};
    return BanksAndOffsets {std::move(b), std::move(o)};
  }

  std::tuple<bool, bool, size_t> fill_parallel(size_t slice_index, size_t n)
  {
    open_file();
    size_t i_buffer = 0;
    auto [eof, full, n_bytes] = read_events(*m_input, i_buffer, n);
    auto n_filled = std::get<0>(m_buffers[i_buffer]);
    info_cout << "Read " << n_filled << " events; eof "
              << eof << " full " << full
              << " kB read " << n_bytes / 1024 << "\n";

    if (!m_sizes_known) {
      if (!fill_counts(i_buffer)) {
        error_cout << "Failed to determine number bank counts\n";
        return {false, false, 0};
      } else {
        for (auto bank_type : this->types()) {
          info_cout << std::setw(10) << bank_name(bank_type) << " banks:"
                    << std::setw(4) << m_banks_count[to_integral(bank_type)] << "\n";
          m_sizes_known = true;
        }
      }
    }

    auto [good, transpose_full, n_transposed] = transpose_events(i_buffer, slice_index, n);
    info_cout << "Transposed " << n_transposed << " error " << !good << " full " << transpose_full <<  "\n";
    return {good, full, n_filled};
  }

private:

  bool fill_counts(int i_buffer)
  {
    auto& [n_filled, offsets, buffer] = m_buffers[i_buffer];

    // Care only about the first event
    size_t i_event = 0;

    // Offsets are to the start of the event, which includes the header
    auto const* bank = buffer.data() + offsets[i_event] + headerSize + 1;
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

  std::tuple<bool, bool, size_t> read_events(std::ifstream& input, int i_buffer, size_t n_events)
  {
    auto& [n_filled, offsets, buffer] = m_buffers[i_buffer];

    auto* write = &buffer[0 + offsets[n_filled]];
    auto* buffer_start = &buffer[0];
    auto const* buffer_end = buffer.data() + buffer.size();
    size_t n_bytes = 0;
    bool full = false;

    while (!input.eof() && n_filled < n_events && n_filled < offsets.size()) {
      input.read(write, headerSize);
      auto const* header = reinterpret_cast<LHCb::MDFHeader const*>(write);
      auto readSize = header->recordSize() - headerSize;

      // To be able to read the next one, there should at least be
      // sufficient space for the banks and the header of the next
      // event
      if ((write + readSize + headerSize) > buffer_end) {
        full = true;
        break;
      }
      input.read(write + headerSize, readSize);

      // Set writing location to end of this event
      write += headerSize + readSize;
      offsets[++n_filled] = write - buffer_start;
      n_bytes += headerSize + readSize;
    }

    // If not EOF: backup the size of the header to be able to read it again.
    if (!input.eof()) {
      input.seekg(input.tellg() - headerSize);
    }

    return {input.eof(), full || n_filled == offsets.size(), n_bytes};
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
      auto const* bank = buffer.data() + offsets[i_event] + headerSize + 1;
      auto const* bank_end = buffer.data() + offsets[i_event + 1];

      size_t vp_size = 0;

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

        // if (bank_type_it->second == BankTypes::VP) {
        //   vp_size += b->totalSize() - 4;
        // } else if (vp_size != 0) {
        //   info_cout << "VP bank size " << vp_size << "\n";
        //   vp_size = 0;
        // }

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

          // Initialize offset to start of this set of banks from the previous one
          (*banks_offsets)[*n_banks_offsets] = (*banks_offsets)[*n_banks_offsets - 1] + preamble_words * sizeof(uint32_t);

          // Three things to write for a new set of banks:
          // - number of banks/offsets
          // - offsets to individual banks
          // - bank data

          // Initialize point to write from offset of previous set
          banks_write = reinterpret_cast<uint32_t*>(banks_data->data() + (*banks_offsets)[*n_banks_offsets - 1]);
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

        // if (bank_type_it->second == BankTypes::VP) {
        //   info_cout << "bank offset " << bank_counter - 1 << " " << n_word << " " << banks_offsets_write[bank_counter - 1] << "\n";
        // }

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

    std::tie(eof, error, bank_span) = MDF::read_event(*m_input, m_header, std::get<2>(m_buffers[0]), m_checkChecksum);
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
      auto new_offset = (offset + n_word) * sizeof(uint32_t);

      // if (bank_type_it->second == BankTypes::VP)
      //   info_cout << "bank offset: " << offsets.size() - 1 << " " << " " << n_word << " " << new_offset << "\n";

      offsets.push_back(new_offset);

      // Move to next raw bank
      bank += b->totalSize();
    }

    // for (auto bank_type : this->types()) {
    //   auto ib = to_integral<BankTypes>(bank_type);
    //   auto& offsets = m_banks_offsets[ib];
    //   info_cout << bank_name(bank_type) << " " << offsets.size() << " " << offsets.back() << "\n";
    // }

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

  // Memory buffers to read binary data into from the file
  mutable std::array<std::tuple<size_t, std::vector<unsigned int>, std::vector<char>>, 2> m_buffers;

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
