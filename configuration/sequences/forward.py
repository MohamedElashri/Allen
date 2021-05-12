###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import gec
from AllenConf.scifi_reconstruction import forward_tracking
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.event_list_utils import generate

forward_tracking_sequence = CompositeNode(
    "ForwardTrackingWithGEC",
    [gec("gec"), forward_tracking()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(forward_tracking_sequence)
