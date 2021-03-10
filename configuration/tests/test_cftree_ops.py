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
from PyConf.control_flow import Leaf, NodeLogic as Logic, CompositeNode
from PyConf import configurable
from AllenConf.cftree_ops import (
    gather_algs,
    get_ordered_trees,
    to_string,
    gather_leafs,
    parse_boolean,
    get_execution_list_for,
    get_best_order,
    merge_execution_masks,
    find_execution_masks_for_algorithms,
    avrg_efficiency,
    make_independent_of_algs,
    simplify,
    order_algs
)
from definitions.algorithms import *


@lru_cache(1)
def sample_tree_0():
    pre0 = Algorithm(decider_1_t, name="pre0_st0", conf=2)
    pre1 = Algorithm(decider_1_t, name="pre1_st0", conf=1)
    x = Algorithm(decider_1_t, name="decider0_st0", conf=3)
    y = Algorithm(decider_1_t, name="decider1_st0", conf=4)

    PRE0 = Leaf("PRE0_st0", 1, 0.7, alg=pre0)
    PRE1 = Leaf("PRE1_st0", 2, 0.3, alg=pre1)
    X = Leaf("X_st0", 3, 1, alg=x)
    Y = Leaf("Y_st0", 4, 1, alg=y)

    line1 = CompositeNode("L1_st0", [PRE0, X], Logic.LAZY_AND, forceOrder=True)
    line2 = CompositeNode("L2_st0", [PRE1, Y], Logic.LAZY_AND, forceOrder=True)
    top = CompositeNode("root_st0", [line1, line2], Logic.LAZY_OR, forceOrder=False)
    return top


@lru_cache(1)
def sample_tree_1():
    PRE0 = Leaf("PRE0_st1", 1, 0.7, alg=None)
    PRE1 = Leaf("PRE1_st1", 2, 0.6, alg=None)
    X = Leaf("X_st1", 3, 0.5, alg=None)
    Y = Leaf("Y_st1", 5, 0.4, alg=None)

    line1 = CompositeNode("L1_st1", [PRE0, X], Logic.LAZY_AND, forceOrder=True)
    line2 = CompositeNode("L2_st1", [PRE1, Y], Logic.LAZY_AND, forceOrder=True)
    notline2 = CompositeNode("nL2_st1", [line2], Logic.NOT, forceOrder=True)
    top = CompositeNode(
        "root_st1", [line1, notline2], Logic.LAZY_OR, forceOrder=True)
    return top


@lru_cache(1)
def sample_tree_2():
    """
    In Moore (or rather the HltControlflowMgr), this would be an invalid tree
    to operate, because forceOrder there means that the order of evaluation
    of the children is hard. Because PRE2 appears in both pre02 and pre12,
    this would mean that PRE2 ultimately has to evaluate before PRE2, which
    is impossible.

    However, in this scheduler forceOrder is used to build control flow
    dependencies. A forceOrder = False in boom_st2 causes two trees to be
    evaluated, one with [pre02, pre12] and one with [pre12, pre02]. A score
    is calculated on both sequences that come out of these trees to see which
    one executes faster. Therefore, forceOrder here can rather be interpreted
    as "preferredOrder" of the topalgs involved in the ordering.
    """

    pre0 = Algorithm(decider_1_t, name="pre0_st2", conf=5, weight=1)
    pre1 = Algorithm(decider_1_t, name="pre1_st2", conf=6, weight=1)
    pre2 = Algorithm(decider_1_t, name="pre2_st2", conf=7, weight=1)
    PRE0 = Leaf("PRE0_st2", 1, 0.7, alg=pre0)
    PRE1 = Leaf("PRE1_st2", 1, 0.3, alg=pre1)
    PRE2 = Leaf("PRE2_st2", 2, 0.3, alg=pre2)
    pre12 = CompositeNode(
        "pre12_st2", [PRE1, PRE2], Logic.LAZY_AND, forceOrder=True)
    pre02 = CompositeNode(
        "pre02_st2", [PRE0, PRE2], Logic.LAZY_AND, forceOrder=True)
    return CompositeNode(
        "boom_st2", [pre02, pre12], Logic.LAZY_OR, forceOrder=True)

