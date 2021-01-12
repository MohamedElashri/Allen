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

import pytest
from sympy import simplify
from collections import OrderedDict
from minipyconf.components import Algorithm
from minipyconf.control_flow import Leaf, NodeLogic, CompositeNode
from minipyconf.cftree_ops import (
    gather_algs,
    get_ordered_trees,
    to_string,
    gather_leafs,
    parse_boolean,
    get_execution_list_for,
    get_best_order,
    merge_execution_masks
)
from minipyconf.utils import memoizing
from definitions.event_list_utils import make_algorithm
from definitions.algorithms import host_global_event_cut_t, producer_1_t

def test_merge_execution_masks():
    masks = [("alg1", "true"), ("alg1", "false")]
    should_be_merged = merge_execution_masks(masks)
    merged = {"alg1": "true"}
    assert simplify(should_be_merged["alg1"]) == simplify(merged["alg1"])


@memoizing
def sample_tree_0():
    pre0 = Algorithm(host_global_event_cut_t, name="gec", weight=1)
    pre1 = Algorithm(host_global_event_cut_t, name="gec2", min_clusters="10", weight=2)
    x = Algorithm(producer_1_t, name="producer_1", weight=10)
    y = Decider("y", 4)

    PRE0 = Leaf("PRE0", 1, 0.7, algs=[pre0])
    PRE1 = Leaf("PRE1", 2, 0.3, algs=[pre1])
    X = Leaf("X", 3, 1, algs=[x])
    Y = Leaf("Y", 4, 0.5, algs=[y])

    line1 = CompositeNode("L1", Logic.AND, [PRE0, X])
    line2 = CompositeNode("L2", Logic.AND, [PRE1, Y])
    top = CompositeNode("root", Logic.OR, [line1, line2], order=False)
    return top, set((pre0, pre1, x, y))


@memoizing
def sample_tree_1():
    PRE0 = Leaf("PRE0_", 1, 0.7, algs=[])
    PRE1 = Leaf("PRE1_", 1, 0.7, algs=[])
    X = Leaf("X_", 3, 0.5, algs=[])
    Y = Leaf("Y_", 5, 0.5, algs=[])

    line1 = CompositeNode("L1", Logic.AND, [PRE0, X])
    line2 = CompositeNode("L2", Logic.AND, [PRE1, Y])
    notline2 = CompositeNode("L2", Logic.NOT, [line2])
    top = CompositeNode("root", Logic.OR, [line1, notline2], order=False)
    return top


@memoizing
def sample_tree_2():
    pre0 = Prescaler("pre0", 1)
    pre1 = Prescaler("pre1", 2)
    pre2 = Prescaler("pre2", 1)
    PRE0 = Leaf("PRE0", 1, 0.7, algs=[pre0])
    PRE1 = Leaf("PRE1", 2, 0.3, algs=[pre1, pre2])
    return CompositeNode("boom", Logic.OR, [PRE0, PRE1], order=True, lazy=True)

def line():
    alg1 = make_alg1()
    alg2 = make_alg2()
    return Line(CompositeNode([Leaf(alg1), Leaf(alg2)], AND, lazy=True, order=True), persistency)

def moore():
    all_lines = get_all_lines()
    return Moore(CompositeNode(OR, all_lines, not_lazy))


def test_gather_leafs():
    root, _ = sample_tree_0()
    leafs = set(
        (Leaf.leafs["PRE0"], Leaf.leafs["PRE1"], Leaf.leafs["X"], Leaf.leafs["Y"])
    )
    assert gather_leafs(root) == leafs


# def test_gather_algs():
#     root, algs = sample_tree_0()
#     assert gather_algs(root) == algs


# def test_get_ordered_trees():
#     root, _ = sample_tree_0()
#     ord_trees = get_ordered_trees(root)
#     assert len(ord_trees) == 2  # 2^the number of false orderings

#     def child_names(node):
#         return [child._name for child in node.children]

#     import numpy as np

#     assert all(
#         np.array(child_names(ord_trees[0])) == np.flip(child_names(ord_trees[1]))
#     )


# def test_to_string():
#     root = sample_tree_1()
#     root = get_ordered_trees(root)[0]
#     assert to_string(root) == "((PRE0_ & X_) | ~(PRE1_ & Y_))"


# def test_parse_boolean():
#     root = sample_tree_1()
#     root = get_ordered_trees(root)[0]
#     other_root = parse_boolean("((PRE0_ & X_) | ~(PRE1_ & Y_))")
#     assert root == other_root
