from minipyconf.components import Algorithm
from minipyconf.dataflow import configurable_inputs
from minipyconf.cftree_ops import get_best_order, get_execution_list_for
from minipyconf.control_flow import Leaf, NodeLogic, CompositeNode
from definitions.AllenSequenceGenerator import generate_allen_sequence
from definitions.allen_benchmarks import benchmark_weights, benchmark_efficiencies
from definitions.algorithms import AlgorithmCategory
from definitions.algorithms import (
    host_init_event_list_t,
    event_list_intersection_t,
    event_list_union_t,
    event_list_inversion_t,
)


def make_algorithm(alg_type, name, **kwargs):
    """Makes an Algorithm with a weight extracted from the benchmark weights."""
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
    # gather all combinations that have to be made
    seq, val = order
    trees = tuple(set(seq.values()))

    def _make_combiner(inputs, logic):

        if logic == NodeLogic.AND:
            return Algorithm(
                event_list_intersection_t,
                name="_AND_".join([i.producer.name for i in inputs]),
                dev_event_list_a_t=inputs[0],
                dev_event_list_b_t=inputs[1],
            )
        elif logic == NodeLogic.OR:
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
        return _make_combiner(
            inputs=[n.dev_event_list_output_t for n in nodes], logic=logic
        )

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
    final_sequence = list(order[0].items())

    # Add combiners in the right place
    for mask, combiner in combiners.items():
        for i, (alg, _mask) in enumerate(final_sequence):
            if mask == _mask:
                for comb in combiner[::-1]:
                    final_sequence.insert(i, (comb, None))
                break

    # Remove duplicate combiners
    final_sequence_unique = list()
    for alg, mask in final_sequence:
        for alg_, _ in final_sequence_unique:
            if alg == alg_:
                break
        else:
            final_sequence_unique.append((alg, mask))

    # Update all algorithm event lists
    for alg, mask in final_sequence_unique:
        if "dev_event_list_t" in configurable_inputs(alg.type):
            alg.inputs["dev_event_list_t"] = combiners[mask][-1].dev_event_list_output_t

    return [alg for alg, _ in final_sequence_unique]


def generate(node):
    """Generates an Allen sequence out of a root node."""
    best_order = get_execution_list_for(node)

    print("Generated sequence represented as algorithms with execution masks:")
    for a, b in best_order[0].items():
        print(f"  {a} ({b})")
    
    final_seq = add_event_list_combiners(best_order)
    return generate_allen_sequence(final_seq)
