/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DownstreamV2DefineSciFiCandidates.cuh"
#include "UTEventModel.cuh"
#include "PrefixSum.cuh"
#include "DownstreamV2Extrapolation.cuh"
#include "BinarySearch.cuh"

INSTANTIATE_ALGORITHM(downstream_v2_define_scifi_candidates::downstream_v2_define_scifi_candidates_t);

void downstream_v2_define_scifi_candidates::downstream_v2_define_scifi_candidates_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Basics
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto number_of_seeds = first<host_total_number_of_scifi_tracks_t>(arguments);
  // Set sizes
  set_size<dev_downstream_seed_offsets_t>(arguments, number_of_events + 1);
  set_size<dev_downstream_candidate_offsets_t>(arguments, number_of_events + 1);
  set_size<dev_downstream_seeds_t>(arguments, number_of_seeds);
  set_size<host_total_number_of_downstream_seeds_t>(arguments, 1);
  set_size<host_total_number_of_downstream_candidates_t>(arguments, 1);
}

void downstream_v2_define_scifi_candidates::downstream_v2_define_scifi_candidates_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{

  const auto dev_ut_layer_geometry = constants.dev_ut_layer_geometry;

  Allen::memset_async<dev_downstream_seed_offsets_t>(arguments, 0, context);

  //
  // Find the hit ranges
  //
  global_function(downstream_v2_find_hit_ranges)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    dev_ut_layer_geometry,
    m_y_layer_tolerance,
    m_tx_tolerance,
    m_seed_max_ghost_prob,
    m_seed_ghost_killer.getDevicePointer());
  PrefixSum::prefix_sum<dev_downstream_seed_offsets_t, host_total_number_of_downstream_seeds_t>(
    *this, arguments, context);

  //
  // Compute number of pairs
  //
  resize<dev_downstream_seed_hits_offsets_t>(
    arguments, 4 * first<host_total_number_of_downstream_seeds_t>(arguments) + 1);
  global_function(downstream_v2_compute_number_of_pairs)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);
  PrefixSum::prefix_sum<dev_downstream_seed_hits_offsets_t, host_total_number_of_downstream_candidates_t>(
    *this, arguments, context);

  //
  // Fill pairs
  //
  resize<dev_downstream_candidates_t>(arguments, first<host_total_number_of_downstream_candidates_t>(arguments));

  global_function(downstream_v2_fill_pairs)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments);

  if (m_verbosity >= logger::debug) {
    const auto dev_downstream_candidate_offsets =
      make_host_buffer<dev_downstream_candidate_offsets_t>(arguments, context);
    printf("dev_downstream_candidate_offsets: ");
    unsigned p = 0;
    for (auto v : dev_downstream_candidate_offsets) {
      printf("%d, ", v - p);
      p = v;
    }
    printf("\n");
  }
}

__global__ void downstream_v2_define_scifi_candidates::downstream_v2_find_hit_ranges(
  Parameters parameters,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  float y_layer_tolerance,
  std::array<float, 2> tx_tolerance,
  float seed_max_ghost_prob,
  const GhostKiller::DeviceType* ghost_killer)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto number_of_events = parameters.dev_number_of_events[0];

  // Offsets
  const auto seed_offset = parameters.dev_offsets_seeding_tracks[event_number];
  const auto num_seed = parameters.dev_offsets_seeding_tracks[event_number + 1] - seed_offset;

  // Inputs
  const auto is_seed_used = parameters.dev_matched_is_scifi_track_used + seed_offset;
  const auto seeding_states = parameters.dev_seeding_states + seed_offset;
  const auto seeding_chi2s = parameters.dev_seeding_chi2Y + seed_offset;

  // UT input
  const auto total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  UT::HitOffsets ut_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, ut_offsets.event_offset()};

  // Output
  auto out_counter = parameters.dev_downstream_seed_offsets + event_number;
  auto out_seeds = parameters.dev_downstream_seeds + seed_offset;

  // Constants
  constexpr auto layer = 3;

  // Get layer level constants
  const auto layer_z = dev_ut_layer_geometry->mean_z[layer];
  const auto layer_z_error = dev_ut_layer_geometry->error_z[layer];
  const auto layer_dxdy = dev_ut_layer_geometry->mean_dxdy[layer];
  const auto layer_dxdy_error = dev_ut_layer_geometry->error_dxdy[layer];

  for (unsigned seed_idx = threadIdx.x; seed_idx < num_seed; seed_idx += blockDim.x) {
    // Skip the used seeds
    if (is_seed_used[seed_idx]) continue;

    // Preselection
    const MiniState scifi_state = seeding_states[seed_idx];
    if (seed_max_ghost_prob < 1.f) {
      const auto scifi_chi2 = seeding_chi2s[seed_idx];
      float inputs[10] = {fabsf(scifi_chi2),
                          fabsf(scifi_state.xAt(0)),
                          fabsf(scifi_state.yAt(0)),
                          fabsf(scifi_state.x()),
                          fabsf(scifi_state.y()),
                          fabsf(scifi_state.tx()),
                          fabsf(scifi_state.ty()),
                          hypotf(scifi_state.x(), scifi_state.y()),
                          fabsf(fabsf(atan2f(scifi_state.tx(), scifi_state.ty())) - 1.57f),
                          asinhf(1.f / hypotf(scifi_state.tx(), scifi_state.ty()))};
      const auto ghost_prob = ghost_killer->evaluate(inputs);
      if (!(ghost_prob < seed_max_ghost_prob)) continue;
    }

    // Expected position
    const auto layer_y = scifi_state.yAt(layer_z);
    const auto layer_y_error = scifi_state.ty() * layer_z_error;
    const auto yTolLayer = y_layer_tolerance;
    const auto zMagnet = Downstream::Extrapolation::get_zMagnet(scifi_state);
    const auto xMagnet = scifi_state.xAt(zMagnet);
    const auto tx_min = tx_tolerance[0] * xMagnet - tx_tolerance[1];
    const auto tx_max = tx_tolerance[0] * xMagnet + tx_tolerance[1];
    const auto layer_xmin = xMagnet + tx_max * (layer_z - zMagnet) - fabsf(layer_z_error * tx_max);
    const auto layer_xmax = xMagnet + tx_min * (layer_z - zMagnet) + fabsf(layer_z_error * tx_min);
    const auto layer_x0min =
      layer_xmin - layer_dxdy * layer_y - fabsf(layer_dxdy_error * layer_y) - fabsf(layer_dxdy * layer_y_error);
    const auto layer_x0max =
      layer_xmax - layer_dxdy * layer_y + fabsf(layer_dxdy_error * layer_y) + fabsf(layer_dxdy * layer_y_error);

    // Get fired sectors
    const auto fired_sectors = dev_ut_layer_geometry->find_sectors(layer, layer_y - yTolLayer, layer_y + yTolLayer);
    unsigned num_ranges = 0;
    Downstream::Structs::LayerHitRanges out_ranges = {
      short2 {-1, -1}, short2 {-1, -1}, short2 {-1, -1}, short2 {-1, -1}};
    for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
      const auto sector = fired_sectors[sector_idx];
      if (sector == -1) break;

      const int sector_start = ut_offsets.sector_group_offset(layer, sector) - ut_offsets.event_offset();
      const int sector_end = ut_offsets.sector_group_offset(layer, sector + 1) - ut_offsets.event_offset();

      // Find hit start
      int hit_start =
        binary_search_leftmost(ut_hits.xAtYEq0_p(0) + sector_start, sector_end - sector_start, layer_x0min) +
        sector_start;
      if (hit_start < sector_start || hit_start >= sector_end) continue;

      // Find hit end
      int hit_end =
        binary_search_leftmost(ut_hits.xAtYEq0_p(0) + hit_start, sector_end - hit_start, layer_x0max) + hit_start;
      if (hit_end <= hit_start || hit_end > sector_end) continue;

      out_ranges[num_ranges].x = hit_start;
      out_ranges[num_ranges].y = hit_end;
      num_ranges++;
    }
    if (num_ranges == 0) continue;

    // Add candidate
    const auto idx = atomicAdd(out_counter, 1u);
    Downstream::Structs::DownstreamSeed out;
    out.event_number = event_number;
    out.scifi_index = seed_idx;
    out.hits = out_ranges;
    out_seeds[idx] = out;
  }
}

