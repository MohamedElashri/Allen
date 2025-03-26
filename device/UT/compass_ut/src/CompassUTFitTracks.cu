/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "CompassUTFitTracks.cuh"
#include "UTEventModel.cuh"
#include "VeloDefinitions.cuh"
#include "PrefixSum.cuh"
#include "LinearAlgebra.cuh"

INSTANTIATE_ALGORITHM(compass_ut_fit_tracks::compass_ut_fit_tracks_t)

namespace {
  __host__ __device__ float get_bdl(const float* bdl_table, const MiniState& vp_state)
  {
    //== Handle states. copy Velo one, add UT.
    const float zOrigin = (fabsf(vp_state.ty()) > 0.001f) ? vp_state.z() - vp_state.y() / vp_state.ty() :
                                                            vp_state.z() - vp_state.x() / vp_state.tx();

    // -- These are calculations, copied and simplified from PrTableForFunction
    const float var[3] = {vp_state.ty(), zOrigin, vp_state.z()};

    const int index1 = max(0, min(30, int((var[0] + 0.3f) / 0.6f * 30)));
    const int index2 = max(0, min(10, int((var[1] + 250) / 500 * 10)));
    const int index3 = max(0, min(10, int(var[2] / 800 * 10)));

    // inline function for index
    auto master_index = [](const int index1, const int index2, const int index3) -> int {
      return (index3 * 11 + index2) * 31 + index1;
    };

    assert(master_index(index1, index2, index3) < UTMagnetTool::N_bdl_vals);
    float bdl = bdl_table[master_index(index1, index2, index3)];

    const int num_idx = 3;
    const float bdls[num_idx] = {bdl_table[master_index(index1 + 1, index2, index3)],
                                 bdl_table[master_index(index1, index2 + 1, index3)],
                                 bdl_table[master_index(index1, index2, index3 + 1)]};
    const float deltaBdl[num_idx] = {0.02f, 50.0f, 80.0f};
    const float boundaries[num_idx] = {
      -0.3f + float(index1) * deltaBdl[0], -250.0f + float(index2) * deltaBdl[1], 0.0f + float(index3) * deltaBdl[2]};

    // This is an interpolation, to get a bit more precision
    float addBdlVal = 0.0f;
    const float minValsBdl[num_idx] = {-0.3f, -250.0f, 0.0f};
    const float maxValsBdl[num_idx] = {0.3f, 250.0f, 800.0f};
    for (int i = 0; i < num_idx; ++i) {
      if (var[i] < minValsBdl[i] || var[i] > maxValsBdl[i]) continue;
      const float dTab_dVar = (bdls[i] - bdl) / deltaBdl[i];
      const float dVar = (var[i] - boundaries[i]);
      addBdlVal += dTab_dVar * dVar;
    }
    bdl += addBdlVal;

    return bdl;
  }

  struct fitted_state_t {
    float qop;
    float x;
    float z;
    float tx;
  };

