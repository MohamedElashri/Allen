#pragma once

#include <sys/stat.h>

//#include <regex>
#include <InputProvider.h>
//#include <InputTools.h>
#include <BankTypes.h>
//#include <TransposeTypes.h>

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
   */
  int set_banks(const std::array<std::vector<char>, int(BankTypes::Unknown)>& banks)
  {
    // to do: check that all raw banks are there and return 1 if it fails
    
    m_banks = banks;

    return 0;
  } 
    
  /**
   * @brief      Obtain banks from TES
   *
   * @param      BankType
   *
   * @return     Banks and their offsets
   */
  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const override
  {

    const auto ib = to_integral<BankTypes>(bank_type);

    // Offsets to events (we only process one event)
    std::array<unsigned int, 2> bank_offsets;
    bank_offsets[0] = 0;
    bank_offsets[1] = m_banks[ib].size();
    gsl::span<unsigned int const> offsets {bank_offsets.data(), 2};
    
    // bank content
    using data_span = gsl::span<char const>;
    auto data_size = static_cast<data_span::index_type>(m_banks[ib].size());
    std::vector<data_span> spans(1, data_span {m_banks[ib].data(), data_size});
    
    return BanksAndOffsets {{std::move(spans)}, data_size, std::move(offsets)};
  } 
  
  void event_sizes(size_t const, gsl::span<unsigned int const> const, std::vector<size_t>&) const override {}
  
  void copy_banks(size_t const, unsigned int const, gsl::span<char>) const override {}
  
 private:
  std::array<std::vector<char>, LHCb::RawBank::LastType> m_banks;
  
};
 
