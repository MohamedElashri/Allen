#include "MomentumForwardUtils.h"

// access hits from a layer
// first zone number: y < 0
// second zone number: y > 0
std::tuple<int, int>
get_offset_and_n_hits_for_layer(const int first_zone, const SciFi::HitCount& scifi_hit_count, const float y)
{
  assert(first_zone < SciFi::Constants::n_zones - 1);
  const auto offset = (y < 0) ? 0 : 1;

  return {scifi_hit_count.zone_offset(first_zone + offset), scifi_hit_count.zone_number_of_hits(first_zone + offset)};
}

void get_offset_and_n_hits_for_layer(
  const int first_zone,
  const SciFi::HitCount& scifi_hit_count,
  const float y,
  int& zone_number_of_hits,
  int& zone_offset)
{
  assert(first_zone < SciFi::Constants::n_zones - 1);
  const auto offset = (y < 0) ? 0 : 1;

  zone_offset = scifi_hit_count.zone_offset(first_zone + offset);
  zone_number_of_hits = scifi_hit_count.zone_number_of_hits(first_zone + offset);
}

// straight line extrapolation of MiniState to other z position
MiniState state_at_z(const MiniState state, const float z)
{
  MiniState extrap_state;
  extrap_state.tx = state.tx;
  extrap_state.ty = state.ty;
  extrap_state.x = state.x + (z - state.z) * state.tx;
  extrap_state.y = state.y + (z - state.z) * state.ty;
  extrap_state.z = z;
  return extrap_state;
}

// straight line extrapolation of y to other z position
float y_at_z(const MiniState state, const float z)
{
  float yf = state.y + (z - state.z) * state.ty;
  return yf;
}
