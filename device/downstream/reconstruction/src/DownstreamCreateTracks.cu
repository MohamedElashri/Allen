/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DownstreamCreateTracks.cuh"
#include <PrefixSum.cuh>

/**
 * @file DownstreamCreateTracks.cu
 * @brief This file implements the second part of downstream track reconstruction, which creates the downstream tracks
 * from the previous algorithm. It includes the following steps:
 * - Loading the SciFi seeds from the previous algorithm.
 * - Finding the best downstream track candidate for each SciFi seed.
 * - Performing clone killing to remove clone tracks.
 * - Running a ghost killer to reduce the ghost rate.
 * - Outputting downstream tracks.
 */

INSTANTIATE_ALGORITHM(downstream_create_tracks::downstream_create_tracks_t);

void downstream_create_tracks::downstream_create_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // outputs
  set_size<dev_downstream_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * UT::Constants::max_num_tracks);
  set_size<dev_offsets_downstream_tracks_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_downstream_tracks_t>(arguments, 1);
}

void downstream_create_tracks::downstream_create_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_offsets_downstream_tracks_t>(arguments, 0, context);

  const auto dev_magnet_polarity = constants.dev_magnet_polarity.data();

  // Create tracks
  global_function(downstream_create_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    dev_magnet_polarity,
    m_ghost_killer_threshold,
    dev_downstream_ghostkiller.getDevicePointer(),
    m_n_overflow_downstream_create_tracks.data(context));

  PrefixSum::prefix_sum<dev_offsets_downstream_tracks_t, host_number_of_downstream_tracks_t>(*this, arguments, context);
}

namespace {
  struct fitresult_t {
    float a, b;
    float chi2;
  };

  __device__ inline fitresult_t
  fit_3points(const float x0, const float z0, const float x1, const float z1, const float x2, const float z2)
  {
    float ATA[3] = {0, 0, 0};
    float ATY[2] = {0, 0};

    if (!std::isnan(x0)) {
      ATA[0] += 1;
      ATA[1] += z0;
      ATA[2] += z0 * z0;
      ATY[0] += x0;
      ATY[1] += x0 * z0;
    }
    if (!std::isnan(x1)) {
      ATA[0] += 1;
      ATA[1] += z1;
      ATA[2] += z1 * z1;
      ATY[0] += x1;
      ATY[1] += x1 * z1;
    }
    if (!std::isnan(x2)) {
      ATA[0] += 1;
      ATA[1] += z2;
      ATA[2] += z2 * z2;
      ATY[0] += x2;
      ATY[1] += x2 * z2;
    }

    // Determinant
    const auto det = ATA[0] * ATA[2] - ATA[1] * ATA[1];

    // Solve ax, bx, cx
    fitresult_t fr;
    fr.a = ATY[0] * (ATA[2]) + ATY[1] * (-ATA[1]);
    fr.b = ATY[0] * (-ATA[1]) + ATY[1] * (ATA[0]);
    fr.a /= det;
    fr.b /= det;

    // Compute chi2
    fr.chi2 = ((fr.a + fr.b * z0) - x0) * ((fr.a + fr.b * z0) - x0) +
              ((fr.a + fr.b * z1) - x1) * ((fr.a + fr.b * z1) - x1) +
              ((fr.a + fr.b * z2) - x2) * ((fr.a + fr.b * z2) - x2);

    return fr;
  }

