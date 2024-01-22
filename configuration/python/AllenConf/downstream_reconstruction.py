###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

from AllenCore.algorithms import (
    downstream_find_hits_t, downstream_create_tracks_t, host_prefix_sum_t,
    downstream_copy_hit_number_t, downstream_consolidate_t,
    downstream_make_particles_t, downstream_ut_filter_t,
    downstream_update_ut_offset_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from PyConf.tonic import configurable


@configurable
def make_downstream(decoded_ut,
                    scifi_seeds,
                    velo_scifi_matches,
                    ghost_killer_threshold=0.5,
                    ut_tracks=None):
    number_of_events = initialize_number_of_events()

    # Filter used ut hits
    if ut_tracks is not None:
        downstream_num_hits_per_sector = make_algorithm(
            downstream_update_ut_offset_t,
            name='downstream_update_ut_offset',
            # Basics
            host_number_of_events_t=number_of_events["host_number_of_events"],
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            # UT
            host_accumulated_number_of_ut_hits_t=decoded_ut[
                "host_accumulated_number_of_ut_hits"],
            dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
            # Compass UT
            dev_is_ut_hit_used_t=ut_tracks['dev_is_ut_hit_used'])
        prefix_sum_downstream_num_hits_per_sector = make_algorithm(
            host_prefix_sum_t,
            name="prefix_sum_downstream_num_hits_per_sector",
            dev_input_buffer_t=downstream_num_hits_per_sector.
            dev_num_hits_per_sector_t)

        filtered_hits = make_algorithm(
            downstream_ut_filter_t,
            name='downstream_ut_filter',
            # Basics
            host_number_of_events_t=number_of_events["host_number_of_events"],
            dev_number_of_events_t=number_of_events["dev_number_of_events"],
            # UT
            host_accumulated_number_of_ut_hits_t=decoded_ut[
                "host_accumulated_number_of_ut_hits"],
            dev_ut_hits_t=decoded_ut["dev_ut_hits"],
            dev_ut_hit_offsets_t=decoded_ut["dev_ut_hit_offsets"],
            # Compass UT
            dev_is_ut_hit_used_t=ut_tracks['dev_is_ut_hit_used'],
            # New offsets
            dev_filtered_hits_offsets_t=
            prefix_sum_downstream_num_hits_per_sector.dev_output_buffer_t,
            host_total_number_of_filtered_hits_t=
            prefix_sum_downstream_num_hits_per_sector.host_total_sum_holder_t,
        )
        ut_hits = {
            "dev_ut_hits":
            filtered_hits.dev_filtered_hits_t,
            "dev_ut_hit_offsets":
            prefix_sum_downstream_num_hits_per_sector.dev_output_buffer_t,
            "host_accumulated_number_of_ut_hits":
            prefix_sum_downstream_num_hits_per_sector.host_total_sum_holder_t,
        }
    else:
        ut_hits = decoded_ut

    downstream_find_hits = make_algorithm(
        downstream_find_hits_t,
        name='downstream_find_hits',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # Matching
        dev_matched_is_scifi_track_used_t=velo_scifi_matches[
            "dev_matched_is_scifi_track_used"],
        # Scifi
        dev_offsets_seeding_t=scifi_seeds["dev_offsets_scifi_seeds"],
        dev_seeding_states_t=scifi_seeds["dev_seeding_states"],
        dev_seeding_qop_t=scifi_seeds["dev_seeding_qop"],
        dev_seeding_chi2Y_t=scifi_seeds["dev_seeding_chi2Y"],
        # UT
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        host_accumulated_number_of_ut_hits_t=ut_hits[
            "host_accumulated_number_of_ut_hits"])

    downstream_create_tracks = make_algorithm(
        downstream_create_tracks_t,
        name='downstream_create_tracks',
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        # From find hits
        dev_find_hits_output_table_t=downstream_find_hits.dev_output_table_t,
        dev_find_hits_num_row_output_table_t=downstream_find_hits.
        dev_num_row_output_table_t,
        # SciFi
        dev_selected_scifi_t=downstream_find_hits.dev_selected_scifi_t,
        dev_num_selected_scifi_t=downstream_find_hits.dev_num_selected_scifi_t,
        dev_selected_scifi_offsets_t=downstream_find_hits.
        dev_selected_scifi_offsets_t,
        dev_selected_scifi_qop_t=downstream_find_hits.dev_selected_scifi_qop_t,
        dev_selected_scifi_chi2Y_t=downstream_find_hits.
        dev_selected_scifi_chi2Y_t,
        # Properties
        ghost_killer_threshold=ghost_killer_threshold)

    prefix_sum_downstream_tracks = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_downstream_tracks",
        dev_input_buffer_t=downstream_create_tracks.
        dev_num_downstream_tracks_t)

    downstream_copy_track_hit_number = make_algorithm(
        downstream_copy_hit_number_t,
        name="downstream_copy_track_hit_number",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_downstream_tracks_t=prefix_sum_downstream_tracks.
        host_total_sum_holder_t,
        dev_downstream_tracks_t=downstream_create_tracks.
        dev_downstream_tracks_t,
        dev_offsets_downstream_tracks_t=prefix_sum_downstream_tracks.
        dev_output_buffer_t)

    prefix_sum_downstream_copy_track_hit_number = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_downstream_copy_track_hit_number",
        dev_input_buffer_t=downstream_copy_track_hit_number.
        dev_downstream_track_hit_number_t)

    downstream_consolidate_tracks = make_algorithm(
        downstream_consolidate_t,
        name="downstream_consolidate_tracks",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_hits_in_downstream_tracks_t=
        prefix_sum_downstream_copy_track_hit_number.host_total_sum_holder_t,
        host_number_of_downstream_tracks_t=prefix_sum_downstream_tracks.
        host_total_sum_holder_t,
        dev_offsets_downstream_hit_numbers_t=
        prefix_sum_downstream_copy_track_hit_number.dev_output_buffer_t,
        dev_downstream_track_hit_number_t=downstream_copy_track_hit_number.
        dev_downstream_track_hit_number_t,
        dev_offsets_downstream_tracks_t=prefix_sum_downstream_tracks.
        dev_output_buffer_t,
        dev_downstream_tracks_t=downstream_create_tracks.
        dev_downstream_tracks_t,
        dev_ut_hits_t=ut_hits["dev_ut_hits"],
        dev_ut_hit_offsets_t=ut_hits["dev_ut_hit_offsets"],
        dev_scifi_tracks_view_t=scifi_seeds["dev_scifi_tracks_view"])

    downstream_make_particles = make_algorithm(
        downstream_make_particles_t,
        name="downstream_make_particles",
        # Basics
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        host_number_of_downstream_tracks_t=prefix_sum_downstream_tracks.
        host_total_sum_holder_t,
        # States
        dev_downstream_track_states_view_t=downstream_consolidate_tracks.
        dev_downstream_track_states_view_t,
        # Downstream consolidated tracks
        dev_offsets_downstream_tracks_t=prefix_sum_downstream_tracks.
        dev_output_buffer_t,
        dev_multi_event_downstream_tracks_view_t=downstream_consolidate_tracks.
        dev_multi_event_downstream_tracks_view_t)

    output_map = {
        #
        # Forward previous outputs
        #
        "decode_ut":
        decoded_ut,
        "scifi_seeds":
        scifi_seeds,
        "velo_scifi_matches":
        velo_scifi_matches,
        #
        # Downstream reconstruction output
        #
        "dev_downstream_tracks":
        downstream_create_tracks.dev_downstream_tracks_t,
        "dev_offsets_downstream_tracks":
        prefix_sum_downstream_tracks.dev_output_buffer_t,
        "host_number_of_downstream_tracks":
        prefix_sum_downstream_tracks.host_total_sum_holder_t,

        #
        # Downstream copy track hit number output
        #
        "dev_downstream_track_hit_number":
        downstream_copy_track_hit_number.dev_downstream_track_hit_number_t,
        "dev_offsets_downstream_hit_numbers":
        prefix_sum_downstream_copy_track_hit_number.dev_output_buffer_t,

        #
        # Downstream ut tracks
        #
        "dev_downstream_track_states":
        downstream_consolidate_tracks.dev_downstream_track_states_t,
        "dev_downstream_track_hits":
        downstream_consolidate_tracks.dev_downstream_track_hits_t,
        "dev_downstream_track_qops":
        downstream_consolidate_tracks.dev_downstream_track_qops_t,
        "dev_downstream_track_scifi_idx":
        downstream_consolidate_tracks.dev_downstream_track_scifi_idx_t,
        "dev_downstream_hits_view":
        downstream_consolidate_tracks.dev_downstream_hits_view_t,
        "dev_downstream_ut_track_view":
        downstream_consolidate_tracks.dev_downstream_ut_track_view_t,
        "dev_downstream_ut_tracks_view":
        downstream_consolidate_tracks.dev_downstream_ut_tracks_view_t,
        "dev_multi_event_downstream_ut_tracks_view":
        downstream_consolidate_tracks.
        dev_multi_event_downstream_ut_tracks_view_t,
        "dev_multi_event_downstream_ut_tracks_view_ptr":
        downstream_consolidate_tracks.
        dev_multi_event_downstream_ut_tracks_view_ptr_t,

        #
        #  Downstream tracks
        #
        "dev_downstream_track_states_view":
        downstream_consolidate_tracks.dev_downstream_track_states_view_t,
        "dev_downstream_track_view":
        downstream_consolidate_tracks.dev_downstream_track_view_t,
        "dev_downstream_tracks_view":
        downstream_consolidate_tracks.dev_downstream_tracks_view_t,
        "dev_multi_event_downstream_tracks_view":
        downstream_consolidate_tracks.dev_multi_event_downstream_tracks_view_t,
        "dev_multi_event_downstream_tracks_view_ptr":
        downstream_consolidate_tracks.
        dev_multi_event_downstream_tracks_view_ptr_t,

        #
        # Downstream track particles
        #
        "dev_downstream_track_particle_view":
        downstream_make_particles.dev_downstream_track_particle_view_t,
        "dev_downstream_track_particles_view":
        downstream_make_particles.dev_downstream_track_particles_view_t,
        "dev_multi_event_downstream_track_particles_view":
        downstream_make_particles.
        dev_multi_event_downstream_track_particles_view_t,
        "dev_multi_event_downstream_track_particles_view_ptr":
        downstream_make_particles.
        dev_multi_event_downstream_track_particles_view_ptr_t,
    }

    if ut_tracks is not None:
        output_map.update({"ut_tracks": ut_tracks})

    return output_map


def downstream_track_reconstruction():

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    velo_kalman_filter = run_velo_kalman_filter(velo_tracks)
    decoded_ut = decode_ut()
    # ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
    matched_tracks = make_velo_scifi_matches(velo_tracks, velo_kalman_filter,
                                             seeding_tracks)
    downstream_tracks = make_downstream(decoded_ut, seeding_tracks,
                                        matched_tracks
                                        # , ut_tracks=ut_tracks
                                        )

    return downstream_tracks["dev_downstream_track_particles_view"]
