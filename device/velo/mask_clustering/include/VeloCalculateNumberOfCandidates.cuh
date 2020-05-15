#pragma once

#include "DeviceAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_calculate_number_of_candidates {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_INPUT(dev_velo_raw_input_t, char), dev_velo_raw_input),
    (DEVICE_INPUT(dev_velo_raw_input_offsets_t, uint), dev_velo_raw_input_offsets),
    (DEVICE_OUTPUT(dev_number_of_candidates_t, uint), dev_number_of_candidates),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", uint), block_dim_x_prop))

  // Global function
  __global__ void velo_calculate_number_of_candidates(Parameters parameters, const uint number_of_events);

  __global__ void velo_calculate_number_of_candidates_mep(
    Parameters parameters,
    const uint number_of_events);

  // Algorithm
  struct velo_calculate_number_of_candidates_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentRefManager<ParameterTuple<Parameters>::t> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentRefManager<ParameterTuple<Parameters>::t>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
  };
} // namespace velo_calculate_number_of_candidates
