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

#include <LumiDefinitions.cuh>

namespace host_dummy_maker {
  struct Parameters {
    HOST_OUTPUT(host_unsigned_dummy_t, unsigned) host_unsigned_dummy;
    DEVICE_OUTPUT(dev_unsigned_dummy_t, unsigned) dev_unsigned_dummy;
    DEVICE_OUTPUT(dev_lumi_dummy_t, Lumi::LumiInfo) dev_lumi_dummy;
  };

  // Algorithm
  struct host_dummy_maker_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;
  };
} // namespace host_dummy_maker
