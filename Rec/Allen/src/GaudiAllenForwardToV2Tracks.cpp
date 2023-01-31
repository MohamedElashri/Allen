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
#include "ParticleTypes.cuh"

#include <AIDA/IHistogram1D.h>

/**
 * Convert Velo::Consolidated::Tracks into LHCb::Event::v2::Track
 */

class GaudiAllenForwardToV2Tracks final
  : public Gaudi::Functional::Transformer<
      std::vector<LHCb::Event::v2::Track>(const std::vector<Allen::Views::Physics::MultiEventBasicParticles>&),
      Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {

public:
  /// Standard constructor
  GaudiAllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<Allen::Views::Physics::MultiEventBasicParticles>& allen_tracks_mec) const override;

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
    {KeyValue {"allen_tracks_mec", ""}},
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
  const std::vector<Allen::Views::Physics::MultiEventBasicParticles>& allen_tracks_mec) const
{
  const unsigned i_event = 0;
  const auto allen_tracks_view = allen_tracks_mec[0].container(i_event);
  const auto number_of_tracks = allen_tracks_view.size();

  // Do the conversion
  if (msgLevel(MSG::DEBUG)) debug() << "Number of SciFi tracks to convert = " << number_of_tracks << endmsg;

  std::vector<LHCb::Event::v2::Track> forward_tracks;
  forward_tracks.reserve(number_of_tracks);
  for (unsigned t = 0; t < number_of_tracks; t++) {
    const auto track = allen_tracks_view.particle(t);
    auto& newTrack = forward_tracks.emplace_back();

    // set track flags
    newTrack.setType(LHCb::Event::v2::Track::Type::Long);
    newTrack.setHistory(LHCb::Event::v2::Track::History::PrForward);
    newTrack.setPatRecStatus(LHCb::Event::v2::Track::PatRecStatus::PatRecIDs);
    newTrack.setFitStatus(LHCb::Event::v2::Track::FitStatus::Fitted);

    // get momentum
    float qop = track.state().qop();
    float qopError = m_covarianceValues[4] * qop * qop;

    // closest to beam state
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(
      track.state().x(),
      track.state().y(),
      track.state().z(),
      track.state().tx(),
      track.state().ty(),
      track.state().qop());

    closesttobeam_state.covariance()(0, 0) = track.state().c00();
    closesttobeam_state.covariance()(0, 2) = track.state().c20();
    closesttobeam_state.covariance()(2, 2) = track.state().c22();
    closesttobeam_state.covariance()(1, 1) = track.state().c11();
    closesttobeam_state.covariance()(1, 3) = track.state().c31();
    closesttobeam_state.covariance()(3, 3) = track.state().c33();
    closesttobeam_state.covariance()(4, 4) = qopError;

    closesttobeam_state.setLocation(LHCb::State::Location::ClosestToBeam);
    newTrack.addToStates(closesttobeam_state);

    // SciFi state

    // TODO: We can't just get the SciFi state from the basic particle. These
    // aren't combined when combining tracking methods, so if we have a
    // LookingForward + HybridSeeding sequence, we can't just pass the states
    // seperately. If this is necessary we should add a pointer to the SciFi
    // segment.

    // LHCb::State scifi_state;
    // const MiniState& state = scifi_tracks.states(t);
    // scifi_state.setState(state.x, state.y, state.z, state.tx, state.ty, qop);

    // scifi_state.covariance()(0, 0) = m_covarianceValues[0];
    // scifi_state.covariance()(0, 2) = 0.f;
    // scifi_state.covariance()(2, 2) = m_covarianceValues[2];
    // scifi_state.covariance()(1, 1) = m_covarianceValues[1];
    // scifi_state.covariance()(1, 3) = 0.f;
    // scifi_state.covariance()(3, 3) = m_covarianceValues[3];
    // scifi_state.covariance()(4, 4) = qopError;

    // scifi_state.setLocation(LHCb::State::Location::AtT);
    // newTrack.addToStates( scifi_state );

    // set chi2 / chi2ndof
    newTrack.setChi2PerDoF(LHCb::Event::v2::Track::Chi2PerDoF {track.state().chi2() / track.state().ndof(),
                                                               static_cast<int>(track.state().ndof())});

    // add SciFi hits
    const auto n_hits = track.number_of_ids();
    for (unsigned int i_hit = 0; i_hit < n_hits; i_hit++) {
      const LHCb::LHCbID lhcbid = LHCb::LHCbID(track.id(i_hit));
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
    hist->second->fill(track.state().chi2());
    hist = m_histos.find("ndof_newTrack");
    hist->second->fill(newTrack.nDoF());
    hist = m_histos.find("ndof");
    hist->second->fill(track.state().ndof());
  }

  return forward_tracks;
}
