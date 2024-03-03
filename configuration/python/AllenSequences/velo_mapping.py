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
from AllenConf.hlt1_monitoring_lines import make_velo_micro_bias_line, make_z_range_materialvertex_seed_line
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenCore.generator import generate
from AllenConf.persistency import make_persistency
from AllenConf.utils import line_maker
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.validators import rate_validation
from AllenConf.odin import odin_error_filter, tae_filter


def setup_hlt1_node(velo_open=False):
    hlt1_config = {}

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(velo_open=velo_open)
    hlt1_config['reconstruction'] = reconstructed_objects
    material_interaction_tracks = reconstructed_objects[
        "material_interaction_tracks"]

    odin_err_filter = [odin_error_filter("odin_error_filter")]
    with line_maker.bind(prefilter=odin_err_filter + [tae_filter()]):
        lines = [
            line_maker(
                make_passthrough_line(name="Hlt1TAEPassthrough", pre_scaler=1))
        ]

    with line_maker.bind(prefilter=odin_err_filter):
        lines += [
            line_maker(
                make_z_range_materialvertex_seed_line(
                    material_interaction_tracks,
                    min_z_materialvertex_seed=-550,
                    max_z_materialvertex_seed=1000,
                    name="Hlt1MaterialVertexSeeds_zIntegrated",
                    post_scaler=0.01)),
            line_maker(
                make_z_range_materialvertex_seed_line(
                    material_interaction_tracks,
                    min_z_materialvertex_seed=300,
                    max_z_materialvertex_seed=1000,
                    name="Hlt1MaterialVertexSeeds_Downstreamz_z",
                    post_scaler=0.5)),
            line_maker(
                make_z_range_materialvertex_seed_line(
                    material_interaction_tracks,
                    min_z_materialvertex_seed=700,
                    max_z_materialvertex_seed=1000,
                    name="Hlt1_MaterialVertexSeeds_DWFS"))
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
