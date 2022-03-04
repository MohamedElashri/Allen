###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import odin_provider_t, odin_beamcrossingtype_t
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
    }


@configurable
def make_bxtype(name="BunchCrossing_Type", bx_type=3):
    return ODIN_BeamXtype(name=name, bxtype=bx_type)


def ODIN_BeamXtype(name='ODIN_BeamXType', bxtype=3):

    number_of_events = initialize_number_of_events()
    layout = mep_layout()
    odin = decode_odin()

    return make_algorithm(
        odin_beamcrossingtype_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        beam_crossing_type=bxtype)
