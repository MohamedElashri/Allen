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

// This
#include "DownstreamV2FindTracks.cuh"

// Primitives
#include "PrefixSum.cuh"

// Downstream
#include "DownstreamV2Extrapolation.cuh"
#include "DownstreamV2Helper.cuh"
#include "DownstreamV2Constants.cuh"

// UT
#include "UTEventModel.cuh"

INSTANTIATE_ALGORITHM(downstream_v2_find_tracks::downstream_v2_find_tracks_t);

void downstream_v2_find_tracks::downstream_v2_find_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Basics
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto number_of_candidates = first<host_total_number_of_downstream_candidates_t>(arguments);

  // Set sizes
  set_size<dev_downstream_compact_track_offsets_t>(arguments, number_of_events + 1);
  set_size<dev_downstream_compact_track_offsets_layer_0_t>(arguments, number_of_events + 1);
  set_size<dev_downstream_compact_track_offsets_layer_1_t>(arguments, number_of_events + 1);
  set_size<dev_downstream_compact_tracks_buffer_t>(arguments, number_of_candidates);
  set_size<host_number_of_downstream_compact_tracks_t>(arguments, 1);
}

void downstream_v2_find_tracks::downstream_v2_find_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Basics
  const auto dev_ut_layer_geometry = constants.dev_ut_layer_geometry;

  Allen::memset_async<dev_downstream_compact_track_offsets_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_compact_track_offsets_layer_0_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_compact_track_offsets_layer_1_t>(arguments, 0, context);

  //
  // Fill layer 0
  //
  global_function(downstream_v2_find_hits_in_layer_0)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    dev_ut_layer_geometry,
    m_fiducial_cut,
    m_x0_max,
    m_x_axial_tolerance,
    m_y_tolerance,
    m_y_layer_tolerance);
  PrefixSum::prefix_sum<dev_downstream_compact_track_offsets_layer_0_t, host_number_of_downstream_compact_tracks_t>(
    *this, arguments, context);

  //
  // Fill layer 1
  //
  resize<dev_downstream_compact_tracks_t>(arguments, first<host_number_of_downstream_compact_tracks_t>(arguments));
  global_function(downstream_v2_find_hits_in_layer_1)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    dev_ut_layer_geometry,
    m_fiducial_cut,
    m_x0_max,
    m_dtx_range,
    m_ut_r_min,
    m_eta_range,
    m_x_stereo_tolerance,
    m_y_tolerance,
    m_y_layer_tolerance);
  PrefixSum::prefix_sum<dev_downstream_compact_track_offsets_layer_1_t, host_number_of_downstream_compact_tracks_t>(
    *this, arguments, context);

  //
  // Fill layer 2
  //

  resize<dev_downstream_compact_tracks_buffer_t>(
    arguments, first<host_number_of_downstream_compact_tracks_t>(arguments));
  global_function(downstream_v2_find_hits_in_layer_2)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    dev_ut_layer_geometry,
    m_fiducial_cut,
    m_stereo_bias_threshold,
    m_x_stereo_tolerance,
    m_y_tolerance,
    m_y_layer_tolerance);
  PrefixSum::prefix_sum<dev_downstream_compact_track_offsets_t, host_number_of_downstream_compact_tracks_t>(
    *this, arguments, context);

  //
  // Consolidate output
  //
  resize<dev_downstream_compact_tracks_t>(arguments, first<host_number_of_downstream_compact_tracks_t>(arguments));
  global_function(downstream_v2_consolidate_find_hits)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);
}

