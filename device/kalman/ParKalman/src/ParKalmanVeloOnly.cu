/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ParKalmanVeloOnly.cuh"

INSTANTIATE_ALGORITHM(kalman_velo_only::kalman_velo_only_t)

void kalman_velo_only::kalman_velo_only_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  auto n_scifi_tracks = first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
  set_size<dev_kf_tracks_t>(arguments, n_scifi_tracks);
  set_size<dev_kalman_pv_ipchi2_t>(arguments, Associate::Consolidated::table_size(n_scifi_tracks));
}

void kalman_velo_only::kalman_velo_only_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(kalman_velo_only)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  global_function(kalman_pv_ipchi2)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  if (runtime_options.fill_extra_host_buffers) {
    assign_to_host_buffer<dev_kf_tracks_t>(host_buffers.host_kf_tracks, arguments, context);
  }
}

__device__ void add_noise_1d(
  const KalmanFloat dz,
  const KalmanFloat tx,
  KalmanFloat& qop,
  KalmanFloat& predcovXX,
  KalmanFloat& predcovXTx,
  KalmanFloat& predcovTxTx,
  const KalmanFloat Cms,
  const KalmanFloat etaxx,
  const KalmanFloat etaxtx,
  const KalmanFloat Eloss,
  const bool infoil)
{
  // Adds full noise.
  // Scattering paramters are defined in the include/ParKalmanVeloOnly.cuh as
  // scatterSensorParameter_VPHit2VPHit_{cms,etaxx, etaxtx, Eloss}
  // Values are taken from the Rec/Tr/TrackFitEvent/include/Event/ParametrisedScatters.h
  // fine tuned on 10k events of upgrade-magdown-sim10-up08-30000000-digi from TestFileDB
  // as of 14.12.21

  const KalmanFloat tx2 = tx * tx;
  const KalmanFloat n2 = 1 + tx2;
  const KalmanFloat n = sqrtf(n2);
  const KalmanFloat invp = fabsf(qop);
  const KalmanFloat norm = n2 * invp * invp * n;

  KalmanFloat normCms = norm * Cms;
  normCms += infoil ? norm * rffoilscatter : 0;

  const KalmanFloat sig = (1 + tx2) * normCms;
  // x, tx part
  predcovXX += sig * dz * dz * etaxx * etaxx;
  predcovXTx += sig * dz * etaxtx;
  predcovTxTx += sig;

  const KalmanFloat deltaE = ((dz) < 0 ? 1 : -1) * Eloss * n;
  const KalmanFloat charge = qop > 0 ? 1. : -1.;
  const KalmanFloat momnew =
    (fabsf(qop) > 1e-20f && 10.f < (fabsf(1.f / qop) + deltaE)) ? fabsf(1.f / qop) + deltaE : 10.f;
  qop = (fabsf(momnew) > 10.f && fabsf(qop) > 1e-20f) ? (charge / momnew) : qop;
}
__device__ void add_noise_2d(
  const KalmanFloat dz,
  const KalmanFloat tx,
  const KalmanFloat ty,
  KalmanFloat& qop,
  SymMatrix5x5& Q,
  const KalmanFloat Cms,
  const KalmanFloat etaxx,
  const KalmanFloat etaxtx,
  const KalmanFloat Eloss,
  const bool infoil)
{

  // Adds full noise.
  // Scattering paramters are defined in the include/ParKalmanVeloOnly.cuh as
  // scatterSensorParameter_VPHit2VPHit_{cms,etaxx, etaxtx, Eloss}
  // Values are taken from the Rec/Tr/TrackFitEvent/include/Event/ParametrisedScatters.h
  // fine tuned on 10k events of upgrade-magdown-sim10-up08-30000000-digi from TestFileDB
  // as of 14.12.21

  const KalmanFloat tx2 = tx * tx;
  const KalmanFloat ty2 = ty * ty;
  const KalmanFloat n2 = 1 + tx2 + ty2;
  const KalmanFloat n = sqrtf(n2);
  const KalmanFloat invp = fabsf(qop);
  const KalmanFloat norm = n2 * invp * invp * n;

  KalmanFloat normCms = norm * Cms;
  normCms += infoil ? (norm * rffoilscatter) : 0;

  Q(2, 2) = (1 + tx2) * normCms;
  Q(3, 3) = (1 + ty2) * normCms;
  Q(3, 2) = tx * ty * normCms;

  // x, tx part
  Q(0, 0) = Q(2, 2) * dz * dz * etaxx * etaxx;
  Q(2, 0) = Q(2, 2) * dz * etaxtx;
  // y, ty part
  Q(1, 1) = Q(3, 3) * dz * dz * etaxx * etaxx;
  Q(3, 1) = Q(3, 3) * dz * etaxtx;

  Q(1, 0) = Q(3, 2) * dz * dz * etaxx * etaxx;
  Q(3, 0) = Q(3, 2) * dz * etaxtx;
  Q(2, 1) = Q(3, 0);

  const KalmanFloat deltaE = ((dz) < 0 ? 1 : -1) * Eloss * n;
  const KalmanFloat charge = (qop > 0) ? 1. : -1.;
  const KalmanFloat momnew =
    (fabsf(qop) > 1e-20f && 10.f < (fabsf(1.f / qop) + deltaE)) ? fabsf(1.f / qop) + deltaE : 10.f;
  qop = (fabsf(momnew) > 10.f && fabsf(qop) > 1e-20f) ? (charge / momnew) : qop;
}

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
  const bool infoil)
{
  // Predict the state.
  const KalmanFloat dz = zhit - z;
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
  add_noise_1d(
    dz,
    tx,
    qop,
    predcovXX,
    predcovXTx,
    predcovTxTx,
    scatterSensorParameter_VPHit2VPHit_cms,
    scatterSensorParameter_VPHit2VPHit_etaxx,
    scatterSensorParameter_VPHit2VPHit_etaxtx,
    scatterSensorParameter_VPHit2VPHit_Eloss,
    infoil);

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

  // Add full noise.
  KalmanFloat qop = x[4];
  const KalmanFloat xprime = x[1] + x[0];
  const KalmanFloat yprime = x[1] - x[0];

  const bool infoil = (yprime > -15 && xprime >= 0 && xprime < 15) || (yprime < 15 && xprime > -15 && xprime <= 0);

  add_noise_2d(
    dz,
    x[2],
    x[3],
    qop,
    Q,
    scatterSensorParameter_VPHit2VPHit_cms,
    scatterSensorParameter_VPHit2VPHit_etaxx,
    scatterSensorParameter_VPHit2VPHit_etaxtx,
    scatterSensorParameter_VPHit2VPHit_Eloss,
    infoil);
  x[4] = qop;
}

