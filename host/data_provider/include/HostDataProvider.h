/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include "InputProvider.h"
#include <gsl/gsl>

namespace host_data_provider {
  struct Parameters {
    HOST_OUTPUT(host_raw_banks_t, gsl::span<char const>) host_raw_banks;
    HOST_OUTPUT(host_raw_offsets_t, gsl::span<unsigned int const>) host_raw_offsets;
    PROPERTY(raw_bank_type_t, "bank_type", "type of raw bank to provide", BankTypes) prop_raw_bank_type;
  };

  struct host_data_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<raw_bank_type_t> m_bank_type {this, BankTypes::ODIN};
  };
} // namespace host_data_provider
