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

namespace data_provider {
  struct Parameters {
    DEVICE_OUTPUT(dev_raw_banks_t, char) dev_raw_banks;
    DEVICE_OUTPUT(dev_raw_offsets_t, unsigned) dev_raw_offsets;
    DEVICE_OUTPUT(dev_raw_sizes_t, unsigned) dev_raw_sizes;
    DEVICE_OUTPUT(dev_raw_types_t, unsigned) dev_raw_types;
    HOST_OUTPUT(host_raw_bank_version_t, int) host_raw_bank_version;
  };

  struct data_provider_t : public ProviderAlgorithm, Parameters {
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
} // namespace data_provider
