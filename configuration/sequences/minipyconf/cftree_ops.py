import numpy as np
import itertools
import functools
import ast
import sympy
from collections import defaultdict, OrderedDict
from .control_flow import Leaf, CompositeNode, NodeLogic
from .utils import memoizing, uniqueify

@memoizing
def simplify(string):
    return sympy.simplify(string)


@memoizing
def get_ordered_trees(node):
    if isinstance(node, Leaf):
        return [node]
    elif not node.is_ordered and node.is_lazy:
        return [
            CompositeNode(node.name, node.logic, x, lazy=node.is_lazy, forceOrder=True)
            for children in itertools.permutations(
                [get_ordered_trees(c) for c in node.children]
            )
            for x in itertools.product(*children)
        ]
    else:
        return [
            CompositeNode(node.name, node.logic, x, lazy=node.is_lazy, forceOrder=True)
            for x in itertools.product(*[get_ordered_trees(c) for c in node.children])
        ]


@memoizing
def to_string(node):
    if isinstance(node, Leaf):
        return node.name
    elif node.logic == NodeLogic.NOT:
        return f"~{to_string(node.children[0])}"
    elif isinstance(node, CompositeNode):
        return (
            "("
            + f" {node.logic.value} ".join([to_string(c) for c in node.children])
            + ")"
        )
    else:
        raise RuntimeError("please provide CompositeNodes or Leafs.")

@memoizing
def score(node):
    if isinstance(node, Leaf):
        return node.execution_weight, node.average_eff
    elif isinstance(node, CompositeNode):
        weight, eff = score(node.children[0])
        if node.logic == NodeLogic.AND:
            weight2, eff2 = score(node.children[1])
            return weight + eff * weight2, eff * eff2
        elif node.logic == NodeLogic.OR:
            weight2, eff2 = score(node.children[1])
            return weight + (1 - eff) * weight2, 1 - ((1 - eff) * (1 - eff2))
        elif node.logic == NodeLogic.NOT:
            return weight, 1 - eff


def gather_leafs(node):
    def impl(node):
        if isinstance(node, Leaf):
            yield node
        if isinstance(node, CompositeNode):
            for child in node.children:
                yield from impl(child)

    return frozenset(impl(node))


def gather_algs(node):
    return frozenset([alg for leaf in gather_leafs(node) for alg in leaf.algs])

@memoizing
def parse_boolean(expr: str):
    if expr.lower == "true":
        return None
    if expr.lower == "false":
        raise ValueError(
            "your tree will never evaluate to true, do you really want this?"
        )

    class visitor(ast.NodeVisitor):
        astToNode = dict()
        root_node = None

        def visit_BoolOp(self, node):
            raise NotImplementedError(
                'please provide "AND" as &, "OR" as |, "NOT" as ~'
            )

        def visit_Not(self, node):
            raise NotImplementedError(
                'please provide "AND" as &, "OR" as |, "NOT" as ~'
            )

        def visit_BinOp(self, node):
            my_name = uniqueify("LN")
            if isinstance(node.op, ast.BitOr):
                self.astToNode[node] = CompositeNode(
                    my_name, NodeLogic.OR, [node.left, node.right]
                )
            elif isinstance(node.op, ast.BitAnd):
                self.astToNode[node] = CompositeNode(
                    my_name, NodeLogic.AND, [node.left, node.right]
                )
            else:
                raise NotImplementedError("WTH MAN")
            if self.root_node == None:
                self.root_node = self.astToNode[node]
            return super().generic_visit(node)

        def visit_UnaryOp(self, node):
            if isinstance(node.op, ast.Invert):
                my_name = uniqueify("LN")
                self.astToNode[node] = CompositeNode(my_name, NodeLogic.NOT, [node.operand])
            if self.root_node == None:
                self.root_node = self.astToNode[node]
            return super().generic_visit(node)

        def visit_Name(self, node):
            if node.id in Leaf.leafs:
                self.astToNode[node] = Leaf.leafs[node.id]
            else:
                # TODO or do we require them to appear already?
                print("Warning: generating new Leaf in parse_boolean")
                self.astToNode[node] = Leaf(node.id, 1, 1, [])
            if self.root_node == None:
                self.root_node = self.astToNode[node]
            return super().generic_visit(node)

    tree = ast.parse(expr)
    v = visitor()
    v.visit(tree)
    # fix node children
    for node in v.astToNode.values():
        if isinstance(node, CompositeNode):
            node.children = [v.astToNode[child] for child in node.children]

    return v.root_node

@memoizing
def find_execution_masks_for_algorithms(node, execution_mask="true"):
    def impl(
        node, execution_mask="true"
    ):  # for sympy.simplify we need lower case true and false
        if isinstance(node, Leaf):
            return [(algorithm, execution_mask) for algorithm in node.algs], node.name
        elif isinstance(node, CompositeNode):
            outputs = []
            output_names = []
            if node.logic == NodeLogic.AND:
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
                    np.concatenate(outputs),
                    "(" + execution_mask + " & (" + " & ".join(output_names) + "))",
                )
            elif node.logic == NodeLogic.OR:
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
                    np.concatenate(outputs),
                    "(" + execution_mask + " & (" + " | ".join(output_names) + "))",
                )
            elif node.logic == NodeLogic.NOT:
                output, output_name = impl(node.children[0], execution_mask)
                return (output, "(" + execution_mask + " & ~ (" + output_name + "))")

    return impl(node, execution_mask)[0]


