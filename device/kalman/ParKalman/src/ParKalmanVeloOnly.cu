/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ParKalmanVeloOnly.cuh"

INSTANTIATE_ALGORITHM(kalman_velo_only::kalman_velo_only_t)

void kalman_velo_only::kalman_velo_only_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_scifi_tracks = first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
  set_size<dev_kf_tracks_t>(arguments, n_scifi_tracks);
  set_size<dev_kalman_pv_ip_t>(arguments, Associate::Consolidated::table_size(n_scifi_tracks));
  set_size<dev_kalman_fit_results_t>(arguments, n_scifi_tracks * Velo::Consolidated::States::size);
  set_size<dev_kalman_states_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_kalman_pv_tables_t>(arguments, first<host_number_of_events_t>(arguments));
}

void kalman_velo_only::kalman_velo_only_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(kalman_velo_only)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);

  global_function(kalman_pv_ip)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
}

void kalman_velo_only::kalman_velo_only_t::update(const Constants& constants) const
{
  struct BeamlinePVConstants::Common::Beamline host_beamline;

  host_beamline.pos.x = constants.host_beamline[0];
  host_beamline.pos.y = constants.host_beamline[1];
  host_beamline.pos.z = constants.host_beamline[2];

  for (long unsigned int i = 0; i < 6; i++) { // spread matrix have 6 elements
    host_beamline.sprd[i] = constants.host_beamline[3 + i];
  }
  double beamlineTx = 0.;
  double beamlineTy = 0.; // Beamline inclination is set at zero for now. This will be modified later
  host_beamline.tx.x = beamlineTx;
  host_beamline.tx.y = beamlineTy;

  // To stay backward compatible we need to check the size of host_beamline. In version 0 and 1 of the beamline only
  // position with 3 elements and spread matrix with 6 were included
  double CrossingAngleh = constants.host_beamline.size() == 9 ?
                            0 :
                            static_cast<double>(constants.host_beamline[9]) /
                              (2 * std::pow(10, 6)); // Convert crossing angles between beams from microrad to rad,
                                                     // take half to convert the angle to the beam inclination
  if ((CrossingAngleh == 0.0) & (constants.host_gen_crossing_angles.size() == 2)) {
    CrossingAngleh = fabs(static_cast<double>(constants.host_gen_crossing_angles[0])) / 2.;
  }
  double CrossingAnglev =
    constants.host_beamline.size() == 9 ? 0 : static_cast<double>(constants.host_beamline[10]) / (2 * std::pow(10, 6));

  if ((CrossingAnglev == 0.0) & (constants.host_gen_crossing_angles.size() == 2)) {
    CrossingAnglev = fabs(static_cast<double>(constants.host_gen_crossing_angles[1])) / 2.;
  }
  host_beamline.tx_SMOG.x = beamlineTx + CrossingAngleh;
  host_beamline.tx_SMOG.y = beamlineTy + CrossingAnglev;
  Allen::memcpyToSymbol(dev_beamline, &host_beamline, sizeof(struct BeamlinePVConstants::Common::Beamline));
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

    const KalmanFloat xprime = hit_x + hit_y;
    const KalmanFloat yprime = hit_y - hit_x;
    const bool infoil = (yprime > -15 && xprime >= 0 && xprime < 15) || (yprime < 15 && xprime > -15 && xprime <= 0);
    simplified_step(z, hit_z, hit_x, wx, x, tx, qop, cXX, cXTx, cTxTx, chi2, infoil);
    simplified_step(z, hit_z, hit_y, wy, y, ty, qop, cYY, cYTy, cTyTy, chi2, infoil);
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
  propagate_to_beamline(track, dev_beamline);
}

__host__ __device__ void set_fit_result(
  const unsigned track_number,
  const ParKalmanFilter::FittedTrack& track,
  Velo::Consolidated::States& states)
{
  states.x(track_number) = track.state[0];
  states.y(track_number) = track.state[1];
  states.tx(track_number) = track.state[2];
  states.ty(track_number) = track.state[3];
  states.qop(track_number) = track.state[4];
  states.z(track_number) = track.z;

  states.c00(track_number) = track.cov(0, 0);
  // states.c10(track_number) = track.cov(1, 0);
  states.c11(track_number) = track.cov(1, 1);
  states.c20(track_number) = track.cov(2, 0);
  // states.c21(track_number) = track.cov(2, 1);
  states.c22(track_number) = track.cov(2, 2);
  states.c31(track_number) = track.cov(3, 1);
  states.c33(track_number) = track.cov(3, 3);
  states.chi2(track_number) = track.chi2;
  states.ndof(track_number) = track.ndof;
  return;
}

__global__ void kalman_velo_only::kalman_velo_only(kalman_velo_only::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Long tracks.
  const auto event_long_tracks = parameters.dev_long_tracks_view->container(event_number);
  const unsigned total_number_of_tracks = parameters.dev_long_tracks_view->number_of_contained_objects();

  parameters.dev_kalman_states_view[event_number] = Allen::Views::Physics::KalmanStates {
    parameters.dev_kalman_fit_results, parameters.dev_atomics_scifi, event_number, number_of_events};
  // TODO: It'd be nice not to need the total number of tracks here.
  Velo::Consolidated::States kalman_states {parameters.dev_kalman_fit_results, total_number_of_tracks};
  // Loop over SciFi tracks and get associated UT and VELO tracks.
  const unsigned n_long_tracks = event_long_tracks.size();
  for (unsigned i_long_track = threadIdx.x; i_long_track < n_long_tracks; i_long_track += blockDim.x) {
    const auto long_track = event_long_tracks.track(i_long_track);
    const auto velo_track = long_track.track_segment<Allen::Views::Physics::Track::segment::velo>();
    const KalmanFloat init_qop = (KalmanFloat) long_track.qop();
    ParKalmanFilter::FittedTrack kalman_track;
    simplified_fit(velo_track, init_qop, kalman_track);

    set_fit_result(event_long_tracks.offset() + i_long_track, kalman_track, kalman_states);
    parameters.dev_kf_tracks[event_long_tracks.offset() + i_long_track] = kalman_track;
  }
}