__device__ void predict_velo_only(
  Velo::Consolidated::ConstHits& hits,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  const ParKalmanFilter::KalmanParametrizations* params)
{
  // Extrapolate.
  Matrix5x5 F;
  SymMatrix5x5 Q;
  extrapolate_velo_only(lastz, (KalmanFloat) hits.z(nHit), x, F, Q, params);

  // Transport the covariance matrix.
  C = similarity_5_5(F, C);

  // Add noise.
  C = C + Q;

  // Set the current z position.
  lastz = (KalmanFloat) hits.z(nHit);
}

__device__ void
update_velo_only(Velo::Consolidated::ConstHits& hits, int nHit, Vector5& x, SymMatrix5x5& C, KalmanFloat& chi2)
{
  // Get the residual.
  Vector2 res;
  res(0) = (KalmanFloat) hits.x(nHit) - x(0);
  res(1) = (KalmanFloat) hits.y(nHit) - x(1);

  KalmanFloat xErr = pixelErr;
  KalmanFloat yErr = pixelErr;
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
  Velo::Consolidated::ConstHits& velo_hits,
  const unsigned n_velo_hits,
  const KalmanFloat init_qop,
  const KalmanParametrizations* kalman_params,
  FittedTrack& track)
{
  KalmanFloat chi2 = 0;

  // Set the initial state.
  Vector5 x;
  x(0) = (KalmanFloat) velo_hits.x(0);
  x(1) = (KalmanFloat) velo_hits.y(0);
  x(2) =
    (KalmanFloat)((velo_hits.x(0) - velo_hits.x(n_velo_hits - 1)) / (velo_hits.z(0) - velo_hits.z(n_velo_hits - 1)));
  x(3) =
    (KalmanFloat)((velo_hits.y(0) - velo_hits.y(n_velo_hits - 1)) / (velo_hits.z(0) - velo_hits.z(n_velo_hits - 1)));
  x(4) = init_qop;
  KalmanFloat lastz = (KalmanFloat) velo_hits.z(0);

  // Set covariance matrix with large uncertainties and no correlations.
  SymMatrix5x5 C;
  C(0, 0) = (KalmanFloat) pixelErr * pixelErr;
  C(0, 1) = (KalmanFloat) 0.0;
  C(0, 2) = (KalmanFloat) 0.0;
  C(0, 3) = (KalmanFloat) 0.0;
  C(0, 4) = (KalmanFloat) 0.0;
  C(1, 1) = (KalmanFloat) pixelErr * pixelErr;
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

__device__ void propagate_to_beamline(FittedTrack& track)
{
  KalmanFloat x = track.state[0];
  KalmanFloat y = track.state[1];
  KalmanFloat tx = track.state[2];
  KalmanFloat ty = track.state[3];
  const KalmanFloat t2 = sqrtf(tx * tx + ty * ty);

  // Get the beam position.
  KalmanFloat zBeam = track.z;
  KalmanFloat denom = t2 * t2;
  const KalmanFloat tol = (KalmanFloat) 0.001;
  zBeam = (denom < tol * tol) ? zBeam : track.z - (x * tx + y * ty) / denom;
  const KalmanFloat dz = zBeam - track.z;
  KalmanFloat qop = track.state[4];

  // Propagate the covariance matrix.
  const KalmanFloat dz2 = dz * dz;
  track.cov(0, 0) += dz2 * track.cov(2, 2) + 2 * dz * track.cov(0, 2);
  track.cov(0, 2) += dz * track.cov(2, 2);
  track.cov(1, 1) += dz2 * track.cov(3, 3) + 2 * dz * track.cov(1, 3);
  track.cov(1, 3) += dz * track.cov(3, 3);

  // Propagate the state.
  track.state[0] = x + dz * tx;
  track.state[1] = y + dz * ty;
  track.z = zBeam;

  //
  x = track.state[0];
  y = track.state[1];
  tx = track.state[2];
  ty = track.state[3];

  SymMatrix5x5 Q;
  // add noise
  // Note: for VPhit2BeamLine propagation the rf-foil is included in the parameters,
  // so infoil has to be set to false.
  add_noise_2d(
    dz,
    tx,
    ty,
    qop,
    Q,
    scatterSensorParameter_VPHit2ClosestToBeam_cms,
    scatterSensorParameter_VPHit2ClosestToBeam_etaxx,
    scatterSensorParameter_VPHit2ClosestToBeam_etaxtx,
    scatterSensorParameter_VPHit2ClosestToBeam_Eloss,
    false);

  track.state[4] = qop;

  track.cov(0, 0) += Q(0, 0);
  track.cov(1, 1) += Q(1, 1);
  track.cov(2, 2) += Q(2, 2);
  track.cov(3, 3) += Q(3, 3);

  track.cov(1, 0) += Q(1, 0);

  track.cov(2, 0) += Q(2, 0);
  track.cov(2, 1) += Q(2, 1);

  track.cov(3, 0) += Q(3, 0);
  track.cov(3, 1) += Q(3, 1);
  track.cov(3, 2) += Q(3, 2);
}

__device__ void simplified_fit(
  const Allen::Views::Velo::Consolidated::Track& velo_track,
  const KalmanFloat init_qop,
  FittedTrack& track)
{
  const auto n_velo_hits = velo_track.number_of_hits();
  int first_hit_number = 0;
  int last_hit_number = n_velo_hits - 1;
  int dhit = 1;

  // Initialize the state.
  const auto first_hit = velo_track.hit(first_hit_number);
  const auto last_hit = velo_track.hit(last_hit_number);
  KalmanFloat x = first_hit.x();
  KalmanFloat y = first_hit.y();
  KalmanFloat tx = ((first_hit.x() - last_hit.x()) / (first_hit.z() - last_hit.z()));
  KalmanFloat ty = ((first_hit.y() - last_hit.y()) / (first_hit.z() - last_hit.z()));
  KalmanFloat qop = init_qop;
  KalmanFloat z = first_hit.z();

  // Initialize the covariance.
  KalmanFloat cXX = 100.0;
  KalmanFloat cXTx = 0;
  KalmanFloat cTxTx = 0.01;
  KalmanFloat cYY = 100.0;
  KalmanFloat cYTy = 0;
  KalmanFloat cTyTy = 0.01;

  // Initialize the chi2.
  KalmanFloat chi2 = 0;

  // Calculate winv.
  const KalmanFloat wx = pixelErr * pixelErr;
  const KalmanFloat wy = wx;

  // Initialize the covariance.
  KalmanFloat cXX = wx;
  KalmanFloat cXTx = 0;
  KalmanFloat cTxTx = 0.01;
  KalmanFloat cYY = wy;
  KalmanFloat cYTy = 0;
  KalmanFloat cTyTy = 0.01;

  // Fit loop.
  for (int i = first_hit_number + dhit; i != last_hit_number + dhit; i += dhit) {
    const auto hit = velo_track.hit(i);
    const auto hit_x = hit.x();
    const auto hit_y = hit.y();
    const auto hit_z = hit.z();
    simplified_step(z, hit_z, hit_x, wx, x, tx, qop, cXX, cXTx, cTxTx, chi2);
    simplified_step(z, hit_z, hit_y, wy, y, ty, qop, cYY, cYTy, cTyTy, chi2);
    z = hit_z;
  }
  __syncthreads();

  // Add info to the output track.
  track.chi2 = chi2;
  track.ndof = 2 * n_velo_hits - 4;
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

  // Propagate track to beamline.
  propagate_to_beamline(track);
}

__global__ void kalman_velo_only::kalman_velo_only(
  kalman_velo_only::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Forward tracks.
  const auto scifi_tracks_view = parameters.dev_scifi_tracks_view[event_number];
  //const auto scifi_track_view = parameters.dev_scifi_track_view + parameters.dev_atomics_scifi[event_number];

  // Velo track <-> PV table.
  // TODO: Rework the association event model to get rid of the need for these old VELO tracks.
  Velo::Consolidated::Tracks const velo_pv_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Associate::Consolidated::ConstTable velo_pv_ip {parameters.dev_velo_pv_ip, velo_pv_tracks.total_number_of_tracks()};
  const auto pv_table = velo_pv_ip.event_table(velo_pv_tracks, event_number);

  // Loop over SciFi tracks and get associated UT and VELO tracks.
  const unsigned n_scifi_tracks = scifi_tracks_view.size();
  for (unsigned i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    const auto scifi_track = scifi_tracks_view.track(i_scifi_track);
    const auto velo_track = scifi_track.velo_track();
    const int i_velo_track = scifi_track.ut_track().velo_track_index();
    const KalmanFloat init_qop = (KalmanFloat) scifi_track.qop();
    
    simplified_fit(
      velo_track,
      init_qop,
      parameters.dev_kf_tracks[scifi_tracks_view.offset() + i_scifi_track]);
    parameters.dev_kf_tracks[scifi_tracks_view.offset() + i_scifi_track].ip =
      pv_table.value(i_velo_track);
  }
}
