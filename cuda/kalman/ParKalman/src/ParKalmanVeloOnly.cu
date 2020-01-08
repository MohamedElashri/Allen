#include "ParKalmanVeloOnly.cuh"

__device__ void simplified_step(
  const KalmanFloat z,
  const KalmanFloat zhit,
  const KalmanFloat xhit,
  const KalmanFloat winv,
  KalmanFloat& x,
  KalmanFloat& tx,
  KalmanFloat& qop,
  KalmanFloat& covXX,
  KalmanFloat& covXTx,
  KalmanFloat& covTxTx,
  KalmanFloat& chi2,
  const ParKalmanFilter::KalmanParametrizations* params)
{
  // Predict the state.
  const KalmanFloat dz = zhit - z;
  const auto& par = params->Par_predictV[dz > 0 ? 0 : 1];
  // For now don't use the momentum-dependent correction to ty. It doesn't work for some reason.
  // const KalmanFloat predTx = tx + corTx * par[4] * (1e-5 * dz * ((dz > 0 ? z : zhit) + par[5] * 1e3));
  // const KalmanFloat predx = x + 0.5 * (tx + predTx) * dz;
  const KalmanFloat predTx = tx;
  const KalmanFloat predx = x + tx * dz;

  // Predict the covariance matrix (accurate if we ignore the small
  // momentum dependence of the Jacobian).
  const KalmanFloat dz_t_covTxTx = dz * covTxTx;
  KalmanFloat predcovXTx = covXTx + dz_t_covTxTx;
  const KalmanFloat dx_t_covXTx = dz * covXTx;
  KalmanFloat predcovXX = covXX + 2 * dx_t_covXTx + dz * dz_t_covTxTx;
  KalmanFloat predcovTxTx = covTxTx;

  // Add noise.
  const KalmanFloat sigTx = par[1] * ((KalmanFloat) 1e-5) + par[2] * fabsf(qop);
  const KalmanFloat sigX = par[6] * sigTx * fabsf(dz);
  const KalmanFloat corr = par[7];
  predcovXX += sigX * sigX;
  predcovXTx += corr * sigX * sigTx;
  predcovTxTx += sigTx * sigTx;

  // Gain matrix.
  const KalmanFloat R = 1.0f / (winv + predcovXX);
  const KalmanFloat Kx = predcovXX * R;
  const KalmanFloat KTx = predcovXTx * R;

  // Update.
  const KalmanFloat r = xhit - predx;
  x = predx + Kx * r;
  tx = predTx + KTx * r;
  covXX = (1 - Kx) * predcovXX;
  covXTx = (1 - Kx) * predcovXTx;
  covTxTx = predcovTxTx - KTx * predcovXTx;

  chi2 += r * r * R;
}

__device__ void extrapolate_velo_only(
  KalmanFloat zFrom,
  KalmanFloat zTo,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  const ParKalmanFilter::KalmanParametrizations* params)
{
  Vector5 x_old = x;
  KalmanFloat dz = zTo - zFrom;
  if (dz == 0) return;
  const auto& par = params->Par_predictV[dz > 0 ? 0 : 1];

  // State extrapolation.
  x[2] = x_old[2] +
         x_old[4] * par[4] * ((KalmanFloat) 1.0e-5) * dz * ((dz > 0 ? zFrom : zTo) + par[5] * ((KalmanFloat) 1.0e3));
  x[0] = x_old[0] + (x[2] + x_old[2]) * ((KalmanFloat) 0.5) * dz;
  x[3] = x_old[3];
  x[1] = x_old[1] + x[3] * dz;

  // Determine the Jacobian.
  F.SetElements(F_diag);
  F(0, 2) = dz;
  F(1, 3) = dz;
  F(2, 4) = par[4] * ((KalmanFloat) 1.0e-5) * dz * ((dz > 0 ? zFrom : zTo) + par[5] * ((KalmanFloat) 1.0e3));
  F(0, 4) = ((KalmanFloat) 0.5) * dz * F(2, 4);

  // Noise matrix.
  KalmanFloat sigt = par[1] * ((KalmanFloat) 1.0e-5) + par[2] * fabsf(x_old[4]);
  KalmanFloat sigx = par[6] * sigt * fabsf(dz);
  KalmanFloat corr = par[7];
  Q(0, 0) = sigx * sigx;
  Q(1, 1) = sigx * sigx;
  Q(2, 2) = sigt * sigt;
  Q(3, 3) = sigt * sigt;
  Q(0, 2) = corr * sigx * sigt;
  Q(1, 3) = corr * sigx * sigt;
}

__device__ void predict_velo_only(
  const Velo::Consolidated::Hits& hits,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  const ParKalmanFilter::KalmanParametrizations* params)
{
  // Extrapolate.
  Matrix5x5 F;
  SymMatrix5x5 Q;
  extrapolate_velo_only(lastz, (KalmanFloat) hits.z[nHit], x, F, Q, params);

  // Transport the covariance matrix.
  C = similarity_5_5(F, C);

  // Add noise.
  C = C + Q;

  // Set the current z position.
  lastz = (KalmanFloat) hits.z[nHit];
}

