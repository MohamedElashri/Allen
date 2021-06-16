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
#include "Argument.cuh"

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
  gsl::span<const unsigned> velo_track_atomics,
  gsl::span<const unsigned> velo_track_hit_number,
  gsl::span<const char> velo_track_hits,
  gsl::span<const char> velo_states_base,
  gsl::span<const unsigned> ut_track_atomics,
  gsl::span<const unsigned> ut_track_hit_number,
  gsl::span<const char> ut_track_hits,
  gsl::span<const unsigned> ut_track_velo_indices,
  gsl::span<const float> ut_qop,
  gsl::span<const unsigned> scifi_track_atomics,
  gsl::span<const unsigned> scifi_track_hit_number,
  gsl::span<const char> scifi_track_hits,
  gsl::span<const unsigned> scifi_track_ut_indices,
  gsl::span<const float> scifi_qop,
  gsl::span<const MiniState> scifi_states,
  const char* host_scifi_geometry,
  gsl::span<const ParKalmanFilter::FittedTrack> kf_tracks,
  gsl::span<const PV::Vertex> rec_vertex,
  gsl::span<const unsigned> number_of_vertex,
  gsl::span<const mask_t> event_list);
