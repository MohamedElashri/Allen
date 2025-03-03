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
#include "DownstreamFindHits.cuh"

/**
 * @file DownstreamFindHits.cu
 * @brief This file implements the first part of downstream track reconstruction, which includes two kernel functions:
 *  - `downstream_create_output_table`: Creates an output table with all possible candidates for downstream tracks,
 * using the last layer of UT.
 *  - `downstream_fill_output_table`: Finds hits in the remaining layers of UT for each candidate.
 */

INSTANTIATE_ALGORITHM(downstream_find_hits::downstream_find_hits_t);

void downstream_find_hits::downstream_find_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // output
  set_size<dev_findhits_output_t>(
    arguments, first<host_number_of_events_t>(arguments) * Downstream::DownstreamParameters::MaxNumCandidates);
  set_size<dev_findhits_extrapolation_t>(
    arguments, first<host_number_of_events_t>(arguments) * Downstream::DownstreamParameters::MaxNumCandidates);
  set_size<dev_findhits_candidate_cache_t>(
    arguments, first<host_number_of_events_t>(arguments) * Downstream::DownstreamParameters::MaxNumCandidates);
  set_size<dev_findhits_selected_scifi_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * Downstream::DownstreamParameters::MaxNumDownstreamSciFi);

  // Offsets
  set_size<dev_findhits_num_output_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_findhits_num_selected_scifi_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_findhits_output_selected_scifi_offsets_t>(
    arguments,
    first<host_number_of_events_t>(arguments) * (Downstream::DownstreamParameters::MaxNumDownstreamSciFi + 1));
}

namespace {

  // Special atomicAdd based on atomicCAS for ushort2
  __device__ inline ushort2 atomicAdd_ushort2(ushort2* address, ushort2 val)
  {
    // More checks for differents compilers
    static_assert(sizeof(ushort2) == sizeof(unsigned int));
    static_assert(alignof(ushort2) == alignof(unsigned int));
    // Cast input
    auto add_in_ui = reinterpret_cast<unsigned int*>(address);
    auto val_in_ui = Allen::device::bit_cast<unsigned int>(val);
    // Use CUDA atomicAdd
    // NOTE: this is not always safe, when ushort2.y overflow the uint16_t limit, this will break the value of ushort2.x
    //       but we don't have to worry this in downstream track, since it should never happens.
    //       Related issue in GitLab: https://gitlab.cern.ch/lhcb/Allen/-/issues/495
    auto res_in_ui = atomicAdd(add_in_ui, val_in_ui);
    // Return
    return Allen::device::bit_cast<ushort2>(res_in_ui);
  }

  __device__ inline void add_best_stereo_hits(
    Downstream::DownstreamStructs::DownstreamHits& findhits_output,
    const Downstream::DownstreamStructs::CandidateCache& findhits_cache,
    const unsigned layer)
  {
    constexpr auto layer_u = 1;

    const auto hits = (layer == layer_u) ? findhits_cache.uhits : findhits_cache.vhits;
    const auto scores = (layer == layer_u) ? findhits_cache.uscores : findhits_cache.vscores;

    using Downstream::DownstreamHelpers::BestCandidateManager;
    BestCandidateManager<ushort, true> best_hit_manager;
    best_hit_manager.add(hits[0], scores[0]);
    best_hit_manager.add(hits[1], scores[1]);

    if (!best_hit_manager.exist()) return;

    findhits_output.hits[layer] = best_hit_manager.best();
    findhits_output.score += best_hit_manager.score() * best_hit_manager.score();
  };

