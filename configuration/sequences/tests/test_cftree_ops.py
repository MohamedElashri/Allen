###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

# See https://stackoverflow.com/questions/16981921/relative-imports-in-python-3
import sys
import os
PACKAGE_PARENT = '..'
SCRIPT_DIR = os.path.dirname(
    os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT)))

# import pytest
from sympy import simplify
from collections import OrderedDict
from minipyconf.components import Algorithm
from minipyconf.control_flow import Leaf, NodeLogic as Logic, CompositeNode
from minipyconf.cftree_ops import (
    gather_algs,
    get_ordered_trees,
    to_string,
    gather_leafs,
    parse_boolean,
    get_execution_list_for,
    get_best_order,
    merge_execution_masks,
    find_execution_masks_for_algorithms
)
from minipyconf.utils import memoizing
from definitions.event_list_utils import make_algorithm
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
    Y = Leaf("Y_st0", 4, 0.5, alg=y)

    line1 = CompositeNode("L1_st0", Logic.AND, [PRE0, X], forceOrder=True)
    line2 = CompositeNode("L2_st0", Logic.AND, [PRE1, Y], forceOrder=True)
    top = CompositeNode("root_st0", Logic.OR, [line1, line2], forceOrder=False)
    return top


@memoizing
def sample_tree_1():
    PRE0 = Leaf("PRE0_st1", 1, 0.7, alg=None)
    PRE1 = Leaf("PRE1_st1", 2, 0.7, alg=None)
    X = Leaf("X_st1", 3, 0.5, alg=None)
    Y = Leaf("Y_st1", 5, 0.5, alg=None)

    line1 = CompositeNode("L1_st1", Logic.AND, [PRE0, X], forceOrder=True)
    line2 = CompositeNode("L2_st1", Logic.AND, [PRE1, Y], forceOrder=True)
    notline2 = CompositeNode("nL2_st1", Logic.NOT, [line2], forceOrder=True)
    top = CompositeNode("root_st1", Logic.OR, [line1, notline2], forceOrder=True)
    return top


@memoizing
def sample_tree_2():
    pre0 = Algorithm(decider_1_t, name="pre0_st2", conf=1, weight=1)
    pre1 = Algorithm(decider_1_t, name="pre1_st2", conf=2, weight=1)
    pre2 = Algorithm(decider_1_t, name="pre2_st2", conf=3, weight=1)
    PRE0 = Leaf("PRE0_st2", 1, 0.7, alg=pre0)
    PRE1 = Leaf("PRE1_st2", 1, 0.3, alg=pre1)
    PRE2 = Leaf("PRE2_st2", 2, 0.3, alg=pre2)
    pre12 = CompositeNode("pre12_st2", Logic.AND, [PRE1, PRE2], forceOrder=True, lazy=True)
    return CompositeNode("boom_st2", Logic.OR, [PRE0, pre12], forceOrder=True, lazy=True)


def test_gather_leafs():
    root = sample_tree_0()
    leafs = set(
        (Leaf.leafs["PRE0_st0"], Leaf.leafs["PRE1_st0"], Leaf.leafs["X_st0"], Leaf.leafs["Y_st0"])
    )
    assert gather_leafs(root) == leafs


def test_merge_execution_masks():
    masks = [("alg1", "true"), ("alg1", "false")]
    should_be_merged = merge_execution_masks(masks)
    merged = {"alg1": "true"}
    assert simplify(should_be_merged["alg1"]) == simplify(merged["alg1"])


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
        np.array(child_names(ord_trees[0])) == np.flip(child_names(ord_trees[1]))
    )


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
    root = sample_tree_0()
    exec_masks = find_execution_masks_for_algorithms(root)
    pre0 = root.children[0].children[0].top_alg
    pre1 = root.children[1].children[0].top_alg
    dec0 = root.children[0].children[1].top_alg
    dec1 = root.children[1].children[1].top_alg
    assert exec_masks == [(pre0, 'True'),
                          (dec0, 'PRE0_st0'),
                          (pre1, '~PRE0_st0 | ~X_st0'),
                          (dec1, 'PRE1_st0 & (~PRE0_st0 | ~X_st0)')]
