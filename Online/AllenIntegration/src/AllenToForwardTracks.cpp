
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
 * Convert ParKalmanFilter::FittedTrack and SciFi::Consolidated::Tracks into LHCb::Event::v2::Track
 *
 * author Dorothea vom Bruch
 *
 */


#include "AllenToForwardTracks.h"

DECLARE_COMPONENT( AllenToForwardTracks )

AllenToForwardTracks::AllenToForwardTracks( const std::string& name, ISvcLocator* pSvcLocator )
: Transformer( name, pSvcLocator,
                    // Inputs
                          {KeyValue{"AllenOutput", "Allen/Out/HostBuffers"}},
                    // Outputs
                    {KeyValue{"OutputTracks", "Allen/Out/ForwardTracks"}} ) {}

StatusCode AllenToForwardTracks::initialize() {
  auto sc = Transformer::initialize();
  if ( sc.isFailure() ) return sc;
  if ( msgLevel( MSG::DEBUG ) ) debug() << "==> Initialize" << endmsg;

  return StatusCode::SUCCESS;
}

std::vector<LHCb::Event::v2::Track> AllenToForwardTracks::operator()(const HostBuffers& host_buffers ) const {

  // Make the consolidated tracks.
  const uint i_event = 0;
  const uint number_of_events = 1;
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) host_buffers.host_atomics_velo, (uint*) host_buffers.host_velo_track_hit_number, i_event, number_of_events};
  const UT::Consolidated::Tracks ut_tracks {(uint*) host_buffers.host_atomics_ut,
      (uint*) host_buffers.host_ut_track_hit_number,
      (float*) host_buffers.host_ut_qop,
      (uint*) host_buffers.host_ut_track_velo_indices,
      i_event,
      number_of_events};
  const SciFi::Consolidated::Tracks scifi_tracks {(uint*) host_buffers.host_atomics_scifi,
      (uint*) host_buffers.host_scifi_track_hit_number,
      (float*) host_buffers.host_scifi_qop,
      (MiniState*) host_buffers.host_scifi_states,
      (uint*) host_buffers.host_scifi_track_ut_indices,
      i_event,
      number_of_events};

  // Do the conversion
  ParKalmanFilter::FittedTrack* kf_tracks = host_buffers.host_kf_tracks;
  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(i_event);
  info() << "Number of SciFi tracks to convert = " << number_of_tracks_event << endmsg;
  
  std::vector<LHCb::Event::v2::Track> output;
  output.reserve( number_of_tracks_event );
  for (uint t = 0; t < number_of_tracks_event; t++) {
    ParKalmanFilter::FittedTrack track = kf_tracks[t];
    auto& newTrack = output.emplace_back();

    // set track flags
    newTrack.setType( LHCb::Event::v2::Track::Type::Long );
    newTrack.setHistory( LHCb::Event::v2::Track::History::PrForward );
    newTrack.setPatRecStatus( LHCb::Event::v2::Track::PatRecStatus::PatRecIDs );
    newTrack.setFitStatus( LHCb::Event::v2::Track::FitStatus::Fitted );

    // get momentum
    float qop = track.state[4];
    float qopError = m_covarianceValues[4] * qop * qop;

    // closest to beam state
    LHCb::State closesttobeam_state;
    closesttobeam_state.setState(
      track.state[0],
      track.state[1],
      track.z,
      track.state[2],
      track.state[3],
      track.state[4]);
    
    closesttobeam_state.covariance()( 0, 0 ) = track.cov(0,0);
    closesttobeam_state.covariance()( 0, 2 ) = track.cov(2,0);
    closesttobeam_state.covariance()( 2, 2 ) = track.cov(2,2);
    closesttobeam_state.covariance()( 1, 1 ) = track.cov(1,1);
    closesttobeam_state.covariance()( 1, 3 ) = track.cov(3,1);
    closesttobeam_state.covariance()( 3, 3 ) = track.cov(3,3);
    closesttobeam_state.covariance()( 4, 4 ) = qopError;
    
    closesttobeam_state.setLocation( LHCb::State::Location::ClosestToBeam );
    newTrack.addToStates( closesttobeam_state );
    
    // SciFi state 
    LHCb::State scifi_state;
    const MiniState& state = scifi_tracks.states[t];
    scifi_state.setState(state.x, state.y, state.z, state.tx, state.ty, qop);

    scifi_state.covariance()( 0, 0 ) = m_covarianceValues[0];
    scifi_state.covariance()( 0, 2 ) = 0.f;
    scifi_state.covariance()( 2, 2 ) = m_covarianceValues[2];
    scifi_state.covariance()( 1, 1 ) = m_covarianceValues[1];
    scifi_state.covariance()( 1, 3 ) = 0.f;
    scifi_state.covariance()( 3, 3 ) = m_covarianceValues[3];
    scifi_state.covariance()( 4, 4 ) = qopError;
    
    scifi_state.setLocation( LHCb::State::Location::AtT );
    newTrack.addToStates( scifi_state );
    
    // set chi2 / chi2ndof
    newTrack.setChi2PerDoF( LHCb::Event::v2::Track::Chi2PerDoF{track.chi2,track.ndof} );

    // set LHCb IDs
    std::vector<LHCbID> lhcbids;
    // add SciFi hits
    std::vector<uint32_t> scifi_ids = scifi_tracks.get_lhcbids_for_track(host_buffers.host_scifi_track_hits, t);
    for (const auto id : scifi_ids) {
      newTrack.addToLhcbIDs( static_cast<const LHCb::LHCbID&>(LHCb::LHCbID(id)) );
    }
    
    // add UT hits
    std::vector<uint32_t> ut_ids = ut_tracks.get_lhcbids_for_track(host_buffers.host_ut_track_hits, t);
    for (const auto id : ut_ids) {
      newTrack.addToLhcbIDs( static_cast<const LHCb::LHCbID&>(LHCb::LHCbID(id)) );
    }
    
    // add Velo hits
    std::vector<uint32_t> velo_ids = velo_tracks.get_lhcbids_for_track(host_buffers.host_velo_track_hits, t);
    for (const auto id : velo_ids) {
      newTrack.addToLhcbIDs( static_cast<const LHCb::LHCbID&>(LHCb::LHCbID(id)) );
    }

    // std::cout << "Track has the following" << newTrack.lhcbIDs().size() << "LHCbIDs" << std::endl;
    // for (const auto& id : newTrack.lhcbIDs() ) {
    //   std::cout << "\t " << std::hex << id.lhcbID() << std::dec << std::endl;
    // }
   
  }
  
  return output;
}


