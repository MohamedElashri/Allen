###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.ut_reconstruction import ut_tracking
from AllenConf.utils import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

ut_tracking_sequence = CompositeNode(
    "UTTrackingWithGEC", [make_gec("gec"), ut_tracking()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(ut_tracking_sequence)
