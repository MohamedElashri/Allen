/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "InputProvider.h"
#include <gsl/span>

namespace host_data_provider {
  struct Parameters {
    HOST_OUTPUT(host_raw_banks_t, gsl::span<char const>) host_raw_banks;
    HOST_OUTPUT(host_raw_offsets_t, gsl::span<unsigned int const>) host_raw_offsets;
    HOST_OUTPUT(host_raw_sizes_t, gsl::span<unsigned int const>) host_raw_sizes;
    HOST_OUTPUT(host_raw_types_t, gsl::span<unsigned int const>) host_raw_types;
    HOST_OUTPUT(host_raw_bank_version_t, int) host_raw_bank_version;
  };

  struct host_data_provider_t : public ProviderAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<BankTypes> m_bank_type {this, "bank_type", BankTypes::ODIN, "type of raw bank to provide"};
    Allen::Property<bool> m_empty {this, "empty", false, "will provide empty banks"};
  };
} // namespace host_data_provider
