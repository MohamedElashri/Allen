#include "LFExtendTracksImpl.cuh"

using namespace LookingForward;

__device__ std::tuple<int16_t, float> lf_extend_tracks_impl(
  const float projection_y,
  const unsigned short first_extrapolated_candidate,
  const unsigned short size_extrapolated_candidates,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::TrackHits& track,
  const uint8_t layer)
{
  // do the propagation
  const auto x_at_layer_8 = hits.x0[hit_count.event_offset() + track.hits[0]];
  const auto x_at_layer_11 = hits.x0[hit_count.event_offset() + track.hits[1]];
  const auto reco_slope = (x_at_layer_11 - x_at_layer_8) * LookingForward::inverse_dz_x_layers;

  // Pick the best, according to chi2
  int16_t best_index = -1;
  float best_chi2 = dev_looking_forward_constants->chi2_extrap_mean[layer]
    + 2.f * dev_looking_forward_constants->chi2_extrap_stddev[layer];

  const auto hit_layer8 = std::make_tuple(dev_looking_forward_constants->Zone_zPos[8], x_at_layer_8);
  const auto hit_layer11 = std::make_tuple(dev_looking_forward_constants->Zone_zPos[11], x_at_layer_11);

  for (int i = 0; i < size_extrapolated_candidates; i++) {
    const auto hit_current_layer = std::make_tuple(dev_looking_forward_constants->Zone_zPos[layer],
      hits.x0[hit_count.event_offset() + first_extrapolated_candidate + i] + projection_y * dev_looking_forward_constants->Zone_dxdy[layer % 4]);

    const auto chi2 = chi2_extrapolation(
      x_at_layer_8,
      dev_looking_forward_constants->Zone_zPos[8],
      reco_slope,
      track.qop,
      hit_layer8,
      hit_layer11,
      hit_current_layer);
    
    if (chi2 < best_chi2) {
      best_chi2 = chi2;
      best_index = first_extrapolated_candidate + i;
    }
  }

  return {best_index, best_chi2};
}
