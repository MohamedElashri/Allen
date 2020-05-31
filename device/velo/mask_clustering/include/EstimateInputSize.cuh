/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_estimate_input_size {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_cluster_candidates_t, unsigned), host_number_of_cluster_candidates),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_candidates_offsets_t, unsigned), dev_candidates_offsets),
    (DEVICE_INPUT(dev_velo_raw_input_t, char), dev_velo_raw_input),
    (DEVICE_INPUT(dev_velo_raw_input_offsets_t, unsigned), dev_velo_raw_input_offsets),
    (DEVICE_OUTPUT(dev_estimated_input_size_t, unsigned), dev_estimated_input_size),
    (DEVICE_OUTPUT(dev_module_candidate_num_t, unsigned), dev_module_candidate_num),
    (DEVICE_OUTPUT(dev_cluster_candidates_t, unsigned), dev_cluster_candidates),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void velo_estimate_input_size(Parameters parameters);

  __global__ void velo_estimate_input_size_mep(Parameters parameters);

  struct velo_estimate_input_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{16, 16, 1}}};
  };
} // namespace velo_estimate_input_size
