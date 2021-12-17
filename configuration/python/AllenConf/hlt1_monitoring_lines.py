###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (beam_crossing_line_t, velo_micro_bias_line_t,
                                  odin_event_type_line_t, calo_digits_minADC_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenConf.odin import decode_odin
from AllenCore.generator import make_algorithm


def make_beam_line(pre_scaler_hash_string="beam_line_pre",
                   post_scaler_hash_string="beam_line_post",
                   beam_crossing_type="0"):
    name_map = {
        "0": "Hlt1NoBeam",
        "1": "Hlt1BeamOne",
        "2": "Hlt1BeamTwo",
        "3": "Hlt1BothBeams",
    }
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        beam_crossing_line_t,
        name=name_map[beam_crossing_type],
        beam_crossing_type=beam_crossing_type,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_velo_micro_bias_line(
        velo_tracks,
        pre_scaler_hash_string="velo_micro_bias_line_pre",
        post_scaler_hash_string="velo_micro_bias_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        velo_micro_bias_line_t,
        name="Hlt1VeloMicroBias",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_odin_event_type_line(
        pre_scaler_hash_string="odin_event_type_line_pre",
        post_scaler_hash_string="odin_event_type_line_post",
        odin_event_type="0x8"):
    name_map = {0x8: "Hlt1ODINLumi", 0x4: "Hlt1ODINNoBias"}
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()
    odin_event_type_int = int(odin_event_type, 0)

    return make_algorithm(
        odin_event_type_line_t,
        name=name_map[odin_event_type_int],
        odin_event_type=odin_event_type_int,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_calo_digits_minADC_line(
        decode_calo,
        pre_scaler_hash_string="calo_digits_minADC_line_pre",
        post_scaler_hash_string="calo_digits_minADC_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        calo_digits_minADC_t,
        name="Hlt1CaloDigitsMinADC",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_digits_t=decode_calo["host_ecal_number_of_digits"],
        dev_ecal_digits_t=decode_calo["dev_ecal_digits"],
        dev_ecal_digits_offsets_t=decode_calo["dev_ecal_digits_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)
