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
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void pv_beamline_cleanup(Parameters);

  template<typename T>
  struct pv_beamline_cleanup_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(pv_beamline_cleanup)) function {pv_beamline_cleanup};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_multi_final_vertices_t>(
        arguments, first<host_number_of_selected_events_t>(arguments) * PV::max_number_vertices);
      set_size<dev_number_of_multi_final_vertices_t>(arguments, first<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_number_of_multi_final_vertices_t>(arguments, 0, cuda_stream);

      function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {data<dev_multi_fit_vertices_t>(arguments),
                    data<dev_number_of_multi_fit_vertices_t>(arguments),
                    data<dev_multi_final_vertices_t>(arguments),
                    data<dev_number_of_multi_final_vertices_t>(arguments)});

      // Retrieve result
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_reconstructed_multi_pvs,
        data<dev_multi_final_vertices_t>(arguments),
        size<dev_multi_final_vertices_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_number_of_multivertex,
        data<dev_number_of_multi_final_vertices_t>(arguments),
        size<dev_number_of_multi_final_vertices_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace pv_beamline_cleanup
