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
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;

    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;

    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;

    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
    HOST_OUTPUT(host_particle_container_t, Allen::Views::Physics::IMultiEventParticleContainer*) host_particle_container;

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
    PROPERTY(make_tuple_t, "make_tuple", "Make tuple for monitoring", bool) make_tuple;
  };

  struct single_calo_cluster_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      Line<single_calo_cluster_line_t, Parameters> {

#ifdef WITH_ROOT
    static void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context);

    __device__ static void
    monitor(const Parameters& parameters, std::tuple<const CaloCluster> input, unsigned index, bool sel);

    void output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;
#endif

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

    static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_ecal_number_of_clusters_t>(arguments);
    }

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minEt_t> m_minEt {this, 200.0f};   // MeV
    Property<maxEt_t> m_maxEt {this, 10000.0f}; // MeV
    Property<make_tuple_t> m_make_tuple {this, false};
  };
} // namespace single_calo_cluster_line
