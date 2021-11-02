/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

/**
 * Convert Velo::Consolidated::Tracks into LHCb::Event::v2::Track
 */

#include "GaudiAllenVeloToV2Tracks.h"

DECLARE_COMPONENT(GaudiAllenVeloToV2Tracks)

GaudiAllenVeloToV2Tracks::GaudiAllenVeloToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenVeloTrackOffsets", ""},
     KeyValue {"AllenVeloTrackHitOffsets", ""},
     KeyValue {"AllenVeloTrackHits", ""},
     KeyValue {"AllenVeloKalmanStates", ""}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/Velo"}})
{}

std::vector<LHCb::Event::v2::Track> GaudiAllenVeloToV2Tracks::operator()(
  const std::vector<unsigned>& allen_velo_track_offsets,
  const std::vector<unsigned>& allen_velo_track_hit_offsets,
  const std::vector<char>& allen_velo_track_hits,
  const std::vector<char>& allen_velo_kalman_states) const
{
  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {
    allen_velo_track_offsets.data(), allen_velo_track_hit_offsets.data(), i_event, number_of_events};
  const Velo::Consolidated::ConstStates velo_states(
    allen_velo_kalman_states.data(), velo_tracks.total_number_of_tracks());
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(i_event);

  const unsigned number_of_tracks = velo_tracks.number_of_tracks(i_event);
  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  if (msgLevel(MSG::DEBUG)) debug() << "Number of Velo tracks to convert = " << number_of_tracks << endmsg;

  for (unsigned int t = 0; t < number_of_tracks; t++) {
    auto& newTrack = output.emplace_back();

    // add Velo hits
    Velo::Consolidated::ConstHits track_hits = velo_tracks.get_hits(allen_velo_track_hits.data(), t);
    for (unsigned i = 0; i < velo_tracks.number_of_hits(t); ++i) {
      const auto id = track_hits.id(i);
      const LHCb::LHCbID lhcbid {id};
      newTrack.addToLhcbIDs(lhcbid);
      if (msgLevel(MSG::DEBUG)) debug() << "Adding LHCbID " << std::hex << id << std::dec << endmsg;
    }

    // set state at beamline
    const unsigned current_track_offset = event_tracks_offset + t;
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(
      velo_states.x(current_track_offset),
      velo_states.y(current_track_offset),
      velo_states.z(current_track_offset),
      velo_states.tx(current_track_offset),
      velo_states.ty(current_track_offset),
      0.f);
    closesttobeam_state.covariance()(0, 0) = velo_states.c00(current_track_offset);
    closesttobeam_state.covariance()(1, 1) = velo_states.c11(current_track_offset);
    closesttobeam_state.covariance()(0, 2) = velo_states.c20(current_track_offset);
    closesttobeam_state.covariance()(2, 2) = velo_states.c22(current_track_offset);
    closesttobeam_state.covariance()(1, 3) = velo_states.c31(current_track_offset);
    closesttobeam_state.covariance()(3, 3) = velo_states.c33(current_track_offset);
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    newTrack.setType(LHCb::Event::v2::Track::Type::Velo); // CHECKME!!!
    newTrack.setHistory(LHCb::Event::v2::Track::History::PatFastVelo);
    newTrack.setPatRecStatus(LHCb::Event::v2::Track::PatRecStatus::PatRecIDs);
    const int firstRow = newTrack.lhcbIDs()[0].channelID();
    const int charge = (firstRow % 2 == 0 ? -1 : 1);
    for (auto& aState : newTrack.states()) {
      const float tx1 = aState.tx();
      const float ty1 = aState.ty();
      const float slope2 = std::max(tx1 * tx1 + ty1 * ty1, 1.e-20f);
      const float qop = charge * std::sqrt(slope2) / (m_ptVelo * std::sqrt(1.f + slope2));
      aState.setQOverP(qop);
      aState.setErrQOverP2(1e-6);
    }
  }

  return output;
}
