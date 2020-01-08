#include "LFTripletSeeding.cuh"
#include "LFTripletSeedingImpl.cuh"
#include "LookingForwardTools.cuh"

void lf_triplet_seeding_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_scifi_lf_found_triplets>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::n_triplet_seeds *
    LookingForward::triplet_seeding_block_dim_x * LookingForward::maximum_number_of_triplets_per_thread);
  arguments.set_size<dev_scifi_lf_number_of_found_triplets>(
    host_buffers.host_number_of_reconstructed_ut_tracks[0] * LookingForward::n_triplet_seeds *
    LookingForward::triplet_seeding_block_dim_x);
}

void lf_triplet_seeding_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_scifi_lf_number_of_found_triplets>(),
    0,
    arguments.size<dev_scifi_lf_number_of_found_triplets>(),
    cuda_stream));

  function(dim3(host_buffers.host_number_of_selected_events[0]),
    dim3(LookingForward::triplet_seeding_block_dim_x, 2), cuda_stream)(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_states>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_ut_qop>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_initial_windows>(),
    constants.dev_looking_forward_constants,
    arguments.offset<dev_ut_states>(),
    arguments.offset<dev_scifi_lf_process_track>(),
    arguments.offset<dev_scifi_lf_found_triplets>(),
    arguments.offset<dev_scifi_lf_number_of_found_triplets>());
}

__global__ void lf_triplet_seeding(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const uint* dev_ut_track_velo_indices,
  const float* dev_ut_qop,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows,
  const LookingForward::Constants* dev_looking_forward_constants,
  const MiniState* dev_ut_states,
  const bool* dev_scifi_lf_process_track,
  int* dev_scifi_lf_found_triplets,
  int8_t* dev_scifi_lf_number_of_found_triplets)
{
  __shared__ float shared_precalc_expected_x1[2 * LookingForward::max_number_of_hits_in_window];

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, dev_atomics_velo[2 * number_of_events]};
  const uint velo_tracks_offset_event = dev_atomics_velo[number_of_events + event_number];

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // UT consolidated tracks
  UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                      (uint*) dev_ut_track_hit_number,
                                      (float*) dev_ut_qop,
                                      (uint*) dev_ut_track_velo_indices,
                                      event_number,
                                      number_of_events};

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint ut_track_number = blockIdx.y; ut_track_number < ut_event_number_of_tracks; ut_track_number += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + ut_track_number;

    if (dev_scifi_lf_process_track[current_ut_track_index]) {
      const auto velo_track_index = ut_tracks.velo_track[ut_track_number];
      const auto qop = dev_ut_qop[current_ut_track_index];
      const int* initial_windows = dev_initial_windows + current_ut_track_index;

      const uint velo_states_index = velo_tracks_offset_event + velo_track_index;
      const MiniState velo_state = velo_states.getMiniState(velo_states_index);
      const auto x_at_z_magnet = velo_state.x + (LookingForward::z_magnet - velo_state.z) * velo_state.tx;

      for (uint triplet_seed = threadIdx.y; triplet_seed < LookingForward::n_triplet_seeds;
           triplet_seed += blockDim.y) {
        const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
        const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
        const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];

        const int l0_size = initial_windows
          [(layer_0 * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];
        const int l1_size = initial_windows
          [(layer_1 * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];
        const int l2_size = initial_windows
          [(layer_2 * LookingForward::number_of_elements_initial_window + 1) * ut_total_number_of_tracks];

        if (l0_size > 0 && l1_size > 0 && l2_size > 0) {
          const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
          const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_1];
          const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

          lf_triplet_seeding_impl(
            scifi_hits.x0 + event_offset,
            layer_0,
            layer_1,
            layer_2,
            l0_size,
            l1_size,
            l2_size,
            z0,
            z1,
            z2,
            initial_windows,
            ut_total_number_of_tracks,
            qop,
            (dev_ut_states + current_ut_track_index)->tx,
            velo_state.tx,
            x_at_z_magnet,
            shared_precalc_expected_x1 + triplet_seed * LookingForward::max_number_of_hits_in_window,
            dev_scifi_lf_found_triplets + (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                                            LookingForward::triplet_seeding_block_dim_x *
                                            LookingForward::maximum_number_of_triplets_per_thread,
            dev_scifi_lf_number_of_found_triplets +
              (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                LookingForward::triplet_seeding_block_dim_x,
            triplet_seed);
        }
      }
    }
  }
}
