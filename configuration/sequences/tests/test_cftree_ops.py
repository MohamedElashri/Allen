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
from sympy import simplify
from collections import OrderedDict
from PyConf.components import Algorithm
from PyConf.control_flow import Leaf, NodeLogic as Logic, CompositeNode
from PyConf.cftree_ops import (
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
)
from PyConf.utils import memoizing
from definitions.algorithms import *


@memoizing
def sample_tree_0():
    pre0 = Algorithm(decider_1_t, name="pre0_st0", conf=2)
    pre1 = Algorithm(decider_1_t, name="pre1_st0", conf=1)
    x = Algorithm(decider_1_t, name="decider0_st0", conf=3)
    y = Algorithm(decider_1_t, name="decider0_st0", conf=4)

    PRE0 = Leaf("PRE0_st0", 1, 0.7, alg=pre0)
    PRE1 = Leaf("PRE1_st0", 2, 0.3, alg=pre1)
    X = Leaf("X_st0", 3, 1, alg=x)
    Y = Leaf("Y_st0", 4, 1, alg=y)

    line1 = CompositeNode("L1_st0", Logic.AND, [PRE0, X], forceOrder=True)
    line2 = CompositeNode("L2_st0", Logic.AND, [PRE1, Y], forceOrder=True)
    top = CompositeNode("root_st0", Logic.OR, [line1, line2], forceOrder=False)
    return top


@memoizing
def sample_tree_1():
    PRE0 = Leaf("PRE0_st1", 1, 0.7, alg=None)
    PRE1 = Leaf("PRE1_st1", 2, 0.6, alg=None)
    X = Leaf("X_st1", 3, 0.5, alg=None)
    Y = Leaf("Y_st1", 5, 0.4, alg=None)

    line1 = CompositeNode("L1_st1", Logic.AND, [PRE0, X], forceOrder=True)
    line2 = CompositeNode("L2_st1", Logic.AND, [PRE1, Y], forceOrder=True)
    notline2 = CompositeNode("nL2_st1", Logic.NOT, [line2], forceOrder=True)
    top = CompositeNode(
        "root_st1", Logic.OR, [line1, notline2], forceOrder=True)
    return top


@memoizing
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
        "pre12_st2", Logic.AND, [PRE1, PRE2], forceOrder=True, lazy=True)
    pre02 = CompositeNode(
        "pre02_st2", Logic.AND, [PRE0, PRE2], forceOrder=True, lazy=True)
    return CompositeNode(
        "boom_st2", Logic.OR, [pre02, pre12], forceOrder=True, lazy=True)


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

    import numpy as np

    assert all(
        np.array(child_names(ord_trees[0])) == np.flip(
            child_names(ord_trees[1])))


def test_to_string():
    root = sample_tree_1()
    root = get_ordered_trees(root)[0]
    assert to_string(root) == "((PRE0_st1 & X_st1) | ~(PRE1_st1 & Y_st1))"


def test_parse_boolean():
    root = sample_tree_1()
    root = get_ordered_trees(root)[0]
    other_root = parse_boolean("((PRE0_st1 & X_st1) | ~(PRE1_st1 & Y_st1))")
    assert root == other_root


def test_find_execution_masks_for_algorithms():
    # test sample tree 0
    root = sample_tree_0()
    exec_masks = find_execution_masks_for_algorithms(root)
    pre0_st0 = root.children[0].children[0].top_alg
    pre1_st0 = root.children[1].children[0].top_alg
    dec0_st0 = root.children[0].children[1].top_alg
    dec1_st0 = root.children[1].children[1].top_alg
    assert exec_masks == [
        (pre0_st0, "True"),
        (dec0_st0, "PRE0_st0"),
        (pre1_st0, "~PRE0_st0 | ~X_st0"),
        (dec1_st0, "PRE1_st0 & (~PRE0_st0 | ~X_st0)"),
    ]

    # test sample tree 2
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
