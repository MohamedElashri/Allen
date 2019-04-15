#include "LFQualityFilter.cuh"

__global__ void lf_quality_filter(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const int* dev_atomics_ut,
  const char* dev_ut_track_hits,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  float* dev_scifi_lf_track_params,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const SciFi::Tracking::TMVA* dev_tmva1,
  const SciFi::Tracking::TMVA* dev_tmva2,
  const SciFi::Tracking::Arrays* constArrays,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity,
  int* dev_atomics_scifi,
  SciFi::TrackHits* dev_scifi_tracks)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, (uint*) dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, velo_tracks.total_number_of_tracks};
  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  const UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                            (uint*) dev_ut_track_hit_number,
                                            (float*) dev_ut_qop,
                                            (uint*) dev_ut_track_velo_indices,
                                            event_number,
                                            number_of_events};
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number);

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  const auto number_of_tracks = dev_scifi_lf_atomics[event_number];

  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_lf_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;
    const auto velo_states_index = velo_tracks_offset_event + ut_tracks.velo_track[track.ut_track_index];
    float* trackParams = dev_scifi_lf_track_params + ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter * SciFi::Tracking::nTrackParams + i * SciFi::Tracking::nTrackParams;

    const MiniState velo_state = velo_states.getMiniState(velo_states_index);

    // float trackParams[SciFi::Tracking::nTrackParams];
    // lf_fit_impl(
    //   track,
    //   event_offset,
    //   scifi_hits,
    //   dev_looking_forward_constants,
    //   constArrays,
    //   velo_state,
    //   trackParams);

    track.quality = lf_track_quality(track, velo_state, dev_ut_qop[current_ut_track_index], trackParams, constArrays, dev_magnet_polarity[0], dev_tmva1, dev_tmva2);
  }

  __syncthreads();

  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    float best_quality = LookingForward::track_min_quality;
    short best_track_index = -1;

    for (int j = 0; j < number_of_tracks; j++) {
      const SciFi::TrackHits& track = dev_scifi_lf_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + j];
      if (track.ut_track_index == i && track.quality > best_quality) {
        best_quality = track.quality;
        best_track_index = j;
      }
    }

    if (best_track_index != -1) {
      const auto insert_index = atomicAdd(dev_atomics_scifi + event_number, 1);
      assert(insert_index < ut_event_number_of_tracks); // only one candidate per UT track, to do: check efficiency when allowing for more
      const auto& track = dev_scifi_lf_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + best_track_index];
      dev_scifi_tracks[event_number * SciFi::Constants::max_tracks + insert_index] = track;
    }
  }

}