@lru_cache(1)
def sample_tree_3():
    """ A sample tree with data dependencies. """

    p0 = Algorithm(producer_1_t, name="p0_st3", conf=0)
    c0 = Algorithm(consumer_decider_1_t, name="c0_st3", b_t = p0.a_t, conf=0)
    p1 = Algorithm(producer_1_t, name="p1_st3", conf=1, weight=2)
    c1 = Algorithm(consumer_decider_1_t, name="c1_st3", b_t = p1.a_t, conf=1)
    c2 = Algorithm(decider_1_t, name="c2_st3", conf=8)
    c3 = Algorithm(consumer_decider_1_t, name="c3_st3", b_t = p1.a_t, conf=4)

    C0 = Leaf("C0_st3", 1, 0.7, alg=c0)
    C1 = Leaf("C1_st3", 1, 0.8, alg=c1)
    C2 = Leaf("C2_st3", 1, 1, alg=c2)
    C3 = Leaf("C3_st3", 1, 0.5, alg=c3)

    line1 = CompositeNode("L1_st3", [C0, C1], Logic.LAZY_AND, forceOrder=True)
    line2 = CompositeNode("L2_st3", [C2, C3], Logic.LAZY_AND, forceOrder=True)
    top = CompositeNode("root_st3", [line1, line2], Logic.LAZY_OR, forceOrder=False)
    return top, (p0, c0, p1, c1, c2, c3)


def test_gather_leafs():
    root = sample_tree_0()
    leafs = set((
        Leaf.leafs["PRE0_st0"],
        Leaf.leafs["PRE1_st0"],
        Leaf.leafs["X_st0"],
        Leaf.leafs["Y_st0"],
    ))
    assert gather_leafs(root) == leafs


def test_gather_algs():
    root = sample_tree_0()
    algs = [leaf.top_alg for leaf in root.children[0].children]
    algs += [leaf.top_alg for leaf in root.children[1].children]
    assert gather_algs(root) == set(algs)


def test_get_ordered_trees():
    root = sample_tree_0()
    ord_trees = get_ordered_trees(root)
    assert len(ord_trees) == 2  # 2^the number of false orderings

    def child_names(node):
        return [child.name for child in node.children]


    assert all(
        [
            a == b for a,b in
            zip(child_names(ord_trees[0]), reversed(child_names(ord_trees[1])))
        ])


def test_to_string():
    root = sample_tree_1()
    root = get_ordered_trees(root)[0]
    assert to_string(root) == "((PRE0_st1 & X_st1) | ~(PRE1_st1 & Y_st1))"


def test_parse_boolean():
    root = sample_tree_1()
    root = get_ordered_trees(root)[0]
    other_root = parse_boolean("((PRE0_st1 & X_st1) | ~(PRE1_st1 & Y_st1))")
    assert to_string(root) == to_string(other_root) and gather_leafs(root) == gather_leafs(other_root)


def test_find_execution_masks_for_algorithms():
    root = sample_tree_0()
    exec_masks = find_execution_masks_for_algorithms(root)
    pre0_st0 = root.children[0].children[0].top_alg
    pre1_st0 = root.children[1].children[0].top_alg
    dec0_st0 = root.children[0].children[1].top_alg
    dec1_st0 = root.children[1].children[1].top_alg
    assert exec_masks == [
        (pre0_st0, "True"),
        (dec0_st0, "PRE0_st0"),
        (pre1_st0, "~PRE0_st0"),
        (dec1_st0, "PRE1_st0 & ~PRE0_st0"),
    ]

    root = sample_tree_2()
    pre0_st2 = root.children[0].children[0].top_alg
    pre1_st2 = root.children[1].children[0].top_alg
    pre2_st2 = root.children[0].children[1].top_alg
    exec_masks = find_execution_masks_for_algorithms(root)
    should_be_exec_masks = [
        (pre0_st2, "True"),
        (pre2_st2, "PRE0_st2"),
        (pre1_st2, "~PRE0_st2 | ~PRE2_st2"),
        (pre2_st2, "PRE1_st2 & (~PRE0_st2 | ~PRE2_st2)"),
    ]
    assert exec_masks == should_be_exec_masks


