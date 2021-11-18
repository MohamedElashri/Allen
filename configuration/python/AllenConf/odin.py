###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import odin_provider_t
from AllenCore.generator import make_algorithm
from AllenConf.utils import mep_layout, initialize_number_of_events


def decode_odin():
    odin_banks = make_algorithm(
        odin_provider_t,
        name="populate_odin_banks",
        host_number_of_events_t=initialize_number_of_events()
        ['host_number_of_events'],
        host_mep_layout_t=mep_layout()['host_mep_layout'])

    return {
        "dev_odin_raw_input": odin_banks.dev_raw_banks_t,
        "dev_odin_raw_input_offsets": odin_banks.dev_raw_offsets_t,
        "host_odin_raw_input": odin_banks.host_raw_banks_t,
        "host_odin_raw_input_offsets": odin_banks.host_raw_offsets_t,
        "host_odin_version": odin_banks.host_raw_bank_version_t,
    }
