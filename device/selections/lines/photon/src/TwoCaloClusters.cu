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

  bool decision = (mass > parameters.minMass) && (mass < parameters.maxMass) && (pt > parameters.minPt) &&
                  (pt <= parameters.maxPt) && (pt > parameters.minPtEta * (10 - eta)) &&
                  (child1->et() > parameters.minEt_clusters && child2->et() > parameters.minEt_clusters) &&
                  (child1->et() + child2->et() > parameters.minSumEt_clusters) &&
                  (c1.CaloNeutralE19 > parameters.minE19_clusters && c2.CaloNeutralE19 > parameters.minE19_clusters) &&
                  (number_of_velo_tracks <= parameters.max_velo_tracks) &&
                  (ecal_number_of_clusters <= parameters.max_ecal_clusters) && (n_pvs <= parameters.max_n_pvs) &&
                  (eta < parameters.eta_max);

  return decision;
}

__device__ void two_calo_clusters_line::two_calo_clusters_line_t::fill_tuples(
  const Parameters& parameters,
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
}

void two_calo_clusters_line::two_calo_clusters_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<typename Parameters::dev_histogram_diphoton_mass_t>(arguments, 0, context);
  Allen::memset_async<typename Parameters::dev_histogram_diphoton_pt_t>(arguments, 0, context);
}

void two_calo_clusters_line::two_calo_clusters_line_t::init()
{
  Line<two_calo_clusters_line::two_calo_clusters_line_t, two_calo_clusters_line::Parameters>::init();
#ifndef ALLEN_STANDALONE
  histogram_diphoton_mass = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                         "diphoton_mass",
                                                                         "m(diphoton)",
                                                                         {property<histogram_diphoton_mass_nbins_t>(),
                                                                          property<histogram_diphoton_mass_min_t>(),
                                                                          property<histogram_diphoton_mass_max_t>()}},
                                                                        {}};
  histogram_diphoton_pt = new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                                       "diphoton_pt",
                                                                       "pT(diphoton)",
                                                                       {property<histogram_diphoton_pt_nbins_t>(),
                                                                        property<histogram_diphoton_pt_min_t>(),
                                                                        property<histogram_diphoton_pt_max_t>()}},
                                                                      {}};
#endif
}

void two_calo_clusters_line::two_calo_clusters_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_diphoton_mass_t>(arguments, 100u);
  set_size<typename Parameters::dev_histogram_diphoton_pt_t>(arguments, 100u);
}

__device__ void two_calo_clusters_line::two_calo_clusters_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned> input,
  unsigned,
  bool sel)
{
  const auto& [dicluster, n_velotracks, n_caloclusters, n_pvs] = input;
  if (sel) {
    const float m = dicluster.diphoton_mass();
    const float pt = dicluster.diphoton_pt();
    if (m > parameters.histogram_diphoton_mass_min && m < parameters.histogram_diphoton_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_diphoton_mass_min) * parameters.histogram_diphoton_mass_nbins /
        (parameters.histogram_diphoton_mass_max - parameters.histogram_diphoton_mass_min));
      atomicAdd(&parameters.dev_histogram_diphoton_mass[bin], 1);
    }
    if (pt > parameters.histogram_diphoton_pt_min && pt < parameters.histogram_diphoton_pt_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (pt - parameters.histogram_diphoton_pt_min) * parameters.histogram_diphoton_pt_nbins /
        (parameters.histogram_diphoton_pt_max - parameters.histogram_diphoton_pt_min));
      atomicAdd(&parameters.dev_histogram_diphoton_pt[bin], 1);
    }
  }
}

void two_calo_clusters_line::two_calo_clusters_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {get<dev_histogram_diphoton_mass_t>(arguments),
                            histogram_diphoton_mass,
                            property<histogram_diphoton_mass_min_t>(),
                            property<histogram_diphoton_mass_max_t>()},
                std::tuple {get<dev_histogram_diphoton_pt_t>(arguments),
                            histogram_diphoton_pt,
                            property<histogram_diphoton_pt_min_t>(),
                            property<histogram_diphoton_pt_max_t>()}});
#endif
}
