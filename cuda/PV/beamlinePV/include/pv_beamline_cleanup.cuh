#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

namespace pv_beamline_cleanup {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_OUTPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_OUTPUT(dev_number_of_multi_final_vertices_t, uint) dev_number_of_multi_final_vertices;
  };

  __global__ void pv_beamline_cleanup(Parameters);

  template<typename T>
  struct pv_beamline_cleanup_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"pv_beamline_cleanup_t"};
    decltype(global_function(pv_beamline_cleanup)) function {pv_beamline_cleanup};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_multi_final_vertices_t>(arguments,
        value<host_number_of_selected_events_t>(arguments) * PV::max_number_vertices);
      set_size<dev_number_of_multi_final_vertices_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(cudaMemsetAsync(
        offset<dev_number_of_multi_final_vertices_t>(arguments),
        0,
        size<dev_number_of_multi_final_vertices_t>(arguments),
        cuda_stream));

      function.invoke(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        offset<dev_multi_fit_vertices_t>(arguments),
        offset<dev_number_of_multi_fit_vertices_t>(arguments),
        offset<dev_multi_final_vertices_t>(arguments),
        offset<dev_number_of_multi_final_vertices_t>(arguments));

      if (runtime_options.do_check) {
        // Retrieve result
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_reconstructed_multi_pvs,
          offset<dev_multi_final_vertices_t>(arguments),
          size<dev_multi_final_vertices_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_number_of_multivertex,
          offset<dev_number_of_multi_final_vertices_t>(arguments),
          size<dev_number_of_multi_final_vertices_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace pv_beamline_cleanup