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
#include <UTDecodingHitClustering.cuh>
#include <PrefixSum.cuh>
#include <SegSort.h>
#include <UTUniqueID.cuh>

INSTANTIATE_ALGORITHM(ut_decoding_hit_clustering::ut_decoding_hit_clustering_t)

void ut_decoding_hit_clustering::ut_decoding_hit_clustering_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto num_hits = first<host_total_number_of_ut_hits_t>(arguments);
  const auto num_events = first<host_number_of_events_t>(arguments);
  const auto n_groups = UT::Constants::n_groups;

  // Temporally memory
  set_size<dev_ut_hits_clustering_end_mask_t>(arguments, num_hits + 1);

  // Output
  set_size<dev_ut_clusters_sector_group_offsets_t>(arguments, num_events * n_groups + 1);
  set_size<dev_ut_all_clusters_t>(arguments, num_hits);
  set_size<host_ut_num_clusters_t>(arguments, 1);
}

void ut_decoding_hit_clustering::ut_decoding_hit_clustering_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto num_hits = first<host_total_number_of_ut_hits_t>(arguments);

  // If there's not any UT hit, we should skip it
  if (num_hits == 0) {
    Allen::memset_async<dev_ut_clusters_sector_group_offsets_t>(arguments, 0, context);
    Allen::memset_async<host_ut_num_clusters_t>(arguments, 0, context);
    return;
  }

  // Bank dependent info
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  //
  // Main logic
  //
  if (!m_cluster_ut_hits || bank_version == 3) // Avoid clustering for old rawbanks
  {
    resize<dev_ut_cluster_keys_t>(arguments, num_hits);
    resize<dev_ut_all_clusters_t>(arguments, 0);
    resize<dev_ut_clusters_t>(arguments, num_hits);
    resize<dev_ut_clusters_permutations_t>(arguments, num_hits);
    //
    // Fill offsets
    //
    Allen::memset_async<dev_ut_clusters_sector_group_offsets_t>(arguments, 0, context);
    global_function(ut_decoding_no_clustering_fill_offsets)(
      dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
      arguments, constants.dev_ut_board_to_sector_group_map.data());
    PrefixSum::prefix_sum<dev_ut_clusters_sector_group_offsets_t>(*this, arguments, context);
    *data<host_ut_num_clusters_t>(arguments) = num_hits;

    //
    // Fill outputs
    //
    auto global_func = bank_version == 4 ? global_function(ut_decoding_no_clustering_fill<4>) :
                                           global_function(ut_decoding_no_clustering_fill<3>);

    global_func(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_geometry.data(),
      constants.dev_ut_board_to_sector_group_map.data(),
      constants.dev_ut_board_geometry_map.data());
  }
  else {
    //
    // Define the clustering ranges
    //
    {
      constexpr unsigned MaxSize = 2048;
      const auto nblocks = (num_hits + MaxSize - 1) / MaxSize;
      Allen::memset_async<dev_ut_hits_clustering_end_mask_t>(arguments, 0, context);
      global_function(ut_decoding_clustering_fill_mask<MaxSize>)(dim3(nblocks), dim3(256), context)(
        arguments, num_hits);
      // print<dev_ut_hits_clustering_end_mask_t>(arguments);
      PrefixSum::prefix_sum<dev_ut_hits_clustering_end_mask_t, host_ut_num_clusters_t>(*this, arguments, context);
    }
    auto num_clusters = first<host_ut_num_clusters_t>(arguments);
    resize<dev_ut_hits_clustering_hit_offsets_t>(arguments, num_clusters + 1);
    {
      const auto max_size = num_hits + 1;
      constexpr unsigned MaxSize = 2048;
      const auto nblocks = (max_size + MaxSize - 1) / MaxSize;
      Allen::memset_async<dev_ut_hits_clustering_hit_offsets_t>(arguments, 0, context);
      global_function(ut_decoding_clustering_make_hit_offsets<MaxSize>)(dim3(nblocks), dim3(256), context)(
        arguments, max_size);
    }
    //
    // Perform clustering
    //
    {
      Allen::memset_async<dev_ut_clusters_sector_group_offsets_t>(arguments, 0, context);
      global_function(ut_decoding_clustering)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
        arguments,
        constants.dev_ut_board_to_sector_group_map.data(),
        m_save_clusters_above_max,
        m_max_cluster_size,
        (bank_version == 3) ? int(UT::Decoding::PositionMethod::GeoWeighting) : m_position_method);
      PrefixSum::prefix_sum<dev_ut_clusters_sector_group_offsets_t, host_ut_num_clusters_t>(*this, arguments, context);
    }
    //
    // Consolidate
    //
    resize<dev_ut_cluster_keys_t>(arguments, num_clusters);
    resize<dev_ut_clusters_t>(arguments, num_clusters);
    resize<dev_ut_clusters_permutations_t>(arguments, num_clusters);
    {
      auto global_func = bank_version == 4 ? global_function(ut_decoding_consolidate_clusters<4>) :
                                             global_function(ut_decoding_consolidate_clusters<3>);

      global_func(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
        arguments,
        constants.dev_ut_boards.data(),
        constants.dev_ut_geometry.data(),
        constants.dev_ut_board_to_sector_group_map.data(),
        constants.dev_ut_board_geometry_map.data());
    }
  }
  //
  // Sort
  //
  {
    SegSort::segsort(
      *this,
      arguments,
      context,
      data<dev_ut_cluster_keys_t>(arguments),
      data<dev_ut_clusters_sector_group_offsets_t>(arguments),
      size<dev_ut_clusters_sector_group_offsets_t>(arguments) - 1,
      data<dev_ut_clusters_permutations_t>(arguments));
  }
}

