#include "LFFormSeedsFromCandidates.cuh"

__global__ void lf_form_seeds_from_candidates(
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
  SciFi::TrackCandidate* dev_scifi_track_candidates,
  int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const uint* dev_first_layer_candidates,
  const unsigned short* dev_second_layer_candidates,
  const MiniState* dev_ut_states,
  const uint station)
{
  __shared__ float looking_forward_constants [8];

  const auto first_layer = (station - 1) * 4;
  
  for (int i=threadIdx.x; i<4; i+=blockDim.x) {
    looking_forward_constants[i] = dev_looking_forward_constants->Zone_zPos[first_layer + i];
    looking_forward_constants[4 + i] = dev_looking_forward_constants->Zone_dxdy[i];
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
  SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);

  // SciFi un-consolidated track types
  SciFi::TrackCandidate* scifi_track_candidates = dev_scifi_track_candidates + event_number * SciFi::Constants::max_track_candidates;
  int* atomics_scifi = dev_atomics_scifi + event_number;

  // Looking Forward offset and size of this event
  const uint* offset_size_first_candidate_pointer = dev_first_layer_candidates + ut_tracks.total_number_of_tracks + ut_event_tracks_offset;
  const uint offset_first_candidate = *offset_size_first_candidate_pointer;
  const uint size_first_candidate = *(offset_size_first_candidate_pointer + ut_event_number_of_tracks) - offset_first_candidate;
  const uint total_number_of_candidates = *(dev_first_layer_candidates + 2 * ut_tracks.total_number_of_tracks);

  // Only proceed if we have candidates in the first window
  if (size_first_candidate > 0) {
    const unsigned short* second_candidate_p = dev_second_layer_candidates + offset_first_candidate;

    for (int i=threadIdx.x; i<size_first_candidate; i+=blockDim.x) {
      const auto rel_ut_track_index = second_candidate_p[i];
      const auto first_candidate_index = second_candidate_p[total_number_of_candidates + i];
      const auto second_candidate_offset = second_candidate_p[2*total_number_of_candidates + i];
      const auto second_candidate_size = second_candidate_p[3*total_number_of_candidates + i];
      const auto second_candidate_l1_start = second_candidate_p[4*total_number_of_candidates + i];
      const auto second_candidate_l1_size = second_candidate_p[5*total_number_of_candidates + i];
      const auto second_candidate_l2_start = second_candidate_p[6*total_number_of_candidates + i];
      const auto second_candidate_l2_size = second_candidate_p[7*total_number_of_candidates + i];
      const MiniState state_at_z_last_ut_plane = dev_ut_states[ut_event_tracks_offset + rel_ut_track_index];

      lf_form_seeds_from_candidates_impl(
        state_at_z_last_ut_plane,
        ut_tracks.qop[rel_ut_track_index],
        rel_ut_track_index,
        scifi_hits,
        scifi_hit_count,
        looking_forward_constants,
        atomics_scifi,
        scifi_track_candidates,
        first_candidate_index,
        second_candidate_offset,
        second_candidate_size,
        second_candidate_l1_start,
        second_candidate_l1_size,
        second_candidate_l2_start,
        second_candidate_l2_size);
    }
  }
}
