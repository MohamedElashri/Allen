/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

// Basic
#include "AlgorithmTypes.cuh"

// Event Model
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"
#include "DownstreamExtrapolation.cuh"
#include "DownstreamCache.cuh"

/**
 * @brief This is the definition file for the downstream_update_ut_offset
 * algorithm. This algorithm is responsible for updating the UT hit offsets
 * implemntation file is downstream_update_ut_offset.cu
 */

namespace downstream_update_ut_offset {

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // UT input
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Compass UT
    DEVICE_INPUT(dev_is_ut_hit_used_t, bool) dev_is_ut_hit_used;

    // Output UT hits
    DEVICE_OUTPUT(dev_num_hits_per_sector_t, unsigned) dev_num_hits_per_sector;

    // Block size
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void downstream_update_ut_offset(Parameters, const unsigned*);

  struct downstream_update_ut_offset_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };

} // namespace downstream_update_ut_offset
