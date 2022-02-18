###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (d2kpi_line_t, passthrough_line_t,
                                  rich_1_line_t, rich_2_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenConf.odin import decode_odin


def make_d2kpi_line(forward_tracks,
                    secondary_vertices,
                    pre_scaler_hash_string="d2kpi_line_pre",
                    post_scaler_hash_string="d2kpi_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        d2kpi_line_t,
        name="Hlt1D2KPi",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices["dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_passthrough_line(pre_scaler_hash_string="passthrough_line_pre",
                          post_scaler_hash_string="passthrough_line_post",
                          name="Hlt1Passthrough"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        passthrough_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_rich_line(line_type, reconstructed_objects, pre_scaler_hash_string,
                   post_scaler_hash_string, name):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    forward_tracks = reconstructed_objects["forward_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]

    return make_algorithm(
        line_type,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles["dev_multi_event_basic_particles"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_rich_1_line(reconstructed_objects,
                     pre_scaler_hash_string="rich_1_line_pre",
                     post_scaler_hash_string="rich_1_line_post",
                     name="Hlt1RICH1Alignment"):
    return make_rich_line(rich_1_line_t, reconstructed_objects,
                          pre_scaler_hash_string, post_scaler_hash_string,
                          name)


def make_rich_2_line(reconstructed_objects,
                     pre_scaler_hash_string="rich_2_line_pre",
                     post_scaler_hash_string="rich_2_line_post",
                     name="Hlt1RICH2Alignment"):
    return make_rich_line(rich_2_line_t, reconstructed_objects,
                          pre_scaler_hash_string, post_scaler_hash_string,
                          name)
