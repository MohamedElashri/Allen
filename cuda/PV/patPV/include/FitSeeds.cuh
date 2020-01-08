#pragma once

#include <stdint.h>
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "patPV_Definitions.cuh"
#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "PV_Definitions.cuh"

__device__ bool fit_vertex(
  PatPV::XYZPoint& seedPoint,
  Velo::Consolidated::KalmanStates velo_states,
  PV::Vertex& vtx,
  int number_of_tracks,
  uint tracks_offset);

__device__ float get_tukey_weight(float trchi2, int iter);

namespace fit_seeds {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_vertex_t, PV::Vertex) dev_vertex;
    DEVICE_INPUT(dev_number_vertex_t, int) dev_number_vertex;
    DEVICE_INPUT(dev_seeds_t, PatPV::XYZPoint) dev_seeds;
    DEVICE_INPUT(dev_number_seeds_t, uint) dev_number_seeds;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
  };

  __global__ void fit_seeds(Parameters);

  template<typename T>
  struct pv_fit_seeds_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"pv_fit_seeds_t"};
    decltype(global_function(fit_seeds)) function {fit_seeds};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_vertex_t>(
        arguments, PatPV::max_number_vertices * value<host_number_of_selected_events_t>(arguments));
      set_size<dev_number_vertex_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_vertex_t>(arguments),
                    offset<dev_number_vertex_t>(arguments),
                    offset<dev_seeds_t>(arguments),
                    offset<dev_number_seeds_t>(arguments),
                    offset<dev_velo_kalman_beamline_states_t>(arguments),
                    offset<dev_atomics_velo_t>(arguments),
                    offset<dev_velo_track_hit_number_t>(arguments)});

      if (runtime_options.do_check) {
        // Retrieve result
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_reconstructed_pvs,
          offset<dev_vertex_t>(arguments),
          size<dev_vertex_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_number_of_vertex,
          offset<dev_number_vertex_t>(arguments),
          size<dev_number_vertex_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace fit_seeds