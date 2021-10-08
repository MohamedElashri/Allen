/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "InputProvider.h"
#include "MCEvent.h"
#include "MCRaw.h"

namespace mc_data_provider {
  struct Parameters {
    HOST_INPUT(host_mc_particle_banks_t, gsl::span<char const>) mc_particle_banks;
    HOST_INPUT(host_mc_particle_offsets_t, gsl::span<unsigned int const>) mc_particle_offsets;
    HOST_INPUT(host_mc_pv_banks_t, gsl::span<char const>) mc_pv_banks;
    HOST_INPUT(host_mc_pv_offsets_t, gsl::span<unsigned int const>) mc_pv_offsets;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_mc_events_t, const MCEvents*) host_mc_events;
  };

  struct mc_data_provider_t : public ValidationAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&, const HostBuffers&)
      const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context&) const;

  private:
    mutable MCEvents m_mc_events;
  };
} // namespace mc_data_provider
