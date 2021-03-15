###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
import numpy as np
import itertools
import functools
import ast
import sympy
from collections import defaultdict, OrderedDict
from PyConf.control_flow import CompositeNode, NodeLogic
from functools import lru_cache
from PyConf.components import _get_unique_name, Algorithm

class BoolNode:
    """
    A representation of boolean operations (and, or, not).
    Although somewhat similar to the CompositeNode in PyConf.control_flow, it
    serves the purpose of representation and does not need a name or caching.
    """

    AND="&"
    OR="|"
    NOT="~"

    def __init__(self, combine_logic, children):
        assert all(isinstance(c, Algorithm) or isinstance(c, BoolNode) for c in children)
        assert combine_logic in (self.AND, self.OR, self.NOT)
        self.children = tuple(c for c in children)
        self.combine_logic = combine_logic

    @property
    def uses_not(self):
        return self.combine_logic == self.NOT

    @property
    def uses_or(self):
        return self.combine_logic == self.OR

    @property
    def uses_and(self):
        return self.combine_logic == self.AND

    def __repr__(self):
        return to_string(self)

    def __hash__(self):
        return hash((
            self.children,
            self.combine_logic,
        ))

    def __eq__(self, other):
        return hash(self) == hash(other)

@lru_cache(1000)
def simplify(string):
    return str(sympy.simplify(string))


@lru_cache(1000)
def get_ordered_trees(node):
    """
    Gets all possible orderings from a partially specified tree.
    A tree may have CompositeNodes with force_order = False.
    For every occurence of these nodes, this function expands the tree
    into a collection of all permutations.
    Example:
    For a input tree with two binary CompositeNodes with force_order=False,
    four trees will come of of this function:

    both & and | unordered: ((A & B) | C)
    -> [
        ((A & B) | C),
        ((B & A) | C),
        (C | (A & B)),
        (C | (B & A))
       ]
    """
    if isinstance(node, Algorithm):
        return (node,)
    elif isinstance(node, CompositeNode):
        if not node.force_order and node.is_lazy:
            return [
                CompositeNode(node.name, x, node.combine_logic, force_order=True)
                for children in itertools.permutations(
                    tuple(get_ordered_trees(c) for c in node.children)
                )
                for x in itertools.product(*children)
            ]
        else:
            return [
                CompositeNode(node.name, x, node.combine_logic, force_order=True)
                for x in itertools.product(
                    *tuple(get_ordered_trees(c) for c in node.children)
                )
            ]
    else:
        raise TypeError("please provide CompositeNodes or Algorithms.")


@lru_cache(1000)
def to_string(node):
    """
    translates a tree into a string:

        OR
       /  \
      A    B

      -> "(A | B)"

    For binary trees, to_string and parse_boolean should be inverse functions
    """
    if isinstance(node, Algorithm):
        return node.name
    elif isinstance(node, CompositeNode) or isinstance(node, BoolNode):
        if node.uses_not:
            return f"~{to_string(node.children[0])}"
        elif node.uses_and:
            return (
                "("
                + f" & ".join([to_string(c) for c in node.children])
                + ")"
            )
        elif node.uses_or:
            return (
                "("
                + f" | ".join([to_string(c) for c in node.children])
                + ")"
            )
    else:
        raise TypeError("please provide CompositeNodes, BoolNodes or Algorithms.")


def gather_leafs(node):
    """
    gathers algs from a tree that do decision making
    """

    def impl(node):
        if isinstance(node, Algorithm):
            yield node
        if isinstance(node, CompositeNode) or isinstance(node, BoolNode):
            for child in node.children:
                yield from impl(child)

    return frozenset(impl(node))


def gather_algs(node):
    return frozenset([alg for leaf in gather_leafs(node) for alg in leaf.all_producers(False)])


