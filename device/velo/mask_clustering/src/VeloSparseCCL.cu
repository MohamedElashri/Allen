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

#include <VeloSparseCCL.cuh>
#include <VeloTools.cuh>
#include <PrefixSum.cuh>
#include <SegSort.h>

INSTANTIATE_ALGORITHM(velo_sparse_ccl::velo_sparse_ccl_t)

// Biggest cluster possible is the size of the sensor (768x256)
// * max sum_x = 256*sum(1...768) = 75 399 168 < 2^27
// * max_sum_y = 768*sum(1...256) = 25 067 520 < 2^25
// * max_n = 196 608 < 2^18
// 18+27+25 = 70 almost fit in a 64 bit word, removing 2 bit per feature
// still allows for fairly large maximum clusters, and overflow would only
// cause loss of precision
// * sum_x : 25 bits
// * sum_y : 23 bits
// * n : 16 bits

inline constexpr uint64_t encode_cluster_features(uint64_t sum_x, uint64_t sum_y, unsigned n)
{
  return (sum_x << 39) | (sum_y << 16) | n;
}

inline constexpr void decode_cluster_features(uint64_t features, unsigned& sum_x, unsigned& sum_y, unsigned& n)
{
  sum_x = features >> 39;
  sum_y = (features >> 16) & ((1 << 23) - 1);
  n = features & 0xFFFF;
}

inline __device__ unsigned find(const unsigned* labels, unsigned l)
{
  unsigned a = l;
  do {
    l = a;
    a = labels[l];
  } while (a != l);
  return a;
}

inline __device__ void swap(unsigned& l1, unsigned& l2)
{
  unsigned l3 = l1;
  l1 = l2;
  l2 = l3;
}

inline __device__ unsigned merge(unsigned* labels, unsigned l1, unsigned l2, uint64_t* features)
{
  l1 = find(labels, l1);
  l2 = find(labels, l2);
  __threadfence();
  while (l1 != l2) {
    if (l2 < l1) swap(l1, l2);
    unsigned l3 = atomicMin(&labels[l2], l1);
    __threadfence();
    // uint64_t is defined as unsigned long in 64bit mode..
    // therfore we need to cast, even if the type is the same
    auto f = atomicExch((unsigned long long*) &features[l2], 0llu);
    atomicAdd((unsigned long long*) &features[l1], f);
    __threadfence();
    if (l3 == l2) break;
    l2 = l3;
  }
  unsigned a = find(labels, l1);
  __threadfence();
  while (a != l1) {
    auto f = atomicExch((unsigned long long*) &features[l1], 0llu);
    atomicAdd((unsigned long long*) &features[a], f);
    __threadfence();
    l1 = a;
    a = find(labels, l1);
    __threadfence();
  }
  return a;
}

//=============================================================================
// Link Horizontal : test if there is a link between two horizontal adjacent SP
// 0 1 2 3 | 0 1 2 3
// 4 5 6 7 | 4 5 6 7
//=============================================================================
inline constexpr auto linkH(uint8_t l, uint8_t r) { return (l & 0x88) && (r & 0x11); }

//=============================================================================
// Link Diagonal Forward : test if there is a link between two SW-NE adjacent
// SP
//         | 0 1 2 3
//         | 4 5 6 7
// --------|--------
// 0 1 2 3 |
// 4 5 6 7 |
//=============================================================================
inline constexpr auto linkDF(uint8_t sw, uint8_t ne) { return (sw & 0x08) && (ne & 0x10); }

//=============================================================================
// Link Diagonal Backward : test if there is a link between two NW-SE adjacent
// SP
// 0 1 2 3 |
// 4 5 6 7 |
// --------|--------
//         | 0 1 2 3
//         | 4 5 6 7
//=============================================================================
inline constexpr auto linkDB(uint8_t nw, uint8_t se) { return (nw & 0x80) && (se & 0x01); }

