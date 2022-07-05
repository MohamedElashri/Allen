/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"

namespace seed_xz_consolidate {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, unsigned) host_accumulated_number_of_scifi_hits;
    HOST_INPUT(host_number_of_reconstructed_seeding_tracksXZ_t, unsigned) host_number_of_reconstructed_seeding_tracksXZ;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_accumulated_number_of_hits_in_scifi_tracksXZ_t, unsigned)
    host_accumulated_number_of_hits_in_scifi_tracksXZ;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_seeding_tracksXZ_t, unsigned) dev_atomics_scifi;                 // fishy
    DEVICE_INPUT(dev_offsets_seeding_XZ_hit_number_t, unsigned) dev_scifi_seed_XZ_hit_number; // fishy
    DEVICE_INPUT(dev_seeding_tracksXZ_t, SciFi::Seeding::TrackXZ) dev_seeding_tracksXZ;

    //    DEVICE_OUTPUT(dev_seeding_qop_t, float) dev_seeding_qop;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };
  __global__ void seed_xz_consolidate(Parameters);

  struct seed_xz_consolidate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace seed_xz_consolidate
