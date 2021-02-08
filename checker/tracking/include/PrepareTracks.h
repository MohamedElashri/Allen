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
  const unsigned number_of_events,
  const std::vector<unsigned>& track_atomics,
  const std::vector<unsigned>& track_hit_number,
  const std::vector<char>& track_hits,
  const std::vector<unsigned>& event_list);

/**
 * @brief Prepares tracks for Velo, UT consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareUTTracks(
  const unsigned number_of_events,
  const std::vector<unsigned>& velo_track_atomics,
  const std::vector<unsigned>& velo_track_hit_number,
  const std::vector<char>& velo_track_hits,
  const std::vector<char>& kalman_velo_states,
  const std::vector<unsigned>& ut_track_atomics,
  const std::vector<unsigned>& ut_track_hit_number,
  const std::vector<char>& ut_track_hits,
  const std::vector<unsigned>& ut_track_velo_indices,
  const std::vector<float>& ut_qop,
  const std::vector<unsigned>& event_list);

/**
 * @brief Prepares tracks for Velo, UT, SciFi consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareForwardTracks(
  const unsigned number_of_events,
  const std::vector<unsigned>& velo_track_atomics,
  const std::vector<unsigned>& velo_track_hit_number,
  const std::vector<char>& velo_track_hits,
  const std::vector<char>& kalman_velo_states,
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
  const std::vector<unsigned>& event_list,
  const std::vector<Allen::bool_as_char_t<bool>>& is_muon = {});
