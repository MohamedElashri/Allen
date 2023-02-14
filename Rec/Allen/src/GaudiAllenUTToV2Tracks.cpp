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
#include "States.cuh"

class GaudiAllenUTToV2Tracks final : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(
                                       const std::vector<Allen::IMultiEventContainer*>&,
                                       const std::vector<Allen::Views::Physics::KalmanStates>&,
                                       const std::vector<Allen::Views::Physics::KalmanStates>&)> {
public:
  /// Standard constructor
  GaudiAllenUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<Allen::IMultiEventContainer*>& allen_ut_tracks_mec,
    const std::vector<Allen::Views::Physics::KalmanStates>& allen_beamline_states,
    const std::vector<Allen::Views::Physics::KalmanStates>& allen_endvelo_states) const override;

private:
};

#endif

DECLARE_COMPONENT(GaudiAllenUTToV2Tracks)

GaudiAllenUTToV2Tracks::GaudiAllenUTToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_ut_tracks_mec", ""},
     KeyValue {"allen_beamline_states_view", ""},
     KeyValue {"allen_endvelo_states_view", ""}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/VeloUT"}})
{}

std::vector<LHCb::Event::v2::Track> GaudiAllenUTToV2Tracks::operator()(
  const std::vector<Allen::IMultiEventContainer*>& allen_ut_tracks_mec,
  const std::vector<Allen::Views::Physics::KalmanStates>& allen_beamline_states,
  const std::vector<Allen::Views::Physics::KalmanStates>& allen_endvelo_states) const
{

  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const auto ut_tracks_view =
    static_cast<Allen::Views::UT::Consolidated::MultiEventTracks*>(allen_ut_tracks_mec[0])->container(i_event);
  const unsigned number_of_tracks = ut_tracks_view.size();

  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  if (msgLevel(MSG::VERBOSE)) debug() << "Number of UT tracks to convert = " << number_of_tracks << endmsg;

  for (unsigned int t = 0; t < number_of_tracks; t++) {
    auto& newTrack = output.emplace_back();

    // add UT hits
    const auto track = ut_tracks_view.track(t);
    const unsigned n_hits = track.number_of_ids();
    for (unsigned int i = 0; i < n_hits; i++) {
      const auto id = track.id(i);
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // add Velo hits
    const auto velo_track = track.velo_track();
    const unsigned n_velo_hits = velo_track.number_of_ids();
    for (unsigned int i = 0; i < n_velo_hits; i++) {
      const auto id = velo_track.id(i);
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(id);
      newTrack.addToLhcbIDs(lhcbid);
    }

    // set state at beamline
    const auto velo_beamline_state = velo_track.state(allen_beamline_states[0]);
    LHCb::State closesttobeam_state;
    const float qop = track.qop();
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
    const auto velo_endvelo_state = velo_track.state(allen_endvelo_states[0]);
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
