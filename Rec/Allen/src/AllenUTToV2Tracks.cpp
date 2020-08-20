/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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

std::vector<LHCb::Event::v2::Track> AllenUTToV2Tracks::operator()(const HostBuffers& host_buffers) const
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
  const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(i_event);

  const UT::Consolidated::ConstExtendedTracks ut_tracks {(unsigned*) host_buffers.host_atomics_ut,
                                                         (unsigned*) host_buffers.host_ut_track_hit_number,
                                                         (float*) host_buffers.host_ut_qop,
                                                         (unsigned*) host_buffers.host_ut_track_velo_indices,
                                                         i_event,
                                                         number_of_events};

  const unsigned number_of_tracks = ut_tracks.number_of_tracks(i_event);
  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  if (msgLevel(MSG::VERBOSE)) debug() << "Number of UT tracks to convert = " << number_of_tracks << endmsg;

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
    const unsigned velo_state_index = velo_event_tracks_offset + velo_track_index;
    const VeloState velo_beamline_state = velo_beamline_states.get(velo_state_index);
    LHCb::State closesttobeam_state;
    const float qop = ut_tracks.qop(t);
    closesttobeam_state.setState(velo_beamline_state.x, velo_beamline_state.y, velo_beamline_state.z, velo_beamline_state.tx, velo_beamline_state.ty, qop);
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    // set state at endvelo
    const VeloState velo_endvelo_state = velo_endvelo_states.get(velo_state_index);
    LHCb::State endvelo_state;
    const float qop = ut_tracks.qop(t);
    endvelo_state.setState(velo_endvelo_state.x, velo_endvelo_state.y, velo_endvelo_state.z, velo_endvelo_state.tx, velo_endvelo_state.ty, qop);
    endvelo_state.setLocation(LHCb::State::Location::EndVelo);
    newTrack.addToStates(endvelo_state);

    // newTrack.setType( LHCb::Event::v2::Track::Type::VeloUT );
  }

  return output;
}
