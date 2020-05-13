#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include <gsl/gsl>

namespace data_provider {
  struct Parameters {
    DEVICE_OUTPUT(dev_raw_banks_t, char) dev_raw_banks;
    DEVICE_OUTPUT(dev_raw_offsets_t, uint) dev_raw_offsets;
    PROPERTY(raw_bank_type_t, BankTypes, "bank_type", "type of raw bank to provide");
  };

  // Algorithm
  template<typename T>
  struct data_provider_t : public HostAlgorithm, Parameters {


    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
      set_size<dev_raw_banks_t>(arguments, std::get<1>(bno));
      set_size<dev_raw_offsets_t>(arguments, std::get<2>(bno).size());
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);

      // Copy data to device
      data_to_device<dev_raw_banks_t, dev_raw_offsets_t>(arguments, bno, cuda_stream);
    }

  private:
    Property<raw_bank_type_t> m_bank_type {this, BankTypes::ODIN};
  };
} // namespace data_provider
