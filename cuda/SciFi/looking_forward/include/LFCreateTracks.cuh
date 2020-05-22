#pragma once

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

namespace lf_create_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_atomics_t, uint) dev_scifi_lf_atomics;
    DEVICE_INPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_INPUT(dev_scifi_lf_process_track_t, bool) dev_scifi_lf_process_track;
    DEVICE_INPUT(dev_scifi_lf_found_triplets_t, int) dev_scifi_lf_found_triplets;
    DEVICE_INPUT(dev_scifi_lf_number_of_found_triplets_t, int8_t) dev_scifi_lf_number_of_found_triplets;
    DEVICE_OUTPUT(dev_scifi_lf_total_number_of_found_triplets_t, uint) dev_scifi_lf_total_number_of_found_triplets;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_t, float) dev_scifi_lf_parametrization;
    DEVICE_INPUT(dev_ut_states_t, MiniState) dev_ut_states;
    PROPERTY(
      triplet_keep_best_block_dim_t,
      DeviceDimensions,
      "triplet_keep_best_block_dim",
      "block dimensions triplet keep best");
    PROPERTY(
      calculate_parametrization_block_dim_t,
      DeviceDimensions,
      "calculate_parametrization_block_dim",
      "block dimensions calculate parametrization");
    PROPERTY(extend_tracks_block_dim_t, DeviceDimensions, "extend_tracks_block_dim", "block dimensions extend tracks");
  };

  __global__ void lf_triplet_keep_best(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  __global__ void lf_calculate_parametrization(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants);

  __global__ void lf_extend_tracks(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  template<typename T, char... S>
  struct lf_create_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(lf_triplet_keep_best)) triplet_keep_best {lf_triplet_keep_best};
    decltype(global_function(lf_calculate_parametrization)) calculate_parametrization {lf_calculate_parametrization};
    decltype(global_function(lf_extend_tracks)) extend_tracks {lf_extend_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_lf_tracks_t>(
        arguments,
        value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
      set_size<dev_scifi_lf_atomics_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_scifi_lf_total_number_of_found_triplets_t>(
        arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
      set_size<dev_scifi_lf_parametrization_t>(
        arguments,
        4 * value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_scifi_lf_total_number_of_found_triplets_t>(arguments, 0, cuda_stream);
      initialize<dev_scifi_lf_atomics_t>(arguments, 0, cuda_stream);

      const auto parameters = Parameters {begin<dev_offsets_ut_tracks_t>(arguments),
                                          begin<dev_offsets_ut_track_hit_number_t>(arguments),
                                          begin<dev_scifi_lf_tracks_t>(arguments),
                                          begin<dev_scifi_lf_atomics_t>(arguments),
                                          begin<dev_scifi_lf_initial_windows_t>(arguments),
                                          begin<dev_scifi_lf_process_track_t>(arguments),
                                          begin<dev_scifi_lf_found_triplets_t>(arguments),
                                          begin<dev_scifi_lf_number_of_found_triplets_t>(arguments),
                                          begin<dev_scifi_lf_total_number_of_found_triplets_t>(arguments),
                                          begin<dev_scifi_hits_t>(arguments),
                                          begin<dev_scifi_hit_offsets_t>(arguments),
                                          begin<dev_offsets_all_velo_tracks_t>(arguments),
                                          begin<dev_offsets_velo_track_hit_number_t>(arguments),
                                          begin<dev_velo_states_t>(arguments),
                                          begin<dev_ut_track_velo_indices_t>(arguments),
                                          begin<dev_ut_qop_t>(arguments),
                                          begin<dev_scifi_lf_parametrization_t>(arguments),
                                          begin<dev_ut_states_t>(arguments)};

      triplet_keep_best(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        property<triplet_keep_best_block_dim_t>(),
        cuda_stream)(parameters, constants.dev_looking_forward_constants);

      calculate_parametrization(
        dim3(value<host_number_of_selected_events_t>(arguments)),
        property<calculate_parametrization_block_dim_t>(),
        cuda_stream)(parameters, constants.dev_looking_forward_constants);

      extend_tracks(
        dim3(value<host_number_of_selected_events_t>(arguments)), property<extend_tracks_block_dim_t>(), cuda_stream)(
        parameters, constants.dev_looking_forward_constants);
    }

  private:
    Property<triplet_keep_best_block_dim_t> m_triplet_keep_best_block_dim {this, {{128, 1, 1}}};
    Property<calculate_parametrization_block_dim_t> m_calculate_parametrization_block_dim {this, {{128, 1, 1}}};
    Property<extend_tracks_block_dim_t> m_extend_tracks_block_dim {this, {{256, 1, 1}}};
  };
} // namespace lf_create_tracks