  __device__ inline fitresult_t fit_3points_plus_slope(
    const float y0,
    const float z0,
    const float y1,
    const float z1,
    const float y2,
    const float z2,
    const float ty3)
  {
    float ATA[3] = {0, 0, 1.f};
    float ATY[2] = {0, ty3};

    if (!std::isnan(y0)) {
      ATA[0] += 1.f;
      ATA[1] += z0;
      ATA[2] += z0 * z0;
      ATY[0] += y0;
      ATY[1] += y0 * z0;
    }
    if (!std::isnan(y1)) {
      ATA[0] += 1.f;
      ATA[1] += z1;
      ATA[2] += z1 * z1;
      ATY[0] += y1;
      ATY[1] += y1 * z1;
    }
    if (!std::isnan(y2)) {
      ATA[0] += 1.f;
      ATA[1] += z2;
      ATA[2] += z2 * z2;
      ATY[0] += y2;
      ATY[1] += y2 * z2;
    }

    // Determinant
    const auto det = ATA[0] * ATA[2] - ATA[1] * ATA[1];

    // Solve ax, bx, cx
    fitresult_t fr;
    fr.a = ATY[0] * (ATA[2]) + ATY[1] * (-ATA[1]);
    fr.b = ATY[0] * (-ATA[1]) + ATY[1] * (ATA[0]);
    fr.a /= det;
    fr.b /= det;

    // Compute chi2
    fr.chi2 = ((fr.a + fr.b * z0) - y0) * ((fr.a + fr.b * z0) - y0) +
              ((fr.a + fr.b * z1) - y1) * ((fr.a + fr.b * z1) - y1) +
              ((fr.a + fr.b * z2) - y2) * ((fr.a + fr.b * z2) - y2) + (fr.b - ty3) * (fr.b - ty3);

    fr.chi2 /= 2; // 4 - 2

    return fr;
  }
} // namespace