  __device__ inline void add_best_stereo_combination(
    Downstream::DownstreamStructs::DownstreamHits& findhits_output,
    const Downstream::DownstreamStructs::CandidateCache& findhits_cache)
  {
    constexpr auto layer_u = 1;
    constexpr auto layer_v = 2;

    // Find the best combination
    using Downstream::DownstreamHelpers::BestCandidateManager;
    BestCandidateManager<uint8_t, true> best_uv_combination_manager;
    // using Downstream::DownstreamParameters::MaxNumSelectedUVhitPerRow;

    best_uv_combination_manager.add(0b00u, findhits_cache.uscores[0] + findhits_cache.vscores[0]);
    best_uv_combination_manager.add(0b01u, findhits_cache.uscores[0] + findhits_cache.vscores[1]);
    best_uv_combination_manager.add(0b10u, findhits_cache.uscores[1] + findhits_cache.vscores[0]);
    best_uv_combination_manager.add(0b11u, findhits_cache.uscores[1] + findhits_cache.vscores[1]);

    // If there's not enough hits, we skip the candidate
    if (!best_uv_combination_manager.exist()) return;

    // Fetch the best hit combination
    const auto best_combination = best_uv_combination_manager.best();
    const auto best_combination_score = best_uv_combination_manager.score();

    // Fill result
    findhits_output.hits[layer_u] = findhits_cache.uhits[(best_combination >> 1u) & 1];
    findhits_output.hits[layer_v] = findhits_cache.vhits[(best_combination) &1];
    findhits_output.score += best_combination_score * best_combination_score;
  };

} // namespace

void downstream_find_hits::downstream_find_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Reset the counter
  Allen::memset_async<dev_findhits_num_output_t>(arguments, 0, context);
  Allen::memset_async<dev_findhits_num_selected_scifi_t>(arguments, 0, context);
  Allen::memset_async<dev_findhits_output_selected_scifi_offsets_t>(arguments, 0, context);
  // Reset the output container
  Allen::memset_async<dev_findhits_output_t>(arguments, 0, context);
  Allen::memset_async<dev_findhits_extrapolation_t>(arguments, 0, context);
  Allen::memset_async<dev_findhits_candidate_cache_t>(arguments, 0, context);
  Allen::memset_async<dev_findhits_selected_scifi_tracks_t>(arguments, 0, context);

  const auto dev_magnet_polarity = constants.dev_magnet_polarity.data();
  const auto dev_ut_layer_geometry = constants.dev_ut_layer_geometry;

  const bool filter_used_scifi_seeds = size<dev_matched_is_scifi_track_used_t>(arguments) > 0;

  // Create candidates
  if (filter_used_scifi_seeds) {
    auto candidates_condition = (m_enable_constant_tolerance_window.value()) ?
                                  global_function(downstream_create_candidates<true, true>) :
                                  global_function(downstream_create_candidates<true, false>);
    candidates_condition(dim3(size<dev_event_list_t>(arguments)), m_num_threads_create_candidates, context)(
      arguments,
      dev_magnet_polarity,
      m_tolerance_window_x4_multiplier,
      m_tolerance_window_y4_multiplier,
      m_ttracks_probability_threshold,
      dev_ut_layer_geometry,
      dev_ttrack_selector.getDevicePointer(),
      m_n_overflow_downstream_tracking.data(context));
  }
  else {
    auto candidates_condition = (m_enable_constant_tolerance_window.value()) ?
                                  global_function(downstream_create_candidates<false, true>) :
                                  global_function(downstream_create_candidates<false, false>);
    candidates_condition(dim3(size<dev_event_list_t>(arguments)), m_num_threads_create_candidates, context)(
      arguments,
      dev_magnet_polarity,
      m_tolerance_window_x4_multiplier,
      m_tolerance_window_y4_multiplier,
      m_ttracks_probability_threshold,
      dev_ut_layer_geometry,
      dev_ttrack_selector.getDevicePointer(),
      m_n_overflow_downstream_tracking.data(context));
  }

  // Fill table
  if (m_require_four_ut_hits.value()) {
    auto candidates_condition = (m_enable_constant_tolerance_window.value()) ?
                                  global_function(downstream_find_rest_hits<true, true>) :
                                  global_function(downstream_find_rest_hits<true, false>);
    candidates_condition(dim3(size<dev_event_list_t>(arguments)), m_num_threads_find_rest_hits, context)(
      arguments,
      dev_ut_layer_geometry,
      m_tolerance_window_x1_multiplier,
      m_tolerance_window_x2_multiplier,
      m_tolerance_window_x3_multiplier,
      m_tolerance_window_y1_multiplier,
      m_tolerance_window_y2_multiplier,
      m_tolerance_window_y3_multiplier);
  }
  else {
    auto candidates_condition = (m_enable_constant_tolerance_window.value()) ?
                                  global_function(downstream_find_rest_hits<false, true>) :
                                  global_function(downstream_find_rest_hits<false, false>);
    candidates_condition(dim3(size<dev_event_list_t>(arguments)), m_num_threads_find_rest_hits, context)(
      arguments,
      dev_ut_layer_geometry,
      m_tolerance_window_x1_multiplier,
      m_tolerance_window_x2_multiplier,
      m_tolerance_window_x3_multiplier,
      m_tolerance_window_y1_multiplier,
      m_tolerance_window_y2_multiplier,
      m_tolerance_window_y3_multiplier);
  }
}

