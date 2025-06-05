/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SingleCaloCluster.cuh"
#include <ROOTHeaders.h>
#include "CaloConstants.cuh"

// Explicit instantiation
INSTANTIATE_LINE(single_calo_cluster_line::single_calo_cluster_line_t, single_calo_cluster_line::Parameters)

__device__ bool single_calo_cluster_line::single_calo_cluster_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input)
{
  const auto calo = std::get<0>(input);
  const auto& ecal_cluster = calo.cluster();
  const float z = Calo::Constants::z; // mm
  const unsigned ecal_number_of_clusters = std::get<1>(input);

  const float sintheta = sqrtf(
    (ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y) /
    (ecal_cluster.x * ecal_cluster.x + ecal_cluster.y * ecal_cluster.y + z * z));
  const float E_T = ecal_cluster.e * sintheta;
  const float decision =
    (E_T > properties.minEt && E_T < properties.maxEt && fabsf(ecal_cluster.y) > properties.minAbsY_cluster &&
     ecal_number_of_clusters <= properties.max_ecal_clusters);

  return decision;
}

__device__ bool single_calo_cluster_line::single_calo_cluster_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  const auto calo = std::get<0>(input);
  const auto& ecal_cluster = calo.cluster();

  if (sel) {
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
  return sel;
}
