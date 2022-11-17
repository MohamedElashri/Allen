/*****************************************************************************\
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"
#include "States.cuh"

namespace SMOG2_minimum_bias_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_tracks_container_t, Allen::Views::Velo::Consolidated::Tracks) dev_tracks_container;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_tracks_container_t), char) host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minNHits_t, "minNHits", "min number of hits of velo track", unsigned) minNHits;
    PROPERTY(minZ_t, "minZ", "min z coordinate for accepted reconstructed primary vertex", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "max z coordinate for accepted reconstructed primary vertex", float) maxZ;
  };

  // SelectionAlgorithm definition
  struct SMOG2_minimum_bias_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     Line<SMOG2_minimum_bias_line_t, Parameters> {

    // Offset function
    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

    // Get decision size function
    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments);

    // Get input size function
    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number);

    // Get input function
    __device__ static std::tuple<const unsigned, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    // Selection function
    __device__ static bool select(const Parameters& parameters, std::tuple<const unsigned, const float> input);

  private:
    // Commonly required properties
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Line-specific properties
    Property<minNHits_t> m_minNHits {this, 12};
    Property<minZ_t> m_minZ {this, -551.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -331.f * Gaudi::Units::mm};
  };
} // namespace SMOG2_minimum_bias_line
