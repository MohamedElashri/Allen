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
#include <CaloSeedClusters.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(calo_seed_clusters::calo_seed_clusters_t)

__device__ void seed_clusters(
  Allen::device::span<CaloDigit const> digits,
  unsigned const num_digits,
  Allen::device::span<CaloSeedCluster> clusters,
  Allen::device::span<unsigned> num_clusters,
  const CaloGeometry& geometry,
  const int16_t min_adc,
  unsigned* digit_is_seed)
{

  __shared__ unsigned num_clusters_shared;
  if (threadIdx.x == 0) num_clusters_shared = 0u;
  __syncthreads();

  // Loop over all CellIDs.
  for (unsigned i = threadIdx.x; i < num_digits; i += blockDim.x) {
    const auto digit = digits[i];
    if (digit.adc < min_adc || !digit.is_valid()) {
      continue;
    }
    const uint16_t* neighbors = &(geometry.neighbors[i * Calo::Constants::max_neighbours]);
    bool is_max = true;
    float energy = geometry.getE(i, digit.adc);
    for (unsigned n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const neighbor_id = neighbors[n];
      if (neighbor_id == USHRT_MAX) {
        continue;
      }
      auto const neighbor_digit = digits[neighbor_id];
      if (neighbor_digit.is_valid()) {
        is_max = is_max && (digit.adc > neighbor_digit.adc);
        energy += geometry.getE(neighbor_id, neighbor_digit.adc);
      }
    }
    if (is_max) {
      auto const id = atomicAdd(&num_clusters_shared, 1);
      clusters[id] = CaloSeedCluster(i, digit.adc, geometry.getX(i), geometry.getY(i), energy);
      digit_is_seed[i] = id;
    }
  }

  __syncthreads();
  if (threadIdx.x == 0) num_clusters[0] = num_clusters_shared;
}

__global__ void calo_seed_clusters::calo_seed_clusters(
  calo_seed_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const int16_t ecal_min_adc)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // Get geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);

  // ECal
  auto const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  seed_clusters(
    parameters.dev_ecal_digits.subspan(ecal_digits_offset),
    parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
    parameters.dev_ecal_seed_clusters.subspan(Calo::Constants::ecal_max_index / 8 * event_number),
    parameters.dev_ecal_cluster_offsets.subspan(event_number),
    ecal_geometry,
    ecal_min_adc,
    parameters.dev_ecal_digit_is_seed + ecal_digits_offset);
}

void calo_seed_clusters::calo_seed_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const n_events = first<host_number_of_events_t>(arguments);
  auto const n_digits = first<host_ecal_number_of_digits_t>(arguments);

  set_size<dev_ecal_cluster_offsets_t>(arguments, n_events + 1);
  set_size<host_total_sum_holder_t>(arguments, 1);

  // TODO: get this from the geometry too
  set_size<dev_ecal_seed_clusters_t>(arguments, Calo::Constants::ecal_max_index / 8 * n_events);
  set_size<dev_ecal_digit_is_seed_t>(arguments, n_digits);
}

void calo_seed_clusters::calo_seed_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  Allen::Context const& context) const
{
  Allen::memset_async<dev_ecal_digit_is_seed_t>(arguments, 0, context);
  Allen::memset_async<dev_ecal_cluster_offsets_t>(arguments, 0, context);

  // Find local maxima.
  global_function(calo_seed_clusters)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments, constants.dev_ecal_geometry, m_ecal_min_adc);

  PrefixSum::prefix_sum<dev_ecal_cluster_offsets_t, host_total_sum_holder_t>(*this, arguments, context);
}
