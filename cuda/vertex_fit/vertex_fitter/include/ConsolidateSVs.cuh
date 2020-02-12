#pragma once

#include "VertexDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace consolidate_svs {
  struct Parameters {
    HOST_INPUT(host_number_of_svs_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_INPUT(dev_secondary_vertices_t, VertexFit::TrackMVAVertex) dev_secondary_vertices;
    DEVICE_OUTPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void consolidate_svs(Parameters);

  template<typename T, char... S>
  struct consolidate_svs_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(consolidate_svs)) function {consolidate_svs};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_consolidated_svs_t>(arguments, value<host_number_of_svs_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_sv_offsets_t>(arguments),
                    begin<dev_secondary_vertices_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments)});

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_secondary_vertices,
          begin<dev_consolidated_svs_t>(arguments),
          size<dev_consolidated_svs_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_sv_atomics,
          begin<dev_sv_offsets_t>(arguments),
          size<dev_sv_offsets_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace consolidate_svs
