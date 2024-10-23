/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "NeuralNetwork.cuh"

namespace downstream_busca_selector {
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Size of downstream vertices
    HOST_INPUT(host_number_of_downstream_secondary_vertices_t, unsigned) host_number_of_downstream_secondary_vertices;
    // Composites
    DEVICE_INPUT(dev_multi_event_composites_view_t, Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_composites_view;
    // Output
    DEVICE_OUTPUT(dev_downstream_mva_busca_t, float) dev_downstream_mva_busca;
    // DEVICE_OUTPUT(dev_downstream_mva_l0_t, float) dev_downstream_mva_l0;
    // DEVICE_OUTPUT(dev_downstream_mva_detached_ks_t, float) dev_downstream_mva_detached_ks;
    // DEVICE_OUTPUT(dev_downstream_mva_detached_l0_t, float) dev_downstream_mva_detached_l0;
    // Property
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void downstream_busca_selector(
    Parameters,
    const Allen::NeuralNetwork::Model::DownstreamBuscaSelector*

  );

  struct downstream_busca_selector_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{16, 1, 1}}};
  };
} // namespace downstream_busca_selector