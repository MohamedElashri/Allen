#pragma once

#include <stdint.h>
#include "VeloEventModel.cuh"
#include "States.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "VeloConsolidated.cuh"

namespace velo_kalman_filter {
  __device__ void velo_kalman_filter_step(
    const float z,
    const float zhit,
    const float xhit,
    const float whit,
    float& x,
    float& tx,
    float& covXX,
    float& covXTx,
    float& covTxTx);

  /**
   * @brief Fit the track with a Kalman filter,
   *        allowing for some scattering at every hit
   */
  template<bool upstream>
  __device__ KalmanVeloState
  simplified_fit(const Velo::Consolidated::Hits consolidated_hits, const MiniState& stateAtBeamLine, const uint nhits)
  {
    // backward = state.z > track.hits[0].z;
    const bool backward = stateAtBeamLine.z > consolidated_hits.z[0];
    const int direction = (backward ? 1 : -1) * (upstream ? 1 : -1);
    const float noise2PerLayer =
      1e-8f + 7e-6f * (stateAtBeamLine.tx * stateAtBeamLine.tx + stateAtBeamLine.ty * stateAtBeamLine.ty);

    // assume the hits are sorted,
    // but don't assume anything on the direction of sorting
    int firsthit = 0;
    int lasthit = nhits - 1;
    int dhit = 1;
    if ((consolidated_hits.z[lasthit] - consolidated_hits.z[firsthit]) * direction < 0) {
      const int temp = firsthit;
      firsthit = lasthit;
      lasthit = temp;
      dhit = -1;
    }

    // We filter x and y simultaneously but take them uncorrelated.
    // filter first the first hit.
    KalmanVeloState state;
    state.x = consolidated_hits.x[firsthit];
    state.y = consolidated_hits.y[firsthit];
    state.z = consolidated_hits.z[firsthit];
    state.tx = stateAtBeamLine.tx;
    state.ty = stateAtBeamLine.ty;

    // Initialize the covariance matrix
    state.c00 = Velo::Tracking::param_w_inverted;
    state.c11 = Velo::Tracking::param_w_inverted;
    state.c20 = 0.f;
    state.c31 = 0.f;
    state.c22 = 1.f;
    state.c33 = 1.f;

    // add remaining hits
    for (auto i = firsthit + dhit; i != lasthit + dhit; i += dhit) {
      int hitindex = i;
      const auto hit_x = consolidated_hits.x[hitindex];
      const auto hit_y = consolidated_hits.y[hitindex];
      const auto hit_z = consolidated_hits.z[hitindex];

      // add the noise
      state.c22 += noise2PerLayer;
      state.c33 += noise2PerLayer;

      // filter X and filter Y
      velo_kalman_filter_step(
        state.z, hit_z, hit_x, Velo::Tracking::param_w, state.x, state.tx, state.c00, state.c20, state.c22);
      velo_kalman_filter_step(
        state.z, hit_z, hit_y, Velo::Tracking::param_w, state.y, state.ty, state.c11, state.c31, state.c33);

      // update z (note done in the filter, since needed only once)
      state.z = hit_z;
    }

    // add the noise at the last hit
    state.c22 += noise2PerLayer;
    state.c33 += noise2PerLayer;

    // finally, store the state
    return state;
  }

  struct Arguments {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_offsets_velo_tracks_t, uint) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_OUTPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
  };

  __global__ void velo_kalman_filter(Arguments);

  template<typename T>
  struct velo_kalman_filter_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"velo_kalman_filter_t"};
    decltype(global_function(velo_kalman_filter)) function {velo_kalman_filter};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_velo_kalman_beamline_states_t>(
        manager, value<host_number_of_reconstructed_velo_tracks_t>(manager) * sizeof(KalmanVeloState));
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
        Arguments {offset<dev_offsets_velo_tracks_t>(manager),
                   offset<dev_offsets_velo_track_hit_number_t>(manager),
                   offset<dev_velo_track_hits_t>(manager),
                   offset<dev_velo_states_t>(manager),
                   offset<dev_velo_kalman_beamline_states_t>(manager)});

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_kalmanvelo_states,
          offset<dev_velo_kalman_beamline_states_t>(manager),
          size<dev_velo_kalman_beamline_states_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace velo_kalman_filter