__global__ void downstream_v2_find_tracks::downstream_v2_find_hits_in_layer_0(
  Parameters parameters,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  bool fiducial_cut,
  float x0_max,
  float x_axial_tolerance,
  float y_tolerance,
  float y_layer_tolerance)
{
  constexpr unsigned layer = 0;

  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const auto total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, ut_hit_offsets.event_offset()};

  // Offsets
  const auto input_offset = parameters.dev_downstream_candidate_offsets[event_number];
  const auto input_size = parameters.dev_downstream_candidate_offsets[event_number + 1] - input_offset;

  // Input
  const auto input_candidates = parameters.dev_downstream_candidates + input_offset;

  // SciFi
  const auto scifi_offset = parameters.dev_offsets_seeding_tracks[event_number];
  const auto scifi_states = parameters.dev_seeding_states + scifi_offset;

  // Output
  auto output_counter = parameters.dev_downstream_compact_track_offsets_layer_0 + event_number;
  auto output_tracks = parameters.dev_downstream_compact_tracks_buffer + input_offset;

  //
  // Hit cache
  //

  // Allocate the memory
  __shared__ typename UTHitsCache::ElementType shared_memory_hit_caching[UTHitsCache::NumElements];

  // Hit Cache
  UTHitsCache hit_cache {shared_memory_hit_caching};

  //
  // Start (Layer 0)
  //
  hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_ut_layer_geometry, layer);
  __syncthreads();

  for (unsigned candidate_idx = threadIdx.x; candidate_idx < input_size; candidate_idx += blockDim.x) {
    const auto candidate = input_candidates[candidate_idx];

    // Alias
    const auto& scifi_idx = candidate.x;
    const auto& h3_idx = candidate.y;

    // SciFi
    const auto scifi_state = scifi_states[scifi_idx];
    const auto zMagnet = Downstream::Extrapolation::get_zMagnet(scifi_state);
    const auto xMagnet = scifi_state.xAt(zMagnet);

    const auto l3_xAtYEq0 = ut_hits.xAtYEq0(h3_idx);
    const auto l3_zAtYEq0 = ut_hits.zAtYEq0(h3_idx);

    const float tx = (xMagnet - l3_xAtYEq0) / (zMagnet - l3_zAtYEq0);
    const float x0 = l3_xAtYEq0 - l3_zAtYEq0 * tx;

    if (fiducial_cut) {
      if (fabsf(x0) > x0_max || fabsf(tx) > 1.f) continue;
    }

    Downstream::Helpers::BestSelector<uint16_t> best_hit;

    // Compute the search range
    const auto layer_z = dev_ut_layer_geometry->mean_z[layer];
    const auto layer_zerr = dev_ut_layer_geometry->error_z[layer];
    const auto layer_x = x0 + layer_z * tx;
    const auto yTol = y_tolerance;
    const auto xTol = x_axial_tolerance;
    const auto xTol_layer = xTol + fabsf(layer_zerr * tx);
    const auto yTol_layer = y_layer_tolerance;
    const auto layer_y = scifi_state.yAt(layer_z);
    const auto fired_sectors = dev_ut_layer_geometry->find_sectors(layer, layer_y - yTol_layer, layer_y + yTol_layer);

    for (unsigned s = 0; s < 4; s++) {
      const auto sector = fired_sectors[s];
      if (sector == -1) break;
      const auto hit_start = ut_hit_offsets.sector_group_offset(layer, sector) - ut_hit_offsets.layer_offset(layer);
      const auto hit_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - ut_hit_offsets.layer_offset(layer);
      hit_cache.for_each_in_x_tol(
        hit_start,
        hit_end,
        layer_x - xTol_layer,
        layer_x + xTol_layer,
        [&](ushort idx, const UTHitsCache::MiniHit& hit) {
          const float expected_hit_y = scifi_state.yAt(hit.zAtYEq0());
          if (hit.isNotYCompatible(expected_hit_y, yTol)) {
            return;
          }
          const float xdist = (x0 + tx * hit.zAtYEq0()) - hit.xAtYEq0();
          if (fabsf(xdist) < xTol) {
            best_hit.add(xdist, idx);
          }
        });
    }

    if (!best_hit.exist()) continue;

    // Add candidates
    const auto idx = atomicAdd(output_counter, 1u);
    Downstream::Structs::CompactTrack out;
    out.scifi_idx = scifi_offset + scifi_idx;
    out.ut_hits[0] = best_hit.best() + hit_cache.HitOffset();
    out.ut_hits[1] = -1;
    out.ut_hits[2] = -1;
    out.ut_hits[3] = h3_idx;
    output_tracks[idx] = out;
  }
}

