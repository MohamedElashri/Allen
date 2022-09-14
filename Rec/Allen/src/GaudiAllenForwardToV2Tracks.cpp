/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "Logger.h"
#include "ParKalmanFittedTrack.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"

#include <AIDA/IHistogram1D.h>

/**
 * Convert Velo::Consolidated::Tracks into LHCb::Event::v2::Track
 */

class GaudiAllenForwardToV2Tracks final : public Gaudi::Functional::Transformer<
                                            std::vector<LHCb::Event::v2::Track>(
                                              const std::vector<unsigned>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<char>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<char>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<float>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<char>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<float>&,
                                              const std::vector<MiniState>&,
                                              const std::vector<ParKalmanFilter::FittedTrack>&),
                                            Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {

public:
  /// Standard constructor
  GaudiAllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<unsigned>& allen_offsets_all_velo_tracks,
    const std::vector<unsigned>& allen_offsets_velo_track_hit_number,
    const std::vector<char>& allen_velo_track_hits,
    const std::vector<unsigned>& allen_atomics_ut,
    const std::vector<unsigned>& allen_ut_track_hit_number,
    const std::vector<char>& allen_ut_track_hits,
    const std::vector<unsigned>& allen_ut_track_velo_indices,
    const std::vector<float>& allen_ut_qop,
    const std::vector<unsigned>& allen_atomics_scifi,
    const std::vector<unsigned>& allen_scifi_track_hit_number,
    const std::vector<char>& allen_scifi_track_hits,
    const std::vector<unsigned>& allen_scifi_track_ut_indices,
    const std::vector<float>& allen_scifi_qop,
    const std::vector<MiniState>& allen_scifi_states,
    const std::vector<ParKalmanFilter::FittedTrack>& allen_kf_tracks) const override;

private:
  const std::array<float, 5> m_default_covarianceValues {4.0, 400.0, 4.e-6, 1.e-4, 0.1};
  Gaudi::Property<std::array<float, 5>> m_covarianceValues {this, "COVARIANCEVALUES", m_default_covarianceValues};

  std::unordered_map<std::string, AIDA::IHistogram1D*> m_histos;
};

DECLARE_COMPONENT(GaudiAllenForwardToV2Tracks)

GaudiAllenForwardToV2Tracks::GaudiAllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_offsets_all_velo_tracks", ""},
     KeyValue {"allen_offsets_velo_track_hit_number", ""},
     KeyValue {"allen_velo_track_hits", ""},
     KeyValue {"allen_atomics_ut", ""},
     KeyValue {"allen_ut_track_hit_number", ""},
     KeyValue {"allen_ut_track_hits", ""},
     KeyValue {"allen_ut_track_velo_indices", ""},
     KeyValue {"allen_ut_qop", ""},
     KeyValue {"allen_atomics_scifi", ""},
     KeyValue {"allen_scifi_track_hit_number", ""},
     KeyValue {"allen_scifi_track_hits", ""},
     KeyValue {"allen_scifi_track_ut_indices", ""},
     KeyValue {"allen_scifi_qop", ""},
     KeyValue {"allen_scifi_states", ""},
     KeyValue {"allen_kf_tracks", ""}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/ForwardTracks"}})
{}

StatusCode GaudiAllenForwardToV2Tracks::initialize()
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

  return sc;
}

std::vector<LHCb::Event::v2::Track> GaudiAllenForwardToV2Tracks::operator()(
  const std::vector<unsigned>& allen_offsets_all_velo_tracks,
  const std::vector<unsigned>& allen_offsets_velo_track_hit_number,
  const std::vector<char>& allen_velo_track_hits,
  const std::vector<unsigned>& allen_atomics_ut,
  const std::vector<unsigned>& allen_ut_track_hit_number,
  const std::vector<char>& allen_ut_track_hits,
  const std::vector<unsigned>& allen_ut_track_velo_indices,
  const std::vector<float>& allen_ut_qop,
  const std::vector<unsigned>& allen_atomics_scifi,
  const std::vector<unsigned>& allen_scifi_track_hit_number,
  const std::vector<char>& allen_scifi_track_hits,
  const std::vector<unsigned>& allen_scifi_track_ut_indices,
  const std::vector<float>& allen_scifi_qop,
  const std::vector<MiniState>& allen_scifi_states,
  const std::vector<ParKalmanFilter::FittedTrack>& allen_kf_tracks) const
{
  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {
    allen_offsets_all_velo_tracks.data(), allen_offsets_velo_track_hit_number.data(), i_event, number_of_events};
  const UT::Consolidated::ConstExtendedTracks ut_tracks {allen_atomics_ut.data(),
                                                         allen_ut_track_hit_number.data(),
                                                         allen_ut_qop.data(),
                                                         allen_ut_track_velo_indices.data(),
                                                         i_event,
                                                         number_of_events};
  const SciFi::Consolidated::ConstTracks scifi_tracks {allen_atomics_scifi.data(),
                                                       allen_scifi_track_hit_number.data(),
                                                       allen_scifi_qop.data(),
                                                       allen_scifi_states.data(),
                                                       allen_scifi_track_ut_indices.data(),
                                                       i_event,
                                                       number_of_events};

  // Do the conversion
  const unsigned number_of_tracks = scifi_tracks.number_of_tracks(i_event);
  if (msgLevel(MSG::DEBUG)) debug() << "Number of SciFi tracks to convert = " << number_of_tracks << endmsg;

  std::vector<LHCb::Event::v2::Track> forward_tracks;
  forward_tracks.reserve(number_of_tracks);
  for (unsigned t = 0; t < number_of_tracks; t++) {
    ParKalmanFilter::FittedTrack track = allen_kf_tracks[t];
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
    std::vector<uint32_t> scifi_ids = scifi_tracks.get_lhcbids_for_track(allen_scifi_track_hits.data(), t);
    for (const auto id : scifi_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add UT hits
    const unsigned UT_track_index = scifi_tracks.ut_track(t);
    std::vector<uint32_t> ut_ids = ut_tracks.get_lhcbids_for_track(allen_ut_track_hits.data(), UT_track_index);
    for (const auto id : ut_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add Velo hits
    const int velo_track_index = ut_tracks.velo_track(UT_track_index);
    std::vector<uint32_t> velo_ids = velo_tracks.get_lhcbids_for_track(allen_velo_track_hits.data(), velo_track_index);
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

  return forward_tracks;
}