def merge_execution_masks(execution_masks):
    merged_masks = defaultdict(list)
    for alg, mask in execution_masks:
        merged_masks[alg].append("(" + mask + ")")
    return {k: " | ".join(v) for k, v in merged_masks.items()}

@memoizing
def avrg_efficiency(node):
    if not node:  # the tree is just "True"
        return 1
    elif isinstance(node, Leaf):
        return node.average_eff
    elif isinstance(node, CompositeNode):
        combine_effs = lambda fun: functools.reduce(
            fun, map(avrg_efficiency, node.children), 1
        )
        if node.logic == NodeLogic.AND:
            return combine_effs(lambda x, y: x * y)
        elif node.logic == NodeLogic.OR:
            return 1 - combine_effs(lambda x, y: x * (1 - y))
        elif node.logic == NodeLogic.NOT:
            return 1 - avrg_efficiency(node.children[0])  # only one child
    else:
        raise TypeError()

@memoizing
def make_independent_of_algs(node, algs):
    algs = set(algs)

    def has_unknown_cf(leaf):
        return leaf.average_eff not in [0, 1]

    unknown_outcome_leafs = set(filter(has_unknown_cf, gather_leafs(node)))

    if not unknown_outcome_leafs:
        return node

    mini_repr = to_string(node)
    all_reprs = []
    for decisions in itertools.product(
        *(["true", "false"] for x in unknown_outcome_leafs)
    ):
        curr_repr = mini_repr
        for i, leaf in enumerate(unknown_outcome_leafs):
            curr_repr = curr_repr.replace(leaf.name, decisions[i])
        all_reprs.append(curr_repr)

    combined = str(simplify("(" + " | ".join(all_reprs) + ")"))
    return parse_boolean(combined)

@memoizing
def get_weight(algorithm, ordered_algorithm_tuple):
    # TODO: Maybe more complex logic bum
    return algorithm._weight

def order_algs(alg_dependencies: dict) -> (list, float):
    # alg dependencies : dict(alg : (cf_dependencies, df_dependencies, minitree)
    algs = list(alg_dependencies.keys())
    sortd = OrderedDict([])
    score = 0

    def _insertable(alg, i):
        return all(x in sortd for x in alg_dependencies[alg][i])

    cf_insertable = lambda alg: _insertable(alg, 0)
    df_insertable = lambda alg: _insertable(alg, 1)

    while algs:
        insertable_algorithms = [alg for alg in algs if df_insertable(alg) and cf_insertable(alg)]
        algorithms_already_sortd = tuple(sortd.keys())
        if insertable_algorithms:
            # Simple heuristic: Execute least expensive one
            alg = min(
                insertable_algorithms, key=lambda x: get_weight(x, algorithms_already_sortd) * avrg_efficiency(alg_dependencies[x][2])
            )
            minitree = alg_dependencies[alg][2]
            score += get_weight(alg, algorithms_already_sortd) * avrg_efficiency(minitree)
            sortd[algs.pop(algs.index(alg))] = minitree
        else:
            # Simple heuristic: Execute least expensive one
            alg = min(
                [alg for alg in algs if df_insertable(alg)], key=lambda x: get_weight(x, algorithms_already_sortd) * avrg_efficiency(alg_dependencies[x][2])
            )
            minitree = alg_dependencies[alg][2]
            not_in_sortd = alg_dependencies[alg][0].difference(sortd)
            evaluable_tree = make_independent_of_algs(minitree, not_in_sortd)
            avrg_eff = avrg_efficiency(evaluable_tree)
            score += avrg_eff * get_weight(alg, algorithms_already_sortd)
            sortd[algs.pop(algs.index(alg))] = evaluable_tree
    return sortd, score

def map_alg_to_node(root):
    algorithm_with_output_mask_to_leaf = {}
    for leaf in gather_leafs(root):
        top_algorithm = leaf.top_alg
        contains_output_mask = [a for a in top_algorithm.outputs.values() if a.type == "mask_t"]
        if contains_output_mask:
            algorithm_with_output_mask_to_leaf[top_algorithm] = leaf
    return algorithm_with_output_mask_to_leaf

def get_execution_list_for(tree):

    dependencies = dict()
    exec_masks = find_execution_masks_for_algorithms(tree)
    exec_masks = merge_execution_masks(exec_masks)
    for alg, mask in exec_masks.items():
        mini_tree = parse_boolean(str(simplify(mask)))
        producers = set()
        for inp in alg.inputs.values():
            if type(inp) == list:
                for single_input in inp:
                    producers.add(single_input.producer)
            else:
                producers.add(inp.producer)
        dependencies[alg] = (gather_algs(mini_tree), producers, mini_tree)

    (seq, val) = order_algs(dependencies)

    #add the output masks to seq
    alg_to_leaf = map_alg_to_node(tree)
    return ([(alg, in_, alg_to_leaf.get(alg)) for (alg,in_) in seq.items()], val)


def get_best_order(tree):
    import numpy as np

    all_orders = get_ordered_trees(tree)
    x = map(get_execution_list_for, all_orders)
    return (x, min(x, key=lambda x: x[-1]))
