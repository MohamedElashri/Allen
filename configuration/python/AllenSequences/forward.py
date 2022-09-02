###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import make_gec
from AllenConf.scifi_reconstruction import forward_tracking
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

forward_tracking_sequence = CompositeNode(
    "ForwardTrackingWithGEC", [make_gec(), forward_tracking()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(forward_tracking_sequence)
