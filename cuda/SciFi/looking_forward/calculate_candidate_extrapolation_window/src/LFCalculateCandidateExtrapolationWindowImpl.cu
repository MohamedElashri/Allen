#include "LFCalculateCandidateExtrapolationWindowImpl.cuh"

using namespace LookingForward;

__device__ void lf_calculate_candidate_extrapolation_window_impl(
  const float projection_y,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::TrackCandidate& track_candidate,
  const uint8_t layer,
  unsigned short* extrapolation_layer_candidates,
  const int extrapolation_candidates_offset)
{
  // do the propagation
  const auto x_at_layer_8 = hits.x0[hit_count.event_offset() + track_candidate.hits[0]];
  const auto reco_slope = (hits.x0[hit_count.event_offset() + track_candidate.hits[1]] - x_at_layer_8) * LookingForward::inverse_dz_x_layers;

  const auto projection_x = LookingForward::scifi_propagation(
                              x_at_layer_8,
                              reco_slope,
                              track_candidate.qop,
                              dev_looking_forward_constants->Zone_zPos[layer] - dev_looking_forward_constants->Zone_zPos[8]) -
                            dev_looking_forward_constants->Zone_dxdy[(layer % 4)] * projection_y;

  const auto layer_offset_nhits = LookingForward::get_offset_and_n_hits_for_layer(2 * layer, hit_count, projection_y);
  const auto layer_candidates = LookingForward::find_x_in_window(
    hits,
    std::get<0>(layer_offset_nhits),
    std::get<1>(layer_offset_nhits),
    projection_x,
    3 * dev_looking_forward_constants->extrapolation_stddev[layer]);

  extrapolation_layer_candidates[0] = std::get<0>(layer_candidates) - hit_count.event_offset();
  extrapolation_layer_candidates[extrapolation_candidates_offset] = std::get<1>(layer_candidates) - std::get<0>(layer_candidates);
}
