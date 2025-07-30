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
#include <math.h>
#include "TwoCaloClusters.cuh"
#include <ROOTHeaders.h>
#include "CaloConstants.cuh"

// Explicit instantiation
INSTANTIATE_LINE(two_calo_clusters_line::two_calo_clusters_line_t, two_calo_clusters_line::Parameters)

__device__ bool two_calo_clusters_line::two_calo_clusters_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned> input)
{
  const auto number_of_velo_tracks = std::get<1>(input);
  const auto ecal_number_of_clusters = std::get<2>(input);
  const auto n_pvs = std::get<3>(input);
  const auto dicluster = std::get<0>(input);

  const auto child1 = static_cast<const Allen::Views::Physics::NeutralBasicParticle*>(dicluster.child(0));
  const auto child2 = static_cast<const Allen::Views::Physics::NeutralBasicParticle*>(dicluster.child(1));
  const auto c1 = child1->cluster();
  const auto c2 = child2->cluster();

  const float mass = dicluster.diphoton_mass();
  const float pt = dicluster.diphoton_pt();
  const float eta = dicluster.diphoton_eta();

  bool decision = (mass > properties.minMass) && (mass < properties.maxMass) && (pt > properties.minPt) &&
                  (pt <= properties.maxPt) && (pt > properties.minPtEta * (10 - eta)) &&
                  (child1->et() > properties.minEt_clusters && child2->et() > properties.minEt_clusters) &&
                  (child1->et() + child2->et() > properties.minSumEt_clusters) &&
                  (c1.CaloNeutralE19 > properties.minE19_clusters && c2.CaloNeutralE19 > properties.minE19_clusters) &&
                  (fabsf(c1.y) > properties.minAbsY_clusters && fabsf(c2.y) > properties.minAbsY_clusters) &&
                  (number_of_velo_tracks <= properties.max_velo_tracks) &&
                  (ecal_number_of_clusters <= properties.max_ecal_clusters) && (n_pvs <= properties.max_n_pvs) &&
                  (eta < properties.eta_max);

  if (properties.veto_bm_clusters) decision = decision && !(c1.isBremMatched || c2.isBremMatched);

  return decision;
}

__device__ bool two_calo_clusters_line::two_calo_clusters_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned> input,
  unsigned index,
  bool sel)
{
  const auto& [dicluster, n_velotracks, n_caloclusters, n_pvs] = input;
  if (sel) {
    parameters.diphoton_mass[index] = dicluster.diphoton_mass();
    parameters.diphoton_et[index] = dicluster.diphoton_pt();
    parameters.diphoton_eta[index] = dicluster.diphoton_eta();
    const auto child1 = static_cast<const Allen::Views::Physics::NeutralBasicParticle*>(dicluster.child(0));
    const auto child2 = static_cast<const Allen::Views::Physics::NeutralBasicParticle*>(dicluster.child(1));
    const auto c1 = child1->cluster();
    const auto c2 = child2->cluster();
    parameters.diphoton_min_photonet[index] =
      min(child1->et(), child2->et()); // can be used in bandwidth division, [2000,4500] GeV
    parameters.diphoton_distance[index] = dicluster.diphoton_distance();
    parameters.diphoton_isTrackMatched[index] = c1.isTrackMatched || c2.isTrackMatched;
    parameters.diphoton_isBremMatched[index] = c1.isBremMatched || c2.isBremMatched;
    parameters.photon1_x[index] = c1.x;
    parameters.photon1_y[index] = c1.y;
    parameters.photon1_et[index] = child1->et();
    parameters.photon1_e19[index] = c1.CaloNeutralE19;
    parameters.photon2_x[index] = c2.x;
    parameters.photon2_y[index] = c2.y;
    parameters.photon2_et[index] = child2->et();
    parameters.photon2_e19[index] = c2.CaloNeutralE19;
    parameters.nvelotracks[index] = n_velotracks;
    parameters.necalclusters[index] = n_caloclusters;
    parameters.npvs[index] = n_pvs;
  }
  return sel;
}

void two_calo_clusters_line::two_calo_clusters_line_t::init()
{
  Line<two_calo_clusters_line::two_calo_clusters_line_t, two_calo_clusters_line::Parameters>::init();

  m_histogram_diphoton_mass.x_axis().nBins = m_histogramdiphotonMassNBins;
  m_histogram_diphoton_mass.x_axis().minValue = m_histogramdiphotonMassMin;
  m_histogram_diphoton_mass.x_axis().maxValue = m_histogramdiphotonMassMax;

  m_histogram_diphoton_pt.x_axis().nBins = m_histogramdiphotonPtNBins;
  m_histogram_diphoton_pt.x_axis().minValue = m_histogramdiphotonPtMin;
  m_histogram_diphoton_pt.x_axis().maxValue = m_histogramdiphotonPtMax;
}

__device__ void two_calo_clusters_line::two_calo_clusters_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned> input,
  unsigned,
  bool sel)
{
  const auto& dicluster = std::get<0>(input);
  if (sel) {
    properties.histogram_diphoton_mass.increment(dicluster.diphoton_mass());
    properties.histogram_diphoton_pt.increment(dicluster.diphoton_pt());
  }
}
