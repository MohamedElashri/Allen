###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

# See https://stackoverflow.com/questions/16981921/relative-imports-in-python-3
import sys
import os

PACKAGE_PARENT = ".."
SCRIPT_DIR = os.path.dirname(
    os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT)))

# import pytest
from collections import OrderedDict
from functools import lru_cache
from PyConf.components import Algorithm
from PyConf.control_flow import NodeLogic as Logic, CompositeNode
from PyConf import configurable
from AllenCore.cftree_ops import (
    gather_algs, get_ordered_trees, to_string, gather_leafs, parse_boolean,
    get_execution_list_for, get_best_order, merge_execution_masks,
    find_execution_masks_for_algorithms, avrg_efficiency,
    make_independent_of_algs, simplify, order_algs)
from AllenConf.algorithms import *


@lru_cache(1)
def sample_tree_0():
    # the conf variable is to fool the id check of the algorithm
    pre0 = Algorithm(decider_1_t, name="PRE0_st0", conf=2, average_eff=0.7)
    pre1 = Algorithm(decider_1_t, name="PRE1_st0", conf=1, average_eff=0.3)
    x = Algorithm(decider_1_t, name="X_st0", conf=3, average_eff=0.9)
    y = Algorithm(decider_1_t, name="Y_st0", conf=4, average_eff=0.8)

    line1 = CompositeNode(
        "L1_st0", [pre0, x], Logic.LAZY_AND, force_order=True)
    line2 = CompositeNode(
        "L2_st0", [pre1, y], Logic.LAZY_AND, force_order=True)
    top = CompositeNode(
        "root_st0", [line1, line2], Logic.LAZY_OR, force_order=False)
    return top, (pre0, pre1, x, y)


@lru_cache(1)
def sample_tree_1():
    pre0 = Algorithm(decider_1_t, name="PRE0_st1", conf=5, average_eff=0.7)
    pre1 = Algorithm(decider_1_t, name="PRE1_st1", conf=6, average_eff=0.6)
    x = Algorithm(decider_1_t, name="X_st1", conf=7, average_eff=.5)
    y = Algorithm(decider_1_t, name="Y_st1", conf=8, average_eff=.4)

    line1 = CompositeNode(
        "L1_st1", [pre0, x], Logic.LAZY_AND, force_order=True)
    line2 = CompositeNode(
        "L2_st1", [pre1, y], Logic.LAZY_AND, force_order=True)
    notline2 = CompositeNode("nL2_st1", [line2], Logic.NOT, force_order=True)
    top = CompositeNode(
        "root_st1", [line1, notline2], Logic.LAZY_OR, force_order=True)
    return top


@lru_cache(1)
def sample_tree_2():
    """
    In Moore (or rather the HltControlflowMgr), this would be an invalid tree
    to operate, because force_order there means that the order of evaluation
    of the children is hard. Because PRE2 appears in both pre02 and pre12,
    this would mean that PRE2 ultimately has to evaluate before PRE2, which
    is impossible.

    However, in this scheduler force_order is used to build control flow
    dependencies. A force_order = False in boom_st2 causes two trees to be
    evaluated, one with [pre02, pre12] and one with [pre12, pre02]. A score
    is calculated on both sequences that come out of these trees to see which
    one executes faster. Therefore, force_order here can rather be interpreted
    as "preferredOrder" of the topalgs involved in the ordering.
    """

    PRE0 = Algorithm(
        decider_1_t, name="PRE0_st2", average_eff=0.7, conf=9, weight=1)
    PRE1 = Algorithm(
        decider_1_t, name="PRE1_st2", average_eff=0.3, conf=10, weight=1)
    PRE2 = Algorithm(
        decider_1_t, name="PRE2_st2", average_eff=0.3, conf=11, weight=1)
    pre12 = CompositeNode(
        "pre12_st2", [PRE1, PRE2], Logic.LAZY_AND, force_order=True)
    pre02 = CompositeNode(
        "pre02_st2", [PRE0, PRE2], Logic.LAZY_AND, force_order=True)
    return CompositeNode(
        "boom_st2", [pre02, pre12], Logic.LAZY_OR,
        force_order=True), (PRE0, PRE1, PRE2)


@lru_cache(1)
def sample_tree_3():
    """ A sample tree with data dependencies. """

    p0 = Algorithm(producer_1_t, name="P0_st3", conf=0, average_eff=1)
    c0 = Algorithm(
        consumer_decider_1_t,
        name="C0_st3",
        b_t=p0.a_t,
        conf=0,
        average_eff=0.7)
    p1 = Algorithm(
        producer_1_t, name="P1_st3", conf=1, weight=2, average_eff=1)
    c1 = Algorithm(
        consumer_decider_1_t,
        name="C1_st3",
        b_t=p1.a_t,
        conf=1,
        average_eff=0.8)
    c2 = Algorithm(decider_1_t, name="C2_st3", conf=42, average_eff=1)
    c3 = Algorithm(
        consumer_decider_1_t,
        name="C3_st3",
        b_t=p1.a_t,
        conf=4,
        average_eff=0.5)

    line1 = CompositeNode("L1_st3", [c0, c1], Logic.LAZY_AND, force_order=True)
    line2 = CompositeNode("L2_st3", [c2, c3], Logic.LAZY_AND, force_order=True)
    top = CompositeNode(
        "root_st3", [line1, line2], Logic.LAZY_OR, force_order=False)
    return top, (p0, c0, p1, c1, c2, c3)


def test_gather_leafs():
    root, algs = sample_tree_0()
    assert gather_leafs(root) == set(algs)


