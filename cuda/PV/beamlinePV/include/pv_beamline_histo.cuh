#pragma once

#include <cstdint>
#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "FloatOperations.cuh"

namespace pv_beamline_histo {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_OUTPUT(dev_zhisto_t, float) dev_zhisto;
  };

  __global__ void pv_beamline_histo(Arguments arguments, float* dev_beamline);

  template<typename T>
  struct pv_beamline_histo_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"pv_beamline_histo_t"};
    decltype(global_function(pv_beamline_histo)) function {pv_beamline_histo};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_zhisto_t>(manager, value<host_number_of_selected_events_t>(manager) * (zmax - zmin) / dz);
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
        Arguments {offset<dev_atomics_velo_t>(manager),
                   offset<dev_velo_track_hit_number_t>(manager),
                   offset<dev_pvtracks_t>(manager),
                   offset<dev_zhisto_t>(manager)},
        constants.dev_beamline.data());
    }
  };
} // namespace pv_beamline_histo