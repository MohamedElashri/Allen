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
from AllenConf.velo_reconstruction import velo_tracking, decode_velo
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

with decode_velo.bind(retina_decoding=False):
    velo_tracking_sequence = CompositeNode(
        "VeloTracking", [velo_tracking()],
        NodeLogic.LAZY_AND,
        force_order=True)

generate(velo_tracking_sequence)
