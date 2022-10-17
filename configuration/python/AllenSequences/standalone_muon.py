###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.muon_reconstruction import make_muon_stubs
from AllenCore.generator import generate
from AllenConf.persistency import make_gather_selections, make_sel_report_writer, make_global_decision, make_routingbits_writer, make_dec_reporter
from AllenConf.hlt1_muon_lines import make_one_muon_track_line
from AllenConf.utils import line_maker
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.hlt1_reconstruction import validator_node
from AllenConf.validators import rate_validation

muon_stubs = make_muon_stubs(monitoring=False)
lines = [
    line_maker(
        make_one_muon_track_line(
            muon_stubs["dev_muon_number_of_tracks"],
            muon_stubs["consolidated_muon_tracks"],
            muon_stubs["dev_output_buffer"],
            muon_stubs["host_total_sum_holder"],
            name="Hlt1OneMuonStub"))
]

line_algorithms = [tup[0] for tup in lines]
line_nodes = [tup[1] for tup in lines]

global_decision = make_global_decision(lines=line_algorithms)

lines = CompositeNode(
    "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

gather_selections = make_gather_selections(lines=line_algorithms)
hlt1_node = CompositeNode(
    "StandaloneMuon", [
        lines,
        make_routingbits_writer(lines=line_algorithms), global_decision,
        rate_validation(lines=line_algorithms)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)
generate(hlt1_node)