/**
 * @brief Creates the output table with all possible downstream track candidates from SciFi seeds. This includes the
 * following steps:
 *  1. Calculates the magnet point for each SciFi seed.
 *  2. Opens a search window and selects possible hits in the last layer of UT.
 *  3. For each selected hit, recomputes the slope using the hit position and magnet point.
 *
 * @note To improve algorithm throughput, this function will cache all UT hits and sector information into shared
 * memory, if possible.
 */
template<bool filter_used_scifi_seeds, bool use_constant_tolerance_window>
__global__ void downstream_find_hits::downstream_create_candidates(
  downstream_find_hits::Parameters parameters,
  const float* dev_magnet_polarity,
  const float tolerance_window_x4_multiplier,
  const float tolerance_window_y4_multiplier,
  const float ttracks_probability_threshold,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  const TTrackSelector::DeviceType* dev_ttrack_selector,
  [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType dev_n_overflow_downstream_tracking)
{

  ///////////////////////////////////////////////////////
  //
  // B a s i c   s e t u p
  //
  ///////////////////////////////////////////////////////

  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Load scifi information
  const auto scifi_offset = parameters.dev_offsets_seeding[event_number];
  const auto scifi_n_tracks = parameters.dev_offsets_seeding[event_number + 1] - scifi_offset;
  const auto scifi_states = parameters.dev_seeding_states + scifi_offset;
  const auto scifi_qops = parameters.dev_seeding_qop + scifi_offset;
  const auto scifi_chi2Y = parameters.dev_seeding_chi2Y + scifi_offset;

  // Load UT information
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Output
  auto findhits_outputs =
    parameters.dev_findhits_output + event_number * Downstream::DownstreamParameters::MaxNumCandidates;
  auto findhits_extrapolations =
    parameters.dev_findhits_extrapolation + event_number * Downstream::DownstreamParameters::MaxNumCandidates;
  auto findhits_selected_scifi_tracks = parameters.dev_findhits_selected_scifi_tracks +
                                        event_number * Downstream::DownstreamParameters::MaxNumDownstreamSciFi;

  // Offset
  auto output_selected_scifi_offsets = parameters.dev_findhits_output_selected_scifi_offsets +
                                       event_number * (Downstream::DownstreamParameters::MaxNumDownstreamSciFi + 1);

  ///////////////////////////////////////////////////////
  //
  // S h a r e d   m e m o r y   s e t u p
  //
  ///////////////////////////////////////////////////////

  // Allocate the memory
  __shared__ typename UTHitsCache_CreateCandidates::ElementType
    shared_memory_hit_caching[UTHitsCache_CreateCandidates::NumElements];

  // Hit Cache
  UTHitsCache_CreateCandidates hit_cache {shared_memory_hit_caching};

  // Allocate objects
  __shared__ ushort2 shared_counter;
  auto& shared_num_candidates = shared_counter.x;
  auto& shared_num_selelected_scifi = shared_counter.y;

  __shared__ float scaling_factor;

  // Initialization
  if (threadIdx.x == 0) {
    shared_counter = Allen::device::bit_cast<ushort2>(0u);
    scaling_factor = 1.f;
  };
  __syncthreads();

  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t
  //
  ///////////////////////////////////////////////////////

  // Alias
  const unsigned layer = 3; // X3 layer

  // Cache mean values to register
  const float mean_z = dev_ut_layer_geometry->mean_z[layer];
  const float error_layer_z = dev_ut_layer_geometry->error_z[layer];

  // Layer offset
  const auto layer_offset = ut_hit_offsets.layer_offset(layer);

  // Cache hits and sectors
  hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_ut_layer_geometry, layer);
  __syncthreads();

  // Try up to MaxNumIteration times.
  // If a candidate overflows, try using a tighter threshold.
  // If it still exceeds after MaxNumIteration times, simply reset the event to 0
  for (unsigned iteration = 0; iteration < MaxNumIteration; iteration++) {
    // Start
    for (unsigned short SciFi_idx = threadIdx.x; SciFi_idx < scifi_n_tracks; SciFi_idx += blockDim.x) {
      // Skip the used seeds
      if constexpr (filter_used_scifi_seeds) {
        if (parameters.dev_matched_is_scifi_track_used[scifi_offset + SciFi_idx]) continue;
      }

      // Filter T tracks which are 100% ghost for downstream tracks
      const auto scifi_state = scifi_states[SciFi_idx];
      float ttrack_prob_inputs[TTrackSelector::DeviceType::nInput] = {
        fabsf(scifi_state.x()),
        fabsf(scifi_state.y()),
        fabsf(scifi_state.tx()),
        fabsf(scifi_state.ty()),
      };
      const auto ttrack_prob = dev_ttrack_selector->evaluate(ttrack_prob_inputs);
      if (ttrack_prob > ttracks_probability_threshold) continue;

      // Get SciFi qop
      const auto scifi_qop = scifi_qops[SciFi_idx];

      // Load extrapolation
      using Downstream::DownstreamExtrapolation::ExtrapolateTrack;
      ExtrapolateTrack exTrack(scifi_state, scifi_qop);

      auto xTol = 0.f;
      auto yTol = 0.f;

      // Get tolerances
      if constexpr (!(use_constant_tolerance_window)) {
        xTol = exTrack.xTol(layer);
        yTol = exTrack.yTol(layer);
      }
      else {
        xTol = exTrack.xTolConst(layer) * tolerance_window_x4_multiplier;
        yTol = exTrack.yTolConst(layer) * tolerance_window_y4_multiplier;
      }

      xTol *= scaling_factor;
      yTol *= scaling_factor;

      // Get expected x and open the search window
      const auto expected_layer_y = exTrack.yAtZ(mean_z);
      const auto expected_layer_x = exTrack.xAtZ(mean_z);
      const auto xTol_layer = xTol + fabsf(exTrack.tx() * error_layer_z);
      const auto yTol_layer = 18.f;
      const auto fired_sectors =
        dev_ut_layer_geometry->find_sectors(layer, expected_layer_y - yTol_layer, expected_layer_y + yTol_layer);

      // Loop all hits, save best 10 hits inside of the search window.
      using Downstream::DownstreamHelpers::MultiCandidateManager;
      using Downstream::DownstreamParameters::MaxNumSelectedX3HitPerScifi;
      MultiCandidateManager<unsigned short, MaxNumSelectedX3HitPerScifi, true> BestX3Hits;

      for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
        const auto sector = fired_sectors[sector_idx];
        if (sector == -1) break;
        const auto hit_start = ut_hit_offsets.sector_group_offset(layer, sector) - layer_offset;
        const auto hit_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - layer_offset;
        hit_cache.for_each_in_x_tol(
          hit_start,
          hit_end,
          expected_layer_x - xTol_layer,
          expected_layer_x + xTol_layer,
          [&BestX3Hits, &exTrack, &xTol, &yTol](ushort idx, const UTHitsCache_CreateCandidates::MiniHit& hit) {
            const float expected_hit_y = exTrack.yAtZ(hit.zAtYEq0());
            if (hit.isNotYCompatible(expected_hit_y, yTol)) return;
            const float xdist = exTrack.xAtZ(hit.zAtYEq0()) - hit.xAtYEq0();
            if (fabsf(xdist) < xTol) {
              BestX3Hits.add(idx, xdist);
            }
          });
      }

      // Skip the seed if not X3 hit is found
      const auto n_x3hits = BestX3Hits.size();
      if (n_x3hits == 0) continue;

      const auto offset_and_idx = atomicAdd_ushort2(&shared_counter, make_ushort2(n_x3hits, 1u));
      const auto& offset = offset_and_idx.x;
      const auto& idx = offset_and_idx.y;

      if (
        (offset + n_x3hits) < Downstream::DownstreamParameters::MaxNumCandidates &&
        idx < Downstream::DownstreamParameters::MaxNumDownstreamSciFi) {
        // Output table
        for (unsigned short x3hits_idx = 0; x3hits_idx < n_x3hits; x3hits_idx++) {
          const auto hit_idx = BestX3Hits.get(x3hits_idx);
          const auto hit = hit_cache.hit(hit_idx);
          // const auto expected_hit_y = exTrack.yAtZ(hit.zAtYEq0());
          const auto new_tx = exTrack.get_new_tx(hit.zAtYEq0(), hit.xAtYEq0());
          const auto new_qop = exTrack.get_new_qop(new_tx, scifi_states[SciFi_idx].tx(), *dev_magnet_polarity);

          // Fill output
          const auto candidate_idx = offset + x3hits_idx;

          auto& findhits_output = findhits_outputs[candidate_idx];
          findhits_output.hits[layer] = hit_idx + hit_cache.HitOffset();
          findhits_output.hits[0] = Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
          findhits_output.hits[1] = Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
          findhits_output.hits[2] = Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
          findhits_output.score = 0;

          // Fill cache
          auto& findhits_extrapolation = findhits_extrapolations[candidate_idx];
          findhits_extrapolation.xMagnet = exTrack.xMagnet();
          findhits_extrapolation.yMagnet = exTrack.yMagnet();
          findhits_extrapolation.zMagnet = exTrack.zMagnet();
          findhits_extrapolation.tx = new_tx;
          findhits_extrapolation.ty = exTrack.ty();
          findhits_extrapolation.qop = new_qop;
        }
        // Output scifi selection
        auto& findhits_selected_scifi_track = findhits_selected_scifi_tracks[idx];
        findhits_selected_scifi_track.scifi_idx = SciFi_idx;
        findhits_selected_scifi_track.tx = scifi_state.tx();
        findhits_selected_scifi_track.ty = scifi_state.ty();
        findhits_selected_scifi_track.y = scifi_state.y();
        findhits_selected_scifi_track.chi2 = scifi_chi2Y[SciFi_idx];
        findhits_selected_scifi_track.xMagnet = exTrack.xMagnet();
        findhits_selected_scifi_track.zMagnet = exTrack.zMagnet();

        // Update offset
        output_selected_scifi_offsets[idx] = offset;
      }
      else {
        break;
      }
    }
    __syncthreads();

    const auto overflow =
      !((shared_num_candidates < Downstream::DownstreamParameters::MaxNumCandidates) &&
        (shared_num_selelected_scifi < Downstream::DownstreamParameters::MaxNumDownstreamSciFi));
    __syncthreads();
    if (overflow) {
      if (threadIdx.x == 0) {
        shared_counter = Allen::device::bit_cast<ushort2>(0u);
        scaling_factor *= 0.5f;
        dev_n_overflow_downstream_tracking.increment();
      }
      __syncthreads();
      continue;
    }
    break;
  }
  if (threadIdx.x == 0) {

    // Store the number of rows
    parameters.dev_findhits_num_output[event_number] = shared_num_candidates;
    // Store the number of selected scifi seeds
    parameters.dev_findhits_num_selected_scifi[event_number] = shared_num_selelected_scifi;
    // Set the end of offsets
    output_selected_scifi_offsets[shared_num_selelected_scifi] = shared_num_candidates;
  };
  __syncthreads();
}

