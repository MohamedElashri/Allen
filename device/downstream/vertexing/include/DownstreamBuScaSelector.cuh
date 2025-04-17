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
#include "SingleLayerFCNN.cuh"
#include "VertexDefinitions.cuh"

namespace downstream_busca_selector {

  using DownstreamBuscaSelector = Allen::MVAModels::SingleLayerFCNN<8, 32>;
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
    // Property
  };

  __global__ void downstream_busca_selector(Parameters, const DownstreamBuscaSelector::DeviceType*);

  struct downstream_busca_selector_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {16, 1, 1}, "block dimensions"};

    Allen::Property<std::string> m_NN_selection_path {this,
                                                      "nn_selection_path",
                                                      "/HLT1Downstream/Hlt1_Downstream_BuScaSelector_v2r1.json",
                                                      "path to NN which should be used for selection"};

    DownstreamBuscaSelector m_busca_selector {"busca_selector", m_NN_selection_path};
  };
} // namespace downstream_busca_selector