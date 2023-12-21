/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
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
  // working memory
  using Downstream::DownstreamCache::HitCache;
  set_size<dev_hit_caching_memory_t>(
    arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) * HitCache::RowSize);
  set_size<dev_hit_caching_counter_t>(arguments, 1);

  // output table
  using Downstream::DownstreamStructs::FindHits_OutputTable;
  set_size<dev_output_table_t>(
    arguments, first<host_number_of_events_t>(arguments) * FindHits_OutputTable::TotalMemorySize);
  set_size<dev_num_row_output_table_t>(arguments, first<host_number_of_events_t>(arguments));

  // output scifi selection
  using Downstream::DownstreamParameters::MaxNumDownstreamSciFi;
  set_size<dev_selected_scifi_t>(arguments, first<host_number_of_events_t>(arguments) * MaxNumDownstreamSciFi);
  set_size<dev_num_selected_scifi_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_selected_scifi_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * (MaxNumDownstreamSciFi + 1));
  set_size<dev_selected_scifi_qop_t>(arguments, first<host_number_of_events_t>(arguments) * MaxNumDownstreamSciFi);
  set_size<dev_selected_scifi_chi2Y_t>(arguments, first<host_number_of_events_t>(arguments) * MaxNumDownstreamSciFi);
}

void downstream_find_hits::downstream_find_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Reset the counter
  Allen::memset_async<dev_num_row_output_table_t>(arguments, 0, context);
  Allen::memset_async<dev_num_selected_scifi_t>(arguments, 0, context);
  Allen::memset_async<dev_hit_caching_counter_t>(arguments, 0, context);

  const auto dev_unique_x_sector_layer_offsets = constants.dev_unique_x_sector_layer_offsets.data();
  const auto dev_unique_sector_xs = constants.dev_unique_sector_xs.data();
  const auto dev_ut_dxDy = constants.dev_ut_dxDy.data();
  const auto dev_magnet_polarity = constants.dev_magnet_polarity.data();
  const auto dev_mean_layer_z = constants.dev_mean_ut_layer_zs.data();

  // Create table
  global_function(downstream_create_output_table)(
    dim3(size<dev_event_list_t>(arguments)), property<num_threads_scifi_t>(), context)(
    arguments, dev_unique_x_sector_layer_offsets, dev_unique_sector_xs, dev_magnet_polarity, dev_mean_layer_z);

  // Fill table
  global_function(downstream_fill_output_table)(
    dim3(size<dev_event_list_t>(arguments)), property<num_threads_row_t>(), context)(
    arguments, dev_unique_x_sector_layer_offsets, dev_unique_sector_xs, dev_ut_dxDy, dev_mean_layer_z);
}

