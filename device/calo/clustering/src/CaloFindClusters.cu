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
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(calo_find_clusters::calo_find_clusters_t)

__device__ void simple_clusters(
  CaloDigit const* digits,
  const bool* digits_isTrackMatched,
  const bool* digits_isBremMatched,
  CaloSeedCluster const* seed_clusters,
  CaloCluster* clusters,
  unsigned const num_clusters,
  unsigned* num_neutral_clusters,
  const CaloGeometry& calo,
  const int16_t min_adc,
  float const* corrections,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_digit_e,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_e,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_et,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_x,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_y)
{

  __shared__ unsigned num_neutral_clusters_shared;
  if (threadIdx.x == 0) num_neutral_clusters_shared = 0u;
  __syncthreads();

  for (unsigned c = threadIdx.x; c < num_clusters; c += blockDim.x) {
    auto const seed_cluster = seed_clusters[c];
    const bool isTrackMatched = digits_isTrackMatched[seed_cluster.id];
    const bool isBremMatched = digits_isBremMatched[seed_cluster.id];
    auto cluster = CaloCluster(calo, seed_cluster, isTrackMatched, isBremMatched);

    uint16_t const* neighbors = &(calo.neighbors[seed_cluster.id * Calo::Constants::max_neighbours]);
    for (uint16_t n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const n_id = neighbors[n];
      if (n_id == USHRT_MAX) {
        continue;
      }
      auto const digit = digits[n_id];
      if (digit.is_valid() && (digit.adc > min_adc)) {
        const auto digit_e = calo.getE(n_id, digit.adc);
        cluster.e += digit_e;
        cluster.digits[n] = n_id;
        histo_ecal_digit_e.increment(digit_e);
      }
    }
    cluster.e -= corrections[c];

    for (uint16_t n = 0; n < Calo::Constants::max_neighbours; n++) {
      auto const n_id = cluster.digits[n];
      if (n_id == USHRT_MAX) {
        continue;
      }
      auto const digit = digits[n_id];
      float const e_frac = calo.getE(n_id, digit.adc) / cluster.e;
      cluster.x += e_frac * (calo.getX(n_id) - seed_cluster.x);
      cluster.y += e_frac * (calo.getY(n_id) - seed_cluster.y);
    }
    cluster.CalcEt();
    cluster.CaloNeutralE19 = calo.getE(seed_cluster.id, seed_cluster.adc) / cluster.e;

    histo_ecal_cluster_e.increment(cluster.e);
    histo_ecal_cluster_et.increment(cluster.et);
    histo_ecal_cluster_x.increment(cluster.x);
    histo_ecal_cluster_y.increment(cluster.y);

    clusters[c] = cluster;

    if (!cluster.isTrackMatched) {
      atomicAdd(&num_neutral_clusters_shared, 1);
    }
  }

  __syncthreads();
  if (threadIdx.x == 0) *num_neutral_clusters = num_neutral_clusters_shared;
}

__global__ void calo_find_clusters::calo_find_clusters(
  calo_find_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const int16_t min_adc,
  Allen::Monitoring::Histogram<>::DeviceType histo_n_clusters,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_digit_e,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_e,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_et,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_x,
  Allen::Monitoring::Histogram<>::DeviceType histo_ecal_cluster_y)
{
  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);

  // Build simple 3x3 clusters from seed clusters
  // Ecal
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];
  unsigned const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  unsigned const ecal_clusters_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_clusters_offset;

  histo_n_clusters.increment(ecal_num_clusters);

  simple_clusters(
    parameters.dev_ecal_digits + ecal_digits_offset,
    parameters.dev_ecal_digits_isTrackMatched + ecal_digits_offset,
    parameters.dev_ecal_digits_isBremMatched + ecal_digits_offset,
    parameters.dev_ecal_seed_clusters + Calo::Constants::ecal_max_index / 8 * event_number,
    parameters.dev_ecal_clusters + ecal_clusters_offset,
    ecal_num_clusters,
    parameters.dev_ecal_neutral_cluster_offsets + event_number,
    ecal_geometry,
    min_adc,
    parameters.dev_ecal_corrections + ecal_clusters_offset,
    histo_ecal_digit_e,
    histo_ecal_cluster_e,
    histo_ecal_cluster_et,
    histo_ecal_cluster_x,
    histo_ecal_cluster_y);
}

void calo_find_clusters::calo_find_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const n_events = first<host_number_of_events_t>(arguments);
  set_size<dev_ecal_clusters_t>(arguments, first<host_ecal_number_of_clusters_t>(arguments));
  set_size<dev_ecal_neutral_cluster_offsets_t>(arguments, n_events + 1);
  set_size<host_total_sum_holder_t>(arguments, 1);
}

__host__ void calo_find_clusters::calo_find_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  Allen::Context const& context) const
{
  auto dev_histo_n_clusters = m_histogram_n_clusters.data(context);
  auto dev_histo_ecal_digit_e = m_histogram_ecal_digit_e.data(context);
  auto dev_histo_ecal_cluster_e = m_histogram_ecal_cluster_e.data(context);
  auto dev_histo_ecal_cluster_et = m_histogram_ecal_cluster_et.data(context);
  auto dev_histo_ecal_cluster_x = m_histogram_ecal_cluster_x.data(context);
  auto dev_histo_ecal_cluster_y = m_histogram_ecal_cluster_y.data(context);

  Allen::memset_async<dev_ecal_neutral_cluster_offsets_t>(arguments, 0, context);

  // Find clusters.
  global_function(calo_find_clusters)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments,
    constants.dev_ecal_geometry,
    m_ecal_min_adc,
    dev_histo_n_clusters,
    dev_histo_ecal_digit_e,
    dev_histo_ecal_cluster_e,
    dev_histo_ecal_cluster_et,
    dev_histo_ecal_cluster_x,
    dev_histo_ecal_cluster_y);

  PrefixSum::prefix_sum<dev_ecal_neutral_cluster_offsets_t, host_total_sum_holder_t>(*this, arguments, context);
}
