/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "ROOTService.h"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <CaloCluster.cuh>
#include <cfloat>
namespace two_calo_clusters_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_ecal_number_of_twoclusters_t, unsigned) host_ecal_number_of_twoclusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    DEVICE_INPUT(dev_ecal_number_of_clusters_t, unsigned) dev_ecal_number_of_clusters;
    DEVICE_INPUT(dev_ecal_twoclusters_t, TwoCaloCluster) dev_ecal_twoclusters;
    DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;
    DEVICE_INPUT(dev_number_of_pvs_t, unsigned) dev_number_of_pvs;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;

    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(dev_local_decisions_t, bool) dev_local_decisions;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minE19_clusters_t, "minE19_clusters", "min E19 of each cluster", float) minE19_clusters;
    PROPERTY(minEt_clusters_t, "minEt_clusters", "min Et of each cluster", float) minEt_clusters;
    PROPERTY(minSumEt_clusters_t, "minSumEt_clusters", "min SumEt of clusters", float) minSumEt_clusters;
    PROPERTY(minPt_t, "minPt", "min Pt of the twocluster", float) minPt;
    PROPERTY(minPtEta_t, "minPtEta", "Pt > (minPtEta * (10-Eta)) of the twocluster", float) minPtEta;
    PROPERTY(minMass_t, "minMass", "min Mass of the two cluster", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "max Mass of the two cluster", float) maxMass;
    PROPERTY(eta_max_t, "eta_max", "Maximum dicluster pseudorapidity", float) eta_max;
    PROPERTY(max_velo_tracks_t, "max_velo_tracks", "Maximum number of VELO tracks", unsigned) max_velo_tracks;
    PROPERTY(max_ecal_clusters_t, "max_ecal_clusters", "Maximum number of ECAL clusters", unsigned) max_ecal_clusters;
    PROPERTY(max_n_pvs_t, "max_n_pvs", "Maximum number of PVs", unsigned) max_n_pvs;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line monitoring", bool) enable_tupling;
  };

  struct two_calo_clusters_line_t : public SelectionAlgorithm, Parameters, Line<two_calo_clusters_line_t, Parameters> {

    void init_tuples(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned>,
      unsigned index,
      bool sel);

    void output_tuples(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned> input);

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants) const;

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_twocluster_offsets[event_number];
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_twocluster_offsets[event_number + 1] -
             parameters.dev_ecal_twocluster_offsets[event_number];
    }

    __device__ static std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      Velo::Consolidated::ConstTracks velo_tracks {parameters.dev_offsets_velo_tracks,
                                                   parameters.dev_offsets_velo_track_hit_number,
                                                   event_number,
                                                   parameters.dev_number_of_events[0]};
      const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);
      const unsigned ecal_number_of_clusters = parameters.dev_ecal_number_of_clusters[event_number];
      const unsigned n_pvs = parameters.dev_number_of_pvs[event_number];
      const TwoCaloCluster event_ecal_twoclusters =
        parameters.dev_ecal_twoclusters[parameters.dev_ecal_twocluster_offsets[event_number] + i];
      return std::forward_as_tuple(event_ecal_twoclusters, number_of_velo_tracks, ecal_number_of_clusters, n_pvs);
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_ecal_number_of_twoclusters_t>(arguments);
    }

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minMass_t> m_minMass {this, 3000.0f};                   // MeV
    Property<maxMass_t> m_maxMass {this, 7000.0f};                   // MeV
    Property<minPt_t> m_minPt {this, 0.0f};                          // MeV
    Property<minPtEta_t> m_minPtEta {this, 0.0f};                    // MeV
    Property<minEt_clusters_t> m_minEt_clusters {this, 200.f};       // MeV
    Property<minSumEt_clusters_t> m_minSumEt_clusters {this, 400.f}; // MeV
    Property<minE19_clusters_t> m_minE19_clusters {this, 0.6f};
    Property<eta_max_t> m_eta_max {this, 10.f};
    Property<max_velo_tracks_t> m_max_velo_tracks {this, UINT_MAX};
    Property<max_ecal_clusters_t> m_max_ecal_clusters {this, UINT_MAX};
    Property<max_n_pvs_t> m_max_n_pvs {this, UINT_MAX};
    Property<enable_tupling_t> m_enable_tupling {this, false};
  };
} // namespace two_calo_clusters_line
