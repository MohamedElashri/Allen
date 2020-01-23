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
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_OUTPUT(dev_zhisto_t, float) dev_zhisto;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {128, 1, 1});
  };

  __global__ void pv_beamline_histo(Parameters, float* dev_beamline);

  template<typename T, char... S>
  struct pv_beamline_histo_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(pv_beamline_histo)) function {pv_beamline_histo};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_zhisto_t>(arguments, value<host_number_of_selected_events_t>(arguments) * (zmax - zmin) / dz);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                   begin<dev_offsets_velo_track_hit_number_t>(arguments),
                   begin<dev_pvtracks_t>(arguments),
                   begin<dev_zhisto_t>(arguments)},
        constants.dev_beamline.data());
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace pv_beamline_histo