/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "ParticleTypes.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"

namespace flatten_svs {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_composite_offsets_t, unsigned) dev_composite_offsets;
    DEVICE_INPUT(dev_input_sv_mec_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_input_sv_mec;

    DEVICE_OUTPUT(dev_sv_info_t, char) dev_sv_info;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_info_view_t,
      DEPENDENCIES(dev_sv_info_t),
      Allen::Views::Physics::SecondaryVertices)
    dev_sv_info_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_composite_view_t,
      DEPENDENCIES(dev_input_sv_mec_t, dev_sv_info_view_t),
      Allen::Views::Physics::CompositeParticle)
    dev_composite_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_composites_view_t,
      DEPENDENCIES(dev_composite_view_t),
      Allen::Views::Physics::CompositeParticles)
    dev_composites_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_composites_view_t,
      DEPENDENCIES(dev_composites_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_composites_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_composites_ptr_t,
      DEPENDENCIES(dev_multi_event_composites_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_composites_ptr;

    // PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void create_flat_views(Parameters parameters);

  struct flatten_svs_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "Block dimensions"};
  };
} // namespace flatten_svs