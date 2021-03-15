###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from PyConf.components import Algorithm
from AllenConf.event_list_utils import add_event_list_combiners, initialize_event_lists
from AllenConf.cftree_ops import get_execution_list_for, parse_boolean
from test_cftree_ops import sample_tree_3, sample_tree_0
from definitions.algorithms import event_list_union_t, event_list_inversion_t, event_list_intersection_t

def test_add_event_list_combiners():
    root, (p0, c0, p1, c1, c2, c3) = sample_tree_3()
    NOT_c0 = Algorithm(
                event_list_inversion_t,
                name="NOT_C0_st3",
                dev_event_list_input_t=c0.a_t,
             )
    NOT_c1 = Algorithm(
                event_list_inversion_t,
                name="NOT_C1_st3",
                dev_event_list_input_t=c1.a_t,
             )
    NOT_c0_OR_NOT_c1 = Algorithm(
                event_list_union_t,
                name="NOT_C0_st3_OR_NOT_C1_st3",
                dev_event_list_a_t=NOT_c0.dev_event_list_output_t,
                dev_event_list_b_t=NOT_c1.dev_event_list_output_t,
             )

    order, score = get_execution_list_for(root)
    should_be_algs = add_event_list_combiners(order)
    algs = ((initialize_event_lists(), None),
            (p0, None),
            (c0, None),
            (p1, None),
            (c1, c0),
            (NOT_c0, None),
            (NOT_c1, None),
            (NOT_c0_OR_NOT_c1, None),
            # (NOT_c0, None, parse_boolean("(~C0_st3 | ~C1_st3)")),
            # (NOT_c1, None, parse_boolean("(~C0_st3 | ~C1_st3)")),
            # (NOT_c0_OR_NOT_c1, None, parse_boolean("(~C0_st3 | ~C1_st3)")),
            (c2, parse_boolean("(~C0_st3 | ~C1_st3)")),
            (c3, parse_boolean("(~C0_st3 | ~C1_st3)")))
    assert algs == should_be_algs

    root, (pre0, pre1, dec0, dec1) = sample_tree_0()

    NOT_pre0 = Algorithm(
                event_list_inversion_t,
                name="NOT_PRE0_st0",
                dev_event_list_input_t=pre0.a_t,
             )

    NOT_dec0 = Algorithm(
                event_list_inversion_t,
                name="NOT_X_st0",
                dev_event_list_input_t=dec0.a_t,
             )

    NOT_pre0_OR_NOT_dec0 = Algorithm(
                event_list_union_t,
                name="NOT_PRE0_st0_OR_NOT_X_st0",
                dev_event_list_a_t=NOT_pre0.dev_event_list_output_t,
                dev_event_list_b_t=NOT_dec0.dev_event_list_output_t,
             )
    pre1_AND_NOT_pre0_OR_NOT_dec0 = Algorithm(
                event_list_intersection_t,
                name="PRE1_st0_AND_NOT_PRE0_st0_OR_NOT_X_st0",
                dev_event_list_a_t=pre1.a_t,
                dev_event_list_b_t=NOT_pre0_OR_NOT_dec0.dev_event_list_output_t,
             )

    order, score = get_execution_list_for(root)
    should_be_algs = add_event_list_combiners(order)
    algs = ((initialize_event_lists(), None),
            (pre0, None),
            (dec0, pre0),
            (NOT_pre0, None),
            (NOT_dec0, None),
            (NOT_pre0_OR_NOT_dec0, None),
            (pre1, parse_boolean("(~PRE0_st0 | ~X_st0)")),
            (pre1_AND_NOT_pre0_OR_NOT_dec0, None),
            (dec1, parse_boolean("(PRE1_st0 & (~PRE0_st0 | ~X_st0))")))
    assert algs == should_be_algs
