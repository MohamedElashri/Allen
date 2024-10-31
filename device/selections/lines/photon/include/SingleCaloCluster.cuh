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
#include "CaloClusterLine.cuh"
#include <CaloDigit.cuh>
#include <CaloCluster.cuh>

namespace single_calo_cluster_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventNeutralBasicParticles)
    dev_particle_container;

    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

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
    PROPERTY(minAbsY_cluster_t, "minAbsY_cluster", "min |Y| of cluster", float) minAbsY_cluster;
    PROPERTY(max_ecal_clusters_t, "max_ecal_clusters", "Maximum number of VELO tracks", unsigned) max_ecal_clusters;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line monitoring", bool) enable_tupling;
  };

  struct single_calo_cluster_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CaloClusterLine<single_calo_cluster_line_t, Parameters> {

    __device__ static std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const auto calos = parameters.dev_particle_container->container(event_number);
      const auto calo = calos.particle(i);
      return std::forward_as_tuple(calo, calos.size());
    }

    void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input,
      unsigned index,
      bool sel);

    void output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;

    __device__ static bool select(
      const Parameters& ps,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input,
      unsigned index,
      bool sel);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minEt_t> m_minEt {this, 200.0f};                  // MeV
    Property<maxEt_t> m_maxEt {this, 999999.f};                // MeV
    Property<minAbsY_cluster_t> minAbsY_cluster {this, -1.0f}; // mm
    Property<max_ecal_clusters_t> m_max_ecal_clusters {this, UINT_MAX};
    Property<enable_tupling_t> m_enable_tupling {this, false};
  };
} // namespace single_calo_cluster_line
