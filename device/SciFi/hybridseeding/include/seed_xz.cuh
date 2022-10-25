/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "hybrid_seeding_helpers.cuh"
#include "hybrid_seeding_case.cuh"

/**
 * @brief Seeding in SciFI 1st stage with x_z layers
 * @detail first implementation of seeding starting with x_z layers to fit under HLT1 timing budget.
 */

namespace seed_xz {
  __device__ static constexpr unsigned int maxNHits = 300; // FIXME

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, uint) host_number_of_events;
    HOST_INPUT(host_scifi_hit_count_t, unsigned) host_scifi_hit_count;
    HOST_OUTPUT(host_seeding_number_of_tracksXZ_t, unsigned) host_seeding_number_of_tracksXZ;
    HOST_OUTPUT(host_seeding_tracksXZ_t, SciFi::Seeding::TrackXZ) host_seeding_tracksXZ;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;

    DEVICE_OUTPUT(dev_hits_working_mem_t, float) dev_hits_working_mem;
    DEVICE_OUTPUT(dev_count_hits_working_mem_t, unsigned) dev_count_hits_working_mem;
    DEVICE_OUTPUT(dev_triplets_t, uint) dev_triplets;

    DEVICE_OUTPUT(dev_seeding_number_of_tracksXZ_t, uint) dev_seeding_number_of_tracksXZ;
    DEVICE_OUTPUT(dev_seeding_number_of_tracksXZ_part0_t, uint) dev_seeding_number_of_tracksXZ_part0;
    DEVICE_OUTPUT(dev_seeding_number_of_tracksXZ_part1_t, uint) dev_seeding_number_of_tracksXZ_part1;

    DEVICE_OUTPUT(dev_seeding_tracksXZ_t, SciFi::Seeding::TrackXZ) dev_seeding_tracksXZ;
  };

  __global__ void seed_xz(Parameters);

  struct seed_xz_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;
  };
} // namespace seed_xz
