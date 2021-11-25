###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate, make_algorithm
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.persistency import make_global_decision
from AllenConf.odin import decode_odin
from AllenConf.algorithms import data_provider_t
from AllenConf.HLT1 import line_maker

bank_providers = [decode_odin()['dev_odin_raw_input'].producer]

# To test memory traffic when copying to the device, add the following
# for det, bt in (("velo", "VP"), ("ut", "UT"), ("scifi", "FTCluster"),
#                 ("muon", "Muon")):
#     bank_providers.append(
#         make_algorithm(data_provider_t, name=det + "_banks", bank_type=bt))

passthrough_line = line_maker(
    "Hlt1Passthrough",
    make_passthrough_line(
        name="Hlt1Passthrough",
        pre_scaler_hash_string="passthrough_line_pre",
        post_scaler_hash_string="passthrough_line_post"),
    enableGEC=False)

global_decision = make_global_decision(lines=[passthrough_line[0]])

providers = CompositeNode(
    "Providers", bank_providers, NodeLogic.NONLAZY_AND, force_order=False)

lines = CompositeNode(
    "AllLines", [passthrough_line[1]], NodeLogic.NONLAZY_OR, force_order=False)

passthrough_sequence = CompositeNode(
    "Passthrough", [lines, global_decision],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(passthrough_sequence)