//=============================================================================
// Link Vertical : test if there is a link between two vertical adjacent SP
// 0 1 2 3
// 4 5 6 7
// -------
// 0 1 2 3
// 4 5 6 7
//=============================================================================
inline constexpr auto linkV(uint8_t b, uint8_t t)
{
  return ((b & 0x10) && (t & (0x01 | 0x02))) || ((b & 0x20) && (t & (0x01 | 0x02 | 0x04))) ||
         ((b & 0x40) && (t & (0x02 | 0x04 | 0x08))) || ((b & 0x80) && (t & (0x04 | 0x08)));
}

inline __device__ bool is_adjacent(int xi, int yi, int xj, int yj, int spi, int spj)
{
  if (xi == xj) {
    if (yi == yj + 1) return linkH(spj, spi);
  }
  else if (xi == xj + 1) {
    if (yi == yj)
      return linkV(spj, spi);
    else if (yi == yj - 1)
      return linkDF(spi, spj);
    else if (yi == yj + 1)
      return linkDB(spj, spi);
  }
  return false;
}

__global__ void velo_run_ccl(velo_sparse_ccl::Parameters parameters, unsigned n_sp)
{
  unsigned* labels = parameters.dev_labels;
  uint64_t* features = parameters.dev_pixels_features;
  const unsigned* superpixels = parameters.dev_superpixels;

  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i < n_sp; i += blockDim.x * gridDim.x) {
    auto sp_word0 = superpixels[i];
    int sp_sensor0 = sp_word0 >> 24;
    int sp_col0 = (sp_word0 >> 14) & 0x1FF;
    int sp_row0 = (sp_word0 >> 8) & 0x3F;
    int sp0 = sp_word0 & 0xFF;

    unsigned ai = i;

    for (int j = i - 1; j >= 0; j--) {
      auto sp_word1 = superpixels[j];
      int sp_sensor1 = sp_word1 >> 24;
      int sp_col1 = (sp_word1 >> 14) & 0x1FF;
      int sp_row1 = (sp_word1 >> 8) & 0x3F;
      int sp1 = sp_word1 & 0xFF;

      if (sp_col0 - 1 > sp_col1 || sp_sensor0 != sp_sensor1) break;

      if (is_adjacent(sp_col0, sp_row0, sp_col1, sp_row1, sp0, sp1)) {
        ai = merge(labels, ai, j, features);
      }
    }
  }
}

__global__ void velo_init_ccl(velo_sparse_ccl::Parameters parameters, const unsigned n_superpixels)
{
  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i < n_superpixels; i += blockDim.x * gridDim.x) {
    auto sp_word = parameters.dev_superpixels[i];
    auto sp = sp_word & 0xFF;
    auto sp_col = (sp_word >> 14) & 0x1FF;
    auto sp_row = (sp_word >> 8) & 0x3F;

    auto kx = __popc(sp & 0xF0);
    auto ky = __popc(sp & 0xEE) + __popc(sp & 0xCC) + __popc(sp & 0x88);
    auto n = __popc(sp);

    parameters.dev_labels[i] = i;
    parameters.dev_pixels_features[i] = encode_cluster_features(sp_col * n * 2 + kx, sp_row * n * 4 + ky, n);
  }
}

__global__ void velo_count_clusters_ccl(velo_sparse_ccl::Parameters parameters)
{
  constexpr auto n_sensors_per_module_pair = Velo::Constants::n_sensors_per_module * 2;
  unsigned module_pair = blockIdx.x;

  unsigned start_offset = parameters.dev_superpixels_offsets[module_pair * n_sensors_per_module_pair];
  unsigned n_superpixels =
    parameters.dev_superpixels_offsets[(module_pair + 1) * n_sensors_per_module_pair] - start_offset;

  for (unsigned i = threadIdx.x; i < n_superpixels; i += blockDim.x) {
    unsigned cluster_index = start_offset + i;
    if (parameters.dev_labels[cluster_index] == cluster_index) { // cluster root
      atomicAdd(&parameters.dev_module_pair_cluster_num[module_pair], 1);
      atomicAdd(&parameters.dev_module_pair_cluster_offset[module_pair], 1);
    }
  }
}

