###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.cftree_ops import get_execution_list_for, BoolNode
from AllenCore.event_list_utils import add_event_list_combiners
from AllenCore.AllenSequenceGenerator import generate_json_configuration
from AllenCore.allen_benchmarks import benchmark_weights, benchmark_efficiencies
from AllenCore.algorithms import host_init_event_list_t
from PyConf.components import Algorithm
from PyConf.filecontent_metadata import flush_key_registry
from PyConf.tonic import configurable
from json import dump


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
        eff = .99  # TODO we could also just do 1, but then they wont be considered in masks

    if "weight" in kwargs:
        weight = kwargs["weight"]
    elif name in benchmark_weights:
        weight = benchmark_weights[name]
    elif "prefix_sum" in name:  # hard coded heuristic for now, TODO might want to change
        weight = 1000.0
    elif alg_type.category() == "SelectionAlgorithm":
        weight = 10.0
    else:
        weight = 100.0

    return Algorithm(
        alg_type, name=name, weight=weight, average_eff=eff, **kwargs)


def initialize_event_lists(**kwargs):
    initialize_lists = make_algorithm(
        host_init_event_list_t, name="initialize_event_lists")
    return initialize_lists


def build_sequence(root, verbose=True):
    if type(root) == dict:
        root = root['control_flow_node']

    with flush_key_registry():
        best_order, score = get_execution_list_for(root)
        final_seq = add_event_list_combiners(best_order)

    if verbose:
        print("Generated sequence represented as algorithms with execution masks:")
        for alg, mask_in in final_seq:
            if mask_in == None:
                mask_in_str = ""
            elif isinstance(mask_in, Algorithm):
                mask_in_str = f" in:{str(mask_in).split('/')[1]}"
            elif isinstance(mask_in, BoolNode):
                mask_in_str = f" in:{mask_in}"
            print(f"  {alg}{mask_in_str}")

    return [alg for (alg, _) in final_seq]


@configurable
def generate(root, json_configuration_filename="Sequence.json", noop=False, verbose=True):
    """Generates an Allen sequence out of a root node."""
    if noop:
        return

    algorithms = build_sequence(root, verbose=verbose)

    sequence_json = generate_json_configuration(algorithms)
    with open(json_configuration_filename, 'w') as outfile:
        dump(sequence_json, outfile, indent=4, sort_keys=True)