namespace {
  // Special atomicAdd based on atomicCAS for uint2
  __device__ auto atomicAdd(uint2* address, uint2 val)
  {
    // More checks for differents compilers
    static_assert(sizeof(uint2) == sizeof(unsigned long long));
    static_assert(alignof(uint2) == alignof(unsigned long long));
    static_assert(Allen::is_trivially_copyable_v<uint2>);
    static_assert(Allen::is_trivially_copyable_v<unsigned long long>);

    // Convert address to ull
    auto address_as_ull = reinterpret_cast<unsigned long long int*>(address);

    unsigned long long int assumed_as_ull, old_as_ull = *address_as_ull;

    do {
      assumed_as_ull = old_as_ull;
      auto old_as_u2 = Allen::device::bit_cast<uint2>(old_as_ull);
      auto added_as_u2 = make_uint2(old_as_u2.x + val.x, old_as_u2.y + val.y);
      auto added_as_ull = Allen::device::bit_cast<unsigned long long int>(added_as_u2);
      old_as_ull = atomicCAS(address_as_ull, assumed_as_ull, added_as_ull);
    } while (assumed_as_ull != old_as_ull);

    return Allen::device::bit_cast<uint2>(old_as_ull);
  }
} // namespace

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
__global__ void downstream_find_hits::downstream_create_output_table(
  downstream_find_hits::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const float* dev_unique_sector_xs,
  const float* dev_magnet_polarity,
  const float* dev_mean_layer_z)
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
  const auto scifi_is_matched = parameters.dev_matched_is_scifi_track_used + scifi_offset;

  // Load UT information
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Global memory for hit caching
  const auto global_memory_hit_caching = parameters.dev_hit_caching_memory;
  const auto global_memory_hit_caching_counter = parameters.dev_hit_caching_counter;

  // Output table
  using Downstream::DownstreamStructs::FindHits_OutputTable;
  auto output_table_memory = parameters.dev_output_table + event_number * FindHits_OutputTable::TotalMemorySize;
  auto num_row_output_table = parameters.dev_num_row_output_table + event_number;
  FindHits_OutputTable output_table {output_table_memory};

  // Scifi selection output
  using Downstream::DownstreamParameters::MaxNumDownstreamSciFi;
  auto output_selected_scifi = parameters.dev_selected_scifi + event_number * MaxNumDownstreamSciFi;
  auto output_selected_scifi_qop = parameters.dev_selected_scifi_qop + event_number * MaxNumDownstreamSciFi;
  auto output_selected_scifi_chi2Y = parameters.dev_selected_scifi_chi2Y + event_number * MaxNumDownstreamSciFi;
  auto output_selected_scifi_offsets =
    parameters.dev_selected_scifi_offsets + event_number * (MaxNumDownstreamSciFi + 1);
  auto output_num_selected_scifi = parameters.dev_num_selected_scifi + event_number;

  ///////////////////////////////////////////////////////
  //
  // S h a r e d   m e m o r y   s e t u p
  //
  ///////////////////////////////////////////////////////

  using Downstream::DownstreamCache::HitCache;
  using Downstream::DownstreamCache::SectorCache;

  // Allocate the memory
  __shared__ char shared_memory_hit_caching[HitCache::TotalMemorySize];
  __shared__ char shared_memory_sector_caching[SectorCache::TotalMemorySize];

  // Allocate objects
  __shared__ uint2 shared_counter;
  auto& shared_num_rows = shared_counter.x;
  auto& shared_num_selelected_scifi = shared_counter.y;

  // Hit Cache
  HitCache hit_cache {shared_memory_hit_caching, global_memory_hit_caching, global_memory_hit_caching_counter};
  SectorCache sector_cache {shared_memory_sector_caching};

  // Initialization
  if (threadIdx.x == 0) {
    shared_num_rows = 0;
    shared_num_selelected_scifi = 0;
  };
  __syncthreads();

  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t
  //
  ///////////////////////////////////////////////////////

  // Alias
  const unsigned layer = 3; // X3 layer

  // Cache hits and sectors
  hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_mean_layer_z[layer], layer, threadIdx.x, blockDim.x);
  sector_cache.cache_layer(
    ut_hit_offsets, dev_unique_sector_xs, dev_unique_x_sector_layer_offsets, layer, threadIdx.x, blockDim.x);
  __syncthreads();

  // Start
  for (unsigned short SciFi_idx = threadIdx.x; SciFi_idx < scifi_n_tracks; SciFi_idx += blockDim.x) {
    // Skip the matched seeds
    if (scifi_is_matched[SciFi_idx]) continue;

    // Get SciFi qop
    const float scifi_qop = scifi_qops[SciFi_idx];

    // Load extrapolation
    using Downstream::DownstreamExtrapolation::ExtrapolateTrack;
    ExtrapolateTrack exTrack(scifi_states[SciFi_idx], scifi_qop, *dev_magnet_polarity);

    // Get tolerances
    const auto xTol = exTrack.xTol(layer);
    const auto yTol = exTrack.yTol(layer);

    // Get expected x and open the search window
    const auto expected_layer_x = exTrack.xAtZ(dev_mean_layer_z[layer]);
    const auto hit_range = sector_cache.get_hit_range(expected_layer_x - xTol, expected_layer_x + xTol);

    // Loop all hits, save best 10 hits inside of the search window.
    using Downstream::DownstreamHelpers::MultiCandidateManager;
    using Downstream::DownstreamParameters::MaxNumSelectedX3HitPerScifi;
    MultiCandidateManager<unsigned short, MaxNumSelectedX3HitPerScifi, true> BestX3Hits;

    for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
      // Cross check
      assert(hit_idx < hit_cache.size());

      // Filter Y
      const float hit_z = hit_cache.zAtYEq0(hit_idx);
      const float expected_hit_y = exTrack.yAtZ(hit_z);
      if (hit_cache.isNotYCompatible(hit_idx, expected_hit_y, yTol)) continue;

      // Filter X
      const float expected_hit_x = exTrack.xAtZ(hit_z);
      const float hit_x = hit_cache.xAtYEq0(hit_idx);
      const float xdist = fabsf(expected_hit_x - hit_x);
      if (xdist > xTol) continue;

      // Store
      BestX3Hits.add(hit_idx, xdist);
    };

    // Skip the seed if not X3 hit is found
    const auto n_x3hits = BestX3Hits.size();
    if (n_x3hits == 0) continue;

    // Create the output table
    using Downstream::DownstreamParameters::MaxNumDownstreamSciFi;
    if (shared_num_rows < FindHits_OutputTable::NumRow && shared_num_selelected_scifi < MaxNumDownstreamSciFi) {
      // Output table
      const auto num_hits = min(FindHits_OutputTable::NumRow - shared_num_rows, n_x3hits);
      const auto offset_and_idx = atomicAdd(&shared_counter, make_uint2(num_hits, 1u));
      const auto& offset = offset_and_idx.x;
      const auto& idx = offset_and_idx.y;
      for (unsigned short x3hits_idx = 0; x3hits_idx < num_hits; x3hits_idx++) {
        const auto hit_idx = BestX3Hits.get(x3hits_idx);
        const auto hit_z = hit_cache.zAtYEq0(hit_idx);
        const auto hit_x = hit_cache.xAtYEq0(hit_idx);

        const auto new_tx = exTrack.get_new_tx(hit_z, hit_x);
        const auto new_qop = exTrack.get_new_qop(new_tx, scifi_states[SciFi_idx].tx, *dev_magnet_polarity);

        output_table.x3_hit(offset + x3hits_idx) = hit_idx + hit_cache.HitOffset();
        output_table.tx(offset + x3hits_idx) = new_tx;
        output_table.ty(offset + x3hits_idx) = exTrack.ty();
        output_table.xMagnet(offset + x3hits_idx) = exTrack.xMagnet();
        output_table.yMagnet(offset + x3hits_idx) = exTrack.yMagnet();
        output_table.zMagnet(offset + x3hits_idx) = exTrack.zMagnet();
        output_table.qop(offset + x3hits_idx) = new_qop;
        output_table.score(offset + x3hits_idx) = 0.f;
      }
      // Output scifi selection
      output_selected_scifi[idx] = SciFi_idx;
      output_selected_scifi_qop[idx] = scifi_qop;
      output_selected_scifi_chi2Y[idx] = scifi_chi2Y[SciFi_idx];
      output_selected_scifi_offsets[idx] = offset;
    }
    else {
      break;
    }
  }
  __syncthreads();

  if (threadIdx.x == 0) {
    // Store the number of rows
    num_row_output_table[0] = shared_num_rows;
    // Store the number of selected scifi seeds
    output_num_selected_scifi[0] = shared_num_selelected_scifi;
    // Set the end of offsets
    output_selected_scifi_offsets[shared_num_selelected_scifi] = shared_num_rows;
  };
  __syncthreads();
}

