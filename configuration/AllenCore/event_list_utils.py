###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.components import Algorithm
from PyConf.dataflow import configurable_inputs
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.cftree_ops import get_best_order, BoolNode
from AllenConf.algorithms import (
    event_list_intersection_t,
    event_list_union_t,
    event_list_inversion_t,
)


def is_combiner(alg):
    return alg.type in (event_list_intersection_t, event_list_union_t,
                        event_list_inversion_t)


def add_event_list_combiners(order):
    """
    This function accepts an ordered list of algorithms and inserts event list combiners
    where necessary to fulfill combined masks formed as a combination of other masks.

    Combiners are host algorithms that provide three operations for masks: union, intersection
    and difference. These three operations would correspond in a single-event scenario to the
    OR, AND and NOT gate. This equivalence is used to transform NodeLogic into combiners.
    """

    from AllenCore.generator import initialize_event_lists
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

        return _make_combiner(inputs=output_masks, logic=logic)

    def make_combiners_from(node):
        if node is None:
            return [initialize_event_lists()]
        elif isinstance(node, Algorithm):
            return [node]
        elif isinstance(node, BoolNode):
            if node.combine_logic == BoolNode.NOT:
                combs = make_combiners_from(node.children[0])
                return combs + [combine(BoolNode.NOT, combs[-1])]
            else:  # AND / OR
                lhs, rhs = node.children
                combs_lhs = make_combiners_from(lhs)
                combs_rhs = make_combiners_from(rhs)
                return combs_lhs + combs_rhs + [
                    combine(node.combine_logic, combs_lhs[-1], combs_rhs[-1])
                ]
        else:
            raise ValueError(
                f"expected input of type NoneType, Algorithm or BoolNode, got {type(node)}"
            )

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
            continue  # combiner algorithms always run on all events, transforming masks
        mask_input = [
            k for k, v in configurable_inputs(alg.type).items()
            if v.type() == "mask_t"
        ]
        if len(mask_input):
            output_mask = [
                v for v in combiners[mask][-1].outputs.values()
                if v.type == "mask_t"
            ]
            assert (len(mask_input) == 1 and len(output_mask) == 1)
            alg.inputs[mask_input[0]] = output_mask[0]

    return tuple(final_sequence_unique)
