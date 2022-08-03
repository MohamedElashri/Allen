###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import gec
from AllenConf.scifi_reconstruction import forward_tracking
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.validators import (velo_validation, long_validation)

tracks = forward_tracking(with_ut=False)

velo_node = CompositeNode(
    "velo_validation",
    [velo_validation(tracks["velo_tracks"])],
    NodeLogic.LAZY_AND,
    force_order=True)

long_node = CompositeNode(
    "long_validation",
    [long_validation(tracks)],
    NodeLogic.LAZY_AND,
    force_order=True)

forward_tracking_sequence = CompositeNode(
    "ForwardTrackingNoUT", [velo_node, long_node],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(forward_tracking_sequence)
