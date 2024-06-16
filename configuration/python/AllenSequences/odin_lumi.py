###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenCore.generator import generate
from AllenConf.persistency import make_persistency
from AllenConf.utils import line_maker
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.validators import rate_validation
from AllenConf.odin import odin_error_filter, make_event_type, make_odin_orbit
from AllenConf.HLT1 import odin_monitoring_lines


def setup_hlt1_node(velo_open=False):
    hlt1_config = {}
    lines = []
    odin_err_filter = [odin_error_filter("odin_error_filter")]
    lumiline_name = "Hlt1ODINLumi"
    lumilinefull_name = "Hlt1ODIN1kHzLumi"
    odin_lumi_event = make_event_type(event_type='Lumi')
    with line_maker.bind(prefilter=odin_err_filter + [odin_lumi_event]):
        lines += [
            line_maker(
                make_passthrough_line(name=lumiline_name, pre_scaler=1.))
        ]

    odin_orbit = make_odin_orbit(odin_orbit_modulo=30, odin_orbit_remainder=1)
    with line_maker.bind(
            prefilter=odin_err_filter + [odin_lumi_event, odin_orbit]):
        lines += [
            line_maker(
                make_passthrough_line(name=lumilinefull_name, pre_scaler=1.))
        ]

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in lines]

    persistency_node, persistency_algorithms = make_persistency(
        line_algorithms)

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    hlt1_node = CompositeNode(
        "Allen", [lines, persistency_node],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms
    hlt1_config.update(persistency_algorithms)
    hlt1_config['control_flow_node'] = hlt1_node
    return hlt1_config


hlt1_node = setup_hlt1_node()
generate(hlt1_node)
