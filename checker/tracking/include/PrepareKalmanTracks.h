/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include "CheckerTypes.h"
#include "Logger.h"
#include "InputTools.h"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"

// Kalman tracks.
float ipKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float ipxKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float ipyKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float ipChi2Kalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float kalmanDOCAz(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);

// Velo tracks.
float ipVelo(
  const Velo::Consolidated::States& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex);
float ipxVelo(
  const Velo::Consolidated::States& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex);
float ipyVelo(
  const Velo::Consolidated::States& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex);
float ipChi2Velo(
  const Velo::Consolidated::States& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex);
float veloDOCAz(
  const Velo::Consolidated::States& velo_kalman_states,
  const unsigned state_index,
  const PV::Vertex& vertex);

std::vector<Checker::Tracks> prepareKalmanTracks(
  const unsigned number_of_events,
  const std::vector<unsigned>& velo_track_atomics,
  const std::vector<unsigned>& velo_track_hit_number,
  const std::vector<char>& velo_track_hits,
  const std::vector<char>& velo_states_base,
  const std::vector<unsigned>& ut_track_atomics,
  const std::vector<unsigned>& ut_track_hit_number,
  const std::vector<char>& ut_track_hits,
  const std::vector<unsigned>& ut_track_velo_indices,
  const std::vector<float>& ut_qop,
  const std::vector<unsigned>& scifi_track_atomics,
  const std::vector<unsigned>& scifi_track_hit_number,
  const std::vector<char>& scifi_track_hits,
  const std::vector<unsigned>& scifi_track_ut_indices,
  const std::vector<float>& scifi_qop,
  const std::vector<MiniState>& scifi_states,
  const char* host_scifi_geometry,
  const std::vector<ParKalmanFilter::FittedTrack>& kf_tracks,
  const std::vector<PV::Vertex>& rec_vertex,
  const std::vector<unsigned>& number_of_vertex,
  const std::vector<unsigned>& event_list);