/**
 * @brief Finds and fills in corresponding hits in the remaining layers of UT for each downstream track candidate.
 *
 * @note To improve algorithm throughput, this function will cache all UT hits and sector information into shared
 * memory, if possible.
 */

template<bool require_four_hits, bool use_constant_tolerance_window>
__global__ void downstream_find_hits::downstream_find_rest_hits(
  downstream_find_hits::Parameters parameters,
  const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
  const float tolerance_window_x1_multiplier,
  const float tolerance_window_x2_multiplier,
  const float tolerance_window_x3_multiplier,
  const float tolerance_window_y1_multiplier,
  const float tolerance_window_y2_multiplier,
  const float tolerance_window_y3_multiplier)
{
  ///////////////////////////////////////////////////////
  //
  // B a s i c   s e t u p
  //
  ///////////////////////////////////////////////////////

  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Load UT information
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Output
  auto findhits_outputs =
    parameters.dev_findhits_output + event_number * Downstream::DownstreamParameters::MaxNumCandidates;
  auto findhits_extrapolations =
    parameters.dev_findhits_extrapolation + event_number * Downstream::DownstreamParameters::MaxNumCandidates;
  auto findhits_caches =
    parameters.dev_findhits_candidate_cache + event_number * Downstream::DownstreamParameters::MaxNumCandidates;

  // Sizes
  const auto num_output = parameters.dev_findhits_num_output[event_number];

  ///////////////////////////////////////////////////////
  //
  // S h a r e d   m e m o r y   s e t u p
  //
  ///////////////////////////////////////////////////////

  using UT::Constants::n_layers;

  // Allocate the memory
  __shared__
    typename UTHitsCache_FindRestHits::ElementType shared_memory_hit_caching[UTHitsCache_FindRestHits::NumElements];

  // Hit Cache
  UTHitsCache_FindRestHits hit_cache {shared_memory_hit_caching};

  const float x_tolerance_windows[3] = {
    tolerance_window_x1_multiplier, tolerance_window_x2_multiplier, tolerance_window_x3_multiplier};
  const float y_tolerance_windows[3] = {
    tolerance_window_y1_multiplier, tolerance_window_y2_multiplier, tolerance_window_y3_multiplier};

  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t
  //
  ///////////////////////////////////////////////////////

  // Since this loop is static, it should be unrolled automatically
  for (unsigned layer = 0; layer < 3; ++layer) {
    // Cache dxdy to register
    const float layer_dxdy = dev_ut_layer_geometry->mean_dxdy[layer];
    const float layer_z = dev_ut_layer_geometry->mean_z[layer];
    const float error_layer_dxdy = dev_ut_layer_geometry->error_dxdy[layer];
    const float error_layer_z = dev_ut_layer_geometry->error_z[layer];

    // Layer offset
    const auto layer_offset = ut_hit_offsets.layer_offset(layer);

    // Cache hits and sectors
    hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_ut_layer_geometry, layer);
    __syncthreads();

    // Start
    for (unsigned candidate_idx = threadIdx.x; candidate_idx < num_output; candidate_idx += blockDim.x) {
      auto& findhits_output = findhits_outputs[candidate_idx];
      if constexpr (require_four_hits) {
        if (findhits_output.score == std::numeric_limits<float>::infinity()) continue;
      }

      // Load extrapolation
      using Downstream::DownstreamExtrapolation::ExtrapolateTrack;
      auto findhits_extrapolation = findhits_extrapolations[candidate_idx];
      ExtrapolateTrack exTrack {findhits_extrapolation.xMagnet,
                                findhits_extrapolation.yMagnet,
                                findhits_extrapolation.zMagnet,
                                findhits_extrapolation.tx,
                                findhits_extrapolation.ty,
                                findhits_extrapolation.qop};

      auto xTol = 0.f;
      auto yTol = 0.f;

      // Get tolerances
      if constexpr (!(use_constant_tolerance_window)) {
        xTol = exTrack.xTol(layer);
        yTol = exTrack.yTol(layer);
      }
      else {
        xTol = exTrack.xTolConst(layer) * x_tolerance_windows[layer];
        yTol = exTrack.yTolConst(layer) * y_tolerance_windows[layer];
      }

      // Get expected x and open the search window
      const auto expected_layer_y = exTrack.yAtZ(layer_z);
      const auto expected_layer_x = exTrack.xAtZ(layer_z) - layer_dxdy * expected_layer_y;
      const auto expected_layer_y_error = fabsf(exTrack.ty() * error_layer_z);
      const auto xTol_layer = xTol + fabsf(exTrack.tx() * error_layer_z) + fabsf(expected_layer_y * error_layer_dxdy) +
                              fabsf(expected_layer_y_error * layer_dxdy);
      const auto yTol_layer = 18.f;
      const auto fired_sectors =
        dev_ut_layer_geometry->find_sectors(layer, expected_layer_y - yTol_layer, expected_layer_y + yTol_layer);

      // For x0 layer, we select the best candidate
      if (layer == 0) {
        using Downstream::DownstreamHelpers::BestCandidateManager;
        BestCandidateManager<ushort, true> best_x0_hit;
        for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
          const auto sector = fired_sectors[sector_idx];
          if (sector == -1) break;
          const auto hit_start = ut_hit_offsets.sector_group_offset(layer, sector) - layer_offset;
          const auto hit_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - layer_offset;
          hit_cache.for_each_in_x_tol(
            hit_start,
            hit_end,
            expected_layer_x - xTol_layer,
            expected_layer_x + xTol_layer,
            [&best_x0_hit, &exTrack, &xTol, &yTol](ushort idx, const UTHitsCache_FindRestHits::MiniHit& hit) {
              const float expected_hit_y = exTrack.yAtZ(hit.zAtYEq0());
              if (hit.isNotYCompatible(expected_hit_y, yTol)) return;
              const float xdist = exTrack.xAtZ(hit.zAtYEq0()) - hit.xAtYEq0();
              if (fabsf(xdist) < xTol) {
                best_x0_hit.add(idx, xdist);
              }
            });
        }

        if (!best_x0_hit.exist()) {
          if constexpr (require_four_hits) {
            findhits_output.score = Allen::numeric_limits<float>::infinity();
          }
          continue;
        }

        // Fill result
        findhits_output.hits[layer] = best_x0_hit.best() + hit_cache.HitOffset();
        findhits_output.score = best_x0_hit.score() * best_x0_hit.score();
      }
      // For uv layers, we select best two candidates
      else {

        using Downstream::DownstreamHelpers::MultiCandidateManager;
        using Downstream::DownstreamParameters::MaxNumSelectedUVhitPerRow;
        MultiCandidateManager<ushort, MaxNumSelectedUVhitPerRow, true> best_uv_hits;
        for (unsigned sector_idx = 0; sector_idx < 4; sector_idx++) {
          const auto sector = fired_sectors[sector_idx];
          if (sector == -1) break;
          const auto hit_start = ut_hit_offsets.sector_group_offset(layer, sector) - layer_offset;
          const auto hit_end = ut_hit_offsets.sector_group_offset(layer, sector + 1) - layer_offset;
          hit_cache.for_each_in_x_tol(
            hit_start,
            hit_end,
            expected_layer_x - xTol_layer,
            expected_layer_x + xTol_layer,
            [&best_uv_hits, &exTrack, &yTol](ushort idx, const UTHitsCache_FindRestHits::MiniHit& hit) {
              const float expected_hit_y = exTrack.yAtZ(hit.zAtYEq0());
              if (hit.isNotYCompatible(expected_hit_y, yTol)) return;
              const float xdist = exTrack.xAtZ(hit.zAtYEq0()) - hit.xAt(expected_hit_y);
              best_uv_hits.add(idx, xdist);
            });
        }

        if constexpr (require_four_hits) {
          if (!best_uv_hits.exist()) {
            findhits_output.score = Allen::numeric_limits<float>::infinity();
            continue;
          }
        }

        // Fill result
        auto& findhits_cache = findhits_caches[candidate_idx];
        auto& hits = (layer == 1) ? findhits_cache.uhits : findhits_cache.vhits;
        auto& scores = (layer == 1) ? findhits_cache.uscores : findhits_cache.vscores;

        // Fill hits and scores
        if constexpr (require_four_hits) {
          hits[0] = best_uv_hits.get(0) + hit_cache.HitOffset();
          scores[0] = best_uv_hits.score(0);
          hits[1] = (best_uv_hits.size() > 1) ? best_uv_hits.get(1) + hit_cache.HitOffset() :
                                                Allen::numeric_limits<float>::infinity();
          scores[1] = (best_uv_hits.size() > 1) ? best_uv_hits.score(1) : Allen::numeric_limits<float>::infinity();
        }
        else {
          hits[0] = (best_uv_hits.size() > 0) ? best_uv_hits.get(0) + hit_cache.HitOffset() :
                                                Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
          hits[1] = (best_uv_hits.size() > 1) ? best_uv_hits.get(1) + hit_cache.HitOffset() :
                                                Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;

          scores[0] = (best_uv_hits.size() > 0) ? best_uv_hits.score(0) : Allen::numeric_limits<float>::infinity();
          scores[1] = (best_uv_hits.size() > 1) ? best_uv_hits.score(1) : Allen::numeric_limits<float>::infinity();
        }
      }
    }
    __syncthreads();
  }

  //
  // Now we have found all possible hits for each row, we can compute best UV combination
  //
  for (unsigned candidate_idx = threadIdx.x; candidate_idx < num_output; candidate_idx += blockDim.x) {

    auto& findhits_output = findhits_outputs[candidate_idx];

    if constexpr (require_four_hits) {
      if (findhits_output.score == std::numeric_limits<float>::infinity()) continue;

      const auto& findhits_cache = findhits_caches[candidate_idx];

      add_best_stereo_combination(findhits_output, findhits_cache);
    }
    else {
      const auto& findhits_cache = findhits_caches[candidate_idx];
      constexpr auto INVALID_HIT = Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
      const unsigned num_hits = (findhits_output.hits[0] != INVALID_HIT) + (findhits_output.hits[3] != INVALID_HIT) +
                                (findhits_cache.uhits[0] != INVALID_HIT) + (findhits_cache.vhits[0] != INVALID_HIT);

      if (num_hits < 3) {
        findhits_output.score = Allen::numeric_limits<float>::infinity();
        continue;
      }

      if (num_hits == 4) {
        add_best_stereo_combination(findhits_output, findhits_cache);
      }
      else {
        constexpr auto layer_u = 1;
        constexpr auto layer_v = 2;
        add_best_stereo_hits(findhits_output, findhits_cache, layer_u);
        add_best_stereo_hits(findhits_output, findhits_cache, layer_v);

        // Scale the score of 3 hits candidates to favor the 4 hits candidates
        findhits_output.score *= 10.f;
      }
    }
  }
  __syncthreads();
}
