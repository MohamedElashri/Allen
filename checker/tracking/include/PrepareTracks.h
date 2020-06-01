/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include "TrackChecker.h"
#include "Logger.h"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"
#include "States.cuh"

float eta_from_rho(const float rho);

/**
 * @brief Prepares tracks for Velo consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareVeloTracks(
  const unsigned* track_atomics,
  const unsigned* track_hit_number,
  const char* track_hits,
  const unsigned number_of_events,
  const unsigned event_list_size,
  const unsigned* event_list);

/**
 * @brief Prepares tracks for Velo, UT consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareUTTracks(
  const unsigned* velo_track_atomics,
  const unsigned* velo_track_hit_number,
  const char* velo_track_hits,
  const char* kalman_velo_states,
  const unsigned* ut_track_atomics,
  const unsigned* ut_track_hit_number,
  const char* ut_track_hits,
  const unsigned* ut_track_velo_indices,
  const float* ut_qop,
  const unsigned number_of_events,
  const unsigned event_list_size,
  const unsigned* event_list);

/**
 * @brief Prepares tracks for Velo, UT, SciFi consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareSciFiTracks(
  const unsigned* velo_track_atomics,
  const unsigned* velo_track_hit_number,
  const char* velo_track_hits,
  const char* kalman_velo_states,
  const unsigned* ut_track_atomics,
  const unsigned* ut_track_hit_number,
  const char* ut_track_hits,
  const unsigned* ut_track_velo_indices,
  const float* ut_qop,
  const unsigned* scifi_track_atomics,
  const unsigned* scifi_track_hit_number,
  const char* scifi_track_hits,
  const unsigned* scifi_track_ut_indices,
  const float* scifi_qop,
  const MiniState* scifi_states,
  const char* host_scifi_geometry,
  const std::array<float, 9>& host_inv_clus_res,
  const float* muon_catboost_output,
  const bool* is_muon,
  const unsigned number_of_events);
