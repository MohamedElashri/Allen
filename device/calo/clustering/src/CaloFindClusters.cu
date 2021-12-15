/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <CaloCluster.cuh>
#include <CaloFindClusters.cuh>

INSTANTIATE_ALGORITHM(calo_find_clusters::calo_find_clusters_t)

__device__ void simple_clusters(
  CaloDigit const* digits,
  CaloSeedCluster const* seed_clusters,
  CaloCluster* clusters,
  unsigned const num_clusters,
  const CaloGeometry& calo,
  const int16_t min_adc)
{
  for (unsigned c = threadIdx.x; c < num_clusters; c += blockDim.x) {
    auto const& seed_cluster = seed_clusters[c];
    auto& cluster = clusters[c];
    cluster.center_id = seed_cluster.id;
    cluster.e = calo.getE(seed_cluster.id, seed_cluster.adc);
    cluster.x = seed_cluster.x;
    cluster.y = seed_cluster.y;

    uint16_t const* neighbors = &(calo.neighbors[seed_cluster.id * Calo::Constants::max_neighbours]);
    for (uint16_t n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const n_id = neighbors[n];
      int16_t adc = digits[n_id].adc;
      if (n_id != USHRT_MAX && (adc != SHRT_MAX) && (adc > min_adc)) {
        cluster.e += calo.getE(n_id, adc);
        cluster.digits[n] = n_id;
      }
      else {
        cluster.digits[n] = USHRT_MAX;
      }
    }

    for (uint16_t n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const n_id = neighbors[n];
      auto const adc = digits[n_id].adc;
      if (n_id != USHRT_MAX && (adc < SHRT_MAX) && (adc > min_adc)) {
        float const adc_frac = float(adc) / float(cluster.e);
        cluster.x += adc_frac * (calo.getX(n_id) - seed_cluster.x);
        cluster.y += adc_frac * (calo.getY(n_id) - seed_cluster.y);
      }
    }
  }
}

__global__ void calo_find_clusters::calo_find_clusters(
  calo_find_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const int16_t min_adc)
{
  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);

  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // Build simple 3x3 clusters from seed clusters
  // Ecal
  unsigned const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  unsigned const ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_clusters_offset;
  simple_clusters(
    parameters.dev_ecal_digits + ecal_digits_offset,
    parameters.dev_ecal_seed_clusters + Calo::Constants::ecal_max_index / 8 * event_number,
    parameters.dev_ecal_clusters + ecal_clusters_offset,
    ecal_num_clusters,
    ecal_geometry,
    min_adc);
}

void calo_find_clusters::calo_find_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_clusters_t>(arguments, first<host_ecal_number_of_clusters_t>(arguments));
}

__host__ void calo_find_clusters::calo_find_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  Allen::Context const& context) const
{
  // Find clusters.
  initialize<dev_ecal_clusters_t>(arguments, SHRT_MAX, context);

  global_function(calo_find_clusters)(
    dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
    arguments, constants.dev_ecal_geometry, property<ecal_min_adc_t>().get());

  if (runtime_options.fill_extra_host_buffers) {
    safe_assign_to_host_buffer<dev_ecal_cluster_offsets_t>(host_buffers.host_ecal_cluster_offsets, arguments, context);
    safe_assign_to_host_buffer<dev_ecal_clusters_t>(host_buffers.host_ecal_clusters, arguments, context);
  }
}
