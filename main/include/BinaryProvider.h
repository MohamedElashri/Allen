#pragma once

#include <regex>
#include <InputProvider.h>
#include <InputTools.h>
#include <BankTypes.h>

template <BankTypes... Banks>
class BinaryProvider final : public InputProvider<BinaryProvider<Banks...>> {
public:
  BinaryProvider(size_t n_slices, size_t n_events, std::vector<std::string> connections, bool loop = false) :
    InputProvider<BinaryProvider<Banks...>>{n_slices, n_events},
    m_loop {loop}, m_event_ids(n_slices)
  {
    for (auto bank_type : this->types()) {
      auto it = std::find_if(connections.begin(), connections.end(),
                             [bank_type] (auto const& folder) {
                               auto bn = bank_name(bank_type);
                               return folder.substr(folder.size() - bn.size(), std::string::npos) == bn;
                             });
      if (it == connections.end()) {
        throw StrException{"Failed to find a folder for " + bank_name(bank_type) + " banks"};
      } else {
        auto ib = to_integral<BankTypes>(bank_type);
        m_files[ib] = std::tuple{*it, list_folder(*it)};
      }
    }

    auto const& some_files = std::get<1>(m_files[0]);
    m_all_events.reserve(some_files.size());
    std::regex file_expr {"(\\d+)_(\\d+).*\\.bin"};
    std::smatch result;
    for (auto const& file : some_files) {
      if (std::regex_match(file, result, file_expr)) {
        m_all_events.emplace_back(std::tuple {std::atoi(result[1].str().c_str()), std::atol(result[2].str().c_str())});
      }
    }

    for (auto bank_type : this->types()) {
      auto it = BankSizes.find(bank_type);
      auto ib = to_integral<BankTypes>(bank_type);
      if (it == end(BankSizes)) {
        throw std::out_of_range {std::string {"Bank type "} + std::to_string(ib) + " has no known size"};
      }

      // Fudge with extra 20% memory
      size_t n_bytes = std::lround(it->second * n_events * 1024 * 1.2);
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

    for (size_t n = 0; n < n_slices; ++n) {
      m_event_ids[n].reserve(n_events);
    }
  }

  static constexpr const char* name = "Binary";

  std::vector<std::tuple<unsigned int, unsigned long>> const& event_ids(size_t slice_index) const
  {
    return m_event_ids[slice_index];
  }

  std::tuple<bool, bool, size_t> fill(size_t slice_index, size_t n)
  {
    size_t n_files = std::get<1>(m_files.front()).size();
    size_t start = m_current;
    bool full = false;

    // "Reset" the slice
    m_event_ids[slice_index].clear();
    for (auto bank_type : this->types()) {
      auto ib = to_integral<BankTypes>(bank_type);
      std::get<2>(m_slices[ib][slice_index]) = 1;
    }

    for (; (m_current < n_files || m_loop) && m_current < start + n; ++m_current) {
      auto inputs = open_files(m_current % n_files);
      full = std::any_of(this->types().begin(), this->types().end(), [this, slice_index, &inputs](auto bank_type) {
        auto ib = to_integral<BankTypes>(bank_type);
        const auto& [slice, offsets, offsets_size] = m_slices[ib][slice_index];
        return (offsets[offsets_size - 1] + std::get<2>(inputs[ib])) > slice.size();
      });
      if (!full) {
        for (auto& [bank_type, input, data_size] : inputs) {
          auto ib = to_integral<BankTypes>(bank_type);
          auto& [slice, offsets, offsets_size] = m_slices[ib][slice_index];
          read_file(input, data_size, slice.data(), offsets.data(), offsets_size - 1);
          ++offsets_size;
        }
        m_event_ids[slice_index].emplace_back(m_all_events[m_current]);
      }
    }
    return {m_current != n_files || m_loop, full, m_current - start};
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

  std::array<std::tuple<BankTypes, std::ifstream, size_t>, NBankTypes> open_files(size_t n)
  {
    std::array<std::tuple<BankTypes, std::ifstream, size_t>, NBankTypes> result;
    for (auto bank_type : this->types()) {
      auto ib = to_integral<BankTypes>(bank_type);
      auto filename = std::get<0>(m_files[ib]) + "/" + std::get<1>(m_files[ib])[n];
      std::ifstream input(filename, std::ifstream::binary);
      input.seekg(0, std::ios::end);
      auto end = input.tellg();
      input.seekg(0, std::ios::beg);
      auto data_size = end - input.tellg();

      if (data_size == 0) {
        throw StrException{"Empty file: " + filename};
      }
      result[ib] = std::tuple{bank_type, std::move(input), data_size};
    }
    return result;
  }

  void read_file(std::ifstream& input, size_t data_size, char* events, unsigned int* offsets, size_t n)
  {
    // read content
    size_t const previous_size = offsets[n];
    input.read(events + previous_size, data_size);
    offsets[n + 1] = previous_size + data_size;
  }

  // Pinned memory slices, N per banks types,
  std::array<std::vector<std::tuple<gsl::span<char>, gsl::span<unsigned int>, size_t>>, NBankTypes> m_slices;

  // Index of the event file currently being read
  size_t m_current = 0;

  // Loop on available input files
  bool m_loop = false;

  // Run and event numbers of all available events
  std::vector<std::tuple<unsigned int, unsigned long>> m_all_events;

  // Run and events numbers of events in each slice
  std::vector<std::vector<std::tuple<unsigned int, unsigned long>>> m_event_ids;

  // Folder and file names per bank type
  std::array<std::tuple<std::string, std::vector<std::string>>, NBankTypes> m_files;

  using base_class = InputProvider<BinaryProvider<Banks...>>;


};