__global__ void velo_decode_ccl(
  velo_sparse_ccl::Parameters parameters,
  const unsigned number_of_events,
  const VeloGeometry* dev_velo_geometry)
{
  constexpr auto n_sensors_per_module_pair = Velo::Constants::n_sensors_per_module * 2;

  __shared__ unsigned atomic_index;
  if (threadIdx.x == 0) atomic_index = 0;

  __syncthreads();

  unsigned start_offset = parameters.dev_superpixels_offsets[blockIdx.x * n_sensors_per_module_pair];
  unsigned n_superpixels =
    parameters.dev_superpixels_offsets[(blockIdx.x + 1) * n_sensors_per_module_pair] - start_offset;
  const unsigned out_start_offset = parameters.dev_module_pair_cluster_offset[blockIdx.x];

  const unsigned number_of_clusters =
    parameters.dev_module_pair_cluster_offset[Velo::Constants::n_module_pairs * number_of_events];
  auto velo_cluster_container = Velo::Clusters {parameters.dev_velo_cluster_container, number_of_clusters};
  if (blockIdx.x < number_of_events && threadIdx.x == 0) { // TODO: this is useless, get rid of this container
    parameters.dev_velo_clusters[blockIdx.x] = velo_cluster_container;
  }

  int64_t* sort_keys = parameters.dev_hit_sorting_key;

  for (unsigned i = threadIdx.x; i < n_superpixels; i += blockDim.x) {
    unsigned cluster_index = start_offset + i;
    if (parameters.dev_labels[cluster_index] == cluster_index) { // cluster root
      const unsigned sensor_number = parameters.dev_superpixels[cluster_index] >> 24;

      const float* ltg = dev_velo_geometry->ltg + dev_velo_geometry->n_trans * sensor_number;

      unsigned out_index = out_start_offset + atomicAdd(&atomic_index, 1);

      unsigned x, y, n;
      decode_cluster_features(parameters.dev_pixels_features[cluster_index], x, y, n);

      const unsigned cx = x / n;
      const unsigned cy = y / n;

      const float fx = x / static_cast<float>(n) - cx;
      const float fy = y / static_cast<float>(n) - cy;

      // store target (3D point for tracking)
      const uint32_t chip = cx >> VP::ChipColumns_division;
      const unsigned cid = get_channel_id(sensor_number, chip, cx & VP::ChipColumns_mask, cy);

      const float local_x = dev_velo_geometry->local_x[cx] + fx * dev_velo_geometry->x_pitch[cx];
      const float local_y = (cy + 0.5f + fy) * Velo::Constants::pixel_size;

      const float gx = ltg[0] * local_x + ltg[1] * local_y + ltg[9];
      const float gy = ltg[3] * local_x + ltg[4] * local_y + ltg[10];
      const float gz = ltg[6] * local_x + ltg[7] * local_y + ltg[11];

      const auto id = get_lhcb_id(cid);
      const auto phi = hit_phi_16(gx, gy);

      velo_cluster_container.set_id(out_index, id);
      velo_cluster_container.set_x(out_index, gx);
      velo_cluster_container.set_y(out_index, gy);
      velo_cluster_container.set_z(out_index, gz);
      velo_cluster_container.set_phi(out_index, phi);
      sort_keys[out_index] = (static_cast<int64_t>(phi) << 48) | id;
    }
  }
}