@lru_cache(1000)
def parse_boolean(expr):
    """
    parses a boolean expression of existing control flow nodes.
    Example:
    (GEC & HASMUON) builds a tree with and AND node with children [GEC, HASMUON].
    Because algorithms (like GEC, HASMUON) are globally cached,
    it will query the cache to get the same instances.
    For binary trees, to_string and parse_boolean should be inverse functions
    """
    if expr.lower() == "true":
        return None
    elif expr.lower() == "false":
        raise ValueError(
            "your tree will never evaluate to true, do you really want this?"
        )

    def build_tree(node):
        if isinstance(node, ast.BinOp):
            if isinstance(node.op, ast.BitOr):
                return BoolNode(
                    BoolNode.OR,
                    (build_tree(node.left), build_tree(node.right)),
                )
            elif isinstance(node.op, ast.BitAnd):
                return BoolNode(
                    BoolNode.AND,
                    (build_tree(node.left), build_tree(node.right)),
                )
            else:
                raise NotImplementedError("Unexpected binary operation in node")
        elif isinstance(node, ast.UnaryOp):
            if isinstance(node.op, ast.Invert):
                return BoolNode(
                    BoolNode.NOT, (build_tree(node.operand),)
                )
            else:
                raise NotImplementedError("Unexpected unary operation in node")
        elif isinstance(node, ast.Name):
            # TODO make this better
            names = {alg.name : alg for alg in Algorithm._algorithm_store.values()}
            if node.id in names:
                return names[node.id]
            else:
                raise ValueError(f"Unknown Alg: {node.id}, could not parse")
        else:
            raise NotImplementedError(f"cannot parse {node}")

    return build_tree(ast.parse(expr).body[0].value)


@lru_cache(1000)
def find_execution_masks_for_algorithms(root, execution_mask="true"):
    """An execution mask determines on which events an algorithm will be executed.
    This function finds an execution mask for each algorithm in the
    tree whose root node is passed.

    An execution mask of "true" means the algorithm will be executed for all events within.
    Other execution masks are formed from MASK_OUTPUT types, by combining them if necessary,
    to fulfill the requirements set by the control flow logic.

    The functionality of this function is implemented in a recursive "impl" function, which
    converts logical nodes to a logic string that is parsable, which is attached to each node
    in the tree.

    @returns tree decorated with execution masks."""

    def impl(
        node, execution_mask="true"
    ):  # for sympy.simplify we need lower case true and false
        if isinstance(node, Algorithm):
            # TODO do we want to keep these if statements?
            # do we have a RL usecase for average efficiencies of 0 and 1?
            if node.average_eff == 1:
                leafmask = "true"
            elif node.average_eff == 0:
                leafmask == "false"
            else:
                leafmask = node.name
            return [(algorithm, execution_mask) for algorithm in node.all_producers(False)], leafmask
        elif isinstance(node, CompositeNode):
            outputs = []
            output_names = []
            if node.uses_and:
                for child in node.children:
                    if node.is_lazy:
                        output, output_name = impl(
                            child, " & ".join([execution_mask] + output_names)
                        )
                    else:
                        output, output_name = impl(child, execution_mask)
                    outputs.append(output)
                    output_names.append(output_name)
                return (
                    [x for output in outputs for x in output],
                    "(" + execution_mask + " & (" + " & ".join(output_names) + "))",
                )
            elif node.uses_or:
                for child in node.children:
                    if node.is_lazy:
                        output, output_name = impl(
                            child, " & ~ ".join([execution_mask] + output_names)
                        )
                    else:
                        output, output_name = impl(child, execution_mask)
                    outputs.append(output)
                    output_names.append(output_name)
                return (
                    [x for output in outputs for x in output],
                    "(" + execution_mask + " & (" + " | ".join(output_names) + "))",
                )
            elif node.uses_not:
                output, output_name = impl(node.children[0], execution_mask)
                return (output, "(" + execution_mask + " & ~ (" + output_name + "))")

    # return impl(root, execution_mask)[0]
    return [(alg, simplify(mask)) for alg, mask in impl(root, execution_mask)[0]]


