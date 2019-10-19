#include "LFSearchInitialWindowsImpl.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

__device__ inline float linear_parameterization(const float value_at_ref, const float t, const float z)
{
  float dz = z - SciFi::Tracking::zReference;
  return value_at_ref + t * dz;
}

__device__ void lf_search_initial_windows_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const MiniState& UT_state,
  const LookingForward::Constants* looking_forward_constants,
  const float qop,
  const int side,
  int* initial_windows,
  const int number_of_tracks)
{
  int iZoneStartingPoint = (side > 0) ? LookingForward::number_of_x_layers : 0;

  for (int i = threadIdx.y; i < LookingForward::number_of_x_layers; i += blockDim.y) {
    const auto iZone = iZoneStartingPoint + i;
    const float zZone = looking_forward_constants->Zone_zPos_xlayers[i];

    // TODO this could be done in a more optimized way
    const auto stateInZone = LookingForward::propagate_state_from_velo_multi_par(
      UT_state, qop, looking_forward_constants->x_layers[i], looking_forward_constants);

    const float xInZone = stateInZone.x;
    // const float yInZone = stateInZone.y;

    const float xMag = LookingForward::state_at_z(UT_state, LookingForward::z_magnet).x;

    const float xTol = 1.5f * LookingForward::dx_calc(UT_state.tx, qop);
    float xMin = xInZone - xTol;
    float xMax = xInZone + xTol;

    // Get the hits within the bounds
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->xZones[iZone]);
    const int x_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->xZones[iZone]);
    int hits_within_bounds_start = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin, x_zone_size, xMin);
    int hits_within_bounds_size = binary_search_leftmost(
      scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xMax);
    hits_within_bounds_start += x_zone_offset_begin;

    // Initialize windows
    initial_windows[i * 8 * number_of_tracks] = hits_within_bounds_start;
    initial_windows[(i * 8 + 1) * number_of_tracks] = hits_within_bounds_size;

    // Skip making range but continue if the size is zero
    if (hits_within_bounds_size > 0) {
      // Now match the stereo hits
      const float this_uv_z = looking_forward_constants->Zone_zPos_uvlayers[i];
      const float dz = this_uv_z - zZone;
      const float xInUv = LookingForward::linear_propagation(xInZone, stateInZone.tx, dz);
      const float UvCorr = LookingForward::y_at_z(stateInZone, this_uv_z) * looking_forward_constants->Zone_dxdy_uvlayers[i % 2];
      const float xInUvCorr = xInUv - UvCorr;
      const float xMinUV = xInUvCorr - 800.f;
      const float dz_ratio = (this_uv_z - zZone) / (LookingForward::z_magnet - zZone);

      // Get bounds in UV layers
      // do one search on the same side as the x module
      // if we are close to y = 0, also look within a region on the other side module ("triangle search")
      const int uv_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->uvZones[iZone]);
      const int uv_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->uvZones[iZone]);
      const int hits_within_uv_bounds =
        binary_search_leftmost(scifi_hits.x0 + uv_zone_offset_begin, uv_zone_size, xMinUV);

      initial_windows[(i * 8 + 2) * number_of_tracks] = hits_within_uv_bounds + uv_zone_offset_begin;
      initial_windows[(i * 8 + 3) * number_of_tracks] = uv_zone_size - hits_within_uv_bounds;

      float* initial_windows_f = (float*) &initial_windows[0];
      initial_windows_f[(i * 8 + 4) * number_of_tracks] = xMag;
      initial_windows_f[(i * 8 + 5) * number_of_tracks] = UvCorr;
      // TODO this should be read from the constants
      initial_windows_f[(i * 8 + 6) * number_of_tracks] = looking_forward_constants->uv_dx[i];
      initial_windows_f[(i * 8 + 7) * number_of_tracks] = dz_ratio;
    }
  }
}
