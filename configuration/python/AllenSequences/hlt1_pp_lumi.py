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
from AllenCore.algorithms import host_dummy_odin_provider_t
from AllenConf.utils import initialize_number_of_events
from AllenConf.odin import decode_odin
from AllenCore.generator import make_algorithm
import AllenConf


def decode_dummy_odin(lumi_fraction=[0.5, 0.5, 0.5, 0.5]):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    dummy_odin_banks = make_algorithm(
        host_dummy_odin_provider_t,
        name="dummy_odin_lumi_throughput",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_odin_data_t=odin["host_odin_data"],
        lumi_frac=lumi_fraction)

    return {
        "dev_odin_data": dummy_odin_banks.dev_odin_dummy_t,
        "host_odin_data": dummy_odin_banks.host_odin_dummy_t,
        "host_odin_version": odin["host_odin_version"],
        "host_event_list": odin["host_event_list"],
        "dev_event_mask": odin["dev_event_mask"]
    }


AllenConf.odin.decode_odin = decode_dummy_odin

import AllenConf.HLT1
from AllenCore.generator import generate

hlt1_node = AllenConf.HLT1.setup_hlt1_node()
generate(hlt1_node)
