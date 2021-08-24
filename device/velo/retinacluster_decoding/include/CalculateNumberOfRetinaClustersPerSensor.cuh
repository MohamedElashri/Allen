/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "ClusteringDefinitions.cuh"

namespace calculate_number_of_retinaclusters_each_sensor {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, uint) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_retina_raw_input_t, char) dev_velo_retina_raw_input;
    DEVICE_INPUT(dev_velo_retina_raw_input_offsets_t, uint) dev_velo_retina_raw_input_offsets;
    DEVICE_OUTPUT(dev_each_sensor_size_t, uint) dev_each_sensor_size;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim_prop;
  };

  struct calculate_number_of_retinaclusters_each_sensor_t : public DeviceAlgorithm, Parameters {
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
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace calculate_number_of_retinaclusters_each_sensor

// #pragma once
// 
// #include "DeviceAlgorithm.cuh"
// #include "ClusteringDefinitions.cuh"
// 
// namespace calculate_number_of_retinaclusters_each_sensor {
//   DEFINE_PARAMETERS(
//     Parameters,
//     (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
//     (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
//     (DEVICE_INPUT(dev_velo_retina_raw_input_t, char), dev_velo_retina_raw_input),
//     (DEVICE_INPUT(dev_velo_retina_raw_input_offsets_t, uint), dev_velo_retina_raw_input_offsets),
//     (DEVICE_OUTPUT(dev_each_sensor_size_t, uint), dev_each_sensor_size),
//     (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim_prop))
// 
//   __global__ void calculate_number_of_retinaclusters_each_sensor(Parameters parameters);
// 
//   __global__ void calculate_number_of_retinaclusters_each_sensor_mep(Parameters parameters);
// 
//   struct calculate_number_of_retinaclusters_each_sensor_t : public DeviceAlgorithm, Parameters {
//     void set_arguments_size(
//       ArgumentReferences<Parameters> arguments,
//       const RuntimeOptions&,
//       const Constants&,
//       const HostBuffers&) const;
// 
//     void operator()(
//       const ArgumentReferences<Parameters>& arguments,
//       const RuntimeOptions& runtime_options,
//       const Constants&,
//       HostBuffers&,
//       cudaStream_t& cuda_stream,
//       cudaEvent_t&) const;
// 
//   private:
//     Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
//   };
// } // namespace calculate_number_of_retinaclusters_each_sensor
