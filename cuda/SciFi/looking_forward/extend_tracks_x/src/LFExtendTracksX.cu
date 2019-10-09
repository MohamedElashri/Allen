#include "LFExtendTracksX.cuh"

__global__ void lf_extend_tracks_x(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const uint* dev_scifi_lf_number_of_candidates,
  const short* dev_scifi_lf_candidates)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const int ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  for (int i_ut_track = threadIdx.y; i_ut_track < ut_event_number_of_tracks; i_ut_track += blockDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i_ut_track;
    int number_of_tracks = dev_atomics_scifi[current_ut_track_index];

    for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
      SciFi::TrackHits& track =
        dev_scifi_tracks[current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + i];

      // Candidates pointer for current UT track
      const auto scifi_lf_candidates = dev_scifi_lf_candidates + current_ut_track_index *
                                                                   LookingForward::number_of_x_layers *
                                                                   LookingForward::maximum_number_of_candidates;

      const auto h0 = event_offset + track.hits[0];
      const auto h1 = event_offset + track.hits[1];
      const auto x0 = scifi_hits.x0[h0];
      const auto x1 = scifi_hits.x0[h1];
      const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(0)];
      const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(1)];

      // Extrapolate to other layers
      for (int j = 0; j < LookingForward::number_of_x_layers; ++j) {
        // Make sure we don't have that layer populated already
        bool layer_populated = false;
        for (int k = 0; k < 3; ++k) {
          layer_populated |= track.get_layer(k) == j;
        }

        if (!layer_populated) {
          const int8_t number_of_candidates =
            dev_scifi_lf_number_of_candidates[current_ut_track_index * LookingForward::number_of_x_layers + j];

          lf_extend_tracks_x_impl(
            scifi_hits.x0 + event_offset,
            scifi_lf_candidates + j * LookingForward::maximum_number_of_candidates,
            number_of_candidates,
            track,
            x0,
            x1,
            z0,
            z1,
            dev_looking_forward_constants->Zone_zPos_xlayers[j],
            LookingForward::chi2_max_extrapolation_to_x_layers_single);
        }
      }
    }
  }
}
