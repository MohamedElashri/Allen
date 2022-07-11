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
    HOST_INPUT(host_ecal_number_of_twoclusters_t, unsigned) host_ecal_number_of_twoclusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_twoclusters_t, TwoCaloCluster) dev_ecal_twoclusters;
    DEVICE_INPUT(dev_ecal_twocluster_offsets_t, unsigned) dev_ecal_twocluster_offsets;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;

    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // Monitoring
    HOST_OUTPUT(host_number_of_multi_final_vertices_t, unsigned) host_number_of_multi_final_vertices;
    HOST_OUTPUT(host_ecal_twoclusters_t, TwoCaloCluster) host_ecal_twoclusters;
    HOST_OUTPUT(host_local_decisions_t, bool) host_local_decisions;
    HOST_OUTPUT(dev_local_decisions_t, bool) dev_local_decisions;
    HOST_OUTPUT(host_ecal_twocluster_offsets_t, unsigned) host_ecal_twocluster_offsets;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minE19_clusters_t, "minE19_clusters", "min E19 of each cluster", float) minE19_clusters;
    PROPERTY(minEt_clusters_t, "minEt_clusters", "min Et of each cluster", float) minEt_clusters;
    PROPERTY(minSumEt_clusters_t, "minSumEt_clusters", "min SumEt of clusters", float) minSumEt_clusters;
    PROPERTY(minEt_t, "minEt", "min Et of the twocluster", float) minEt;
    PROPERTY(minMass_t, "minMass", "min Mass of the two cluster", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "max Mass of the two cluster", float) maxMass;
    PROPERTY(maxNPVs_t, "maxNPVs", "max of PVs", unsigned) maxNPVs;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct two_calo_clusters_line_t : public SelectionAlgorithm, Parameters, Line<two_calo_clusters_line_t, Parameters> {

    void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;

    __device__ static void
    monitor(const Parameters& parameters, std::tuple<const TwoCaloCluster>, unsigned index, bool sel);

    void output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;

    __device__ static bool select(const Parameters& parameters, std::tuple<const TwoCaloCluster> input);

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const;

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_twocluster_offsets[event_number];
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_twocluster_offsets[event_number + 1] -
             parameters.dev_ecal_twocluster_offsets[event_number];
    }

    __device__ static std::tuple<const TwoCaloCluster>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const TwoCaloCluster event_ecal_twoclusters =
        parameters.dev_ecal_twoclusters[parameters.dev_ecal_twocluster_offsets[event_number] + i];
      return std::forward_as_tuple(event_ecal_twoclusters);
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
    Property<minEt_t> m_minEt {this, 0.0f};                          // MeV
    Property<minEt_clusters_t> m_minEt_clusters {this, 200.f};       // MeV
    Property<minSumEt_clusters_t> m_minSumEt_clusters {this, 400.f}; // MeV
    Property<minE19_clusters_t> m_minE19_clusters {this, 0.6f};
    Property<maxNPVs_t> m_maxNPVs {this, UINT_MAX};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
  };
} // namespace two_calo_clusters_line
