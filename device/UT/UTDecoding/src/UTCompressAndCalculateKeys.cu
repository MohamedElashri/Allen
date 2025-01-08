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
#include "UTCompressAndCalculateKeys.cuh"
#include "BinarySearch.cuh"

INSTANTIATE_ALGORITHM(ut_compress_and_calculate_keys::ut_compress_and_calculate_keys_t)

void ut_compress_and_calculate_keys::ut_compress_and_calculate_keys_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_compressed_hits_t>(
    arguments, first<host_accumulated_number_of_ut_clusters_t>(arguments) * UT::PreDecodedHits::element_size);
  set_size<dev_ut_sort_keys_t>(arguments, first<host_accumulated_number_of_ut_clusters_t>(arguments));
}

void ut_compress_and_calculate_keys::ut_compress_and_calculate_keys_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  global_function(ut_compress_and_calculate_keys)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, constants.dev_ut_geometry.data(), constants.dev_unique_x_sector_layer_offsets.data());
}

/**
 * @brief Makes an unsigned key out of a float, where
 *        float order is preserved. Unsigned order can be composed
 *        to one another as opposed to float order (sign-magnitude).
 */
__device__ uint16_t generate_sort_key(const float a)
{
  int16_t i = Allen::device::bit_cast<int16_t>(compress_float_to_16_bits(a));
  return i < 0 ? -i & uint16_t(0x7FFFu) : uint16_t(1u << 15) | (i & uint16_t(0x7FFF));
}

/**
 * @brief Makes a composed key value made out of:
 *        (u32 representation of yBegin) (u32 representation of xAtYEq0)
 */
__device__ uint64_t generate_sort_key(const float xAtYEq0, const float yBegin)
{
  auto yBegin_u = generate_sort_key(yBegin);
  auto xAtYEq0_u = generate_sort_key(xAtYEq0);
  return static_cast<uint64_t>(yBegin_u) << 48 | static_cast<uint64_t>(xAtYEq0_u) << 32;
}

__device__ uint64_t generate_sort_key(
  UTGeometry const& geometry,
  const unsigned geometry_index,
  const float num_strips,
  const uint32_t tiebreak)
{
  const float dp0diX = geometry.dp0diX[geometry_index];
  const float dp0diY = geometry.dp0diY[geometry_index];
  const float p0X = geometry.p0X[geometry_index];
  const float p0Y = geometry.p0Y[geometry_index];

  const float xAtYEq0 = p0X + num_strips * dp0diX;
  const float yBegin = p0Y + num_strips * dp0diY;

  const uint64_t key = generate_sort_key(xAtYEq0, yBegin);
  return key | tiebreak; // with index for stable sort
}

__global__ void ut_compress_and_calculate_keys::ut_compress_and_calculate_keys(
  ut_compress_and_calculate_keys::Parameters parameters,
  const char* ut_geometry,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];

  const uint32_t* hit_offsets = parameters.dev_ut_hit_offsets + event_number * number_of_unique_x_sectors;
  const uint32_t* cluster_offsets = parameters.dev_ut_cluster_offsets + event_number * number_of_unique_x_sectors;
  const unsigned number_of_clusters = cluster_offsets[number_of_unique_x_sectors] - cluster_offsets[0];

  // Use the output LHCbIDs to temporarily store compressed index
  UT::PreDecodedHits ut_compressed_hits {
    parameters.dev_ut_compressed_hits,
    parameters.dev_ut_cluster_offsets[number_of_events * number_of_unique_x_sectors]};

  // Binary search for compressed offset
  for (unsigned hit_index = threadIdx.x; hit_index < number_of_clusters; hit_index += blockDim.x) {
    // Do a rightmost search to find sector group
    const unsigned compressed_index = cluster_offsets[0] + hit_index;
    const int group = binary_search_rightmost(cluster_offsets, number_of_unique_x_sectors, compressed_index);
    const unsigned hit_index_in_group = compressed_index - cluster_offsets[group];
    const unsigned uncompressed_index = hit_offsets[group] + hit_index_in_group;
    ut_compressed_hits.id(compressed_index) = uncompressed_index;
  }

  __syncthreads();

  const unsigned event_offset = cluster_offsets[0];
  const UTGeometry geometry(ut_geometry);

  UT::ConstPreDecodedHits ut_uncompressed_hits {
    parameters.dev_ut_uncompressed_hits, parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};
  uint64_t* sort_keys = parameters.dev_ut_sort_keys;

  for (unsigned hit_index = threadIdx.x; hit_index < number_of_clusters; hit_index += blockDim.x) {
    const unsigned compressed_index = event_offset + hit_index;
    const unsigned uncompressed_index = ut_compressed_hits.id(compressed_index);

    const unsigned geometry_index = ut_uncompressed_hits.geometry_index(uncompressed_index);
    const float num_strips = ut_uncompressed_hits.num_strips(uncompressed_index);

    ut_compressed_hits.geometry_index(compressed_index) = geometry_index;
    ut_compressed_hits.id(compressed_index) = ut_uncompressed_hits.id(uncompressed_index);
    ut_compressed_hits.num_strips(compressed_index) = num_strips;

    const uint32_t tiebreak = parameters.dev_ut_tiebreak[uncompressed_index];
    sort_keys[compressed_index] = generate_sort_key(geometry, geometry_index, num_strips, tiebreak);
  }
}
