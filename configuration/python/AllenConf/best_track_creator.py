###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import make_gec, initialize_number_of_events
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.scifi_reconstruction import (
    forward_tracking, make_seeding_XZ_tracks, make_seeding_tracks,
    decode_scifi, make_forward_tracks)
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate, make_algorithm
from AllenCore.algorithms import create_reduced_scifi_hit_container_t, combine_long_track_containers_t, host_prefix_sum_t
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.enum_types import TrackingType


def create_reduced_scifi_container(dev_used_scifi_hits):
    number_of_events = initialize_number_of_events()
    decoded_scifi = decode_scifi()

    prefix_sum_used_scifi_hits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_used_scifi_hits",
        dev_input_buffer_t=dev_used_scifi_hits)

    create_reduced_scifi_hit_container = make_algorithm(
        create_reduced_scifi_hit_container_t,
        name="create_reduced_scifi_hit_container",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_used_scifi_hits_offsets_t=prefix_sum_used_scifi_hits.
        dev_output_buffer_t,
        host_used_scifi_hits_offsets_t=prefix_sum_used_scifi_hits.
        host_output_buffer_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_scifi_hit_offsets_input_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_scifi_hits_input_t=decoded_scifi["dev_scifi_hits"])

    reduced_scifi_hit_container = {
        "host_number_of_scifi_hits":
        create_reduced_scifi_hit_container.host_number_of_scifi_hits_t,
        "dev_scifi_hits":
        create_reduced_scifi_hit_container.dev_scifi_hits_t,
        "dev_scifi_hit_offsets":
        create_reduced_scifi_hit_container.dev_scifi_hit_offsets_t,
    }

    return reduced_scifi_hit_container


def combine_long_containers(long_tracks_0, long_tracks_1):
    number_of_events = initialize_number_of_events()
    combine_long_track_containers = make_algorithm(
        combine_long_track_containers_t,
        name="combine_long_track_containers",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_long_track_view_0_t=long_tracks_0["dev_long_track_view"],
        dev_offset_tracks_0_t=long_tracks_0["dev_offsets_long_tracks"],
        dev_scifi_states_0_t=long_tracks_0["dev_scifi_states"],
        host_number_of_reconstructed_scifi_tracks_0_t=long_tracks_0[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_long_track_view_1_t=long_tracks_1["dev_long_track_view"],
        dev_offset_tracks_1_t=long_tracks_1["dev_offsets_long_tracks"],
        host_number_of_reconstructed_scifi_tracks_1_t=long_tracks_1[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_scifi_states_1_t=long_tracks_1["dev_scifi_states"],
    )

    combined_tracks = {
        "dev_offsets_long_tracks":
        combine_long_track_containers.dev_offset_tracks_output_t,
        "dev_multi_event_long_tracks_view":
        combine_long_track_containers.
        dev_multi_event_long_tracks_view_output_t,
        "dev_multi_event_long_tracks_ptr":
        combine_long_track_containers.dev_multi_event_long_tracks_ptr_output_t,
        "host_number_of_reconstructed_scifi_tracks":
        combine_long_track_containers.
        host_number_of_reconstructed_scifi_tracks_output_t,
        "dev_scifi_states":
        combine_long_track_containers.dev_scifi_states_output_t,
        "velo_tracks":
        long_tracks_0["velo_tracks"],
        "velo_kalman_filter":
        long_tracks_0["velo_kalman_filter"],
    }

    if "seeding_tracks" in long_tracks_0.keys():
        combined_tracks.update({
            "seeding_tracks":
            long_tracks_0["seeding_tracks"]
        })
    elif "seeding_tracks" in long_tracks_1.keys():
        combined_tracks.update({
            "seeding_tracks":
            long_tracks_1["seeding_tracks"]
        })

    return combined_tracks


def best_track_creator(with_ut=True,
                       tracking_type=TrackingType.FORWARD_THEN_MATCHING,
                       algorithm_name=''):
    if algorithm_name != '':
        algorithm_name = algorithm_name + '_'
    if tracking_type == TrackingType.FORWARD_THEN_MATCHING:
        forward_tracks = forward_tracking(with_ut)
        reduced_scifi_hit_container = create_reduced_scifi_container(
            forward_tracks["dev_used_scifi_hits"])

        decoded_velo = decode_velo()
        velo_tracks = make_velo_tracks(decoded_velo)
        velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
        seeding_xz_tracks = make_seeding_XZ_tracks(reduced_scifi_hit_container)
        seeding_tracks = make_seeding_tracks(
            reduced_scifi_hit_container,
            seeding_xz_tracks,
            scifi_consolidate_seeds_name=algorithm_name +
            'scifi_consolidate_seeds')
        matched_tracks = make_velo_scifi_matches(
            velo_tracks,
            velo_kalman_filter,
            seeding_tracks,
            forward_tracks["dev_accepted_and_unused_velo_tracks"],
            matching_consolidate_tracks_name=algorithm_name +
            'matching_consolidate_tracks')
    elif tracking_type == TrackingType.MATCHING_THEN_FORWARD:
        decoded_velo = decode_velo()
        velo_tracks = make_velo_tracks(decoded_velo)
        velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
        decoded_scifi = decode_scifi()
        seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
        seeding_tracks = make_seeding_tracks(
            decoded_scifi,
            seeding_xz_tracks,
            scifi_consolidate_seeds_name=algorithm_name +
            'scifi_consolidate_seeds')
        matched_tracks = make_velo_scifi_matches(
            velo_tracks,
            velo_kalman_filter,
            seeding_tracks,
            matching_consolidate_tracks_name=algorithm_name +
            'matching_consolidate_tracks')

        reduced_scifi_hit_container = create_reduced_scifi_container(
            matched_tracks["dev_used_scifi_hits"])

        if with_ut:
            decoded_ut = decode_ut()
            ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
            input_tracks = ut_tracks
        else:
            input_tracks = velo_tracks

        forward_tracks = make_forward_tracks(
            reduced_scifi_hit_container,
            input_tracks,
            matched_tracks["dev_accepted_and_unused_velo_tracks"],
            with_ut,
            scifi_consolidate_tracks_name=algorithm_name +
            'scifi_consolidate_tracks')
    else:
        raise Exception("Tracking type not supported")

    return combine_long_containers(forward_tracks, matched_tracks)
