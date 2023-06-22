/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SingleCaloCluster.cuh"
#include <ROOTHeaders.h>
#include "CaloConstants.cuh"

// Explicit instantiation
INSTANTIATE_LINE(single_calo_cluster_line::single_calo_cluster_line_t, single_calo_cluster_line::Parameters)

__device__ bool single_calo_cluster_line::single_calo_cluster_line_t::select(
  const Parameters& parameters,
  std::tuple<const CaloCluster, const unsigned> input)
{
  const auto& ecal_cluster = std::get<0>(input);
  const auto ecal_number_of_clusters = std::get<1>(input);
  const float z = Calo::Constants::z; // mm

  const float sintheta = sqrtf(
    (ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y) /
    (ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y + z * z));
  const float E_T = ecal_cluster.e * sintheta;
  const float decision =
    (E_T > parameters.minEt && E_T < parameters.maxEt && ecal_number_of_clusters <= parameters.max_ecal_clusters);

  return decision;
}

__device__ void single_calo_cluster_line::single_calo_cluster_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const CaloCluster, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& ecal_cluster = std::get<0>(input);
    const float& z = Calo::Constants::z; // mm
    const float sintheta = sqrtf(
      (ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y) /
      (ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y + z * z));
    const float cosphi = ecal_cluster.x / sqrtf(ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y);
    const float E_T = ecal_cluster.e * sintheta;
    const float eta = -logf(tanf(asinf(sintheta) / 2.f));
    float phi = acosf(cosphi);
    if (ecal_cluster.y < 0) {
      phi = -phi;
    }

    parameters.clusters_x[index] = ecal_cluster.x;
    parameters.clusters_y[index] = ecal_cluster.y;
    parameters.clusters_Et[index] = E_T;
    parameters.clusters_Eta[index] = eta;
    parameters.clusters_Phi[index] = phi;
  }
}
