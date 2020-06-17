#pragma once

#include "VertexDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace consolidate_svs {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_svs_t, unsigned), host_number_of_svs),
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_sv_offsets_t, unsigned), dev_sv_offsets),
    (DEVICE_INPUT(dev_secondary_vertices_t, VertexFit::TrackMVAVertex), dev_secondary_vertices),
    (DEVICE_OUTPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex), dev_consolidated_svs),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void consolidate_svs(Parameters);

  struct consolidate_svs_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace consolidate_svs
