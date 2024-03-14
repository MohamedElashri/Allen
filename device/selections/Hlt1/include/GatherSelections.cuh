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

#include <string>

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "Line.cuh"
#include "ODINBank.cuh"

#ifndef ALLEN_STANDALONE
#include "SelectionsEventModel.cuh"
#include "Gaudi/Accumulators.h"
#include "GaudiMonitoring.h"
#endif

namespace gather_selections {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_selections_lines_offsets_t, unsigned) host_selections_lines_offsets;
    HOST_OUTPUT(host_selections_offsets_t, unsigned) host_selections_offsets;
    HOST_OUTPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_OUTPUT(host_names_of_active_lines_t, char) host_names_of_active_lines;
    HOST_INPUT_AGGREGATE(host_input_line_data_t, LineData) host_input_line_data;
    HOST_INPUT_AGGREGATE(host_fn_parameters_agg_t, char) host_fn_parameters_agg;
    DEVICE_OUTPUT(dev_fn_parameters_t, char) dev_fn_parameters;
    HOST_OUTPUT(host_fn_parameter_pointers_t, char*) host_fn_parameter_pointers;
    DEVICE_OUTPUT(dev_fn_parameter_pointers_t, char*) dev_fn_parameter_pointers;
    HOST_OUTPUT(host_fn_indices_t, unsigned) host_fn_indices;
    DEVICE_OUTPUT(dev_fn_indices_t, unsigned) dev_fn_indices;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    DEVICE_OUTPUT(dev_selections_t, uint32_t) dev_selections;
    DEVICE_OUTPUT(dev_selections_lines_offsets_t, unsigned) dev_selections_lines_offsets;
    DEVICE_OUTPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_OUTPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    DEVICE_OUTPUT(dev_line_data_t, LineData) dev_line_data;
    DEVICE_OUTPUT(dev_pre_scale_event_lists_t, unsigned) dev_pre_scale_event_lists;
    DEVICE_OUTPUT(dev_pre_scale_event_lists_size_t, unsigned) dev_pre_scale_event_lists_size;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_particle_containers_t,
      DEPENDENCIES(host_fn_parameters_agg_t),
      Allen::IMultiEventContainer*)
    dev_particle_containers;
    HOST_OUTPUT(host_event_list_output_size_t, unsigned) host_event_list_output_size;
    DEVICE_OUTPUT(dev_event_list_output_size_t, unsigned) dev_event_list_output_size;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
    PROPERTY(names_of_active_lines_t, "names_of_active_lines", "names of active lines", std::string);
    PROPERTY(
      names_of_active_line_algorithms_t,
      "names_of_active_line_algorithms",
      "names of active line algorithms",
      std::string);
  };

  struct gather_selections_t : public BarrierAlgorithm, Parameters {
    void init();

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    std::vector<unsigned> m_indices_active_line_algorithms;
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<names_of_active_line_algorithms_t> m_names_of_active_line_algorithms {this, ""};
    Property<names_of_active_lines_t> m_names_of_active_lines {this, ""};

#ifndef ALLEN_STANDALONE
  private:
    mutable std::vector<std::unique_ptr<Gaudi::Accumulators::Counter<>>> m_pass_counters;
    mutable std::vector<std::unique_ptr<Gaudi::Accumulators::Counter<>>> m_rate_counters;
    gaudi_monitoring::Lockable_Histogram<>* histogram_line_passes;
    gaudi_monitoring::Lockable_Histogram<>* histogram_line_rates;
#endif
  };
} // namespace gather_selections