__global__ void downstream_v2_find_tracks::downstream_v2_find_hits_in_layer_1(
  Parameters parameters,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  bool fiducial_cut,
  float x0_max,
  std::array<float, 2> dtx_range,
  float ut_r_min,
  std::array<float, 2> eta_range,
  float x_stereo_tolerance,
  float y_tolerance,
  float y_layer_tolerance)
{
  constexpr unsigned layer = 1;

  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const auto total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, ut_hit_offsets.event_offset()};

  // Offsets
  const auto input_offset = parameters.dev_downstream_candidate_offsets[event_number];
  const auto output_offset = parameters.dev_downstream_compact_track_offsets_layer_0[event_number];
  const auto input_size = parameters.dev_downstream_compact_track_offsets_layer_0[event_number + 1] - output_offset;

  // Input
  const auto input_candidates = parameters.dev_downstream_compact_tracks_buffer + input_offset;

  // Outputs
  auto output_counter = parameters.dev_downstream_compact_track_offsets_layer_1 + event_number;
  auto output_tracks = parameters.dev_downstream_compact_tracks + output_offset;

  //
  // Hit cache
  //

  // Allocate the memory
  __shared__ typename UTHitsCache::ElementType shared_memory_hit_caching[UTHitsCache::NumElements];

  // Hit Cache
  UTHitsCache hit_cache {shared_memory_hit_caching};

  //
  // Start
  //
  hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_ut_layer_geometry, layer);
  __syncthreads();

  for (unsigned candidate_idx = threadIdx.x; candidate_idx < input_size; candidate_idx += blockDim.x) {
    auto candidate = input_candidates[candidate_idx];

    // Alias
    const auto& scifi_idx = candidate.scifi_idx;
    const auto& h0_idx = candidate.ut_hits[0];
    const auto& h3_idx = candidate.ut_hits[3];

    // SciFi
    const auto scifi_state = parameters.dev_seeding_states[scifi_idx];

    const auto h0_xAtYEq0 = ut_hits.xAtYEq0(h0_idx);
    const auto h0_zAtYEq0 = ut_hits.zAtYEq0(h0_idx);
    const auto h3_xAtYEq0 = ut_hits.xAtYEq0(h3_idx);
    const auto h3_zAtYEq0 = ut_hits.zAtYEq0(h3_idx);
    const auto tx = (h3_xAtYEq0 - h0_xAtYEq0) / (h3_zAtYEq0 - h0_zAtYEq0);
    const auto x0 = h0_xAtYEq0 - tx * h0_zAtYEq0;

    // Fiducial cuts
    if (fiducial_cut) {
      if (fabsf(x0) > x0_max || fabsf(tx) > 1.f) continue;
      const auto dtx = fabsf(tx - scifi_state.tx());
      if (!(dtx > dtx_range[0] && dtx < dtx_range[1])) continue;
      const auto r = hypotf(x0 + tx * UT::Constants::zMidUT, scifi_state.yAt(UT::Constants::zMidUT));
      if (!(r > ut_r_min)) continue;
      const auto eta = asinhf(1.f / (hypotf(tx, scifi_state.ty())));
      if (!(eta > eta_range[0] && eta < eta_range[1])) continue;
    }

    Downstream::Helpers::Best2Selector<uint16_t> best_hit;

    // Compute the search range
    const auto layer_dxdy = dev_ut_layer_geometry->mean_dxdy[layer];
    const auto layer_z = dev_ut_layer_geometry->mean_z[layer];
    const auto layer_zerr = dev_ut_layer_geometry->error_z[layer];
    const auto layer_y = scifi_state.yAt(layer_z);
    const auto layer_x = x0 + layer_z * tx - (layer_dxdy * layer_y);
    const auto layer_yerr = scifi_state.ty() * layer_zerr;
    const auto yTol = y_tolerance;
    const auto xTol = x_stereo_tolerance;
    const auto xTol_layer = xTol + fabsf(layer_zerr * tx) + fabsf(layer_yerr * layer_dxdy);
    const auto yTol_layer = y_layer_tolerance;
    const auto fired_sectors = dev_ut_layer_geometry->find_sectors(layer, layer_y - yTol_layer, layer_y + yTol_layer);

    for (unsigned s = 0; s < 4; s++) {
      const auto sector = fired_sectors[s];
      if (sector == -1) break;
      const auto hit_start = ut_hit_offsets.sector_group_offset(layer, sector) - ut_hit_offsets.layer_offset(layer);
      const auto hit_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - ut_hit_offsets.layer_offset(layer);
      hit_cache.for_each_in_x_tol(
        hit_start,
        hit_end,
        layer_x - xTol_layer,
        layer_x + xTol_layer,
        [&](ushort idx, const UTHitsCache::MiniHit& hit) {
          const float expected_hit_y = scifi_state.yAt(hit.zAtYEq0());
          if (hit.isNotYCompatible(expected_hit_y, yTol)) {
            return;
          }
          const float xdist = (x0 + tx * hit.zAtYEq0()) - hit.xAt(expected_hit_y);
          if (fabsf(xdist) < xTol) {
            best_hit.add(xdist, idx);
          }
        });
    }

    if (!best_hit.exist()) continue;

    // Add candidates
    const auto idx = atomicAdd(output_counter, 1u);
    candidate.ut_hits[1] = best_hit.get(0) + hit_cache.HitOffset();
    if (best_hit.valid(1)) {
      candidate.ut_hits[2] = best_hit.get(1) + hit_cache.HitOffset();
    }
    output_tracks[idx] = candidate;
  }
}

