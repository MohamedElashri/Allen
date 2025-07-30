###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import data_provider_t, plume_decode_t
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def decode_plume():
    number_of_events = initialize_number_of_events()
    Plume_banks = make_algorithm(
        data_provider_t, name="Plume_banks", bank_type="Plume")

    plume_decode = make_algorithm(
        plume_decode_t,
        name="plume_decode",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=Plume_banks.host_raw_bank_version_t,
        dev_plume_raw_input_t=Plume_banks.dev_raw_banks_t,
        dev_plume_raw_input_offsets_t=Plume_banks.dev_raw_offsets_t,
        dev_plume_raw_input_sizes_t=Plume_banks.dev_raw_sizes_t,
        dev_plume_raw_input_types_t=Plume_banks.dev_raw_types_t)

    return {
        "plume_algo": plume_decode,
        "dev_plume": plume_decode.dev_plume_t,
    }
