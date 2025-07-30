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
#include <CaloOverlapClusters.cuh>
#include <vector>
using std::vector;
INSTANTIATE_ALGORITHM(calo_overlap_clusters::calo_overlap_clusters_t)

__device__ void overlap_clusters(
  CaloDigit const* digits,
  CaloSeedCluster const* seed_clusters,
  float* ecal_corrections,
  unsigned const num_clusters,
  const CaloGeometry& geometry,
  unsigned const* digit_is_seed,
  int16_t min_nb_adc)
{
  // Loop over all CellIDs.
  for (unsigned i = threadIdx.x; i < num_clusters; i += blockDim.x) {
    auto seed1 = seed_clusters[i];
    float seed1_e = seed1.e;
    uint16_t* neighbors = &(geometry.neighbors[seed1.id * Calo::Constants::max_neighbours]);

    float ecal_correction = 0.f;
    for (unsigned n = 0; n < Calo::Constants::max_neighbours; n++) {
      if (neighbors[n] == USHRT_MAX) continue;
      if (digits[neighbors[n]].adc < min_nb_adc) continue;
      float ov_energy = geometry.getE(neighbors[n], digits[neighbors[n]].adc);
      float seed2_e = 0.0;
      uint16_t* second_nb = &(geometry.neighbors[neighbors[n] * Calo::Constants::max_neighbours]);

      for (unsigned m = 0; m < Calo::Constants::max_neighbours; m++) {
        if (second_nb[m] == USHRT_MAX) continue;
        if (digit_is_seed[second_nb[m]] == 0) continue;
        if (second_nb[m] == seed1.id) continue;
        seed2_e += seed_clusters[digit_is_seed[second_nb[m]]].e;
      }

      if (seed2_e == 0) continue;
      float correction = seed2_e / (seed1_e + seed2_e) * ov_energy;
      ecal_correction += correction;
    }
    ecal_corrections[i] = ecal_correction;
  }
}

__global__ void calo_overlap_clusters::calo_overlap_clusters(
  calo_overlap_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const int16_t ecal_min_adc)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // Get geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);

  // ECal
  unsigned const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  unsigned const ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_clusters_offset;

  overlap_clusters(
    parameters.dev_ecal_digits + ecal_digits_offset,
    parameters.dev_ecal_seed_clusters + Calo::Constants::ecal_max_index / 8 * event_number,
    parameters.dev_ecal_corrections + ecal_clusters_offset,
    ecal_num_clusters,
    ecal_geometry,
    parameters.dev_ecal_digit_is_seed + ecal_digits_offset,
    ecal_min_adc);
}

void calo_overlap_clusters::calo_overlap_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ecal_corrections_t>(arguments, first<host_ecal_number_of_clusters_t>(arguments));
}

void calo_overlap_clusters::calo_overlap_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  Allen::Context const& context) const
{
  // Find overlap cells.
  global_function(calo_overlap_clusters)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments, constants.dev_ecal_geometry, m_ecal_min_adc);
}
