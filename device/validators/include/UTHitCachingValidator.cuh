/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "UTEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "UTHitCache.cuh"

namespace ut_hit_caching_test {

  struct MiniUTHit {
    float zAtYEq0;
    float xAtYEq0;
    float yMid;
    float yMin;
    float yMax;
    float dxDy;
    float layer;
  };

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;

    // Hits
    DEVICE_OUTPUT(dev_original_ut_hits_t, MiniUTHit) dev_original_ut_hits;
    DEVICE_OUTPUT(dev_cached_ut_hits_t, MiniUTHit) dev_cached_ut_hits;

    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  using UTHitCache = UT::SmartHitsCache<2000>;

  __global__ void fill_ut_hits(
    Parameters parameters,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const UT::Constants::PerLayerInfo* dev_mean_layer_info);

  struct ut_hit_caching_test_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };

} // namespace ut_hit_caching_test
