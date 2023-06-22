/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "ROOTService.h"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <CaloDigit.cuh>
#include <CaloCluster.cuh>

namespace single_calo_cluster_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    DEVICE_INPUT(dev_ecal_number_of_clusters_t, unsigned) dev_ecal_number_of_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_clusters_t, CaloCluster) dev_ecal_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // monitoring
    DEVICE_OUTPUT(clusters_x_t, float) clusters_x;
    DEVICE_OUTPUT(clusters_y_t, float) clusters_y;
    DEVICE_OUTPUT(clusters_Et_t, float) clusters_Et;
    DEVICE_OUTPUT(clusters_Eta_t, float) clusters_Eta;
    DEVICE_OUTPUT(clusters_Phi_t, float) clusters_Phi;
    //

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minEt_t, "minEt", "minEt description", float) minEt;
    PROPERTY(maxEt_t, "maxEt", "maxEt description", float) maxEt;
    PROPERTY(max_ecal_clusters_t, "max_ecal_clusters", "Maximum number of VELO tracks", unsigned) max_ecal_clusters;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line monitoring", bool) enable_tupling;
  };

  struct single_calo_cluster_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      Line<single_calo_cluster_line_t, Parameters> {

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const CaloCluster, const unsigned> input,
      unsigned index,
      bool sel);

    __device__ static bool select(const Parameters& ps, std::tuple<const CaloCluster, const unsigned> input);

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_cluster_offsets[event_number];
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_cluster_offsets[event_number + 1] - parameters.dev_ecal_cluster_offsets[event_number];
    }

    __device__ static std::tuple<const CaloCluster, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const unsigned ecal_number_of_clusters = parameters.dev_ecal_number_of_clusters[event_number];
      const CaloCluster event_ecal_clusters =
        parameters.dev_ecal_clusters[parameters.dev_ecal_cluster_offsets[event_number] + i];
      return std::forward_as_tuple(event_ecal_clusters, ecal_number_of_clusters);
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
    Property<max_ecal_clusters_t> m_max_ecal_clusters {this, UINT_MAX};
    Property<enable_tupling_t> m_enable_tupling {this, false};
  };
} // namespace single_calo_cluster_line
