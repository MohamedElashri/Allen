###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import track_matching_t, matching_copy_track_ut_hit_number_t, matching_consolidate_tracks_t, ut_select_velo_tracks_t
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.ut_reconstruction import make_dummy_ut_hits
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable


@configurable
def make_velo_scifi_matches(
        velo_tracks,
        velo_kalman_filter,
        seeding_tracks,
        ut_hits=None,
        accepted_velo_tracks=None,
        ghost_killer_threshold=0.5,
        force_skip_ut=False,
        matching_no_ut_ghost_killer_version=2,
        matching_consolidate_tracks_name='matching_consolidate_tracks'):
    number_of_events = initialize_number_of_events()

    if not accepted_velo_tracks:
        accepted_velo_tracks = velo_tracks["dev_accepted_velo_tracks"]

    if not ut_hits:
        ut_hits = make_dummy_ut_hits()

    ut_select_velo_tracks = make_algorithm(
        ut_select_velo_tracks_t,
        name="ut_select_velo_tracks_{hash}",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_beamline_states_view"],
        dev_accepted_velo_tracks_t=accepted_velo_tracks)

    # list of the two momentum parametrisation. 1st is for magUp, 2nd is for magDown

    momentum_parameters_magUp = (34.27448, 1.239076e+03, 5.650170e+02,
                                 -7.683592e+01, 6.148917e+02, 2.071115e+03,
                                 -6.795680e+03, 4.577582e+02)  #magUp
    momentum_parameters_magDown = (
        1239.4073749458162, 486.05664058906814, 6.7158701518424815,
        632.7283787142547, 2358.5758035677504, -9256.27946160669,
        241.4601040854867, 42.04859549174048)  #magDown

    matched_tracks = make_algorithm(
        track_matching_t,
        name='track_matching_veloSciFi_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"],
        dev_scifi_tracks_view_t=seeding_tracks["dev_scifi_tracks_view"],
        dev_seeding_states_t=seeding_tracks["dev_seeding_states"],
        dev_ut_number_of_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_number_of_selected_velo_tracks_t,
        dev_ut_selected_velo_tracks_t=ut_select_velo_tracks.
        dev_ut_selected_velo_tracks_t,
        # UT
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        host_accumulated_number_of_ut_hits_t=ut_hits[
            "host_accumulated_number_of_ut_hits"],
        # Properties
        multiplication_factor_dX=1.5,
        multiplication_factor_dY=0.2,
        multiplication_factor_dty=937.5,
        multiplication_factor_dtx=2.0,
        ghost_killer_threshold=ghost_killer_threshold,
        momentum_parameters_magUp=momentum_parameters_magUp,
        momentum_parameters_magDown=momentum_parameters_magDown,
        # Dimension tunning (with A5000)
        block_dim=(128, 1, 1),
        force_skip_ut=force_skip_ut,
        matching_no_ut_ghost_killer_version=matching_no_ut_ghost_killer_version
    )

    matching_copy_track_ut_hit_number = make_algorithm(
        matching_copy_track_ut_hit_number_t,
        name='matching_copy_track_ut_hit_number_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_matched_tracks_t=matched_tracks.
        host_number_of_reconstructed_matched_tracks_t,
        dev_matched_tracks_t=matched_tracks.dev_matched_tracks_t,
        dev_offsets_matched_tracks_t=matched_tracks.
        dev_offsets_matched_tracks_t)

    matching_consolidate_tracks = make_algorithm(
        matching_consolidate_tracks_t,
        name=str(matching_consolidate_tracks_name),
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Velo tracks
        dev_accepted_velo_tracks_t=accepted_velo_tracks,
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"],
        # SciFi tracks
        host_number_of_reconstructed_scifi_tracks_t=seeding_tracks[
            'host_number_of_reconstructed_seeding_tracks'],
        dev_scifi_tracks_view_t=seeding_tracks["dev_scifi_tracks_view"],
        dev_seeding_states_t=seeding_tracks["dev_seeding_states"],
        # UT hits
        host_accumulated_number_of_ut_hits_t=ut_hits[
            "host_accumulated_number_of_ut_hits"],
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        # Matching results (general)
        host_number_of_reconstructed_matched_tracks_t=matched_tracks.
        host_number_of_reconstructed_matched_tracks_t,
        dev_offsets_matched_tracks_t=matched_tracks.
        dev_offsets_matched_tracks_t,
        dev_matched_tracks_t=matched_tracks.dev_matched_tracks_t,
        # Matching results (UT related)
        host_accumulated_number_of_ut_hits_in_matched_tracks_t=
        matching_copy_track_ut_hit_number.host_total_sum_holder_t,
        dev_offsets_matched_ut_hit_number_t=matching_copy_track_ut_hit_number.
        dev_offsets_matched_ut_hit_number_t)

    return {
        #
        # Debug nodes
        #
        'alg_ut_select_velo_tracks':
        ut_select_velo_tracks,
        'alg_matched_tracks':
        matched_tracks,
        'alg_matching_copy_track_ut_hit_number':
        matching_copy_track_ut_hit_number,
        'alg_matching_consolidate_tracks':
        matching_consolidate_tracks,
        #
        # Outputs
        #
        "velo_tracks":
        velo_tracks,
        "velo_kalman_filter":
        velo_kalman_filter,
        "seeding_tracks":
        seeding_tracks,
        "matched_tracks":
        matched_tracks.dev_matched_tracks_t,
        "matched_atomics":
        matched_tracks.dev_offsets_matched_tracks_t,
        "dev_scifi_states":
        matching_consolidate_tracks.dev_scifi_states_t,
        "dev_scifi_track_ut_indices":
        matching_consolidate_tracks.dev_matched_track_velo_indices_t,
        "dev_matched_is_scifi_track_used":
        matching_consolidate_tracks.dev_matched_is_scifi_track_used_t,
        "host_number_of_reconstructed_scifi_tracks":
        matched_tracks.host_number_of_reconstructed_matched_tracks_t,
        "dev_offsets_long_tracks":
        matched_tracks.
        dev_offsets_matched_tracks_t,  #naming convention same as in forward so that hlt1 sequence works
        "dev_offsets_scifi_track_hit_number":
        matching_copy_track_ut_hit_number.dev_offsets_matched_ut_hit_number_t,
        "dev_scifi_tracks_view":
        seeding_tracks["dev_scifi_tracks_view"],
        "dev_multi_event_long_tracks_view":
        matching_consolidate_tracks.dev_multi_event_long_tracks_view_t,
        "dev_multi_event_long_tracks_ptr":
        matching_consolidate_tracks.dev_multi_event_long_tracks_ptr_t,
        "dev_long_track_view":
        matching_consolidate_tracks.dev_long_track_view_t,
        # Needed for long track particle dependencies.
        "dev_scifi_track_view":
        seeding_tracks["dev_scifi_track_view"],
        "dev_scifi_hits_view":
        seeding_tracks["dev_scifi_hits_view"],
        "dev_ut_number_of_selected_velo_tracks":
        ut_select_velo_tracks.dev_ut_number_of_selected_velo_tracks_t,
        "dev_ut_selected_velo_tracks":
        ut_select_velo_tracks.dev_ut_selected_velo_tracks_t,
        "dev_used_scifi_hits":
        seeding_tracks["dev_used_scifi_hits"],
        "dev_accepted_and_unused_velo_tracks":
        matching_consolidate_tracks.dev_accepted_and_unused_velo_tracks_t,
        "dev_used_ut_hits_offsets":
        matching_consolidate_tracks.dev_used_ut_hits_offsets_t,
    }


def velo_scifi_matching(algorithm_name='',
                        ut_hits=None,
                        output_name='matched_tracks'):
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(
        decoded_scifi,
        seeding_xz_tracks,
        scifi_consolidate_seeds_name=algorithm_name +
        '_scifi_consolidate_seeds_velo_scifi_matching')
    matched_tracks = make_velo_scifi_matches(
        velo_tracks,
        velo_kalman_filter,
        seeding_tracks,
        ut_hits=ut_hits,
        matching_consolidate_tracks_name=algorithm_name +
        '_matching_consolidate_tracks_velo_scifi_matching')
    return matched_tracks[output_name]
