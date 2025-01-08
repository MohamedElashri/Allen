/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"

// Event Model
#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "AlgorithmTypes.cuh"

/**
 * @brief This is definition file for downstream_copy_hit_number algorithm.
 * implementation is in downstream_copy_hit_number.cu
 *
 */

namespace downstream_copy_hit_number {
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    // Size of downstream tracks
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
    // Downstream tracks
    DEVICE_INPUT(dev_downstream_tracks_t, UT::DownstreamTrack) dev_downstream_tracks;
    DEVICE_INPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    // Output
    DEVICE_OUTPUT(dev_offsets_downstream_hit_numbers_t, unsigned) dev_offsets_downstream_hit_numbers;
    HOST_OUTPUT(host_number_of_hits_in_downstream_tracks_t, unsigned) host_number_of_hits_in_downstream_tracks;
    // Property
  };

  __global__ void downstream_copy_hit_number(Parameters);

  struct downstream_copy_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
  };
} // namespace downstream_copy_hit_number