###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import (data_provider_t, rich_decoding_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def decode_rich():
    number_of_events = initialize_number_of_events()

    rich_banks = make_algorithm(
        data_provider_t, name=f"rich_banks", bank_type="Rich1")

    rich_decoding = make_algorithm(
        rich_decoding_t,
        name=f"rich_decoding",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=rich_banks.host_raw_bank_version_t,
        dev_rich_raw_input_t=rich_banks.dev_raw_banks_t,
        dev_rich_raw_input_offsets_t=rich_banks.dev_raw_offsets_t,
        dev_rich_raw_input_sizes_t=rich_banks.dev_raw_sizes_t,
        dev_rich_raw_input_types_t=rich_banks.dev_raw_types_t,
        block_dim_x=128)

    return {
        "dev_smart_ids": rich_decoding.dev_smart_ids_t,
        "dev_rich_hit_offsets": rich_decoding.dev_rich_hit_offsets_t
    }
