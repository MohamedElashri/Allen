###############################################################################
# (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.generator import generate, make_algorithm
from AllenConf.ut_reconstruction import decode_ut

from PyConf.control_flow import NodeLogic, CompositeNode


def make_ut_hit_caching_test(name):
    from AllenCore.algorithms import ut_hit_caching_test_t
    from AllenConf.utils import initialize_number_of_events

    number_of_events = initialize_number_of_events()

    ut_hits = decode_ut()

    return make_algorithm(
        ut_hit_caching_test_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ut_hits_t=ut_hits['dev_ut_hits'],
        dev_ut_hit_offsets_t=ut_hits['dev_ut_hit_offsets'],
        host_accumulated_number_of_ut_hits_t=ut_hits[
            'host_accumulated_number_of_ut_hits'],
    )


test_sequence = CompositeNode(
    "TestSequence",
    [make_ut_hit_caching_test(name='ut_hit_caching_test', )],
    NodeLogic.NONLAZY_AND,
    force_order=False,
)

generate(test_sequence)
