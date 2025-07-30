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
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate, make_algorithm
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.persistency import make_persistency
from AllenConf.odin import decode_odin
from AllenCore.algorithms import data_provider_t
from AllenConf.utils import line_maker
from AllenConf.validators import rate_validation

bank_providers = [decode_odin()['dev_odin_data'].producer]

# To test memory traffic when copying to the device, add the following
for det, bt in (("velo", "VP"), ("scifi", "FTCluster"), ("muon", "Muon"),
                ("ecal_banks", "ECal")):
    bank_providers.append(
        make_algorithm(data_provider_t, name=det + "_banks", bank_type=bt))

passthrough_line = line_maker(make_passthrough_line(pre_scaler=1))
line_algorithms = [passthrough_line[0]]

providers = CompositeNode(
    "Providers", bank_providers, NodeLogic.NONLAZY_AND, force_order=False)

lines = CompositeNode(
    "AllLines", [passthrough_line[1]], NodeLogic.NONLAZY_OR, force_order=False)

persistency_node, persistency_algorithms = make_persistency(line_algorithms)

hlt1_node = CompositeNode(
    "Passthrough", [
        providers, lines, persistency_node,
        rate_validation(lines=line_algorithms)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(hlt1_node)
