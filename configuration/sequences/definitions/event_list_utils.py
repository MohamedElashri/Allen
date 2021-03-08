###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.components import Algorithm
from PyConf.dataflow import configurable_inputs
from PyConf.control_flow import Leaf, NodeLogic, CompositeNode
from PyConf.cftree_ops import get_best_order, get_execution_list_for, gather_leafs
from definitions.AllenSequenceGenerator import generate_allen_sequence
from definitions.allen_benchmarks import benchmark_weights, benchmark_efficiencies
from definitions.algorithms import (
    AlgorithmCategory,
    host_init_event_list_t,
    event_list_intersection_t,
    event_list_union_t,
    event_list_inversion_t,
)


def make_algorithm(alg_type, name, **kwargs):
    """
    Makes an Algorithm with a weight extracted from the benchmark weights.

    In order to determine the weight of Allen algorithms, a profiled benchmark of `nsys profile`
    is used for most entries, where the field average time is used.
    Each algorithm has an entry in the file `allen_benchmarks.py`, with the exception of:

    * Prefix sum algorithms (identified by prefix_sum in its name): A weight of 1000.0 is manually set.
    * Algorithms of category SelectionAlgorithm: A weight of 10.0 is set.
    * Else: A weight of 100.0 is set. A message is shown identifying the algorithm with no weight.
    """
    if name in benchmark_weights:
        weight = benchmark_weights[name]
    elif "prefix_sum" in name:
        weight = 1000.0
    elif alg_type.category() == AlgorithmCategory.SelectionAlgorithm:
        weight = 10.0
    else:
        weight = 100.0
        print(name, "does not have a weight")
    return Algorithm(alg_type, name=name, weight=weight, **kwargs)


def make_leaf(name, alg, **kwargs):
    """
    Makes a leaf identified by its name and algorithm. Also, sets the "efficiency" of the leaf.
    The efficiency of the leaf indicates how likely is it to accept events. Similarly to
    benchmark weights, benchmark efficiencies are also set in the file `allen_benchmarks.py`.
    """
    t = alg.type.getType()
    # TODO efficiency should not be based on the type, but on the configuration (maybe the name)
    if t in benchmark_efficiencies:
        efficiency = benchmark_efficiencies[t]
    else:
        efficiency = 1.0
    return Leaf(name, alg=alg, average_eff=efficiency, **kwargs)


def initialize_event_lists(**kwargs):
    initialize_lists = make_algorithm(host_init_event_list_t, name="initialize_event_lists")
    return initialize_lists


def add_event_list_combiners(order):
    """
    This function accepts an ordered list of algorithms and inserts event list combiners
    where necessary to fulfill combined masks formed as a combination of other masks.

    Combiners are host algorithms that provide three operations for masks: union, intersection
    and difference. These three operations would correspond in a single-event scenario to the
    OR, AND and NOT gate. This equivalence is used to transform NodeLogic into combiners.
    """
    # gather all combinations that have to be made
    seq = order[0]
    trees = tuple(set([s[1] for s in seq]))

    def _make_combiner(inputs, logic):

        if logic in (NodeLogic.LAZY_AND, NodeLogic.NONLAZY_AND):
            return Algorithm(
                event_list_intersection_t,
                name="_AND_".join([i.producer.name for i in inputs]),
                dev_event_list_a_t=inputs[0],
                dev_event_list_b_t=inputs[1],
            )
        elif logic in (NodeLogic.LAZY_OR, NodeLogic.NONLAZY_OR):
            return Algorithm(
                event_list_union_t,
                name="_OR_".join([i.producer.name for i in inputs]),
                dev_event_list_a_t=inputs[0],
                dev_event_list_b_t=inputs[1],
            )
        elif logic == NodeLogic.NOT:
            return Algorithm(
                event_list_inversion_t,
                name="NOT_" + inputs[0].producer.name,
                dev_event_list_input_t=inputs[0],
            )

    def combine(logic, *nodes):  # needs to return pyconf algorithm
        output_masks = []
        for n in nodes:
            m = [a for a in n.outputs.values() if a.type == "mask_t"]
            assert len(m) == 1, f"should have one output mask, got {len(m)}"
            output_masks.append(m[0])

        return _make_combiner(
            inputs=output_masks, logic=logic)

    def _has_only_leafs(node):
        return all(isinstance(c, Leaf) for c in node.children)

    def _is_leaf(node):
        return isinstance(node, Leaf)

    def _make_combiners_from(node, combiners):
        if not node:
            combiners.append(initialize_event_lists())
        if isinstance(node, Leaf):
            combiners.append(node.algs[-1])
        elif isinstance(node, CompositeNode):
            if _has_only_leafs(node):
                combiners.append(
                    combine(node.combineLogic, *[c.algs[-1] for c in node.children])
                )
            else:
                if _is_leaf(node.children[0]):
                    _make_combiners_from(node.children[1], combiners)
                    combiners.append(
                        combine(
                            node.combineLogic, node.children[0].algs[-1], combiners[-1]
                        )
                    )
                elif _is_leaf(node.children[1]):
                    _make_combiners_from(node.children[0], combiners)
                    combiners.append(
                        combine(
                            node.combineLogic, combiners[-1], node.children[1].algs[-1]
                        )
                    )
                else:
                    _make_combiners_from(node.children[0], combiners)
                    c1 = combiners[-1]
                    _make_combiners_from(node.children[1], combiners)
                    c2 = combiners[-1]
                    combiners.append(combine(node.combineLogic, c1, c2))
        return combiners

    def make_combiners_from(node):
        return tuple(_make_combiners_from(node, []))

    combiners = {t: make_combiners_from(t) for t in trees}

    # Generate the final sequence in a list of tuples (algorithm, execution mask)
    final_sequence = seq

    # Add combiners in the right place
    for mask, combiner in combiners.items():
        for i, (alg, _mask, _) in enumerate(final_sequence):
            if mask == _mask:
                for comb in combiner[::-1]:
                    final_sequence.insert(i, (comb, None, mask))
                break

    # Remove duplicate combiners
    final_sequence_unique = list()
    for (alg, mask_in, mask_out) in final_sequence:
        for (alg_, _, _) in final_sequence_unique:
            if alg == alg_:
                break
        else:
            final_sequence_unique.append((alg, mask_in, mask_out))

    # Update all algorithm event lists
    for alg, mask, _ in final_sequence_unique:
        mask_input = [k for k,v in configurable_inputs(alg.type).items() if v.type() == "mask_t"]
        if len(mask_input):
            output_mask = [v for v in combiners[mask][-1].outputs.values() if v.type == "mask_t"]
            assert(len(mask_input) == 1 and len(output_mask) == 1)
            alg.inputs[mask_input[0]] = output_mask[0]

    return final_sequence_unique

def generate(root):
    """Generates an Allen sequence out of a root node."""
    best_order = get_execution_list_for(root)
    final_seq = add_event_list_combiners(best_order)

    print("Generated sequence represented as algorithms with execution masks:")
    for alg, mask_in, mask_out in final_seq:
        mask_in_str = f" in:{mask_in}" if mask_in else ""
        mask_out_str = f" out:{mask_out}" if mask_out else ""
        print(f"  {alg}{mask_in_str}{mask_out_str}")

    return generate_allen_sequence([alg for (alg,_,_) in final_seq])