template<unsigned N>
__global__ void ut_decoding_hit_clustering::ut_decoding_clustering_fill_mask(Parameters parameters, unsigned num_hits)
{
  const auto offset = N * blockIdx.x;
  const auto size = std::min(num_hits - offset, N);

  // Alias
  using UTDecoding::UTStripInfo;
  const auto id = parameters.dev_ut_hits_strip_info.data();

  for (unsigned i = threadIdx.x; i < size; i += blockDim.x) {
    const auto h = offset + i;

    const auto last_hit = (h + 1) == num_hits;

    const auto is_end =
      last_hit ? true : ((UTStripInfo(id[h]).signed_strip_id() + 1) != UTStripInfo(id[h + 1]).signed_strip_id());

    parameters.dev_ut_hits_clustering_end_mask[h] = is_end;
  }
}

template<unsigned N>
__global__ void ut_decoding_hit_clustering::ut_decoding_clustering_make_hit_offsets(
  Parameters parameters,
  unsigned max_size)
{
  const auto offset = N * blockIdx.x;
  const auto size = std::min(max_size - offset, N);

  // Alias
  const auto id = parameters.dev_ut_hits_clustering_end_mask.data();

  for (unsigned i = threadIdx.x; i < size; i += blockDim.x) {
    const auto h = offset + i;

    const auto start_of_cluster = (h == 0) || (id[h - 1] != id[h]);
    if (start_of_cluster) {
      parameters.dev_ut_hits_clustering_hit_offsets[id[h]] = h;
    }
  }
}

