###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.algorithms import *
from definitions.event_list_utils import make_algorithm


def decode_odin():
    odin_banks = make_algorithm(
        data_provider_t, name="populate_odin_banks", bank_type="ODIN")

    return {
        "dev_odin_raw_input": odin_banks.dev_raw_banks_t,
        "dev_odin_raw_input_offsets": odin_banks.dev_raw_offsets_t,
    }
