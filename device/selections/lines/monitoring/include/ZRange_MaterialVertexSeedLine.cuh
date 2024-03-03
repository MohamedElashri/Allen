/*****************************************************************************\
 * (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"
#include "patPV_Definitions.cuh"

namespace z_range_materialvertex_seed_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_total_number_of_interaction_seeds_t, unsigned) host_total_number_of_interactions_seeds;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    DEVICE_INPUT(dev_consolidated_interaction_seeds_t, PatPV::XYZPoint) dev_consolidated_interaction_seeds;
    DEVICE_INPUT(dev_interaction_seeds_offsets_t, unsigned) dev_interaction_seeds_offsets;
    DEVICE_INPUT(dev_event_number_of_interactions_seeds_t, unsigned) dev_event_number_of_interactions_seeds;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_z_materialvertex_seed_t, "min_z_materialvertex_seed", "min z for the material vertex seed", float)
    min_z_materialvertex_seed;
    PROPERTY(max_z_materialvertex_seed_t, "max_z_materialvertex_seed", "max z for the material vertex seed", float)
    max_z_materialvertex_seed;
  };

  // SelectionAlgorithm definition
  struct z_range_materialvertex_seed_line_t : public SelectionAlgorithm,
                                              Parameters,
                                              Line<z_range_materialvertex_seed_line_t, Parameters> {

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
    __device__ static bool select(const Parameters& parameters, std::tuple<const float> input);

  private:
    // Commonly required properties
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Line-specific properties
    Property<min_z_materialvertex_seed_t> m_min_z_materialvertex_seed {this, -1000.f};
    Property<max_z_materialvertex_seed_t> m_max_z_materialvertex_seed {this, 1000.f};
  };
} // namespace z_range_materialvertex_seed_line
