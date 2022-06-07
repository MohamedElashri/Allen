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

INSTANTIATE_ALGORITHM(calo_seed_clusters::calo_seed_clusters_t)

__device__ void seed_clusters(
  CaloDigit const* digits,
  unsigned const num_digits,
  CaloSeedCluster* clusters,
  unsigned* num_clusters,
  const CaloGeometry& geometry,
  const int16_t min_adc)
{
  // Loop over all CellIDs.
  for (unsigned i = threadIdx.x; i < num_digits; i += blockDim.x) {
    const auto digit = digits[i];
    if (!digit.is_valid() || digit.adc < min_adc) {
      continue;
    }
    uint16_t* neighbors = &(geometry.neighbors[i * Calo::Constants::max_neighbours]);
    bool is_max = true;
    for (unsigned n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const neighbor_digit = digits[neighbors[n]];
      is_max = is_max && (neighbors[n] == USHRT_MAX || !neighbor_digit.is_valid() || digit.adc > neighbor_digit.adc);
    }
    if (is_max) {
      auto const id = atomicAdd(num_clusters, 1);
      clusters[id] = CaloSeedCluster(i, digits[i].adc, geometry.getX(i), geometry.getY(i));
    }
  }
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
    &parameters.dev_ecal_digits[ecal_digits_offset],
    parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
    &parameters.dev_ecal_seed_clusters[Calo::Constants::ecal_max_index / 8 * event_number],
    &parameters.dev_ecal_num_clusters[event_number],
    ecal_geometry,
    ecal_min_adc);
}

void calo_seed_clusters::calo_seed_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  auto const n_events = first<host_number_of_events_t>(arguments);
  set_size<dev_ecal_num_clusters_t>(arguments, n_events);

  // TODO: get this from the geometry too
  set_size<dev_ecal_seed_clusters_t>(arguments, Calo::Constants::ecal_max_index / 8 * n_events);
}

void calo_seed_clusters::calo_seed_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  Allen::Context const& context) const
{
  initialize<dev_ecal_num_clusters_t>(arguments, 0, context);

  // Find local maxima.
  global_function(calo_seed_clusters)(
    dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
    arguments, constants.dev_ecal_geometry, property<ecal_min_adc_t>().get());
}
