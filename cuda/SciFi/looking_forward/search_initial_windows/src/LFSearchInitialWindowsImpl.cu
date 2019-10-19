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
  // uint8_t sizes = 0x00;

  for (int i = 0; i < LookingForward::number_of_x_layers; i++) {
    const auto iZone = iZoneStartingPoint + i;

    const auto stateInZone = LookingForward::propagate_state_from_velo_multi_par(
      UT_state, qop, looking_forward_constants->x_layers[i], looking_forward_constants);

    const float xInZone = stateInZone.x;

    const float xMag = LookingForward::state_at_z(UT_state, LookingForward::z_magnet).x;

    const float xTol = 1.5f * LookingForward::dx_calc(UT_state.tx, qop);
    float xMin = xInZone - xTol;
    float xMax = xInZone + xTol;

    // Get the hits within the bounds
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(looking_forward_constants->xZones[iZone]);
    const int x_zone_size = scifi_hit_count.zone_number_of_hits(looking_forward_constants->xZones[iZone]);
    int hits_within_bounds_start = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin, x_zone_size, xMin);
    const int hits_within_bounds_xInZone = binary_search_leftmost(
      scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xInZone);
    const int hits_within_bounds_size = binary_search_leftmost(
      scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xMax);

    hits_within_bounds_start += x_zone_offset_begin;

    // Initialize windows
    initial_windows[i * 8 * number_of_tracks] = hits_within_bounds_start;
    initial_windows[(i * 8 + 1) * number_of_tracks] = hits_within_bounds_size;
    initial_windows[(i * 8 + 2) * number_of_tracks] = hits_within_bounds_xInZone;

    // sizes |= (hits_within_bounds_size > 0) << i;
  }

  // A track is processable if there is at least one recostructible triplet
  // const bool process_track = 
  //   ((sizes & 0x01) && (sizes & 0x02) && (sizes & 0x04)) ||
  //   ((sizes & 0x02) && (sizes & 0x04) && (sizes & 0x08)) ||
  //   ((sizes & 0x04) && (sizes & 0x08) && (sizes & 0x10)) ||
  //   ((sizes & 0x08) && (sizes & 0x10) && (sizes & 0x20));
}
