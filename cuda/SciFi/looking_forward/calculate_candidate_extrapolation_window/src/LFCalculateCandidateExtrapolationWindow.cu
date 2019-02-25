#include "LFCalculateCandidateExtrapolationWindow.cuh"

__global__ void lf_calculate_candidate_extrapolation_window(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const SciFi::TrackCandidate* dev_scifi_track_candidates,
  const int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  const uint8_t layer,
  unsigned short* dev_extrapolation_layer_candidates)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);

  // SciFi un-consolidated track types
  int number_of_candidates = *(dev_atomics_scifi + event_number);

  // Only proceed if we have candidates in the first window
  for (int i=threadIdx.x; i<number_of_candidates; i+=blockDim.x) {
    unsigned short* extrapolation_layer_candidates = dev_extrapolation_layer_candidates + event_number * SciFi::Constants::max_track_candidates + i;
    const SciFi::TrackCandidate track_candidate = dev_scifi_track_candidates[event_number * SciFi::Constants::max_track_candidates + i];
    const MiniState state_at_z_last_ut_plane = dev_ut_states[ut_event_tracks_offset + track_candidate.ut_track_index];
    const float projection_y = LookingForward::y_at_z(state_at_z_last_ut_plane, dev_looking_forward_constants->Zone_zPos[layer]);

    lf_calculate_candidate_extrapolation_window_impl(
      projection_y,
      scifi_hits,
      scifi_hit_count,
      dev_looking_forward_constants,
      track_candidate,
      layer,
      extrapolation_layer_candidates,
      number_of_events * SciFi::Constants::max_track_candidates);
  }
}