  __device__ __host__ fitted_state_t fit_state(
    const float* bdl_table,
    UT::ConstHits& ut_hits,
    const MiniState& velo_state,
    const int16_t* best_hits,
    const float sigma_velo_slope)
  {
    //
    // Get bdl
    //
    const auto bdl = get_bdl(bdl_table, velo_state);
    const float qpxz2p = -1.f / bdl * 3.3356f / Gaudi::Units::GeV;

    //
    // First we perform a pkick fit
    //
    float best_qp = 0.f;
    float best_x = -10000;
    float best_tx = -10000;
    float best_z = -10000;
    {
      // Constants (extracted from old CompassUT code)
      const float inv_sigma_velo_slope = 1.f / sigma_velo_slope;

      // Helper stuff from velo state
      const float xMidField = velo_state.x() + velo_state.tx() * (UT::Constants::zKink - velo_state.z());
      const float a = sigma_velo_slope * (UT::Constants::zKink - velo_state.z());
      const float wb = 1.0f / (a * a);
      const float yyProto = velo_state.yAt(0);

      float mat[3] = {wb, wb * UT::Constants::zDiff, wb * UT::Constants::zDiff * UT::Constants::zDiff};
      float rhs[2] = {wb * xMidField, wb * xMidField * UT::Constants::zDiff};

      // add hits
      float last_z = -10000.f;

      for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
        const auto hit_index = best_hits[i];
        if (hit_index >= 0) {
          const float wi = ut_hits.weight(hit_index);
          const float ci = ut_hits.cosT(hit_index);
          last_z = ut_hits.zAtYEq0(hit_index);
          const float dz = 0.001f * (last_z - UT::Constants::zMidUT);

          // x_pos_layer
          const float yy = yyProto + (velo_state.ty() * last_z);
          const float ui = ut_hits.xAt(hit_index, yy);

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
      const float invKinkVeloDist = 1.f / (UT::Constants::zKink - velo_state.z());
      const float xSlopeVeloFit = (xb - velo_state.x()) * invKinkVeloDist;
      const float chi2VeloSlope = (velo_state.tx() - xSlopeVeloFit) * inv_sigma_velo_slope;

      // chi2 takes chi2 from velo fit + chi2 from UT fit
      float chi2UT = chi2VeloSlope * chi2VeloSlope;
      // add chi2
      int total_num_hits = 0;

      for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
        const auto hit_index = best_hits[i];
        if (hit_index >= 0) {
          const float zd = ut_hits.zAtYEq0(hit_index);
          const float xd = xUTFit + xSlopeUTFit * (zd - UT::Constants::zMidUT);
          // x_pos_layer
          const float yy = yyProto + (velo_state.ty() * zd);
          const float x = ut_hits.xAt(hit_index, yy);

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

        best_qp = sinInX - sinOutX;
        best_x = xUTFit;
        best_z = last_z;
        best_tx = xSlopeUTFit;
      }
    }

    //
    // Then we perform a fast fit
    //
    // float final_x = best_x;
    // float final_tx = best_tx;
    // float final_y = velo_state.y() + velo_state.ty() * (UT::Constants::zMidUT - velo_state.z());
    // float final_chi2 = best_chi2;
    float qp;
    {
      const float ty = velo_state.ty();
      const float zKink = UT::Constants::magFieldParams_0 - ty * ty * UT::Constants::magFieldParams_1 -
                          ty * ty * ty * ty * UT::Constants::magFieldParams_2;
      const float xMidField = velo_state.x() + velo_state.tx() * (zKink - velo_state.z());

      const float zDiff = 0.001f * (zKink - UT::Constants::zMidUT);

      // -- This is to avoid division by zero...
      const float pHelper = max(float(fabsf(best_qp * qpxz2p)), 1e-9f);
      const float invP = pHelper * sqrtf(1.0f + ty * ty);

      // these resolution are semi-empirical, could be tuned and might not be correct for low momentum.
      // this is the resolution due to multiple scattering between Velo and UT
      const float error1 = 0.14f + 10000.0f * invP;
      // this is the resolution due to the finite Velo resolution
      const float error2 = 0.12f + 3000.0f * invP;
      const float error = error1 * error1 + error2 * error2;
      const float weight = 1.0f / error;

      float mat[6] = {weight, weight * zDiff, weight * zDiff * zDiff, 0.0f, 0.0f, 0.0f};
      float rhs[3] = {weight * xMidField, weight * xMidField * zDiff, 0.0f};

      const float yyProto = velo_state.y() - velo_state.ty() * velo_state.z();

      for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
        if (best_hits[i] != -1) {
          const auto hit = best_hits[i];

          const float yy = yyProto + (velo_state.ty() * ut_hits.zAtYEq0(hit));
          const float ui = ut_hits.xAt(hit, yy);
          const float dz = 0.001f * (ut_hits.zAtYEq0(hit) - UT::Constants::zMidUT);
          const float w = ut_hits.weight(hit);
          const float t = ut_hits.sinT(hit);

          mat[0] += w;
          mat[1] += w * dz;
          mat[2] += w * dz * dz;
          mat[3] += w * t;
          mat[4] += w * dz * t;
          mat[5] += w * t * t;

          rhs[0] += w * ui;
          rhs[1] += w * ui * dz;
          rhs[2] += w * ui * t;
        }
      }

      const float a11 = mat[2] * mat[5] - mat[4] * mat[4];
      const float a12 = mat[4] * mat[3] - mat[1] * mat[5];
      const float a13 = mat[1] * mat[4] - mat[2] * mat[3];
      const float a22 = mat[0] * mat[5] - mat[3] * mat[3];
      const float a23 = mat[1] * mat[3] - mat[0] * mat[4];
      // const float a33 = mat[0] * mat[2] - mat[1] * mat[1];

      const float det_inv = 1.f / (mat[0] * a11 + mat[1] * a12 + mat[3] * a13);

      const float sol0 = det_inv * (a11 * rhs[0] + a12 * rhs[1] + a13 * rhs[2]);
      const float sol1 = det_inv * (a12 * rhs[0] + a22 * rhs[1] + a23 * rhs[2]);
      // const float sol2 = det_inv * (a13 * rhs[0] + a23 * rhs[1] + a33 * rhs[2]);

      const float xUTFit = sol0;
      const float xSlopeUTFit = 0.001f * sol1;
      // const float offsetY = sol2;

      // const float distX = (xMidField - xUTFit - xSlopeUTFit * (zKink - UT::Constants::zMidUT));
      // // -- This takes into account that the distance between a point and track is smaller than the distance on the
      // // x-axis
      // const float distCorrectionX2 = 1.0f / (1 + xSlopeUTFit * xSlopeUTFit);
      // // float chi2 = weight * (distX * distX * distCorrectionX2 + offsetY * offsetY / (1.0f + ty * ty));

      // for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
      //   if (best_hits[i] != -1) {
      //     const auto hit = best_hits[i];

      //     const float w = ut_hits.weight(hit);
      //     const float dz = ut_hits.zAtYEq0(hit) - UT::Constants::zMidUT;
      //     const float yy = yyProto + (velo_state.ty() * ut_hits.zAtYEq0(hit));
      //     const float x = ut_hits.xAt(hit, yy);
      //     const float dist = (x - xUTFit - xSlopeUTFit * dz - offsetY * ut_hits.sinT(hit));
      //     chi2 += w * dist * dist * distCorrectionX2;
      //   }
      // }

      // new VELO slope x
      const float xb =
        0.5f * ((xUTFit + xSlopeUTFit * (zKink - UT::Constants::zMidUT)) + xMidField); // the 0.5 is empirical
      const float xSlopeVeloFit = (xb - velo_state.x()) / (zKink - velo_state.z());

      // final_x = xUTFit;
      // final_tx = xSlopeUTFit;
      // final_y = velo_state.y() + velo_state.ty() * (UT::Constants::zMidUT - velo_state.z()) + offsetY;
      // final_chi2 = chi2;

      // calculate q/p
      const float sinInX = xSlopeVeloFit * sqrtf(1.0f + xSlopeVeloFit * xSlopeVeloFit + ty * ty);
      const float sinOutX = xSlopeUTFit * sqrtf(1.0f + xSlopeUTFit * xSlopeUTFit + ty * ty);
      qp = sinInX - sinOutX;
    }

    //
    // Compute results
    //
    const float qop = (fabsf(bdl) < 1.e-8f) ? 0.0f : qp * qpxz2p;

    fitted_state_t fit_result;
    fit_result.qop = qop;
    fit_result.x = best_x;
    fit_result.z = best_z;
    fit_result.tx = best_tx;

    return fit_result;
  }