__global__ void downstream_create_tracks::downstream_create_tracks(
  downstream_create_tracks::Parameters parameters,
  const float* dev_magnet_polarity,
  const float ghost_killer_threshold,
  const DownstreamGhostKiller::DeviceType* dev_downstream_ghostkiller,
  [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType dev_n_overflow_downstream_create_tracks)
{
  ///////////////////////////////////////////////////////
  //
  // B a s i c   s e t u p
  //
  ///////////////////////////////////////////////////////

  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Fetch found hits
  const auto findhits_outputs =
    parameters.dev_findhits_output + event_number * Downstream::DownstreamParameters::MaxNumCandidates;
  const auto findhits_selected_scifi_tracks = parameters.dev_findhits_selected_scifi_tracks +
                                              event_number * Downstream::DownstreamParameters::MaxNumDownstreamSciFi;

  const auto findhits_num_selected_scifi = parameters.dev_findhits_num_selected_scifi[event_number];
  const auto findhits_output_selected_scifi_offsets =
    parameters.dev_findhits_output_selected_scifi_offsets +
    event_number * (Downstream::DownstreamParameters::MaxNumDownstreamSciFi + 1);

  // Load UT information
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Ouptut
  auto downstream_tracks = parameters.dev_downstream_tracks + event_number * UT::Constants::max_num_tracks;
  auto num_downstream_tracks = parameters.dev_offsets_downstream_tracks + event_number;

  ///////////////////////////////////////////////////////
  //
  // S h a r e d    m e m o r y
  //
  ///////////////////////////////////////////////////////
  __shared__ unsigned shared_num_downstream_tracks;
  __shared__ bool clone_label[UT::Constants::max_num_tracks];
  __shared__ float scaling_factor;

  // Reset values
  if (threadIdx.x == 0) {
    scaling_factor = 1.f;
    shared_num_downstream_tracks = 0;
  };
  for (unsigned i = threadIdx.x; i < UT::Constants::max_num_tracks; i += blockDim.x) {
    clone_label[i] = false;
  }
  __syncthreads();
  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t s
  //
  ///////////////////////////////////////////////////////

  // Try up to MaxNumIteration times.
  // If a candidate overflows, try using a tighter threshold.
  // If it still exceeds after MaxNumIteration times, simply reset the event to 0
  for (unsigned iteration = 0; iteration < MaxNumIteration; iteration++) {
    //
    // Find best candidates
    //
    for (unsigned scifi_idx = threadIdx.x; scifi_idx < findhits_num_selected_scifi; scifi_idx += blockDim.x) {
      const auto candidate_idx_begin = findhits_output_selected_scifi_offsets[scifi_idx];
      const auto candidate_idx_end = findhits_output_selected_scifi_offsets[scifi_idx + 1];

      using Downstream::DownstreamHelpers::BestCandidateManager;
      BestCandidateManager<unsigned> track_candidate_manager;
      for (unsigned short candidate_idx = candidate_idx_begin; candidate_idx < candidate_idx_end; candidate_idx++) {
        track_candidate_manager.add(candidate_idx, findhits_outputs[candidate_idx].score);
      }

      // Skip this seed if none candidate are valid
      if (!track_candidate_manager.exist()) continue;

      // Best candidate!
      const auto best_candidate = track_candidate_manager.best();
      const auto findhits_output = findhits_outputs[best_candidate];

      //
      // Fitting the state
      //
      using SciFi::Constants::ZEndT;
      using UT::Constants::zMidUT;
      constexpr auto INVALID_HIT = Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
      constexpr auto NaN = std::numeric_limits<float>::quiet_NaN();

      // Fetch hits
      const auto hit_0 = findhits_output.hits[0];
      const auto hit_1 = findhits_output.hits[1];
      const auto hit_2 = findhits_output.hits[2];
      const auto hit_3 = findhits_output.hits[3];

      const auto num_hits =
        (hit_0 != INVALID_HIT) + (hit_1 != INVALID_HIT) + (hit_2 != INVALID_HIT) + (hit_3 != INVALID_HIT);

      const auto dz0 = (hit_0 != INVALID_HIT) ? (ut_hits.zAtYEq0(hit_0) - zMidUT) : NaN;
      const auto dz1 = (hit_1 != INVALID_HIT) ? (ut_hits.zAtYEq0(hit_1) - zMidUT) : NaN;
      const auto dz2 = (hit_2 != INVALID_HIT) ? (ut_hits.zAtYEq0(hit_2) - zMidUT) : NaN;
      const auto dz3 = (hit_3 != INVALID_HIT) ? (ut_hits.zAtYEq0(hit_3) - zMidUT) : NaN;

      const auto xAtYEq0_0 = (hit_0 != INVALID_HIT) ? (ut_hits.xAtYEq0(hit_0)) : NaN;
      const auto xAtYEq0_1 = (hit_1 != INVALID_HIT) ? (ut_hits.xAtYEq0(hit_1)) : NaN;
      const auto xAtYEq0_2 = (hit_2 != INVALID_HIT) ? (ut_hits.xAtYEq0(hit_2)) : NaN;
      const auto xAtYEq0_3 = (hit_3 != INVALID_HIT) ? (ut_hits.xAtYEq0(hit_3)) : NaN;

      const auto dxdy_1 = (hit_1 != INVALID_HIT) ? (ut_hits.dxDy(hit_1)) : NaN;
      const auto dxdy_2 = (hit_2 != INVALID_HIT) ? (ut_hits.dxDy(hit_2)) : NaN;

      // Fetch SciFi info
      const auto findhits_selected_scifi_track = findhits_selected_scifi_tracks[scifi_idx];
      const auto ft_idx = findhits_selected_scifi_track.scifi_idx;
      const auto ft_tx = findhits_selected_scifi_track.tx;
      const auto ft_ty = findhits_selected_scifi_track.ty;
      const auto ft_y = findhits_selected_scifi_track.y;
      const auto ft_chi2 = findhits_selected_scifi_track.chi2;
      const auto xMag = findhits_selected_scifi_track.xMagnet;
      const auto zMag = findhits_selected_scifi_track.zMagnet;

      // Fit XZ
      const auto fr_xz = fit_3points(xAtYEq0_0, dz0, xAtYEq0_3, dz3, xMag, zMag - zMidUT);
      const auto ut_x = fr_xz.a;
      const auto ut_tx = fr_xz.b;
      const auto ut_chi2x = fr_xz.chi2;

      // Fit YZ
      const auto x1 = ut_x + ut_tx * dz1;
      const auto x2 = ut_x + ut_tx * dz2;
      const auto fr_yz = fit_3points_plus_slope(
        (x1 - xAtYEq0_1) / dxdy_1, dz1, (x2 - xAtYEq0_2) / dxdy_2, dz2, ft_y, ZEndT - zMidUT, ft_ty);
      const auto ut_y = fr_yz.a;
      const auto ut_ty = fr_yz.b;
      const auto ut_chi2y = fr_yz.chi2;

      // Distances
      auto dist0 = (xAtYEq0_0) - (ut_x + ut_tx * dz0);
      auto dist1 = (xAtYEq0_1 + dxdy_1 * (ut_y + ut_ty * dz1)) - (ut_x + ut_tx * dz1);
      auto dist2 = (xAtYEq0_2 + dxdy_2 * (ut_y + ut_ty * dz2)) - (ut_x + ut_tx * dz2);
      auto dist3 = (xAtYEq0_3) - (ut_x + ut_tx * dz3);

      if (std::isnan(dist0)) {
        dist0 = dist3;
      }
      if (std::isnan(dist1)) {
        dist1 = dist2;
      }
      if (std::isnan(dist2)) {
        dist2 = dist1;
      }
      if (std::isnan(dist3)) {
        dist3 = dist0;
      }

      // Ghost killing
      const auto eta = asinhf(1.f / hypotf(ut_tx, ut_ty));
      float ghost_killer_input[DownstreamGhostKiller::DeviceType::nInput] = {dist1 + dist2,
                                                                             dist0,
                                                                             dist3,
                                                                             ft_chi2,
                                                                             eta,
                                                                             ut_x,
                                                                             ut_y,
                                                                             ut_tx,
                                                                             ut_ty,
                                                                             ft_tx - ut_tx,
                                                                             ft_y - (ut_y + ut_ty * (ZEndT - zMidUT))};
      const auto ghost_killer_score = dev_downstream_ghostkiller->evaluate(ghost_killer_input);

      if (ghost_killer_score > ghost_killer_threshold * scaling_factor) continue;

      const auto idx = atomicAdd(&shared_num_downstream_tracks, 1u);

      if (idx >= UT::Constants::max_num_tracks) break;

      auto& output_track = downstream_tracks[idx];

      output_track.x = ut_x;
      output_track.y = ut_y;
      output_track.tx = ut_tx;
      output_track.ty = ut_ty;
      output_track.qop = Downstream::DownstreamExtrapolation::Physics::qop(ut_tx, ut_ty, ft_tx, *dev_magnet_polarity);
      output_track.chi2 = ut_chi2x + ut_chi2y;
      output_track.ghost_prob = ghost_killer_score;
      output_track.scifi_idx = ft_idx;
      output_track.num_hits = num_hits;
      output_track.hits[0] = hit_0;
      output_track.hits[1] = hit_1;
      output_track.hits[2] = hit_2;
      output_track.hits[3] = hit_3;
    }
    __syncthreads();
    const auto overflow = shared_num_downstream_tracks > UT::Constants::max_num_tracks;
    __syncthreads();
    if (overflow) {
      if (threadIdx.x == 0) {
        scaling_factor *= 0.5f;
        shared_num_downstream_tracks = 0;
        dev_n_overflow_downstream_create_tracks.increment();
      }
      __syncthreads();
      continue;
    }
    break;
  }

  //
  // Clone killing
  //
  for (unsigned track_1_idx = threadIdx.x; track_1_idx < shared_num_downstream_tracks; track_1_idx += blockDim.x) {
    if (clone_label[track_1_idx] == true) continue;

    auto& track_1 = downstream_tracks[track_1_idx];

    for (unsigned track_2_idx = track_1_idx + 1; track_2_idx < shared_num_downstream_tracks; track_2_idx += 1) {
      auto& track_2 = downstream_tracks[track_2_idx];

      int shared_hits = 0;
      if (track_1.hits[0] == track_2.hits[0]) {
        shared_hits += 1;
      };
      if (track_1.hits[1] == track_2.hits[1]) {
        shared_hits += 1;
      };
      if (track_1.hits[2] == track_2.hits[2]) {
        shared_hits += 1;
      };
      if (track_1.hits[3] == track_2.hits[3]) {
        shared_hits += 1;
      };

      if (shared_hits >= 2) {
        if (track_1.ghost_prob <= track_2.ghost_prob) {
          // if (track_1.chi2 <= track_2.chi2) {
          clone_label[track_2_idx] = true;
        }
        else {
          clone_label[track_1_idx] = true;
        };
      };
    };
  };
  __syncthreads();

  // Collapse
  for (unsigned i = threadIdx.x; i < shared_num_downstream_tracks; i += blockDim.x) {
    auto track = downstream_tracks[i];
    __syncthreads();
    if (clone_label[i] != true) {
      unsigned idx = atomicAdd(num_downstream_tracks, 1u);
      downstream_tracks[idx] = track;
    }
    __syncthreads();
  };
}
