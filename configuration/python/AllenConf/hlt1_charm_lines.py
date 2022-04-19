###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (d2kk_line_t, d2pipi_line_t, two_ks_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_d2kk_line(forward_tracks,
                   secondary_vertices,
                   pre_scaler_hash_string="d2kk_line_pre",
                   post_scaler_hash_string="d2kk_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        d2kk_line_t,
        name="Hlt1D2KK",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_d2pipi_line(forward_tracks,
                     secondary_vertices,
                     pre_scaler_hash_string="d2pipi_line_pre",
                     post_scaler_hash_string="d2pipi_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        d2pipi_line_t,
        name="Hlt1D2PiPi",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_two_ks_line(forward_tracks,
                     secondary_vertices,
                     pre_scaler_hash_string="two_ks_line_pre",
                     post_scaler_hash_string="two_ks_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        two_ks_line_t,
        name="Hlt1TwoKs",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)
