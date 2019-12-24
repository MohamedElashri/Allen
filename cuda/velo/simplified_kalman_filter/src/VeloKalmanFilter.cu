#include "VeloKalmanFilter.cuh"

using namespace velo_kalman_filter;

/**
 * @brief Helper function to filter one hit
 */
__device__ void velo_kalman_filter::velo_kalman_filter_step(
  const float z,
  const float zhit,
  const float xhit,
  const float whit,
  float& x,
  float& tx,
  float& covXX,
  float& covXTx,
  float& covTxTx) {
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

__global__ void velo_kalman_filter::velo_kalman_filter(
  dev_offsets_atomics_velo_t dev_offsets_atomics_velo,
  dev_offsets_velo_track_hit_number_t dev_offsets_velo_track_hit_number,
  dev_velo_track_hits_t dev_velo_track_hits,
  dev_velo_states_t dev_velo_states,
  dev_velo_kalman_beamline_states_t dev_velo_kalman_beamline_states) {
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Consolidated datatypes
  const Velo::Consolidated::Tracks velo_tracks {
    dev_offsets_atomics_velo, dev_offsets_velo_track_hit_number, event_number, number_of_events};

  // TODO: Make const
  Velo::Consolidated::States velo_states {const_cast<char*>(dev_velo_states.get()), velo_tracks.total_number_of_tracks()};
  Velo::Consolidated::KalmanStates kalmanvelo_states {dev_velo_kalman_beamline_states,
                                                      velo_tracks.total_number_of_tracks()};

  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {

    Velo::Consolidated::Hits consolidated_hits = velo_tracks.get_hits(const_cast<char*>(dev_velo_track_hits.get()), i);
    const uint n_hits = velo_tracks.number_of_hits(i);

    MiniState stateAtBeamline = velo_states.getMiniState(event_tracks_offset + i);

    KalmanVeloState kalmanbeam_state = simplified_fit<true>(consolidated_hits, stateAtBeamline, n_hits);

    kalmanvelo_states.set(event_tracks_offset + i, kalmanbeam_state);
  }
}
