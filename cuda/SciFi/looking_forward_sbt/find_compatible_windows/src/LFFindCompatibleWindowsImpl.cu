#include "LFFindCompatibleWindowsImpl.cuh"
#include "BinarySearchTools.cuh"

__device__ void lf_find_compatible_windows_impl(
  const SciFi::Hits& scifi_hits,
  const uint8_t relative_layer,
  const uint* number_of_candidates,
  const short* candidates,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float UT_state_tx,
  const float x_at_ref,
  const float z_mag,
  const int ut_total_number_of_tracks,
  short* compatible_window,
  const int total_number_of_candidates,
  const float event_offset)
{
  const uint8_t relative_layer_direction = relative_layer % 2;
  const uint8_t relative_layer_from = (relative_layer >> 1) + 1;
  const uint8_t relative_layer_to = relative_layer_from + 2 * relative_layer_direction - 1;
  const uint8_t layer_from = (relative_layer_from >> 1) * 4 + (relative_layer_from % 2) * 3;
  const uint8_t layer_to = relative_layer_direction * 4 + (relative_layer >> 2) * 4 + ((relative_layer >> 1) % 2) * 3;

  const auto z1 = dev_looking_forward_constants->Zone_zPos[layer_from];
  const auto z0 = dev_looking_forward_constants->Zone_zPos[layer_to];
  const auto dSlopeDivPart = 1.f / (z1 - LookingForward::zMagnetParams_0);
  const auto x_from_velo_hit = x_at_ref + UT_state_tx * z1;
  const auto dz = 1.e-3f * std::abs(z1 - z0);
  const auto dxCoef_part = dz * dz * (LookingForward::xParams_0 + dz * LookingForward::xParams_1);

  const int candidate_from_offset = number_of_candidates[relative_layer_from];
  const uint8_t number_of_candidates_from = number_of_candidates[relative_layer_from + 1] - candidate_from_offset;
  const uint8_t number_of_candidates_to = number_of_candidates[relative_layer_to + 1] - number_of_candidates[relative_layer_to];

  for (int h1_rel = threadIdx.z; h1_rel < number_of_candidates_from; h1_rel += blockDim.z) {
    const auto h1_index = candidates[relative_layer_from * LookingForward::maximum_number_of_candidates + h1_rel];
    const auto x1 = scifi_hits.x0[h1_index];

    const auto dSlope = (x_from_velo_hit - x1) * dSlopeDivPart;
    const auto zMag_corrected = z_mag + LookingForward::zMagnetParams_1 * dSlope * dSlope;
    const auto xMag = x_from_velo_hit + UT_state_tx * (zMag_corrected - z1);

    // calculate x position on reference plane (save in coodX)
    // dxCoef: account for additional bending of track due to fringe field in first station
    // expressed by quadratic and cubic term in z
    const auto dxCoef = dxCoef_part * dSlope;
    const auto ratio = (z0 - zMag_corrected) / (z1 - zMag_corrected);
    const auto extrapolated_value = xMag + ratio * (x1 + dxCoef - xMag);

    const auto window = find_x_in_window(
      candidates + relative_layer_to * LookingForward::maximum_number_of_candidates,
      scifi_hits,
      number_of_candidates_to,
      extrapolated_value,
      4.f * dev_looking_forward_constants->dx_stddev_triplet[relative_layer],
      event_offset);

    compatible_window[relative_layer_direction * total_number_of_candidates + candidate_from_offset + h1_rel] =
      std::get<0>(window);

    compatible_window[(2 + relative_layer_direction) * total_number_of_candidates + candidate_from_offset + h1_rel] =
      std::get<1>(window);
  }
}
