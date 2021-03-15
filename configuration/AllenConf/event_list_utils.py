###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.components import Algorithm
from PyConf.dataflow import configurable_inputs
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.cftree_ops import get_best_order, get_execution_list_for, BoolNode
from AllenConf.AllenSequenceGenerator import generate_allen_sequence
from AllenConf.allen_benchmarks import benchmark_weights, benchmark_efficiencies
from definitions.algorithms import (
    AlgorithmCategory,
    host_init_event_list_t,
    event_list_intersection_t,
    event_list_union_t,
    event_list_inversion_t,
)

def is_combiner(alg):
    return alg.type in (event_list_intersection_t, event_list_union_t, event_list_inversion_t)

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
    if "average_eff" in kwargs:
        eff = kwargs['average_eff']
    elif name in benchmark_efficiencies:
        eff = benchmark_efficiencies[name]
    else:
        eff = .99 # TODO we could also just do 1, but then they wont be considered in masks

    if "weight" in kwargs:
        weight = kwargs["weight"]
    elif name in benchmark_weights:
        weight = benchmark_weights[name]
    elif "prefix_sum" in name: # hard coded heuristic for now, TODO might want to change
        weight = 1000.0
    elif alg_type.category() == AlgorithmCategory.SelectionAlgorithm:
        weight = 10.0
    else:
        weight = 100.0

    return Algorithm(alg_type, name=name, weight=weight, average_eff=eff, **kwargs)


def initialize_event_lists(**kwargs):
    initialize_lists = make_algorithm(
        host_init_event_list_t, name="initialize_event_lists")
    return initialize_lists


def add_event_list_combiners(order):
    """
    This function accepts an ordered list of algorithms and inserts event list combiners
    where necessary to fulfill combined masks formed as a combination of other masks.

    Combiners are host algorithms that provide three operations for masks: union, intersection
    and difference. These three operations would correspond in a single-event scenario to the
    OR, AND and NOT gate. This equivalence is used to transform NodeLogic into combiners.
    """

    def _make_combiner(inputs, logic):
        # TODO shall we somehow make the name so that parantheses are obvious?
        # here, a combinerfor (A & B) | C gets the same name as A & (B | C)
        assert 1 <= len(inputs) <= 2, "only one or two inputs are accepted"
        if logic == BoolNode.AND:
            return Algorithm(
                event_list_intersection_t,
                name="_AND_".join([i.producer.name for i in inputs]),
                dev_event_list_a_t=inputs[0],
                dev_event_list_b_t=inputs[1],
            )
        elif logic == BoolNode.OR:
            return Algorithm(
                event_list_union_t,
                name="_OR_".join([i.producer.name for i in inputs]),
                dev_event_list_a_t=inputs[0],
                dev_event_list_b_t=inputs[1],
            )
        elif logic == BoolNode.NOT:
            return Algorithm(
                event_list_inversion_t,
                name="NOT_" + inputs[0].producer.name,
                dev_event_list_input_t=inputs[0],
            )
        else:
            raise ValueError(f"unknown logic {logic}")

    def combine(logic, *nodes):  # needs to return pyconf algorithm
        output_masks = []
        for n in nodes:
            m = [a for a in n.outputs.values() if a.type == "mask_t"]
            assert len(m) == 1, f"should have one output mask, got {len(m)}"
            output_masks.append(m[0])

        return _make_combiner(
            inputs=output_masks, logic=logic)


    def make_combiners_from(node):
        if node is None:
            return [initialize_event_lists()]
        elif isinstance(node, Algorithm):
            return [node]
        elif isinstance(node, BoolNode):
            if node.combineLogic == BoolNode.NOT:
                combs = make_combiners_from(node.children[0])
                return combs + [combine(BoolNode.NOT, combs[-1])]
            else: # AND / OR
                lhs, rhs = node.children
                combs_lhs = make_combiners_from(lhs)
                combs_rhs = make_combiners_from(rhs)
                return combs_lhs + combs_rhs + [combine(node.combineLogic, combs_lhs[-1], combs_rhs[-1])]
        else:
            raise ValueError(f"expected input of type NoneType, Algorithm or BoolNode, got {type(node)}")

    # gather all combinations that have to be made
    masks = tuple(set([s[1] for s in order]))

    combiners = {m: make_combiners_from(m) for m in masks}

    # Generate the final sequence in a list of tuples (algorithm, execution mask)
    final_sequence = list(order)

    # Add combiners in the right place
    for mask, combs in combiners.items():
        for i, (alg, _mask) in enumerate(final_sequence):
            if mask == _mask:
                for comb in combs[::-1]:
                    final_sequence.insert(i, (comb, None))
                break

    # Remove duplicate combiners
    final_sequence_unique = list()
    for (alg, mask_in) in final_sequence:
        for (alg_, _) in final_sequence_unique:
            if alg == alg_:
                break
        else:
            final_sequence_unique.append((alg, mask_in))

    # Update all algorithm masks
    for alg, mask in final_sequence_unique:
        if is_combiner(alg):
            continue # combiner algorithms always run on all events, transforming masks
        mask_input = [k for k,v in configurable_inputs(alg.type).items() if v.type() == "mask_t"]
        if len(mask_input):
            output_mask = [v for v in combiners[mask][-1].outputs.values() if v.type == "mask_t"]
            assert(len(mask_input) == 1 and len(output_mask) == 1)
            alg.inputs[mask_input[0]] = output_mask[0]

    return tuple(final_sequence_unique)

def generate(root):
    """Generates an Allen sequence out of a root node."""
    best_order, score = get_execution_list_for(root)
    final_seq = add_event_list_combiners(best_order)

    print("Generated sequence represented as algorithms with execution masks:")
    for alg, mask_in in final_seq:
        mask_in_str = f" in:{str(mask_in).split('/')[1]}" if mask_in else ""
        print(f"  {alg}{mask_in_str}")

    return generate_allen_sequence([alg for (alg,_) in final_seq])
