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

namespace pv_beamline_multi_fitter {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_INPUT(dev_pvtracks_denom_t, float) dev_pvtracks_denom;
    DEVICE_INPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_INPUT(dev_number_of_zpeaks_t, uint) dev_number_of_zpeaks;
    DEVICE_OUTPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_INPUT(dev_pvtrack_z_t, float) dev_pvtrack_z;
    DEVICE_OUTPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
  };

  __global__ void pv_beamline_multi_fitter(Arguments arguments, const float* dev_beamline);

  template<typename T>
  struct pv_beamline_multi_fitter_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"pv_beamline_multi_fitter_t"};
    decltype(global_function(pv_beamline_multi_fitter)) function {pv_beamline_multi_fitter};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_multi_fit_vertices_t>(
        manager, value<host_number_of_selected_events_t>(manager) * PV::max_number_vertices);
      set_size<dev_number_of_multi_fit_vertices_t>(manager, value<host_number_of_selected_events_t>(manager));
      set_size<dev_pvtracks_denom_t>(manager, value<host_number_of_reconstructed_velo_tracks_t>(manager));
    }

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        offset<dev_number_of_multi_fit_vertices_t>(manager),
        0,
        size<dev_number_of_multi_fit_vertices_t>(manager),
        cuda_stream));

      function.invoke(dim3(value<host_number_of_selected_events_t>(manager)), block_dimension(), cuda_stream)(
        Arguments {offset<dev_atomics_velo_t>(manager),
                   offset<dev_velo_track_hit_number_t>(manager),
                   offset<dev_pvtracks_t>(manager),
                   offset<dev_pvtracks_denom_t>(manager),
                   offset<dev_zpeaks_t>(manager),
                   offset<dev_number_of_zpeaks_t>(manager),
                   offset<dev_multi_fit_vertices_t>(manager),
                   offset<dev_number_of_multi_fit_vertices_t>(manager),
                   offset<dev_pvtrack_z_t>(manager)},
        constants.dev_beamline.data());
    }
  };
} // namespace pv_beamline_multi_fitter