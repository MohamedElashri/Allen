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
                       pre_scaler_hash_string=None,
                       post_scaler_hash_string=None,
                       name="Hlt1KsToPiPi"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        kstopipi_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_track_mva_line(forward_tracks,
                        long_track_particles,
                        pre_scaler_hash_string=None, 
                        post_scaler_hash_string=None,
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
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_two_track_mva_line(forward_tracks,
                            secondary_vertices,
                            pre_scaler_hash_string=None, 
                            post_scaler_hash_string=None, 
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
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_two_track_mva_evaluation_t=two_track_mva_evaluator.
        dev_two_track_mva_evaluation_t)


def make_two_track_line_ks(forward_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           name="Hlt1TwoTrackKs"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        two_track_line_ks_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_two_track_catboost_line(
        forward_tracks,
        secondary_vertices,
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        name="Hlt1TwoTrackCatBoost"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    ut_tracks = forward_tracks["veloUT_tracks"]
    velo_tracks = ut_tracks["velo_tracks"]

    two_track_preprocess = make_algorithm(
        two_track_preprocess_t,
        name="two_track_preprocess",
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_consolidated_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"])

    two_track_evaluator = make_algorithm(
        two_track_evaluator_t,
        name="two_track_evaluator",
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_two_track_catboost_preprocess_output_t=two_track_preprocess.
        dev_two_track_preprocess_output_t)

    return make_algorithm(
        two_track_catboost_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_two_track_evaluation_t=two_track_evaluator.
        dev_two_track_catboost_evaluation_t,
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
>>>>>>> 0f64828a6 (Restore SMOG2 lines functionality)
>>>>>>> 2bd044db6 (Restore SMOG2 lines functionality)
