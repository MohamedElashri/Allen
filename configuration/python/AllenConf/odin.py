###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import odin_provider_t, odin_beamcrossingtype_t, host_odin_error_filter_t
from AllenCore.generator import make_algorithm
from AllenConf.utils import mep_layout, initialize_number_of_events
from PyConf.tonic import configurable


def decode_odin():
    odin_banks = make_algorithm(
        odin_provider_t,
        name="populate_odin_banks",
        host_number_of_events_t=initialize_number_of_events()
        ['host_number_of_events'],
        host_mep_layout_t=mep_layout()['host_mep_layout'])

    return {
        "dev_odin_data": odin_banks.dev_odin_data_t,
        "host_odin_data": odin_banks.host_odin_data_t,
        "host_odin_version": odin_banks.host_raw_bank_version_t,
        "dev_event_mask": odin_banks.dev_event_mask_t
    }


@configurable
def make_bxtype(name="BunchCrossing_Type", bx_type=3, invert=False):
    return ODIN_BeamXtype(name=name, bxtype=bx_type, invert=invert)


def ODIN_BeamXtype(name='ODIN_BeamXType', bxtype=3, invert=False):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        odin_beamcrossingtype_t,
        name=name,
        invert=invert,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin['dev_odin_data'],
        beam_crossing_type=bxtype)


def odin_error_filter(name="odin_error_filter"):
    odin_error_filter = make_algorithm(
        host_odin_error_filter_t,
        name="odin_error_filter",
        dev_event_mask_t=decode_odin()["dev_event_mask"])
    return odin_error_filter
