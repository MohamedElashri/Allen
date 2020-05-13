#pragma once

#include <stdint.h>
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "patPV_Definitions.cuh"
#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "PV_Definitions.cuh"

__device__ bool fit_vertex(
  const PatPV::XYZPoint& seedPoint,
  Velo::Consolidated::ConstKalmanStates& velo_states,
  PV::Vertex& vtx,
  int number_of_tracks,
  uint tracks_offset);

__device__ float get_tukey_weight(float trchi2, int iter);

namespace fit_seeds {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_vertex_t, PV::Vertex) dev_vertex;
    DEVICE_OUTPUT(dev_number_vertex_t, int) dev_number_vertex;
    DEVICE_INPUT(dev_seeds_t, PatPV::XYZPoint) dev_seeds;
    DEVICE_INPUT(dev_number_seeds_t, uint) dev_number_seeds;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void fit_seeds(Parameters);

  template<typename T>
  struct pv_fit_seeds_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(fit_seeds)) function {fit_seeds};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_vertex_t>(
        arguments, PatPV::max_number_vertices * value<host_number_of_selected_events_t>(arguments));
      set_size<dev_number_vertex_t>(arguments, value<host_number_of_selected_events_t>(arguments));
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
        Parameters {begin<dev_vertex_t>(arguments),
                    begin<dev_number_vertex_t>(arguments),
                    begin<dev_seeds_t>(arguments),
                    begin<dev_number_seeds_t>(arguments),
                    begin<dev_velo_kalman_beamline_states_t>(arguments),
                    begin<dev_atomics_velo_t>(arguments),
                    begin<dev_velo_track_hit_number_t>(arguments)});

      if (runtime_options.do_check) {
        // Retrieve result
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_reconstructed_pvs,
          begin<dev_vertex_t>(arguments),
          size<dev_vertex_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_number_of_vertex,
          begin<dev_number_vertex_t>(arguments),
          size<dev_number_vertex_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace fit_seeds