def merge_execution_masks(execution_masks):
    """
    merges two execution masks using the or operator.
    """
    merged_masks = defaultdict(list)
    for alg, mask in execution_masks:
        merged_masks[alg].append("(" + mask + ")")
    return {k: " | ".join(v) for k, v in merged_masks.items()}


@lru_cache(1000)
def avrg_efficiency(node):
    """
    obtains the average efficiency of a CompositeNode by
    combining leaf efficiencies. It assumes no correlation between them.

    Example:
    tree : (A & B)
    efficiency of A: 0.5
    efficiency of B: 0.2

    -> tree efficiency = 0.5*0.2 = 0.1

    It handles arbitrary tree complexity.
    """
    if not node:  # the tree is just "True"
        return 1
    elif isinstance(node, Algorithm):
        return node.average_eff
    elif isinstance(node, CompositeNode) or isinstance(node, BoolNode):
        combine_effs = lambda fun: functools.reduce(
            fun, map(avrg_efficiency, node.children), 1
        )
        if node.uses_and:
            return combine_effs(lambda x, y: x * y)
        elif node.uses_or:
            return 1 - combine_effs(lambda x, y: x * (1 - y))
        elif node.uses_not:
            return 1 - avrg_efficiency(node.children[0])  # only one child
    else:
        raise TypeError()


@lru_cache(1000)
def make_independent_of_algs(node, algs):
    """
    This function takes an execution mask in form of a tree and a list of algs.
    It returns a looser mask which does not depend on the control flow
    outcome of these algorithms.
    This function is used when building an execution sequence, whenever the
    execution masks of all algorithms depend on the outcomes of other
    algorithms, meaning that no algorithm can trivially be scheduled next.
    In this case, this function can 'loosen' the execution mask to be
    invariant under the outcome of other specified algorithms.
    """
    algs = set(algs)

    def has_unknown_cf(alg):
        return alg.average_eff not in [0, 1] and alg in algs

    unknown_outcome_algs = set(filter(has_unknown_cf, gather_leafs(node)))

    if not unknown_outcome_algs:
        return node

    mini_repr = to_string(node)
    all_reprs = []
    for decisions in itertools.product(
        *(["true", "false"] for _ in unknown_outcome_algs)
    ):
        curr_repr = mini_repr
        for i, leaf in enumerate(unknown_outcome_algs):
            curr_repr = curr_repr.replace(leaf.name, decisions[i])
        all_reprs.append(curr_repr)
    combined = simplify("(" + " | ".join(all_reprs) + ")")
    return parse_boolean(combined)


@lru_cache(1000)
def get_weight(algorithm, ordered_algorithm_tuple):
    """
    gets the weight of an algorithm.
    """
    # TODO: Maybe make logic more complex
    # the weight might be dependent on other algorithms
    # in Allen, an example might be that the weight of
    # a dataloader increases dramatically when there is another
    # dataloader right infront of it. For now though,
    # lets leave it like this
    return algorithm._weight


