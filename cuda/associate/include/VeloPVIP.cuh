#pragma once

// Associate Velo tracks to PVs using their impact parameter and store
// the calculated values.
#include "PV_Definitions.cuh"
#include "AssociateConsolidated.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"

namespace velo_pv_ip {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_OUTPUT(dev_velo_pv_ip_t, char) dev_velo_pv_ip;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void velo_pv_ip(Parameters);

  template<typename T, char... S>
  struct velo_pv_ip_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_pv_ip)) function {velo_pv_ip};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      auto n_velo_tracks = value<host_number_of_reconstructed_velo_tracks_t>(arguments);
      set_size<dev_velo_pv_ip_t>(arguments, Associate::Consolidated::table_size(n_velo_tracks));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_velo_kalman_beamline_states_t>(arguments),
                   begin<dev_offsets_all_velo_tracks_t>(arguments),
                   begin<dev_offsets_velo_track_hit_number_t>(arguments),
                   begin<dev_multi_fit_vertices_t>(arguments),
                   begin<dev_number_of_multi_fit_vertices_t>(arguments),
                   begin<dev_velo_pv_ip_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_pv_ip