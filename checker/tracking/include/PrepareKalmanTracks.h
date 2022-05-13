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
#include "ParKalmanFittedTrack.cuh"
#include "ParKalmanMath.cuh"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"
#include "Argument.cuh"
#include "ParticleTypes.cuh"

// Kalman tracks.
float ipKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float ipxKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float ipyKalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float ipChi2Kalman(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);
float kalmanDOCAz(const ParKalmanFilter::FittedTrack& track, const PV::Vertex& vertex);

// Velo tracks.
float ipVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex);
float ipxVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex);
float ipyVelo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex);
float ipChi2Velo(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex);
float veloDOCAz(const Allen::Views::Velo::Consolidated::State& velo_kalman_state, const PV::Vertex& vertex);

std::vector<Checker::Tracks> prepareKalmanTracks(
  const unsigned number_of_events,
  gsl::span<const Allen::Views::Physics::MultiEventLongTracks> multi_event_long_tracks_view,
  gsl::span<const Allen::Views::Velo::Consolidated::States> velo_states,
  const char* host_scifi_geometry,
  gsl::span<const ParKalmanFilter::FittedTrack> kf_tracks,
  gsl::span<const PV::Vertex> rec_vertex,
  gsl::span<const unsigned> number_of_vertex,
  gsl::span<const mask_t> event_list);
