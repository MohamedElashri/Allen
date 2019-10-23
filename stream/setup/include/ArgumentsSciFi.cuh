#pragma once

#include "Argument.cuh"
#include "SciFiEventModel.cuh"
#include "States.cuh"

/**
 * @brief Definition of arguments. All arguments should be defined here,
 *        with their associated type.
 */
ARGUMENT(dev_scifi_hit_count, uint)
ARGUMENT(dev_scifi_hit_permutations, uint)
ARGUMENT(dev_scifi_hits, uint)
ARGUMENT(dev_scifi_tracks, SciFi::TrackHits)
ARGUMENT(dev_scifi_track_candidates, SciFi::TrackCandidate)
ARGUMENT(dev_atomics_scifi, uint)
ARGUMENT(dev_scifi_track_hit_number, uint)
ARGUMENT(dev_scifi_track_hits, char)
ARGUMENT(dev_scifi_qop, float)
ARGUMENT(dev_scifi_states, MiniState)
ARGUMENT(dev_scifi_track_ut_indices, uint)
ARGUMENT(dev_scifi_selected_track_indices, uint)

ARGUMENT(dev_scifi_lf_first_layer_candidates, uint)
ARGUMENT(dev_scifi_lf_second_layer_candidates, unsigned short)
ARGUMENT(dev_ut_states, MiniState)
ARGUMENT(dev_extrapolation_layer_candidates, unsigned short)
ARGUMENT(dev_scifi_track_promoted_candidates, bool)

ARGUMENT(dev_scifi_lf_initial_windows, int)
ARGUMENT(dev_scifi_lf_number_of_candidates, uint)
ARGUMENT(dev_scifi_lf_candidates, short)
ARGUMENT(dev_scifi_lf_compatible_windows, short)
ARGUMENT(dev_scifi_lf_candidates_flag, bool)
ARGUMENT(dev_scifi_lf_candidate_atomics, int)
ARGUMENT(dev_scifi_lf_tracks, SciFi::TrackHits)
ARGUMENT(dev_scifi_lf_atomics, uint)
ARGUMENT(dev_scifi_lf_x_filtered_tracks, SciFi::TrackHits)
ARGUMENT(dev_scifi_lf_x_filtered_atomics, uint)
ARGUMENT(dev_scifi_lf_length_filtered_tracks, SciFi::TrackHits)
ARGUMENT(dev_scifi_lf_length_filtered_atomics, uint)
ARGUMENT(dev_scifi_lf_uv_windows, short)
ARGUMENT(dev_scifi_lf_triplet_best, SciFi::CombinedValue)
ARGUMENT(dev_scifi_lf_track_params, float)
ARGUMENT(dev_scifi_lf_xAtRef, float)
ARGUMENT(dev_scifi_lf_xAtRef_after_length_filter, float)
ARGUMENT(dev_scifi_lf_active_ut_tracks, uint)
ARGUMENT(dev_scifi_lf_number_of_active_ut_tracks, uint)
ARGUMENT(dev_scifi_lf_parametrization, float)
ARGUMENT(dev_scifi_lf_parametrization_x_filter, float)
ARGUMENT(dev_scifi_lf_collected_hits_atomics, uint)
ARGUMENT(dev_scifi_lf_collected_hits_tracks, uint)