#pragma once

#include <InputProvider.h>
#include "mdf_header.hpp"
#include "read_mdf.hpp"
#include "raw_bank.hpp"

namespace {
  // Copy data from the event-local buffer to the global
  // one, while keeping the global buffer's size consistent with its
  // content
  void copy_data(unsigned int& event_offset, char* buf, const void* source, size_t s)
  {
    ::memcpy(buf + event_offset, source, s);
    event_offset += s;
  }
} // namespace

// FIXME: add start offset
template <BankTypes... Banks>
class MDFProvider final : public InputProvider<MDFProvider<Banks...>> {
public:
  MDFProvider(size_t n_slices, size_t n_events, std::vector<std::string> connections) :
    InputProvider<MDFProvider<Banks...>>{n_slices, n_events},
    m_event_ids(n_slices), m_connections {std::move(connections)}
  {
    for (auto bank_type : this->types()) {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }

      // Fudge with extra 20% memory
      size_t n_bytes = std::lround(it->second * n_events * 1024 * 1.2);
      m_banks_data[ib].reserve(n_bytes);
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

          // Copy in bank data
          const auto& bank_data = m_banks_data[ib];
          copy_data(event_offset, buf.data(), bank_data.data(), bank_data.size() * sizeof(uint32_t));

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

private:
  std::tuple<bool, unsigned int, unsigned long> next() const
  {

    bool eof = false, error = false;
    gsl::span<const char> bank_span;
    unsigned int run = 0;
    unsigned long event = 0;

    auto open_file = [this] {
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
    };

    if (!m_input && !open_file()) {
      return {false, 0, 0};
    }

    std::tie(eof, error, bank_span) = MDF::read_event(*m_input, m_header, m_buffer);
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

      // Check if cuda_hlt even knows about this type of bank and we want this type
      auto cuda_type_it = LHCbToGPU::bank_types.find(b->type());
      if (cuda_type_it == LHCbToGPU::bank_types.end()
          || !this->types().count(cuda_type_it->second)) {
        bank += b->totalSize();
        continue;
      }

      auto index = to_integral(cuda_type_it->second);
      auto& bank_data = m_banks_data[index];
      auto& offsets = m_banks_offsets[index];
      auto offset = offsets.back() / sizeof(uint32_t);

      // Store this bank in the event-local buffers
      bank_data.push_back(b->sourceID());
      offset++;

      auto b_start = b->begin<uint32_t>();
      auto b_end = b->end<uint32_t>();

      while (b_start != b_end) {
        const uint32_t raw_data = *b_start;
        bank_data.emplace_back(raw_data);

        b_start++;
        offset++;
      }

      // Record raw bank offset
      offsets.push_back(offset * sizeof(uint32_t));

      // Move to next raw bank
      bank += b->totalSize();
    }
    return {!eof, run, event};
  }

  mutable std::vector<char> m_buffer;
  mutable LHCb::MDFHeader m_header;

  mutable std::array<std::vector<uint32_t>, NBankTypes> m_banks_offsets;
  mutable std::array<std::vector<uint32_t>, NBankTypes> m_banks_data;

  std::array<std::vector<std::tuple<gsl::span<char>, gsl::span<unsigned int>, size_t>>, NBankTypes> m_slices;
  std::vector<std::vector<std::tuple<unsigned int, unsigned long>>> m_event_ids;

  std::vector<std::string> m_connections;
  mutable std::unique_ptr<std::ifstream> m_input;
  mutable std::vector<std::string>::const_iterator m_current;

  using base_class = InputProvider<MDFProvider<Banks...>>;

};
