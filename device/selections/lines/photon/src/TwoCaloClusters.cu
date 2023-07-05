/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include <math.h>
#include "TwoCaloClusters.cuh"
#include <ROOTHeaders.h>
#include "CaloConstants.cuh"

// Explicit instantiation
INSTANTIATE_LINE(two_calo_clusters_line::two_calo_clusters_line_t, two_calo_clusters_line::Parameters)

__device__ bool two_calo_clusters_line::two_calo_clusters_line_t::select(
  const Parameters& parameters,
  std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned> input)
{
  const auto number_of_velo_tracks = std::get<1>(input);
  const auto ecal_number_of_clusters = std::get<2>(input);
  const auto n_pvs = std::get<3>(input);
  const auto dicluster = std::get<0>(input);

  bool decision = (dicluster.Mass > parameters.minMass) && (dicluster.Mass < parameters.maxMass) &&
                  (dicluster.Pt > parameters.minPt) && (dicluster.Pt > parameters.minPtEta * (10 - dicluster.Eta)) &&
                  (dicluster.et1 > parameters.minEt_clusters && dicluster.et2 > parameters.minEt_clusters) &&
                  (dicluster.et1 + dicluster.et2 > parameters.minSumEt_clusters) &&
                  (dicluster.CaloNeutralE19_1 > parameters.minE19_clusters &&
                   dicluster.CaloNeutralE19_2 > parameters.minE19_clusters) &&
                  (number_of_velo_tracks <= parameters.max_velo_tracks) &&
                  (ecal_number_of_clusters <= parameters.max_ecal_clusters) && (n_pvs <= parameters.max_n_pvs) &&
                  (dicluster.Eta < parameters.eta_max);

  return decision;
}

__device__ void two_calo_clusters_line::two_calo_clusters_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned> input,
  unsigned index,
  bool sel)
{
  const auto& [dicluster, n_velotracks, n_caloclusters, n_pvs] = input;
  if(sel){
    parameters.diphoton_mass[index] = dicluster.Mass;
    parameters.diphoton_et[index] = dicluster.Pt;
    parameters.diphoton_eta[index] = dicluster.Eta;
    parameters.diphoton_min_photonet[index] = min(dicluster.et1, dicluster.et2); // can be used in bandwidth division, [2000,4500] GeV
    parameters.diphoton_distance[index] = dicluster.Distance;
    parameters.photon1_x[index] = dicluster.x1;
    parameters.photon1_y[index] = dicluster.y1;
    parameters.photon1_et[index] = dicluster.et1; 
    parameters.photon1_e19[index] = dicluster.CaloNeutralE19_1;
    parameters.photon2_x[index] = dicluster.x2;
    parameters.photon2_y[index] = dicluster.y2;
    parameters.photon2_et[index] = dicluster.et2;
    parameters.photon2_e19[index] = dicluster.CaloNeutralE19_2;
    parameters.nvelotracks[index] = n_velotracks;
    parameters.necalclusters[index] = n_caloclusters;
    parameters.npvs[index] = n_pvs;
  }
}