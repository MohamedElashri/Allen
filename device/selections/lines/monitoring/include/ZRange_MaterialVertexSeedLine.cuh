/*****************************************************************************\
 * (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"

namespace z_range_materialvertex_seed_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_total_number_of_interaction_seeds_t, unsigned) host_total_number_of_interactions_seeds;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    DEVICE_INPUT(dev_consolidated_interaction_seeds_t, float3) dev_consolidated_interaction_seeds;
    DEVICE_INPUT(dev_interaction_seeds_offsets_t, unsigned) dev_interaction_seeds_offsets;
  };

  // SelectionAlgorithm definition
  struct z_range_materialvertex_seed_line_t : public SelectionAlgorithm,
                                              Parameters,
                                              Line<z_range_materialvertex_seed_line_t, Parameters> {
    struct DeviceProperties {
      float min_z_materialvertex_seed;
      float max_z_materialvertex_seed;
      DeviceProperties(const z_range_materialvertex_seed_line_t& algo, const Allen::Context&) :
        min_z_materialvertex_seed(algo.m_min_z_materialvertex_seed),
        max_z_materialvertex_seed(algo.m_max_z_materialvertex_seed)
      {}
    };

    // Offset function
    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

    // Get decision size function
    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments);

    // Get input size function
    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number);

    // Get input function
    __device__ static std::tuple<const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    // Selection function
    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const float> input);

  private:
    // Commonly required properties
    // Line-specific properties
    Allen::Property<float> m_min_z_materialvertex_seed {this,
                                                        "min_z_materialvertex_seed",
                                                        -1000.f,
                                                        "min z for the material vertex seed"};
    Allen::Property<float> m_max_z_materialvertex_seed {this,
                                                        "max_z_materialvertex_seed",
                                                        1000.f,
                                                        "max z for the material vertex seed"};
  };
} // namespace z_range_materialvertex_seed_line