__global__ void velo_apply_sort_permutation(velo_sparse_ccl::Parameters parameters, const unsigned number_of_events)
{
  const unsigned n_hits = parameters.dev_module_pair_cluster_offset[Velo::Constants::n_module_pairs * number_of_events];

  const auto velo_cluster_container = Velo::Clusters {parameters.dev_velo_cluster_container, n_hits};
  auto velo_sorted_cluster_container = Velo::Clusters {parameters.dev_sorted_velo_cluster_container, n_hits};

  // Sort by phi
  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i < n_hits; i += gridDim.x * blockDim.x) {
    const auto hit_index_global = parameters.dev_hit_permutation[i];
    velo_sorted_cluster_container.set_id(i, velo_cluster_container.id(hit_index_global));
    velo_sorted_cluster_container.set_phi(i, velo_cluster_container.phi(hit_index_global));
    velo_sorted_cluster_container.set_x(i, velo_cluster_container.x(hit_index_global));
    velo_sorted_cluster_container.set_y(i, velo_cluster_container.y(hit_index_global));
    velo_sorted_cluster_container.set_z(i, velo_cluster_container.z(hit_index_global));
  }
}

void velo_sparse_ccl::velo_sparse_ccl_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_module_pair_cluster_num_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs);
  set_size<dev_module_pair_cluster_offset_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs + 1);
  set_size<host_total_number_of_clusters_t>(arguments, 1);

  set_size<dev_velo_cluster_container_t>(arguments, 1);        // will be resized
  set_size<dev_sorted_velo_cluster_container_t>(arguments, 1); // will be resized
  set_size<dev_hit_permutation_t>(arguments, 1);               // will be resized
  set_size<dev_hit_sorting_key_t>(arguments, 1);               // will be resized
  set_size<dev_velo_clusters_t>(arguments, first<host_number_of_events_t>(arguments));

  set_size<dev_labels_t>(arguments, first<host_total_number_of_superpixels_t>(arguments));
  set_size<dev_pixels_features_t>(arguments, first<host_total_number_of_superpixels_t>(arguments));
}

void velo_sparse_ccl::velo_sparse_ccl_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_module_pair_cluster_num_t>(arguments, 0, context);
  Allen::memset_async<dev_module_pair_cluster_offset_t>(arguments, 0, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) { // no VP banks present in data
    Allen::memset_async<host_total_number_of_clusters_t>(arguments, 0, context);
    return;
  }

  // init
  global_function(velo_init_ccl)(
    dim3((first<host_total_number_of_superpixels_t>(arguments) + 255) / 256), dim3(256), context)(
    arguments, first<host_total_number_of_superpixels_t>(arguments));

  // ccl
  global_function(velo_run_ccl)(
    dim3((first<host_total_number_of_superpixels_t>(arguments) + 255) / 256), dim3(256), context)(
    arguments, first<host_total_number_of_superpixels_t>(arguments));

  // count
  global_function(velo_count_clusters_ccl)(
    dim3(first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs), dim3(128), context)(arguments);
  PrefixSum::prefix_sum<dev_module_pair_cluster_offset_t, host_total_number_of_clusters_t>(*this, arguments, context);

  // alloc
  unsigned n_hits = first<host_total_number_of_clusters_t>(arguments);
  resize<dev_velo_cluster_container_t>(arguments, n_hits * Velo::Clusters::element_size);
  resize<dev_sorted_velo_cluster_container_t>(arguments, n_hits * Velo::Clusters::element_size);
  resize<dev_hit_permutation_t>(arguments, n_hits);
  resize<dev_hit_sorting_key_t>(arguments, n_hits);

  // decode
  global_function(velo_decode_ccl)(
    dim3(first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs), dim3(128), context)(
    arguments, first<host_number_of_events_t>(arguments), constants.dev_velo_geometry);

  // sort
  SegSort::segsort<int64_t>(
    *this,
    arguments,
    context,
    data<dev_hit_sorting_key_t>(arguments),
    data<dev_module_pair_cluster_offset_t>(arguments),
    size<dev_module_pair_cluster_offset_t>(arguments) - 1,
    data<dev_hit_permutation_t>(arguments));

  global_function(velo_apply_sort_permutation)(
    dim3((first<host_total_number_of_clusters_t>(arguments) + 255) / 256), dim3(256), context)(
    arguments, first<host_number_of_events_t>(arguments));
}
