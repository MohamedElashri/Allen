#include "FindBestHits.cuh"
#include "CompassUT.cuh"

//=========================================================================
// Get the best 3 or 4 hits, 1 per layer, for a given VELO track
// When iterating over a panel, 3 windows are given, we set the index
// to be only in the windows
//=========================================================================
__device__ std::tuple<int, int, int, int, BestParams> find_best_hits(
  const short* win_size_shared,
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const MiniState& velo_state,
  const float* ut_dxDy,
  const uint parameter_max_considered_before_found,
  const float delta_tx_2,
  const float hit_tol_2,
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope,
  const int event_hit_offset)
{
  uint number_of_candidates = 0;
  uint candidate_pairs[UT::Constants::max_value_considered_before_found];

  const uint max_considered_before_found =
    parameter_max_considered_before_found > UT::Constants::max_value_considered_before_found ?
      UT::Constants::max_value_considered_before_found :
      parameter_max_considered_before_found;

  const float yyProto = velo_state.y - velo_state.ty * velo_state.z;

  const TrackCandidates ranges(win_size_shared);

  int best_hits[UT::Constants::n_layers] = {-1, -1, -1, -1};

  int best_number_of_hits = 3;
  int best_fit = UT::Constants::maxPseudoChi2;
  BestParams best_params;

  // Fill in candidate pairs
  // Get total number of hits for forward + backward in first layer (0 for fwd, 3 for bwd)
  for (int i = 0; number_of_candidates < max_considered_before_found && i < sum_layer_hits(ranges, 0, 3); ++i) {
    const int i_hit0 = calc_index(i, ranges, 0, 3, ut_hit_offsets);
    bool forward = false;

    // set range for next layer if forward or backward
    int layer_2;
    int dxdy_layer = -1;
    if (i < sum_layer_hits(ranges, 0)) {
      forward = true;
      layer_2 = 2;
      dxdy_layer = 0;
    }
    else {
      forward = false;
      layer_2 = 1;
      dxdy_layer = 3;
    }

    // Get info to calculate slope
    const auto zhitLayer0 = ut_hits.zAtYEq0(i_hit0);
    const float yy0 = yyProto + (velo_state.ty * zhitLayer0);
    const auto xhitLayer0 = ut_hits.xAt(i_hit0, yy0, ut_dxDy[dxdy_layer]);

    // 2nd layer
    const int total_hits_2layers_2 = sum_layer_hits(ranges, layer_2);
    for (int j = 0; number_of_candidates < max_considered_before_found && j < total_hits_2layers_2; ++j) {
      int i_hit2 = calc_index(j, ranges, layer_2, ut_hit_offsets);

      // Get info to calculate slope
      const int dxdy_layer_2 = forward ? 2 : 1;
      const auto zhitLayer2 = ut_hits.zAtYEq0(i_hit2);
      const float yy2 = yyProto + (velo_state.ty * zhitLayer2);
      const auto xhitLayer2 = ut_hits.xAt(i_hit2, yy2, ut_dxDy[dxdy_layer_2]);

      // if slope is out of delta range, don't look for triplet/quadruplet
      const auto tx = (xhitLayer2 - xhitLayer0) / (zhitLayer2 - zhitLayer0);
      if (fabsf(tx - velo_state.tx) <= delta_tx_2) {
        candidate_pairs[number_of_candidates++] =
          (forward << 31) | ((i_hit0 - event_hit_offset) << 16) | (i_hit2 - event_hit_offset);
      }
    }
  }

  // Iterate over candidate pairs
  for (uint i = 0; i < number_of_candidates; ++i) {
    const auto pair = candidate_pairs[i];
    const bool forward = pair >> 31;
    const int i_hit0 = event_hit_offset + ((pair >> 16) & 0x7FFF);
    const int i_hit2 = event_hit_offset + (pair & 0x7FFF);

    const auto dxdy_layer = forward ? 0 : 3;
    const auto zhitLayer0 = ut_hits.zAtYEq0(i_hit0);
    const auto yy0 = yyProto + (velo_state.ty * zhitLayer0);
    const auto xhitLayer0 = ut_hits.xAt(i_hit0, yy0, ut_dxDy[dxdy_layer]);

    const auto dxdy_layer_2 = forward ? 2 : 1;
    const auto zhitLayer2 = ut_hits.zAtYEq0(i_hit2);
    const auto yy2 = yyProto + (velo_state.ty * zhitLayer2);
    const auto xhitLayer2 = ut_hits.xAt(i_hit2, yy2, ut_dxDy[dxdy_layer_2]);

    const auto tx = (xhitLayer2 - xhitLayer0) / (zhitLayer2 - zhitLayer0);

    int temp_best_hits[4] = {i_hit0, -1, i_hit2, -1};
    const int layers[2] = {forward ? 1 : 2, forward ? 3 : 0};

    // search for a triplet in 3rd layer
    float hitTol = hit_tol_2;
    for (int i1 = 0; i1 < sum_layer_hits(ranges, layers[0]); ++i1) {

      int i_hit1 = calc_index(i1, ranges, layers[0], ut_hit_offsets);

      // Get info to check tolerance
      const float zhitLayer1 = ut_hits.zAtYEq0(i_hit1);
      const float yy1 = yyProto + (velo_state.ty * zhitLayer1);
      const float xhitLayer1 = ut_hits.xAt(i_hit1, yy1, ut_dxDy[layers[0]]);
      const float xextrapLayer1 = xhitLayer0 + tx * (zhitLayer1 - zhitLayer0);

      if (fabsf(xhitLayer1 - xextrapLayer1) < hitTol) {
        hitTol = fabsf(xhitLayer1 - xextrapLayer1);
        temp_best_hits[1] = i_hit1;
      }
    }

    // search for triplet/quadruplet in 4th layer
    hitTol = hit_tol_2;
    for (int i3 = 0; i3 < sum_layer_hits(ranges, layers[1]); ++i3) {

      int i_hit3 = calc_index(i3, ranges, layers[1], ut_hit_offsets);

      // Get info to check tolerance
      const float zhitLayer3 = ut_hits.zAtYEq0(i_hit3);
      const float yy3 = yyProto + (velo_state.ty * zhitLayer3);
      const float xhitLayer3 = ut_hits.xAt(i_hit3, yy3, ut_dxDy[layers[1]]);
      const float xextrapLayer3 = xhitLayer2 + tx * (zhitLayer3 - zhitLayer2);
      if (fabsf(xhitLayer3 - xextrapLayer3) < hitTol) {
        hitTol = fabsf(xhitLayer3 - xextrapLayer3);
        temp_best_hits[3] = i_hit3;
      }
    }

    // Fit the hits to get q/p, chi2
    const auto temp_number_of_hits = 2 + (temp_best_hits[1] != -1) + (temp_best_hits[3] != -1);
    const auto params =
      pkick_fit(temp_best_hits, ut_hits, velo_state, ut_dxDy, yyProto, forward, sigma_velo_slope, inv_sigma_velo_slope);

    // Save the best chi2 and number of hits triplet/quadruplet
    if (params.chi2UT < best_fit && temp_number_of_hits >= best_number_of_hits) {
      if (forward) {
        best_hits[0] = temp_best_hits[0];
        best_hits[1] = temp_best_hits[1];
        best_hits[2] = temp_best_hits[2];
        best_hits[3] = temp_best_hits[3];
      }
      else {
        best_hits[0] = temp_best_hits[3];
        best_hits[1] = temp_best_hits[2];
        best_hits[2] = temp_best_hits[1];
        best_hits[3] = temp_best_hits[0];
      }
      best_number_of_hits = temp_number_of_hits;
      best_params = params;
      best_fit = params.chi2UT;
    }
  }

  return std::tuple<int, int, int, int, BestParams> {
    best_hits[0], best_hits[1], best_hits[2], best_hits[3], best_params};
}

