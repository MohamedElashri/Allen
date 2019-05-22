#include "LFExtendMissingX.cuh"
#include "BinarySearch.cuh"

__global__ void lf_extend_missing_x(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // UT consolidated tracks
  const int ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const int number_of_tracks = dev_atomics_scifi[event_number];

  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto current_ut_track_index = ut_event_tracks_offset + track.ut_track_index; 

    // Find out missing layers
    uint8_t number_of_missing_layers = 0;
    uint8_t missing_layers[2];

    for (int j = 0; j < 6; ++j) {
      const auto layer_j = dev_looking_forward_constants->x_layers[j];
      bool found = false;
      for (int k = 0; k < track.hitsNum; ++k) {
        const auto hit_index = event_offset + track.hits[k];
        const auto layer_k = scifi_hits.planeCode(hit_index) >> 1;
        found |= layer_j == layer_k;
      }
      if (!found) {
        missing_layers[number_of_missing_layers++] = j;
      }
    }

    const auto h0 = event_offset + track.hits[0];
    const auto h1 = event_offset + track.hits[1];
    const auto x0 = scifi_hits.x0[h0];
    const auto x1 = scifi_hits.x0[h1];
    const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(0)];
    const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[track.get_layer(1)];

    for (int j = 0; j < number_of_missing_layers; ++j) {
      const auto current_layer = missing_layers[j];

      // Find window
      const auto UT_state = dev_ut_states[current_ut_track_index];
      const float y_projection = LookingForward::y_at_z(UT_state, dev_looking_forward_constants->Zone_zPos_xlayers[0]);
      const auto iZoneStartingPoint = (y_projection >= 0) ? 6 : 0;

      const float zZone = dev_looking_forward_constants->Zone_zPos_xlayers[current_layer];

      const auto stateInZone = LookingForward::propagate_state_from_velo(
        UT_state,
        track.qop,
        dev_looking_forward_constants->x_layers[current_layer],
        dev_looking_forward_constants);
      const float xInZone = stateInZone.x;

      const float xMag = LookingForward::state_at_z(UT_state, LookingForward::z_magnet).x;
      const float xTol = 1.5f * LookingForward::dx_calc(UT_state.tx, track.qop);
      float xMin = xInZone - xTol;
      float xMax = xInZone + xTol;

      // Get the hits within the bounds
      const int x_zone_offset_begin = scifi_hit_count.zone_offset(dev_looking_forward_constants->xZones[iZoneStartingPoint + current_layer]);
      const int x_zone_size = scifi_hit_count.zone_number_of_hits(dev_looking_forward_constants->xZones[iZoneStartingPoint + current_layer]);
      const int hits_within_bounds_start = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin, x_zone_size, xMin);
      const int hits_within_bounds_size = binary_search_leftmost(
        scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xMax);
      
      // printf("Track %i %i, current layer %i, bin window %i %i\n",
      //   current_ut_track_index,
      //   i,
      //   current_layer,
      //   hits_within_bounds_start,
      //   hits_within_bounds_size);

      // Try all hits in the window now
      const auto best_index = lf_extend_missing_x_impl(
        scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start,
        hits_within_bounds_size,
        track,
        x0,
        x1,
        z0,
        z1,
        zZone,
        LookingForward::chi2_mean_extrapolation_to_x_layers_single);

      if (best_index != -1) {
        // printf("  Found hit for track %i, %i: hit %i\n",
        //   current_ut_track_index,
        //   i,
        //   best_index);

        track.add_hit((uint16_t) ((x_zone_offset_begin + hits_within_bounds_start - event_offset) + best_index));
      }
    }
  }
}
