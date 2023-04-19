/*****************************************************************************\
 * (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "EventLine.cuh"

namespace n_materialvertex_seed_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_number_of_materialvertex_seeds_t, unsigned) dev_number_of_materialvertex_seeds;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_materialvertex_seeds_t, "min_materialvertex_seeds", "min number of material vertex seeds", unsigned)
    min_materialvertex_seeds;
  };

  // SelectionAlgorithm definition
  struct n_materialvertex_seed_line_t : public SelectionAlgorithm,
                                        Parameters,
                                        EventLine<n_materialvertex_seed_line_t, Parameters> {

    // Get input function
    __device__ static std::tuple<const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    // Selection function
    __device__ static bool select(const Parameters& parameters, std::tuple<const unsigned> input);

  private:
    // Commonly required properties
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Line-specific properties
    Property<min_materialvertex_seeds_t> m_min_materialvertex_seeds {this, 2};
  };
} // namespace n_materialvertex_seed_line