__global__ void downstream_v2_define_scifi_candidates::downstream_v2_compute_number_of_pairs(Parameters parameters)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Offsets
  const auto input_offset = parameters.dev_offsets_seeding_tracks[event_number];
  const auto output_offset = parameters.dev_downstream_seed_offsets[event_number];
  const auto input_size = parameters.dev_downstream_seed_offsets[event_number + 1] - output_offset;

  // Input
  const auto input_seeds = parameters.dev_downstream_seeds + input_offset;

  // Output
  auto output_counters = parameters.dev_downstream_seed_hits_offsets + output_offset * 4;

  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    const auto ranges = input_seeds[i].hits;
    output_counters[i * 4 + 0] = (ranges[0].x == -1) ? 0 : ranges[0].y - ranges[0].x;
    output_counters[i * 4 + 1] = (ranges[1].x == -1) ? 0 : ranges[1].y - ranges[1].x;
    output_counters[i * 4 + 2] = (ranges[2].x == -1) ? 0 : ranges[2].y - ranges[2].x;
    output_counters[i * 4 + 3] = (ranges[3].x == -1) ? 0 : ranges[3].y - ranges[3].x;
  }
}

__global__ void downstream_v2_define_scifi_candidates::downstream_v2_fill_pairs(Parameters parameters)
{
  // Basics
  const auto event_number = blockIdx.x;
  const auto number_of_events = parameters.dev_number_of_events[0];

  // Offsets
  const auto input_offset = parameters.dev_offsets_seeding_tracks[event_number];
  const auto output_offset = parameters.dev_downstream_seed_offsets[event_number];
  const auto input_size = parameters.dev_downstream_seed_offsets[event_number + 1] - output_offset;

  // Input
  const auto input_seeds = parameters.dev_downstream_seeds + input_offset;

  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    const auto seed = input_seeds[i];
    const auto output_idx = output_offset + i;
    for (unsigned r = 0; r < 4; r++) {
      const auto range = seed.hits[r];
      if (range.x == -1) break;

      const auto output_hit_offset = parameters.dev_downstream_seed_hits_offsets[output_idx * 4 + r];
      const auto output_num_hits =
        parameters.dev_downstream_seed_hits_offsets[output_idx * 4 + r + 1] - output_hit_offset;
      for (unsigned h = 0; h < output_num_hits; h++) {
        parameters.dev_downstream_candidates[output_hit_offset + h] = make_ushort2(seed.scifi_index, range.x + h);
      }
    }
  }

  // Fill offsets
  if (threadIdx.x == 0) {
    parameters.dev_downstream_candidate_offsets[event_number] =
      parameters.dev_downstream_seed_hits_offsets[output_offset * 4];
    if (event_number + 1 == number_of_events) {
      parameters.dev_downstream_candidate_offsets[event_number + 1] =
        parameters.dev_downstream_seed_hits_offsets[(output_offset + input_size) * 4];
    }
  }
}