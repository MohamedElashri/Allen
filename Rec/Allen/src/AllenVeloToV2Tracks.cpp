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
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {(unsigned*) host_buffers.host_atomics_velo,
                                                (unsigned*) host_buffers.host_velo_track_hit_number,
                                                i_event,
                                                number_of_events};
  const Velo::Consolidated::States velo_beamline_states(
    host_buffers.host_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks());
  const Velo::Consolidated::States velo_endvelo_states(
    host_buffers.host_velo_kalman_endvelo_states, velo_tracks.total_number_of_tracks());
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(i_event);

  const unsigned number_of_tracks = velo_tracks.number_of_tracks(i_event);
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
    const unsigned current_track_offset = event_tracks_offset + t;
    const KalmanVeloState velo_beamline_state = velo_beamline_states.get_kalman_state(current_track_offset);
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(
      velo_beamline_state.x,
      velo_beamline_state.y,
      velo_beamline_state.z,
      velo_beamline_state.tx,
      velo_beamline_state.ty,
      0.f);
    closesttobeam_state.covariance()(0, 0) = velo_beamline_state.c00;
    closesttobeam_state.covariance()(1, 1) = velo_beamline_state.c11;
    closesttobeam_state.covariance()(0, 2) = velo_beamline_state.c20;
    closesttobeam_state.covariance()(2, 2) = velo_beamline_state.c22;
    closesttobeam_state.covariance()(1, 3) = velo_beamline_state.c31;
    closesttobeam_state.covariance()(3, 3) = velo_beamline_state.c33;
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    // set state at endvelo
    const KalmanVeloState velo_endvelo_state = velo_endvelo_states.get_kalman_state(current_track_offset);
    LHCb::State endvelo_state;
    endvelo_state.setState(
      velo_endvelo_state.x,
      velo_endvelo_state.y,
      velo_endvelo_state.z,
      velo_endvelo_state.tx,
      velo_endvelo_state.ty,
      0.f);
    endvelo_state.covariance()(0, 0) = velo_endvelo_state.c00;
    endvelo_state.covariance()(1, 1) = velo_endvelo_state.c11;
    endvelo_state.covariance()(0, 2) = velo_endvelo_state.c20;
    endvelo_state.covariance()(2, 2) = velo_endvelo_state.c22;
    endvelo_state.covariance()(1, 3) = velo_endvelo_state.c31;
    endvelo_state.covariance()(3, 3) = velo_endvelo_state.c33;
    endvelo_state.setLocation(LHCb::State::Location::EndVelo);
    newTrack.addToStates(endvelo_state);

    setFlagsAndPt(newTrack, m_ptVelo);
  }

  return output;
}
