###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    beam_crossing_line_t, velo_micro_bias_line_t, odin_event_type_line_t,
    odin_event_and_orbit_line_t, calo_digits_minADC_t, beam_gas_line_t,
    velo_clusters_micro_bias_line_t, n_displaced_velo_track_line_t,
    n_materialvertex_seed_line_t)
from AllenConf.utils import initialize_number_of_events
from AllenConf.odin import decode_odin
from AllenCore.generator import make_algorithm


def make_beam_line(pre_scaler_hash_string=None,
                   post_scaler_hash_string=None,
                   pre_scaler=1.,
                   post_scaler=1.e-3,
                   beam_crossing_type=0,
                   name=None):
    name_map = {
        0: "Hlt1NoBeam",
        1: "Hlt1BeamOne",
        2: "Hlt1BeamTwo",
        3: "Hlt1BothBeams",
    }
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    line_name = name or name_map[beam_crossing_type]

    return make_algorithm(
        beam_crossing_line_t,
        name=line_name,
        beam_crossing_type=beam_crossing_type,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or line_name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or line_name + "_post",
        dev_odin_data_t=odin["dev_odin_data"])


def make_velo_micro_bias_line(velo_tracks,
                              name="Hlt1VeloMicroBias",
                              pre_scaler=1.,
                              post_scaler=1.e-4,
                              pre_scaler_hash_string=None,
                              post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        velo_micro_bias_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_odin_event_type_line(odin_event_type: str,
                              name=None,
                              pre_scaler=1.,
                              post_scaler=1.,
                              pre_scaler_hash_string=None,
                              post_scaler_hash_string=None):
    type_map = {
        "VeloOpen": 0x0001,
        "Physics": 0x0002,
        "NoBias": 0x0004,
        "Lumi": 0x0008,
        "Beam1Gas": 0x0010,
        "Beam2Gas": 0x0020
    }

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    line_name = name or 'Hlt1ODIN' + odin_event_type
    return make_algorithm(
        odin_event_type_line_t,
        name=line_name,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        dev_odin_data_t=odin["dev_odin_data"],
        odin_event_type=type_map[odin_event_type],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or line_name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or line_name + "_post")


def make_odin_event_and_orbit_line(odin_event_type: str,
                                   odin_orbit_modulo,
                                   odin_orbit_remainder,
                                   name=None,
                                   pre_scaler=1.,
                                   post_scaler=1.,
                                   pre_scaler_hash_string=None,
                                   post_scaler_hash_string=None):
    type_map = {
        "VeloOpen": 0x0001,
        "Physics": 0x0002,
        "NoBias": 0x0004,
        "Lumi": 0x0008,
        "Beam1Gas": 0x0010,
        "Beam2Gas": 0x0020
    }

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    line_name = name or 'Hlt1ODINEventAndOrbit' + odin_event_type
    return make_algorithm(
        odin_event_and_orbit_line_t,
        name=line_name,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        dev_odin_data_t=odin["dev_odin_data"],
        odin_event_type=type_map[odin_event_type],
        odin_orbit_modulo=odin_orbit_modulo,
        odin_orbit_remainder=odin_orbit_remainder,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or line_name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or line_name + "_post")


def make_calo_digits_minADC_line(decode_calo,
                                 name="Hlt1CaloDigitsMinADC",
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 minADC=100):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        calo_digits_minADC_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_digits_t=decode_calo["host_ecal_number_of_digits"],
        dev_ecal_digits_t=decode_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decode_calo["dev_ecal_digits_offsets"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minADC=minADC)


def make_beam_gas_line(velo_tracks,
                       velo_states,
                       name="Hlt1BeamGas",
                       pre_scaler_hash_string=None,
                       post_scaler_hash_string=None,
                       beam_crossing_type=1):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        beam_gas_line_t,
        name=name,
        beam_crossing_type=beam_crossing_type,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_odin_data_t=odin["dev_odin_data"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_velo_clusters_micro_bias_line(decoded_velo,
                                       name="Hlt1VeloClustersMicroBias",
                                       pre_scaler=1.,
                                       post_scaler=1.,
                                       pre_scaler_hash_string=None,
                                       post_scaler_hash_string=None,
                                       min_velo_clusters=1):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        velo_clusters_micro_bias_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_estimated_input_size_t=decoded_velo[
            "dev_offsets_estimated_input_size"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        min_velo_clusters=min_velo_clusters)


def make_n_displaced_velo_line(filtered_velo_tracks,
                               n_tracks=6,
                               name="Hlt1NVELODisplacedTrack",
                               pre_scaler_hash_string=None,
                               post_scaler_hash_string=None,
                               pre_scaler=1.,
                               post_scaler=1.):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        n_displaced_velo_track_line_t,
        name=name,
        dev_number_of_filtered_tracks_t=filtered_velo_tracks[
            "dev_number_of_filtered_velo_tracks"],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        min_filtered_velo_tracks=n_tracks)


def make_n_materialvertex_seed_line(filtered_velo_tracks,
                                    name="Hlt1NMaterialVertexSeeds",
                                    n_seeds=2,
                                    pre_scaler=1.,
                                    post_scaler=1.,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        n_materialvertex_seed_line_t,
        name=name,
        dev_number_of_materialvertex_seeds_t=filtered_velo_tracks[
            "dev_number_of_close_track_pairs"],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        min_materialvertex_seeds=n_seeds,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
