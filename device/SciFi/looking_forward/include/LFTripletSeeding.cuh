/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

namespace lf_triplet_seeding {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, unsigned), host_number_of_reconstructed_ut_tracks),
    (DEVICE_INPUT(dev_scifi_hits_t, char), dev_scifi_hits),
    (DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned), dev_scifi_hit_count),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_velo_states_t, char), dev_velo_states),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned), dev_ut_track_velo_indices),
    (DEVICE_INPUT(dev_ut_qop_t, float), dev_ut_qop),
    (DEVICE_INPUT(dev_scifi_lf_initial_windows_t, int), dev_scifi_lf_initial_windows),
    (DEVICE_INPUT(dev_ut_states_t, MiniState), dev_ut_states),
    (DEVICE_INPUT(dev_scifi_lf_process_track_t, bool), dev_scifi_lf_process_track),
    (DEVICE_OUTPUT(dev_scifi_lf_found_triplets_t, int), dev_scifi_lf_found_triplets),
    (DEVICE_OUTPUT(dev_scifi_lf_number_of_found_triplets_t, int8_t), dev_scifi_lf_number_of_found_triplets))

  __global__ void lf_triplet_seeding(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants);

  struct lf_triplet_seeding_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& stream,
      cudaEvent_t&) const;
  };
} // namespace lf_triplet_seeding
