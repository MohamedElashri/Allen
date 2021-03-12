from PyConf.components import Algorithm
from AllenConf.event_list_utils import add_event_list_combiners, initialize_event_lists
from AllenConf.cftree_ops import get_execution_list_for, parse_boolean
from test_cftree_ops import sample_tree_3, sample_tree_0
from definitions.algorithms import event_list_union_t, event_list_inversion_t, event_list_intersection_t

def test_add_event_list_combiners():
    root, (p0, c0, p1, c1, c2, c3) = sample_tree_3()
    C0 = root.children[0].children[0]
    C1 = root.children[0].children[1]
    C2 = root.children[1].children[0]
    C3 = root.children[1].children[1]

    NOT_c0 = Algorithm(
                event_list_inversion_t,
                name="NOT_c0_st3",
                dev_event_list_input_t=c0.a_t,
             )
    NOT_c1 = Algorithm(
                event_list_inversion_t,
                name="NOT_c1_st3",
                dev_event_list_input_t=c1.a_t,
             )
    NOT_c0_OR_NOT_c1 = Algorithm(
                event_list_union_t,
                name="NOT_c0_st3_OR_NOT_c1_st3",
                dev_event_list_a_t=NOT_c0.dev_event_list_output_t,
                dev_event_list_b_t=NOT_c1.dev_event_list_output_t,
             )

    order, score = get_execution_list_for(root)
    should_be_algs = add_event_list_combiners(order)
    algs = [(initialize_event_lists(), None, None),
            (p0, None, None),
            (c0, None, C0),
            (p1, None, None),
            (c1, C0, C1),
            (NOT_c0, None, None),
            (NOT_c1, None, None),
            (NOT_c0_OR_NOT_c1, None, None),
            # (NOT_c0, None, parse_boolean("(~C0_st3 | ~C1_st3)")),
            # (NOT_c1, None, parse_boolean("(~C0_st3 | ~C1_st3)")),
            # (NOT_c0_OR_NOT_c1, None, parse_boolean("(~C0_st3 | ~C1_st3)")),
            (c2, parse_boolean("(~C0_st3 | ~C1_st3)"), C2),
            (c3, parse_boolean("(~C0_st3 | ~C1_st3)"), C3)]
    assert algs == should_be_algs

    root = sample_tree_0()
    PRE0 = root.children[0].children[0]
    PRE1 = root.children[1].children[0]
    DEC0 = root.children[0].children[1]
    DEC1 = root.children[1].children[1]
    pre0 = PRE0.top_alg
    pre1 = PRE1.top_alg
    dec0 = DEC0.top_alg
    dec1 = DEC1.top_alg

    NOT_pre0 = Algorithm(
                event_list_inversion_t,
                name="NOT_pre0_st0",
                dev_event_list_input_t=pre0.a_t,
             )

    NOT_dec0 = Algorithm(
                event_list_inversion_t,
                name="NOT_decider0_st0",
                dev_event_list_input_t=dec0.a_t,
             )

    NOT_pre0_OR_NOT_dec0 = Algorithm(
                event_list_union_t,
                name="NOT_pre0_st0_OR_NOT_decider0_st0",
                dev_event_list_a_t=NOT_pre0.dev_event_list_output_t,
                dev_event_list_b_t=NOT_dec0.dev_event_list_output_t,
             )
    pre1_AND_NOT_pre0_OR_NOT_dec0 = Algorithm(
                event_list_intersection_t,
                name="pre1_st0_AND_NOT_pre0_st0_OR_NOT_decider0_st0",
                dev_event_list_a_t=pre1.a_t,
                dev_event_list_b_t=NOT_pre0_OR_NOT_dec0.dev_event_list_output_t,
             )

    order, score = get_execution_list_for(root)
    should_be_algs = add_event_list_combiners(order)
    algs = [(initialize_event_lists(), None, None),
            (pre0, None, PRE0),
            (dec0, PRE0, DEC0),
            (NOT_pre0, None, None),
            (NOT_dec0, None, None),
            (NOT_pre0_OR_NOT_dec0, None, None),
            (pre1, parse_boolean("(~PRE0_st0 | ~X_st0)"), PRE1),
            (pre1_AND_NOT_pre0_OR_NOT_dec0, None, None),
            (dec1, parse_boolean("(PRE1_st0 & (~PRE0_st0 | ~X_st0))"), DEC1)]
    assert algs == should_be_algs
