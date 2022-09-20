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
#include "SciFiConsolidated.cuh"

class GaudiAllenSeedAndMatchNoUTToV2Tracks final
  : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(
      const std::vector<unsigned>&,
      const std::vector<unsigned>&,
      const std::vector<char>&,
      const std::vector<unsigned>&,
      const std::vector<unsigned>&,
      const std::vector<char>&,
      const std::vector<unsigned>&,
      const std::vector<float>&,
      const std::vector<MiniState>&,
      const std::vector<ParKalmanFilter::FittedTrack>&)> {

public:
  /// Standard constructor
  GaudiAllenSeedAndMatchNoUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<unsigned>& offsets_all_velo_tracks,
    const std::vector<unsigned>& offsets_velo_track_hit_number,
    const std::vector<char>& velo_track_hits,
    const std::vector<unsigned>& atomics_scifi,
    const std::vector<unsigned>& scifi_track_hit_number,
    const std::vector<char>& scifi_track_hits,
    const std::vector<unsigned>& scifi_track_velo_indices,
    const std::vector<float>& scifi_qop,
    const std::vector<MiniState>& scifi_states,
    const std::vector<ParKalmanFilter::FittedTrack>& kf_tracks) const override;

private:
  const std::array<float, 5> m_default_covarianceValues {4.0, 400.0, 4.e-6, 1.e-4, 0.1};
  Gaudi::Property<std::array<float, 5>> m_covarianceValues {this, "COVARIANCEVALUES", m_default_covarianceValues};
};

DECLARE_COMPONENT(GaudiAllenSeedAndMatchNoUTToV2Tracks)

GaudiAllenSeedAndMatchNoUTToV2Tracks::GaudiAllenSeedAndMatchNoUTToV2Tracks(
  const std::string& name,
  ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"offsets_all_velo_tracks", ""},
     KeyValue {"offsets_velo_track_hit_number", ""},
     KeyValue {"velo_track_hits", ""},
     KeyValue {"atomics_scifi", ""},
     KeyValue {"scifi_track_hit_number", ""},
     KeyValue {"scifi_track_hits", ""},
     KeyValue {"scifi_track_velo_indices", ""},
     KeyValue {"scifi_qop", ""},
     KeyValue {"scifi_states", ""},
     KeyValue {"kf_tracks", ""}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/SeedAndMatchTracks"}})
{}

StatusCode GaudiAllenSeedAndMatchNoUTToV2Tracks::initialize()
{
  auto sc = Transformer::initialize();
  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  return sc;
}

std::vector<LHCb::Event::v2::Track> GaudiAllenSeedAndMatchNoUTToV2Tracks::operator()(
  const std::vector<unsigned>& offsets_all_velo_tracks,
  const std::vector<unsigned>& offsets_velo_track_hit_number,
  const std::vector<char>& velo_track_hits,
  const std::vector<unsigned>& atomics_scifi,
  const std::vector<unsigned>& scifi_track_hit_number,
  const std::vector<char>& scifi_track_hits,
  const std::vector<unsigned>& scifi_track_velo_indices,
  const std::vector<float>& scifi_qop,
  const std::vector<MiniState>& scifi_states,
  const std::vector<ParKalmanFilter::FittedTrack>& kf_tracks) const
{
  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {
    offsets_all_velo_tracks.data(), offsets_velo_track_hit_number.data(), i_event, number_of_events};

  const SciFi::Consolidated::ConstTracks scifi_tracks {atomics_scifi.data(),
                                                       scifi_track_hit_number.data(),
                                                       scifi_qop.data(),
                                                       scifi_states.data(),
                                                       scifi_track_velo_indices.data(),
                                                       i_event,
                                                       number_of_events};

  // Do the conversion
  const unsigned number_of_tracks = scifi_tracks.number_of_tracks(i_event);
  if (msgLevel(MSG::DEBUG)) debug() << "Number of SciFi tracks to convert = " << number_of_tracks << endmsg;

  std::vector<LHCb::Event::v2::Track> seed_and_match_tracks;
  seed_and_match_tracks.reserve(number_of_tracks);
  for (unsigned t = 0; t < number_of_tracks; t++) {
    ParKalmanFilter::FittedTrack track = kf_tracks[t];
    auto& newTrack = seed_and_match_tracks.emplace_back();

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

    // set chi2 / chi2ndof
    newTrack.setChi2PerDoF(LHCb::Event::v2::Track::Chi2PerDoF {track.chi2 / track.ndof, static_cast<int>(track.ndof)});

    // set LHCb IDs
    std::vector<LHCb::LHCbID> lhcbids;
    // add SciFi hits
    std::vector<uint32_t> scifi_ids = scifi_tracks.get_lhcbids_for_track(scifi_track_hits.data(), t);
    for (const auto id : scifi_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add Velo hits
    const int velo_track_index = scifi_tracks.ut_track(t);
    std::vector<uint32_t> velo_ids = velo_tracks.get_lhcbids_for_track(velo_track_hits.data(), velo_track_index);
    for (const auto id : velo_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }
  }

  return seed_and_match_tracks;
}
