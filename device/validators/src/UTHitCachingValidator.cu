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
#include "UTHitCachingValidator.cuh"

#include "AverageChecker.h"
#include <boost/format.hpp>

INSTANTIATE_ALGORITHM(ut_hit_caching_test::ut_hit_caching_test_t);

void ut_hit_caching_test::ut_hit_caching_test_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_original_ut_hits_t>(arguments, first<host_accumulated_number_of_ut_hits_t>(arguments));
  set_size<dev_cached_ut_hits_t>(arguments, first<host_accumulated_number_of_ut_hits_t>(arguments));
}

void ut_hit_caching_test::ut_hit_caching_test_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  printf("Start the UT hit caching test\n");

  Allen::memset_async<dev_original_ut_hits_t>(arguments, 0, context);
  Allen::memset_async<dev_cached_ut_hits_t>(arguments, 0, context);

  // Fill ut hits into compact struct
  global_function(fill_ut_hits)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, constants.dev_unique_x_sector_layer_offsets.data(), constants.dev_ut_per_layer_info);

  // Copy result to CPU
  const auto host_original_ut_hits = make_host_buffer<dev_original_ut_hits_t>(arguments, context);
  const auto host_cached_ut_hits = make_host_buffer<dev_cached_ut_hits_t>(arguments, context);
  const auto host_ut_hit_offsets = make_host_buffer<dev_ut_hit_offsets_t>(arguments, context);
  const auto host_event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  // Get offsets
  using UT::Constants::n_layers;
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const unsigned number_of_unique_x_sectors = constants.host_unique_x_sector_layer_offsets[n_layers];
  const unsigned total_number_of_hits = host_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];

  auto& average_checker = runtime_options.checker_invoker->checker<AverageChecker>(name());

  // Accumulate counters
  for (unsigned hit_idx = 0; hit_idx < total_number_of_hits; hit_idx++) {
    const auto original = host_original_ut_hits[hit_idx];
    const auto cached = host_cached_ut_hits[hit_idx];

    const auto layer = original.layer;

    average_checker.accumulate([&original, &cached, &layer](
                                 std::map<std::string, AverageChecker::AverageAccumulator>& counters) {
      counters[(boost::format("0_Original UT Hits, xAtYEq0, layer = %1%") % layer).str()] += original.xAtYEq0;
      counters[(boost::format("0_Original UT Hits, zAtYEq0, layer = %1%") % layer).str()] += original.zAtYEq0;
      counters[(boost::format("0_Original UT Hits, yMid   , layer = %1%") % layer).str()] += original.yMid;
      counters[(boost::format("0_Original UT Hits, yMin   , layer = %1%") % layer).str()] += original.yMin;
      counters[(boost::format("0_Original UT Hits, yMax   , layer = %1%") % layer).str()] += original.yMax;
      counters[(boost::format("0_Original UT Hits, dxDy   , layer = %1%") % layer).str()] += original.dxDy;

      counters[(boost::format("1_Cached UT Hits, xAtYEq0, layer = %1%") % layer).str()] += cached.xAtYEq0;
      counters[(boost::format("1_Cached UT Hits, zAtYEq0, layer = %1%") % layer).str()] += cached.zAtYEq0;
      counters[(boost::format("1_Cached UT Hits, yMid   , layer = %1%") % layer).str()] += cached.yMid;
      counters[(boost::format("1_Cached UT Hits, yMin   , layer = %1%") % layer).str()] += cached.yMin;
      counters[(boost::format("1_Cached UT Hits, yMax   , layer = %1%") % layer).str()] += cached.yMax;
      counters[(boost::format("1_Cached UT Hits, dxDy   , layer = %1%") % layer).str()] += cached.dxDy;

      counters[(boost::format("2_Caching Bias, xAtYEq0, layer = %1%") % layer).str()] +=
        (cached.xAtYEq0 - original.xAtYEq0);
      counters[(boost::format("2_Caching Bias, zAtYEq0, layer = %1%") % layer).str()] +=
        (cached.zAtYEq0 - original.zAtYEq0);
      counters[(boost::format("2_Caching Bias, yMid   , layer = %1%") % layer).str()] += (cached.yMid - original.yMid);
      counters[(boost::format("2_Caching Bias, yMin   , layer = %1%") % layer).str()] += (cached.yMin - original.yMin);
      counters[(boost::format("2_Caching Bias, yMax   , layer = %1%") % layer).str()] += (cached.yMax - original.yMax);
      counters[(boost::format("2_Caching Bias, dxDy   , layer = %1%") % layer).str()] += (cached.dxDy - original.dxDy);
    });
  }
  for (unsigned event_idx = 0; event_idx < host_event_list.size(); event_idx++) {
    const auto event_number = host_event_list[event_idx];
    const auto nhits = host_ut_hit_offsets[(event_number + 1) * number_of_unique_x_sectors] -
                       host_ut_hit_offsets[event_number * number_of_unique_x_sectors];
    if (nhits > 0)
      average_checker.accumulate([nhits](std::map<std::string, AverageChecker::AverageAccumulator>& counters) {
        counters["3_Number of UT hits per non-empty event"] += nhits;
      });
  }
}

__global__ void ut_hit_caching_test::fill_ut_hits(
  Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const UT::Constants::PerLayerInfo* dev_mean_layer_info)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Load UT information
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Allocate the memory
  __shared__ typename UTHitCache::ElementType shared_memory_hit_caching[UTHitCache::NumElements];

  // Hit Cache
  UTHitCache hit_cache {shared_memory_hit_caching};

  for (unsigned layer = 0; layer < UT::Constants::n_layers; layer++) {
    hit_cache.cache_layer(ut_hit_offsets, ut_hits, dev_mean_layer_info, layer);
    __syncthreads();

    const auto layer_offset = ut_hit_offsets.layer_offset(layer) - event_hit_offset;
    const auto layer_number_of_hits = ut_hit_offsets.layer_number_of_hits(layer);

    for (unsigned hit_idx = threadIdx.x; hit_idx < layer_number_of_hits; hit_idx += blockDim.x) {
      MiniUTHit original, cached;

      original.yMin = ut_hits.yMin(layer_offset + hit_idx);
      original.yMax = ut_hits.yMax(layer_offset + hit_idx);
      original.yMid = ut_hits.yMid(layer_offset + hit_idx);
      original.zAtYEq0 = ut_hits.zAtYEq0(layer_offset + hit_idx);
      original.xAtYEq0 = ut_hits.xAtYEq0(layer_offset + hit_idx);
      original.dxDy = ut_hits.dxDy(layer_offset + hit_idx);
      original.layer = layer;

      const auto cached_hit = hit_cache.hit(hit_idx);

      cached.yMin = cached_hit.yMin();
      cached.yMax = cached_hit.yMax();
      cached.yMid = cached_hit.yMid();
      cached.zAtYEq0 = cached_hit.zAtYEq0();
      cached.xAtYEq0 = cached_hit.xAtYEq0();
      cached.dxDy = cached_hit.dxDy();
      cached.layer = layer;

      parameters.dev_original_ut_hits[ut_hit_offsets.layer_offset(layer) + hit_idx] = original;
      parameters.dev_cached_ut_hits[ut_hit_offsets.layer_offset(layer) + hit_idx] = cached;
    }
    __syncthreads();
  }
}