def test_gather_algs():
    root, algs = sample_tree_0()
    assert gather_algs(root) == set(algs)

    root, algs = sample_tree_3()
    assert gather_algs(root) == set(algs)


def test_get_ordered_trees():
    root, _ = sample_tree_0()
    ord_trees = get_ordered_trees(root)
    assert len(ord_trees) == 2  # 2^the number of false orderings

    def child_names(node):
        return [child.name for child in node.children]

    assert all([
        a == b for a, b in zip(
            child_names(ord_trees[0]), reversed(child_names(ord_trees[1])))
    ])


def test_to_string():
    root = sample_tree_1()
    root = get_ordered_trees(root)[0]
    assert to_string(root) == "((PRE0_st1 & X_st1) | ~(PRE1_st1 & Y_st1))"


def test_parse_boolean():
    root = sample_tree_1()
    root = get_ordered_trees(root)[0]
    other_root = parse_boolean("((PRE0_st1 & X_st1) | ~(PRE1_st1 & Y_st1))")
    assert to_string(root) == to_string(other_root) and gather_leafs(
        root) == gather_leafs(other_root)


def test_find_execution_masks_for_algorithms():
    root, (p0, p1, dec0, dec1) = sample_tree_0()
    should_be_exec_masks = find_execution_masks_for_algorithms(root)
    assert should_be_exec_masks == [
        (p0, "True"),
        (dec0, "PRE0_st0"),
        (p1, "~PRE0_st0 | ~X_st0"),
        (dec1, "PRE1_st0 & (~PRE0_st0 | ~X_st0)"),
    ]

    root, (pre0, pre1, pre2) = sample_tree_2()
    should_be_exec_masks = find_execution_masks_for_algorithms(root)
    assert should_be_exec_masks == [
        (pre0, "True"),
        (pre2, "PRE0_st2"),
        (pre1, "~PRE0_st2 | ~PRE2_st2"),
        (pre2, "PRE1_st2 & (~PRE0_st2 | ~PRE2_st2)"),
    ]


def test_merge_execution_masks():
    masks = [("alg1", "true"), ("alg1", "false")]
    should_be_merged = merge_execution_masks(masks)
    merged = {"alg1": "true"}
    assert simplify(should_be_merged["alg1"]) == simplify(merged["alg1"])

    root, (pre0, pre1, pre2) = sample_tree_2()

    should_be_exec_masks = find_execution_masks_for_algorithms(root)
    should_be_exec_masks = merge_execution_masks(should_be_exec_masks)
    exec_masks = {
        pre0: "(True)",
        pre2: "(PRE0_st2) | (PRE1_st2 & (~PRE0_st2 | ~PRE2_st2))",
        pre1: "(~PRE0_st2 | ~PRE2_st2)",
    }

    assert exec_masks == should_be_exec_masks


def test_avrg_efficiency():
    root, _ = sample_tree_0()
    should_be_eff = avrg_efficiency(root)
    eff = 0.7188
    assert should_be_eff == eff

    root = sample_tree_1()
    should_be_eff = avrg_efficiency(root)
    eff = 0.844
    assert should_be_eff == eff


def test_make_independent_of_algs():
    root, (_, _, pre2) = sample_tree_2()

    should_be_ind = to_string(make_independent_of_algs(root, (pre2, )))
    ind = '(PRE0_st2 | PRE1_st2)'
    assert ind == should_be_ind


def test_order_algs():
    root, (pre0, pre1, dec0, dec1) = sample_tree_0()
    # dependencies : dict{alg: (cf_dependencies, df_dependencies, execution_condition)}
    dependencies = {
        pre0: (set(), set(), None),
        dec0: (set([pre0]), set(), parse_boolean("PRE0_st0")),
        pre1: (set([pre0, dec0]), set(),
               parse_boolean("(~PRE0_st0 | ~X_st0)")),
        dec1: (set([pre0, dec0, pre1]), set(),
               parse_boolean("PRE1_st0 & (~PRE0_st0 | ~X_st0)")),
    }
    should_be_order, _ = order_algs(dependencies)
    order = OrderedDict([(pre0, None), (dec0, parse_boolean("PRE0_st0")),
                         (pre1, parse_boolean("(~PRE0_st0 | ~X_st0)")),
                         (dec1,
                          parse_boolean("PRE1_st0 & (~PRE0_st0 | ~X_st0)"))])
    assert order == should_be_order

    root, (pre0, pre1, pre2) = sample_tree_2()
    # dependencies : dict{alg: (cf_dependencies, df_dependencies, execution_condition)}
    dependencies = {
        pre0: (set(), set(), None),
        pre1: (set([pre0, pre2]), set(),
               parse_boolean("(~PRE0_st2 | ~PRE2_st2)")),
        pre2:
        (set([pre1, pre0, pre2]), set(),
         parse_boolean(
             simplify("(PRE0_st2) | (PRE1_st2 & (~PRE0_st2 | ~PRE2_st2))"))),
    }
    should_be_order, _ = order_algs(dependencies)
    order = OrderedDict([(pre0, None), (pre1, None),
                         (pre2, parse_boolean("(PRE0_st2 | PRE1_st2)"))])
    assert order == should_be_order


def test_get_execution_list_for():
    root, (p0, c0, p1, c1, c2, c3) = sample_tree_3()

    should_be_order, _ = get_execution_list_for(root)
    order = ((p0, None), (c0, None), (p1, None), (c1, c0),
             (c2, parse_boolean("(~C0_st3 | ~C1_st3)")),
             (c3, parse_boolean("(~C0_st3 | ~C1_st3)")))
    # c2 not in execution condition, because c2.average_eff = 1

    assert order == should_be_order
