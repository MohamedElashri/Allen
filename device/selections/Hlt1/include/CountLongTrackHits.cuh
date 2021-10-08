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

#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"
//#include "Argument.cuh"

namespace count_long_track_hits {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT_OPTIONAL(host_number_of_reconstructed_scifi_tracks_t, unsigned)
    host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT_OPTIONAL(dev_offsets_all_velo_tracks_t, unsigned) dev_atomics_velo;
    DEVICE_INPUT_OPTIONAL(dev_offsets_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
    DEVICE_INPUT_OPTIONAL(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT_OPTIONAL(dev_offsets_ut_tracks_t, unsigned) dev_atomics_ut;
    DEVICE_INPUT_OPTIONAL(dev_offsets_ut_track_hit_number_t, unsigned) dev_ut_track_hit_number;
    DEVICE_INPUT_OPTIONAL(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT_OPTIONAL(dev_ut_track_velo_indices_t, unsigned) dev_ut_track_velo_indices;
    DEVICE_INPUT_OPTIONAL(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT_OPTIONAL(dev_offsets_forward_tracks_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT_OPTIONAL(dev_offsets_scifi_track_hit_number_t, unsigned) dev_scifi_track_hit_number;
    DEVICE_INPUT_OPTIONAL(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT_OPTIONAL(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT_OPTIONAL(dev_scifi_track_ut_indices_t, unsigned) dev_scifi_track_ut_indices;
    DEVICE_INPUT_OPTIONAL(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_OUTPUT(dev_long_track_hit_number_t, unsigned) dev_long_track_hit_number;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void count_hits(Parameters);

  struct count_long_track_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{512, 1, 1}}};
  };

} // namespace count_long_track_hits