#include "LFConvertTrackIndices.cuh"

__global__ void lf_convert_track_indices(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  const int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const uint* dev_scifi_lf_number_of_candidates,
  const short* dev_scifi_lf_candidates)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  // SciFi un-consolidated track types
  const int number_of_tracks = dev_atomics_scifi[event_number];

  for (int i=threadIdx.x; i<number_of_tracks; i+=blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_tracks[event_number * SciFi::Constants::max_tracks + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index;

    // Candidates pointer for current UT track
    const auto scifi_lf_candidates = dev_scifi_lf_candidates + current_ut_track_index * LookingForward::number_of_x_layers *
                                                           LookingForward::maximum_number_of_candidates;

    for (int i=0; i<track.hitsNum; ++i) {
      track.hits[i] = (uint16_t) (scifi_lf_candidates[track.hits[i]]);
    }
  }
}
