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
#include "Argument.cuh"

float eta_from_rho(const float rho);

/**
 * @brief Prepares tracks for Velo consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareVeloTracks(
  const unsigned number_of_events,
  gsl::span<const unsigned> track_atomics,
  gsl::span<const unsigned> track_hit_number,
  gsl::span<const char> track_hits,
  gsl::span<const mask_t> event_list);

/**
 * @brief Prepares tracks for Velo, UT consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareUTTracks(
  const unsigned number_of_events,
  gsl::span<const unsigned> velo_track_atomics,
  gsl::span<const unsigned> velo_track_hit_number,
  gsl::span<const char> velo_track_hits,
  gsl::span<const char> kalman_velo_states,
  gsl::span<const unsigned> ut_track_atomics,
  gsl::span<const unsigned> ut_track_hit_number,
  gsl::span<const char> ut_track_hits,
  gsl::span<const unsigned> ut_track_velo_indices,
  gsl::span<const float> ut_qop,
  gsl::span<const mask_t> event_list);

/**
 * @brief Prepares tracks for Velo, UT, SciFi consolidated datatypes.
 */
std::vector<Checker::Tracks> prepareForwardTracks(
  const unsigned number_of_events,
  gsl::span<const unsigned> velo_track_atomics,
  gsl::span<const unsigned> velo_track_hit_number,
  gsl::span<const char> velo_track_hits,
  gsl::span<const char> kalman_velo_states,
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
  gsl::span<const mask_t> event_list,
  gsl::span<const Allen::bool_as_char_t<bool>> is_muon = {});

/**
 * @brief Read forward tracks from binary files
 */
std::vector<Checker::Tracks> read_forward_tracks(const char* events, const unsigned* event_offsets, const int n_events);