  struct free_state_t {
    float x;
    float tx;
    float dy;
  };

  // Fit UT hits without VELO constraints
  __device__ bool
  free_fit(UT::ConstHits& ut_hits, const MiniState& vp_state, const int16_t* found_hits, free_state_t& out)
  {
    using UT::Constants::n_layers;
    using UT::Constants::zMidUT;
    float mat[6] = {0, 0, 0, 0, 0, 0};
    float rhs[3] = {0, 0, 0};

    for (unsigned i = 0; i < n_layers; i++) {
      const auto hit = found_hits[i];
      if (hit == -1) continue;
      const auto w = ut_hits.weight(hit);
      const auto zAtYEq0 = ut_hits.zAtYEq0(hit);
      const auto dz = zAtYEq0 - zMidUT;
      const auto t = -ut_hits.dxDy(hit);
      const auto hit_y = vp_state.yAt(zAtYEq0);
      const auto hit_x = ut_hits.xAt(hit, hit_y);
      mat[0] += w;
      mat[1] += w * dz;
      mat[2] += w * dz * dz;
      mat[3] += w * t;
      mat[4] += w * dz * t;
      mat[5] += w * t * t;
      rhs[0] += w * hit_x;
      rhs[1] += w * hit_x * dz;
      rhs[2] += w * hit_x * t;
    }

    float sol[3];
    bool sucess = LinAlg::SolveCholesky<3>(mat, rhs, sol);
    if (!sucess) return false;

    out.x = sol[0];
    out.tx = sol[1];
    out.dy = sol[2];
    return true;
  }
} // namespace

void compass_ut_fit_tracks::compass_ut_fit_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto number_of_candidates = first<host_number_of_ut_track_selected_tracks_t>(arguments);

  set_size<host_number_of_ut_track_hits_t>(arguments, 1);
  set_size<dev_ut_track_hits_offset_t>(arguments, number_of_events + 1);
  set_size<dev_ut_track_hits_t>(arguments, number_of_candidates);
}

