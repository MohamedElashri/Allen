/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"

namespace seeding_copy_trackXZ_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events; // input from event model
    HOST_INPUT(host_number_of_reconstructed_seeding_tracksXZ_t, unsigned)
    host_number_of_reconstructed_seeding_trackXZs;                                      // input from prefix sum
    DEVICE_INPUT(dev_seeding_tracksXZ_t, SciFi::Seeding::TrackXZ) dev_seeding_tracksXZ; // input from seed_xz
    DEVICE_INPUT(dev_seeding_xz_atomics_t, unsigned) dev_seeding_xz_atomics;            // input from seed_xz
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_OUTPUT(dev_seeding_trackXZ_hit_number_t, unsigned) dev_seeding_trackXZ_hit_number;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };
  __global__ void seeding_copy_trackXZ_hit_number(Parameters);

  struct seeding_copy_trackXZ_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{512, 1, 1}}};
  };
} // namespace seeding_copy_trackXZ_hit_number
