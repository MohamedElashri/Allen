/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <sys/stat.h>

#include <InputProvider.h>
#include <Event/RawBank.h>
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

template<BankTypes... Banks>
class TESProvider final : public InputProvider<TESProvider<Banks...>> {
public:
  TESProvider(size_t n_slices, size_t events_per_slice, boost::optional<size_t> n_events) :
    InputProvider<TESProvider<Banks...>> {n_slices, events_per_slice, n_events}
  {}

  /**
   * @brief      Get banks in the format they are stored in TES
   *
   * @param      Array with raw bank content
   * @param      Set with bank types to be used as input for Allen
   */
  int set_banks(
    const std::array<std::vector<char>, LHCb::RawBank::LastType>& banks,
    std::set<LHCb::RawBank::BankType> bankTypes)
  {
    // get mapping of LHCb::RawBank::BankType to Allen::BankType
    const std::vector<int> bank_ids_mapping = bank_ids();

    // store banks and offsets as BanksAndOffsets object
    for (const auto& bank : bankTypes) {
      if (bank >= bank_ids_mapping.size()) {
        std::cout << "ERROR: LHCb::RawBank index out of scope from conversion between Allen and LHCb raw bank types"
                  << std::endl;
        return 1;
      }
      const auto allen_bank_index = bank_ids_mapping[bank];
      if (allen_bank_index < 0) {
        std::cout << "ERROR: dumped bank type does not exist in Allen" << std::endl;
        return 1;
      }

      // Offsets to events (we only process one event)
      m_offsets[0] = 0;
      m_offsets[1] = banks[bank].size();
      gsl::span<unsigned int const> offsets {m_offsets.data(), 2};

      // bank content
      auto data_size = static_cast<span_size_t<char const>>(banks[bank].size());
      gsl::span<char const> b {banks[bank].data(), data_size};

      m_banks_and_offsets[allen_bank_index] = {{std::move(b)}, static_cast<std::size_t>(data_size), std::move(offsets)};
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
  BanksAndOffsets banks(BankTypes bank_type, size_t /* slice_index */) const override
  {
    const auto ib = to_integral<BankTypes>(bank_type);
    return m_banks_and_offsets[ib];
  }

  void event_sizes(size_t const, gsl::span<unsigned int const> const, std::vector<size_t>&) const override {}

  void copy_banks(size_t const, unsigned int const, gsl::span<char>) const override {}

private:
  std::array<BanksAndOffsets, NBankTypes> m_banks_and_offsets;
  std::array<unsigned int, 2> m_offsets;
};
