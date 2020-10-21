/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

/**
 * Convert ParKalmanFilter::FittedTrack and SciFi::Consolidated::Tracks into LHCb::Event::v2::Track
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenForwardToV2Tracks.h"

DECLARE_COMPONENT(AllenForwardToV2Tracks)

AllenForwardToV2Tracks::AllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  MultiTransformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Out/ForwardTracks"},
     KeyValue {"OutputMuonTracks", "Allen/Out/ForwardMuonTracks"}})
{}

StatusCode AllenForwardToV2Tracks::initialize()
{
  auto sc = MultiTransformer::initialize();
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

  return sc;
}

std::tuple<std::vector<LHCb::Event::v2::Track>, std::vector<LHCb::Event::v2::Track>> AllenForwardToV2Tracks::operator()(
  const HostBuffers& host_buffers) const
{

  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {(unsigned*) host_buffers.host_atomics_velo,
                                                (unsigned*) host_buffers.host_velo_track_hit_number,
                                                i_event,
                                                number_of_events};
  const UT::Consolidated::ConstExtendedTracks ut_tracks {(unsigned*) host_buffers.host_atomics_ut,
                                                         (unsigned*) host_buffers.host_ut_track_hit_number,
                                                         (float*) host_buffers.host_ut_qop,
                                                         (unsigned*) host_buffers.host_ut_track_velo_indices,
                                                         i_event,
                                                         number_of_events};
  const SciFi::Consolidated::ConstTracks scifi_tracks {(unsigned*) host_buffers.host_atomics_scifi,
                                                       (unsigned*) host_buffers.host_scifi_track_hit_number,
                                                       (float*) host_buffers.host_scifi_qop,
                                                       (MiniState*) host_buffers.host_scifi_states,
                                                       (unsigned*) host_buffers.host_scifi_track_ut_indices,
                                                       i_event,
                                                       number_of_events};

  // Do the conversion
  ParKalmanFilter::FittedTrack* kf_tracks = host_buffers.host_kf_tracks;
  const unsigned number_of_tracks = scifi_tracks.number_of_tracks(i_event);
  if (msgLevel(MSG::DEBUG)) debug() << "Number of SciFi tracks to convert = " << number_of_tracks << endmsg;

  std::vector<LHCb::Event::v2::Track> forward_tracks;
  forward_tracks.reserve(number_of_tracks);
  std::vector<LHCb::Event::v2::Track> forward_muon_tracks;
  for (unsigned t = 0; t < number_of_tracks; t++) {
    ParKalmanFilter::FittedTrack track = kf_tracks[t];
    auto& newTrack = forward_tracks.emplace_back();

    // set track flags
    newTrack.setType(LHCb::Event::v2::Track::Type::Long);
    newTrack.setHistory(LHCb::Event::v2::Track::History::PrForward);
    newTrack.setPatRecStatus(LHCb::Event::v2::Track::PatRecStatus::PatRecIDs);
    newTrack.setFitStatus(LHCb::Event::v2::Track::FitStatus::Fitted);

    // get momentum
    float qop = track.state[4];
    float qopError = m_covarianceValues[4] * qop * qop;

    // closest to beam state
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(
      track.state[0], track.state[1], track.z, track.state[2], track.state[3], track.state[4]);

    closesttobeam_state.covariance()(0, 0) = track.cov(0, 0);
    closesttobeam_state.covariance()(0, 2) = track.cov(2, 0);
    closesttobeam_state.covariance()(2, 2) = track.cov(2, 2);
    closesttobeam_state.covariance()(1, 1) = track.cov(1, 1);
    closesttobeam_state.covariance()(1, 3) = track.cov(3, 1);
    closesttobeam_state.covariance()(3, 3) = track.cov(3, 3);
    closesttobeam_state.covariance()(4, 4) = qopError;

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
    const unsigned UT_track_index = scifi_tracks.ut_track(t);
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

    // fill list of tracks identified as muon
    if (host_buffers.host_is_muon[t]) {
      forward_muon_tracks.push_back(newTrack);
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

  return std::make_tuple(forward_tracks, forward_muon_tracks);
}
