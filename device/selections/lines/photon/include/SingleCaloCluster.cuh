/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "ROOTService.h"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace single_calo_cluster_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // monitoring
    DEVICE_OUTPUT(dev_clusters_x_t, float) dev_clusters_x;
    HOST_OUTPUT(host_clusters_x_t, float) host_clusters_x;

    DEVICE_OUTPUT(dev_clusters_y_t, float) dev_clusters_y;
    HOST_OUTPUT(host_clusters_y_t, float) host_clusters_y;

    DEVICE_OUTPUT(dev_clusters_Et_t, float) dev_clusters_Et;
    HOST_OUTPUT(host_clusters_Et_t, float) host_clusters_Et;

    DEVICE_OUTPUT(dev_clusters_Eta_t, float) dev_clusters_Eta;
    HOST_OUTPUT(host_clusters_Eta_t, float) host_clusters_Eta;

    DEVICE_OUTPUT(dev_clusters_Phi_t, float) dev_clusters_Phi;
    HOST_OUTPUT(host_clusters_Phi_t, float) host_clusters_Phi;
    //

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minEt_t, "minEt", "minEt description", float) minEt;
    PROPERTY(maxEt_t, "maxEt", "maxEt description", float) maxEt;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct single_calo_cluster_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      Line<single_calo_cluster_line_t, Parameters> {

    void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;

    __device__ static void
    monitor(const Parameters& parameters, std::tuple<const CaloCluster> input, unsigned index, bool sel);

    void output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;

    __device__ static bool select(const Parameters& ps, std::tuple<const CaloCluster> input);

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_cluster_offsets[event_number];
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_cluster_offsets[event_number + 1] - parameters.dev_ecal_cluster_offsets[event_number];
    }

    __device__ static std::tuple<const CaloCluster>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const CaloCluster event_ecal_clusters =
        parameters.dev_ecal_clusters[parameters.dev_ecal_cluster_offsets[event_number] + i];
      return std::forward_as_tuple(event_ecal_clusters);
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<host_ecal_number_of_clusters_t>(arguments);
    }

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minEt_t> m_minEt {this, 200.0f};   // MeV
    Property<maxEt_t> m_maxEt {this, 10000.0f}; // MeV
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
  };
} // namespace single_calo_cluster_line
