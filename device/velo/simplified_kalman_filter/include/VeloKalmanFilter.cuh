/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include "VeloEventModel.cuh"
#include "States.cuh"
#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "VeloConsolidated.cuh"
#include "ParticleTypes.cuh"
#include "patPV_Definitions.cuh"
#include "CopyTrackParameters.cuh"

#ifndef ALLEN_STANDALONE
#include <Gaudi/Accumulators.h>
#include "GaudiMonitoring.h"
#endif

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
    const Allen::Views::Velo::Consolidated::Track& track,
    const MiniState& stateAtBeamLine,
    float* dev_beamline,
    bool backward)
  {
    const int direction = (backward ? 1 : -1) * (upstream ? 1 : -1);
    const float noise2PerLayer =
      1e-8f + 7e-6f * (stateAtBeamLine.tx * stateAtBeamLine.tx + stateAtBeamLine.ty * stateAtBeamLine.ty);

    // assume the hits are sorted,
    // but don't assume anything on the direction of sorting
    int firsthit = 0;
    int lasthit = track.number_of_hits() - 1;
    int dhit = 1;
    if ((track.hit(lasthit).z() - track.hit(firsthit).z()) * direction < 0) {
      const int temp = firsthit;
      firsthit = lasthit;
      lasthit = temp;
      dhit = -1;
    }

    // We filter x and y simultaneously but take them uncorrelated.
    // filter first the first hit.
    KalmanVeloState state;
    const auto hit = track.hit(firsthit);
    state.x = hit.x();
    state.y = hit.y();
    state.z = hit.z();
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
      const auto hit = track.hit(i);
      const auto hit_x = hit.x();
      const auto hit_y = hit.y();
      const auto hit_z = hit.z();

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

    // Propagate the state
    state.x = state.x + state.tx * delta_z;
    state.y = state.y + state.ty * delta_z;
    state.z = state.z + delta_z;

    // Propagate the covariance matrix
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
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_OUTPUT(dev_is_backward_t, bool) dev_is_backward;
    DEVICE_OUTPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_OUTPUT(dev_velo_kalman_endvelo_states_t, char) dev_velo_kalman_endvelo_states;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_kalman_beamline_states_view_t,
      DEPENDENCIES(dev_velo_kalman_beamline_states_t, dev_offsets_all_velo_tracks_t),
      Allen::Views::Physics::KalmanStates)
    dev_velo_kalman_beamline_states_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_velo_kalman_endvelo_states_view_t,
      DEPENDENCIES(dev_velo_kalman_endvelo_states_t, dev_offsets_all_velo_tracks_t),
      Allen::Views::Physics::KalmanStates)
    dev_velo_kalman_endvelo_states_view;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;

    PROPERTY(
      histogram_velo_track_eta_min_t,
      "histogram_velo_track_eta_min",
      "histogram_velo_track_eta_min description",
      float)
    histogram_velo_track_eta_min;
    PROPERTY(
      histogram_velo_track_eta_max_t,
      "histogram_velo_track_eta_max",
      "histogram_velo_track_eta_max description",
      float)
    histogram_velo_track_eta_max;
    PROPERTY(
      histogram_velo_track_eta_nbins_t,
      "histogram_velo_track_eta_nbins",
      "histogram_velo_track_eta_nbins description",
      unsigned int)
    histogram_velo_track_eta_nbins;

    PROPERTY(
      histogram_velo_track_phi_min_t,
      "histogram_velo_track_phi_min",
      "histogram_velo_track_phi_min description",
      float)
    histogram_velo_track_phi_min;
    PROPERTY(
      histogram_velo_track_phi_max_t,
      "histogram_velo_track_phi_max",
      "histogram_velo_track_phi_max description",
      float)
    histogram_velo_track_phi_max;
    PROPERTY(
      histogram_velo_track_phi_nbins_t,
      "histogram_velo_track_phi_nbins",
      "histogram_velo_track_phi_nbins description",
      unsigned int)
    histogram_velo_track_phi_nbins;

    PROPERTY(
      histogram_velo_track_nhits_min_t,
      "histogram_velo_track_nhits_min",
      "histogram_velo_track_nhits_min description",
      float)
    histogram_velo_track_nhits_min;
    PROPERTY(
      histogram_velo_track_nhits_max_t,
      "histogram_velo_track_nhits_max",
      "histogram_velo_track_nhits_max description",
      float)
    histogram_velo_track_nhits_max;
    PROPERTY(
      histogram_velo_track_nhits_nbins_t,
      "histogram_velo_track_nhits_nbins",
      "histogram_velo_track_nhits_nbins description",
      unsigned int)
    histogram_velo_track_nhits_nbins;
  };

  __global__ void
  velo_kalman_filter(Parameters, float* dev_beamline, gsl::span<unsigned>, gsl::span<unsigned>, gsl::span<unsigned>);
  struct velo_kalman_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    __device__ static void monitor(
      const velo_kalman_filter::Parameters& parameters,
      Allen::Views::Velo::Consolidated::Track velo_track,
      KalmanVeloState beamline_state,
      gsl::span<unsigned>,
      gsl::span<unsigned>,
      gsl::span<unsigned>);

    void output_monitor(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<histogram_velo_track_eta_min_t> m_histogramVeloEtaMin {this, -10.f};
    Property<histogram_velo_track_eta_max_t> m_histogramVeloEtaMax {this, 10.f};
    Property<histogram_velo_track_eta_nbins_t> m_histogramVeloEtaNBins {this, 40u};
    Property<histogram_velo_track_phi_min_t> m_histogramVeloPhiMin {this, -4.f};
    Property<histogram_velo_track_phi_max_t> m_histogramVeloPhiMax {this, 4.f};
    Property<histogram_velo_track_phi_nbins_t> m_histogramVeloPhiNBins {this, 16u};
    Property<histogram_velo_track_nhits_min_t> m_histogramVeloNhitsMin {this, 0.f};
    Property<histogram_velo_track_nhits_max_t> m_histogramVeloNhitsMax {this, 50.f};
    Property<histogram_velo_track_nhits_nbins_t> m_histogramVeloNhitsNBins {this, 50u};

#ifndef ALLEN_STANDALONE
  private:
    gaudi_monitoring::Lockable_Histogram<>* histogram_velo_track_eta;
    gaudi_monitoring::Lockable_Histogram<>* histogram_velo_track_phi;
    gaudi_monitoring::Lockable_Histogram<>* histogram_velo_track_nhits;
#endif
  };
} // namespace velo_kalman_filter
