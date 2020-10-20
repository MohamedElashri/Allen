/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include "InputProvider.h"
#include <gsl/gsl>

namespace data_provider {
  DEFINE_PARAMETERS(
    Parameters,
    (DEVICE_OUTPUT(dev_raw_banks_t, char), dev_raw_banks),
    (DEVICE_OUTPUT(dev_raw_offsets_t, unsigned), dev_raw_offsets),
    (PROPERTY(raw_bank_type_t, "bank_type", "type of raw bank to provide", BankTypes), prop_raw_bank_type))

  struct data_provider_t : public HostAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<raw_bank_type_t> m_bank_type {this, BankTypes::ODIN};
  };
} // namespace data_provider
