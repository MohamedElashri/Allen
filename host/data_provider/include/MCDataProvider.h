/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "HostAlgorithm.cuh"
#include "InputProvider.h"
#include "MCEvent.h"

namespace mc_data_provider {
  struct Parameters {
    HOST_OUTPUT(host_mc_events_t, MCEvents) host_mc_events;
  };

  struct mc_data_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&, const HostBuffers&)
      const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context&) const;
  };
} // namespace mc_data_provider
