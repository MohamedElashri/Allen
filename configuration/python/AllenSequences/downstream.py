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
from AllenConf.downstream_reconstruction import downstream_track_reconstruction

from AllenConf.filters import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

downstream_sequence = CompositeNode(
    "DownstreamReconstruction", [downstream_track_reconstruction()],
    NodeLogic.LAZY_AND,
    force_order=True)
generate(downstream_sequence)
