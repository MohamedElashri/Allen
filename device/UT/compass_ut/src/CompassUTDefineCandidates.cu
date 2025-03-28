
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "CompassUTDefineCandidates.cuh"
#include "UTEventModel.cuh"
#include "BinarySearch.cuh"
#include "PrefixSum.cuh"
#include "BinarySearch.cuh"
#include <tuple>

INSTANTIATE_ALGORITHM(compass_ut_define_candidates::compass_ut_define_candidates_t)

void compass_ut_define_candidates::compass_ut_define_candidates_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto number_of_selected_velo = first<host_ut_number_of_selected_velo_tracks_t>(arguments);

  // Preselection
  set_size<dev_ut_track_candidate_hit_ranges_t>(arguments, number_of_selected_velo * 2);
  set_size<dev_ut_track_candidate_tols_t>(arguments, number_of_selected_velo * 2);
  set_size<dev_ut_track_all_candidate_input_offset_t>(arguments, number_of_selected_velo * 2 + 1);
  set_size<host_number_of_ut_track_candidate_t>(arguments, 1);

  // Fill candidates
  set_size<dev_ut_track_all_candidate_output_offset_t>(arguments, number_of_selected_velo * 2 + 1);
}

void compass_ut_define_candidates::compass_ut_define_candidates_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto number_of_events = first<host_number_of_events_t>(arguments);

  Allen::memset_async<dev_ut_track_all_candidate_input_offset_t>(arguments, 0, context);
  Allen::memset_async<dev_ut_track_all_candidate_output_offset_t>(arguments, 0, context);

  //
  // Preselect hits and count size
  //
  global_function(compass_ut_hit_preselection)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    constants.dev_ut_magnet_tool,
    constants.dev_ut_layer_geometry,
    m_min_momentum,
    m_min_pt,
    m_y_tol,
    m_y_tol_slope);
  PrefixSum::prefix_sum<dev_ut_track_all_candidate_input_offset_t, host_number_of_ut_track_candidate_t>(
    *this, arguments, context);

  //
  // Fill all candidates within tolerance window
  //

  // Set size
  resize<dev_ut_track_all_candidates_t>(arguments, first<host_number_of_ut_track_candidate_t>(arguments));
  // Run it
  global_function(compass_ut_fill_cadidates)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_y_tol, m_y_tol_slope);
  // Update offsets
  PrefixSum::prefix_sum<dev_ut_track_all_candidate_output_offset_t, host_number_of_ut_track_candidate_t>(
    *this, arguments, context);

  //
  // Consolidate
  //
  resize<dev_ut_track_consolidate_candidate_offset_t>(arguments, number_of_events + 1);
  resize<dev_ut_track_consolidate_candidates_t>(arguments, first<host_number_of_ut_track_candidate_t>(arguments));
  global_function(compass_ut_consolidate_candidates)(dim3(number_of_events), m_block_dim, context)(arguments);
}