def order_algs(alg_dependencies):
    """
    This function accepts as a parameter a dictionary of algorithm dependencies:
    alg dependencies : dict(alg : (cf_dependencies, df_dependencies, minitree),
    and returns an ordering of the algorithms (variable sortd) according to a predefined heuristic,
    alongside the weight of the resulting order.

    In order to append an algorithm to the sortd order that is created in this function,
    the algorithm must fulfill the condition of being dataflow-insertable. An algorithm is
    dataflow-insertable if all algorithms in dataflow-dependencies (df_dependencies) have
    already been met (ie. have already been inserted in sortd).

    Algorithms for which controlflow-dependencies are also fulfilled, that is, algorithms that are
    df_insertable and cf_insertable, are preferred over algorithms that are only df_insertable. However, it is
    possible to reach a point where there are no algorithms that are cf_insertable. In the following example,
    the top algorithm for A is a, the one for B is b, and the one for C is c. Example:

    tree: (A & B) | (C & B)
    sortd: [a]
    df_insertable: [b, c]
    cf_insertable: []

    B and C both depend on each other to be cf_insertable. In this scenario, either the algorithm(s) in node B
    or the algorithm(s) in C could be inserted. A more comprehensive description of this scenario can be found at:
    https://codimd.web.cern.ch/jMxAOmYhR4-q9eRxnp6kRA

    Therefore, the following rules are followed to determine an order:
    * Always prefer algorithms that are both cf_ and df_ insertable over algorithms that are only df_ insertable.
    * Use a heuristic to determine the algorithm between those that are cf_ and df_ insertable.
    * Use a heuristic to determine the algorithm between those that are only df_ insertable.

    The current heuristic for the above cases is "execute the least expensive one", according to its weight.
    """
    algs = list(alg_dependencies.keys())
    sortd = OrderedDict([])
    score = 0

    def _insertable(alg, i):
        return all(x in sortd for x in alg_dependencies[alg][i])

    cf_insertable = lambda alg: _insertable(alg, 0)
    df_insertable = lambda alg: _insertable(alg, 1)

    while algs:
        insertable_algorithms = [
            alg for alg in algs if df_insertable(alg) and cf_insertable(alg)
        ]
        algorithms_already_sortd = tuple(sortd.keys())
        if insertable_algorithms:
            # Simple heuristic: Execute least expensive one
            # TODO review this logic
            alg = min(
                insertable_algorithms,
                key=lambda x: get_weight(x, algorithms_already_sortd)
                * avrg_efficiency(alg_dependencies[x][2]),
            )
            minitree = alg_dependencies[alg][2]
            score += get_weight(alg, algorithms_already_sortd) * avrg_efficiency(
                minitree
            )
            sortd[algs.pop(algs.index(alg))] = minitree
        else:
            # there is no algorithm that can be executed next
            # without removing control flow dependencies
            # so to check which algorithm is the cheapest one now, lets
            # look at updated weights:
            # TODO review this logic
            def _get_adjusted_weight(alg):
                weight = get_weight(alg, algorithms_already_sortd)
                eval_mask = alg_dependencies[alg][2]
                # now, lets see how the eval mask looks without the unknown outcomes
                not_in_sortd = alg_dependencies[alg][0].difference(sortd)
                eval_mask = make_independent_of_algs(eval_mask, frozenset(not_in_sortd))
                efficiency = avrg_efficiency(eval_mask)
                return weight*efficiency

            alg = min(
                [alg for alg in algs if df_insertable(alg)],
                key=_get_adjusted_weight
            )
            eval_mask = alg_dependencies[alg][2]
            not_in_sortd = alg_dependencies[alg][0].difference(sortd)
            eval_mask = make_independent_of_algs(eval_mask, frozenset(not_in_sortd))
            avrg_eff = avrg_efficiency(eval_mask)
            score += avrg_eff * get_weight(alg, algorithms_already_sortd)
            sortd[algs.pop(algs.index(alg))] = eval_mask

    return sortd, score


def get_execution_list_for(tree):
    """
    produces an execution sequence from a control flow tree,
    with a specified algorithm order and execution conditions(masks).
    """
    dependencies = dict()
    exec_masks = find_execution_masks_for_algorithms(tree)
    exec_masks = merge_execution_masks(exec_masks)
    for alg, mask in exec_masks.items():
        mini_tree = parse_boolean(simplify(mask))
        producers = set()
        for inp in alg.inputs.values():
            if type(inp) == list:
                for single_input in inp:
                    producers.add(single_input.producer)
            else:
                producers.add(inp.producer)
        dependencies[alg] = (gather_algs(mini_tree), producers, mini_tree)

    (seq, val) = order_algs(dependencies)

    return (tuple(seq.items()), val)


def get_best_order(tree):
    """
    gets the tree with the lowest combined weight.
    relies on `get_execution_list_for`
    """
    all_orders = get_ordered_trees(tree)
    x = map(get_execution_list_for, all_orders)
    return (x, min(x, key=lambda x: x[-1]))
