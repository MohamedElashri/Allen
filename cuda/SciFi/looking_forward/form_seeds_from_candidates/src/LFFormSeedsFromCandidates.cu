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
  const float* dev_ut_x,
  const float* dev_ut_tx,
  const float* dev_ut_z,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackCandidate* dev_scifi_track_candidates,
  int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const uint* dev_first_layer_candidates,
  const unsigned short* dev_second_layer_candidates,
  const uint station)
{
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
    const unsigned short* second_candidate_ut_track_p = dev_second_layer_candidates + offset_first_candidate;
    const unsigned short* second_candidate_first_candidate_p = dev_second_layer_candidates + total_number_of_candidates + offset_first_candidate;
    const unsigned short* second_candidate_start_p = dev_second_layer_candidates + 2 * total_number_of_candidates + offset_first_candidate;
    const unsigned short* second_candidate_size_p = dev_second_layer_candidates + 3 * total_number_of_candidates + offset_first_candidate;
    const unsigned short* second_candidate_l1_start_p = dev_second_layer_candidates + 4 * total_number_of_candidates + offset_first_candidate;
    const unsigned short* second_candidate_l1_size_p  = dev_second_layer_candidates + 5 * total_number_of_candidates + offset_first_candidate;
    const unsigned short* second_candidate_l2_start_p = dev_second_layer_candidates + 6 * total_number_of_candidates + offset_first_candidate;
    const unsigned short* second_candidate_l2_size_p  = dev_second_layer_candidates + 7 * total_number_of_candidates + offset_first_candidate;

    for (int i=threadIdx.x; i<size_first_candidate; i+=blockDim.x) {
      const int rel_ut_track_index = second_candidate_ut_track_p[i];
      const auto first_candidate_index = second_candidate_first_candidate_p[i];
      const auto second_candidate_offset = second_candidate_start_p[i];
      const auto second_candidate_size = second_candidate_size_p[i];
      const auto second_candidate_l1_start = second_candidate_l1_start_p[i];
      const auto second_candidate_l1_size = second_candidate_l1_size_p[i];
      const auto second_candidate_l2_start = second_candidate_l2_start_p[i];
      const auto second_candidate_l2_size = second_candidate_l2_size_p[i];

      const int ut_track_index = ut_event_tracks_offset + rel_ut_track_index;
      const int velo_track_index = ut_tracks.velo_track[rel_ut_track_index];
      const float ut_qop = ut_tracks.qop[rel_ut_track_index];

      // Note: These data should be accessed like
      //       the previous ut_tracks.qop[i] in the future
      const float ut_x = dev_ut_x[ut_track_index];
      const float ut_tx = dev_ut_tx[ut_track_index];
      const float ut_z = dev_ut_z[ut_track_index];

      const uint velo_states_index = velo_tracks_offset_event + velo_track_index;
      const MiniState velo_state {velo_states, velo_states_index};

      // extrapolate velo y & ty to z of UT x and tx
      // use ty from Velo state
      const MiniState ut_state {ut_x, LookingForward::y_at_z(velo_state, ut_z), ut_z, ut_tx, velo_state.ty};
      const MiniState state_at_z_last_ut_plane = LookingForward::state_at_z(ut_state, LookingForward::z_last_UT_plane);

      lf_form_seeds_from_candidates_impl(
        state_at_z_last_ut_plane,
        ut_qop,
        rel_ut_track_index,
        scifi_hits,
        scifi_hit_count,
        station,
        dev_looking_forward_constants,
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
