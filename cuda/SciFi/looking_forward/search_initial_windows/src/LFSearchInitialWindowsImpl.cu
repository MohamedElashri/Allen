#include "LFSearchInitialWindowsImpl.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

__device__ void lf_search_initial_windows_impl(
  SciFi::ConstHits& scifi_hits,
  SciFi::ConstHitCount& scifi_hit_count,
  const MiniState& UT_state,
  const LookingForward::Constants* looking_forward_constants,
  const float qop,
  const bool side,
  int* initial_windows,
  const int number_of_tracks,
  const uint event_offset,
  bool* dev_process_track,
  const uint ut_track_index)
{
  int iZoneStartingPoint = side ? LookingForward::number_of_x_layers : 0;
  uint16_t sizes = 0;

  for (int i = 0; i < LookingForward::number_of_x_layers; i++) {
    const auto iZone = iZoneStartingPoint + i;

    const auto stateInZone = LookingForward::propagate_state_from_velo_multi_par(
      UT_state, qop, looking_forward_constants->x_layers[i], looking_forward_constants);
    const float xInZone = stateInZone.x;

    const float xTol =
      LookingForward::initial_window_offset_xtol + LookingForward::initial_window_factor_qop * fabsf(qop);
    const float xMin = xInZone - xTol - LookingForward::initial_window_factor_assymmetric_opening * signbit(qop);
    const float xMax =
      xInZone + xTol + LookingForward::initial_window_factor_assymmetric_opening * (signbit(qop) ^ 0x01);

    // Get the hits within the bounds
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->xZones[iZone]);
    const int x_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->xZones[iZone]);
    const int hits_within_bounds_start = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin, x_zone_size, xMin);
    const int hits_within_bounds_xInZone = binary_search_leftmost(
      scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xInZone);
    const int hits_within_bounds_size = binary_search_leftmost(
      scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xMax);

    // Cap the central windows to a certain size
    const int central_window_begin =
      max(hits_within_bounds_xInZone - LookingForward::max_number_of_hits_in_window / 2, 0);
    const int central_window_size =
      min(central_window_begin + LookingForward::max_number_of_hits_in_window, hits_within_bounds_size) -
      central_window_begin;

    // Initialize windows
    initial_windows[i * LookingForward::number_of_elements_initial_window * number_of_tracks] =
      hits_within_bounds_start + x_zone_offset_begin - event_offset + central_window_begin;
    initial_windows[(i * LookingForward::number_of_elements_initial_window + 1) * number_of_tracks] =
      central_window_size;

    sizes |= (hits_within_bounds_size > 0) << i;

    // Skip making range but continue if the size is zero
    if (hits_within_bounds_size > 0) {
      // Now match the stereo hits
      const float zZone = looking_forward_constants->Zone_zPos_xlayers[i];
      const float this_uv_z = looking_forward_constants->Zone_zPos_uvlayers[i];
      const float dz = this_uv_z - zZone;
      const float xInUv = LookingForward::linear_propagation(xInZone, stateInZone.tx, dz);
      const float UvCorr =
        LookingForward::y_at_z(stateInZone, this_uv_z) * looking_forward_constants->Zone_dxdy_uvlayers[i % 2];
      const float xInUvCorr = xInUv - UvCorr;
      const float xMinUV = xInUvCorr - LookingForward::initial_windows_max_offset_uv_window;
      const float xMaxUV = xInUvCorr + LookingForward::initial_windows_max_offset_uv_window;

      // Get bounds in UV layers
      // do one search on the same side as the x module
      const int uv_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->uvZones[iZone]);
      const int uv_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->uvZones[iZone]);
      const int hits_within_uv_bounds =
        binary_search_leftmost(scifi_hits.x0_p(uv_zone_offset_begin, uv_zone_size, xMinUV));
      const int hits_within_uv_bounds_size = binary_search_leftmost(
        scifi_hits.x0_p(uv_zone_offset_begin + hits_within_uv_bounds, uv_zone_size - hits_within_uv_bounds, xMaxUV));

      initial_windows[(i * LookingForward::number_of_elements_initial_window + 2) * number_of_tracks] =
        hits_within_uv_bounds + uv_zone_offset_begin - event_offset;
      initial_windows[(i * LookingForward::number_of_elements_initial_window + 3) * number_of_tracks] =
        hits_within_uv_bounds_size;

      sizes |= (hits_within_uv_bounds_size > 0) << (8 + i);
    }
  }

  // Process track if:
  // * It can have a triplet 0,2,4 or 1,3,5
  // * It can have at least one hit in UV layers
  //   (1 or 2) and (5 or 6) and (9 or 10)
  const bool do_process =
    (((sizes & LookingForward::bit_layer0) && (sizes & LookingForward::bit_layer4) && (sizes & LookingForward::bit_layer8)) ||
     ((sizes & LookingForward::bit_layer3) && (sizes & LookingForward::bit_layer7) && (sizes & LookingForward::bit_layer11))) &&
    ((sizes & LookingForward::bit_layer1) || (sizes & LookingForward::bit_layer2)) &&
    ((sizes & LookingForward::bit_layer5) || (sizes & LookingForward::bit_layer6)) &&
    ((sizes & LookingForward::bit_layer9) || (sizes & LookingForward::bit_layer10));

  dev_process_track[ut_track_index] = do_process;
}
