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

#include "CompassUTFindTracks.cuh"
#include "UTEventModel.cuh"
#include "VeloDefinitions.cuh"
#include "PrefixSum.cuh"
#include "BinarySearch.cuh"

INSTANTIATE_ALGORITHM(compass_ut_find_tracks::compass_ut_find_tracks_t)

void compass_ut_find_tracks::compass_ut_find_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto number_of_candidates = first<host_number_of_ut_track_candidate_t>(arguments);

  set_size<dev_ut_track_output_offset_t>(arguments, number_of_events + 1);
  // set_size<dev_ut_track_best_offset_t>(arguments, number_of_events + 1);
  set_size<dev_ut_track_output_tracks_t>(arguments, number_of_candidates);
  set_size<host_number_of_ut_track_output_tracks_t>(arguments, 1);
  // set_size<host_number_of_ut_track_best_tracks_t>(arguments, 1);
}

void compass_ut_find_tracks::compass_ut_find_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{

  Allen::memset_async<dev_ut_track_output_offset_t>(arguments, 0, context);

  // Count allocation size for candidates
  global_function(compass_ut_find_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, constants.dev_ut_magnet_tool, constants.dev_ut_layer_geometry, m_xtol_axial, m_xtol_stereo, m_ytol);
  PrefixSum::prefix_sum<dev_ut_track_output_offset_t, host_number_of_ut_track_output_tracks_t>(
    *this, arguments, context);
}