void compass_ut_fit_tracks::compass_ut_fit_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ut_track_hits_offset_t>(arguments, 0, context);

  // Fit
  global_function(compass_ut_fit_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    constants.dev_ut_magnet_tool,
    m_dev_velout_ghostkiller_3hits.getDevicePointer(),
    m_dev_velout_ghostkiller_4hits.getDevicePointer(),
    m_sigma_velo_slope,
    m_min_momentum_final,
    m_min_pt_final,
    m_min_ghost_prob_3_hit,
    m_min_ghost_prob_4_hit);
  PrefixSum::prefix_sum<dev_ut_track_hits_offset_t, host_number_of_ut_track_hits_t>(*this, arguments, context);
}

__global__ void compass_ut_fit_tracks::compass_ut_fit_tracks(
  Parameters parameters,
  UTMagnetTool* dev_ut_magnet_tool,
  const VeloUTGhostKiller::DeviceType* dev_velout_ghostkiller_3hits,
  const VeloUTGhostKiller::DeviceType* dev_velout_ghostkiller_4hits,
  float sigma_velo_slope,
  float min_momentum_final,
  float min_pt_final,
  float min_ghost_prob_3_hit,
  float min_ghost_prob_4_hit)
{
  using UT::Constants::zMidUT;

  // General
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, ut_hit_offsets.event_offset()};

  // Velo Input
  const auto velo_states = parameters.dev_velo_states_view[event_number];

  // Extrapolation
  const float* bdl_table = dev_ut_magnet_tool->bdlTable;

  // Input
  const auto input_offset = parameters.dev_ut_track_output_offset[event_number];
  const auto output_offset = parameters.dev_ut_track_selected_offset[event_number];
  const auto input_size = parameters.dev_ut_track_selected_offset[event_number + 1] - output_offset;

  // Output counter
  auto output_counter = parameters.dev_ut_track_hits_offset + event_number;

  for (unsigned input_idx = threadIdx.x; input_idx < input_size; input_idx += blockDim.x) {
    // Basics
    const auto candidate = parameters.dev_ut_track_selected_tracks[input_offset + input_idx];

    // Fetch Velo track
    const MiniState vp_state = velo_states.state(candidate.velo_index);

    // Fit state
    const auto ut_state = fit_state(bdl_table, ut_hits, vp_state, candidate.ut_hits, sigma_velo_slope);

    // Don't make tracks that have grossly too low momentum, beware of the momentum resolution!
    const float p = 1.3f * fabsf(1.f / ut_state.qop);
    const float pt = p * sqrtf(vp_state.tx() * vp_state.tx() + vp_state.ty() * vp_state.ty());
    if ((p < min_momentum_final) || (pt < min_pt_final)) continue;

    // Compute number of hits
    const auto nHits = (candidate.ut_hits[0] >= 0) + (candidate.ut_hits[1] >= 0) + (candidate.ut_hits[2] >= 0) +
                       (candidate.ut_hits[3] >= 0);

    // Ghost killing
    const auto model = (nHits == 3) ? dev_velout_ghostkiller_3hits : dev_velout_ghostkiller_4hits;
    const auto threshold = (nHits == 3) ? min_ghost_prob_3_hit : min_ghost_prob_4_hit;
    float inputs[4];
    {
      free_state_t free_state;
      const auto successful = free_fit(ut_hits, vp_state, candidate.ut_hits, free_state);
      if (!successful) continue;

      const auto zKink =
        UT::Constants::magFieldParams_0 - vp_state.ty() * vp_state.ty() * UT::Constants::magFieldParams_1 -
        vp_state.ty() * vp_state.ty() * vp_state.ty() * vp_state.ty() * UT::Constants::magFieldParams_2;
      const auto xV = vp_state.xAt(zKink);
      const auto xU = free_state.x + free_state.tx * (zKink - zMidUT);
      const auto distX = xU - xV;
      const auto dSlopeX = free_state.tx - vp_state.tx();
      const auto vp_eta = asinhf(1.f / hypotf(vp_state.tx(), vp_state.ty()));
      inputs[0] = fabsf(distX);
      inputs[1] = fabsf(free_state.dy);
      inputs[2] = fabsf(dSlopeX);
      inputs[3] = vp_eta;
    }
    const auto ghost_prob = model->evaluate(inputs);
    if (ghost_prob > threshold) continue;

    // Add track
    const auto idx = atomicAdd(output_counter, 1u);
    UT::TrackHits track;
    track.velo_track_index = static_cast<uint16_t>(candidate.velo_index);
    track.qop = ut_state.qop;
    track.x = ut_state.x;
    track.z = ut_state.z;
    track.tx = ut_state.tx;
    track.hits_num = nHits;
    track.hits[0] = candidate.ut_hits[0];
    track.hits[1] = candidate.ut_hits[1];
    track.hits[2] = candidate.ut_hits[2];
    track.hits[3] = candidate.ut_hits[3];
    parameters.dev_ut_track_hits[output_offset + idx] = track;
  }
}