/**
 * @brief Finds and fills in corresponding hits in the remaining layers of UT for each downstream track candidate.
 *
 * @note To improve algorithm throughput, this function will cache all UT hits and sector information into shared
 * memory, if possible.
 */

__global__ void downstream_find_hits::downstream_fill_output_table(
  downstream_find_hits::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const float* dev_unique_sector_xs,
  const float* dev_ut_dxDy,
  const float* dev_mean_layer_z)
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
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Global memory for hit caching
  const auto global_memory_hit_caching = parameters.dev_hit_caching_memory;
  const auto global_memory_hit_caching_counter = parameters.dev_hit_caching_counter;

  // Output
  using Downstream::DownstreamStructs::FindHits_OutputTable;
  auto output_table_memory = parameters.dev_output_table + event_number * FindHits_OutputTable::TotalMemorySize;
  const auto num_row_output_table = parameters.dev_num_row_output_table[event_number];
  FindHits_OutputTable output_table {output_table_memory};

  ///////////////////////////////////////////////////////
  //
  // S h a r e d   m e m o r y   s e t u p
  //
  ///////////////////////////////////////////////////////

  using Downstream::DownstreamCache::HitCache;
  using Downstream::DownstreamCache::SectorCache;
  using UT::Constants::n_layers;

  // Allocate the memory
  __shared__ char shared_memory_hit_caching[HitCache::TotalMemorySize];
  __shared__ char shared_memory_sector_caching[SectorCache::TotalMemorySize];

  // Hit Cache
  HitCache hit_cache {shared_memory_hit_caching, global_memory_hit_caching, global_memory_hit_caching_counter};
  SectorCache sector_cache {shared_memory_sector_caching};

  ///////////////////////////////////////////////////////
  //
  // A l g o r i t h m    s t a r t
  //
  ///////////////////////////////////////////////////////

  // Since this loop is static, it should be unrolled automatically
  for (unsigned short layer = 0; layer < 3; ++layer) {
    // Cache hits and sectors
    hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_mean_layer_z[layer], layer, threadIdx.x, blockDim.x);
    sector_cache.cache_layer(
      ut_hit_offsets, dev_unique_sector_xs, dev_unique_x_sector_layer_offsets, layer, threadIdx.x, blockDim.x);
    __syncthreads();

    // Cache dxdy to register
    const float dxdy = dev_ut_dxDy[layer];

    // Start

    for (unsigned short row = threadIdx.x; row < num_row_output_table; row += blockDim.x) {
      if (output_table.score(row) == Allen::numeric_limits<float>::infinity()) continue;

      // Load extrapolation
      using Downstream::DownstreamExtrapolation::ExtrapolateTrack;
      ExtrapolateTrack exTrack {output_table.xMagnet(row),
                                output_table.yMagnet(row),
                                output_table.zMagnet(row),
                                output_table.tx(row),
                                output_table.ty(row),
                                output_table.qop(row)};

      // Get tolerances
      const auto xTol = exTrack.xTol(layer);
      const auto yTol = exTrack.yTol(layer);

      // For x0 layer, we select the best candidate
      if (layer == 0) {
        // Get expected x and open the search window
        const auto expected_layer_x = exTrack.xAtZ(dev_mean_layer_z[layer]);
        const auto hit_range = sector_cache.get_hit_range(expected_layer_x - xTol, expected_layer_x + xTol);

        using Downstream::DownstreamHelpers::BestCandidateManager;
        BestCandidateManager<ushort, true> best_x0_hit;
        for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
          const float hit_z = hit_cache.zAtYEq0(hit_idx);

          const float expected_hit_y = exTrack.yAtZ(hit_z);
          if (hit_cache.isNotYCompatible(hit_idx, expected_hit_y, yTol)) continue;

          const float expected_hit_x = exTrack.xAtZ(hit_z);
          const float hit_x = hit_cache.xAtYEq0(hit_idx);

          const float xdist = expected_hit_x - hit_x;
          if (fabsf(xdist) > xTol) continue;

          // Store
          best_x0_hit.add(hit_idx, xdist);
        };

        if (!best_x0_hit.exist()) {
          output_table.score(row) = Allen::numeric_limits<float>::infinity();
          continue;
        }

        // Fill result
        output_table.x0_hit(row) = best_x0_hit.best() + hit_cache.HitOffset();
        output_table.x0_dist(row) = best_x0_hit.score();
      }
      // For uv layers, we select best two candidates
      else {
        // Get expected x and open the search window
        const auto expected_layer_y = exTrack.yAtZ(dev_mean_layer_z[layer]);
        const auto expected_layer_x = exTrack.xAtZ(dev_mean_layer_z[layer]) - dxdy * expected_layer_y;
        const auto hit_range = sector_cache.get_hit_range(expected_layer_x - xTol, expected_layer_x + xTol);

        using Downstream::DownstreamHelpers::MultiCandidateManager;
        using Downstream::DownstreamParameters::MaxNumSelectedUVhitPerRow;
        MultiCandidateManager<ushort, MaxNumSelectedUVhitPerRow, true> best_uv_hits;
        for (auto hit_idx = hit_range.x; hit_idx < hit_range.y; hit_idx++) {
          const float hit_z = hit_cache.zAtYEq0(hit_idx);

          const float expected_hit_y = exTrack.yAtZ(hit_z);
          if (hit_cache.isNotYCompatible(hit_idx, expected_hit_y, yTol)) continue;

          const float expected_hit_x = exTrack.xAtZ(hit_z);
          const float hit_x = hit_cache.xAtYEq0(hit_idx) + expected_hit_y * dxdy;

          const float xdist = expected_hit_x - hit_x;
          if (fabsf(xdist) > xTol) continue;

          // Store
          best_uv_hits.add(hit_idx, xdist);
        };

        if (!best_uv_hits.exist()) {
          output_table.score(row) = Allen::numeric_limits<float>::infinity();
          continue;
        }

        // Fill result
        const auto n_uv_hits = best_uv_hits.size();
        for (unsigned short icandidate = 0; icandidate < n_uv_hits; icandidate++) {
          output_table.uv_hit(row, layer, icandidate) = best_uv_hits.get(icandidate) + hit_cache.HitOffset();
          output_table.uv_dist(row, layer, icandidate) = best_uv_hits.score(icandidate);
        }
        for (unsigned short icandidate = n_uv_hits; icandidate < MaxNumSelectedUVhitPerRow; icandidate++) {
          output_table.uv_dist(row, layer, icandidate) = Allen::numeric_limits<float>::infinity();
        }
      }
    }
    __syncthreads();
  }

  //
  // Now we have found all possible hits for each row, we can compute best UV combination
  //
  for (unsigned short row = threadIdx.x; row < num_row_output_table; row += blockDim.x) {

    if (output_table.score(row) == Allen::numeric_limits<float>::infinity()) continue;

    // Find the best combination
    using Downstream::DownstreamHelpers::BestCandidateManager;
    BestCandidateManager<ushort2, true> best_uv_combination_manager;
    using Downstream::DownstreamParameters::MaxNumSelectedUVhitPerRow;

    for (unsigned short u1 = 0; u1 < MaxNumSelectedUVhitPerRow; u1++) {
      const auto u1_dist = output_table.uv_dist(row, 1, u1);
      if (u1_dist == Allen::numeric_limits<float>::infinity()) continue;

      for (unsigned short v2 = 0; v2 < MaxNumSelectedUVhitPerRow; v2++) {
        const auto v2_dist = output_table.uv_dist(row, 2, v2);
        if (v2_dist == Allen::numeric_limits<float>::infinity()) continue;

        best_uv_combination_manager.add({u1, v2}, u1_dist + v2_dist);
      }
    }

    const auto best_combination = best_uv_combination_manager.best();

    if (best_combination.x != 0) {
      output_table.uv_hit(row, 1) = output_table.uv_hit(row, 1, best_combination.x);
      output_table.uv_dist(row, 1) = output_table.uv_dist(row, 1, best_combination.x);
    }

    if (best_combination.y != 0) {
      output_table.uv_hit(row, 2) = output_table.uv_hit(row, 2, best_combination.y);
      output_table.uv_dist(row, 2) = output_table.uv_dist(row, 2, best_combination.y);
    }

    output_table.score(row) = output_table.x0_dist(row) * output_table.x0_dist(row) +
                              best_uv_combination_manager.score() * best_uv_combination_manager.score();
  }
  __syncthreads();
}