__global__ void compass_ut_define_candidates::compass_ut_hit_preselection(
  Parameters parameters,
  UTMagnetTool* dev_ut_magnet_tool,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  float min_momentum,
  float min_pt,
  float y_tol,
  float y_tol_slope)
{
  // General
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, ut_hit_offsets.event_offset()};

  // Velo Input
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  // const auto velo_offset = parameters.dev_offsets_all_velo_tracks[event_number];
  const auto output_offset = parameters.dev_ut_selected_velo_tracks_offsets[event_number];
  const auto number_of_selected_velo_tracks =
    parameters.dev_ut_selected_velo_tracks_offsets[event_number + 1] - output_offset;
  const auto selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + output_offset;

  // Outputs
  auto output_ranges = parameters.dev_ut_track_candidate_hit_ranges + output_offset * 2;
  auto output_xtols = parameters.dev_ut_track_candidate_tols + output_offset * 2;
  auto output_counter = parameters.dev_ut_track_all_candidate_input_offset + output_offset * 2;

  // Extrapolation
  const float* fudge_factors = dev_ut_magnet_tool->dxLayTable;

  // Parallelization
  const auto n_case = 2;
  const auto number_of_threads = number_of_selected_velo_tracks * n_case;

  for (unsigned thread_idx = threadIdx.x; thread_idx < number_of_threads; thread_idx += blockDim.x) {
    // Fetch parallelization info
    const auto case_idx = thread_idx % n_case;
    const auto selected_idx = thread_idx / n_case;
    const auto layer = (case_idx == 0) ? 0 : 3;

    // Fetch velo track
    const auto velo_track_idx = selected_velo_tracks[selected_idx];
    const auto velo_state = velo_states.state(velo_track_idx);

    // Layer info
    const auto layer_z = dev_ut_layer_geometry->mean_z[layer];
    const auto layer_z_error = dev_ut_layer_geometry->error_z[layer];
    const auto layer_dxdy = dev_ut_layer_geometry->mean_dxdy[layer];
    const auto layer_dxdy_error = dev_ut_layer_geometry->error_dxdy[layer];

    // Extrapolation
    const auto expected_layer_x = velo_state.x() + velo_state.tx() * (layer_z - velo_state.z());
    const auto expected_layer_y = velo_state.y() + velo_state.ty() * (layer_z - velo_state.z());
    const auto expected_layer_xAtYEq0 = expected_layer_x - layer_dxdy * expected_layer_y;

    //
    // Define tolerance window with fudge_factors
    //

    // TODO: Understand and fix this logic (especially ty_index)
    // -- This is hardcoded, so faster
    // -- If you ever change the Table in the magnet tool, this will be wrong
    // -- Need to understand where 100 and 0.5 comes from when converting ty->ty_index
    const int ty_index = static_cast<int>(fabsf(velo_state.ty()) * 100 + 0.5f);
    const int fudge_index =
      min(UT::Constants::n_layers * ty_index + layer, UTMagnetTool::N_dxLay_vals - UT::Constants::n_layers + layer);
    const float invNormFact = 1.0f / fudge_factors[fudge_index];

    // -- this 500 seems a little odd...
    // to do: change back!
    const float invTheta =
      min(500.0f, 1.0f / sqrtf(velo_state.tx() * velo_state.tx() + velo_state.ty() * velo_state.ty()));
    const float minMom = max(min_pt * invTheta, min_momentum);
    const float xTol = fabsf(1.0f / (UT::Constants::distToMomentum * minMom));
    const float xTolNormFact = xTol * invNormFact;
    const float yTol = y_tol + y_tol_slope * fabsf(xTolNormFact);
    const float xTolLayer = xTol + fabsf(layer_z_error * velo_state.tx()) + fabsf(layer_dxdy_error * expected_layer_y);
    const float yTolLayer = max(yTol + fabsf(layer_z_error * velo_state.ty()), 10.f);

    //
    // Find hit ranges
    //
    unsigned num_ranges = 0;
    CompassUT::Structs::LayerHitRanges hit_ranges = {
      short2 {-1, -1}, short2 {-1, -1}, short2 {-1, -1}, short2 {-1, -1}};
    unsigned num_candidates = 0;
    const auto fired_sectors =
      dev_ut_layer_geometry->find_sectors(layer, expected_layer_y - yTolLayer, expected_layer_y + yTolLayer);
    for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
      const auto sector = fired_sectors[sector_idx];
      if (sector == -1) break;

      const int sector_start = ut_hit_offsets.sector_group_offset(layer, sector) - ut_hit_offsets.event_offset();
      const int sector_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - ut_hit_offsets.event_offset();

      // Find hit start
      int hit_start =
        binary_search_leftmost(
          ut_hits.xAtYEq0_p(0) + sector_start, sector_end - sector_start, expected_layer_xAtYEq0 - xTolLayer) +
        sector_start;
      // if (hit_start < sector_start) continue;

      // Find hit end
      int hit_end;
      for (hit_end = hit_start; hit_end < sector_end; hit_end++) {
        const auto xAtYEq0 = ut_hits.xAtYEq0(hit_end);
        if (xAtYEq0 > (expected_layer_xAtYEq0 + xTolLayer)) {
          break;
        }
      }
      if (hit_end <= hit_start) continue;

      // Fill result
      hit_ranges[num_ranges] = short2 {static_cast<short>(hit_start), static_cast<short>(hit_end)};
      num_ranges++;
      num_candidates += hit_end - hit_start;
    }
    if (num_ranges == 0) continue;

    // Add candidate
    output_ranges[thread_idx] = hit_ranges;
    output_xtols[thread_idx] = float2 {fabsf(xTolNormFact), fabsf(invNormFact)};
    output_counter[thread_idx] = num_candidates;
  }
}

