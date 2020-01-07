#pragma once

#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

namespace pv_beamline_extrapolate {
  struct Arguments {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_OUTPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_OUTPUT(dev_pvtrack_z_t, float) dev_pvtrack_z;
  };

  __global__ void pv_beamline_extrapolate(Arguments);

  template<typename T>
  struct pv_beamline_extrapolate_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"pv_beamline_extrapolate_t"};
    decltype(global_function(pv_beamline_extrapolate)) function {pv_beamline_extrapolate};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_pvtracks_t>(manager, value<host_number_of_reconstructed_velo_tracks_t>(manager));
      set_size<dev_pvtrack_z_t>(manager, 2 * value<host_number_of_reconstructed_velo_tracks_t>(manager));
    }

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function.invoke(dim3(value<host_number_of_selected_events_t>(manager)), block_dimension(), cuda_stream)(
        Arguments {offset<dev_velo_kalman_beamline_states_t>(manager),
                   offset<dev_atomics_velo_t>(manager),
                   offset<dev_velo_track_hit_number_t>(manager),
                   offset<dev_pvtracks_t>(manager),
                   offset<dev_pvtrack_z_t>(manager)});
    }
  };
} // namespace pv_beamline_extrapolate