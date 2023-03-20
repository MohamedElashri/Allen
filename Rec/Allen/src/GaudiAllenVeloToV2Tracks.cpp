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
#include "VeloConsolidated.cuh"
#include "States.cuh"

/**
 * Convert Velo::Consolidated::Tracks into LHCb::Event::v2::Track
 */

class GaudiAllenVeloToV2Tracks final : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(
                                         const std::vector<Allen::IMultiEventContainer*>&,
                                         const std::vector<Allen::Views::Physics::KalmanStates>&)> {
public:
  /// Standard constructor
  GaudiAllenVeloToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<Allen::IMultiEventContainer*>& allen_velo_tracks_mec,
    const std::vector<Allen::Views::Physics::KalmanStates>& allen_velo_kalman_states) const override;

private:
  Gaudi::Property<float> m_ptVelo {this, "ptVelo", 400 * Gaudi::Units::MeV, "Default pT for Velo tracks"};
};

DECLARE_COMPONENT(GaudiAllenVeloToV2Tracks)

GaudiAllenVeloToV2Tracks::GaudiAllenVeloToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"allen_velo_tracks_mec", ""}, KeyValue {"allen_velo_states_view", ""}},
    // Outputs
    {KeyValue {"OutputTracks", "Allen/Track/v2/Velo"}})
{}

std::vector<LHCb::Event::v2::Track> GaudiAllenVeloToV2Tracks::operator()(
  const std::vector<Allen::IMultiEventContainer*>& allen_velo_tracks_mec,
  const std::vector<Allen::Views::Physics::KalmanStates>& allen_velo_kalman_states) const
{
  // Make the consolidated tracks.
  const unsigned i_event = 0;
  const auto velo_tracks_view =
    static_cast<Allen::Views::Velo::Consolidated::MultiEventTracks*>(allen_velo_tracks_mec[0])->container(i_event);
  const unsigned number_of_tracks = velo_tracks_view.size();

  std::vector<LHCb::Event::v2::Track> output;
  output.reserve(number_of_tracks);

  if (msgLevel(MSG::DEBUG)) debug() << "Number of Velo tracks to convert = " << number_of_tracks << endmsg;

  for (unsigned int t = 0; t < number_of_tracks; t++) {
    auto& newTrack = output.emplace_back();

    // add Velo hits
    const auto track = velo_tracks_view.track(t);
    const unsigned n_hits = track.number_of_ids();
    for (unsigned i = 0; i < n_hits; ++i) {
      const auto id = track.id(i);
      const LHCb::LHCbID lhcbid {id};
      newTrack.addToLhcbIDs(lhcbid);
      if (msgLevel(MSG::DEBUG)) debug() << "Adding LHCbID " << std::hex << id << std::dec << endmsg;
    }

    // set state at beamline
    const auto state = track.state(allen_velo_kalman_states[0]);
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(state.x, state.y, state.z, state.tx, state.ty, 0.f);
    closesttobeam_state.covariance()(0, 0) = state.c00;
    closesttobeam_state.covariance()(1, 1) = state.c11;
    closesttobeam_state.covariance()(0, 2) = state.c20;
    closesttobeam_state.covariance()(2, 2) = state.c22;
    closesttobeam_state.covariance()(1, 3) = state.c31;
    closesttobeam_state.covariance()(3, 3) = state.c33;
    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    const bool backward = closesttobeam_state.z() > track.hit(0).z();

    if (backward)
      newTrack.setType(LHCb::Event::v2::Track::Type::VeloBackward);
    else
      newTrack.setType(LHCb::Event::v2::Track::Type::Velo);

    newTrack.setHistory(LHCb::Event::v2::Track::History::PrPixel);
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