//=========================================================================
// Apply the p-kick method to the triplet/quadruplet
//=========================================================================
__device__ BestParams pkick_fit(
  const int best_hits[UT::Constants::n_layers],
  UT::ConstHits& ut_hits,
  const MiniState& velo_state,
  const float* ut_dxDy,
  const float yyProto,
  const bool forward,
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope)
{
  BestParams best_params;

  // Helper stuff from velo state
  const float xMidField = velo_state.x + velo_state.tx * (UT::Constants::zKink - velo_state.z);
  const float a = sigma_velo_slope * (UT::Constants::zKink - velo_state.z);
  const float wb = 1.0f / (a * a);

  float mat[3] = {wb, wb * UT::Constants::zDiff, wb * UT::Constants::zDiff * UT::Constants::zDiff};
  float rhs[2] = {wb * xMidField, wb * xMidField * UT::Constants::zDiff};

  // add hits
  float last_z = -10000.f;

  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = best_hits[i];
    if (hit_index >= 0) {
      const float wi = ut_hits.weight(hit_index);
      const int plane_code = forward ? i : UT::Constants::n_layers - 1 - i;
      const float dxDy = ut_dxDy[plane_code];
      const float ci = ut_hits.cosT(hit_index, dxDy);
      last_z = ut_hits.zAtYEq0(hit_index);
      const float dz = 0.001f * (last_z - UT::Constants::zMidUT);

      // x_pos_layer
      const float yy = yyProto + (velo_state.ty * last_z);
      const float ui = ut_hits.xAt(hit_index, yy, dxDy);

      mat[0] += wi * ci;
      mat[1] += wi * ci * dz;
      mat[2] += wi * ci * dz * dz;

      rhs[0] += wi * ui;
      rhs[1] += wi * ui * dz;
    }
  }

  const float denom = 1.0f / (mat[0] * mat[2] - mat[1] * mat[1]);
  const float xSlopeUTFit = 0.001f * (mat[0] * rhs[1] - mat[1] * rhs[0]) * denom;
  const float xUTFit = (mat[2] * rhs[0] - mat[1] * rhs[1]) * denom;

  // new VELO slope x
  const float xb = xUTFit + xSlopeUTFit * (UT::Constants::zKink - UT::Constants::zMidUT);
  const float invKinkVeloDist = 1.f / (UT::Constants::zKink - velo_state.z);
  const float xSlopeVeloFit = (xb - velo_state.x) * invKinkVeloDist;
  const float chi2VeloSlope = (velo_state.tx - xSlopeVeloFit) * inv_sigma_velo_slope;

  // chi2 takes chi2 from velo fit + chi2 from UT fit
  float chi2UT = chi2VeloSlope * chi2VeloSlope;
  // add chi2
  int total_num_hits = 0;

  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = best_hits[i];
    if (hit_index >= 0) {
      const float zd = ut_hits.zAtYEq0(hit_index);
      const float xd = xUTFit + xSlopeUTFit * (zd - UT::Constants::zMidUT);
      // x_pos_layer
      const int plane_code = forward ? i : UT::Constants::n_layers - 1 - i;
      const float dxDy = ut_dxDy[plane_code];
      const float yy = yyProto + (velo_state.ty * zd);
      const float x = ut_hits.xAt(hit_index, yy, dxDy);

      const float du = xd - x;
      chi2UT += (du * du) * ut_hits.weight(hit_index);

      // count the number of processed htis
      total_num_hits++;
    }
  }

  chi2UT /= (total_num_hits - 1);

  // Save the best parameters if chi2 is good
  if (chi2UT < UT::Constants::maxPseudoChi2) {
    // calculate q/p
    const float sinInX = xSlopeVeloFit * sqrtf(1.0f + xSlopeVeloFit * xSlopeVeloFit);
    const float sinOutX = xSlopeUTFit * sqrtf(1.0f + xSlopeUTFit * xSlopeUTFit);

    best_params.qp = sinInX - sinOutX;
    best_params.chi2UT = chi2UT;
    best_params.n_hits = total_num_hits;
    best_params.x = xUTFit;
    best_params.z = last_z;
    best_params.tx = xSlopeUTFit;
  }

  return best_params;
}

