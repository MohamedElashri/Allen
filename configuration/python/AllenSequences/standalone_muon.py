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
from AllenConf.muon_reconstruction import make_muon_stubs
from AllenCore.generator import generate
from AllenConf.persistency import make_persistency
from AllenConf.hlt1_muon_lines import make_one_muon_track_line
from AllenConf.utils import line_maker
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.hlt1_reconstruction import validator_node
from AllenConf.validators import rate_validation

muon_stubs = make_muon_stubs(monitoring=False)
lines = [
    line_maker(
        make_one_muon_track_line(
            muon_stubs["consolidated_muon_tracks"],
            muon_stubs["dev_muon_tracks_offsets"],
            muon_stubs["host_muon_total_number_of_tracks"],
            name="Hlt1OneMuonStub"))
]

line_algorithms = [tup[0] for tup in lines]
line_nodes = [tup[1] for tup in lines]

lines = CompositeNode(
    "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

persistency_node, persistency_algorithms = make_persistency(line_algorithms)

hlt1_node = CompositeNode(
    "StandaloneMuon",
    [lines, persistency_node,
     rate_validation(lines=line_algorithms)],
    NodeLogic.NONLAZY_AND,
    force_order=True)
generate(hlt1_node)
