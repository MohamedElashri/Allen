###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.algorithms import *
from definitions.odin import decode_odin
from definitions.utils import initialize_number_of_events, mep_layout
from AllenConf.event_list_utils import make_algorithm


def make_gather_selections(lines):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        gather_selections_t,
        name="gather_selections",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        dev_input_selections_t=[line.dev_decisions_t for line in lines],
        dev_input_selections_offsets_t=[
            line.dev_decisions_offsets_t for line in lines
        ],
        host_input_post_scale_factors_t=[
            line.host_post_scaler_t for line in lines
        ],
        host_input_post_scale_hashes_t=[
            line.host_post_scaler_hash_t for line in lines
        ],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        names_of_active_lines=",".join([line.name for line in lines]))


def make_dec_reporter(lines):
    gather_selections = make_gather_selections(lines)
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        dec_reporter_t,
        name="dec_reporter",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_active_lines_t=gather_selections.
        host_number_of_active_lines_t,
        dev_number_of_active_lines_t=gather_selections.
        dev_number_of_active_lines_t,
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t)
