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
from AllenConf.matching_reconstruction import velo_scifi_matching
from AllenConf.ut_reconstruction import decode_ut
from AllenConf.hlt1_reconstruction import make_composite_node_with_gec
from AllenConf.filters import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

velo_scifi_matching_sequence = CompositeNode(
    "Matching", [
        make_composite_node_with_gec(
            "velo_scifi_matching",
            velo_scifi_matching(),
            with_scifi=True,
            with_ut=False),
        make_composite_node_with_gec(
            "decode_ut",
            decode_ut()['dev_ut_hits'],
            with_scifi=True,
            with_ut=True)
    ],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(velo_scifi_matching_sequence)
