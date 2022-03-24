/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <sys/stat.h>

#include <InputProvider.h>
#include <Event/RawBank.h>
#include <Event/ODIN.h>
#include <TransposeTypes.h>

#include "SciFiRaw.cuh"

/**
 * @brief      Provide event from TES location containing the same format as the binary files,
 *             i.e. the layout used for Allen
 *
 * @details
 *
 * @param      number of slices
 * @param      number of events to fill per slice
 * @param      optional: number of events to read
 *
 */

// template<BankTypes... Banks>
class TESProvider final : public InputProvider {
public:
  TESProvider(size_t n_slices, size_t events_per_slice, std::optional<size_t> n_events) :
    InputProvider {n_slices, events_per_slice, {}, IInputProvider::Layout::Allen, n_events}
  {}

  /**
   * @brief      Get banks in the format they are stored in TES
   *
   * @param      Array with raw bank content
   * @param      Set with bank types to be used as input for Allen
   */
  int set_banks(
    const std::array<TransposedBanks, LHCb::RawBank::types().size()>&
      transposed_banks)
  {
    // store banks and offsets as BanksAndOffsets object
    for (size_t i = 0; i < transposed_banks.size(); ++i) {
      auto const& banks = transposed_banks[i];

      if (banks.data.empty()) continue;

      if (i >= m_bank_ids_mapping.size()) {
        std::cout << "ERROR: LHCb::RawBank index out of scope from conversion between Allen and LHCb raw bank types"
                  << std::endl;
        return 1;
      }

      auto bank = static_cast<LHCb::RawBank::BankType>(i);
      const auto allen_bank_index = m_bank_ids_mapping[bank];
      if (allen_bank_index < 0) {
        std::cout << "ERROR: dumped bank type does not exist in Allen" << std::endl;
        return 1;
      }

      // Offsets to events (we only process one event)
      auto& offsets = m_offsets[allen_bank_index];
      offsets[0] = 0;
      offsets[1] = banks.data.size();

      // Bank sizes
      auto const n_banks = reinterpret_cast<unsigned const*>(banks.data.data())[0];

      auto& sizes_offsets = m_sizes[allen_bank_index];
      sizes_offsets.resize(2 + n_banks / 2 + 1);
      // Only 1 event, so a single offset is enough. The offset
      // counts uint16_t and is a uint32_t itself.
      sizes_offsets[0] = 2;
      uint16_t* sizes = reinterpret_cast<uint16_t*>(&sizes_offsets[1]);
      std::copy_n(banks.sizes.begin(), banks.sizes.size(), sizes);

      auto& types_offsets = m_types[allen_bank_index];
      types_offsets.resize(2 + n_banks / 4 + 1);
      // Only 1 event, so a single offset offset is enough. The offset
      // counts uint8_t and is a uint32_t itself.
      types_offsets[0] = 4;
      uint8_t* types = reinterpret_cast<uint8_t*>(&types_offsets[1]);
      std::copy_n(banks.types.begin(), banks.types.size(), types);

      // bank content
      auto data_size = static_cast<span_size_t<char const>>(banks.data.size());
      gsl::span<char const> b {banks.data.data(), data_size};

      m_banks_and_offsets[allen_bank_index] = {{std::move(b)},
                                               {offsets.data(), 2u},
                                               static_cast<std::size_t>(data_size),
                                               {sizes_offsets.data(), sizes_offsets.size()},
                                               {types_offsets.data(), types_offsets.size()},
                                               banks.version};
    }

    return 0;
  }

  /**
   * @brief      Obtain banks from TES
   *
   * @param      BankType
   *
   * @return     Banks and their offsets
   */
  BanksAndOffsets banks(BankTypes bank_type, size_t) const override
  {
    const auto ib = to_integral<BankTypes>(bank_type);
    return m_banks_and_offsets[ib];
  }

  EventIDs event_ids(size_t, std::optional<size_t> = {}, std::optional<size_t> = {}) const override
  {
    return EventIDs {};
  }

  void slice_free(size_t) override {};

  std::tuple<bool, bool, bool, size_t, size_t, std::any> get_slice(std::optional<unsigned int> = {}) override
  {
    LHCb::ODIN odin;
    odin.setRunNumber(0);
    return {false, false, false, 0, 0, odin};
  }

  void event_sizes(size_t const, gsl::span<unsigned int const> const, std::vector<size_t>&) const override {}

  void copy_banks(size_t const, unsigned int const, gsl::span<char>) const override {}

private:
  // Mapping of LHCb::RawBank::BankType to Allen::BankType
  const std::array<int, LHCb::RawBank::types().size()> m_bank_ids_mapping = Allen::bank_ids();

  std::array<BanksAndOffsets, NBankTypes> m_banks_and_offsets;
  std::array<std::array<unsigned int, 2>, NBankTypes> m_offsets;
  std::array<std::vector<unsigned>, NBankTypes> m_sizes;
  std::array<std::vector<unsigned>, NBankTypes> m_types;
};
