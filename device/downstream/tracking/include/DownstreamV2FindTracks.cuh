/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
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
#include "States.cuh"

#include "UTHitCache.cuh"

// Local
#include "DownstreamV2Structs.cuh"

namespace downstream_v2_find_tracks {

#if defined(TARGET_DEVICE_CUDA)
#if __CUDA_ARCH__ >= 800 // Ampere (A5000)
  // downstream_create_candidates has 48 register / thread
  // downstream_find_rest_hits has 40 register / thread
  __device__ static constexpr unsigned int MaxCacheSize = 1472;
#else // Volta, Turing:
  __device__ static constexpr unsigned int MaxCacheSize = 1344;
#endif
#else // CPU, HIP
  __device__ static constexpr unsigned int MaxCacheSize = 1;
#endif
  using UTHitsCache = UTHitCache::NodxDyHitCache_8Bytes<MaxCacheSize>;

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // SciFi input
    DEVICE_INPUT(dev_offsets_seeding_tracks_t, unsigned) dev_offsets_seeding_tracks;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;

    // Input candidates
    HOST_INPUT(host_total_number_of_downstream_candidates_t, unsigned) host_total_number_of_downstream_candidates;
    DEVICE_INPUT(dev_downstream_candidate_offsets_t, unsigned) dev_downstream_candidate_offsets;
    DEVICE_INPUT(dev_downstream_candidates_t, ushort2) dev_downstream_candidates;

    // Outputs
    HOST_OUTPUT(host_number_of_downstream_compact_tracks_t, unsigned) host_number_of_downstream_compact_tracks;
    DEVICE_OUTPUT(dev_downstream_compact_track_offsets_t, unsigned) dev_downstream_compact_track_offsets;
    DEVICE_OUTPUT(dev_downstream_compact_tracks_t, Downstream::Structs::CompactTrack) dev_downstream_compact_tracks;

    // Buffer
    DEVICE_OUTPUT(dev_downstream_compact_track_offsets_layer_0_t, unsigned)
    dev_downstream_compact_track_offsets_layer_0;
    DEVICE_OUTPUT(dev_downstream_compact_track_offsets_layer_1_t, unsigned)
    dev_downstream_compact_track_offsets_layer_1;
    DEVICE_OUTPUT(dev_downstream_compact_tracks_buffer_t, Downstream::Structs::CompactTrack)
    dev_downstream_compact_tracks_buffer;
  };
  struct downstream_v2_find_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<bool> m_fiducial_cut {this, "fiducial_cut", false, "enable fiducial cuts"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<float> m_y_tolerance {this, "y_tolerance", 10.f, "the tolerance window in Y"};
    Allen::Property<float> m_y_layer_tolerance {this,
                                                "y_layer_tolerance",
                                                18.f,
                                                "the tolerance window in Y in layer level"};
    Allen::Property<float> m_x_axial_tolerance {this,
                                                "x_axial_tolerance",
                                                3.f,
                                                "the tolerance window in X for axial layers"};
    Allen::Property<float> m_x_stereo_tolerance {this,
                                                 "x_stereo_tolerance",
                                                 4.f,
                                                 "the tolerance window in X for stereo layers"};
    Allen::Property<std::array<float, 2>> m_dtx_range {this, "dtx_range", {0.01f, 0.43f}, "the dtx range"};
    Allen::Property<float> m_ut_r_min {this, "ut_r_min", 24.f, "the minimum ut r for beamline removal"};
    Allen::Property<float> m_x0_max {this, "x0_max", 400.f, "the maximum x0"};
    Allen::Property<std::array<float, 2>> m_eta_range {this, "eta_range", {1.8f, 5.7f}, "the eta range"};
    Allen::Property<std::array<float, 3>> m_stereo_bias_threshold {this,
                                                                   "stereo_bias_threshold",
                                                                   {1.39454254e+01f, -9.63571400e-01f, 3.18779385e+00f},
                                                                   "the stereo bias threshold"};
  };

  __global__ void downstream_v2_find_hits_in_layer_0(
    Parameters,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    bool fiducial_cut,
    float x0_max,
    float x_axial_tolerance,
    float y_tolerance,
    float y_layer_tolerance);

  __global__ void downstream_v2_find_hits_in_layer_1(
    Parameters,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    bool fiducial_cut,
    float x0_max,
    std::array<float, 2> dtx_range,
    float ut_r_min,
    std::array<float, 2> eta_range,
    float x_stereo_tolerance,
    float y_tolerance,
    float y_layer_tolerance);

  __global__ void downstream_v2_find_hits_in_layer_2(
    Parameters,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    bool fiducial_cut,
    std::array<float, 3> stereo_bias_threshold,
    float x_stereo_tolerance,
    float y_tolerance,
    float y_layer_tolerance);

  __global__ void downstream_v2_consolidate_find_hits(Parameters);

} // namespace downstream_v2_find_tracks
