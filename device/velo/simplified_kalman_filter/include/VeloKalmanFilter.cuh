/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include "VeloEventModel.cuh"
#include "States.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "VeloConsolidated.cuh"
// #include <Gaudi/Parsers/Factory.h>
#include "patPV_Definitions.cuh"

namespace velo_kalman_filter {
  /**
   * @brief Helper function to filter one hit
   */
  __device__ void inline velo_kalman_filter_step(
    const float z,
    const float zhit,
    const float xhit,
    const float whit,
    float& x,
    float& tx,
    float& covXX,
    float& covXTx,
    float& covTxTx)
  {
    // compute the prediction
    const float dz = zhit - z;
    const float predx = x + dz * tx;

    const float dz_t_covTxTx = dz * covTxTx;
    const float predcovXTx = covXTx + dz_t_covTxTx;
    const float dx_t_covXTx = dz * covXTx;

    const float predcovXX = covXX + 2 * dx_t_covXTx + dz * dz_t_covTxTx;
    const float predcovTxTx = covTxTx;
    // compute the gain matrix
    const float R = 1.0f / ((1.0f / whit) + predcovXX);
    const float Kx = predcovXX * R;
    const float KTx = predcovXTx * R;
    // update the state vector
    const float r = xhit - predx;
    x = predx + Kx * r;
    tx = tx + KTx * r;
    // update the covariance matrix. we can write it in many ways ...
    covXX /*= predcovXX  - Kx * predcovXX */ = (1 - Kx) * predcovXX;
    covXTx /*= predcovXTx - predcovXX * predcovXTx / R */ = (1 - Kx) * predcovXTx;
    covTxTx = predcovTxTx - KTx * predcovXTx;
    // not needed by any other algorithm
    // const float chi2 = r * r * R;
  }

  /**
   * @brief Fit the track with a Kalman filter,
   *        allowing for some scattering at every hit
   */
  template<bool upstream>
  __device__ KalmanVeloState simplified_fit(
    Velo::Consolidated::ConstHits& consolidated_hits,
    const MiniState& stateAtBeamLine,
    const unsigned nhits,
    float* dev_beamline)
  {
    const bool backward = stateAtBeamLine.z > consolidated_hits.z(0);
    const int direction = (backward ? 1 : -1) * (upstream ? 1 : -1);
    const float noise2PerLayer =
      1e-8f + 7e-6f * (stateAtBeamLine.tx * stateAtBeamLine.tx + stateAtBeamLine.ty * stateAtBeamLine.ty);

    // assume the hits are sorted,
    // but don't assume anything on the direction of sorting
    int firsthit = 0;
    int lasthit = nhits - 1;
    int dhit = 1;
    if ((consolidated_hits.z(lasthit) - consolidated_hits.z(firsthit)) * direction < 0) {
      const int temp = firsthit;
      firsthit = lasthit;
      lasthit = temp;
      dhit = -1;
    }

    // We filter x and y simultaneously but take them uncorrelated.
    // filter first the first hit.
    KalmanVeloState state;
    state.x = consolidated_hits.x(firsthit);
    state.y = consolidated_hits.y(firsthit);
    state.z = consolidated_hits.z(firsthit);
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
      const auto hit_x = consolidated_hits.x(hitindex);
      const auto hit_y = consolidated_hits.y(hitindex);
      const auto hit_z = consolidated_hits.z(hitindex);

      // add the noise
      state.c22 += noise2PerLayer;
      state.c33 += noise2PerLayer;

      // filter X and filter Y
      velo_kalman_filter_step(
        state.z, hit_z, hit_x, Velo::Tracking::param_w, state.x, state.tx, state.c00, state.c20, state.c22);
      velo_kalman_filter_step(
        state.z, hit_z, hit_y, Velo::Tracking::param_w, state.y, state.ty, state.c11, state.c31, state.c33);

      // update z (not done in the filter, since needed only once)
      state.z = hit_z;
    }

    // add the noise at the last hit
    state.c22 += noise2PerLayer;
    state.c33 += noise2PerLayer;

    auto delta_z = 0.f;

    if constexpr (upstream) {
      // Propagate to the closest point near the beam line
      delta_z = (state.tx * (dev_beamline[0] - state.x) + state.ty * (dev_beamline[1] - state.y)) /
                (state.tx * state.tx + state.ty * state.ty);
    }
    else {
      // Propagate to the end of the Velo (z=770 mm)
      delta_z = Velo::Constants::z_endVelo - state.z;
    }

    state.x = state.x + state.tx * delta_z;
    state.y = state.y + state.ty * delta_z;
    state.z = state.z + delta_z;

    // TODO: Is this safety check necessary ? (coming from the PV finder)
    // if (delta_z * state.c20 < 0.f || delta_z * state.c31 < 0.f) {
    //   state.z = -9999.f;
    // }

    // Update the covariance states
    // TODO: Check correctness of this code
    const auto dz2 = delta_z * delta_z;
    state.c00 += dz2 * state.c22 + 2.f * delta_z * state.c20;
    state.c11 += dz2 * state.c33 + 2.f * delta_z * state.c31;
    state.c20 += state.c22 * delta_z;
    state.c31 += state.c33 * delta_z;

    // finally, store the state
    return state;
  }

  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_OUTPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_OUTPUT(dev_velo_kalman_endvelo_states_t, char) dev_velo_kalman_endvelo_states;
    DEVICE_OUTPUT(dev_velo_lmsfit_beamline_states_t, char) dev_velo_lmsfit_beamline_states;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };
  
  __global__ void velo_kalman_filter(Parameters, float* dev_beamline);

  struct velo_kalman_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_kalman_filter