def test_merge_execution_masks():
    masks = [("alg1", "true"), ("alg1", "false")]
    should_be_merged = merge_execution_masks(masks)
    merged = {"alg1": "true"}
    assert simplify(should_be_merged["alg1"]) == simplify(merged["alg1"])

    root = sample_tree_2()
    pre0_st2 = root.children[0].children[0].top_alg
    pre1_st2 = root.children[1].children[0].top_alg
    pre2_st2 = root.children[0].children[1].top_alg
    should_be_exec_masks = find_execution_masks_for_algorithms(root)
    should_be_exec_masks = merge_execution_masks(should_be_exec_masks)
    exec_masks = {
        pre0_st2: "(True)",
        pre2_st2: "(PRE0_st2) | (PRE1_st2 & (~PRE0_st2 | ~PRE2_st2))",
        pre1_st2: "(~PRE0_st2 | ~PRE2_st2)",
    }

    assert exec_masks == should_be_exec_masks


def test_avrg_efficiency():
    root = sample_tree_0()
    should_be_eff = avrg_efficiency(root)
    eff = 0.79
    assert should_be_eff == eff

    root = sample_tree_1()
    should_be_eff = avrg_efficiency(root)
    eff = 0.844
    assert should_be_eff == eff


def test_make_independent_of_algs():
    root = sample_tree_2()
    pre0_st2 = root.children[0].children[0].top_alg
    pre1_st2 = root.children[1].children[0].top_alg
    pre2_st2 = root.children[0].children[1].top_alg
    should_be_ind = to_string(make_independent_of_algs(root, (pre2_st2, )))
    ind = '(PRE0_st2 | PRE1_st2)'
    assert ind == should_be_ind

def test_order_algs():
    root = sample_tree_0()
    pre0 = root.children[0].children[0].top_alg
    pre1 = root.children[1].children[0].top_alg
    dec0 = root.children[0].children[1].top_alg
    dec1 = root.children[1].children[1].top_alg
    # dependencies : dict{alg: (cf_dependencies, df_dependencies, execution_condition)}
    dependencies = {
        pre0 : (set(), set(), None),
        dec0 : (set([pre0]), set(), parse_boolean("PRE0_st0")),
        pre1 : (set([pre0, dec0]), set(), parse_boolean("(~PRE0_st0 | ~X_st0)")),
        dec1 : (set([pre0, dec0, pre1]), set(),
                        parse_boolean("PRE1_st0 & (~PRE0_st0 | ~X_st0)")),
    }
    should_be_order, _ = order_algs(dependencies)
    order = OrderedDict([(pre0, None),
             (dec0, parse_boolean("PRE0_st0")),
             (pre1, parse_boolean("(~PRE0_st0 | ~X_st0)")),
             (dec1, parse_boolean("PRE1_st0 & (~PRE0_st0 | ~X_st0)"))])
    assert order == should_be_order

    root = sample_tree_2()
    pre0 = root.children[0].children[0].top_alg
    pre1 = root.children[1].children[0].top_alg
    pre2 = root.children[0].children[1].top_alg
    # dependencies : dict{alg: (cf_dependencies, df_dependencies, execution_condition)}
    dependencies = {
        pre0 : (set(), set(), None),
        pre1 : (set([pre0, pre2]), set(), parse_boolean("(~PRE0_st2 | ~PRE2_st2)")),
        pre2 : (set([pre1, pre0, pre2]),
                        set(),
                        parse_boolean(simplify("(PRE0_st2) | (PRE1_st2 & (~PRE0_st2 | ~PRE2_st2))"))),
    }
    should_be_order, _ = order_algs(dependencies)
    order = OrderedDict([(pre0, None),
             (pre1, None),
             (pre2, parse_boolean("(PRE0_st2 | PRE1_st2)"))])
    assert order == should_be_order


def test_get_execution_list_for():
    root, (p0, c0, p1, c1, c2, c3) = sample_tree_3()

    C0 = root.children[0].children[0]
    C1 = root.children[0].children[1]
    C2 = root.children[1].children[0]
    C3 = root.children[1].children[1]

    should_be_order, _ = get_execution_list_for(root)
    order = [(p0, None, None),
             (c0, None, C0),
             (p1, None, None),
             (c1, C0, C1),
             (c2, parse_boolean("(~C0_st3 | ~C1_st3)"), C2),
             (c3, parse_boolean("(~C0_st3 | ~C1_st3)"), C3)] # C2 not in execution condition, because C2.average_eff = 1

    assert order == should_be_order

