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
#include "MCEvent.h"
#include "MCRaw.h"
#include <gsl/span>

namespace mc_data_provider {
  struct Parameters {
    HOST_INPUT(host_mc_particle_banks_t, gsl::span<char const>) mc_particle_banks;
    HOST_INPUT(host_mc_particle_offsets_t, gsl::span<unsigned int const>) mc_particle_offsets;
    HOST_INPUT(host_mc_particle_sizes_t, gsl::span<unsigned int const>) mc_particle_sizes;
    HOST_INPUT(host_mc_pv_banks_t, gsl::span<char const>) mc_pv_banks;
    HOST_INPUT(host_mc_pv_offsets_t, gsl::span<unsigned int const>) mc_pv_offsets;
    HOST_INPUT(host_mc_pv_sizes_t, gsl::span<unsigned int const>) mc_pv_sizes;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_bank_version_t, int) host_bank_version;
    HOST_OUTPUT(host_mc_events_t, const MCEvents*) host_mc_events;
  };

  struct mc_data_provider_t : public ValidationAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    mutable MCEvents m_mc_events;
  };
} // namespace mc_data_provider