__device__ void
update_velo_only(const Velo::Consolidated::Hits& hits, int nHit, Vector5& x, SymMatrix5x5& C, KalmanFloat& chi2)
{
  // Get the residual.
  Vector2 res;
  res(0) = (KalmanFloat) hits.x[nHit] - x(0);
  res(1) = (KalmanFloat) hits.y[nHit] - x(1);

  // TODO: For now, I'm assuming xErr == yErr == 0.015 mm. This
  // roughly matches what Daniel uses in the simplified Kalman
  // filter, but needs to be checked.
  KalmanFloat xErr = 0.015;
  KalmanFloat yErr = 0.015;
  KalmanFloat CResTmp[3] = {xErr * xErr + C(0, 0), C(0, 1), yErr * yErr + C(1, 1)};
  SymMatrix2x2 CRes(CResTmp);

  // Kalman formalism.
  SymMatrix2x2 CResInv;
  KalmanFloat Dinv = ((KalmanFloat) 1.) / (CRes(0, 0) * CRes(1, 1) - CRes(1, 0) * CRes(1, 0));
  CResInv(0, 0) = CRes(1, 1) * Dinv;
  CResInv(1, 0) = -CRes(1, 0) * Dinv;
  CResInv(1, 1) = CRes(0, 0) * Dinv;

  Vector10 K;
  multiply_S5x5_S2x2(C, CResInv, K);
  x = x + K * res;
  SymMatrix5x5 KCrKt;
  similarity_5x2_2x2(K, CRes, KCrKt);

  C = C - KCrKt;

  // Update the chi2.
  KalmanFloat chi2Tmp = similarity_2x1_2x2(res, CResInv);
  chi2 += chi2Tmp;
}

__device__ void velo_only_fit(
  const Velo::Consolidated::Hits& velo_hits,
  const uint n_velo_hits,
  const KalmanFloat init_qop,
  const KalmanParametrizations* kalman_params,
  FittedTrack& track)
{
  KalmanFloat chi2 = 0;

  // Set the initial state.
  Vector5 x;
  x(0) = (KalmanFloat) velo_hits.x[0];
  x(1) = (KalmanFloat) velo_hits.y[0];
  x(2) =
    (KalmanFloat)((velo_hits.x[0] - velo_hits.x[n_velo_hits - 1]) / (velo_hits.z[0] - velo_hits.z[n_velo_hits - 1]));
  x(3) =
    (KalmanFloat)((velo_hits.y[0] - velo_hits.y[n_velo_hits - 1]) / (velo_hits.z[0] - velo_hits.z[n_velo_hits - 1]));
  x(4) = init_qop;
  KalmanFloat lastz = (KalmanFloat) velo_hits.z[0];

  // Set covariance matrix with large uncertainties and no correlations.
  SymMatrix5x5 C;
  C(0, 0) = (KalmanFloat) 100.0;
  C(0, 1) = (KalmanFloat) 0.0;
  C(0, 2) = (KalmanFloat) 0.0;
  C(0, 3) = (KalmanFloat) 0.0;
  C(0, 4) = (KalmanFloat) 0.0;
  C(1, 1) = (KalmanFloat) 100.0;
  C(1, 2) = (KalmanFloat) 0.0;
  C(1, 3) = (KalmanFloat) 0.0;
  C(1, 4) = (KalmanFloat) 0.0;
  C(2, 2) = (KalmanFloat) 0.01;
  C(2, 3) = (KalmanFloat) 0.0;
  C(2, 4) = (KalmanFloat) 0.0;
  C(3, 3) = (KalmanFloat) 0.01;
  C(3, 4) = (KalmanFloat) 0.0;
  // Keep this small to reflect that we actually know the momentum to
  // ~1%. The VELO-only fit does not improve this.
  C(4, 4) = ((KalmanFloat) 0.0001) * x(4) * x(4);

  //------------------------------ Start the fit.
  update_velo_only(velo_hits, 0, x, C, chi2);
  for (int i_hit = n_velo_hits - 2; i_hit >= 0; i_hit--) {
    predict_velo_only(velo_hits, n_velo_hits - 1 - i_hit, x, C, lastz, kalman_params);
    update_velo_only(velo_hits, n_velo_hits - 1 - i_hit, x, C, chi2);
  }
  __syncthreads();
  //------------------------------ End fit.

  // Set the resulting track parameters.
  track.chi2 = chi2;
  track.ndof = 2 * n_velo_hits;
  track.z = lastz;
  track.state = x;
  track.cov = C;
  track.first_qop = init_qop;
  track.best_qop = x[4];
  track.nhits = n_velo_hits;
}

