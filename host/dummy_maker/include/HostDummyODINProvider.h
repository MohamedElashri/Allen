/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"

#include <ODINBank.cuh>

// emulated ODIN parts:
// - eventType: set to LHCb::ODIN::EventTypes::Lumi or 0u according to the given fraction
//   uses different fraction for each bxtype
// All other fields are preserved

namespace host_dummy_odin_provider {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_odin_data_t, ODINData) host_odin_data;
    DEVICE_OUTPUT(dev_odin_dummy_t, ODINData) dev_odin_dummy;
    HOST_OUTPUT(host_odin_dummy_t, ODINData) host_odin_dummy;
    PROPERTY(lumi_frac_t, "lumi_frac", "fraction of lumi events", std::array<float, 4>) lumi_frac;
  };

  // Algorithm
  struct host_dummy_odin_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<lumi_frac_t> m_lumi_frac {this, {0.f, 0.f, 0.f, 0.f}};
  };
} // namespace host_dummy_odin_provider