//=========================================================================
// Give total number of hits for N windows in 2 layers
//=========================================================================
__device__ __inline__ int sum_layer_hits(const TrackCandidates& ranges, const int layer0, const int layer2)
{
  return sum_layer_hits(ranges, layer0) + sum_layer_hits(ranges, layer2);
}

//=========================================================================
// Give total number of hits for N windows in a layer
//=========================================================================
__device__ __inline__ int sum_layer_hits(const TrackCandidates& ranges, const int layer)
{
  return ranges.get_size(layer, 0) + ranges.get_size(layer, 1) + ranges.get_size(layer, 2) + ranges.get_size(layer, 3) +
         ranges.get_size(layer, 4);
}

//=========================================================================
// Given a panel,
// return the index in the correct place depending on the iteration.
// Put the index first in the central window, then left, then right
//=========================================================================
__device__ int
calc_index(const int index, const TrackCandidates& ranges, const int layer, const UT::HitOffsets& ut_hit_offsets)
{
  auto temp_index = index;
  for (int i = 0; i < CompassUT::num_sectors; ++i) {
    const auto ranges_size = ranges.get_size(layer, i);
    if (temp_index < ranges_size) {
      return temp_index + ut_hit_offsets.layer_offset(layer) + ranges.get_from(layer, i);
    }
    temp_index -= ranges_size;
  }

  return -1;
}

//=========================================================================
// Given 2 panels (forward backward case),
// return the index in the correct place depending on the iteration.
// Put the index first in the central window, then left, then right
//=========================================================================
__device__ int calc_index(
  const int index,
  const TrackCandidates& ranges,
  const int layer0,
  const int layer2,
  const UT::HitOffsets& ut_hit_offsets)
{
  auto temp_index = index;
  for (int i = 0; i < CompassUT::num_sectors; ++i) {
    const auto ranges_size = ranges.get_size(layer0, i);
    if (temp_index < ranges_size) {
      return temp_index + ut_hit_offsets.layer_offset(layer0) + ranges.get_from(layer0, i);
    }
    temp_index -= ranges_size;
  }

  return calc_index(temp_index, ranges, layer2, ut_hit_offsets);
}
