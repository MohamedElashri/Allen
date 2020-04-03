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
 * Convert Velo::Consolidated::Tracks into LHCb::Event::v2::Track
 *
 * author Dorothea vom Bruch
 *
 */

#include "AllenVeloToV2Tracks.h"

DECLARE_COMPONENT(AllenVeloToV2Tracks)

// function copied from Rec/Tr/TrackUtils/src/TracksVPConverter.cpp
void setFlagsAndPt(LHCb::Event::v2::Track& outtrack, float ptVelo)
{
  outtrack.setType(LHCb::Event::v2::Track::Type::Velo); // CHECKME!!!
  outtrack.setHistory(LHCb::Event::v2::Track::History::PatFastVelo);
  outtrack.setPatRecStatus(LHCb::Event::v2::Track::PatRecStatus::PatRecIDs);
  const int firstRow = outtrack.lhcbIDs()[0].channelID();
  const int charge = (firstRow % 2 == 0 ? -1 : 1);
  for (auto& aState : outtrack.states()) {
    const float tx1 = aState.tx();
    const float ty1 = aState.ty();
    const float slope2 = std::max(tx1 * tx1 + ty1 * ty1, 1.e-20f);
    const float qop = charge * std::sqrt(slope2) / (ptVelo * std::sqrt(1.f + slope2));
    aState.setQOverP(qop);
    aState.setErrQOverP2(1e-6);
  }
}

AllenVeloToV2Tracks::AllenVeloToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/Velo"}})
{}

std::vector<LHCb::Event::v2::Track> AllenVeloToV2Tracks::operator()(const HostBuffers& host_buffers) const
{

  // Make the consolidated tracks.
  const uint i_event = 0;
  const uint number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) host_buffers.host_atomics_velo, (uint*) host_buffers.host_velo_track_hit_number, i_event, number_of_events};
  const Velo::Consolidated::States velo_states(
    host_buffers.host_kalmanvelo_states, velo_tracks.total_number_of_tracks());
  const uint event_tracks_offset = velo_tracks.tracks_offset(i_event);

  const uint number_of_tracks = velo_tracks.number_of_tracks(i_event);
  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  if (msgLevel(MSG::DEBUG)) debug() << "Number of Velo tracks to convert = " << number_of_tracks << endmsg;

  for (unsigned int t = 0; t < number_of_tracks; t++) {
    auto& newTrack = output.emplace_back();

    // add Velo hits
    std::vector<uint32_t> velo_ids = velo_tracks.get_lhcbids_for_track(host_buffers.host_velo_track_hits, t);
    for (const auto id : velo_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
      if (msgLevel(MSG::DEBUG)) debug() << "Adding LHCbID " << std::hex << id << std::dec << endmsg;
    }

    // set state at beamline
    const uint current_track_offset = event_tracks_offset + t;
    const VeloState velo_state = velo_states.get(current_track_offset);
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(velo_state.x, velo_state.y, velo_state.z, velo_state.tx, velo_state.ty, 0.f);
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    setFlagsAndPt(newTrack, m_ptVelo);
  }

  return output;
}
