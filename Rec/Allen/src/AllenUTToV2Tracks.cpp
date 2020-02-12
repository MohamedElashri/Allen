
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

#include "AllenUTToV2Tracks.h"

DECLARE_COMPONENT(AllenUTToV2Tracks)

AllenUTToV2Tracks::AllenUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/VeloUT"}})
{}

StatusCode AllenUTToV2Tracks::initialize()
{
  auto sc = Transformer::initialize();
  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

std::vector<LHCb::Event::v2::Track> AllenUTToV2Tracks::operator()(const HostBuffers& host_buffers) const
{

  // Make the consolidated tracks.
  const uint i_event = 0;
  const uint number_of_events = 1;

  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) host_buffers.host_atomics_velo, (uint*) host_buffers.host_velo_track_hit_number, i_event, number_of_events};
  const Velo::Consolidated::States velo_states(
    host_buffers.host_kalmanvelo_states, velo_tracks.total_number_of_tracks());
  const uint velo_event_tracks_offset = velo_tracks.tracks_offset(i_event);

  const UT::Consolidated::ConstExtendedTracks ut_tracks {(uint*) host_buffers.host_atomics_ut,
                                                         (uint*) host_buffers.host_ut_track_hit_number,
                                                         (float*) host_buffers.host_ut_qop,
                                                         (uint*) host_buffers.host_ut_track_velo_indices,
                                                         i_event,
                                                         number_of_events};

  const uint number_of_tracks = ut_tracks.number_of_tracks(i_event);
  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  info() << "Number of UT tracks to convert = " << number_of_tracks << endmsg;

  for (unsigned int t = 0; t < number_of_tracks; t++) {
    auto& newTrack = output.emplace_back();

    // add UT hits
    std::vector<uint32_t> ut_ids = ut_tracks.get_lhcbids_for_track(host_buffers.host_ut_track_hits, t);
    for (const auto id : ut_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add Velo hits
    const int velo_track_index = ut_tracks.velo_track(t);
    std::vector<uint32_t> velo_ids =
      velo_tracks.get_lhcbids_for_track(host_buffers.host_velo_track_hits, velo_track_index);
    for (const auto id : velo_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // set state at beamline
    const uint velo_state_index = velo_event_tracks_offset + velo_track_index;
    const VeloState velo_state = velo_states.get(velo_state_index);
    LHCb::State closesttobeam_state;
    const float qop = ut_tracks.qop(t);
    closesttobeam_state.setState(velo_state.x, velo_state.y, velo_state.z, velo_state.tx, velo_state.ty, qop);
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    // newTrack.setType( LHCb::Event::v2::Track::Type::VeloUT );
  }

  return output;
}
