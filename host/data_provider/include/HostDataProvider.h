#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include "InputProvider.h"
#include <gsl/gsl>

namespace host_data_provider {
  struct Parameters {
    HOST_OUTPUT(host_raw_banks_t, gsl::span<char const>) host_raw_banks;
    HOST_OUTPUT(host_raw_offsets_t, gsl::span<unsigned int const>) host_raw_offsets;
    PROPERTY(raw_bank_type_t, BankTypes, "bank_type", "type of raw bank to provide");
  };

  // Algorithm
  template<typename T, char... S>
  struct host_data_provider_t : public HostAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
      // A number of spans for the blocks equal to the number of blocks
      set_size<host_raw_banks_t>(arguments, std::get<0>(bno).size());
      // A single span for the offsets
      set_size<host_raw_offsets_t>(arguments, 1);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t&,
      cudaEvent_t&) const
    {
      auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);

      // memcpy the offsets span directly
      auto const& offsets = std::get<2>(bno);
      ::memcpy(begin<host_raw_offsets_t>(arguments), &offsets, sizeof(offsets));

      // Copy the spans for the blocks
      auto const& blocks = std::get<0>(bno);
      ::memcpy(
        begin<host_raw_banks_t>(arguments),
        blocks.data(),
        blocks.size() * sizeof(typename std::remove_reference_t<decltype(blocks)>::value_type));
    }

  private:
    Property<raw_bank_type_t> m_bank_type {this, BankTypes::ODIN};
  };
} // namespace host_data_provider