__global__ void ut_decoding_hit_clustering::ut_decoding_clustering(
  Parameters parameters,
  const uint8_t* board_to_sector_group_map,
  bool save_clusters_above_max,
  unsigned max_cluster_size,
  int position_method)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Alias
  using UTDecoding::PredecodeHitInfo;
  using UTDecoding::UTClusterInfo;
  using UTDecoding::UTStripInfo;

  // Offsets
  using UT::Constants::n_groups;
  const auto predecoded_offset = parameters.dev_ut_predecoded_event_offsets[event_number];
  const auto predecoded_end = parameters.dev_ut_predecoded_event_offsets[event_number + 1];
  const auto cluster_offset = parameters.dev_ut_hits_clustering_end_mask[predecoded_offset];
  const auto num_cluster = parameters.dev_ut_hits_clustering_end_mask[predecoded_end] - cluster_offset;

  __shared__ unsigned event_counter;
  if (threadIdx.x == 0) {
    event_counter = 0;
  }
  __syncthreads();

  // Output
  auto output_counter = parameters.dev_ut_clusters_sector_group_offsets + n_groups * event_number;

  for (unsigned cluster_idx = threadIdx.x; cluster_idx < num_cluster; cluster_idx += blockDim.x) {
    const auto cluster_number = cluster_offset + cluster_idx;
    const auto hit_offset = parameters.dev_ut_hits_clustering_hit_offsets[cluster_number];
    const auto num_hits = parameters.dev_ut_hits_clustering_hit_offsets[cluster_number + 1] - hit_offset;

    // Skip if we want to drop cluster above max size
    if ((!save_clusters_above_max) && (num_hits > max_cluster_size)) continue;

    // Otherwise we only consider the size up to max (same behaviour like HLT2)
    const auto max_num_hits = min(max_cluster_size, num_hits);

    // Input
    const auto hits_strip_info = parameters.dev_ut_hits_strip_info + hit_offset;
    const auto predecoded_hits = parameters.dev_ut_predecoded_hits + hit_offset;

    // Start
    float mean_strip;
    unsigned strip_id;
    if (position_method == int(UT::Decoding::PositionMethod::AdcWeighting)) {
      unsigned sum_weight = 0;
      unsigned sum_position = 0;
      for (unsigned i = 0; i < max_num_hits; i++) {
        UTStripInfo strip_info(hits_strip_info[i]);
        sum_position += strip_info.strip_id() * strip_info.adc_count();
        sum_weight += strip_info.adc_count();
      }
      if (sum_weight == 0) continue; // Remove the zero adc_count
      mean_strip = 1.f * sum_position / sum_weight;
      strip_id = (sum_position * 2 + sum_weight) / 2 / sum_weight;
    }
    else {
      unsigned sum_position = 0;
      for (unsigned i = 0; i < max_num_hits; i++) {
        UTStripInfo strip_info(hits_strip_info[i]);
        sum_position += strip_info.strip_id();
      }
      mean_strip = 1.f * sum_position / max_num_hits;
      strip_id = (sum_position * 2 + max_num_hits) / 2 / max_num_hits;
    }

    // Fill cluster
    const auto hit_idx = strip_id - UTStripInfo(hits_strip_info[0]).strip_id();
    PredecodeHitInfo predecoded {predecoded_hits[hit_idx]};
    const auto sector_group = board_to_sector_group_map[predecoded.board_idx()];
    atomicAdd(output_counter + sector_group, 1u);
    const auto idx = atomicAdd(&event_counter, 1u);
    parameters.dev_ut_all_clusters[predecoded_offset + idx] = UTClusterInfo(predecoded.data, mean_strip).data;
  }
}

