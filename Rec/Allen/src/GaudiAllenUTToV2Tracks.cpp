/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

/**
 * Convert Velo::Consolidated::Tracks into LHCb::Event::v2::Track
 *
 * author Dorothea vom Bruch
 *
 */

#ifndef GAUDIALLENTOUTTRACKS_H
#define GAUDIALLENTOUTTRACKS_H

#include <vector>

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "Logger.h"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"

class GaudiAllenUTToV2Tracks final : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(
                                       const std::vector<unsigned>&,
                                       const std::vector<unsigned>&,
                                       const std::vector<char>&,
                                       const std::vector<char>&,
                                       const std::vector<char>&,
                                       const std::vector<unsigned>&,
                                       const std::vector<unsigned>&,
                                       const std::vector<float>&,
                                       const std::vector<unsigned>&,
                                       const std::vector<char>&)> {
public:
  /// Standard constructor
  GaudiAllenUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<unsigned>&,
    const std::vector<unsigned>&,
    const std::vector<char>&,
    const std::vector<char>&,
    const std::vector<char>&,
    const std::vector<unsigned>&,
    const std::vector<unsigned>&,
    const std::vector<float>&,
    const std::vector<unsigned>&,
    const std::vector<char>&) const override;

private:
};

#endif

DECLARE_COMPONENT(GaudiAllenUTToV2Tracks)

GaudiAllenUTToV2Tracks::GaudiAllenUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"offsets_all_velo_tracks", ""},
     KeyValue {"offsets_velo_track_hit_number", ""},
     KeyValue {"velo_track_hits", ""},
     KeyValue {"velo_kalman_beamline_states", ""},
     KeyValue {"velo_kalman_endvelo_states", ""},
     KeyValue {"atomics_ut", ""},
     KeyValue {"ut_track_hit_number", ""},
     KeyValue {"ut_qop", ""},
     KeyValue {"ut_track_velo_indices", ""},
     KeyValue {"ut_track_hits", ""}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/VeloUT"}})
{}

std::vector<LHCb::Event::v2::Track> GaudiAllenUTToV2Tracks::operator()(
  const std::vector<unsigned>& offsets_all_velo_tracks,
  const std::vector<unsigned>& offsets_velo_track_hit_number,
  const std::vector<char>& velo_track_hits,
  const std::vector<char>& velo_kalman_beamline_states,
  const std::vector<char>& velo_kalman_endvelo_states,
  const std::vector<unsigned>& atomics_ut,
  const std::vector<unsigned>& ut_track_hit_number,
  const std::vector<float>& ut_qop,
  const std::vector<unsigned>& ut_track_velo_indices,
  const std::vector<char>& ut_track_hits) const
{

  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const unsigned number_of_events = 1;

  const Velo::Consolidated::Tracks velo_tracks {
    offsets_all_velo_tracks.data(), offsets_velo_track_hit_number.data(), i_event, number_of_events};
  const Velo::Consolidated::ConstStates velo_beamline_states(
    velo_kalman_beamline_states.data(), velo_tracks.total_number_of_tracks());
  const Velo::Consolidated::ConstStates velo_endvelo_states(
    velo_kalman_endvelo_states.data(), velo_tracks.total_number_of_tracks());
  const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(i_event);

  const UT::Consolidated::ConstExtendedTracks ut_tracks {atomics_ut.data(),
                                                         ut_track_hit_number.data(),
                                                         ut_qop.data(),
                                                         ut_track_velo_indices.data(),
                                                         i_event,
                                                         number_of_events};

  const unsigned number_of_tracks = ut_tracks.number_of_tracks(i_event);
  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  if (msgLevel(MSG::VERBOSE)) debug() << "Number of UT tracks to convert = " << number_of_tracks << endmsg;

  for (unsigned int t = 0; t < number_of_tracks; t++) {
    auto& newTrack = output.emplace_back();

    // add UT hits
    std::vector<uint32_t> ut_ids = ut_tracks.get_lhcbids_for_track(ut_track_hits.data(), t);
    for (const auto id : ut_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add Velo hits
    const int velo_track_index = ut_tracks.velo_track(t);
    std::vector<uint32_t> velo_ids = velo_tracks.get_lhcbids_for_track(velo_track_hits.data(), velo_track_index);
    for (const auto id : velo_ids) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // set state at beamline
    const unsigned velo_state_index = velo_event_tracks_offset + velo_track_index;
    const auto velo_beamline_state = velo_beamline_states.get(velo_state_index);
    LHCb::State closesttobeam_state;
    const float qop = ut_tracks.qop(t);
    closesttobeam_state.setState(
      velo_beamline_state.x,
      velo_beamline_state.y,
      velo_beamline_state.z,
      velo_beamline_state.tx,
      velo_beamline_state.ty,
      qop);
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    // set state at endvelo
    const auto velo_endvelo_state = velo_endvelo_states.get(velo_state_index);
    LHCb::State endvelo_state;
    endvelo_state.setState(
      velo_endvelo_state.x,
      velo_endvelo_state.y,
      velo_endvelo_state.z,
      velo_endvelo_state.tx,
      velo_endvelo_state.ty,
      qop);
    endvelo_state.setLocation(LHCb::State::Location::EndVelo);
    newTrack.addToStates(endvelo_state);

    // newTrack.setType( LHCb::Event::v2::Track::Type::VeloUT );
  }

  return output;
}
