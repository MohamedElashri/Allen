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

namespace pv_beamline_calculate_denom {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_OUTPUT(dev_pvtracks_denom_t, float) dev_pvtracks_denom;
    DEVICE_INPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_INPUT(dev_number_of_zpeaks_t, uint) dev_number_of_zpeaks;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void pv_beamline_calculate_denom(Parameters);

  template<typename T, char... S>
  struct pv_beamline_calculate_denom_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(pv_beamline_calculate_denom)) function {pv_beamline_calculate_denom};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const {
      set_size<dev_pvtracks_denom_t>(arguments, value<host_number_of_reconstructed_velo_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters{
          begin<dev_offsets_all_velo_tracks_t>(arguments),
          begin<dev_offsets_velo_track_hit_number_t>(arguments),
          begin<dev_pvtracks_t>(arguments),
          begin<dev_pvtracks_denom_t>(arguments),
          begin<dev_zpeaks_t>(arguments),
          begin<dev_number_of_zpeaks_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
}