template<unsigned version>
__global__ void ut_decoding_hit_clustering::ut_decoding_consolidate_clusters(
  Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const uint8_t* board_to_sector_group_map,
  const uint16_t* board_to_geometry_map)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Useful information
  const UTGeometry geometry(ut_geometry);
  const UTBoards boards(ut_boards);

  // Alias
  using UTDecoding::UTClusterInfo;
  using UTDecoding::UTClusterKeyInfo;

  // Offsets
  using UT::Constants::n_groups;
  const auto input_offset = parameters.dev_ut_predecoded_event_offsets[event_number];
  const auto output_offsets = parameters.dev_ut_clusters_sector_group_offsets + n_groups * event_number;
  const auto input_size = output_offsets[n_groups] - output_offsets[0];

  // Event level counter
  __shared__ unsigned sector_counter[n_groups];
  for (unsigned i = threadIdx.x; i < n_groups; i += blockDim.x) {
    sector_counter[i] = 0;
  }
  __syncthreads();

  // Input
  const auto input_clusters = parameters.dev_ut_all_clusters + input_offset;

  // Input
  for (unsigned cluster_idx = threadIdx.x; cluster_idx < input_size; cluster_idx += blockDim.x) {
    UTClusterInfo cluster {input_clusters[cluster_idx]};
    const auto board_idx = cluster.board_idx();
    const auto mean_strip = cluster.mean_strip();
    const auto word = cluster.word();

    // Get advance info
    const auto sector_group = board_to_sector_group_map[board_idx];
    const auto geometry_idx = board_to_geometry_map[board_idx];
    const auto output_offset = output_offsets[sector_group];

    uint64_t sort_key;

    if constexpr (version == 4) {
      const uint32_t chanID = boards.chanIDs[board_idx];
      const uint32_t fullSectorID = chanID & 0xFFFFFE00;
      // chanID will include a subsector bit at the 9th position
      // stripID can range from [0, 511]
      // If stripID is between [256, 511], the bit on the 9th position will be 1
      // But so would the chanID subsector bit (9th bit)
      // To calculate LHCbID, we have to mask the last 9 bits from channelID to get full sector ID
      // This is so that the last 9 bits can be reserved for UT sector stripID
      const float p0Z = geometry.p0Z[geometry_idx];
      // we need to know whether or not a "stripflip" canges the numbering
      const auto num_strips = p0Z < 0 ? UT::Decoding::v5::strips_per_hybrid - mean_strip : mean_strip;
      // compute position
      const float dp0diX = geometry.dp0diX[geometry_idx];
      const float p0X = geometry.p0X[geometry_idx];
      const float xAtYEq0 = p0X + num_strips * dp0diX;
      // compute strip id
      const uint16_t stripID = (word & UT::Decoding::v5::strip_mask) >> UT::Decoding::v5::strip_offset;
      // compute ut id
      const uint32_t ut_id = fullSectorID + stripID;
      // save it
      sort_key = UTClusterKeyInfo(xAtYEq0, ut_id).data;
    }
    else {
      const uint32_t chanID = boards.chanIDs[board_idx];
      const uint32_t m_nStripsPerHybrid =
        boards.stripsPerHybrids[board_idx / UT::Decoding::ut_number_of_sectors_per_board];
      const uint32_t fracStrip = (word & UT::Decoding::v4::frac_mask) >> UT::Decoding::v4::frac_offset;
      const uint32_t channelID = (word & UT::Decoding::v4::chan_mask) >> UT::Decoding::v4::chan_offset;
      // Calculate the relative index of the corresponding board
      const uint32_t index = channelID / m_nStripsPerHybrid;
      const uint32_t stripID = channelID - (index * m_nStripsPerHybrid) + 1;
      const uint32_t firstStrip = geometry.firstStrip[geometry_idx];
      const float num_strips = 0.25f * fracStrip + stripID - firstStrip;
      // compute position
      const float dp0diX = geometry.dp0diX[geometry_idx];
      const float p0X = geometry.p0X[geometry_idx];
      const float xAtYEq0 = p0X + num_strips * dp0diX;
      // compute UT id
      const uint32_t ut_id = (chanID + stripID - 1);
      // save it
      sort_key = UTClusterKeyInfo(xAtYEq0, ut_id).data;
    }

    // Fill output
    const auto idx = atomicAdd(sector_counter + sector_group, 1u);
    parameters.dev_ut_clusters[output_offset + idx] = cluster.data;
    parameters.dev_ut_cluster_keys[output_offset + idx] = sort_key;
  }
}

__global__ void ut_decoding_hit_clustering::ut_decoding_no_clustering_fill_offsets(
  Parameters parameters,
  const uint8_t* board_to_sector_group_map)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Alias
  using UTDecoding::PredecodeHitInfo;
  using UTDecoding::UTClusterInfo;
  using UTDecoding::UTStripInfo;

  // Offsets
  using UT::Constants::n_groups;
  const auto predecoded_offset = parameters.dev_ut_predecoded_event_offsets[event_number];
  const auto predecoded_end = parameters.dev_ut_predecoded_event_offsets[event_number + 1];
  const auto number_of_predecoded = predecoded_end - predecoded_offset;

  // Inputs
  const auto predecoded_hits = parameters.dev_ut_predecoded_hits + predecoded_offset;

  // Outputs
  auto sector_group_offsets = parameters.dev_ut_clusters_sector_group_offsets + n_groups * event_number;

  // Fill offsets
  for (unsigned hit_idx = threadIdx.x; hit_idx < number_of_predecoded; hit_idx += blockDim.x) {
    PredecodeHitInfo predecoded {predecoded_hits[hit_idx]};
    const auto sector_group = board_to_sector_group_map[predecoded.board_idx()];
    atomicAdd(sector_group_offsets + sector_group, 1u);
  }
}