__global__ void downstream_v2_find_tracks::downstream_v2_find_hits_in_layer_2(
  Parameters parameters,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  bool fiducial_cut,
  std::array<float, 3> stereo_bias_threshold,
  float x_stereo_tolerance,
  float y_tolerance,
  float y_layer_tolerance)
{
  constexpr unsigned layer = 2;

  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto number_of_events = parameters.dev_number_of_events[0];

  // UT hits
  const auto total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, ut_hit_offsets.event_offset()};

  // Offsets
  const auto input_offset = parameters.dev_downstream_compact_track_offsets_layer_0[event_number];
  const auto output_offset = parameters.dev_downstream_compact_track_offsets_layer_1[event_number];
  const auto input_size = parameters.dev_downstream_compact_track_offsets_layer_1[event_number + 1] - output_offset;

  // Input
  const auto input_candidates = parameters.dev_downstream_compact_tracks + input_offset;

  // Outputs
  auto output_counter = parameters.dev_downstream_compact_track_offsets + event_number;
  auto output_tracks = parameters.dev_downstream_compact_tracks_buffer + output_offset;

  //
  // Hit cache
  //

  // Allocate the memory
  __shared__ typename UTHitsCache::ElementType shared_memory_hit_caching[UTHitsCache::NumElements];

  // Hit Cache
  UTHitsCache hit_cache {shared_memory_hit_caching};

  //
  // Start (Layer 0)
  //
  hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_ut_layer_geometry, layer);
  __syncthreads();

  for (unsigned candidate_idx = threadIdx.x; candidate_idx < input_size; candidate_idx += blockDim.x) {
    auto candidate = input_candidates[candidate_idx];

    // Alias
    const auto& scifi_idx = candidate.scifi_idx;
    const auto& h0_idx = candidate.ut_hits[0];
    const auto& h3_idx = candidate.ut_hits[3];
    const auto& h10_idx = candidate.ut_hits[1];
    const auto& h11_idx = candidate.ut_hits[2];

    // Get state
    const auto h0_xAtYEq0 = ut_hits.xAtYEq0(h0_idx);
    const auto h0_zAtYEq0 = ut_hits.zAtYEq0(h0_idx);
    const auto h3_xAtYEq0 = ut_hits.xAtYEq0(h3_idx);
    const auto h3_zAtYEq0 = ut_hits.zAtYEq0(h3_idx);
    const auto tx = (h3_xAtYEq0 - h0_xAtYEq0) / (h3_zAtYEq0 - h0_zAtYEq0);
    const auto x0 = h0_xAtYEq0 - tx * h0_zAtYEq0;

    // SciFi
    const auto scifi_state = parameters.dev_seeding_states[scifi_idx];

    // Get candidates
    const auto dist_10 =
      (x0 + tx * ut_hits.zAtYEq0(h10_idx)) - (ut_hits.xAt(h10_idx, scifi_state.yAt(ut_hits.zAtYEq0(h10_idx))));
    const auto dist_11 = (h11_idx != -1) ? (x0 + tx * ut_hits.zAtYEq0(h11_idx)) -
                                             (ut_hits.xAt(h11_idx, scifi_state.yAt(ut_hits.zAtYEq0(h11_idx)))) :
                                           std::numeric_limits<float>::infinity();

    Downstream::Helpers::BestSelector<short2> best_combination;

    // Compute the search range
    const auto layer_dxdy = dev_ut_layer_geometry->mean_dxdy[layer];
    const auto layer_z = dev_ut_layer_geometry->mean_z[layer];
    const auto layer_zerr = dev_ut_layer_geometry->error_z[layer];
    const auto layer_y = scifi_state.yAt(layer_z);
    const auto layer_x = x0 + layer_z * tx - (layer_dxdy * layer_y);
    const auto layer_yerr = scifi_state.ty() * layer_zerr;
    const auto yTol = y_tolerance;
    const auto xTol = x_stereo_tolerance;
    const auto xTol_layer = xTol + fabsf(layer_zerr * tx) + fabsf(layer_yerr * layer_dxdy);
    const auto yTol_layer = y_layer_tolerance;
    const auto fired_sectors = dev_ut_layer_geometry->find_sectors(layer, layer_y - yTol_layer, layer_y + yTol_layer);

    for (unsigned s = 0; s < 4; s++) {
      const auto sector = fired_sectors[s];
      if (sector == -1) break;
      const auto hit_start = ut_hit_offsets.sector_group_offset(layer, sector) - ut_hit_offsets.layer_offset(layer);
      const auto hit_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - ut_hit_offsets.layer_offset(layer);
      hit_cache.for_each_in_x_tol(
        hit_start,
        hit_end,
        layer_x - xTol_layer,
        layer_x + xTol_layer,
        [&](ushort idx, const UTHitsCache::MiniHit& hit) {
          const float expected_hit_y = scifi_state.yAt(hit.zAtYEq0());
          if (hit.isNotYCompatible(expected_hit_y, yTol)) {
            return;
          }
          const float xdist = (x0 + tx * hit.zAtYEq0()) - hit.xAt(expected_hit_y);
          if (fabsf(xdist) < xTol) {
            best_combination.add(xdist + dist_10, make_short2(h10_idx, idx));
            if (h11_idx != -1) {
              best_combination.add(xdist + dist_11, make_short2(h11_idx, idx));
            }
          }
        });
    }

    if (!best_combination.exist()) continue;

    // Fiducial cut
    if (fiducial_cut) {
      const auto dtx = fabsf(tx - scifi_state.tx());
      const auto threshold =
        stereo_bias_threshold[0] * dtx * dtx + stereo_bias_threshold[1] * dtx + stereo_bias_threshold[2];
      if (!(best_combination.value() < threshold)) continue;
    }

    // Add candidates
    const auto idx = atomicAdd(output_counter, 1u);
    candidate.ut_hits[1] = best_combination.best().x;
    candidate.ut_hits[2] = best_combination.best().y + hit_cache.HitOffset();
    output_tracks[idx] = candidate;
  }
}

__global__ void downstream_v2_find_tracks::downstream_v2_consolidate_find_hits(Parameters parameters)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Offsets
  const auto input_offset = parameters.dev_downstream_compact_track_offsets_layer_1[event_number];
  const auto output_offset = parameters.dev_downstream_compact_track_offsets[event_number];
  const auto input_size = parameters.dev_downstream_compact_track_offsets[event_number + 1] - output_offset;

  // Input
  const auto input_candidates = parameters.dev_downstream_compact_tracks_buffer + input_offset;

  auto output_tracks = parameters.dev_downstream_compact_tracks + output_offset;

  for (unsigned candidate_idx = threadIdx.x; candidate_idx < input_size; candidate_idx += blockDim.x) {
    output_tracks[candidate_idx] = input_candidates[candidate_idx];
  }
}
