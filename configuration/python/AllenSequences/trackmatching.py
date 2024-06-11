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
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

velo_scifi_matching_sequence = CompositeNode(
    "Matching", [
        velo_scifi_matching(
            algorithm_name='velo_scifi_matching_sequence', ut_hits=decode_ut())
    ],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(velo_scifi_matching_sequence)
