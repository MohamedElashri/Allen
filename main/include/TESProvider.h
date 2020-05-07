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
  TESProvider(
    size_t n_slices,
    size_t events_per_slice,
    boost::optional<size_t> n_events) :
  InputProvider<TESProvider<Banks...>> {n_slices, events_per_slice, n_events} 
  {}
  
  /**
   * @brief      Get banks in the format they are stored in TES
   *
   * @param      Array with raw bank content
   * @param      Set with bank types to be used as input for Allen
   */
  int set_banks(std::array<std::vector<char>, LHCb::RawBank::LastType> banks, std::set<LHCb::RawBank::BankType> bankTypes)
  {
    // get mapping of LHCb::RawBank::BankType to Allen::BankType
    const std::vector<int> bank_ids_mapping = bank_ids();
    
    // store banks and offsets as BanksAndOffsets object
    for (const auto& bank : bankTypes) {
      if (bank >= bank_ids_mapping.size()) {
        std::cout << "ERROR: LHCb::RawBank index out of scope from conversion between Allen and LHCb raw bank types" << std::endl;;
        return 1;
      }
      const auto allen_bank_index = bank_ids_mapping[bank];  
      if (allen_bank_index < 0 ) {
        std::cout << "ERROR: dumped bank type does not exist in Allen" << std::endl;;
        return 1;
      }
      std::cout << "LHCb index is " << bank << ", Allen index is " << allen_bank_index << std::endl;
      
      // Offsets to events (we only process one event)
      std::array<unsigned int, 2> bank_offsets;
      bank_offsets[0] = 0;
      bank_offsets[1] = banks[bank].size();
      gsl::span<unsigned int const> offsets {bank_offsets.data(), 2};
      
      // bank content
      using data_span = gsl::span<char const>;
      auto data_size = static_cast<data_span::index_type>(banks[bank].size());
      std::vector<data_span> spans(1, data_span {banks[bank].data(), data_size}); 
      
      std::cout << "total data size is " << data_size << std::endl;

      if ( allen_bank_index == 2) {
        auto const scifi_offsets = offsets;
        const SciFi::SciFiRawEvent scifi_event( spans[0].data() + scifi_offsets[0]);
        std::cout << "TESProvider set_banks: offset = " << scifi_offsets[0] << std::endl;
        std::cout << "TESProvider set_banks: number of scifi raw banks = " << scifi_event.number_of_raw_banks << std::endl;
      }
 
      m_banks_and_offsets[allen_bank_index] = std::make_tuple(std::move(spans), data_size, std::move(offsets));
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
    std::cout << "fetching Allen bank type " << ib << " with size " << std::get<1>(m_banks_and_offsets[ib]) << std::endl;
    
    if ( ib == 2 ) {
      auto const scifi_offsets = std::get<2>(m_banks_and_offsets[ib]);
      using data_span = gsl::span<char const>;
      std::vector<data_span> spans = std::get<0>(m_banks_and_offsets[ib]);
      const SciFi::SciFiRawEvent scifi_event( spans[0].data() + scifi_offsets[0]);
      std::cout << "TESProvider banks: offset = " << scifi_offsets[0] << std::endl;
      std::cout << "TESProvider banks: number of scifi raw banks = " << scifi_event.number_of_raw_banks << std::endl;
    }
     
    return m_banks_and_offsets[ib];
  } 
  
  void event_sizes(size_t const, gsl::span<unsigned int const> const, std::vector<size_t>&) const override {}
  
  void copy_banks(size_t const, unsigned int const, gsl::span<char>) const override {}
  
 private:
  std::array<BanksAndOffsets, NBankTypes> m_banks_and_offsets;
};
