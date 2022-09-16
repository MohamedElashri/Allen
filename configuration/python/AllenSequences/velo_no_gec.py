###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import velo_tracking
from AllenConf.utils import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

velo_tracking_sequence = CompositeNode(
    "VeloTracking", [velo_tracking()], NodeLogic.LAZY_AND, force_order=True)

generate(velo_tracking_sequence)