__global__ void
compass_ut_define_candidates::compass_ut_fill_cadidates(Parameters parameters, float y_tol, float y_tol_slope)
{
  // General
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, ut_hit_offsets.event_offset()};

  // Velo Input
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  // const auto velo_offset = parameters.dev_offsets_all_velo_tracks[event_number];
  const auto velo_output_offset = parameters.dev_ut_selected_velo_tracks_offsets[event_number];
  const auto number_of_selected_velo_tracks =
    parameters.dev_ut_selected_velo_tracks_offsets[event_number + 1] - velo_output_offset;
  const auto selected_velo_tracks = parameters.dev_ut_selected_velo_tracks + velo_output_offset;

  // Preselection result
  const auto tols = parameters.dev_ut_track_candidate_tols + velo_output_offset * 2;
  const auto ranges = parameters.dev_ut_track_candidate_hit_ranges + velo_output_offset * 2;
  const auto candidate_offsets = parameters.dev_ut_track_all_candidate_input_offset + velo_output_offset * 2;

  // Output
  auto output_counter = parameters.dev_ut_track_all_candidate_output_offset + velo_output_offset * 2;

  // Parallelization
  const auto n_case = 2;
  const auto number_of_threads = number_of_selected_velo_tracks * n_case;
  for (unsigned thread_idx = threadIdx.x; thread_idx < number_of_threads; thread_idx += blockDim.x) {
    // Output offset
    const auto candidate_offset = candidate_offsets[thread_idx];
    const auto number_of_candidate = candidate_offsets[thread_idx + 1] - candidate_offset;
    if (number_of_candidate == 0) {
      continue;
    }

    // Fetch parallelization info
    const auto selected_idx = thread_idx / n_case;

    // Fetch velo track
    const auto velo_track_idx = selected_velo_tracks[selected_idx];
    MiniState velo_state = velo_states.state(velo_track_idx);

    // Fetch input
    const auto hit_ranges = ranges[thread_idx];
    const auto tol = tols[thread_idx];

    //
    // Find good hits
    //
    unsigned num_good_hits = 0;
    for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
      const auto hit_start = hit_ranges[sector_idx].x;
      const auto hit_end = hit_ranges[sector_idx].y;

      if (hit_start == -1 || hit_end == -1) break;

      for (int h = hit_start; h < hit_end; h++) {
        const auto zAtYEq0 = ut_hits.zAtYEq0(h);
        const auto expected_y = velo_state.yAt(zAtYEq0);
        const auto expected_x = velo_state.xAt(zAtYEq0);
        const auto dist_x = fabsf(ut_hits.xAt(h, expected_y) - expected_x);
        if (dist_x > tol.x) continue;

        const auto yTol = y_tol + y_tol_slope * tol.y * dist_x;
        if (ut_hits.isNotYCompatible(h, expected_y, yTol)) continue;

        parameters.dev_ut_track_all_candidates[candidate_offset + num_good_hits] =
          CompassUT::Structs::Candidate {static_cast<uint16_t>(velo_track_idx), static_cast<uint16_t>(h)};
        num_good_hits++;
      }
      output_counter[thread_idx] = num_good_hits;
    }
  }
}

__global__ void compass_ut_define_candidates::compass_ut_consolidate_candidates(Parameters parameters)
{
  // General
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Velo Input
  const auto velo_offset = parameters.dev_ut_selected_velo_tracks_offsets[event_number];
  const auto number_of_velo_tracks = parameters.dev_ut_selected_velo_tracks_offsets[event_number + 1] - velo_offset;

  // Offsets
  const auto input_offsets = parameters.dev_ut_track_all_candidate_input_offset + velo_offset * 2;
  const auto output_offsets = parameters.dev_ut_track_all_candidate_output_offset + velo_offset * 2;

  // Parallelization
  const auto n_case = 2;
  const auto number_of_threads = number_of_velo_tracks * n_case;

  for (unsigned thread_idx = threadIdx.x; thread_idx < number_of_threads; thread_idx += blockDim.x) {
    // Fetch ranges
    const auto input_offset = input_offsets[thread_idx];
    const auto output_offset = output_offsets[thread_idx];
    const auto input_size = output_offsets[thread_idx + 1] - output_offset;
    if (input_size == 0) continue;

    // Fill consolidated results
    for (unsigned i = 0; i < input_size; i++) {
      parameters.dev_ut_track_consolidate_candidates[output_offset + i] =
        parameters.dev_ut_track_all_candidates[input_offset + i];
    }
  }

  if (blockIdx.x == 0) {
    for (unsigned event_number = threadIdx.x; event_number <= number_of_events; event_number += blockDim.x) {
      const auto velo_offset = parameters.dev_ut_selected_velo_tracks_offsets[event_number];
      parameters.dev_ut_track_consolidate_candidate_offset[event_number] =
        parameters.dev_ut_track_all_candidate_output_offset[velo_offset * 2];
    }
  }
}