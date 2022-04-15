/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "Line.cuh"
#include <string>

namespace gather_selections {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_selections_lines_offsets_t, unsigned) host_selections_lines_offsets;
    HOST_OUTPUT(host_selections_offsets_t, unsigned) host_selections_offsets;
    HOST_OUTPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_OUTPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_INPUT_AGGREGATE(dev_input_selections_t, bool) dev_input_selections;
    DEVICE_INPUT_AGGREGATE(dev_input_selections_offsets_t, unsigned) dev_input_selections_offsets;
    HOST_INPUT_AGGREGATE(host_input_post_scale_factors_t, float) host_input_post_scale_factors;
    HOST_INPUT_AGGREGATE(host_input_post_scale_hashes_t, uint32_t) host_input_post_scale_hashes;
    DEVICE_INPUT_AGGREGATE(dev_fn_parameters_agg_t, char) dev_fn_parameters_agg;
    HOST_OUTPUT(host_fns_parameters_t, char*) host_fns_parameters;
    DEVICE_OUTPUT(dev_fns_parameters_t, char*) dev_fns_parameters;
    HOST_OUTPUT(host_fn_indices_t, unsigned) host_fn_indices;
    DEVICE_OUTPUT(dev_fn_indices_t, unsigned) dev_fn_indices;
    DEVICE_INPUT_AGGREGATE(dev_particle_containers_agg_t, Allen::IMultiEventContainer*)
    dev_particle_containers_agg;
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_OUTPUT(dev_selections_t, bool) dev_selections;
    DEVICE_OUTPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_OUTPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    HOST_OUTPUT(host_post_scale_factors_t, float) host_post_scale_factors;
    HOST_OUTPUT(host_post_scale_hashes_t, uint32_t) host_post_scale_hashes;
    DEVICE_OUTPUT(dev_post_scale_factors_t, float) dev_post_scale_factors;
    DEVICE_OUTPUT(dev_post_scale_hashes_t, uint32_t) dev_post_scale_hashes;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_particle_containers_t,
      DEPENDENCIES(dev_particle_containers_agg_t),
      Allen::IMultiEventContainer*)
    dev_particle_containers;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
    PROPERTY(names_of_active_lines_t, "names_of_active_lines", "names of active lines", std::string);
    PROPERTY(names_of_active_line_algorithms_t, "names_of_active_line_algorithms", "names of active line algorithms", std::string);
  };

  struct gather_selections_t : public HostAlgorithm, Parameters {
    void init();

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    std::vector<unsigned> m_indices_active_line_algorithms;
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<names_of_active_line_algorithms_t> m_names_of_active_line_algorithms {this, ""};
    Property<names_of_active_lines_t> m_names_of_active_lines {this, ""};
  };
} // namespace gather_selections
