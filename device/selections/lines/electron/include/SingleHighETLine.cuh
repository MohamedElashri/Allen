/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "Line.cuh"
#include "VeloConsolidated.cuh"

namespace single_high_et_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Velo tracks
    DEVICE_INPUT(dev_velo_tracks_offsets_t, unsigned) dev_velo_tracks_offsets;
    // ECAL
    DEVICE_INPUT(dev_brem_ET_t, float) dev_brem_ET;
    // Outputs
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // Properties
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minET_t, "minET", "min Et of brem cluster", float) minET;
  };

  // SelectionAlgorithm definition
  struct single_high_et_line_t : public SelectionAlgorithm, Parameters, Line<single_high_et_line_t, Parameters> {
    // Offset function
    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number);

    // Get decision size function
    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments);

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
    Property<minET_t> m_minET {this, 15000.f};
  };
} // namespace single_high_et_line
