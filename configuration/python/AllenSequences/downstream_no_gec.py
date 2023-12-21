###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.downstream_reconstruction import downstream_track_reconstruction

from AllenConf.utils import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

downstream_sequence = CompositeNode(
    "DownstreamReconstruction", [downstream_track_reconstruction()],
    NodeLogic.LAZY_AND,
    force_order=True)
generate(downstream_sequence)