__global__ void compass_ut_find_tracks::compass_ut_find_tracks(
  Parameters parameters,
  UTMagnetTool*,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  float xtol_axial,
  float xtol_stereo,
  float ytol)
{
  // General
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, ut_hit_offsets.event_offset()};
  const auto backward_offset = ut_hit_offsets.layer_offset(3) - ut_hit_offsets.event_offset();

  // Velo Input
  const auto velo_states = parameters.dev_velo_states_view[event_number];

  // Input
  const auto input_offset = parameters.dev_ut_track_consolidate_candidate_offset[event_number];
  const auto input_size = parameters.dev_ut_track_consolidate_candidate_offset[event_number + 1] - input_offset;

  const uint8_t layers[2][4] = {{0, 2, 1, 3}, {3, 1, 2, 0}};

  // Shared counter
  __shared__ unsigned num_tracks;
  if (threadIdx.x == 0) {
    num_tracks = 0;
  }
  __syncthreads();

  for (unsigned input_idx = threadIdx.x; input_idx < input_size; input_idx += blockDim.x) {
    // Basics
    const auto candidate = parameters.dev_ut_track_consolidate_candidates[input_offset + input_idx];
    const auto case_idx = candidate.hit_idx >= backward_offset;
    // if (case_idx==1) continue;

    // Fetch Velo track
    const MiniState vp_state = velo_states.state(candidate.velo_index);

    // Correct trajectory
    const auto h0_z0 = ut_hits.zAtYEq0(candidate.hit_idx);
    const auto l0_y = vp_state.yAt(h0_z0);
    const auto h0_x = ut_hits.xAt(candidate.hit_idx, l0_y);
    float gamma = (h0_x - (vp_state.x() + vp_state.tx() * (h0_z0 - vp_state.z()))) /
                  ((h0_z0 - vp_state.z()) * (h0_z0 - vp_state.z()));

    // Find best hits
    int16_t best_hits[4] = {-1, -1, -1, -1};
    best_hits[layers[case_idx][0]] = candidate.hit_idx;
    unsigned num_hits = 1;
    float score = 0.f;
    for (unsigned l = 1; l < 4; l++) {
      CompassUT::Helper::BestSelector<uint16_t> best_hit;

      const auto layer = layers[case_idx][l];
      const auto is_axial = ((layer == 0) || (layer == 3));

      const auto xTol = is_axial ? xtol_axial : xtol_stereo;
      const auto yTol = ytol;

      const auto layer_z = dev_ut_layer_geometry->mean_z[layer];
      const auto error_z = dev_ut_layer_geometry->error_z[layer];
      const auto layer_dxdy = dev_ut_layer_geometry->mean_dxdy[layer];
      const auto error_dxdy = dev_ut_layer_geometry->error_dxdy[layer];

      const auto expected_layer_y = vp_state.yAt(layer_z);
      const auto expected_layer_x = vp_state.xAt(layer_z) + gamma * (layer_z - vp_state.z()) * (layer_z - vp_state.z());
      const auto expected_layer_x0 = expected_layer_x - layer_dxdy * expected_layer_y;
      const auto expected_layer_tx = vp_state.tx() + 2 * gamma * (layer_z - vp_state.z());
      const auto xTolLayer = xTol + fabsf(error_z * expected_layer_tx) + fabsf(error_dxdy * expected_layer_y);

      const auto yTolLayer = 10.f;
      const auto fired_sectors =
        dev_ut_layer_geometry->find_sectors(layer, expected_layer_y - yTolLayer, expected_layer_y + yTolLayer);

      for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
        const auto sector = fired_sectors[sector_idx];
        if (sector == -1) break;
        const auto sector_start = ut_hit_offsets.sector_group_offset(layer, sector) - ut_hit_offsets.event_offset();
        const auto sector_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - ut_hit_offsets.event_offset();

        const auto hit_start =
          binary_search_leftmost(
            ut_hits.xAtYEq0_p(0) + sector_start, sector_end - sector_start, expected_layer_x0 - xTolLayer) +
          sector_start;
        for (unsigned hit_idx = hit_start; hit_idx < sector_end; hit_idx++) {
          const auto xAtYEq0 = ut_hits.xAtYEq0(hit_idx);
          if (xAtYEq0 > (expected_layer_x0 + xTolLayer)) break;

          const auto zAtYEq0 = ut_hits.zAtYEq0(hit_idx);
          const auto expected_y = vp_state.yAt(zAtYEq0);
          if (ut_hits.isNotYCompatible(hit_idx, expected_y, yTol)) continue;

          const auto expected_x = vp_state.xAt(zAtYEq0) + gamma * (zAtYEq0 - vp_state.z()) * (zAtYEq0 - vp_state.z());
          const auto dist_x = expected_x - ut_hits.xAt(hit_idx, expected_y);
          if (fabsf(dist_x) > xTol) continue;

          // best_hit.add(dist_x, hit_idx);
          best_hit.add(dist_x, hit_idx);
        }
      }

      if (!best_hit.exist()) continue;

      // Add results
      score += best_hit.value() * best_hit.value();
      best_hits[layer] = best_hit.best();
      num_hits++;

      // Correct trajectory
      float best_zAtYEq0 = ut_hits.zAtYEq0(best_hit.best());
      float best_y = vp_state.yAt(best_zAtYEq0);
      float best_x = ut_hits.xAt(best_hit.best(), best_y);
      const auto new_gamma = (best_x - (vp_state.x() + vp_state.tx() * (best_zAtYEq0 - vp_state.z()))) /
                             ((best_zAtYEq0 - vp_state.z()) * (best_zAtYEq0 - vp_state.z()));
      gamma = (gamma + new_gamma) / 2;
      // gamma = new_gamma;
    }

    // We need at least 3 hits
    if (num_hits < 3) continue;

    // Make 3 hits always worse than 4 hits
    if (num_hits == 3) {
      score *= 1000;
    }

    // Add candidates
    const auto idx = atomicAdd(&num_tracks, 1u);
    CompassUT::Structs::VeloUTTrack out;
    out.score = score;
    out.velo_index = candidate.velo_index;
    out.ut_hits[0] = best_hits[0];
    out.ut_hits[1] = best_hits[1];
    out.ut_hits[2] = best_hits[2];
    out.ut_hits[3] = best_hits[3];
    parameters.dev_ut_track_output_tracks[input_offset + idx] = out;
  }
  __syncthreads();
  if (threadIdx.x == 0) {
    parameters.dev_ut_track_output_offset[event_number] = num_tracks;
  }
}