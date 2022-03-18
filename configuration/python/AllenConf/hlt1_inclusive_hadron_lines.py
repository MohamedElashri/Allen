###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (
    kstopipi_line_t, track_mva_line_t, two_track_mva_line_t,
    two_track_mva_evaluator_t, two_track_line_ks_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_kstopipi_line(forward_tracks,
                       secondary_vertices,
                       pre_scaler_hash_string="kstopipi_line_pre",
                       post_scaler_hash_string="kstopipi_line_post",
                       name="Hlt1KsToPiPi"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        kstopipi_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_svs_t=secondary_vertices["dev_two_track_particles"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_track_mva_line(forward_tracks,
                        kalman_velo_only,
                        pre_scaler_hash_string="track_mva_line_pre",
                        post_scaler_hash_string="track_mva_line_post",
                        name="Hlt1TrackMVA"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        track_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_tracks_t=kalman_velo_only["dev_long_track_particles"],
        dev_track_offsets_t=forward_tracks["dev_offsets_forward_tracks"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_two_track_mva_line(forward_tracks,
                            secondary_vertices,
                            pre_scaler_hash_string="two_track_mva_line_pre",
                            post_scaler_hash_string="two_track_mva_line_post",
                            name="Hlt1TwoTrackMVA"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    two_track_mva_evaluator = make_algorithm(
        two_track_mva_evaluator_t,
        name="two_track_mva_evaluator",
        dev_consolidated_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"])

    return make_algorithm(
        two_track_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_svs_t=secondary_vertices["dev_two_track_particles"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        dev_two_track_mva_evaluation_t=two_track_mva_evaluator.
        dev_two_track_mva_evaluation_t)


def make_two_track_line_ks(forward_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string="two_track_line_ks_pre",
                           post_scaler_hash_string="two_track_line_ks_post",
                           name="Hlt1TwoTrackKs"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        two_track_line_ks_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_svs_t=secondary_vertices["dev_two_track_particles"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)
