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

namespace downstream_composite_selector {

  using PromptSelector = Allen::MVAModels::SingleLayerFCNN<8, 32>;
  using DetachedSelector = Allen::MVAModels::SingleLayerFCNN<7, 32>;
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
    DEVICE_OUTPUT(dev_downstream_mva_ks_t, float) dev_downstream_mva_ks;
    DEVICE_OUTPUT(dev_downstream_mva_l0_t, float) dev_downstream_mva_l0;
    DEVICE_OUTPUT(dev_downstream_mva_detached_ks_t, float) dev_downstream_mva_detached_ks;
    DEVICE_OUTPUT(dev_downstream_mva_detached_l0_t, float) dev_downstream_mva_detached_l0;
    // Property
  };

  __global__ void downstream_composite_selector(
    Parameters,
    const PromptSelector::DeviceType*,
    const PromptSelector::DeviceType*,
    const DetachedSelector::DeviceType*,
    const DetachedSelector::DeviceType*);

  struct downstream_composite_selector_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {16, 1, 1}, "block dimensions"};

    PromptSelector lambda_selector {"lambda_selector", "/HLT1Downstream/Hlt1_Downstream_LambdaSelector.json"};
    PromptSelector ks_selector {"ks_selector", "/HLT1Downstream/Hlt1_Downstream_KshortSelector.json"};
    DetachedSelector lambda_detached_selector {"lambda_detached_selector",
                                               "/HLT1Downstream/Hlt1_Downstream_DetachedLambdaSelector.json"};
    DetachedSelector ks_detached_selector {"ks_detached_selector",
                                           "/HLT1Downstream/Hlt1_Downstream_DetachedKshortSelector.json"};
  };
} // namespace downstream_composite_selector