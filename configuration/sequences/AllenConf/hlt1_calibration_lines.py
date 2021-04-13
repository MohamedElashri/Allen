###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (d2kpi_line_t, passthrough_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.event_list_utils import make_algorithm
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
        dev_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
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