template<unsigned version>
__global__ void ut_decoding_hit_clustering::ut_decoding_no_clustering_fill(
  Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const uint8_t* board_to_sector_group_map,
  const uint16_t* board_to_geometry_map)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Useful information
  const UTGeometry geometry(ut_geometry);
  const UTBoards boards(ut_boards);

  // Alias
  using UTDecoding::PredecodeHitInfo;
  using UTDecoding::UTClusterInfo;
  using UTDecoding::UTClusterKeyInfo;
  using UTDecoding::UTStripInfo;

  // Offsets
  using UT::Constants::n_groups;
  const auto predecoded_offset = parameters.dev_ut_predecoded_event_offsets[event_number];
  const auto predecoded_end = parameters.dev_ut_predecoded_event_offsets[event_number + 1];
  const auto number_of_predecoded = predecoded_end - predecoded_offset;
  const auto sector_group_offsets = parameters.dev_ut_clusters_sector_group_offsets + n_groups * event_number;

  // Inputs
  const auto hits_strip_info = parameters.dev_ut_hits_strip_info + predecoded_offset;
  const auto predecoded_hits = parameters.dev_ut_predecoded_hits + predecoded_offset;

  // Outputs
  // const auto output_clusters = parameters.dev_ut_clusters

  // Event level counter
  __shared__ unsigned sector_counter[n_groups];
  for (unsigned i = threadIdx.x; i < n_groups; i += blockDim.x) {
    sector_counter[i] = 0;
  }
  __syncthreads();

  // Fill offsets
  for (unsigned hit_idx = threadIdx.x; hit_idx < number_of_predecoded; hit_idx += blockDim.x) {

    // Input
    UTStripInfo strip_info(hits_strip_info[hit_idx]);
    PredecodeHitInfo predecoded {predecoded_hits[hit_idx]};

    const auto board_idx = predecoded.board_idx();
    const auto mean_strip = strip_info.strip_id();
    const auto word = predecoded.word();

    const auto sector_group = board_to_sector_group_map[board_idx];
    const auto geometry_idx = board_to_geometry_map[board_idx];

    // Fetch offset
    const auto output_offset = sector_group_offsets[sector_group];

    // Compute sort key
    uint64_t sort_key;
    if constexpr (version == 4) {
      const uint32_t chanID = boards.chanIDs[board_idx];
      const uint32_t fullSectorID = chanID & 0xFFFFFE00;
      // chanID will include a subsector bit at the 9th position
      // stripID can range from [0, 511]
      // If stripID is between [256, 511], the bit on the 9th position will be 1
      // But so would the chanID subsector bit (9th bit)
      // To calculate LHCbID, we have to mask the last 9 bits from channelID to get full sector ID
      // This is so that the last 9 bits can be reserved for UT sector stripID
      const float p0Z = geometry.p0Z[geometry_idx];
      // we need to know whether or not a "stripflip" canges the numbering
      const auto num_strips = p0Z < 0 ? UT::Decoding::v5::strips_per_hybrid - mean_strip : mean_strip;
      // compute position
      const float dp0diX = geometry.dp0diX[geometry_idx];
      const float p0X = geometry.p0X[geometry_idx];
      const float xAtYEq0 = p0X + num_strips * dp0diX;
      // compute strip id
      const uint16_t stripID = (word & UT::Decoding::v5::strip_mask) >> UT::Decoding::v5::strip_offset;
      // compute ut id
      const uint32_t ut_id = fullSectorID + stripID;
      // save it
      sort_key = UTClusterKeyInfo(xAtYEq0, ut_id).data;
    }
    else {
      const uint32_t chanID = boards.chanIDs[board_idx];
      const uint32_t m_nStripsPerHybrid =
        boards.stripsPerHybrids[board_idx / UT::Decoding::ut_number_of_sectors_per_board];
      const uint32_t fracStrip = (word & UT::Decoding::v4::frac_mask) >> UT::Decoding::v4::frac_offset;
      const uint32_t channelID = (word & UT::Decoding::v4::chan_mask) >> UT::Decoding::v4::chan_offset;
      // Calculate the relative index of the corresponding board
      const uint32_t index = channelID / m_nStripsPerHybrid;
      const uint32_t stripID = channelID - (index * m_nStripsPerHybrid) + 1;
      const uint32_t firstStrip = geometry.firstStrip[geometry_idx];
      const float num_strips = 0.25f * fracStrip + stripID - firstStrip;
      // compute position
      const float dp0diX = geometry.dp0diX[geometry_idx];
      const float p0X = geometry.p0X[geometry_idx];
      const float xAtYEq0 = p0X + num_strips * dp0diX;
      // compute UT id
      const uint32_t ut_id = (chanID + stripID - 1);
      // save it
      sort_key = UTClusterKeyInfo(xAtYEq0, ut_id).data;
    }

    // Fill output
    const auto idx = atomicAdd(sector_counter + sector_group, 1u);
    parameters.dev_ut_clusters[output_offset + idx] = UTDecoding::UTClusterInfo(predecoded.data, mean_strip).data;
    parameters.dev_ut_cluster_keys[output_offset + idx] = sort_key;
  }
}