__device__ void simplified_fit(
  const Velo::Consolidated::Hits& velo_hits,
  const uint n_velo_hits,
  const KalmanFloat init_qop,
  const ParKalmanFilter::KalmanParametrizations* kalman_params,
  FittedTrack& track)
{
  int firsthit = 0;
  int lasthit = n_velo_hits - 1;
  int dhit = 1;

  // Initialize the state.
  KalmanFloat x = velo_hits.x[firsthit];
  KalmanFloat y = velo_hits.y[firsthit];
  KalmanFloat tx = ((velo_hits.x[firsthit] - velo_hits.x[lasthit]) / (velo_hits.z[firsthit] - velo_hits.z[lasthit]));
  KalmanFloat ty = ((velo_hits.y[firsthit] - velo_hits.y[lasthit]) / (velo_hits.z[firsthit] - velo_hits.z[lasthit]));
  KalmanFloat qop = init_qop;
  KalmanFloat z = velo_hits.z[firsthit];

  // Initialize the covariance.
  KalmanFloat cXX = 100.0;
  KalmanFloat cXTx = 0;
  KalmanFloat cTxTx = 0.01;
  KalmanFloat cYY = 100.0;
  KalmanFloat cYTy = 0;
  KalmanFloat cTyTy = 0.01;

  // Initialize the chi2.
  KalmanFloat chi2 = 0;

  // Fit loop.
  for (int i = firsthit + dhit; i != lasthit + dhit; i += dhit) {
    int hitindex = i;
    const auto hit_x = velo_hits.x[hitindex];
    const auto hit_y = velo_hits.y[hitindex];
    const auto hit_z = velo_hits.z[hitindex];
    simplified_step(
      z, hit_z, hit_x, Velo::Tracking::param_w_inverted, x, tx, qop, cXX, cXTx, cTxTx, chi2, kalman_params);
    simplified_step(
      z, hit_z, hit_y, Velo::Tracking::param_w_inverted, y, ty, qop, cYY, cYTy, cTyTy, chi2, kalman_params);
    z = hit_z;
  }
  __syncthreads();

  // Add info to the output track.
  track.chi2 = chi2;
  track.ndof = 2 * n_velo_hits;
  track.z = z;
  track.state[0] = x;
  track.state[1] = y;
  track.state[2] = tx;
  track.state[3] = ty;
  track.state[4] = qop;
  track.cov(0, 0) = cXX;
  track.cov(0, 1) = 0.0;
  track.cov(0, 2) = cXTx;
  track.cov(0, 3) = 0.0;
  track.cov(0, 4) = 0.0;
  track.cov(1, 1) = cYY;
  track.cov(1, 2) = 0.0;
  track.cov(1, 3) = cYTy;
  track.cov(1, 4) = 0.0;
  track.cov(2, 2) = cTxTx;
  track.cov(2, 3) = 0.0;
  track.cov(2, 4) = 0.0;
  track.cov(3, 3) = cTyTy;
  track.cov(3, 4) = 0.0;
  // Just assume 1% uncertainty on qop. Shouldn't matter.
  track.cov(4, 4) = ((KalmanFloat) 0.0001) * qop * qop;
  track.first_qop = init_qop;
  track.best_qop = init_qop;
  track.nhits = n_velo_hits;
}

__global__ void kalman_velo_only::kalman_velo_only(
  kalman_velo_only::Parameters parameters,
  const char* dev_scifi_geometry,
  const ParKalmanFilter::KalmanParametrizations* dev_kalman_params)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Create velo tracks.
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) parameters.dev_atomics_velo, (uint*) parameters.dev_velo_track_hit_number, event_number, number_of_events};

  // Create UT tracks.
  const UT::Consolidated::Tracks ut_tracks {(uint*) parameters.dev_atomics_veloUT,
                                            (uint*) parameters.dev_ut_track_hit_number,
                                            (float*) parameters.dev_ut_qop,
                                            (uint*) parameters.dev_ut_track_velo_indices,
                                            event_number,
                                            number_of_events};

  // Create SciFi tracks.
  const SciFi::Consolidated::Tracks scifi_tracks {(uint*) parameters.dev_atomics_scifi,
                                                  (uint*) parameters.dev_scifi_track_hit_number,
                                                  (float*) parameters.dev_scifi_qop,
                                                  (MiniState*) parameters.dev_scifi_states,
                                                  (uint*) parameters.dev_scifi_track_ut_indices,
                                                  event_number,
                                                  number_of_events};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};

  // Loop over SciFi tracks and get associated UT and VELO tracks.
  const uint n_scifi_tracks = scifi_tracks.number_of_tracks(event_number);
  for (uint i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    // Prepare fit input.
    const int i_ut_track = scifi_tracks.ut_track[i_scifi_track];
    const int i_velo_track = ut_tracks.velo_track[i_ut_track];
    const Velo::Consolidated::Hits velo_hits =
      velo_tracks.get_hits((char*) parameters.dev_velo_track_hits, i_velo_track);
    const uint n_velo_hits = velo_tracks.number_of_hits(i_velo_track);
    const KalmanFloat init_qop = (KalmanFloat) scifi_tracks.qop[i_scifi_track];
    simplified_fit(
      velo_hits,
      n_velo_hits,
      init_qop,
      dev_kalman_params,
      parameters.dev_kf_tracks[scifi_tracks.tracks_offset(event_number) + i_scifi_track]);
  }
}
