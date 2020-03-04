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
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void pv_beamline_histo(Parameters, float* dev_beamline);

  template<typename T, char... S>
  struct pv_beamline_histo_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(pv_beamline_histo)) function {pv_beamline_histo};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const {
      set_size<dev_zhisto_t>(arguments, value<host_number_of_selected_events_t>(arguments) * (BeamlinePVConstants::Common::zmax - BeamlinePVConstants::Common::zmin) / BeamlinePVConstants::Common::dz);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                   begin<dev_offsets_velo_track_hit_number_t>(arguments),
                   begin<dev_pvtracks_t>(arguments),
                   begin<dev_zhisto_t>(arguments)},
        constants.dev_beamline.data());
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };
} // namespace pv_beamline_histo