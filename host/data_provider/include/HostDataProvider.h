#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include "InputProvider.h"
#include <gsl/gsl>

namespace host_data_provider {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_OUTPUT(host_raw_banks_t, gsl::span<char const>), host_raw_banks),
    (HOST_OUTPUT(host_raw_offsets_t, gsl::span<unsigned int const>), host_raw_offsets),
    (PROPERTY(raw_bank_type_t, "bank_type", "type of raw bank to provide", BankTypes), prop_raw_bank_type))

  struct host_data_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentRefManager<ParameterTuple<Parameters>::t> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentRefManager<ParameterTuple<Parameters>::t>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t&,
      cudaEvent_t&) const;

  private:
    Property<raw_bank_type_t> m_bank_type {this, BankTypes::ODIN};
  };
} // namespace host_data_provider
