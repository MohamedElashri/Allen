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
#pragma once

#include "Line.cuh"
#include "ROOTService.h"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "VeloConsolidated.cuh"
#include "CompositeParticleLine.cuh"
#include <cfloat>

#include "AllenMonitoring.h"

namespace two_calo_clusters_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_cluster_particle_container_t, Allen::Views::Physics::MultiEventNeutralBasicParticles)
    dev_cluster_particle_container;
    DEVICE_INPUT(dev_number_of_pvs_t, unsigned) dev_number_of_pvs;

    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(mass_t, float) diphoton_mass;
    DEVICE_OUTPUT(et_t, float) diphoton_et;
    DEVICE_OUTPUT(eta_t, float) diphoton_eta;
    DEVICE_OUTPUT(minet_t, float) diphoton_min_photonet; // use this in bandwidth division
    DEVICE_OUTPUT(distance_t, float) diphoton_distance;
    DEVICE_OUTPUT(isTrackMatched_t, bool) diphoton_isTrackMatched;
    DEVICE_OUTPUT(isBremMatched_t, bool) diphoton_isBremMatched;
    DEVICE_OUTPUT(et1_t, float) photon1_et;
    DEVICE_OUTPUT(et2_t, float) photon2_et;
    DEVICE_OUTPUT(x1_t, float) photon1_x;
    DEVICE_OUTPUT(x2_t, float) photon2_x;
    DEVICE_OUTPUT(y1_t, float) photon1_y;
    DEVICE_OUTPUT(y2_t, float) photon2_y;
    DEVICE_OUTPUT(e19_1_t, float) photon1_e19;
    DEVICE_OUTPUT(e19_2_t, float) photon2_e19;
    DEVICE_OUTPUT(nvelotracks_t, unsigned) nvelotracks;
    DEVICE_OUTPUT(necalclusters_t, unsigned) necalclusters;
    DEVICE_OUTPUT(npvs_t, unsigned) npvs;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct two_calo_clusters_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<two_calo_clusters_line_t, Parameters> {
    struct DeviceProperties {
      float minMass;
      float maxMass;
      float minPt;
      float maxPt;
      float minPtEta;
      float minEt_clusters;
      float minSumEt_clusters;
      float minE19_clusters;
      float minAbsY_clusters;
      float eta_max;
      unsigned max_velo_tracks;
      unsigned max_ecal_clusters;
      unsigned max_n_pvs;
      bool veto_bm_clusters;
      Allen::Monitoring::Histogram<>::DeviceType histogram_diphoton_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_diphoton_pt;
      DeviceProperties(const two_calo_clusters_line_t& algo, const Allen::Context& ctx) :
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), minPt(algo.m_minPt), maxPt(algo.m_maxPt),
        minPtEta(algo.m_minPtEta), minEt_clusters(algo.m_minEt_clusters), minSumEt_clusters(algo.m_minSumEt_clusters),
        minE19_clusters(algo.m_minE19_clusters), minAbsY_clusters(algo.m_minAbsY_clusters), eta_max(algo.m_eta_max),
        max_velo_tracks(algo.m_max_velo_tracks), max_ecal_clusters(algo.m_max_ecal_clusters),
        max_n_pvs(algo.m_max_n_pvs), veto_bm_clusters(algo.m_veto_bm_clusters),
        histogram_diphoton_mass(algo.m_histogram_diphoton_mass.data(ctx)),
        histogram_diphoton_pt(algo.m_histogram_diphoton_pt.data(ctx))
      {}
    };

    __device__ static void fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>,
      unsigned,
      bool);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>);

    using monitoring_types = std::tuple<
      mass_t,
      et_t,
      eta_t,
      minet_t,
      distance_t,
      isTrackMatched_t,
      isBremMatched_t,
      et1_t,
      et2_t,
      x1_t,
      x2_t,
      y1_t,
      y2_t,
      e19_1_t,
      e19_2_t,
      nvelotracks_t,
      necalclusters_t,
      npvs_t,
      evtNo_t,
      runNo_t>;

    __device__ static std::
      tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>
      get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const auto velo_tracks = parameters.dev_velo_tracks[event_number];
      const unsigned number_of_velo_tracks = velo_tracks.size();
      const auto cluster_particles = parameters.dev_cluster_particle_container->container(event_number);
      const unsigned ecal_number_of_clusters = cluster_particles.size();
      const unsigned n_pvs = parameters.dev_number_of_pvs[event_number];
      const auto particles = parameters.dev_particle_container->container(event_number);
      const auto particle = particles.particle(i);
      return std::forward_as_tuple(particle, number_of_velo_tracks, ecal_number_of_clusters, n_pvs);
    }

    void init();

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_minMass {this, "minMass", 4200.0f, "min Mass of the two cluster"};                 // MeV
    Allen::Property<float> m_maxMass {this, "maxMass", 21000.0f, "max Mass of the two cluster"};                // MeV
    Allen::Property<float> m_minPt {this, "minPt", 0.0f, "min Pt of the twocluster"};                           // MeV
    Allen::Property<float> m_maxPt {this, "maxPt", 999999.f, "max Pt of the twocluster"};                       // MeV
    Allen::Property<float> m_minPtEta {this, "minPtEta", 0.0f, "Pt > (minPtEta * (10-Eta)) of the twocluster"}; // MeV
    Allen::Property<float> m_minEt_clusters {this, "minEt_clusters", 200.f, "min Et of each cluster"};          // MeV
    Allen::Property<float> m_minSumEt_clusters {this, "minSumEt_clusters", 400.f, "min SumEt of clusters"};     // MeV
    Allen::Property<float> m_minE19_clusters {this, "minE19_clusters", 0.6f, "min E19 of each cluster"};
    Allen::Property<float> m_minAbsY_clusters {this, "minAbsY_clusters", -1.0f, "min |Y| of each cluster"}; // mm
    Allen::Property<float> m_eta_max {this, "eta_max", 10.f, "Maximum dicluster pseudorapidity"};
    Allen::Property<unsigned> m_max_velo_tracks {this, "max_velo_tracks", UINT_MAX, "Maximum number of VELO tracks"};
    Allen::Property<unsigned> m_max_ecal_clusters {this,
                                                   "max_ecal_clusters",
                                                   UINT_MAX,
                                                   "Maximum number of ECAL clusters"};
    Allen::Property<unsigned> m_max_n_pvs {this, "max_n_pvs", UINT_MAX, "Maximum number of PVs"};
    Allen::Property<bool> m_veto_bm_clusters {this,
                                              "veto_bm_clusters",
                                              true,
                                              "Discard candidates with bremsstrahlung-matched clusters"};

    Allen::Property<float> m_histogramdiphotonMassMin {this,
                                                       "histogram_diphoton_mass_min",
                                                       0.f,
                                                       "histogram_diphoton_mass_min description"};
    Allen::Property<float> m_histogramdiphotonMassMax {this,
                                                       "histogram_diphoton_mass_max",
                                                       2000.f,
                                                       "histogram_diphoton_mass_max description"};
    Allen::Property<unsigned int> m_histogramdiphotonMassNBins {this,
                                                                "histogram_diphoton_mass_nbins",
                                                                100u,
                                                                "histogram_diphoton_mass_nbins description"};
    Allen::Property<float> m_histogramdiphotonPtMin {this,
                                                     "histogram_diphoton_pt_min",
                                                     0.f,
                                                     "histogram_diphoton_pt_min description"};
    Allen::Property<float> m_histogramdiphotonPtMax {this,
                                                     "histogram_diphoton_pt_max",
                                                     2e3,
                                                     "histogram_diphoton_pt_max description"};
    Allen::Property<unsigned int> m_histogramdiphotonPtNBins {this,
                                                              "histogram_diphoton_pt_nbins",
                                                              100u,
                                                              "histogram_diphoton_pt_nbins description"};

    Allen::Monitoring::Histogram<> m_histogram_diphoton_mass {this, "diphoton_mass", "m(diphoton)", {100u, 0.f, 2e3f}};
    Allen::Monitoring::Histogram<> m_histogram_diphoton_pt {this, "diphoton_pt", "pT(diphoton)", {100u, 0.f, 2e3f}};
  };
} // namespace two_calo_clusters_line
