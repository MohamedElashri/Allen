/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "ROOTService.h"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "VeloConsolidated.cuh"
#include "CompositeParticleLine.cuh"
#include <cfloat>

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include <Gaudi/Accumulators.h>
#endif

namespace two_calo_clusters_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    // DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_tracks_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    // DEVICE_INPUT(dev_ecal_number_of_clusters_t, unsigned) dev_ecal_number_of_clusters;
    // DEVICE_INPUT(dev_ecal_twoclusters_t, TwoCaloCluster) dev_ecal_twoclusters;
    // DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_cluster_particle_container_t, Allen::Views::Physics::MultiEventNeutralBasicParticles) dev_cluster_particle_container;
    DEVICE_INPUT(dev_number_of_pvs_t, unsigned) dev_number_of_pvs;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;

    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // Device outputs for monitoring
    DEVICE_OUTPUT(dev_histogram_diphoton_mass_t, unsigned) dev_histogram_diphoton_mass;
    DEVICE_OUTPUT(dev_histogram_diphoton_pt_t, unsigned) dev_histogram_diphoton_pt;

    DEVICE_OUTPUT(mass_t, float) diphoton_mass;
    DEVICE_OUTPUT(et_t, float) diphoton_et;
    DEVICE_OUTPUT(eta_t, float) diphoton_eta;
    DEVICE_OUTPUT(minet_t, float) diphoton_min_photonet; // use this in bandwidth division
    DEVICE_OUTPUT(distance_t, float) diphoton_distance;
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

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minE19_clusters_t, "minE19_clusters", "min E19 of each cluster", float) minE19_clusters;
    PROPERTY(minEt_clusters_t, "minEt_clusters", "min Et of each cluster", float) minEt_clusters;
    PROPERTY(minSumEt_clusters_t, "minSumEt_clusters", "min SumEt of clusters", float) minSumEt_clusters;
    PROPERTY(minPt_t, "minPt", "min Pt of the twocluster", float) minPt;
    PROPERTY(maxPt_t, "maxPt", "min Pt of the twocluster", float) maxPt;
    PROPERTY(minPtEta_t, "minPtEta", "Pt > (minPtEta * (10-Eta)) of the twocluster", float) minPtEta;
    PROPERTY(minMass_t, "minMass", "min Mass of the two cluster", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "max Mass of the two cluster", float) maxMass;
    PROPERTY(eta_max_t, "eta_max", "Maximum dicluster pseudorapidity", float) eta_max;
    PROPERTY(max_velo_tracks_t, "max_velo_tracks", "Maximum number of VELO tracks", unsigned) max_velo_tracks;
    PROPERTY(max_ecal_clusters_t, "max_ecal_clusters", "Maximum number of ECAL clusters", unsigned) max_ecal_clusters;
    PROPERTY(max_n_pvs_t, "max_n_pvs", "Maximum number of PVs", unsigned) max_n_pvs;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

    PROPERTY(
      histogram_diphoton_mass_min_t,
      "histogram_diphoton_mass_min",
      "histogram_diphoton_mass_min description",
      float)
    histogram_diphoton_mass_min;
    PROPERTY(
      histogram_diphoton_mass_max_t,
      "histogram_diphoton_mass_max",
      "histogram_diphoton_mass_max description",
      float)
    histogram_diphoton_mass_max;
    PROPERTY(
      histogram_diphoton_mass_nbins_t,
      "histogram_diphoton_mass_nbins",
      "histogram_diphoton_mass_nbins description",
      unsigned int)
    histogram_diphoton_mass_nbins;
    PROPERTY(histogram_diphoton_pt_min_t, "histogram_diphoton_pt_min", "histogram_diphoton_pt_min description", float)
    histogram_diphoton_pt_min;
    PROPERTY(histogram_diphoton_pt_max_t, "histogram_diphoton_pt_max", "histogram_diphoton_pt_max description", float)
    histogram_diphoton_pt_max;
    PROPERTY(
      histogram_diphoton_pt_nbins_t,
      "histogram_diphoton_pt_nbins",
      "histogram_diphoton_pt_nbins description",
      unsigned int)
    histogram_diphoton_pt_nbins;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct two_calo_clusters_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<two_calo_clusters_line_t, Parameters> {

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>,
      unsigned index,
      bool sel);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned> input);

    using monitoring_types = std::tuple<
      mass_t,
      et_t,
      eta_t,
      minet_t,
      distance_t,
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

    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>
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

    static void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context);

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned, const unsigned>,
      unsigned index,
      bool sel);

    __host__ void
    output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minMass_t> m_minMass {this, 4200.0f};                   // MeV
    Property<maxMass_t> m_maxMass {this, 21000.0f};                  // MeV
    Property<minPt_t> m_minPt {this, 0.0f};                          // MeV
    Property<maxPt_t> m_maxPt {this, 999999.f};                      // MeV
    Property<minPtEta_t> m_minPtEta {this, 0.0f};                    // MeV
    Property<minEt_clusters_t> m_minEt_clusters {this, 200.f};       // MeV
    Property<minSumEt_clusters_t> m_minSumEt_clusters {this, 400.f}; // MeV
    Property<minE19_clusters_t> m_minE19_clusters {this, 0.6f};
    Property<eta_max_t> m_eta_max {this, 10.f};
    Property<max_velo_tracks_t> m_max_velo_tracks {this, UINT_MAX};
    Property<max_ecal_clusters_t> m_max_ecal_clusters {this, UINT_MAX};
    Property<max_n_pvs_t> m_max_n_pvs {this, UINT_MAX};
    Property<enable_tupling_t> m_enable_tupling {this, false};

    Property<histogram_diphoton_mass_min_t> m_histogramdiphotonMassMin {this, 0.f};
    Property<histogram_diphoton_mass_max_t> m_histogramdiphotonMassMax {this, 2000.f};
    Property<histogram_diphoton_mass_nbins_t> m_histogramdiphotonMassNBins {this, 100u};
    Property<histogram_diphoton_pt_min_t> m_histogramdiphotonPtMin {this, 0.f};
    Property<histogram_diphoton_pt_max_t> m_histogramdiphotonPtMax {this, 2e3};
    Property<histogram_diphoton_pt_nbins_t> m_histogramdiphotonPtNBins {this, 100u};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_diphoton_mass;
    gaudi_monitoring::Lockable_Histogram<>* histogram_diphoton_pt;
#endif
  };
} // namespace two_calo_clusters_line
