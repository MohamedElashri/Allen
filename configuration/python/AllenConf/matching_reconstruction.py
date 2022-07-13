###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import host_prefix_sum_t, track_matching_veloSciFi_t, matching_copy_track_hit_number_t, matching_consolidate_tracks_t, ut_select_velo_tracks_t
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def make_velo_scifi_matches(velo_tracks, velo_kalman_filter, seeding_tracks):
    number_of_events = initialize_number_of_events()

    ut_select_velo_tracks = make_algorithm(
        ut_select_velo_tracks_t,
        name="ut_select_velo_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_beamline_states_view"],
        dev_accepted_velo_tracks_t=velo_tracks["dev_accepted_velo_tracks"])

    matched_tracks = make_algorithm(
        track_matching_veloSciFi_t,
        name="track_matching_veloSciFi",
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
        dev_ut_selected_velo_tracks_t)

    prefix_sum_matched_tracks = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_matched_tracks",
        dev_input_buffer_t=matched_tracks.dev_atomics_matched_tracks_t)

    matching_copy_track_hit_number = make_algorithm(
        matching_copy_track_hit_number_t,
        name="matching_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_matched_tracks_t=prefix_sum_matched_tracks
        .host_total_sum_holder_t,
        dev_matched_tracks_t=matched_tracks.dev_matched_tracks_t,
        dev_offsets_matched_tracks_t=prefix_sum_matched_tracks.
        dev_output_buffer_t,
        dev_event_list_t=number_of_events["dev_number_of_events"])

    prefix_sum_matched_track_hit_number = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_matched_track_hit_number",
        dev_input_buffer_t=matching_copy_track_hit_number.
        dev_matched_track_hit_number_t)

    matching_consolidate_tracks = make_algorithm(
        matching_consolidate_tracks_t,
        name="matching_consolidate_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_accumulated_number_of_hits_in_matched_tracks_t=
        prefix_sum_matched_track_hit_number.host_total_sum_holder_t,
        host_number_of_reconstructed_matched_tracks_t=prefix_sum_matched_tracks
        .host_total_sum_holder_t,
        dev_offsets_matched_tracks_t=prefix_sum_matched_tracks.
        dev_output_buffer_t,
        dev_offsets_matched_hit_number_t=prefix_sum_matched_track_hit_number.
        dev_output_buffer_t,
        dev_matched_tracks_t=matched_tracks.dev_matched_tracks_t,
        dev_scifi_tracks_view_t=seeding_tracks["dev_scifi_tracks_view"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"])

    return {
        "velo_tracks":
        velo_tracks,
        "velo_kalman_filter":
        velo_kalman_filter,
        "seeding_tracks":
        seeding_tracks,
        "matched_tracks":
        matched_tracks.dev_matched_tracks_t,
        "matched_atomics":
        matched_tracks.dev_atomics_matched_tracks_t,
        "dev_scifi_track_hits":
        matching_consolidate_tracks.dev_matched_track_hits_t,
        "dev_scifi_states":
        seeding_tracks["dev_seeding_states"],
        "dev_scifi_track_ut_indices":
        matching_consolidate_tracks.dev_matched_track_velo_indices_t,
        "host_number_of_reconstructed_scifi_tracks":
        prefix_sum_matched_tracks.host_total_sum_holder_t,
        "dev_offsets_long_tracks":
        prefix_sum_matched_tracks.
        dev_output_buffer_t,  #naming convention same as in forward so that hlt1 sequence works
        "dev_offsets_scifi_track_hit_number":
        prefix_sum_matched_track_hit_number.dev_output_buffer_t,
        "dev_scifi_tracks_view":
        seeding_tracks["dev_scifi_tracks_view"],
        "dev_multi_event_long_tracks_view":
        matching_consolidate_tracks.dev_multi_event_long_tracks_view_t,
        "dev_multi_event_long_tracks_ptr":
        matching_consolidate_tracks.dev_multi_event_long_tracks_ptr_t,
        # Needed for long track particle dependencies.
        "dev_scifi_track_view":
        seeding_tracks["dev_scifi_track_view"],
        "dev_scifi_hits_view":
        seeding_tracks["dev_scifi_hits_view"],
        "dev_ut_number_of_selected_velo_tracks":
        ut_select_velo_tracks.dev_ut_number_of_selected_velo_tracks_t,
        "dev_ut_selected_velo_tracks":
        ut_select_velo_tracks.dev_ut_selected_velo_tracks_t
    }


def velo_scifi_matching():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
    matched_tracks = make_velo_scifi_matches(velo_tracks, velo_kalman_filter,
                                             seeding_tracks)
    return matched_tracks["matched_tracks"]
