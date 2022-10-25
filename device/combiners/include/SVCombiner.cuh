/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VertexDefinitions.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace SVCombiner {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_combos_t, unsigned) host_number_of_combos;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_max_combo_offsets_t, unsigned) dev_max_combo_offsets;
    DEVICE_INPUT(dev_combo_offsets_t, unsigned) dev_combo_offsets;
    DEVICE_INPUT(dev_secondary_vertices_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_secondary_vertices;
    DEVICE_INPUT(dev_child1_idx_t, unsigned) dev_child1_idx;
    DEVICE_INPUT(dev_child2_idx_t, unsigned) dev_child2_idx;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_child_pointers_t,
      DEPENDENCIES(dev_secondary_vertices_t),
      std::array<const Allen::Views::Physics::IParticle*, 4>)
    dev_child_pointers;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_combo_view_t,
      DEPENDENCIES(dev_child_pointers_t),
      Allen::Views::Physics::CompositeParticle)
    dev_combo_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_combos_view_t,
      DEPENDENCIES(dev_combo_view_t),
      Allen::Views::Physics::CompositeParticles)
    dev_combos_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_combos_view_t,
      DEPENDENCIES(dev_combos_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_combos_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_combos_ptr_t,
      DEPENDENCIES(dev_multi_event_combos_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles*)
    dev_multi_event_combos_ptr;

    // Set all properties to filter svs
    PROPERTY(block_dim_filter_t, "block_dim_filter", "block dimensions for filter step", DeviceDimensions)
    block_dim_filter;
  };

  __global__ void combine_svs(Parameters);

  struct sv_combiner_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_filter_t> m_block_dim_filter {this, {{16, 16, 1}}};
  };
} // namespace SVCombiner
