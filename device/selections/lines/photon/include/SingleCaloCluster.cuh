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
  };

  struct single_calo_cluster_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CaloClusterLine<single_calo_cluster_line_t, Parameters> {

    struct DeviceProperties {
      float minEt;
      float maxEt;
      float minAbsY_cluster;
      unsigned max_ecal_clusters;
      DeviceProperties(const single_calo_cluster_line_t& algo, const Allen::Context&) :
        minEt(algo.m_minEt), maxEt(algo.m_maxEt), minAbsY_cluster(algo.m_minAbsY_cluster),
        max_ecal_clusters(algo.m_max_ecal_clusters)
      {}
    };

    __device__ static std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const auto calos = parameters.dev_particle_container->container(event_number);
      const auto calo = calos.particle(i);
      return std::forward_as_tuple(calo, calos.size());
    }

    __device__ static bool select(
      const Parameters& ps,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input);

    __device__ static bool fill_tuples(
      const Parameters& parameters,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle, const unsigned> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_minEt {this, "minEt", 200.0f, "minEt description"};                     // MeV
    Allen::Property<float> m_maxEt {this, "maxEt", 999999.f, "maxEt description"};                   // MeV
    Allen::Property<float> m_minAbsY_cluster {this, "minAbsY_cluster", -1.0f, "min |Y| of cluster"}; // mm
    Allen::Property<unsigned> m_max_ecal_clusters {this,
                                                   "max_ecal_clusters",
                                                   UINT_MAX,
                                                   "Maximum number of VELO tracks"};
  };
} // namespace single_calo_cluster_line
