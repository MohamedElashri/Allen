/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "EventLine.cuh"
#include "Plume.cuh"

namespace plume_activity_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_plume_t, Plume_) dev_plume;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_plume_adc_t, "min_plume_adc", "ADC threshold", unsigned) min_plume_adc;
    PROPERTY(
      min_number_plume_adcs_over_min_t,
      "min_number_plume_adcs_over_min",
      "Number of ADCs over configured threshold",
      unsigned)
    min_number_plume_adcs_over_min;
    PROPERTY(plume_channel_mask_t, "plume_channel_mask_t", "PLUME channel mask as a 64-bit bitset", uint64_t)
    plume_channel_mask;
  };

  struct plume_activity_line_t : public SelectionAlgorithm, Parameters, EventLine<plume_activity_line_t, Parameters> {
    __device__ static std::tuple<const uint64_t>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned);

    __device__ static bool select(const Parameters& parameters, std::tuple<const uint64_t> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<min_plume_adc_t> m_min_plume_adc {this, 1};
    Property<min_number_plume_adcs_over_min_t> m_min_number_plume_adcs_over_min {this, 1};
    Property<plume_channel_mask_t> plume_channel_mask {this, 0x003FFFFF003FFFFF};
  };
} // namespace plume_activity_line
