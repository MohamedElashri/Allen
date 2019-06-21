#include "LFCalculateSecondLayerWindow.cuh"

__global__ void lf_calculate_second_layer_window(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const int* dev_atomics_ut,
  const char* dev_ut_track_hits,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  uint* dev_first_layer_candidates,
  unsigned short* dev_second_layer_candidates,
  const MiniState* dev_ut_states,
  const int station)
{
  __shared__ MiniState states_at_z_last_ut_plane[2];
  __shared__ float looking_forward_constants[7];

  const auto first_layer = (station - 1) * 4;

  if (threadIdx.x == 0) {
    for (int i = threadIdx.y; i < 4; i += blockDim.y) {
      looking_forward_constants[i] = dev_looking_forward_constants->Zone_zPos[first_layer + i];
    }

    if (threadIdx.y == 0) {
      looking_forward_constants[4] = dev_looking_forward_constants->zMagnetParams[0];
    }

    for (int i = threadIdx.y; i < 2; i += blockDim.y) {
      looking_forward_constants[5 + i] = dev_looking_forward_constants->Zone_dxdy[1 + i];
    }
  }

  __syncthreads();

  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, (uint*) dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, velo_tracks.total_number_of_tracks};
  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                      (uint*) dev_ut_track_hit_number,
                                      (float*) dev_ut_qop,
                                      (uint*) dev_ut_track_velo_indices,
                                      event_number,
                                      number_of_events};
  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};

  // Looking Forward first layer window parameters
  const uint* first_candidate_start = dev_first_layer_candidates + ut_event_tracks_offset;
  const uint* offset_size_first_candidate_pointer =
    dev_first_layer_candidates + ut_event_tracks_offset + ut_tracks.total_number_of_tracks;
  const uint total_number_of_candidates = *(dev_first_layer_candidates + 2 * ut_tracks.total_number_of_tracks);

  // Loop over the veloUT input tracks
  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    const uint local_hit_offset_first_candidate = first_candidate_start[i];
    const uint offset_first_candidate = offset_size_first_candidate_pointer[i];
    const uint size_first_candidate =
      offset_size_first_candidate_pointer[i + 1] - offset_size_first_candidate_pointer[i];

    if (size_first_candidate > 0) {
      unsigned short* second_candidate_p = dev_second_layer_candidates + offset_first_candidate;

      __syncthreads();

      if (threadIdx.y == 0) {
        const int ut_track_index = ut_event_tracks_offset + i;
        states_at_z_last_ut_plane[threadIdx.x] = dev_ut_states[ut_track_index];
      }

      __syncthreads();

      lf_calculate_second_layer_window_impl(
        states_at_z_last_ut_plane,
        ut_tracks.qop[i],
        scifi_hits,
        scifi_hit_count,
        first_layer,
        looking_forward_constants,
        i,
        local_hit_offset_first_candidate,
        size_first_candidate,
        second_candidate_p,
        total_number_of_candidates);
    }
  }
}
