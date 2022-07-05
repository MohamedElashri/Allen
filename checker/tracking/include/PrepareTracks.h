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
#include "Datatype.cuh"
#include "ParticleTypes.cuh"

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

std::vector<Checker::Tracks> prepareSeedingTracks(
  const unsigned number_of_events,
  gsl::span<const unsigned> scifi_seed_atomics,
  gsl::span<const unsigned> scifi_seed_hit_number,
  gsl::span<const char> scifi_seed_hits,
  gsl::span<const SciFi::Seeding::Track> scifi_seeds,
  gsl::span<const MiniState> seeding_states,
  gsl::span<const mask_t> event_list);

std::vector<Checker::Tracks> prepareSeedingTracksXZ(
  const unsigned number_of_events,
  gsl::span<const unsigned> scifi_seed_atomics,
  gsl::span<const unsigned> scifi_seed_hit_number,
  gsl::span<const SciFi::Seeding::TrackXZ> scifi_seeds,
  gsl::span<const mask_t> event_list);

/**
 * @brief Read forward tracks from binary files
 */
std::vector<Checker::Tracks> read_forward_tracks(const char* events, const unsigned* event_offsets, const int n_events);
