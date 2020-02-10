
/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

/**
 * Convert ParKalmanFilter::FittedTrack and SciFi::Consolidated::Tracks into LHCb::Event::v2::Track
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenForwardToV2Tracks.h"

DECLARE_COMPONENT(AllenForwardToV2Tracks)

namespace {
  const float m_scatterFoilParameters[2] = {1.67, 20.};
}

AllenForwardToV2Tracks::AllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Out/ForwardTracks"}})
{}

StatusCode AllenForwardToV2Tracks::initialize()
{
  auto sc = Transformer::initialize();
  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  m_histos["x"] = book1D("x", -1, 1, 100);
  m_histos["y"] = book1D("y", -1, 1, 100);
  m_histos["z"] = book1D("z", -300, 600, 100);
  m_histos["tx"] = book1D("tx", -0.5, 0.5, 100);
  m_histos["ty"] = book1D("ty", -0.5, 0.5, 100);
  m_histos["chi2"] = book1D("chi2", 0, 100, 100);
  m_histos["chi2_newTrack"] = book1D("chi2_newTrack", 0, 100, 100);
  m_histos["ndof"] = book1D("ndof", -0.5, 49.5, 500);
  m_histos["ndof_newTrack"] = book1D("ndof_newTrack", -0.5, 49.5, 500);

  return StatusCode::SUCCESS;
}

LHCb::State propagate_state_from_first_measurement_to_beam(const LHCb::State state)
{
  const float t2 = sqrt(state.tx() * state.tx() + state.ty() * state.ty());

  const float scat2RFFoil =
    m_scatterFoilParameters[0] * (1.0 + m_scatterFoilParameters[1] * t2) * state.qOverP() * state.qOverP();
  LHCb::State beamline_state;
  beamline_state.covariance()(2, 2) = state.covariance()(2, 2) + scat2RFFoil;
  beamline_state.covariance()(3, 3) = state.covariance()(3, 3) + scat2RFFoil;

  float zBeam = state.z();
  float denom = state.tx() * state.tx() + state.ty() * state.ty();
  zBeam = (denom < 0.001f * 0.001f) ? zBeam : state.z() - (state.x() * state.tx() + state.y() * state.ty()) / denom;

  const float dz = zBeam - state.z();
  const float dz2 = dz * dz;

  beamline_state.covariance()(0, 0) =
    state.covariance()(0, 0) + dz2 * state.covariance()(2, 2) + 2 * dz * state.covariance()(0, 2);
  beamline_state.covariance()(0, 2) = state.covariance()(0, 2) + dz * state.covariance()(2, 2);
  beamline_state.covariance()(1, 1) =
    state.covariance()(1, 1) + dz2 * state.covariance()(3, 3) + 2 * dz * state.covariance()(1, 3);
  beamline_state.covariance()(1, 3) = state.covariance()(1, 3) + dz * state.covariance()(3, 3);

  beamline_state.setState(
    state.x() + dz * state.tx(), state.y() + dz * state.ty(), zBeam, state.tx(), state.ty(), state.qOverP());

  return beamline_state;
}

std::vector<LHCb::Event::v2::Track> AllenForwardToV2Tracks::operator()(const HostBuffers& host_buffers) const
{

  // Make the consolidated tracks.
  const uint i_event = 0;
  const uint number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) host_buffers.host_atomics_velo, (uint*) host_buffers.host_velo_track_hit_number, i_event, number_of_events};
  const UT::Consolidated::ConstExtendedTracks ut_tracks {(uint*) host_buffers.host_atomics_ut,
                                                         (uint*) host_buffers.host_ut_track_hit_number,
                                                         (float*) host_buffers.host_ut_qop,
                                                         (uint*) host_buffers.host_ut_track_velo_indices,
                                                         i_event,
                                                         number_of_events};
  const SciFi::Consolidated::ConstTracks scifi_tracks {(uint*) host_buffers.host_atomics_scifi,
                                                       (uint*) host_buffers.host_scifi_track_hit_number,
                                                       (float*) host_buffers.host_scifi_qop,
                                                       (MiniState*) host_buffers.host_scifi_states,
                                                       (uint*) host_buffers.host_scifi_track_ut_indices,
                                                       i_event,
                                                       number_of_events};

  // Do the conversion
  ParKalmanFilter::FittedTrack* kf_tracks = host_buffers.host_kf_tracks;
  const uint number_of_tracks = scifi_tracks.number_of_tracks(i_event);
  info() << "Number of SciFi tracks to convert = " << number_of_tracks << endmsg;

  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);
  for (uint t = 0; t < number_of_tracks; t++) {
    ParKalmanFilter::FittedTrack track = kf_tracks[t];
    auto& newTrack = output.emplace_back();

    // set track flags
    newTrack.setType(LHCb::Event::v2::Track::Type::Long);
    newTrack.setHistory(LHCb::Event::v2::Track::History::PrForward);
    newTrack.setPatRecStatus(LHCb::Event::v2::Track::PatRecStatus::PatRecIDs);
    newTrack.setFitStatus(LHCb::Event::v2::Track::FitStatus::Fitted);

    // get momentum
    float qop = track.state[4];
    float qopError = m_covarianceValues[4] * qop * qop;

    // closest to beam state
    LHCb::State first_measurement_state;
    first_measurement_state.setState(
      track.state[0], track.state[1], track.z, track.state[2], track.state[3], track.state[4]);

    first_measurement_state.covariance()(0, 0) = track.cov(0, 0);
    first_measurement_state.covariance()(0, 2) = track.cov(2, 0);
    first_measurement_state.covariance()(2, 2) = track.cov(2, 2);
    first_measurement_state.covariance()(1, 1) = track.cov(1, 1);
    first_measurement_state.covariance()(1, 3) = track.cov(3, 1);
    first_measurement_state.covariance()(3, 3) = track.cov(3, 3);
    first_measurement_state.covariance()(4, 4) = qopError;

    LHCb::State closesttobeam_state = propagate_state_from_first_measurement_to_beam(first_measurement_state);

    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    // SciFi state
    LHCb::State scifi_state;
    const MiniState& state = scifi_tracks.states(t);
    scifi_state.setState(state.x, state.y, state.z, state.tx, state.ty, qop);

    scifi_state.covariance()(0, 0) = m_covarianceValues[0];
    scifi_state.covariance()(0, 2) = 0.f;
    scifi_state.covariance()(2, 2) = m_covarianceValues[2];
    scifi_state.covariance()(1, 1) = m_covarianceValues[1];
    scifi_state.covariance()(1, 3) = 0.f;
    scifi_state.covariance()(3, 3) = m_covarianceValues[3];
    scifi_state.covariance()(4, 4) = qopError;

    scifi_state.setLocation(LHCb::State::Location::AtT);
    // newTrack.addToStates( scifi_state );

    // set chi2 / chi2ndof
    newTrack.setChi2PerDoF(LHCb::Event::v2::Track::Chi2PerDoF {track.chi2 / track.ndof, static_cast<int>(track.ndof)});

    // set LHCb IDs
    std::vector<LHCb::LHCbID> lhcbids;
    // add SciFi hits
    std::vector<uint32_t> scifi_ids = scifi_tracks.get_lhcbids_for_track(host_buffers.host_scifi_track_hits, t);
    for (const auto id : scifi_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add UT hits
    const uint UT_track_index = scifi_tracks.ut_track(t);
    std::vector<uint32_t> ut_ids = ut_tracks.get_lhcbids_for_track(host_buffers.host_ut_track_hits, UT_track_index);
    for (const auto id : ut_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add Velo hits
    const int velo_track_index = ut_tracks.velo_track(UT_track_index);
    std::vector<uint32_t> velo_ids =
      velo_tracks.get_lhcbids_for_track(host_buffers.host_velo_track_hits, velo_track_index);
    for (const auto id : velo_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // Fill histograms
    auto hist = m_histos.find("x");
    hist->second->fill(closesttobeam_state.x());
    hist = m_histos.find("y");
    hist->second->fill(closesttobeam_state.y());
    hist = m_histos.find("z");
    hist->second->fill(closesttobeam_state.z());
    hist = m_histos.find("tx");
    hist->second->fill(closesttobeam_state.tx());
    hist = m_histos.find("ty");
    hist->second->fill(closesttobeam_state.ty());
    hist = m_histos.find("chi2_newTrack");
    hist->second->fill(newTrack.chi2());
    hist = m_histos.find("chi2");
    hist->second->fill(track.chi2);
    hist = m_histos.find("ndof_newTrack");
    hist->second->fill(newTrack.nDoF());
    hist = m_histos.find("ndof");
    hist->second->fill(track.ndof);
  }

  return output;
}
