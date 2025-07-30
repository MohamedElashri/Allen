###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.generator import make_algorithm, initialize_event_lists
from AllenCore.algorithms import (host_init_number_of_events_t,
                                  layout_provider_t, event_list_inversion_t,
                                  host_dummy_maker_t)
from PyConf.tonic import configurable
from PyConf.control_flow import NodeLogic, CompositeNode


# Helper function to make composite nodes
def make_line_composite_node(name, algos):
    return CompositeNode(
        name + "_node", algos, NodeLogic.LAZY_AND, force_order=True)


@configurable
def line_maker(line_algorithm, prefilter=None):
    if prefilter is None:
        node = make_line_composite_node(
            line_algorithm.name, algos=[line_algorithm])
    elif isinstance(prefilter, list):
        node = make_line_composite_node(
            line_algorithm.name, algos=prefilter + [line_algorithm])
    else:
        node = make_line_composite_node(
            line_algorithm.name, algos=[prefilter, line_algorithm])
    return line_algorithm, node


def make_invert_event_list(
        alg, name, alg_output_event_list_name="dev_event_list_output_t"):
    return make_algorithm(
        event_list_inversion_t,
        name=name,
        dev_event_list_input_t=getattr(alg, alg_output_event_list_name))


def initialize_number_of_events():
    initialize_number_of_events = make_algorithm(
        host_init_number_of_events_t, name="initialize_number_of_events")
    return {
        "host_number_of_events":
        initialize_number_of_events.host_number_of_events_t,
        "host_event_list":
        initialize_number_of_events.host_number_of_events_t,
        "dev_number_of_events":
        initialize_number_of_events.dev_number_of_events_t,
    }


def mep_layout():
    layout = make_algorithm(layout_provider_t, name="mep_layout")
    return {
        "host_mep_layout": layout.host_mep_layout_t,
        "dev_mep_layout": layout.dev_mep_layout_t
    }


def make_dummy():
    return make_algorithm(host_dummy_maker_t, name="host_dummy_maker")
